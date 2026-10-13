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

$VERSION = '3.978002';

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

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=cut
