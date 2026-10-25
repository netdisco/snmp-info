# SNMP::Info::Layer2::RuckusAP - SNMP interface to Ruckus access points
#
# Copyright (c) 2026 The SNMP::Info Developers
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
#     * Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
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
#

package SNMP::Info::Layer2::RuckusAP;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer2;

our ($VERSION, %GLOBALS, %FUNCS, %MIBS, %MUNGE);
$VERSION = '3.982000';
@SNMP::Info::Layer2::RuckusAP::ISA = qw(SNMP::Info::Layer2 Exporter);
@SNMP::Info::Layer2::RuckusAP::EXPORT_OK = qw//;

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
    'RUCKUS-HWINFO-MIB' => 'ruckusHwInfoModelNumber',
    'RUCKUS-SWINFO-MIB' => 'ruckusSwRevision',
    'RUCKUS-WLAN-MIB'   => 'ruckusWLANSSID',
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
    'ruckus_model'  => 'ruckusHwInfoModelNumber',
    'ruckus_serial' => 'ruckusHwInfoSerialNumber',
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
    'ruckus_sw_rev'        => 'ruckusSwRevision',
    'ruckus_sw_rev_status' => 'ruckusSwRevStatus',
    'ruckus_wlan_ssid'           => 'ruckusWLANSSID',
    'ruckus_wlan_bssid'          => 'ruckusWLANBSSID',
    'ruckus_wlan_channel'        => 'ruckusWLANChannel',
    'ruckus_wlan_admin_status'   => 'ruckusWLANAdminStatus',
    'ruckus_wlan_bcast_disabled' => 'ruckusWLANSSIDBcastDisable',
    'ruckus_wlan_ifindex'        => 'ruckusWLANIfIndex',
    'ruckus_station_mac'         => 'ruckusWLANStaAddr',
    'ruckus_station_rates'       => 'ruckusWLANStaRates',
    'ruckus_station_stats_mac'   => 'ruckusWLANStaStatsMacAddr',
    'ruckus_station_stats_ssid'  => 'ruckusWLANStaStatsSSID',
    'ruckus_station_stats_rxpkt' => 'ruckusWLANStaStatsRxDataFrames',
    'ruckus_station_stats_rxbyte' => 'ruckusWLANStaStatsRxBytes',
    'ruckus_station_stats_txpkt' => 'ruckusWLANStaStatsTxDataFrames',
    'ruckus_station_stats_txbyte' => 'ruckusWLANStaStatsTxBytes',
    'ruckus_station_stats_rssi'  => 'ruckusWLANStaStatsRSSI',
    'ruckus_station_rks_txrate'  => 'ruckusWLANStaRksTxRate',
);

%MUNGE = (
    %SNMP::Info::Layer2::MUNGE,
);

# Ruckus' WLAN table may expose spare/default rows that are not real
# interfaces. Keep only active rows whose mapped IF-MIB index exists.
sub _ruckus_active_wlan_rows {
    my $self = shift;
    my $status = $self->ruckus_wlan_admin_status() || {};
    my $ifindex = $self->ruckus_wlan_ifindex() || {};
    my $interfaces = $self->i_index() || {};
    my %active;

    foreach my $row ( keys %$status ) {
        my $state = $status->{$row};
        next unless defined $state and ( $state eq '1' or lc($state) eq 'up' );
        my $port = $ifindex->{$row};
        next unless defined $port and $port =~ /^\d+$/;
        next unless exists $interfaces->{$port};
        $active{$row} = $port;
    }

    return \%active;
}

sub _ruckus_wlan_values_by_interface {
    my ( $self, $method, $partial ) = @_;
    my $values = $self->$method() || {};
    my $rows = _ruckus_active_wlan_rows($self);
    my %result;

    foreach my $row ( keys %$rows ) {
        my $port = $rows->{$row};
        next if defined $partial and $partial ne $port;
        next unless defined $values->{$row};
        $result{"$port.$row"} = $values->{$row};
    }

    return \%result;
}

sub i_ssidlist {
    my ( $self, $partial ) = @_;
    my $ssids = $self->ruckus_wlan_ssid() || {};
    my $rows = _ruckus_active_wlan_rows($self);
    my %result;

    foreach my $row ( keys %$rows ) {
        my $port = $rows->{$row};
        next if defined $partial and $partial ne $port;
        my $ssid = $ssids->{$row};
        next unless defined $ssid and $ssid =~ /\S/;
        $result{"$port.$row"} = $ssid;
    }

    return \%result;
}

