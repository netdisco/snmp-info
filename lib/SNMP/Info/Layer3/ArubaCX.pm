# SNMP::Info::Layer3::ArubaCX
#
# Copyright (c) 2026 SNMP::Info Developers
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
use SNMP::Info::IEEE802dot3ad;
use SNMP::Info::IEEE802_STP;
use SNMP::Info::Layer3;
use SNMP::Info::IEEE802_Bridge;
use Socket ();

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

our ( $VERSION, %GLOBALS, %MIBS, %FUNCS, %MODEL_MAP, %MUNGE );

$VERSION = '3.985005';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::IEEE802_STP::MIBS,
    %SNMP::Info::IEEE802dot3ad::MIBS,
    %SNMP::Info::IEEE802_Bridge::MIBS,
    'ARUBAWIRED-CIPT-MIB'        => 'arubaWiredCiptClientIpAddress',
    'ARUBAWIRED-FAN-MIB'         => 'arubaWiredFanName',
    'ARUBAWIRED-VSF-MIB'         => 'arubaWiredVsfTrapEnable',
    'ARUBAWIRED-POE-MIB'         => 'arubaWiredPoePethPsePortAveragePower',
    'ARUBAWIRED-POWERSUPPLY-MIB' => 'arubaWiredPSUName',
    'ARUBAWIRED-PM-MIB'          => 'arubaWiredPmXcvrDescription',
    'ARUBAWIRED-RPVST-MIB'       => 'arubaWiredRpvstExtendedSystemID',
    'ARUBAWIRED-VSX-MIB'         => 'arubaWiredVsxDeviceRole',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::IEEE802_STP::GLOBALS,
    %SNMP::Info::IEEE802_Bridge::GLOBALS,
    'ps1_type'        => 'arubaWiredPSUProductName.1.1',
    'ps2_type'        => 'arubaWiredPSUProductName.1.2',
    'ps1_status'      => 'arubaWiredPSUState.1.1',
    'ps2_status'      => 'arubaWiredPSUState.1.2',
    'vsf_topology'    => 'arubaWiredVsfTopology',
    'rpvst_ext_sysid' => 'arubaWiredRpvstExtendedSystemID',

    # ARUBAWIRED-VSX-MIB
    'vsx_role'            => 'arubaWiredVsxDeviceRole',
    'vsx_system_mac'      => 'arubaWiredVsxDeviceOperSystemID',
    'vsx_isl_port'        => 'arubaWiredVsxIslPort',
    'vsx_isl_state'       => 'arubaWiredVsxIslOperState',
    'vsx_keepalive_peer'  => 'arubaWiredVsxKeepAlivePeerIPAddr',
    'vsx_keepalive_state' => 'arubaWiredVsxKeepAliveOperState',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::IEEE802_STP::FUNCS,
    %SNMP::Info::IEEE802dot3ad::FUNCS,
    %SNMP::Info::IEEE802_Bridge::FUNCS,
    'peth_port_power'  => 'arubaWiredPoePethPsePortAveragePower',
    'fan_names'        => 'arubaWiredFanName',
    'fan_states'       => 'arubaWiredFanState',
    'psu_names'        => 'arubaWiredPSUName',
    'psu_types'        => 'arubaWiredPSUProductName',
    'psu_states'       => 'arubaWiredPSUState',
    'vsf_prod_names'   => 'arubaWiredVsfMemberProductName',
    'cipt_addr_type'   => 'arubaWiredCiptClientIpAddrType',
    'cipt_addr'        => 'arubaWiredCiptClientIpAddress',
    'cipt_ifindex'     => 'arubaWiredCiptClientPortIfIndex',
    'raw_ad_lag_ports' => 'dot3adAggPortListPorts',        # unmunged raw data
    'pm_xcvr_port'     => 'arubaWiredPmXcvrPortDesc',
    'pm_xcvr_descr'    => 'arubaWiredPmXcvrDescription',
    'pm_xcvr_product'  => 'arubaWiredPmXcvrProductNum',
    'pm_xcvr_serial'   => 'arubaWiredPmXcvrSerialNum',
    'pm_xcvr_type'     => 'arubaWiredPmXcvrType',

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

    # ARUBAWIRED-VSX-MIB::arubaWiredVsxAggregatorTable
    'vsx_agg_type' => 'arubaWiredVsxAggregatorType',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::IEEE802_STP::MUNGE,
    %SNMP::Info::IEEE802dot3ad::MUNGE,
    %SNMP::Info::IEEE802_Bridge::MUNGE,
    'rpvst_v_root_mac'   => \&SNMP::Info::munge_mac,
    'rpvst_pv_bridge'    => \&SNMP::Info::munge_mac,
    'vsx_system_mac'     => \&_munge_vsx_mac,
    'vsx_keepalive_peer' => \&_munge_vsx_addr,
);

# The VSX system ID is a MAC in text; the keepalive peer is an InetAddress
# that AOS-CX can serve as text. Accept text or raw octets for both, and
# format a text address as its octets would be, so both forms compare equal
sub _munge_vsx_mac {
    my $value = shift;
    return unless defined $value;
    if ( $value =~ /^[[:xdigit:]]{2}(?:[:-][[:xdigit:]]{2}){5}$/ ) {
        ( my $mac = lc $value ) =~ tr/-/:/;
        return $mac;
    }
    return SNMP::Info::munge_mac($value) if length $value == 6;
    return;
}

