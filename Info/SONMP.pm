# SNMP::Info::SONMP
# Eric Miller <eric@jeneric.org>
# $Id$
#
# Copyright (c) 2004 Eric Miller, Max Baker
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

package SNMP::Info::SONMP;
$VERSION = 1.0;

use strict;

use Exporter;
use SNMP::Info;
use Carp;

@SNMP::Info::SONMP::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::SONMP::EXPORT_OK = qw//;

use vars qw/$VERSION $DEBUG %FUNCS %GLOBALS %MIBS %MUNGE $INIT/;

%MIBS    = (
            'SYNOPTICS-ROOT-MIB' => 'synoptics',
            'S5-ETH-MULTISEG-TOPOLOGY-MIB' => 's5EnMsTop',
            );

%GLOBALS = (
            'cdp_id'  => 's5EnMsTopIpAddr',
            'cdp_run' => 's5EnMsTopStatus',
            );

%FUNCS  = (
            # From S5-ETH-MULTISEG-TOPOLOGY-MIB::TopNmmTable
            'sonmp_topo_slot'     => 's5EnMsTopNmmSlot',
            'sonmp_topo_port'     => 's5EnMsTopNmmPort',
            'sonmp_topo_ip'       => 's5EnMsTopNmmIpAddr',
            'sonmp_topo_seg'      => 's5EnMsTopNmmSegId',
            'sonmp_topo_mac'      => 's5EnMsTopNmmMacAddr',
            'sonmp_topo_platform' => 's5EnMsTopNmmChassisType',
            'sonmp_topo_localseg' => 's5EnMsTopNmmLocalSeg',
          );

%MUNGE = (
         'sonmp_topo_mac'           => \&SNMP::Info::munge_mac
         );

sub index_factor {
    return 32;
}

sub slot_offset {
    return 1;
}

sub port_offset {
    return 0;
}

sub hasCDP {
    my $sonmp = shift;
    return $sonmp->cdp_run();
}


sub c_if {
    my $sonmp = shift;
    my $sonmp_topo_port = $sonmp->sonmp_topo_port();
    my $sonmp_topo_slot = $sonmp->sonmp_topo_slot();
    my $index_factor = $sonmp->index_factor();
    my $slot_offset = $sonmp->slot_offset();
    my $port_offset = $sonmp->port_offset();
    my $model = $sonmp->model();

    my %c_if;
    foreach my $entry (keys %$sonmp_topo_port){
        my $port = $sonmp_topo_port->{$entry};
        next unless defined $port;
        next if $port == 0;
        my $slot = $sonmp_topo_slot->{$entry}||0;

        if ($model eq 'Baystack Hub') {
        my $comidx = $slot;
            if (! ($comidx % 5)) {
               $slot = ($slot / 5);
            } elsif ($comidx =~ /[16]$/) {
               $slot = int($slot/5);
               $port = 25;          
            } elsif ($comidx =~ /[27]$/) {
               $slot = int($slot/5);
               $port = 26;          
            }
        }

        my $index = (($slot-$slot_offset)*$index_factor) + ($port-$port_offset);
        
        $c_if{"$index.1"} = $index;
    }
    return \%c_if;
}

sub c_ip {
    my $sonmp = shift;
    my $sonmp_topo_ip   = $sonmp->sonmp_topo_ip();
    my $sonmp_topo_port = $sonmp->sonmp_topo_port();
    my $sonmp_topo_slot = $sonmp->sonmp_topo_slot();
    my $ip = $sonmp->cdp_id();
    my $index_factor = $sonmp->index_factor();
    my $slot_offset = $sonmp->slot_offset();
    my $port_offset = $sonmp->port_offset();
    my $model = $sonmp->model();

    
    # Count the number of devices seen on each port.
    # more than one device seen means connected to a non-sonmp
    # device, but other sonmp devices are squawking further away.
    my %ip_port;
    foreach my $entry (keys %$sonmp_topo_ip){
        my $port = $sonmp_topo_port->{$entry};
        next unless defined $port;
        next if ($port =~ /^[\d\.]+$/ and $port == 0);
        my $slot = $sonmp_topo_slot->{$entry}||0;
        
        if ($model eq 'Baystack Hub') {
            my $comidx = $slot;
               if (! ($comidx % 5)) {
                  $slot = ($slot / 5);
               } elsif ($comidx =~ /[16]$/) {
                  $slot = int($slot/5);
                  $port = 25;          
               } elsif ($comidx =~ /[27]$/) {
                  $slot = int($slot/5);
                  $port = 26;          
               }
          }

        my $index = (($slot-$slot_offset)*$index_factor) + ($port-$port_offset);
        
        my $ip = $sonmp_topo_ip->{$entry};
        push(@{$ip_port{$index}},$ip);
    }

    my %c_ip;
    foreach my $port (keys %ip_port){
        my $ips = $ip_port{$port};
        if (scalar @$ips == 1) {
            $c_ip{"$port.1"} = $ips->[0];
        } else {
            $c_ip{"$port.1"} = $ips;
        }
    }
    return \%c_ip;
}