sub i_ssidmac {
    my ( $self, $partial ) = @_;
    my $values = _ruckus_wlan_values_by_interface(
        $self, 'ruckus_wlan_bssid', $partial
    );
    foreach my $key ( keys %$values ) {
        $values->{$key} = SNMP::Info::munge_mac( $values->{$key} );
    }
    return $values;
}

sub i_ssidbcast {
    my ( $self, $partial ) = @_;
    my $disabled = _ruckus_wlan_values_by_interface(
        $self, 'ruckus_wlan_bcast_disabled', $partial
    );
    my %broadcast;
    foreach my $key ( keys %$disabled ) {
        my $value = $disabled->{$key};
        $broadcast{$key} = ( $value eq '1' or lc($value) eq 'true' ) ? 0 : 1;
    }
    return \%broadcast;
}

sub i_80211channel {
    my ( $self, $partial ) = @_;
    my $channels = $self->ruckus_wlan_channel() || {};
    my $rows = _ruckus_active_wlan_rows($self);
    my %result;

    # Each active WLAN row repeats the radio channel. Return one channel per
    # mapped IF-MIB interface, as Netdisco's wireless radio consumers expect.
    foreach my $row ( sort { $a <=> $b } keys %$rows ) {
        my $port = $rows->{$row};
        next if defined $partial and $partial ne $port;
        next unless defined $channels->{$row};
        $result{$port} = $channels->{$row} unless exists $result{$port};
    }

    return \%result;
}

sub fw_mac {
    my $self = shift;
    my $standard = $self->SUPER::fw_mac() || {};
    my $macs = $self->ruckus_station_mac() || {};
    my $rows = _ruckus_active_wlan_rows($self);
    my %result = %$standard;

    foreach my $idx ( keys %$macs ) {
        next unless $idx =~ /^(\d+)\.6\.\d+(?:\.\d+){5}$/;
        next unless exists $rows->{$1};
        $result{$idx} = SNMP::Info::munge_mac( $macs->{$idx} );
    }

    return \%result;
}

sub fw_port {
    my $self = shift;
    my $standard = $self->SUPER::fw_port() || {};
    my $macs = $self->ruckus_station_mac() || {};
    my $rows = _ruckus_active_wlan_rows($self);
    my %result = %$standard;

    foreach my $idx ( keys %$macs ) {
        next unless $idx =~ /^(\d+)\.6\.\d+(?:\.\d+){5}$/;
        next unless exists $rows->{$1};
        $result{$idx} = $rows->{$1};
    }

    return \%result;
}

sub fw_ssid {
    my $self = shift;
    my $macs = $self->ruckus_station_mac() || {};
    my $ssids = $self->ruckus_wlan_ssid() || {};
    my $rows = _ruckus_active_wlan_rows($self);
    my %result;

    foreach my $idx ( keys %$macs ) {
        next unless $idx =~ /^(\d+)\.6\.\d+(?:\.\d+){5}$/;
        my $row = $1;
        next unless exists $rows->{$row};
        next unless defined $ssids->{$row} and $ssids->{$row} =~ /\S/;
        $result{$idx} = $ssids->{$row};
    }

    return \%result;
}

sub _ruckus_stats_index {
    my ($idx) = @_;
    return $idx if $idx =~ /^\d+\.6(?:\.\d+){6}$/;
    return "$1.6.$2" if $idx =~ /^(\d+)\.(\d+(?:\.\d+){5})$/;
    return;
}

sub cd11_mac {
    my $self = shift;
    my $macs = $self->ruckus_station_stats_mac() || {};
    return { map { $_ => SNMP::Info::munge_mac( $macs->{$_} ) } keys %$macs };
}

sub cd11_ssid {
    my $self = shift;
    return $self->ruckus_station_stats_ssid() || {};
}

sub cd11_txrate {
    my $self = shift;
    my $rates = $self->ruckus_station_rks_txrate() || {};
    my %result;
    foreach my $idx ( keys %$rates ) {
        my $stats_idx = _ruckus_stats_index($idx);
        next unless defined $stats_idx and defined $rates->{$idx};
        # Live AP data reports this PHY rate in Kbps; Netdisco stores Mbps.
        $result{$stats_idx} = [ $rates->{$idx} / 1000 ];
    }
    return \%result;
}

sub cd11_rateset {
    my $self = shift;
    my $raw_rates = $self->ruckus_station_rates() || {};
    my %result;
    foreach my $idx ( keys %$raw_rates ) {
        my $raw = $raw_rates->{$idx};
        next unless defined $raw and length $raw;
        my @rates = ($raw =~ /^\s*\d+(?:[\s,]+\d+)*\s*$/)
          ? map { 0 + $_ } split /[\s,]+/, $raw
          : map { (($_ & 0x7f) / 2) } unpack 'C*', $raw;
        $result{$idx} = \@rates if @rates;
    }
    return \%result;
}