sub _munge_vsx_addr {
    my $value = shift;
    return unless defined $value and length $value;
    my $octets = Socket::inet_pton( Socket::AF_INET(), $value )
        // Socket::inet_pton( Socket::AF_INET6(), $value );
    unless ( defined $octets ) {
        return unless length $value == 4 or length $value == 16;
        $octets = $value;
    }
    my $addr = SNMP::Info::munge_inetaddress($octets);
    return unless defined $addr;
    return if $addr =~ /^[0:.]+$/;
    return $addr;
}

# Product codes reported by ENTITY-MIB or the product OID.
%MODEL_MAP = ( 'JL719C' => '8360-48Y6C v2', );

sub _at_pbb_one {
    my $in  = shift // {};
    my $ret = {};
    foreach my $key ( keys %$in ) {
        if ( $key =~ /^1\.(\d+)$/ ) {
            $ret->{$1} = $in->{$key};
        }
    }
    return unless %$ret;
    return $ret;
}

sub fan {
    my $cx     = shift;
    my $names  = $cx->fan_names()  || {};
    my $states = $cx->fan_states() || {};
    my @ary    = ();
    foreach my $idx ( sort keys %$names ) {
        my $name  = $names->{$idx}  // 'n/a';
        my $state = $states->{$idx} // 'n/a';
        push @ary, sprintf( "%s: %s", $name, $state );
    }
    return join( ', ', @ary );
}

sub vendor {
    my $cx     = shift;
    my $mfg    = $cx->entPhysicalMfgName(1) || {};
    my $vendor = $mfg->{1}                  || "aruba";
    return lc($vendor);
}

sub mac {
    my $cx    = shift;
    my $b_mac = $cx->b_mac();
    return $b_mac if defined $b_mac and $b_mac !~ /^[0:]+$/;
    return $cx->orig_mac();
}

sub stack_info {
    my $cx       = shift;
    my $vsf_topo = $cx->vsf_topology();
    if ( defined $vsf_topo and $vsf_topo ne 'standalone' ) {
        my $member_prod_names = $cx->vsf_prod_names() || {};
        my $num_members       = scalar keys %$member_prod_names;
        my $fullname          = ( values %$member_prod_names )[0];
        my $modelname         = '';
        if ( $fullname =~ /^(\S+)/ ) {
            $modelname = $1;
        }
        return sprintf( "%s (stack of %d)", $modelname, $num_members );
    }
    else {
        return;
    }
}

sub model {
    my $cx            = shift;
    my $model         = $cx->entPhysicalModelName(1) || {};
    my $id            = $cx->id();
    my $translated_id = &SNMP::translateObj($id) || $id;
    $translated_id =~ s/arubaWiredSwitch//i;
    my $name = $cx->stack_info() || $model->{1} || $translated_id;
    return defined $MODEL_MAP{$name} ? $MODEL_MAP{$name} : $name;
}

# Keep client tracking rows separate from the standard neighbour-table
# indexes.
# InetAddress is an OCTET STRING; check its length against the address type.
sub _cipt_clients {
    my ( $cx, $family, $partial ) = @_;
    my $types = $cx->cipt_addr_type() || {};
    my $addrs = $cx->cipt_addr()      || {};
    my $ports = $cx->cipt_ifindex()   || {};
    my %clients;
    foreach my $idx ( keys %$types ) {
        my $type = $types->{$idx};
        next unless defined $type;
        next
            unless ( $family == 1 && ( $type eq '1' || $type eq 'ipv4' ) )
            || ( $family == 2 && ( $type eq '2' || $type eq 'ipv6' ) );
        next unless $idx =~ /^6\.((?:\d+\.){5}\d+)\.(\d+)\.(\d+)$/;
        my ( $mac_index, $vlan, $ip_index ) = ( $1, $2, $3 );
        my @mac = split /\./, $mac_index;
        next if grep                     { $_ > 255 } @mac;
        next if ( $mac[0] & 1 ) || !grep {$_} @mac;
        next unless $vlan >= 1 && $vlan <= 4094 && $ip_index > 0;
        my $addr = $addrs->{$idx};
        next
            unless defined $addr
            && length($addr) == ( $family == 1 ? 4 : 16 );
        my $port = $ports->{$idx};
        next unless defined $port && $port =~ /^\d+$/ && $port > 0;
        my $row = "cipt.$idx";
        next if defined $partial && $row !~ /^\Q$partial\E(?:\.|$)/;
        $clients{$row} = {
            mac  => join( ':', map { sprintf '%02x', $_ } @mac ),
            addr => SNMP::Info::munge_inetaddress($addr),
            port => $port,
        };
    }
    return \%clients;
}

sub _cipt_merge {
    my ( $cx, $base, $family, $field, $partial ) = @_;
    my %result  = %{ $base || {} };
    my $clients = $cx->_cipt_clients( $family, $partial );
    $result{$_} = $clients->{$_}{$field} for keys %$clients;
    return \%result;
}

sub at_paddr {
    my ( $cx, $partial ) = @_;
    return $cx->_cipt_merge( $cx->SUPER::at_paddr($partial), 1, 'mac',
        $partial );
}

sub at_netaddr {
    my ( $cx, $partial ) = @_;
    return $cx->_cipt_merge( $cx->SUPER::at_netaddr($partial),
        1, 'addr', $partial );
}

