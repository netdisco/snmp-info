# SNMP::Info::Layer3::Extreme - SNMP Interface to Extreme devices
#
# Copyright (c) 2012 Eric Miller
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

package SNMP::Info::Layer3::Extreme;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::MAU;
use SNMP::Info::EDP;

@SNMP::Info::Layer3::Extreme::ISA
    = qw/SNMP::Info::Layer3 SNMP::Info::MAU
    SNMP::Info::EDP Exporter/;
@SNMP::Info::Layer3::Extreme::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %FUNCS, %MIBS, %MUNGE);

$VERSION = '3.984000';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::MAU::MIBS,
    %SNMP::Info::EDP::MIBS,
    'EXTREME-BASE-MIB'           => 'extremeAgent',
    'EXTREME-SYSTEM-MIB'         => 'extremeSystem',
    'EXTREME-FDB-MIB'            => 'extremeFdbMacFdbMacAddress',
    'EXTREME-VLAN-MIB'           => 'extremeVlan',
    'EXTREME-POE-MIB'            => 'extremePethSystemAdminEnable',
    'EXTREME-STP-EXTENSIONS-MIB' => 'extremeStpDomainBridgeId',
    'RAPID-CITY'                 => 'rcVrfName',
    'EXTREME-PORT-MIB'           => 'extremePortLoadshare2Status',
    'EXTREME-MLAG-MIB'           => 'extremeMlagPeerIP',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::MAU::GLOBALS,
    %SNMP::Info::EDP::GLOBALS,
    'serial1'        => 'extremeSystemID.0',
    'temp'           => 'extremeCurrentTemperature',
    'ps1_status_old' => 'extremePrimaryPowerOperational.0',
    'ps1_status_new' => 'extremePowerSupplyStatus.1',
    'ps2_status_old' => 'extremeRedundantPowerStatus.0',
    'ps2_status_new' => 'extremePowerSupplyStatus.2',
    'mac'            => 'dot1dBaseBridgeAddress',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::MAU::FUNCS,
    %SNMP::Info::EDP::FUNCS,
    'fan_state' => 'extremeFanOperational',
    # EXTREME-FDB-MIB:extremeFdbMacFdbTable
    'ex_fw_mac'    => 'extremeFdbMacFdbMacAddress',
    'ex_fw_port'   => 'extremeFdbMacFdbPortIfIndex',
    'ex_fw_status' => 'extremeFdbMacFdbStatus',
    # EXTREME-VLAN-MIB:extremeVlanIfTable
    'ex_vlan_descr'     => 'extremeVlanIfDescr',
    'ex_vlan_global_id' => 'extremeVlanIfGlobalIdentifier',
    'ex_vlan_id'        => 'extremeVlanIfVlanId',
    # EXTREME-VLAN-MIB:extremeVlanEncapsIfTable
    'ex_vlan_encap_tag' => 'extremeVlanEncapsIfTag',
    # EXTREME-VLAN-MIB:extremeVlanOpaqueTable
    'ex_vlan_untagged'  => 'extremeVlanOpaqueUntaggedPorts',
    'ex_vlan_tagged'    => 'extremeVlanOpaqueTaggedPorts',
    # EXTREME-POE-MIB::extremePethPseSlotTable
    'peth_power_watts'  => 'extremePethSlotPowerLimit',
    # EXTREME-POE-MIB::extremePethPsePortTable
    'peth_port_power'   => 'extremePethPortMeasuredPower',
    # EXTREME-STP-EXTENSIONS-MIB::extremeStpDomainTable
    'stp_i_time'      => 'extremeStpDomainTimeSinceTopologyChange',
    'stp_i_ntop'      => 'extremeStpDomainTopChanges',
    'stp_i_root'      => 'extremeStpDomainDesignatedRoot',
    'stp_i_root_port' => 'extremeStpDomainRootPortIfIndex',
    'stp_i_priority'  => 'extremeStpDomainBridgePriority',
    'ex_stp_i_mac'    => 'extremeStpDomainBridgeId',
    'ex_stp_i_name'   => 'extremeStpDomainStpdName',
    'ex_stp_i_tag'    => 'extremeStpDomainStpdTag',
    # EXTREME-STP-EXTENSIONS-MIB::extremeStpPortTable
    'stp_p_priority' => 'extremeStpPortPortPriority',
    'stp_p_state'    => 'extremeStpPortPortState',
    'stp_p_enable'   => 'extremeStpPortStpEnabled',
    'stp_p_cost'     => 'extremeStpPortPathCost',
    'stp_p_root'     => 'extremeStpPortDesignatedRoot',
    'stp_p_bridge'   => 'extremeStpPortDesignatedBridge',
    'stp_p_port'     => 'extremeStpPortDesignatedPort',
    'ex_stp_p_mode'  => 'extremeStpPortPortMode',
    # EXTREME-STP-EXTENSIONS-MIB::extremeStpVlanPortTable
    'ex_stp_vlan_mask' => 'extremeStpVlanPortPortMask',
    # RAPID-CITY::rcVrfConfigTable (VOSS)
    'vrf_rc_name'    => 'rcVrfName',
    'vrf_rc_context' => 'rcVrfContextName',
    # RAPID-CITY::rcVrfIpVpnTable (VOSS)
    'vrf_rc_isid' => 'rcVrfIpVpnIsidNumber',
    # RAPID-CITY::rcVlanTable (VOSS). RapidCity.pm reads rcVlanIfIndex and
    # rcIpAdEntAddr too, as rc_vlan_if and rc_ip_addr, but it is not a
    # parent of this class.
    'vrf_rc_vlan_if'  => 'rcVlanIfIndex',
    'vrf_rc_vlan_vrf' => 'rcVlanVrfId',
    # RAPID-CITY::rcIpAddrTable (VOSS)
    'vrf_rc_ip_vrf'  => 'rcIpAdEntVrfId',
    'vrf_rc_ip_addr' => 'rcIpAdEntAddr',
    'vrf_rc_ip_mask' => 'rcIpAdEntNetMask',
    # EXTREME-PORT-MIB::extremePortLoadshare2Table
    'ex_loadshare' => 'extremePortLoadshare2Status',
    # EXTREME-MLAG-MIB::extremeMlagPeerTable
    'ex_mlag_peer_ip'       => 'extremeMlagPeerIP',
    'ex_mlag_peer_status'   => 'extremeMlagPeerCheckPointStatus',
    'ex_mlag_peer_lacp_mac' => 'extremeMlagPeerOperLacpMac',
    # EXTREME-MLAG-MIB::extremeMlagPortTable
    'ex_mlag_port_id'    => 'extremeMlagPortId',
    'ex_mlag_port_peer'  => 'extremeMlagPortPeer',
    'ex_mlag_port_state' => 'extremeMlagPortLocalLinkStatus',
);

%MUNGE = (

    # Inherit all the built in munging
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::MAU::MUNGE,
    %SNMP::Info::EDP::MUNGE,
    'ex_fw_mac'        => \&SNMP::Info::munge_mac,
    'ex_mlag_peer_ip'       => \&SNMP::Info::munge_inetaddress,
    'ex_mlag_peer_lacp_mac' => \&SNMP::Info::munge_mac,
    'ps1_status_old'   => \&munge_true_ok,
    'ps1_status_new'   => \&munge_power_stat,
    'ps2_status_old'   => \&munge_power_stat,
    'ps2_status_new'   => \&munge_power_stat,
    'fan_state'        => \&munge_true_ok,
    'ex_vlan_untagged' => \&SNMP::Info::munge_port_list,
    'ex_vlan_tagged'   => \&SNMP::Info::munge_port_list,
    'ex_stp_i_mac'     => \&SNMP::Info::munge_prio_mac,
    'stp_i_root'       => \&SNMP::Info::munge_prio_mac,
    'stp_p_root'       => \&SNMP::Info::munge_prio_mac,
    'stp_p_bridge'     => \&SNMP::Info::munge_prio_mac,
    'stp_p_port'       => \&SNMP::Info::munge_prio_port,
);

# Method OverRides

*SNMP::Info::Layer3::Extreme::i_duplex = \&SNMP::Info::MAU::mau_i_duplex;
*SNMP::Info::Layer3::Extreme::i_duplex_admin
    = \&SNMP::Info::MAU::mau_i_duplex_admin;

# extremePortLoadshare2Table is indexed master.member; the master lists
# itself as a member, which agg_ports leaves out
sub agg_ports {
    my $extreme = shift;

    my $loadshare = $extreme->ex_loadshare() || {};
    my %member_of;
    foreach my $iid ( keys %$loadshare ) {
        my ( $master, $member ) = split /\./, $iid;
        next if !defined $member or $member eq $master;
        $member_of{$member} = $master;
    }
    return \%member_of;
}

sub _agg_ports_walked { return qw/ex_loadshare/ }

# The peer table is indexed by the peer name, a string
sub _ex_mlag_peer_name {
    my $iid = shift;

    return $iid unless $iid =~ /^\d+(?:\.\d+)+$/;
    my ( $length, @codes ) = split /\./, $iid;
    return $iid unless $length == scalar @codes;
    return join '', map { chr } @codes;
}

# EXOS 33.6 serves extremeMlagPeerIP as text ("192.0.2.2"), which the
# binary InetAddress munge reads as nothing
sub _ex_text_address {
    my $raw = shift;

    return unless defined $raw;
    return $raw if $raw =~ /^\d{1,3}(?:\.\d{1,3}){3}$/;
    return $raw if $raw =~ /^[0-9a-fA-F:.]*:[0-9a-fA-F:.]*:[0-9a-fA-F:.]*$/;
    return;
}

sub _lag_vendor_walked {
    return qw/ex_loadshare ex_mlag_peer_ip ex_mlag_peer_status
        ex_mlag_peer_lacp_mac ex_mlag_port_id ex_mlag_port_peer
        ex_mlag_port_state/;
}

