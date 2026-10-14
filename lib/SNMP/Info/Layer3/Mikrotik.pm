# SNMP::Info::Layer3::Mikrotik
#
# Copyright (c) 2011 Jeroen van Ingen
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the University of California, Santa Cruz nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR # ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Layer3::Mikrotik;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Mikrotik::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Mikrotik::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.979000';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'HOST-RESOURCES-MIB'       => 'hrSystem',
    'MIKROTIK-MIB'             => 'mtxrLicVersion',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'hrSystemUptime' => 'hrSystemUptime',
    'os_level'       => 'mtxrLicLevel',
    'os_ver'         => 'mtxrLicVersion',
    'serial1'        => 'mtxrSystem.3.0',
    'firmware'       => 'mtxrSystem.4.0',
    'fan_type'       => 'mtxrHlActiveFan',
    'mt_board_name'  => 'mtxrBoardName',
    'mt_psu_state'        => 'mtxrHlPowerSupplyState',
    'mt_backup_psu_state' => 'mtxrHlBackupPowerSupplyState',
    'mt_fan1_speed'       => 'mtxrHlFanSpeed1.0',
    'mt_fan2_speed'       => 'mtxrHlFanSpeed2.0',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    'mt_nbr_ip'       => 'mtxrNeighborIpAddress',
    'mt_nbr_mac'      => 'mtxrNeighborMacAddress',
    'mt_nbr_identity' => 'mtxrNeighborIdentity',
    'mt_nbr_platform' => 'mtxrNeighborPlatform',
    'mt_nbr_if'       => 'mtxrNeighborInterfaceID',
    'mt_gauge_name'   => 'mtxrGaugeName',
    'mt_gauge_value'  => 'mtxrGaugeValue',
    'mt_poe_status'   => 'mtxrPOEStatus',
    'mt_poe_power'    => 'mtxrPOEPower',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    'mt_nbr_mac' => \&SNMP::Info::munge_mac,
);

sub vendor {
    return 'mikrotik';
}

sub serial {
    my $mikrotik = shift;
    return $mikrotik->serial1;
}

sub model {
    my $mikrotik = shift;

    my $board = $mikrotik->mt_board_name();
    return $board if $board;

    # Recent RouterOS 7 appends the version: "RouterOS CHR 7.24.5 (stable)"
    my $descr = $mikrotik->description() || '';
    my $model = undef;
    $model = $1
        if ( $descr =~ /^RouterOS\s+(\S+)(?:\s+\d+\.\d+\S*\s+\([\w-]+\))?$/i );
    $model = $1 if ( $descr =~ /^RouterOS\s+(RB .*)$/i );
    return $model;
}

sub os {
    return 'routeros';
}

# The legacy mtxrHealth scalars are in tenths of a degree; RouterOS 7
# reports whole degrees in mtxrGaugeTable instead.
sub board_temp {
    my $mikrotik = shift;
    my $temp = $mikrotik->mtxrHlTemperature;
    return $temp / 10.0 if defined $temp;
    return $mikrotik->_gauge_value( 'board-temperature1', 'temperature' );
}

sub cpu_temp {
    my $mikrotik = shift;
    my $temp = $mikrotik->mtxrHlProcessorTemperature;
    return $temp / 10.0 if defined $temp;
    return $mikrotik->_gauge_value('cpu-temperature');
}

sub _gauge_value {
    my ( $mikrotik, @names ) = @_;

    my $gauge_names  = $mikrotik->mt_gauge_name()  || {};
    my $gauge_values = $mikrotik->mt_gauge_value() || {};
    my %index_of     = reverse %$gauge_names;
    foreach my $name (@names) {
        my $index = $index_of{$name};
        return $gauge_values->{$index} if defined $index;
    }
    return;
}

# RouterOS health states, in the order mtxrGaugeTable status rows report
# them: 0 ok, 1 fail.
my @GAUGE_STATES = qw/ok fail not-present idle no-input/;

my %POE_STATUS = (
    disabled        => 'disabled',
    waitingForLoad  => 'searching',
    poweredOn       => 'deliveringPower',
    overload        => 'fault',
    shortCircuit    => 'fault',
    voltageTooLow   => 'fault',
    currentTooLow   => 'fault',
    voltageTooHigh  => 'fault',
    controllerError => 'fault',
);

sub ps1_status {
    my $mikrotik = shift;
    my $legacy   = $mikrotik->mt_psu_state();
    return $mikrotik->_psu_status( $legacy, 'psu1-state' );
}

