# SNMP::Info::Layer2::TPLink
#
# Copyright (c) 2025 The Netdisco Development Team
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

package SNMP::Info::Layer2::TPLink;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer2;
use SNMP::Info::EtherLike;

@SNMP::Info::Layer2::TPLink::ISA = qw/
    SNMP::Info::EtherLike SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::TPLink::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.978002';

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
    %SNMP::Info::EtherLike::MIBS,
    # Ensure we can reference TP-Link system/product objects
    'TPLINK-SYSINFO-MIB' => 'tpSysInfoDescription',
    'TPLINK-MIB'         => 'tplinkProducts',
    'TPLINK-LLDP-MIB'    => 'tplinkLldpMIBObjects',
    'TPLINK-LLDPINFO-MIB' => 'lldpInfo',
    'TPLINK-DOT1Q-VLAN-MIB' => 'tplinkDot1qVlanMIBObjects',
    'TPLINK-PORTCONFIG-MIB' => 'tpPortConfigTable',
    'TPLINK-SPANNING-TREE-MIB' => 'tplinkSpanningTreeMIBObjects',
    'TPLINK-L2BRIDGE-MIB' => 'tplinkl2BridgeMIBObjects',
    'TPLINK-POWER-OVER-ETHERNET-MIB' => 'tplinkPowerOverEthernetMIB',
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
    %SNMP::Info::EtherLike::GLOBALS,
    'tp_sysinfo_descr'    => 'tpSysInfoDescription',
    'tp_sysinfo_hostname' => 'tpSysInfoHostName',
    'tp_sysinfo_hwver'    => 'tpSysInfoHwVersion',
    'tp_sysinfo_swver'    => 'tpSysInfoSwVersion',
    'tp_sysinfo_mac'      => 'tpSysInfoMacAddr',

    # netdisco/netdisco-mibs#281: tpSysInfoSerialNum (netdisco-mibs names .8
    # tpSysInfoUpTime).
    'tp_sysinfo_serial'   => '.1.3.6.1.4.1.11863.6.1.1.8.0',

    # netdisco/netdisco-mibs#281: powerSupplyUnitInternalPower and
    # powerSupplyUnitExternalPower (netdisco-mibs lacks
    # TPLINK-POWERSUPPLYUNIT-MIB).
    'ps1_status'          => '.1.3.6.1.4.1.11863.6.88.1.1.3.0',
    'ps2_status'          => '.1.3.6.1.4.1.11863.6.88.1.1.4.0',

    # Spanning Tree globals from TP-Link private MIB
    'stp_ver'       => 'TPLINK-SPANNING-TREE-MIB::tpStpMode',
    'stp_time'      => 'TPLINK-SPANNING-TREE-MIB::tpStpLastTopologyChangeTime',
    'stp_root'      => 'TPLINK-SPANNING-TREE-MIB::tpStpCISTRoot',
    'stp_root_port' => 'TPLINK-SPANNING-TREE-MIB::tpStpRootPort',
    'stp_priority'  => 'TPLINK-SPANNING-TREE-MIB::tpStpCistPriority',
    'v_index'    => 'TPLINK-DOT1Q-VLAN-MIB::dot1qVlanId',
    'v_name' => 'TPLINK-DOT1Q-VLAN-MIB::dot1qVlanDescription',
    'tp_power_limit'  => 'TPLINK-POWER-OVER-ETHERNET-MIB::tpSystemPowerLimit.0',
    'tp_power_consumption'  => 'TPLINK-POWER-OVER-ETHERNET-MIB::tpSystemPowerConsumption.0',
    'tp_power_remain'  => 'TPLINK-POWER-OVER-ETHERNET-MIB::tpSystemPowerRemain.0',
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
    %SNMP::Info::EtherLike::FUNCS,

    # netdisco/netdisco-mibs#281: TP-Link 2024 vlanPortPvid. netdisco-mibs
    # names column 2 vlanPortType with enums, so labels arrive and
    # munge_tp_pvid maps them back.
    'tp_vlan_port_pvid' => '.1.3.6.1.4.1.11863.6.14.1.1.1.1.2',
    'tp_vlan_tagged'    => 'TPLINK-DOT1Q-VLAN-MIB::vlanTagPortMemberAdd',
    'tp_vlan_untagged'  => 'TPLINK-DOT1Q-VLAN-MIB::vlanUntagPortMemberAdd',
    # TP-Link port config (duplex/speed/etc)
    'i_duplex_admin' => 'TPLINK-PORTCONFIG-MIB::tpPortConfigDuplex',
    'i_speed_admin'  => 'TPLINK-PORTCONFIG-MIB::tpPortConfigSpeed',
    'tp_port_config_descr' => 'TPLINK-PORTCONFIG-MIB::tpPortConfigDescription',
    'tp_lldp_rem_id'      => 'TPLINK-LLDPINFO-MIB::lldpNeighborChassisId',
    'tp_lldp_rem_pid'     => 'TPLINK-LLDPINFO-MIB::lldpNeighborPortIdDescr',
    'tp_lldp_rem_desc'    => 'TPLINK-LLDPINFO-MIB::lldpNeighborPortDescr',
    'tp_lldp_rem_sysname' => 'TPLINK-LLDPINFO-MIB::lldpNeighborDeviceName',
    'tp_lldp_rem_sysdesc' => 'TPLINK-LLDPINFO-MIB::lldpNeighborDeviceDescr',
    'tp_lldp_rem_cap_spt' => 'TPLINK-LLDPINFO-MIB::lldpNeighborCapAvailable',
    'tp_lldp_rman'        => 'TPLINK-LLDPINFO-MIB::lldpNeighborManageIpAddr',
    'tp_lldp_oper_mau'    => 'TPLINK-LLDPINFO-MIB::lldpLocalOperMau',
    # TP-Link dynamic MAC forwarding table
    'tpl2BridgeManageDynMac'  => 'TPLINK-L2BRIDGE-MIB::tpl2BridgeManageDynMac',
    'tpl2BridgeManageDynVlanId' => 'TPLINK-L2BRIDGE-MIB::tpl2BridgeManageDynVlanId',
    'tpl2BridgeManageDynPort' => 'TPLINK-L2BRIDGE-MIB::tpl2BridgeManageDynPort',
    # Map TP-Link STP per-port table fields into the Bridge expected names
    'stp_i_root'       => 'TPLINK-SPANNING-TREE-MIB::tpStpCISTRoot',
    'stp_i_time'       => 'TPLINK-SPANNING-TREE-MIB::tpStpLastTopologyChangeTime',
    'stp_i_root_port'  => 'TPLINK-SPANNING-TREE-MIB::tpStpRootPort',
    'stp_i_priority'   => 'TPLINK-SPANNING-TREE-MIB::tpStpCistPriority',
    # Per-port STP mapped keys (index by ifIndex)
    'stp_p_id'       => 'TPLINK-SPANNING-TREE-MIB::tpStpPortNumber',
    'stp_p_priority' => 'TPLINK-SPANNING-TREE-MIB::tpStpPortPriority',
    'stp_p_state'    => 'TPLINK-SPANNING-TREE-MIB::tpStpPortStatus',
    'stp_p_cost'     => 'TPLINK-SPANNING-TREE-MIB::tpStpPortInPathCost',
    'stp_p_role'     => 'TPLINK-SPANNING-TREE-MIB::tpStpPortRole',
    'is_edgeport_admin' => 'TPLINK-SPANNING-TREE-MIB::tpStpEdgePortStatus',
    'is_edgeport_oper'  => 'TPLINK-SPANNING-TREE-MIB::tpStpEdgePortStatus',
    # PoE
    'tp_peth_port_admin'       => 'TPLINK-POWER-OVER-ETHERNET-MIB::tpPoePortStatus',
    'tp_peth_port_status'     => 'TPLINK-POWER-OVER-ETHERNET-MIB::tpPoePowerStatus',
    'tp_peth_port_class'       => 'TPLINK-POWER-OVER-ETHERNET-MIB::tpPoeClass',
    'tp_peth_port_power'       => 'TPLINK-POWER-OVER-ETHERNET-MIB::tpPoePower',
);

