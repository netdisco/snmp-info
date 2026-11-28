# SNMP::Info::IEEE802_STP
#
# Copyright (c) 2026 SNMP::Info Developers
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

package SNMP::Info::IEEE802_STP;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Bridge;

@SNMP::Info::IEEE802_STP::ISA       = qw/SNMP::Info::Bridge Exporter/;
@SNMP::Info::IEEE802_STP::EXPORT_OK = qw//;

our ( $VERSION, $DEBUG, %MIBS, %FUNCS, %GLOBALS, %MUNGE, $INIT );

$VERSION = '3.985005';

%MIBS = (
    %SNMP::Info::Bridge::MIBS,
    'IEEE8021-SPANNING-TREE-MIB' => 'ieee8021SpanningTreeVersion',
    'IEEE8021-MSTP-MIB'          => 'ieee8021MstpCistBridgeIdentifier',
);

%GLOBALS = ( %SNMP::Info::Bridge::GLOBALS, );

%FUNCS = (
    %SNMP::Info::Bridge::FUNCS,

    # IEEE8021-SPANNING-TREE-MIB::ieee8021SpanningTreeTable
    'ieee_stp_version' => 'ieee8021SpanningTreeVersion',
    'ieee_stp_root'    => 'ieee8021SpanningTreeDesignatedRoot',

    # IEEE8021-SPANNING-TREE-MIB::ieee8021SpanningTreePortTable
    'ieee_stp_p_state'  => 'ieee8021SpanningTreePortState',
    'ieee_stp_p_enable' => 'ieee8021SpanningTreePortEnabled',
    'ieee_stp_p_bridge' => 'ieee8021SpanningTreePortDesignatedBridge',
    'ieee_stp_p_port'   => 'ieee8021SpanningTreePortDesignatedPort',

    # IEEE8021-SPANNING-TREE-MIB::ieee8021SpanningTreeRstpPortTable
    'ieee_rstp_p_edge_admin' => 'ieee8021SpanningTreeRstpPortAdminEdgePort',
    'ieee_rstp_p_edge_oper'  => 'ieee8021SpanningTreeRstpPortOperEdgePort',

    # IEEE8021-MSTP-MIB::ieee8021MstpCistTable
    'mstp_cist_bridge' => 'ieee8021MstpCistBridgeIdentifier',

    # IEEE8021-MSTP-MIB::ieee8021MstpCistPortTable
    'mstp_cist_p_role'       => 'ieee8021MstpCistPortRole',
    'mstp_cist_p_edge_admin' => 'ieee8021MstpCistPortAdminEdgePort',
    'mstp_cist_p_edge_oper'  => 'ieee8021MstpCistPortOperEdgePort',

    # IEEE8021-MSTP-MIB::ieee8021MstpTable
    'mstp_i_bridge' => 'ieee8021MstpBridgeId',
    'mstp_i_root'   => 'ieee8021MstpDesignatedRoot',

    # IEEE8021-MSTP-MIB::ieee8021MstpPortTable
    'mstp_p_state'  => 'ieee8021MstpPortState',
    'mstp_p_role'   => 'ieee8021MstpPortRole',
    'mstp_p_bridge' => 'ieee8021MstpPortDesignatedBridge',

    # IEEE8021-MSTP-MIB::ieee8021MstpVlanTable
    'mstp_vlan_msti' => 'ieee8021MstpVlanMstId',
);

%MUNGE = (
    %SNMP::Info::Bridge::MUNGE,
    'ieee_stp_root'     => \&SNMP::Info::munge_prio_mac,
    'ieee_stp_p_bridge' => \&SNMP::Info::munge_prio_mac,
    'ieee_stp_p_port'   => \&SNMP::Info::munge_prio_port,
    'mstp_cist_bridge'  => \&SNMP::Info::munge_prio_mac,
    'mstp_i_bridge'     => \&SNMP::Info::munge_prio_mac,
    'mstp_i_root'       => \&SNMP::Info::munge_prio_mac,
    'mstp_p_bridge'     => \&SNMP::Info::munge_prio_mac,
);

# Tables are indexed by component first; only the lowest one is read
sub _ieee_stp_component {
    my $stp = shift;

    foreach my $column (
        qw/ieee_stp_version mstp_cist_bridge
        mstp_cist_p_role/
        )
    {
        my $rows = $stp->$column() || {};
        my ($component)
            = sort { $a <=> $b } map { ( split /\./ )[0] } keys %$rows;
        return $component if defined $component;
    }
    return;
}

