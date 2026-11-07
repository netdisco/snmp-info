# SNMP::Info::Layer3::ArubaInstant
#
# Copyright (c) 2013 Eric Miller
# Copyright (c) 2026 Muris
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

package SNMP::Info::Layer3::ArubaInstant;

use strict;
use warnings;
use SNMP::Info::Layer3::Aruba;

our @ISA = qw/SNMP::Info::Layer3::Aruba/;
our ($VERSION, %MIBS, %GLOBALS, %FUNCS, %MUNGE);
$VERSION = '3.985002';

%MIBS = (%SNMP::Info::Layer3::Aruba::MIBS,
    'AI-AP-MIB' => 'aiWlanESSID');
%GLOBALS = (%SNMP::Info::Layer3::Aruba::GLOBALS);
%FUNCS = (%SNMP::Info::Layer3::Aruba::FUNCS,
    'instant_radio_channel' => 'aiRadioChannel',
    'instant_radio_power'   => 'aiRadioTransmitPower',
    'instant_radio_mac'     => 'aiRadioMACAddress',
    'instant_radio_status'  => 'aiRadioStatus',
    'instant_wlan_ssid'   => 'aiWlanESSID',
    'instant_wlan_mac'    => 'aiWlanMACAddress',
    'instant_ap_name'     => 'aiAPName',
    'instant_ap_status'   => 'aiAPStatus',
    'instant_ssid'        => 'aiSSID',
    'instant_ssid_hide'   => 'aiSSIDHide',
    'instant_client_mac'  => 'aiClientMACAddress',
    'instant_client_bssid'=> 'aiClientWlanMACAddress',
    'instant_client_snr'      => 'aiClientSNR',
    'instant_client_txrate'   => 'aiClientTxRate',
    'instant_client_uptime'   => 'aiClientUptime',
    'instant_client_txbytes'  => 'aiClientTxDataBytes',
    'instant_client_rxbytes'  => 'aiClientRxDataBytes',
    'instant_client_txframes' => 'aiClientTxDataFrames',
    'instant_client_rxframes' => 'aiClientRxDataFrames',
);
%MUNGE = (%SNMP::Info::Layer3::Aruba::MUNGE,
    'instant_radio_mac' => \&SNMP::Info::munge_mac,
    'instant_wlan_mac'     => \&SNMP::Info::munge_mac,
    'instant_client_mac'   => \&SNMP::Info::munge_mac,
    'instant_client_bssid' => \&SNMP::Info::munge_mac,
    'instant_wlan_ssid'    => \&SNMP::Info::munge_null,
    'instant_ssid'         => \&SNMP::Info::munge_null,
);

# WLANs with a usable BSSID. They are not ports: each is mapped to the radio
# that serves it (_wlan_radios).
sub _wlans {
    my ($self, $partial) = @_;
    my $macs = $self->instant_wlan_mac($partial) || {};
    my %wlans;
    foreach my $iid (keys %$macs) {
        next unless $iid =~ /^(\d+(?:\.\d+){5})\.(\d+)$/;
        my ($ap, $number) = ($1, $2);
        my $mac = $macs->{$iid};
        next unless defined $mac && $mac =~ /^(?:[0-9a-f]{2}:){5}[0-9a-f]{2}$/i;
        next if $mac eq '00:00:00:00:00:00';
        $wlans{$iid} = {ap => $ap, number => $number, mac => lc $mac};
    }
    return \%wlans;
}

# One port per radio. The trailing .0 keeps the keys radio ports had when
# WLANs were ports too, and leaves room for the WLAN number in i_ssidlist.
sub _radios {
    my ($self, $partial) = @_;
    my $channels = $self->instant_radio_channel() || {};
    my $macs = $self->instant_radio_mac() || {};
    my %radios;
    # A radio missing from one column (a failed walk) keeps its port.
    foreach my $iid (keys %{ {%$channels, %$macs} }) {
        next unless $iid =~ /^(\d+(?:\.\d+){5})\.(\d+)$/;
        my ($ap, $number) = ($1, $2);
        my $mac = $macs->{$iid};
        $mac = undef unless defined $mac && $mac =~ /^(?:[0-9a-f]{2}:){5}[0-9a-f]{2}$/i;
        my $logical = "$iid.0";
        next if defined $partial && length $partial
            && $logical ne $partial && index($logical, "$partial.") != 0;
        $radios{$logical} = {ap => $ap, number => $number,
            source => $iid, kind => 'radio', mac => $mac};
    }
    return \%radios;
}

