# SNMP::Info::Layer3 - SNMP Interface to Layer3 devices
# Max Baker <max@warped.org>
#
# Copyright (c) 2002, Regents of the University of California
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

package SNMP::Info::Layer3;
$VERSION = 0.1;

use strict;

use Exporter;
use SNMP::Info;
use SNMP::Info::CDP;
use SNMP::Info::Bridge;
use SNMP::Info::EtherLike;

use vars qw/$VERSION $DEBUG %GLOBALS %FUNCS $INIT %MIBS %MUNGE/;

@SNMP::Info::Layer3::ISA = qw/SNMP::Info SNMP::Info::CDP SNMP::Info::Bridge SNMP::Info::EtherLike Exporter/;
@SNMP::Info::Layer3::EXPORT_OK = qw//;

$DEBUG=0;
$SNMP::debugging=$DEBUG;

$INIT = 0;

%MIBS = ( %SNMP::Info::MIBS,
          %SNMP::Info::CDP::MIBS,
          %SNMP::Info::Bridge::MIBS,
          %SNMP::Info::EtherLike::MIBS,
          'ENTITY-MIB'         => 'entPhysicalName',
          'HP-ICF-OID'         => 'hpSwitch4000',
          'CISCO-PRODUCTS-MIB' => 'sysName',
          'OSPF-MIB'           => 'ospfRouterId',
        );

%GLOBALS = (
            # Inherit the super class ones
            %SNMP::Info::GLOBALS,
            %SNMP::Info::CDP::GLOBALS,
            %SNMP::Info::Bridge::GLOBALS,
            %SNMP::Info::EtherLike::GLOBALS,
            'mac'       => 'ifPhysAddress.1',
            'chassis'   => 'entPhysicalDescr.1',
            'router_ip' => 'ospfRouterId.0',
           );

%FUNCS   = (
            %SNMP::Info::FUNCS,
            %SNMP::Info::CDP::FUNCS,
            %SNMP::Info::Bridge::FUNCS,
            %SNMP::Info::EtherLike::FUNCS,
            # IFMIB
            'i_name2'    => 'ifName',
            # Address Translation Table (ARP Cache)
            'at_index'   => 'atIfIndex',
            'at_paddr'   => 'atPhysAddress',
            'at_netaddr' => 'atNetAddress',
            'ospf_ip'    => 'ospfHostIpAddress'
           );

%MUNGE = (
            # Inherit all the built in munging
            %SNMP::Info::MUNGE,
            %SNMP::Info::CDP::MUNGE,
            %SNMP::Info::Bridge::MUNGE,
            %SNMP::Info::EtherLike::MUNGE,
            'at_paddr' => \&SNMP::Info::munge_mac,
         );


# Method OverRides

sub root_ip {
    my $l3 = shift;

    my $router_ip  = $l3->router_ip();
    my $ospf_ip    = $l3->ospf_ip();

    # return the first one found here (should be only)
    if (defined $ospf_ip and scalar(keys %$ospf_ip)){
        foreach my $key (keys %$ospf_ip){
            my $ip = $ospf_ip->{$key};
            print " SNMP::Layer3::root_ip() using $ip\n" if $DEBUG;
            return $ip;
        }
    }

    return $router_ip if defined $router_ip;
    return undef;
}

sub i_ignore {
    my $l3 = shift;
    
    my $interfaces = $l3->interfaces();

    my %i_ignore;
    foreach my $if (keys %$interfaces) {
        # lo -> cisco aironet 350 loopback
        if ($interfaces->{$if} =~ /(tunnel|loopback|lo|null)/i){
            $i_ignore{$if}++;
        }
    }
    return \%i_ignore;
}