sub _lag_vendor_domains {
    my $extreme = shift;

    my %columns = (
        peer   => [ ex_mlag_peer_ip     => 'extremeMlagPeerIP' ],
        status => [
            ex_mlag_peer_status => 'extremeMlagPeerCheckPointStatus'
        ],
        system_mac => [
            ex_mlag_peer_lacp_mac => 'extremeMlagPeerOperLacpMac'
        ],
    );
    my $peers = $extreme->ex_mlag_peer_ip() || {};
    my $text_peers = $extreme->ex_mlag_peer_ip_raw() || {};
    my $domains = {};
    foreach my $iid ( keys %$peers ) {
        my $domain = { kind => 'mlag', sources => {} };
        foreach my $field ( keys %columns ) {
            my ( $method, $leaf ) = @{ $columns{$field} };
            $domain->{$field} = ( $extreme->$method() || {} )->{$iid};
            $domain->{$field} = _ex_text_address( $text_peers->{$iid} )
                if $field eq 'peer' and !$domain->{$field};
            $domain->{sources}{$field} = 'EXTREME-MLAG-MIB::' . $leaf
                if defined $domain->{$field};
        }
        $domains->{ _ex_mlag_peer_name($iid) } = $domain;
    }
    return $domains;
}

sub _lag_vendor_groups {
    my ( $extreme, $groups ) = @_;

    $extreme->_ex_loadshare_masters($groups);
    $extreme->_ex_mlag_ports($groups);
    return;
}

# The master is a member of its own aggregate in lag_groups
sub _ex_loadshare_masters {
    my ( $extreme, $groups ) = @_;

    my $loadshare = $extreme->ex_loadshare() || {};
    foreach my $iid ( keys %$loadshare ) {
        my ( $master, $member ) = split /\./, $iid;
        next if !defined $member or $member ne $master;
        my $record = $groups->{$master} or next;
        $extreme->_lag_place_members( $groups, $master, { $master => 1 },
            $record->{sources}{members}
                || 'EXTREME-PORT-MIB::extremePortLoadshare2Status' );
    }
    return;
}

sub _ex_mlag_ports {
    my ( $extreme, $groups ) = @_;

    my $ids    = $extreme->ex_mlag_port_id()    || {};
    my $peers  = $extreme->ex_mlag_port_peer()  || {};
    my $states = $extreme->ex_mlag_port_state() || {};
    foreach my $port ( keys %$ids ) {
        my $aggregate = _ex_aggregate_of( $groups, $port );
        my $members = $aggregate ? $groups->{$aggregate}{members} : {};
        $aggregate
            = $extreme->_ex_lone_mlag_port( $groups, $aggregate, $port )
            unless scalar keys %$members;
        $groups->{$aggregate}{mc} = {
            kind   => 'mlag',
            group  => $ids->{$port},
            domain => $peers->{$port},
            state  => $states->{$port},
        };
        $groups->{$aggregate}{sources}{mc}
            = 'EXTREME-MLAG-MIB::extremeMlagPortId';
    }
    return;
}

# An MLAG port on a load sharing group of one, or on no load sharing group,
# is its own aggregate; it is keyed by the load sharing master when it has one
sub _ex_lone_mlag_port {
    my ( $extreme, $groups, $aggregate, $port ) = @_;

    my $loadshare = $extreme->ex_loadshare() || {};
    my $key = $aggregate;
    foreach my $iid ( keys %$loadshare ) {
        my ( $master, $member ) = split /\./, $iid;
        $key = $master if defined $member and $member eq $port;
    }
    $key = $port unless defined $key;
    my $source = $key eq $port && !grep { /^\Q$key\E\./ } keys %$loadshare
        ? 'EXTREME-MLAG-MIB::extremeMlagPortLocalPortIfIndex'
        : 'EXTREME-PORT-MIB::extremePortLoadshare2Status';
    $extreme->_lag_place_members( $groups, $key, { $port => 1 }, $source );
    return $key;
}

# The MLAG port is the aggregate's master or a single member of it
sub _ex_aggregate_of {
    my ( $groups, $port ) = @_;

    return $port if $groups->{$port};
    foreach my $aggregate ( keys %$groups ) {
        return $aggregate if $groups->{$aggregate}{members}{$port};
    }
    return;
}

sub model {
    my $extreme = shift;
    my $id      = $extreme->id();

    unless ( defined $id ) {
        print
            " SNMP::Info::Layer3::Extreme::model() - Device does not support sysObjectID\n"
            if $extreme->debug();
        return;
    }

    my $model = &SNMP::translateObj($id);

    return $id unless defined $model;

    return $model;
}

sub vendor {
    return 'extreme';
}

sub os {
    my $extreme = shift;
    my $desc = $extreme->description();

    if ( $desc =~ /xos/i ) {
        return 'xos';
    }

    return 'voss' if defined _voss_version($desc);

    return 'extremeware';
}


sub os_ver {
    my $extreme = shift;
    my $descr   = $extreme->description();
    return unless defined $descr;

    if ( $descr =~ m/Version\s+([^ ]+)/i ) {
        return $1;
    }

    return _voss_version($descr);
}