sub ps2_status {
    my $mikrotik = shift;
    my $legacy   = $mikrotik->mt_backup_psu_state();
    return $mikrotik->_psu_status( $legacy, 'psu2-state' );
}

# mtxrHlPowerSupplyState and mtxrHlBackupPowerSupplyState are 1 when ok.
sub _psu_status {
    my ( $mikrotik, $legacy, $gauge_name ) = @_;

    return ( $legacy eq '1' or $legacy eq 'true' ) ? 'ok' : 'fail'
        if defined $legacy;
    return $mikrotik->_gauge_state($gauge_name);
}

sub _gauge_state {
    my ( $mikrotik, $name ) = @_;

    my $value = $mikrotik->_gauge_value($name);
    return unless defined $value;
    return $GAUGE_STATES[$value] // "unknown ($value)";
}

sub fan {
    my $mikrotik = shift;

    my @parts = grep {defined} $mikrotik->_gauge_state('fan-state'),
        $mikrotik->_fan_speeds();
    return unless @parts;
    return join( ', ', @parts );
}

sub _fan_speeds {
    my $mikrotik = shift;

    my $fan1   = $mikrotik->mt_fan1_speed();
    my $fan2   = $mikrotik->mt_fan2_speed();
    my @legacy
        = grep { defined $_->[1] } [ 'fan1', $fan1 ], [ 'fan2', $fan2 ];
    return map {"$_->[0] $_->[1] rpm"} @legacy if @legacy;

    my $gauge_names  = $mikrotik->mt_gauge_name()  || {};
    my $gauge_values = $mikrotik->mt_gauge_value() || {};
    my %speed_of;
    foreach my $index ( keys %$gauge_names ) {
        next unless $gauge_names->{$index} =~ /^(fan\d+)-speed$/;
        $speed_of{$1} = $gauge_values->{$index};
    }
    return map {"$_ $speed_of{$_} rpm"} sort keys %speed_of;
}

# POWER-ETHERNET-MIB is used if the device has it; RouterOS only exports
# mtxrPOETable, indexed by ifIndex, which is mapped to module 1.
sub _uses_mt_poe {
    my $mikrotik = shift;

    my $standard = $mikrotik->SUPER::peth_port_status() || {};
    return 0 if scalar keys %$standard;
    my $status = $mikrotik->mt_poe_status() || {};
    return scalar keys %$status;
}

sub _mt_poe_column {
    my ( $mikrotik, $column ) = @_;

    my $values = $mikrotik->$column() || {};
    return { map { ( "1.$_" => $values->{$_} ) } keys %$values };
}

sub peth_port_ifindex {
    my $mikrotik = shift;

    return $mikrotik->SUPER::peth_port_ifindex(@_)
        unless $mikrotik->_uses_mt_poe();
    my $status = $mikrotik->mt_poe_status() || {};
    return { map { ( "1.$_" => $_ ) } keys %$status };
}

sub peth_port_admin {
    my $mikrotik = shift;

    return $mikrotik->SUPER::peth_port_admin(@_)
        unless $mikrotik->_uses_mt_poe();
    my $status = $mikrotik->_mt_poe_column('mt_poe_status');
    return { map { ( $_ => $status->{$_} eq 'disabled' ? 'false' : 'true' ) }
            keys %$status };
}

sub peth_port_status {
    my $mikrotik = shift;

    return $mikrotik->SUPER::peth_port_status(@_)
        unless $mikrotik->_uses_mt_poe();
    my $status = $mikrotik->_mt_poe_column('mt_poe_status');
    return { map { ( $_ => $POE_STATUS{ $status->{$_} } || 'otherFault' ) }
            keys %$status };
}

# mtxrPOEPower is in deciwatts
sub peth_port_power {
    my $mikrotik = shift;

    return $mikrotik->SUPER::peth_port_power(@_)
        unless $mikrotik->_uses_mt_poe();
    my $power = $mikrotik->_mt_poe_column('mt_poe_power');
    return { map { ( $_ => $power->{$_} * 100 ) } keys %$power };
}

# RouterOS exports no PoE budget; an empty hash still lets callers read the
# port table.
sub peth_power_watts {
    my $mikrotik = shift;

    return $mikrotik->SUPER::peth_power_watts(@_)
        unless $mikrotik->_uses_mt_poe();
    return {};
}

sub peth_power_status {
    my $mikrotik = shift;

    return $mikrotik->SUPER::peth_power_status(@_)
        unless $mikrotik->_uses_mt_poe();
    return {};
}

