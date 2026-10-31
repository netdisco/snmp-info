# SNMP::Info::RapidCityVRF
#
# Copyright (c) 2026 The SNMP::Info Developers
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

package SNMP::Info::RapidCityVRF;

use strict;
use warnings;
use Exporter;
use SNMP::Info;

@SNMP::Info::RapidCityVRF::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::RapidCityVRF::EXPORT_OK = qw//;

our ($VERSION, %FUNCS, %GLOBALS, %MIBS, %MUNGE);

$VERSION = '3.984000';

%MIBS = ( 'RAPID-CITY' => 'rapidCity' );

%GLOBALS = ();

%FUNCS = (
    # RAPID-CITY::rcVrfConfigTable
    'vrf_rc_name'    => 'rcVrfName',
    'vrf_rc_context' => 'rcVrfContextName',
    # RAPID-CITY::rcVrfIpVpnTable
    'vrf_rc_isid' => 'rcVrfIpVpnIsidNumber',
    # RAPID-CITY::rcVlanTable. RapidCity.pm reads rcVlanIfIndex and
    # rcIpAdEntAddr too, as rc_vlan_if and rc_ip_addr.
    'vrf_rc_vlan_if'  => 'rcVlanIfIndex',
    'vrf_rc_vlan_vrf' => 'rcVlanVrfId',
    # RAPID-CITY::rcIpAddrTable
    'vrf_rc_ip_vrf'  => 'rcIpAdEntVrfId',
    'vrf_rc_ip_addr' => 'rcIpAdEntAddr',
    'vrf_rc_ip_mask' => 'rcIpAdEntNetMask',
);

%MUNGE = ();

