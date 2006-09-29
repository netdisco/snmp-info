# SNMP::Info::Layer3::Passport
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

package SNMP::Info::Layer3::Passport;
$VERSION = '1.05';

use strict;

use Exporter;
use SNMP::Info::SONMP;
use SNMP::Info::RapidCity;
use SNMP::Info::Layer3;

use vars qw/$VERSION $DEBUG %GLOBALS %FUNCS $INIT %MIBS %MUNGE/;

@SNMP::Info::Layer3::Passport::ISA = qw/SNMP::Info::SONMP SNMP::Info::RapidCity SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Passport::EXPORT_OK = qw//;

%MIBS = (
         %SNMP::Info::Layer3::MIBS,
         %SNMP::Info::RapidCity::MIBS,
         %SNMP::Info::SONMP::MIBS,
        );

%GLOBALS = (
            %SNMP::Info::Layer3::GLOBALS,
            %SNMP::Info::RapidCity::GLOBALS,
            %SNMP::Info::SONMP::GLOBALS,
           );

%FUNCS = (
          %SNMP::Info::Layer3::FUNCS,
          %SNMP::Info::RapidCity::FUNCS,
          %SNMP::Info::SONMP::FUNCS,
         );
         
%MUNGE = (
          %SNMP::Info::Layer3::MUNGE,
          %SNMP::Info::RapidCity::MUNGE,
          %SNMP::Info::SONMP::MUNGE,
         );

sub model {
    my $passport = shift;
    my $id = $passport->id();
    
    unless (defined $id){
        print " SNMP::Info::Layer3::Passport::model() - Device does not support sysObjectID\n" if $passport->debug(); 
        return undef;
    }
    
    my $model = &SNMP::translateObj($id);

    return $id unless defined $model;

    $model =~ s/^rcA//i;
    return $model;
}

sub vendor {
    return 'nortel';
}

sub os {
    return 'passport';
}

sub os_ver {
    my $passport = shift;
    my $descr = $passport->description();
    return undef unless defined $descr;

    #ERS / Passport
    if ($descr =~ m/(\d+\.\d+\.\d+\.\d+)/){
        return $1;
    }
    #Accelar
    if ($descr =~ m/(\d+\.\d+\.\d+)/){
        return $1;
    }
    return undef;
}

sub i_index {
    my $passport = shift;
    my $partial = shift;

    my $i_index = $passport->orig_i_index($partial);
    my $model   = $passport->model();

    my %if_index;
    foreach my $iid (keys %$i_index){
        my $index = $i_index->{$iid};
        next unless defined $index;

        $if_index{$iid} = $index;
    }

    # Get VLAN Virtual Router Interfaces
    if (!defined $partial or (defined $model and
        (($partial > 2000 and $model =~ /(86|83|81|16)/) or
        ($partial > 256  and $model =~ /(105|11[05]0|12[05])/)))) {
        
        my $vlan_index = $passport->rc_vlan_if() || {};
        
        foreach my $vid (keys %$vlan_index){
            my $v_index = $vlan_index->{$vid};
            next unless defined $v_index;
            next if $v_index == 0;
            next if (defined $partial and $v_index !~ /^$partial$/);

            $if_index{$v_index} = $v_index;
        }
    }

    if (defined $model and $model =~ /(86)/) {

        my $cpu_index = $passport->rc_cpu_ifindex($partial) || {};
        my $virt_ip = $passport->rc_virt_ip();
        
        # Get CPU Ethernet Interfaces
        foreach my $cid (keys %$cpu_index){
            my $c_index = $cpu_index->{$cid};
            next unless defined $c_index;
            next if $c_index == 0;

            $if_index{$c_index} = $c_index;
        }

        # Check for Virtual Mgmt Interface
        unless ($virt_ip eq '0.0.0.0') {
            # Make up an index number, 1 is not reserved AFAIK
            $if_index{1} = 1;
        }
    }
    return \%if_index;
}

