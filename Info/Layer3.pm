# SNMP::Info::Layer3 - SNMP Interface to Layer3 devices
# Max Baker
#
# Copyright (c) 2004 Max Baker -- All changes from Version 0.7 on
#
# Copyright (c) 2002,2003 Regents of the University of California
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
$VERSION = 1.0;
# $Id$

use strict;

use Exporter;
use SNMP::Info;
use SNMP::Info::Bridge;
use SNMP::Info::EtherLike;
use SNMP::Info::Entity;

use vars qw/$VERSION $DEBUG %GLOBALS %FUNCS $INIT %MIBS %MUNGE/;

@SNMP::Info::Layer3::ISA = qw/SNMP::Info SNMP::Info::Bridge SNMP::Info::EtherLike
                              SNMP::Info::Entity Exporter/;
@SNMP::Info::Layer3::EXPORT_OK = qw//;

%MIBS = ( %SNMP::Info::MIBS,
          %SNMP::Info::Bridge::MIBS,
          %SNMP::Info::EtherLike::MIBS,
          %SNMP::Info::Entity::MIBS,
          'OSPF-MIB'    => 'ospfRouterId',
          'BGP4-MIB'    => 'bgpIdentifier',
        );

%GLOBALS = (
            # Inherit the super class ones
            %SNMP::Info::GLOBALS,
            %SNMP::Info::Bridge::GLOBALS,
            %SNMP::Info::EtherLike::GLOBALS,
            %SNMP::Info::Entity::GLOBALS,
            'mac'          => 'ifPhysAddress.1',
            'serial1'      => '.1.3.6.1.4.1.9.3.6.3.0', # OLD-CISCO-CHASSIS-MIB::chassisId.0
            'router_ip'    => 'ospfRouterId.0',
            'bgp_id'       => 'bgpIdentifier.0',
            'bgp_local_as' => 'bgpLocalAs.0',
           );

%FUNCS   = (
            %SNMP::Info::FUNCS,
            %SNMP::Info::Bridge::FUNCS,
            %SNMP::Info::EtherLike::FUNCS,
            %SNMP::Info::Entity::FUNCS,
            # IFMIB
            'i_name2'    => 'ifName',
            # Address Translation Table (ARP Cache)
            'at_index'   => 'atIfIndex',
            'at_paddr'   => 'atPhysAddress',
            'at_netaddr' => 'atNetAddress',
            'ospf_ip'    => 'ospfHostIpAddress',
            # BGP Peer Table
            'bgp_peers'               => 'bgpPeerLocalAddr',
            'bgp_peer_id'             => 'bgpPeerIdentifier',
            'bgp_peer_state'          => 'bgpPeerState',
            'bgp_peer_as'             => 'bgpPeerRemoteAs',
            'bgp_peer_addr'           => 'bgpPeerRemoteAddr',
            'bgp_peer_fsm_est_trans'  => 'bgpPeerFsmEstablishedTransitions',
            'bgp_peer_in_tot_msgs'    => 'bgpPeerInTotalMessages',
            'bgp_peer_in_upd_el_time' => 'bgpPeerInUpdateElapsedTime',
            'bgp_peer_in_upd'         => 'bgpPeerInUpdates', 
            'bgp_peer_out_tot_msgs'   => 'bgpPeerOutTotalMessages',
            'bgp_peer_out_upd'        => 'bgpPeerOutUpdates',
           );

%MUNGE = (
            # Inherit all the built in munging
            %SNMP::Info::MUNGE,
            %SNMP::Info::Bridge::MUNGE,
            %SNMP::Info::EtherLike::MUNGE,
            %SNMP::Info::Entity::MUNGE,
            'at_paddr' => \&SNMP::Info::munge_mac,
         );


# Method OverRides

sub root_ip {
    my $l3 = shift;

    my $router_ip  = $l3->router_ip();
    my $ospf_ip    = $l3->ospf_ip();

    # return the first one found here (should be only one)
    if (defined $ospf_ip and scalar(keys %$ospf_ip)){
        foreach my $key (keys %$ospf_ip){
            my $ip = $ospf_ip->{$key};
            next if $ip eq '0.0.0.0';
            next unless $l3->snmp_connect_ip($ip);
            print " SNMP::Layer3::root_ip() using $ip\n" if $l3->debug();
            return $ip;
        }
    }

    return $router_ip if ( (defined $router_ip) and ($router_ip ne '0.0.0.0') and ($l3->snmp_connect_ip($router_ip)) );
    return undef;
}

sub i_ignore {
    my $l3 = shift;
    
    my $interfaces = $l3->interfaces();

    my %i_ignore;
    foreach my $if (keys %$interfaces) {
        # lo -> cisco aironet 350 loopback
        if ($interfaces->{$if} =~ /(tunnel|loopback|\blo\b|null)/i){
            $i_ignore{$if}++;
        }
    }
    return \%i_ignore;
}

