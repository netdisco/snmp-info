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

# The IPv6 role's ipv6_n2p_* subs walk these columns, which walk_status names
my @ND_COLUMNS      = qw/ip_n2p_phys_addr c_inet_phys_addr i6_n2p_phys_addr/;
my @ND_TYPE_COLUMNS = qw/ip_n2p_phys_type c_inet_phys_type i6_n2p_phys_type/;

# Layer3's at_* subs fall back to atTable, then ipNetToPhysicalTable, and
# its at_netaddr fallback reads the paddr columns to choose
my @ARP_PADDR_COLUMNS = qw/at_paddr old_at_paddr ip_n2p_phys_addr/;
my @ARP_NETADDR_COLUMNS
    = ( qw/at_netaddr old_at_netaddr/, @ARP_PADDR_COLUMNS );

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
        next if $with_caller{$name};
        $with_caller{$name} = _vrf_record( $name, 'vrf', 'caller' );
        $vrf->_vrf_set_contexts( $with_caller{$name} );
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

# The context that filters to one VRF, as snmp_context('vrf') answers it,
# or undef where the device has none.
sub _vrf_context_for {
    my $vrf  = shift;
    my $name = shift;

    return unless $vrf->context_kinds('vrf');
    return $vrf->snmp_context( 'vrf', $name );
}

sub _vrf_set_contexts {
    my $vrf    = shift;
    my $record = shift;

    return if $record->{name} eq 'default';
    my $context = $vrf->_vrf_context_for( $record->{name} );
    $record->{contexts} = [$context] if $context;
    return;
}

# True when the device served a VRF row, so caller names have nothing to
# add. A configured count alone does not list: an agent can count zero
# MPLS-L3VPN VRFs on a device that has instances of another kind.
sub _vrf_device_lists {
    my $vrf       = shift;
    my $instances = shift;

    return ( grep { $_->{sources}{list} } values %$instances ) ? 1 : 0;
}

sub _vrf_served_instances {
    my $vrf = shift;

    my $instances = $vrf->_vrf_mpls_records();
    $vrf->{_vrf_vendor_listed} = %$instances ? 0 : 1;
    $instances = $vrf->_vrf_vendor_records() if !%$instances;
    $vrf->_vrf_add_route_targets($instances);
    $vrf->_vrf_add_members($instances);
    return $instances;
}

# True when the list came from the vendor hook: MPLS-L3VPN-STD-MIB served
# no instance row. Memoized because a second read of the MPLS table would
# replace its walk status.
sub _vrf_vendor_listed {
    my $vrf = shift;

    $vrf->{_vrf_vendor_listed} //= %{ $vrf->_vrf_mpls_records() } ? 0 : 1;
    return $vrf->{_vrf_vendor_listed};
}

# One record per row mplsL3VpnVrfTable serves, minus the internal ones
sub _vrf_mpls_records {
    my $vrf = shift;

    my $descr = $vrf->vrf_l3vpn_descr() || {};
    my $rd    = $vrf->vrf_l3vpn_rd()    || {};
    my $oper  = $vrf->vrf_l3vpn_oper()  || {};
    my %iids  = map { $_ => 1 } keys %$descr, keys %$rd, keys %$oper;

    my %instances;
    foreach my $iid ( keys %iids ) {
        my ($name) = $vrf->_vrf_decode_instance($iid);
        next if !defined $name or $vrf->_vrf_internal_instance($name);

        my $record = _vrf_record( $name, 'vrf', 'device' );
        $record->{description}   = _vrf_text( $descr->{$iid} );
        $record->{oper}          = _vrf_text( $oper->{$iid} );
        $record->{rd}            = $vrf->_vrf_rd( $rd->{$iid} );
        $record->{sources}{list} = $LIST_SOURCE;
        $record->{sources}{rd}   = $LIST_SOURCE if defined $record->{rd};
        $vrf->_vrf_set_contexts($record);
        $instances{$name} = $record;
    }
    return \%instances;
}

# The vendor list, used only when MPLS-L3VPN-STD-MIB served no instance row
sub _vrf_vendor_records {
    my $vrf = shift;

    my $records = $vrf->_vrf_vendor_instances() || {};
    $vrf->_vrf_set_contexts($_) for values %$records;
    return $records;
}

# Membership is the sources key; i_vrf holds the ports themselves
sub _vrf_add_members {
    my $vrf       = shift;
    my $instances = shift;

    my $vendor_ports
        = $vrf->_vrf_vendor_listed() ? $vrf->_vrf_vendor_membership() : {};
    my %vendor_named = map { $_ => 1 } values %$vendor_ports;
    foreach my $name ( values %{ $vrf->_vrf_membership() } ) {
        next unless $instances->{$name};
        $instances->{$name}{sources}{members}
            = $vendor_named{$name}
            ? $instances->{$name}{sources}{list}
            : $LIST_SOURCE;
    }
    return;
}

# { ifIndex => name } for every active row of mplsL3VpnIfConfTable. The
# index is the VRF name then the ifIndex. clear_cache drops the memo.
sub _vrf_membership {
    my $vrf = shift;

    return $vrf->{_vrf_members} ||= $vrf->_vrf_decode_membership();
}

