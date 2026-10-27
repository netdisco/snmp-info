# SNMP::Info::Bridge
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

package SNMP::Info::Bridge;

use strict;
use warnings;
use Exporter;
use SNMP::Info;

@SNMP::Info::Bridge::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::Bridge::EXPORT_OK = qw//;

our ($VERSION, $DEBUG, %MIBS, %FUNCS, %GLOBALS, %MUNGE, $INIT);

$VERSION = '3.983000';

%MIBS = (
    'BRIDGE-MIB'   => 'dot1dBaseBridgeAddress',
    'Q-BRIDGE-MIB' => 'dot1qPvid',
    'RSTP-MIB'     => 'dot1dStpPortOperEdgePort',
);

%GLOBALS = (
    'b_mac'   => 'dot1dBaseBridgeAddress',
    'b_ports' => 'dot1dBaseNumPorts',
    'b_type'  => 'dot1dBaseType',

    # Spanning Tree Protocol
    'stp_ver'       => 'dot1dStpProtocolSpecification',
    'stp_time'      => 'dot1dStpTimeSinceTopologyChange',
    'stp_root'      => 'dot1dStpDesignatedRoot',
    'stp_root_port' => 'dot1dStpRootPort',
    'stp_priority'  => 'dot1dStpPriority',

    # Q-BRIDGE-MIB
    'qb_vlans_max'       => 'dot1qMaxSupportedVlans',
    'qb_vlans'           => 'dot1qNumVlans',
    'qb_next_vlan_index' => 'dot1qNextFreeLocalVlanIndex',
);

%FUNCS = (

    # Forwarding Table: Dot1dTpFdbEntry
    'fw_mac'    => 'dot1dTpFdbAddress',
    'fw_port'   => 'dot1dTpFdbPort',
    'fw_status' => 'dot1dTpFdbStatus',

    # Bridge Port Table: Dot1dBasePortEntry
    'bp_index' => 'dot1dBasePortIfIndex',
    'bp_port'  => 'dot1dBasePortCircuit',

    # Bridge Static (Destination-Address Filtering) Database
    'bs_mac'    => 'dot1dStaticAddress',
    'bs_port'   => 'dot1dStaticReceivePort',
    'bs_to'     => 'dot1dStaticAllowedToGoTo',
    'bs_status' => 'dot1dStaticStatus',

    # These leafs are not part of a table, but placed here
    # to return a hash reference to ease API compatibility with
    # MST and PVST implementations indexed by a spanning tree
    # instance id
    'stp_i_mac'       => 'dot1dBaseBridgeAddress',
    'stp_i_time'      => 'dot1dStpTimeSinceTopologyChange',
    'stp_i_ntop'      => 'dot1dStpTopChanges',
    'stp_i_root'      => 'dot1dStpDesignatedRoot',
    'stp_i_root_port' => 'dot1dStpRootPort',
    'stp_i_priority'  => 'dot1dStpPriority',

    # Spanning Tree Protocol Table : dot1dStpPortTable
    'stp_p_id'       => 'dot1dStpPort',
    'stp_p_priority' => 'dot1dStpPortPriority',
    'stp_p_state'    => 'dot1dStpPortState',
    'stp_p_enable'   => 'dot1dStpPortEnable',
    'stp_p_cost'     => 'dot1dStpPortPathCost',
    'stp_p_root'     => 'dot1dStpPortDesignatedRoot',
    'stp_p_bridge'   => 'dot1dStpPortDesignatedBridge',
    'stp_p_port'     => 'dot1dStpPortDesignatedPort',

    # Rapid Spanning Tree Protocol Table : dot1dStpExtPortEntry
    'is_edgeport_admin' => 'dot1dStpPortAdminEdgePort',
    'is_edgeport_oper'  => 'dot1dStpPortOperEdgePort',

    # Q-BRIDGE-MIB : dot1qPortVlanTable
    'qb_i_vlan'        => 'dot1qPvid',
    'qb_i_vlan_type'   => 'dot1qPortAcceptableFrameTypes',
    'qb_i_vlan_in_flt' => 'dot1qPortIngressFiltering',

    # Q-BRIDGE-MIB : dot1qVlanCurrentTable
    'qb_cv_egress'   => 'dot1qVlanCurrentEgressPorts',
    'qb_cv_untagged' => 'dot1qVlanCurrentUntaggedPorts',
    'qb_cv_stat'     => 'dot1qVlanStatus',

    # Q-BRIDGE-MIB : dot1qVlanStaticTable
    'v_name'           => 'dot1qVlanStaticName',
    'qb_v_name'        => 'dot1qVlanStaticName',
    'qb_v_egress'      => 'dot1qVlanStaticEgressPorts',
    'qb_v_fbdn_egress' => 'dot1qVlanForbiddenEgressPorts',
    'qb_v_untagged'    => 'dot1qVlanStaticUntaggedPorts',
    'qb_v_stat'        => 'dot1qVlanStaticRowStatus',

    # VLAN Forwarding Table: Dot1qTpFdbEntry
    'qb_fw_port'   => 'dot1qTpFdbPort',
    'qb_fw_status' => 'dot1qTpFdbStatus',
);

