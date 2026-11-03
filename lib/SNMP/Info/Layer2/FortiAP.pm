# SNMP::Info::Layer2::FortiAP
#
# Copyright (c) 2026 SNMP::Info Developers
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

package SNMP::Info::Layer2::FortiAP;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer2;

@SNMP::Info::Layer2::FortiAP::ISA = qw/
    SNMP::Info::Layer2
    Exporter
    /;
@SNMP::Info::Layer2::FortiAP::EXPORT_OK = qw//;

our ( $VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE );

$VERSION = '3.985000';

%MIBS = ( %SNMP::Info::Layer2::MIBS, );

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,

    # FORTINET-FORTIAP-MIB objects are read by OID until the MIB is in a
    # netdisco-mibs release, netdisco/netdisco-mibs#312
    # fapVersion, fapSerialNum
    'fap_version' => '.1.3.6.1.4.1.12356.120.1.1.0',
    'fap_serial'  => '.1.3.6.1.4.1.12356.120.1.2.0',
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,

    # fapRadioTxPowerOper (dBm), fapRadioChannelOper; indexed by radio
    'fap_radio_tx_pwr'  => '.1.3.6.1.4.1.12356.120.4.1.1.10',
    'fap_radio_channel' => '.1.3.6.1.4.1.12356.120.4.1.1.14',

    # fapVapSSID; indexed by radio.wlan
    'fap_vap_ssid' => '.1.3.6.1.4.1.12356.120.7.1.1.4',

    # fapStaVlanId, fapStaSSID; indexed by radio.wlan.<station MAC>
    'fap_sta_vlan' => '.1.3.6.1.4.1.12356.120.8.1.1.5',
    'fap_sta_ssid' => '.1.3.6.1.4.1.12356.120.8.1.1.7',
);

%MUNGE = ( %SNMP::Info::Layer2::MUNGE, );

# FortiAPs serve no sysServices
sub layers {
    my $fap = shift;

    return $fap->SUPER::layers() || '00000010';
}

sub vendor {
    return 'fortinet';
}

sub os {
    return 'fortiap';
}

# fapVersion is "<image>-v<version>", e.g. "FP221E-v7.0-build0033"
sub os_ver {
    my $fap     = shift;
    my $version = $fap->fap_version();

    return unless defined $version;
    return $1 if $version =~ /^\S+?-v(\S+)$/;
    return $version;
}

# The image name before "-v" names the model: FP231G, PU231F
sub model {
    my $fap     = shift;
    my $version = $fap->fap_version() // '';

    return $1 if $version =~ /^(\S+?)-v/;
    return $fap->SUPER::model();
}

sub serial {
    my $fap = shift;

    return $fap->fap_serial();
}

# fapRadioTable row R is the interface named wifi<R>; no column links
# the two
sub _fap_radios {
    my $fap = shift;

    my $channels        = $fap->fap_radio_channel() || {};
    my $i_descr         = $fap->i_description()     || {};
    my %ifindex_by_name = reverse %$i_descr;

    my %radios;
    foreach my $radio ( keys %$channels ) {
        my $ifindex = $ifindex_by_name{"wifi$radio"};
        $radios{$radio} = $ifindex if defined $ifindex;
    }
    return \%radios;
}

# Per-VAP interfaces of a mapped radio: wlan<R><W>, w<R><W>.<vlan>,
# tv<R><W>, wlbgs<R>; and per-SSID interfaces br.ssid.<W>, tc<W> of a WLAN
# served on a mapped radio
sub _fap_vap_ports {
    my $fap = shift;

    my $radios  = $fap->_fap_radios();
    my $i_descr = $fap->i_description() || {};
    my %wlans   = map { ( split /\./ )[1] => 1 }
        grep { exists $radios->{ ( split /\./ )[0] } }
        keys %{ $fap->fap_vap_ssid() || {} };

    my %vap_ports;
    foreach my $iid ( keys %$i_descr ) {
        my $name = $i_descr->{$iid};
        if ( $name =~ /^(?:wlan(\d)\d+|w(\d)\d+\.\d+|tv(\d)\d+|wlbgs(\d))$/ )
        {
            my $radio = $1 // $2 // $3 // $4;
            $vap_ports{$iid} = 1 if exists $radios->{$radio};
        }
        elsif ( $name =~ /^(?:br\.ssid\.|tc)(\d+)$/ ) {
            $vap_ports{$iid} = 1 if $wlans{$1};
        }
    }
    return \%vap_ports;
}

