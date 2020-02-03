# SNMP::Info::Layer2::Aironet
#
# Copyright (c) 2008-2009 Max Baker changes from version 0.8 and beyond.
#
# Copyright (c) 2003 Regents of the University of California
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

package SNMP::Info::Layer2::Aironet;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer2;
use SNMP::Info::EtherLike;
use SNMP::Info::CiscoStats;
use SNMP::Info::CiscoConfig;
use SNMP::Info::CDP;
use SNMP::Info::IEEE802dot11;

@SNMP::Info::Layer2::Aironet::ISA
    = qw/SNMP::Info::Layer2 SNMP::Info::EtherLike
    SNMP::Info::CiscoStats SNMP::Info::CiscoConfig SNMP::Info::CDP Exporter/;
@SNMP::Info::Layer2::Aironet::EXPORT_OK = qw//;

our ($VERSION, %FUNCS, %GLOBALS, %MIBS, %MUNGE);

$VERSION = '3.70';

%GLOBALS = (
    %SNMP::Info::IEEE802dot11::GLOBALS,
    %SNMP::Info::Layer2::GLOBALS,
    %SNMP::Info::EtherLike::GLOBALS,
    %SNMP::Info::CiscoStats::GLOBALS,
    %SNMP::Info::CiscoConfig::GLOBALS,
    %SNMP::Info::CDP::GLOBALS,
    'serial' => 'entPhysicalSerialNum.1',
    'ps1_type' => 'cpoePdCurrentPowerSource',
);

%FUNCS = (
    %SNMP::Info::IEEE802dot11::FUNCS,
    %SNMP::Info::Layer2::FUNCS,
    %SNMP::Info::EtherLike::FUNCS,
    %SNMP::Info::CiscoStats::FUNCS,
    %SNMP::Info::CiscoConfig::FUNCS,
    %SNMP::Info::CDP::FUNCS,
    'i_80211channel'   => 'cd11IfPhyDsssCurrentChannel',
    'c_dot11subif'     => 'cDot11ClientSubIfIndex',
    'cd11_rateset'     => 'cDot11ClientDataRateSet',
    'cd11_txrate'      => 'cDot11ClientCurrentTxRateSet',
    'cd11_uptime'      => 'cDot11ClientUpTime',
    'cd11_sigstrength' => 'cDot11ClientSignalStrength',
    'cd11_sigqual'     => 'cDot11ClientSigQuality',
    'cd11_rxpkt'       => 'cDot11ClientPacketsReceived',
    'cd11_txpkt'       => 'cDot11ClientPacketsSent',
    'cd11_rxbyte'      => 'cDot11ClientBytesReceived',
    'cd11_txbyte'      => 'cDot11ClientBytesSent',
    'mbss_mac_addr'    => 'cdot11MbssidIfMacAddress',
);

%MIBS = (
    %SNMP::Info::IEEE802dot11::MIBS,
    %SNMP::Info::Layer2::MIBS,
    %SNMP::Info::EtherLike::MIBS,
    %SNMP::Info::CiscoStats::MIBS,
    %SNMP::Info::CiscoConfig::MIBS,
    %SNMP::Info::CDP::MIBS,
    'CISCO-DOT11-IF-MIB'                  => 'cd11IfAuxSsid',
    'CISCO-DOT11-ASSOCIATION-MIB'         => 'cDot11ClientSubIfIndex',
    'CISCO-DOT11-SSID-SECURITY-MIB'       => 'cdot11SecVlanNameId',
    'CISCO-VLAN-IFTABLE-RELATIONSHIP-MIB' => 'cviRoutedVlanIfIndex',
    'CISCO-POE-PD-MIB'                    => 'cpoePdCurrentPowerSource',
);

%MUNGE = (
    %SNMP::Info::IEEE802dot11::MUNGE,
    %SNMP::Info::Layer2::MUNGE,
    %SNMP::Info::EtherLike::MUNGE,
    %SNMP::Info::CiscoStats::MUNGE,
    %SNMP::Info::CiscoConfig::MUNGE,
    %SNMP::Info::CDP::MUNGE,
    'cd11_txrate'   => \&munge_cd11_txrate,
    'cd11_rateset'  => \&munge_cd11_txrate,
    'mbss_mac_addr' => \&SNMP::Info::munge_mac,
);

