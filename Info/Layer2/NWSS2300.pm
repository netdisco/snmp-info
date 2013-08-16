# SNMP::Info::Layer2::NWSS2300
#
# Copyright (c) 2012 Eric Miller
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

package SNMP::Info::Layer2::NWSS2300;

use strict;
use Exporter;
use SNMP::Info;
use SNMP::Info::Bridge;

@SNMP::Info::Layer2::NWSS2300::ISA
    = qw/SNMP::Info SNMP::Info::Bridge Exporter/;
@SNMP::Info::Layer2::NWSS2300::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE/;

$VERSION = '3.05';

%MIBS = (
    %SNMP::Info::MIBS,
    %SNMP::Info::Bridge::MIBS,
    'NTWS-REGISTRATION-DEVICES-MIB' => 'ntwsSwitch2380',
    'NTWS-AP-STATUS-MIB'            => 'ntwsApStatNumAps',
    'NTWS-CLIENT-SESSION-MIB'       => 'ntwsClSessTotalSessions',
    'NTWS-SYSTEM-MIB'               => 'ntwsSysCpuAverageLoad',
    'NTWS-BASIC-MIB'                => 'ntwsVersionString',
);

%GLOBALS = (
    %SNMP::Info::GLOBALS,
    %SNMP::Info::Bridge::GLOBALS,
    'os_ver' => 'ntwsVersionString',
    'serial' => 'ntwsSerialNumber',
    'mac'    => 'dot1dBaseBridgeAddress',
);

%FUNCS = (
    %SNMP::Info::FUNCS,
    %SNMP::Info::Bridge::FUNCS,

    # NTWS-AP-STATUS-MIB::ntwsApStatApStatusTable
    'nwss2300_ap_mac'      => 'ntwsApStatApStatusBaseMac',
    'nwss2300_ap_name'     => 'ntwsApStatApStatusApName',
    'nwss2300_ap_ip'       => 'ntwsApStatApStatusIpAddress',
    #'nwss2300_ap_loc'      => 'bsnAPLocation',
    'nwss2300_ap_sw'       => 'ntwsApStatApStatusSoftwareVer',
    'nwss2300_ap_fw'       => 'ntwsApStatApStatusBootVer',
    'nwss2300_ap_model'    => 'ntwsApStatApStatusModel',
    'nwss2300_ap_type'     => 'ntwsApStatApStatusModel',
    'nwss2300_ap_status'   => 'ntwsApStatApStatusApState',
    'nwss2300_ap_vendor'   => 'ntwsApStatApStatusManufacturerId',
    'nwss2300_ap_num'      => 'ntwsApStatApStatusApNum',
    'nwss2300_ap_dapnum'   => 'ntwsApStatApStatusPortOrDapNum',

    # NTWS-AP-STATUS-MIB::ntwsApStatRadioStatusTable
    'nwss2300_apif_mac'    => 'ntwsApStatRadioStatusBaseMac',
    'nwss2300_apif_type'   => 'ntwsApStatRadioStatusRadioPhyType',
    'nwss2300_apif_ch_num' => 'ntwsApStatRadioStatusCurrentChannelNum',
    'nwss2300_apif_power'  => 'ntwsApStatRadioStatusCurrentPowerLevel',
    'nwss2300_apif_admin'  => 'ntwsApStatRadioStatusRadioMode',

    # NTWS-AP-STATUS-MIB::ntwsApStatRadioServiceTable
    'nwss2300_apif_prof'   => 'ntwsApStatRadioServServiceProfileName',

    # NTWS-AP-CONFIG-MIB::ntwsApConfServiceProfileTable
    'nwss2300_ess_bcast'   => 'ntwsApConfServProfBeaconEnabled',

    # NTWS-AP-CONFIG-MIB::ntwsApConfRadioConfigTable
    'nwss2300_apcr_txpwr'  => 'ntwsApConfRadioConfigTxPower',
    'nwss2300_apcr_ch'     => 'ntwsApConfRadioConfigChannel',
    'nwss2300_apcr_mode'   => 'ntwsApConfRadioConfigRadioMode',

    # NTWS-AP-CONFIG-MIB::ntwsApConfApConfigTable
    'nwss2300_apc_descr'   => 'ntwsApConfApConfigDescription',
    'nwss2300_apc_loc'     => 'ntwsApConfApConfigLocation',
    'nwss2300_apc_name'    => 'ntwsApConfApConfigApName',
    'nwss2300_apc_model'   => 'ntwsApConfApConfigApModelName',
    'nwss2300_apc_serial'  => 'ntwsApConfApConfigApSerialNum',

    # NTWS-CLIENT-SESSION-MIB::ntwsClSessClientSessionTable
    'nwss2300_sta_slot'    => 'ntwsClSessClientSessRadioNum',
    'nwss2300_sta_serial'  => 'ntwsClSessClientSessApSerialNum',
    'nwss2300_sta_ssid'    => 'ntwsClSessClientSessSsid',
    'nwss2300_sta_ip'      => 'ntwsClSessClientSessIpAddress',

    # NTWS-AP-STATUS-MIB::ntwsApStatRadioServiceTable
    'nwss2300_apif_bssid'  => 'ntwsApStatRadioServBssid',

    # NTWS-CLIENT-SESSION-MIB::ntwsClSessClientSessionStatisticsTable
    # Pretend to have the CISCO-DOT11-MIB for signal strengths, etc.
    'cd11_sigstrength' => 'ntwsClSessClientSessStatsLastRssi',
    'cd11_sigqual'     => 'ntwsClSessClientSessStatsLastSNR',
    'cd11_txrate'      => 'ntwsClSessClientSessStatsLastRate',
    # These are supposed to be there...
    'cd11_rxbyte'      => 'ntwsClSessClientSessStatsUniOctetIn',
    'cd11_txbyte'      => 'ntwsClSessClientSessStatsUniOctetOut',
    'cd11_rxpkt'       => 'ntwsClSessClientSessStatsUniPktIn',
    'cd11_txpkt'       => 'ntwsClSessClientSessStatsUniPktOut',
);

