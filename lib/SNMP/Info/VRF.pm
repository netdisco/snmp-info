# SNMP::Info::VRF
#
# Copyright (c) 2026 Eric Miller
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

package SNMP::Info::VRF;

use strict;
use warnings;
use Exporter;
use SNMP::Info;

@SNMP::Info::VRF::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::VRF::EXPORT_OK = qw//;

our ( $VERSION, %MIBS, %FUNCS, %GLOBALS, %MUNGE );

$VERSION = '3.983000';

%MIBS = (
    'MPLS-L3VPN-STD-MIB' => 'mplsL3VpnConfiguredVrfs',
    'IP-FORWARD-MIB'     => 'inetCidrRouteNumber',
);

%GLOBALS = ( 'vrf_configured' => 'mplsL3VpnConfiguredVrfs', );

%FUNCS = (
    'vrf_l3vpn_descr'     => 'mplsL3VpnVrfDescription',
    'vrf_l3vpn_rd'        => 'mplsL3VpnVrfRD',
    'vrf_l3vpn_oper'      => 'mplsL3VpnVrfOperStatus',
    'vrf_l3vpn_if'        => 'mplsL3VpnIfConfRowStatus',
    'vrf_l3vpn_rt'        => 'mplsL3VpnVrfRT',
    'vrf_l3vpn_rte_if'    => 'mplsL3VpnVrfRteInetCidrIfIndex',
    'vrf_l3vpn_rte_proto' => 'mplsL3VpnVrfRteInetCidrProto',

    # IP-FORWARD-MIB, context mode only
    'vrf_cidr_if'    => 'inetCidrRouteIfIndex',
    'vrf_cidr_proto' => 'inetCidrRouteProto',
);

%MUNGE = ();

my $LIST_SOURCE = 'MPLS-L3VPN-STD-MIB';

# mplsL3VpnVrfRTType values, which sit in the last arc of the index
my %RT_TYPE = ( 1 => 'import', 2 => 'export', 3 => 'both' );

# ipAddressTable index types: bytes is the address part, length the whole
my %INET_TYPE = (
    1 => { family => 'ipv4', bytes => 4,  length => 4 },
    2 => { family => 'ipv6', bytes => 16, length => 16 },
    3 => { family => 'ipv4', bytes => 4,  length => 8 },
    4 => { family => 'ipv6', bytes => 16, length => 20 },
);

sub vrf_instances {
    my $vrf          = shift;
    my $caller_names = shift;

    return unless $vrf->_vrf_default_context_ok();
    my $instances = $vrf->{_vrf_instances} ||= $vrf->_vrf_all_instances();
    my $names     = ref $caller_names eq 'ARRAY' ? $caller_names : [];
    return $instances if !@$names or $vrf->_vrf_device_lists($instances);

    my %with_caller = %$instances;
    foreach my $name (@$names) {
        $with_caller{$name} ||= _vrf_record( $name, 'vrf', 'caller' );
    }
    return \%with_caller;
}

sub _vrf_all_instances {
    my $vrf = shift;

    my $instances = $vrf->_vrf_served_instances();
    $instances->{default} ||= _vrf_record( 'default', 'default', 'device' );
    $instances->{default}{kind} = 'default';
    return $instances;
}

# True when the device served a VRF row or a configured count, so caller
# names have nothing to add
sub _vrf_device_lists {
    my $vrf       = shift;
    my $instances = shift;

    return 1 if grep { $_->{sources}{list} } values %$instances;
    return defined $vrf->vrf_configured() ? 1 : 0;
}

# One record per row mplsL3VpnVrfTable serves, minus the internal ones
sub _vrf_served_instances {
    my $vrf = shift;

    my $descr = $vrf->vrf_l3vpn_descr() || {};
    my $rd    = $vrf->vrf_l3vpn_rd()    || {};
    my $oper  = $vrf->vrf_l3vpn_oper()  || {};
    my %iids  = map { $_ => 1 } keys %$descr, keys %$rd, keys %$oper;

    my %instances;
    foreach my $iid ( keys %iids ) {
        my ($name) = $vrf->_vrf_decode_name($iid);
        next if !defined $name or $vrf->_vrf_internal_instance($name);

        my $record = _vrf_record( $name, 'vrf', 'device' );
        $record->{description}   = _vrf_text( $descr->{$iid} );
        $record->{oper}          = _vrf_text( $oper->{$iid} );
        $record->{rd}            = $vrf->_vrf_rd( $rd->{$iid} );
        $record->{sources}{list} = $LIST_SOURCE;
        $instances{$name}        = $record;
    }

    $vrf->_vrf_add_route_targets( \%instances );
    $vrf->_vrf_add_members( \%instances );
    return \%instances;
}