# VOSS / Fabric Engine sysDescr is "<model> (<a.b.c.d>[_build])"
sub _voss_version {
    my $descr = shift;
    return unless defined $descr;

    if ( $descr =~ m/^\S+\s+\((\d+(?:\.\d+){3})/ ) {
        return $1;
    }

    return;
}

#
# ifName is a nice concise port name on Extreme devices.
# Layer3.pm defaults to i_description, which is verbose
# and has spaces.  However, ifName has the IP address
# assigned for router interfaces, so we use ifDescr
# for those.
sub interfaces {
    my $extreme       = shift;
    my $partial       = shift;
    my $i_name        = $extreme->orig_i_name($partial);
    my $i_description = $extreme->orig_i_description($partial);
    my $interfaces    = {};
    foreach my $idx ( keys %$i_name ) {
        if ( $i_name->{$idx} =~ /\([0-9.]+\)/ ) {
            $interfaces->{$idx} = $i_description->{$idx};
        }
        else {
            $interfaces->{$idx} = $i_name->{$idx};
        }
    }
    return $interfaces;
}

#
# Ignore VLAN meta-interfaces and loopback
sub i_ignore {
    my $extreme = shift;
    my $partial = shift;

    my $i_description = $extreme->i_description($partial) || {};

    my %i_ignore;
    foreach my $if ( keys %$i_description ) {
        if ( $i_description->{$if}
            =~ /^(802.1Q Encapsulation Tag \d+|VLAN \d+|lo\d+|VirtualRouter\d+)/i )
        {
            $i_ignore{$if}++;
        }
    }
    return \%i_ignore;
}

# When we use the extreme_fw_* objects, we're not using BRIDGE-MIB.
# Either way, Extreme uses a 1:1 mapping of bridge interface ID to
# ifIndex.
sub bp_index {
    my $extreme  = shift;

    my $bindex = $extreme->SUPER::bp_index();
    return $bindex if (keys %$bindex);

    my $if_index = $extreme->i_index();

    my %bp_index;
    foreach my $iid ( keys %$if_index ) {
        $bp_index{$iid} = $iid;
    }
    return \%bp_index;
}

sub munge_true_ok {
    my $val = shift;
    return unless defined($val);
    return "OK"     if ( $val eq 'true' );
    return "Not OK" if ( $val eq 'false' );
    return $val;
}

sub munge_power_stat {
    my $val = shift;
    return unless defined($val);
    $val =~ s/^present//;
    $val =~ s/^not/Not /i;
    return $val;
}

sub ps1_status {
    my $extreme    = shift;
    my $ps1_status = $extreme->ps1_status_new();
    return $ps1_status || $extreme->ps1_status_old();
}

sub ps2_status {
    my $extreme    = shift;
    my $ps2_status = $extreme->ps2_status_new();
    return $ps2_status || $extreme->ps2_status_old();
}

sub fan {
    my $extreme   = shift;
    my $fan_state = $extreme->fan_state();
    my $ret       = "";
    my $s         = "";
    foreach my $i ( sort { $a <=> $b } keys %$fan_state ) {
        $ret .= $s . $i . ": " . $fan_state->{$i};
        $s = ", ";
    }
    return if ( $s eq "" );
    return $ret;
}

# For xos based VLAN functions we need to know how the ports are indexed
# default is slot * 1000, but some older switches start at 1
sub _slot_factor {
    my $extreme = shift;

    my $index = $extreme->i_index();

    return 1 if (exists $index->{1} && $index->{1} == 1);
    return 1000;
}

# Some versions of the Extreme firmware have vendor-specific tables
# for this; those are ex_fw_*().  Some don't have these tables,
# we use the BRIDGE-MIB tables if available then the ex_fw_*() methods.
sub fw_mac {
    my $extreme = shift;

    my $fw_m = $extreme->SUPER::fw_mac();
    return $fw_m if (keys %$fw_m);

    return $extreme->ex_fw_mac();
}

sub fw_port {
    my $extreme = shift;

    my $fw_p = $extreme->SUPER::fw_port();
    return $fw_p if (keys %$fw_p);

    return $extreme->ex_fw_port();
}

sub fw_status {
    my $extreme   = shift;

    my $fw_s = $extreme->SUPER::fw_status();
    return $fw_s if (keys %$fw_s);

    return $extreme->ex_fw_status();
}

# Mapping the virtual VLAN interfaces:
# The virtual VLAN interfaces in extremeVlanIfTable
#  are the higher layer above the interfaces that are
#  untagged, and also above an interface in
#  extremeVlanEncapsIfTable that does the encapsulation.
# Note that it's possible to have a VLAN defined that
#  does not have a tag, if it has all native interfaces.
#  To represent this, we use a negative version of the
#  internal VLAN ID (the deprecated extremeVlanIfGlobalIdentifier)
sub _if2tag {
    my $extreme    = shift;
    my $partial    = shift;
    my $stack      = shift || $extreme->ifStackStatus($partial);
    my $encap_tag  = $extreme->ex_vlan_encap_tag();
    my $vlan_descr = $extreme->ex_vlan_descr();

    my $stackmap = {};
    foreach my $idx ( keys %$stack ) {
        my ( $higher, $lower ) = split( /\./, $idx );
        $stackmap->{$higher}->{$lower} = $stack->{$idx};
    }

    my %if2tag = ();
    my $missed = 0;
    foreach my $if ( keys %$vlan_descr ) {
        $if2tag{$if} = -1;
        foreach my $tagif ( keys %$encap_tag ) {
            if ( defined( $stackmap->{$if}->{$tagif} )
                && $stackmap->{$if}->{$tagif} eq 'active' )
            {
                $if2tag{$if} = $encap_tag->{$tagif};
            }
        }
        if ( $if2tag{$if} == -1 ) {
            $missed++;
        }
    }
    if ($missed) {
        my $global_id = $extreme->ex_vlan_id();
        foreach my $if ( keys %if2tag ) {
            $if2tag{$if} = -$global_id->{$if}
                if ( $if2tag{$if} == -1 && defined( $global_id->{$if} ) );
        }
    }
    return \%if2tag;
}

# No partial support in v_name or v_index, because the obvious partial
# is the VLAN ID and the index here is the ifIndex of
# the VLAN interface.
sub v_name {
    my $extreme = shift;

    my $names = $extreme->ex_vlan_descr() || {};
    return $names if scalar keys %$names;
    return $extreme->qb_v_name() || {};
}

sub v_index {
    my $extreme = shift;

    my $names = $extreme->ex_vlan_descr() || {};
    return $extreme->SUPER::v_index() unless scalar keys %$names;
    return $extreme->ex_vlan_id || $extreme->_if2tag();
}

sub i_vlan {
    my $extreme    = shift;
    my $partial    = shift;

    # Some devices support Q-Bridge, if so short circuit and return it
    my $q_bridge = $extreme->SUPER::i_vlan($partial);
    return $q_bridge if (keys %$q_bridge);

    # Next we try extremeVlanOpaqueTable
    my $xos = $extreme->_xos_i_vlan($partial);
    return $xos if (keys %$xos);

    # Try older ifStack method
    my $extremeware = $extreme->_extremeware_i_vlan($partial);
    return $extremeware if (keys %$extremeware);

    return;
}

sub _xos_i_vlan {
    my $extreme = shift;
    my $partial = shift;

    my $index   = $extreme->i_index();
    my $vlans   = $extreme->ex_vlan_id() || {};
    my $slotx   = $extreme->_slot_factor() || 1000;
    my $u_ports = $extreme->ex_vlan_untagged() || {};

    my $i_vlan = {};
    foreach my $idx ( keys %$u_ports ) {
        next unless ( defined $u_ports->{$idx} );
        my $portlist = $u_ports->{$idx};
        my $ret      = [];

        my ( $vlan_if, $slot ) = $idx =~ /^(\d+)\.(\d+)/;
        my $vlan = $vlans->{$vlan_if} || '';

        # Convert portlist bit array to bp_index array
        for ( my $i = 0; $i <= $#$portlist; $i++ ) {
            push( @{$ret}, ( $slotx * $slot + $i + 1 ) )
                if ( @$portlist[$i] );
        }

        #Create HoA ifIndex -> VLAN array
        foreach my $port ( @{$ret} ) {
            my $ifindex = $index->{$port};
            next unless ( defined($ifindex) );    # shouldn't happen
            next if ( defined $partial and $ifindex !~ /^$partial$/ );
            $i_vlan->{$ifindex} = $vlan;
        }
    }
    return $i_vlan;
}

sub _extremeware_i_vlan {
    my $extreme    = shift;
    my $partial    = shift;
    my $stack      = $extreme->ifStackStatus($partial);
    my $encap_tag  = $extreme->ex_vlan_encap_tag();
    my $vlan_descr = $extreme->ex_vlan_descr();
    my $stackmap   = {};
    foreach my $idx ( keys %$stack ) {
        my ( $higher, $lower ) = split( /\./, $idx );
        $stackmap->{$higher}->{$lower} = $stack->{$idx};
    }
    my $if2tag = $extreme->_if2tag( $partial, $stack );

    #
    # Now that we've done all that mapping work, we can map the
    #   ifStack indexes.
    my %i_vlan = ();
    foreach my $if ( keys %$if2tag ) {
        foreach my $lowif ( keys %{ $stackmap->{$if} } ) {
            $i_vlan{$lowif} = $if2tag->{$if};
        }
    }
    return \%i_vlan;
}

sub i_vlan_membership {
    my $extreme = shift;
    my $partial = shift;

    # Some devices support Q-Bridge, if so short circuit and return it
    my $q_bridge = $extreme->SUPER::i_vlan_membership($partial);
    return $q_bridge if (ref {} eq ref $q_bridge and scalar keys %$q_bridge);

    # Next we try extremeVlanOpaqueTable
    my $xos = $extreme->_xos_i_vlan_membership($partial);
    return $xos if (ref {} eq ref $xos and scalar keys %$xos);

    # Try older ifStack method
    my $extremeware = $extreme->_extremeware_i_vlan_membership($partial);
    return $extremeware if (ref {} eq ref $extremeware and scalar keys %$extremeware);

    return;
}

sub _xos_i_vlan_membership {
    my $extreme = shift;
    my $partial = shift;

    my $index   = $extreme->i_index();
    my $vlans   = $extreme->ex_vlan_id();
    my $slotx   = $extreme->_slot_factor() || 1000;
    my $u_ports = $extreme->ex_vlan_untagged() || {};
    my $t_ports = $extreme->ex_vlan_tagged() || {};

    my $i_vlan_membership = {};
    foreach my $idx ( keys %$u_ports ) {
        next unless ( defined $u_ports->{$idx} );
        my $u_portlist = $u_ports->{$idx};
        my $t_portlist = $t_ports->{$idx};
        my $ret        = [];

        my ( $vlan_if, $slot ) = $idx =~ /^(\d+)\.(\d+)/;
        my $vlan = $vlans->{$vlan_if} || '';

        foreach my $portlist ( $u_portlist, $t_portlist ) {

            # Convert portlist bit array to bp_index array
            for ( my $i = 0; $i <= $#$portlist; $i++ ) {
                push( @{$ret}, ( $slotx * $slot + $i + 1 ) )
                    if ( @$portlist[$i] );
            }
        }

        #Create HoA ifIndex -> VLAN array
        foreach my $port ( @{$ret} ) {
            my $ifindex = $index->{$port};
            next unless ( defined($ifindex) );    # shouldn't happen
            next if ( defined $partial and $ifindex !~ /^$partial$/ );
            push( @{ $i_vlan_membership->{$ifindex} }, $vlan );
        }
    }
    return $i_vlan_membership;
}

sub _extremeware_i_vlan_membership {
    my $extreme    = shift;
    my $partial    = shift;
    my $stack      = $extreme->ifStackStatus($partial);
    my $encap_tag  = $extreme->ex_vlan_encap_tag();
    my $vlan_descr = $extreme->ex_vlan_descr();
    my $stackmap   = {};
    foreach my $idx ( keys %$stack ) {
        my ( $higher, $lower ) = split( /\./, $idx );
        $stackmap->{$higher}->{$lower} = $stack->{$idx};
    }
    my $if2tag = $extreme->_if2tag( $partial, $stack );

    #
    # Now that we've done all that mapping work, we can map the
    #   ifStack indexes.
    my %i_vlan_membership = ();
    foreach my $if ( keys %$if2tag ) {
        foreach my $lowif ( keys %{ $stackmap->{$if} } ) {
            push( @{ $i_vlan_membership{$lowif} }, $if2tag->{$if} );
        }
    }

    #
    # Now add all the tagged ports.
    foreach my $if ( keys %$encap_tag ) {
        foreach my $lowif ( keys %{ $stackmap->{$if} } ) {
            push( @{ $i_vlan_membership{$lowif} }, $encap_tag->{$if} );
        }
    }
    return \%i_vlan_membership;
}

sub i_vlan_membership_untagged {
    my $extreme = shift;
    my $partial = shift;

    # Some devices support Q-Bridge, if so short circuit and return it
    my $q_bridge = $extreme->SUPER::i_vlan_membership_untagged($partial);
    return $q_bridge if (ref {} eq ref $q_bridge and scalar keys %$q_bridge);

    # Next we try extremeVlanOpaqueTable
    my $xos = $extreme->_xos_i_vlan_membership_untagged($partial);
    return $xos if (ref {} eq ref $xos and scalar keys %$xos);

    # Try older ifStack method
    my $extremeware = $extreme->_extremeware_i_vlan_membership_untagged($partial);
    return $extremeware if (ref {} eq ref $extremeware and scalar keys %$extremeware);

    return;
}

sub _xos_i_vlan_membership_untagged {
    my $extreme = shift;
    my $partial = shift;

    my $index   = $extreme->i_index();
    my $vlans   = $extreme->ex_vlan_id();
    my $slotx   = $extreme->_slot_factor() || 1000;
    my $u_ports = $extreme->ex_vlan_untagged() || {};

    my $i_vlan_membership = {};
    foreach my $idx ( keys %$u_ports ) {
        next unless ( defined $u_ports->{$idx} );
        my $u_portlist = $u_ports->{$idx};
        my $ret        = [];

        my ( $vlan_if, $slot ) = $idx =~ /^(\d+)\.(\d+)/;
        my $vlan = $vlans->{$vlan_if} || '';

        foreach my $portlist ( $u_portlist ) {

            # Convert portlist bit array to bp_index array
            for ( my $i = 0; $i <= $#$portlist; $i++ ) {
                push( @{$ret}, ( $slotx * $slot + $i + 1 ) )
                    if ( @$portlist[$i] );
            }
        }

        #Create HoA ifIndex -> VLAN array
        foreach my $port ( @{$ret} ) {
            my $ifindex = $index->{$port};
            next unless ( defined($ifindex) );    # shouldn't happen
            next if ( defined $partial and $ifindex !~ /^$partial$/ );
            push( @{ $i_vlan_membership->{$ifindex} }, $vlan );
        }
    }
    return $i_vlan_membership;
}

# Assuming Cisco-like trunk behavior that native VLAN is transmitted untagged
sub _extremeware_i_vlan_membership_untagged {
    my $extreme  = shift;
    my $partial = shift;

    my $vlans = $extreme->_extremeware_i_vlan($partial);
    my $i_vlan_membership = {};
    foreach my $port (keys %$vlans) {
        my $vlan = $vlans->{$port};
        push( @{ $i_vlan_membership->{$port} }, $vlan );
    }

    return $i_vlan_membership;
}

# VLAN management.
# See extreme-vlan.mib for a detailed description of
# Extreme's use of ifStackTable and EXTREME-VLAN-MIB.
# EXOS no longer has those tables, so it is managed through Q-BRIDGE-MIB.

sub _has_vlan_encaps {
    my $extreme   = shift;
    my $encap_tag = $extreme->ex_vlan_encap_tag() || {};
    return scalar keys %$encap_tag;
}

sub set_i_vlan {
    my $extreme = shift;
    return $extreme->_qb_set_i_vlan( 0, @_ )
        unless $extreme->_has_vlan_encaps();
    return $extreme->_extreme_set_i_vlan( 0, @_ );
}

sub set_i_pvid {
    my $extreme = shift;
    return $extreme->_qb_set_i_vlan( 1, @_ )
        unless $extreme->_has_vlan_encaps();
    return $extreme->_extreme_set_i_vlan( 1, @_ );
}

sub _qb_bridge_port {
    my ( $extreme, $ifindex ) = @_;
    my $bp_index = $extreme->bp_index() || {};
    my %if_bp    = reverse %$bp_index;

    my $bp = $if_bp{$ifindex};
    $extreme->error_throw(
        "ifIndex $ifindex is not a bridge port, so its VLANs cannot be set")
        unless defined $bp;
    return $bp;
}

sub _qb_port_in_list {
    my ( $extreme, $method, $vlan_id, $bp ) = @_;
    my $lists = $extreme->$method() || {};
    my $list  = $lists->{$vlan_id}  || [];
    return $list->[ $bp - 1 ];
}

sub _qb_port_is_tagged {
    my ( $extreme, $vlan_id, $bp ) = @_;
    return
        unless $extreme->_qb_port_in_list( 'qb_v_egress', $vlan_id, $bp );
    return !$extreme->_qb_port_in_list( 'qb_v_untagged', $vlan_id, $bp );
}

sub _qb_set_egress {
    my ( $extreme, $vlan_id, $bp, $member ) = @_;
    my $egress = $extreme->qb_v_egress() || {};

    unless ( defined $egress->{$vlan_id} ) {
        $extreme->error_throw(
            "VLAN $vlan_id does not exist in dot1qVlanStaticEgressPorts; create it on the device first"
        );
        return;
    }
    my $portlist = $extreme->modify_port_list( [ @{ $egress->{$vlan_id} } ],
        $bp - 1, $member );
    return $extreme->set_qb_v_egress( $portlist, $vlan_id );
}

# Writing dot1qPvid moves the port's untagged membership to the new VLAN.
# A VLAN already tagged on the port would stay tagged, leaving the port
# with no untagged VLAN, so set_i_vlan removes the tag first.
sub _qb_set_i_vlan {
    my ( $extreme, $is_pvid, $vlan_id, $ifindex ) = @_;
    my $bp = $extreme->_qb_bridge_port($ifindex);
    return unless defined $bp;

    if ( $extreme->_qb_port_is_tagged( $vlan_id, $bp ) ) {
        if ($is_pvid) {
            $extreme->error_throw(
                "VLAN $vlan_id is tagged on ifIndex $ifindex and cannot also be its PVID; use set_i_vlan to make it the untagged VLAN"
            );
            return;
        }
        return unless $extreme->_qb_set_egress( $vlan_id, $bp, '0' );
    }
    return $extreme->set_qb_i_vlan( $vlan_id, $bp );
}

sub _qb_set_i_vlan_tagged {
    my ( $extreme, $member, $vlan_id, $ifindex ) = @_;
    my $bp = $extreme->_qb_bridge_port($ifindex);
    return unless defined $bp;

    if ( $extreme->_qb_port_in_list( 'qb_v_untagged', $vlan_id, $bp ) ) {
        $extreme->error_throw(
            "VLAN $vlan_id is untagged on ifIndex $ifindex; use set_i_vlan to change the untagged VLAN"
        );
        return;
    }
    return $extreme->_qb_set_egress( $vlan_id, $bp, $member );
}

# set_i_vlan implicitly turns off any encapsulation
# set_i_pvid retains any encapsulation
# otherwise they do the same: set the unencapsulated
# vlan ID.
# First arg to _set_i_vlan is whether or not to turn
# off any encapsulation.
sub _extreme_set_i_vlan {
    my $extreme = shift;
    my ( $is_pvid, $vlan_id, $ifindex ) = @_;
    my $encap_tag = $extreme->ex_vlan_encap_tag();

    # The inverted stack MIB would make this easier, since
    # we need to find the vlan interface
    # that's stacked above $ifindex.
    my $cur_stack = $extreme->ifStackStatus();

    #
    # create inverted stack
    my $invstack;
    foreach my $idx ( keys %$cur_stack ) {
        my ( $higher, $lower ) = split( /\./, $idx );
        $invstack->{$lower}->{$higher} = $cur_stack->{$idx};
    }

    # create vlan tag -> encap interface map
    my %encapif = reverse %$encap_tag;

    # now find encap interface from tag
    my $encapidx = $encapif{$vlan_id};
    if ( !defined($encapidx) ) {
        $extreme->error_throw(
            "can't map $vlan_id to encapsulation interface");
        return;
    }

    # now find vlan interface stacked above encap
    my @abovevlan = keys %{ $invstack->{$encapidx} };
    if ( @abovevlan != 1 ) {
        $extreme->error_throw(
            "can't map encap interface $encapidx for $vlan_id to encapsulation interface"
        );
        return;
    }
    my $vlanidx = $abovevlan[0];
    my $rv;

    # Delete old VLAN mapping
    foreach my $oldidx ( keys %{ $invstack->{$ifindex} } ) {
        if ( $is_pvid && defined( $encap_tag->{$oldidx} ) ) {
            next;    # Don't delete tagged mappings
        }
        $rv = $extreme->set_ifStackStatus( "destroy",
            $oldidx . "." . $ifindex );
        unless ($rv) {
            $extreme->error_throw(
                "Unable to remove $ifindex from old VLAN index $oldidx");
            return;
        }
    }

    # Add new VLAN mapping
    $rv = $extreme->set_ifStackStatus( "createAndGo",
        $vlanidx . "." . $ifindex );
    unless ($rv) {
        $extreme->error_throw(
            "Unable to add new VLAN index $vlanidx to ifIndex $ifindex");
        return;
    }

# XXX invalidate cache of ifstack?
# XXX Info.pm library function for this?
# XXX set_ should do invalidation?
# $store = $extreme->store(); delete $store->{ifStackStatus}; $extreme->store($store);
# $extreme->{_ifStackStatus} = 0;
    return $rv;
}

sub set_remove_i_vlan_tagged {
    my $extreme = shift;
    return $extreme->_qb_set_i_vlan_tagged( '0', @_ )
        unless $extreme->_has_vlan_encaps();

    my ( $vlan_id, $ifindex ) = @_;
    my $encap_tag = $extreme->ex_vlan_encap_tag();

    # create vlan tag -> encap interface map
    my %encapif = reverse %$encap_tag;

    # now find encap interface from tag
    my $encapidx = $encapif{$vlan_id};
    if ( !defined($encapidx) ) {
        $extreme->error_throw(
            "can't map $vlan_id to encapsulation interface");
        return;
    }
    my $rv = $extreme->set_ifStackStatus( "destroy",
        $encapidx . "." . $ifindex );
    unless ($rv) {
        $extreme->error_throw(
            "Unable to delete VLAN encap ifIndex $encapidx for VLAN $vlan_id from ifIndex $ifindex"
        );
        return;
    }

    # invalidate cache of ifstack?
    return $rv;
}

sub set_add_i_vlan_tagged {
    my $extreme = shift;
    return $extreme->_qb_set_i_vlan_tagged( '1', @_ )
        unless $extreme->_has_vlan_encaps();

    my ( $vlan_id, $ifindex ) = @_;
    my $encap_tag = $extreme->ex_vlan_encap_tag();

    # create vlan tag -> encap interface map
    my %encapif = reverse %$encap_tag;

    # now find encap interface from tag
    my $encapidx = $encapif{$vlan_id};
    if ( !defined($encapidx) ) {
        $extreme->error_throw(
            "can't map $vlan_id to encapsulation interface");
        return;
    }
    my $rv = $extreme->set_ifStackStatus( "createAndGo",
        $encapidx . "." . $ifindex );
    unless ($rv) {
        $extreme->error_throw(
            "Unable to add VLAN encap ifIndex $encapidx for VLAN $vlan_id to ifIndex $ifindex"
        );
        return;
    }

    # invalidate cache of ifstack?
    return $rv;
}

# LLDP uses the bridge index rather than ifIndex
sub lldp_if {
    my $extreme = shift;
    my $partial = shift;

    my $addr    = $extreme->lldp_rem_pid($partial) || {};
    my $b_index = $extreme->bp_index() || {};
    #my %r_i_descr = reverse %$i_descr;

    my %lldp_if;
    foreach my $key ( keys %$addr ) {
        my @aOID = split( '\.', $key );
        my $port = $aOID[1];
        next unless $port;

        my $idx = $b_index->{$port};

        $lldp_if{$key} = $idx;
    }
    return \%lldp_if;
}

# extremeStpDomainStpdInstance not accessible, so we need to extract from iid
sub stp_i_id {
    my $extreme  = shift;
    my $partial  = shift;

    my $stp_i_roots = $extreme->stp_i_root($partial);

    my %stp_i_id;
    foreach my $iid ( keys %$stp_i_roots ) {
        $stp_i_id{$iid} = $iid;
    }
    return \%stp_i_id;
}

# extremeStpDomainBridgeId returns priority and mac,
# for cross class compatibility we just need mac
sub stp_i_mac {
    my $extreme  = shift;
    my $partial  = shift;

    my $stp_i_bids = $extreme->ex_stp_i_mac($partial);

    my %stp_i_mac;
    foreach my $iid ( keys %$stp_i_bids ) {
        my $mac = $stp_i_bids->{$iid};
        next unless $mac;

        $mac =~ s/^([0-9A-F][0-9A-F]:){2}//;

        $stp_i_mac{$iid} = $mac;
    }
    return \%stp_i_mac;
}

# Break up the extremeStpPortEntry INDEX into Stpd Instance and IfIndex.
sub _ex_stpport_index {
    my $idx    = shift;
    my ( $id, $ifindex ) = split( /\./, $idx);
    return ($id, $ifindex);
}

# extremeStpPortPortIfIndex not-accessible, extract from iid
sub stp_p_id {
    my $extreme  = shift;
    my $partial  = shift;

    my $stp_port = $extreme->stp_p_root($partial);
    my $stp_p_id  = {};
    foreach my $idx ( keys %$stp_port ) {
        my ( $id, $ifindex ) = _ex_stpport_index($idx);
        $stp_p_id->{$idx} = $ifindex;
    }
    return $stp_p_id;
}

# extremeStpDomainStpdInstance not-accessible, extract from iid
sub stp_p_stg_id {
    my $extreme  = shift;
    my $partial  = shift;

    my $stp_port = $extreme->stp_p_root($partial);
    my $stp_p_stg_id  = {};
    foreach my $idx ( keys %$stp_port ) {
        my ( $id, $ifindex ) = _ex_stpport_index($idx);
        $stp_p_stg_id->{$idx} = $id;
    }
    return $stp_p_stg_id;
}

# stp_p_state here is extremeStpPortTable, keyed <instance>.<ifIndex>, which
# matches no bp_index key, so read BRIDGE-MIB directly.
sub i_stp_state {
    my $extreme = shift;
    my $partial = shift;

    my $bp_index    = $extreme->bp_index($partial);
    my $stp_p_state = $extreme->dot1dStpPortState($partial);

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

# Keeps the base from reporting the default tree: on EXOS the domains are
# the trees, and VOSS serves forwarding on a blocked port under RSTP
sub _stp_default_is_common { return 0; }

# dot1dStpVersion: RSTP-MIB names 0 and 2 only, so 3 (MSTP) comes back bare
my %ex_stp_version = (
    0               => 'stp',
    'stpCompatible' => 'stp',
    2               => 'rstp',
    'rstp'          => 'rstp',
    3               => 'mstp',
);

sub _ex_stp_version {
    my $extreme = shift;

    my $version = $extreme->dot1dStpVersion();
    return unless defined $version;
    return $ex_stp_version{$version};
}

sub _ex_stp_pvst_instances {
    my $extreme = shift;

    my $modes = $extreme->ex_stp_p_mode() || {};
    my %pvst;
    foreach my $idx ( keys %$modes ) {
        next unless ( $modes->{$idx} || '' ) eq 'pvstp';
        my ($inst) = _ex_stpport_index($idx);
        $pvst{$inst} = 1;
    }
    return \%pvst;
}

sub hasMSTP {
    my $extreme = shift;
    return ( $extreme->_ex_stp_version() || '' ) eq 'mstp' ? 1 : 0;
}

sub hasRSTP {
    my $extreme = shift;
    return ( $extreme->_ex_stp_version() || '' ) eq 'rstp' ? 1 : 0;
}

sub hasPVST {
    my $extreme = shift;
    return keys %{ $extreme->_ex_stp_pvst_instances() } ? 1 : 0;
}

sub hasSTP {
    my $extreme = shift;

    return 0 unless ( $extreme->_ex_stp_version() || '' ) eq 'stp';
    my $names = $extreme->ex_stp_i_name() || {};
    my $pvst  = $extreme->_ex_stp_pvst_instances();
    return ( grep { !$pvst->{$_} } keys %$names ) ? 1 : 0;
}

sub stp_protocols {
    my $extreme = shift;

    my @protocols = grep {
        my $method = 'has' . uc $_;
        $extreme->$method();
    } qw/stp rstp mstp pvst/;
    return unless @protocols;
    return \@protocols;
}

sub stp_trees {
    my $extreme = shift;

    return unless $extreme->_stp_default_context_ok();
    return $extreme->{_stp_trees} if $extreme->{_stp_trees};

    my $names = $extreme->ex_stp_i_name() || {};
    return {} unless keys %$names;

    my $tags  = $extreme->ex_stp_i_tag()  || {};
    my $bids  = $extreme->ex_stp_i_mac()  || {};
    my $roots = $extreme->stp_i_root()    || {};
    my $pvst  = $extreme->_ex_stp_pvst_instances();
    my $version = $extreme->_ex_stp_version() || '';
    my $device_protocol
        = ( keys %$names == 1 and length $version ) ? $version : undef;
    my $measured = ( $extreme->os() || '' ) eq 'xos' ? 1 : 0;

    my %trees;
    foreach my $inst ( keys %$names ) {
        my $tree = {
            type           => 'domain',
            id             => $inst,
            name           => $names->{$inst},
            protocol       => $pvst->{$inst} ? 'pvst'
                : $version eq 'stp' ? 'stp'
                : $device_protocol,
            measured       => $measured,
            ports_complete => 1,
            contexts       => [ { kind => 'none' } ],
            bridge => scalar SNMP::Info::Bridge::_stp_decode_bridge_id(
                $bids->{$inst} ),
            root => scalar SNMP::Info::Bridge::_stp_decode_bridge_id(
                $roots->{$inst} ),
        };
        $tree->{vlan} = $tags->{$inst} if $tags->{$inst};
        $trees{"domain.$inst"} = $tree;
    }
    $extreme->{_stp_trees} = \%trees;
    return $extreme->{_stp_trees};
}

sub stp_tree_ports {
    my $extreme  = shift;
    my $tree_key = shift;

    my $trees = $extreme->stp_trees() || {};
    my $tree  = defined $tree_key ? $trees->{$tree_key} : undef;
    unless ($tree) {
        my $key = defined $tree_key ? $tree_key : 'undef';
        $extreme->error_throw(
            "SNMP::Info::Layer3::Extreme::stp_tree_ports() has no tree"
                . " '$key'. Pass a key from stp_trees(), read in the default"
                . " context.\n" );
        return;
    }

    my $states   = $extreme->stp_p_state()  || {};
    my $enable   = $extreme->stp_p_enable() || {};
    my $d_bridge = $extreme->stp_p_bridge() || {};
    my $d_port   = $extreme->stp_p_port()   || {};

    my %tree_ports;
    foreach my $idx ( keys %$states ) {
        my ( $inst, $ifindex ) = _ex_stpport_index($idx);
        next unless $inst eq $tree->{id};
        $tree_ports{$ifindex} = {
            tree_type         => $tree->{type},
            tree_id           => $tree->{id},
            state             => $states->{$idx},
            role              => undef,
            role_raw          => undef,
            enabled           =>
                scalar SNMP::Info::Bridge::_stp_enabled( $enable->{$idx} ),
            designated_bridge =>
                scalar SNMP::Info::Bridge::_stp_decode_bridge_id(
                $d_bridge->{$idx} ),
            designated_port => scalar SNMP::Info::Bridge::_stp_decode_port_id(
                $d_port->{$idx} ),
        };
    }
    return \%tree_ports;
}

sub stp_trees_complete {
    my $extreme = shift;

    my $trees = $extreme->stp_trees() || {};
    return 0 if $extreme->_stp_walk_incomplete('ex_stp_i_name');
    return keys %$trees ? 1 : 0;
}

# extremeStpVlanPortTable is indexed <vlan ifIndex>.<domain instance>
sub stp_vlan_map {
    my $extreme = shift;

    my $rows     = $extreme->ex_stp_vlan_mask() || {};
    my $vlan_ids = $extreme->ex_vlan_id()       || {};

    my %map;
    foreach my $idx ( keys %$rows ) {
        my ( $vlan_if, $inst ) = split /\./, $idx;
        my $vlan = $vlan_ids->{$vlan_if};
        next unless defined $vlan;
        $map{$vlan} = "domain.$inst";
    }
    return unless keys %map;
    return \%map;
}

# EXOS serves mplsL3VpnConfiguredVrfs 0 and no VRF row while VRs and VRFs
# are configured: they answer only as SNMPv3 contexts, so a zero from that
# MIB is no evidence of none
sub vrf_instances_complete {
    my $extreme = shift;

    my $complete = $extreme->SUPER::vrf_instances_complete(@_);
    return $complete unless $complete and ( $extreme->os() || '' ) eq 'xos';
    return;
}

sub _exos_vrf_context { return ( $_[0]->os() || '' ) eq 'xos' ? 1 : 0; }
sub _voss_vrf_context { return ( $_[0]->os() || '' ) eq 'voss' ? 1 : 0; }

sub _vrf_context_os {
    my $extreme = shift;

    return ( $extreme->_exos_vrf_context() or $extreme->_voss_vrf_context() )
        ? 1
        : 0;
}

# Each EXOS virtual router is an SNMPv3 context named like it; there is no
# v2c form. Each VOSS VRF is the context its rcVrfContextName names.
sub _context_kinds {
    my ( $extreme, $feature ) = @_;

    return
        unless ( $feature // '' ) eq 'vrf' and $extreme->_vrf_context_os();
    return ['vrf'];
}

sub _snmp_context {
    my ( $extreme, $kind, $id ) = @_;

    return unless ( $kind // '' ) eq 'vrf' and $extreme->_vrf_context_os();
    return if !defined $id or $id eq q() or $id eq 'default';
    return $extreme->_voss_snmp_context($id) if $extreme->_voss_vrf_context();
    return { kind => 'vrf', id => $id, v2c => undef, v3 => $id };
}

# VOSS reads a v2c community of the form community::vrfid in that VRF's
# context. vrfid 0, GlobalRouter, is the default context.
sub _voss_snmp_context {
    my ( $extreme, $id ) = @_;

    my $names    = $extreme->vrf_rc_name()    || {};
    my $contexts = $extreme->vrf_rc_context() || {};
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
sub _vrf_community_suffix_is_context {
    my $extreme = shift;

    return $extreme->_voss_vrf_context() ? 0 : 1;
}

# The context a VOSS VRF context's own rcVrfConfigTable row names. A VRF
# context serves only its own row; the default context serves every row,
# vrfid 0 (GlobalRouter, context '') among them. '' is the default context.
# Undef over SNMPv3 (its Context decides), on EXOS, which answers no v2c
# session, or when the table is not served. A VRF context whose one row
# names no context reads as "vrfid N", a context no instance has, so the
# readers refuse it instead of reading it as the default.
sub _vrf_community_context {
    my $extreme = shift;

    return unless $extreme->_voss_vrf_context();
    my $version = ( $extreme->session() || {} )->{Version};
    return if defined $version and $version eq '3';

    my $contexts = $extreme->vrf_rc_context();
    return unless $contexts and %$contexts;
    my @vrfids = sort keys %$contexts;
    return q() if @vrfids > 1 or grep { $_ eq '0' } @vrfids;
    my $context = SNMP::Info::VRF::_vrf_text( $contexts->{ $vrfids[0] } );
    return $context if defined $context and length $context;
    return "vrfid $vrfids[0]";
}

# Each virtual router reads in its own context, named for it. EXOS serves
# the same address table in every context and scopes only routes and
# neighbors, so the ports of a context are those its routes use. Each VOSS
# VRF context serves only its own VLANs, addresses, routes and neighbors;
# the default context maps every VRF's VLANs.
sub _vrf_context_filters           { return $_[0]->_vrf_context_os(); }
sub _vrf_context_is_instance_name  { return $_[0]->_exos_vrf_context(); }
sub _vrf_context_ports_from_routes { return $_[0]->_vrf_context_os(); }
sub _vrf_subnets_from_routes       { return $_[0]->_vrf_context_os(); }
sub _vrf_default_context_members   { return $_[0]->_voss_vrf_context(); }

# rcVrfConfigTable is indexed by vrfid. vrfid 0, GlobalRouter, is the
# instance default, which any row lists; the I-SID of an IP VPN is its
# layer 3 I-SID.
sub _vrf_vendor_instances {
    my $extreme = shift;

    return {} unless $extreme->_voss_vrf_context();
    my $names = $extreme->vrf_rc_name() || {};
    my $isids = $extreme->vrf_rc_isid() || {};
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
    $extreme->_vrf_list_default( \%instances, 'RAPID-CITY' ) if %$names;
    return \%instances;
}

sub _vrf_vendor_list_methods {
    my $extreme = shift;

    return unless $extreme->_voss_vrf_context();
    return qw/vrf_rc_name vrf_rc_context vrf_rc_isid vrf_rc_vlan_if
        vrf_rc_vlan_vrf vrf_rc_ip_vrf/;
}

# { ifIndex => name } of the VRFs other than default
sub _vrf_vendor_membership {
    my $extreme = shift;

    return {} unless $extreme->_voss_vrf_context();
    my $ports = $extreme->_voss_ports();
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
    my ( $extreme, $name ) = @_;

    my $names    = $extreme->_voss_column( 'vrf_rc_name',     $name );
    my $vlan_ifs = $extreme->_voss_column( 'vrf_rc_vlan_if',  $name );
    my $vlan_ids = $extreme->_voss_column( 'vrf_rc_vlan_vrf', $name );
    my $ip_ids   = $extreme->_voss_column( 'vrf_rc_ip_vrf',   $name );

    my %ports;
    foreach my $iid ( keys %$ip_ids ) {
        my ($ifindex) = $iid =~ /^(\d+)\./ or next;
        my $vrf = _voss_vrf_name( $names, $ip_ids->{$iid} );
        $ports{$ifindex} = $vrf if defined $vrf;
    }
    foreach my $vlan ( keys %$vlan_ids ) {
        my $vrf = _voss_vrf_name( $names, $vlan_ids->{$vlan} );
        $ports{ $vlan_ifs->{$vlan} } = $vrf
            if defined $vrf and defined $vlan_ifs->{$vlan};
    }
    return \%ports;
}

# A walk that counts toward the read of $name, or a plain one without
sub _voss_column {
    my ( $extreme, $method, $name ) = @_;

    return $extreme->_vrf_column( $method, $name ) if defined $name;
    return $extreme->$method() || {};
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
sub _voss_route_ports {
    my ( $extreme, $name ) = @_;

    my $mapped = $extreme->_voss_ports($name);
    my %ports  = map { $_ => $name } grep { $mapped->{$_} eq $name }
        keys %$mapped;
    my $ifs    = $extreme->_vrf_column( 'vrf_cidr_if',    $name );
    my $protos = $extreme->_vrf_column( 'vrf_cidr_proto', $name );
    foreach my $iid ( keys %$protos ) {
        next unless SNMP::Info::VRF::_vrf_connected_proto( $protos->{$iid} );
        my $ifindex = SNMP::Info::VRF::_vrf_route_ifindex( $ifs->{$iid} );
        $ports{$ifindex} = $name if defined $ifindex;
    }
    $ports{$_} = $name for $extreme->_voss_next_hop_ports($name);
    return \%ports;
}

# The default context's ipAddrTable places the management CLIP's address
# on the CLIP's ifIndex, while its local host route sits on the management
# VLAN's interface: the route's next hop is the address, so the CLIP is a
# port of the context. Other VRFs' addresses there have no such route.
sub _voss_next_hop_ports {
    my ( $extreme, $name ) = @_;

    my %hops = map { join( q{.}, @{ $_->{hop} } ) => 1 }
        grep { $_->{family} eq 'ipv4' }
        @{ $extreme->_voss_connected_routes($name) };
    my $rows = $extreme->_vrf_ipadent_rows($name);
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
    my ( $extreme, $name ) = @_;

    my $protos = $extreme->_vrf_column( 'vrf_cidr_proto', $name );
    my $ifs    = $extreme->_vrf_column( 'vrf_cidr_if',    $name );
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
    my ( $extreme, $name ) = @_;

    return $extreme->SUPER::_vrf_context_route_subnets($name)
        unless $extreme->_voss_vrf_context();
    my @subnets;
    foreach my $route ( @{ $extreme->_voss_connected_routes($name) } ) {
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
    push @subnets, @{ $extreme->_voss_standard_route_subnets($name) };
    return \@subnets;
}

# Connected routes in the standard index shape, which the VOSS parser
# rejects, read by the standard parser
sub _voss_standard_route_subnets {
    my ( $extreme, $name ) = @_;

    my $protos = $extreme->_vrf_column( 'vrf_cidr_proto', $name );
    my $ifs    = $extreme->_vrf_column( 'vrf_cidr_if',    $name );
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
    my ( $extreme, $name ) = @_;

    return {} unless $extreme->_voss_vrf_context();
    return {
        %{ $extreme->_voss_rc_ip_addresses($name) },
        %{ $extreme->_vrf_ipv6_mib_address_rows($name) },
    };
}

# rcIpAddrTable is indexed by ifIndex then address, so an address two VRFs
# share on their own VLANs is two rows
sub _voss_rc_ip_addresses {
    my ( $extreme, $name ) = @_;

    my $names = $extreme->_vrf_column( 'vrf_rc_name',    $name );
    my $vrfs  = $extreme->_vrf_column( 'vrf_rc_ip_vrf',  $name );
    my $ips   = $extreme->_vrf_column( 'vrf_rc_ip_addr', $name );
    my $masks = $extreme->_vrf_column( 'vrf_rc_ip_mask', $name );
    my %rows;
    foreach my $iid ( keys %$ips ) {
        my ($ifindex) = $iid =~ /^(\d+)\./ or next;
        my $vrf = _voss_vrf_name( $names, $vrfs->{$iid} );
        next unless defined $vrf and $vrf eq $name;
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

# EXOS puts a VLAN's IPv4 routes on its router interface, ifName
# "<vlan> rtif(<address>)", and the VLAN's addresses on the interface named
# "<vlan>", so a router interface adds its VLAN's. EXOS forbids two VLANs of
# one name. ifName decides membership, so it counts toward the read.
sub _vrf_route_ports {
    my ( $extreme, $name ) = @_;

    return $extreme->_voss_route_ports($name)
        if $extreme->_voss_vrf_context();
    my $ports = $extreme->SUPER::_vrf_route_ports($name);
    return $ports unless $extreme->_exos_vrf_context();

    my $if_names = $extreme->_vrf_column( 'orig_i_name', $name, 'i_name' );
    my %port_named
        = map { $if_names->{$_} => $_ } sort { $a <=> $b } keys %$if_names;
    foreach my $port ( keys %$ports ) {
        my ($vlan) = ( $if_names->{$port} // q{} ) =~ /^(.+) rtif\(/
            or next;
        $ports->{ $port_named{$vlan} } = $name if exists $port_named{$vlan};
    }
    return $ports;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer3::Extreme - Perl5 Interface to Extreme Network Devices

=head1 AUTHOR

Eric Miller, Bill Fenner

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $extreme = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $extreme->class();

 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from an
Extreme device through SNMP.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::MAU

=item SNMP::Info::EDP

=back

=head2 Required MIBs

=over

=item F<EXTREME-BASE-MIB>

=item F<EXTREME-SYSTEM-MIB>

=item F<EXTREME-FDB-MIB>

=item F<EXTREME-VLAN-MIB>

=item F<EXTREME-POE-MIB>

=item F<EXTREME-STP-EXTENSIONS-MIB>

=item F<RAPID-CITY>

=item F<EXTREME-PORT-MIB>

=item F<EXTREME-MLAG-MIB>

=item Inherited Classes' MIBs

See classes listed above for their required MIBs.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $extreme->model()

Returns model type.  Checks $extreme->id() against the F<EXTREME-BASE-MIB>.

=item $extreme->vendor()

Returns C<extreme>

=item $extreme->os()

Returns C<xos>, C<voss> (VOSS / Fabric Engine) or C<extremeware>
depending on description()

=item $extreme->os_ver()

Parses device operating system version from description()

=item $extreme->serial()

Returns serial number

(C<extremeSystemID>)

=item $extreme->temp()

Returns system temperature

(C<extremeCurrentTemperature>)

=item $extreme->ps1_status()

Returns status of power supply 1

(C<extremePowerSupplyStatus.1>)

=item $extreme->ps2_status()

Returns status of power supply 2

(C<extremePowerSupplyStatus.2>)

=item $extreme->fan()

Returns fan status

(C<extremeFanOperational.1>)

=item $extreme->mac()

Returns base mac

(C<dot1dBaseBridgeAddress>)

=item $extreme->hasMSTP()

Returns 1 when the device runs MSTP: C<dot1dStpVersion> is 3.

=item $extreme->hasRSTP()

Returns 1 when the device runs 802.1W: C<dot1dStpVersion> is 2.

=item $extreme->hasPVST()

Returns 1 when any domain's ports run in PVST+ mode
(C<extremeStpPortPortMode> C<pvstp>).

=item $extreme->hasSTP()

Returns 1 when C<dot1dStpVersion> is 0 and a domain has no port in PVST+
mode.  A device with one such domain and one PVST+ domain answers 1 to
both C<hasSTP()> and C<hasPVST()>.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::EDP

See documentation in L<SNMP::Info::EDP/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $extreme->interfaces()

Returns a mapping between the Interface Table Index (iid) and the physical
port name.

=item $extreme->i_duplex()

Parses mau_index and mau_link to return the duplex information for
interfaces.

=item $extreme->i_duplex_admin()

Parses C<mac_index>,C<mau_autostat>,C<mau_type_admin> in
order to find the admin duplex setting for all the interfaces.

Returns either (auto,full,half).

=item $extreme->i_ignore()

Returns reference to hash.  Increments value of IID if port is to be ignored.

Ignores VLAN meta interfaces and loopback

=item $extreme->fw_mac()

(C<extremeFdbMacFdbMacAddress>)

=item $extreme->fw_port()

(C<extremeFdbMacFdbPortIfIndex>)

=item $extreme->fw_status()

(C<extremeFdbMacFdbStatus>)

=item $extreme->lldp_if()

Returns the mapping to the SNMP Interface Table. Extreme LLDP uses the
bridge index rather than ifIndex.

=item $extreme->i_stp_state()

Returns reference to hash.  Key: C<ifIndex>, Value: the port state in the
device's default spanning tree, from C<dot1dStpPortState> mapped through
C<bp_index>.  Returns an empty hash when the device serves no
C<BRIDGE-MIB> STP port table, as VOSS does under MSTP; the vendor
C<extremeStpPortTable> is not used, since it is keyed by STP domain.
Under RSTP, VOSS serves forwarding for a port its CLI shows blocked.

(C<dot1dStpPortState>)

=item $extreme->i_vlan()

Returns a mapping between C<ifIndex> and the VLAN.

=item $extreme->i_vlan_membership()

Returns reference to hash of arrays: key = C<ifIndex>, value = array of VLAN
IDs.  These are the VLANs which are members of the egress list for the port.

  Example:
  my $interfaces = $extreme->interfaces();
  my $vlans      = $extreme->i_vlan_membership();

  foreach my $iid (sort keys %$interfaces) {
    my $port = $interfaces->{$iid};
    my $vlan = join(',', sort(@{$vlans->{$iid}}));
    print "Port: $port VLAN: $vlan\n";
  }

=item $extreme->i_vlan_membership_untagged()

Returns reference to hash of arrays: key = C<ifIndex>, value = array of VLAN
IDs.  These are the VLANs which are members of the untagged egress list for
the port.

=item $extreme->v_index()

Returns VLAN IDs from C<extremeVlanIfTable>, or from C<Q-BRIDGE-MIB> when
that table is empty.

=item $extreme->v_name()

Returns VLAN names from C<extremeVlanIfDescr>, or C<dot1qVlanStaticName>
when C<extremeVlanIfTable> is empty.

(C<extremeVlanIfDescr>)

=item $extreme->bp_index()

Returns reference to hash of bridge port table entries map back to interface
identifier (iid)

Returns (C<ifIndex>) for both key and value since we're using
F<EXTREME-FDB-MIB> rather than F<BRIDGE-MIB>.

=item $extreme->vrf_instances_complete( [ \@names ] )

On ExtremeXOS, returns undef where L<SNMP::Info::VRF> would return 1.
EXOS serves C<mplsL3VpnConfiguredVrfs> as 0 even with virtual routers
configured, since they answer only as SNMPv3 contexts. So the list is
never known to be whole. A caller name still returns 0.

=item $extreme->context_kinds($feature)

Returns C<['vrf']> for C<vrf> on ExtremeXOS, where each virtual router
answers in its own SNMPv3 context, and on VOSS, where each VRF does.
Returns nothing otherwise, and nothing on ExtremeWare. See
C<context_kinds()> in L<SNMP::Info>.

=item $extreme->snmp_context($kind, $id)

Returns nothing for kinds other than C<vrf>. See
C<snmp_context()> in L<SNMP::Info>.

On ExtremeXOS, for a virtual router name returns C<< { kind =E<gt>
'vrf', id =E<gt> $name, v2c =E<gt> undef, v3 =E<gt> $name } >>. The
default virtual router is the default context, so C<default> and an
empty name get nothing.

On VOSS, for a name C<vrf_instances()> lists returns C<< { kind =E<gt>
'vrf', id =E<gt> $name, v2c =E<gt> '%s::$vrfid', v3 =E<gt> $context } >>.
C<$vrfid> is the VRF's C<rcVrfConfigTable> index. For vrfid 1,
C<public> becomes C<public::1>. C<$context> is the VRF's
C<rcVrfContextName>, such as C<vrf1>. C<default>, which is
C<GlobalRouter>, and a name the device does not list get nothing.

On ExtremeXOS C<v2c> is undef. The ExtremeXOS user guide documents an
SNMPv2c read community of the form C<vr_name@community_name> for a user
virtual router. That form is unverified, so it is not offered as C<v2c>.
If you can confirm it on a device, please open an issue with a walk.
SNMPv3 with the virtual router name as the context is verified; use it.

A VOSS SNMPv2c community with an C<@> suffix (C<public@vrf1>) is served
from the default context, so the VRF readers do not take the suffix as
the session's context. A VOSS session on a C<community::vrfid> community
reads as that VRF: a VRF context serves only its own C<rcVrfConfigTable>
row, and the VRF readers take the context from that row. The default
context serves every row, so a session there reads as the default
context.

=item $extreme->peth_port_power()

Power supplied by PoE ports, in milliwatts

(C<extremePethPortMeasuredPower>)

=item $extreme->peth_power_watts()

The configured maximum amount of in-line power available to the slot.

(C<extremePethSlotPowerLimit>)

=back

=head2 VRF Instances

See L<SNMP::Info::VRF/"VRF Instances"> for the readers. Both ExtremeXOS
and VOSS use context mode.

=head3 ExtremeXOS

=over

=item *

On ExtremeXOS 33.6 the virtual routers answer only as SNMPv3 contexts,
and the device serves no list of them: C<mplsL3VpnConfiguredVrfs> is 0
and C<MPLS-L3VPN-STD-MIB> has no row. Pass the names with
C<vrf_instances(\@names)>. Each reads in the context of its name.

=item *

The address table is the same in every context. So the ports of a
context are the interfaces of its C<inetCidrRouteTable> routes, and its
addresses, neighbors and subnets are those on them.

=item *

EXOS puts a VLAN's IPv4 routes on its router interface, whose C<ifName>
is C<< <vlan> rtif(<address>) >>, and the VLAN's addresses on the
interface named C<< <vlan> >>. A router interface therefore also makes
its VLAN's interface a port of the context.

=item *

The default context works the same way, for the default virtual router.

=item *

A subnet two virtual routers share is read from each one's connected
route.

=item *

A name the device lacks has no route, so it reads no port, address or
neighbor.

=back

=head3 VOSS: instances and ports

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

=head3 VOSS: addresses, routes and neighbors

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

=head2 VOSS VRF Tables (F<RAPID-CITY>)

=over

=item $extreme->vrf_rc_name()

Returns reference to hash of VRF names, keyed by vrfid.

(C<rcVrfName>)

=item $extreme->vrf_rc_context()

Returns reference to hash of the SNMP context name of each VRF, keyed
by vrfid.

(C<rcVrfContextName>)

=item $extreme->vrf_rc_isid()

Returns reference to hash of the I-SID of each VRF's IP VPN, keyed by
vrfid.

(C<rcVrfIpVpnIsidNumber>)

=item $extreme->vrf_rc_vlan_if()

Returns reference to hash of the ifIndex of each VLAN, keyed by VLAN id.

(C<rcVlanIfIndex>)

=item $extreme->vrf_rc_vlan_vrf()

Returns reference to hash of the vrfid of each VLAN, keyed by VLAN id.

(C<rcVlanVrfId>)

=item $extreme->vrf_rc_ip_vrf()

Returns reference to hash of the vrfid of each address, keyed by
ifIndex then address.

(C<rcIpAdEntVrfId>)

=item $extreme->vrf_rc_ip_addr()

Returns reference to hash of addresses, keyed by ifIndex then address.

(C<rcIpAdEntAddr>)

=item $extreme->vrf_rc_ip_mask()

Returns reference to hash of address masks, keyed by ifIndex then
address.

(C<rcIpAdEntNetMask>)

=back

=head2 Spanning Tree Instance Globals

=over

=item $extreme->stp_i_mac()

Returns the MAC extracted from (C<extremeStpDomainBridgeId>).

=item $extreme->stp_i_id()

Returns the unique identifier of the STP domain.

(C<extremeStpDomainStpdInstance>)

=item $extreme->stp_i_time()

Returns time since last topology change detected. (100ths/second)

(C<extremeStpDomainTimeSinceTopologyChange>)

=item $extreme->stp_i_time()

Returns time since last topology change detected. (100ths/second)

(C<extremeStpDomainTimeSinceTopologyChange>)

=item $extreme->stp_i_time()

Returns the total number of topology changes detected.

(C<extremeStpDomainTopChanges>)

=item $extreme->stp_i_root()

Returns root of STP.

(C<extremeStpDomainDesignatedRoot>)

=item $extreme->stp_i_root_port()

Returns the port number of the port that offers the lowest cost path
to the root bridge.

(C<extremeStpDomainRootPortIfIndex>)

=item $extreme->stp_i_priority()

Returns the port number of the port that offers the lowest cost path
to the root bridge.

(C<extremeStpDomainBridgePriority>)

=back

=head2 Spanning Tree Protocol Port Table

=over

=item $extreme->stp_p_id()

(C<extremeStpPortPortIfIndex>)

=item $extreme->stp_p_stg_id()

(C<extremeStpDomainStpdInstance>)

=item $extreme->stp_p_priority()

(C<extremeStpPortPortPriority>)

=item $extreme->stp_p_state()

(C<extremeStpPortPortState>)

=item $extreme->stp_p_enable()

(C<extremeStpPortStpEnabled>)

=item $extreme->stp_p_cost()

(C<extremeStpPortPathCost>)

=item $extreme->stp_p_root()

(C<extremeStpPortDesignatedRoot>)

=item $extreme->stp_p_bridge()

(C<extremeStpPortDesignatedBridge>)

=item $extreme->stp_p_port()

(C<extremeStpPortDesignatedPort>)

=back

=head2 Spanning Tree Trees

EXOS runs one spanning tree per STP domain, served in the default
context.  These override L<SNMP::Info::Bridge/"Spanning Tree Trees">,
where the records are described.  VOSS, also handled by this class,
serves none of these tables.

The tree records:

=over

=item Keys

C<domain.N> for each domain, N its C<extremeStpDomainStpdInstance>.

=item C<name>

The domain name, C<extremeStpDomainStpdName>.

=item C<vlan>

The domain's carrier VLAN, C<extremeStpDomainStpdTag>, when it is not
0.

=item C<protocol>

C<dot1dStpVersion> is device-wide, so a domain's protocol is:

=over

=item *

C<pvst> when a port of the domain runs in PVST+ mode
(C<extremeStpPortPortMode> C<pvstp>);

=item *

else C<stp> when C<dot1dStpVersion> is 0;

=item *

else the protocol C<dot1dStpVersion> names, when the device has one
domain;

=item *

else undef.

=back

=item C<measured>

1 on EXOS, 0 otherwise.

=item C<ports_complete>

1.

=item C<contexts>

The default context.

=item C<bridge>, C<root>

C<extremeStpDomainBridgeId> and C<extremeStpDomainDesignatedRoot>.

=back

The port records come from C<extremeStpPortTable>: C<state>
(C<extremeStpPortPortState>), C<enabled> (C<extremeStpPortStpEnabled>),
C<designated_bridge> and C<designated_port>.  C<role> and C<role_raw>
are undef: the MIB serves none.

=over

=item $extreme->stp_protocols()

Returns reference to an array of the protocols C<hasSTP()>, C<hasRSTP()>,
C<hasMSTP()> and C<hasPVST()> report, or nothing.

=item $extreme->stp_trees()

Returns reference to hash of domain records keyed
C<domain.E<lt>instanceE<gt>>.

=item $extreme->stp_tree_ports($tree_key)

Returns reference to hash of the domain's port records keyed by ifIndex,
from (C<extremeStpPortTable>).

=item $extreme->stp_trees_complete()

Returns 1 or 0, as L<SNMP::Info::Bridge/"Spanning Tree Trees">
describes.  0 when the device serves no domain, or the
C<extremeStpDomainStpdName> walk was incomplete.

=item $extreme->stp_vlan_map()

Returns reference to hash mapping VLAN id to domain key, from the index of
(C<extremeStpVlanPortTable>) and (C<extremeVlanIfVlanId>).

=item $extreme->ex_stp_i_name()

(C<extremeStpDomainStpdName>)

=item $extreme->ex_stp_i_tag()

(C<extremeStpDomainStpdTag>)

=item $extreme->ex_stp_p_mode()

(C<extremeStpPortPortMode>)

=item $extreme->ex_stp_vlan_mask()

(C<extremeStpVlanPortPortMask>)

=back

=head2 Link Aggregation

=over

=item $extreme->agg_ports()

Returns a reference to a hash mapping each member port ifIndex to the
ifIndex of its load sharing master, from C<extremePortLoadshare2Table>.
The table lists the master as a member of itself; that row is left out.
Returns an empty hash when the device serves no load sharing rows.

=item $extreme->lag_groups()

As described in L<SNMP::Info::IEEE802dot3ad/"METHODS">, keyed by the load
sharing master port, with:

=over

=item *

The master port is a member of its own aggregate.

=item *

An aggregate whose master or member is an MLAG port
(C<extremeMlagPortTable>) gets C<mc>: C<kind> C<mlag>, C<group> the MLAG
port id (C<extremeMlagPortId>), C<domain> the peer name
(C<extremeMlagPortPeer>), and C<state> the local link status
(C<extremeMlagPortLocalLinkStatus>).

=item *

An MLAG port whose load sharing group has only its master is an
aggregate of its own, keyed by that master, with the port as its member.

=item *

An MLAG port with no load sharing row is an aggregate of its own, keyed
by the port, with the port as its member.

=back

=item $extreme->mlag_domains()

As described in L<SNMP::Info::IEEE802dot3ad/"METHODS">, keyed by MLAG
peer name (C<extremeMlagPeerTable>), with C<kind> C<mlag> and these
fields:

=over

=item *

C<system_mac>: the operational LACP MAC, C<extremeMlagPeerOperLacpMac>.

=item *

C<peer>: the peer address, C<extremeMlagPeerIP>, served as an address or
as text.

=item *

C<status>: the checkpoint status, C<extremeMlagPeerCheckPointStatus>.

=back

=item $extreme->ex_loadshare()

(C<extremePortLoadshare2Status>)

=item $extreme->ex_mlag_peer_ip()

(C<extremeMlagPeerIP>)

=item $extreme->ex_mlag_peer_status()

(C<extremeMlagPeerCheckPointStatus>)

=item $extreme->ex_mlag_peer_lacp_mac()

(C<extremeMlagPeerOperLacpMac>)

=item $extreme->ex_mlag_port_id()

(C<extremeMlagPortId>)

=item $extreme->ex_mlag_port_peer()

(C<extremeMlagPortPeer>)

=item $extreme->ex_mlag_port_state()

(C<extremeMlagPortLocalLinkStatus>)

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::EDP

See documentation in L<SNMP::Info::EDP/"TABLE METHODS"> for details.

=head1 SET METHODS

These are methods that provide SNMP set functionality for overridden methods
or provide a simpler interface to complex set operations.  See
L<SNMP::Info/"SETTING DATA VIA SNMP"> for general information on set
operations.

ExtremeWare is configured through C<ifStackTable> and
C<extremeVlanEncapsIfTable>. ExtremeXOS has neither table, so when
C<extremeVlanEncapsIfTable> is empty these methods use C<dot1qPvid> and
C<dot1qVlanStaticEgressPorts> from C<Q-BRIDGE-MIB> instead.

=over

=item $extreme->set_i_vlan ( vlan, ifIndex )

Changes an access (untagged) port VLAN, must be supplied with the numeric
VLAN ID and port C<ifIndex>.  This method should only be used on end station
(non-trunk) ports.  Through C<Q-BRIDGE-MIB>, a VLAN already tagged on the
port is removed from its egress list first.

  Example:
  my %if_map = reverse %{$extreme->interfaces()};
  $extreme->set_i_vlan('2', $if_map{'FastEthernet0/1'})
    or die "Couldn't change port VLAN. ",$extreme->error(1);

=item $extreme->set_i_pvid ( pvid, ifIndex )

Sets port default VLAN, must be supplied with the numeric VLAN ID and
port C<ifIndex>.  This method should only be used on trunk ports.  Through
C<Q-BRIDGE-MIB>, a VLAN tagged on the port is refused; use C<set_i_vlan>.

  Example:
  my %if_map = reverse %{$extreme->interfaces()};
  $extreme->set_i_pvid('2', $if_map{'FastEthernet0/1'})
    or die "Couldn't change port default VLAN. ",$extreme->error(1);

=item $extreme->set_add_i_vlan_tagged ( vlan, ifIndex )

Adds the VLAN to the enabled VLANs list of the port, must be supplied with the
numeric VLAN ID and port C<ifIndex>.

  Example:
  my %if_map = reverse %{$extreme->interfaces()};
  $extreme->set_add_i_vlan_tagged('2', $if_map{'FastEthernet0/1'})
    or die "Couldn't add port to egress list. ",$extreme->error(1);

=item $extreme->set_remove_i_vlan_tagged ( vlan, ifIndex )

Removes the VLAN from the enabled VLANs list of the port, must be supplied
with the numeric VLAN ID and port C<ifIndex>.

  Example:
  my %if_map = reverse %{$extreme->interfaces()};
  $extreme->set_remove_i_vlan_tagged('2', $if_map{'FastEthernet0/1'})
    or die "Couldn't add port to egress list. ",$extreme->error(1);

=back

=head1 Data Munging Callback Subroutines

=over

=item $extreme->munge_power_stat()

Removes 'present' and changes 'not' to 'Not' in the front of a string.

=item $extreme->munge_true_ok()

Replaces 'true' with "OK" and 'false' with "Not OK".

=back

=cut
