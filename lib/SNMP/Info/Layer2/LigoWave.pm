# SNMP::Info::Layer2::LigoWave - SNMP interface to LigoWave DLB radios
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

package SNMP::Info::Layer2::LigoWave;

use strict;
use warnings;
use Exporter;
use SNMP::Info::IEEE802dot11;
use SNMP::Info::Layer2;

@SNMP::Info::Layer2::LigoWave::ISA
    = qw/SNMP::Info::IEEE802dot11 SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::LigoWave::EXPORT_OK = qw//;

our ($VERSION, %FUNCS, %GLOBALS, %MIBS, %MUNGE);

$VERSION = '3.983000';

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
    %SNMP::Info::IEEE802dot11::MIBS,
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
    %SNMP::Info::IEEE802dot11::GLOBALS,
    # LIGO-GENERIC-MIB subtree, beyond the published objects
    'ligo_unit_id' => '.1.3.6.1.4.1.32750.3.1.1.1.0.1.2.0',
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
    %SNMP::Info::IEEE802dot11::FUNCS,
    # LIGO-WIRELESS-MIB, read by numeric OID until netdisco-mibs#310 is
    # released. ligoWiIfConfTable columns 1 to 16, in MIB order, from
    # ligoWiIfMacAddress to ligoWiIfAssocNodeCount:
    'ligo_wifi_mac'         => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.1',
    'ligo_wifi_protocol'    => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.2',
    'ligo_wifi_mode'        => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.3',
    'ligo_wifi_essid'       => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.4',
    'ligo_wifi_country'     => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.5',
    'ligo_wifi_frequency'   => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.6',
    'ligo_wifi_channel'     => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.7',
    'ligo_wifi_width'       => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.8',
    'ligo_wifi_encryption'  => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.9',
    'ligo_wifi_tx_power'    => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.10',
    'ligo_wifi_bitrate'     => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.11',
    'ligo_wifi_snr'         => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.12',
    'ligo_wifi_max_snr'     => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.13',
    'ligo_wifi_signal'      => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.14',
    'ligo_wifi_noise'       => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.15',
    'ligo_wifi_assoc_count' => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.16',
    # Column 17 is served beyond the published table.
    'ligo_wifi_state'       => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.17',
    # ligoWiRemoteNodeStatsTable, ligoWiRmtNode*; the agent also serves
    # columns 7 to 11, beyond the published table.
    'ligo_peer_mac'         => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.1',
    'ligo_peer_associated'  => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.2',
    'ligo_peer_tx_bytes'    => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.3',
    'ligo_peer_rx_bytes'    => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.4',
    'ligo_peer_signal'      => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.5',
    'ligo_peer_noise'       => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.6',
    'ligo_peer_ip'          => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.7',
    'ligo_peer_remote_port' => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.8',
    'ligo_peer_name'        => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.9',
    'ligo_peer_rx_rate'     => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.10',
    'ligo_peer_tx_rate'     => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.11',
);

%MUNGE = (
    %SNMP::Info::Layer2::MUNGE,
    %SNMP::Info::IEEE802dot11::MUNGE,
    'ligo_wifi_mac' => \&SNMP::Info::munge_mac,
    'ligo_peer_mac' => \&SNMP::Info::munge_mac,
);

sub vendor { return 'ligowave'; }

sub model {
    my $self = shift;
    my $desc = $self->description() || '';
    return $self->SUPER::model() unless $desc =~ /^(LigoDLB\s+.+)$/i;
    my $model = $1;
    $model =~ s/\s+v\d+(?:\.\d+)*\s*$//i;
    return $model;
}

sub os { return 'ligowave os'; }

sub os_ver {
    my $self = shift;
    my $desc = $self->description() || '';
    return $1 if $desc =~ /\bv([\d]+(?:\.[\d]+)*)\b/i;
    return $self->SUPER::os_ver();
}