# Membership is the sources key; i_vrf holds the ports themselves
sub _vrf_add_members {
    my $vrf       = shift;
    my $instances = shift;

    foreach my $name ( values %{ $vrf->_vrf_membership() } ) {
        next unless $instances->{$name};
        $instances->{$name}{sources}{members} = $LIST_SOURCE;
    }
    return;
}

# { ifIndex => name } for every active row of mplsL3VpnIfConfTable. The
# index is the VRF name then the ifIndex.
sub _vrf_membership {
    my $vrf = shift;

    my $rows = $vrf->vrf_l3vpn_if() || {};
    my %ports;
    foreach my $iid ( keys %$rows ) {
        next unless $rows->{$iid} =~ /^(?:active|1)$/;
        my ( $name, $ifindex, @extra ) = $vrf->_vrf_decode_name($iid);
        next if !defined $ifindex  or @extra;
        next if $name eq 'default' or $vrf->_vrf_internal_instance($name);
        $ports{$ifindex} = $name;
    }
    return \%ports;
}

sub _vrf_record {
    my ( $name, $kind, $listed_by ) = @_;

    return {
        name        => $name,
        kind        => $kind,
        description => undef,
        oper        => undef,
        rd          => undef,
        rt_import   => [],
        rt_export   => [],
        l3_vni      => undef,
        l3_isid     => undef,
        listed_by   => $listed_by,
        sources     => {},
        contexts    => [ { kind => 'none' } ],
    };
}

sub _vrf_text {
    my $value = shift;

    return ( defined $value and length $value ) ? $value : undef;
}

# Index is name, rtIndex, rtType; a 'both' target belongs in each list
sub _vrf_add_route_targets {
    my $vrf       = shift;
    my $instances = shift;

    my $targets = $vrf->vrf_l3vpn_rt() || {};
    my ( %import, %export );
    foreach my $iid ( keys %$targets ) {
        my ( $name, $rt_index, $type_arc ) = $vrf->_vrf_decode_name($iid);
        next unless defined $type_arc        and $instances->{$name};
        next unless defined $targets->{$iid} and length $targets->{$iid};

        my $type = $RT_TYPE{$type_arc} or next;
        $import{$name}{ $targets->{$iid} } = 1 if $type ne 'export';
        $export{$name}{ $targets->{$iid} } = 1 if $type ne 'import';
    }

    foreach my $name ( keys %$instances ) {
        $instances->{$name}{rt_import} = [ sort keys %{ $import{$name} } ];
        $instances->{$name}{rt_export} = [ sort keys %{ $export{$name} } ];
    }
    return;
}

# Decodes a length-prefixed octet string index. Returns the string and the
# arcs after it, or an empty list when the index is shorter than its prefix.
sub _vrf_decode_name {
    my $vrf = shift;
    my $iid = shift;

    return unless defined $iid and $iid =~ /^\d+(?:\.\d+)*$/;
    my ( $length, @arcs ) = split /\./, $iid;
    return if $length > @arcs;
    my @octets = splice @arcs, 0, $length;
    return if grep { $_ > 255 } @octets;

    return ( join( q{}, map {chr} @octets ), @arcs );
}

# Empty and 0:0 mean no distinguisher; printable text is kept as served and
# anything else is binary, shown as colon separated hex
sub _vrf_rd {
    my $vrf = shift;
    my $raw = shift;

    return      if !defined $raw or $raw eq q{} or $raw eq '0:0';
    return $raw if $raw =~ /^[\x20-\x7e]+$/;
    return join ':', map { sprintf '%02x', ord } split //, $raw;
}