%MUNGE = (

    # Inherit all the built in munging
    %SNMP::Info::MUNGE,

    # Add ones for our class
    'b_mac'            => \&SNMP::Info::munge_mac,
    'fw_mac'           => \&SNMP::Info::munge_mac,
    'bs_mac'           => \&SNMP::Info::munge_mac,
    'stp_root'         => \&SNMP::Info::munge_prio_mac,
    'stp_i_mac'        => \&SNMP::Info::munge_mac,
    'stp_i_root'       => \&SNMP::Info::munge_prio_mac,
    'stp_p_root'       => \&SNMP::Info::munge_prio_mac,
    'stp_p_bridge'     => \&SNMP::Info::munge_prio_mac,
    'stp_p_port'       => \&SNMP::Info::munge_prio_port,
    'qb_cv_egress'     => \&SNMP::Info::munge_port_list,
    'qb_cv_untagged'   => \&SNMP::Info::munge_port_list,
    'qb_v_egress'      => \&SNMP::Info::munge_port_list,
    'qb_v_fbdn_egress' => \&SNMP::Info::munge_port_list,
    'qb_v_untagged'    => \&SNMP::Info::munge_port_list,
    'qb_cv_untagged'   => \&SNMP::Info::munge_port_list,

);

# break up the Dot1qTpFdbEntry INDEX into FDB ID and MAC Address.
sub _qb_fdbtable_index {
    my $idx    = shift;
    my @values = split( /\./, $idx );
    my $fdb_id = shift(@values);
    return ( $fdb_id, join( ':', map { sprintf "%02x", $_ } @values ) );
}

sub qb_fw_mac {
    my $bridge  = shift;
    my $partial = shift;

    my $qb_fw_port = $bridge->qb_fw_port($partial);
    my $qb_fw_mac  = {};
    foreach my $idx ( keys %$qb_fw_port ) {
        my ( $fdb_id, $mac ) = _qb_fdbtable_index($idx);
        $qb_fw_mac->{$idx} = $mac;
    }
    return $qb_fw_mac;
}

sub qb_fw_vlan {
    my $bridge  = shift;
    my $partial = shift;

    my $qb_fw_port = $bridge->qb_fw_port($partial);
    my $qb_fdb_ids = $bridge->qb_fdb_index() || {};


    my $qb_fw_vlan = {};
    foreach my $idx ( keys %$qb_fw_port ) {
        my ( $fdb_id, $mac ) = _qb_fdbtable_index($idx);
        # Many devices do not populate the dot1qVlanCurrentTable, so default
        # to FDB ID = VID, but if we have a mapping use it.
        my $vlan = $fdb_id;
        # exists as test since some devices have a vlan 0, and a shared
        # FDB ID maps to undef because its entries name no single VLAN
        if (exists $qb_fdb_ids->{$fdb_id}) {
            $vlan = $qb_fdb_ids->{$fdb_id};
        }
        $qb_fw_vlan->{$idx} = $vlan;
    }
    return $qb_fw_vlan;
}

sub qb_i_vlan_t {
    my $bridge  = shift;
    my $partial = shift;

    my $qb_i_vlan      = $bridge->qb_i_vlan($partial);
    my $qb_i_vlan_type = $bridge->qb_i_vlan_type($partial);

    my $i_vlan = {};

    foreach my $if ( keys %$qb_i_vlan ) {
        my $vlan = $qb_i_vlan->{$if};
        my $tagged = $qb_i_vlan_type->{$if} || '';
        next unless defined $vlan;
        $i_vlan->{$if} = $tagged eq 'admitOnlyVlanTagged' ? 'trunk' : $vlan;
    }
    return $i_vlan;
}

sub qb_fdb_index {
    my $bridge  = shift;
    my $partial = shift;

    # Some devices may not implement TimeFilter in a standard manner
    # appearing to loop on this request.  Override in the device class,
    # see Enterasys for example.
    my $qb_fdb_ids = $bridge->dot1qVlanFdbId() || {};

    return $bridge->_qb_fdb_vlan_map($qb_fdb_ids);
}

# Strip the TimeFilter from dot1qVlanFdbId and invert it. With shared VLAN
# learning several VLANs report one FDB ID; it maps to undef rather than to
# whichever of those VLANs hash order happened to visit last.
sub _qb_fdb_vlan_map {
    my ( $bridge, $qb_fdb_ids ) = @_;

    my %vlans_of;
    foreach my $fdb_entry ( keys %$qb_fdb_ids ) {
        ( my $vlan = $fdb_entry ) =~ s/^\d+\.//;
        $vlans_of{ $qb_fdb_ids->{$fdb_entry} }{$vlan} = 1;
    }

    my $vl_fdb_index = {};
    foreach my $fdb_id ( keys %vlans_of ) {
        my @vlans = keys %{ $vlans_of{$fdb_id} };
        $vl_fdb_index->{$fdb_id} = scalar @vlans == 1 ? $vlans[0] : undef;
    }
    return $vl_fdb_index;
}

# Most devices now support Q-BRIDGE-MIB, fall back to
# BRIDGE-MIB for those that don't.
sub fw_mac {
    my $bridge = shift;

    unless ($bridge->can('cisco_comm_indexing') && $bridge->cisco_comm_indexing()){
        my $qb = $bridge->qb_fw_mac();
        return $qb if (ref {} eq ref $qb and scalar keys %$qb);
    }

    return $bridge->SUPER::fw_mac();
}

sub fw_port {
    my $bridge = shift;

    unless ($bridge->can('cisco_comm_indexing') && $bridge->cisco_comm_indexing()){
        my $qb = $bridge->qb_fw_port();
        return $qb if (ref {} eq ref $qb and scalar keys %$qb);
    }

    return $bridge->SUPER::fw_port();
}

sub fw_status {
    my $bridge = shift;

    unless ($bridge->can('cisco_comm_indexing') && $bridge->cisco_comm_indexing()){
        my $qb = $bridge->qb_fw_status();
        return $qb if (ref {} eq ref $qb and scalar keys %$qb);
    }

    return $bridge->SUPER::fw_status();
}