# ligoWiIfConfTable says INDEX { ifIndex }, but the agent numbers its rows
# otherwise (7 and 10 on captures where ath0 is ifIndex 410). Join each row
# to the athN interface that has the row's MAC address.
sub _ligo_wifi_ifindex {
    my $self     = shift;
    my $wifi_mac = $self->ligo_wifi_mac() || {};
    my $names    = $self->interfaces()    || {};
    my $macs     = $self->i_mac()         || {};

    my @radios = grep { ( $names->{$_} || '' ) =~ /^ath\d+$/ } keys %$names;
    my %ifindex;
    foreach my $row ( keys %$wifi_mac ) {
        my $mac = lc( $wifi_mac->{$row} || '' );
        my @match = grep { lc( $macs->{$_} || '' ) eq $mac } @radios;
        $ifindex{$row} = $match[0] if $mac and @match == 1;
    }
    return \%ifindex;
}

sub _ligo_by_ifindex {
    my ( $self, $column, $partial ) = @_;
    my $values  = $self->$column() || {};
    my $ifindex = $self->_ligo_wifi_ifindex();
    my %by_ifindex;
    foreach my $row ( keys %$ifindex ) {
        next if defined $partial and $ifindex->{$row} ne $partial;
        next unless defined $values->{$row};
        $by_ifindex{ $ifindex->{$row} } = $values->{$row};
    }
    return \%by_ifindex;
}

sub i_ssidlist {
    my ( $self, $partial ) = @_;
    return $self->_ligo_by_ifindex( 'ligo_wifi_essid', $partial );
}

sub i_ssidmac {
    my ( $self, $partial ) = @_;
    return $self->_ligo_by_ifindex( 'ligo_wifi_mac', $partial );
}

# The inherited IEEE802dot11 channel method needs dot11PHYType, which this
# firmware does not serve.
sub i_80211channel {
    my ( $self, $partial ) = @_;
    return $self->_ligo_by_ifindex( 'ligo_wifi_channel', $partial );
}

sub _vlan_interfaces {
    my $self = shift;
    my $names = $self->i_name() || {};
    my $descr = $self->i_description() || {};
    my %interfaces;

    foreach my $ifindex ( keys %$names, keys %$descr ) {
        my $name = $names->{$ifindex} || $descr->{$ifindex} || '';
        my $vlan;
        $vlan = $1 if $name =~ /^(?:eth\d+|ath\d+)\.(\d{1,4})$/i;
        $vlan = $1 if !defined($vlan) && $name =~ /^br(\d{1,4})$/i;
        next unless defined $vlan && $vlan >= 1 && $vlan <= 4094;
        $interfaces{$ifindex} = 0 + $vlan;
    }

    return \%interfaces;
}

# VLANs are represented as logical interfaces by this firmware (for example,
# br99 and eth0.99). They are not switch-port memberships or PVIDs.
sub v_name {
    my $self = shift;
    my $interfaces = $self->_vlan_interfaces();
    my %vlans = map {
        $interfaces->{$_} => 'VLAN ' . $interfaces->{$_}
    } keys %$interfaces;
    return \%vlans;
}

sub v_index {
    my $self = shift;
    my $names = $self->v_name() || {};
    return { map { $_ => $_ } keys %$names };
}

sub i_vlan_membership {
    my $self = shift;
    my $partial = shift;
    my $interfaces = $self->_vlan_interfaces();
    my %membership;
    foreach my $ifindex ( keys %$interfaces ) {
        next if defined($partial) && $ifindex ne $partial;
        $membership{$ifindex} = [ $interfaces->{$ifindex} ];
    }
    return \%membership;
}

sub i_vlan_membership_untagged { return {}; }

1;

__END__

=head1 NAME

SNMP::Info::Layer2::LigoWave - SNMP interface to LigoWave DLB radios

=head1 AUTHOR

SNMP::Info Developers

=head1 SYNOPSIS

 use SNMP::Info;

 my $info = SNMP::Info->new(
     AutoSpecify => 1,
     DestHost    => 'mydevice',
     Community   => 'public',
     Version     => 2,
 );

