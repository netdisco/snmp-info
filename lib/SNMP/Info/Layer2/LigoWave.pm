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

$VERSION = '3.982000';

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
    %SNMP::Info::IEEE802dot11::MIBS,
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
    %SNMP::Info::IEEE802dot11::GLOBALS,
    'ligo_unit_id' => '.1.3.6.1.4.1.32750.3.1.1.1.0.1.2.0',
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
    %SNMP::Info::IEEE802dot11::FUNCS,
    # The LigoWave private MIB is not included in netdisco-mibs. Keep these
    # documented table columns numeric until that MIB is available there.
    'ligo_wifi_mac'         => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.1',
    'ligo_wifi_protocol'    => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.2',
    'ligo_wifi_mode'        => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.3',
    'ligo_wifi_essid'       => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.4',
    'ligo_wifi_country'     => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.5',
    'ligo_wifi_frequency'   => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.6',
    'ligo_wifi_channel'     => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.7',
    'ligo_wifi_width'       => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.8',
    'ligo_wifi_tx_streams'  => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.9',
    'ligo_wifi_tx_power'    => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.10',
    'ligo_wifi_bitrate'     => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.11',
    'ligo_wifi_snr'         => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.12',
    'ligo_wifi_quality'     => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.13',
    'ligo_wifi_signal'      => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.14',
    'ligo_wifi_noise'       => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.15',
    'ligo_wifi_status'      => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.16',
    'ligo_wifi_state'       => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.17',
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

=head2 Inherited Classes

=over

=item SNMP::Info::IEEE802dot11

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

No additional MIBs are required. LigoWave tables are read by numeric OID
while their vendor MIB contribution is pending in netdisco-mibs.

=head2 Inherited MIBs

See L<SNMP::Info::IEEE802dot11/Required MIBs> and
L<SNMP::Info::Layer2/Required MIBs> for inherited MIB requirements.

=head1 DESCRIPTION

Identifies LigoDLB devices and parses the model and firmware version from
C<sysDescr>. Exposes the wireless-interface and remote-node columns provided
under the LigoWave enterprise MIB.

On tested firmware, VLAN 99 appears as logical interfaces named C<br99>,
C<eth0.99>, and C<ath0.99>. VLAN methods report these logical interfaces;
they do not imply switch-port VLAN membership. The tested devices do not
implement the standard IP address or bridge VLAN tables.

The C<ligo_unit_id> scalar is distinct on the tested devices, but the published
vendor MIB does not identify it as a serial number, so it is not returned by
C<serial()>.

=head1 METHODS

=head2 Device identity

=over 4

=item $ligo->vendor()

Returns C<ligowave>.

=item $ligo->model()

Returns the model name parsed from C<sysDescr>, without the firmware version.

=item $ligo->os()

Returns C<ligowave os>.

=item $ligo->os_ver()

Returns the firmware version parsed from C<sysDescr>.

=back

=head2 Wireless and peer tables

The following methods return hash references keyed by the LigoWave table
instance. Wireless values describe the local radio. Peer values describe its
associated remote radio.

=over 4

=item ligo_wifi_mac()

Radio MAC address.

=item ligo_wifi_protocol()

Wireless protocol name.

=item ligo_wifi_mode()

Wireless operating mode code.

=item ligo_wifi_essid()

Configured wireless network name.

=item ligo_wifi_country()

Configured regulatory country code.

=item ligo_wifi_frequency()

Radio frequency in MHz.

=item ligo_wifi_channel()

Configured wireless channel.

=item ligo_wifi_width()

Configured channel width in MHz.

=item ligo_wifi_tx_streams()

Number of transmit streams.

=item ligo_wifi_tx_power()

Transmit power reported by the radio.

=item ligo_wifi_bitrate()

Wireless bitrate reported by the radio.

=item ligo_wifi_snr()

Signal-to-noise ratio reported by the radio.

=item ligo_wifi_quality()

Wireless link quality value reported by the radio.

=item ligo_wifi_signal()

Received signal level in dBm.

=item ligo_wifi_noise()

Noise level in dBm.

=item ligo_wifi_status()

Numeric wireless interface status.

=item ligo_wifi_state()

Text wireless interface state.

=item ligo_peer_mac()

Associated peer MAC address.

=item ligo_peer_associated()

Peer association status.

=item ligo_peer_tx_bytes()

Bytes transmitted to the peer.

=item ligo_peer_rx_bytes()

Bytes received from the peer.

=item ligo_peer_signal()

Signal level reported for the peer link in dBm.

=item ligo_peer_noise()

Noise level reported for the peer link in dBm.

=item ligo_peer_ip()

Peer management address.

=item ligo_peer_remote_port()

Remote port value reported by the peer table.

=item ligo_peer_name()

Peer name.

=item ligo_peer_rx_rate()

Receive rate reported for the peer link.

=item ligo_peer_tx_rate()

Transmit rate reported for the peer link.

=back

=head2 VLAN methods

=over 4

=item $ligo->v_name()

Returns VLAN IDs and labels inferred from logical interface names such as
C<br99> and C<eth0.99>.

=item $ligo->v_index()

Returns the VLAN IDs as both keys and values.

=item $ligo->i_vlan_membership()

Associates each recognized logical VLAN interface with its VLAN ID.

=item $ligo->i_vlan_membership_untagged()

Returns an empty hash reference because untagged membership is not reported.

=back

=cut
