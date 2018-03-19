# SNMP::Info::Layer3::Lancom
#
# Copyright (c) 2018 Christoph Neuhaus
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

package SNMP::Info::Layer3::Lancom;

use strict;
use Exporter;
use SNMP::Info::MAU;
use SNMP::Info::Layer3;
use SNMP::Info::LLDP;
use SNMP::Info;

@SNMP::Info::Layer3::Lancom::ISA
    = qw/SNMP::Info::MAU SNMP::Info::Layer3 SNMP::Info::LLDP SNMP::Info Exporter/;
@SNMP::Info::Layer3::Lancom::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %FUNCS %MIBS %MUNGE/;

$VERSION = '3.51';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::LLDP::MIBS,
    %SNMP::Info::MAU::MIBS,
    'LCOS-MIB'  => 'lcsStatus',
    'LANCOM-1711-PLUS-MIB'  => 'lcsStatus',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::LLDP::FUNCS,
    %SNMP::Info::MAU::FUNCS,
    'lancom_i_name'                 => 'IF_MIB__ifName',
    'lancom_i_description'          => 'IF_MIB__ifDescr',
    # LCOS MIB
    'new_lancom_vlan'               => 'LCOS_MIB__lcsSetupVlanNetworksEntryVlanId',
    'new_lancom_vlan_ports'         => 'LCOS_MIB__lcsSetupVlanNetworksEntryPorts',
    'new_lancom_port_vid'           => 'LCOS_MIB__lcsSetupVlanPortTableEntryPortVlanId.5', # Ethernet only
    'new_lancom_port_tagmode'       => 'LCOS_MIB__lcsSetupVlanPortTableEntryTaggingMode.5', # Ethernet only
    'new_lancom_network_ip'         => 'LCOS_MIB__lcsSetupTcpIpNetworkListEntryIpAddress',
    'new_lancom_network_ip_vlan'    => 'LCOS_MIB__lcsSetupTcpIpNetworkListEntryVlanId',
    'new_lancom_arptable_ip'        => 'LCOS_MIB__lcsStatusTcpIpArpTableArpEntryIpAddress',
    'new_lancom_arptable_mac'       => 'LCOS_MIB__lcsStatusTcpIpArpTableArpEntryMacAddress',
    'new_lancom_arptable_port'      => 'LCOS_MIB__lcsStatusTcpIpArpTableArpEntryConnect',
    'new_lancom_network_elan'       => 'LCOS_MIB__lcsSetupInterfacesLanInterfacesEntryIfc',
    'new_lancom_elan_lan'           => 'LCOS_MIB__lcsStatusEthernetPortsPortsEntryAssignment', # physical to logical assignment
    'new_lancom_elan_id'            => 'LCOS_MIB__lcsStatusEthernetPortsPortsEntryPort', # eLAN id to eLAN Name
    # 1711 Plus MIB
    'old_lancom_vlan'               => 'LANCOM_1711_PLUS_MIB__lcsSetupVlanNetworksEntryVlanId',
    'old_lancom_vlan_ports'         => 'LANCOM_1711_PLUS_MIB__lcsSetupVlanNetworksEntryPorts',
    'old_lancom_port_vid'           => 'LANCOM_1711_PLUS_MIB__lcsSetupVlanPortTableEntryPortVlanId.5', # Ethernet only
    'old_lancom_port_tagmode'       => 'LANCOM_1711_PLUS_MIB__lcsSetupVlanPortTableEntryTaggingMode.5', # Ethernet only
    'old_lancom_network_ip'         => 'LANCOM_1711_PLUS_MIB__lcsSetupTcpIpNetworkListEntryIpAddress',
    'old_lancom_network_ip_vlan'    => 'LANCOM_1711_PLUS_MIB__lcsSetupTcpIpNetworkListEntryVlanId',
    'old_lancom_arptable_ip'        => 'LANCOM_1711_PLUS_MIB__lcsStatusTcpIpArpTableArpEntryIpAddress',
    'old_lancom_arptable_mac'       => 'LANCOM_1711_PLUS_MIB__lcsStatusTcpIpArpTableArpEntryMacAddress',
    'old_lancom_arptable_port'      => 'LANCOM_1711_PLUS_MIB__lcsStatusTcpIpArpTableArpEntryConnect',
    'old_lancom_network_elan'       => 'LANCOM_1711_PLUS_MIB__lcsSetupInterfacesLanInterfacesEntryIfc',
    'old_lancom_elan_lan'           => 'LANCOM_1711_PLUS_MIB__lcsStatusEthernetPortsPortsEntryAssignment', # physical to logical assignment
    'old_lancom_elan_id'            => 'LANCOM_1711_PLUS_MIB__lcsStatusEthernetPortsPortsEntryPort', # eLAN id to eLAN Name
);

