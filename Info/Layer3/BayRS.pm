# SNMP::Info::Layer3::BayRS
# Eric Miller
# $Id$
#
# Copyright (c) 2004 Eric Miller, Max Baker
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#     * Neither the name of the University of California, Santa Cruz nor the 
#       names of its contributors may be used to endorse or promote products 
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Layer3::BayRS;
$VERSION = '1.01';

use strict;

use Exporter;
use SNMP::Info;
use SNMP::Info::Bridge;

use vars qw/$VERSION $DEBUG %GLOBALS %FUNCS $INIT %MIBS %MUNGE %MODEL_MAP/;

@SNMP::Info::Layer3::BayRS::ISA = qw/SNMP::Info SNMP::Info::Bridge Exporter/;
@SNMP::Info::Layer3::BayRS::EXPORT_OK = qw//;

%MIBS = (
          %SNMP::Info::MIBS,
          %SNMP::Info::Bridge::MIBS,
          'Wellfleet-HARDWARE-MIB'        => 'wfHwBpIdOpt',
          'Wellfleet-OSPF-MIB'            => 'wfOspfRouterId',
          'Wellfleet-DOT1QTAG-CONFIG-MIB' => 'wfDot1qTagCfgVlanName',
          'Wellfleet-CSMACD-MIB'          => 'wfCSMACDCct',
        );

%GLOBALS = (
            %SNMP::Info::GLOBALS,
            %SNMP::Info::Bridge::GLOBALS,
            'bp_id'         => 'wfHwBpIdOpt',
            'bp_serial'     => 'wfHwBpSerialNumber',
            'ospf_rtr_id'   => 'wfOspfRouterId',
           );

%FUNCS = (
            %SNMP::Info::FUNCS,
            %SNMP::Info::Bridge::FUNCS,
            'i_name2'             => 'ifName',
            # From RFC1213-MIB
            'at_index'    => 'ipNetToMediaIfIndex',
            'at_paddr'    => 'ipNetToMediaPhysAddress',
            'at_netaddr'  => 'ipNetToMediaNetAddress',
            # From Wellfleet-CSMACD-MIB::wfCSMACDTable
            'wf_csmacd_cct'          => 'wfCSMACDCct',
            'wf_csmacd_slot'    => 'wfCSMACDSlot',
            'wf_csmacd_conn'    => 'wfCSMACDConnector',
            'wf_csmacd_mtu'            => 'wfCSMACDMtu',
            'wf_duplex'            => 'wfCSMACDLineCapability',
            'wf_csmacd_line'           => 'wfCSMACDLineNumber',
            # From Wellfleet-CSMACD-MIB::wfCSMACDAutoNegTable
            'wf_auto'            => 'wfCSMACDAutoNegSpeedSelect',
            # From Wellfleet-DOT1QTAG-CONFIG-MIB::wfDot1qTagConfigTable
            'wf_vlan_name'        => 'wfDot1qTagCfgVlanName',
            'wf_local_vlan_id'    => 'wfDot1qTagCfgLocalVlanId',
            'wf_global_vlan_id'   => 'wfDot1qTagCfgGlobalVlanId',
            'wf_vlan_port'          => 'wfDot1qTagCfgPhysicalPortId',
            # From Wellfleet-HARDWARE-MIB::wfHwTable
            'wf_hw_slot'        => 'wfHwSlot',
            'wf_hw_mod_id'        => 'wfHwModIdOpt',
            'wf_hw_mod_rev'        => 'wfHwModRev',
            'wf_hw_mod_ser'        => 'wfHwModSerialNumber',
            'wf_hw_mobo_id'     => 'wfHwMotherBdIdOpt ',
            'wf_hw_mobo_rev'    => 'wfHwMotherBdRev',
            'wf_hw_mobo_ser'        => 'wfHwMotherBdSerialNumber',
            'wf_hw_diag'        => 'wfHwDiagPromRev',
            'wf_hw_boot'        => 'wfHwBootPromRev',
            'wf_hw_mobo_mem'        => 'wfHwMotherBdMemorySize',
            'wf_hw_cfg_time'        => 'wfHwConfigDateAndTime ',
         );
         
