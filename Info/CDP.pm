# SNMP::Info::CDP
# $Id$
#
# Changes since Version 0.7 Copyright (c) 2004 Max Baker
# All rights reserved.
#
# Copyright (c) 2002,2003 Regents of the University of California
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

package SNMP::Info::CDP;

use strict;
use Exporter;
use SNMP::Info;

@SNMP::Info::CDP::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::CDP::EXPORT_OK = qw//;

use vars qw/$VERSION $DEBUG %FUNCS %GLOBALS %MIBS %MUNGE $INIT/;

$VERSION = '3.01';

# Five data structures required by SNMP::Info
%MIBS = ( 'CISCO-CDP-MIB' => 'cdpGlobalRun' );

# Notice we dont inherit the default GLOBALS and FUNCS
# only the default MUNGE.
%GLOBALS = (
    'cdp_run'      => 'cdpGlobalRun',
    'cdp_interval' => 'cdpGlobalMessageInterval',
    'cdp_holdtime' => 'cdpGlobalHoldTime',
    'cdp_gid'       => 'cdpGlobalDeviceId',
);

%FUNCS = (
    'cdp_index'        => 'cdpCacheIfIndex',
    'cdp_proto'        => 'cdpCacheAddressType',
    'cdp_addr'         => 'cdpCacheAddress',
    'cdp_ver'          => 'cdpCacheVersion',
    'cdp_id'           => 'cdpCacheDeviceId',
    'cdp_port'         => 'cdpCacheDevicePort',
    'cdp_platform'     => 'cdpCachePlatform',
    'cdp_capabilities' => 'cdpCacheCapabilities',
    'cdp_domain'       => 'cdpCacheVTPMgmtDomain',
    'cdp_vlan'         => 'cdpCacheNativeVLAN',
    'cdp_duplex'       => 'cdpCacheDuplex',
    'cdp_power'        => 'cdpCachePowerConsumption',
    'cdp_pri_mgmt_type'=> 'cdpCachePrimaryMgmtAddrType',
    'cdp_pri_mgmt_addr'=> 'cdpCachePrimaryMgmtAddr',
    'cdp_sec_mgmt_type'=> 'cdpCacheSecondaryMgmtAddrType',
    'cdp_sec_mgmt_addr'=> 'cdpCacheSecondaryMgmtAddr',
);

%MUNGE = (
    'cdp_capabilities' => \&SNMP::Info::munge_caps,
    'cdp_platform'     => \&SNMP::Info::munge_null,
    'cdp_domain'       => \&SNMP::Info::munge_null,
    'cdp_port'         => \&SNMP::Info::munge_null,
    'cdp_id'           => \&SNMP::Info::munge_null,
    'cdp_ver'          => \&SNMP::Info::munge_null,
    'cdp_ip'           => \&SNMP::Info::munge_ip,
    'cdp_power'        => \&munge_power,

);

sub munge_power {
    my $power = shift;
    my $decimal = substr( $power, -3 );
    $power =~ s/$decimal$/\.$decimal/;
    return $power;
}

sub hasCDP {
    my $cdp = shift;

    my $ver = $cdp->{_version};

    # SNMP v1 clients dont have the globals
    if ( defined $ver and $ver == 1 ) {
        my $cdp_ip = $cdp->cdp_ip();

        # See if anything in cdp cache, if so we have cdp
        return 1 if ( defined $cdp_ip and scalar( keys %$cdp_ip ) );
        return;
    }

    return $cdp->cdp_run();
}

sub cdp_if {
    my $cdp = shift;

    # See if by some miracle Cisco implemented the cdpCacheIfIndex entry
    my $cdp_index = $cdp->cdp_index();
    return $cdp_index if defined $cdp_index;

    # Nope, didn't think so. Now we fake it.
    my $cdp_ip = $cdp->cdp_ip();
    unless ( defined $cdp_ip ) {
        $cdp->error_throw(
            "SNMP::Info::CDP:cdp_if() - Device doesn't have cdp_ip() data.  Can't fake cdp_index()"
        );
        return;
    }

    my %cdp_if;
    foreach my $key ( keys %$cdp_ip ) {
        next unless defined $key;
        my $iid = $key;

        # Truncate .1 from cdp cache entry
        $iid =~ s/\.\d+$//;
        $cdp_if{$key} = $iid;
    }

    return \%cdp_if;
}

sub cdp_ip {
    my $cdp     = shift;
    my $partial = shift;

    my $cdp_addr  = $cdp->cdp_addr($partial)  || {};
    my $cdp_proto = $cdp->cdp_proto($partial) || {};

    my %cdp_ip;
    foreach my $key ( keys %$cdp_addr ) {
        my $addr  = $cdp_addr->{$key};
        my $proto = $cdp_proto->{$key};
        next unless defined $addr;
        next if ( defined $proto and $proto ne 'ip' );

        my $ip = join( '.', unpack( 'C4', $addr ) );
        $cdp_ip{$key} = $ip;
    }
    return \%cdp_ip;
}

1;
__END__

=head1 NAME

SNMP::Info::CDP - SNMP Interface to Cisco Discovery Protocol (CDP) using SNMP

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 my $cdp = new SNMP::Info ( 
                             AutoSpecify => 1,
                             Debug       => 1,
                             DestHost    => 'router', 
                             Community   => 'public',
                             Version     => 2
                           );

 my $class = $cdp->class();
 print " Using device sub class : $class\n";

 $hascdp   = $cdp->hasCDP() ? 'yes' : 'no';

 # Print out a map of device ports with CDP neighbors:
 my $interfaces = $cdp->interfaces();
 my $cdp_if       = $cdp->cdp_if();
 my $cdp_ip       = $cdp->cdp_ip();
 my $cdp_port     = $cdp->cdp_port();

 foreach my $cdp_key (keys %$cdp_ip){
    my $iid           = $cdp_if->{$cdp_key};
    my $port          = $interfaces->{$iid};
    my $neighbor      = $cdp_ip->{$cdp_key};
    my $neighbor_port = $cdp_port->{$cdp_key};
    print "Port : $port connected to $neighbor / $neighbor_port\n";
 }