sub cd11_sigstrength {
    my $self = shift;
    return $self->ruckus_station_stats_rssi() || {};
}

sub cd11_rxpkt {
    my $self = shift;
    return $self->ruckus_station_stats_rxpkt() || {};
}

sub cd11_txpkt {
    my $self = shift;
    return $self->ruckus_station_stats_txpkt() || {};
}

sub cd11_rxbyte {
    my $self = shift;
    return $self->ruckus_station_stats_rxbyte() || {};
}

sub cd11_txbyte {
    my $self = shift;
    return $self->ruckus_station_stats_txbyte() || {};
}

sub bp_index {
    my $self = shift;
    my $ifindexes = $self->i_index() || {};
    return { map { $_ => $_ } keys %$ifindexes };
}

sub model {
    my $self = shift;
    my $description = $self->description() || '';
    my ($unleashed_model) = $description =~ /^Ruckus Wireless ([A-Z]\d{3}\w*)/;
    return $self->ruckus_model() || $unleashed_model || $self->SUPER::model();
}

sub vendor { return 'ruckus'; }
sub os { return 'ruckus'; }
sub os_ver {
    my $self = shift;
    my $revisions = $self->ruckus_sw_rev() || {};
    my $statuses  = $self->ruckus_sw_rev_status() || {};

    foreach my $index ( sort { $a <=> $b } keys %$revisions ) {
        my $status = $statuses->{$index};
        my $revision = $revisions->{$index};
        next unless defined $status;
        next unless defined $revision and $revision =~ /\S/;
        return $revision
            if $status =~ /^(?:active|2)$/i;
    }

    # Some firmware (R500 on 9.13) answers ruckusSwRevision with no status.
    my ($first_revision) = grep { defined and /\S/ }
        @$revisions{ sort { $a <=> $b } keys %$revisions };
    return $first_revision if !%$statuses and defined $first_revision;

    return $self->SUPER::os_ver();
}
sub serial {
    my $self = shift;
    my $serial = $self->ruckus_serial();
    return $serial if defined $serial and $serial !~ /^\s*$/;
    return $self->SUPER::serial();
}

1;

__END__

=head1 NAME

SNMP::Info::Layer2::RuckusAP - SNMP interface to Ruckus access points

=head1 AUTHOR

SNMP::Info Developers

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $ruckus = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myap',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $ruckus->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides model, serial number, and software version information for Ruckus
access points registered below the Ruckus wireless product OID branches, and
for Unleashed access points identified by C<sysDescr>. It also maps active
WLANs, radio channels, and associated station data to the standard SNMP::Info
wireless methods.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

=over

=item F<RUCKUS-HWINFO-MIB>

=item F<RUCKUS-SWINFO-MIB>

=item F<RUCKUS-WLAN-MIB>

=back

=head2 Inherited MIBs

See L<SNMP::Info::Layer2/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These methods return scalar values.

=over

=item $ruckus->ruckus_model()

Returns the model number reported by the access point.

(C<ruckusHwInfoModelNumber>)

=item $ruckus->ruckus_serial()

Returns the serial number reported by the access point.

(C<ruckusHwInfoSerialNumber>)

=back

=head2 Overrides

=over

=item $ruckus->vendor()

Returns C<ruckus>.

=item $ruckus->os()

Returns C<ruckus>.

=item $ruckus->model()

Returns the model from C<ruckusHwInfoModelNumber>. Unleashed access points
do not answer it, so the model named in C<sysDescr> is used next, then the
inherited model method.

=item $ruckus->serial()

Returns the serial number from C<ruckusHwInfoSerialNumber>, falling back to
the inherited serial method.

=item $ruckus->os_ver()

Returns the software revision whose C<ruckusSwRevStatus> is active. When no
revision has a status, returns the lowest-indexed revision, then falls back
to the inherited method.

=back

=head2 Global Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Ruckus Software Revision Table (C<ruckusSwRevTable>)

=over

=item $ruckus->ruckus_sw_rev()

Returns reference to hash. Key: revision index, Value: software revision.

(C<ruckusSwRevision>)

=item $ruckus->ruckus_sw_rev_status()

Returns reference to hash. Key: revision index, Value: C<active> for the
running revision, otherwise C<inactive>.

(C<ruckusSwRevStatus>)

=back

=head2 Ruckus WLAN Table (C<ruckusWLANTable>)