# Use 802.11 power level without putting IEEE802dot11 in @ISA
*SNMP::Info::Layer2::Aironet::dot11_cur_tx_pwr_mw
    = \&SNMP::Info::IEEE802dot11::dot11_cur_tx_pwr_mw;

sub vendor {
    # Sorry, but it's true.
    return 'cisco';
}

sub interfaces {
    my $aironet = shift;
    my $partial = shift;

    my $i_description = $aironet->i_description($partial);

    return $i_description;
}

# Tag on e_descr.1
sub description {
    my $aironet = shift;
    my $descr   = $aironet->SUPER::description();
    my $e_descr = $aironet->e_descr();

    if (defined $e_descr->{1}) {
      if (defined $descr) {
        $descr = "$e_descr->{1}  $descr"
      } else {
        $descr = "$e_descr->{1}"
      }
    }
    return $descr;
}

# Fetch duplex from EtherLike
sub i_duplex {
    my $aironet = shift;
    my $partial = shift;

    my $el_duplex = $aironet->el_duplex($partial);

    my %i_duplex;
    foreach my $d ( keys %$el_duplex ) {
        my $val = $el_duplex->{$d};
        next unless defined $val;
        $i_duplex{$d} = 'full' if $val =~ /full/i;
        $i_duplex{$d} = 'half' if $val =~ /half/i;
    }

    return \%i_duplex;
}

#
# IOS 12.3 introduces the cDot11ClientSubIfIndex in the
# cDot11ClientConfigInfoTable, which supplies the ifIndex
# of the VLAN Subinterface if one exists, or of the primary
# interface if there are not subinterfaces.  12.2 used the
# Q-BRIDGE-MIB dot1qTpFdbTable but that was removed in 12.3.
sub _aironet_special {
    my $aironet = shift;
    my $os_ver  = $aironet->os_ver();
    if (   defined($os_ver)
        && $os_ver =~ /^(\d+)\.(\d+)(\D|$)/
        && ( ( $1 == 12 && $2 >= 3 ) || $1 > 12 ) )
    {
        return 1;
    }
}

#
# INDEX      { ifIndex, cd11IfAuxSsid, cDot11ClientAddress }
sub _aironet_breakout_dot11idx {
    my $oid = shift;

    my @parts   = split( /\./, $oid );
    my $ifindex = shift(@parts);
    my $ssidlen = shift(@parts);
    my $ssid    = pack( "C*", splice( @parts, 0, $ssidlen ) );
    my $mac     = join( ":", map { sprintf "%02x", $_ } @parts );
    return ( $ifindex, $ssid, $mac );
}

sub fw_mac {
    my $aironet = shift;

    return $aironet->qb_fw_mac() unless _aironet_special($aironet);
    my $c_dot11subif = $aironet->c_dot11subif();
    my $fw_mac       = {};

    foreach my $i ( keys %$c_dot11subif ) {
        my ( $ifindex, $ssid, $mac ) = _aironet_breakout_dot11idx($i);
        $fw_mac->{$i} = $mac;
    }
    return $fw_mac;
}

sub fw_port {
    my $aironet = shift;

    return $aironet->qb_fw_port() unless _aironet_special($aironet);
    my $c_dot11subif = $aironet->c_dot11subif();
    my $fw_port      = {};

    foreach my $i ( keys %$c_dot11subif ) {
        my ( $ifindex, $ssid, $mac ) = _aironet_breakout_dot11idx($i);
        $fw_port->{$i} = $c_dot11subif->{$i} || $ifindex;
    }
    return $fw_port;
}

sub bp_index {
    my $aironet = shift;

    return $aironet->orig_bp_index() unless _aironet_special($aironet);
    my $c_dot11subif = $aironet->c_dot11subif();
    my $bp_index     = {};

    foreach my $i ( keys %$c_dot11subif ) {
        my ( $ifindex, $ssid, $mac ) = _aironet_breakout_dot11idx($i);
        my ($i) = $c_dot11subif->{$i} || $ifindex;
        $bp_index->{$i} = $i;
    }
    return $bp_index;
}

