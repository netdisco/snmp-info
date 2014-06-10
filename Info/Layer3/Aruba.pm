# SNMP::Info::Layer3::Aruba
# $Id$
#
# Copyright (c) 2013 Eric Miller
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

package SNMP::Info::Layer3::Aruba;

use strict;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::LLDP;

@SNMP::Info::Layer3::Aruba::ISA       = qw/SNMP::Info::LLDP SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Aruba::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE/;

$VERSION = '3.15';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::LLDP::MIBS,
    'WLSR-AP-MIB'        => 'wlsrHideSSID',
    'WLSX-IFEXT-MIB'     => 'ifExtVlanName',
    'WLSX-POE-MIB'       => 'wlsxPseSlotPowerAvailable',
    'WLSX-SWITCH-MIB'    => 'wlsxHostname',
    'WLSX-SYSTEMEXT-MIB' => 'wlsxSysExtSwitchBaseMacaddress',
    'WLSX-USER-MIB'      => 'nUserCurrentVlan',
    'WLSX-WLAN-MIB'      => 'wlanAPFQLN',

    #'ALCATEL-IND1-TP-DEVICES' => 'familyOmniAccessWireless',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,
    'aruba_serial_old' => 'wlsxSwitchLicenseSerialNumber',
    'aruba_serial_new' => 'wlsxSysExtLicenseSerialNumber',
    'aruba_model'      => 'wlsxModelName',
    'mac'              => 'wlsxSysExtSwitchBaseMacaddress',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::LLDP::FUNCS,

    # WLSR-AP-MIB::wlsrConfigTable
    'aruba_ap_ssidbcast' => 'wlsrHideSSID',

    # WLSX-IFEXT-MIB::wlsxIfExtPortTable
    'aruba_if_idx'    => 'ifExtPortIfIndex',
    'aruba_if_mode'   => 'ifExtMode',
    'aruba_if_pvid'   => 'ifExtTrunkNativeVlanId',
    'aruba_if_duplex' => 'ifExtPortDuplex',

    # WLSX-IFEXT-MIB::wlsxIfExtVlanMemberTable
    'aruba_if_vlan_member' => 'ifExtVlanMemberStatus',

    # WLSX-IFEXT-MIB::::wlsxIfExtVlanTable
    'aruba_v_name' => 'ifExtVlanName',

    # Other cd11_ methods are indexed by staPhyAddress, we need to
    # strip staAccessPointBSSID from the aruba_cd11_ methods.
    # wlanStaRSSI and staSignalToNoiseRatio don't appear to be reporting
    # distinct values.
    # WLSX-SWITCH-MIB::wlsxSwitchStationMgmtTable
    'aruba_cd11_sigqual' => 'staSignalToNoiseRatio',
    'aruba_cd11_txrate'  => 'staTransmitRate',

    # WLSX-SWITCH-MIB::wlsxSwitchStationStatsTable
    'aruba_cd11_rxbyte' => 'staRxBytes',
    'aruba_cd11_txbyte' => 'staTxBytes',
    'aruba_cd11_rxpkt'  => 'staRxPackets',
    'aruba_cd11_txpkt'  => 'staTxPackets',

    # WLSX-SYSTEMEXT-MIB::wlsxSysExtCardTable
    'aruba_card_type'   => 'sysExtCardType',
    'aruba_card_serial' => 'sysExtCardSerialNo',
    'aruba_card_hw'     => 'sysExtCardHwRevision',
    'aruba_card_fpga'   => 'sysExtCardFpgaRevision',
    'aruba_card_no'     => 'sysExtCardAssemblyNo',

    # WLSX-USER-MIB::wlsxUserTable
    'aruba_user_vlan'  => 'nUserCurrentVlan',
    'aruba_user_bssid' => 'nUserApBSSID',
    'aruba_user_name'  => 'userName',

    # WLSX-WLAN-MIB::wlsxWlanRadioTable
    'aruba_apif_ch_num' => 'wlanAPRadioChannel',
    'aruba_apif_power'  => 'wlanAPRadioTransmitPower',
    'aruba_apif_type'   => 'wlanAPRadioType',
    'aruba_apif_name'   => 'wlanAPRadioAPName',

    # WLSX-WLAN-MIB::wlsxWlanAPTable
    'aruba_ap_fqln'   => 'wlanAPFQLN',
    'aruba_ap_status' => 'wlanAPStatus',
    'aruba_ap_type'   => 'wlanAPModel',
    'aruba_ap_serial' => 'wlanAPSerialNumber',
    'aruba_ap_model'  => 'wlanAPModelName',
    'aruba_ap_name'   => 'wlanAPName',
    'aruba_ap_ip'     => 'wlanAPIpAddress',

    # WLSX-WLAN-MIB::wlsxWlanESSIDVlanPoolTable
    'aruba_ssid_vlan' => 'wlanESSIDVlanPoolStatus',

    # WLSX-WLAN-MIB::wlsxWlanAPBssidTable
    'aruba_ap_bssid_ssid' => 'wlanAPESSID',

    # We pretend to have the CISCO-DOT11-MIB for signal strengths, etc.
    # WLSX-WLAN-MIB::wlsxWlanStationTable
    'cd11_sigstrength' => 'wlanStaRSSI',
    'cd11_ssid'        => 'wlanStaAccessPointESSID',
    'cd11_uptime'      => 'wlanStaUpTime',

);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::LLDP::MUNGE,
    'aruba_ap_fqln'       => \&munge_aruba_fqln,
    'aruba_ap_type'       => \&SNMP::Info::munge_e_type,
    'aruba_card_type'     => \&SNMP::Info::munge_e_type,
    'aruba_ap_bssid_ssid' => \&SNMP::Info::munge_null,
    'aruba_user_bssid'    => \&SNMP::Info::munge_mac,
    'cd11_ssid'           => \&SNMP::Info::munge_null,

);

sub layers {
    return '00000111';
}

sub os {
    my $aruba = shift;
    my %osmap = ( 'alcatel-lucent' => 'aos-w', );
    return $osmap{ $aruba->vendor() } || 'airos';
}