%MUNGE = (
    %SNMP::Info::Layer2::MUNGE,
    %SNMP::Info::EtherLike::MUNGE,
    'tp_vlan_port_pvid' => \&munge_tp_pvid,
    'tp_power_limit' => \&munge_power,
    'tp_power_consumption' => \&munge_power,
    'tp_power_remain' => \&munge_power,
);

sub vendor {
    return 'TP-Link';
}

sub os {
    return 'tplink';
}

sub model {
    my $tp = shift;

    # Prefer TP-Link's own sysinfo MIB (TPLINK-SYSINFO-MIB)
    # Use textual description (tpSysInfoDescription) first which typically
    # contains product name and version.  If available, prefer a cleaned
    # combination of description and hardware version.
    my $tp_descr = $tp->tp_sysinfo_descr();
    my $tp_hw    = $tp->tp_sysinfo_hwver();
    if ( defined $tp_descr and $tp_descr !~ /^\s*$/ ) {
        my $model = $tp_descr;
        $model =~ s/\s+$//;
        # Append hardware version if present and not duplicate
        if ( defined $tp_hw and $tp_hw !~ /^\s*$/ and $model !~ /\Q$tp_hw\E/ ) {
            $model = "$model $tp_hw";
        }
        return $model;
    }

    # Last resort: use sysDescr
    my $descr = $tp->description() || '';
    $descr =~ s/\s+$//;
    return $descr if $descr ne '';

    return;
}

sub os_ver {
    my $tp = shift;

    # Prefer TP-Link specific SW version
    my $sw = $tp->tp_sysinfo_swver();
    return $sw if defined $sw and $sw ne '';

    # Last resort, take from sysDescr
    my $desc = $tp->description() || '';
    if ( $desc =~ /([\d]+(?:\.[\d]+)+)/ ) {
        return $1;
    }
    return;
}

sub serial {
    my $tp = shift;

    my $serial = $tp->tp_sysinfo_serial();
    return $serial if defined $serial and $serial !~ /^\s*$/;

    return;
}

sub mac {
    my $tp = shift;

    my $mac = $tp->b_mac();
    return $mac if defined $mac and $mac ne '';

    $mac = $tp->tp_sysinfo_mac();
    if ( defined $mac and $mac ne '' ) {
        $mac =~ s/-/:/g;
        return uc $mac;
    }

    return;
}

sub i_name {
    my $tp      = shift;
    my $partial = shift;

    my $names   = $tp->orig_i_name($partial) || {};
    my $aliases = $tp->i_alias($partial) || {};
    $aliases = $tp->tp_port_config_descr($partial) || {}
        unless keys %$aliases;

    my %out;
    foreach my $iid ( keys %$names ) {
        my $alias = $aliases->{$iid};
        $out{$iid}
            = ( defined $alias and $alias !~ /^\s*$/ )
            ? $alias
            : $names->{$iid};
    }

    return \%out;
}