sub i_vrf {
    my $vrf = shift;

    return unless $vrf->_vrf_default_context_ok();
    return $vrf->_vrf_membership();
}

# 1 when the list is whole, 0 when it may be short, undef when the device
# serves no VRF list and the caller named none
sub vrf_instances_complete {
    my $vrf          = shift;
    my $caller_names = shift;

    my $instances  = $vrf->vrf_instances($caller_names) or return;
    my @listed     = grep { $_->{sources}{list} } values %$instances;
    my $configured = $vrf->vrf_configured();

    if ( !defined $configured and !@listed ) {
        return ( ref $caller_names eq 'ARRAY' and @$caller_names )
            ? 0
            : undef;
    }
    return 0 if $vrf->_vrf_walk_incomplete();
    my @rows = grep { $_->{name} ne 'default' } @listed;
    return 0 if defined $configured and $configured > @rows;
    return 0 if $vrf->_vrf_split_agent( \@rows, $configured );
    return 1;
}

sub _vrf_walk_incomplete {
    my $vrf = shift;

    foreach my $method (qw/vrf_l3vpn_rd vrf_l3vpn_if/) {
        my $status = $vrf->walk_status($method) or next;
        return 1 unless $status->{complete};
    }
    return 0;
}

# A row with no port is fine when the agent serves ports for other rows; it
# is a gap when the agent cannot say whether it serves ports at all
sub _vrf_split_agent {
    my $vrf        = shift;
    my $rows       = shift;
    my $configured = shift;

    my $members   = $vrf->i_vrf() || {};
    my %with_port = map { $_ => 1 } values %$members;
    return 0 unless grep { !$with_port{ $_->{name} } } @$rows;
    return 1 if !defined $configured;
    return %$members ? 0 : 1;
}

# ARP and IPv6 neighbor rows of one instance, keyed as the source tables
# are: ifIndex, then the address arcs. Attribution mode keeps the rows whose
# port belongs to the instance; context mode already reads one instance.
sub vrf_neighbors {
    my $vrf  = shift;
    my $name = shift;

    return unless defined $name and $vrf->_vrf_in_reader_context($name);
    my $context_mode = $vrf->_vrf_context_filters();
    return if !$context_mode and !$vrf->_vrf_is_listed($name);

    my %rows = ( %{ $vrf->_vrf_arp_rows() }, %{ $vrf->_vrf_nd_rows() } );
    return \%rows if $context_mode;

    foreach my $key ( keys %rows ) {
        my $owner = $vrf->_vrf_owner_of( $rows{$key}{ifindex} );
        delete $rows{$key} if !defined $owner or $owner ne $name;
    }
    return \%rows;
}

# Interface addresses of one instance, keyed ifIndex.address. The device
# serves one address table per port, so an address two VRFs share survives
# in each, and ownership comes from the port as for neighbors.
sub vrf_addresses {
    my $vrf  = shift;
    my $name = shift;

    return unless defined $name and $vrf->_vrf_in_reader_context($name);
    my $context_mode = $vrf->_vrf_context_filters();
    return if !$context_mode and !$vrf->_vrf_is_listed($name);

    my $rows = $vrf->_vrf_address_rows();
    return $rows if $context_mode;

    foreach my $key ( keys %$rows ) {
        my $owner = $vrf->_vrf_owner_of( $rows->{$key}{ifindex} );
        delete $rows->{$key} if !defined $owner or $owner ne $name;
    }
    return $rows;
}

# Subnets of one instance: the network of each address that has a prefix
# length, plus the connected routes when the class enables them. A prefix
# found both ways lists 'address' first.
sub vrf_subnets {
    my $vrf  = shift;
    my $name = shift;

    return unless defined $name and $vrf->_vrf_in_reader_context($name);
    my $context_mode = $vrf->_vrf_context_filters();
    return if !$context_mode and !$vrf->_vrf_is_listed($name);

    my %subnets;
    my $addresses = $vrf->vrf_addresses($name) || {};
    foreach my $key ( sort keys %$addresses ) {
        my $subnet = _vrf_address_subnet( $addresses->{$key} ) or next;
        _vrf_add_subnet( \%subnets, $subnet, 'address' );
    }
    return \%subnets unless $vrf->_vrf_subnets_from_routes();

    my $routes
        = $context_mode
        ? $vrf->_vrf_context_route_subnets()
        : $vrf->_vrf_attributed_route_subnets($name);
    _vrf_add_subnet( \%subnets, $_, 'route' ) for @$routes;
    return \%subnets;
}