%MUNGE = (
    %SNMP::Info::MAU::MUNGE,
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::LLDP::MUNGE,
);

# Method OverRides

sub model {
    my $lancom  = shift;
    my $id      = $lancom->id() || '';
    my $model   = &SNMP::translateObj($id);
    return $id unless defined $model;
    $model  =~ s/(^lcsProducts)?//;
    return $model;
}

sub vendor {
    return 'Lancom';
}

sub os {
    return 'lcos';
}

sub os_ver {
    my $lancom  = shift;
    my $descr   = $lancom->sysDescr();
    # normal: 9.00.0257 / 03.12.2004
    # I also cropped the date out of the version string
    $descr  =~ s/.*([0-9]+\.[0-9]*\.[0-9]*)\ \/.*/\1/;
    return $descr;
}

sub serial {
    my $lancom  = shift;
    my $serial  = $lancom->descr();
    my @return = split ' ', $serial;
    return $return[-1];
}

#
# Lancom uses an extra virtual interface layer which are assigned
# to the hardware ethernet ports.
# All Lancom mibs references those virtual interfaces, so that we
# had to trick with the output for netdisco.
sub interfaces {
    my $lancom      = shift;
    my $partial     = shift;
    my $interfaces  = $lancom->i_index($partial)       || {};
    my $i_name      = $lancom->lancom_i_name($partial) || {};

    # Replace the Index with the ifDescr field.
    # Check for duplicates in ifDescr, if so uniquely identify by adding
    # ifIndex to repeated values
    my %return;
    my %seen;
    foreach my $iid ( keys %$i_name ) {
        my $port = $i_name->{$iid};
        next unless defined $port;
        if ( $seen{$port}++ ) {
            $return{$iid} = sprintf( "%s (%d)", $port, $iid );
        }
        else {
            $return{$iid} = $port;
        }
    }
    # inject dummy VLAN interfaces for ip alias 
    my $vinterface  = $lancom->v_name() || {};
    foreach my $iid ( keys %$vinterface ) {
        # new interface fake ID 1000 + VLAN
        my $newid = 1000 + $iid;
        $return{$newid} = $vinterface->{$iid};
    }
    return \%return;
}

sub i_description {
    my $lancom      = shift;
    my $partial     = shift;
    my $orig_desc   = $lancom->lancom_i_description($partial) || {};
    my $vlan_desc   = $lancom->v_name($partial) || {};
    # inject dummy VLAN interfaces for ip alias
    foreach my $iid ( keys %$vlan_desc ) {
        my $newid = 1000 + $iid;
        $orig_desc->{$newid} = 'Dummy Interface for VLAN: '.$vlan_desc->{$iid};
    }
    return \%$orig_desc; 
}