sub serial {
    my $l3 = shift;
    
    my $serial1     = $l3->serial1();
    my $e_descr     = $l3->e_descr()  || {};
    my $e_serial    = $l3->e_serial() || {};
    
    my $serial2     = $e_serial->{1}  || undef;
    my $chassis     = $e_descr->{1}   || undef;
    
    # precedence
    #   serial2,chassis parse,serial1
    return $serial2 if (defined $serial2 and $serial2 !~ /^\s*$/);
    return $1 if (defined $chassis and $chassis =~ /serial#?:\s*([a-z0-9]+)/i);
    return $serial1 if (defined $serial1 and $serial1 !~ /^\s*$/);

    return undef;
}

# $l3->model() - the sysObjectID returns an IID to an entry in 
#       the CISCO-PRODUCT-MIB.  Look it up and return it.
sub model {
    my $l3 = shift;
    my $id = $l3->id();
    
    unless (defined $id){
        print " SNMP::Info::Layer3::model() - Device does not support sysObjectID\n" if $l3->debug(); 
        return undef;
    }
    
    my $model = &SNMP::translateObj($id);

    return $id unless defined $model;

    $model =~ s/^cisco//i;
    $model =~ s/^catalyst//;
    $model =~ s/^cat//;
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

    return 'cisco' if ($descr =~ /(cisco|\bios\b)/i);
    return 'foundry' if ($descr =~ /foundry/i);

}

1;

__END__

=head1 NAME

SNMP::Info::Layer3 - Perl5 Interface to network devices serving Layer3 or Layers 2 & 3

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $l3 = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $l3->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

 # Let's get some basic Port information
 my $interfaces = $l3->interfaces();
 my $i_up       = $l3->i_up();
 my $i_speed    = $l3->i_speed();
 foreach my $iid (keys %$interfaces) {
    my $port  = $interfaces->{$iid};
    my $up    = $i_up->{$iid};
    my $speed = $i_speed->{$iid}
    print "Port $port is $up. Port runs at $speed.\n";
 }

=head1 DESCRIPTION

This class is usually used as a superclass for more specific device classes listed under 
SNMP::Info::Layer3::*   Please read all docs under SNMP::Info first.

Provides generic methods for accessing SNMP data for Layer 3 network devices. 
Includes support for Layer2+3 devices. 

For speed or debugging purposes you can call the subclass directly, but not after determining
a more specific class using the method above. 

 my $l3 = new SNMP::Info::Layer3(...);

=head2 Inherited Classes

=over

=item SNMP::Info

=item SNMP::Info::Bridge

For L2/L3 devices.

=item SNMP::Info::EtherLike

=back

=head2 Required MIBs

=over

=item OSPF-MIB

=item BGP4-MIB

=item Inherited Classes

MIBs required by the inherited classes listed above.

=back

MIBs can be found in the netdisco-mibs package.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $l3->mac()

Returns root port mac address

(B<ifPhysAddress.1>)

=item $l3->router_ip()

(B<ospfRouterId.0>)

=item $l3->bgp_id()

(B<bgpIdentifier.0>)

Returns the BGP identifier of the local system

=item $l3->bgp_local_as()

Returns the local autonomous system number 

(B<bgpLocalAs.0>)

=back

=head2 Overrides

=over

=item $l3->model()

Trys to reference $l3->id() to one of the product MIBs listed above

Removes 'cisco'  from cisco devices for readability.

=item $l3->serial()

Trys to cull a serial number from ENTITY-MIB, description, and OLD-CISCO-... mib

=item $l3->vendor()

Trys to cull a Vendor name from B<sysDescr>

=back

=head2 Globals imported from SNMP::Info

See documentation in SNMP::Info for details.

=head2 Globals imported from SNMP::Info::Bridge

See documentation in SNMP::Info::Bridge for details.

=head2 Globals imported from SNMP::Info::EtherLike

See documentation in SNMP::Info::EtherLike for details.

=head2 Globals imported from SNMP::Info::Entity

See documentation in SNMP::Info::Entity for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

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

=head2 BGP Peer Table

=over

=item $l3->bgp_peers()

Returns reference to hash of BGP peer to local IP address

(B<bgpPeerLocalAddr>)

=item $l3->bgp_peer_id()

Returns reference to hash of BGP peer to BGP peer identifier

(B<bgpPeerIdentifier>)

=item $l3->bgp_peer_state()

Returns reference to hash of BGP peer to BGP peer state

(B<bgpPeerState>)

=item $l3->bgp_peer_as()

Returns reference to hash of BGP peer to BGP peer autonomous system number

(B<bgpPeerRemoteAs>)

=item $l3->bgp_peer_addr()

Returns reference to hash of BGP peer to BGP peer IP address

(B<bgpPeerRemoteAddr>)

=item $l3->bgp_peer_fsm_est_trans()

Returns reference to hash of BGP peer to the total number of times the BGP FSM
transitioned into the established state

(B<bgpPeerFsmEstablishedTransitions>)

=item $l3->bgp_peer_in_tot_msgs()

Returns reference to hash of BGP peer to the total number of messages received
from the remote peer on this connection

(B<bgpPeerInTotalMessages>)

=item $l3->bgp_peer_in_upd_el_time()

Returns reference to hash of BGP peer to the elapsed time in seconds since
the last BGP UPDATE message was received from the peer.

(B<bgpPeerInUpdateElapsedTime>)

=item $l3->bgp_peer_in_upd()

Returns reference to hash of BGP peer to the number of BGP UPDATE messages
received on this connection

(B<bgpPeerInUpdates>)

=item $l3->bgp_peer_out_tot_msgs()

Returns reference to hash of BGP peer to the total number of messages transmitted
to the remote peer on this connection

(B<bgpPeerOutTotalMessages>)

=item $l3->bgp_peer_out_upd()

Returns reference to hash of BGP peer to the number of BGP UPDATE messages
transmitted on this connection

(B<bgpPeerOutUpdates>)

=back

=head2 Table Methods imported from SNMP::Info

See documentation in SNMP::Info for details.

=head2 Table Methods imported from SNMP::Info::Bridge

See documentation in SNMP::Info::Bridge for details.

=head2 Table Methods imported from SNMP::Info::EtherLike

See documentation in SNMP::Info::EtherLike for details.

=head2 Table Methods imported from SNMP::Info::Entity

See documentation in SNMP::Info::Entity for details.

=cut