# BSSIDs count up from their radio's MAC (16 per radio on current APs, 8
# on older ones), so each radio owns the addresses from its MAC up to the
# next radio's MAC on the same AP. The highest radio owns a range as wide
# as the gap below it, or 16 on a single-radio AP. A WLAN no range holds is
# left out, not guessed. A radio with no MAC may sit inside any other
# radio's range, so on its AP each radio keeps only the 8 addresses no
# other radio can start within.
sub _wlan_radios {
    my $self   = shift;
    my $wlans  = $self->_wlans();
    my $radios = $self->_radios();
    my (%by_ap, %unbounded);
    foreach my $iid (keys %$radios) {
        my $radio = $radios->{$iid};
        $unbounded{ $radio->{ap} } = 1 unless defined $radio->{mac};
        next unless defined $radio->{mac};
        push @{ $by_ap{ $radio->{ap} } }, [_mac_number($radio->{mac}), $iid];
    }
    my %ranges;
    foreach my $ap (keys %by_ap) {
        my @sorted = sort { $a->[0] <=> $b->[0] || $a->[1] cmp $b->[1] }
            @{ $by_ap{$ap} };
        foreach my $i (0 .. $#sorted) {
            my ($start, $iid) = @{ $sorted[$i] };
            my $gap = $i > 0 ? $start - $sorted[$i - 1][0] : 0;
            my $end = $i < $#sorted ? $sorted[$i + 1][0]
                : $start + ($gap > 0 ? $gap : 16);
            $end = $start + 8 if $unbounded{$ap} && $end > $start + 8;
            push @{ $ranges{$ap} }, [$start, $end, $iid];
        }
    }
    my %radio_of;
    foreach my $iid (keys %$wlans) {
        my $bssid = _mac_number($wlans->{$iid}{mac});
        my ($range) = grep { $_->[0] <= $bssid && $bssid < $_->[1] }
            @{ $ranges{ $wlans->{$iid}{ap} } || [] };
        $radio_of{$iid} = $range->[2] if $range;
    }
    return \%radio_of;
}

sub _mac_number {
    (my $mac = shift) =~ s/://g;
    no warnings 'portable';
    return hex $mac;
}

sub _in_partial {
    my ($key, $partial) = @_;
    return 1 unless defined $partial && length $partial;
    return $key eq $partial || index($key, "$partial.") == 0;
}