#
# VLAN information are stored in the configuration MIBS
#
sub i_vlan {
    my $lancom      = shift;
    my $partial     = shift;
    my $index       = $lancom->new_lancom_vlan() || $lancom->old_lancom_vlan();
    my $interfaces  = $lancom->interfaces();
    my %rev         = reverse %$interfaces;
    if ($partial) {
        $partial = $interfaces->{$partial};
		# convert to int
		my @aOID = split( "", $partial);
        # adding '5.' which describes ethernet
		$partial = '5.'.join ( '.' , map { sprintf "%d", ord($_)} @aOID);
    }
    # PVID Lancom MIB
    my $tmp_i_pvid = $lancom->new_lancom_port_vid() || $lancom->old_lancom_port_vid() || {};
	my $i_pvid;
	if ($partial) {
		$i_pvid->{$partial} = $tmp_i_pvid->{$partial};
	} else {
		$i_pvid = $tmp_i_pvid;
	}
    my $i_vlan = {};
    foreach my $bport ( keys %$i_pvid ) {
        # convert to string
        my @aOID = split( '\.', $bport);
        shift(@aOID);
        my $myport = pack("c*", @aOID);
        $i_vlan->{$rev{$myport}} = $i_pvid->{$bport};
    }
    return \%$i_vlan;
}

sub i_untagged { goto &i_vlan }

sub i_vlan_membership {
    my $lancom  = shift;
    my $partial = shift;

    # No dynamic VLANs
	# we use the Configuration MIBS
	my $vlans = $lancom->new_lancom_vlan_ports || $lancom->old_lancom_vlan_ports;
    # reverse interfaces mapping
    my %interfaces = $lancom->_rev_interfaces();
    # vlan index
    my $v_index = $lancom->v_name();
    my %rev_v_index = reverse %$v_index;
    # return var
    my %return;
	foreach my $myport ( keys %$vlans ) {
		#extract VLAN Names
        my @aOID = split( '\.', $myport);
        shift(@aOID);
        my $tmp_myport = $rev_v_index{pack("c*", @aOID)};
		my @vlan_per_port = split(',', $vlans->{$myport});
		# Reverse
		foreach my $myvlan ( @vlan_per_port ) {
            my @test;
            if ($return{$interfaces{$myvlan}}) {
    			push(@{$return{$interfaces{$myvlan}}}, $tmp_myport);
            } else {
                @test = ($tmp_myport);
                $return{$interfaces{$myvlan}} = \@test;
            } 
		}
	}
    return \%return;
}

#
# it's time to place information about the phyical connected ports (ethernet only)
#
sub i_name {
    my $lancom          = shift;
    my $partial         = shift;
    my $interfaces      = $lancom->lancom_i_name($partial)  || {};
    my $lancom_elan     = $lancom->new_lancom_elan_lan()    || $lancom->old_lancom_elan_lan()   || {};
    my $lancom_elan_id  = $lancom->new_lancom_elan_id()     || $lancom->old_lancom_elan_lan()   || {};
    
    my %return;
    foreach my $iid ( keys %$interfaces ) {
        # LAN mapping in MIB is not really nice described from vendor
        my $elan_key = $interfaces->{$iid};
        $elan_key =~ s/LAN-/eLan/;
        my $elan_value;
        foreach my $elaniid ( keys %$lancom_elan ) {
            if ( $lancom_elan->{$elaniid} eq $elan_key ) {
                $elan_value .= ", $lancom_elan_id->{$elaniid}";
            } 
        }
        # remove leading ','
        $elan_value =~ s/^,\ //;
        $return{$iid} = $elan_value;
    }
    return \%return;
}

sub i_duplex {
	my $lancom = shift;
	return $lancom->mau_i_duplex;
}

sub ip_index { goto &_lancom_network_list }

#
# vlan information from the Lancom configuration
#
sub v_name {
    my $lancom  = shift;
    my $partial = shift;
    my $v_name  = $lancom->new_lancom_vlan($partial) || $lancom->old_lancom_vlan($partial);
    my %return; 
	foreach my $idx ( keys %$v_name ) {
		my @aOID = split( '\.', $idx);
		shift(@aOID);
		my $newidx = pack("c*", @aOID);
		$return{$v_name->{$idx}} = $newidx;
	}
    return \%return;
}
sub v_index {
    my $lancom  = shift;
    my $partial = shift;
    my $v_name  = $lancom->new_lancom_vlan($partial) || $lancom->old_lancom_vlan($partial);
    my %return; 
	foreach my $idx ( keys %$v_name ) {
		$return{$v_name->{$idx}} = $v_name->{$idx};
	}
    return \%return;
}