sub _ieee_stp_protocol {
    my $stp = shift;

    my $component = $stp->_ieee_stp_component();
    return unless defined $component;

    my $version = ( $stp->ieee_stp_version() || {} )->{$component};
    return unless defined $version;
    return 'stp'  if $version =~ /^(?:stp|0)$/;
    return 'rstp' if $version =~ /^(?:rstp|2)$/;
    return 'mstp' if $version =~ /^(?:mstp|3)$/;
    return;
}

sub _ieee_stp_measured { return 0; }

sub _ieee_stp_is_mstp {
    my $stp = shift;
    return ( $stp->_ieee_stp_protocol() || '' ) eq 'mstp';
}

sub hasSTP {
    my $stp = shift;
    return ( $stp->_ieee_stp_protocol() || '' ) eq 'stp' ? 1 : 0;
}

sub hasRSTP {
    my $stp = shift;
    return ( $stp->_ieee_stp_protocol() || '' ) eq 'rstp' ? 1 : 0;
}

sub hasMSTP {
    my $stp = shift;
    return $stp->_ieee_stp_is_mstp() ? 1 : 0;
}

sub stp_protocols {
    my $stp = shift;

    return $stp->SUPER::stp_protocols() unless $stp->_ieee_stp_is_mstp();
    return ['mstp'];
}

sub stp_trees {
    my $stp = shift;

    return unless $stp->_stp_default_context_ok();
    return $stp->{_stp_trees} if $stp->{_stp_trees};
    return $stp->SUPER::stp_trees() unless $stp->_ieee_stp_is_mstp();

    my $trees = $stp->_ieee_mstp_trees();
    $stp->{_stp_trees} = $trees if keys %$trees;
    return $trees;
}

sub _ieee_mstp_trees {
    my $stp = shift;

    my $component = $stp->_ieee_stp_component();
    return {} unless defined $component;
    my $bridges   = $stp->mstp_i_bridge() || {};
    my $roots     = $stp->mstp_i_root()   || {};
    my $cist_id   = ( $stp->mstp_cist_bridge() || {} )->{$component};
    my $cist_root = ( $stp->ieee_stp_root()    || {} )->{$component};

    my %ids;
    $ids{0} = [ $cist_id, $cist_root ]
        if defined $cist_id or defined $cist_root;
    foreach my $row ( keys %$bridges ) {
        my ( $row_component, $msti ) = split /\./, $row, 2;
        next unless $row_component == $component;
        $ids{$msti} = [ $bridges->{$row}, $roots->{$row} ];
    }

    my $incomplete = $stp->_ieee_mstp_incomplete_trees($component);
    my $measured   = $stp->_ieee_stp_measured();
    my %trees;
    foreach my $msti ( keys %ids ) {
        my ( $bridge, $root ) = @{ $ids{$msti} };
        my $unmapped = $incomplete->{all} || $incomplete->{$msti};
        $trees{ _ieee_mstp_tree_key($msti) } = {
            type           => $msti ? 'msti' : 'cist',
            id             => $msti + 0,
            protocol       => 'mstp',
            measured       => $measured,
            ports_complete => $unmapped ? 0 : 1,
            contexts       => [ { kind => 'none' } ],
            bridge         =>
                scalar SNMP::Info::Bridge::_stp_decode_bridge_id($bridge),
            root => scalar SNMP::Info::Bridge::_stp_decode_bridge_id($root),
        };
    }
    return \%trees;
}

sub _ieee_mstp_tree_key {
    my $msti = shift;
    return $msti ? "msti.$msti" : 'cist.0';
}

