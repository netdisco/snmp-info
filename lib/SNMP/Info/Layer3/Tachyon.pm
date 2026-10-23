# SNMP::Info::Layer3::Tachyon - SNMP interface to Tachyon Networks TNA devices
#
# Copyright (c) 2026 by The Netdisco Developer Team.
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
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Layer3::Tachyon;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Tachyon::ISA = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Tachyon::EXPORT_OK = qw//;

our ($VERSION, %FUNCS, %GLOBALS, %MIBS, %MUNGE);

$VERSION = '3.981001';

# Tachyon's private MIB is not included in netdisco-mibs. Poll its stable
# numeric OIDs directly so discovery does not depend on an external MIB file.
%MIBS = (%SNMP::Info::Layer3::MIBS);
%FUNCS = (%SNMP::Info::Layer3::FUNCS);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'tachyon_device_model'  => '.1.3.6.1.4.1.57344.1.3.1.0',
    'tachyon_serial'        => '.1.3.6.1.4.1.57344.1.3.2.0',
    'tachyon_firmware'      => '.1.3.6.1.4.1.57344.1.3.4.0',
    'tachyon_description'   => '.1.3.6.1.4.1.57344.1.3.9.0',
);

%MUNGE = (%SNMP::Info::Layer3::MUNGE);

sub vendor { return 'tachyon'; }

sub os { return 'Tachyon'; }

sub model {
    my $self = shift;
    my $model = $self->tachyon_device_model();
    return $model if defined $model and $model =~ /\S/;
    return $self->SUPER::model();
}

sub os_ver {
    my $self = shift;
    my $version = $self->tachyon_firmware();
    return $version if defined $version and $version =~ /\S/;
    return;
}

sub serial {
    my $self = shift;
    my $serial = $self->tachyon_serial();
    return $serial if defined $serial and $serial =~ /\S/;
    return $self->SUPER::serial();
}

sub description {
    my $self = shift;
    my $description = $self->tachyon_description();
    return $description if defined $description and $description =~ /\S/;
    return $self->SUPER::description();
}

# Walk a column numerically because the vendor MIB is not required by
# SNMP::Info or Netdisco. The returned indexes are the SNMP table indexes.
sub _tachyon_column {
    my ( $self, $attr, $base ) = @_;
    return $self->_show_attr( $attr, 0 ) if defined $self->{"_$attr"};

    my $sess = $self->session() or return {};
    my %rows;
    my %seen;
    my $next_oid = $base;

    while (1) {
        my $var = SNMP::Varbind->new( [$next_oid] );
        $sess->getnext($var);
        if ( $sess->{ErrorNum} ) {
            last if SNMP::Info::_nosuch_end($sess);
            $self->error_throw("Tachyon table walk failed for $attr");
            return;
        }

        my $name = $var->[0];
        $name .= ".$var->[1]" if defined $var->[1] and length $var->[1];
        my $oid = $name =~ /^\.[0-9]/ ? $name : (SNMP::translateObj($name) || $name);
        last if defined $var->[2] and $var->[2] eq 'ENDOFMIBVIEW';
        last unless $oid =~ /^\Q$base\E\.(\d+(?:\.\d+)*)$/;
        last if $seen{$oid}++;

        $rows{$1} = $var->[2] if defined $var->[2];
        $next_oid = $oid;
    }

    $self->_cache( $attr, \%rows );
    return $self->_show_attr( $attr, 0 );
}

my %TACHYON_COLUMNS = (
    tachyon_peer_mac     => '.1.3.6.1.4.1.57344.1.2.6.1.1',
    tachyon_peer_ifindex => '.1.3.6.1.4.1.57344.1.2.6.1.3',
    tachyon_ethernet_ifname => '.1.3.6.1.4.1.57344.1.1.3.1.2',
    tachyon_ethernet_link   => '.1.3.6.1.4.1.57344.1.1.3.1.5',
    tachyon_ethernet_duplex => '.1.3.6.1.4.1.57344.1.1.3.1.8',
    tachyon_ethernet_admin  => '.1.3.6.1.4.1.57344.1.1.3.1.10',
);

sub _tachyon_munge_mac {
    my $mac = shift;
    return unless defined $mac;

    $mac =~ s/[^0-9A-Fa-f]//g;
    return unless length($mac) == 12;
    return join ':', map { lc substr( $mac, $_, 2 ) } ( 0, 2, 4, 6, 8, 10 );
}

sub fw_mac {
    my $self = shift;
    my $macs = _tachyon_column( $self, 'tachyon_peer_mac', $TACHYON_COLUMNS{tachyon_peer_mac} ) || {};
    my %fw_mac;
    foreach my $index ( keys %$macs ) {
        my $mac = _tachyon_munge_mac( $macs->{$index} );
        $fw_mac{$index} = $mac if defined $mac;
    }
    return \%fw_mac;
}

sub fw_port {
    my $self = shift;
    return _tachyon_column( $self, 'tachyon_peer_ifindex', $TACHYON_COLUMNS{tachyon_peer_ifindex} ) || {};
}

