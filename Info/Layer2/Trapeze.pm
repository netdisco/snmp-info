# SNMP::Info::Layer2::Trapeze
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

package SNMP::Info::Layer2::Trapeze;

use strict;
use Exporter;
use SNMP::Info;
use SNMP::Info::Bridge;
use SNMP::Info::LLDP;

@SNMP::Info::Layer2::Trapeze::ISA
    = qw/SNMP::Info SNMP::Info::Bridge SNMP::Info::LLDP Exporter/;
@SNMP::Info::Layer2::Trapeze::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE/;

$VERSION = '3.22';

%MIBS = (
    %SNMP::Info::MIBS,
    %SNMP::Info::Bridge::MIBS,
    %SNMP::Info::LLDP::MIBS,
    'TRAPEZE-NETWORKS-REGISTRATION-DEVICES-MIB' => 'wirelessLANController',
    'TRAPEZE-NETWORKS-AP-STATUS-MIB'            => 'trpzApStatNumAps',
    'TRAPEZE-NETWORKS-CLIENT-SESSION-MIB'       => 'trpzClSessTotalSessions',
    'TRAPEZE-NETWORKS-SYSTEM-MIB'               => 'trpzSysCpuAverageLoad',
    'TRAPEZE-NETWORKS-BASIC-MIB'                => 'trpzVersionString',
);

%GLOBALS = (
    %SNMP::Info::GLOBALS,
    %SNMP::Info::Bridge::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,
    'os_ver' => 'trpzVersionString',
    'serial' => 'trpzSerialNumber',
    'mac'    => 'dot1dBaseBridgeAddress',
);

%FUNCS = (
    %SNMP::Info::FUNCS,
    %SNMP::Info::Bridge::FUNCS,
    %SNMP::Info::LLDP::FUNCS,
    # TRAPEZE-NETWORKS-AP-STATUS-MIB::trpzApStatApStatusTable
    'trapeze_ap_mac'      => 'trpzApStatApStatusBaseMac',
    'trapeze_ap_name'     => 'trpzApStatApStatusApName',
    'trapeze_ap_ip'       => 'trpzApStatApStatusIpAddress',
    #'trapeze_ap_loc'      => 'bsnAPLocation',
    'trapeze_ap_sw'       => 'trpzApStatApStatusSoftwareVer',
    'trapeze_ap_fw'       => 'trpzApStatApStatusBootVer',
    'trapeze_ap_model'    => 'trpzApStatApStatusModel',
    'trapeze_ap_type'     => 'trpzApStatApStatusModel',
    'trapeze_ap_status'   => 'trpzApStatApStatusApState',
    'trapeze_ap_vendor'   => 'trpzApStatApStatusManufacturerId',
    'trapeze_ap_num'      => 'trpzApStatApStatusApNum',
    'trapeze_ap_dapnum'   => 'trpzApStatApStatusPortOrDapNum',

    # TRAPEZE-NETWORKS-AP-STATUS-MIB::trpzApStatRadioStatusTable
    'trapeze_apif_mac'    => 'trpzApStatRadioStatusBaseMac',
    'trapeze_apif_type'   => 'trpzApStatRadioStatusRadioPhyType',
    'trapeze_apif_ch_num' => 'trpzApStatRadioStatusCurrentChannelNum',
    'trapeze_apif_power'  => 'trpzApStatRadioStatusCurrentPowerLevel',
    'trapeze_apif_admin'  => 'trpzApStatRadioStatusRadioMode',

    # TRAPEZE-NETWORKS-AP-STATUS-MIB::trpzApStatRadioServiceTable
    'trapeze_apif_prof'   => 'trpzApStatRadioServServiceProfileName',

    # TRAPEZE-NETWORKS-AP-CONFIG-MIB::trpzApConfServiceProfileTable
    'trapeze_ess_bcast'   => 'trpzApConfServProfBeaconEnabled',

    # TRAPEZE-NETWORKS-AP-CONFIG-MIB::trpzApConfRadioConfigTable
    'trapeze_apcr_txpwr'  => 'trpzApConfRadioConfigTxPower',
    'trapeze_apcr_ch'     => 'trpzApConfRadioConfigChannel',
    'trapeze_apcr_mode'   => 'trpzApConfRadioConfigRadioMode',

    # TRAPEZE-NETWORKS-AP-CONFIG-MIB::trpzApConfApConfigTable
    'trapeze_apc_descr'   => 'trpzApConfApConfigDescription',
    'trapeze_apc_loc'     => 'trpzApConfApConfigLocation',
    'trapeze_apc_name'    => 'trpzApConfApConfigApName',
    'trapeze_apc_model'   => 'trpzApConfApConfigApModelName',
    'trapeze_apc_serial'  => 'trpzApConfApConfigApSerialNum',

    # TRAPEZE-NETWORKS-CLIENT-SESSION-MIB::trpzClSessClientSessionTable
    'trapeze_sta_slot'    => 'trpzClSessClientSessRadioNum',
    'trapeze_sta_serial'  => 'trpzClSessClientSessApSerialNum',
    'trapeze_sta_ssid'    => 'trpzClSessClientSessSsid',
    'trapeze_sta_ip'      => 'trpzClSessClientSessIpAddress',

    # TRAPEZE-NETWORKS-AP-STATUS-MIB::trpzApStatRadioServiceTable
    'trapeze_apif_bssid'  => 'trpzApStatRadioServBssid',

    # TRAPEZE-NETWORKS-CLIENT-SESSION-MIB::trpzClSessClientSessionStatisticsTable
    # Pretend to have the CISCO-DOT11-MIB for signal strengths, etc.
    'cd11_sigstrength' => 'trpzClSessClientSessStatsLastRssi',
    'cd11_sigqual'     => 'trpzClSessClientSessStatsLastSNR',
    'cd11_txrate'      => 'trpzClSessClientSessStatsLastRate',
    # These are supposed to be there...
    'cd11_rxbyte'      => 'trpzClSessClientSessStatsUniOctetIn',
    'cd11_txbyte'      => 'trpzClSessClientSessStatsUniOctetOut',
    'cd11_rxpkt'       => 'trpzClSessClientSessStatsUniPktIn',
    'cd11_txpkt'       => 'trpzClSessClientSessStatsUniPktOut',
);