sub i_stp_state {
    my $bridge  = shift;
    my $partial = shift;

    my $bp_index    = $bridge->bp_index($partial);
    my $stp_p_state = $bridge->stp_p_state($partial);

    my %i_stp_state;

    foreach my $index ( keys %$stp_p_state ) {
        my $state = $stp_p_state->{$index};
        my $iid   = $bp_index->{$index};
        next unless defined $iid;
        next unless defined $state;
        $i_stp_state{$iid} = $state;
    }

    return \%i_stp_state;
}

sub i_faststart_enabled {
    my $bridge  = shift;
    my $partial = shift;

    my $edge_admin = $bridge->is_edgeport_admin();
    return _stp_edge_by_ifindex( $bridge, $edge_admin, $partial );
}

# Admin edge values keyed by bridge port, mapped to ifIndex through bp_index
# and read as 1 or 0 by $decode (default _stp_enabled); a port missing from
# bp_index, or a value $decode does not know, is absent.  Called as a
# function by classes outside Bridge's inheritance (RapidCity).
sub _stp_edge_by_ifindex {
    my ( $bridge, $edge_admin, $partial, $decode ) = @_;
    $decode ||= \&_stp_enabled;

    my $bp_index = $bridge->bp_index($partial) || {};

    my %i_faststart_enabled;
    foreach my $port ( keys %{ $edge_admin || {} } ) {
        my $iid     = $bp_index->{$port};
        my $enabled = $decode->( $edge_admin->{$port} );
        next unless defined $iid;
        next unless defined $enabled;
        $i_faststart_enabled{$iid} = $enabled;
    }
    return \%i_faststart_enabled;
}

sub i_stp_port {
    my $bridge  = shift;
    my $partial = shift;

    my $bp_index   = $bridge->bp_index($partial);
    my $stp_p_port = $bridge->stp_p_port($partial);

    my %i_stp_port;

    foreach my $index ( keys %$stp_p_port ) {
        my $bport  = $stp_p_port->{$index};
        my $iid    = $bp_index->{$index};
        next unless defined $iid;
        next unless defined $bport;
        $i_stp_port{$iid} = $bport;
    }
    return \%i_stp_port;
}

sub i_stp_id {
    my $bridge  = shift;
    my $partial = shift;

    my $bp_index = $bridge->bp_index($partial);
    my $stp_p_id = $bridge->stp_p_id($partial);

    my %i_stp_id;

    foreach my $index ( keys %$stp_p_id ) {
        my $bport  = $stp_p_id->{$index};
        my $iid    = $bp_index->{$index};
        next unless defined $iid;
        next unless defined $bport;
        $i_stp_id{$iid} = $bport;
    }
    return \%i_stp_id;
}

sub i_stp_bridge {
    my $bridge  = shift;
    my $partial = shift;

    my $bp_index     = $bridge->bp_index($partial);
    my $stp_p_bridge = $bridge->stp_p_bridge($partial);

    my %i_stp_bridge;

    foreach my $index ( keys %$stp_p_bridge ) {
        my $bport  = $stp_p_bridge->{$index};
        my $iid    = $bp_index->{$index};
        next unless defined $iid;
        next unless defined $bport;
        $i_stp_bridge{$iid} = $bport;
    }
    return \%i_stp_bridge;
}

sub stp_protocols {
    my $bridge = shift;

    my $trees = $bridge->stp_trees() || {};
    return unless keys %$trees;
    return ['dot1d'];
}

sub stp_trees {
    my $bridge = shift;

    return unless $bridge->_stp_default_context_ok();
    return $bridge->{_stp_trees} if $bridge->{_stp_trees};
    return {} unless $bridge->_stp_default_is_common();

    my $record = $bridge->_stp_dot1d_tree() or return {};
    $bridge->{_stp_trees} = { 'cist.0' => $record };
    return $bridge->{_stp_trees};
}

# The BRIDGE-MIB common tree whatever _stp_default_is_common() says, so a
# class that keeps the default off can still build it. Callers set
# protocol and measured on a copy.
sub _stp_dot1d_tree {
    my $bridge = shift;

    my $ports = $bridge->stp_p_id() || {};
    my $root  = $bridge->stp_root();
    return unless keys %$ports or defined $root;

    my $bp_index = $bridge->bp_index() || {};
    my $unmapped = grep { !defined $bp_index->{$_} } values %$ports;

    return {
        type           => 'cist',
        id             => 0,
        protocol       => undef,
        measured       => 0,
        ports_complete => $unmapped ? 0 : 1,
        contexts       => [ { kind => 'none' } ],
        bridge         => scalar $bridge->_stp_own_bridge_id(),
        root           => scalar _stp_decode_bridge_id($root),
    };
}

sub stp_vlan_map { return; }

# Only the default context serves the whole tree list
sub _stp_default_context_ok {
    my $bridge = shift;

    my $context = $bridge->_walk_context();
    return 1 unless length $context;

    my $method = ( caller(1) )[3];
    $bridge->error_throw(
        "$method() reads the tree list, which only the default context"
            . " serves whole. This session is in context '$context'. Call"
            . " update() back to the default context, read the list, and"
            . " keep it while you switch contexts.\n" );
    return 0;
}

sub stp_tree_ports {
    my $bridge   = shift;
    my $tree_key = shift;

    my $tree = $bridge->_stp_tree_for_key($tree_key) or return;
    return $bridge->_stp_dot1d_port_rows($tree);
}