#
# LLDP stuff copied and modified
#

sub lldp_ip {
    my $lldp        = shift;
    my $partial     = shift;
    my $rman_addr   = $lldp->lldp_rman_addr($partial) || {};
    my %lldp_ip;
    foreach my $key ( keys %$rman_addr ) {
        my ( $index, $proto, $addr ) = _lldp_addr_index($key);
        next unless defined $index;
        next unless $proto == 1;
        $lldp_ip{$index} = $addr;
    }
    return \%lldp_ip;
}

sub lldp_port {
    my $lldp    = shift;
    my $partial = shift;

    my $pdesc   = $lldp->lldp_rem_desc($partial)     || {};
    my $pid     = $lldp->lldp_rem_pid($partial)      || {};
    my $ptype   = $lldp->lldp_rem_pid_type($partial) || {};
    my $desc    = $lldp->lldp_rem_sysdesc($partial)  || {};

    my %lldp_port;
    foreach my $key ( sort keys %$pid ) {
        my $port = $pdesc->{$key};
        my $type = $ptype->{$key};
        if ( $type and $type eq 'interfaceName' ) {
            # If the pid claims to be an interface name,
            # believe it.
            $port = $pid->{$key};
        }
        unless ($port) {
            $port = $pid->{$key};
            next unless $port;
            next unless $type;
          # May need to format other types in the future, i.e. Network address
            if ( $type =~ /mac/ ) {
                $port = join( ':',
                    map { sprintf "%02x", $_ } unpack( 'C*', $port ) );
            }
        }
        # Avaya/Nortel lldpRemPortDesc doesn't match ifDescr, but we can still
        # figure out slot.port based upon lldpRemPortDesc
        if ( defined $desc->{$key}
            && $desc->{$key}
            =~ /^Ethernet\s(?:Routing\s)?Switch\s\d|^Virtual\sServices\sPlatform\s\d/
            && $port =~ /^(Unit\s+(\d+)\s+)?Port\s+(\d+)$/ )
        {
            $port = defined $1 ? "$2.$3" : "1.$3";
        }
        # Cisco LLDP doesn't match ifDesc
        if ( defined $desc->{$key}
            && $desc->{$key}
            =~ /^Cisco\sIOS\sSoftware/
            && $port =~ /^(Gi)(\d?\/?\d+\/\d+)/ )
        {
            $port = "GigabitEthernet$2"; 
        }
        if ( defined $desc->{$key}
            && $desc->{$key}
            =~ /^Cisco\sIOS\sSoftware/
            && $port =~ /^(Fa)(\d?\/?\d+\/\d+)/ )
        {
            $port = "FastEthernet$2"; 
        }
        $lldp_port{$key} = $port;
    }
    return \%lldp_port;
}

sub lldp_if {
    my $lldp    = shift;
    my $partial = shift;

    my $addr        = $lldp->lldp_rem_pid($partial)     || {};
    my $i_descr     = $lldp->lancom_i_name()        	|| {};
    my $i_alias     = $lldp->i_alias()                  || {};
    my %r_i_descr   = reverse %$i_descr;
    my %r_i_alias   = reverse %$i_alias;

    my %lldp_if;
    foreach my $key ( keys %$addr ) {
        my @aOID = split( '\.', $key );
        my $port = $aOID[1];
        next unless $port;
        # Local LLDP port may not equate to ifIndex, see LldpPortNumber TEXTUAL-CONVENTION in LLDP-MIB.
        # Cross reference lldpLocPortDesc with ifDescr and ifAlias to get ifIndex,
        # prefer ifDescr over ifAlias because using cross ref with description is correct behavior 
        # according to the LLDP-MIB. Some devices (eg H3C gear) seem to use ifAlias though.
        my $lldp_desc = $lldp->lldpLocPortDesc($port);
        my $desc      = $lldp_desc->{$port};
        # If cross reference is successful use it, otherwise stick with lldpRemLocalPortNum
        if ( $desc && exists $r_i_descr{$desc} ) {
            $port = $r_i_descr{$desc};
        }
        elsif ( $desc && exists $r_i_alias{$desc} ) {
            $port = $r_i_alias{$desc};
        }
        $lldp_if{$key} = $port;
    }
    return \%lldp_if;
}