sub interfaces {
    my $passport = shift;
    my $partial = shift;

    my $i_index = $passport->i_index($partial);
    my $model   = $passport->model();
    my $index_factor = $passport->index_factor();
    my $port_offset = $passport->port_offset();
    my $vlan_index = {};
    my %reverse_vlan;
    my $vlan_id = {};
    
    if (!defined $partial or (defined $model and
        (($partial > 2000 and $model =~ /(86|83|81|16)/) or
        ($partial > 256  and $model =~ /(105|11[05]0|12[05])/)))) {
            $vlan_index = $passport->rc_vlan_if(); 
            %reverse_vlan = reverse %$vlan_index;
            $vlan_id = $passport->rc_vlan_id();
    }
   
    my %if;
    foreach my $iid (keys %$i_index){
        my $index = $i_index->{$iid};
        next unless defined $index;

        if (($index == 1) and ($model =~ /(86)/)) {
            $if{$index} = 'Cpu.Virtual';
        }

        elsif (($index == 192) and ($model eq '8603')) {
            $if{$index} = 'Cpu.3';
        }

        elsif (($index == 320) and ($model =~ /(8606|8610|8610co)/)) {
            $if{$index} = 'Cpu.5';
        }

        elsif (($index == 384) and ($model =~ /(8606|8610|8610co)/)) {
            $if{$index} = 'Cpu.6';
        }

        elsif (($index > 2000 and $model =~ /(86|83|81|16)/) or
               ($index > 256  and $model =~ /(105|11[05]0|12[05])/)) {

                my $v_index = $reverse_vlan{$iid};
                my $v_id = $vlan_id->{$v_index};
                next unless defined $v_id;
                my $v_port = 'Vlan'."$v_id";
                $if{$index} = $v_port;
        }           

        else {
            my $port = ($index % $index_factor) + $port_offset;
            my $slot = int($index / $index_factor);

            my $slotport = "$slot.$port";
            $if{$iid} = $slotport;
        }

    }

    return \%if;
}

sub i_mac {
    my $passport = shift;
    my $partial = shift;

    my $i_mac = $passport->orig_i_mac($partial) || {};
    my $model   = $passport->model();

    my %if_mac;
    foreach my $iid (keys %$i_mac){
        my $mac = $i_mac->{$iid};
        next unless defined $mac;

        $if_mac{$iid} = $mac;
    }

    # Get VLAN Virtual Router Interfaces
    if (!defined $partial or (defined $model and
        (($partial > 2000 and $model =~ /(86|83|81|16)/) or
        ($partial > 256  and $model =~ /(105|11[05]0|12[05])/)))) {

        my $vlan_index = $passport->rc_vlan_if() || {};
        my $vlan_mac = $passport->rc_vlan_mac() || {};

        foreach my $iid (keys %$vlan_mac){
            my $v_mac = $vlan_mac->{$iid};
            next unless defined $v_mac;
            my $v_id  = $vlan_index->{$iid};
            next unless defined $v_id;
            next if (defined $partial and $v_id !~ /^$partial$/);

            $if_mac{$v_id} = $v_mac;
        }
    }
    
    if (defined $model and $model =~ /(86)/) {

        my $cpu_mac = $passport->rc_cpu_mac($partial);
        my $virt_ip = $passport->rc_virt_ip();

        # Get CPU Ethernet Interfaces
        foreach my $iid (keys %$cpu_mac){
            my $mac = $cpu_mac->{$iid};
            next unless defined $mac;

            $if_mac{$iid} = $mac;
        }

        # Check for Virtual Mgmt Interface
        unless (($virt_ip eq '0.0.0.0') or (defined $partial and $partial ne "1")) {
            my $chassis_base_mac = $passport->rc_base_mac();
            my @virt_mac = split /:/, $chassis_base_mac;
            $virt_mac[0] = hex($virt_mac[0]);
            $virt_mac[1] = hex($virt_mac[1]);
            $virt_mac[2] = hex($virt_mac[2]);
            $virt_mac[3] = hex($virt_mac[3]);
            $virt_mac[4] = hex($virt_mac[4]) + 0x03;
            $virt_mac[5] = hex($virt_mac[5]) + 0xF8;

            my $mac = join(':',map { sprintf "%02x",$_ } @virt_mac);

            $if_mac{1} = $mac;
        }
    }
    return \%if_mac;
}

sub i_description {
    my $passport = shift;
    my $partial = shift;

    my $i_descr = $passport->orig_i_description($partial) || {};
    my $model   = $passport->model();

    my %descr;
    foreach my $iid (keys %$i_descr){
        my $if_descr = $i_descr->{$iid};
        next unless defined $if_descr;

        $descr{$iid} = $if_descr;
    }

    # Get VLAN Virtual Router Interfaces
    if (!defined $partial or (defined $model and
        (($partial > 2000 and $model =~ /(86|83|81|16)/) or
        ($partial > 256  and $model =~ /(105|11[05]0|12[05])/)))) {

        my $v_descr = $passport->rc_vlan_name();
        my $vlan_index = $passport->rc_vlan_if();

        foreach my $vid (keys %$v_descr){
            my $vl_descr = $v_descr->{$vid};
            next unless defined $vl_descr;
            my $v_id  = $vlan_index->{$vid};
            next unless defined $v_id;
            next if (defined $partial and $v_id !~ /^$partial$/);

            $descr{$v_id} = $vl_descr;
        }
    }
    return \%descr;
}
    
