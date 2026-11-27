# SNMP::Info::Layer3::ArubaCX
#
# Copyright (c) 2021 Jeroen van Ingen
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

package SNMP::Info::Layer3::ArubaCX;

use strict;
use warnings;
use Exporter;
use SNMP::Info::IEEE802dot3ad 'agg_ports_lag';
use SNMP::Info::IEEE802_STP;
use SNMP::Info::Layer3;
use SNMP::Info::IEEE802_Bridge;

@SNMP::Info::Layer3::ArubaCX::ISA = qw/
  SNMP::Info::IEEE802dot3ad
  SNMP::Info::IEEE802_STP
  SNMP::Info::Layer3
  SNMP::Info::IEEE802_Bridge
  Exporter
/;
@SNMP::Info::Layer3::ArubaCX::EXPORT_OK = qw/
  agg_ports
/;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MODEL_MAP, %MUNGE);

$VERSION = '3.985004';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::IEEE802_STP::MIBS,
    %SNMP::Info::IEEE802dot3ad::MIBS,
    %SNMP::Info::IEEE802_Bridge::MIBS,
    'ARUBAWIRED-CIPT-MIB' => 'arubaWiredCiptClientIpAddress',
    'ARUBAWIRED-FAN-MIB' => 'arubaWiredFanName',
    'ARUBAWIRED-VSF-MIB' => 'arubaWiredVsfTrapEnable',
    'ARUBAWIRED-POE-MIB' => 'arubaWiredPoePethPsePortAveragePower',
    'ARUBAWIRED-POWERSUPPLY-MIB' => 'arubaWiredPSUName',
    'ARUBAWIRED-PM-MIB' => 'arubaWiredPmXcvrDescription',
    'ARUBAWIRED-RPVST-MIB' => 'arubaWiredRpvstExtendedSystemID',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::IEEE802_STP::GLOBALS,
    %SNMP::Info::IEEE802_Bridge::GLOBALS,
    'ps1_type' => 'arubaWiredPSUProductName.1.1',
    'ps2_type' => 'arubaWiredPSUProductName.1.2',
    'ps1_status' => 'arubaWiredPSUState.1.1',
    'ps2_status' => 'arubaWiredPSUState.1.2',
    'vsf_topology' => 'arubaWiredVsfTopology',
    'rpvst_ext_sysid' => 'arubaWiredRpvstExtendedSystemID',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::IEEE802_STP::FUNCS,
    %SNMP::Info::IEEE802dot3ad::FUNCS,
    %SNMP::Info::IEEE802_Bridge::FUNCS,
    'peth_port_power' => 'arubaWiredPoePethPsePortAveragePower',
    'fan_names' => 'arubaWiredFanName',
    'fan_states' => 'arubaWiredFanState',
    'psu_names' => 'arubaWiredPSUName',
    'psu_types' => 'arubaWiredPSUProductName',
    'psu_states' => 'arubaWiredPSUState',
    'vsf_prod_names' => 'arubaWiredVsfMemberProductName',
    'cipt_addr_type' => 'arubaWiredCiptClientIpAddrType',
    'cipt_addr' => 'arubaWiredCiptClientIpAddress',
    'cipt_ifindex' => 'arubaWiredCiptClientPortIfIndex',
    'raw_ad_lag_ports' => 'dot3adAggPortListPorts',  # unmunged raw data
    'pm_xcvr_port'    => 'arubaWiredPmXcvrPortDesc',
    'pm_xcvr_descr'   => 'arubaWiredPmXcvrDescription',
    'pm_xcvr_product' => 'arubaWiredPmXcvrProductNum',
    'pm_xcvr_serial'  => 'arubaWiredPmXcvrSerialNum',
    'pm_xcvr_type'    => 'arubaWiredPmXcvrType',
    # ARUBAWIRED-RPVST-MIB::arubaWiredRpvstVlanTable
    'rpvst_v_admin'         => 'arubaWiredRpvstVlanRpvstAdminStatus',
    'rpvst_v_priority'      => 'arubaWiredRpvstVlanPriority',
    'rpvst_v_root_priority' => 'arubaWiredRpvstVlanRootPriority',
    'rpvst_v_root_mac'      => 'arubaWiredRpvstVlanRootMacAddress',
    # ARUBAWIRED-RPVST-MIB::arubaWiredRpvstPortVlanTable
    'rpvst_pv_state'     => 'arubaWiredRpvstPortVlanState',
    'rpvst_pv_role'      => 'arubaWiredRpvstPortVlanRole',
    'rpvst_pv_bridge'    => 'arubaWiredRpvstPortVlanDesigBridge',
    'rpvst_pv_edge_oper' => 'arubaWiredRpvstPortVlanOperEdge',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::IEEE802_STP::MUNGE,
    %SNMP::Info::IEEE802dot3ad::MUNGE,
    %SNMP::Info::IEEE802_Bridge::MUNGE,
    'rpvst_v_root_mac' => \&SNMP::Info::munge_mac,
    'rpvst_pv_bridge'  => \&SNMP::Info::munge_mac,
);