# Adds one source to the subnet; the first port seen keeps the record
sub _vrf_add_subnet {
    my ( $subnets, $subnet, $source ) = @_;

    my $key    = "$subnet->{prefix}/$subnet->{len}";
    my $record = $subnets->{$key} ||= {
        prefix  => $subnet->{prefix},
        len     => $subnet->{len},
        family  => $subnet->{family},
        ifindex => $subnet->{ifindex},
        sources => [],
    };
    $record->{ifindex} //= $subnet->{ifindex};
    push @{ $record->{sources} }, $source
        unless grep { $_ eq $source } @{ $record->{sources} };
    return;
}

sub _vrf_address_subnet {
    my $address = shift;

    return unless defined $address->{prefix_len};
    my @octets = _vrf_ip_octets( $address->{family}, $address->{ip} )
        or return;
    my $prefix
        = _vrf_network( $address->{family}, \@octets, $address->{prefix_len} )
        or return;

    return {
        prefix  => $prefix,
        len     => $address->{prefix_len},
        family  => $address->{family},
        ifindex => $address->{ifindex},
    };
}

# The octets of an address in the form vrf_addresses gives it
sub _vrf_ip_octets {
    my ( $family, $ip ) = @_;

    return split /\./, $ip if $family eq 'ipv4';
    my @groups = split /:/, $ip;
    return if @groups != 8;
    return unpack 'C*', pack 'n8', map {hex} @groups;
}

# Zeroes the host bits and formats the result as vrf_addresses does
sub _vrf_network {
    my ( $family, $octets, $length ) = @_;

    my $bits = unpack 'B*', pack 'C*', @$octets;
    return if $length > length $bits;
    my $masked
        = substr( $bits, 0, $length ) . ( '0' x ( length($bits) - $length ) );
    my @network = unpack 'C*', pack 'B*', $masked;

    return join q{.}, @network if $family eq 'ipv4';
    return join q{:}, unpack '(H4)*', pack 'C*', @network;
}

# Connected routes of mplsL3VpnVrfRteTable whose index starts with $name
sub _vrf_attributed_route_subnets {
    my $vrf  = shift;
    my $name = shift;

    my $protos = $vrf->_vrf_column('vrf_l3vpn_rte_proto');
    my $ifs    = $vrf->_vrf_column('vrf_l3vpn_rte_if');
    my @subnets;
    foreach my $iid ( sort keys %$protos ) {
        next unless _vrf_connected_proto( $protos->{$iid} );
        my ( $route_name, @arcs ) = $vrf->_vrf_decode_name($iid);
        next if !defined $route_name or $route_name ne $name;
        my $subnet = _vrf_route_subnet(@arcs) or next;
        $subnet->{ifindex} = $ifs->{$iid};
        push @subnets, $subnet;
    }
    return \@subnets;
}

# Connected routes of inetCidrRouteTable, which has no name in its index
sub _vrf_context_route_subnets {
    my $vrf = shift;

    my $protos = $vrf->_vrf_column('vrf_cidr_proto');
    my $ifs    = $vrf->_vrf_column('vrf_cidr_if');
    my @subnets;
    foreach my $iid ( sort keys %$protos ) {
        next unless _vrf_connected_proto( $protos->{$iid} );
        my $subnet = _vrf_route_subnet( split /\./, $iid ) or next;
        $subnet->{ifindex} = $ifs->{$iid};
        push @subnets, $subnet;
    }
    return \@subnets;
}

sub _vrf_connected_proto {
    my $proto = shift;

    return ( defined $proto and $proto =~ /^(?:local|2)$/ ) ? 1 : 0;
}