# Error names the method that called stp_tree_ports, not this helper
sub _stp_tree_for_key {
    my $bridge   = shift;
    my $tree_key = shift;

    my $trees = $bridge->stp_trees() || {};
    my $tree  = defined $tree_key ? $trees->{$tree_key} : undef;
    return $tree if $tree;

    my $key    = defined $tree_key ? $tree_key : 'undef';
    my $method = ( caller(1) )[3] // 'stp_tree_ports';
    $bridge->error_throw( "$method() has no tree '$key'. Pass a key from"
            . " stp_trees(), read in the default context.\n" );
    return;
}

# BRIDGE-MIB port rows in the session's current context, labeled with $tree
sub _stp_dot1d_port_rows {
    my $bridge = shift;
    my $tree   = shift;

    my $ports    = $bridge->stp_p_id()     || {};
    my $states   = $bridge->stp_p_state()  || {};
    my $enable   = $bridge->stp_p_enable() || {};
    my $d_bridge = $bridge->stp_p_bridge() || {};
    my $d_port   = $bridge->stp_p_port()   || {};
    my $bp_index = $bridge->bp_index()     || {};

    my %tree_ports;
    foreach my $index ( keys %$ports ) {
        my $iid = $bp_index->{ $ports->{$index} };
        next unless defined $iid;
        $tree_ports{$iid} = {
            tree_type         => $tree->{type},
            tree_id           => $tree->{id},
            state             => $states->{$index},
            role              => undef,
            role_raw          => undef,
            enabled           => scalar _stp_enabled( $enable->{$index} ),
            designated_bridge =>
                scalar _stp_decode_bridge_id( $d_bridge->{$index} ),
            designated_port =>
                scalar _stp_decode_port_id( $d_port->{$index} ),
        };
    }
    return \%tree_ports;
}

sub stp_trees_complete {
    my $bridge = shift;

    # A class that keeps the default off has trees this class does not read
    return 0 unless $bridge->_stp_default_is_common();

    my $trees = $bridge->stp_trees() || {};
    return unless keys %$trees;
    return 0;
}

sub _stp_default_is_common { return 1; }

sub _stp_own_bridge_id {
    my $bridge = shift;

    return _stp_bridge_id_from( $bridge->stp_priority(), $bridge->b_mac() );
}

# EnabledStatus and TruthValue both use 1 and 2
sub _stp_enabled {
    my $value = shift;
    return unless defined $value;

    return 1 if $value =~ /^(?:enabled|true|1)$/;
    return 0 if $value =~ /^(?:disabled|false|2)$/;
    return;
}

sub _stp_bridge_id_from {
    my ( $priority, $mac ) = @_;
    return unless defined $priority and defined $mac;

    my $prio_hex = sprintf( '%04x', $priority );
    my $prio_octets = join( ':', unpack( '(A2)2', $prio_hex ) );
    return _stp_decode_bridge_id( join( ':', $prio_octets, $mac ) );
}

# 802.1t fixed format: top 4 bits priority, low 12 bits system ID extension
sub _stp_decode_bridge_id {
    my $id = shift;
    return unless defined $id;

    my @octets = split /:/, $id;
    return unless @octets == 8;

    my $prio = hex( $octets[0] . $octets[1] );
    return {
        priority   => ( $prio >> 12 ) * 4096,
        sys_id_ext => $prio & 0x0fff,
        mac        => join( ':', @octets[ 2 .. 7 ] ),
        raw        => $id,
    };
}

# 802.1t fixed format: top 4 bits priority, low 12 bits port number
sub _stp_decode_port_id {
    my $id = shift;
    return unless defined $id;

    my @octets = split /:/, $id;
    return unless @octets == 2;

    my $value = hex( $octets[0] . $octets[1] );
    return {
        priority => ( $value >> 12 ) * 16,
        port     => $value & 0x0fff,
        raw      => $id,
    };
}

# Non-accessible, but needed for consistency with other classes
sub v_index {
    my $bridge  = shift;
    my $partial = shift;

    my $v_name = $bridge->v_name($partial);
    my %v_index;
    foreach my $idx ( keys %$v_name ) {
        $v_index{$idx} = $idx;
    }
    return \%v_index;
}

sub i_vlan {
    my $bridge  = shift;
    my $partial = shift;

    my $index = $bridge->bp_index() or return {};

    # If given a partial it will be an ifIndex, we need to use dot1dBasePort
    if ($partial) {
        my %r_index = reverse %$index;
        $partial = $r_index{$partial};
    }

    my $i_pvid = $bridge->qb_i_vlan($partial) || {};
    my $i_vlan = {};

    foreach my $bport ( keys %$i_pvid ) {
        my $vlan    = $i_pvid->{$bport};
        my $ifindex = $index->{$bport};
        unless ( defined $ifindex ) {
            print "  Port $bport has no bp_index mapping. Skipping.\n"
                if $DEBUG;
            next;
        }
        $i_vlan->{$ifindex} = $vlan;
    }

    return $i_vlan;
}

sub i_untagged { goto &i_vlan }

sub i_vlan_membership {
    my $bridge  = shift;
    my $partial = shift;

    # Use VlanCurrentTable if available since it will include dynamic
    # VLANs.  However, some devices do not populate the table.
    my $v_ports = $bridge->qb_cv_egress() || $bridge->qb_v_egress();

    return $bridge->_vlan_hoa($v_ports, $partial);
}