%MUNGE = (
    %SNMP::Info::MUNGE,
    %SNMP::Info::Bridge::MUNGE,
    'nwss2300_apif_mac'      => \&SNMP::Info::munge_mac,
    'nwss2300_apif_bssid'    => \&SNMP::Info::munge_mac,
);

sub layers {
    return '00000111';
}

sub os {
    return 'trapeze';
}

sub vendor {
    return 'avaya';
}

sub model {
    my $nwss2300 = shift;
    my $id = $nwss2300->id();

    unless ( defined $id ) {
        print
            " SNMP::Info::Layer2::NWSS2300::model() - Device does not support sysObjectID\n"
            if $nwss2300->debug();
        return;
    }

    my $model = &SNMP::translateObj($id);

    return $id unless defined $model;

    $model =~ s/^ntwsSwitch//i;
    return $model;    
}

sub _ap_serial {
    my $nwss2300 = shift;
    my $partial  = shift;

    my $names = $nwss2300->nwss2300_ap_name($partial) || {};

    my %ap_serial;
    foreach my $iid ( keys %$names ) {
        next unless $iid;

        my $serial = join( '', map { sprintf "%c", $_ } split /\./, $iid );
	# Remove any control characters to include nulls
        $serial =~ s/[\c@-\c_]//g;

        $ap_serial{$iid} = "$serial";
    }
    return \%ap_serial;
}

# Wireless switches do not support ifMIB requirements to get MAC
# and port status

sub i_index {
    my $nwss2300 = shift;
    my $partial  = shift;

    my $i_index  = $nwss2300->orig_i_index($partial)      || {};
    my $ap_index = $nwss2300->nwss2300_apif_mac($partial) || {};

    my %if_index;
    foreach my $iid ( keys %$i_index ) {
        my $index = $i_index->{$iid};
        next unless defined $index;

        $if_index{$iid} = $index;
    }

    # Get Attached APs as Interfaces
    foreach my $ap_id ( keys %$ap_index ) {
	
	my $mac = $ap_index->{$ap_id};
        next unless ($mac);

        $if_index{$ap_id} = $mac;
    }

    return \%if_index;
}

sub interfaces {
    my $nwss2300 = shift;
    my $partial  = shift;

    my $i_index      = $nwss2300->i_index($partial)              || {};
    my $descriptions = $nwss2300->SUPER::i_description($partial) || {};

    my %if;
    foreach my $iid ( keys %$i_index ) {
        my $desc = $descriptions->{$iid} || $i_index->{$iid};
        next unless defined $desc;

        $if{$iid} = $desc;
    }

    return \%if;
}