# Product codes reported by ENTITY-MIB or the product OID.
%MODEL_MAP = (
    'JL719C' => '8360-48Y6C v2',
);

sub _at_pbb_one {
    my $in = shift // {};
    my $ret = {};
    foreach my $key (keys %$in) {
        if ($key =~ /^1\.(\d+)$/) {
            $ret->{$1} = $in->{$key};
        }
    }
    return $ret;
}

sub fan {
    my $cx = shift;
    my $names = $cx->fan_names() || {};
    my $states = $cx->fan_states() || {};
    my @ary = ();
    foreach my $idx (sort keys %$names) {
        my $name = $names->{$idx} // 'n/a';
        my $state = $states->{$idx} // 'n/a';
        push @ary, sprintf("%s: %s", $name, $state);
    }
    return join (', ', @ary);
}

sub vendor {
    my $cx = shift;
    my $mfg = $cx->entPhysicalMfgName(1) || {};
    my $vendor = $mfg->{1} || "aruba";
    return lc($vendor);
}

sub mac {
    my $cx = shift;
    my $b_mac = $cx->b_mac();
    return $b_mac if defined $b_mac and $b_mac !~ /^[0:]+$/;
    return $cx->orig_mac();
}

sub stack_info {
    my $cx = shift;
    my $vsf_topo = $cx->vsf_topology();
    if (defined $vsf_topo and $vsf_topo ne 'standalone') {
        my $member_prod_names = $cx->vsf_prod_names() || {};
        my $num_members = scalar keys %$member_prod_names;
        my $fullname = (values %$member_prod_names)[0];
        my $modelname = '';
        if ($fullname =~ /^(\S+)/) {
            $modelname = $1;
        }
        return sprintf("%s (stack of %d)", $modelname, $num_members);
    } else {
        return;
    }
}

sub model {
    my $cx = shift;
    my $model = $cx->entPhysicalModelName(1) || {};
    my $id = $cx->id();
    my $translated_id = &SNMP::translateObj($id) || $id;
    $translated_id =~ s/arubaWiredSwitch//i;
    my $name = $cx->stack_info() || $model->{1} || $translated_id;
    return defined $MODEL_MAP{$name} ? $MODEL_MAP{$name} : $name;
}

# Keep client tracking rows separate from the standard neighbour-table indexes.
# InetAddress is an OCTET STRING; check its length against the address type.
sub _cipt_clients {
    my ($cx, $family, $partial) = @_;
    my $types = $cx->cipt_addr_type() || {};
    my $addrs = $cx->cipt_addr() || {};
    my $ports = $cx->cipt_ifindex() || {};
    my %clients;
    foreach my $idx (keys %$types) {
        my $type = $types->{$idx};
        next unless defined $type;
        next unless ($family == 1 && ($type eq '1' || $type eq 'ipv4'))
            || ($family == 2 && ($type eq '2' || $type eq 'ipv6'));
        next unless $idx =~ /^6\.((?:\d+\.){5}\d+)\.(\d+)\.(\d+)$/;
        my ($mac_index, $vlan, $ip_index) = ($1, $2, $3);
        my @mac = split /\./, $mac_index;
        next if grep { $_ > 255 } @mac;
        next if ($mac[0] & 1) || !grep { $_ } @mac;
        next unless $vlan >= 1 && $vlan <= 4094 && $ip_index > 0;
        my $addr = $addrs->{$idx};
        next unless defined $addr && length($addr) == ($family == 1 ? 4 : 16);
        my $port = $ports->{$idx};
        next unless defined $port && $port =~ /^\d+$/ && $port > 0;
        my $row = "cipt.$idx";
        next if defined $partial && $row !~ /^\Q$partial\E(?:\.|$)/;
        $clients{$row} = {
            mac => join(':', map { sprintf '%02x', $_ } @mac),
            addr => SNMP::Info::munge_inetaddress($addr),
            port => $port,
        };
    }
    return \%clients;
}

sub _cipt_merge {
    my ($cx, $base, $family, $field, $partial) = @_;
    my %result = %{ $base || {} };
    my $clients = $cx->_cipt_clients($family, $partial);
    $result{$_} = $clients->{$_}{$field} for keys %$clients;
    return \%result;
}

