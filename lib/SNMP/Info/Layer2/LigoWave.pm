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

$VERSION = '3.981001';

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
);

%MUNGE = (
    %SNMP::Info::Layer2::MUNGE,
    %SNMP::Info::IEEE802dot11::MUNGE,
    'ligo_wifi_mac' => \&SNMP::Info::munge_mac,
    'ligo_peer_mac' => \&SNMP::Info::munge_mac,
);

# Walk numeric vendor table columns directly. SNMP::Info's normal table
# walker needs a loaded MIB leaf name, while Netdisco's MIB bundle does not
# include the LigoWave MIBs. Keep the raw OID walk independent of that bundle.
sub _ligo_column {
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
            $self->error_throw("LigoWave table walk failed for $attr");
            return;
        }

        my $name = $var->[0];
        last unless defined $name;
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

my %LIGO_COLUMNS = (
    ligo_wifi_mac       => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.1',
    ligo_wifi_protocol  => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.2',
    ligo_wifi_mode      => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.3',
    ligo_wifi_essid     => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.4',
    ligo_wifi_country   => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.5',
    ligo_wifi_frequency => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.6',
    ligo_wifi_channel   => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.7',
    ligo_wifi_width     => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.8',
    ligo_wifi_tx_streams => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.9',
    ligo_wifi_tx_power  => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.10',
    ligo_wifi_bitrate   => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.11',
    ligo_wifi_snr       => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.12',
    ligo_wifi_quality   => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.13',
    ligo_wifi_signal    => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.14',
    ligo_wifi_noise     => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.15',
    ligo_wifi_status    => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.16',
    ligo_wifi_state     => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.17',
    ligo_peer_mac       => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.1',
    ligo_peer_associated => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.2',
    ligo_peer_tx_bytes  => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.3',
    ligo_peer_rx_bytes  => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.4',
    ligo_peer_signal    => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.5',
    ligo_peer_noise     => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.6',
    ligo_peer_ip        => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.7',
    ligo_peer_remote_port => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.8',
    ligo_peer_name      => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.9',
    ligo_peer_rx_rate   => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.10',
    ligo_peer_tx_rate   => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.11',
);

{
    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    foreach my $attr ( keys %LIGO_COLUMNS ) {
        my $method = $attr;
        my $column = $LIGO_COLUMNS{$method};
        *{$method} = sub { return _ligo_column( $_[0], $method, $column ); };
    }
}

sub vendor { return 'ligowave'; }

sub model {
    my $self = shift;
    my $desc = $self->description() || '';
    return unless $desc =~ /^(LigoDLB\s+.+)$/i;
    my $model = $1;
    $model =~ s/\s+v\d+(?:\.\d+)*\s*$//i;
    return $model;
}

sub os { return 'LigoWave OS'; }

sub os_ver {
    my $self = shift;
    my $desc = $self->description() || '';
    return $1 if $desc =~ /\bv([\d]+(?:\.[\d]+)*)\b/i;
    return;
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

# The management address used by Netdisco is the one address we can report
# reliably on every tested radio. LigoWave's agent omits IP-MIB, so associate
# that known address with br0 when the interface is present. The agent does
# not publish a prefix length, so ip_netmask() intentionally has no entry.
sub _management_ip {
    my $self = shift;
    my $args = $self->args() || {};
    my $ip = $args->{DestHost} || '';
    return unless $ip =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;
    return if grep { $_ > 255 } ($1, $2, $3, $4);
    return if $ip eq '0.0.0.0' or $ip eq '255.255.255.255';
    return $ip;
}

sub _management_ifindex {
    my $self = shift;
    my $names = $self->i_name() || {};
    my $descr = $self->i_description() || {};
    foreach my $ifindex ( keys %$names, keys %$descr ) {
        my $name = $names->{$ifindex} || $descr->{$ifindex} || '';
        return $ifindex if $name =~ /^br0$/i;
    }
    return 0;
}

sub ip_index {
    my $self = shift;
    my %indices = %{ $self->SUPER::ip_index() || {} };
    my $ip = $self->_management_ip();
    $indices{$ip} = $self->_management_ifindex()
        if defined $ip and not exists $indices{$ip};
    return \%indices;
}

sub ip_table {
    my $self = shift;
    my %addresses = %{ $self->SUPER::ip_table() || {} };
    my $ip = $self->_management_ip();
    $addresses{$ip} = $ip if defined $ip and not exists $addresses{$ip};
    return \%addresses;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer2::LigoWave - SNMP interface to LigoWave DLB radios

=head1 DESCRIPTION

Identifies LigoDLB devices and parses the model and firmware version from
C<sysDescr>. Exposes the wireless-interface and remote-node columns provided
under the LigoWave enterprise MIB.

On tested firmware, VLAN 99 appears as logical interfaces named C<br99>,
C<eth0.99>, and C<ath0.99>. VLAN methods report these logical interfaces;
they do not imply switch-port VLAN membership. The tested devices do not
implement the standard IP address or bridge VLAN tables.

The management address used for SNMP discovery is reported as an address on
C<br0> when that interface is present. No subnet is reported because the
tested firmware does not expose an address prefix or netmask.

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

Returns C<LigoWave OS>.

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

=head2 VLAN and address methods

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

=item $ligo->ip_index()

Returns IP addresses and interface indexes. When IP-MIB is unavailable, the
discovery address is associated with C<br0> if that interface is present.

=item $ligo->ip_table()

Returns the IP address table, including the discovery address when IP-MIB is
unavailable.

=back

=cut