=head1 DESCRIPTION

Identifies LigoDLB radios, and reports model and firmware from C<sysDescr>.
Reports the SSID and channel on the radio interface, and logical VLAN
interfaces. The tested devices do not serve IP-MIB addresses, BRIDGE-MIB or
Q-BRIDGE-MIB.

=head2 Inherited Classes

=over

=item SNMP::Info::IEEE802dot11

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

None. The F<LIGO-WIRELESS-MIB> and F<LIGO-GENERIC-MIB> objects are read by
numeric OID until those MIBs are in a netdisco-mibs release.

=head2 Inherited MIBs

See L<SNMP::Info::IEEE802dot11/"Required MIBs"> and
L<SNMP::Info::Layer2/"Required MIBs"> for their MIB requirements.

=head1 GLOBALS

These are methods that return scalar values.

=over

=item $ligo->ligo_unit_id()

Returns a unit identifier from the F<LIGO-GENERIC-MIB> subtree, beyond the
published objects. It differs between devices, but the MIB does not call it
a serial number, so C<serial()> does not use it.

=back

=head2 Overrides

=over

=item $ligo->vendor()

Returns C<ligowave>.

=item $ligo->model()

Returns the model name from C<sysDescr>, without the firmware version.

=item $ligo->os()

Returns C<ligowave os>.

=item $ligo->os_ver()

Returns the firmware version from C<sysDescr>.

=back

=head2 Global Methods imported from SNMP::Info::IEEE802dot11

See L<SNMP::Info::IEEE802dot11/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

The firmware represents a VLAN as logical interfaces, such as C<br99>,
C<eth0.99> and C<ath0.99>. These methods report those interfaces, not
switch-port membership.

=over

=item $ligo->v_name()

Returns reference to hash. Key: VLAN ID, Value: C<VLAN> and the ID.

=item $ligo->v_index()

Returns reference to hash. Key: VLAN ID, Value: VLAN ID.

=item $ligo->i_vlan_membership()

Returns reference to hash. Key: ifIndex of a logical VLAN interface, Value:
array reference holding its VLAN ID.

=item $ligo->i_vlan_membership_untagged()

Returns reference to an empty hash: untagged membership is not reported.

=back

=head2 LigoWave Wireless Interface Table (C<ligoWiIfConfTable>)

Keys are the agent's row number, which does not equal the ifIndex.

=over

=item $ligo->ligo_wifi_mac()

Returns reference to hash. Key: row, Value: radio MAC address.

(C<ligoWiIfMacAddress>)

=item $ligo->ligo_wifi_protocol()

Returns reference to hash. Key: row, Value: wireless protocol name.

(C<ligoWiIfProtocol>)

=item $ligo->ligo_wifi_mode()

Returns reference to hash. Key: row, Value: operating mode.

(C<ligoWiIfMode>)

=item $ligo->ligo_wifi_essid()

Returns reference to hash. Key: row, Value: SSID.

(C<ligoWiIfESSID>)

=item $ligo->ligo_wifi_country()

Returns reference to hash. Key: row, Value: regulatory country code.

(C<ligoWiIfCountryCode>)

=item $ligo->ligo_wifi_frequency()

Returns reference to hash. Key: row, Value: frequency in MHz.

(C<ligoWiIfFrequency>)

=item $ligo->ligo_wifi_channel()

Returns reference to hash. Key: row, Value: channel.

(C<ligoWiIfChannel>)

=item $ligo->ligo_wifi_width()

Returns reference to hash. Key: row, Value: channel width.

(C<ligoWiIfChannelBandwidth>)

=item $ligo->ligo_wifi_encryption()

Returns reference to hash. Key: row, Value: encryption mode.

(C<ligoWiIfEncryption>)

=item $ligo->ligo_wifi_tx_power()

Returns reference to hash. Key: row, Value: transmit power.

(C<ligoWiIfTxPower>)

=item $ligo->ligo_wifi_bitrate()