sub i_name {
    my $passport = shift;
    my $partial = shift;

    my $model   = $passport->model();
    my $i_index = $passport->i_index($partial) || {};
    my $rc_alias = $passport->rc_alias($partial) || {};
    my $i_name2  = $passport->orig_i_name($partial) || {};
    my $v_name = {};
    my $vlan_index = {};
    my %reverse_vlan;

    if (!defined $partial or (defined $model and
        (($partial > 2000 and $model =~ /(86|83|81|16)/) or
        ($partial > 256  and $model =~ /(105|11[05]0|12[05])/)))) {
            $v_name = $passport->rc_vlan_name() || {};
            $vlan_index = $passport->rc_vlan_if() || {};
            %reverse_vlan = reverse %$vlan_index;
    }    

    my %i_name;
    foreach my $iid (keys %$i_index){
 
        if (($iid == 1) and ($model =~ /(86)/)) {
            $i_name{$iid} = 'CPU Virtual Management IP';
        }

        elsif (($iid == 192) and ($model eq '8603')) {
            $i_name{$iid} = 'CPU 3 Ethernet Port';
        }

        elsif (($iid == 320) and ($model =~ /(8606|8610|8610co)/)) {
            $i_name{$iid} = 'CPU 5 Ethernet Port';
        }

        elsif (($iid == 384) and ($model =~ /(8606|8610|8610co)/)) {
            $i_name{$iid} = 'CPU 6 Ethernet Port';
        }

        elsif (($iid > 2000 and defined $model and $model =~ /(86|83|81|16)/) or
                ($iid > 256 and defined $model and $model =~ /(105|11[05]0|12[05])/)) {
            my $vlan_index = $reverse_vlan{$iid};
            my $vlan_name = $v_name->{$vlan_index};
            next unless defined $vlan_name;

            $i_name{$iid} = $vlan_name;
        }

        else {
            my $name = $i_name2->{$iid};
            my $alias = $rc_alias->{$iid};
            $i_name{$iid} = (defined $alias and $alias !~ /^\s*$/) ?
                        $alias : 
                        $name;
        }
    }

    return \%i_name;
}

sub ip_index {
    my $passport = shift;
    my $partial = shift;

    my $model   = $passport->model();
    my $ip_index = $passport->orig_ip_index($partial) || {};

    my %ip_index;
    foreach my $ip (keys %$ip_index){
        my $iid  = $ip_index->{$ip};
        next unless defined $iid;
        
        $ip_index{$ip} = $iid;
    }

    # Only 8600 has CPU and Virtual Management IP
    if (defined $model and $model =~ /(86)/) {

    my $cpu_ip = $passport->rc_cpu_ip($partial) || {};
    my $virt_ip = $passport->rc_virt_ip($partial) || {};

        # Get CPU Ethernet IP
        foreach my $cid (keys %$cpu_ip){
            my $c_ip = $cpu_ip->{$cid};
            next unless defined $c_ip;

            $ip_index{$c_ip} = $cid;
        }

        # Get Virtual Mgmt IP
        $ip_index{$virt_ip} = 1;
    }
    
    return \%ip_index;
}

sub root_ip {
    my $passport = shift;
    my $model   = $passport->model();
    my $rc_ip_addr = $passport->rc_ip_addr();
    my $rc_ip_type = $passport->rc_ip_type();
    my $virt_ip = $passport->rc_virt_ip();
    my $router_ip  = $passport->router_ip();
    my $sonmp_topo_port = $passport->sonmp_topo_port();
    my $sonmp_topo_ip = $passport->sonmp_topo_ip();

    # Only 8600 and 1600 have CLIP or Management Virtual IP
    if (defined $model and $model =~ /(86|16)/) {
        # Return CLIP (CircuitLess IP)
        foreach my $iid (keys %$rc_ip_type){
            my $ip_type = $rc_ip_type->{$iid};
            next unless ((defined $ip_type) and ($ip_type =~ /circuitLess/i));
            my $ip = $rc_ip_addr->{$iid};
            next unless defined $ip;
            
            return $ip if $passport->snmp_connect_ip($ip);
        }

        # Return Management Virtual IP address
        if ( (defined $virt_ip) and ($virt_ip ne '0.0.0.0') ) {
            return $virt_ip if $passport->snmp_connect_ip($virt_ip);
        }
    }

    # Return OSPF Router ID
    if ((defined $router_ip) and ($router_ip ne '0.0.0.0')) {
        foreach my $iid (keys %$rc_ip_addr){
            my $ip = $rc_ip_addr->{$iid};
            next unless $router_ip eq $ip;
            return $router_ip if $passport->snmp_connect_ip($router_ip);
        }
    }

    # Otherwise Return SONMP Advertised IP Address    
    foreach my $entry (keys %$sonmp_topo_port){
        my $port = $sonmp_topo_port->{$entry};
        next unless $port == 0;
        my $ip = $sonmp_topo_ip->{$entry};
        return $ip if ( (defined $ip) and ($ip ne '0.0.0.0') and ($passport->snmp_connect_ip($ip)) );
    }
    return undef;
}