# Parses destType.destLen.dest.pfxLen.policyLen.policy.nhType.nhLen.nh by
# the length octets. Gives nothing for a malformed index or a host route.
sub _vrf_route_subnet {
    my @arcs = @_;

    my ( $type, $dest_length ) = splice @arcs, 0, 2;
    my $shape = $INET_TYPE{ $type // q{} } or return;
    return if !defined $dest_length or $dest_length != $shape->{length};
    return if @arcs < $dest_length + 2;

    my @dest = splice @arcs, 0, $dest_length;
    my ( $length, $policy_length ) = splice @arcs, 0, 2;
    return if @arcs < $policy_length + 2;

    splice @arcs, 0, $policy_length;
    my ( undef, $hop_length ) = splice @arcs, 0, 2;
    return if @arcs != $hop_length;
    return if $length >= $shape->{bytes} * 8;

    my @octets = @dest[ 0 .. $shape->{bytes} - 1 ];
    my $prefix = _vrf_network( $shape->{family}, \@octets, $length )
        or return;
    return {
        prefix => $prefix,
        len    => $length + 0,
        family => $shape->{family}
    };
}

# ipAddressTable, with ipAdEntTable standing in for IPv4 when the first
# serves no IPv4 row
sub _vrf_address_rows {
    my $vrf = shift;

    my $rows = $vrf->_vrf_inet_address_rows();
    return $rows if grep { $_->{family} eq 'ipv4' } values %$rows;
    return { %$rows, %{ $vrf->_vrf_ipadent_rows() } };
}

# Index is type, length, address octets; types 3 and 4 end with four zone
# octets that are not part of the address. Two rows on one port that differ
# only by zone are one address: the lowest index is kept so the choice
# does not depend on hash order.
sub _vrf_inet_address_rows {
    my $vrf = shift;

    my $ifindexes = $vrf->new_ip_index()  || {};
    my $types     = $vrf->new_ip_type()   || {};
    my $prefixes  = $vrf->new_ip_prefix() || {};

    my %rows;
    foreach my $iid ( sort keys %$ifindexes ) {
        next unless ( $types->{$iid} // q{} ) eq 'unicast';
        my $address = _vrf_parse_address($iid) or next;
        my $key     = "$ifindexes->{$iid}.$address->{ip}";
        next if exists $rows{$key};

        $rows{$key} = {
            ifindex    => $ifindexes->{$iid},
            ip         => $address->{ip},
            prefix_len => scalar _vrf_pointer_length( $prefixes->{$iid} ),
            family     => $address->{family},
        };
    }
    return \%rows;
}

# { ip, family } from type.length.octets, or nothing for a shape the
# address types do not allow
sub _vrf_parse_address {
    my $iid = shift;

    my ( $type, $length, @octets ) = split /\./, $iid;
    my $shape = $INET_TYPE{ $type // q{} } or return;
    return unless defined $length and $length == $shape->{length};
    return unless @octets == $length;

    my @address = @octets[ 0 .. $shape->{bytes} - 1 ];
    return {
        family => $shape->{family},
        ip     => $shape->{family} eq 'ipv4'
        ? join( q{.}, @address )
        : join( q{:}, unpack '(H4)*', pack 'C*', @address ),
    };
}

# The last arc of an ipAddressPrefix RowPointer is the prefix length; the
# null pointer 0.0 says the device holds none
sub _vrf_pointer_length {
    my $pointer = shift;

    return if !defined $pointer or $pointer =~ /^(?:\.?0\.0|zeroDotZero)$/;
    return $pointer =~ /\.(\d+)$/ ? $1 + 0 : undef;
}

sub _vrf_ipadent_rows {
    my $vrf = shift;

    my $ifindexes = $vrf->old_ip_index()   || {};
    my $masks     = $vrf->old_ip_netmask() || {};

    my %rows;
    foreach my $ip ( keys %$ifindexes ) {
        $rows{"$ifindexes->{$ip}.$ip"} = {
            ifindex    => $ifindexes->{$ip},
            ip         => $ip,
            prefix_len => scalar _vrf_mask_length( $masks->{$ip} ),
            family     => 'ipv4',
        };
    }
    return \%rows;
}

# 255.255.255.0 is 24; a mask with a gap in it has no length
sub _vrf_mask_length {
    my $mask = shift;

    return unless defined $mask and $mask =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/;
    my $bits = unpack 'B32', pack 'C4', $1, $2, $3, $4;
    return $bits =~ /^(1*)0*$/ ? length $1 : undef;
}

sub _vrf_is_listed {
    my $vrf  = shift;
    my $name = shift;

    my $instances = $vrf->vrf_instances() or return 0;
    return exists $instances->{$name} ? 1 : 0;
}

# A method the class does not have contributes no rows
sub _vrf_column {
    my $vrf    = shift;
    my $method = shift;

    return {} unless $vrf->can($method);
    return $vrf->$method() || {};
}

sub _vrf_arp_rows {
    my $vrf = shift;

    my $macs = $vrf->_vrf_column('at_paddr');
    my $ips  = $vrf->_vrf_column('at_netaddr');
    my %rows;
    foreach my $key ( keys %$macs ) {
        my ($ifindex) = $key =~ /^(\d+)\./ or next;
        next unless defined $ips->{$key} and defined $macs->{$key};
        $rows{$key} = {
            ifindex => $ifindex,
            ip      => $ips->{$key},
            mac     => $macs->{$key},
            family  => 'ipv4',
        };
    }
    return \%rows;
}

sub _vrf_nd_rows {
    my $vrf = shift;

    my $macs = $vrf->_vrf_column('ipv6_n2p_mac');
    my $ips  = $vrf->_vrf_column('ipv6_n2p_addr');
    my $ifs  = $vrf->_vrf_column('ipv6_n2p_if');
    my %rows;
    foreach my $key ( keys %$macs ) {
        next unless defined $ips->{$key} and defined $ifs->{$key};
        $rows{$key} = {
            ifindex => $ifs->{$key},
            ip      => $ips->{$key},
            mac     => $macs->{$key},
            family  => 'ipv6',
        };
    }
    return \%rows;
}

sub _vrf_context_filters { return 0; }

sub _vrf_subnets_from_routes { return 0; }

sub _vrf_internal_instance { return 0; }

# Only the default context serves the whole VRF list
sub _vrf_default_context_ok {
    my $vrf = shift;

    my $context = $vrf->_walk_context();
    return 1 unless length $context;

    my $method = ( caller(1) )[3];
    $vrf->error_throw(
              "$method() reads the VRF list, which only the default context"
            . " serves whole. This session is in context '$context'. Call"
            . " update() back to the default context, read the list, and"
            . " keep it while you switch contexts.\n" );
    return 0;
}

# Attribution mode reads the default context and sorts rows by port. Context
# mode reads one instance per context, so the default context only serves
# the instance named default.
sub _vrf_in_reader_context {
    my $vrf  = shift;
    my $name = shift;

    my $context = $vrf->_walk_context();
    my $method  = ( caller(1) )[3];

    if ( !$vrf->_vrf_context_filters() ) {
        return 1 unless length $context;
        $vrf->error_throw(
                  "$method() reads instance '$name' from the default"
                . " context, attributing rows by port, on this device."
                . " This session is in context '$context'. Call update()"
                . " back to the default context first.\n" );
        return 0;
    }

    return 1 if length $context or $name eq 'default';
    $vrf->error_throw(
              "$method() reads instance '$name' from its own context on"
            . " this device, but this session is in the default context."
            . " Switch with snmp_context('vrf', '$name') first.\n" );
    return 0;
}

# A port the membership table does not list belongs to the global table
sub _vrf_owner_of {
    my $vrf     = shift;
    my $ifindex = shift;

    my $members = $vrf->i_vrf() or return;
    return exists $members->{$ifindex} ? $members->{$ifindex} : 'default';
}

1;

__END__

=head1 NAME

SNMP::Info::VRF - SNMP Interface to VRF (virtual routing and forwarding)
instances

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

    my $vrf = new SNMP::Info(
        AutoSpecify => 1,
        Debug       => 1,
        DestHost    => 'myrouter',
        Community   => 'public',
        Version     => 2
    );

    my $instances = $vrf->vrf_instances();

=head1 DESCRIPTION

SNMP::Info::VRF is a role that reports the VRF instances a device serves in
F<MPLS-L3VPN-STD-MIB>, with the route distinguisher and route targets of
each. The global routing table is always the instance C<default>.

=head2 Inherited Classes

=over

None.

=back

=head2 Required MIBs

=over

=item F<MPLS-L3VPN-STD-MIB>

=item F<IP-FORWARD-MIB>

=back

=head1 GLOBALS

=over

=item $vrf->vrf_configured()

(C<mplsL3VpnConfiguredVrfs>)

=back

=head1 METHODS

=over

=item $vrf->vrf_instances( [ \@names ] )

Returns a hashref of instance records keyed by VRF name, always including
C<default>. Each record holds C<name>, C<kind>, C<description>, C<oper>,
C<rd>, C<rt_import>, C<rt_export>, C<listed_by>, C<sources> and
C<contexts>. Names passed in C<\@names> that the device did not serve are
added with C<listed_by> set to C<caller>.

Names are used only when the device serves no VRF list at all; when it
lists instances they are ignored.

Reads the default context only. In any other context it sets an error and
returns nothing.

=item $vrf->vrf_instances_complete( [ \@names ] )

Returns 1 when the list holds every VRF the device has, 0 when it may be
short (the list came from the caller, a walk was incomplete, the device
configures more VRFs than it listed, or it lists VRFs but no port
membership), and undef when the device serves no VRF list and no names were
given. A device that reports zero configured VRFs returns 1.

=item $vrf->i_vrf()

Returns a hashref of VRF name keyed by ifIndex, from the active rows of
F<MPLS-L3VPN-STD-MIB> C<mplsL3VpnIfConfTable>. Ports in the default instance
are absent. Reads the default context only.

=item $vrf->vrf_neighbors($name)

Returns a hashref of the neighbor rows of instance C<$name>, keyed by
ifIndex and address as C<at_paddr> and C<ipv6_n2p_mac> key them. Each row
holds C<ifindex>, C<ip>, C<mac> and C<family> (C<ipv4> or C<ipv6>). Returns
nothing for a name the device does not list, or when the session is in the
wrong context for the device; the error says how to change it.

=item $vrf->vrf_addresses($name)

Returns a hashref of the interface addresses of instance C<$name>, keyed
by ifIndex and address. Each row holds C<ifindex>, C<ip>, C<prefix_len>
(undef when the device gives none) and C<family>. IPv6 addresses are in the
form C<ipv6_n2p_addr> returns, without any zone. Reads C<ipAddressTable>,
and C<ipAdEntTable> for IPv4 when the first serves no IPv4 row. Returns
nothing for a name the device does not list, or in the wrong context.

=item $vrf->vrf_subnets($name)

Returns a hashref of the subnets of instance C<$name>, keyed C<prefix/len>.
Each holds C<prefix>, C<len>, C<family>, C<ifindex> and C<sources>, a list of
C<address> (the network of an interface address that has a prefix length)
and C<route> (a connected route). Routes are read only by classes that
enable them. Returns nothing for a name the device does not list, or in the
wrong context.

=back

=head1 TABLE METHODS

=over

=item $vrf->vrf_l3vpn_descr()

(C<mplsL3VpnVrfDescription>)

=item $vrf->vrf_l3vpn_rd()

(C<mplsL3VpnVrfRD>)

=item $vrf->vrf_l3vpn_oper()

(C<mplsL3VpnVrfOperStatus>)

=item $vrf->vrf_l3vpn_if()

(C<mplsL3VpnIfConfRowStatus>)

=item $vrf->vrf_l3vpn_rt()

(C<mplsL3VpnVrfRT>)

=item $vrf->vrf_l3vpn_rte_if()

(C<mplsL3VpnVrfRteInetCidrIfIndex>)

=item $vrf->vrf_l3vpn_rte_proto()

(C<mplsL3VpnVrfRteInetCidrProto>)

=item $vrf->vrf_cidr_if()

(C<inetCidrRouteIfIndex>)

=item $vrf->vrf_cidr_proto()

(C<inetCidrRouteProto>)

=back

=cut
