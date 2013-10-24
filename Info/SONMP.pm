# SNMP::Info::SONMP
#
# Copyright (c) 2012 Eric Miller
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

package SNMP::Info::SONMP;

use warnings;
use strict;
use Exporter;
use SNMP::Info;

@SNMP::Info::SONMP::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::SONMP::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE/;

$VERSION = '3.08';

%MIBS = (
    'SYNOPTICS-ROOT-MIB'           => 'synoptics',
    'S5-ETH-MULTISEG-TOPOLOGY-MIB' => 's5EnMsTop',
);

%GLOBALS = (
    'sonmp_gid' => 's5EnMsTopIpAddr',
    'sonmp_run' => 's5EnMsTopStatus',
);

%FUNCS = (

    # From S5-ETH-MULTISEG-TOPOLOGY-MIB::TopNmmTable
    'sonmp_topo_slot'     => 's5EnMsTopNmmSlot',
    'sonmp_topo_port'     => 's5EnMsTopNmmPort',
    'sonmp_topo_ip'       => 's5EnMsTopNmmIpAddr',
    'sonmp_topo_seg'      => 's5EnMsTopNmmSegId',
    'sonmp_topo_mac'      => 's5EnMsTopNmmMacAddr',
    'sonmp_topo_platform' => 's5EnMsTopNmmChassisType',
    'sonmp_topo_localseg' => 's5EnMsTopNmmLocalSeg',
);

%MUNGE = ( 'sonmp_topo_mac' => \&SNMP::Info::munge_mac );

sub index_factor {
    return 32;
}

sub slot_offset {
    return 1;
}

sub port_offset {
    return 0;
}

sub hasSONMP {
    my $sonmp = shift;

    return 1 if defined $sonmp->sonmp_run();
    return;
}

sub sonmp_if {
    my $sonmp   = shift;
    my $partial = shift;

    my $sonmp_topo_port = $sonmp->sonmp_topo_port($partial) || {};
    my $sonmp_topo_slot = $sonmp->sonmp_topo_slot($partial) || {};
    my $index_factor    = $sonmp->index_factor();
    my $slot_offset     = $sonmp->slot_offset();
    my $port_offset     = $sonmp->port_offset();
    my $model           = $sonmp->model();

    my %sonmp_if;
    foreach my $entry ( keys %$sonmp_topo_port ) {
        my $port = $sonmp_topo_port->{$entry};
        next unless defined $port;
        next if $port == 0;
        my $slot = $sonmp_topo_slot->{$entry} || 0;

        if ( $model eq 'Baystack Hub' ) {
            my $comidx = $slot;
            if ( !( $comidx % 5 ) ) {
                $slot = ( $slot / 5 );
            }
            elsif ( $comidx =~ /[16]$/ ) {
                $slot = int( $slot / 5 );
                $port = 25;
            }
            elsif ( $comidx =~ /[27]$/ ) {
                $slot = int( $slot / 5 );
                $port = 26;
            }
        }

        my $index = ( ( $slot - $slot_offset ) * $index_factor )
            + ( $port - $port_offset );

        $sonmp_if{$entry} = $index;
    }
    return \%sonmp_if;
}

sub sonmp_ip {
    my $sonmp   = shift;
    my $partial = shift;

    my $sonmp_topo_port = $sonmp->sonmp_topo_port($partial) || {};
    my $sonmp_topo_ip   = $sonmp->sonmp_topo_ip($partial)   || {};

    my %sonmp_ip;
    foreach my $entry ( keys %$sonmp_topo_ip ) {
        my $port = $sonmp_topo_port->{$entry};
        next unless defined $port;
        next if $port == 0;

        my $ip = $sonmp_topo_ip->{$entry};
        $sonmp_ip{$entry} = $ip;
    }
    return \%sonmp_ip;
}

sub sonmp_port {
    my $sonmp   = shift;
    my $partial = shift;

    my $sonmp_topo_port     = $sonmp->sonmp_topo_port($partial)     || {};
    my $sonmp_topo_seg      = $sonmp->sonmp_topo_seg($partial)      || {};
    my $sonmp_topo_platform = $sonmp->sonmp_topo_platform($partial) || {};

    my %sonmp_port;
    foreach my $entry ( keys %$sonmp_topo_seg ) {
        my $port = $sonmp_topo_port->{$entry};
        next unless defined $port;
        next if $port == 0;

        my $seg      = $sonmp_topo_seg->{$entry};
        my $platform = $sonmp_topo_platform->{$entry};

        # AP-222x Series does not adhere to port numbering
        if ( $platform =~ /AccessPoint/i ) {
            $sonmp_port{$entry} = 'dp0';
        }

        # BayHubs send the lower three bytes of the MAC not the slot/port
        elsif ( $seg > 4000 ) {
            $sonmp_port{$entry} = 'unknown';
        }
        else {

            # Segment id is (256 * remote slot_num) + (remote_port)
            my $remote_port = $seg % 256;
            my $remote_slot = int( $seg / 256 );

            $sonmp_port{$entry} = "$remote_slot.$remote_port";
        }
    }
    return \%sonmp_port;
}