###
#
# VLAN support
#
sub v_name {
    my $aironet = shift;

    my $v_name      = {};
    my $vlan_nameid = $aironet->cdot11SecVlanNameId();
    foreach my $i ( keys %$vlan_nameid ) {
        my @parts = split( /\./, $i );
        my $namelen = shift(@parts);

        my $name = pack( "C*", @parts );
        $v_name->{$i} = $name;
    }
    return $v_name;
}

sub v_index {
    my $aironet = shift;

    return $aironet->cdot11SecVlanNameId();
}

sub i_vlan {
    my $aironet = shift;

    my $i_vlan = {};
    my $idxmap = $aironet->cviRoutedVlanIfIndex();
    foreach my $i ( keys %$idxmap ) {
        my @parts = split( /\./, $i );
        $i_vlan->{ $idxmap->{$i} } = $parts[0];
    }
    return $i_vlan;
}

# The MIB reports in units of half a megabit, e.g.,
# 5.5Mbps is reported as 11.
sub munge_cd11_txrate {
    my $txrates = shift;
    my @units   = unpack( "C*", $txrates );
    my @rates   = map {
        my $unit = $_;
        $unit *= 0.5;
    } @units;

    return \@rates;
}

# cd11 INDEX
sub cd11_port {
    my $aironet          = shift;
    my $cd11_sigstrength = $aironet->cd11_sigstrength();
    my $interfaces       = $aironet->interfaces();
    my %ret;
    foreach ( keys %$cd11_sigstrength ) {
        my ( $ifindex, $ssid, $mac ) = _aironet_breakout_dot11idx($_);
        $ret{$_} = $interfaces->{$ifindex};
    }
    return \%ret;
}

sub cd11_ssid {
    my $aironet          = shift;
    my $cd11_sigstrength = $aironet->cd11_sigstrength();
    my %ret;
    foreach ( keys %$cd11_sigstrength ) {
        my ( $ifindex, $ssid, $mac ) = _aironet_breakout_dot11idx($_);
        $ret{$_} = $ssid;
    }
    return \%ret;
}

sub cd11_mac {
    my $aironet          = shift;
    my $cd11_sigstrength = $aironet->cd11_sigstrength();
    my %ret;
    foreach ( keys %$cd11_sigstrength ) {
        my ( $ifindex, $ssid, $mac ) = _aironet_breakout_dot11idx($_);
        $ret{$_} = $mac;
    }
    return \%ret;
}

# Map VLAN N on interface I to its actual ifIndex.
sub _vlan_map_n_stack {
    my $aironet  = shift;
    my $vlan_idx = $aironet->cviRoutedVlanIfIndex();

    my $vlan_map = {};
    foreach my $idx ( keys %$vlan_idx ) {
        my ( $vlan, $num ) = split( /\./, $idx );
        $vlan_map->{$vlan}->{$num} = $vlan_idx->{$idx};
    }
    return $vlan_map;
}

# When using MBSS, the ifTable reports the
# base MAC address, but the actual association is
# with a different MAC address for MBSS.
# This convoluted path seems to be necessary
# to get the right overrides.
sub i_mac {
    my $aironet = shift;

    # no partial is possible due to the levels
    # of indirection.

    # Start with the ifPhysAddress, and override
    my $mbss_mac = $aironet->orig_i_mac();

    my $mbss_mac_addr = $aironet->mbss_mac_addr();
    my $ssid_vlan     = $aironet->cdot11SecAuxSsidVlan();
    my $vlan_map      = $aironet->cviRoutedVlanIfIndex();
    my $ifstack       = $aironet->ifStackStatus();

    my $vlan_list = {};
    foreach my $idx ( keys %$vlan_map ) {
        my ( $vlan, $num ) = split( /\./, $idx );
        push( @{ $vlan_list->{$vlan} }, $vlan_map->{$idx} );
    }

    my $stack = {};
    foreach my $idx ( keys %$ifstack ) {
        my ( $upper, $lower ) = split( /\./, $idx );
        $stack->{$upper}->{$lower} = $ifstack->{$idx};
    }

    # mbss_mac_addr index is (radio, ssid).
    # ssid_vlan maps ssid->vlan.
    # vlan_map maps vlan->[list of interfaces]
    # ifstack allows us to pick the right interface
    foreach my $idx ( keys %$mbss_mac_addr ) {
        my ( $interface, @ssid ) = split( /\./, $idx );
        my $vlan = $ssid_vlan->{ join( ".", scalar(@ssid), @ssid ) };
        next unless defined($vlan);
        foreach my $vlanif ( @{ $vlan_list->{$vlan} } ) {
            if ( defined( $stack->{$vlanif}->{$interface} ) ) {
                $mbss_mac->{$vlanif} = $mbss_mac_addr->{$idx};
            }
        }
    }

    return $mbss_mac;
}