%MUNGE = (
            %SNMP::Info::MUNGE,
            %SNMP::Info::Bridge::MUNGE,
            'at_paddr' => \&SNMP::Info::munge_mac,
         );

%MODEL_MAP = ( 
        'acefn'     => 'FN',
        'aceln'     => 'LN',
        'acecn'     => 'CN',
        'afn'       => 'AFN',
        'in'        => 'IN',
        'an'        => 'AN',
        'arn'       => 'ARN',
        'sys5000'   => '5000',
        'freln'     => 'BLN',
        'frecn'     => 'BCN',
        'frerbln'   => 'BLN-2',
        'asn'       => 'ASN',
        'asnzcable' => 'ASN-Z',
        'asnbcable' => 'ASN-B',
             );

sub model {
    my $bayrs = shift;
    my $bp_id = $bayrs->bp_id();

    return defined $MODEL_MAP{$bp_id} ? $MODEL_MAP{$bp_id} : $bp_id;
}

sub vendor {
    return 'nortel';
}

sub os {
    return 'bayrs';
}

sub os_ver {
    my $bayrs = shift;
    my $descr = $bayrs->description();
    return undef unless defined $descr;

    if ($descr =~ m/rel\/(\d+\.\d+\.\d+\.\d+)/){
        return $1;
    }
    return undef;
}

sub serial {
    my $bayrs = shift;
    my $serialnum = $bayrs->bp_serial(); 
    $serialnum = hex(join('','0x',map{sprintf "%02X", $_}unpack("C*",$serialnum)));
    
    return $serialnum if defined $serialnum ;
    return undef;
}

sub interfaces {
    my $bayrs = shift;
    my $description = $bayrs->i_description();
    my $vlan_ids = $bayrs->wf_global_vlan_id();
    my $vlan_idx = $bayrs->wf_local_vlan_id();
    
    my %interfaces = ();
    foreach my $iid (keys %$description){
        my $desc = $description->{$iid};
        next unless defined $desc;

        $desc  = $1 if $desc =~ /(^[A-Z]\d+)/;

        $interfaces{$iid} = $desc;
    }
    foreach my $iid (keys %$vlan_ids){
        my $vlan = $vlan_ids->{$iid};
        next unless defined $vlan;
        my $vlan_if = $vlan_idx->{$iid};
        next unless defined $vlan_if;
        
        my $desc = 'Vlan' . $vlan;

        $interfaces{$vlan_if} = $desc;
    }    
    return \%interfaces;
}

sub i_name {
    my $bayrs = shift;
    my $i_index = $bayrs->i_index();
    my $description = $bayrs->i_description();
    my $v_name  = $bayrs->wf_vlan_name();
    my $vlan_idx = $bayrs->wf_local_vlan_id();

    my %i_name;
    foreach my $iid (keys %$description){
        my $name = $description->{$iid};
        next unless defined $name;
        $i_name{$iid} = $name;
    }
    # Get VLAN Virtual Router Interfaces
    foreach my $vid (keys %$v_name){
        my $v_name = $v_name->{$vid};
        next unless defined $v_name;
        my $vlan_if = $vlan_idx->{$vid};
        next unless defined $vlan_if;

        $i_name{$vlan_if} = $v_name;
    }
    return \%i_name;
}

sub i_duplex {
    my $bayrs = shift;
    
    my $wf_cct = $bayrs->wf_csmacd_cct();
    my $wf_duplex = $bayrs->wf_duplex();
    
    my %i_duplex;
    foreach my $if (keys %$wf_cct){
        my $idx = $wf_cct->{$if};
        next unless defined $idx; 
        my $duplex = $wf_duplex->{$if};
        next unless defined $duplex; 
    
        my $string = 'half';
        $string = 'full' if $duplex =~ /duplex/i;
        
        $i_duplex{$idx}=$string; 
    }
    return \%i_duplex;
}