=over

=item $ruckus->ruckus_wlan_ssid()

Returns reference to hash. Key: WLAN row, Value: SSID name
(C<ruckusWLANSSID>).

=item $ruckus->ruckus_wlan_bssid()

Returns reference to hash. Key: WLAN row, Value: BSSID
(C<ruckusWLANBSSID>).

=item $ruckus->ruckus_wlan_channel()

Returns reference to hash. Key: WLAN row, Value: channel
(C<ruckusWLANChannel>).

=item $ruckus->ruckus_wlan_admin_status()

Returns reference to hash. Key: WLAN row, Value: admin status
(C<ruckusWLANAdminStatus>).

=item $ruckus->ruckus_wlan_bcast_disabled()

Returns reference to hash. Key: WLAN row, Value: SSID broadcast disable flag
(C<ruckusWLANSSIDBcastDisable>).

=item $ruckus->ruckus_wlan_ifindex()

Returns reference to hash. Key: WLAN row, Value: mapped IF-MIB index
(C<ruckusWLANIfIndex>).

=back

=head2 Ruckus Station Tables (C<ruckusWLANStaTable>, C<ruckusWLANStaStatsTable>, C<ruckusWLANStaRksTable>)

=over

=item $ruckus->ruckus_station_mac()

Returns reference to hash. Key: WLAN row and station address, Value: station
MAC address (C<ruckusWLANStaAddr>).

=item $ruckus->ruckus_station_rates()

Returns reference to hash. Key: station row, Value: supported rates
(C<ruckusWLANStaRates>).

=item $ruckus->ruckus_station_stats_mac()

Returns reference to hash. Key: interface index and station address, Value:
station MAC address (C<ruckusWLANStaStatsMacAddr>).

=item $ruckus->ruckus_station_stats_ssid()

Returns reference to hash. Key: interface index and station address, Value:
SSID name (C<ruckusWLANStaStatsSSID>).

=item $ruckus->ruckus_station_stats_rxpkt()

Returns reference to hash. Key: station row, Value: received data frames
(C<ruckusWLANStaStatsRxDataFrames>).

=item $ruckus->ruckus_station_stats_rxbyte()

Returns reference to hash. Key: station row, Value: received bytes
(C<ruckusWLANStaStatsRxBytes>).

=item $ruckus->ruckus_station_stats_txpkt()

Returns reference to hash. Key: station row, Value: transmitted data frames
(C<ruckusWLANStaStatsTxDataFrames>).

=item $ruckus->ruckus_station_stats_txbyte()

Returns reference to hash. Key: station row, Value: transmitted bytes
(C<ruckusWLANStaStatsTxBytes>).

=item $ruckus->ruckus_station_stats_rssi()

Returns reference to hash. Key: station row, Value: received signal strength
(C<ruckusWLANStaStatsRSSI>).

=item $ruckus->ruckus_station_rks_txrate()

Returns reference to hash. Key: interface index and station address, Value:
current PHY rate (C<ruckusWLANStaRksTxRate>).

=back

=head2 Wireless Methods

=over

=item $ruckus->i_ssidlist()

Returns active SSIDs keyed by interface and WLAN row.

=item $ruckus->i_ssidmac()

Returns BSSIDs with the same keys as C<i_ssidlist()>.

=item $ruckus->i_ssidbcast()

Returns SSID broadcast state with the same keys as C<i_ssidlist()>.

=item $ruckus->i_80211channel()

Returns operating channels keyed by IF-MIB interface index.

=item $ruckus->fw_mac(), $ruckus->fw_port(), and $ruckus->fw_ssid()

Return associated client MAC addresses, their mapped interfaces, and their
active SSID names. Standard forwarding data is retained alongside Ruckus
station-table rows.

=item $ruckus->bp_index()

Returns reference to hash mapping IF-MIB indexes to themselves for wireless
station rows that already carry IF-MIB indexes.

=item $ruckus->cd11_mac(), $ruckus->cd11_ssid(), $ruckus->cd11_txrate(), and $ruckus->cd11_rateset()

Return client MAC addresses, SSIDs, current transmit PHY rates in Mbps, and
supported rates in Mbps, keyed by the station stats index.

=item $ruckus->cd11_sigstrength(), $ruckus->cd11_rxpkt(), $ruckus->cd11_txpkt(), $ruckus->cd11_rxbyte(), and $ruckus->cd11_txbyte()

Return station RSSI and RX/TX data counters. The Ruckus AP MIB does not expose
a verified signal-to-noise or signal-quality value, so C<cd11_sigqual> is not
provided.

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=cut