sub i_ssidlist {
    my $aironet = shift;

    # no partial is possible due to the levels
    # of indirection.
    my $ssid_row  = $aironet->cdot11SecInterfSsidRowStatus();
    my $ssid_vlan = $aironet->cdot11SecAuxSsidVlan();
    if ( !defined($ssid_row) || !defined($ssid_vlan) ) {
        return $aironet->cd11IfAuxSsid();
    }
    my $ssidlist     = {};
    my $if_ssidcount = {};
    my $vlan_map     = $aironet->_vlan_map_n_stack();
    foreach my $idx ( keys %$ssid_row ) {
        next unless $ssid_row->{$idx} eq 'active';

        # ssid_row index is radio.ssid
        my ( $interface, $ssid ) = split( /\./, $idx, 2 );
        my ( $len, @ssidt ) = split( /\./, $ssid );
        my $mappedintf = $vlan_map->{ $ssid_vlan->{$ssid} }->{$interface};
        next unless $mappedintf;
        if ( !$if_ssidcount->{$mappedintf} ) {
            $if_ssidcount->{$mappedintf} = 1;
        }
        my $ssidlist_idx
            = sprintf( "%s.%d", $mappedintf, $if_ssidcount->{$mappedintf} );
        $ssidlist->{$ssidlist_idx} = pack( "C*", @ssidt );
        $if_ssidcount->{$mappedintf}++;
    }
    return $ssidlist;
}

sub i_ssidbcast {
    my $aironet    = shift;
    my $partial    = shift;
    my $mbss_bcast = $aironet->cdot11SecAuxSsidMbssidBroadcast();
    if ( !defined($mbss_bcast) ) {
        return $aironet->cd11IfAuxSsidBroadcastSsid($partial);
    }
    my $map = {};
    foreach my $key ( keys %$mbss_bcast ) {
        my (@idx) = split( /\./, $key );
        my $len = shift(@idx);
        $map->{ pack( "C*", @idx ) } = $mbss_bcast->{$key};
    }

    # This needs to return the same indexes as i_ssidlist.
    # mbss_bcast maps ssid -> broadcasting
    #  so we just replace the i_ssidlist values with the mbss_bcast ones.
    my $i_ssidlist  = $aironet->i_ssidlist();
    my $i_ssidbcast = {};
    foreach my $key ( keys %$i_ssidlist ) {
        $i_ssidbcast->{$key} = $map->{ $i_ssidlist->{$key} };
    }
    return $i_ssidbcast;
}

sub i_ssidmac {
    my $aironet    = shift;
    my $partial    = shift;
    my $mbss_mac_addr = $aironet->mbss_mac_addr();

    # Same logic as i_ssidbcast to return same indexes as i_ssidlist
    my $map = {};
    foreach my $key ( keys %$mbss_mac_addr ) {
        my ( $interface, @idx ) = split( /\./, $key );
        $map->{ pack( "C*", @idx ) } = $mbss_mac_addr->{$key};
    }

    my $i_ssidlist  = $aironet->i_ssidlist();
    my $i_ssidmac = {};
    foreach my $key ( keys %$i_ssidlist ) {
        $i_ssidmac->{$key} = $map->{ $i_ssidlist->{$key} };
    }
    return $i_ssidmac;
}

