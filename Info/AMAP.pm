# SNMP::Info::AMAP
#
# Copyright (c) 2013 Eric Miller
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

package SNMP::Info::AMAP;

use strict;
use Exporter;
use SNMP::Info;

@SNMP::Info::LLDP::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::LLDP::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE/;

$VERSION = '3.06_001';

%MIBS
    = ( 'ALCATEL-IND1-INTERSWITCH-PROTOCOL-MIB' => 'aipAMAPRemDeviceType', );

%GLOBALS = (

);

%FUNCS = (

    # EXTREME-EDP-MIB::extremeEdpTable
    'amap_rem_sysname' => 'aipAMAPRemHostname',
);

%MUNGE = ( 'amap_rem_sysname' => \&SNMP::Info::munge_null, );

sub hasAMAP {
    my $amap = shift;

    my $amap_ip = $amap->aipAMAPIpAddr() || {};

    return 1 if ( scalar( keys %$amap_ip ) );

    return;
}

# Break up the aipAMAPhostsTable INDEX into MAC and IP address.
sub _hosts_table_index {
    my $idx  = shift;
    my @oids = split( /\./, $idx );
    my $mac  = join( '.', splice( @oids, 0, 6 ) );

    return ( $mac, join( '.', @oids ) );
}

# Break up the aipAMAPportConnectionTable INDEX and return MAC
sub _conn_table_mac {
    my $idx       = shift;
    my @oids      = split( /\./, $idx );
    my $local_idx = shift @oids;
    my $mac       = join( '.', splice( @oids, 0, 6 ) );

    return ($mac);
}

# Since we need to get IP Addresses from the aipAMAPhostsTable which has
# a different index (MAC, IP) than the aipAMAPportConnectionTable which holds
# the remote device details we create a combined index and skip any
# IPs which have an address of 0.0.0.0.  Would like to include only one
# address since they should all originate from the same device, but we don't
# know if they would all be reachable from the network management application.
#
# We don't inplement partials since this is private index function
sub _amap_index {
    my $amap = shift;

    my $amap_ip    = $amap->aipAMAPIpAddr()    || {};
    my $amap_rport = $amap->aipAMAPLocalPort() || {};

    my %amap_index;
    foreach my $key ( keys %$amap_ip ) {
        my ( $mac, $ip ) = _hosts_table_index($key);

        next if ( $ip eq '0.0.0.0' );
        next unless $ip;

        foreach my $idx ( keys %$amap_rport ) {
            my $c_mac = _conn_table_mac($idx);

            if ( $mac eq $c_mac ) {
                my $index = "$idx.$ip";
                $amap_index{$index} = $index;
            }
        }
    }
    return \%amap_index;
}

# Break up _amap_index INDEX into local index, MAC, remote index, and
# IP address
sub _amap_index_parts {
    my $idx       = shift;
    my @oids      = split( /\./, $idx );
    my $local_idx = shift @oids;
    my $mac       = join( '.', splice( @oids, 0, 6 ) );
    my $rem_idx   = shift @oids;

    return ( $local_idx, $mac, $rem_idx, join( '.', @oids ) );
}

sub amap_if {
    my $amap = shift;

    my $index  = $amap->_amap_index()         || {};
    my $if_idx = $amap->aipAMAPLocalIfindex() || {};

    my %amap_if;
    foreach my $key ( keys %$index ) {
        my ( $local_idx, $mac, $rem_idx, $ip ) = _amap_index_parts($key);
        my $if_key = "$local_idx.$mac.$rem_idx";

        if ( $key =~ /^$if_key/ ) {
            my $if = $if_idx->{$if_key};
            $amap_if{$key} = $if;
        }
    }

    return \%amap_if;
}

sub amap_ip {
    my $amap = shift;

    my $index = $amap->_amap_index() || {};

    my %amap_ip;
    foreach my $key ( keys %$index ) {
        my ( $local_idx, $mac, $rem_idx, $ip ) = _amap_index_parts($key);

        # MIB says should only be IPv4
        next unless ( $ip =~ /\d+(\.\d+){3}/ );
        $amap_ip{$key} = $ip;
    }
    return \%amap_ip;
}