sub i_vlan_membership_untagged {
    my $bridge  = shift;
    my $partial = shift;

    # Use VlanCurrentTable if available since it will include dynamic
    # VLANs.  However, some devices do not populate the table.
    my $v_ports = $bridge->qb_cv_untagged() || $bridge->qb_v_untagged();

    return $bridge->_vlan_hoa($v_ports, $partial);
}

sub _vlan_hoa {
    my $bridge = shift;
    my ( $v_ports, $partial ) = @_;

    my $index = $bridge->bp_index();

    my $vlan_hoa = {};
    foreach my $idx ( keys %$v_ports ) {
        next unless ( defined $v_ports->{$idx} );
        my $portlist = $v_ports->{$idx};
        my $ret      = [];
        my $vlan;

        # Strip TimeFilter if we're using VlanCurrentTable
        ($vlan = $idx) =~ s/^(\d+\.)*//g;

        # Convert portlist bit array to bp_index array
        for ( my $i = 0; $i <= $#$portlist; $i++ ) {
            push( @{$ret}, $i + 1 ) if ( @$portlist[$i] );
        }

        #Create HoA ifIndex -> VLAN array
        foreach my $port ( @{$ret} ) {
            my $ifindex = $index->{$port};
            next unless ( defined($ifindex) );    # shouldn't happen
            next if ( defined $partial and $ifindex !~ /^$partial$/ );
            push( @{ $vlan_hoa->{$ifindex} }, $vlan );
        }
    }
    return $vlan_hoa;
}

sub set_i_pvid {
    my $bridge = shift;

    $bridge->error_throw("VLAN set not supported.");
    return;
}

sub set_i_vlan {
    my $bridge = shift;

    $bridge->error_throw("VLAN set not supported.");
    return;
}

sub set_i_untagged { goto &set_i_vlan }

sub set_add_i_vlan_tagged {
    my $bridge = shift;

    $bridge->error_throw("VLAN set not supported.");
    return;
}

sub set_remove_i_vlan_tagged {
    my $bridge = shift;

    $bridge->error_throw("VLAN set not supported.");
    return;
}

#
# These are internal methods and are not documented.  Do not use directly.
#
sub _check_forbidden_ports {
    my $bridge = shift;
    my ( $vlan_id, $index ) = @_;
    return unless ( $vlan_id =~ /\d+/ and $index =~ /\d+/ );

    my $iv_forbidden = $bridge->qb_v_fbdn_egress($vlan_id);

    my $forbidden_ports = $iv_forbidden->{$vlan_id};
    print "Forbidden ports: @$forbidden_ports\n" if $bridge->debug();
    if ( defined( @$forbidden_ports[ $index - 1 ] )
        and ( @$forbidden_ports[ $index - 1 ] eq "1" ) )
    {
        print
            "Error: Index: $index in forbidden list for VLAN: $vlan_id unable to add.\n"
            if $bridge->debug();
        return;
    }
    return 1;
}

sub _validate_vlan_param {
    my $bridge = shift;
    my ( $vlan_id, $ifindex ) = @_;

    # VID and ifIndex should both be numeric
    unless (defined $vlan_id
        and defined $ifindex
        and $vlan_id =~ /^\d+$/
        and $ifindex =~ /^\d+$/ )
    {
        $bridge->error_throw("Invalid parameter.");
        return;
    }

    # Check that ifIndex exists on device
    my $index = $bridge->interfaces($ifindex);

    unless ( exists $index->{$ifindex} ) {
        $bridge->error_throw("ifIndex $ifindex does not exist.");
        return;
    }

    #Check that VLAN exists on device
    my $vtp_vlans = $bridge->load_qb_cv_stat() || $bridge->load_qb_v_stat();
    my $vlan_exists = 0;

    foreach my $iid ( keys %$vtp_vlans ) {
        my $vlan  = 0;
        my $state = $vtp_vlans->{$iid};
        next unless defined $state;
        if ( $iid =~ /(\d+)$/ ) {
            $vlan = $1;
        }

        $vlan_exists = 1 if ( $vlan_id eq $vlan );
    }
    unless ($vlan_exists) {
        $bridge->error_throw(
            "VLAN $vlan_id does not exist or is not operational.");
        return;
    }

    return 1;
}

1;

__END__


=head1 NAME

SNMP::Info::Bridge - SNMP Interface to SNMP data available through the
F<BRIDGE-MIB> (RFC1493)

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 my $bridge = new SNMP::Info (
                             AutoSpecify => 1,
                             Debug       => 1,
                             DestHost    => 'switch',
                             Community   => 'public',
                             Version     => 2
                             );

 my $class = $bridge->class();
 print " Using device sub class : $class\n";

 # Grab Forwarding Tables
 my $interfaces = $bridge->interfaces();
 my $fw_mac     = $bridge->fw_mac();
 my $fw_port    = $bridge->fw_port();
 my $bp_index   = $bridge->bp_index();

 foreach my $fw_index (keys %$fw_mac){
    my $mac   = $fw_mac->{$fw_index};
    my $bp_id = $fw_port->{$fw_index};
    my $iid   = $bp_index->{$bp_id};
    my $port  = $interfaces->{$iid};

    print "Port:$port forwarding to $mac\n";
 }

 # Spanning trees: read the list in the default context and keep it, then
 # read each tree's ports in the contexts that serve it.  enter_context()
 # is the helper in "SNMP Contexts" in SNMP::Info.
 my $community = $bridge->snmp_comm();
 my $trees     = $bridge->stp_trees() || {};
 foreach my $key (sort keys %$trees) {
    my %ports;
    foreach my $context (@{ $trees->{$key}{contexts} }) {
        enter_context($bridge, $context, $community) or next;
        %ports = (%ports, %{ $bridge->stp_tree_ports($key) || {} });
    }
    $bridge->update();

    foreach my $iid (sort keys %ports) {
        printf "%s %s: %s\n", $key, $interfaces->{$iid},
            $ports{$iid}{state} // 'no state';
    }
 }

