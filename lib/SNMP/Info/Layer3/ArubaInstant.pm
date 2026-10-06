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
$VERSION = '3.978000';

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
);
%MUNGE = (%SNMP::Info::Layer3::Aruba::MUNGE,
    'instant_radio_mac' => \&SNMP::Info::munge_mac,
    'instant_wlan_mac'     => \&SNMP::Info::munge_mac,
    'instant_client_mac'   => \&SNMP::Info::munge_mac,
    'instant_client_bssid' => \&SNMP::Info::munge_mac,
    'instant_wlan_ssid'    => \&SNMP::Info::munge_null,
    'instant_ssid'         => \&SNMP::Info::munge_null,
);

# Use one logical port per AP/WLAN, preserving all physical interfaces.
# Only advertise entries with a BSSID, so both discovery and macsuck can join.
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

# Radio indexes overlap WLAN indexes. Append a component for a separate
# synthetic interface namespace; do not infer a WLAN-to-radio relationship.
sub _radios {
    my ($self, $partial) = @_;
    my $channels = $self->instant_radio_channel() || {};
    my $macs = $self->instant_radio_mac() || {};
    my %radios;
    foreach my $iid (keys %$channels) {
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

sub _augment {
    my ($self, $physical, $field, $partial) = @_;
    my %result = %{ $physical || {} };
    my $wlans = {%{$self->_wlans($partial)}, %{$self->_radios($partial)}};
    my $radio_status = $self->instant_radio_status() || {};
    my $channels = $self->instant_radio_channel() || {};
    my $names = $self->instant_ap_name() || {};
    my $ssids = $self->instant_wlan_ssid($partial) || {};
    my $status = $self->instant_ap_status() || {};
    foreach my $iid (keys %$wlans) {
        my $wlan = $wlans->{$iid};
        my $ap_mac = join ':', map {sprintf '%02x', $_} split /\./, $wlan->{ap};
        my $radio = ($wlan->{kind} || '') eq 'radio';
        my $name = $ap_mac . ($radio ? '.radio' : '.wlan') . $wlan->{number};
        if ($field eq 'index') { $result{$iid} = $name }
        elsif ($field eq 'name') { $result{$iid} = $name }
        elsif ($field eq 'description') {
            $result{$iid} = join ': ', $names->{$wlan->{ap}} || $ap_mac,
                ($radio ? "Radio $wlan->{number} (channel " . ($channels->{$wlan->{source}} // '') . ')'
                    : $ssids->{$iid} // "WLAN $wlan->{number}");
        }
        elsif ($field eq 'type') { $result{$iid} = 'ieee80211' }
        elsif ($field eq 'mac') {
            if (defined $wlan->{mac}) { $result{$iid} = $wlan->{mac} }
            else { delete $result{$iid} }
        }
        elsif ($field eq 'up') {
            my $value = $radio ? $radio_status->{$wlan->{source}} : $status->{$wlan->{ap}};
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

sub i_ssidlist {
    my ($self, $partial) = @_;
    my $ssids = $self->instant_wlan_ssid($partial) || {};
    my $wlans = $self->_wlans($partial);
    return {map { ("$_.0" => $ssids->{$_}) }
        grep {defined $ssids->{$_}} keys %$wlans};
}

sub i_ssidmac {
    my ($self, $partial) = @_;
    my $wlans = $self->_wlans($partial);
    return {map { ("$_.0" => $wlans->{$_}{mac}) } keys %$wlans};
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
    my $wlans = $self->_wlans();
    foreach my $iid (keys %$wlans) {
        $index{ $wlans->{$iid}{mac} } = $iid;
    }
    return \%index;
}

sub _clients {
    my ($self, $partial) = @_;
    my $macs = $self->instant_client_mac($partial) || {};
    my $bssids = $self->instant_client_bssid($partial) || {};
    my $wlans = $self->_wlans();
    my %known = map {$_->{mac} => 1} values %$wlans;
    my %clients;
    foreach my $iid (keys %$macs) {
        my $mac = $macs->{$iid};
        my $bssid = $bssids->{$iid};
        next unless defined $mac && $mac =~ /^(?:[0-9a-f]{2}:){5}[0-9a-f]{2}$/i;
        next unless defined $bssid && $known{lc $bssid};
        $clients{$iid} = {mac => lc $mac, bssid => lc $bssid};
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
C<i_up> and C<i_up_admin> preserve physical interfaces and add a logical
wireless interface per AP and WLAN index, plus separate radio interfaces. These are WLAN interfaces, not
physical radio indexes. WLAN status reflects AP status; radio status comes from the radio table.

C<i_ssidlist>, C<i_ssidmac> and C<i_ssidbcast> expose each WLAN's name,
BSSID and broadcast flag. Missing data does not create wireless interfaces.

=head2 Radio channel and power

C<i_80211channel> exposes the numeric channel for each separate radio
interface. Channel suffixes such as C<+>, C<E> and C<S> remain in the radio
interface description. C<dot11_cur_tx_pwr_mw> converts radio power from dBm
to integer milliwatts, rounding to the nearest milliwatt. The dBm interpretation
follows the L<LibreNMS Aruba Instant implementation|https://github.com/librenms/librenms/blob/master/LibreNMS/OS/ArubaInstant.php>.
No WLAN-to-radio relationship is inferred.

=head2 Wireless clients

C<fw_mac>, C<fw_port> and C<bp_index> map associated clients onto their WLAN
interfaces by BSSID, preserving wired forwarding entries. Clients with an
unknown BSSID are omitted. No client VLAN or physical radio is inferred.

=head2 Interface methods

=over

=item i_index

Returns physical indexes and logical AP/WLAN identifiers.

=item interfaces

Returns physical port names and stable logical WLAN names.

=item i_name

Returns the same stable WLAN names alongside physical interface names.

=item i_description

Returns the AP name and SSID for each logical WLAN.

=item i_type

Returns C<ieee80211> for logical WLANs.

=item i_mac

Returns the BSSID for each logical WLAN.

=item i_up

Returns AP operational status for WLANs and radio status for radio interfaces.

=item i_up_admin

Returns AP status for logical WLANs; separate WLAN administrative status
is not available from these tables.

=item i_ssidlist

Returns SSID names indexed by logical interface and SSID index.

=item i_ssidmac

Returns BSSIDs using the same indexes as C<i_ssidlist>.

=item i_ssidbcast

Returns broadcast flags from the SSID hide setting, when available.

=item i_80211channel

Returns numeric channels indexed by synthetic radio interface.

=item dot11_cur_tx_pwr_mw

Returns radio transmit power converted from dBm to integer milliwatts.

=item bp_index

Adds BSSID to logical interface mappings to physical bridge mappings.

=item fw_mac

Adds associated wireless client MAC addresses to wired forwarding entries.

=item fw_port

Maps associated clients to BSSIDs for joining through C<bp_index>.

=back

=cut