sub serial {
    my $l3 = shift;
    
    my $chassis = $l3->chassis();
    
    return $1 if (defined $chassis and $chassis =~ /serial#?:\s*([a-z0-9]+)/i);

}

# $l3->model() - the sysObjectID returns an IID to an entry in 
#       the CISCO-PRODUCT-MIB.  Look it up and return it.
sub model {
    my $l3 = shift;
    my $id = $l3->id();
    my $model = &SNMP::translateObj($id);

    $model =~ s/^cisco//i;
    return $model;
}

sub i_name {
    my $l3 = shift;
    my $i_index = $l3->i_index();
    my $i_alias = $l3->i_alias();
    my $i_name2  = $l3->i_name2();

    my %i_name;
    foreach my $iid (keys %$i_name2){
        my $name = $i_name2->{$iid};
        my $alias = $i_alias->{$iid};
        $i_name{$iid} = (defined $alias and $alias !~ /^\s*$/) ?
                        $alias : 
                        $name;
    }

    return \%i_name;
}

sub i_duplex {
    my $l3 = shift;

    my $el_index = $l3->el_index();
    my $el_duplex = $l3->el_duplex();
    
    my %i_index;
    foreach my $el_port (keys %$el_duplex){
        my $iid = $el_index->{$el_port};
        next unless defined $iid;
        my $duplex = $el_duplex->{$el_port};
        next unless defined $duplex;

        $i_index{$iid} = 'half' if $duplex =~ /half/i;
        $i_index{$iid} = 'full' if $duplex =~ /full/i;
        $i_index{$iid} = 'auto' if $duplex =~ /auto/i;
    }

    return \%i_index;
}

# $l3->interfaces() - Map the Interfaces to their physical names
sub interfaces {
    my $l3 = shift;
    my $interfaces = $l3->i_index();
    my $descriptions = $l3->i_description();

    my %interfaces = ();
    foreach my $iid (keys %$interfaces){
        my $desc = $descriptions->{$iid};
        next unless defined $desc;

        $interfaces{$iid} = $desc;
    }
    
    return \%interfaces;
}

sub vendor {
    my $l3 = shift;

    my $descr = $l3->description();

    return 'cisco' if ($descr =~ /(cisco|ios)/i);
    return 'foundry' if ($descr =~ /foundry/i);

}
1;
__END__

=head1 NAME

SNMP::Info::Layer3 - Perl5 Interface to network devices using Layer3

=head1 DESCRIPTION

Provides generic methods for accessing SNMP data for Layer 3 network devices. 
Includes support for Layer2+3 devices. See super classes for other inherited
methods.

Inherits from:

 SNMP::Info
 SNMP::Info::Bridge
 SNMP::Info::CDP
 SNMP::Info::EtherLike

Required MIBs:

 ENTITY-MIB         - For model identification
 CISCO-PRODUCTS-MIB - For model identification
 HP-ICF-OID         - For model identification
 MIBS listed in SNMP::Info::CDP, SNMP::Info::Bridge, and SNMP::Info::Etherlike

Cisco MIBs can be found at ftp://ftp.cisco.com/pub/mibs/v2/v2.tar.gz

HP MIBs can be found at http://www.hp.com/rnd/software

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 my $l3 = new SNMP::Info::Layer3(DestHost  => 'router' , 
                              Community => 'public' ); 

=head1 CREATING AN OBJECT

=over

=item  new SNMP::Info::Layer3()

Arguments passed to new() are passed on to SNMP::Session::new()
    

    my $l3 = new SNMP::Info::Layer3(
        DestHost => $host,
        Community => 'public',
        Version => 3,...
        ) 
    die "Couldn't connect.\n" unless defined $l3;

=item  $l3->session()

Sets or returns the SNMP::Session object

    # Get
    my $sess = $l3->session();

    # Set
    my $newsession = new SNMP::Session(...);
    $l3->session($newsession);

=back

=head1 GLOBALS

=over

=item $l3->mac()

Returns root port mac address

(B<ifPhysAddress.1>)

=item $l3->chassis()

Returns Chassis type (model).

(B<entPhysicalDescr.1>)

=item $l3->serial()

Trys to cull a serial number from $l3->chassis()

=item $l3->model()

Trys to reference $l3->id() to one of the product MIBs listed above

Removes 'cisco'  from cisco devices for readability.

=item $l3->vendor()

Trys to cull a Vendor name from B<sysDescr>

=back

=head1 TABLE ENTRIES

=head2 Overrides

=over

=item $l3->interfaces()

Returns the map between SNMP Interface Identifier (iid) and physical port name. 

Only returns those iids that have a description listed in $l3->i_description()

=item $l3->i_ignore()

Returns reference to hash.  Creates a key for each IID that should be ignored.

Currently looks for tunnel,loopback,lo,null from $l3->interfaces()

=item $l3->i_name()

Returns reference to hash of iid to human set name. 

Defaults to B<ifName>, but checks for an B<ifAlias>

=item $l3->i_duplex()

Returns reference to hash of iid to current link duplex setting.

Maps $l3->el_index() to $l3->el_duplex, then culls out 
full,half, or auto and sets the map to that value. 

see SNMP::Info::Etherlike for the el_index() and el_duplex() methods.

=back

=head2 ARP Cache Entries

=over

=item $l3->at_index()

Returns reference to map of IID to Arp Cache Entry

(B<atIfIndex>)

=item $l3->at_paddr()

Returns reference to hash of Arp Cache Entries to MAC address

(B<atPhysAddress>)

=item $l3->at_netaddr()

Returns reference to hash of Arp Cache Entries to IP Address

(B<atNetAddress>)

=back

=cut