%MUNGE = (
    %SNMP::Info::MUNGE,
    %SNMP::Info::Bridge::MUNGE,
    %SNMP::Info::LLDP::MUNGE,
    'trapeze_apif_mac'      => \&SNMP::Info::munge_mac,
    'trapeze_apif_bssid'    => \&SNMP::Info::munge_mac,
);

sub layers {
    return '00000111';
}

sub os {
    return 'trapeze';
}

sub vendor {
    return 'juniper';
}

sub model {
    my $trapeze = shift;
    my $id = $trapeze->id();

    unless ( defined $id ) {
        print
            "SNMP::Info::Layer2::Trapeze::model() - Device does not support sysObjectID\n"
            if $trapeze->debug();
        return;
    }

    my $model = &SNMP::translateObj($id);

    return $id unless defined $model;

    $model =~ s/^wirelessLANController//i;
    return $model;    
}

sub _ap_serial {
    my $trapeze = shift;
    my $partial  = shift;

    my $names = $trapeze->trapeze_ap_name($partial) || {};

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
    my $trapeze = shift;
    my $partial  = shift;

    my $i_index  = $trapeze->orig_i_index($partial)      || {};
    my $ap_index = $trapeze->trapeze_apif_mac($partial) || {};

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
    my $trapeze = shift;
    my $partial  = shift;

    my $i_index      = $trapeze->i_index($partial)              || {};
    my $descriptions = $trapeze->SUPER::i_description($partial) || {};

    my %if;
    foreach my $iid ( keys %$i_index ) {
        my $desc = $descriptions->{$iid} || $i_index->{$iid};
        next unless defined $desc;

        $if{$iid} = $desc;
    }

    return \%if;
}

sub i_description {
    my $trapeze = shift;
    my $partial  = shift;

    my $i_index = $trapeze->i_index($partial)            || {};
    my $i_desc  = $trapeze->orig_i_description($partial) || {};
    my $ap_name = $trapeze->trapeze_ap_name($partial)   || {};

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
    my $trapeze = shift;
    my $partial  = shift;

    return $trapeze->i_description($partial);
}

sub i_type {
    my $trapeze = shift;
    my $partial  = shift;

    my $i_index   = $trapeze->i_index($partial)     || {};
    my $i_type    = $trapeze->orig_i_type($partial) || {};

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
    my $trapeze = shift;
    my $partial   = shift;

    return $trapeze->i_up_admin($partial);
}