###
# PoE status.  The ps1_type is the PoE injector type, which is just
# a scalar; the status is a little more complex.
sub ps1_status {
    my $aironet = shift;
    my $idx = $aironet->cpoePdCurrentPowerLevel();
    my $mw = $aironet->cpoePdSupportedPower( $idx );
    my $descr = $aironet->cpoePdSupportedPowerMode( $idx );

    return sprintf( "%.2fW (%s)", $mw->{$idx} * 0.001, $descr->{$idx} );
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::Aironet - SNMP Interface to Cisco Aironet devices running
IOS.

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $aironet = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $aironet->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides interface to SNMP Data available on newer Aironet devices running
Cisco IOS.

Note there are two classes for Aironet devices :

=over

=item SNMP::Info::Layer3::Aironet

This class is for devices running Aironet software (older)

=item SNMP::Info::Layer2::Aironet

This class is for devices running Cisco IOS software (newer)

=back

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above.

my $aironet = new SNMP::Info::Layer2::Aironet(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=item SNMP::Info::EtherLike

=item SNMP::Info::CiscoStats

=item SNMP::Info::CiscoConfig

=back

=head2 Required MIBs

=over

=item F<CISCO-DOT11-ASSOCIATION-MIB>

=item F<CISCO-DOT11-IF-MIB>

=item F<CISCO-DOT11-SSID-SECURITY-MIB>

=item F<CISCO-POE-PD-MIB>

=item F<CISCO-VLAN-IFTABLE-RELATIONSHIP-MIB>

=item Inherited Classes

MIBs required by the inherited classes listed above.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $aironet->vendor()

Returns 'cisco'

=item $aironet->description()

System description. Adds info from method e_descr() from SNMP::Info::Entity

=back

=head2 Globals imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::EtherLike

See documentation in L<SNMP::Info::EtherLike/"GLOBALS"> for details.

=head1 TABLE METHODS

=over

=item $aironet->cd11_port()

Returns radio interfaces.

=item $aironet->cd11_mac()

Returns client radio interface MAC addresses.

=item $aironet->cd11_ssid()

Returns radio interface ssid.

=item $aironet->dot11_cur_tx_pwr_mw()

Current transmit power, in milliwatts, of the radio interface.

=back

=head2 Overrides

=over

=item $aironet->interfaces()

Uses the i_description() field.

=item $aironet->i_mac()

MAC address of the interface. Note this is just the MAC of the port, not
anything connected to it.

=item $aironet->i_duplex()

Crosses information from SNMP::Info::EtherLike to get duplex info for
interfaces.

=item $aironet->bp_index()

Returns reference to hash of bridge port table entries map back to interface
identifier (iid)

=item $aironet->fw_mac()

Returns reference to hash of forwarding table MAC Addresses

=item $aironet->fw_port()

Returns reference to hash of forwarding table entries port interface
identifier (iid)

=item $aironet->i_vlan()

Returns a mapping between C<ifIndex> and the PVID or default VLAN.

=item $aironet->v_index()

Returns VLAN IDs

=item $aironet->v_name()

Returns VLAN names

=item $aironet->i_ssidlist()

Returns a list of SSIDs associated with interfaces.  This function
is C<MBSSID> aware, so when using C<MBSSID> can map SSIDs to the sub-interface
to which they belong.

=item $aironet->i_ssidbcast()

With the same keys as i_ssidlist, returns whether the given SSID is
being broadcast.

=item $aironet->i_ssidmac()

With the same keys as i_ssidlist, returns the Basic service set
identification (BSSID), MAC address, the AP is using for the SSID.

=item $aironet ps1_status()

Returns the PoE injector status based on C<cpoePdSupportedPower> and
C<cpoePdSupportedPowerMode>.

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::EtherLike

See documentation in L<SNMP::Info::EtherLike/"TABLE METHODS"> for details.

=head1 Data Munging Callback Subroutines

=over

=item $aironet->munge_cd11_txrate()

Converts units of half a megabit to human readable string.

=back

=cut