=head1 DESCRIPTION

F<BRIDGE-MIB> is used by most Layer 2 devices, and holds information like the
MAC Forwarding Table and Spanning Tree Protocol info.

F<Q-BRIDGE-MIB> holds 802.1q information -- VLANs and Trunking.  Cisco tends
not to use this MIB, but some proprietary ones.  HP and some nicer vendors use
this.  This is from C<RFC2674_q>.

Create or use a subclass of SNMP::Info that inherits this class.  Do not use
directly.

For debugging you can call new() directly as you would in SNMP::Info

 my $bridge = new SNMP::Info::Bridge(...);

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item F<BRIDGE-MIB>

=item F<Q-BRIDGE-MIB>

=item F<RSTP-MIB>

=back

=head1 GLOBALS

These are methods that return scalar values from SNMP

=over

=item $bridge->b_mac()

Returns the MAC Address of the root bridge port

(C<dot1dBaseBridgeAddress>)

=item $bridge->b_ports()

Returns the number of ports in device

(C<dot1dBaseNumPorts>)

=item $bridge->b_type()

Returns the type of bridging this bridge can perform, transparent and/or
source route.

(C<dot1dBaseType>)

=item $bridge->stp_ver()

Returns what version of STP the device is running.

(C<dot1dStpProtocolSpecification>)

=item $bridge->stp_time()

Returns time since last topology change detected. (100ths/second)

(C<dot1dStpTimeSinceTopologyChange>)

=item $bridge->stp_root()

Returns root of STP.

(C<dot1dStpDesignatedRoot>)

=item $bridge->qb_vlans_max()

Maximum number of VLANS supported on this device.

(C<dot1qMaxSupportedVlans>)

=item $bridge->qb_vlans()

Current number of VLANs that are configured in this device.

(C<dot1qNumVlans>)

=item $bridge->qb_next_vlan_index()

The next available value for C<dot1qVlanIndex> of a local VLAN entry in
C<dot1qVlanStaticTable>

(C<dot1qNextFreeLocalVlanIndex>)

=back

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $bridge->i_vlan()

Returns a mapping between C<ifIndex> and the PVID or default VLAN.

=item $vtp->i_untagged()

An alias for C<i_vlan>.

=item $bridge->i_vlan_membership()

Returns reference to hash of arrays: key = C<ifIndex>, value = array of VLAN
IDs.  These are the VLANs which are members of the egress list for the port.

  Example:
  my $interfaces = $bridge->interfaces();
  my $vlans      = $bridge->i_vlan_membership();

  foreach my $iid (sort keys %$interfaces) {
    my $port = $interfaces->{$iid};
    my $vlan = join(',', sort(@{$vlans->{$iid}}));
    print "Port: $port VLAN: $vlan\n";
  }

=item $bridge->i_vlan_membership_untagged()

Returns reference to hash of arrays: key = C<ifIndex>, value = array of VLAN
IDs.  These are the VLANs which are members of the untagged egress list for
the port.

=item $bridge->qb_i_vlan_t()

Returns reference to hash: key = C<dot1dBasePort>, value = either 'trunk' for
tagged ports or the VLAN ID.

=item $bridge->qb_fdb_index()

Returns reference to hash: key = FDB ID, value = VLAN ID.

An FDB ID shared by several VLANs (shared VLAN learning) maps to C<undef>.

=item $bridge->v_index()

Returns VLAN IDs

=back

=head2 Forwarding Table (C<dot1dTpFdbEntry>)

Some devices serve this table once per VLAN, each in its own SNMP
context.  Check with L<SNMP::Info/"context_kinds">.

=over

=item $bridge->fw_mac()

Returns reference to hash of forwarding table MAC Addresses

(C<dot1dTpFdbAddress>)

=item $bridge->fw_port()

Returns reference to hash of forwarding table entries port interface
identifier (iid)

(C<dot1dTpFdbPort>)

=item $bridge->fw_status()

Returns reference to hash of forwarding table entries status

(C<dot1dTpFdbStatus>)

=back

=head2 Bridge Port Table (C<dot1dBasePortEntry>)

=over

=item $bridge->bp_index()

Returns reference to hash of bridge port table entries map back to interface
identifier (iid)

(C<dot1dBasePortIfIndex>)

=item $bridge->bp_port()

Returns reference to hash of bridge port table entries for a port which
(potentially) has the same value of C<dot1dBasePortIfIndex> as another port
on the same bridge, this object contains the name of an	object instance unique
to this port.

(C<dot1dBasePortCircuit>)

=back

=head2 Spanning Tree Instance Globals

These are not part of a table, but return a hash reference to ease API
compatibility with MST and PVST implementations indexed by a spanning tree
instance id.

=over

=item $bridge->stp_i_time()

Returns time since last topology change detected. (100ths/second)

(C<dot1dStpTimeSinceTopologyChange>)

=item $bridge->stp_i_time()

Returns the total number of topology changes detected.

(C<dot1dStpTopChanges>)

=item $bridge->stp_i_root()

Returns root of STP.

(C<dot1dStpDesignatedRoot>)

=item $bridge->stp_i_root_port()

Returns the port number of the port that offers the lowest cost path
to the root bridge.

(C<dot1dStpRootPort>)