sub at_paddr {
    my ($cx, $partial) = @_;
    return $cx->_cipt_merge($cx->SUPER::at_paddr($partial), 1, 'mac', $partial);
}

sub at_netaddr {
    my ($cx, $partial) = @_;
    return $cx->_cipt_merge($cx->SUPER::at_netaddr($partial), 1, 'addr', $partial);
}

sub ipv6_n2p_mac {
    my ($cx, $partial) = @_;
    return $cx->_cipt_merge($cx->SUPER::ipv6_n2p_mac(), 2, 'mac', $partial);
}

sub ipv6_n2p_addr {
    my ($cx, $partial) = @_;
    return $cx->_cipt_merge($cx->SUPER::ipv6_n2p_addr(), 2, 'addr', $partial);
}

sub ipv6_n2p_if {
    my ($cx, $partial) = @_;
    return $cx->_cipt_merge($cx->SUPER::ipv6_n2p_if(), 2, 'port', $partial);
}

# Transceivers are absent from ENTITY-MIB; add one module row per
# arubaWiredPmXcvrTable row, indexed above any real entPhysicalIndex.
my $XCVR_BASE = 1_000_000_000;

sub _xcvr_entities {
    my $cx = shift;
    my $descr = $cx->pm_xcvr_descr() || {};
    return {} unless %$descr;
    my $real = $cx->SUPER::e_index() || {};
    my $class = $cx->SUPER::e_class() || {};
    my $name = $cx->SUPER::e_name() || {};
    my $port = $cx->pm_xcvr_port() || {};
    my $product = $cx->pm_xcvr_product() || {};
    my $serial = $cx->pm_xcvr_serial() || {};
    my $type = $cx->pm_xcvr_type() || {};
    my ($chassis) = sort { $a <=> $b }
        grep { ($class->{$_} // '') eq 'chassis' } keys %$class;
    my %port_entity = map { $name->{$_} => $_ }
        grep { ($class->{$_} // '') eq 'port' && defined $name->{$_} }
        keys %$class;
    my %rows;
    foreach my $ifindex (grep { /^\d+$/ } keys %$descr) {
        my $idx = $XCVR_BASE + $ifindex;
        next if exists $real->{$idx};
        my $port_name = $port->{$ifindex} // $ifindex;
        $rows{$idx} = {
            e_index => $idx,
            e_class => 'module',
            e_descr => $descr->{$ifindex},
            e_name => "Transceiver $port_name",
            e_model => $product->{$ifindex},
            e_serial => $serial->{$ifindex},
            e_type => $type->{$ifindex},
            e_fru => 'true',
            e_parent => $port_entity{$port_name} // $chassis // 0,
        };
    }
    return \%rows;
}

sub _xcvr_merge {
    my ($cx, $method, $partial) = @_;
    my $super = "SUPER::$method";
    return $cx->$super($partial) if defined $partial;
    my $rows = $cx->_xcvr_entities();
    return $cx->$super() unless %$rows;
    my $base = $cx->$super();
    my %result = %{ $base || {} };
    $result{$_} = $rows->{$_}{$method} for keys %$rows;
    return \%result;
}

sub e_index  { my ($cx, $p) = @_; return $cx->_xcvr_merge('e_index', $p) }
sub e_class  { my ($cx, $p) = @_; return $cx->_xcvr_merge('e_class', $p) }
sub e_descr  { my ($cx, $p) = @_; return $cx->_xcvr_merge('e_descr', $p) }
sub e_name   { my ($cx, $p) = @_; return $cx->_xcvr_merge('e_name', $p) }
sub e_model  { my ($cx, $p) = @_; return $cx->_xcvr_merge('e_model', $p) }
sub e_serial { my ($cx, $p) = @_; return $cx->_xcvr_merge('e_serial', $p) }
sub e_type   { my ($cx, $p) = @_; return $cx->_xcvr_merge('e_type', $p) }
sub e_fru    { my ($cx, $p) = @_; return $cx->_xcvr_merge('e_fru', $p) }
sub e_parent { my ($cx, $p) = @_; return $cx->_xcvr_merge('e_parent', $p) }

sub os {
    return "arubaos-cx";
}

sub os_ver {
    my $cx = shift;
    my $ver_release = $cx->entPhysicalSoftwareRev(1) || {};
    return $ver_release->{1};
}

# agg_ports should return a hash with
# ifindex of member -> ifindex of aggregation
#
# arabuaos-cx has a broken implementation of 
# dot3adAggPortListPorts / 1.2.840.10006.300.43.1.1.2.1.1
# it return a comma seperated String with interface names
# (rfc states a PortList / bitmask of member ports)
#
# fetch value, split at comma, reverse search the interface hash
# for the interface index

sub agg_ports {
    my $cx = shift;
    my $ret = {};
    my $ports = $cx->raw_ad_lag_ports();
    my $interfaces = $cx->interfaces();
    foreach my $m ( keys %$ports ) {
        my $idx = $m;
        my $portlist = $ports->{$m};
        next unless $portlist;

        foreach my $ifname ( split(/,/, $portlist) ) {
            foreach my $ifindex ( keys %$interfaces) {
                if ($interfaces->{$ifindex} eq $ifname) {
                    $ret->{$ifindex} = $idx;
                }
            }
        }
    }
    return $ret;    
}

sub _agg_ports_walked { return qw/raw_ad_lag_ports/ }

# Overrides for VLAN & forwarding table methods
sub v_name {
    my $cx = shift;
    return _at_pbb_one($cx->iqb_v_name()) || $cx->SUPER::v_name();
}
sub qb_i_vlan {
    my $cx = shift;
    return _at_pbb_one($cx->iqb_i_vlan()) || $cx->SUPER::qb_i_vlan();
}
sub i_vlan_type {
    my $cx = shift;
    return _at_pbb_one($cx->iqb_i_vlan_type()) || $cx->SUPER::qb_i_vlan_type();
}
sub qb_v_egress {
    my $cx = shift;
    return $cx->iqb_v_egress() || $cx->SUPER::qb_v_egress();
}
sub qb_cv_egress {
    my $cx = shift;
    return $cx->iqb_cv_egress() || $cx->SUPER::qb_cv_egress();
}
sub qb_v_untagged {
    my $cx = shift;
    return $cx->iqb_v_untagged() || $cx->SUPER::qb_v_untagged();
}
sub qb_cv_untagged {
    my $cx = shift;
    return $cx->iqb_cv_untagged() || $cx->SUPER::qb_cv_untagged();
}

# AOS-CX 10.16 serves ieee8021SpanningTreeVersion 3 (mstp) in both of its
# modes. It reports CIST port role 6, outside the MIB's enum, on every port
# while running RPVST, and on link-down ports while running MSTP; it never
# reports a defined role under RPVST. So in the lowest component a defined
# role is MSTP, and role 6 on every row is RPVST when one of those ports is
# up; otherwise the mode is unknown.
sub _aoscx_stp_protocol {
    my $cx = shift;

    return $cx->{_aoscx_stp_protocol} if $cx->{_aoscx_stp_protocol};

    my $component = $cx->_ieee_stp_component();
    return unless defined $component;
    my $rows  = $cx->mstp_cist_p_role() || {};
    my %roles = map { ( split /\./ )[1] => $rows->{$_} }
        grep { ( split /\./ )[0] == $component } keys %$rows;
    return unless %roles;

    my @roles = values %roles;
    my $protocol;
    if ( grep { defined and /^(?:root|alternate|designated|backup)$/ }
        @roles )
    {
        $protocol = 'mstp';
    }
    elsif ( @roles == grep { defined and $_ eq '6' } @roles ) {
        $protocol = 'rapid-pvst'
            if $cx->_aoscx_any_port_up( [ keys %roles ] );
    }
    return unless defined $protocol;
    return $cx->{_aoscx_stp_protocol} = $protocol;
}

# Whether any of these bridge ports maps to an ifIndex that is up, or to
# a link aggregation with a member that is up. AOS-CX 10.16 reports a link
# aggregation's ifOperStatus as down while its members are up.
sub _aoscx_any_port_up {
    my ( $cx, $ports ) = @_;

    my $bp_index = $cx->bp_index()  || {};
    my $up       = $cx->i_up()      || {};
    my $lag_of   = $cx->agg_ports() || {};
    my %iids     = map { $_ => 1 } grep {defined} @{$bp_index}{@$ports};

    foreach my $iid ( keys %$up ) {
        next unless ( $up->{$iid} // '' ) eq 'up';
        my $lag = $lag_of->{$iid};
        return 1 if $iids{$iid} or ( defined $lag and $iids{$lag} );
    }
    return 0;
}

sub _ieee_stp_protocol {
    my $cx = shift;
    return ( $cx->_aoscx_stp_protocol() || '' ) eq 'mstp' ? 'mstp' : undef;
}

sub _ieee_stp_measured { return 1; }

sub hasRapidPVST {
    my $cx = shift;
    return ( $cx->_aoscx_stp_protocol() || '' ) eq 'rapid-pvst' ? 1 : 0;
}

sub stp_protocols {
    my $cx = shift;

    my $protocol = $cx->_aoscx_stp_protocol();
    return unless defined $protocol;
    return $cx->SUPER::stp_protocols() if $protocol eq 'mstp';
    return $cx->_aoscx_rpvst_protocols();
}

sub stp_trees {
    my $cx = shift;

    return unless $cx->_stp_default_context_ok();
    my $protocol = $cx->_aoscx_stp_protocol();
    return {} unless defined $protocol;
    return $cx->SUPER::stp_trees() if $protocol eq 'mstp';
    return $cx->_aoscx_rpvst_trees();
}

sub stp_trees_complete {
    my $cx = shift;

    my $protocol = $cx->_aoscx_stp_protocol();
    return 0 unless defined $protocol;
    return $cx->SUPER::stp_trees_complete() if $protocol eq 'mstp';
    return $cx->_aoscx_rpvst_trees_complete();
}

sub stp_vlan_map {
    my $cx = shift;

    my $protocol = $cx->_aoscx_stp_protocol();
    return unless defined $protocol;
    return $cx->SUPER::stp_vlan_map() if $protocol eq 'mstp';
    return $cx->_aoscx_rpvst_vlan_map();
}

sub stp_tree_ports {
    my ( $cx, $tree_key ) = @_;

    my $protocol = $cx->_aoscx_stp_protocol() // '';
    return $cx->SUPER::stp_tree_ports($tree_key) if $protocol eq 'mstp';
    $cx->_stp_tree_for_key($tree_key) or return;
    return $cx->_aoscx_rpvst_tree_ports($tree_key);
}

# dot1dStpPortState keeps MSTP's last values while AOS-CX runs RPVST
sub i_stp_state {
    my ( $cx, $partial ) = @_;

    return {} if ( $cx->_aoscx_stp_protocol() || '' ) eq 'rapid-pvst';
    return $cx->SUPER::i_stp_state($partial);
}

# RPVST keeps the operational edge flag per VLAN; the port's native VLAN is
# the row that describes the port
sub i_edgeport_oper {
    my ( $cx, $partial ) = @_;

    my $protocol = $cx->_aoscx_stp_protocol() or return {};
    return $cx->SUPER::i_edgeport_oper($partial) if $protocol eq 'mstp';

    my $native = $cx->i_vlan($partial)     || {};
    my $edge   = $cx->rpvst_pv_edge_oper() || {};
    my %i_edgeport;
    foreach my $iid ( keys %$native ) {
        next unless defined $native->{$iid};
        my $enabled = SNMP::Info::Bridge::_stp_enabled(
            $edge->{"$native->{$iid}.$iid"} );
        $i_edgeport{$iid} = $enabled if defined $enabled;
    }
    return \%i_edgeport;
}

# MAC part of this switch's CIST bridge ID, which RPVST also uses as the
# bridge MAC; on a VSX pair it is the VSX system MAC
sub _aoscx_bridge_mac {
    my $cx = shift;

    my $component = $cx->_ieee_stp_component();
    return unless defined $component;
    my $id    = ( $cx->mstp_cist_bridge() || {} )->{$component};
    my $parts = SNMP::Info::Bridge::_stp_decode_bridge_id($id) or return;
    return $parts->{mac};
}

sub _aoscx_rpvst_protocols { return ['rapid-pvst']; }

# One tree per RPVST-enabled VLAN. No 8-octet bridge ID is served, so IDs
# are built from parts; sys_id_ext is the VLAN only where the bridge is
# this switch and ExtendedSystemID is on.
sub _aoscx_rpvst_trees {
    my $cx = shift;

    return $cx->{_stp_trees} if $cx->{_stp_trees};

    my $admin     = $cx->rpvst_v_admin()         || {};
    my $priority  = $cx->rpvst_v_priority()      || {};
    my $root_prio = $cx->rpvst_v_root_priority() || {};
    my $root_mac  = $cx->rpvst_v_root_mac()      || {};
    my $own_mac = $cx->_aoscx_bridge_mac();
    my $ext_on  = SNMP::Info::Bridge::_stp_enabled( $cx->rpvst_ext_sysid() );

    my %trees;
    foreach my $vlan ( keys %$admin ) {
        next unless SNMP::Info::Bridge::_stp_enabled( $admin->{$vlan} );
        my $ext = $ext_on ? $vlan + 0 : undef;
        my $root_is_own
            = defined $own_mac
            && defined $root_mac->{$vlan}
            && $root_mac->{$vlan} eq $own_mac;
        $trees{"vlan.$vlan"} = {
            type           => 'vlan',
            id             => $vlan + 0,
            vlan           => $vlan + 0,
            protocol       => 'rapid-pvst',
            measured       => 1,
            ports_complete => 1,
            contexts       => [ { kind => 'none' } ],
            bridge         => scalar SNMP::Info::Bridge::_stp_bridge_id_parts(
                $priority->{$vlan}, $ext, $own_mac
            ),
            root => scalar SNMP::Info::Bridge::_stp_bridge_id_parts(
                $root_prio->{$vlan}, $root_is_own ? $ext : undef,
                $root_mac->{$vlan}
            ),
        };
    }
    $cx->{_stp_trees} = \%trees if keys %trees;
    return \%trees;
}

sub _aoscx_rpvst_trees_complete {
    my $cx = shift;

    my $trees = $cx->stp_trees() || {};
    return 0 unless keys %$trees;
    return 0 if $cx->_stp_walk_incomplete('rpvst_v_admin');
    return 1;
}

sub _aoscx_rpvst_vlan_map {
    my $cx = shift;

    my $trees = $cx->stp_trees() || {};
    return unless keys %$trees;
    my %map = map { $_->{vlan} => "vlan.$_->{vlan}" } values %$trees;
    return \%map;
}

# Rows indexed <VLAN>.<ifIndex>; the designated bridge column serves only a
# MAC, so its priority comes from the root or this switch when it matches
sub _aoscx_rpvst_tree_ports {
    my ( $cx, $tree_key ) = @_;

    my $tree     = ( $cx->stp_trees() || {} )->{$tree_key} or return;
    my $vlan     = $tree->{vlan};
    my $states   = $cx->rpvst_pv_state()  || {};
    my $roles    = $cx->rpvst_pv_role()   || {};
    my $d_bridge = $cx->rpvst_pv_bridge() || {};

    my %rows;
    foreach my $index ( keys %{ +{ %$states, %$roles, %$d_bridge } } ) {
        my ( $row_vlan, $iid ) = split /\./, $index, 2;
        next unless $row_vlan == $vlan;
        $rows{$iid} = {
            tree_type => $tree->{type},
            tree_id   => $tree->{id},
            state     => $states->{$index},
            role      => scalar _aoscx_rpvst_known_role( $roles->{$index} ),
            role_raw  => $roles->{$index},
            enabled   => undef,
            designated_bridge =>
                scalar _aoscx_rpvst_designated( $tree, $d_bridge->{$index} ),
            designated_port => undef,
        };
    }
    return \%rows;
}

sub _aoscx_rpvst_known_role {
    my $role = shift;
    return unless defined $role;
    return $role
        if $role =~ /^(?:root|alternate|designated|backup|master|disabled)$/;
    return;
}

# Priority and sys_id_ext from the root or this switch when the MAC is
# theirs, else undef
sub _aoscx_rpvst_designated {
    my ( $tree, $mac ) = @_;
    return unless defined $mac;

    foreach my $known ( $tree->{root}, $tree->{bridge} ) {
        next unless $known and defined $known->{mac};
        next unless $known->{mac} eq $mac;
        return SNMP::Info::Bridge::_stp_bridge_id_parts( $known->{priority},
            $known->{sys_id_ext}, $mac );
    }
    return SNMP::Info::Bridge::_stp_bridge_id_parts( undef, undef, $mac );
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::ArubaCX - SNMP Interface to L3 Devices running ArubaOS-CX

=head1 AUTHORS

Jeroen van Ingen

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $cx = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $cx->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for devices running ArubaOS-CX

=head2 Inherited Classes

=over

=item SNMP::Info::IEEE802_STP

=item SNMP::Info::Layer3

=item SNMP::Info::IEEE802_Bridge

=item SNMP::Info::IEEE802dot3ad

=back

=head2 Required MIBs

=over

=item F<ARUBAWIRED-CIPT-MIB>

=item F<ARUBAWIRED-FAN-MIB>

=item F<ARUBAWIRED-VSF-MIB>

=item F<ARUBAWIRED-POE-MIB>

=item F<ARUBAWIRED-POWERSUPPLY-MIB>

=item F<ARUBAWIRED-PM-MIB>

=item F<ARUBAWIRED-RPVST-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::IEEE802_STP> for its own MIB requirements.

See L<SNMP::Info::Layer3> for its own MIB requirements.

See L<SNMP::Info::IEEE802_Bridge> for its own MIB requirements.

See L<SNMP::Info::IEEE802dot3ad> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $cx->stack_info()

If the device supports VSF stacking and is not in standalone mode, returns
a string describing the switch family and the number of stack members.
Example return value: '6300M (stack of 2)'. Will return undef when VSF is not
supported or when the device is VSF standalone.

=item $cx->model()

Known product codes are translated to readable model names.

Returns L<stack_info()> if defined, otherwise will fall back to returning the
model from C<entPhysicalModelName.1>; if that's also not set, will use
C<sysObjectID> as a last resort, stripping 'arubaWiredSwitch' from the value.

=item $cx->vendor()

Returns (lowercased) value for C<entPhysicalMfgName.1>, or 'aruba'.

=item $cx->mac()

Returns the system MAC address from C<dot1dBaseBridgeAddress>. Interface 1
is a front panel port with its own MAC address. Falls back to
C<ifPhysAddress.1> when the bridge address is missing or all zeros.

=item $cx->os()

Returns 'arubaos-cx'.

=item $cx->os_ver()

Returns the software version. Either C<entPhysicalSoftwareRev.1> or
extracted from C<sysDescr>.

=item $cx->fan()

Returns a string with status information for all fans listed in
C<ARUBAWIRED-FAN-MIB>.

=item $cx->rpvst_ext_sysid()

Whether this switch puts the VLAN in the system ID extension of its RPVST
bridge IDs.
(C<arubaWiredRpvstExtendedSystemID>)

=back

=head2 Overrides

=over

=item $cx->hasRapidPVST()

Returns 1 when every C<ieee8021MstpCistPortRole> row of the lowest
component reads 6, which AOS-CX reports on every port while running
RPVST; else 0.
(C<ieee8021MstpCistPortRole>)

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Globals imported from SNMP::Info::IEEE802_Bridge

See documentation in L<SNMP::Info::IEEE802_Bridge> for details.

=head2 Globals imported from SNMP::Info::IEEE802dot3ad

See documentation in L<SNMP::Info::IEEE802dot3ad> for details.

=head2 Client IP tracking

=over

=item $cx->at_paddr()

=item $cx->at_netaddr()

Add IPv4 client tracking MAC/IP pairs to the inherited ARP tables.

=item $cx->ipv6_n2p_mac()

=item $cx->ipv6_n2p_addr()

=item $cx->ipv6_n2p_if()

Add IPv6 client tracking MAC/IP/interface rows to the inherited neighbour tables.
Client tracking must already be enabled on the switch. These methods only read
its data; they do not enable tracking. Unsupported or empty tracking tables
leave the inherited results intact. Tracking row keys use a C<cipt.> prefix
followed by the MAC/VLAN/IP index, preserving multiple addresses for a client.
Malformed rows and unsupported address types are omitted.

=back

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $cx->peth_port_power()

Power supplied by PoE ports, in milliwatts.
(C<arubaWiredPoePethPsePortAveragePower>)

=back

=head2 Transceivers

Columns of C<ARUBAWIRED-PM-MIB::arubaWiredPmXcvrTable>, indexed by ifIndex.

=over

=item $cx->pm_xcvr_port()

(C<arubaWiredPmXcvrPortDesc>)

=item $cx->pm_xcvr_descr()

(C<arubaWiredPmXcvrDescription>)

=item $cx->pm_xcvr_product()

(C<arubaWiredPmXcvrProductNum>)

=item $cx->pm_xcvr_serial()

(C<arubaWiredPmXcvrSerialNum>)

=item $cx->pm_xcvr_type()

(C<arubaWiredPmXcvrType>)

=back

=head2 Aruba RPVST VLAN Table (C<arubaWiredRpvstVlanTable>)

Indexed by VLAN.

=over

=item $cx->rpvst_v_admin()

Returns reference to hash. Whether RPVST is enabled on the VLAN.
(C<arubaWiredRpvstVlanRpvstAdminStatus>)

=item $cx->rpvst_v_priority()

Returns reference to hash. This switch's bridge priority on the VLAN.
(C<arubaWiredRpvstVlanPriority>)

=item $cx->rpvst_v_root_priority()

Returns reference to hash. The root bridge priority on the VLAN.
(C<arubaWiredRpvstVlanRootPriority>)

=item $cx->rpvst_v_root_mac()

Returns reference to hash. The root bridge MAC address on the VLAN.
(C<arubaWiredRpvstVlanRootMacAddress>)

=back

=head2 Aruba RPVST Port VLAN Table (C<arubaWiredRpvstPortVlanTable>)

Indexed by VLAN and ifIndex.

=over

=item $cx->rpvst_pv_state()

Returns reference to hash. The port's state on the VLAN.
(C<arubaWiredRpvstPortVlanState>)

=item $cx->rpvst_pv_role()

Returns reference to hash. The port's role on the VLAN.
(C<arubaWiredRpvstPortVlanRole>)

=item $cx->rpvst_pv_bridge()

Returns reference to hash. The MAC address of the designated bridge on
the port's segment.
(C<arubaWiredRpvstPortVlanDesigBridge>)

=item $cx->rpvst_pv_edge_oper()

Returns reference to hash. Whether the port is operating as an edge port
on the VLAN.
(C<arubaWiredRpvstPortVlanOperEdge>)

=back

=head2 Overrides

=over

=item $cx->e_index()

=item $cx->e_class()

=item $cx->e_descr()

=item $cx->e_name()

=item $cx->e_model()

=item $cx->e_serial()

=item $cx->e_type()

=item $cx->e_fru()

=item $cx->e_parent()

Add one C<module> row per transceiver to the C<ENTITY-MIB> data, indexed
1000000000 plus the port ifIndex. The parent is the C<port> entity whose
name matches C<arubaWiredPmXcvrPortDesc>, else the first chassis, else 0.
A row whose index is already a real C<entPhysicalIndex> is skipped. Partial
fetches and devices without transceiver data return the inherited result.

=item $cx->stp_protocols()

=item $cx->stp_trees()

=item $cx->stp_trees_complete()

=item $cx->stp_vlan_map()

=item $cx->stp_tree_ports($tree_key)

AOS-CX serves C<ieee8021SpanningTreeVersion> 3 in both of its modes, so
the mode comes from C<ieee8021MstpCistPortRole>, which reads 6 on every
port under RPVST and on link-down ports under MSTP. Any row with a
defined role is MSTP; every row 6 with at least one of those ports up
is RPVST. A port is up when C<i_up()> says so for it or, for a link
aggregation, for any of its members (C<agg_ports()>), since AOS-CX
reports a link aggregation's C<ifOperStatus> as down while its members
are up. Only the lowest component is read.
Under MSTP these return the L<SNMP::Info::IEEE802_STP> results, with
C<measured> 1.

Under RPVST they return C<rapid-pvst> trees from F<ARUBAWIRED-RPVST-MIB>:
one C<vlan.N> tree per VLAN with RPVST enabled, and C<stp_vlan_map()>
maps each such VLAN to its tree. No 8-octet bridge ID is served, so
bridge IDs are built from their parts with C<raw> undef. The bridge MAC
is the MAC part of C<ieee8021MstpCistBridgeIdentifier>, the VSX system
MAC on a VSX pair. C<sys_id_ext> is the VLAN where the bridge is this
switch and C<rpvst_ext_sysid()> is true, else undef. Port rows come
from C<arubaWiredRpvstPortVlanTable>, with the state as served, the
role where it is one the API names, C<enabled> and C<designated_port>
undef. That table serves the designated bridge as a MAC only, so its
priority and C<sys_id_ext> are those of the root or this switch when
the MAC is theirs, else undef.

When the mode is unknown (no rows, or role 6 on every row with every
port down) they report nothing: no
protocols, an empty tree list, C<stp_trees_complete()> 0, no VLAN map, and an
C<error()> from C<stp_tree_ports()>. C<hasMSTP()> is 1 only under MSTP,
and C<hasSTP()> and C<hasRSTP()> are always 0, since AOS-CX offers only
MSTP and RPVST.

=item $cx->i_stp_state()

Returns an empty hash under RPVST, where C<dot1dStpPortState> keeps
MSTP's last values. Otherwise the inherited result.

=item $cx->i_edgeport_oper()

Returns reference to hash of ifIndex to 1 or 0. Under MSTP, the inherited
result. Under RPVST, C<arubaWiredRpvstPortVlanOperEdge> on the row for the
port's native VLAN (C<i_vlan()>); a port with no such row is absent.
Returns an empty hash when the mode is unknown. C<i_edgeport_admin()> is
the inherited method in every mode. Whether this value reports an
operational edge port as true has not been verified.

=item C<agg_ports>

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.

=item C<v_name>
=item C<qb_i_vlan>
=item C<i_vlan_type>
=item C<qb_v_egress>
=item C<qb_cv_egress>
=item C<qb_v_untagged>
=item C<qb_cv_untagged>
All overridden to return the VLAN data structures that we'd expect for a
device that implements C<Q-BRIDGE-MIB>, but with data from
L<SNMP::Info::IEEE8021_Bridge> at PBB 1.

=back

=head2 Table Methods imported from SNMP::Info::IEEE802_STP

See documentation in L<SNMP::Info::IEEE802_STP> for details.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Table Methods imported from SNMP::Info::IEEE802_Bridge

See documentation in L<SNMP::Info::IEEE802_Bridge> for details.

=head2 Table Methods imported from SNMP::Info::IEEE802dot3ad

See documentation in L<SNMP::Info::IEEE802dot3ad> for details.

=cut