# The peer table lists active wireless associations, so they have learned
# forwarding status. Its port value is already an ifIndex rather than a
# dot1d bridge port number.
sub fw_status {
    my $self = shift;
    my $macs = $self->fw_mac() || {};
    return { map { $_ => 3 } keys %$macs };
}

sub bp_index {
    my $self = shift;
    my $if_index = $self->i_index() || {};
    return { map { $_ => $_ } keys %$if_index };
}

sub _tachyon_ethernet_ifindexes {
    my $self = shift;
    my $ifnames = _tachyon_column(
        $self, 'tachyon_ethernet_ifname', $TACHYON_COLUMNS{tachyon_ethernet_ifname}
    ) || {};
    my $if_descriptions = $self->i_description() || {};
    my %ifindex_for_name = map { $if_descriptions->{$_} => $_ }
        grep { defined $if_descriptions->{$_} } keys %$if_descriptions;
    my %ifindex_for_row;

    foreach my $row ( keys %$ifnames ) {
        my $ifindex = $ifindex_for_name{ $ifnames->{$row} };
        $ifindex_for_row{$row} = $ifindex if defined $ifindex;
    }

    return \%ifindex_for_row;
}

sub i_up {
    my ( $self, $partial ) = @_;
    my $up = $self->SUPER::i_up($partial) || {};
    my $ifindex_for_row = _tachyon_ethernet_ifindexes($self);
    my $link = _tachyon_column(
        $self, 'tachyon_ethernet_link', $TACHYON_COLUMNS{tachyon_ethernet_link}
    ) || {};

    foreach my $row ( keys %$link ) {
        my $ifindex = $ifindex_for_row->{$row};
        next unless defined $ifindex;
        next if defined $partial and $partial ne $ifindex;
        $up->{$ifindex} = $link->{$row} ? 'up' : 'down';
    }

    return $up;
}

sub i_up_admin {
    my ( $self, $partial ) = @_;
    my $admin = $self->SUPER::i_up_admin($partial) || {};
    my $ifindex_for_row = _tachyon_ethernet_ifindexes($self);
    my $enabled = _tachyon_column(
        $self, 'tachyon_ethernet_admin', $TACHYON_COLUMNS{tachyon_ethernet_admin}
    ) || {};

    foreach my $row ( keys %$enabled ) {
        my $ifindex = $ifindex_for_row->{$row};
        next unless defined $ifindex;
        next if defined $partial and $partial ne $ifindex;
        $admin->{$ifindex} = $enabled->{$row} ? 'up' : 'down';
    }

    return $admin;
}

sub i_duplex {
    my ( $self, $partial ) = @_;
    my $duplex = $self->SUPER::i_duplex($partial) || {};
    my $ifindex_for_row = _tachyon_ethernet_ifindexes($self);
    my $ethernet_duplex = _tachyon_column(
        $self, 'tachyon_ethernet_duplex', $TACHYON_COLUMNS{tachyon_ethernet_duplex}
    ) || {};

    foreach my $row ( keys %$ethernet_duplex ) {
        my $ifindex = $ifindex_for_row->{$row};
        next unless defined $ifindex;
        next if defined $partial and $partial ne $ifindex;
        my $value = lc( $ethernet_duplex->{$row} || '' );
        $duplex->{$ifindex} = $value if $value =~ /^(?:full|half)$/;
    }

    return $duplex;
}

sub i_type {
    my ( $self, $partial ) = @_;
    my $type = $self->SUPER::i_type($partial) || {};
    my $ifindex_for_row = _tachyon_ethernet_ifindexes($self);

    foreach my $ifindex ( values %$ifindex_for_row ) {
        next if defined $partial and $partial ne $ifindex;
        $type->{$ifindex} = 'ethernetCsmacd';
    }

    return $type;
}

# Tachyon firmware 1.12.1 does not populate the standard IP-MIB address
# tables. The management address is assigned to br-wan, or to br-mgmt<VLAN>
# when management VLAN is enabled. NetDisco's SNMP target is that address.
sub _tachyon_management_ip {
    my $self = shift;
    my $session = $self->session() or return;
    my $ip = $session->{DestHost};
    $ip = $self->{args}->{DestHost} if !defined($ip) or $ip eq '';
    return unless defined $ip and $ip ne '';

    # Net-SNMP records the peer as "address:port" for IPv4 sessions.
    $ip =~ s/:\d+$// if $ip =~ /^\d{1,3}(?:\.\d{1,3}){3}:\d+$/;

    $ip = SNMP::Info::resolve_desthost($ip)
        unless $ip =~ /^\d{1,3}(?:\.\d{1,3}){3}$/;
    return unless defined $ip and $ip =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;
    return if grep { $_ > 255 } ( $1, $2, $3, $4 );

    my $names = $self->i_name() || {};
    my $ifindex;
    foreach my $index ( keys %$names ) {
        if ( $names->{$index} =~ /^br-mgmt\d+$/i ) {
            $ifindex = $index;
            last;
        }
    }
    if ( !defined $ifindex ) {
        foreach my $index ( keys %$names ) {
            if ( $names->{$index} eq 'br-wan' ) {
                $ifindex = $index;
                last;
            }
        }
    }

    return unless defined $ifindex;
    return ( $ip, $ifindex );
}