=item $bridge->stp_i_priority()

Returns the port number of the port that offers the lowest cost path
to the root bridge.

(C<dot1dStpPriority>)

=back

=head2 Spanning Tree Protocol Table (C<dot1dStpPortTable>)

Descriptions are straight from F<BRIDGE-MIB.my>

=over

=item $bridge->stp_p_id()

"The port number of the port for which this entry contains Spanning Tree
Protocol management information."

(C<dot1dStpPort>)

=item $bridge->stp_p_priority()

"The value of the priority field which is contained in the first
(in network byte order) octet of the (2 octet long) Port ID.  The other octet
of the Port ID is given by the value of C<dot1dStpPort>."

(C<dot1dStpPortPriority>)

=item $bridge->stp_p_enable()

"The enabled/disabled status of the port."

(C<dot1dStpPortEnable>)

=item $bridge->stp_p_state()

"The port's current state as defined by application of the Spanning Tree
Protocol.  This state controls what action a port takes on reception of a
frame.  If the bridge has detected a port that is malfunctioning it will place
that port into the broken(6) state.  For ports which are disabled
(see C<dot1dStpPortEnable>), this object will have a value of disabled(1)."

 disabled(1)
 blocking(2)
 listening(3)
 learning(4)
 forwarding(5)
 broken(6)

(C<dot1dStpPortState>)

=item $bridge->stp_p_cost()

"The contribution of this port to the path cost of paths towards the spanning
tree root which include this port.  802.1D-1990 recommends that the default
value of this parameter be in inverse proportion to the speed of the attached
LAN."

(C<dot1dStpPortPathCost>)

=item $bridge->stp_p_root()

"The unique Bridge Identifier of the Bridge recorded as the Root in the
Configuration BPDUs transmitted by the Designated Bridge for the segment to
which the port is attached."

(C<dot1dStpPortDesignatedRoot>)

=item $bridge->stp_p_bridge()

"The Bridge Identifier of the bridge which this port considers to be the
Designated Bridge for this port's segment."

(C<dot1dStpPortDesignatedBridge>)

=item $bridge->stp_p_port()

(C<dot1dStpPortDesignatedPort>)

"The Port Identifier of the port on the Designated Bridge for this port's
segment."

=item $bridge->i_stp_port()

Returns the mapping of (C<dot1dStpPortDesignatedPort>) to the interface
index (iid).

=item $bridge->i_stp_state()

Returns the mapping of (C<dot1dStpPortState>) to the interface
index (iid): the port state in the device's default spanning tree.

C<BRIDGE-MIB> indexes spanning tree ports by port number alone, with no
instance or VLAN.  On a device running more than one tree (MSTP
instances, a tree per VLAN, or vendor STP domains) this is the one tree
the agent exposes in the polled context, not the port's state in every
VLAN.  A class whose platform exposes a different tree says so in its
own documentation.  See L</"Spanning Tree Trees"> for every tree the
device runs.

=item $bridge->i_faststart_enabled()

Returns 1 or 0 for each port by whether it is configured as an edge port
(the IEEE equivalent of PortFast).  Format is a hash reference with
key = C<ifIndex>, value = [1|0].  A port with no administrative value is
absent.

(C<dot1dStpPortAdminEdgePort>)

=item $bridge->i_stp_id()

Returns the mapping of (C<dot1dStpPort>) to the interface index (iid).

=item $bridge->i_stp_bridge()

Returns the mapping of (C<dot1dStpPortDesignatedBridge>) to the interface
index (iid).

=back

=head2 Spanning Tree Trees

These methods report each spanning tree a device runs, and its ports'
state, role, designated bridge and designated port, one tree at a time.
Every record names its tree, so a row read out of context still says
which tree it describes.  Read the tree list in the default context and
keep it: C<update()> clears the cache on every context switch.  Where
trees are served in other contexts, see L<SNMP::Info/"SNMP Contexts">.

This class reports the C<BRIDGE-MIB> tree as the common tree, the one
tree under RSTP and the CIST under MSTP, with its protocol unknown.
Classes that read a vendor's protocol and trees override these methods.

A class that can read which protocol a device runs also defines
C<hasSTP()>, C<hasRSTP()>, C<hasMSTP()>, C<hasPVST()>,
C<hasRapidPVST()> or C<hasVSTP()>, each true when the device runs that
protocol, read from an object that names the protocol and never from a
table having rows.  As with C<has_topo()> in L<SNMP::Info>, test C<can()>
before calling one.

=over

=item $bridge->stp_protocols()

Returns a reference to an array of the spanning tree protocols the device
runs, or nothing when no tree was read: C<stp>, C<rstp>, C<mstp>,
C<pvst> (PVST+), C<rapid-pvst> (Rapid-PVST+), C<vstp> (Juniper VLAN
Spanning Tree, one tree per VLAN in its own context) or C<dot1d>.  C<dot1d>
means a C<BRIDGE-MIB> tree is served but no object says which protocol it
is.  Nothing does not mean the device runs no spanning tree: check
C<stp_trees_complete()>.

=item $bridge->stp_trees()

Returns reference to hash of tree records, keyed by tree key (C<cist.0>).
Each record holds C<type> and C<id>; C<protocol>, undef where the device
does not say; C<measured>, true only where the platform's data was
checked against the device's CLI; C<ports_complete>, false when port rows
were dropped; C<contexts>, the contexts that serve the tree, in order, each
as L<SNMP::Info/"snmp_context"> describes it (C<kind> C<none> means the
default context); read the tree's ports in any one of them, and union the
rows where several are listed; C<bridge>, the device's own bridge ID; and
C<root>, the designated root.  Bridge IDs are hashes of C<priority>,
C<sys_id_ext>, C<mac> and C<raw>, the served value; the device's own
C<raw> is built from C<dot1dStpPriority> and C<dot1dBaseBridgeAddress>.