sub i_description {
    my $nwss2300 = shift;
    my $partial  = shift;

    my $i_index = $nwss2300->i_index($partial)            || {};
    my $i_desc  = $nwss2300->orig_i_description($partial) || {};
    my $ap_name = $nwss2300->nwss2300_ap_name($partial)   || {};

    my %i_name;
    foreach my $iid ( keys %$i_index ) {
        my $index = $i_index->{$iid};
        next unless defined $index;

        if ( $index =~ /^\d+$/ ) {
            my $name = $i_desc->{$iid};
            next unless defined $name;
            $i_name{$iid} = $name;
        }

        elsif ( $index =~ /(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/ ) {
            my $idx = $iid;
            $idx =~ s/\.(\d+)$//;
	    my $radio = $1;
	    $radio--;
            my $name = $ap_name->{$idx};
            next unless defined $name;
            $i_name{$iid} = "Radio-$radio: $name";
        }

        else {
            $i_name{$iid} = $index;
        }
    }
    return \%i_name;
}

sub i_name {
    my $nwss2300 = shift;
    my $partial  = shift;

    return $nwss2300->i_description($partial);
}

sub i_type {
    my $nwss2300 = shift;
    my $partial  = shift;

    my $i_index   = $nwss2300->i_index($partial)     || {};
    my $i_type    = $nwss2300->orig_i_type($partial) || {};

    my %i_type;
    foreach my $iid ( keys %$i_index ) {
        my $index = $i_index->{$iid};
        next unless defined $index;

        if ( $index =~ /^\d+$/ ) {
            my $type = $i_type->{$iid};
            next unless defined $type;
            $i_type{$iid} = $type;
        }

        elsif ( $index =~ /(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/ ) {
	    # Match to an ifType
            $i_type{$iid} = 'capwapWtpVirtualRadio';
        }

        else {
            next;
        }
    }
    return \%i_type;
}

sub i_up {
    my $nwss2300 = shift;
    my $partial   = shift;

    return $nwss2300->i_up_admin($partial);
}

sub i_up_admin {
    my $nwss2300 = shift;
    my $partial   = shift;

    my $i_index = $nwss2300->i_index($partial)             || {};
    my $i_up    = $nwss2300->orig_i_up($partial)           || {};
    my $apif_up = $nwss2300->nwss2300_apif_admin($partial) || {};

    my %i_up_admin;
    foreach my $iid ( keys %$i_index ) {
        my $index = $i_index->{$iid};
        next unless defined $index;

        if ( $index =~ /^\d+$/ ) {
            my $stat = $i_up->{$iid};
            next unless defined $stat;
            $i_up_admin{$iid} = $stat;
        }

        elsif ( $index =~ /(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/ ) {
            my $stat = $apif_up->{$iid};
            next unless defined $stat;
            $i_up_admin{$iid} = $stat;
        }

        else {
            next;
        }
    }
    return \%i_up_admin;
}

sub i_mac {
    my $nwss2300 = shift;
    my $partial  = shift;

    my $i_index = $nwss2300->i_index($partial)    || {};
    my $i_mac   = $nwss2300->orig_i_mac($partial) || {};

    my %i_mac;
    foreach my $iid ( keys %$i_index ) {
        my $index = $i_index->{$iid};
        next unless defined $index;

        if ( $index =~ /^\d+$/ ) {
            my $mac = $i_mac->{$iid};
            next unless defined $mac;
            $i_mac{$iid} = $mac;
        }

        # Don't grab AP MACs - we want the AP to show up on edge switch
        # ports

        else {
            next;
        }
    }
    return \%i_mac;
}

# Wireless switches do not support the standard Bridge MIB for client devices
sub bp_index {
    my $nwss2300 = shift;
    my $partial  = shift;

    my $i_index = $nwss2300->i_index($partial) || {};

    my %bp_index;
    foreach my $iid ( keys %$i_index ) {
        my $index = $i_index->{$iid};
        next unless defined $index;

        $bp_index{$index} = $iid;
    }
    return \%bp_index;
}

sub fw_mac {
    my $nwss2300 = shift;
    my $partial  = shift;
    
    my $serials = $nwss2300->nwss2300_sta_serial($partial) || {};

    my %fw_mac;
    foreach my $iid ( keys %$serials ) {
        next unless $iid;

        my $mac = join( ':', map { sprintf "%02x", $_ } split /\./, $iid );
        next unless $mac =~ /^([0-9A-F][0-9A-F]:){5}[0-9A-F][0-9A-F]$/i;
	
        $fw_mac{$iid} = $mac;
    }
    return \%fw_mac;    
}

sub fw_port {
    my $nwss2300 = shift;
    my $partial  = shift;

    my $slots      = $nwss2300->nwss2300_sta_slot($partial) || {};
    my $serials    = $nwss2300->nwss2300_sta_serial($partial) || {};
    my $ap_serials = $nwss2300->_ap_serial($partial) || {};
    my %serial_iid = reverse %$ap_serials;

    my %fw_port;
    foreach my $iid ( keys %$slots ) {
        my $slot = $slots->{$iid};
        next unless defined $slot;
	$slot =~ s/radio-//i;
	
        my $serial = $serials->{$iid};
        next unless defined $serial;
	my $index = $serial_iid{$serial};
	next unless defined $index;
	
        $fw_port{$iid} = "$index.$slot";
    }
    return \%fw_port;
}

sub i_ssidlist {
    my $nwss2300 = shift;
    my $partial  = shift;

    my $apif_bssid = $nwss2300->nwss2300_apif_bssid($partial) || {};
    my $i_index    = $nwss2300->i_index($partial)             || {};

    my %i_ssidlist;
    foreach my $iid ( keys %$i_index ) {

	# Skip non-radio interfaces
	next if $iid =~ /^\d+$/;

	foreach my $idx ( keys %$apif_bssid ) {
	    next unless ( $idx =~ /^$iid\./ );
	    my $bssid_mac = $apif_bssid->{$idx};
	    next unless $bssid_mac;

	    # Give the SSID a numeric value based upon tail of BSSID
	    my $id;
	    if ( $bssid_mac =~ /:([0-9A-F]{1,2})$/i ) {
		$id = hex $1;
	    }
	    next unless ( defined $id and $id =~ /\d+/ );
	    my $ssid_oid = $idx;
	    $ssid_oid =~ s/^$iid\.//;

	    my $ssid
		= join( '', map { sprintf "%c", $_ } split /\./, $ssid_oid );

	    # Remove any control characters including nulls
	    $ssid =~ s/[\c@-\c_]//g;
	    $i_ssidlist{"$iid.$id"} = $ssid;
	}
    }
    return \%i_ssidlist;
}


# Can't find in MIB
#
#sub i_ssidbcast {
#
#}

sub i_80211channel {
    my $nwss2300 = shift;
    my $partial  = shift;

    my $ch_list = $nwss2300->nwss2300_apif_ch_num($partial) || {};

    my %i_80211channel;
    foreach my $iid ( keys %$ch_list ) {
        my $ch = $ch_list->{$iid};
        next unless $ch =~ /\d+/;
        $i_80211channel{$iid} = $ch;
    }
    return \%i_80211channel;
}

sub dot11_cur_tx_pwr_mw {
    my $nwss2300 = shift;
    my $partial  = shift;

    my $cur = $nwss2300->nwss2300_apif_power($partial);
    
    my $dot11_cur_tx_pwr_mw = {};
    foreach my $idx ( keys %$cur ) {
        my $pwr_dbm = $cur->{$idx};
	next unless $pwr_dbm;
	#Convert to milliWatts = 10(dBm/10)
        my $pwr = int (10 ** ($pwr_dbm / 10));
	
        $dot11_cur_tx_pwr_mw->{$idx} = $pwr; 
    }
    return $dot11_cur_tx_pwr_mw;
}

# Pseudo ENTITY-MIB methods

sub e_index {
    my $nwss2300 = shift;

    # Try new first, fall back to depreciated
    my $ap_num = $nwss2300->nwss2300_ap_num() || $nwss2300->nwss2300_ap_dapnum() || {};
  
    my %e_index;

    # Chassis
    $e_index{1} = 1;

    # We're going to hack an index to capture APs
    foreach my $idx ( keys %$ap_num ) {
	my $number = $ap_num->{$idx};
	next unless $number =~ /\d+/;

        $e_index{$idx} = $number;
    }
    return \%e_index;
}

sub e_class {
    my $nwss2300 = shift;

    my $e_idx = $nwss2300->e_index() || {};

    my %e_class;
    foreach my $iid ( keys %$e_idx ) {
        if ( $iid eq "1" ) {
            $e_class{$iid} = 'chassis';
        }

        # This isn't a valid PhysicalClass, but we're hacking this anyway
        else {
            $e_class{$iid} = 'ap';
        }
    }
    return \%e_class;
}

sub e_name {
    my $nwss2300 = shift;

    my $ap_name = $nwss2300->nwss2300_ap_name() || {};

    my %e_name;

    # Chassis
    $e_name{1} = 'WLAN Controller';

    # APs
    foreach my $iid ( keys %$ap_name ) {
        $e_name{$iid} = 'AP';
    }
    return \%e_name;
}

sub e_descr {
    my $nwss2300 = shift;

    my $ap_model = $nwss2300->nwss2300_ap_model() || {};
    my $ap_name  = $nwss2300->nwss2300_ap_name()  || {};

    my %e_descr;

    # Chassis
    $e_descr{1} = $nwss2300->model();

    # APs
    foreach my $iid ( keys %$ap_name ) {
        my $name = $ap_name->{$iid};
        next unless defined $name;
        my $model = $ap_model->{$iid} || 'AP';

        $e_descr{$iid} = "$model: $name";
    }
    return \%e_descr;
}

sub e_model {
    my $nwss2300 = shift;

    my $ap_model = $nwss2300->nwss2300_ap_model() || {};

    my %e_model;

    # Chassis
    $e_model{1} = $nwss2300->model();

    # APs
    foreach my $iid ( keys %$ap_model ) {
        my $model = $ap_model->{$iid};
        next unless defined $model;

        $e_model{$iid} = $model;
    }
    return \%e_model;
}

sub e_type {
    my $nwss2300 = shift;

    return $nwss2300->e_model();
}

sub e_fwver {
    my $nwss2300 = shift;

    my $ap_fw = $nwss2300->nwss2300_ap_fw() || {};

    my %e_fwver;
    # APs
    foreach my $iid ( keys %$ap_fw ) {
        my $fw = $ap_fw->{$iid};
        next unless defined $fw;

        $e_fwver{$iid} = $fw;
    }
    return \%e_fwver;
}

sub e_vendor {
    my $nwss2300 = shift;

    my $vendors = $nwss2300->nwss2300_ap_vendor() || {};

    my %e_vendor;

    # Chassis
    $e_vendor{1} = 'avaya';

    # APs
    foreach my $iid ( keys %$vendors ) {
        my $vendor = $vendors->{$iid};
        next unless defined $vendor;

        $e_vendor{$iid} = $vendor;
    }
    return \%e_vendor;
}

sub e_serial {
    my $nwss2300 = shift;

    my $ap_serial = $nwss2300->_ap_serial() || {};

    my %e_serial;

    # Chassis
    $e_serial{1} = $nwss2300->serial();

    # APs
    foreach my $iid ( keys %$ap_serial ) {
        my $serial = $ap_serial->{$iid};
        next unless defined $serial;

        $e_serial{$iid} = $serial;
    }
    return \%e_serial;
}

sub e_pos {
    my $nwss2300 = shift;

    my $e_idx = $nwss2300->e_index() || {};

    my %e_pos;
    my $pos = 0;
    foreach my $iid ( sort keys %$e_idx ) {
        if ( $iid eq "1" ) {
            $e_pos{$iid} = -1;
            next;
        }
        else {
            $pos++;
            $e_pos{$iid} = $pos;
        }
    }
    return \%e_pos;
}

sub e_swver {
    my $nwss2300 = shift;

    my $ap_sw = $nwss2300->nwss2300_ap_sw() || {};

    my %e_swver;

    # Chassis
    $e_swver{1} = $nwss2300->os_ver();

    # APs
    foreach my $iid ( keys %$ap_sw ) {
        my $sw = $ap_sw->{$iid};
        next unless defined $sw;

        $e_swver{$iid} = $sw;
    }
    return \%e_swver;
}

sub e_parent {
    my $nwss2300 = shift;

    my $e_idx = $nwss2300->e_index() || {};

    my %e_parent;
    foreach my $iid ( sort keys %$e_idx ) {
        if ( $iid eq "1" ) {
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

sub at_paddr {
    my $nwss2300 = shift;

    my $mac2ip = $nwss2300->nwss2300_sta_ip();

    my $ret = {};
    foreach my $idx ( keys %$mac2ip ) {
	next if ( $mac2ip->{ $idx } eq '0.0.0.0' );
	my $mac = join( ":", map { sprintf "%02x", $_ } split /\./, $idx );
	$ret->{$idx} = $mac;
    }
    return $ret;
}

sub at_netaddr {
    my $nwss2300 = shift;

    my $mac2ip = $nwss2300->nwss2300_sta_ip();

    my $ret = {};
    foreach my $idx ( keys %$mac2ip ) {
	next if ( $mac2ip->{ $idx } eq '0.0.0.0' );
	$ret->{$idx} = $mac2ip->{ $idx };
    }
    return $ret;
}

# Client MAC
sub cd11_mac {
    my $nwss2300 = shift;
    my $cd11_sigstrength = $nwss2300->cd11_sigstrength();

    my $ret = {};
    foreach my $idx ( keys %$cd11_sigstrength ) {
	my $mac = join( ":", map { sprintf "%02x", $_ } split /\./, $idx );
	$ret->{$idx} = $mac
    }
    return $ret;
}


1;
__END__

=head1 NAME

SNMP::Info::Layer2::NWSS2300 - SNMP Interface to Avaya (Trapeze) Wireless
Controllers

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

    #Let SNMP::Info determine the correct subclass for you.

    my $nwss2300 = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 

    or die "Can't connect to DestHost.\n";

    my $class = $nwss2300->class();
    print " Using device sub class : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from 
Avaya (Trapeze) Wireless Controllers through SNMP.

This class emulates bridge functionality for the wireless switch. This enables
end station MAC addresses collection and correlation to the thin access point
the end station is using for communication.

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

my $nwss2300 = new SNMP::Info::Layer2::NWSS2300(...);

=head2 Inherited Classes

=over

=item SNMP::Info

=item SNMP::Info::Bridge

=back

=head2 Required MIBs

=over

=item F<NTWS-REGISTRATION-DEVICES-MIB>

=item F<NTWS-AP-STATUS-MIB>

=item F<NTWS-CLIENT-SESSION-MIB>

=item F<NTWS-SYSTEM-MIB>

=item F<NTWS-BASIC-MIB>

=back

=head2 Inherited Classes' MIBs

See L<SNMP::Info/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::Bridge/"Required MIBs"> for its own MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $nwss2300->vendor()

Returns 'avaya'

=item $nwss2300->os()

Returns 'trapeze'

=item $nwss2300->os_ver()

(C<ntwsVersionString>)

=item $nwss2300->model()

Tries to reference $nwss2300->id() to F<NTWS-REGISTRATION-DEVICES-MIB>

Removes C<'ntwsSwitch'> for readability.

=item $nwss2300->serial()

(C<ntwsSerialNumber>)

=item $nwss2300->mac()

(C<dot1dBaseBridgeAddress>)

=back

=head2 Overrides

=over

=item $nwss2300->layers()

Returns 00000011.  Class emulates Layer 2 functionality for Thin APs through
proprietary MIBs.

=back

=head2 Global Methods imported from SNMP::Info

See documentation in L<SNMP::Info/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::Bridge

See documentation in L<SNMP::Info::Bridge/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over 

=item $nwss2300->i_ssidlist()

Returns reference to hash.  SSID's recognized by the radio interface.

=item $nwss2300->i_80211channel()

Returns reference to hash.  Current operating frequency channel of the radio
interface.

=item $nwss2300->dot11_cur_tx_pwr_mw()

Returns reference to hash.  Current transmit power, in milliwatts, of the
radio interface.

=item cd11_mac()

Client MAC address.

=back

=head2 AP Status Table  (C<ntwsApStatApStatusTable>)

A table describing all the APs currently present and managed by the
controller.

=over

=item $nwss2300->nwss2300_ap_mac()

(C<ntwsApStatApStatusBaseMac>)

=item $nwss2300->nwss2300_ap_name()

(C<ntwsApStatApStatusApName>)

=item $nws2300->nwss2300_ap_ip()

(C<ntwsApStatApStatusIpAddress>)

=item $nws2300->nwss2300_ap_sw()

(C<ntwsApStatApStatusSoftwareVer>)

=item $nws2300->nwss2300_ap_fw()

(C<ntwsApStatApStatusBootVer>)

=item $nws2300->nwss2300_ap_model()

(C<ntwsApStatApStatusModel>)

=item $nws2300->nwss2300_ap_type()

(C<ntwsApStatApStatusModel>)

=item $nws2300->nwss2300_ap_status()

(C<ntwsApStatApStatusApState>)

=item $nws2300->nwss2300_ap_vendor()

(C<ntwsApStatApStatusManufacturerId>)

=item $nws2300->nwss2300_ap_num()

(C<ntwsApStatApStatusApNum>)

=item $nws2300->nwss2300_ap_dapnum()

(C<ntwsApStatApStatusPortOrDapNum>)

=back

=head2 AP Radio Status Table  (C<ntwsApStatRadioStatusTable>)

A table describing all radios on all the APs currently present and managed
by the controller.

=over

=item $nws2300->nwss2300_apif_mac()

(C<ntwsApStatRadioStatusBaseMac>)

=item $nws2300->nwss2300_apif_type()

(C<ntwsApStatRadioStatusRadioPhyType>)

=item $nws2300->nwss2300_apif_ch_num()

(C<ntwsApStatRadioStatusCurrentChannelNum>)

=item $nws2300->nwss2300_apif_power()

(C<ntwsApStatRadioStatusCurrentPowerLevel>)

=item $nws2300->nwss2300_apif_admin()

(C<ntwsApStatRadioStatusRadioMode>)

=back

=head2 AP Radio Status Service Table (C<ntwsApStatRadioServiceTable>)

A table describing radio services associated with APs currently present
and managed by the controller.

=over

=item $nws2300->nwss2300_apif_bssid()

(C<ntwsApStatRadioServBssid>)

=item $nws2300->nwss2300_apif_prof()

(C<ntwsApStatRadioServServiceProfileName>)

=back

=head2 AP Service Profile Config Table (C<ntwsApConfServiceProfileTable>)

=over

=item $nws2300->nwss2300_ess_bcast()

(C<ntwsApConfServProfBeaconEnabled>)

=back

=head2 AP Radio Config Table (C<ntwsApConfRadioConfigTable>)

=over

=item $nws2300->nwss2300_apcr_txpwr()

(C<ntwsApConfRadioConfigTxPower>)

=item $nws2300->nwss2300_apcr_ch()

(C<ntwsApConfRadioConfigChannel>)

=item $nws2300->nwss2300_apcr_mode()

(C<ntwsApConfRadioConfigRadioMode>)

=back

=head2 AP Config Table (C<ntwsApConfApConfigTable>)

=over

=item $nws2300->nwss2300_apc_descr()

(C<ntwsApConfApConfigDescription>)

=item $nws2300->nwss2300_apc_loc()

(C<ntwsApConfApConfigLocation>)

=item $nws2300->nwss2300_apc_name()

(C<ntwsApConfApConfigApName>)

=item $nws2300->nwss2300_apc_model()

(C<ntwsApConfApConfigApModelName>)

=item $nws2300->nwss2300_apc_serial()

(C<ntwsApConfApConfigApSerialNum>)

=back

=head2 Client Session Table (C<ntwsClSessClientSessionTable>)

=over

=item $nws2300->nwss2300_sta_slot()

(C<ntwsClSessClientSessRadioNum>)

=item $nws2300->nwss2300_sta_serial()

(C<ntwsClSessClientSessApSerialNum>)

=item $nws2300->nwss2300_sta_ssid()

(C<ntwsClSessClientSessSsid>)

=item $nws2300->nwss2300_sta_ip()

(C<ntwsClSessClientSessIpAddress>)

=back

=head2 Client Session Statistics Table (C<ntwsClSessClientSessionStatisticsTable>)

These emulate the F<CISCO-DOT11-MIB>

=over

=item $nws2300->cd11_sigstrength()

(C<ntwsClSessClientSessStatsLastRssi>)

=item $nws2300->cd11_sigqual()

(C<ntwsClSessClientSessStatsLastSNR>)

=item $nws2300->cd11_txrate()

(C<ntwsClSessClientSessStatsLastRate>)

=item $nws2300->cd11_rxbyte()

(C<ntwsClSessClientSessStatsUniOctetIn>)

=item $nws2300->cd11_txbyte()

(C<ntwsClSessClientSessStatsUniOctetOut>)

=item $nws2300->cd11_rxpkt()

(C<ntwsClSessClientSessStatsUniPktIn>)

=item $nws2300->cd11_txpkt()

(C<ntwsClSessClientSessStatsUniPktOut>)

=back 

=head2 Table Methods imported from SNMP::Info

See documentation in L<SNMP::Info/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::Bridge

See documentation in L<SNMP::Info::Bridge/"TABLE METHODS"> for details.

=head2 Overrides

=over

=item $nwss2300->i_index()

Returns reference to map of IIDs to Interface index. 

Extends C<ifIndex> to support thin APs and WLAN virtual interfaces as device
interfaces.

=item $nwss2300->interfaces()

Returns reference to map of IIDs to ports.  Thin APs are implemented as device 
interfaces.  The thin AP MAC address and Slot ID nwss2300_apif_slot() are
used as the port identifier.

=item $nwss2300->i_name()

Returns reference to map of IIDs to interface names.  Returns C<ifName> for
Ethernet interfaces and nwss2300_ap_name() for thin AP interfaces.

=item $nwss2300->i_description()

Returns reference to map of IIDs to interface types.  Returns C<ifDescr>
for Ethernet interfaces, nwss2300_ap_name() for thin AP interfaces.

=item $nwss2300->i_type()

Returns reference to map of IIDs to interface descriptions.  Returns
C<ifType> for Ethernet interfaces and C<'capwapWtpVirtualRadio'> for thin AP
interfaces.

=item $nwss2300->i_up()

Returns reference to map of IIDs to link status of the interface.  Returns
C<ifOperStatus> for Ethernet interfaces and nwss2300_apif_admin() for thin AP
interfaces.

=item $nwss2300->i_up_admin()

Returns reference to map of IIDs to administrative status of the interface.
Returns C<ifAdminStatus> for Ethernet interfaces and nwss2300_apif_admin()
for thin AP interfaces.

=item $nwss2300->i_mac()

Returns reference to map of IIDs to MAC address of the interface.  Returns
C<ifPhysAddress> for Ethernet interfaces.

=item $nwss2300->bp_index()

Simulates bridge MIB by returning reference to a hash mapping i_index() to
the interface iid.

=item $nwss2300->fw_port()

Returns reference to a hash, value being mac and
nwss2300_sta_slot() combined to match the interface iid.  

=item $nwss2300->fw_mac()

Extracts the MAC from the nwss2300_sta_serial() index.

=back

=head2 Pseudo ARP Cache Entries

The controller snoops on the MAC->IP mappings.  Using this as ARP cache data
allows us to get MAC->IP mappings even for stations that only
communicate locally.  The data is gathered from nwss2300_sta_ip().

=over

=item $nwss2300->at_paddr()

Returns reference to hash of Pseudo Arp Cache Entries to MAC address

=item $nwss2300->at_netaddr()

Returns reference to hash of Pseudo Arp Cache Entries to IP Address

=back

=head2 Pseudo F<ENTITY-MIB> information

These methods emulate F<ENTITY-MIB> Physical Table methods using
F<NTWS-AP-STATUS-MIB>.  Thin APs are included as subcomponents of
the wireless controller.

=over

=item $nwss2300->e_index()

Returns reference to hash.  Key: IID and Value: Integer. The index for APs is
created with an integer representation of the last three octets of the
AP MAC address.

=item $nwss2300->e_class()

Returns reference to hash.  Key: IID, Value: General hardware type.  Return ap
for wireless access points.

=item $nwss2300->e_descr()

Returns reference to hash.  Key: IID, Value: Human friendly name.

=item $nwss2300->e_model()

Returns reference to hash.  Key: IID, Value: Model name.

=item $nwss2300->e_name()

More computer friendly name of entity.  Name is either 'WLAN Controller' or
'AP'.

=item $nwss2300->e_vendor()

Returns reference to hash.  Key: IID, Value: avaya.

=item $nwss2300->e_serial()

Returns reference to hash.  Key: IID, Value: Serial number.

=item $nwss2300->e_pos()

Returns reference to hash.  Key: IID, Value: The relative position among all
entities sharing the same parent.

=item $nwss2300->e_type()

Returns reference to hash.  Key: IID, Value: Type of component.

=item $nwss2300->e_fwver()

Returns reference to hash.  Key: IID, Value: Firmware revision.

=item $nwss2300->e_swver()

Returns reference to hash.  Key: IID, Value: Software revision.

=item $nwss2300->e_parent()

Returns reference to hash.  Key: IID, Value: The value of e_index() for the
entity which 'contains' this entity.

=back

=cut