sub i_duplex_admin {
    my $bayrs = shift;
    
    my $wf_cct    = $bayrs->wf_csmacd_cct();
    my $wf_duplex = $bayrs->wf_duplex();
    my $wf_auto   = $bayrs->wf_auto();
    my $wf_slot   = $bayrs->wf_csmacd_slot();
    my $wf_conn   = $bayrs->wf_csmacd_conn();
 
    my %i_duplex_admin;
    foreach my $if (keys %$wf_cct){
        my $idx = $wf_cct->{$if};
        next unless defined $idx;
        my $duplex = $wf_duplex->{$if};
        next unless defined $duplex; 
        my $slot = $wf_slot->{$if};
        my $conn = $wf_conn->{$if};
        my $auto_idx = "$slot.$conn";
        my $auto = $wf_auto->{$auto_idx};
        
        my $string = 'other';
        if ($auto) {
            $string = 'half';
            $string = 'full' if $auto =~ /duplex/i;
            $string = 'auto' if $auto =~ /nway/i;
        }
        elsif ($duplex) {
            $string = 'half';        
            $string = 'full' if $duplex =~ /duplex/i;        
        }
        
        $i_duplex_admin{$idx}=$string; 
    }
    return \%i_duplex_admin;
}

sub i_vlan {
    my $bayrs = shift;

    my $wf_cct          = $bayrs->wf_csmacd_cct();
    my $wf_mtu          = $bayrs->wf_csmacd_mtu();
    my $wf_line         = $bayrs->wf_csmacd_line();
    my $wf_local_vid    = $bayrs->wf_local_vlan_id();
    my $wf_global_vid   = $bayrs->wf_global_vlan_id();
    my $wf_vport        = $bayrs->wf_vlan_port();

    my %i_vlan;
    # Look for VLANs on Ethernet Interfaces
    foreach my $if (keys %$wf_cct){
        my $idx = $wf_cct->{$if};
        next unless defined $idx;
        # Check MTU size, if unable to carry VLAN tag skip.
        my $mtu = $wf_mtu->{$if};
        next if (($mtu =~ /default/i) or ($mtu < 1522));
        my $line = $wf_line->{$if};
        my @vlans = ();
        foreach my $v_idx (keys %$wf_vport){
            my $port = $wf_vport->{$v_idx};
            next unless defined $port;
            next if ($port != $line);
                        
            my $vlan = $wf_global_vid->{$v_idx};
            push(@vlans, $vlan);
        }
        my $vlans = join (',', @vlans);    
        $i_vlan{$idx}=$vlans; 
    }
    # Add VLAN on VLAN Interfaces
    foreach my $idx (keys %$wf_global_vid){
        my $v_if = $wf_local_vid->{$idx};
        next unless defined $v_if;
        my $vlan = $wf_global_vid->{$idx};
        next unless defined $vlan;
        
        $i_vlan{$v_if}=$vlan; 
    }
    return \%i_vlan;
}