sub interfaces {
    my $fap     = shift;
    my $partial = shift;

    my $interfaces = $fap->SUPER::interfaces($partial) || {};
    my $vap_ports  = $fap->_fap_vap_ports();

    delete @{$interfaces}{ keys %$vap_ports };
    return $interfaces;
}

sub i_80211channel {
    my $fap = shift;

    my $radios   = $fap->_fap_radios();
    my $channels = $fap->fap_radio_channel() || {};

    my %i_80211channel;
    foreach my $radio ( keys %$radios ) {
        my $channel = $channels->{$radio};
        next unless $channel;
        $i_80211channel{ $radios->{$radio} } = $channel;
    }
    return \%i_80211channel;
}

sub dot11_cur_tx_pwr_mw {
    my $fap = shift;

    my $radios   = $fap->_fap_radios();
    my $channels = $fap->fap_radio_channel() || {};
    my $power    = $fap->fap_radio_tx_pwr()  || {};

    my %tx_pwr_mw;
    foreach my $radio ( keys %$radios ) {
        my $dbm = $power->{$radio};
        next
            unless $channels->{$radio}
            and defined $dbm
            and $dbm =~ /^-?\d+$/;
        $tx_pwr_mw{ $radios->{$radio} } = int( 10**( $dbm / 10 ) + 0.5 );
    }
    return \%tx_pwr_mw;
}

sub i_ssidlist {
    my $fap = shift;

    my $radios = $fap->_fap_radios();
    my $ssids  = $fap->fap_vap_ssid() || {};

    my %i_ssidlist;
    foreach my $vap ( keys %$ssids ) {
        my ( $radio, $wlan ) = split /\./, $vap;
        next unless defined $wlan and exists $radios->{$radio};
        $i_ssidlist{"$radios->{$radio}.$wlan"} = $ssids->{$vap};
    }
    return \%i_ssidlist;
}

# The BSSID is the MAC of the VAP's wlan<R><W> interface
sub i_ssidmac {
    my $fap = shift;

    my $radios          = $fap->_fap_radios();
    my $ssids           = $fap->fap_vap_ssid()  || {};
    my $i_descr         = $fap->i_description() || {};
    my $i_mac           = $fap->i_mac()         || {};
    my %ifindex_by_name = reverse %$i_descr;

    my %i_ssidmac;
    foreach my $vap ( keys %$ssids ) {
        my ( $radio, $wlan ) = split /\./, $vap;
        next unless defined $wlan and exists $radios->{$radio};
        my $vap_port = $ifindex_by_name{"wlan$radio$wlan"};
        next unless defined $vap_port and $i_mac->{$vap_port};
        $i_ssidmac{"$radios->{$radio}.$wlan"} = $i_mac->{$vap_port};
    }
    return \%i_ssidmac;
}

# fapStaMacAddr is a PhysAddress index, so normally length prefixed;
# accept the bare six octets too
sub _fap_sta_index {
    my $iid = shift;

    my ( $radio, $wlan, @octets ) = split /\./, $iid;
    shift @octets if @octets == 7 and $octets[0] == 6;
    return unless defined $wlan   and @octets == 6;
    return ( $radio, $wlan, join ':', map { sprintf '%02x', $_ } @octets );
}

# Stations on a radio with a port: { iid => [ radio ifIndex, mac ] }
sub _fap_stations {
    my $fap     = shift;
    my $partial = shift;

    my $radios = $fap->_fap_radios();
    my $ssids  = $fap->fap_sta_ssid($partial) || {};

    my %stations;
    foreach my $iid ( keys %$ssids ) {
        my ( $radio, $wlan, $mac ) = _fap_sta_index($iid);
        next unless defined $mac and exists $radios->{$radio};
        $stations{$iid} = [ $radios->{$radio}, $mac ];
    }
    return \%stations;
}

sub qb_fw_mac {
    my $fap      = shift;
    my $stations = $fap->_fap_stations(shift);

    return { map { $_ => $stations->{$_}[1] } keys %$stations };
}

sub qb_fw_port {
    my $fap      = shift;
    my $stations = $fap->_fap_stations(shift);

    return { map { $_ => $stations->{$_}[0] } keys %$stations };
}