# RouterOS returns MAC chassis IDs as text ("0C:00:1E:5A:27:00") rather than
# the six octets LLDP-MIB defines, which munge_mac() rejects.
sub _lldp_id_string {
    my ( $mikrotik, $id, $type ) = @_;

    return lc $id
        if $type =~ /mac/ and $id =~ /^(?:[0-9A-F]{2}:){5}[0-9A-F]{2}$/i;
    return $mikrotik->SUPER::_lldp_id_string( $id, $type );
}

# ifPhysAddress.1 is the loopback, all zeros. The chassis MAC is what LLDP
# neighbors report as c_id, so Netdisco can match them to this device.
sub mac {
    my $mikrotik = shift;

    my $chassis
        = $mikrotik->lldp_loc_id_type() ? $mikrotik->lldp_loc_id() : undef;
    return $chassis || $mikrotik->SUPER::mac();
}

# RouterOS advertises only addresses on the sending port or its bridge. For
# an LLDP neighbor without an IPv4 address, use the one mtxrNeighborTable has
# for it (from CDP, say). Failing that return 0.0.0.0, which Netdisco
# resolves by looking up c_id among known devices.
sub c_ip {
    my ( $mikrotik, $partial, $topo_cap ) = @_;

    my $c_ip     = $mikrotik->SUPER::c_ip( $partial, $topo_cap ) || {};
    my $c_id     = $mikrotik->c_id( $partial, $topo_cap )        || {};
    my $table_ip = $mikrotik->_lldp_table_ip();
    foreach my $iid ( keys %$c_id ) {
        next if defined $c_ip->{$iid};
        $c_ip->{$iid} = $table_ip->{$iid} // '0.0.0.0';
    }
    return $c_ip;
}

sub hasMNDP {
    my $mikrotik = shift;
    my $nbr_if   = $mikrotik->mt_nbr_if() || {};
    return scalar keys %$nbr_if ? 1 : undef;
}

sub mndp_ip       { return $_[0]->_mndp_column( 'mt_nbr_ip',       $_[1] ) }
sub mndp_if       { return $_[0]->_mndp_column( 'mt_nbr_if',       $_[1] ) }
sub mndp_id       { return $_[0]->_mndp_column( 'mt_nbr_mac',      $_[1] ) }
sub mndp_platform { return $_[0]->_mndp_column( 'mt_nbr_platform', $_[1] ) }

# mtxrNeighborTable has no remote port or capabilities
sub mndp_port { return {} }
sub mndp_cap  { return {} }

sub _mndp_column {
    my ( $mikrotik, $column, $partial ) = @_;

    my $values = $mikrotik->$column() || {};
    return { map { $_ => $values->{$_} } grep { defined $values->{$_} }
            @{ $mikrotik->_mndp_neighbors($partial) } };
}

# mtxrNeighborTable lists neighbors heard by MNDP, CDP and LLDP alike. Skip
# those LLDP-MIB already reports on the same port: Netdisco keeps one
# neighbor per port and would replace the LLDP one, which has a remote port.
sub _mndp_neighbors {
    my ( $mikrotik, $partial ) = @_;

    my $nbr_if    = $mikrotik->mt_nbr_if()        || {};
    my $nbr_ip    = $mikrotik->mt_nbr_ip()        || {};
    my $identity  = $mikrotik->mt_nbr_identity()  || {};
    my $lldp_if   = $mikrotik->lldp_if()          || {};
    my $lldp_name = $mikrotik->lldp_rem_sysname() || {};
    my %lldp_seen = map { _nbr_key( $lldp_if->{$_}, $lldp_name->{$_} ) => 1 }
        keys %$lldp_if;

    my @neighbors;
    foreach my $idx ( keys %$nbr_if ) {
        next if defined $partial and $idx ne $partial;
        next if !$nbr_ip->{$idx} or $nbr_ip->{$idx} eq '0.0.0.0';
        my $neighbor = _nbr_key( $nbr_if->{$idx}, $identity->{$idx} );
        push @neighbors, $idx unless $lldp_seen{$neighbor};
    }
    return \@neighbors;
}

# IPv4 addresses mtxrNeighborTable holds for LLDP neighbors, keyed by the
# LLDP entry and matched on local port and name.
sub _lldp_table_ip {
    my $mikrotik = shift;

    my $nbr_if   = $mikrotik->mt_nbr_if()       || {};
    my $nbr_ip   = $mikrotik->mt_nbr_ip()       || {};
    my $identity = $mikrotik->mt_nbr_identity() || {};
    my %ip_of
        = map { _nbr_key( $nbr_if->{$_}, $identity->{$_} ) => $nbr_ip->{$_} }
        grep { $nbr_ip->{$_} and $nbr_ip->{$_} ne '0.0.0.0' } keys %$nbr_if;

    my $lldp_if   = $mikrotik->lldp_if()          || {};
    my $lldp_name = $mikrotik->lldp_rem_sysname() || {};
    my %table_ip;
    foreach my $iid ( keys %$lldp_if ) {
        my $ip = $ip_of{ _nbr_key( $lldp_if->{$iid}, $lldp_name->{$iid} ) };
        $table_ip{$iid} = $ip if defined $ip;
    }
    return \%table_ip;
}

