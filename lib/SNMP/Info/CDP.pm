# SNMP::Info::CDP
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
use warnings;
use Exporter;
use SNMP::Info;

@SNMP::Info::CDP::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::CDP::EXPORT_OK = qw//;

our
    ($VERSION, $DEBUG, %FUNCS, %GLOBALS, %MIBS, %MUNGE, $INIT, %CDP_CAPABILITIES);

$VERSION = '3.70';

# Five data structures required by SNMP::Info
%MIBS = ( 'CISCO-CDP-MIB' => 'cdpGlobalRun' );

# Notice we dont inherit the default GLOBALS and FUNCS
# only the default MUNGE.
%GLOBALS = (
    'cdp_run'      => 'cdpGlobalRun',
    'cdp_interval' => 'cdpGlobalMessageInterval',
    'cdp_holdtime' => 'cdpGlobalHoldTime',
    'cdp_gid'      => 'cdpGlobalDeviceId',
);

%FUNCS = (
    'cdp_proto'        => 'cdpCacheAddressType',
    'cdp_addr'         => 'cdpCacheAddress',
    'cdp_ver'          => 'cdpCacheVersion',
    'cdp_dev_id'       => 'cdpCacheDeviceId',
    'cdp_dev_port'     => 'cdpCacheDevicePort',
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
    'cdp_capabilities' => \&SNMP::Info::munge_bits,
    'cdp_platform'     => \&SNMP::Info::munge_null,
    'cdp_domain'       => \&SNMP::Info::munge_null,
    'cdp_ver'          => \&SNMP::Info::munge_null,
    'cdp_ip'           => \&SNMP::Info::munge_ip,
    'cdp_power'        => \&munge_power,
);

%CDP_CAPABILITIES = (
    'Router'                  => 0x001,
    'Trans-Bridge'            => 0x002,
    'Source-Route-Bridge'     => 0x004,
    'Switch'                  => 0x008,
    'Host'                    => 0x010,
    'IGMP'                    => 0x020,
    'Repeater'                => 0x040,
    'VoIP-Phone'              => 0x080,
    'Remotely-Managed-Device' => 0x100,
    'Supports-STP-Dispute'    => 0x200,
    'Two-port Mac Relay'      => 0x400,
);

sub munge_power {
    my $power = shift;
    my $decimal = substr( $power, -3 );
    $power =~ s/$decimal$/\.$decimal/;
    return $power;
}

sub hasCDP {
    my $cdp = shift;

    # Check the global that is supposed to indicate CDP is running
    my $cdp_run = $cdp->cdp_run();
    return 1 if $cdp_run;

    # SNMP v1 clients don't have the globals, fallback
    # by checking if it would report neighbors
    my $cdp_ip = $cdp->cdp_ip() || {};
    return 1 if scalar keys %$cdp_ip;

    return;
}

sub cdp_if {
    my $cdp = shift;

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

sub cdp_cap {
    my $cdp     = shift;
    my $partial = shift;

    # Some devices return a hex-string, others return a space separated
    # string, we need the raw data to determine return value and
    # take appropriate action
    my $cdp_caps = $cdp->cdp_capabilities_raw($partial) || {};

    my %cdp_cap;
    foreach my $key ( keys %$cdp_caps ) {
        my $cap_raw = $cdp_caps->{$key};
        next unless $cap_raw;

        # Simple check, smallest single string is either Host or IGMP with a
        # space added on the end for a length of 5, hex string is normally
        # 4 bytes, but since only one byte was traditionally needed process
        # as hex for a length of 4 or less
        if ( length $cap_raw < 5 ) {
            my $cap_hex = join( '',
                map { sprintf "%x", $_ } unpack( 'C*', $cap_raw ) );
            foreach my $capability ( keys %CDP_CAPABILITIES ) {
                if ( ( hex $cap_hex ) & $CDP_CAPABILITIES{$capability} ) {
                    push( @{ $cdp_cap{$key} }, $capability );
                }
            }
        }
        else {
            my @caps = split /\s/, $cap_raw;
            push( @{ $cdp_cap{$key} }, @caps );
        }
    }
    return \%cdp_cap;
}

sub cdp_id {
    my $cdp    = shift;
    my $partial = shift;

    my $ch = $cdp->cdp_dev_id($partial) || {};

    my %cdp_id;
    foreach my $key ( sort keys %$ch ) {
        my $id = $ch->{$key};
        next unless $id;
        $id = SNMP::Info::munge_mac($id) || SNMP::Info::munge_null($id);
        $cdp_id{$key} = $id;
    }
    return \%cdp_id;
}

sub cdp_port {
    my $cdp    = shift;
    my $partial = shift;

    my $ch = $cdp->cdp_dev_port($partial) || {};

    # most devices return a string with the interface name here (Port-ID TLV)
    # see https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/cdp/command/cdp-cr-book/cdp-cr-a1.html
    # it seems however that some devices report hex encoded mac addresses for this, see
    # https://github.com/netdisco/snmp-info/issues/252
    # once these bad devices get known we can figure out workarounds for them

    my %cdp_port;
    foreach my $key ( sort keys %$ch ) {
        my $port = $ch->{$key};
        next unless $port;
        $port = SNMP::Info::munge_null($port);
        $cdp_port{$key} = $port;
    }
    return \%cdp_port;
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
 my $interfaces   = $cdp->interfaces();
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
also speak CDP, mostly switches and routers.  CDP is implemented by Cisco and
several other vendors.

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

=head1 GLOBALS

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
binary string, MSB.  Each digit represents a bit from the table below from
the CDP Capabilities Mapping to Smartport Type table within the
Cisco Small Business 200 Series Smart Switch Administration Guide,
L<http://www.cisco.com/c/en/us/support/switches/small-business-200-series-smart-switches/products-maintenance-guides-list.html>:

(Bit) - Description

=over

=item (0x400) - Two-Port MAC Relay.

=item (0x200) - CAST Phone Port / CVTA / Supports-STP-Dispute depending
                upon platform.

=item (0x100) - Remotely-Managed Device.

=item (0x80)  - VoIP Phone.

=item (0x40)  - Provides level 1 functionality.

=item (0x20)  - The bridge or switch does not forward IGMP Report packets on
non router ports.

=item (0x10)  - Sends and receives packets for at least one network layer
protocol. If the device is routing the protocol, this bit should not be set.

=item (0x08)  - Performs level 2 switching. The difference between this bit
and bit 0x02 is that a switch does not run the Spanning-Tree Protocol. This
device is assumed to be deployed in a physical loop-free topology.

=item (0x04)  - Performs level 2 source-route bridging. A source-route bridge
would set both this bit and bit 0x02.

=item (0x02)  - Performs level 2 transparent bridging.

=item (0x01)  - Performs level 3 routing for at least one network layer
protocol.

=back

Thanks to Martin Lorensen for a pointer to the original information and
CPAN user Alex for updates.

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

Returns remote Port-ID. Most of the time this is a string with the port name, but this
is not guaranteed to be so.

(C<cdpCacheDevicePort>)

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

=item  $cdp->cdp_cap()

Returns hash of arrays with each array containing the system capabilities
supported by the remote system.  Possible elements in the array are
C<Router>, C<Trans-Bridge>, C<Source-Route-Bridge>, C<Switch>, C<Host>,
C<IGMP>, C<Repeater>, C<VoIP-Phone>, C<Remotely-Managed-Device>,
C<Supports-STP-Dispute>, and C<Two-port Mac Relay>.

=back

=head1 Data Munging Callback Subroutines

=over

=item $cdp->munge_power()

Inserts a decimal at the proper location.

=back

=cut