=head1 DESCRIPTION

SNMP::Info::CDP is a subclass of SNMP::Info that provides an object oriented 
interface to CDP information through SNMP.

CDP is a Layer 2 protocol that supplies topology information of devices that
also speak CDP, mostly switches and routers.  CDP is implemented in Cisco and
some HP devices.

Create or use a device subclass that inherits this class.  Do not use
directly.

Each device implements a subset of the global and cache entries. 
Check the return value to see if that data is held by the device.

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item F<CISCO-CDP-MIB>

=back

MIBs can be found at ftp://ftp.cisco.com/pub/mibs/v2/v2.tar.gz

=head1 GLOBAL METHODS

These are methods that return scalar values from SNMP

=over

=item  $cdp->hasCDP()

Is CDP is active in this device?  

Accounts for SNMP version 1 devices which may have CDP but not cdp_run()

=item $cdp->cdp_run()

Is CDP enabled on this device?  Note that a lot of Cisco devices that
implement CDP don't implement this value. @#%$!

(C<cdpGlobalRun>)

=item $cdp->cdp_interval()

Interval in seconds at which CDP messages are generated.

(C<cdpGlobalMessageInterval>)

=item $cdp->cdp_holdtime()

Time in seconds that CDP messages are kept. 

(C<cdpGlobalHoldTime>)

=item  $cdp->cdp_gid() 

Returns CDP device ID.  

This is the device id broadcast via CDP to other devices, and is what is
retrieved from remote devices with $cdp->id().

(C<cdpGlobalDeviceId>)

=back

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 CDP CACHE ENTRIES

=over

=item $cdp->cdp_capabilities()

Returns Device Functional Capabilities.  Results are munged into an ascii
binary string, 7 digits long, MSB.  Each digit represents a bit from the
table below.

From L<http://www.cisco.com/univercd/cc/td/doc/product/lan/trsrb/frames.htm#18843>:

(Bit) - Description

=over

=item (0x40) - Provides level 1 functionality.

=item (0x20) - The bridge or switch does not forward IGMP Report packets on
non router ports.

=item (0x10) - Sends and receives packets for at least one network layer
protocol. If the device is routing the protocol, this bit should not be set.

=item (0x08) - Performs level 2 switching. The difference between this bit
and bit 0x02 is that a switch does not run the Spanning-Tree Protocol. This
device is assumed to be deployed in a physical loop-free topology.

=item (0x04) - Performs level 2 source-route bridging. A source-route bridge
would set both this bit and bit 0x02.

=item (0x02) - Performs level 2 transparent bridging.

=item (0x01) - Performs level 3 routing for at least one network layer
protocol.

=back

Thanks to Martin Lorensen C<martin -at- lorensen.dk> for a pointer to this
information.

(C<cdpCacheCapabilities>)

=item $cdp->cdp_domain()

Returns remote VTP Management Domain as defined in
C<CISCO-VTP-MIB::managementDomainName>

(C<cdpCacheVTPMgmtDomain>)

=item $cdp->cdp_duplex() 

Returns the port duplex status from remote devices.

(C<cdpCacheDuplex>)

=item $cdp->cdp_id()

Returns remote device id string

(C<cdpCacheDeviceId>)

=item $cdp->cdp_if()

Returns the mapping to the SNMP Interface Table.

Note that a lot devices don't implement $cdp->cdp_index(),  So if it isn't
around, we fake it. 

In order to map the cdp table entry back to the interfaces() entry, we
truncate the last number off of it :

  # it exists, yay.
  my $cdp_index     = $device->cdp_index();
  return $cdp_index if defined $cdp_index;

  # if not, let's fake it
  my $cdp_ip       = $device->cdp_ip();
    
  my %cdp_if
  foreach my $key (keys %$cdp_ip){
      $iid = $key;
      ## Truncate off .1 from cdp response
      $iid =~ s/\.\d+$//;
      $cdp_if{$key} = $iid;
  }
 
  return \%cdp_if;


=item $cdp->cdp_index()

Returns the mapping to the SNMP2 Interface table for CDP Cache Entries. 

Most devices don't implement this, so you probably want to use $cdp->cdp_if()
instead.

See cdp_if() entry.

(C<cdpCacheIfIndex>)

=item  $cdp->cdp_ip()

If $cdp->cdp_proto() is supported, returns remote IPV4 address only.  Otherwise
it will return all addresses.

(C<cdpCacheAddress>)

=item  $cdp->cdp_addr()

Returns remote address

(C<cdpCacheAddress>)

=item $cdp->cdp_platform() 

Returns remote platform id 

(C<cdpCachePlatform>)

=item $cdp->cdp_port()

Returns remote port ID

(C<cdpDevicePort>)

=item  $cdp->cdp_proto()

Returns remote address type received.  Usually IP.

(C<cdpCacheAddressType>)

=item $cdp->cdp_ver() 

Returns remote hardware version

(C<cdpCacheVersion>)

=item $cdp->cdp_vlan()

Returns the remote interface native VLAN.

(C<cdpCacheNativeVLAN>)

=item $cdp->cdp_power()

Returns the amount of power consumed by remote device in milliwatts munged
for decimal placement.

(C<cdpCachePowerConsumption>)

=back

=head1 Data Munging Callback Subroutines

=over

=item $cdp->munge_power()

Inserts a decimal at the proper location.

=back

=cut