# { MSTI => 1 } for each tree with a port row on a bridge port bp_index
# lacks, and all => 1 when another component serves rows, since this role
# reads only the lowest
sub _ieee_mstp_incomplete_trees {
    my ( $stp, $component ) = @_;

    my $cist_ports = {
        %{ $stp->mstp_cist_p_role() || {} },
        %{ $stp->ieee_stp_p_state() || {} },
    };
    my $msti_ports = $stp->mstp_p_state() || {};
    my $bp_index   = $stp->bp_index()     || {};

    my @rows = (
        ( map { [ split /\./ ] } keys %$cist_ports ),
        ( map { [ ( split /\./ )[ 0, 2, 1 ] ] } keys %$msti_ports ),
    );

    my %incomplete;
    foreach my $row (@rows) {
        my ( $row_component, $port, $msti ) = @$row;
        $incomplete{all}          = 1 unless $row_component == $component;
        $incomplete{ $msti // 0 } = 1 unless defined $bp_index->{$port};
    }
    $incomplete{all} = 1 if $stp->_ieee_stp_other_component($component);
    return \%incomplete;
}

sub _ieee_stp_other_component {
    my ( $stp, $component ) = @_;

    my @rows = map { keys %{ $_ || {} } } $stp->ieee_stp_version(),
        $stp->mstp_cist_bridge(), $stp->mstp_i_bridge();
    return scalar grep { ( split /\./ )[0] != $component } @rows;
}

sub stp_tree_ports {
    my ( $stp, $tree_key ) = @_;

    return $stp->SUPER::stp_tree_ports($tree_key)
        unless $stp->_ieee_stp_is_mstp();

    my $tree = $stp->_stp_tree_for_key($tree_key) or return;
    return $tree->{type} eq 'cist'
        ? $stp->_ieee_mstp_cist_port_rows($tree)
        : $stp->_ieee_mstp_msti_port_rows($tree);
}

# Rows keyed by ifIndex, from the lowest component only
sub _ieee_mstp_cist_port_rows {
    my ( $stp, $tree ) = @_;

    my $component = $stp->_ieee_stp_component();
    my $states    = $stp->ieee_stp_p_state()  || {};
    my $roles     = $stp->mstp_cist_p_role()  || {};
    my $enable    = $stp->ieee_stp_p_enable() || {};
    my $d_bridge  = $stp->ieee_stp_p_bridge() || {};
    my $d_port    = $stp->ieee_stp_p_port()   || {};
    my $bp_index  = $stp->bp_index()          || {};

    my %rows;
    foreach my $index ( keys %{ +{ %$states, %$roles } } ) {
        my ( $row_component, $port ) = split /\./, $index, 2;
        next unless $row_component == $component;
        my $iid = $bp_index->{$port};
        next unless defined $iid;
        $rows{$iid} = {
            tree_type => $tree->{type},
            tree_id   => $tree->{id},
            state     => $states->{$index},
            role      => scalar _ieee_mstp_known_role( $roles->{$index} ),
            role_raw  => $roles->{$index},
            enabled   =>
                scalar SNMP::Info::Bridge::_stp_enabled( $enable->{$index} ),
            designated_bridge =>
                scalar SNMP::Info::Bridge::_stp_decode_bridge_id(
                $d_bridge->{$index}
                ),
            designated_port =>
                scalar SNMP::Info::Bridge::_stp_decode_port_id(
                $d_port->{$index} ),
        };
    }
    return \%rows;
}

sub _ieee_mstp_msti_port_rows {
    my ( $stp, $tree ) = @_;

    my $component = $stp->_ieee_stp_component();
    my $states    = $stp->mstp_p_state()      || {};
    my $roles     = $stp->mstp_p_role()       || {};
    my $d_bridge  = $stp->mstp_p_bridge()     || {};
    my $enable    = $stp->ieee_stp_p_enable() || {};
    my $bp_index  = $stp->bp_index()          || {};

    my %rows;
    foreach my $index ( keys %$states ) {
        my ( $row_component, $msti, $port ) = split /\./, $index, 3;
        next unless $row_component == $component and $msti == $tree->{id};
        my $iid = $bp_index->{$port};
        next unless defined $iid;
        $rows{$iid} = {
            tree_type => $tree->{type},
            tree_id   => $tree->{id},
            state     => $states->{$index},
            role      => scalar _ieee_mstp_known_role( $roles->{$index}, 1 ),
            role_raw  => $roles->{$index},
            enabled   => scalar SNMP::Info::Bridge::_stp_enabled(
                $enable->{"$component.$port"}
            ),
            designated_bridge =>
                scalar SNMP::Info::Bridge::_stp_decode_bridge_id(
                $d_bridge->{$index}
                ),
            designated_port => undef,
        };
    }
    return \%rows;
}

# The CIST column serves four roles; an MSTI row may serve any role the
# Bridge contract names
sub _ieee_mstp_known_role {
    my ( $role, $any_role ) = @_;
    return unless defined $role;
    my $known
        = $any_role
        ? qr/^(?:disabled|root|designated|alternate|backup|boundary|master)$/
        : qr/^(?:root|alternate|designated|backup)$/;
    return $role if $role =~ $known;
    return;
}

sub i_edgeport_admin {
    my ( $stp, $partial ) = @_;

    return $stp->_ieee_edge_ports( $partial, 'ieee_rstp_p_edge_admin',
        'mstp_cist_p_edge_admin' )
        || $stp->SUPER::i_edgeport_admin($partial);
}

sub i_edgeport_oper {
    my ( $stp, $partial ) = @_;

    return $stp->_ieee_edge_ports( $partial, 'ieee_rstp_p_edge_oper',
        'mstp_cist_p_edge_oper' )
        || $stp->SUPER::i_edgeport_oper($partial);
}

# First of the two columns with rows for the lowest component, as
# { ifIndex => 1|0 }; nothing when both are empty. Not gated on protocol.
sub _ieee_edge_ports {
    my ( $stp, $partial, @columns ) = @_;

    my $component = $stp->_ieee_stp_component();
    return unless defined $component;

    foreach my $column (@columns) {
        my $rows = $stp->$column() || {};
        my %by_port;
        foreach my $index ( keys %$rows ) {
            my ( $row_component, $port ) = split /\./, $index, 2;
            next unless $row_component == $component;
            $by_port{$port} = $rows->{$index};
        }
        next unless keys %by_port;
        return SNMP::Info::Bridge::_stp_edge_by_ifindex( $stp, \%by_port,
            $partial );
    }
    return;
}

sub stp_trees_complete {
    my $stp = shift;

    return $stp->SUPER::stp_trees_complete()
        unless $stp->_ieee_stp_is_mstp();

    my $trees = $stp->stp_trees() || {};
    return 0 unless keys %$trees;
    return 0
        if $stp->_stp_walk_incomplete(qw/mstp_i_bridge mstp_cist_p_role/);
    my $component = $stp->_ieee_stp_component();
    return 0 if $stp->_ieee_stp_other_component($component);
    return 1;
}

sub stp_vlan_map {
    my $stp = shift;

    return $stp->SUPER::stp_vlan_map() unless $stp->_ieee_stp_is_mstp();

    my $component = $stp->_ieee_stp_component();
    return unless defined $component;
    my $vlan_msti = $stp->mstp_vlan_msti() || {};
    my %map;
    foreach my $row ( keys %$vlan_msti ) {
        my ( $row_component, $vlan ) = split /\./, $row, 2;
        next unless $row_component == $component;
        $map{$vlan} = _ieee_mstp_tree_key( $vlan_msti->{$row} );
    }
    return unless keys %map;
    return \%map;
}

1;

__END__

=head1 NAME

SNMP::Info::IEEE802_STP - SNMP Interface to spanning tree data in the
F<IEEE8021-SPANNING-TREE-MIB> and F<IEEE8021-MSTP-MIB>

=head1 AUTHOR

SNMP::Info Developers

=head1 SYNOPSIS

 my $stp = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                         )
    or die "Can't connect to DestHost.\n";

 my $trees = $stp->stp_trees() || {};
 foreach my $key ( sort keys %$trees ) {
     my $root = $trees->{$key}{root} || {};
     print "$key root ", ( $root->{mac} // 'unknown' ), "\n";
 }

=head1 DESCRIPTION

A role for devices that serve the IEEE 802.1 spanning tree MIBs. It fills
the spanning tree API that L<SNMP::Info::Bridge> documents.

Trees are built only for MSTP, when C<ieee8021SpanningTreeVersion> reads
C<mstp>: the CIST from C<ieee8021MstpCistTable> and one MSTI per
C<ieee8021MstpTable> row. Under any other version the tree methods return
what L<SNMP::Info::Bridge> returns. C<hasSTP()>, C<hasRSTP()> and
C<hasMSTP()> report the served indicator whatever its value.

Every table is indexed by bridge component first. Only the lowest
component is read.

A device class that cannot trust the served version overrides the private
hooks C<_ieee_stp_protocol()>, which returns C<mstp>, C<rstp>, C<stp> or
nothing, and C<_ieee_stp_measured()>, which sets C<measured> in each tree
record and returns 0 here.

Create or use a subclass of SNMP::Info that inherits this class. Do not
use directly.

For debugging you can call new() directly as you would in SNMP::Info

 my $stp = new SNMP::Info::IEEE802_STP(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Bridge

=back

=head2 Required MIBs

=over

=item F<IEEE8021-SPANNING-TREE-MIB>

=item F<IEEE8021-MSTP-MIB>

=back

=head2 Inherited MIBs

See L<SNMP::Info::Bridge/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar values from SNMP.

=over

=item $stp->hasSTP()

Returns 1 when C<_ieee_stp_protocol()> reports C<stp>, else 0. That hook
reads C<ieee8021SpanningTreeVersion> by default, and a class may override
it.

=item $stp->hasRSTP()

Returns 1 when C<_ieee_stp_protocol()> reports C<rstp>, else 0. That hook
reads C<ieee8021SpanningTreeVersion> by default, and a class may override
it.

=item $stp->hasMSTP()

Returns 1 when C<_ieee_stp_protocol()> reports C<mstp>, else 0. That hook
reads C<ieee8021SpanningTreeVersion> by default, and a class may override
it.

=back

=head2 Global Methods imported from SNMP::Info::Bridge

See L<SNMP::Info::Bridge/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a
reference to a hash.

=head2 Overrides

=over

=item $stp->stp_protocols()

Returns C<['mstp']> under MSTP. Otherwise returns what
L<SNMP::Info::Bridge> returns.

=item $stp->stp_trees()

Under MSTP, returns reference to hash of tree records, in the form
L<SNMP::Info::Bridge> documents:

=over

=item C<cist.0>

C<bridge> from C<ieee8021MstpCistBridgeIdentifier>, C<root> from
C<ieee8021SpanningTreeDesignatedRoot>.

=item C<msti.N>

One per C<ieee8021MstpTable> row. C<bridge> from C<ieee8021MstpBridgeId>,
C<root> from C<ieee8021MstpDesignatedRoot>.

=back

C<ports_complete> is 0 when a port row of the tree is on a bridge port
missing from C<bp_index()>, or when a component other than the lowest
serves rows. Otherwise returns what L<SNMP::Info::Bridge> returns.

=item $stp->stp_tree_ports($tree_key)

Under MSTP, returns reference to hash of port rows keyed by ifIndex, in
the form L<SNMP::Info::Bridge> documents, for the tree C<$tree_key> names.
Sets C<error()> and returns nothing for a key C<stp_trees()> does not hold.
Otherwise returns what L<SNMP::Info::Bridge> returns.

=over

=item C<cist.0>

C<state> from C<ieee8021SpanningTreePortState>. C<role_raw> is
C<ieee8021MstpCistPortRole> as served, and C<role> is it when it is
C<root>, C<alternate>, C<designated> or C<backup>, else undef. C<enabled>
from C<ieee8021SpanningTreePortEnabled>, and the designated bridge and
port from C<ieee8021SpanningTreePortDesignatedBridge> and
C<ieee8021SpanningTreePortDesignatedPort>.

=item C<msti.N>

C<state> from C<ieee8021MstpPortState>, C<role> and C<role_raw> from
C<ieee8021MstpPortRole>, C<enabled> from the same port's
C<ieee8021SpanningTreePortEnabled>, and C<designated_bridge> from
C<ieee8021MstpPortDesignatedBridge>. C<designated_port> is undef, because
the MIB serves no usable value.

=back

=item $stp->i_edgeport_admin()

Returns reference to hash of ifIndex to 1 or 0, the configured edge port
setting, from C<ieee8021SpanningTreeRstpPortAdminEdgePort>, or from
C<ieee8021MstpCistPortAdminEdgePort> when that is empty. Returns what
L<SNMP::Info::Bridge> returns when both are empty. Does not depend on the
protocol.

=item $stp->i_edgeport_oper()

As C<i_edgeport_admin()>, for the operational state, from
C<ieee8021SpanningTreeRstpPortOperEdgePort> or
C<ieee8021MstpCistPortOperEdgePort>.

=item $stp->stp_trees_complete()

Under MSTP, returns 1 when C<stp_trees()> holds trees and the
C<ieee8021MstpTable> and C<ieee8021MstpCistPortTable> walks completed,
else 0. Otherwise returns what L<SNMP::Info::Bridge> returns.

=item $stp->stp_vlan_map()

Under MSTP, returns reference to hash of VLAN to tree key, C<cist.0> or
C<msti.N>, from C<ieee8021MstpVlanMstId>. Returns nothing when the column
is empty. Otherwise returns what L<SNMP::Info::Bridge> returns.

=back

=head2 Spanning Tree Table (C<ieee8021SpanningTreeTable>)

=over

=item $stp->ieee_stp_version()

Returns reference to hash. The spanning tree version by component.

(C<ieee8021SpanningTreeVersion>)

=item $stp->ieee_stp_root()

Returns reference to hash. The root bridge ID by component.

(C<ieee8021SpanningTreeDesignatedRoot>)

=back

=head2 Spanning Tree Port Table (C<ieee8021SpanningTreePortTable>)

=over

=item $stp->ieee_stp_p_state()

Returns reference to hash. The port state.

(C<ieee8021SpanningTreePortState>)

=item $stp->ieee_stp_p_enable()

Returns reference to hash. Whether spanning tree is enabled on the port.

(C<ieee8021SpanningTreePortEnabled>)

=item $stp->ieee_stp_p_bridge()

Returns reference to hash. The designated bridge ID.

(C<ieee8021SpanningTreePortDesignatedBridge>)

=item $stp->ieee_stp_p_port()

Returns reference to hash. The designated port ID.

(C<ieee8021SpanningTreePortDesignatedPort>)

=back

=head2 RSTP Port Table (C<ieee8021SpanningTreeRstpPortTable>)

=over

=item $stp->ieee_rstp_p_edge_admin()

Returns reference to hash. The configured edge port setting.

(C<ieee8021SpanningTreeRstpPortAdminEdgePort>)

=item $stp->ieee_rstp_p_edge_oper()

Returns reference to hash. The operational edge port state.

(C<ieee8021SpanningTreeRstpPortOperEdgePort>)

=back

=head2 MSTP CIST Table (C<ieee8021MstpCistTable>)

=over

=item $stp->mstp_cist_bridge()

Returns reference to hash. The CIST bridge ID by component.

(C<ieee8021MstpCistBridgeIdentifier>)

=back

=head2 MSTP CIST Port Table (C<ieee8021MstpCistPortTable>)

=over

=item $stp->mstp_cist_p_role()

Returns reference to hash. The CIST port role.

(C<ieee8021MstpCistPortRole>)

=item $stp->mstp_cist_p_edge_admin()

Returns reference to hash. The configured edge port setting.

(C<ieee8021MstpCistPortAdminEdgePort>)

=item $stp->mstp_cist_p_edge_oper()

Returns reference to hash. The operational edge port state.

(C<ieee8021MstpCistPortOperEdgePort>)

=back

=head2 MSTP Table (C<ieee8021MstpTable>)

=over

=item $stp->mstp_i_bridge()

Returns reference to hash. The MSTI bridge ID, keyed by component and
MSTI.

(C<ieee8021MstpBridgeId>)

=item $stp->mstp_i_root()

Returns reference to hash. The MSTI root bridge ID, keyed by component
and MSTI.

(C<ieee8021MstpDesignatedRoot>)

=back

=head2 MSTP Port Table (C<ieee8021MstpPortTable>)

=over

=item $stp->mstp_p_state()

Returns reference to hash. The port state, keyed by component, MSTI and
port.

(C<ieee8021MstpPortState>)

=item $stp->mstp_p_role()

Returns reference to hash. The port role, keyed by component, MSTI and
port.

(C<ieee8021MstpPortRole>)

=item $stp->mstp_p_bridge()

Returns reference to hash. The designated bridge ID, keyed by component,
MSTI and port.

(C<ieee8021MstpPortDesignatedBridge>)

=back

=head2 MSTP VLAN Table (C<ieee8021MstpVlanTable>)

=over

=item $stp->mstp_vlan_msti()

Returns reference to hash. The MSTI each VLAN maps to, 0 for the CIST,
keyed by component and VLAN.

(C<ieee8021MstpVlanMstId>)

=back

=head2 Table Methods imported from SNMP::Info::Bridge

See L<SNMP::Info::Bridge/"TABLE METHODS"> for details.

=cut