# Required for SNMP::Info::SONMP
sub index_factor {
    my $passport   = shift;
    my $model   = $passport->model();
    my $index_factor = 64;
    # Older Accelar models use base 16 instead of 64
    $index_factor = 16  if (defined $model and $model =~ /(105|11[05]0|12[05])/);
    return $index_factor;
}

sub slot_offset {
    return 0;
}

sub port_offset {
    return 1;
}

# Bridge MIB does not map Bridge Port to ifIndex correctly
sub bp_index {
    my $passport = shift;
    my $partial = shift;

    my $if_index = $passport->i_index($partial) || {};

    my %bp_index;
    foreach my $iid (keys %$if_index){
        $bp_index{$iid} = $iid;
    }
    return \%bp_index;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Passport - SNMP Interface to modular Nortel Ethernet Routing
Switches (formerly Passport / Accelar)

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $passport = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class = $passport->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for modular Nortel Ethernet Routing Switches (formerly
Passport and Accelar Series Switches).

These devices have some of the same charactersitics as the stackable Nortel 
Ethernet Switches (Baystack).  For example, extended interface information is 
gleened from RAPID-CITY.

For speed or debugging purposes you can call the subclass directly, but not after
determining a more specific class using the method above. 

 my $passport = new SNMP::Info::Layer3::Passport(...);

=head2 Inherited Classes

=over

=item SNMP::Info::SONMP

=item SNMP::Info::RapidCity

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::SONMP> for its own MIB requirements.

See L<SNMP::Info::RapidCity> for its own MIB requirements.

See L<SNMP::Info::Layer3> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $passport->model()

Returns model type.  Checks $passport->id() against the 
RAPID-CITY-MIB and then parses out rcA.

=item $passport->vendor()

Returns 'nortel'

=item $passport->os()

Returns 'passport'

=item $passport->os_ver()

Returns the software version extracted from B<sysDescr>

=item $passport->serial()

Returns (B<rcChasSerialNumber>)

=item $passport->root_ip()

Returns the primary IP used to communicate with the device.  Returns the first
found:  CLIP (CircuitLess IP), Management Virtual IP (B<rcSysVirtualIpAddr>),
OSPF Router ID (B<ospfRouterId>), SONMP Advertised IP Address.

=back

=head2 Overrides

=over

=item $passport->index_factor()

Required by SNMP::Info::SONMP.  Returns 64 for 8600, 16 for Accelar.

=item $passport->port_offset()

Required by SNMP::Info::SONMP.  Returns 1.

=item $passport->slot_offset()

Required by SNMP::Info::SONMP.  Returns 0.

=back

=head2 Global Methods imported from SNMP::Info::SONMP

See documentation in L<SNMP::Info::SONMP> for details.

=head2 Global Methods imported from SNMP::Info::RapidCity

See documentation in L<SNMP::Info::RapidCity> for details.

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $passport->i_index()

Returns SNMP IID to Interface index.  Extends (B<ifIndex>) by adding the index of
the CPU virtual management IP (if present), each CPU Ethernet port, and each VLAN
to ensure the virtual router ports are captured.

=item $passport->interfaces()

Returns reference to the map between IID and physical Port.

Slot and port numbers on the Passport switches are determined by the formula:
port = (ifIndex % index_factor) + port_offset, slot = int(ifIndex / index_factor).

The physical port name is returned as slot.port.  CPU Ethernet ports are prefixed
with CPU and VLAN interfaces are returned as the VLAN ID prefixed with Vlan.

=item $passport->i_mac()

MAC address of the interface.  Note this is just the MAC of the port, not anything
connected to it.

=item $passport->i_description()

Description of the interface. Usually a little longer single word name that is both
human and machine friendly.  Not always.

=item $passport->i_name()

Crosses rc_alias() (B<rcPortName>) with ifAlias() and returns the human set port
name if exists.

=item $passport->ip_index()

Maps the IP Table to the IID.  Extends (B<ipAdEntIfIndex>) by adding the index of
the CPU virtual management IP (if present) and each CPU Ethernet port.

=item $passport->bp_index()

Returns reference to hash of bridge port table entries map back to interface identifier (iid)

Returns (B<ifIndex>) for both key and value since some devices seem to have
problems with BRIDGE-MIB

=back

=head2 Table Methods imported from SNMP::Info::SONMP

See documentation in L<SNMP::Info::SONMP> for details.

=head2 Table Methods imported from SNMP::Info::RapidCity

See documentation in L<SNMP::Info::RapidCity> for details.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=cut
