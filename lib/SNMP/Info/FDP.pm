# SNMP::Info::FDP
#
# Copyright (c) 2008 Bruce Rodger, Max Baker
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

package SNMP::Info::FDP;

use strict;
use warnings;
use Exporter;
use SNMP::Info;

@SNMP::Info::FDP::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::FDP::EXPORT_OK = qw//;

our ($VERSION, %FUNCS, %GLOBALS, %MIBS, %MUNGE);

$VERSION = '3.70';

%MIBS = ( 'FOUNDRY-SN-SWITCH-GROUP-MIB' => 'snFdpGlobalRun' );

%GLOBALS = (
    'fdp_run'      => 'snFdpGlobalRun',
    'fdp_interval' => 'snFdpGlobalMessageInterval',
    'fdp_holdtime' => 'snFdpGlobalHoldTime',
);

%FUNCS = (
    'fdp_proto'        => 'snFdpCacheAddressType',
    'fdp_ip'           => 'snFdpCacheAddress',
    'fdp_ver'          => 'snFdpCacheVersion',
    'fdp_id'           => 'snFdpCacheDeviceId',
    'fdp_port'         => 'snFdpCacheDevicePort',
    'fdp_platform'     => 'snFdpCachePlatform',
    'fdp_capabilities' => 'snFdpCacheCapabilities',
    'fdp_cache_type'   => 'snFdpCacheVendorId',
);

%MUNGE = (
    'fdp_capabilities' => \&SNMP::Info::munge_bits,
    'fdp_ip'           => \&SNMP::Info::munge_ip,
);

sub fdp_run {
    my $fdp     = shift;
    my $fdp_run = $fdp->orig_fdp_run();

    # if fdp_run isn't implemented on device, assume FDP is on
    return $fdp_run if defined $fdp_run;
    return 1;
}

sub hasFDP {
    my $fdp = shift;

    my $ver = $fdp->snmp_ver();

    # SNMP v1 clients dont have the globals
    if ( defined $ver and $ver == 1 ) {
        my $fdp_ip = $fdp->fdp_ip();

        # See if anything in fdp cache, if so we have fdp
        return 1 if ( defined $fdp_ip and scalar( keys %$fdp_ip ) );
        return;
    }

    return $fdp->fdp_run();
}

sub fdp_if {
    my $fdp = shift;

    my $fdp_ip = $fdp->fdp_ip();
    unless ( defined $fdp_ip ) {
        $fdp->error_throw(
            "SNMP::Info::FDP:fdp_if() - Device doesn't have fdp_ip() data.  Can't fake fdp_index()"
        );
        return;
    }

    my %fdp_if;
    foreach my $key ( keys %$fdp_ip ) {
        next unless defined $key;
        my $iid = $key;

        # Truncate .1 from fdp cache entry
        $iid =~ s/\.\d+$//;
        $fdp_if{$key} = $iid;
    }

    return \%fdp_if;
}

1;
__END__

=head1 NAME

SNMP::Info::FDP - SNMP Interface to Foundry Discovery Protocol (FDP) using
SNMP

=head1 AUTHOR

Bruce Rodger, Max Baker

=head1 SYNOPSIS

 my $fdp = new SNMP::Info (
                             AutoSpecify => 1,
                             Debug       => 1,
                             DestHost    => 'router',
                             Community   => 'public',
                             Version     => 2
                           );

 my $class = $fdp->class();
 print " Using device sub class : $class\n";

 $hasfdp   = $fdp->hasFDP() ? 'yes' : 'no';

 # Print out a map of device ports with FDP neighbors:
 my $interfaces   = $fdp->interfaces();
 my $fdp_if       = $fdp->fdp_if();
 my $fdp_ip       = $fdp->fdp_ip();
 my $fdp_port     = $fdp->fdp_port();

 foreach my $fdp_key (keys %$fdp_ip){
    my $iid           = $fdp_if->{$fdp_key};
    my $port          = $interfaces->{$iid};
    my $neighbor      = $fdp_ip->{$fdp_key};
    my $neighbor_port = $fdp_port->{$fdp_key};
    print "Port : $port connected to $neighbor / $neighbor_port\n";
 }

=head1 DESCRIPTION

SNMP::Info::FDP is a subclass of SNMP::Info that provides an object oriented
interface to FDP information through SNMP.

FDP is a Layer 2 protocol that supplies topology information of
devices that also speak FDP, mostly switches and routers.  It has
similar functionality to Cisco's CDP, and the SNMP interface is
virtually identical.  FDP is implemented in Brocade (Foundry) devices.

Create or use a device subclass that inherits this class.  Do not use
directly.

Each device implements a subset of the global and cache entries.
Check the return value to see if that data is held by the device.

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item F<FOUNDRY-SN-SWITCH-GROUP-MIB>

Needs a reasonably recent MIB. Works OK with B2R07604A.mib, but doesn't
work with B2R07600C.

=back

=head1 GLOBALS

These are methods that return scalar values from SNMP

=over

=item  $fdp->hasFDP()

Is FDP is active in this device?

Accounts for SNMP version 1 devices which may have FDP but not fdp_run()

=item $fdp->fdp_run()

Is FDP enabled on this device?

(C<fdpGlobalRun>)

=item $fdp->fdp_interval()

Interval in seconds at which FDP messages are generated.

(C<fdpGlobalMessageInterval>)

=item $fdp->fdp_holdtime()

Time in seconds that FDP messages are kept.

(C<fdpGlobalHoldTime>)

=back

=head2 Overrides

CDP compatibility

=over

=item $fdp->fdp_interval()

Interval in seconds at which FDP messages are generated.

(C<fdpGlobalMessageInterval>)

=item $fdp->fdp_holdtime()

Time in seconds that FDP messages are kept.

(C<fdpGlobalHoldTime>)

=item  $fdp->fdp_id()

Returns FDP device ID.

This is the device id broadcast via FDP to other devices, and is what is
retrieved from remote devices with $fdp->id().

(C<fdpGlobalDeviceId>)

=item $fdp->fdp_run()

Is FDP enabled on this device?

=back

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

CDP compatibility

=over

=item $fdp->fdp_capabilities()

Returns Device Functional Capabilities.  Results are munged into an ascii
binary string, MSB.  Each digit represents a bit from the table below.

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

Thanks to Martin Lorensen for a pointer to this information.

(C<fdpCacheCapabilities>)

=item $fdp->fdp_id()

Returns remote device id string

(C<fdpCacheDeviceId>)

=item $fdp->fdp_if()

Returns the mapping to the SNMP Interface Table.

In order to map the fdp table entry back to the interfaces() entry, we
truncate the last number off of it :

  my $fdp_ip       = $device->fdp_ip();

  my %fdp_if
  foreach my $key (keys %$fdp_ip){
      $iid = $key;
      ## Truncate off .1 from fdp response
      $iid =~ s/\.\d+$//;
      $fdp_if{$key} = $iid;
  }

  return \%fdp_if;

=item  $fdp->fdp_ip()

Returns remote IP address

(C<fdpCacheAddress>)

=item $fdp->fdp_platform()

Returns remote platform id

(C<fdpCachePlatform>)

=item $fdp->fdp_port()

Returns remote port ID

(C<fdpDevicePort>)

=item  $fdp->fdp_proto()

Returns remote address type received.  Usually IP.

(C<fdpCacheAddressType>)

=item $fdp->fdp_ver()

Returns remote hardware version

(C<fdpCacheVersion>)

=item $fdp->fdp_cache_type()

Returns type of entry received, either FDP or CDP.

(C<snFdpCacheVendorId>)

=back

=cut