#
# don't know where netdisco use this value
# neighbor detection won't work if the Lancom VLAN1 IP differs from the management ip
#
sub root_ip {
    # return VLAN 1 IP provided by Configuration
    my $lancom  = shift;
    my $networks = $lancom->_lancom_network_list();
    my %rev = reverse %$networks;
    return $rev{'1'} if defined $rev{'1'};
    return;
}

#
# macsuck & arpnip
#

sub bp_index { 
	my $lancom = shift;
	my $index = $lancom->i_index();
	foreach my $idx ( keys %$index ) {
		$index->{$idx} = $idx;
	}
	return \%$index;
}

sub qb_fw_port { goto &fw_port }

#
# Clone from Bridge.pm
#
sub qb_fw_vlan {
    my $bridge      = shift;
    my $partial     = shift;
    my $qb_fw_port  = $bridge->qb_fw_port($partial);
    my $qb_fdb_ids  = $bridge->qb_fdb_index() || {};
    my $qb_fw_vlan  = {};
    foreach my $idx ( keys %$qb_fw_port ) {
        my $port = $bridge->fw_port($idx);
        my $vlan = $bridge->i_vlan->{$port};
        $qb_fw_vlan->{$idx} = $vlan;
    }
    return $qb_fw_vlan;
}

sub qb_fdb_index {
    my $bridge  = shift;
    my $partial = shift;

    # Some devices may not implement TimeFilter in a standard manner
    # appearing to loop on this request.  Override in the device class,
    # see Enterasys for example.
    my $qb_fdb_ids = $bridge->dot1qVlanFdbId() || {};

    # Strip the TimeFilter
    my $vl_fdb_index = {};
    for my $fdb_entry (keys(%$qb_fdb_ids)) {
        (my $vlan = $fdb_entry) =~ s/^\d+\.//;
        $vl_fdb_index->{$qb_fdb_ids->{$fdb_entry}} = $vlan;
    }

    return $vl_fdb_index;
}

sub fw_vlan { goto &qb_fw_vlan }

sub fw_mac {
    my $lancom  = shift;
	my $mac     = $lancom->new_lancom_arptable_mac() || $lancom->old_lancom_arptable_mac() || {};
	my %return;
	foreach my $idx ( values %$mac ) {
		my $hex = unpack "H*", $idx;
		my @pairs = $hex =~ /../sg;
		my $idx = join( ':' , @pairs);
		my $value = join( '.' , map { sprintf "%d", hex($_)} @pairs);
		$return{$value} = $idx;
	}
    return \%return;
}

sub fw_port {
    my $lancom  = shift;
	my $partial = shift;
	my $mac     = $lancom->new_lancom_arptable_mac()    || $lancom->old_lancom_arptable_mac()   || {};
	my $port    = $lancom->new_lancom_arptable_port()   || $lancom->old_lancom_arptable_port()  || {};
	# hurray port prints eLAN information?! 
    # mapping physical ports to logical LAN-X ports
	my $elan    = $lancom->new_lancom_network_elan()    || $lancom->old_lancom_network_elan()   || {};
	my %rev_elan = reverse %$elan;
	my %return;
	foreach my $idx ( keys %$port ) {
		my $e_mac = $mac->{$idx};
		my $e_port = $rev_elan{$port->{$idx}};
		my $hex = unpack "H*", $e_mac;
		my @pairs = $hex =~ /../sg;
		my $idx = join( '.' , map { sprintf "%d", hex($_)} @pairs);
		if (($partial) && ($partial eq $idx)) {
			return ($idx, $e_port);
		} else {
			$return{$idx} = $e_port;
		}
	}	
	return \%return;
}