sub i_up_admin {
    my $trapeze = shift;
    my $partial   = shift;

    my $i_index = $trapeze->i_index($partial)             || {};
    my $i_up    = $trapeze->orig_i_up($partial)           || {};
    my $apif_up = $trapeze->trapeze_apif_admin($partial) || {};

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
    my $trapeze = shift;
    my $partial  = shift;

    my $i_index = $trapeze->i_index($partial)    || {};
    my $i_mac   = $trapeze->orig_i_mac($partial) || {};

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
    my $trapeze = shift;
    my $partial  = shift;

    my $i_index = $trapeze->i_index($partial) || {};

    my %bp_index;
    foreach my $iid ( keys %$i_index ) {
        my $index = $i_index->{$iid};
        next unless defined $index;

        $bp_index{$index} = $iid;
    }
    return \%bp_index;
}

sub fw_mac {
    my $trapeze = shift;
    my $partial  = shift;
    
    my $serials = $trapeze->trapeze_sta_serial($partial) || {};

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
    my $trapeze = shift;
    my $partial  = shift;

    my $slots      = $trapeze->trapeze_sta_slot($partial) || {};
    my $serials    = $trapeze->trapeze_sta_serial($partial) || {};
    my $ap_serials = $trapeze->_ap_serial($partial) || {};
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
    my $trapeze = shift;
    my $partial  = shift;

    my $apif_bssid = $trapeze->trapeze_apif_bssid($partial) || {};
    my $i_index    = $trapeze->i_index($partial)             || {};

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
    my $trapeze = shift;
    my $partial  = shift;

    my $ch_list = $trapeze->trapeze_apif_ch_num($partial) || {};

    my %i_80211channel;
    foreach my $iid ( keys %$ch_list ) {
        my $ch = $ch_list->{$iid};
        next unless $ch =~ /\d+/;
        $i_80211channel{$iid} = $ch;
    }
    return \%i_80211channel;
}

sub dot11_cur_tx_pwr_mw {
    my $trapeze = shift;
    my $partial  = shift;

    my $cur = $trapeze->trapeze_apif_power($partial);
    
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
    my $trapeze = shift;

    # Try new first, fall back to depreciated
    my $ap_num = $trapeze->trapeze_ap_num() || $trapeze->trapeze_ap_dapnum() || {};
  
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
    my $trapeze = shift;

    my $e_idx = $trapeze->e_index() || {};

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
    my $trapeze = shift;

    my $ap_name = $trapeze->trapeze_ap_name() || {};

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
    my $trapeze = shift;

    my $ap_model = $trapeze->trapeze_ap_model() || {};
    my $ap_name  = $trapeze->trapeze_ap_name()  || {};

    my %e_descr;

    # Chassis
    $e_descr{1} = $trapeze->model();

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
    my $trapeze = shift;

    my $ap_model = $trapeze->trapeze_ap_model() || {};

    my %e_model;

    # Chassis
    $e_model{1} = $trapeze->model();

    # APs
    foreach my $iid ( keys %$ap_model ) {
        my $model = $ap_model->{$iid};
        next unless defined $model;

        $e_model{$iid} = $model;
    }
    return \%e_model;
}

sub e_type {
    my $trapeze = shift;

    return $trapeze->e_model();
}

sub e_fwver {
    my $trapeze = shift;

    my $ap_fw = $trapeze->trapeze_ap_fw() || {};

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
    my $trapeze = shift;

    my $vendors = $trapeze->trapeze_ap_vendor() || {};

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
    my $trapeze = shift;

    my $ap_serial = $trapeze->_ap_serial() || {};

    my %e_serial;

    # Chassis
    $e_serial{1} = $trapeze->serial();

    # APs
    foreach my $iid ( keys %$ap_serial ) {
        my $serial = $ap_serial->{$iid};
        next unless defined $serial;

        $e_serial{$iid} = $serial;
    }
    return \%e_serial;
}

sub e_pos {
    my $trapeze = shift;

    my $e_idx = $trapeze->e_index() || {};

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
    my $trapeze = shift;

    my $ap_sw = $trapeze->trapeze_ap_sw() || {};

    my %e_swver;

    # Chassis
    $e_swver{1} = $trapeze->os_ver();

    # APs
    foreach my $iid ( keys %$ap_sw ) {
        my $sw = $ap_sw->{$iid};
        next unless defined $sw;

        $e_swver{$iid} = $sw;
    }
    return \%e_swver;
}