sub ipv6_n2p_mac {
    my ( $cx, $partial ) = @_;
    return $cx->_cipt_merge( $cx->SUPER::ipv6_n2p_mac(), 2, 'mac', $partial );
}

sub ipv6_n2p_addr {
    my ( $cx, $partial ) = @_;
    return $cx->_cipt_merge( $cx->SUPER::ipv6_n2p_addr(), 2, 'addr',
        $partial );
}

sub ipv6_n2p_if {
    my ( $cx, $partial ) = @_;
    return $cx->_cipt_merge( $cx->SUPER::ipv6_n2p_if(), 2, 'port', $partial );
}

# Transceivers are absent from ENTITY-MIB; add one module row per
# arubaWiredPmXcvrTable row, indexed above any real entPhysicalIndex.
my $XCVR_BASE = 1_000_000_000;

sub _xcvr_entities {
    my $cx    = shift;
    my $descr = $cx->pm_xcvr_descr() || {};
    return {} unless %$descr;
    my $real      = $cx->SUPER::e_index()  || {};
    my $class     = $cx->SUPER::e_class()  || {};
    my $name      = $cx->SUPER::e_name()   || {};
    my $port      = $cx->pm_xcvr_port()    || {};
    my $product   = $cx->pm_xcvr_product() || {};
    my $serial    = $cx->pm_xcvr_serial()  || {};
    my $type      = $cx->pm_xcvr_type()    || {};
    my ($chassis) = sort { $a <=> $b }
        grep { ( $class->{$_} // '' ) eq 'chassis' } keys %$class;
    my %port_entity = map { $name->{$_} => $_ }
        grep { ( $class->{$_} // '' ) eq 'port' && defined $name->{$_} }
        keys %$class;
    my %rows;

    foreach my $ifindex ( grep {/^\d+$/} keys %$descr ) {
        my $idx = $XCVR_BASE + $ifindex;
        next if exists $real->{$idx};
        my $port_name = $port->{$ifindex} // $ifindex;
        $rows{$idx} = {
            e_index  => $idx,
            e_class  => 'module',
            e_descr  => $descr->{$ifindex},
            e_name   => "Transceiver $port_name",
            e_model  => $product->{$ifindex},
            e_serial => $serial->{$ifindex},
            e_type   => $type->{$ifindex},
            e_fru    => 'true',
            e_parent => $port_entity{$port_name} // $chassis // 0,
        };
    }
    return \%rows;
}

sub _xcvr_merge {
    my ( $cx, $method, $partial ) = @_;
    my $super = "SUPER::$method";
    return $cx->$super($partial) if defined $partial;
    my $rows = $cx->_xcvr_entities();
    return $cx->$super() unless %$rows;
    my $base   = $cx->$super();
    my %result = %{ $base || {} };
    $result{$_} = $rows->{$_}{$method} for keys %$rows;
    return \%result;
}

sub e_index { my ( $cx, $p ) = @_; return $cx->_xcvr_merge( 'e_index', $p ) }
sub e_class { my ( $cx, $p ) = @_; return $cx->_xcvr_merge( 'e_class', $p ) }
sub e_descr { my ( $cx, $p ) = @_; return $cx->_xcvr_merge( 'e_descr', $p ) }
sub e_name  { my ( $cx, $p ) = @_; return $cx->_xcvr_merge( 'e_name',  $p ) }
sub e_model { my ( $cx, $p ) = @_; return $cx->_xcvr_merge( 'e_model', $p ) }

sub e_serial {
    my ( $cx, $p ) = @_;
    return $cx->_xcvr_merge( 'e_serial', $p );
}
sub e_type { my ( $cx, $p ) = @_; return $cx->_xcvr_merge( 'e_type', $p ) }
sub e_fru  { my ( $cx, $p ) = @_; return $cx->_xcvr_merge( 'e_fru',  $p ) }

sub e_parent {
    my ( $cx, $p ) = @_;
    return $cx->_xcvr_merge( 'e_parent', $p );
}

sub os {
    return "arubaos-cx";
}

sub os_ver {
    my $cx          = shift;
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
    my $cx         = shift;
    my $ret        = {};
    my $ports      = $cx->raw_ad_lag_ports();
    my $interfaces = $cx->interfaces();
    foreach my $m ( keys %$ports ) {
        my $idx      = $m;
        my $portlist = $ports->{$m};
        next unless $portlist;

        foreach my $ifname ( split( /,/, $portlist ) ) {
            foreach my $ifindex ( keys %$interfaces ) {
                if ( $interfaces->{$ifindex} eq $ifname ) {
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
    return _at_pbb_one( $cx->iqb_v_name() ) || $cx->SUPER::v_name();
}

sub qb_i_vlan {
    my $cx = shift;
    return _at_pbb_one( $cx->iqb_i_vlan() ) || $cx->SUPER::qb_i_vlan();
}

# AOS-CX serves PVID 0, which Q-BRIDGE-MIB forbids, on ports with no native
# VLAN in effect; leave those ports out, as for a port with no PVID row
sub i_vlan {
    my ( $cx, $partial ) = @_;
    my $i_vlan = $cx->SUPER::i_vlan($partial) or return;
    my %native = map { $_ => $i_vlan->{$_} }
        grep { ( $i_vlan->{$_} // '0' ) ne '0' } keys %$i_vlan;
    return \%native;
}

sub i_untagged { goto &i_vlan }

sub i_vlan_type {
    my $cx = shift;
    return _at_pbb_one( $cx->iqb_i_vlan_type() )
        || $cx->SUPER::qb_i_vlan_type();
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
# up. A switch that serves no CIST port role is read as BRIDGE-MIB alone
# (dot1d); any other case is unknown.
sub _aoscx_stp_protocol {
    my $cx = shift;

    return $cx->{_aoscx_stp_protocol} if $cx->{_aoscx_stp_protocol};

    my $component = $cx->_ieee_stp_component();
    return $cx->{_aoscx_stp_protocol} = 'dot1d' unless defined $component;
    my $rows  = $cx->mstp_cist_p_role() || {};
    my %roles = map { ( split /\./ )[1] => $rows->{$_} }
        grep { ( split /\./ )[0] == $component } keys %$rows;
    return $cx->{_aoscx_stp_protocol} = 'dot1d' unless %roles;

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

# MSTP is read from the IEEE MIBs, and dot1d from BRIDGE-MIB, both by the
# inherited methods
sub _aoscx_inherits_stp {
    my $cx       = shift;
    my $protocol = $cx->_aoscx_stp_protocol() // '';
    return $protocol eq 'mstp' || $protocol eq 'dot1d';
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

    return $cx->SUPER::stp_protocols() if $cx->_aoscx_inherits_stp();
    my $protocol = $cx->_aoscx_stp_protocol();
    return unless defined $protocol;
    return $cx->_aoscx_rpvst_protocols();
}

sub stp_trees {
    my $cx = shift;

    return unless $cx->_stp_default_context_ok();
    return $cx->SUPER::stp_trees() if $cx->_aoscx_inherits_stp();
    my $protocol = $cx->_aoscx_stp_protocol();
    return {} unless defined $protocol;
    return $cx->_aoscx_rpvst_trees();
}

sub stp_trees_complete {
    my $cx = shift;

    return $cx->SUPER::stp_trees_complete() if $cx->_aoscx_inherits_stp();
    my $protocol = $cx->_aoscx_stp_protocol();
    return 0 unless defined $protocol;
    return $cx->_aoscx_rpvst_trees_complete();
}

sub stp_vlan_map {
    my $cx = shift;

    return $cx->SUPER::stp_vlan_map() if $cx->_aoscx_inherits_stp();
    my $protocol = $cx->_aoscx_stp_protocol();
    return unless defined $protocol;
    return $cx->_aoscx_rpvst_vlan_map();
}

sub stp_tree_ports {
    my ( $cx, $tree_key ) = @_;

    return $cx->SUPER::stp_tree_ports($tree_key)
        if $cx->_aoscx_inherits_stp();
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

    return $cx->SUPER::i_edgeport_oper($partial)
        if $cx->_aoscx_inherits_stp();
    $cx->_aoscx_stp_protocol() or return {};

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

# The ISL is served by interface name; "0" or empty means none is configured
sub _vsx_isl_ifindex {
    my $cx   = shift;
    my $name = $cx->vsx_isl_port();
    return unless defined $name and length $name and $name ne '0';
    my $interfaces = $cx->interfaces() || {};
    my ($ifindex) = grep { ( $interfaces->{$_} // '' ) eq $name }
        sort { $a <=> $b } keys %$interfaces;
    return $ifindex;
}

# One VSX domain per switch, from scalars, as VOSS reports its virtual IST
sub _lag_vendor_domains {
    my $cx = shift;

    my $role      = $cx->vsx_role() // '';
    my $peer_link = $cx->_vsx_isl_ifindex();
    return {}
        unless $role eq 'primary'
        or $role eq 'secondary'
        or defined $peer_link;

    my %value_of = (
        system_mac => scalar $cx->vsx_system_mac(),
        role       => scalar $cx->vsx_role(),
        peer       => scalar $cx->vsx_keepalive_peer(),
        status     => scalar $cx->vsx_isl_state(),
        peer_link  => $peer_link,
    );
    my %leaf_of = (
        system_mac => 'arubaWiredVsxDeviceOperSystemID',
        role       => 'arubaWiredVsxDeviceRole',
        peer       => 'arubaWiredVsxKeepAlivePeerIPAddr',
        status     => 'arubaWiredVsxIslOperState',
        peer_link  => 'arubaWiredVsxIslPort',
    );
    my $domain = { kind => 'vsx', sources => {} };
    foreach my $field ( grep { defined $value_of{$_} } keys %value_of ) {
        $domain->{$field} = $value_of{$field};
        $domain->{sources}{$field} = "ARUBAWIRED-VSX-MIB::$leaf_of{$field}";
    }
    return { vsx => $domain };
}

sub _lag_vendor_walked { return qw/vsx_agg_type/ }

# Multi-chassis LAGs get mc only while the VSX domain is served, as VOSS
# does for split MLTs; a LAG the standard table does not list gets a record
sub _lag_vendor_groups {
    my ( $cx, $groups ) = @_;

    return unless %{ $cx->_lag_vendor_domains() };
    my $types      = $cx->vsx_agg_type() || {};
    my $interfaces = $cx->interfaces()   || {};
    foreach my $ifindex ( keys %$types ) {
        next unless ( $types->{$ifindex} // '' ) eq 'multiChassis';
        my $name   = $interfaces->{$ifindex} // $ifindex;
        my $record = $groups->{$ifindex}
            ||= SNMP::Info::IEEE802dot3ad::_lag_new_record();
        $record->{mc} = {
            kind   => 'vsx',
            group  => $name =~ /^lag(\d+)$/ ? $1 + 0 : $name,
            domain => 'vsx',
            state  => undef,
        };
        $record->{sources}{mc}
            = 'ARUBAWIRED-VSX-MIB::arubaWiredVsxAggregatorType';
    }
    my $isl = $cx->_vsx_isl_ifindex();
    return unless defined $isl;
    my $record = $groups->{$isl}
        ||= SNMP::Info::IEEE802dot3ad::_lag_new_record();
    $record->{peer_link} = 1;
    $record->{sources}{peer_link}
        = 'ARUBAWIRED-VSX-MIB::arubaWiredVsxIslPort';
    return;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::ArubaCX - SNMP Interface to L3 Devices running ArubaOS-CX

=head1 AUTHORS

Jeroen van Ingen, SNMP::Info Developers

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

=head2 Spanning Tree

AOS-CX runs MSTP or RPVST. It serves C<ieee8021SpanningTreeVersion> 3 in
both modes, so this class reads the mode from C<ieee8021MstpCistPortRole>
in the lowest component:

=over

=item * B<MSTP>: any row has a role defined in the MIB. Link-down ports
read 6, which is outside the MIB's enumeration.

=item * B<RPVST>: every row reads 6, and at least one of those ports is
up. A link aggregation counts as up when any member is up
(C<i_up()>, C<agg_ports()>), since AOS-CX reports its C<ifOperStatus> as
down while its members are up.

=item * B<BRIDGE-MIB only>: no row at all, as on a switch that does not
serve the IEEE MIBs.

=item * B<Unknown>: any other case, such as every row 6 with every port
down, or 6 mixed with an undefined role.

=back

Under MSTP the tree methods return the L<SNMP::Info::IEEE802_STP> results,
with C<measured> 1. Under RPVST they read F<ARUBAWIRED-RPVST-MIB>. With
BRIDGE-MIB only they return the L<SNMP::Info::Bridge> tree, C<dot1d> with
C<measured> 0. When the mode is unknown they report nothing. AOS-CX
offers no plain STP or RSTP mode, so C<hasSTP()> and C<hasRSTP()> always
return 0, and C<hasMSTP()> returns 1 only under MSTP.

=head2 VLANs

AOS-CX serves VLAN data in two standard MIBs, F<IEEE8021-Q-BRIDGE-MIB>
and F<Q-BRIDGE-MIB>. The IEEE MIB can describe several bridges in one
device, so each of its indexes starts with a bridge number. A switch has
one bridge, numbered 1. C<v_name()>, C<qb_i_vlan()> and C<i_vlan_type()>
read the IEEE MIB rows of bridge 1 and drop that number, so their keys
match F<Q-BRIDGE-MIB>. The port list methods keep the IEEE keys. Each
VLAN method falls back to F<Q-BRIDGE-MIB> on its own when the IEEE MIB has no
rows for it, since a switch can serve a column in one MIB and not the
other.

AOS-CX serves a native VLAN (PVID) of 0, which both MIBs forbid, on
ports with no native VLAN in effect, such as routed ports and trunks
that do not carry their configured native VLAN. A 0 does not mean
VLAN 1. C<qb_i_vlan()> returns it as served; C<i_vlan()> leaves those
ports out.

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

=item $cx->ps1_type()

Product name of the power supply in group 1, slot 1.
(C<arubaWiredPSUProductName.1.1>)

=item $cx->ps2_type()

Product name of the power supply in group 1, slot 2.
(C<arubaWiredPSUProductName.1.2>)

=item $cx->ps1_status()

Status of the power supply in group 1, slot 1, as served.
(C<arubaWiredPSUState.1.1>)

=item $cx->ps2_status()

Status of the power supply in group 1, slot 2, as served.
(C<arubaWiredPSUState.1.2>)

=item $cx->vsf_topology()

The physical topology of the VSF stack: C<standalone>, C<chain> or
C<ring>. Used by C<stack_info()>.
(C<arubaWiredVsfTopology>)

=item $cx->rpvst_ext_sysid()

Returns C<true> or C<false>: whether this switch puts the VLAN in the
system ID extension of its RPVST bridge IDs.
(C<arubaWiredRpvstExtendedSystemID>)

=item $cx->vsx_role()

The switch's VSX role: C<primary>, C<secondary> or C<notConfigured>.
(C<arubaWiredVsxDeviceRole>)

=item $cx->vsx_system_mac()

The system ID the VSX pair presents to LACP partners, colon separated
hex. Read from text or raw octets; undef when neither parses.
(C<arubaWiredVsxDeviceOperSystemID>)

=item $cx->vsx_isl_port()

The name of the inter-switch link (ISL) interface, such as C<lag256>.
C<0> or empty when no ISL is configured.
(C<arubaWiredVsxIslPort>)

=item $cx->vsx_isl_state()

The state of the ISL session with the VSX peer: C<init>, C<outSync> or
C<inSync>.
(C<arubaWiredVsxIslOperState>)

=item $cx->vsx_keepalive_peer()

The VSX keepalive peer's address. AOS-CX can serve it as text rather than
an InetAddress; either form is read and returned in the same form. Undef
when unset or not an address.
(C<arubaWiredVsxKeepAlivePeerIPAddr>)

=item $cx->vsx_keepalive_state()

The state of the keepalive session: C<init>, C<configured>,
C<inSyncEstablished>, C<outofSyncEstablished>, C<initEstablished>,
C<failed> or C<stopped>.
(C<arubaWiredVsxKeepAliveOperState>)

=item $cx->hasRapidPVST()

Returns 1 when the mode is RPVST, as L</"Spanning Tree"> describes, else 0.
(C<ieee8021MstpCistPortRole>)

=back

=head2 Globals imported from SNMP::Info::IEEE802_STP

See documentation in L<SNMP::Info::IEEE802_STP> for details.

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Globals imported from SNMP::Info::IEEE802_Bridge

See documentation in L<SNMP::Info::IEEE802_Bridge> for details.

=head2 Globals imported from SNMP::Info::IEEE802dot3ad

See documentation in L<SNMP::Info::IEEE802dot3ad> for details.

=head2 Client IP tracking

These methods add rows from C<arubaWiredCiptClientTable> to the inherited
ARP and IPv6 neighbor tables. Client tracking must already be enabled on
the switch; these methods only read its data. Each added row is keyed
C<cipt.> followed by the table's MAC, VLAN and IP index, so a client with
several addresses keeps one row for each. Rows with a malformed index, a
multicast or zero MAC, a VLAN outside 1 to 4094, an address of the wrong
length or no port are omitted. With no usable tracking rows, each method
returns the inherited result.

=over

=item $cx->at_paddr()

Returns reference to hash. The inherited C<at_paddr()> rows, plus the
client MAC address of each IPv4 tracking row, colon separated hex.

=item $cx->at_netaddr()

Returns reference to hash. The inherited C<at_netaddr()> rows, plus the
client IPv4 address of each IPv4 tracking row.

=item $cx->ipv6_n2p_mac()

Returns reference to hash. The inherited C<ipv6_n2p_mac()> rows, plus the
client MAC address of each IPv6 tracking row, colon separated hex.

=item $cx->ipv6_n2p_addr()

Returns reference to hash. The inherited C<ipv6_n2p_addr()> rows, plus
the client IPv6 address of each IPv6 tracking row.

=item $cx->ipv6_n2p_if()

Returns reference to hash. The inherited C<ipv6_n2p_if()> rows, plus the
C<ifIndex> of the port where each IPv6 tracking row's client was seen.

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

Returns reference to hash. The name of the port the transceiver is in.
(C<arubaWiredPmXcvrPortDesc>)

=item $cx->pm_xcvr_descr()

Returns reference to hash. The transceiver description.
(C<arubaWiredPmXcvrDescription>)

=item $cx->pm_xcvr_product()

Returns reference to hash. The transceiver product number.
(C<arubaWiredPmXcvrProductNum>)

=item $cx->pm_xcvr_serial()

Returns reference to hash. The transceiver serial number.
(C<arubaWiredPmXcvrSerialNum>)

=item $cx->pm_xcvr_type()

Returns reference to hash. The transceiver type.
(C<arubaWiredPmXcvrType>)

=back

=head2 Aruba Fan Table (C<arubaWiredFanTable>)

Indexed by group, tray and slot. Read by C<fan()>.

=over

=item $cx->fan_names()

Returns reference to hash. The fan name.
(C<arubaWiredFanName>)

=item $cx->fan_states()

Returns reference to hash. The fan status, as served.
(C<arubaWiredFanState>)

=back

=head2 Aruba Power Supply Table (C<arubaWiredPowerSupplyTable>)

Indexed by group and slot.

=over

=item $cx->psu_names()

Returns reference to hash. The power supply name.
(C<arubaWiredPSUName>)

=item $cx->psu_types()

Returns reference to hash. The power supply product name.
(C<arubaWiredPSUProductName>)

=item $cx->psu_states()

Returns reference to hash. The power supply status, as served.
(C<arubaWiredPSUState>)

=back

=head2 Aruba VSF Member Table (C<arubaWiredVsfMemberTable>)

Indexed by VSF member.

=over

=item $cx->vsf_prod_names()

Returns reference to hash. The product name of each VSF stack member.
Used by C<stack_info()>.
(C<arubaWiredVsfMemberProductName>)

=back

=head2 Aruba Client IP Tracking Table (C<arubaWiredCiptClientTable>)

Indexed by client MAC, VLAN and IP index. Read by the client IP tracking
methods.

=over

=item $cx->cipt_addr_type()

Returns reference to hash. The address type of C<cipt_addr()>.
(C<arubaWiredCiptClientIpAddrType>)

=item $cx->cipt_addr()

Returns reference to hash. The tracked client IP address, as served.
(C<arubaWiredCiptClientIpAddress>)

=item $cx->cipt_ifindex()

Returns reference to hash. The C<ifIndex> of the port where the client
is tracked.
(C<arubaWiredCiptClientPortIfIndex>)

=back

=head2 Aruba RPVST VLAN Table (C<arubaWiredRpvstVlanTable>)

Indexed by VLAN.

=over

=item $cx->rpvst_v_admin()

Returns reference to hash. C<enabled> or C<disabled>: whether RPVST
runs on the VLAN.
(C<arubaWiredRpvstVlanRpvstAdminStatus>)

=item $cx->rpvst_v_priority()

Returns reference to hash. This switch's bridge priority on the VLAN, an
integer.
(C<arubaWiredRpvstVlanPriority>)

=item $cx->rpvst_v_root_priority()

Returns reference to hash. The root bridge priority on the VLAN, an
integer.
(C<arubaWiredRpvstVlanRootPriority>)

=item $cx->rpvst_v_root_mac()

Returns reference to hash. The root bridge MAC address on the VLAN,
colon separated hex.
(C<arubaWiredRpvstVlanRootMacAddress>)

=back

=head2 Aruba RPVST Port VLAN Table (C<arubaWiredRpvstPortVlanTable>)

Indexed by VLAN and ifIndex.

=over

=item $cx->rpvst_pv_state()

Returns reference to hash. The port's state on the VLAN: C<disabled>,
C<blocking>, C<listening>, C<learning>, C<forwarding>, C<broken>,
C<bpduError>, C<loopInconsistent>, C<pvidInconsistent> or C<rootGuard>.
(C<arubaWiredRpvstPortVlanState>)

=item $cx->rpvst_pv_role()

Returns reference to hash. The port's role on the VLAN: C<root>,
C<alternate>, C<designated>, C<backup>, C<master> or C<disabled>.
(C<arubaWiredRpvstPortVlanRole>)

=item $cx->rpvst_pv_bridge()

Returns reference to hash. The MAC address of the designated bridge on
the port's segment, colon separated hex.
(C<arubaWiredRpvstPortVlanDesigBridge>)

=item $cx->rpvst_pv_edge_oper()

Returns reference to hash. C<true> or C<false>: whether the port is
operating as an edge port on the VLAN.
(C<arubaWiredRpvstPortVlanOperEdge>)

=back

=head2 Aruba VSX Aggregator Table (C<arubaWiredVsxAggregatorTable>)

Indexed by the aggregation's ifIndex.

=over

=item $cx->vsx_agg_type()

Returns reference to hash. C<multiChassis> for a link aggregation split
across the VSX pair, else C<point2Point>.
(C<arubaWiredVsxAggregatorType>)

=back

=head2 Overrides

=over

=item $cx->lag_groups()

As described in L<SNMP::Info::IEEE802dot3ad/"METHODS">, with, while the
C<vsx> domain of C<mlag_domains()> is served:

=over

=item * A link aggregation that C<vsx_agg_type()> lists as C<multiChassis>
gets C<mc>: C<kind> C<vsx>, C<group> the LAG number from its interface
name (10 for C<lag10>, or the name when it is not C<lagN>), C<domain>
C<vsx>, and C<state> undef, since no per-LAG state is served. A LAG
that F<IEEE8023-LAG-MIB> does not list still gets a record.

=item * The ISL that C<vsx_isl_port()> names gets C<peer_link>.

=back

C<lag_groups_complete()> also checks the C<vsx_agg_type()> walk.

=item $cx->mlag_domains()

As described in L<SNMP::Info::IEEE802dot3ad/"METHODS">, with one domain,
keyed C<vsx>, when the switch runs VSX: C<vsx_role()> is C<primary> or
C<secondary>, or C<vsx_isl_port()> names an interface. Its fields:

=over

=item * C<kind>: C<vsx>.

=item * C<system_mac>: C<vsx_system_mac()>.

=item * C<role>: C<vsx_role()>.

=item * C<peer>: C<vsx_keepalive_peer()>.

=item * C<status>: the ISL state, C<vsx_isl_state()>.

=item * C<peer_link>: the ifIndex of the interface C<vsx_isl_port()>
names. Absent when no interface has that name.

=back

=item $cx->e_index()

Returns reference to hash. The inherited C<entPhysicalIndex> rows, plus
one row per transceiver in C<arubaWiredPmXcvrTable>, indexed 1000000000
plus the port C<ifIndex>. A transceiver whose index is already a real
C<entPhysicalIndex> is skipped. The other C<e_*> overrides return the
same added rows. A partial fetch, or a device without transceiver rows,
returns the inherited result.

=item $cx->e_class()

Returns reference to hash. The inherited rows, plus C<module> for each
transceiver row.

=item $cx->e_descr()

Returns reference to hash. The inherited rows, plus the transceiver
description from C<pm_xcvr_descr()>.

=item $cx->e_name()

Returns reference to hash. The inherited rows, plus C<Transceiver>
followed by the port name from C<pm_xcvr_port()>.

=item $cx->e_model()

Returns reference to hash. The inherited rows, plus the transceiver
product number from C<pm_xcvr_product()>.

=item $cx->e_serial()

Returns reference to hash. The inherited rows, plus the transceiver
serial number from C<pm_xcvr_serial()>.

=item $cx->e_type()

Returns reference to hash. The inherited rows, plus the transceiver type
from C<pm_xcvr_type()>.

=item $cx->e_fru()

Returns reference to hash. The inherited rows, plus C<true> for each
transceiver row.

=item $cx->e_parent()

Returns reference to hash. The inherited rows, plus each transceiver's
parent: the C<port> entity whose name matches C<pm_xcvr_port()>, else
the first chassis, else 0.

=item $cx->stp_protocols()

Returns C<['mstp']> under MSTP, C<['rapid-pvst']> under RPVST, the
inherited result with BRIDGE-MIB only, and nothing when the mode is
unknown.

=item $cx->stp_trees()

Under RPVST, returns one C<vlan.N> tree for each VLAN where
C<rpvst_v_admin()> is C<enabled>. No eight-octet bridge ID is served, so
each bridge ID is built from its parts:

=over

=item * B<priority>: C<rpvst_v_priority()> for this switch,
C<rpvst_v_root_priority()> for the root.

=item * B<mac>: this switch's MAC is the MAC part of
C<ieee8021MstpCistBridgeIdentifier>, the VSX system MAC on a VSX pair.
The root's MAC is C<rpvst_v_root_mac()>.

=item * B<sys_id_ext>: the VLAN, when the bridge is this switch and
C<rpvst_ext_sysid()> is C<true>. Otherwise undef.

=back

C<ports_complete> is 1, since the port rows are keyed by C<ifIndex>.
Returns an empty hash when the mode is unknown.

=item $cx->stp_trees_complete()

Under RPVST, returns 1 when C<stp_trees()> holds trees and the
C<rpvst_v_admin()> walk completed, else 0. Returns 0 when the mode is
unknown.

=item $cx->stp_vlan_map()

Under RPVST, maps each VLAN with RPVST enabled to its C<vlan.N> tree.
Returns nothing when the mode is unknown.

=item $cx->stp_tree_ports($tree_key)

Under RPVST, returns port rows from C<arubaWiredRpvstPortVlanTable>.
C<state> is C<rpvst_pv_state()> as served. C<role> is
C<rpvst_pv_role()>. C<enabled> and C<designated_port> are undef. The
designated bridge is served as a MAC only, so its priority and
C<sys_id_ext> are those of the root or this switch when the MAC is
theirs, else undef. Sets C<error()> and returns nothing when the mode is
unknown.

=item $cx->i_stp_state()

Returns an empty hash under RPVST, where C<dot1dStpPortState> keeps
MSTP's last values. Otherwise the inherited result.

=item $cx->i_edgeport_oper()

Returns reference to hash of ifIndex to 1 or 0. Under MSTP and with
BRIDGE-MIB only, the inherited result. Under RPVST,
C<arubaWiredRpvstPortVlanOperEdge> on the row for the port's native VLAN
(C<i_vlan()>); a port with no such row is absent.
A port with no native VLAN in effect, which AOS-CX reports as 0, is
absent (L</"VLANs">).
Returns an empty hash when the mode is unknown. C<i_edgeport_admin()> is
the inherited method in every mode. Whether this value reports an
operational edge port as true has not been verified.

=item $cx->agg_ports()

Returns reference to hash of member C<ifIndex> to aggregation
C<ifIndex>. AOS-CX serves C<dot3adAggPortListPorts> as a comma
separated list of interface names, not a PortList, so each name is
matched against C<interfaces()>.

=item $cx->raw_ad_lag_ports()

Returns reference to hash. The member interface names of each
aggregation, as served.
(C<dot3adAggPortListPorts>)

=item $cx->v_name()

Returns reference to hash of VLAN to VLAN name.
(C<ieee8021QBridgeVlanStaticName>, else C<dot1qVlanStaticName>)

=item $cx->qb_i_vlan()

Returns reference to hash of bridge port to native VLAN (PVID). See
L</"VLANs"> for the value 0.
(C<ieee8021QBridgePvid>, else C<dot1qPvid>)

=item $cx->i_vlan()

Returns reference to hash of ifIndex to native VLAN (PVID): the
inherited result without the ports AOS-CX reports as 0, which have no
native VLAN in effect (L</"VLANs">).

=item $cx->i_untagged()

An alias for C<i_vlan()>.

=item $cx->i_vlan_type()

Returns reference to hash of bridge port to the frame types the port
accepts.
(C<ieee8021QBridgePortAcceptableFrameTypes>, else
C<dot1qPortAcceptableFrameTypes>)

=item $cx->qb_v_egress()

Returns reference to hash of VLAN to its configured member ports, an
array of bits. Keys are C<1.VLAN> from the IEEE MIB, or C<VLAN> from
F<Q-BRIDGE-MIB>.
(C<ieee8021QBridgeVlanStaticEgressPorts>, else
C<dot1qVlanStaticEgressPorts>)

=item $cx->qb_cv_egress()

Returns reference to hash of VLAN to its current member ports, an array
of bits. Keys are C<0.1.VLAN> from the IEEE MIB, or C<0.VLAN> from
F<Q-BRIDGE-MIB>; the leading 0 is the time filter.
(C<ieee8021QBridgeVlanCurrentEgressPorts>, else
C<dot1qVlanCurrentEgressPorts>)

=item $cx->qb_v_untagged()

Returns reference to hash of VLAN to its configured untagged ports, an
array of bits. Keys as C<qb_v_egress()>.
(C<ieee8021QBridgeVlanStaticUntaggedPorts>, else
C<dot1qVlanStaticUntaggedPorts>)

=item $cx->qb_cv_untagged()

Returns reference to hash of VLAN to its current untagged ports, an
array of bits. Keys as C<qb_cv_egress()>.
(C<ieee8021QBridgeVlanCurrentUntaggedPorts>, else
C<dot1qVlanCurrentUntaggedPorts>)

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