sub root_ip {
    my $bayrs = shift;

    my $ip_index        = $bayrs->ip_index();
    my $ip_table        = $bayrs->ip_table();
    
    # Check for CLIP
    foreach my $entry (keys %$ip_index){
        my $idx = $ip_index->{$entry};
        next unless $idx == 0;
        my $clip = $ip_table->{$entry};
        next unless ( (defined $clip) and ($clip ne '0.0.0.0') and ($bayrs->snmp_connect_ip($clip)) );
        print " SNMP::Layer3::BayRS::root_ip() using $clip\n" if $bayrs->debug();
        return $clip;
    }
    # Check for OSPF Router ID
    my $ospf_ip  = $bayrs->ospf_rtr_id();
    if ((defined $ospf_ip) and ($ospf_ip ne '0.0.0.0') and ($bayrs->snmp_connect_ip($ospf_ip)) ) {
        print " SNMP::Layer3::BayRS::root_ip() using $ospf_ip\n" if $bayrs->debug();
        return $ospf_ip;
    }

    return undef;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::BayRS - Perl5 Interface to Nortel routers running BayRS.

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $bayrs = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $bayrs->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for routers running Nortel BayRS.  

For speed or debugging purposes you can call the subclass directly, but not after determining
a more specific class using the method above. 

 my $bayrs = new SNMP::Info::Layer3::BayRS(...);

=head2 Inherited Classes

=over

=item SNMP::Info

=item SNMP::Info::Bridge

=back

=head2 Required MIBs

=over

=item Wellfleet-HARDWARE-MIB

=item Wellfleet-OSPF-MIB

=item Wellfleet-DOT1QTAG-CONFIG-MIB

=item Wellfleet-CSMACD-MIB

=item Inherited Classes' MIBs

See SNMP::Info for its own MIB requirements.

See SNMP::Info::Bridge for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $bayrs->model()

Returns the model of the BayRS router.  Will translate between the MIB model and 
the common model with this map :

%MODEL_MAP = ( 
        'acefn' => 'FN',
        'aceln' => 'LN',
        'acecn' => 'CN',
        'afn' => 'AFN',
        'in' => 'IN',
        'an' => 'AN',
        'arn' => 'ARN',
        'sys5000' => '5000',
        'freln' => 'BLN',
        'frecn' => 'BCN',
        'frerbln' => 'BLN-2',
        'asn' => 'ASN',
        'asnzcable' => 'ASN-Z',
        'asnbcable' => 'ASN-B',
             );

=item $bayrs->vendor()

Returns 'nortel'

=item $bayrs->os()

Returns 'bayrs'

=item $bayrs->os_ver()

Returns the software version extracted from B<sysDescr>

=item $bayrs->serial()

Returns (B<wfHwBpSerialNumber>) after conversion to ASCII decimal

=item $bayrs->root_ip()

Returns the primary IP used to communicate with the router.

Returns the first found:  CLIP (CircuitLess IP), (B<wfOspfRouterId>), or undefined.

=back

=head2 Globals imported from SNMP::Info

See documentation in SNMP::Info for details.

=head2 Globals imported from SNMP::Info::Bridge

See documentation in SNMP::Info::Bridge for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $bayrs->interfaces()

Returns reference to the map between IID and physical Port.

The physical port name is stripped to letter and numbers to signify
port type and slot port (S11) if the default platform naming was 
maintained.  Otherwise the port is the interface description. 

=item $bayrs->i_name()

Returns (B<ifDescr>) along with VLAN name (B<wfDot1qTagCfgVlanName>) for VLAN
interfaces.

=item $bayrs->i_duplex()

Returns reference to hash.  Maps port operational duplexes to IIDs for Ethernet
interfaces. 

=item $bayrs->i_duplex_admin()

Returns reference to hash.  Maps port admin duplexes to IIDs for Ethernet interfaces.

=item $bayrs->i_vlan()

Returns reference to hash.  Maps port VLAN ID to IIDs.

=back

=head2 RFC1213 Arp Cache Table (B<ipNetToMediaTable>)

=over

=item $bayrs->at_index()

Returns reference to hash.  Maps ARP table entries to Interface IIDs 

(B<ipNetToMediaIfIndex>)

=item $bayrs->at_paddr()

Returns reference to hash.  Maps ARP table entries to MAC addresses. 

(B<ipNetToMediaPhysAddress>)

=item $bayrs->at_netaddr()

Returns reference to hash.  Maps ARP table entries to IPs 

(B<ipNetToMediaNetAddress>)

=back

=head2 Table Methods imported from SNMP::Info

See documentation in SNMP::Info for details.

=head2 Table Methods imported from SNMP::Info::Bridge

See documentation in SNMP::Info::Bridge for details.

=cut