sub c_port {
    my $sonmp = shift;
    my $sonmp_topo_port = $sonmp->sonmp_topo_port();
    my $sonmp_topo_seg = $sonmp->sonmp_topo_seg();
    my $sonmp_topo_slot = $sonmp->sonmp_topo_slot();
    my $index_factor = $sonmp->index_factor();
    my $slot_offset = $sonmp->slot_offset();
    my $port_offset = $sonmp->port_offset();
    my $model = $sonmp->model();
    my $sonmp_topo_platform = $sonmp->sonmp_topo_platform();

    my %c_port;
    foreach my $entry (keys %$sonmp_topo_seg){
        my $port = $sonmp_topo_port->{$entry};
        next unless defined $port;
        next if $port == 0;
        my $slot = $sonmp_topo_slot->{$entry};
        $slot = 0 unless defined $slot;

        if ($model eq 'Baystack Hub') {
            my $comidx = $slot;
               if (! ($comidx % 5)) {
                  $slot = ($slot / 5);
               } elsif ($comidx =~ /[16]$/) {
                  $slot = int($slot/5);
                  $port = 25;          
               } elsif ($comidx =~ /[27]$/) {
                  $slot = int($slot/5);
                  $port = 26;          
               }
          }

        my $index = (($slot-$slot_offset)*$index_factor) + ($port-$port_offset);
        
        # For fake remotes (multiple IPs for a c_ip), use first found
        next if defined $c_port{"$index.1"};

        my $seg  = $sonmp_topo_seg->{$entry};
        my $platform = $sonmp_topo_platform->{$entry};
        # AP-222x Series does not adhere to port numbering
        if ($platform =~ /AccessPoint/i) {
            $c_port{"$index.1"} = 'dp0';
        }
        # BayHubs send the lower three bytes of the MAC not the slot/port        
        elsif ($seg > 4000) {
            $c_port{"$index.1"} = 'unknown';
        }
        else {
            # Segment id is (256 * remote slot_num) + (remote_port)
            my $remote_port = $seg % 256;
            my $remote_slot = int($seg / 256);
    
           $c_port{"$index.1"} = "$remote_slot.$remote_port";
        }
    }
    return \%c_port;
}

sub c_platform {
    my $sonmp = shift;
    my $sonmp_topo_port = $sonmp->sonmp_topo_port();
    my $sonmp_topo_slot = $sonmp->sonmp_topo_slot();
    my $sonmp_topo_platform = $sonmp->sonmp_topo_platform();
    my $index_factor = $sonmp->index_factor();
    my $slot_offset = $sonmp->slot_offset();
    my $port_offset = $sonmp->port_offset();
    my $model = $sonmp->model();

    my %c_platform;
    foreach my $entry (keys %$sonmp_topo_platform){
        my $port = $sonmp_topo_port->{$entry}||0;
        next if $port == 0;
        my $slot = $sonmp_topo_slot->{$entry};
        $slot = 0 unless defined $slot;

        if ($model eq 'Baystack Hub') {
            my $comidx = $slot;
               if (! ($comidx % 5)) {
                  $slot = ($slot / 5);
               } elsif ($comidx =~ /[16]$/) {
                  $slot = int($slot/5);
                  $port = 25;          
               } elsif ($comidx =~ /[27]$/) {
                  $slot = int($slot/5);
                  $port = 26;          
               }
          }

        my $index = (($slot-$slot_offset)*$index_factor) + ($port-$port_offset);
        
        # For fake remotes (multiple IPs for a c_ip), use first found
        next if defined $c_platform{"$index.1"};

        my $platform  = $sonmp_topo_platform->{$entry};

        $c_platform{"$index.1"} = $platform;
    }
    return \%c_platform;
}

sub mac {
    my $sonmp = shift;
    my $sonmp_topo_port = $sonmp->sonmp_topo_port();
    my $sonmp_topo_mac = $sonmp->sonmp_topo_mac();
    
    foreach my $entry (keys %$sonmp_topo_port){
        my $port = $sonmp_topo_port->{$entry};
        next unless $port == 0;
        my $mac = $sonmp_topo_mac->{$entry};
        return $mac;
    }
    # Topology turned off, not supported.
    return undef;
}

1;
__END__

=head1 NAME

SNMP::Info::SONMP - Perl5 Interface to SynOptics Network Management Protocol (SONMP) using SNMP

=head1 AUTHOR

Eric Miller (C<eric@jeneric.org>)