sub ip_index {
    my $self = shift;
    my $ip_index = $self->SUPER::ip_index() || {};
    return $ip_index if scalar keys %$ip_index;

    my ( $ip, $ifindex ) = _tachyon_management_ip($self);
    return defined $ip ? { $ip => $ifindex } : {};
}

sub ip_table {
    my $self = shift;
    my $ip_table = $self->SUPER::ip_table() || {};
    return $ip_table if scalar keys %$ip_table;

    my ( $ip ) = _tachyon_management_ip($self);
    return defined $ip ? { $ip => $ip } : {};
}

sub _tachyon_vlan_ifindexes {
    my $self = shift;
    my $names = $self->i_name() || {};
    my $descriptions = $self->i_description() || {};
    my %vlans;

    foreach my $ifindex ( keys %$names, keys %$descriptions ) {
        my $name = $names->{$ifindex} || $descriptions->{$ifindex} || '';
        my $vlan;
        $vlan = $1 if $name =~ /\.(\d{1,4})$/;
        $vlan = $1 if !defined($vlan) && $name =~ /^br[^.]*?(\d{1,4})$/i;
        next unless defined $vlan and $vlan >= 1 and $vlan <= 4094;
        $vlans{$ifindex} = 0 + $vlan;
    }

    return \%vlans;
}

sub i_vlan {
    my ( $self, $partial ) = @_;
    my $vlans = _tachyon_vlan_ifindexes($self);
    return $vlans unless defined $partial;
    return exists $vlans->{$partial} ? { $partial => $vlans->{$partial} } : {};
}

sub v_name {
    my ( $self, $partial ) = @_;
    my $vlans = _tachyon_vlan_ifindexes($self);
    my %names = map { $vlans->{$_} => "$vlans->{$_}" } keys %$vlans;
    return \%names unless defined $partial;
    return exists $names{$partial} ? { $partial => $names{$partial} } : {};
}

sub i_vlan_membership {
    my ( $self, $partial ) = @_;
    my $vlans = _tachyon_vlan_ifindexes($self);
    my %membership;
    foreach my $ifindex ( keys %$vlans ) {
        next if defined $partial and $ifindex ne $partial;
        $membership{$ifindex} = [ $vlans->{$ifindex} ];
    }
    return \%membership;
}

sub i_vlan_membership_untagged { return {}; }

=head1 NAME

SNMP::Info::Layer3::Tachyon - SNMP support for Tachyon TNA devices

=head1 DESCRIPTION

Supports Tachyon TNA-300 series devices using the Tachyon private MIB. Reads
model, serial number, and firmware version from the system extension group,
learns wireless peers from the peer table, and identifies VLAN interfaces by
their reported interface names. Vendor OIDs are polled numerically, so the
Tachyon MIB does not need to be installed.

=head1 GLOBALS

These methods return scalar values from the device.

=over

=item $info->vendor()

Returns C<'tachyon'>.

=item $info->os()

Returns C<'Tachyon'>.

=item $info->model()

Returns the device model from C<deviceModel>.

=item $info->os_ver()

Returns the firmware version from C<firmwareVersion>.

=item $info->serial()

Returns the serial number from C<deviceSerialNo>.

=item $info->description()

Returns the device description from the Tachyon system extension group.

=back

=head1 TABLE METHODS

These methods return tables as references to hashes.

=over

=item $info->fw_mac()

Returns wireless peer MAC addresses keyed by the peer table index.

=item $info->fw_port()

Returns the interface index associated with each wireless peer.

=item $info->fw_status()

Returns forwarding status C<3> for each active wireless peer.

=item $info->bp_index()

Maps interface indexes to themselves for bridge forwarding table lookups.

=item $info->i_up()

Returns interface operational status, including Tachyon Ethernet port state.

=item $info->i_up_admin()

Returns interface administrative status, including Tachyon Ethernet port
state.

=item $info->i_duplex()

Returns duplex mode for Tachyon Ethernet interfaces.

=item $info->i_type()

Reports Tachyon Ethernet interfaces as C<ethernetCsmacd>.

=item $info->i_vlan()

Maps VLAN interfaces to VLAN IDs using their interface names.

=item $info->v_name()

Maps VLAN IDs to names derived from the device's VLAN interface names.

=item $info->i_vlan_membership()

Returns VLAN membership for the logical VLAN interfaces reported by the
device.

=item $info->i_vlan_membership_untagged()

Returns an empty table because untagged VLAN membership is not available from
the device's SNMP data.

=item $info->ip_index()

Maps the management address used for SNMP discovery to its management bridge
when standard IP-MIB tables are unavailable.

=item $info->ip_table()

Returns the management address used for SNMP discovery when standard IP-MIB
tables are unavailable.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=cut

1;