sub vendor {
    my $aruba  = shift;
    my $id     = $aruba->id() || 'undef';
    my %oidmap = ( 6486 => 'alcatel-lucent', );
    $id = $1 if ( defined($id) && $id =~ /^\.1\.3\.6\.1\.4\.1\.(\d+)/ );

    if ( defined($id) and exists( $oidmap{$id} ) ) {
	return $oidmap{$id};
    }
    else {
	return 'aruba';
    }
}

sub os_ver {
    my $aruba = shift;
    my $descr = $aruba->description();
    return unless defined $descr;

    if ( $descr =~ m/Version\s+(\d+\.\d+\.\d+\.\d+)/ ) {
	return $1;
    }

    return;
}

sub model {
    my $aruba = shift;
    my $id    = $aruba->id();
    return unless defined $id;
    my $model = &SNMP::translateObj($id);
    return $id unless defined $model;

    return $model;
}

sub serial {
    my $aruba = shift;

    return $aruba->aruba_serial_old() || $aruba->aruba_serial_new();
}

# Thin APs do not support ifMIB requirement

sub i_index {
    my $aruba   = shift;
    my $partial = shift;

    my $i_index  = $aruba->orig_i_index($partial)      || {};
    my $ap_index = $aruba->aruba_apif_ch_num($partial) || {};

    my %if_index;
    foreach my $iid ( keys %$i_index ) {
	my $index = $i_index->{$iid};
	next unless defined $index;

	$if_index{$iid} = $index;
    }

    # Get Attached APs as Interfaces
    foreach my $ap_id ( keys %$ap_index ) {

	if ( $ap_id =~ /(\d+\.\d+\.\d+\.\d+\.\d+\.\d+)\.(\d+)/ ) {
	    my $mac = join( ':',
		map { sprintf( "%02x", $_ ) } split( /\./, $1 ) );
	    my $radio = $2;
	    next unless ( ( defined $mac ) and ( defined $radio ) );

	    $if_index{$ap_id} = "$mac.$radio";
	}
    }

    return \%if_index;
}

sub interfaces {
    my $aruba   = shift;
    my $partial = shift;

    my $i_index = $aruba->i_index($partial)     || {};
    my $i_name  = $aruba->orig_i_name($partial) || {};

    my %if;
    foreach my $iid ( keys %$i_index ) {
	my $index = $i_index->{$iid};
	next unless defined $index;

	if ( $index =~ /^\d+$/ ) {

	    # Replace the Index with the ifName field.
	    my $port = $i_name->{$iid};
	    next unless defined $port;
	    $if{$iid} = $port;
	}

	else {
	    $if{$iid} = $index;
	}
    }
    return \%if;
}