sub _vrf_decode_membership {
    my $vrf = shift;

    my $rows = $vrf->vrf_l3vpn_if() || {};
    my %ports = $vrf->_vrf_vendor_listed()
        ? %{ $vrf->_vrf_vendor_membership() }
        : ();
    foreach my $iid ( keys %$rows ) {
        next unless $rows->{$iid} =~ /^(?:active|1)$/;
        my ( $name, $ifindex, @extra ) = $vrf->_vrf_decode_instance($iid);
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
        my ( $name, undef, $type_arc ) = $vrf->_vrf_decode_instance($iid);
        next unless defined $type_arc        and $instances->{$name};
        next unless defined $targets->{$iid} and length $targets->{$iid};

        my $type = $RT_TYPE{$type_arc} or next;
        $import{$name}{ $targets->{$iid} } = 1 if $type ne 'export';
        $export{$name}{ $targets->{$iid} } = 1 if $type ne 'import';
    }

    foreach my $name ( keys %$instances ) {
        my $record = $instances->{$name};
        $record->{rt_import}   = [ sort keys %{ $import{$name} } ];
        $record->{rt_export}   = [ sort keys %{ $export{$name} } ];
        $record->{sources}{rt} = $LIST_SOURCE
            if @{ $record->{rt_import} }
            or @{ $record->{rt_export} };
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

# As _vrf_decode_name, with the empty name, the global table, as default
sub _vrf_decode_instance {
    my $vrf = shift;
    my $iid = shift;

    my ( $name, @arcs ) = $vrf->_vrf_decode_name($iid) or return;
    return ( ( length $name ? $name : 'default' ), @arcs );
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

    return $vrf->_vrf_context_i_vrf() if $vrf->_vrf_context_filters();
    return unless $vrf->_vrf_default_context_ok();
    return $vrf->_vrf_membership();
}

# Context mode: the ports of the instance whose context the session is in
sub _vrf_context_i_vrf {
    my $vrf = shift;

    my $name = $vrf->_vrf_context_instance();
    return $vrf->_vrf_membership()
        if defined $name
        and $name eq 'default'
        and $vrf->_vrf_default_context_leaks();
    return $vrf->_vrf_context_ports($name) if defined $name;

    my $context = $vrf->_walk_context();
    $vrf->error_throw(
              "i_vrf() maps the ports of the instance whose context this"
            . " session is in, but no instance in vrf_instances() has the"
            . " context '$context'. Switch to the context snmp_context('vrf')"
            . " gives for a name vrf_instances() lists.\n" );
    return;
}

# default in the default context, else the listed instance whose context
# is the session's. The list is read without the default context guard,
# since the context map serves it in every context.
sub _vrf_context_instance {
    my $vrf = shift;

    my $context = $vrf->_walk_context();
    return 'default' unless length $context;

    my $instances = $vrf->{_vrf_instances} ||= $vrf->_vrf_all_instances();
    foreach my $name ( sort keys %$instances ) {
        next if $name eq 'default';
        return $name
            if grep { $_ eq $context } $vrf->_vrf_contexts_of($name);
    }
    return;
}

# { ifIndex => $name } for each port holding an address in this context.
# The address walks decide membership, so they count toward the read.
sub _vrf_context_ports {
    my $vrf  = shift;
    my $name = shift;

    my $rows = $vrf->_vrf_address_rows($name);
    return { map { $_->{ifindex} => $name } values %$rows };
}

# The contexts _walk_context() reports in $name's context: the v3 name,
# and the context of a community the v2c template builds. Where the class
# has no VRF context kind the instance's context is its name; where it has
# one and gives this instance none, the instance has no context.
sub _vrf_contexts_of {
    my $vrf  = shift;
    my $name = shift;

    return $name unless $vrf->context_kinds('vrf');
    my $context = $vrf->snmp_context( 'vrf', $name ) or return;
    my $v2c     = $context->{v2c};
    my @v2c
        = !defined $v2c        ? ()
        : $v2c =~ /^%s\@(.+)$/ ? $1
        : $v2c =~ /^(.+)\@%s$/ ? $1
        :                        ();
    return grep { defined and length } $context->{v3}, @v2c;
}

# 1 when the list is whole, 0 when it may be short, undef when the device
# serves no VRF list and the caller named none
sub vrf_instances_complete {
    my $vrf          = shift;
    my $caller_names = shift;

    my $instances = $vrf->vrf_instances($caller_names) or return;
    return 0 if grep { $_->{listed_by} eq 'caller' } values %$instances;

    my @listed     = grep { $_->{sources}{list} } values %$instances;
    my $configured = $vrf->vrf_configured();
    return   if !defined $configured and !@listed;
    return 0 if $vrf->_vrf_walk_incomplete();
    my @rows = grep { $_->{name} ne 'default' } @listed;
    return 0 if defined $configured and $configured > @rows;
    return 1 if $vrf->_vrf_context_filters();
    return 0 if $vrf->_vrf_split_agent( \@rows, $configured );
    return 1;
}

sub _vrf_walk_incomplete {
    my $vrf = shift;

    my @walked = qw/vrf_l3vpn_rd vrf_l3vpn_if vrf_l3vpn_rt/;
    push @walked, $vrf->_vrf_vendor_list_methods()
        if $vrf->_vrf_vendor_listed();
    foreach my $method (@walked) {
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
# port belongs to the instance; context mode keeps the rows on the ports
# holding an address in this context, which a context can serve for ports
# of other instances.
sub vrf_neighbors {
    my $vrf  = shift;
    my $name = shift;

    return unless defined $name and $vrf->_vrf_in_reader_context($name);
    my $context_mode = $vrf->_vrf_context_filters();
    return if !$context_mode and !$vrf->_vrf_is_listed($name);

    my %rows
        = ( %{ $vrf->_vrf_arp_rows($name) }, %{ $vrf->_vrf_nd_rows($name) },
        );
    my $kept
        = $context_mode
        ? $vrf->_vrf_keep_context_ports( \%rows, $name )
        : $vrf->_vrf_keep_owned( \%rows, $name );
    return $vrf->_vrf_drop_own_rows( $kept, $name );
}

# Drops the rows that are the instance's own addresses: a global address
# the instance holds on any port, a link-local one it holds on that port.
# The address walks decide which rows go, so they count toward the read.
sub _vrf_drop_own_rows {
    my ( $vrf, $rows, $name ) = @_;

    my %own;
    foreach my $address ( values %{ $vrf->_vrf_instance_addresses($name) } ) {
        $own{ _vrf_own_key( $address->{ifindex}, $address->{ip} ) } = 1;
    }
    foreach my $key ( keys %$rows ) {
        my $row = $rows->{$key};
        delete $rows->{$key} if $own{ _vrf_own_key( @$row{qw/ifindex ip/} ) };
    }
    return $rows;
}

# A link-local address is one per link, so its port is part of the key
sub _vrf_own_key {
    my ( $ifindex, $ip ) = @_;

    $ip = lc $ip;
    return $ip =~ /^fe[89ab]/ ? "$ifindex $ip" : $ip;
}

# Interface addresses of one instance, keyed ifIndex.address. The device
# serves one address table per port, so an address two VRFs share survives
# in each, and ownership comes from the port as for neighbors. In context
# mode the addresses are what decides the ports, so all are kept.
sub vrf_addresses {
    my $vrf  = shift;
    my $name = shift;

    return unless defined $name and $vrf->_vrf_in_reader_context($name);
    my $context_mode = $vrf->_vrf_context_filters();
    return if !$context_mode and !$vrf->_vrf_is_listed($name);

    return $vrf->_vrf_instance_addresses($name);
}

# vrf_addresses() past its guards
sub _vrf_instance_addresses {
    my $vrf  = shift;
    my $name = shift;

    my $rows = $vrf->_vrf_address_rows($name);
    return $vrf->_vrf_drop_leaked( $rows, $name )
        if $vrf->_vrf_context_filters();
    return $vrf->_vrf_keep_owned( $rows, $name );
}

# Context mode: drops the rows on ports another instance holds
sub _vrf_drop_leaked {
    my ( $vrf, $rows, $name ) = @_;

    my $leaked = $vrf->_vrf_leaked_ports($name);
    foreach my $key ( keys %$rows ) {
        delete $rows->{$key} if exists $leaked->{ $rows->{$key}{ifindex} };
    }
    return $rows;
}

# Context mode: drops the rows on ports holding no address of $name here
sub _vrf_keep_context_ports {
    my ( $vrf, $rows, $name ) = @_;

    my $ports  = $vrf->_vrf_context_ports($name);
    my $leaked = $vrf->_vrf_leaked_ports($name);
    foreach my $key ( keys %$rows ) {
        my $ifindex = $rows->{$key}{ifindex};
        delete $rows->{$key}
            if !exists $ports->{$ifindex}
            or exists $leaked->{$ifindex};
    }
    return $rows;
}

# The ports the default context's membership tables give another instance,
# where the default context serves their rows too; {} everywhere else. The
# membership walk decides which rows go, so it counts toward the read.
sub _vrf_leaked_ports {
    my $vrf  = shift;
    my $name = shift;

    return {}
        unless $name eq 'default' and $vrf->_vrf_default_context_leaks();
    $vrf->_vrf_record_walk( $name, 'vrf_l3vpn_if' );
    return $vrf->_vrf_membership();
}

# Drops the rows whose port is not in the instance. The membership walk
# decides ownership, so it counts toward the read.
sub _vrf_keep_owned {
    my ( $vrf, $rows, $name ) = @_;

    $vrf->_vrf_record_walk( $name, 'vrf_l3vpn_if' );
    $vrf->_vrf_record_walk( $name, $vrf->_vrf_vendor_membership_methods() );
    my $members = $vrf->i_vrf();
    foreach my $key ( keys %$rows ) {
        my $owner = _vrf_owner_of( $members, $rows->{$key}{ifindex} );
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
        ? $vrf->_vrf_context_route_subnets($name)
        : $vrf->_vrf_attributed_route_subnets($name);
    foreach my $route (@$routes) {
        next
            if _vrf_special_purpose($route)
            and !_vrf_has_subnet( \%subnets, $route );
        _vrf_add_subnet( \%subnets, $route, 'route' );
    }
    return \%subnets;
}

# 1 unless a table a reader walked for $name in this session is known to be
# incomplete; an absent table is complete
sub vrf_read_complete {
    my $vrf  = shift;
    my $name = shift;

    my $walked = defined $name ? $vrf->{_vrf_walked}{$name} : undef;
    foreach my $method ( keys %{ $walked || {} } ) {
        my $status = $vrf->walk_status($method) or next;
        return 0 unless $status->{complete};
    }
    return 0 if $walked and $vrf->_vrf_leak_unfiltered($name);
    return 1;
}

# True in the default context of a class whose default context leaks while
# a listed instance is one the membership table does not cover, such as a
# virtual router: its rows cannot be told from the default instance's. A
# partial list walk may hide such an instance. An MPLS-listed VRF with no
# port has no row to leak.
sub _vrf_leak_unfiltered {
    my $vrf  = shift;
    my $name = shift;

    return 0 unless $name eq 'default' and $vrf->_vrf_default_context_leaks();
    return 0 if length $vrf->_walk_context();
    my $instances = $vrf->{_vrf_instances} ||= $vrf->_vrf_all_instances();
    return 1 if $vrf->_vrf_walk_incomplete();
    return ( grep { $_->{name} ne 'default' and _vrf_uncovered($_) }
            values %$instances ) ? 1 : 0;
}

sub _vrf_uncovered {
    my $record = shift;

    return 0 if $record->{sources}{members};
    return ( $record->{sources}{list} // q() ) ne $LIST_SOURCE ? 1 : 0;
}

sub _vrf_has_subnet {
    my ( $subnets, $subnet ) = @_;

    return exists $subnets->{"$subnet->{prefix}/$subnet->{len}"};
}

# Space no VRF routes to a neighbor: this and loopback networks, multicast,
# and limited broadcast for IPv4; unspecified and loopback, link-local and
# multicast for IPv6. A route-only subnet within it is not a VRF subnet.
my @SPECIAL_PURPOSE = (
    [ ipv4 => '0.0.0.0',            8 ],
    [ ipv4 => '127.0.0.0',          8 ],
    [ ipv4 => '224.0.0.0',          4 ],
    [ ipv4 => '255.255.255.255',    32 ],
    [ ipv6 => '0:0:0:0:0:0:0:0',    127 ],
    [ ipv6 => 'fe80:0:0:0:0:0:0:0', 10 ],
    [ ipv6 => 'ff00:0:0:0:0:0:0:0', 8 ],
);

sub _vrf_special_purpose {
    my $subnet = shift;

    my $bits = unpack 'B*', pack 'C*',
        _vrf_ip_octets( $subnet->{family}, $subnet->{prefix} );
    foreach my $special (@SPECIAL_PURPOSE) {
        my ( $family, $address, $length ) = @$special;
        next if $family ne $subnet->{family} or $subnet->{len} < $length;
        my $special_bits = unpack 'B*', pack 'C*',
            _vrf_ip_octets( $family, $address );
        return 1
            if substr( $bits, 0, $length ) eq
            substr( $special_bits, 0, $length );
    }
    return 0;
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

    if ( $family eq 'ipv4' ) {
        my @octets = split /\./, $ip;
        return @octets == 4 ? @octets : ();
    }
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

    my $protos = $vrf->_vrf_column( 'vrf_l3vpn_rte_proto', $name );
    my $ifs    = $vrf->_vrf_column( 'vrf_l3vpn_rte_if',    $name );
    my @subnets;
    foreach my $iid ( sort keys %$protos ) {
        next unless _vrf_connected_proto( $protos->{$iid} );
        my ( $route_name, @arcs ) = $vrf->_vrf_decode_instance($iid);
        next if !defined $route_name or $route_name ne $name;
        my $subnet = _vrf_route_subnet(@arcs) or next;
        $subnet->{ifindex} = _vrf_route_ifindex( $ifs->{$iid} );
        push @subnets, $subnet;
    }
    return \@subnets;
}

# Connected routes of inetCidrRouteTable, which has no name in its index
sub _vrf_context_route_subnets {
    my $vrf  = shift;
    my $name = shift;

    my $protos = $vrf->_vrf_column( 'vrf_cidr_proto', $name );
    my $ifs    = $vrf->_vrf_column( 'vrf_cidr_if',    $name );
    my $leaked = $vrf->_vrf_leaked_ports($name);
    my @subnets;
    foreach my $iid ( sort keys %$protos ) {
        next unless $iid =~ /^\d+(?:\.\d+)*$/;
        next unless _vrf_connected_proto( $protos->{$iid} );
        my $subnet = _vrf_route_subnet( split /\./, $iid ) or next;
        $subnet->{ifindex} = _vrf_route_ifindex( $ifs->{$iid} );
        next
            if defined $subnet->{ifindex}
            and exists $leaked->{ $subnet->{ifindex} };
        push @subnets, $subnet;
    }
    return \@subnets;
}

# InterfaceIndexOrZero: 0 means the route has no interface
sub _vrf_route_ifindex {
    my $ifindex = shift;

    return ( defined $ifindex and $ifindex ne '0' ) ? $ifindex : undef;
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
    my $vrf  = shift;
    my $name = shift;

    my $rows = $vrf->_vrf_inet_address_rows($name);
    return $rows if grep { $_->{family} eq 'ipv4' } values %$rows;
    return { %$rows, %{ $vrf->_vrf_ipadent_rows($name) } };
}

# Index is type, length, address octets; types 3 and 4 end with four zone
# octets that are not part of the address. Two rows on one port that differ
# only by zone are one address: the row first in sorted index order is
# kept, so the choice does not depend on hash order.
sub _vrf_inet_address_rows {
    my $vrf  = shift;
    my $name = shift;

    my $ifindexes = $vrf->_vrf_column( 'new_ip_index',  $name );
    my $types     = $vrf->_vrf_column( 'new_ip_type',   $name );
    my $prefixes  = $vrf->_vrf_column( 'new_ip_prefix', $name );

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
    my $vrf  = shift;
    my $name = shift;

    my $ifindexes = $vrf->_vrf_column( 'old_ip_index',   $name );
    my $masks     = $vrf->_vrf_column( 'old_ip_netmask', $name );

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
    return 1 if exists $instances->{$name};

    my $method = ( caller(1) )[3];
    $vrf->error_throw( "$method() reads instance '$name', which is not in"
            . " vrf_instances() on this device. In attribution mode the"
            . " readers take only names the device lists; a name passed to"
            . " vrf_instances() is not one. Pass a key of vrf_instances().\n"
    );
    return 0;
}

# A method the class does not have contributes no rows. The read of $name
# records the tables walked, which are @walked when the method is a sub
# over other columns.
sub _vrf_column {
    my ( $vrf, $method, $name, @walked ) = @_;

    return {} unless $vrf->can($method);
    $vrf->_vrf_record_walk( $name, @walked ? @walked : $method );
    return $vrf->$method() || {};
}

# clear_cache, and so update(), empties the record with the cache
sub _vrf_record_walk {
    my ( $vrf, $name, @methods ) = @_;

    $vrf->{_vrf_walked}{$name}{$_} = 1 for @methods;
    return;
}

sub _vrf_arp_rows {
    my $vrf  = shift;
    my $name = shift;

    my $macs = $vrf->_vrf_column( 'at_paddr',   $name, @ARP_PADDR_COLUMNS );
    my $ips  = $vrf->_vrf_column( 'at_netaddr', $name, @ARP_NETADDR_COLUMNS );
    my $local = $vrf->_vrf_local_arp_keys($name);
    my %rows;
    foreach my $key ( keys %$macs ) {
        my ($ifindex) = $key =~ /^(\d+)\./ or next;
        next unless defined $ips->{$key} and _vrf_has_mac( $macs->{$key} );
        next if $local->{$key};
        $rows{$key} = {
            ifindex => $ifindex,
            ip      => $ips->{$key},
            mac     => $macs->{$key},
            family  => 'ipv4',
        };
    }
    return \%rows;
}

# { ifIndex.address => 1 } for each IPv4 row ipNetToPhysicalTable types
# local(5), keyed as at_paddr() keys its rows
sub _vrf_local_arp_keys {
    my $vrf  = shift;
    my $name = shift;

    my $types = $vrf->_vrf_column( 'ip_n2p_phys_type', $name );
    my %local;
    foreach my $iid ( keys %$types ) {
        next unless _vrf_is_local( $types->{$iid}, 5 );
        my ( $ifindex, $addr_type, @octets ) = split /\./, $iid;
        next unless defined $addr_type and $addr_type == 1;
        shift @octets if @octets == 5 and $octets[0] == 4;
        $local{ join q{.}, $ifindex, @octets } = 1 if @octets == 4;
    }
    return \%local;
}

sub _vrf_nd_rows {
    my $vrf  = shift;
    my $name = shift;

    my $macs  = $vrf->_vrf_column( 'ipv6_n2p_mac',  $name, @ND_COLUMNS );
    my $ips   = $vrf->_vrf_column( 'ipv6_n2p_addr', $name, @ND_COLUMNS );
    my $ifs   = $vrf->_vrf_column( 'ipv6_n2p_if',   $name, @ND_COLUMNS );
    my $types = $vrf->_vrf_column( 'ipv6_n2p_type', $name, @ND_TYPE_COLUMNS );
    my %rows;
    foreach my $key ( keys %$macs ) {
        next unless defined $ips->{$key} and defined $ifs->{$key};
        next unless _vrf_has_mac( $macs->{$key} );
        next if _vrf_is_local( $types->{$key}, _vrf_nd_local_number($key) );
        $rows{$key} = {
            ifindex => $ifs->{$key},
            ip      => $ips->{$key},
            mac     => $macs->{$key},
            family  => 'ipv6',
        };
    }
    $vrf->_vrf_add_ipv6_mib_rows( \%rows, $name )
        if $vrf->_vrf_nd_from_ipv6_mib();
    return \%rows;
}

# ipv6NetToMediaTable rows, indexed ifIndex then 16 address octets, for
# the (port, address) pairs the IP-MIB rows lack
sub _vrf_add_ipv6_mib_rows {
    my ( $vrf, $rows, $name ) = @_;

    my %listed = map { "$_->{ifindex} " . lc $_->{ip} => 1 } values %$rows;
    my $macs   = $vrf->_vrf_column( 'i6_n2p_phys_addr', $name );
    my $types  = $vrf->_vrf_column( 'i6_n2p_phys_type', $name );
    foreach my $key ( keys %$macs ) {
        my ( $ifindex, @octets ) = split /\./, $key;
        next if @octets != 16 or grep { $_ > 255 } @octets;
        next unless _vrf_has_mac( $macs->{$key} );
        next if _vrf_is_local( $types->{$key}, 4 );
        my $ip = join q{:}, unpack '(H4)*', pack 'C*', @octets;
        next if $listed{"$ifindex $ip"};
        $rows->{$key} = {
            ifindex => $ifindex,
            ip      => $ip,
            mac     => substr( $macs->{$key}, 0, 17 ),
            family  => 'ipv6',
        };
    }
    return;
}

# An undef, empty or all-zero MAC is no hardware address: the device
# serves its own addresses that way
sub _vrf_has_mac {
    my $mac = shift;

    return ( defined $mac and $mac =~ /[^0:.\-]/ ) ? 1 : 0;
}

# A neighbor type of local is the device's own address. The number is
# local(5) in IP-MIB and CISCO-IETF-IP-MIB, local(4) in IPV6-MIB, where 4
# is static in the others.
sub _vrf_is_local {
    my ( $type, $local_number ) = @_;

    return 0 unless defined $type;
    return ( $type eq 'local' or $type eq $local_number ) ? 1 : 0;
}

# ipv6_n2p_type() keys: ifIndex then sixteen octets from IPV6-MIB, a
# longer InetAddress index from the others
sub _vrf_nd_local_number {
    my $key = shift;

    my @arcs = split /\./, $key;
    return @arcs == 17 ? 4 : 5;
}

sub _vrf_context_filters { return 0; }

# True where the default context also serves other instances' rows on their
# ports, which only the default context's membership tables can name
sub _vrf_default_context_leaks { return 0; }

# True where host link-locals are only in IPV6-MIB ipv6NetToMediaTable
sub _vrf_nd_from_ipv6_mib { return 0; }

# { name => record } a vendor MIB lists where MPLS-L3VPN-STD-MIB serves
# none; records come from _vrf_record with sources->{list} set.
sub _vrf_vendor_instances { return {}; }

# The table methods _vrf_vendor_instances walks, for walk completeness
sub _vrf_vendor_list_methods { return (); }

# { ifIndex => name } the vendor MIB holds, used only when the vendor list
# was used; the tables it walks are named by _vrf_vendor_membership_methods
sub _vrf_vendor_membership { return {}; }

sub _vrf_vendor_membership_methods {
    my $vrf = shift;

    return $vrf->_vrf_vendor_listed() ? $vrf->_vrf_vendor_list_methods() : ();
}

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
    return $vrf->_vrf_in_own_context( $method, $name, $context )
        if $vrf->_vrf_context_filters();

    return 1 unless length $context;
    $vrf->error_throw( "$method() reads instance '$name' from the default"
            . " context, attributing rows by port, on this device."
            . " This session is in context '$context'. Call update()"
            . " back to the default context first.\n" );
    return 0;
}

# Context mode: each instance reads only in its own context, which for
# default is the default context
sub _vrf_in_own_context {
    my ( $vrf, $method, $name, $context ) = @_;

    return 1 if $name eq 'default' and !length $context;
    if ( $name eq 'default' ) {
        $vrf->error_throw( "$method() reads instance 'default' from the"
                . " default context on this device. This session is in"
                . " context '$context'. Call update() back to the default"
                . " context first.\n" );
        return 0;
    }
    if ( !length $context ) {
        $vrf->error_throw(
                  "$method() reads instance '$name' from its own context on"
                . " this device, but this session is in the default context."
                . " Switch with snmp_context('vrf', '$name') first.\n" );
        return 0;
    }

    return 1 if grep { $_ eq $context } $vrf->_vrf_contexts_of($name);
    $vrf->error_throw( "$method() reads instance '$name' from its own"
            . " context, but this session is in context '$context'."
            . " Switch with snmp_context('vrf', '$name') first.\n" );
    return 0;
}

# A port the membership table does not list belongs to the global table;
# with no membership hash the owner is unknown
sub _vrf_owner_of {
    my ( $members, $ifindex ) = @_;

    return unless $members;
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

    # Let SNMP::Info determine the correct subclass for you.
    my $vrf = new SNMP::Info(
        AutoSpecify => 1,
        Debug       => 1,
        DestHost    => 'myrouter',
        Community   => 'public',
        Version     => 2
    ) or die "Can't connect to DestHost.\n";

    my $instances = $vrf->vrf_instances();
    foreach my $name ( sort keys %$instances ) {
        my $subnets = $vrf->vrf_subnets($name);
        print "$name: $_\n" foreach sort keys %$subnets;
    }

=head1 DESCRIPTION

SNMP::Info::VRF is a role that reports the VRF instances a device serves
in F<MPLS-L3VPN-STD-MIB>, which ports belong to each, and each instance's
neighbors, interface addresses and subnets. The global routing table is
always the instance C<default>, of kind C<default>; a served row named
C<default> is that same instance, not a second one.

The role reports only what the device serves. It never infers an instance
the device did not list, except names the caller passes to
C<vrf_instances()>, which are marked as such. Data the device does not
serve is undef or a missing key, never a guessed value.

This class is inherited by L<SNMP::Info::Layer3>.

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item F<MPLS-L3VPN-STD-MIB>

=item F<IP-FORWARD-MIB>

=back

=head2 Records

C<vrf_instances()> returns one record per instance, keyed by name:

    red => {
        name        => 'red',
        kind        => 'vrf',            # 'default' for the global table
        description => undef,            # an empty served string is undef
        oper        => 'up',             # mplsL3VpnVrfOperStatus, or undef
        rd          => '64512:30',       # undef when empty or 0:0
        rt_import   => [ '64512:30' ],   # [] when none is served
        rt_export   => [ '64512:30' ],
        l3_vni      => undef,            # filled by vendor classes
        l3_isid     => undef,
        listed_by   => 'device',         # or 'caller'
        sources     => {                 # one key per fact served
            list    => 'MPLS-L3VPN-STD-MIB',
            members => 'MPLS-L3VPN-STD-MIB',   # when it has ports
            rd      => 'MPLS-L3VPN-STD-MIB',   # when rd is defined
            rt      => 'MPLS-L3VPN-STD-MIB',   # when it has a target
        },
        contexts    => [ { kind => 'none' } ],
    }

C<i_vrf()> maps ifIndex to instance name. Ports of the instance
C<default> are absent.

    { 2 => 'red', 3 => 'blue' }

C<vrf_neighbors($name)> and C<vrf_addresses($name)> key their rows by
ifIndex then address, so an address two instances share keeps one row in
each. One instance can also hold the same address on several ports, as
with link-local addresses, so key rows by ifIndex and address, never by
address alone:

    # vrf_neighbors('red')
    '2.10.40.0.2' => { ifindex => 2, ip => '10.40.0.2',
                       mac => '02:00:00:00:04:01', family => 'ipv4' }

    # vrf_addresses('blue')
    '3.10.40.0.1' => { ifindex => 3, ip => '10.40.0.1',
                       prefix_len => 24, family => 'ipv4' }

C<vrf_subnets($name)> keys its rows by prefix and length:

    '10.40.0.0/24' => { prefix => '10.40.0.0', len => 24,
                        family => 'ipv4', ifindex => 3,
                        sources => [ 'address' ] }   # and/or 'route'

IPv6 addresses are in the form C<ipv6_n2p_addr()> in L<SNMP::Info::IPv6>
returns, without any zone.

=head2 Reading Instances

The per-instance readers work in one of two modes, fixed by the device
class.

In attribution mode, the mode of this class, the default context serves
every instance's rows in one table, and the readers sort the rows by port
through C<i_vrf()>. The caller never switches contexts:

    my $instances = $vrf->vrf_instances();
    my $complete  = $vrf->vrf_instances_complete();
    my $ports     = $vrf->i_vrf();
    foreach my $name ( sort keys %$instances ) {
        my $neighbors = $vrf->vrf_neighbors($name);
        my $addresses = $vrf->vrf_addresses($name);
        my $subnets   = $vrf->vrf_subnets($name);
        my $whole     = $vrf->vrf_read_complete($name);
    }

In context mode, the device class's agent serves each instance's
address rows only in that instance's own context, and the caller switches
to the instance's context before calling the readers. A context can still
serve other instances' rows, such as neighbors on their ports, so the
readers keep only the rows on ports holding an address in the current
context's C<ipAddressTable> or C<ipAdEntTable>. C<i_vrf()> maps those
ports to the instance whose context the session is in, or to C<default>
in the default context. The instance list is still read in the default
context, and kept across the switches, since C<update()> clears the cache:

    my $instances = $vrf->vrf_instances();
    foreach my $name ( sort keys %$instances ) {
        my $context = $instances->{$name}{contexts}[0];
        # switch to $context->{v3} unless $name is default, then update()
        my $neighbors = $vrf->vrf_neighbors($name);
        my $whole     = $vrf->vrf_read_complete($name);
    }

A port with no address in its context, such as an unnumbered one, is in
no instance in context mode, and its neighbors are dropped.

On some platforms the default context leaks: it serves every instance's
neighbors and addresses on the instances' ports, alongside the default
instance's own. A class for such a platform has the readers of
C<default>, in the default context, drop the rows on each port that the
default context's membership table, C<mplsL3VpnIfConfTable>, gives
another instance, and C<i_vrf()> there returns that membership. An
instance the table does not cover, one listed by another source such as
a virtual router, cannot be told apart there, so its rows stay in
C<default> and C<vrf_read_complete('default')> returns 0. A VRF the
table lists with no port has no rows to leak. L<SNMP::Info::Layer3::Juniper>
is such a class.

Some platforms serve host link-local neighbors only in the F<IPV6-MIB>
C<ipv6NetToMediaTable>, not in C<ipNetToPhysicalTable>. A class for such a
platform adds those rows to C<vrf_neighbors()>, one per port and address,
keeping the C<ipNetToPhysicalTable> row where both tables list one.

A caller tells the modes apart from each instance's C<contexts>. It is
C<< [ { kind => 'none' } ] >>, the default context, in attribution mode.
In context mode it lists the instance's own contexts, each as
L<SNMP::Info/"snmp_context"> describes it.

A reader called in the wrong context for the mode returns nothing, with
C<error()> set to a message saying how to switch. In context mode the
session's context must be the instance's own, as C<snmp_context('vrf',
$name)> names it, and for the instance C<default> the default context.

=head2 Completeness

C<vrf_instances_complete()> separates four states:

=over

=item unsupported, undef

The device serves no VRF list and the caller named no instance.
C<vrf_instances()> lists only C<default>.

=item none, 1

The device reports zero configured VRFs. C<vrf_instances()> lists only
C<default>.

=item incomplete, 0

The list may be short: it holds a name from the caller, a walk of the VRF,
route target or membership table ended early, the device configures more
VRFs than it lists, or it lists VRFs but cannot say which ports they hold.

=item complete, 1

The list is whole as far as F<MPLS-L3VPN-STD-MIB> lists instances.

=back

Completeness measures F<MPLS-L3VPN-STD-MIB> only. Some platforms hold
layer 3 instances that MIB does not list, such as virtual routers. Unless
the class lists them from another source, those instances are absent from
C<vrf_instances()>, their ports are absent from C<i_vrf()>, and their rows
are read as the instance C<default>, even when C<vrf_instances_complete()>
returns 1. A class whose default context leaks, as L</"Reading Instances">
describes, reports that through C<vrf_read_complete('default')>.

C<vrf_read_complete($name)> says whether the readers saw the whole of the
tables they walked for C<$name>.

=head2 Collapsed Subnets

Some devices keep an address that two instances share on only one of the
ports in C<ipAddressTable> and C<ipAdEntTable>. The other instance then
has no such address, and C<vrf_subnets()> omits its subnet, unless the
class reads routes. A class that reads routes takes each instance's
connected routes from C<mplsL3VpnVrfRteTable> in attribution mode, or
C<inetCidrRouteTable> in context mode, and lists them with the source
C<route>, which restores the subnet. This class does not read routes.

=head1 GLOBALS

=over

=item $vrf->vrf_configured()

Returns the number of VRFs the device says it configures.

(C<mplsL3VpnConfiguredVrfs>)

=back

=head1 TABLE METHODS

=head2 VRF Instances

These methods read the default context only. In any other context they
return nothing, with C<error()> set, since only the default context serves
the whole list. C<i_vrf()> in context mode is the exception, as described
below.

=over

=item $vrf->vrf_instances( [ \@names ] )

Returns reference to hash of instance records, keyed by name, always
including C<default>. See L</"Records">.

The names in C<\@names> are used only when the device serves no VRF row,
whatever count of configured VRFs it serves. Each is added with
C<listed_by> C<caller> and no C<sources>, and C<vrf_instances_complete()>
then returns 0. When the device lists instances, the names are ignored.
The instance readers take caller names in context mode only; in
attribution mode they return nothing for one, with C<error()> set.

=item $vrf->vrf_instances_complete( [ \@names ] )

Returns 1, 0 or undef, as L</"Completeness"> describes. Pass the same
names given to C<vrf_instances()>.

=item $vrf->i_vrf()

Returns reference to hash of instance name, keyed by ifIndex, from the
active rows of C<mplsL3VpnIfConfTable>. Ports of the instance C<default>
are absent.

In context mode it works in any context. It maps each port holding an
address in the current context's C<ipAddressTable> or C<ipAdEntTable> to
the instance whose context the session is in, or to C<default> in the
default context. In the default context of a class whose default context
leaks, it is the C<mplsL3VpnIfConfTable> membership instead. It returns
nothing, with C<error()> set, in a context no listed instance has.

(C<mplsL3VpnIfConfRowStatus>, or a class's vendor table when
C<MPLS-L3VPN-STD-MIB> lists no instance, such as
L<SNMP::Info::Layer3::Cisco>'s C<cvVrfInterfaceRowStatus>; in context mode
C<ipAddressIfIndex>, C<ipAdEntIfIndex>)

=back

=head2 Instance Readers

Each reader takes an instance name and returns nothing for a name the
device does not list (in attribution mode), or when the session is in the
wrong context, with C<error()> set; see L</"Reading Instances">. A class
with no source table for a reader contributes no rows to it.

=over

=item $vrf->vrf_neighbors($name)

Returns reference to hash of the ARP and IPv6 neighbor rows of instance
C<$name>, keyed as C<at_paddr()> and C<ipv6_n2p_mac()> key them. Each row
holds C<ifindex>, C<ip>, C<mac> and C<family> (C<ipv4> or C<ipv6>). A row
whose MAC is undef, empty or all zeros is not returned: it names no
hardware address, and devices serve their own addresses that way. Rows a
class adds from C<ipv6NetToMediaTable> are keyed by ifIndex then the
sixteen address octets, as that table indexes them.

Rows that are the instance's own addresses are not returned either: a
row whose neighbor type is local (C<ipNetToPhysicalType> local(5),
C<ipv6NetToMediaType> local(4)), a global address that
C<vrf_addresses($name)> holds on any port, and a link-local address it
holds on the row's port. The devices seen serve their own IPv4 rows as
static, not local, so the address match is what drops those. On a device
that lists an address two instances share on one port only (see
L</"Collapsed Subnets">), the other instance's own row is kept.

(C<at_paddr()> and C<at_netaddr()>, with the fallbacks to C<atTable> and
C<ipNetToPhysicalTable> of L<SNMP::Info::Layer3>, the C<ipv6_n2p_*>
methods of L<SNMP::Info::IPv6>, C<ipNetToPhysicalType>,
C<ipv6NetToMediaPhysAddress> and C<ipv6NetToMediaType> where the class
reads them, and C<vrf_addresses()>)

=item $vrf->vrf_addresses($name)

Returns reference to hash of the interface addresses of instance
C<$name>, keyed by ifIndex and address. Each row holds C<ifindex>, C<ip>,
C<prefix_len> (undef when the device gives none) and C<family>. Two rows
on one port that differ only by zone are one address: the row first in
sorted index order is kept. C<ipAdEntTable> is read for IPv4 only when
C<ipAddressTable> serves no IPv4 row.

(C<ipAddressIfIndex>, C<ipAddressType>, C<ipAddressPrefix>,
C<ipAdEntIfIndex>, C<ipAdEntNetMask>)

=item $vrf->vrf_subnets($name)

Returns reference to hash of the subnets of instance C<$name>, keyed
C<prefix/len>. Each holds C<prefix>, C<len>, C<family>, C<ifindex> and
C<sources>: C<address> for the network of an interface address that has a
prefix length, C<route> for a connected route, C<address> first when both
apply. Host routes are not subnets, and neither is a route-only prefix in
special-purpose space: IPv4 C<0.0.0.0/8>, C<127.0.0.0/8>, C<224.0.0.0/4>
and C<255.255.255.255/32>, IPv6 C<::/127>, C<fe80::/10> and C<ff00::/8>.
An interface address in that space is kept. C<ifindex> is undef for a route
with no interface. See L</"Collapsed Subnets">.

(C<vrf_addresses()>, C<mplsL3VpnVrfRteInetCidrProto>,
C<mplsL3VpnVrfRteInetCidrIfIndex>, C<inetCidrRouteProto>,
C<inetCidrRouteIfIndex>)

=item $vrf->vrf_read_complete($name)

Returns 0 when a table a reader walked for C<$name> has an incomplete
C<walk_status()> (see L<SNMP::Info/"Incomplete Walks">), otherwise 1. A
table the device does not implement counts as complete. In attribution
mode the membership table C<mplsL3VpnIfConfTable> counts too, since it
decides which rows are the instance's; in context mode the address tables
do, and for C<default> in a leaking default context the membership table
as well. There it also returns 0 while a listed instance is one the
membership table does not cover, since its rows cannot be told from
C<default>'s, and while a walk of the instance list was incomplete, since
it may hide such an instance.

Call it after the readers, in the same context. C<clear_cache()>, and so
C<update()>, forgets which tables were walked, after which it returns 1
until a reader runs again.

=back

=head2 MPLS-L3VPN VRF Table (C<mplsL3VpnVrfTable>)

=over

=item $vrf->vrf_l3vpn_descr()

(C<mplsL3VpnVrfDescription>)

=item $vrf->vrf_l3vpn_rd()

(C<mplsL3VpnVrfRD>)

=item $vrf->vrf_l3vpn_oper()

(C<mplsL3VpnVrfOperStatus>)

=back

=head2 MPLS-L3VPN Interface Table (C<mplsL3VpnIfConfTable>)

=over

=item $vrf->vrf_l3vpn_if()

(C<mplsL3VpnIfConfRowStatus>)

=back

=head2 MPLS-L3VPN Route Target Table (C<mplsL3VpnVrfRTTable>)

=over

=item $vrf->vrf_l3vpn_rt()

(C<mplsL3VpnVrfRT>)

=back

=head2 MPLS-L3VPN VRF Route Table (C<mplsL3VpnVrfRteTable>)

=over

=item $vrf->vrf_l3vpn_rte_if()

(C<mplsL3VpnVrfRteInetCidrIfIndex>)

=item $vrf->vrf_l3vpn_rte_proto()

(C<mplsL3VpnVrfRteInetCidrProto>)

=back

=head2 IP Forwarding Table (C<inetCidrRouteTable>)

Read only in context mode.

=over

=item $vrf->vrf_cidr_if()

(C<inetCidrRouteIfIndex>)

=item $vrf->vrf_cidr_proto()

(C<inetCidrRouteProto>)

=back

=cut