# Each VOSS VRF is the context its rcVrfContextName names.
sub _context_kinds {
    my ( $vrf, $feature ) = @_;

    return unless ( $feature // '' ) eq 'vrf';
    return ['vrf'];
}

sub _snmp_context {
    my ( $vrf, $kind, $id ) = @_;

    return unless ( $kind // '' ) eq 'vrf';
    return if !defined $id or $id eq q() or $id eq 'default';
    return $vrf->_voss_snmp_context($id);
}

# VOSS reads a v2c community of the form community::vrfid in that VRF's
# context. vrfid 0, GlobalRouter, is the default context.
sub _voss_snmp_context {
    my ( $vrf, $id ) = @_;

    my $names    = $vrf->vrf_rc_name()    || {};
    my $contexts = $vrf->vrf_rc_context() || {};
    my ($vrfid)  = grep { $_ ne '0' and ( $names->{$_} // q() ) eq $id }
        sort keys %$names;
    return unless defined $vrfid;
    my $context = SNMP::Info::VRF::_vrf_text( $contexts->{$vrfid} );
    return unless defined $context;
    return {
        kind => 'vrf',
        id   => $id,
        v2c  => "%s::$vrfid",
        v3   => $context
    };
}

# VOSS serves a community with an @ suffix from the default context, so the
# suffix never names the session's context.
sub _vrf_community_suffix_is_context { return 0; }

# The context a VOSS VRF context's own rcVrfConfigTable row names. A VRF
# context serves only its own row; the default context serves every row,
# vrfid 0 (GlobalRouter, context '') among them. '' is the default context.
# Undef over SNMPv3 (its Context decides) or when the table is not served.
# A VRF context whose one row names no context reads as "vrfid N", a context
# no instance has, so the readers refuse it instead of reading it as the
# default.
sub _vrf_community_context {
    my $vrf = shift;

    my $version = ( $vrf->session() || {} )->{Version};
    return if defined $version and $version eq '3';

    my $contexts = $vrf->vrf_rc_context();
    return unless $contexts and %$contexts;
    my @vrfids = sort keys %$contexts;
    return q() if @vrfids > 1 or grep { $_ eq '0' } @vrfids;
    my $context = SNMP::Info::VRF::_vrf_text( $contexts->{ $vrfids[0] } );
    return $context if defined $context and length $context;
    return "vrfid $vrfids[0]";
}

# Each VOSS VRF context serves only its own VLANs, addresses, routes and
# neighbors; the default context maps every VRF's VLANs.
sub _vrf_context_filters           { return 1; }
sub _vrf_context_ports_from_routes { return 1; }
sub _vrf_subnets_from_routes       { return 1; }
sub _vrf_default_context_members   { return 1; }

# rcVrfConfigTable is indexed by vrfid. vrfid 0, GlobalRouter, is the
# instance default, which any row lists; the I-SID of an IP VPN is its
# layer 3 I-SID.
sub _vrf_vendor_instances {
    my $vrf = shift;

    my $names = $vrf->vrf_rc_name() || {};
    my $isids = $vrf->vrf_rc_isid() || {};
    my %instances;
    foreach my $vrfid ( keys %$names ) {
        my $name = SNMP::Info::VRF::_vrf_text( $names->{$vrfid} );
        next if !defined $name or $vrfid eq '0' or $name eq 'default';

        my $record = SNMP::Info::VRF::_vrf_record( $name, 'vrf', 'device' );
        my $isid   = $isids->{$vrfid};
        $record->{l3_isid}       = $isid + 0 if defined $isid and $isid > 0;
        $record->{sources}{list} = 'RAPID-CITY';
        $record->{sources}{l3_isid} = 'RAPID-CITY'
            if defined $record->{l3_isid};
        $instances{$name} = $record;
    }
    $vrf->_vrf_list_default( \%instances, 'RAPID-CITY' ) if %$names;
    return \%instances;
}

sub _vrf_vendor_list_methods {
    return qw/vrf_rc_name vrf_rc_context vrf_rc_isid vrf_rc_vlan_if
        vrf_rc_vlan_vrf vrf_rc_ip_vrf/;
}

# { ifIndex => name } of the VRFs other than default
sub _vrf_vendor_membership {
    my $vrf = shift;

    my $ports = $vrf->_voss_ports();
    return {
        map  { $_ => $ports->{$_} }
        grep { $ports->{$_} ne 'default' } keys %$ports
    };
}

# { ifIndex => name } from rcVlanTable, each VLAN's interface in the VRF
# rcVlanVrfId gives it, and from rcIpAddrTable, indexed ifIndex then
# address, for an interface with no VLAN. vrfid 0 is default. A read of
# $name records the walks.
sub _voss_ports {
    my ( $vrf, $name ) = @_;

    my $names    = $vrf->_voss_column( 'vrf_rc_name',     $name );
    my $vlan_ifs = $vrf->_voss_column( 'vrf_rc_vlan_if',  $name );
    my $vlan_ids = $vrf->_voss_column( 'vrf_rc_vlan_vrf', $name );
    my $ip_ids   = $vrf->_voss_column( 'vrf_rc_ip_vrf',   $name );

    my %ports;
    foreach my $iid ( keys %$ip_ids ) {
        my ($ifindex) = $iid =~ /^(\d+)\./ or next;
        my $vrf_name = _voss_vrf_name( $names, $ip_ids->{$iid} );
        $ports{$ifindex} = $vrf_name if defined $vrf_name;
    }
    foreach my $vlan ( keys %$vlan_ids ) {
        my $vrf_name = _voss_vrf_name( $names, $vlan_ids->{$vlan} );
        $ports{ $vlan_ifs->{$vlan} } = $vrf_name
            if defined $vrf_name and defined $vlan_ifs->{$vlan};
    }
    return \%ports;
}

# A walk that counts toward the read of $name, or a plain one without
sub _voss_column {
    my ( $vrf, $method, $name ) = @_;

    return $vrf->_vrf_column( $method, $name ) if defined $name;
    return $vrf->$method() || {};
}

sub _voss_vrf_name {
    my ( $names, $vrfid ) = @_;

    return unless defined $vrfid;
    return 'default' if $vrfid eq '0';
    return SNMP::Info::VRF::_vrf_text( $names->{$vrfid} );
}

# VOSS: the ports this context's rcVlanTable and rcIpAddrTable give the VRF,
# the interfaces of its connected routes, and those of the ipAddrTable
# addresses a connected route names as its next hop. A route learned over
# the fabric sits on the fabric VLAN's interface, which is no port of the
# VRF.
sub _vrf_route_ports {
    my ( $vrf, $name ) = @_;

    my $mapped = $vrf->_voss_ports($name);
    my %ports  = map { $_ => $name } grep { $mapped->{$_} eq $name }
        keys %$mapped;
    my $ifs    = $vrf->_vrf_column( 'vrf_cidr_if',    $name );
    my $protos = $vrf->_vrf_column( 'vrf_cidr_proto', $name );
    foreach my $iid ( keys %$protos ) {
        next unless SNMP::Info::VRF::_vrf_connected_proto( $protos->{$iid} );
        my $ifindex = SNMP::Info::VRF::_vrf_route_ifindex( $ifs->{$iid} );
        $ports{$ifindex} = $name if defined $ifindex;
    }
    $ports{$_} = $name for $vrf->_voss_next_hop_ports($name);
    return \%ports;
}

# The default context's ipAddrTable places the management CLIP's address
# on the CLIP's ifIndex, while its local host route sits on the management
# VLAN's interface: the route's next hop is the address, so the CLIP is a
# port of the context. Other VRFs' addresses there have no such route.
sub _voss_next_hop_ports {
    my ( $vrf, $name ) = @_;

    my %hops = map { join( q{.}, @{ $_->{hop} } ) => 1 }
        grep { $_->{family} eq 'ipv4' }
        @{ $vrf->_voss_connected_routes($name) };
    my $rows = $vrf->_vrf_ipadent_rows($name);
    return map { $_->{ifindex} }
        grep { !SNMP::Info::VRF::_vrf_unspecified( $_->{ip} ) }
        grep { $hops{ $_->{ip} } } values %$rows;
}

# VOSS indexes inetCidrRouteTable with no length octet before either
# address: type, destination, prefix length, policy 0, next hop type, next
# hop. Gives { family, dest, len, hop }, the addresses as octet lists, or
# nothing for another shape.
my %VOSS_INET = ( 1 => [ ipv4 => 4 ], 2 => [ ipv6 => 16 ] );

sub _voss_route_index {
    my $iid = shift;

    return unless defined $iid and $iid =~ /^\d+(?:\.\d+)*$/;
    my ( $type, @arcs ) = split /\./, $iid;
    my ( $family, $bytes ) = @{ $VOSS_INET{$type} || [] } or return;
    return if @arcs < $bytes + 3;
    my @dest = splice @arcs, 0, $bytes;
    my ( $length, $policy, $hop_type ) = splice @arcs, 0, 3;
    my ( undef, $hop_bytes ) = @{ $VOSS_INET{$hop_type} || [] } or return;
    return if $policy ne '0' or @arcs != $hop_bytes or $length > $bytes * 8;
    return if grep { $_ > 255 } @dest, @arcs;
    return {
        family => $family,
        dest   => \@dest,
        len    => $length + 0,
        hop    => \@arcs
    };
}

# The connected routes of this context, each with its interface
sub _voss_connected_routes {
    my ( $vrf, $name ) = @_;

    my $protos = $vrf->_vrf_column( 'vrf_cidr_proto', $name );
    my $ifs    = $vrf->_vrf_column( 'vrf_cidr_if',    $name );
    my @routes;
    foreach my $iid ( sort keys %$protos ) {
        next unless SNMP::Info::VRF::_vrf_connected_proto( $protos->{$iid} );
        my $route = _voss_route_index($iid) or next;
        $route->{ifindex}
            = SNMP::Info::VRF::_vrf_route_ifindex( $ifs->{$iid} );
        push @routes, $route;
    }
    return \@routes;
}

# VOSS: the connected routes, parsed from the index VOSS serves; a host
# route is no subnet
sub _vrf_context_route_subnets {
    my ( $vrf, $name ) = @_;

    my @subnets;
    foreach my $route ( @{ $vrf->_voss_connected_routes($name) } ) {
        next if $route->{len} >= 8 * @{ $route->{dest} };
        my $prefix = SNMP::Info::VRF::_vrf_network( $route->{family},
            $route->{dest}, $route->{len} )
            or next;
        push @subnets, {
            prefix  => $prefix,
            len     => $route->{len},
            family  => $route->{family},
            ifindex => $route->{ifindex},
        };
    }
    push @subnets, @{ $vrf->_voss_standard_route_subnets($name) };
    return \@subnets;
}

# Connected routes in the standard index shape, which the VOSS parser
# rejects, read by the standard parser
sub _voss_standard_route_subnets {
    my ( $vrf, $name ) = @_;

    my $protos = $vrf->_vrf_column( 'vrf_cidr_proto', $name );
    my $ifs    = $vrf->_vrf_column( 'vrf_cidr_if',    $name );
    my @subnets;
    foreach my $iid ( sort keys %$protos ) {
        next unless SNMP::Info::VRF::_vrf_connected_proto( $protos->{$iid} );
        next if _voss_route_index($iid) or $iid !~ /^\d+(?:\.\d+)*$/;
        my $subnet = SNMP::Info::VRF::_vrf_route_subnet( split /\./, $iid )
            or next;
        $subnet->{ifindex}
            = SNMP::Info::VRF::_vrf_route_ifindex( $ifs->{$iid} );
        push @subnets, $subnet;
    }
    return \@subnets;
}

# VOSS: a VRF context serves no IP-MIB address table. Its IPv4 addresses
# are the rcIpAddrTable rows whose rcIpAdEntVrfId is the VRF's; in the
# default context those of vrfid 0 add to ipAddrTable. IPv6 addresses are
# in IPV6-MIB ipv6AddrTable.
sub _vrf_vendor_address_rows {
    my ( $vrf, $name ) = @_;

    return {
        %{ $vrf->_voss_rc_ip_addresses($name) },
        %{ $vrf->_vrf_ipv6_mib_address_rows($name) },
    };
}

# rcIpAddrTable is indexed by ifIndex then address, so an address two VRFs
# share on their own VLANs is two rows
sub _voss_rc_ip_addresses {
    my ( $vrf, $name ) = @_;

    my $names = $vrf->_vrf_column( 'vrf_rc_name',    $name );
    my $vrfs  = $vrf->_vrf_column( 'vrf_rc_ip_vrf',  $name );
    my $ips   = $vrf->_vrf_column( 'vrf_rc_ip_addr', $name );
    my $masks = $vrf->_vrf_column( 'vrf_rc_ip_mask', $name );
    my %rows;
    foreach my $iid ( keys %$ips ) {
        my ($ifindex) = $iid =~ /^(\d+)\./ or next;
        my $vrf_name = _voss_vrf_name( $names, $vrfs->{$iid} );
        next unless defined $vrf_name and $vrf_name eq $name;
        $rows{"$ifindex.$ips->{$iid}"} = {
            ifindex    => $ifindex,
            ip         => $ips->{$iid},
            prefix_len =>
                scalar SNMP::Info::VRF::_vrf_mask_length( $masks->{$iid} ),
            family => 'ipv4',
        };
    }
    return \%rows;
}

1;

__END__

=head1 NAME

SNMP::Info::RapidCityVRF - SNMP Interface to the VRFs of Extreme VOSS /
Fabric Engine switches

=head1 AUTHOR

SNMP::Info Developers

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $voss = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $voss->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

SNMP::Info::RapidCityVRF is a subclass of SNMP::Info that implements the
VRF role hooks of L<SNMP::Info::VRF> for VOSS (Virtual Services Platform
Operating System Software) and Fabric Engine, from the C<RAPID-CITY> MIB.
Each VRF is an SNMP context.

Use or create in a subclass of SNMP::Info.  Do not use directly.  List it
ahead of L<SNMP::Info::Layer3> in C<@ISA>, so its hooks replace the defaults
of the VRF role, and list the hashes in the opposite order.  See
L<SNMP::Info::Layer3::VOSS>.

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item F<RAPID-CITY>

=back

=head1 GLOBALS

None.

=head1 TABLE METHODS

=head2 Overrides

=over

=item $voss->context_kinds($feature)

Returns C<['vrf']> for C<vrf>, where each VRF answers in its own context.
Returns nothing otherwise. See C<context_kinds()> in L<SNMP::Info>.

=item $voss->snmp_context($kind, $id)

Returns nothing for kinds other than C<vrf>. See
C<snmp_context()> in L<SNMP::Info>.

For a name C<vrf_instances()> lists returns C<< { kind =E<gt>
'vrf', id =E<gt> $name, v2c =E<gt> '%s::$vrfid', v3 =E<gt> $context } >>.
C<$vrfid> is the VRF's C<rcVrfConfigTable> index. For vrfid 1,
C<public> becomes C<public::1>. C<$context> is the VRF's
C<rcVrfContextName>, such as C<vrf1>. C<default>, which is
C<GlobalRouter>, and a name the device does not list get nothing.

A SNMPv2c community with an C<@> suffix (C<public@vrf1>) is served
from the default context, so the VRF readers do not take the suffix as
the session's context. A session on a C<community::vrfid> community
reads as that VRF: a VRF context serves only its own C<rcVrfConfigTable>
row, and the VRF readers take the context from that row. The default
context serves every row, so a session there reads as the default
context.

=back

=head2 VRF Instances

See L<SNMP::Info::VRF/"VRF Instances"> for the readers. VOSS uses context
mode.

=head3 Instances and ports

=over

=item *

The device lists its VRFs in C<rcVrfConfigTable>, which the default
context serves whole. vrfid 0, C<GlobalRouter>, is the instance
C<default> (see L<SNMP::Info::VRF/"Completeness">). A device with only
C<GlobalRouter> and C<MgmtRouter> reports C<vrf_instances_complete()> 1
with one VRF, C<MgmtRouter>.

=item *

C<l3_isid> is the I-SID C<rcVrfIpVpnTable> gives the VRF's IP VPN, and
undef where it serves none.

=item *

Each VRF reads in its own context, which serves only that VRF's rows.

=item *

In the default context, C<i_vrf()> maps each VRF VLAN's interface from
C<rcVlanTable>, and each interface C<rcIpAddrTable> gives a VRF. That
context serves C<rcIpAddrTable> only for C<GlobalRouter>, so a VRF
interface with no VLAN, such as a loopback, is mapped only in its own
context.

=item *

In a VRF context, the ports are those its C<rcVlanTable> and
C<rcIpAddrTable> give the VRF, and the interfaces of its connected
routes. A route learned over the fabric sits on the fabric VLAN's
interface, which is not a port of the VRF.

=back

=head3 Addresses, routes and neighbors

=over

=item *

A VRF context serves no F<IP-MIB> address table. A VRF's IPv4 addresses
are the C<rcIpAddrTable> rows whose C<rcIpAdEntVrfId> is the VRF's, each
with the prefix length of C<rcIpAdEntNetMask>. No route is an address
source.

=item *

In the default context, the addresses are those C<ipAddrTable> serves,
with the C<rcIpAddrTable> rows of vrfid 0. There C<ipAddrTable> lists
every VRF's addresses, and only those on the ports of C<GlobalRouter> are
kept.

=item *

Those ports include the interface of each C<ipAddrTable> address that a
connected route names as its next hop. The management CLIP is one: its
host route sits on the management VLAN's interface.

=item *

A VRF's IPv6 addresses are those F<IPV6-MIB> C<ipv6AddrTable> serves,
and its IPv6 neighbors those of C<ipv6NetToMediaTable>.

=item *

VOSS indexes C<inetCidrRouteTable> with no length octet before either
address. The subnets of the connected routes are read from that index; a
row in the standard index shape is read as the standard one.

=item *

A context's ARP table holds the VRF's own addresses at the VLAN
interface's MAC, and each subnet broadcast address at the broadcast MAC.
Neither is a neighbor.

=item *

A subnet two VRFs share is read in each one's own context, on its own
VLAN.

=back

=head2 VRF Tables (F<RAPID-CITY>)

=over

=item $voss->vrf_rc_name()

Returns reference to hash of VRF names, keyed by vrfid.

(C<rcVrfName>)

=item $voss->vrf_rc_context()

Returns reference to hash of the SNMP context name of each VRF, keyed
by vrfid.

(C<rcVrfContextName>)

=item $voss->vrf_rc_isid()

Returns reference to hash of the I-SID of each VRF's IP VPN, keyed by
vrfid.

(C<rcVrfIpVpnIsidNumber>)

=item $voss->vrf_rc_vlan_if()

Returns reference to hash of the ifIndex of each VLAN, keyed by VLAN id.

(C<rcVlanIfIndex>)

=item $voss->vrf_rc_vlan_vrf()

Returns reference to hash of the vrfid of each VLAN, keyed by VLAN id.

(C<rcVlanVrfId>)

=item $voss->vrf_rc_ip_vrf()

Returns reference to hash of the vrfid of each address, keyed by
ifIndex then address.

(C<rcIpAdEntVrfId>)

=item $voss->vrf_rc_ip_addr()

Returns reference to hash of addresses, keyed by ifIndex then address.

(C<rcIpAdEntAddr>)

=item $voss->vrf_rc_ip_mask()

Returns reference to hash of address masks, keyed by ifIndex then
address.

(C<rcIpAdEntNetMask>)

=back

=cut