sub i_duplex {
    my $tp      = shift;
    my $partial = shift;

    # EtherLike is present on most JetStream firmware; dot3StatsIndex equals
    # ifIndex and no walk publishes it, so el_duplex is keyed directly.
    my $el_duplex = $tp->el_duplex($partial) || {};
    my %el_out;
    foreach my $iid ( keys %$el_duplex ) {
        my $duplex = $el_duplex->{$iid};
        next unless defined $duplex;
        $el_out{$iid} = 'full' if $duplex =~ /full/i;
        $el_out{$iid} = 'half' if $duplex =~ /half/i;
    }
    return \%el_out if keys %el_out;

    my $mau = $tp->tp_lldp_oper_mau($partial) || {};
    my %out;
    foreach my $key ( keys %$mau ) {
        if ( defined $mau->{$key}
            and $mau->{$key} =~ /speed\(\S+\)\/duplex\((full|half)\)/i )
        {
            $out{$key} = lc $1;
        }
        else {
            $out{$key} = 'unknown';
        }
    }

    return \%out;
}

# PoE methods
sub munge_power {
    my $power = shift;

    return $power ? $power / 10 : 0;
}

sub _tp_port_map {
    my $tp = shift;

    my $descriptions = $tp->i_description() || {};
    my %map;
    foreach my $iid ( keys %$descriptions ) {
        my $description = $descriptions->{$iid};
        next unless defined $description;
        if ( $description =~ m{(\d+/\d+/\d+)} ) {
            $map{$1} = $iid;
        }
        elsif ( $description =~ /^port-channel\s*(\d+)$/i ) {
            $map{"LAG$1"} = $iid;
        }
    }
    return \%map;
}

sub _tp_peth_by_port {
    my $tp     = shift;
    my $column = shift || {};

    my $port_map = $tp->_tp_port_map();
    my %out;
    foreach my $port ( keys %$column ) {
        next unless exists $port_map->{"1/0/$port"};
        $out{"1.$port"} = $column->{$port};
    }
    return \%out;
}

sub peth_power_status {
    my $tp = shift;

    my $watts = $tp->tp_power_limit();
    return defined $watts ? { 1 => 'on' } : {};
}

sub peth_power_watts {
    my $tp = shift;

    my $watts = $tp->tp_power_limit();
    return defined $watts ? { 1 => $watts } : {};
}

sub peth_port_ifindex {
    my $tp = shift;

    my $port_map = $tp->_tp_port_map();
    my $admin    = $tp->tp_peth_port_admin() || {};
    my %out;
    foreach my $port ( keys %$admin ) {
        my $iid = $port_map->{"1/0/$port"};
        $out{"1.$port"} = $iid if defined $iid;
    }
    return \%out;
}

sub peth_port_admin {
    my $tp = shift;

    my $admin = $tp->_tp_peth_by_port( $tp->tp_peth_port_admin() );
    foreach my $entry ( keys %$admin ) {
        my $state = $admin->{$entry};
        $admin->{$entry}
            = ( defined $state and $state eq 'enable' ) ? 'true' : 'false';
    }
    return $admin;
}

sub peth_port_status {
    my $tp = shift;

    my %state_name = (
        'on'         => 'deliveringPower',
        'off'        => 'searching',
        'turning-on' => 'searching',
        'overload'        => 'fault',
        'short'           => 'fault',
        'voltage-high'    => 'fault',
        'voltage-low'     => 'fault',
        'hardware-fault'  => 'fault',
        'overtemperature' => 'fault',
    );
    my $admin  = $tp->_tp_peth_by_port( $tp->tp_peth_port_admin() );
    my $status = $tp->_tp_peth_by_port( $tp->tp_peth_port_status() );
    foreach my $entry ( keys %$status ) {
        my $state = $status->{$entry};
        my $set   = $admin->{$entry};
        $status->{$entry}
            = ( defined $set and $set eq 'disable' ) ? 'disabled'
            : defined $state ? ( $state_name{$state} || 'otherFault' )
            :                  'otherFault';
    }
    return $status;
}

sub peth_port_class {
    my $tp = shift;

    return $tp->_tp_peth_by_port( $tp->tp_peth_port_class() );
}

sub peth_port_power {
    my $tp = shift;

    my $power = $tp->_tp_peth_by_port( $tp->tp_peth_port_power() );
    foreach my $entry ( keys %$power ) {
        $power->{$entry} *= 100 if defined $power->{$entry};
    }
    return $power;
}

sub munge_tp_pvid {
    my $value = shift;

    my %by_label = ( access => 0, trunk => 1, general => 2 );
    return $by_label{$value} if defined $value and exists $by_label{$value};
    return $value;
}

sub _tp_vlan_ports {
    my $tp    = shift;
    my $lists = shift || {};

    my $port_map = $tp->_tp_port_map();
    my %seen;
    foreach my $vlan ( keys %$lists ) {
        foreach my $port ( _tp_expand_port_list( $lists->{$vlan} ) ) {
            my $iid = $port_map->{$port};
            $seen{$iid}{$vlan} = 1 if defined $iid;
        }
    }

    my %out;
    foreach my $iid ( keys %seen ) {
        $out{$iid} = [ sort { $a <=> $b } keys %{ $seen{$iid} } ];
    }
    return \%out;
}

sub _tp_expand_port_list {
    my $list = shift;

    return () unless defined $list;
    my @ports;
    foreach my $token ( split /,/, $list ) {
        $token =~ s/^\s+|\s+$//g;
        if ( $token =~ m{^(\d+/\d+/)(\d+)-(\d+)$} ) {
            push @ports, map {"$1$_"} $2 .. $3;
        }
        elsif ( $token =~ /^LAG(\d+)-(\d+)$/ ) {
            push @ports, map {"LAG$_"} $1 .. $2;
        }
        elsif ( $token =~ m{^(?:\d+/\d+/\d+|LAG\d+)$} ) {
            push @ports, $token;
        }
    }
    return @ports;
}