sub sonmp_platform {
    my $sonmp   = shift;
    my $partial = shift;

    my $sonmp_topo_port     = $sonmp->sonmp_topo_port($partial)     || {};
    my $sonmp_topo_platform = $sonmp->sonmp_topo_platform($partial) || {};

    my %sonmp_platform;
    foreach my $entry ( keys %$sonmp_topo_platform ) {
        my $port = $sonmp_topo_port->{$entry};
        next unless defined $port;
        next if $port == 0;

        my $platform = $sonmp_topo_platform->{$entry};

        $sonmp_platform{$entry} = $platform;
    }
    return \%sonmp_platform;
}

sub mac {
    my $sonmp = shift;

    my $sonmp_topo_port = $sonmp->sonmp_topo_port();
    my $sonmp_topo_mac  = $sonmp->sonmp_topo_mac();

    foreach my $entry ( keys %$sonmp_topo_port ) {
        my $port = $sonmp_topo_port->{$entry};
        next unless $port == 0;
        my $mac = $sonmp_topo_mac->{$entry};
        return $mac;
    }

    # Topology turned off, not supported.
    return;
}

1;
__END__

=head1 NAME

SNMP::Info::SONMP - SNMP Interface to SynOptics Network Management Protocol
(SONMP)

=head1 AUTHOR

Eric Miller

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

 $hassonmp   = $sonmp->hasSONMP() ? 'yes' : 'no';

 # Print out a map of device ports with CDP neighbors:
 my $interfaces = $sonmp->interfaces();
 my $sonmp_if       = $sonmp->sonmp_if();
 my $sonmp_ip       = $sonmp->sonmp_ip();
 my $sonmp_port     = $sonmp->sonmp_port();

 foreach my $sonmp_key (keys %$sonmp_ip){
    my $iid           = $sonmp_if->{$sonmp_key};
    my $port          = $interfaces->{$iid};
    my $neighbor      = $sonmp_ip->{$sonmp_key};
    my $neighbor_port = $sonmp_port->{$sonmp_key};
    print "Port : $port connected to $neighbor / $neighbor_port\n";
 }

=head1 DESCRIPTION

SNMP::Info::SONMP is a subclass of SNMP::Info that provides an object oriented 
interface to the SynOptics Network Management Protocol (SONMP) information
through SNMP.

SONMP is a Layer 2 protocol that supplies topology information of devices that
also speak SONMP, mostly switches and hubs.  SONMP is implemented in
SynOptics, Bay, Nortel, and Avaya devices.  SONMP has been rebranded by Bay
then Nortel and may be referred to by several different names, including Nortel
Discovery Protocol (NDP).

Create or use a device subclass that inherits this class.  Do not use
directly.

Each device implements a subset of the global and cache entries. 
Check the return value to see if that data is held by the device.

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item F<SYNOPTICS-ROOT-MIB>

=item F<S5-ETH-MULTISEG-TOPOLOGY-MIB>

=back

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

=item  $sonmp->hasSONMP()

Is SONMP is active in this device?

=item $sonmp->sonmp_gid()

Returns the IP that the device is sending out for its Nmm topology info.

(C<s5EnMsTopIpAddr>)

=item $sonmp->sonmp_run()

Returns true if SONMP is on for this device. 

(C<s5EnMsTopStatus>)

=item $sonmp->mac()

Returns MAC of the advertised IP address of the device. 

=back

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Layer2 Topology info (C<s5EnMsTopNmmTable>)

=over

=item $sonmp->sonmp_topo_slot()

Returns reference to hash.  Key: Table entry, Value:slot number

(C<s5EnMsTopNmmSlot>)

=item $sonmp->sonmp_topo_port()

Returns reference to hash.  Key: Table entry, Value:Port Number
(interface iid)

(C<s5EnMsTopNmmPort>)

=item $sonmp->sonmp_topo_ip()

Returns reference to hash.  Key: Table entry, Value:Remote IP address of entry

(C<s5EnMsTopNmmIpAddr>)

=item $sonmp->sonmp_topo_seg()

Returns reference to hash.  Key: Table entry, Value:Remote Segment ID

(C<s5EnMsTopNmmSegId>)

=item $sonmp->sonmp_topo_mac()

(C<s5EnMsTopNmmMacAddr>)

Returns reference to hash.  Key: Table entry, Value:Remote MAC address

=item $sonmp->sonmp_topo_platform

Returns reference to hash.  Key: Table entry, Value:Remote Device Type

(C<s5EnMsTopNmmChassisType>)

=item $sonmp->sonmp_topo_localseg

Returns reference to hash.  Key: Table entry, Value: Boolean, if
bay_topo_seg() is local.

(C<s5EnMsTopNmmLocalSeg>)

=back

=head2 Common topology information

All entries with port=0 are local and ignored.

=over

=item $sonmp->sonmp_if()

Returns reference to hash.  Key: IID, Value: Local port (interfaces)

=item $sonmp->sonmp_ip()

Returns reference to hash.  Key: IID, Value: Remote IP address

If multiple entries exist with the same local port, sonmp_if(), with different
IPv4 addresses, sonmp_ip(), there is either a non SONMP device in between two or
more devices or multiple devices which are not directly connected.  

Use the data from the Layer2 Topology Table below to dig deeper.

=item $sonmp->sonmp_port()

Returns reference to hash. Key: IID, Value: Remote port (interfaces)

=item $sonmp->sonmp_platform()

Returns reference to hash. Key: IID, Value: Remote device type

=back

=cut