sub _augment {
    my ($self, $physical, $field, $partial) = @_;
    my %result = %{ $physical || {} };
    my $radios = $self->_radios($partial);
    my $radio_status = $self->instant_radio_status() || {};
    my $channels = $self->instant_radio_channel() || {};
    my $names = $self->instant_ap_name() || {};
    foreach my $iid (keys %$radios) {
        my $radio = $radios->{$iid};
        my $ap_mac = join ':', map {sprintf '%02x', $_} split /\./, $radio->{ap};
        my $name = "$ap_mac.radio$radio->{number}";
        if ($field eq 'index') { $result{$iid} = $name }
        elsif ($field eq 'name') { $result{$iid} = $name }
        elsif ($field eq 'description') {
            $result{$iid} = join ': ', $names->{$radio->{ap}} || $ap_mac,
                "Radio $radio->{number} (channel "
                . ($channels->{$radio->{source}} // '') . ')';
        }
        elsif ($field eq 'type') { $result{$iid} = 'ieee80211' }
        elsif ($field eq 'mac') {
            if (defined $radio->{mac}) { $result{$iid} = $radio->{mac} }
            else { delete $result{$iid} }
        }
        elsif ($field eq 'up') {
            my $value = $radio_status->{$radio->{source}};
            $result{$iid} = ($value eq '1' ? 'up' : $value eq '2' ? 'down' : $value)
                if defined $value;
        }
    }
    return \%result;
}

sub i_index {
    my ($self, $partial) = @_;
    return $self->_augment($self->SUPER::i_index($partial), 'index', $partial);
}

sub interfaces {
    my ($self, $partial) = @_;
    return $self->_augment($self->SUPER::interfaces($partial), 'name', $partial);
}

sub i_name {
    my ($self, $partial) = @_;
    return $self->_augment($self->SUPER::i_name($partial), 'name', $partial);
}

sub i_description {
    my ($self, $partial) = @_;
    return $self->_augment($self->SUPER::i_description($partial), 'description', $partial);
}

sub i_type {
    my ($self, $partial) = @_;
    return $self->_augment($self->SUPER::i_type($partial), 'type', $partial);
}

sub i_mac {
    my ($self, $partial) = @_;
    return $self->_augment($self->SUPER::i_mac($partial), 'mac', $partial);
}

sub i_up {
    my ($self, $partial) = @_;
    return $self->_augment($self->SUPER::i_up($partial), 'up', $partial);
}

sub i_up_admin {
    my ($self, $partial) = @_;
    return $self->_augment($self->SUPER::i_up_admin($partial), 'up', $partial);
}

# Keyed radio port, then WLAN number: callers drop the last component to
# find the port, so every SSID a radio serves lands on that radio.
sub _ssid_rows {
    my ($self, $partial) = @_;
    my $wlans    = $self->_wlans();
    my $radio_of = $self->_wlan_radios();
    my %rows;
    foreach my $iid (keys %$radio_of) {
        my $key = "$radio_of->{$iid}.$wlans->{$iid}{number}";
        $rows{$key} = $iid if _in_partial($key, $partial);
    }
    return \%rows;
}

sub i_ssidlist {
    my ($self, $partial) = @_;
    my $ssids = $self->instant_wlan_ssid() || {};
    my $rows  = $self->_ssid_rows($partial);
    return {map { ($_ => $ssids->{ $rows->{$_} }) }
        grep {defined $ssids->{ $rows->{$_} }} keys %$rows};
}

sub i_ssidmac {
    my ($self, $partial) = @_;
    my $wlans = $self->_wlans();
    my $rows  = $self->_ssid_rows($partial);
    return {map { ($_ => $wlans->{ $rows->{$_} }{mac}) } keys %$rows};
}

sub i_ssidbcast {
    my ($self, $partial) = @_;
    my $ssids = $self->instant_ssid() || {};
    my $hide = $self->instant_ssid_hide() || {};
    my %broadcast;
    foreach my $idx (keys %$ssids) {
        next unless defined $ssids->{$idx} && defined $hide->{$idx};
        next unless $hide->{$idx} =~ /^(?:enable|disable|0|1)$/;
        $broadcast{$ssids->{$idx}} = ($hide->{$idx} eq 'enable' || $hide->{$idx} eq '1') ? 0 : 1;
    }
    my $wlans = $self->i_ssidlist($partial);
    return {map { ($_ => $broadcast{$wlans->{$_}}) }
        grep {exists $broadcast{$wlans->{$_}}} keys %$wlans};
}

sub i_80211channel {
    my ($self, $partial) = @_;
    my $channels = $self->instant_radio_channel() || {};
    my $radios = $self->_radios($partial);
    my %result;
    foreach my $iid (keys %$radios) {
        my $value = $channels->{$radios->{$iid}{source}};
        next unless defined $value && $value =~ /^(\d+)(?:[+-]|[ES])?$/i;
        $result{$iid} = 0 + $1 if $1 > 0;
    }
    return \%result;
}

sub dot11_cur_tx_pwr_mw {
    my ($self, $partial) = @_;
    my $power = $self->instant_radio_power() || {};
    my $radios = $self->_radios($partial);
    my %result;
    foreach my $iid (keys %$radios) {
        my $value = $power->{$radios->{$iid}{source}};
        next unless defined $value && $value =~ /^-?\d+$/;
        # AI-AP-MIB power is treated as dBm by LibreNMS's Aruba Instant
        # implementation. Netdisco stores integer milliwatts.
        $result{$iid} = int(10 ** ($value / 10) + 0.5);
    }
    return \%result;
}

sub bp_index {
    my ($self, $partial) = @_;
    my %index = %{ $self->SUPER::bp_index($partial) || {} };
    my $wlans    = $self->_wlans();
    my $radio_of = $self->_wlan_radios();
    foreach my $iid (keys %$radio_of) {
        $index{ $wlans->{$iid}{mac} } = $radio_of->{$iid};
    }
    return \%index;
}

# aiClientTable is indexed by the client MAC, so the MAC comes from the
# index of the BSSID column rather than a second walk of aiClientMACAddress.
sub _clients {
    my ($self, $partial) = @_;
    my $bssids = $self->instant_client_bssid($partial) || {};
    my $wlans = $self->_wlans();
    my %known = map { ($wlans->{$_}{mac} => 1) } keys %{ $self->_wlan_radios() };
    my %clients;
    foreach my $iid (keys %$bssids) {
        my @octets = split /\./, $iid;
        next unless @octets == 6 && !grep { !/^\d+$/ || $_ > 255 } @octets;
        my $bssid = $bssids->{$iid};
        next unless defined $bssid && $known{lc $bssid};
        $clients{$iid} = {mac => join(':', map { sprintf '%02x', $_ } @octets),
            bssid => lc $bssid};
    }
    return \%clients;
}

sub fw_mac {
    my ($self, $partial) = @_;
    my %macs = %{ $self->SUPER::fw_mac($partial) || {} };
    my $clients = $self->_clients($partial);
    $macs{"instant.$_"} = $clients->{$_}{mac} foreach keys %$clients;
    return \%macs;
}

sub fw_port {
    my ($self, $partial) = @_;
    my %ports = %{ $self->SUPER::fw_port($partial) || {} };
    my $clients = $self->_clients($partial);
    $ports{"instant.$_"} = $clients->{$_}{bssid} foreach keys %$clients;
    return \%ports;
}

# One aiClientTable column for the clients _clients places on a radio.
sub _client_column {
    my ($self, $method) = @_;
    my $clients = $self->_clients();
    my $values  = $self->$method() || {};
    return {map { ($_ => $values->{$_}) }
        grep {defined $values->{$_}} keys %$clients};
}

sub cd11_mac {
    my $self    = shift;
    my $clients = $self->_clients();
    return {map { ($_ => $clients->{$_}{mac}) } keys %$clients};
}

sub cd11_ssid {
    my $self    = shift;
    my $clients = $self->_clients();
    my $wlans   = $self->_wlans();
    my $ssids   = $self->instant_wlan_ssid() || {};
    my %ssid_of = map { ($wlans->{$_}{mac} => $ssids->{$_}) }
        grep {defined $ssids->{$_}} keys %{ $self->_wlan_radios() };
    return {map { ($_ => $ssid_of{ $clients->{$_}{bssid} }) }
        grep {defined $ssid_of{ $clients->{$_}{bssid} }} keys %$clients};
}

sub cd11_txrate {
    my $self  = shift;
    my $rates = $self->_client_column('instant_client_txrate');
    return {map { ($_ => [$rates->{$_}]) } keys %$rates};
}

sub cd11_sigqual { return shift->_client_column('instant_client_snr') }

# AI-AP-MIB reports no RSSI; the inherited leaf is a controller table.
sub cd11_sigstrength { return {} }

sub cd11_uptime { return shift->_client_column('instant_client_uptime') }
sub cd11_txbyte { return shift->_client_column('instant_client_txbytes') }
sub cd11_rxbyte { return shift->_client_column('instant_client_rxbytes') }
sub cd11_txpkt  { return shift->_client_column('instant_client_txframes') }
sub cd11_rxpkt  { return shift->_client_column('instant_client_rxframes') }

1;
__END__

=head1 NAME

SNMP::Info::Layer3::ArubaInstant - SNMP Interface to Aruba Instant access points

=head1 DESCRIPTION

Support for Aruba Instant 8.x wireless networks using C<AI-AP-MIB>.
Inherits physical interface and system information from
L<SNMP::Info::Layer3::Aruba>. ArubaOS 10 is not validated by this class.

=head2 Required MIBs

=over

=item AI-AP-MIB

=item Inherited MIBs from L<SNMP::Info::Layer3::Aruba>

=back

=head2 Interfaces and wireless networks

C<i_index>, C<interfaces>, C<i_name>, C<i_description>, C<i_type>, C<i_mac>,
C<i_up> and C<i_up_admin> preserve physical interfaces and add one port per
AP radio, named after the AP MAC address and radio number. A radio port's
index is the AP and radio index with a trailing C<.0>. Radio status comes
from the radio table.

C<i_ssidlist>, C<i_ssidmac> and C<i_ssidbcast> expose each WLAN's name,
BSSID and broadcast flag on the radio that serves it, keyed by the radio
port index and the WLAN number. A WLAN's BSSID counts up from its radio's
MAC address, so each radio owns the addresses from its MAC address up to
the next radio's MAC address on the same AP. The highest radio owns a range
as wide as the gap below it, or 16 addresses on a single-radio AP. A WLAN
no range holds is omitted. When a radio on the AP reports no MAC address,
its addresses could lie in any other radio's range, so each radio on that
AP keeps only the 8 addresses from its own MAC address, the fewest Aruba
assigns a radio.

=head2 Radio channel and power

C<i_80211channel> exposes the numeric channel for each separate radio
interface. Channel suffixes such as C<+>, C<E> and C<S> remain in the radio
interface description. C<dot11_cur_tx_pwr_mw> converts radio power from dBm
to integer milliwatts, rounding to the nearest milliwatt. The dBm interpretation
follows the L<LibreNMS Aruba Instant implementation|https://github.com/librenms/librenms/blob/master/LibreNMS/OS/ArubaInstant.php>.

=head2 Wireless clients

C<fw_mac>, C<fw_port> and C<bp_index> map associated clients onto the radio
port that serves their BSSID, preserving wired forwarding entries. Clients
whose BSSID belongs to no radio are omitted. Q-BRIDGE ports, which this
agent numbers by ifIndex without a C<dot1dBasePortTable>, are not mapped.

=head2 Aruba Instant Tables (F<AI-AP-MIB>)

These methods return the C<AI-AP-MIB> columns the class reads.

=over

=item instant_radio_channel

Returns reference to hash. Key: AP MAC and radio index, Value: channel, with any C<+>, C<->, C<E> or C<S> suffix.

(C<aiRadioChannel>)

=item instant_radio_power

Returns reference to hash. Key: AP MAC and radio index, Value: transmit power.

(C<aiRadioTransmitPower>)

=item instant_radio_mac

Returns reference to hash. Key: AP MAC and radio index, Value: radio MAC address.

(C<aiRadioMACAddress>)

=item instant_radio_status

Returns reference to hash. Key: AP MAC and radio index, Value: radio state.

(C<aiRadioStatus>)

=item instant_wlan_ssid

Returns reference to hash. Key: AP MAC and WLAN index, Value: ESSID.

(C<aiWlanESSID>)

=item instant_wlan_mac

Returns reference to hash. Key: AP MAC and WLAN index, Value: BSSID.

(C<aiWlanMACAddress>)

=item instant_ap_name

Returns reference to hash. Key: AP MAC, Value: AP name.

(C<aiAPName>)

=item instant_ap_status

Returns reference to hash. Key: AP MAC, Value: AP status.

(C<aiAPStatus>)

=item instant_ssid

Returns reference to hash. Key: SSID index, Value: SSID.

(C<aiSSID>)

=item instant_ssid_hide

Returns reference to hash. Key: SSID index, Value: whether the SSID is hidden.

(C<aiSSIDHide>)

=item instant_client_mac

Returns reference to hash. Key: client MAC, Value: client MAC address.

(C<aiClientMACAddress>)

=item instant_client_bssid

Returns reference to hash. Key: client MAC, Value: BSSID the client is associated with.

(C<aiClientWlanMACAddress>)

=item instant_client_snr

Returns reference to hash. Key: client MAC, Value: signal to noise ratio.

(C<aiClientSNR>)

=item instant_client_txrate

Returns reference to hash. Key: client MAC, Value: transmit rate in Mbps.

(C<aiClientTxRate>)

=item instant_client_uptime

Returns reference to hash. Key: client MAC, Value: uptime since the last mobility event.

(C<aiClientUptime>)

=item instant_client_txbytes

Returns reference to hash. Key: client MAC, Value: bytes transmitted.

(C<aiClientTxDataBytes>)

=item instant_client_rxbytes

Returns reference to hash. Key: client MAC, Value: bytes received.

(C<aiClientRxDataBytes>)

=item instant_client_txframes

Returns reference to hash. Key: client MAC, Value: frames transmitted.

(C<aiClientTxDataFrames>)

=item instant_client_rxframes

Returns reference to hash. Key: client MAC, Value: frames received.

(C<aiClientRxDataFrames>)

=back

=head2 Interface methods

=over

=item i_index

Returns physical indexes and synthetic radio identifiers.

=item interfaces

Returns physical port names and stable radio names.

=item i_name

Returns the same stable radio names alongside physical interface names.

=item i_description

Returns the AP name, radio number and raw channel for each radio.

=item i_type

Returns C<ieee80211> for radio interfaces.

=item i_mac

Returns the radio MAC address, when available, for each radio.

=item i_up

Returns radio status for radio interfaces.

=item i_up_admin

Returns radio operational status for radio interfaces; separate
administrative status is not available from these tables.

=item i_ssidlist

Returns SSID names indexed by radio port and WLAN number.

=item i_ssidmac

Returns BSSIDs using the same indexes as C<i_ssidlist>.

=item i_ssidbcast

Returns broadcast flags from the SSID hide setting, when available.

=item i_80211channel

Returns numeric channels indexed by synthetic radio interface.

=item dot11_cur_tx_pwr_mw

Returns radio transmit power converted from dBm to integer milliwatts.

=item bp_index

Adds BSSID to radio port mappings to physical bridge mappings.

=item fw_mac

Adds associated wireless client MAC addresses to wired forwarding entries.

=item fw_port

Maps associated clients to BSSIDs, which C<bp_index> maps to radio ports.

=back

=head2 Wireless Client Table Emulation

These methods emulate the F<CISCO-DOT11-ASSOCIATION-MIB> C<cd11_*> methods
using the F<AI-AP-MIB> C<aiClientTable>. Keys are the client table index,
the client MAC address. Only clients whose BSSID belongs to a radio are
returned.

=over

=item cd11_mac

Returns the client MAC address, decoded from the client table's index, so
C<aiClientMACAddress> is not walked.

=item cd11_ssid

Returns the SSID of the WLAN whose BSSID the client is associated with.

(C<aiClientWlanMACAddress>, C<aiWlanESSID>)

=item cd11_txrate

Returns reference to an array holding the client transmit rate in Mbps.

(C<aiClientTxRate>)

=item cd11_sigqual

Returns the client signal to noise ratio.

(C<aiClientSNR>)

=item cd11_sigstrength

Returns an empty hash: F<AI-AP-MIB> reports no client RSSI.

=item cd11_uptime

Returns the client uptime, reset on each mobility event.

(C<aiClientUptime>)

=item cd11_txbyte

Returns bytes transmitted by the client.

(C<aiClientTxDataBytes>)

=item cd11_rxbyte

Returns bytes received by the client.

(C<aiClientRxDataBytes>)

=item cd11_txpkt

Returns frames transmitted by the client.

(C<aiClientTxDataFrames>)

=item cd11_rxpkt

Returns frames received by the client.

(C<aiClientRxDataFrames>)

=back

=cut