sub _tp_vlan_membership {
    my $tp      = shift;
    my $partial = shift;
    my @columns = @_;

    my %lists;
    foreach my $column (@columns) {
        my $rows = $tp->$column() || {};
        foreach my $vlan ( keys %$rows ) {
            next unless defined $rows->{$vlan} and $rows->{$vlan} ne '';
            $lists{$vlan} .= ( exists $lists{$vlan} ? ',' : '' )
                . $rows->{$vlan};
        }
    }

    my $members = $tp->_tp_vlan_ports( \%lists );
    return $members unless defined $partial;
    return { map { $_ => $members->{$_} }
            grep { $_ eq $partial } keys %$members };
}

sub i_vlan_membership {
    my $tp      = shift;
    my $partial = shift;

    return $tp->_tp_vlan_membership( $partial, 'tp_vlan_tagged',
        'tp_vlan_untagged' );
}

sub i_vlan_membership_untagged {
    my $tp      = shift;
    my $partial = shift;

    return $tp->_tp_vlan_membership( $partial, 'tp_vlan_untagged' );
}

sub i_vlan {
    my $tp      = shift;
    my $partial = shift;

    my $pvids = $tp->tp_vlan_port_pvid($partial) || {};
    return { %$pvids } if keys %$pvids;

    my $untagged = $tp->i_vlan_membership_untagged($partial) || {};
    my %out;
    foreach my $iid ( keys %$untagged ) {
        $out{$iid} = $untagged->{$iid}[0] if @{ $untagged->{$iid} } == 1;
    }
    return \%out;
}

# TP-Link switches may publish neighbors only in the TP-Link table.
sub hasLLDP {
    my $tp = shift;

    return 1 if $tp->SUPER::hasLLDP();
    my $tp_rem_id = $tp->tp_lldp_rem_id() || {};
    return 1 if scalar keys %$tp_rem_id;
    return;
}

# Decided once per device so neighbor keys never mix. Some models publish
# LLDP-MIB remote rows, which then take precedence.
# Memoized because an empty walk is not cached; clear_cache resets it.
sub _tp_lldp_standard {
    my $tp = shift;

    return $tp->{_tp_lldp_standard} if exists $tp->{_tp_lldp_standard};
    my $rem_id = $tp->lldp_rem_id() || {};
    return $tp->{_tp_lldp_standard} = scalar keys %$rem_id ? 1 : 0;
}

sub _tp_lldp_neighbors {
    my ( $tp, $partial ) = @_;
    return $tp->tp_lldp_rem_id($partial) || {};
}

sub _tp_lldp_first {
    my ( $tp, $partial, @columns ) = @_;

    my @tables = map { $tp->$_($partial) || {} } @columns;
    my %out;
    foreach my $key ( keys %{ $tp->_tp_lldp_neighbors($partial) } ) {
        my ($value) = grep { defined $_ and $_ ne '' }
            map { $_->{$key} } @tables;
        $out{$key} = $value if defined $value;
    }
    return \%out;
}

sub _tp_lldp_addr {
    my ( $tp, $partial, $want_v6 ) = @_;

    my $rman = $tp->tp_lldp_rman($partial) || {};
    my %out;
    foreach my $key ( keys %{ $tp->_tp_lldp_neighbors($partial) } ) {
        my $addr = $rman->{$key};
        next unless defined $addr;
        my $v4 = $addr =~ /^(?:::)?(\d{1,3}(?:\.\d{1,3}){3})$/ ? $1 : undef;
        if ($want_v6) {
            $out{$key} = $addr
                if !defined $v4 and $addr =~ /:/ and $addr ne '::';
        }
        elsif ( defined $v4 ) {
            $out{$key} = $v4;
        }
    }
    return \%out;
}

sub _tp_lldp_std_if {
    my ( $tp, $partial ) = @_;

    my $inherited = $tp->SUPER::lldp_if($partial) || {};
    my $port_id   = $tp->lldp_lport_id()          || {};
    my %ifindex_of = reverse %{ $tp->i_description() || {} };

    # lldpLocPortDesc holds the port alias when one is set, and aliases
    # repeat across ports, so the exact ifDescr in lldpLocPortId decides.
    my %lldp_if = %$inherited;
    foreach my $key ( keys %lldp_if ) {
        my $local_port = ( split /\./, $key )[1];
        my $descr = defined $local_port ? $port_id->{$local_port} : undef;
        $lldp_if{$key} = $ifindex_of{$descr}
            if defined $descr and exists $ifindex_of{$descr};
    }
    return \%lldp_if;
}

sub lldp_if {
    my ( $tp, $partial ) = @_;
    return $tp->_tp_lldp_std_if($partial) if $tp->_tp_lldp_standard;

    my %lldp_if;
    foreach my $key ( keys %{ $tp->_tp_lldp_neighbors($partial) } ) {
        my ($ifindex) = split /\./, $key;
        $lldp_if{$key} = $ifindex;
    }
    return \%lldp_if;
}

sub lldp_ip {
    my ( $tp, $partial ) = @_;
    return $tp->SUPER::lldp_ip($partial) if $tp->_tp_lldp_standard;
    return $tp->_tp_lldp_addr( $partial, 0 );
}

sub lldp_ipv6 {
    my ( $tp, $partial ) = @_;
    return $tp->SUPER::lldp_ipv6($partial) if $tp->_tp_lldp_standard;
    return $tp->_tp_lldp_addr( $partial, 1 );
}

sub lldp_port {
    my ( $tp, $partial ) = @_;
    return $tp->SUPER::lldp_port($partial) if $tp->_tp_lldp_standard;
    return $tp->_tp_lldp_first( $partial, 'tp_lldp_rem_pid',
        'tp_lldp_rem_desc' );
}