sub e_parent {
    my $trapeze = shift;

    my $e_idx = $trapeze->e_index() || {};

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
    my $trapeze = shift;

    my $mac2ip = $trapeze->trapeze_sta_ip();

    my $ret = {};
    foreach my $idx ( keys %$mac2ip ) {
	next if ( $mac2ip->{ $idx } eq '0.0.0.0' );
	my $mac = join( ":", map { sprintf "%02x", $_ } split /\./, $idx );
	$ret->{$idx} = $mac;
    }
    return $ret;
}

sub at_netaddr {
    my $trapeze = shift;

    my $mac2ip = $trapeze->trapeze_sta_ip();

    my $ret = {};
    foreach my $idx ( keys %$mac2ip ) {
	next if ( $mac2ip->{ $idx } eq '0.0.0.0' );
	$ret->{$idx} = $mac2ip->{ $idx };
    }
    return $ret;
}

# Client MAC
sub cd11_mac {
    my $trapeze = shift;
    my $cd11_sigstrength = $trapeze->cd11_sigstrength();

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

SNMP::Info::Layer2::Trapeze - SNMP Interface to Juniper (Trapeze) Wireless
Controllers

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

    #Let SNMP::Info determine the correct subclass for you.

    my $trapeze = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 

    or die "Can't connect to DestHost.\n";

    my $class = $trapeze->class();
    print " Using device sub class : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from 
Juniper (Trapeze) Wireless Controllers through SNMP.

This class emulates bridge functionality for the wireless switch. This enables
end station MAC addresses collection and correlation to the thin access point
the end station is using for communication.

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

my $trapeze = new SNMP::Info::Layer2::Trapeze(...);

=head2 Inherited Classes

=over

=item SNMP::Info

=item SNMP::Info::Bridge

=back

=head2 Required MIBs

=over

=item F<TRAPEZE-NETWORKS-REGISTRATION-DEVICES-MIB>

=item F<TRAPEZE-NETWORKS-AP-STATUS-MIB>

=item F<TRAPEZE-NETWORKS-CLIENT-SESSION-MIB>

=item F<TRAPEZE-NETWORKS-SYSTEM-MIB>

=item F<TRAPEZE-NETWORKS-BASIC-MIB>

=back

=head2 Inherited Classes' MIBs

See L<SNMP::Info/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::Bridge/"Required MIBs"> for its own MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $trapeze->vendor()

Returns 'juniper'

=item $trapeze->os()

Returns 'trapeze'

=item $trapeze->os_ver()

(C<trpzVersionString>)

=item $trapeze->model()

Tries to reference $trapeze->id() to F<TRAPEZE-NETWORKS-REGISTRATION-DEVICES-MIB>

Removes C<'wirelessLANController'> for readability.

=item $trapeze->serial()

(C<trpzSerialNumber>)

=item $trapeze->mac()

(C<dot1dBaseBridgeAddress>)

=back

=head2 Overrides

=over

=item $trapeze->layers()

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

=item $trapeze->i_ssidlist()

Returns reference to hash.  SSID's recognized by the radio interface.

=item $trapeze->i_80211channel()

Returns reference to hash.  Current operating frequency channel of the radio
interface.

=item $trapeze->dot11_cur_tx_pwr_mw()

Returns reference to hash.  Current transmit power, in milliwatts, of the
radio interface.

=item cd11_mac()

Client MAC address.

=back

=head2 AP Status Table  (C<trpzApStatApStatusTable>)

A table describing all the APs currently present and managed by the
controller.

=over

=item $trapeze->trapeze_ap_mac()

(C<trpzApStatApStatusBaseMac>)

=item $trapeze->trapeze_ap_name()

(C<trpzApStatApStatusApName>)

=item $nws2300->trapeze_ap_ip()

(C<trpzApStatApStatusIpAddress>)

=item $nws2300->trapeze_ap_sw()

(C<trpzApStatApStatusSoftwareVer>)

=item $nws2300->trapeze_ap_fw()

(C<trpzApStatApStatusBootVer>)

=item $nws2300->trapeze_ap_model()

(C<trpzApStatApStatusModel>)

=item $nws2300->trapeze_ap_type()

(C<trpzApStatApStatusModel>)

=item $nws2300->trapeze_ap_status()

(C<trpzApStatApStatusApState>)

=item $nws2300->trapeze_ap_vendor()

(C<trpzApStatApStatusManufacturerId>)

=item $nws2300->trapeze_ap_num()

(C<trpzApStatApStatusApNum>)

=item $nws2300->trapeze_ap_dapnum()

(C<trpzApStatApStatusPortOrDapNum>)

=back

=head2 AP Radio Status Table  (C<trpzApStatRadioStatusTable>)

A table describing all radios on all the APs currently present and managed
by the controller.

=over

=item $nws2300->trapeze_apif_mac()

(C<trpzApStatRadioStatusBaseMac>)

=item $nws2300->trapeze_apif_type()

(C<trpzApStatRadioStatusRadioPhyType>)

=item $nws2300->trapeze_apif_ch_num()

(C<trpzApStatRadioStatusCurrentChannelNum>)

=item $nws2300->trapeze_apif_power()

(C<trpzApStatRadioStatusCurrentPowerLevel>)

=item $nws2300->trapeze_apif_admin()

(C<trpzApStatRadioStatusRadioMode>)

=back

=head2 AP Radio Status Service Table (C<trpzApStatRadioServiceTable>)

A table describing radio services associated with APs currently present
and managed by the controller.

=over

=item $nws2300->trapeze_apif_bssid()

(C<trpzApStatRadioServBssid>)

=item $nws2300->trapeze_apif_prof()

(C<trpzApStatRadioServServiceProfileName>)

=back

=head2 AP Service Profile Config Table (C<trpzApConfServiceProfileTable>)

=over

=item $nws2300->trapeze_ess_bcast()

(C<trpzApConfServProfBeaconEnabled>)

=back

=head2 AP Radio Config Table (C<trpzApConfRadioConfigTable>)

=over

=item $nws2300->trapeze_apcr_txpwr()

(C<trpzApConfRadioConfigTxPower>)

=item $nws2300->trapeze_apcr_ch()

(C<trpzApConfRadioConfigChannel>)

=item $nws2300->trapeze_apcr_mode()

(C<trpzApConfRadioConfigRadioMode>)

=back

=head2 AP Config Table (C<trpzApConfApConfigTable>)

=over

=item $nws2300->trapeze_apc_descr()

(C<trpzApConfApConfigDescription>)

=item $nws2300->trapeze_apc_loc()

(C<trpzApConfApConfigLocation>)

=item $nws2300->trapeze_apc_name()

(C<trpzApConfApConfigApName>)

=item $nws2300->trapeze_apc_model()

(C<trpzApConfApConfigApModelName>)

=item $nws2300->trapeze_apc_serial()

(C<trpzApConfApConfigApSerialNum>)

=back

=head2 Client Session Table (C<trpzClSessClientSessionTable>)

=over

=item $nws2300->trapeze_sta_slot()

(C<trpzClSessClientSessRadioNum>)

=item $nws2300->trapeze_sta_serial()

(C<trpzClSessClientSessApSerialNum>)

=item $nws2300->trapeze_sta_ssid()

(C<trpzClSessClientSessSsid>)

=item $nws2300->trapeze_sta_ip()

(C<trpzClSessClientSessIpAddress>)

=back

=head2 Client Session Statistics Table (C<trpzClSessClientSessionStatisticsTable>)

These emulate the F<CISCO-DOT11-MIB>

=over

=item $nws2300->cd11_sigstrength()

(C<trpzClSessClientSessStatsLastRssi>)

=item $nws2300->cd11_sigqual()

(C<trpzClSessClientSessStatsLastSNR>)

=item $nws2300->cd11_txrate()

(C<trpzClSessClientSessStatsLastRate>)

=item $nws2300->cd11_rxbyte()

(C<trpzClSessClientSessStatsUniOctetIn>)

=item $nws2300->cd11_txbyte()

(C<trpzClSessClientSessStatsUniOctetOut>)

=item $nws2300->cd11_rxpkt()

(C<trpzClSessClientSessStatsUniPktIn>)

=item $nws2300->cd11_txpkt()

(C<trpzClSessClientSessStatsUniPktOut>)

=back 

=head2 Table Methods imported from SNMP::Info

See documentation in L<SNMP::Info/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::Bridge

See documentation in L<SNMP::Info::Bridge/"TABLE METHODS"> for details.

=head2 Overrides

=over

=item $trapeze->i_index()

Returns reference to map of IIDs to Interface index. 

Extends C<ifIndex> to support thin APs and WLAN virtual interfaces as device
interfaces.

=item $trapeze->interfaces()

Returns reference to map of IIDs to ports.  Thin APs are implemented as device 
interfaces.  The thin AP MAC address and Slot ID trapeze_apif_slot() are
used as the port identifier.

=item $trapeze->i_name()

Returns reference to map of IIDs to interface names.  Returns C<ifName> for
Ethernet interfaces and trapeze_ap_name() for thin AP interfaces.

=item $trapeze->i_description()

Returns reference to map of IIDs to interface types.  Returns C<ifDescr>
for Ethernet interfaces, trapeze_ap_name() for thin AP interfaces.

=item $trapeze->i_type()

Returns reference to map of IIDs to interface descriptions.  Returns
C<ifType> for Ethernet interfaces and C<'capwapWtpVirtualRadio'> for thin AP
interfaces.

=item $trapeze->i_up()

Returns reference to map of IIDs to link status of the interface.  Returns
C<ifOperStatus> for Ethernet interfaces and trapeze_apif_admin() for thin AP
interfaces.

=item $trapeze->i_up_admin()

Returns reference to map of IIDs to administrative status of the interface.
Returns C<ifAdminStatus> for Ethernet interfaces and trapeze_apif_admin()
for thin AP interfaces.

=item $trapeze->i_mac()

Returns reference to map of IIDs to MAC address of the interface.  Returns
C<ifPhysAddress> for Ethernet interfaces.

=item $trapeze->bp_index()

Simulates bridge MIB by returning reference to a hash mapping i_index() to
the interface iid.

=item $trapeze->fw_port()

Returns reference to a hash, value being mac and
trapeze_sta_slot() combined to match the interface iid.  

=item $trapeze->fw_mac()

Extracts the MAC from the trapeze_sta_serial() index.

=back

=head2 Pseudo ARP Cache Entries

The controller snoops on the MAC->IP mappings.  Using this as ARP cache data
allows us to get MAC->IP mappings even for stations that only
communicate locally.  The data is gathered from trapeze_sta_ip().

=over

=item $trapeze->at_paddr()

Returns reference to hash of Pseudo Arp Cache Entries to MAC address

=item $trapeze->at_netaddr()

Returns reference to hash of Pseudo Arp Cache Entries to IP Address

=back

=head2 Pseudo F<ENTITY-MIB> information

These methods emulate F<ENTITY-MIB> Physical Table methods using
F<TRAPEZE-NETWORKS-AP-STATUS-MIB>.  Thin APs are included as subcomponents of
the wireless controller.

=over

=item $trapeze->e_index()

Returns reference to hash.  Key: IID and Value: Integer. The index for APs is
created with an integer representation of the last three octets of the
AP MAC address.

=item $trapeze->e_class()

Returns reference to hash.  Key: IID, Value: General hardware type.  Return ap
for wireless access points.

=item $trapeze->e_descr()

Returns reference to hash.  Key: IID, Value: Human friendly name.

=item $trapeze->e_model()

Returns reference to hash.  Key: IID, Value: Model name.

=item $trapeze->e_name()

More computer friendly name of entity.  Name is either 'WLAN Controller' or
'AP'.

=item $trapeze->e_vendor()

Returns reference to hash.  Key: IID, Value: avaya.

=item $trapeze->e_serial()

Returns reference to hash.  Key: IID, Value: Serial number.

=item $trapeze->e_pos()

Returns reference to hash.  Key: IID, Value: The relative position among all
entities sharing the same parent.

=item $trapeze->e_type()

Returns reference to hash.  Key: IID, Value: Type of component.

=item $trapeze->e_fwver()

Returns reference to hash.  Key: IID, Value: Firmware revision.

=item $trapeze->e_swver()

Returns reference to hash.  Key: IID, Value: Software revision.

=item $trapeze->e_parent()

Returns reference to hash.  Key: IID, Value: The value of e_index() for the
entity which 'contains' this entity.

=back

=cut