sub _nbr_key {
    my ( $ifindex, $name ) = @_;
    return ( $ifindex // '' ) . ' ' . ( $name // '' );
}

sub i_vlan_membership {
    my $mikrotik = shift;
    my $partial  = shift;

    my $q_bridge = $mikrotik->SUPER::i_vlan_membership($partial);
    return $q_bridge if ref {} eq ref $q_bridge and scalar keys %$q_bridge;

    return $mikrotik->_pvid_membership($partial);
}

sub i_vlan_membership_untagged {
    my $mikrotik = shift;
    my $partial  = shift;

    my $q_bridge = $mikrotik->SUPER::i_vlan_membership_untagged($partial);
    return $q_bridge if ref {} eq ref $q_bridge and scalar keys %$q_bridge;

    return $mikrotik->_pvid_membership($partial);
}

# RouterOS exports no Q-BRIDGE VLAN static or current tables, only the port
# PVID. A port carries its PVID untagged unless it admits only tagged frames,
# which qb_i_vlan_t() reports as 'trunk'. Tagged VLANs are not exported.
sub _pvid_membership {
    my $mikrotik = shift;
    my $partial  = shift;

    my $index = $mikrotik->bp_index() || {};
    my $bridge_port;
    if ( defined $partial ) {
        my %bridge_port_of = reverse %$index;
        $bridge_port = $bridge_port_of{$partial};
        return {} unless defined $bridge_port;
    }

    my $pvids      = $mikrotik->qb_i_vlan_t($bridge_port) || {};
    my $membership = {};
    foreach my $port ( keys %$pvids ) {
        my $vlan    = $pvids->{$port};
        my $ifindex = $index->{$port};
        next unless defined $ifindex and $vlan ne 'trunk';
        $membership->{$ifindex} = [$vlan];
    }
    return $membership;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Mikrotik - SNMP Interface to Mikrotik devices

=head1 AUTHORS

Jeroen van Ingen
initial version based on SNMP::Info::Layer3::NetSNMP by Bradley Baetz and Bill Fenner

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $mikrotik = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $mikrotik->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Mikrotik devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<HOST-RESOURCES-MIB>

=item F<MIKROTIK-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $mikrotik->vendor()

Returns C<'mikrotik'>.

=item $mikrotik->os()

Returns C<'routeros'>.

=item $mikrotik->model()

Returns C<mtxrBoardName>, or else tries to extract the device model from
C<sysDescr>.

=item $mikrotik->os_ver()

Returns the value of C<mtxrLicVersion>.

=item $mikrotik->os_level()

Returns the value of RouterOS level C<mtxrLicLevel>

=item $mikrotik->board_temp()

=item $mikrotik->cpu_temp()

Returns the board or CPU temperature in degrees Celsius, from the
C<mtxrHealth> scalars or, on RouterOS 7, from C<mtxrGaugeTable>.

=item $mikrotik->serial()

Returns the device serial.

=item $mikrotik->firmware()

Returns the firmware version of hardware.

=item $mikrotik->hasMNDP()

Returns 1 when C<mtxrNeighborTable> has rows. C<has_topo()> then adds
C<mndp>, so the C<c_*> topology methods include those neighbors.

=item $mikrotik->mac()

Returns the LLDP chassis MAC (C<lldp_loc_id()>). C<ifPhysAddress.1> is the
loopback on RouterOS and reads as all zeros; it is used only when there is
no LLDP chassis ID.

=item $mikrotik->mt_board_name()

(C<mtxrBoardName>)

=item $mikrotik->ps1_status()

=item $mikrotik->ps2_status()

Returns C<ok> or C<fail> from C<mtxrHlPowerSupplyState> or
C<mtxrHlBackupPowerSupplyState>. Without them, returns the C<psu1-state> or
C<psu2-state> row of C<mtxrGaugeTable>: C<ok>, C<fail>, C<not-present>,
C<idle> or C<no-input>.

=item $mikrotik->fan()

Returns the C<fan-state> row of C<mtxrGaugeTable> (C<ok> or C<fail>) and
the fan speeds, for example C<ok, fan1 3825 rpm, fan2 3945 rpm>. Speeds come
from C<mtxrHlFanSpeed1> and C<mtxrHlFanSpeed2>, or else the C<fanN-speed>
rows of C<mtxrGaugeTable>.

=item $mikrotik->mt_psu_state()

(C<mtxrHlPowerSupplyState>)

=item $mikrotik->mt_backup_psu_state()

(C<mtxrHlBackupPowerSupplyState>)

=item $mikrotik->mt_fan1_speed()

(C<mtxrHlFanSpeed1>)

=item $mikrotik->mt_fan2_speed()

(C<mtxrHlFanSpeed2>)

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $mikrotik->c_ip()

For an LLDP neighbor that advertises no IPv4 management address, returns the
address C<mtxrNeighborTable> has for the same neighbor (matched on local port
and name), for example one learned by CDP. Failing that it returns
C<0.0.0.0>, so Netdisco can resolve the neighbor by C<c_id()>. RouterOS
advertises only addresses on the sending port or its bridge, not on VLAN
interfaces.

=item $mikrotik->i_vlan_membership()

Returns reference to hash of arrays: key = C<ifIndex>, value = array of VLAN
IDs. Uses Q-BRIDGE-MIB when the device exports VLAN tables. RouterOS exports
only the port PVID, so each port's PVID is returned instead, except on ports
that admit only tagged frames. Tagged VLANs are not available.

=item $mikrotik->i_vlan_membership_untagged()

Returns reference to hash of arrays: key = C<ifIndex>, value = array of VLAN
IDs. Same source and fallback as C<i_vlan_membership()>.

=back

=head2 MikroTik neighbors (C<mndp>)

C<mtxrNeighborTable> lists neighbors heard by MNDP, CDP and LLDP. These
methods return the ones LLDP-MIB does not already report on the same port,
and only those with an IPv4 address. They are keyed by C<mtxrNeighborIndex>.

=over

=item $mikrotik->mndp_ip()

(C<mtxrNeighborIpAddress>)

=item $mikrotik->mndp_if()

Local C<ifIndex> (C<mtxrNeighborInterfaceID>).

=item $mikrotik->mndp_id()

Neighbor MAC address (C<mtxrNeighborMacAddress>).

=item $mikrotik->mndp_platform()

(C<mtxrNeighborPlatform>)

=item $mikrotik->mndp_port()

=item $mikrotik->mndp_cap()

Return an empty hash: the table has no remote port or capabilities.

=back

=head2 MikroTik neighbor table (C<MIKROTIK-MIB::mtxrNeighborTable>)

=over

=item $mikrotik->mt_nbr_ip()

(C<mtxrNeighborIpAddress>)

=item $mikrotik->mt_nbr_mac()

(C<mtxrNeighborMacAddress>)

=item $mikrotik->mt_nbr_identity()

(C<mtxrNeighborIdentity>)

=item $mikrotik->mt_nbr_platform()

(C<mtxrNeighborPlatform>)

=item $mikrotik->mt_nbr_if()

(C<mtxrNeighborInterfaceID>)

=back

=head2 Gauge Table (C<mtxrGaugeTable>)

=over

=item $mikrotik->mt_gauge_name()

(C<mtxrGaugeName>)

=item $mikrotik->mt_gauge_value()

(C<mtxrGaugeValue>)

=back

=head2 Power over Ethernet

When the device has no F<POWER-ETHERNET-MIB> port table, these methods
emulate it from C<mtxrPOETable>. Entries are keyed C<1.ifIndex>.

=over

=item $mikrotik->peth_port_ifindex()

Maps C<1.ifIndex> to C<ifIndex>, from the C<mtxrPOETable> index.

=item $mikrotik->peth_port_admin()

C<false> when C<mtxrPOEStatus> is C<disabled>, else C<true>.

=item $mikrotik->peth_port_status()

From C<mtxrPOEStatus>: C<poweredOn> is C<deliveringPower>,
C<waitingForLoad> is C<searching>, C<disabled> is C<disabled>; overload,
short circuit, voltage, current and controller errors are C<fault>;
anything else is C<otherFault>.

=item $mikrotik->peth_port_power()

Power the port is delivering, in milliwatts (C<mtxrPOEPower>).

=item $mikrotik->peth_power_watts()

=item $mikrotik->peth_power_status()

RouterOS exports no PoE budget, so these return an empty hash.

=item $mikrotik->mt_poe_status()

(C<mtxrPOEStatus>)

=item $mikrotik->mt_poe_power()

(C<mtxrPOEPower>)

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=cut