sub lldp_id {
    my ( $tp, $partial ) = @_;
    return $tp->SUPER::lldp_id($partial) if $tp->_tp_lldp_standard;
    return $tp->_tp_lldp_first( $partial, 'tp_lldp_rem_id' );
}

sub lldp_platform {
    my ( $tp, $partial ) = @_;
    return $tp->SUPER::lldp_platform($partial) if $tp->_tp_lldp_standard;
    return $tp->_tp_lldp_first( $partial, 'tp_lldp_rem_sysdesc',
        'tp_lldp_rem_sysname' );
}

my %TP_LLDP_CAP = (
    'Other'               => 'other',
    'Repeater'            => 'repeater',
    'Bridge'              => 'bridge',
    'WLAN Access Point'   => 'wlanAccessPoint',
    'Router'              => 'router',
    'Telephone'           => 'telephone',
    'DOCSIS Cable Device' => 'docsisCableDevice',
    'Station Only'        => 'stationOnly',
);
my $TP_LLDP_CAP_NAMES = join '|', map {quotemeta}
    sort { length $b <=> length $a } keys %TP_LLDP_CAP;

sub lldp_cap {
    my ( $tp, $partial ) = @_;
    return $tp->SUPER::lldp_cap($partial) if $tp->_tp_lldp_standard;

    my $text = $tp->_tp_lldp_first( $partial, 'tp_lldp_rem_cap_spt' );
    my %lldp_cap;
    foreach my $key ( keys %$text ) {
        my @caps = map { $TP_LLDP_CAP{$_} }
            $text->{$key} =~ /(?:^|\s)($TP_LLDP_CAP_NAMES)(?=\s|$)/g;
        $lldp_cap{$key} = \@caps if @caps;
    }
    return \%lldp_cap;
}

sub _tp_bridge_port_ifindex {
    my ( $tp, $number, $port_map ) = @_;

    my @matches = grep { m{^\d+/\d+/\Q$number\E$} } keys %$port_map;
    return unless @matches == 1;
    return $port_map->{ $matches[0] };
}

# Build the Q-BRIDGE style forwarding table (dot1qTpFdbPort) from
# tpl2BridgeManageDynPort when the standard column is absent. Its index is
# mac.vlan; the result is keyed vlan.mac like dot1qTpFdbEntry.
sub qb_fw_port {
    my $tp      = shift;
    my $partial = shift;

    my $super = $tp->SUPER::qb_fw_port($partial) || {};
    return $super if ( ref {} eq ref $super and scalar keys %$super );

    my $dyn_port = $tp->tpl2BridgeManageDynPort($partial) || {};
    my $port_map = $tp->_tp_port_map();
    my $bp_index = $tp->bp_index() || {};

    my %out;
    foreach my $key ( keys %$dyn_port ) {
        my $pval = $dyn_port->{$key};
        next unless defined $pval and $pval ne '' and $pval ne '0';

        my @parts = split /\./, $key;
        next unless @parts >= 2;
        my $vlan = pop @parts;

        my $ifindex;
        if ( $pval =~ m{^\d+/\d+/\d+$} ) {
            $ifindex = $port_map->{$pval};
        }
        elsif ( $pval =~ /^\d+$/ ) {
            $ifindex = $tp->_tp_bridge_port_ifindex( $pval, $port_map );
            $ifindex = $bp_index->{$pval}
                if !defined $ifindex and exists $bp_index->{$pval};
        }

        $out{ join( '.', $vlan, @parts ) }
            = defined $ifindex ? $ifindex : $pval;
    }

    return \%out;
}