sub i_name {
    my $aruba   = shift;
    my $partial = shift;

    my $i_index = $aruba->i_index($partial)         || {};
    my $i_name  = $aruba->orig_i_name($partial)     || {};
    my $ap_name = $aruba->aruba_apif_name($partial) || {};

    my %i_name;
    foreach my $iid ( keys %$i_index ) {
	my $index = $i_index->{$iid};
	next unless defined $index;

	if ( $index =~ /^\d+$/ ) {
	    my $name = $i_name->{$iid};
	    next unless defined $name;
	    $i_name{$iid} = $name;
	}

	elsif ( $index =~ /(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/ ) {
	    my $name = $ap_name->{$iid};
	    next unless defined $name;
	    $i_name{$iid} = $name;
	}

	else {
	    $i_name{$iid} = $index;
	}
    }
    return \%i_name;
}

sub i_description {
    my $aruba   = shift;
    my $partial = shift;

    my $i_descr  = $aruba->orig_i_description($partial) || {};
    my $ap_index = $aruba->aruba_apif_ch_num($partial)  || {};
    my $ap_loc   = $aruba->aruba_ap_fqln($partial)      || {};

    my %descr;
    foreach my $iid ( keys %$i_descr ) {
	my $descr = $i_descr->{$iid};
	next unless defined $descr;
	$descr{$iid} = $descr;
    }

    foreach my $iid ( keys %$ap_index ) {
	my @parts = split( /\./, $iid );
	my $idx = join( ".", @parts[ 0 .. 5 ] );
	my $loc = $ap_loc->{$idx};
	next unless defined $loc;

	$descr{$iid} = $loc;
    }

    return \%descr;
}

sub i_type {
    my $aruba   = shift;
    my $partial = shift;

    my $i_type    = $aruba->orig_i_type($partial)     || {};
    my $apif_type = $aruba->aruba_apif_type($partial) || {};

    my %i_type;
    foreach my $iid ( keys %$i_type ) {
	my $type = $i_type->{$iid};
	next unless defined $type;
	$i_type{$iid} = $type;
    }

    foreach my $iid ( keys %$apif_type ) {
	my $type = $apif_type->{$iid};
	next unless defined $type;

	$i_type{$iid} = $type;
    }

    return \%i_type;
}

sub i_up {
    my $aruba   = shift;
    my $partial = shift;

    my $i_up     = $aruba->orig_i_up($partial)         || {};
    my $ap_index = $aruba->aruba_apif_ch_num($partial) || {};
    my $ap_up    = $aruba->aruba_ap_status($partial)   || {};

    my %i_up;
    foreach my $iid ( keys %$i_up ) {
	my $status = $i_up->{$iid};
	next unless defined $status;
	$i_up{$iid} = $status;
    }

    foreach my $iid ( keys %$ap_index ) {
	my @parts = split( /\./, $iid );
	my $idx = join( ".", @parts[ 0 .. 5 ] );
	my $status = $ap_up->{$idx};
	next unless defined $status;

	$i_up{$iid} = $status;
    }

    return \%i_up;
}

# Fake this for AP's since admin up if operationally up
sub i_up_admin {
    my $aruba   = shift;
    my $partial = shift;

    my $i_up     = $aruba->orig_i_up_admin($partial)   || {};
    my $ap_index = $aruba->aruba_apif_ch_num($partial) || {};
    my $ap_up    = $aruba->aruba_ap_status($partial)   || {};

    my %i_up;
    foreach my $iid ( keys %$i_up ) {
	my $status = $i_up->{$iid};
	next unless defined $status;
	$i_up{$iid} = $status;
    }

    foreach my $iid ( keys %$ap_index ) {
	my @parts = split( /\./, $iid );
	my $idx = join( ".", @parts[ 0 .. 5 ] );
	my $status = $ap_up->{$idx};
	next unless defined $status;

	$i_up{$iid} = $status;
    }

    return \%i_up;
}

sub i_mac {
    my $aruba   = shift;
    my $partial = shift;

    my $i_index = $aruba->i_index($partial)    || {};
    my $i_mac   = $aruba->orig_i_mac($partial) || {};

    my %i_mac;
    foreach my $iid ( keys %$i_index ) {
	my $index = $i_index->{$iid};
	next unless defined $index;

	if ( $index =~ /^\d+$/ ) {
	    my $mac = $i_mac->{$iid};
	    next unless defined $mac;
	    $i_mac{$iid} = $mac;
	}
	elsif ( $index =~ /(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/ ) {
	    $index =~ s/\.\d+$//;
	    next unless defined $index;
	    $i_mac{$iid} = $index;
	}
    }
    return \%i_mac;
}

sub i_duplex {
    my $aruba   = shift;
    my $partial = shift;

    my $index = $aruba->aruba_if_idx();

    if ($partial) {
	my %r_index = reverse %$index;
	$partial = $r_index{$partial};
    }

    my $ap_duplex = $aruba->aruba_if_duplex($partial) || {};
    my %i_duplex;

    foreach my $if ( keys %$ap_duplex ) {
	my $duplex = $ap_duplex->{$if};
	next unless defined $duplex;
	my $ifindex = $index->{$if};
	next unless defined $ifindex;

	$duplex = 'half' if $duplex =~ /half/i;
	$duplex = 'full' if $duplex =~ /full/i;
	$duplex = 'auto' if $duplex =~ /auto/i;
	$i_duplex{$ifindex} = $duplex;
    }
    return \%i_duplex;
}

sub v_index {
	my $aruba   = shift;
	my $partial = shift;

	return $aruba->SUPER::v_index($partial)
		if keys %{ $aruba->SUPER::v_index($partial) };

	my $v_name = $aruba->v_name($partial);
	my %v_index;
	foreach my $idx ( keys %$v_name ) {
		$v_index{$idx} = $idx;
	}
	return \%v_index;
}

sub v_name {
	my $aruba   = shift;
	my $partial = shift;

	return $aruba->SUPER::v_name() || $aruba->aruba_v_name();
}

sub i_vlan {
	my $aruba   = shift;
	my $partial = shift;

	return $aruba->SUPER::i_vlan($partial)
		if keys %{ $aruba->SUPER::i_vlan($partial) };

	my $index = $aruba->aruba_if_idx();

	if ($partial) {
		my %r_index = reverse %$index;
		$partial = $r_index{$partial};
	}

	my $i_pvid = $aruba->aruba_if_pvid($partial) || {};
	my %i_vlan;

	foreach my $port ( keys %$i_pvid ) {
		my $vlan    = $i_pvid->{$port};
		my $ifindex = $index->{$port};
		next unless defined $ifindex;

		$i_vlan{$ifindex} = $vlan;
	}

	return \%i_vlan;
}

sub i_vlan_membership {
	my $aruba   = shift;
	my $partial = shift;

	return $aruba->SUPER::i_vlan_membership($partial)
		if keys %{ $aruba->SUPER::i_vlan_membership($partial) };

	my $essid_ssid = $aruba->aruba_ap_bssid_ssid();
	my $ssid_vlans = $aruba->aruba_ssid_vlan();
	my $if_vlans   = $aruba->aruba_if_vlan_member();

	my %vlan_essid;

	# Create a hash of vlan and textual ssid
	# Possible to have more than one vlan per ssid
	foreach my $oid ( keys %$ssid_vlans ) {
		my @parts   = split( /\./, $oid );
		my $ssidlen = shift(@parts);
		my $ssid    = pack( "C*", splice( @parts, 0, $ssidlen ) );

		# Remove any control chars
		$ssid =~ s/[[:cntrl:]]//g;
		my $vlan = shift(@parts);

		$vlan_essid{$vlan} = $ssid;
	}

	my $i_vlan_membership = {};

	# Handle physical ports first
	foreach my $oid ( keys %$if_vlans ) {
		my @parts   = split( /\./, $oid );
		my $vlan    = shift(@parts);
		my $ifindex = shift(@parts);
		push( @{ $i_vlan_membership->{$ifindex} }, $vlan );
	}

	foreach my $oid ( keys %$essid_ssid ) {
		my $ssid  = $essid_ssid->{$oid};
		my @parts = split( /\./, $oid );
		my $idx   = join( ".", @parts[ 0 .. 6 ] );

		my @vlans = grep { $vlan_essid{$_} eq $ssid } keys %vlan_essid;
		foreach my $vlan (@vlans) {
			push( @{ $i_vlan_membership->{$idx} }, $vlan );
		}
	}
	return $i_vlan_membership;
}

sub i_80211channel {
    my $aruba   = shift;
    my $partial = shift;

    return $aruba->aruba_apif_ch_num($partial);
}

sub dot11_cur_tx_pwr_mw {
    my $aruba   = shift;
    my $partial = shift;

    return $aruba->aruba_apif_power($partial);
}

sub i_ssidlist {
    my $aruba   = shift;
    my $partial = shift;

    my $essid_ssid = $aruba->aruba_ap_bssid_ssid($partial) || {};

    my %i_ssidlist;

    foreach my $oid ( keys %$essid_ssid ) {
	my $ssid = $essid_ssid->{$oid};
	my @parts = split( /\./, $oid );

	# Give the SSID a numeric value based upon tail of BSSID
	my $id = pop(@parts);

	# Get i_index
	my $iid = join( ".", @parts[ 0 .. 6 ] );

	$i_ssidlist{"$iid.$id"} = $ssid;
    }

    return \%i_ssidlist;
}

sub i_ssidbcast {
    my $aruba   = shift;
    my $partial = shift;

    my $essid_ssid = $aruba->aruba_ap_bssid_ssid($partial) || {};
    my $ap_bc      = $aruba->aruba_ap_ssidbcast($partial)  || {};

    my %i_bc;
    foreach my $oid ( keys %$essid_ssid ) {
	my @parts = split( /\./, $oid );

	# Give the SSID a numeric value based upon tail of BSSID
	my $id    = $parts[-1];
	my $iid   = join( ".", splice( @parts, 0, 7 ) );
	my $bssid = join( ':', @parts );

	my $bc = $ap_bc->{$bssid};
	next unless defined $bc;
	$bc = ( $bc ? 0 : 1 );
	$i_bc{"$iid.$id"} = $bc;
    }

    return \%i_bc;
}

sub i_ssidmac {
    my $aruba   = shift;
    my $partial = shift;

    my $essid_ssid = $aruba->aruba_ap_bssid_ssid($partial) || {};

    my %i_ssidmac;

    foreach my $oid ( keys %$essid_ssid ) {
	my @parts = split( /\./, $oid );

	# Give the SSID a numeric value based upon tail of BSSID
	my $id    = $parts[-1];
	my $iid   = join( ".", splice( @parts, 0, 7 ) );
	my $bssid = join( ':', map { sprintf( "%02x", $_ ) } @parts );

	$i_ssidmac{"$iid.$id"} = $bssid;
    }

    return \%i_ssidmac;
}

# Wireless switches do not support the standard Bridge MIB
# Wired switches currently (AOS 7.2.0.0) do, but it seems only for
# dot1q ports or access ports that are 'untrusted' ?
sub bp_index {
	my $aruba   = shift;
	my $partial = shift;

	my $i_index    = $aruba->ifExtPortIfIndex($partial)    || {};
	my $essid_ssid = $aruba->aruba_ap_bssid_ssid($partial) || {};

	# Collect standard bp_index first
	my $wired_bp_index = $aruba->SUPER::bp_index($partial) || {};
	my %bp_index;
	my %offset;

	foreach my $iid ( keys %$wired_bp_index ) {
		my $index = $wired_bp_index->{$iid};
		my $delta = $iid - $index;

		$offset{$delta}++;
		$bp_index{$iid} = $index;
	}

	# If the offset between dot1dBasePortIfIndex and ifIndex is consistent
	# add potentially missing mappings
	if ( keys %offset == 1 ) {
		foreach my $iid ( keys %$i_index ) {
			my $index = $i_index->{$iid};
			next unless defined $index;

			# Only augment bp_index, don't overwrite any existing mappings
			my $iid = (keys %offset)[0] + $index;
			next if exists $bp_index{$iid};

			$bp_index{$iid} = $index;
		}
	}

	# Get Attached APs as Interfaces
	foreach my $oid ( keys %$essid_ssid ) {
		my @parts = split( /\./, $oid );
		my $iid = join( ".", splice( @parts, 0, 7 ) );
		my $bssid = join( '.', @parts );

		$bp_index{$bssid} = $iid;
	}
	return \%bp_index;
}

sub fw_port {
    my $aruba   = shift;
    my $partial = shift;

    my $fw_idx = $aruba->aruba_user_bssid($partial) || {};

    my $wired_fw_port = $aruba->SUPER::qb_fw_port($partial) || {};
    my %fw_port = %$wired_fw_port;

    foreach my $idx ( keys %$fw_idx ) {
	my $port = $fw_idx->{$idx};
	next unless $port;
	my $iid = join( '.', map { hex($_) } split( ':', $port ) );

	$fw_port{$idx} = $iid;
    }

    return \%fw_port;
}

sub fw_mac {
    my $aruba   = shift;
    my $partial = shift;

    my $fw_idx = $aruba->aruba_user_bssid($partial) || {};

    my $wired_fw_mac = $aruba->SUPER::qb_fw_mac($partial) || {};
    my %fw_mac = %$wired_fw_mac;

    foreach my $idx ( keys %$fw_idx ) {
	my @parts = split( /\./, $idx );
	my $mac = join( ':', map { sprintf( "%02x", $_ ) } @parts[ 0 .. 5 ] );

	$fw_mac{$idx} = $mac;
    }
    return \%fw_mac;
}

sub qb_fw_vlan {
    my $aruba   = shift;
    my $partial = shift;

    my $vlans = $aruba->aruba_user_vlan($partial) || {};

    my $wired_fw_vlan = $aruba->SUPER::qb_fw_vlan($partial) || {};
    my %fw_vlan = %$wired_fw_vlan;

    foreach my $idx ( keys %$vlans ) {
	my $vlan = $vlans->{$idx};
	next unless $vlan;

	$fw_vlan{$idx} = $vlan;
    }
    return \%fw_vlan;
}

sub cd11_mac {
    my $aruba            = shift;
    my $cd11_sigstrength = $aruba->cd11_sigstrength();

    my $ret = {};
    foreach my $idx ( keys %$cd11_sigstrength ) {
	my $mac = join( ":", map { sprintf "%02x", $_ } split /\./, $idx );
	$ret->{$idx} = $mac;
    }
    return $ret;
}

sub cd11_sigqual {
    my $aruba        = shift;
    my $cd11_sigqual = $aruba->aruba_cd11_sigqual();

    my $ret = {};
    foreach my $idx ( keys %$cd11_sigqual ) {
	my $value = $cd11_sigqual->{$idx};
	$idx =~ s/(.\d+){6}$//;

	$ret->{$idx} = $value;
    }
    return $ret;
}

sub cd11_txrate {
    my $aruba       = shift;
    my $cd11_txrate = $aruba->aruba_cd11_txrate();

    my $ret = {};
    foreach my $idx ( keys %$cd11_txrate ) {
	my $value = $cd11_txrate->{$idx};
	my @rates;
	if ( $value =~ /(\d+)Mbps/ ) {
	    push @rates, $1;
	}
	$idx =~ s/(.\d+){6}$//;

	$ret->{$idx} = \@rates;
    }
    return $ret;
}

sub cd11_rxbyte {
    my $aruba       = shift;
    my $cd11_rxbyte = $aruba->aruba_cd11_rxbyte();

    my $ret = {};
    foreach my $idx ( keys %$cd11_rxbyte ) {
	my $value = $cd11_rxbyte->{$idx};
	$idx =~ s/(.\d+){6}$//;

	$ret->{$idx} = $value;
    }
    return $ret;
}

sub cd11_txbyte {
    my $aruba       = shift;
    my $cd11_txbyte = $aruba->aruba_cd11_txbyte();

    my $ret = {};
    foreach my $idx ( keys %$cd11_txbyte ) {
	my $value = $cd11_txbyte->{$idx};
	$idx =~ s/(.\d+){6}$//;

	$ret->{$idx} = $value;
    }
    return $ret;
}

sub cd11_rxpkt {
    my $aruba      = shift;
    my $cd11_rxpkt = $aruba->aruba_cd11_rxpkt();

    my $ret = {};
    foreach my $idx ( keys %$cd11_rxpkt ) {
	my $value = $cd11_rxpkt->{$idx};
	$idx =~ s/(.\d+){6}$//;

	$ret->{$idx} = $value;
    }
    return $ret;
}

sub cd11_txpkt {
    my $aruba      = shift;
    my $cd11_txpkt = $aruba->aruba_cd11_txpkt();

    my $ret = {};
    foreach my $idx ( keys %$cd11_txpkt ) {
	my $value = $cd11_txpkt->{$idx};
	$idx =~ s/(.\d+){6}$//;

	$ret->{$idx} = $value;
    }
    return $ret;
}

# Pseudo ENTITY-MIB methods

sub e_index {
    my $aruba = shift;

    my $ap_model = $aruba->aruba_ap_model()    || {};
    my $ap_cards = $aruba->aruba_card_serial() || {};
    my %e_index;

    # Chassis
    $e_index{0} = 1;

    # Cards
    foreach my $idx ( keys %$ap_cards ) {
	$e_index{$idx} = $idx + 1;
    }

    # We're going to hack an index to capture APs
    foreach my $idx ( keys %$ap_model ) {

       # Create the integer index by joining the last three octets of the MAC.
       # Hopefully, this will be unique since the manufacturer should be
       # limited to Aruba.  We can't use the entire MAC since
       # we would exceed the integer size limit.
	if ( $idx =~ /(\d+\.\d+\.\d+)$/ ) {
	    my $index = int(
		join( '', map { sprintf "%03d", $_ } split /\./, $1 ) );
	    $e_index{$idx} = $index;
	}
    }
    return \%e_index;
}

sub e_class {
    my $aruba = shift;

    my $e_idx = $aruba->e_index() || {};

    my %e_class;
    foreach my $iid ( keys %$e_idx ) {
	if ( $iid eq 0 ) {
	    $e_class{$iid} = 'chassis';
	}
	elsif ( $iid =~ /\d+/ ) {
	    $e_class{$iid} = 'module';
	}

	# This isn't a valid PhysicalClass, but we're hacking this anyway
	else {
	    $e_class{$iid} = 'ap';
	}
    }
    return \%e_class;
}

sub e_name {
    my $aruba = shift;

    my $e_idx = $aruba->e_index() || {};

    my %e_name;
    foreach my $iid ( keys %$e_idx ) {
	if ( $iid eq 0 ) {
	    $e_name{$iid} = 'WLAN Controller';
	}
	elsif ( $iid =~ /^\d+$/ ) {
	    $e_name{$iid} = "Card $iid";
	}
	else {

	    # APs
	    $e_name{$iid} = 'AP';
	}
    }
    return \%e_name;
}

sub e_descr {
    my $aruba = shift;

    my $ap_model  = $aruba->aruba_ap_model()  || {};
    my $ap_name   = $aruba->aruba_ap_name()   || {};
    my $ap_loc    = $aruba->aruba_ap_fqln()   || {};
    my $card_type = $aruba->aruba_card_type() || {};
    my $card_assy = $aruba->aruba_card_no()   || {};

    my %e_descr;

    # Chassis
    $e_descr{0} = $aruba->aruba_model();

    #Cards
    foreach my $iid ( keys %$card_type ) {
	my $card = $card_type->{$iid};
	next unless defined $card;
	my $assy = $card_assy->{$iid} || 'unknown';

	$e_descr{$iid} = "$card Assembly: $assy";
    }

    # APs
    foreach my $iid ( keys %$ap_name ) {
	my $name = $ap_name->{$iid};
	next unless defined $name;
	my $model = $ap_model->{$iid} || 'AP';
	my $loc   = $ap_loc->{$iid}   || 'unknown';

	$e_descr{$iid} = "$model: $name ($loc)";
    }
    return \%e_descr;
}

sub e_model {
    my $aruba = shift;

    my $ap_model   = $aruba->aruba_ap_model()  || {};
    my $card_model = $aruba->aruba_card_type() || {};

    my %e_model;

    # Chassis
    $e_model{0} = $aruba->aruba_model();

    #Cards
    foreach my $iid ( keys %$card_model ) {
	my $card = $card_model->{$iid};
	next unless defined $card;

	$e_model{$iid} = $card;
    }

    # APs
    foreach my $iid ( keys %$ap_model ) {
	my $model = $ap_model->{$iid};
	next unless defined $model;

	$e_model{$iid} = $model;
    }
    return \%e_model;
}

sub e_type {
    my $aruba = shift;

    return $aruba->aruba_ap_type() || {};
}

sub e_hwver {
    my $aruba = shift;

    my $ap_hw   = $aruba->aruba_card_hw()   || {};
    my $ap_fpga = $aruba->aruba_card_fpga() || {};

    my %e_hwver;

    # Cards
    foreach my $iid ( keys %$ap_hw ) {
	my $hw = $ap_hw->{$iid};
	next unless defined $hw;
	my $fpga = $ap_fpga->{$iid} || 'unknown';

	$e_hwver{$iid} = "$hw $fpga";
    }
    return \%e_hwver;
}

sub e_vendor {
    my $aruba = shift;

    my $e_idx = $aruba->e_index() || {};

    my %e_vendor;
    foreach my $iid ( keys %$e_idx ) {
	$e_vendor{$iid} = 'aruba';
    }
    return \%e_vendor;
}

sub e_serial {
    my $aruba = shift;

    my $ap_serial   = $aruba->aruba_ap_serial()   || {};
    my $card_serial = $aruba->aruba_card_serial() || {};

    my %e_serial;

    # Chassis
    $e_serial{0} = $aruba->serial() || '';

    # Cards
    foreach my $iid ( keys %$card_serial ) {
	my $serial = $card_serial->{$iid};
	next unless defined $serial;

	$e_serial{$iid} = $serial;
    }

    # APs
    foreach my $iid ( keys %$ap_serial ) {
	my $serial = $ap_serial->{$iid};
	next unless defined $serial;

	$e_serial{$iid} = $serial;
    }
    return \%e_serial;
}

sub e_pos {
    my $aruba = shift;

    my $e_idx = $aruba->e_index() || {};

    my %e_pos;

    # $pos is for AP's, set it high enough that cards come first
    my $pos = 100;
    foreach my $iid ( sort keys %$e_idx ) {
	if ( $iid eq 0 ) {
	    $e_pos{$iid} = -1;
	    next;
	}
	elsif ( $iid =~ /^\d+$/ ) {
	    $e_pos{$iid} = $iid;
	    next;
	}
	else {
	    $pos++;
	    $e_pos{$iid} = $pos;
	}
    }
    return \%e_pos;
}

sub e_parent {
    my $aruba = shift;

    my $e_idx = $aruba->e_index() || {};

    my %e_parent;
    foreach my $iid ( sort keys %$e_idx ) {
	if ( $iid eq 0 ) {
	    $e_parent{$iid} = 0;
	    next;
	}
	else {
	    $e_parent{$iid} = 1;
	}
    }
    return \%e_parent;
}

# arpnip:
#
# This is the controller snooping on the MAC->IP mappings.
# Pretending this is arpnip data allows us to get MAC->IP
# mappings even for stations that only communicate locally.

# We also use the controller's knowledge of the APs' MAC and
# IP addresses to augment the data.

sub at_paddr {
    my $aruba    = shift;
    my $user_mac = $aruba->aruba_user_bssid();

    my $ap_ip      = $aruba->aruba_ap_ip();

    my %at_paddr;
    foreach my $idx ( keys %$user_mac ) {
	$idx =~ s/(.\d+){4}$//;
	my $mac = join( ":", map { sprintf "%02x", $_ } split /\./, $idx );
	next unless $mac;
	$at_paddr{$idx} = $mac;
    }

    foreach my $idx ( keys %$ap_ip ) {
        next if ( $ap_ip->{$idx} eq '0.0.0.0' );
	my $mac = join( ":", map { sprintf "%02x", $_ } split /\./, $idx );
	$at_paddr{$idx} = $mac;
    }
    return \%at_paddr;
}

sub at_netaddr {
    my $aruba    = shift;
    my $user_mac = $aruba->aruba_user_bssid();

    my $ap_ip      = $aruba->aruba_ap_ip();

    my %at_netaddr;

    foreach my $idx ( keys %$ap_ip ) {
	next if ( $ap_ip->{$idx} eq '0.0.0.0' );
	$at_netaddr{$idx} = $ap_ip->{$idx};
    }
    foreach my $idx ( keys %$user_mac ) {
	my @parts = split( /\./, $idx );
	my $iid = join( ".", splice( @parts, 0, 6 ) );
	my $ip = join( ".", @parts );
	next unless ( $ip =~ /^(\d+\.){3}(\d+)$/ );
	next if ( $idx eq '0.0.0.0' );
	$at_netaddr{$iid} = $ip;
    }
    return \%at_netaddr;
}

sub munge_aruba_fqln {
    my $loc = shift;
    $loc =~ s/\\\.0//g;
    return $loc;
}

# The index of wlsxPsePortTable is wlsxPsePortIndex which equals
# ifIndex; however, to emulate POWER-ETHERNET-MIB we need a "module.port"
# index.  If ifDescr has the format x/x/x use it to determine the module
# otherwise default to 1.  Unfortunately, this means we can't map any
# wlsxPsePortTable leafs directly and partials will not be supported.
sub peth_port_ifindex {
    my $aruba = shift;

    my $indexes = $aruba->wlsxPsePortAdminStatus();
    my $descrs  = $aruba->i_description();

    my $peth_port_ifindex = {};
    foreach my $i ( keys %$indexes ) {
        my $descr = $descrs->{$i};
        next unless $descr;

        my $new_idx = "1.$i";

        if ( $descr =~ /(\d+)\/\d+\/\d+/ ) {
            $new_idx = "$1.$i";
        }
        $peth_port_ifindex->{$new_idx} = $i;
    }
    return $peth_port_ifindex;
}

sub peth_port_admin {
    my $aruba = shift;

    my $p_index      = $aruba->peth_port_ifindex()     || {};
    my $admin_states = $aruba->wlsxPsePortAdminStatus() || {};

    my $peth_port_admin = {};
    foreach my $i ( keys %$p_index ) {
        my ( $module, $port ) = split( /\./, $i );
        my $state = $admin_states->{$port};

        if ( $state =~ /enable/ ) {
            $peth_port_admin->{$i} = 'true';
        }
        else {
            $peth_port_admin->{$i} = 'false';
        }
    }
    return $peth_port_admin;
}

sub peth_port_neg_power {
    my $aruba = shift;

    my $p_index    = $aruba->peth_port_ifindex()         || {};
    my $port_alloc = $aruba->wlsxPsePortPowerAllocated() || {};

    my $peth_port_neg_power = {};
    foreach my $i ( keys %$p_index ) {
        my ( $module, $port ) = split( /\./, $i );
        my $power = $port_alloc->{$port};
        next unless $power;

        $peth_port_neg_power->{$i} = $power;
    }
    return $peth_port_neg_power;
}

sub peth_port_power {
    my $aruba = shift;

    my $p_index       = $aruba->peth_port_ifindex()        || {};
    my $port_consumed = $aruba->wlsxPsePortPowerConsumed() || {};

    my $peth_port_power = {};
    foreach my $i ( keys %$p_index ) {
        my ( $module, $port ) = split( /\./, $i );
        my $power = $port_consumed->{$port};
        next unless $power;

        $peth_port_power->{$i} = $power;
    }
    return $peth_port_power;
}

sub peth_port_class {
    my $aruba = shift;

    my $p_index    = $aruba->peth_port_ifindex()  || {};
    my $port_class = $aruba->wlsxPsePortPdClass() || {};

    my $peth_port_class = {};
    foreach my $i ( keys %$p_index ) {
        my ( $module, $port ) = split( /\./, $i );
        my $power = $port_class->{$port};
        next unless $power;

        $peth_port_class->{$i} = $power;
    }
    return $peth_port_class;
}

sub peth_port_status {
    my $aruba = shift;

    my $p_index      = $aruba->peth_port_ifindex() || {};
    my $admin_states = $aruba->wlsxPsePortState()  || {};

    my $peth_port_status = {};
    foreach my $i ( keys %$p_index ) {
        my ( $module, $port ) = split( /\./, $i );
        my $state = $admin_states->{$port};

        if ( $state eq 'on' ) {
            $peth_port_status->{$i} = 'deliveringPower';
        }
        else {
            $peth_port_status->{$i} = 'disabled';
        }
    }
    return $peth_port_status;
}

sub peth_power_status {
    my $aruba   = shift;
    my $partial = shift;

    my $watts = $aruba->wlsxPseSlotPowerAvailable($partial) || {};

	my $offset = (exists $watts->{0}) ? 1 : 0;

    my $peth_power_status = {};
    foreach my $i ( keys %$watts ) {
        $peth_power_status->{$i + $offset} = 'on';
    }
    return $peth_power_status;
}

sub peth_power_watts {
    my $aruba   = shift;
    my $partial = shift;

    my $watts_total = $aruba->wlsxPseSlotPowerAvailable($partial) || {};

    my $offset = (exists $watts_total->{0}) ? 1 : 0;

    my $peth_power_watts = {};
    foreach my $i ( keys %$watts_total ) {
        my $total = $watts_total->{$i};
        next unless $total;

        $peth_power_watts->{$i + $offset} = $total;
    }
    return $peth_power_watts;
}

sub peth_power_consumption {
    my $aruba   = shift;

    my $watts = $aruba->wlsxPseSlotPowerConsumption() || {};

    my $offset = (exists $watts->{0}) ? 1 : 0;

    my $peth_power_consumed = {};
    foreach my $i ( keys %$watts ) {
        my $total = $watts->{$i};
        next unless $total;

        $peth_power_consumed->{$i + $offset} = $total;
    }
    return $peth_power_consumed;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer3::Aruba - SNMP Interface to Aruba wireless switches

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

    my $aruba = new SNMP::Info(
			  AutoSpecify => 1,
			  Debug       => 1,
			  DestHost    => 'myswitch',
			  Community   => 'public',
			  Version     => 2
			) 

    or die "Can't connect to DestHost.\n";

    my $class = $aruba->class();
    print " Using device sub class : $class\n";

=head1 DESCRIPTION

SNMP::Info::Layer3::Aruba is a subclass of SNMP::Info that provides an
interface to Aruba wireless switches.  The Aruba platform utilizes
intelligent wireless switches which control thin access points.  The thin
access points themselves are unable to be polled for end station information.

This class emulates bridge functionality for the wireless switch. This enables
end station MAC addresses collection and correlation to the thin access point
the end station is using for communication.

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

 my $aruba = new SNMP::Info::Layer3::Aruba(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<WLSR-AP-MIB>

=item F<WLSX-IFEXT-MIB>

=item F<WLSX-POE-MIB>

=item F<WLSX-SWITCH-MIB>

=item F<WLSX-SYSTEMEXT-MIB>

=item F<WLSX-USER-MIB>

=item F<WLSX-WLAN-MIB>

=back

=head2 Inherited MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $aruba->model()

Returns model type.  Cross references $aruba->id() with product IDs in the 
Aruba MIB.

=item $aruba->vendor()

Returns 'aruba'

=item $aruba->os()

Returns 'airos'

=item $aruba->os_ver()

Returns the software version extracted from C<sysDescr>

=back

=head2 Overrides

=over

=item $aruba->layers()

Returns 00000111.  Class emulates Layer 2 and Layer 3functionality for
Thin APs through proprietary MIBs.

=item $aruba->serial()

Returns the device serial number extracted
from C<wlsxSwitchLicenseSerialNumber> or C<wlsxSysExtLicenseSerialNumber>

=back

=head2 Globals imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $aruba->i_80211channel()

Returns reference to hash.  Current operating frequency channel of the radio
interface.

(C<wlanAPRadioChannel>)

=item $aruba->dot11_cur_tx_pwr_mw()

Returns reference to hash.  Current transmit power, in milliwatts, of the
radio interface.

(C<wlanAPRadioTransmitPower>)

=item $aruba->i_ssidlist()

Returns reference to hash.  SSID's recognized by the radio interface.

(C<wlanAPESSID>)

=item $aruba->i_ssidbcast()

Returns reference to hash.  Indicates whether the SSID is broadcast, true or
false.

(C<wlsrHideSSID>)

=item $aruba->i_ssidmac()

With the same keys as i_ssidlist, returns the Basic service set
identification (BSSID), MAC address, the AP is using for the SSID. 

=item $aruba->cd11_mac()

Returns client radio interface MAC addresses.

=item $aruba->cd11_sigqual()

Returns client signal quality.

=item $aruba->cd11_txrate()

Returns to hash of arrays.  Client transmission speed in Mbs.

=item $aruba->cd11_rxbyte()

Total bytes received by the wireless client.

=item $aruba->cd11_txbyte()

Total bytes transmitted by the wireless client.

=item $aruba->cd11_rxpkt()

Total packets received by the wireless client.

=item $aruba->cd11_txpkt()

Total packets transmitted by the wireless client.

=back

=head2 Overrides

=over

=item $aruba->i_index()

Returns reference to map of IIDs to Interface index. 

Extends C<ifIndex> to support APs as device interfaces.

=item $aruba->interfaces()

Returns reference to map of IIDs to ports.  Thin APs are implemented as
device interfaces.  The thin AP MAC address and radio number
(C<wlanAPRadioNumber>) are combined as the port identifier.

=item $aruba->i_name()

Interface name.  Returns (C<ifName>) for Ethernet interfaces and
(C<wlanAPRadioAPName>) for AP interfaces.

=item $aruba->i_description()

Returns reference to map of IIDs to interface descriptions.  Returns
C<ifDescr> for Ethernet interfaces and the Fully Qualified Location Name
(C<wlanAPFQLN>) for AP interfaces.

=item $aruba->i_type()

Returns reference to map of IIDs to interface types.  Returns
C<ifType> for Ethernet interfaces and C<wlanAPRadioType> for AP
interfaces.

=item $aruba->i_up()

Returns reference to map of IIDs to link status of the interface.  Returns
C<ifOperStatus> for Ethernet interfaces and C<wlanAPStatus> for AP
interfaces.

=item $aruba->i_up_admin()

Returns reference to map of IIDs to administrative status of the interface.
Returns C<ifAdminStatus> for Ethernet interfaces and C<wlanAPStatus> 
for AP interfaces.

=item $aruba->i_mac()

Interface MAC address.  Returns interface MAC address for Ethernet
interfaces of ports and APs.

=item $aruba->i_duplex()

Returns reference to map of IIDs to current link duplex.  Ethernet interfaces
only.

=item $aruba->v_index()

Returns VLAN IDs.

=item $aruba->v_name()

Human-entered name for vlans.

=item $aruba->i_vlan()

Returns reference to map of IIDs to VLAN ID of the interface.

=item $aruba->i_vlan_membership()

Returns reference to hash of arrays: key = C<ifIndex>, value = array of VLAN
IDs.  These are the VLANs for which the port is a member.

=item $aruba->bp_index()

Augments the bridge MIB by returning reference to a hash containing the
index mapping of BSSID to device port (AP).

=item $aruba->fw_port()

Augments the bridge MIB by including the BSSID a wireless end station is
communicating through (C<nUserApBSSID>).

=item $aruba->fw_mac()

Augments the bridge MIB by including the wireless end station MAC
(C<nUserApBSSID>) as extracted from the IID.

=item $aruba->qb_fw_vlan()

Augments the bridge MIB by including wireless end station VLANs
(C<nUserCurrentVlan>).

=back

=head2 Pseudo F<ENTITY-MIB> information

These methods emulate F<ENTITY-MIB> Physical Table methods using
F<WLSX-WLAN-MIB> and F<WLSX-SYSTEMEXT-MIB>.  APs are included as
subcomponents of the wireless controller.

=over

=item $aruba->e_index()

Returns reference to hash.  Key: IID and Value: Integer. The index for APs is
created with an integer representation of the last three octets of the
AP MAC address.

=item $aruba->e_class()

Returns reference to hash.  Key: IID, Value: General hardware type.  Returns
'ap' for wireless access points.

=item $aruba->e_name()

More computer friendly name of entity.  Name is 'WLAN Controller' for the
chassis, Card # for modules, or 'AP'.

=item $aruba->e_descr()

Returns reference to hash.  Key: IID, Value: Human friendly name.

=item $aruba->e_model()

Returns reference to hash.  Key: IID, Value: Model name.

=item $aruba->e_type()

Returns reference to hash.  Key: IID, Value: Type of component.

=item $aruba->e_hwver()

Returns reference to hash.  Key: IID, Value: Hardware revision.

=item $aruba->e_vendor()

Returns reference to hash.  Key: IID, Value: aruba.

=item $aruba->e_serial()

Returns reference to hash.  Key: IID, Value: Serial number.

=item $aruba->e_pos()

Returns reference to hash.  Key: IID, Value: The relative position among all
entities sharing the same parent. Chassis cards are ordered to come before
APs.

=item $aruba->e_parent()

Returns reference to hash.  Key: IID, Value: The value of e_index() for the
entity which 'contains' this entity.

=back

=head2 Power Over Ethernet Port Table

These methods emulate the F<POWER-ETHERNET-MIB> Power Source Entity (PSE)
Port Table C<pethPsePortTable> methods using the F<WLSX-POE-MIB> Power
over Ethernet Port Table C<wlsxPsePortTable>.

=over

=item $aruba->peth_port_ifindex()

Creates an index of module.port to align with the indexing of the
C<wlsxPsePortTable> with a value of C<ifIndex>.  The module defaults 1
if otherwise unknown.

=item $aruba->peth_port_admin()

Administrative status: is this port permitted to deliver power?

C<wlsxPsePortAdminStatus>

=item $aruba->peth_port_status()

Current status: is this port delivering power.

=item $aruba->peth_port_class()

Device class: if status is delivering power, this represents the 802.3af
class of the device being powered.

=item $aruba->peth_port_neg_power()

The power, in milliwatts, that has been committed to this port.
This value is derived from the 802.3af class of the device being
powered.

=item $aruba->peth_port_power()

The power, in milliwatts, that the port is delivering.

=back

=head2 Power Over Ethernet Module Table

These methods emulate the F<POWER-ETHERNET-MIB> Main Power Source Entity
(PSE) Table C<pethMainPseTable> methods using the F<WLSX-POE-MIB> Power
over Ethernet Port Table C<wlsxPseSlotTable>.

=over

=item $aruba->peth_power_watts()

The power supply's capacity, in watts.

=item $aruba->peth_power_status()

The power supply's operational status.

=item $aruba->peth_power_consumption()

How much power, in watts, this power supply has been committed to
deliver.

=back

=head2 Arp Cache Table Augmentation

The controller has knowledge of MAC->IP mappings for wireless clients.
Augmenting the arp cache data with these MAC->IP mappings enables visibility
for stations that only communicate locally.  We also capture the AP MAC->IP
mappings.

=over

=item $aruba->at_paddr()

Adds MAC addresses extracted from the index of C<nUserApBSSID>.

=item $aruba->at_netaddr()

Adds IP addresses extracted from the index of C<nUserApBSSID>.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head1 Data Munging Callback Subroutines

=over

=item $aruba->munge_aruba_fqln()

Remove nulls encoded as '\.0' from the Fully Qualified Location Name
(C<wlanAPFQLN>).

=back

=cut
