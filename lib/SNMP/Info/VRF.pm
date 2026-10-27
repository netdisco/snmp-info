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

sub _vrf_context_filters { return 0; }

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