# dot1qTpFdbPort carries front-panel port numbers, but Netdisco looks
# fw_port values up in bp_index(), which is keyed by ifIndex.
sub fw_port {
    my $tp      = shift;
    my $partial = shift;

    my $fw = $tp->SUPER::fw_port($partial) || {};

    my $interfaces = $tp->interfaces() || {};
    my $bp_index   = $tp->bp_index()    || {};
    my $port_map   = $tp->_tp_port_map();

    my %out;
    foreach my $idx ( keys %$fw ) {
        my $portval = $fw->{$idx};
        next unless defined $portval and $portval ne '';

        my $ifindex;
        if ( $portval =~ /^\d+$/ ) {
            next if $portval == 0;
            $ifindex = $tp->_tp_bridge_port_ifindex( $portval, $port_map );
            if ( !defined $ifindex and exists $interfaces->{$portval} ) {
                $ifindex = $portval;
            }
            if ( !defined $ifindex and exists $bp_index->{$portval} ) {
                $ifindex = $bp_index->{$portval};
            }
        }
        else {
            $ifindex = $port_map->{$portval};
        }

        $out{$idx} = defined $ifindex ? $ifindex : $portval;
    }

    return \%out;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::TPLink - SNMP Interface to TP-Link Layer2 devices

=head1 AUTHORS

Dmitry Sergienko <dmitry.sergienko@gmail.com> and Eric Miller

based on work by the
Netdisco Developer Team

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $tplink = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
  or die "Can't connect to DestHost.\n";

 my $class = $tplink->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a
TP-Link JetStream or Omada switch through SNMP. TP-Link private MIBs
supply system information, VLANs, PoE, spanning tree, LLDP neighbors and
the dynamic address table where the standard MIBs are absent or
incomplete.

=head2 Inherited Classes

=over

=item SNMP::Info::EtherLike

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

=over

=item F<TPLINK-SYSINFO-MIB>

=item F<TPLINK-MIB>

=item F<TPLINK-LLDP-MIB>

=item F<TPLINK-LLDPINFO-MIB>

=item F<TPLINK-DOT1Q-VLAN-MIB>

=item F<TPLINK-PORTCONFIG-MIB>

=item F<TPLINK-SPANNING-TREE-MIB>

=item F<TPLINK-L2BRIDGE-MIB>

=item F<TPLINK-POWER-OVER-ETHERNET-MIB>

=back

=head2 Inherited MIBs

See L<SNMP::Info::EtherLike/"Required MIBs"> for its MIB requirements.

See L<SNMP::Info::Layer2/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $tplink->vendor()

Returns 'TP-Link'

=item $tplink->os()

Returns 'tplink'

=item $tplink->os_ver()

Returns the software version from C<tp_sysinfo_swver>. When that is
absent or empty, returns the first dotted number found in C<sysDescr>.

=item $tplink->model()

Returns C<tp_sysinfo_descr> with trailing space removed, followed by
C<tp_sysinfo_hwver> unless the description already contains it. When the
description is absent or blank, returns C<sysDescr>.

=item $tplink->serial()

Returns the serial number from C<tp_sysinfo_serial>, or undef when it is
absent or blank.

=item $tplink->mac()

Returns the base MAC address from C<b_mac>. When that is absent, returns
C<tp_sysinfo_mac> in upper case with colon separators.

=item $tplink->tp_sysinfo_descr()

Returns the TP-Link system description, which holds the product name.

(C<tpSysInfoDescription>)

=item $tplink->tp_sysinfo_hostname()

Returns the administratively assigned host name.

(C<tpSysInfoHostName>)

=item $tplink->tp_sysinfo_hwver()

Returns the hardware version of the product.

(C<tpSysInfoHwVersion>)

=item $tplink->tp_sysinfo_swver()

Returns the software version of the product.

(C<tpSysInfoSwVersion>)

=item $tplink->tp_sysinfo_mac()

Returns the system MAC address as text, for example
C<74-DA-88-68-2A-D2>.

(C<tpSysInfoMacAddr>)

=item $tplink->tp_sysinfo_serial()

Returns the serial number. netdisco-mibs names this object
C<tpSysInfoUpTime>, so it is polled by number (netdisco/netdisco-mibs#281).

(C<tpSysInfoSerialNum>, .1.3.6.1.4.1.11863.6.1.1.8.0)

=item $tplink->tp_power_limit()

Returns the maximum power the PoE switch supplies, in watts.

(C<tpSystemPowerLimit>)

=item $tplink->tp_power_consumption()

Returns the real time PoE power consumption, in watts.

(C<tpSystemPowerConsumption>)

=item $tplink->tp_power_remain()

Returns the real time remaining PoE power, in watts.

(C<tpSystemPowerRemain>)

=item $tplink->ps1_status()

Returns the internal power supply status as the device reports it.
netdisco-mibs lacks F<TPLINK-POWERSUPPLYUNIT-MIB>, so it is polled by
number (netdisco/netdisco-mibs#281).

(C<powerSupplyUnitInternalPower>, .1.3.6.1.4.1.11863.6.88.1.1.3.0)

=item $tplink->ps2_status()

Returns the external power supply status as the device reports it.
netdisco-mibs lacks F<TPLINK-POWERSUPPLYUNIT-MIB>, so it is polled by
number (netdisco/netdisco-mibs#281).

(C<powerSupplyUnitExternalPower>, .1.3.6.1.4.1.11863.6.88.1.1.4.0)

=back

=head2 Overrides

=over

=item $tplink->hasLLDP()

Returns true when L<SNMP::Info::LLDP/hasLLDP> is true, or when the TP-Link
neighbor table (C<tp_lldp_rem_id>) has rows. Otherwise returns false.

=item $tplink->stp_ver()

Returns the spanning tree mode: C<stp>, C<rstp> or C<mstp>.

(C<tpStpMode>)

=item $tplink->stp_time()

Returns the time of the last topology change as text.

(C<tpStpLastTopologyChangeTime>)

=item $tplink->stp_root()

Returns the CIST root bridge.

(C<tpStpCISTRoot>)

=item $tplink->stp_root_port()

Returns the root port.

(C<tpStpRootPort>)

=item $tplink->stp_priority()

Returns the bridge priority in the CIST.

(C<tpStpCistPriority>)

=item $tplink->v_index()

Returns reference to a hash keyed by VLAN ID. Values are the VLAN IDs.
Declared as a global, but it walks the TP-Link VLAN table column in place
of the Q-BRIDGE VLAN index.

(C<TPLINK-DOT1Q-VLAN-MIB::dot1qVlanId>)

=item $tplink->v_name()

Returns reference to a hash keyed by VLAN ID. Values are the VLAN
descriptions. Declared as a global, but it walks the TP-Link VLAN table
column in place of the Q-BRIDGE VLAN name.

(C<TPLINK-DOT1Q-VLAN-MIB::dot1qVlanDescription>)

=back

=head2 Global Methods imported from SNMP::Info::EtherLike

See L<SNMP::Info::EtherLike/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a
reference to a hash.

=head2 Overrides

=over

=item $tplink->i_name()

Returns reference to hash. Port name per ifIndex: C<i_alias> when not
blank, else C<ifName>. When C<i_alias> has no rows,
C<tp_port_config_descr> supplies the alias instead.

=item $tplink->i_duplex()

Returns reference to hash. Duplex per ifIndex. Uses C<el_duplex>
(EtherLike, C<full> or C<half>, other states omitted) when it returns any
rows, otherwise parses C<tp_lldp_oper_mau> (C<unknown> when the string has
no duplex).

=item $tplink->i_duplex_admin()

Returns reference to hash. Configured duplex per port: C<half>, C<full>
or C<auto>.

(C<tpPortConfigDuplex>)

=item $tplink->i_speed_admin()

Returns reference to hash. Configured speed per port, for example
C<speed-1Gigabps> or C<auto>.

(C<tpPortConfigSpeed>)

=item $tplink->fw_port()

Returns reference to hash of forwarding table entries port interface
identifier (iid). Values come from C<qb_fw_port> (Q-BRIDGE or the TP-Link
dynamic table) or else BRIDGE-MIB. Port 0 (not learned) is dropped. A port
number resolves to the single C<u/s/number> interface (ambiguous on a
stack), else an existing ifIndex, else C<bp_index>. Unresolved values stay
as reported.

=item $tplink->qb_fw_port()

Returns reference to hash of Q-BRIDGE forwarding table ports, keyed
C<vlan.mac>. Uses C<dot1qTpFdbPort> when present, otherwise builds it from
C<tpl2BridgeManageDynPort> (index C<mac.vlan>). A C<u/s/p> value resolves
through the interface port map, a port number through the single
C<u/s/number> interface, then C<bp_index>. Unresolved values stay as
reported.

=back

=head2 TP-Link VLAN Port Table (C<vlanPortConfigTable>, C<vlanConfigTable>)

=over

=item $tplink->i_vlan()

Returns reference to hash. PVID per ifIndex from C<tp_vlan_port_pvid>.
When that column is empty, the VLAN a port is untagged in, for ports
untagged in exactly one VLAN.

=item $tplink->i_vlan_membership()

Returns reference to hash of arrays: key = ifIndex, value = array of VLAN
IDs (sorted, no repeats) from the tagged and untagged port lists. Tokens
the parser does not know, such as C<Tunnel1>, are skipped. Q-BRIDGE is not
polled.

=item $tplink->i_vlan_membership_untagged()

Returns reference to hash of arrays: key = ifIndex, value = array of VLAN
IDs from the untagged port lists only.

=item $tplink->tp_vlan_port_pvid()

Returns reference to hash. PVID per ifIndex. netdisco-mibs names column 2
C<vlanPortType> with enumerated labels, so the device may return C<trunk>
for VLAN 1; C<munge_tp_pvid> maps the label back. It is polled by number
(netdisco/netdisco-mibs#281).

(C<vlanPortPvid>, .1.3.6.1.4.1.11863.6.14.1.1.1.1.2)

=item $tplink->tp_vlan_tagged()

Returns reference to hash. Tagged member port list per VLAN ID, as text
such as C<1/0/15-18,LAG1>.

(C<vlanTagPortMemberAdd>)

=item $tplink->tp_vlan_untagged()

Returns reference to hash. Untagged member port list per VLAN ID, as text.

(C<vlanUntagPortMemberAdd>)

=back

=head2 Power Over Ethernet Port Table

These methods emulate the F<POWER-ETHERNET-MIB> Power Source Entity (PSE)
Port Table C<pethPsePortTable> methods using the
F<TPLINK-POWER-OVER-ETHERNET-MIB> PoE Port Configuration Table
C<tpPoePortConfigTable>. Entries are keyed C<unit.port> with unit 1; ports
without a matching interface are omitted.

=over

=item $tplink->peth_port_ifindex()

Returns reference to hash. Maps C<unit.port> to ifIndex for every port in
C<tp_peth_port_admin> that has an interface.

=item $tplink->peth_port_admin()

Administrative status: is this port permitted to deliver power? C<true>
or C<false>, from C<tp_peth_port_admin>.

=item $tplink->peth_port_status()

Current status, from C<tp_peth_port_status>: C<on> is
C<deliveringPower>; C<off> and C<turning-on> are C<searching>;
C<overload>, C<short>, C<voltage-high>, C<voltage-low>, C<hardware-fault>
and C<overtemperature> are C<fault>; anything else is C<otherFault>. A
port with C<tp_peth_port_admin> C<disable> is C<disabled>.

=item $tplink->peth_port_class()

Device class as the device reports it, for example C<class3>, from
C<tp_peth_port_class>.

=item $tplink->peth_port_power()

The power, in milliwatts, that the port is delivering, from
C<tp_peth_port_power>.

=item $tplink->peth_power_watts()

The PoE power budget, in watts: C<{1 =E<gt> $watts}> from
C<tp_power_limit>, else an empty hash.

=item $tplink->peth_power_status()

The PoE module status: C<{1 =E<gt> 'on'}> when C<tp_power_limit> is
reported, else an empty hash.

=item $tplink->tp_peth_port_admin()

Returns reference to hash. PoE enabled per port number: C<disable> or
C<enable>.

(C<tpPoePortStatus>)

=item $tplink->tp_peth_port_status()

Returns reference to hash. PoE power state per port number, for example
C<on>, C<off> or C<overload>.

(C<tpPoePowerStatus>)

=item $tplink->tp_peth_port_class()

Returns reference to hash. PoE class per port number.

(C<tpPoeClass>)

=item $tplink->tp_peth_port_power()

Returns reference to hash. Real time power per port number, in units of
0.1 W.

(C<tpPoePower>)

=back

=head2 LLDP Neighbor Information

The neighbor source is decided once per device: LLDP-MIB when it has
remote rows, in which case these methods defer to L<SNMP::Info::LLDP>,
otherwise the F<TPLINK-LLDPINFO-MIB> C<lldpNeighborInfoTable>, keyed
C<ifIndex.remIdx>.

=over

=item $tplink->lldp_if()

Returns reference to hash. Local ifIndex per neighbor. With TP-Link
neighbor data, the first component of the C<ifIndex.remIdx> index. With
LLDP-MIB neighbors, the local port number in the index is mapped through
C<lldpLocPortId> to the interface whose C<ifDescr> matches exactly; a port
with no exact match keeps the result of the inherited C<lldp_if>.

=item $tplink->lldp_ip()

Returns reference to hash. Remote IPv4 management address per neighbor
from C<tp_lldp_rman>. C<::a.b.c.d> is returned as C<a.b.c.d>; C<::> and
IPv6 are omitted.

=item $tplink->lldp_ipv6()

Returns reference to hash. Remote IPv6 management address per neighbor
from C<tp_lldp_rman>, as reported. C<::> and C<::a.b.c.d> are omitted.

=item $tplink->lldp_port()

Returns reference to hash. Remote port per neighbor: C<tp_lldp_rem_pid>,
else C<tp_lldp_rem_desc>.

=item $tplink->lldp_id()

Returns reference to hash. Remote chassis id per neighbor from
C<tp_lldp_rem_id>, as reported.

=item $tplink->lldp_platform()

Returns reference to hash. Remote platform per neighbor:
C<tp_lldp_rem_sysdesc>, else C<tp_lldp_rem_sysname>.

=item $tplink->lldp_cap()

Returns reference to hash of arrays. Remote capabilities per neighbor as
LLDP-MIB names such as C<bridge> and C<router>, parsed from the
C<tp_lldp_rem_cap_spt> text. Unknown words are dropped.

=item $tplink->tp_lldp_rem_id()

Returns reference to hash. Remote chassis id as text, for example
C<48:A9:8A:C1:AC:58>.

(C<lldpNeighborChassisId>)

=item $tplink->tp_lldp_rem_pid()

Returns reference to hash. Remote port id (column 6). Column 1,
C<lldpNeighborPortId>, is the local port.

(C<lldpNeighborPortIdDescr>)

=item $tplink->tp_lldp_rem_desc()

Returns reference to hash. Remote port description.

(C<lldpNeighborPortDescr>)

=item $tplink->tp_lldp_rem_sysname()

Returns reference to hash. Remote system name.

(C<lldpNeighborDeviceName>)

=item $tplink->tp_lldp_rem_sysdesc()

Returns reference to hash. Remote system description.

(C<lldpNeighborDeviceDescr>)

=item $tplink->tp_lldp_rem_cap_spt()

Returns reference to hash. Remote capabilities as text, for example
C<Bridge Router>.

(C<lldpNeighborCapAvailable>)

=item $tplink->tp_lldp_rman()

Returns reference to hash. Remote management address as text, for
example C<::169.254.2.131>.

(C<lldpNeighborManageIpAddr>)

=item $tplink->tp_lldp_oper_mau()

Returns reference to hash. Local operational MAU per ifIndex, for example
C<speed(1000M)/duplex(Full)>. Used by C<i_duplex> when EtherLike is
absent.

(C<lldpLocalOperMau>)

=back

=head2 Spanning Tree Port Table

These methods map the F<TPLINK-SPANNING-TREE-MIB> objects onto the
L<SNMP::Info::Bridge> spanning tree methods.

=over

=item $tplink->stp_i_root()

Returns reference to hash. CIST root bridge.

(C<tpStpCISTRoot>)

=item $tplink->stp_i_time()

Returns reference to hash. Time of the last topology change.

(C<tpStpLastTopologyChangeTime>)

=item $tplink->stp_i_root_port()

Returns reference to hash. Root port.

(C<tpStpRootPort>)

=item $tplink->stp_i_priority()

Returns reference to hash. Bridge priority in the CIST.

(C<tpStpCistPriority>)

=item $tplink->stp_p_id()

Returns reference to hash. Port number of the switch.

(C<tpStpPortNumber>)

=item $tplink->stp_p_priority()

Returns reference to hash. Port priority.

(C<tpStpPortPriority>)

=item $tplink->stp_p_state()

Returns reference to hash. Port state, for example C<blocking> or
C<forwarding>.

(C<tpStpPortStatus>)

=item $tplink->stp_p_cost()

Returns reference to hash. Internal path cost of the port.

(C<tpStpPortInPathCost>)

=item $tplink->stp_p_role()

Returns reference to hash. Port role, for example C<root> or
C<designated>.

(C<tpStpPortRole>)

=item $tplink->is_edgeport_admin()

Returns reference to hash. Edge port setting: C<disable> or C<enable>.

(C<tpStpEdgePortStatus>)

=item $tplink->is_edgeport_oper()

Returns reference to hash. Edge port status, read from the same object as
C<is_edgeport_admin>.

(C<tpStpEdgePortStatus>)

=back

=head2 Port Configuration and Dynamic Address Tables

=over

=item $tplink->tp_port_config_descr()

Returns reference to hash. Port description, used by C<i_name> when
C<ifAlias> has no rows.

(C<tpPortConfigDescription>)

=item $tplink->tpl2BridgeManageDynMac()

Returns reference to hash. Dynamic MAC address, indexed C<mac.vlan>.

(C<tpl2BridgeManageDynMac>)

=item $tplink->tpl2BridgeManageDynVlanId()

Returns reference to hash. VLAN ID of the dynamic MAC address.

(C<tpl2BridgeManageDynVlanId>)

=item $tplink->tpl2BridgeManageDynPort()

Returns reference to hash. Port of the dynamic MAC address, as a
C<u/s/p> name or a port number. Used by C<qb_fw_port> when Q-BRIDGE is
absent.

(C<tpl2BridgeManageDynPort>)

=back

=head2 Table Methods imported from SNMP::Info::EtherLike

See L<SNMP::Info::EtherLike/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=head1 Data Munging Callback Subroutines

=over

=item $tplink->munge_power()

Converts tenths of a watt to watts. Undef and zero return 0.

=item $tplink->munge_tp_pvid()

Maps the C<vlanPortType> labels C<access>, C<trunk> and C<general> back to
C<0>, C<1> and C<2>; other values are returned unchanged.

=back

=cut