#
# internal sub
# 
sub _rev_interfaces {
    my $lancom = shift;
    my $partial = shift;
    my $interfaces = $lancom->interfaces();
    my %return = reverse %$interfaces;
    return %return;
}

# 
# IP Aliases with virtual VLAN Interface (1000 + VLAN)
#
sub _lancom_network_list {
    my $lancom  = shift;
    my $partial = shift;
    my $ip      = $lancom->new_lancom_network_ip()      || $lancom->old_lancom_network_ip()         || {};
    my $vlan    = $lancom->new_lancom_network_ip_vlan() || $lancom->old_lancom_network_ip_vlan()    || {};
    my %return;
    foreach my $iid ( keys %$ip ) {
        $return{$ip->{$iid}} = 1000 + $vlan->{$iid};
    }
    return \%return;
}

sub _lldp_addr_index {
    my $idx    = shift;
    my @oids   = split( /\./, $idx );
    my $index  = join( '.', splice( @oids, 0, 3 ) );
    my $proto  = shift(@oids);
    shift(@oids) if scalar @oids > 4; # $length
    # IPv4
    if ( $proto == 1 ) {
	shift(@oids);
        return ( $index, $proto, join( '.', @oids ) );
    }

    # IPv6
    elsif ( $proto == 2 ) {
        return ( $index, $proto,
            join(':', unpack('(H4)*', pack('C*', @oids)) ) );
    }

    # MAC
    elsif ( $proto == 6 ) {
        return ( $index, $proto,
            join( ':', map { sprintf "%02x", $_ } @oids ) );
    }

    # TODO - Other protocols may be used as well; implement when needed?
    else {
        return;
    }
}

;
__END__

=head1 NAME

SNMP::Info::Layer3::Lancom - SNMP Interface to Lancom network devices.

=head1 AUTHOR

Christoph Neuhaus

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $lancom = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class = $lancom->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for Lancom network devices.

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

 my $lancom = new SNMP::Info::Layer3::Lancom(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::MAU

=item SNMP::Info::LLDP

=item SNMP::Info

=back

=head2 Required MIBs

=over

=item F<LC-UNIFIED-LCOS-10-12-REL-OIDS>

=item F<LANCOM_1711+_VPN-V9-00-0275_03-12-2014>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::MAU/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::LLDP/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $lancom->vendor()

Returns 'lancom'

=item $lancom->model()

Returns the chassis model.

=item $lancom->os()

Returns 'lcos'

=item $lancom->os_ver()

Returns the software version .

=item $lancom->serial()

Returns the chassis serial number.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $lancom->interfaces()

Returns reference to the map between IID and physical port inclusiv dummy VLAN port

=item $lancom->i_description()

Returns description inclusiv dummy VLAN ports

=item $lancom->i_vlan()

Returns a mapping between C<ifIndex> and the VLAN table stored in the Lancom configuration

=item $lancom->i_untaged()

See $lancom->i_vlan()

=item $lancom->i_vlan_membership()

Returns reference to has of arrays: key = C<ifIndex>, value = array of VLAN IDs.

=item $lancom->i_name()

Returns the human set port name if exists. Also a mapping of virtual LAN-X adapter to phyiscal port

=item $lancom->i_duplex()

Returns reference to hash. Maps port operational duplexes to IIDs.

=item $lancom->ip_index()

Returns reference to hash. Maps IP aliases to VLAN

=item $lancom->v_name()

Returns Human-entered name for VLANs

=item $lancom->v_index()

Returns VLAN IDs

=item $lancom->root_ip()

Returns VLAN 1 ipaddress

=item $lancom->lldp_*()

See L<SNMP::Info::LLDP/"TABLE METHODS">

=item $lancom->qb_*()

See L<SNMP::Info::Brdige/"TABLE METHODS">

=item $lancom->fw_*()

See L<SNMP::Info::Brdige/"TABLE METHODS">

=cut

=back