sub qb_fw_vlan {
    my $fap      = shift;
    my $partial  = shift;
    my $stations = $fap->_fap_stations($partial);
    my $vlans    = $fap->fap_sta_vlan($partial) || {};

    return {
        map  { $_ => $vlans->{$_} }
        grep { defined $vlans->{$_} } keys %$stations
    };
}

# Stations are reported on radio ifIndexes, which serve no bridge port
sub bp_index {
    my $fap     = shift;
    my $partial = shift;

    # Copied: SUPER returns the cached table by reference
    my %bp_index = %{ $fap->SUPER::bp_index($partial) || {} };
    my $radios   = $fap->_fap_radios();

    foreach my $ifindex ( values %$radios ) {
        $bp_index{$ifindex} = $ifindex unless exists $bp_index{$ifindex};
    }
    return \%bp_index;
}

# fapStationTable has no rate column; an empty rate keeps the client
sub cd11_txrate {
    my $fap      = shift;
    my $stations = $fap->_fap_stations(shift);

    return { map { $_ => [] } keys %$stations };
}

sub cd11_mac {
    my $fap = shift;

    return $fap->qb_fw_mac(shift);
}

sub cd11_ssid {
    my $fap      = shift;
    my $partial  = shift;
    my $stations = $fap->_fap_stations($partial);
    my $ssids    = $fap->fap_sta_ssid($partial) || {};

    return { map { $_ => $ssids->{$_} } keys %$stations };
}

sub cd11_port {
    my $fap        = shift;
    my $stations   = $fap->_fap_stations(shift);
    my $interfaces = $fap->interfaces();

    return {
        map { $_ => $interfaces->{ $stations->{$_}[0] } }
            keys %$stations
    };
}