Returns nothing, with C<error()> set, when the session is in a
non-default context, since only the default context serves the whole
list.

=item $bridge->stp_trees_complete()

Returns 1 when the tree list holds every tree the device runs, 0 when
trees may exist that were not read (including a device whose class does
not read its trees), and nothing when the device serves no tree.  Vendor
classes that read their own trees return 0, not nothing, when no tree was
read.

=item $bridge->stp_vlan_map()

Returns reference to hash mapping each VLAN id to the key of the tree
that carries it, as the device serves the map, or nothing where it serves
none.  This class serves none: one C<BRIDGE-MIB> tree carries every VLAN.

=item $bridge->stp_tree_ports($tree_key)

Returns reference to hash of port records for the tree C<$tree_key>,
keyed by interface index (iid), read in the session's current context.
Each record holds C<tree_type> and C<tree_id>, C<state>, C<enabled> (1
when the device runs spanning tree on the port, 0 when it does not, undef
where not served), C<role> (one of C<disabled>, C<root>, C<designated>,
C<alternate>, C<backup>, C<boundary> or C<master>, undef where not served
or not known), C<role_raw> (the role as served, undef where not served),
C<designated_bridge> (a bridge ID as above) and C<designated_port> (a hash
of C<priority>, C<port> and C<raw>).  A port whose designated bridge is
another bridge connects to that bridge's designated port.

Returns nothing, with C<error()> set, for a key not in C<stp_trees()>.

=back

=head2 Q-BRIDGE Port VLAN Table (C<dot1qPortVlanTable>)

=over

=item $bridge->qb_i_vlan()

The PVID, the VLAN ID assigned to untagged frames or Priority-Tagged frames
received on this port.

(C<dot1qPvid>)

=item $bridge->qb_i_vlan_type()

Either C<admitAll> or C<admitOnlyVlanTagged>.  This is a good spot to find
trunk ports.

(C<dot1qPortAcceptableFrameTypes>)

=item $bridge->qb_i_vlan_in_flt()

When this is C<true> the device will discard incoming frames for VLANs which
do not include this Port in its Member set.  When C<false>, the port will
accept all incoming frames.

(C<dot1qPortIngressFiltering>)

=back

=head2 Q-BRIDGE VLAN Current Table (C<dot1qVlanCurrentTable>)

=over

=item $bridge->qb_cv_egress()

The set of ports which are assigned to the egress list for this VLAN.

(C<dot1qVlanCurrentEgressPorts>)

=item $bridge->qb_cv_untagged()

The set of ports which should transmit egress packets for this VLAN as
untagged.

(C<dot1qVlanCurrentUntaggedPorts>)

=item $bridge->qb_cv_stat()

Status of the VLAN, other, permanent, or dynamicGvrp.

(C<dot1qVlanStatus>)

=back

=head2 Q-BRIDGE VLAN Static Table (C<dot1qVlanStaticTable>)

=over

=item $bridge->qb_v_name()

Human-entered name for vlans.

(C<dot1qVlanStaticName>)

=item $bridge->qb_v_egress()

The set of ports which are assigned to the egress list for this VLAN.

(C<dot1qVlanStaticEgressPorts>)

=item $bridge->qb_v_fbdn_egress()

The set of ports which are prohibited from being included in the egress list
for this VLAN.

(C<dot1qVlanForbiddenEgressPorts>)

=item $bridge->qb_v_untagged()

The set of ports which should transmit egress packets for this VLAN as
untagged.

(C<dot1qVlanStaticUntaggedPorts>)

=item $bridge->qb_v_stat()

C<active> !

(C<dot1qVlanStaticRowStatus>)

=back

=head2 Q-BRIDGE Filtering Database Table (C<dot1qFdbTable>)

=over

=item $bridge->qb_fw_mac()

Returns reference to hash of forwarding table MAC Addresses

(C<dot1qTpFdbAddress>)

=item $bridge->qb_fw_port()

Returns reference to hash of forwarding table entries port interface
identifier (iid)

(C<dot1qTpFdbPort>)

=item $bridge->qb_fw_vlan()

Returns reference to hash of forwarding table entries VLAN ID

Entries whose FDB ID is shared by several VLANs have an C<undef> VLAN ID.
Entries whose FDB ID has no mapping use the FDB ID as the VLAN ID.

=item $bridge->qb_fw_status()

Returns reference to hash of forwarding table entries status

(C<dot1qTpFdbStatus>)

=back

=head1 SET METHODS

These are methods that provide SNMP set functionality for overridden methods
or provide a simpler interface to complex set operations.  See
L<SNMP::Info/"SETTING DATA VIA SNMP"> for general information on set
operations.

=over

=item $bridge->set_i_vlan(vlan, ifIndex)

Currently unsupported.  Throws an error and returns.

=item $bridge->set_i_untagged(vlan, ifIndex)

An alias for C<set_i_vlan>.

=item $bridge->set_i_pvid(pvid, ifIndex)

Currently unsupported.  Throws an error and returns.

=item $bridge->set_add_i_vlan_tagged(vlan, ifIndex)

Currently unsupported.  Throws an error and returns.

=item $bridge->set_remove_i_vlan_tagged(vlan, ifIndex)

Currently unsupported.  Throws an error and returns.

=back

=cut