Returns reference to hash. Key: row, Value: bit rate.

(C<ligoWiIfBitRate>)

=item $ligo->ligo_wifi_snr()

Returns reference to hash. Key: row, Value: signal-to-noise ratio.

(C<ligoWiIfSNR>)

=item $ligo->ligo_wifi_max_snr()

Returns reference to hash. Key: row, Value: maximum signal-to-noise ratio.

(C<ligoWiIfMaxSNR>)

=item $ligo->ligo_wifi_signal()

Returns reference to hash. Key: row, Value: signal level in dBm.

(C<ligoWiIfSignalLevel>)

=item $ligo->ligo_wifi_noise()

Returns reference to hash. Key: row, Value: noise level in dBm.

(C<ligoWiIfNoiseLevel>)

=item $ligo->ligo_wifi_assoc_count()

Returns reference to hash. Key: row, Value: number of associated remote nodes.

(C<ligoWiIfAssocNodeCount>)

=item $ligo->ligo_wifi_state()

Returns reference to hash. Key: row, Value: interface state. Column 17,
beyond the published table.

=back

=head2 LigoWave Remote Node Table (C<ligoWiRemoteNodeStatsTable>)

Keys are C<0>, the address length and the remote node's MAC address, as
the agent serves them.

=over

=item $ligo->ligo_peer_mac()

Returns reference to hash. Key: node, Value: remote node MAC address.

(C<ligoWiRmtNodeMacAddress>)

=item $ligo->ligo_peer_associated()

Returns reference to hash. Key: node, Value: association status.

(C<ligoWiRmtNodeAssociated>)

=item $ligo->ligo_peer_tx_bytes()

Returns reference to hash. Key: node, Value: bytes transmitted to the node.

(C<ligoWiRmtNodeTxBytes>)

=item $ligo->ligo_peer_rx_bytes()

Returns reference to hash. Key: node, Value: bytes received from the node.

(C<ligoWiRmtNodeRxBytes>)

=item $ligo->ligo_peer_signal()

Returns reference to hash. Key: node, Value: signal level in dBm.

(C<ligoWiRmtNodeSignalLevel>)

=item $ligo->ligo_peer_noise()

Returns reference to hash. Key: node, Value: noise level in dBm.

(C<ligoWiRmtNodeNoiseLevel>)

=item $ligo->ligo_peer_ip()

Returns reference to hash. Key: node, Value: remote node management address.
Column 7, beyond the published table.

=item $ligo->ligo_peer_remote_port()

Returns reference to hash. Key: node, Value: remote port value.
Column 8, beyond the published table.

=item $ligo->ligo_peer_name()

Returns reference to hash. Key: node, Value: remote node name.
Column 9, beyond the published table.

=item $ligo->ligo_peer_rx_rate()

Returns reference to hash. Key: node, Value: receive rate.
Column 10, beyond the published table.

=item $ligo->ligo_peer_tx_rate()

Returns reference to hash. Key: node, Value: transmit rate.
Column 11, beyond the published table.

=back

=head2 802.11 Interface Table Emulation

These methods emulate the F<IEEE802dot11-MIB> SSID and channel methods using
the F<LIGO-WIRELESS-MIB> C<ligoWiIfConfTable>. Each row is matched to the
C<athN> interface whose C<ifPhysAddress> equals the row's MAC address. A row
that matches no interface, or several, is left out.

=over

=item $ligo->i_ssidlist()

Returns reference to hash. Key: ifIndex, Value: SSID.

(C<ligoWiIfESSID>)

=item $ligo->i_ssidmac()

Returns reference to hash. Key: ifIndex, Value: BSSID.

(C<ligoWiIfMacAddress>)

=item $ligo->i_80211channel()

Returns reference to hash. Key: ifIndex, Value: channel.

(C<ligoWiIfChannel>)

=back

=head2 Table Methods imported from SNMP::Info::IEEE802dot11

See L<SNMP::Info::IEEE802dot11/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=cut