# Loopback and Linux pseudo devices that carry no traffic
sub i_ignore {
    my $fap     = shift;
    my $partial = shift;

    my $ignore  = $fap->SUPER::i_ignore($partial) || {};
    my $i_descr = $fap->i_description($partial)   || {};
    my $i_type  = $fap->i_type($partial)          || {};

    foreach my $iid ( keys %$i_descr ) {
        my $name = $i_descr->{$iid};
        my $type = $i_type->{$iid} // '';
        $ignore->{$iid}++
            if $type eq 'softwareLoopback'
            or $name =~ /^(?:gre|gretap|ip6tnl|sit|ip6gre|ifb|teql|soc)\d*$/
            or $name =~ /^(?:ipsecdummy|miireg)$/;
    }
    return $ignore;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::FortiAP - SNMP Interface to Fortinet FortiAP access
points

=head1 AUTHOR

SNMP::Info Developers

=head1 SYNOPSIS

    # Let SNMP::Info determine the correct subclass for you.
    my $fap = new SNMP::Info(
                            AutoSpecify => 1,
                            Debug       => 1,
                            DestHost    => 'myap',
                            Community   => 'public',
                            Version     => 2
                          )
        or die "Can't connect to DestHost.\n";

    my $class = $fap->class();
    print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a
Fortinet FortiAP access point via SNMP. It is chosen for C<sysObjectID>s
under the FortiAP branch, C<.1.3.6.1.4.1.12356.120>.

Each radio is a port, C<wifi>I<R>, carrying its channel, transmit power
and SSIDs. Clients from the station table are nodes on their radio's port,
tagged with their VLAN and SSID.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

None beyond those of the inherited class. The F<FORTINET-FORTIAP-MIB>
objects are read by OID.

=head2 Inherited MIBs

See L<SNMP::Info::Layer2/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP.

=over

=item $fap->vendor()

Returns 'fortinet'.

=item $fap->os()

Returns 'fortiap'.

=item $fap->os_ver()

Returns the firmware version from C<fapVersion>, without the image name
before C<-v> (C<7.0-build0033> from C<FP221E-v7.0-build0033>).

=item $fap->model()

Returns the image name before C<-v> in C<fapVersion> (C<FP231G> from
C<FP231G-v7.4-build0771>), or the inherited model when it has none.

=item $fap->serial()

Returns the serial number.

(C<fapSerialNum>)

=item $fap->fap_version()

(C<fapVersion>)

=item $fap->fap_serial()

(C<fapSerialNum>)

=back

=head2 Overrides

=over

=item $fap->layers()

Returns layer 2 when the device serves no C<sysServices>, as FortiAPs do.

=back

=head2 Global Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a
reference to a hash.

=head2 Overrides

=over

=item $fap->interfaces()

Returns reference to hash of interface names. Each radio is one port,
C<wifi>I<R>. The per-SSID interfaces of a radio (C<wlan>I<RW>,
C<w>I<RW>C<.>I<vlan>, C<tv>I<RW>, C<wlbgs>I<R>), and the per-SSID
C<br.ssid.>I<W> and C<tc>I<W> of a WLAN a radio serves, are not ports;
their SSIDs and clients are reported on the radio's port.

=item $fap->i_ignore()

Returns reference to hash. Adds the loopback and the Linux pseudo
devices that carry no traffic (C<gre>, C<sit>, C<ifb>, C<teql> and
similar) to the inherited list.

=back

=head2 FortiAP Radio Table (C<fapRadioTable>)

Indexed by radio number I<R>, which is the interface C<wifi>I<R>.

=over

=item $fap->fap_radio_channel()

(C<fapRadioChannelOper>)

=item $fap->fap_radio_tx_pwr()

Operating transmit power in dBm.

(C<fapRadioTxPowerOper>)

=back

=head2 FortiAP VAP Table (C<fapVapTable>)

Indexed by radio number and WLAN number, I<R>.I<W>.

=over

=item $fap->fap_vap_ssid()

(C<fapVapSSID>)

=back

=head2 FortiAP Station Table (C<fapStationTable>)

Indexed by radio number, WLAN number and station MAC address. The MAC
address is read from the index.

=over

=item $fap->fap_sta_vlan()

(C<fapStaVlanId>)

=item $fap->fap_sta_ssid()

(C<fapStaSSID>)

=back

=head2 802.11 Interface Table

These methods emulate the F<IEEE802dot11-MIB> interface methods using the
F<FORTINET-FORTIAP-MIB> C<fapRadioTable> and C<fapVapTable>. Keys are the
radio's ifIndex; SSID keys add the WLAN number.

=over

=item $fap->i_80211channel()

Returns reference to hash. Operating channel of each radio port. A radio
on channel 0, as a monitor radio is, is left out.

(C<fapRadioChannelOper>)

=item $fap->dot11_cur_tx_pwr_mw()

Returns reference to hash. Operating transmit power of each radio port
with a channel, converted from dBm to milliwatts.

(C<fapRadioTxPowerOper>)

=item $fap->i_ssidlist()

Returns reference to hash. SSID of each VAP, keyed
I<radio ifIndex>.I<W>.

(C<fapVapSSID>)

=item $fap->i_ssidmac()

Returns reference to hash. BSSID of each VAP, the MAC address of its
C<wlan>I<RW> interface, keyed as C<i_ssidlist()>.

=back

=head2 Forwarding Table

These methods emulate the F<Q-BRIDGE-MIB> forwarding table methods using
the F<FORTINET-FORTIAP-MIB> C<fapStationTable>, so each client is a node
on its radio's port. Keys are the station table index. Stations on a
radio with no port are left out.

=over

=item $fap->qb_fw_mac()

Returns reference to hash. Station MAC address, from the index.

=item $fap->qb_fw_port()

Returns reference to hash. The ifIndex of the station's radio port.

=item $fap->qb_fw_vlan()

Returns reference to hash. The station's VLAN.

(C<fapStaVlanId>)

=item $fap->bp_index()

Returns reference to hash. The inherited bridge port map, with each radio
port's ifIndex mapped to itself.

=back

=head2 Client Table

These methods emulate the F<CISCO-DOT11-ASSOCIATION-MIB> client methods
using the F<FORTINET-FORTIAP-MIB> C<fapStationTable>, keyed as the
forwarding table.

=over

=item $fap->cd11_txrate()

Returns reference to hash of empty array references. The station table
has no rate column; an entry per station keeps each client.

=item $fap->cd11_mac()

Returns reference to hash. Station MAC address, from the index.

=item $fap->cd11_ssid()

Returns reference to hash. The station's SSID.

(C<fapStaSSID>)

=item $fap->cd11_port()

Returns reference to hash. The name of the station's radio port.

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=cut