=head1 SYNOPSIS

 my $sonmp = new SNMP::Info ( 
                             AutoSpecify => 1,
                             Debug       => 1,
                             DestHost    => 'router', 
                             Community   => 'public',
                             Version     => 2
                           );

 my $class = $sonmp->class();
 print " Using device sub class : $class\n";

 $hascdp   = $sonmp->hasCDP() ? 'yes' : 'no';

 # Print out a map of device ports with CDP neighbors:
 my $interfaces = $sonmp->interfaces();
 my $c_if       = $sonmp->c_if();
 my $c_ip       = $sonmp->c_ip();
 my $c_port     = $sonmp->c_port();

 foreach my $cdp_key (keys %$c_ip){
    my $iid           = $c_if->{$cdp_key};
    my $port          = $interfaces->{$iid};
    my $neighbor      = $c_ip->{$cdp_key};
    my $neighbor_port = $c_port->{$cdp_key};
    print "Port : $port connected to $neighbor / $neighbor_port\n";
 }

=head1 DESCRIPTION

SNMP::Info::SONMP is a subclass of SNMP::Info that provides an object oriented 
interface to the SynOptics Network Management Protocol (SONMP) information
through SNMP.

SONMP is a Layer 2 protocol that supplies topology information of devices that also speak SONMP, 
mostly switches and hubs.  SONMP is implemented in SynOptics, Bay, and Nortel Networks devices.
SONMP has been rebranded by Bay then Nortel Networks and is know by several different
names.

Create or use a device subclass that inherits this class.  Do not use directly.

Each device implements a subset of the global and cache entries. 
Check the return value to see if that data is held by the device.

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item SYNOPTICS-ROOT-MIB

=item S5-ETH-MULTISEG-TOPOLOGY-MIB

=back

MIBs can be found on the CD that came with your product.

Or, they can be downloaded directly from Nortel Networks regardless of support
contract status.

Go to http://www.nortelnetworks.com Techninal Support, Browse Technical Support,
Select by product, Java Device Manager, Software.  Download the latest version.
After installation, all mibs are located under the install directory under mibs
and the repspective product line.

Note:  Required version of SYNOPTICS-ROOT-MIB, must be version 199 or higher,
for example synro199.mib.

=head1 GLOBAL METHODS

These are methods that return scalar values from SNMP

=over

=item  $sonmp->index_factor()

Returns a number representing the number of ports reserved per slot or switch
within the device MIB.  Defaults to 32.

=item $sonmp->slot_offset()

Returns the offset if slot numbering does not start at 0.  Defaults to 1.

=item $sonmp->port_offset()

Returns the offset if port numbering does not start at 0.  Defaults to 0. 

=item  $cdp->hasCDP()

Is CDP is active in this device?

=item $sonmp->cdp_id()

Returns the IP that the device is sending out for its Nmm topology info.

(B<s5EnMsTopIpAddr>)

=item $sonmp->cdp_run()

Returns if the S5-ETH-MULTISEG-TOPOLOGY info is on for this device. 

(B<s5EnMsTopStatus>)

=item $sonmp->mac()

Returns MAC of the advertised IP address of the device. 

=back

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Layer2 Topology info (s5EnMsTopNmmTable)

=over

=item $sonmp->sonmp_topo_slot()

Returns reference to hash.  Key: Table entry, Value:slot number

(B<s5EnMsTopNmmSlot>)

=item $sonmp->sonmp_topo_port()

Returns reference to hash.  Key: Table entry, Value:Port Number (interface iid)

(B<s5EnMsTopNmmPort>)

=item $sonmp->sonmp_topo_ip()

Returns reference to hash.  Key: Table entry, Value:Remote IP address of entry

(B<s5EnMsTopNmmIpAddr>)

=item $sonmp->sonmp_topo_seg()

Returns reference to hash.  Key: Table entry, Value:Remote Segment ID

(B<s5EnMsTopNmmSegId>)

=item $sonmp->sonmp_topo_mac

(B<s5EnMsTopNmmMacAddr>)

Returns reference to hash.  Key: Table entry, Value:Remote MAC address

=item $sonmp->sonmp_topo_platform

Returns reference to hash.  Key: Table entry, Value:Remote Device Type

(B<s5EnMsTopNmmChassisType>)

=item $sonmp->sonmp_topo_localseg

Returns reference to hash.  Key: Table entry, Value:Boolean, if bay_topo_seg() is local

(B<s5EnMsTopNmmLocalSeg>)

=back

=head2 Psuedo CDP information

All entries with port=0 are local and ignored.

=over

=item $sonmp->c_if()

Returns reference to hash.  Key: ifIndex.1 Value: port (iid)

=item $sonmp->c_ip()

Returns referenece to hash.  Key: ifIndex.1 

The value of each hash entry can either be a scalar or an array.
A scalar value is most likely a direct neighbor to that port. 
It is possible that there is a non-SONMP device in between this device and the remote device.

An array value represents a list of seen devices.  The only time you will get an array
of neighbors, is if there is a non-SONMP device in between two or more devices. 

Use the data from the Layer2 Topology Table below to dig deeper.

=item $sonmp->c_port()

Returns reference to hash. Key: ifIndex.1 Value: remote port

=item $sonmp->c_platform()

Returns reference to hash. Key: ifIndex.1 Value: Remote Device Type

=back

=cut