sub amap_port {
    my $amap = shift;

    my $index      = $amap->_amap_index()      || {};
    my $amap_rport = $amap->aipAMAPLocalPort() || {};
    my $amap_rslot = $amap->aipAMAPLocalSlot() || {};

    my %amap_port;
    foreach my $key ( sort keys %$index ) {
        my ( $local_idx, $mac, $rem_idx, $ip ) = _amap_index_parts($key);
        my $p_key = "$local_idx.$mac.$rem_idx";

        if ( $key =~ /^$p_key/ ) {
            my $port = $amap_rport->{$p_key};
            my $slot = $amap_rslot->{$p_key} || 0;
            next unless $port;
            $amap_port{$key} = defined $slot ? "$slot\/$port" : $port;
        }
    }
    return \%amap_port;
}

sub amap_id {
    my $amap = shift;

    my $index     = $amap->_amap_index()      || {};
    my $amap_name = $amap->amap_rem_sysname() || {};

    my %amap_name;
    foreach my $key ( sort keys %$index ) {
        my ( $local_idx, $mac, $rem_idx, $ip ) = _amap_index_parts($key);
        my $id_key = "$local_idx.$mac.$rem_idx";

        if ( $key =~ /^$id_key/ ) {
            my $name = $amap_name->{$id_key} || 0;
            next unless $name;
            $amap_name{$key} = $name;
        }
    }
    return \%amap_name;
}

sub amap_platform {
    my $amap = shift;

    my $index              = $amap->_amap_index()          || {};
    my $amap_topo_platform = $amap->aipAMAPRemDeviceType() || {};

    my %amap_platform;
    foreach my $key ( keys %$index ) {
        my ( $local_idx, $mac, $rem_idx, $ip ) = _amap_index_parts($key);
        my $pf_key = "$local_idx.$mac.$rem_idx";

        if ( $key =~ /^$pf_key/ ) {
            my $platform = $amap_topo_platform->{$pf_key};
            next unless $platform;
            $amap_platform{$key} = $platform;
        }
    }
    return \%amap_platform;
}

1;
__END__

=head1 NAME

SNMP::Info::AMAP - SNMP Interface to Alcatel Mapping Adjacency Protocol (AMAP)

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 my $amap = new SNMP::Info ( 
                             AutoSpecify => 1,
                             Debug       => 1,
                             DestHost    => 'router', 
                             Community   => 'public',
                             Version     => 2
                           );

 my $class = $amap->class();
 print " Using device sub class : $class\n";

 $hasamap   = $amap->hasAMAP() ? 'yes' : 'no';

 # Print out a map of device ports with LLDP neighbors:
 my $interfaces    = $amap->interfaces();
 my $amap_if       = $amap->amap_if();
 my $amap_ip       = $amap->amap_ip();
 my $amap_port     = $amap->amap_port();

 foreach my $amap_key (keys %$amap_ip){
    my $iid           = $amap_if->{$amap_key};
    my $port          = $interfaces->{$iid};
    my $neighbor      = $amap_ip->{$amap_key};
    my $neighbor_port = $amap_port->{$amap_key};
    print "Port : $port connected to $neighbor / $neighbor_port\n";
 }

=head1 DESCRIPTION

SNMP::Info::AMAP is a subclass of SNMP::Info that provides an object oriented 
interface to Alcatel Mapping Adjacency Protocol (AMAP) information through
SNMP.

AMAP is a Layer 2 protocol that allows a network device to advertise its
identity and capabilities on the local network providing topology information.

Create or use a device subclass that inherits this class.  Do not use
directly.

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item F<ALCATEL-IND1-INTERSWITCH-PROTOCOL-MIB>

=back

=head1 GLOBAL METHODS

These are methods that return scalar values from SNMP

=over

=item $amap->hasAMAP()

Is AMAP is active in this device?  

=back

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $amap->amap_id()

Returns the string value used to identify the remote system.

=item $amap->amap_if()

Returns the mapping to the SNMP Interface Table.

=item  $amap->amap_ip()

Returns remote IPv4 addresses.  Note: AMAP returns all IP addresses associated
with the remote device.  It would be preferable to include only one address
since they should all originate from the same device, but amap_ip() can not 
determine if all addresses are reachable from the network management
application therefore all addresses are returned and the calling application
must determine which address to use and if they are in fact from the same
device.

=item $amap->amap_port()

Returns remote port ID

=item $amap->amap_platform()

Returns remote platform ID

=back

=cut
