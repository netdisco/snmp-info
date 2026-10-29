# SNMP::Info::RapidCity
#
# Copyright (c) 2014 Eric Miller
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

package SNMP::Info::RapidCity;

use strict;
use warnings;
use Exporter;
use SNMP::Info;

@SNMP::Info::RapidCity::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::RapidCity::EXPORT_OK = qw//;

our ($VERSION, %FUNCS, %GLOBALS, %MIBS, %MUNGE);

$VERSION = '3.983000';

%MIBS = (
    'RAPID-CITY' => 'rapidCity',
    # These are distinct from RAPID-CITY but are potentially used by
    # classes which inherit the RAPID-CITY class
    'NORTEL-NETWORKS-RAPID-SPANNING-TREE-MIB'    => 'nnRstDot1dStpVersion',
    'NORTEL-NETWORKS-MULTIPLE-SPANNING-TREE-MIB' => 'nnMstBrgAddress',
);

%GLOBALS = (
    'rc_serial'    => 'rcChasSerialNumber',
    'chassis'      => 'rcChasType',
    'slots'        => 'rcChasNumSlots',
    'tftp_host'    => 'rcTftpHost',
    'tftp_file'    => 'rcTftpFile',
    'tftp_action'  => 'rcTftpAction',
    'tftp_result'  => 'rcTftpResult',
    'rc_ch_rev'    => 'rcChasHardwareRevision',
    'rc_base_mac'  => 'rc2kChassisBaseMacAddr',
    'rc_virt_ip'   => 'rcSysVirtualIpAddr',
    'rc_virt_mask' => 'rcSysVirtualNetMask',

    # NORTEL-NETWORKS-MULTIPLE-SPANNING-TREE-MIB
    'nn_mst_version'       => 'nnMstForceProtocolVersion',
    'nn_mst_brg_address'   => 'nnMstBrgAddress',
    'nn_mst_cist_root'     => 'nnMstCistRoot',
    'nn_mst_cist_priority' => 'nnMstCistBridgePriority',

    # NORTEL-NETWORKS-RAPID-SPANNING-TREE-MIB
    'nn_rst_version' => 'nnRstDot1dStpVersion',
);

%FUNCS = (

    # From RAPID-CITY::rcPortTable
    'rc_index'        => 'rcPortIndex',
    'rc_duplex'       => 'rcPortOperDuplex',
    'rc_duplex_admin' => 'rcPortAdminDuplex',
    'rc_speed_admin'  => 'rcPortAdminSpeed',
    'rc_auto'         => 'rcPortAutoNegotiate',
    'rc_alias'        => 'rcPortName',

    # From RAPID-CITY::rc2kCpuEthernetPortTable
    'rc_cpu_ifindex'      => 'rc2kCpuEthernetPortIfIndex',
    'rc_cpu_admin'        => 'rc2kCpuEthernetPortAdminStatus',
    'rc_cpu_oper'         => 'rc2kCpuEthernetPortOperStatus',
    'rc_cpu_ip'           => 'rc2kCpuEthernetPortAddr',
    'rc_cpu_mask'         => 'rc2kCpuEthernetPortMask',
    'rc_cpu_auto'         => 'rc2kCpuEthernetPortAutoNegotiate',
    'rc_cpu_duplex_admin' => 'rc2kCpuEthernetPortAdminDuplex',
    'rc_cpu_duplex'       => 'rc2kCpuEthernetPortOperDuplex',
    'rc_cpu_speed_admin'  => 'rc2kCpuEthernetPortAdminSpeed',
    'rc_cpu_speed_oper'   => 'rc2kCpuEthernetPortOperSpeed',
    'rc_cpu_mac'          => 'rc2kCpuEthernetPortMgmtMacAddr',

    # From RAPID-CITY::rcVlanPortTable
    'rc_i_vlan_if'   => 'rcVlanPortIndex',
    'rc_i_vlan_num'  => 'rcVlanPortNumVlanIds',
    'rc_i_vlan'      => 'rcVlanPortVlanIds',
    'rc_i_vlan_type' => 'rcVlanPortType',
    'rc_i_vlan_pvid' => 'rcVlanPortDefaultVlanId',
    'rc_i_vlan_tag'  => 'rcVlanPortPerformTagging',

    # From RAPID-CITY::rcVlanTable
    'rc_vlan_id'      => 'rcVlanId',
    'v_name'          => 'rcVlanName',
    'rc_vlan_color'   => 'rcVlanColor',
    'rc_vlan_if'      => 'rcVlanIfIndex',
    'rc_vlan_stg'     => 'rcVlanStgId',
    'rc_vlan_type'    => 'rcVlanType',
    'rc_vlan_members' => 'rcVlanPortMembers',
    'rc_vlan_no_join' => 'rcVlanNotAllowToJoin',
    'rc_vlan_mac'     => 'rcVlanMacAddress',
    'rc_vlan_rstatus' => 'rcVlanRowStatus',

    # From RAPID-CITY::rcIpAddrTable
    'rc_ip_index' => 'rcIpAdEntIfIndex',
    'rc_ip_addr'  => 'rcIpAdEntAddr',
    'rc_ip_type'  => 'rcIpAdEntIfType',

    # From RAPID-CITY::rcChasFanTable
    'rc_fan_op' => 'rcChasFanOperStatus',

    # From RAPID-CITY::rcChasPowerSupplyTable
    'rc_ps_op' => 'rcChasPowerSupplyOperStatus',

    # From RAPID-CITY::rcChasPowerSupplyDetailTable
    'rc_ps_type'   => 'rcChasPowerSupplyDetailType',
    'rc_ps_serial' => 'rcChasPowerSupplyDetailSerialNumber',
    'rc_ps_rev'    => 'rcChasPowerSupplyDetailHardwareRevision',
    'rc_ps_part'   => 'rcChasPowerSupplyDetailPartNumber',
    'rc_ps_detail' => 'rcChasPowerSupplyDetailDescription',

    # From RAPID-CITY::rcCardTable
    'rc_c_type'   => 'rcCardType',
    'rc_c_serial' => 'rcCardSerialNumber',
    'rc_c_rev'    => 'rcCardHardwareRevision',
    'rc_c_part'   => 'rcCardPartNumber',

    # From RAPID-CITY::rc2kCardTable
    'rc2k_c_ftype'   => 'rc2kCardFrontType',
    'rc2k_c_fdesc'   => 'rc2kCardFrontDescription',
    'rc2k_c_fserial' => 'rc2kCardFrontSerialNum',
    'rc2k_c_frev'    => 'rc2kCardFrontHwVersion',
    'rc2k_c_fpart'   => 'rc2kCardFrontPartNumber',
    'rc2k_c_fdate'   => 'rc2kCardFrontDateCode',
    'rc2k_c_fdev'    => 'rc2kCardFrontDeviations',
    'rc2k_c_btype'   => 'rc2kCardBackType',
    'rc2k_c_bdesc'   => 'rc2kCardBackDescription',
    'rc2k_c_bserial' => 'rc2kCardBackSerialNum',
    'rc2k_c_brev'    => 'rc2kCardBackHwVersion',
    'rc2k_c_bpart'   => 'rc2kCardBackPartNumber',
    'rc2k_c_bdate'   => 'rc2kCardBackDateCode',
    'rc2k_c_bdev'    => 'rc2kCardBackDeviations',

    # From RAPID-CITY::rc2kMdaCardTable
    'rc2k_mda_type'   => 'rc2kMdaCardType',
    'rc2k_mda_desc'   => 'rc2kMdaCardDescription',
    'rc2k_mda_serial' => 'rc2kMdaCardSerialNum',
    'rc2k_mda_rev'    => 'rc2kMdaCardHwVersion',
    'rc2k_mda_part'   => 'rc2kMdaCardPartNumber',
    'rc2k_mda_date'   => 'rc2kMdaCardDateCode',
    'rc2k_mda_dev'    => 'rc2kMdaCardDeviations',

    # From RAPID-CITY::rcMltTable
    'rc_mlt_ports'    => 'rcMltPortMembers',
    'rc_mlt_index'    => 'rcMltIfIndex',
    'rc_mlt_dp'       => 'rcMltDesignatedPort',

    # From RAPID-CITY::rcBridgeSpbmMacTable
    'rc_spbm_fw_port'   => 'rcBridgeSpbmMacCPort',
    'rc_spbm_fw_status' => 'rcBridgeSpbmMacStatus',
    'rc_spbm_fw_vlan'   => 'rcBridgeSpbmMacCVlanId',

    # From RAPID-CITY::rcStgTable
    'stp_i_id'           => 'rcStgId',
    'rc_stp_i_mac'       => 'rcStgBridgeAddress',
    'rc_stp_i_time'      => 'rcStgTimeSinceTopologyChange',
    'rc_stp_i_ntop'      => 'rcStgTopChanges',
    'rc_stp_i_root'      => 'rcStgDesignatedRoot',
    'rc_stp_i_root_port' => 'rcStgRootPort',
    'rc_stp_i_priority'  => 'rcStgPriority',

    # From RAPID-CITY::rcStgPortTable
    'rc_stp_p_id'       => 'rcStgPort',
    'stp_p_stg_id'      => 'rcStgPortStgId',
    'rc_stp_p_priority' => 'rcStgPortPriority',
    'rc_stp_p_state'    => 'rcStgPortState',
    'rc_stp_p_cost'     => 'rcStgPortPathCost',
    'rc_stp_p_root'     => 'rcStgPortDesignatedRoot',
    'rc_stp_p_bridge'   => 'rcStgPortDesignatedBridge',
    'rc_stp_p_port'     => 'rcStgPortDesignatedPort',
    'rc_stp_p_enable'   => 'rcStgPortEnableStp',

    # From RAPID-CITY::rcStgTable, indexed by STG id
    'rc_stg_enable' => 'rcStgEnableStp',

    # NORTEL-NETWORKS-MULTIPLE-SPANNING-TREE-MIB, indexed by instance
    'nn_msti_priority' => 'nnMstBridgePriority',
    'nn_msti_root'     => 'nnMstBridgeRegionalRoot',

    # NORTEL-NETWORKS-MULTIPLE-SPANNING-TREE-MIB, indexed by bridge port
    'nn_cist_p_state'  => 'nnMstCistPortState',
    'nn_cist_p_role'   => 'nnMstCistCurrentPortRole',
    'nn_cist_p_bridge' => 'nnMstCistPortDesignatedBridge',
    'nn_cist_p_port'   => 'nnMstCistPortDesignatedPort',
    'nn_cist_p_enable' => 'nnMstCistForcePortState',

    # NORTEL-NETWORKS-MULTIPLE-SPANNING-TREE-MIB admin edge, by bridge port
    'nn_cist_p_edge_admin' => 'nnMstCistPortAdminEdgeStatus',

    # NORTEL-NETWORKS-MULTIPLE-SPANNING-TREE-MIB oper edge, by bridge port
    'nn_cist_p_edge_oper' => 'nnMstCistPortOperEdgeStatus',

    # NORTEL-NETWORKS-MULTIPLE-SPANNING-TREE-MIB, indexed <port>.<instance>
    'nn_msti_p_state'  => 'nnMstPortState',
    'nn_msti_p_role'   => 'nnMstPortCurrentPortRole',
    'nn_msti_p_bridge' => 'nnMstPortDesignatedBridge',
    'nn_msti_p_port'   => 'nnMstPortDesignatedPort',
    'nn_msti_p_enable' => 'nnMstPortForcePortState',

    # NORTEL-NETWORKS-RAPID-SPANNING-TREE-MIB, indexed by bridge port
    'nn_rst_p_state' => 'nnRstDot1wPortStateTransSmState',
    'nn_rst_p_role'  => 'nnRstDot1wPortRole',

    # NORTEL-NETWORKS-RAPID-SPANNING-TREE-MIB admin edge, by bridge port
    'nn_rst_p_edge_admin' => 'nnRstDot1dStpPortAdminEdgePort',

    # NORTEL-NETWORKS-RAPID-SPANNING-TREE-MIB oper edge, by bridge port
    'nn_rst_p_edge_oper' => 'nnRstDot1dStpPortOperEdgePort',

    # BRIDGE-MIB beside nnRst; stp_p_* prefer rcStgPortTable
    'rc_dot1d_p_bridge' => 'dot1dStpPortDesignatedBridge',
    'rc_dot1d_p_port'   => 'dot1dStpPortDesignatedPort',
    'rc_dot1d_p_enable' => 'dot1dStpPortEnable',
);

%MUNGE = (
    'rc_base_mac'     => \&SNMP::Info::munge_mac,
    'rc_vlan_mac'     => \&SNMP::Info::munge_mac,
    'rc_cpu_mac'      => \&SNMP::Info::munge_mac,
    'rc_vlan_members' => \&SNMP::Info::munge_port_list,
    'rc_vlan_no_join' => \&SNMP::Info::munge_port_list,
    'rc_mlt_ports'    => \&SNMP::Info::munge_port_list,
    'rc_stp_i_mac'       => \&SNMP::Info::munge_mac,
    'rc_stp_i_root'      => \&SNMP::Info::munge_prio_mac,
    'rc_stp_p_root'      => \&SNMP::Info::munge_prio_mac,
    'rc_stp_p_bridge'    => \&SNMP::Info::munge_prio_mac,
    'rc_stp_p_port'      => \&SNMP::Info::munge_prio_port,
    'nn_mst_brg_address'   => \&SNMP::Info::munge_mac,
    'nn_mst_cist_root'     => \&SNMP::Info::munge_prio_mac,
    'nn_msti_root'         => \&SNMP::Info::munge_prio_mac,
    'nn_cist_p_bridge'     => \&SNMP::Info::munge_prio_mac,
    'nn_msti_p_bridge'     => \&SNMP::Info::munge_prio_mac,
    'rc_dot1d_p_bridge'    => \&SNMP::Info::munge_prio_mac,
    'nn_cist_p_port'       => \&SNMP::Info::munge_prio_port,
    'nn_msti_p_port'       => \&SNMP::Info::munge_prio_port,
    'rc_dot1d_p_port'      => \&SNMP::Info::munge_prio_port,
    'nn_cist_p_role'       => \&SNMP::Info::munge_dot1s_port_role,
    'nn_msti_p_role'       => \&SNMP::Info::munge_dot1s_port_role,
    'nn_rst_p_role'        => \&SNMP::Info::munge_dot1w_port_role,
);

# Need to override here since overridden in Layer2 and Layer3 classes
sub serial {
    my $rapidcity = shift;

    my $ver = $rapidcity->rc_serial();
    return $ver unless !defined $ver;

    return;
}

sub i_duplex {
    my $rapidcity = shift;
    my $partial   = shift;

    my $rc_duplex     = $rapidcity->rc_duplex($partial)     || {};
    my $rc_cpu_duplex = $rapidcity->rc_cpu_duplex($partial) || {};

    my %i_duplex;
    foreach my $if ( keys %$rc_duplex ) {
        my $duplex = $rc_duplex->{$if};
        next unless defined $duplex;

        $duplex = 'half' if $duplex =~ /half/i;
        $duplex = 'full' if $duplex =~ /full/i;
        $i_duplex{$if} = $duplex;
    }

    # Get CPU Ethernet Interfaces for 8600 Series
    foreach my $iid ( keys %$rc_cpu_duplex ) {
        my $c_duplex = $rc_cpu_duplex->{$iid};
        next unless defined $c_duplex;

        $i_duplex{$iid} = $c_duplex;
    }

    return \%i_duplex;
}

sub i_duplex_admin {
    my $rapidcity = shift;
    my $partial   = shift;

    my $rc_duplex_admin     = $rapidcity->rc_duplex_admin()             || {};
    my $rc_auto             = $rapidcity->rc_auto($partial)             || {};
    my $rc_cpu_auto         = $rapidcity->rc_cpu_auto($partial)         || {};
    my $rc_cpu_duplex_admin = $rapidcity->rc_cpu_duplex_admin($partial) || {};

    my %i_duplex_admin;
    foreach my $if ( keys %$rc_duplex_admin ) {
        my $duplex = $rc_duplex_admin->{$if};
        next unless defined $duplex;
        my $auto = $rc_auto->{$if} || 'false';

        my $string = 'other';
        $string = 'half' if ( $duplex =~ /half/i and $auto =~ /false/i );
        $string = 'full' if ( $duplex =~ /full/i and $auto =~ /false/i );
        $string = 'auto' if $auto =~ /true/i;

        $i_duplex_admin{$if} = $string;
    }

    # Get CPU Ethernet Interfaces for 8600 Series
    foreach my $iid ( keys %$rc_cpu_duplex_admin ) {
        my $c_duplex = $rc_cpu_duplex_admin->{$iid};
        next unless defined $c_duplex;
        my $c_auto = $rc_cpu_auto->{$iid};

        my $string = 'other';
        $string = 'half' if ( $c_duplex =~ /half/i and $c_auto =~ /false/i );
        $string = 'full' if ( $c_duplex =~ /full/i and $c_auto =~ /false/i );
        $string = 'auto' if $c_auto =~ /true/i;

        $i_duplex_admin{$iid} = $string;
    }

    return \%i_duplex_admin;
}

sub set_i_duplex_admin {
    my $rapidcity = shift;
    my ( $duplex, $iid ) = @_;

    $duplex = lc($duplex);
    return unless ( $duplex =~ /(half|full|auto)/ and $iid =~ /\d+/ );

    # map a textual duplex to an integer one the switch understands
    my %duplexes = qw/full 2 half 1/;
    my $i_auto   = $rapidcity->rc_auto($iid);

    if ( $duplex eq "auto" ) {
        return $rapidcity->set_rc_auto( '1', $iid );
    }
    elsif ( ( $duplex ne "auto" ) and ( $i_auto->{$iid} eq "1" ) ) {
        return unless ( $rapidcity->set_rc_auto( '2', $iid ) );
        return $rapidcity->set_rc_duplex_admin( $duplexes{$duplex}, $iid );
    }
    else {
        return $rapidcity->set_rc_duplex_admin( $duplexes{$duplex}, $iid );
    }
}

sub set_i_speed_admin {
    my $rapidcity = shift;
    my ( $speed, $iid ) = @_;

    return unless ( $speed =~ /(10|100|1000|auto)/i and $iid =~ /\d+/ );

    # map a textual duplex to an integer one the switch understands
    my %speeds = qw/10 1 100 2 1000 3/;
    my $i_auto = $rapidcity->rc_auto($iid);

    if ( $speed eq "auto" ) {
        return $rapidcity->set_rc_auto( '1', $iid );
    }
    elsif ( ( $speed ne "auto" ) and ( $i_auto->{$iid} eq "1" ) ) {
        return unless ( $rapidcity->set_rc_auto( '2', $iid ) );
        return $rapidcity->set_rc_speed_admin( $speeds{$speed}, $iid );
    }
    else {
        return $rapidcity->set_rc_speed_admin( $speeds{$speed}, $iid );
    }
}

sub v_index {
    my $rapidcity = shift;
    my $partial   = shift;

    return $rapidcity->rc_vlan_id($partial);
}

sub i_vlan {
    my $rapidcity = shift;
    my $partial   = shift;

    my $i_pvid = $rapidcity->rc_i_vlan_pvid($partial) || {};

    return $i_pvid;
}

sub i_vlan_membership {
    my $rapidcity = shift;

    my $rc_v_ports = $rapidcity->rc_vlan_members();

    my $i_vlan_membership = {};
    foreach my $vlan ( keys %$rc_v_ports ) {
        my $portlist = $rc_v_ports->{$vlan};
        my $ret      = [];

        # Convert portlist bit array to ifIndex array
        for ( my $i = 0; $i <= scalar(@$portlist); $i++ ) {
            push( @{$ret}, $i ) if ( @$portlist[$i] );
        }

        #Create HoA ifIndex -> VLAN array
        foreach my $port ( @{$ret} ) {
            push( @{ $i_vlan_membership->{$port} }, $vlan );
        }
    }
    return $i_vlan_membership;
}

sub i_vlan_membership_untagged {
    my $rapidcity = shift;

    # Traditionally access ports have one VLAN untagged and trunk ports have
    # one or more VLANs all tagged
    # Newer VOSS device trunks have PerformTagging true or false and also can
    # UntagDefaultVlan
    # Newer BOSS device trunks have four PerformTagging options true, false,
    # tagPvidOnly, and untagPvidOnly

    my $p_members = $rapidcity->i_vlan_membership();
    my $i_vlan = $rapidcity->i_vlan();
    my $p_tag_opt = $rapidcity->rcVlanPortPerformTagging() || {};
    my $p_untag_def = $rapidcity->rcVlanPortUntagDefaultVlan() || {};
    my $p_type = $rapidcity->rcVlanPortType() || {};

    my $members_untagged = {};
    foreach my $port ( keys %$p_type ) {
        my $type = $p_type->{$port};
        next unless $type;

        # Easiest case first access ports
        if ($type eq 'access') {
            # Access ports should only have one VLAN and it should be
            # untagged
            $members_untagged->{$port} = $p_members->{$port};
        }
        else {
            # If PerformTagging has a value do all checks otherwise we're
            # just a trunk and everything is tagged
            if ($p_tag_opt->{$port}) {
                if ($p_tag_opt->{$port} eq 'untagPvidOnly') {
                    my $vlan = $i_vlan->{$port};
                    push( @{ $members_untagged->{$port} }, $vlan );
                }
                elsif (($p_tag_opt->{$port} eq 'true') and
                       ($p_untag_def->{$port} and $p_untag_def->{$port} eq 'true'))
                {
                    my $vlan = $i_vlan->{$port};
                    push( @{ $members_untagged->{$port} }, $vlan );
                }
                elsif ($p_tag_opt->{$port} eq 'tagPvidOnly') {
                    my $vlan = $i_vlan->{$port};
                    my @arr = $p_members->{$port};
                    my $index = 0;
                    my $count = scalar @arr;
                    $index++ until $arr[$index] eq $vlan or $index==$count;
                    splice(@arr, $index, 1);
                    $members_untagged->{$port} = @arr;
                }
                # Don't know if this is a legal configuration, but included
                # for completeness
                elsif ($p_tag_opt->{$port} eq 'false') {
                    $members_untagged->{$port} = $p_members->{$port};
                }
                else {
                    next;
                }
            }
        }
    }

    return $members_untagged;
}

sub set_i_pvid {
    my $rapidcity = shift;
    my ( $vlan_id, $ifindex ) = @_;

    return unless ( $rapidcity->_validate_vlan_param( $vlan_id, $ifindex ) );

    unless ( $rapidcity->set_rc_i_vlan_pvid( $vlan_id, $ifindex ) ) {
        $rapidcity->error_throw(
            "Unable to change PVID to $vlan_id on IfIndex: $ifindex");
        return;
    }
    return 1;
}

sub set_i_vlan {
    my $rapidcity = shift;
    my ( $new_vlan_id, $ifindex ) = @_;

    return
        unless ( $rapidcity->_validate_vlan_param( $new_vlan_id, $ifindex ) );

    my $vlan_p_type = $rapidcity->rc_i_vlan_type($ifindex);
    unless ( $vlan_p_type->{$ifindex} =~ /access/ ) {
        $rapidcity->error_throw("Not an access port");
        return;
    }

    my $i_pvid = $rapidcity->rc_i_vlan_pvid($ifindex);

    # Store current untagged VLAN to remove it from the port list later
    my $old_vlan_id = $i_pvid->{$ifindex};

    # Check that haven't been given the same VLAN we are currently using
    if ( $old_vlan_id eq $new_vlan_id ) {
        $rapidcity->error_throw(
            "Current PVID: $old_vlan_id and New VLAN: $new_vlan_id the same, no change."
        );
        return;
    }

    print "Changing VLAN: $old_vlan_id to $new_vlan_id on IfIndex: $ifindex\n"
        if $rapidcity->debug();

    # Check if port in forbidden list for the VLAN, haven't seen this used,
    # but we'll check anyway
    return
        unless (
        $rapidcity->_check_forbidden_ports( $new_vlan_id, $ifindex ) );

    my $old_vlan_members = $rapidcity->rc_vlan_members($old_vlan_id);
    my $new_vlan_members = $rapidcity->rc_vlan_members($new_vlan_id);

    print "Modifying egress list for VLAN: $new_vlan_id \n"
        if $rapidcity->debug();
    my $new_egress
        = $rapidcity->modify_port_list( $new_vlan_members->{$new_vlan_id},
        $ifindex, '1' );

    print "Modifying egress list for VLAN: $old_vlan_id \n"
        if $rapidcity->debug();
    my $old_egress
        = $rapidcity->modify_port_list( $old_vlan_members->{$old_vlan_id},
        $ifindex, '0' );

    my $vlan_set = [
        [ 'rc_vlan_members', "$new_vlan_id", "$new_egress" ],

        #        ['rc_vlan_members',"$old_vlan_id","$old_egress"],
    ];

    return
        unless ( $rapidcity->set_multi($vlan_set) );

    my $vlan_set2 = [ [ 'rc_vlan_members', "$old_vlan_id", "$old_egress" ], ];

    return
        unless ( $rapidcity->set_multi($vlan_set2) );

 # Set new untagged / native VLAN
 # Some models/versions do this for us also, so check to see if we need to set
    $i_pvid = $rapidcity->rc_i_vlan_pvid($ifindex);

    my $cur_i_pvid = $i_pvid->{$ifindex};
    print "Current PVID: $cur_i_pvid\n" if $rapidcity->debug();
    unless ( $cur_i_pvid eq $new_vlan_id ) {
        return unless ( $rapidcity->set_i_pvid( $new_vlan_id, $ifindex ) );
    }

    print
        "Successfully changed VLAN: $old_vlan_id to $new_vlan_id on IfIndex: $ifindex\n"
        if $rapidcity->debug();
    return 1;
}

sub set_add_i_vlan_tagged {
    my $rapidcity = shift;
    my ( $vlan_id, $ifindex ) = @_;

    return unless ( $rapidcity->_validate_vlan_param( $vlan_id, $ifindex ) );

    print "Adding VLAN: $vlan_id to IfIndex: $ifindex\n"
        if $rapidcity->debug();

# Check if port in forbidden list for the VLAN, haven't seen this used, but we'll check anyway
    return
        unless ( $rapidcity->_check_forbidden_ports( $vlan_id, $ifindex ) );

    my $iv_members = $rapidcity->rc_vlan_members($vlan_id);

    print "Modifying egress list for VLAN: $vlan_id \n"
        if $rapidcity->debug();
    my $new_egress
        = $rapidcity->modify_port_list( $iv_members->{$vlan_id}, $ifindex,
        '1' );

    unless ( $rapidcity->set_qb_v_egress( $new_egress, $vlan_id ) ) {
        print
            "Error: Unable to add VLAN: $vlan_id to Index: $ifindex egress list.\n"
            if $rapidcity->debug();
        return;
    }

    print
        "Successfully added IfIndex: $ifindex to VLAN: $vlan_id egress list\n"
        if $rapidcity->debug();
    return 1;
}

sub set_remove_i_vlan_tagged {
    my $rapidcity = shift;
    my ( $vlan_id, $ifindex ) = @_;

    return unless ( $rapidcity->_validate_vlan_param( $vlan_id, $ifindex ) );

    print "Removing VLAN: $vlan_id from IfIndex: $ifindex\n"
        if $rapidcity->debug();

    my $iv_members = $rapidcity->rc_vlan_members($vlan_id);

    print "Modifying egress list for VLAN: $vlan_id \n"
        if $rapidcity->debug();
    my $new_egress
        = $rapidcity->modify_port_list( $iv_members->{$vlan_id}, $ifindex,
        '0' );

    unless ( $rapidcity->set_qb_v_egress( $new_egress, $vlan_id ) ) {
        print
            "Error: Unable to add VLAN: $vlan_id to Index: $ifindex egress list.\n"
            if $rapidcity->debug();
        return;
    }

    print
        "Successfully removed IfIndex: $ifindex from VLAN: $vlan_id egress list\n"
        if $rapidcity->debug();
    return 1;
}

sub set_create_vlan {
    my $rapidcity = shift;
    my ( $name, $vlan_id ) = @_;
    return unless ( $vlan_id =~ /\d+/ );

    my $vlan_set = [
        [ 'v_name',          "$vlan_id", "$name" ],
        [ 'rc_vlan_rstatus', "$vlan_id", 4 ],
    ];

    unless ( $rapidcity->set_multi($vlan_set) ) {
        print "Error: Unable to create VLAN: $vlan_id\n"
            if $rapidcity->debug();
        return;
    }

    return 1;
}

sub set_delete_vlan {
    my $rapidcity = shift;
    my ($vlan_id) = shift;
    return unless ( $vlan_id =~ /^\d+$/ );

    unless ( $rapidcity->set_rc_vlan_rstatus( '6', $vlan_id ) ) {
        $rapidcity->error_throw("Unable to delete VLAN: $vlan_id");
        return;
    }
    return 1;
}

#
# These are internal methods and are not documented.  Do not use directly.
#
sub _check_forbidden_ports {
    my $rapidcity = shift;
    my ( $vlan_id, $ifindex ) = @_;

    my $iv_forbidden = $rapidcity->rc_vlan_no_join($vlan_id);

    my @forbidden_ports
        = split( //, unpack( "B*", $iv_forbidden->{$vlan_id} ) );
    print "Forbidden ports: @forbidden_ports\n" if $rapidcity->debug();
    if ( defined( $forbidden_ports[$ifindex] )
        and ( $forbidden_ports[$ifindex] eq "1" ) )
    {
        $rapidcity->error_throw(
            "IfIndex: $ifindex in forbidden list for VLAN: $vlan_id unable to add"
        );
        return;
    }
    return 1;
}

sub _validate_vlan_param {
    my $rapidcity = shift;
    my ( $vlan_id, $ifindex ) = @_;

    # VID and ifIndex should both be numeric
    unless (defined $vlan_id
        and defined $ifindex
        and $vlan_id =~ /^\d+$/
        and $ifindex =~ /^\d+$/ )
    {
        $rapidcity->error_throw("Invalid parameter");
        return;
    }

    # Check that ifIndex exists on device
    my $index = $rapidcity->interfaces($ifindex);

    unless ( exists $index->{$ifindex} ) {
        $rapidcity->error_throw("ifIndex $ifindex does not exist");
        return;
    }

    #Check that VLAN exists on device
    unless ( $rapidcity->rc_vlan_id($vlan_id) ) {
        $rapidcity->error_throw(
            "VLAN $vlan_id does not exist or is not operational");
        return;
    }

    return 1;
}

sub agg_ports {
    my $rapidcity = shift;

    # TODO: implement partial
    my $ports  = $rapidcity->rc_mlt_ports;
    my $trunks = $rapidcity->rc_mlt_index;
    my $dps    = $rapidcity->rc_mlt_dp || {};

    return {}
        unless ref {} eq ref $trunks
            and scalar keys %$trunks
            and ref {} eq ref $ports
            and scalar keys %$ports;

    my $ret = {};
    foreach my $m ( keys %$trunks ) {
        my $idx = $trunks->{$m};
        next unless $idx;
        $idx = $dps->{$m} ? $dps->{$m} : $idx;
        my $portlist = $ports->{$m};
        next unless $portlist;
        for ( my $i = 0; $i <= scalar(@$portlist); $i++ ) {
            $ret->{$i} = $idx if ( @$portlist[$i] );
        }
    }

    return $ret;
}

# break up the rcBridgeSpbmMacEntry INDEX into ISID and MAC Address.
sub _spbm_fdbtable_index {
    my $idx    = shift;
    my @values = split( /\./, $idx );
    my $isid = shift(@values);
    return ( $isid, join( ':', map { sprintf "%02x", $_ } @values ) );
}

sub rc_spbm_fw_mac {
    my $rapidcity  = shift;
    my $partial = shift;

    my $spbm_fw_ports = $rapidcity->rc_spbm_fw_port($partial);
    my $spbm_fw_mac  = {};
    foreach my $idx ( keys %$spbm_fw_ports ) {
        my ( $isid, $mac ) = _spbm_fdbtable_index($idx);
        $spbm_fw_mac->{$idx} = $mac;
    }
    return $spbm_fw_mac;
}

sub rc_spbm_fw_isid {
    my $rapidcity  = shift;
    my $partial = shift;

    my $spbm_fw_ports = $rapidcity->rc_spbm_fw_port($partial);
    my $spbm_fw_isid  = {};
    foreach my $idx ( keys %$spbm_fw_ports ) {
        my ( $isid, $mac ) = _spbm_fdbtable_index($idx);
        $spbm_fw_isid->{$idx} = $isid;
    }
    return $spbm_fw_isid;
}

sub stp_ver {
    my $rapidcity = shift;

    return $rapidcity->rcSysSpanningTreeOperMode()
      || $rapidcity->SUPER::stp_ver();
}

# RSTP and ieee8021d operating modes do not populate RAPID-CITY::rcStgTable
# or RAPID-CITY::rcStgPortTable but do populate BRIDGE-MIB so check both
sub stp_i_mac {
    my $rapidcity = shift;

    return $rapidcity->rc_stp_i_mac()
      || $rapidcity->SUPER::stp_i_mac();
}

sub stp_i_time {
    my $rapidcity = shift;

    return $rapidcity->rc_stp_i_time()
      || $rapidcity->SUPER::stp_i_time();
}

sub stp_i_ntop {
    my $rapidcity = shift;

    return $rapidcity->rc_stp_i_ntop()
      || $rapidcity->SUPER::stp_i_ntop();
}

sub stp_i_root {
    my $rapidcity = shift;

    return $rapidcity->rc_stp_i_root()
      || $rapidcity->SUPER::stp_i_root();
}

sub stp_i_root_port {
    my $rapidcity = shift;

    return $rapidcity->rc_stp_i_root_port()
      || $rapidcity->SUPER::stp_i_root_port();
}

sub stp_i_priority {
    my $rapidcity = shift;

    return $rapidcity->rc_stp_i_priority()
      || $rapidcity->SUPER::stp_i_priority();
}

sub stp_p_id {
    my $rapidcity = shift;

    return $rapidcity->rc_stp_p_id()
      || $rapidcity->SUPER::stp_p_id();
}

sub stp_p_priority {
    my $rapidcity = shift;

    return $rapidcity->rc_stp_p_priority()
      || $rapidcity->SUPER::stp_p_priority();
}

sub stp_p_state {
    my $rapidcity = shift;

    return $rapidcity->rc_stp_p_state()
      || $rapidcity->SUPER::stp_p_state();
}

sub stp_p_cost {
    my $rapidcity = shift;

    return $rapidcity->rc_stp_p_cost()
      || $rapidcity->SUPER::stp_p_cost();
}

sub stp_p_root {
    my $rapidcity = shift;

    return $rapidcity->rc_stp_p_root()
      || $rapidcity->SUPER::stp_p_root();
}

sub stp_p_bridge {
    my $rapidcity = shift;

    return $rapidcity->rc_stp_p_bridge()
      || $rapidcity->SUPER::stp_p_bridge();
}

sub stp_p_port {
    my $rapidcity = shift;

    return $rapidcity->rc_stp_p_port()
      || $rapidcity->SUPER::stp_p_port();
}

sub mst_vlan2instance {
    my $rapidcity = shift;
    my $partial   = shift;

    return $rapidcity->rcVlanStgId($partial);
}

sub i_bpduguard_enabled {
    my $rapidcity    = shift;
    my $partial = shift;

    return $rapidcity->rcPortBpduFilteringOperEnabled();
}

sub i_edgeport_admin {
    my $rapidcity = shift;
    my $partial   = shift;

    # The role's @ISA is SNMP::Info, so SUPER:: would not reach Bridge
    my $edge_admin = $rapidcity->_rc_edge('admin');
    return SNMP::Info::Bridge::i_edgeport_admin( $rapidcity, $partial )
        unless $edge_admin;
    return SNMP::Info::Bridge::_stp_edge_by_ifindex( $rapidcity,
        $edge_admin, $partial );
}

sub i_edgeport_oper {
    my $rapidcity = shift;
    my $partial   = shift;

    my $edge_oper = $rapidcity->_rc_edge('oper');
    return SNMP::Info::Bridge::i_edgeport_oper( $rapidcity, $partial )
        unless $edge_oper;
    return SNMP::Info::Bridge::_stp_edge_by_ifindex( $rapidcity,
        $edge_oper, $partial );
}

# Admin or oper ($kind) edge by bridge port from the running protocol's
# table: nnMst CIST under MSTP, nnRst under RSTP.  Under MSTP the nnMst rows
# are the per-port truth even where nnRst lists more ports.
sub _rc_edge {
    my $rapidcity = shift;
    my $kind      = shift;

    my %table_for = (
        mstp => "nn_cist_p_edge_$kind",
        rstp => "nn_rst_p_edge_$kind",
    );
    my $method = $table_for{ $rapidcity->_rc_stp_protocol() || '' }
        or return;
    my $edge = $rapidcity->$method() || {};
    return keys %$edge ? $edge : undef;
}

sub i_stp_state {
    my $rapidcity = shift;
    my $partial   = shift;

    my $bp_index    = $rapidcity->bp_index($partial);
    my $stp_p_state = $rapidcity->dot1dStpPortState($partial);

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

# Spanning tree protocol from nnMstForceProtocolVersion and
# nnRstDot1dStpVersion, which mean the same across the family's generations
# where rcStgProtocolSpecification does not.
# rcSysSpanningTreeOperMode nortelStpg and pvst are not read: those modes
# predate 802.1w and 802.1s, and few devices still run them.
sub _rc_stp_protocol {
    my $rapidcity = shift;

    my $mst_version = $rapidcity->nn_mst_version();
    return 'mstp' if defined $mst_version and $mst_version =~ /^(?:mstp|3)$/;

    my $rst_version = $rapidcity->nn_rst_version();
    return unless defined $rst_version;
    return 'rstp' if $rst_version =~ /^(?:rstp|2)$/;
    return 'stp'  if $rst_version =~ /^(?:stpCompatible|0)$/;
    return;
}

sub _rc_stp_measured { return 0; }

sub hasSTP {
    my $rapidcity = shift;
    return ( $rapidcity->_rc_stp_protocol() || '' ) eq 'stp' ? 1 : 0;
}

sub hasRSTP {
    my $rapidcity = shift;
    return ( $rapidcity->_rc_stp_protocol() || '' ) eq 'rstp' ? 1 : 0;
}

sub hasMSTP {
    my $rapidcity = shift;
    return ( $rapidcity->_rc_stp_protocol() || '' ) eq 'mstp' ? 1 : 0;
}

sub stp_protocols {
    my $rapidcity = shift;

    my $protocol = $rapidcity->_rc_stp_protocol();
    return [$protocol] if defined $protocol;
    return;
}

# An STG with STP disabled, such as the SPBM B-VLAN tree, is no tree
sub _rc_stg_running {
    my ( $rapidcity, $stg ) = @_;

    my $enable = ( $rapidcity->rc_stg_enable() || {} )->{$stg};
    return 1 unless defined $enable;
    return $enable =~ /^(?:false|2)$/ ? 0 : 1;
}

sub stp_trees {
    my $rapidcity = shift;

    return unless $rapidcity->_stp_default_context_ok();
    return $rapidcity->{_stp_trees} if $rapidcity->{_stp_trees};

    my $protocol = $rapidcity->_rc_stp_protocol();
    my $trees = {};
    if ( defined $protocol ) {
        $trees
            = $protocol eq 'mstp'
            ? $rapidcity->_rc_mstp_trees()
            : $rapidcity->_rc_rstp_trees($protocol);
    }
    $rapidcity->{_stp_trees} = $trees if keys %$trees;
    return $trees;
}

sub _rc_tree_key {
    my $instance = shift;
    return $instance ? "msti.$instance" : 'cist.0';
}

sub _rc_tree_record {
    my ( $rapidcity, $protocol, $instance, $fields ) = @_;

    return {
        type     => $instance ? 'msti' : 'cist',
        id       => $instance,
        protocol => $protocol,
        measured => $rapidcity->_rc_stp_measured($protocol),
        contexts => [ { kind => 'none' } ],
        %$fields,
    };
}

# Instances with a port row at a bridge port that bp_index does not map
sub _rc_unmapped_instances {
    my $rapidcity = shift;

    my $bp_index = $rapidcity->bp_index() || {};
    my %unmapped;
    foreach my $port ( keys %{ $rapidcity->nn_cist_p_state() || {} } ) {
        $unmapped{0} = 1 unless defined $bp_index->{$port};
    }
    foreach my $row ( keys %{ $rapidcity->nn_msti_p_state() || {} } ) {
        my ( $port, $instance ) = split /\./, $row, 2;
        $unmapped{$instance} = 1 unless defined $bp_index->{$port};
    }
    return \%unmapped;
}

sub _rc_mstp_trees {
    my $rapidcity = shift;

    my $address    = $rapidcity->nn_mst_brg_address();
    my $priorities = $rapidcity->nn_msti_priority() || {};
    my $roots      = $rapidcity->nn_msti_root() || {};
    my $unmapped   = $rapidcity->_rc_unmapped_instances();

    my %instances = ( 0 => [
        $rapidcity->nn_mst_cist_priority(), $rapidcity->nn_mst_cist_root()
    ] );
    foreach my $instance ( keys %$priorities ) {
        next unless $rapidcity->_rc_stg_running( $instance + 1 );
        $instances{$instance}
            = [ $priorities->{$instance}, $roots->{$instance} ];
    }

    my %trees;
    foreach my $instance ( keys %instances ) {
        my ( $priority, $root ) = @{ $instances{$instance} };
        my $bridge = SNMP::Info::Bridge::_stp_bridge_id_from( $priority,
            $address );
        my $root_id = SNMP::Info::Bridge::_stp_decode_bridge_id($root);
        $trees{ _rc_tree_key($instance) } = $rapidcity->_rc_tree_record(
            'mstp', $instance,
            {   ports_complete => $unmapped->{$instance} ? 0 : 1,
                bridge         => $bridge,
                root           => $root_id,
            }
        );
    }
    return \%trees;
}

# VOSS serves no dot1dStp scalar under RSTP, so the bridge and root come from
# the first STG's rcStg row
sub _rc_rstp_trees {
    my ( $rapidcity, $protocol ) = @_;

    my $states   = $rapidcity->nn_rst_p_state() || {};
    my $bp_index = $rapidcity->bp_index() || {};
    my $complete = keys %$states ? 1 : 0;
    $complete = 0 if grep { !defined $bp_index->{$_} } keys %$states;

    my $priority = ( $rapidcity->rc_stp_i_priority() || {} )->{1};
    my $mac      = ( $rapidcity->rc_stp_i_mac()      || {} )->{1};
    my $root     = ( $rapidcity->rc_stp_i_root()     || {} )->{1};
    my $bridge  = SNMP::Info::Bridge::_stp_bridge_id_from( $priority, $mac );
    my $root_id = SNMP::Info::Bridge::_stp_decode_bridge_id($root);
    return {
        'cist.0' => $rapidcity->_rc_tree_record(
            $protocol, 0,
            {   ports_complete => $complete,
                bridge         => $bridge,
                root           => $root_id,
            }
        )
    };
}

sub stp_tree_ports {
    my ( $rapidcity, $tree_key ) = @_;

    my $tree = $rapidcity->_stp_tree_for_key($tree_key) or return;
    return $rapidcity->_rc_mstp_port_rows($tree)
        if ( $tree->{protocol} || '' ) eq 'mstp';
    return $rapidcity->_rc_rstp_port_rows($tree);
}

# Under MSTP the per-port enable is the nnMst ForcePortState of the tree, as
# rcStgPortEnableStp is 1 on every port and dot1dStpPortEnable is inert there;
# a port without a row is unknown, not a fallback to either.  The enum has
# disabled(0), which _stp_enabled would read as unknown.
sub _rc_mstp_port_enabled {
    my ( $rapidcity, $port, $instance ) = @_;

    my $value;
    if ( $instance == 0 ) {
        $value = ( $rapidcity->nn_cist_p_enable() || {} )->{$port};
    }
    else {
        $value
            = ( $rapidcity->nn_msti_p_enable() || {} )->{"$port.$instance"};
    }
    return unless defined $value;

    return 0 if $value =~ /^(?:disabled|0)$/;
    return scalar SNMP::Info::Bridge::_stp_enabled($value);
}

# Under RSTP and STP, rcStgPortEnableStp is indexed <ifIndex>.<STG id>, and
# a tree's STG is its instance plus one; the BRIDGE-MIB enable, indexed by
# bridge port, is the fallback
sub _rc_port_enabled {
    my ( $rapidcity, $tree, $port, $iid ) = @_;

    return $rapidcity->_rc_mstp_port_enabled( $port, $tree->{id} )
        if ( $tree->{protocol} || '' ) eq 'mstp';

    my $stg_row    = $iid . '.' . ( $tree->{id} + 1 );
    my $stg_enable = ( $rapidcity->rc_stp_p_enable() || {} )->{$stg_row};
    $stg_enable = ( $rapidcity->rc_dot1d_p_enable() || {} )->{$port}
        unless defined $stg_enable;
    return scalar SNMP::Info::Bridge::_stp_enabled($stg_enable);
}

sub _rc_port_row {
    my ( $rapidcity, $tree, $port, $iid, $served, $key ) = @_;

    return {
        tree_type => $tree->{type},
        tree_id   => $tree->{id},
        state     => $served->{state}{$key},
        role      => $served->{role}{$key},
        role_raw  => $served->{role_raw}{$key},
        enabled =>
            scalar $rapidcity->_rc_port_enabled( $tree, $port, $iid ),
        designated_bridge =>
            scalar SNMP::Info::Bridge::_stp_decode_bridge_id(
            $served->{bridge}{$key} ),
        designated_port => scalar SNMP::Info::Bridge::_stp_decode_port_id(
            $served->{port}{$key} ),
    };
}

sub _rc_mstp_port_rows {
    my ( $rapidcity, $tree ) = @_;

    my $cist   = $tree->{id} == 0;
    my $prefix = $cist ? 'nn_cist_p_' : 'nn_msti_p_';
    my %served;
    foreach my $column (qw/state role role_raw bridge port/) {
        my $method = $prefix . $column;
        $served{$column} = $rapidcity->$method() || {};
    }
    my $bp_index = $rapidcity->bp_index() || {};

    my %rows;
    foreach my $key ( keys %{ $served{state} } ) {
        my ( $port, $instance ) = split /\./, $key, 2;
        next if !$cist and $instance != $tree->{id};

        my $iid = $bp_index->{$port};
        next unless defined $iid;
        $rows{$iid}
            = $rapidcity->_rc_port_row( $tree, $port, $iid, \%served, $key );
    }
    return \%rows;
}

# The BRIDGE-MIB and rcStg port states serve forwarding on a blocked port, so
# the state is nnRstDot1wPortStateTransSmState only
sub _rc_rstp_port_rows {
    my ( $rapidcity, $tree ) = @_;

    my %served = (
        state    => $rapidcity->nn_rst_p_state()      || {},
        role     => $rapidcity->nn_rst_p_role()       || {},
        role_raw => $rapidcity->nn_rst_p_role_raw()   || {},
        bridge   => $rapidcity->rc_dot1d_p_bridge()   || {},
        port     => $rapidcity->rc_dot1d_p_port()     || {},
    );
    my $bp_index = $rapidcity->bp_index() || {};

    my %rows;
    foreach my $port ( keys %{ $served{state} } ) {
        my $iid = $bp_index->{$port};
        next unless defined $iid;
        $rows{$iid}
            = $rapidcity->_rc_port_row( $tree, $port, $iid, \%served, $port );
    }
    return \%rows;
}

sub stp_trees_complete {
    my $rapidcity = shift;

    return 0 unless defined $rapidcity->_rc_stp_protocol();
    my $trees = $rapidcity->stp_trees() || {};
    return keys %$trees ? 1 : 0;
}

sub stp_vlan_map {
    my $rapidcity = shift;

    return unless ( $rapidcity->_rc_stp_protocol() || '' ) eq 'mstp';

    my $vlan_stg = $rapidcity->rc_vlan_stg() || {};
    my %map;
    foreach my $vlan ( keys %$vlan_stg ) {
        my $stg = $vlan_stg->{$vlan};
        next unless $rapidcity->_rc_stg_running($stg);
        $map{$vlan} = _rc_tree_key( $stg - 1 );
    }
    return unless keys %map;
    return \%map;
}

# Default tree is not the common tree: VOSS serves forwarding on a blocked
# port under RSTP
sub _stp_default_is_common { return 0; }

1;

__END__

=head1 NAME

SNMP::Info::RapidCity - SNMP Interface to the Avaya/Nortel RapidCity MIB

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $rapidcity = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $rapidcity->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

SNMP::Info::RapidCity is a subclass of SNMP::Info that provides an interface
to the C<RAPID-CITY> MIB.  This MIB is used across the Avaya/Nortel Ethernet
Routing Switch and Ethernet Switch product lines (Formerly known as Passport,
BayStack, and Accelar), as well as, the VSP 9000 and 7000 series.

Use or create in a subclass of SNMP::Info.  Do not use directly.

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item F<RAPID-CITY>

=item F<NORTEL-NETWORKS-RAPID-SPANNING-TREE-MIB>

=item F<NORTEL-NETWORKS-MULTIPLE-SPANNING-TREE-MIB>

=back

=head1 GLOBALS

These are methods that return scalar values from SNMP

=over

=item  $rapidcity->rc_base_mac()

(C<rc2kChassisBaseMacAddr>)

=item  $rapidcity->rc_serial()

(C<rcChasSerialNumber>)

=item  $rapidcity->rc_ch_rev()

(C<rcChasHardwareRevision>)

=item  $rapidcity->chassis()

(C<rcChasType>)

=item  $rapidcity->slots()

(C<rcChasNumSlots>)

=item  $rapidcity->rc_virt_ip()

(C<rcSysVirtualIpAddr>)

=item  $rapidcity->rc_virt_mask()

(C<rcSysVirtualNetMask>)

=item  $rapidcity->tftp_host()

(C<rcTftpHost>)

=item  $rapidcity->tftp_file()

(C<rcTftpFile>)

=item  $rapidcity->tftp_action()

(C<rcTftpAction>)

=item  $rapidcity->tftp_result()

(C<rcTftpResult>)

=item $rapidcity->nn_mst_version()

(C<nnMstForceProtocolVersion>)

=item $rapidcity->nn_rst_version()

(C<nnRstDot1dStpVersion>)

=item $rapidcity->nn_mst_brg_address()

(C<nnMstBrgAddress>)

=item $rapidcity->nn_mst_cist_root()

(C<nnMstCistRoot>)

=item $rapidcity->nn_mst_cist_priority()

(C<nnMstCistBridgePriority>)

=item $rapidcity->hasSTP()

Returns 1 when C<nnRstDot1dStpVersion> is C<stpCompatible(0)> and MSTP is not
the forced version, else 0.

=item $rapidcity->hasRSTP()

Returns 1 when C<nnRstDot1dStpVersion> is C<rstp(2)> and MSTP is not the
forced version, else 0.

=item $rapidcity->hasMSTP()

Returns 1 when C<nnMstForceProtocolVersion> is C<mstp(3)>, else 0.

=back

=head2 Overrides

=over

=item  $rapidcity->serial()

Returns serial number of the chassis

=item $rapidcity->stp_ver()

Returns the particular STP version running on this device.

Values: C<nortelStpg>, C<pvst>, C<rstp>, C<mstp>, C<ieee8021d>

(C<rcSysSpanningTreeOperMode>)

=back

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $rapidcity->i_duplex()

Returns reference to map of IIDs to current link duplex.

=item $rapidcity->i_duplex_admin()

Returns reference to hash of IIDs to admin duplex setting.

=item $rapidcity->i_vlan()

Returns a mapping between C<ifIndex> and the PVID or default VLAN.

=item $rapidcity->i_vlan_membership()

Returns reference to hash of arrays: key = C<ifIndex>, value = array of VLAN
IDs.  These are the VLANs which are members of the egress list for the port.

  Example:
  my $interfaces = $rapidcity->interfaces();
  my $vlans      = $rapidcity->i_vlan_membership();

  foreach my $iid (sort keys %$interfaces) {
    my $port = $interfaces->{$iid};
    my $vlan = join(',', sort(@{$vlans->{$iid}}));
    print "Port: $port VLAN: $vlan\n";
  }

=item $rapidcity->i_vlan_membership_untagged()

Returns reference to hash of arrays: key = C<ifIndex>, value = array of VLAN
IDs.  These are the VLANs which are members of the untagged egress list for
the port.

=item $rapidcity->v_index()

Returns VLAN IDs

(C<rcVlanId>)

=item $rapidcity->agg_ports()

Returns a HASH reference mapping from slave to master port for each member of
a port bundle (MLT) on the device. Keys are ifIndex of the slave ports,
Values are ifIndex of the corresponding master ports.

=item $rapidcity->i_stp_state()

Returns the mapping of (C<dot1dStpPortState>) to the interface
index (iid).  Under RSTP, VOSS serves forwarding for a port its CLI
shows blocked.

=item $rapidcity->mst_vlan2instance()

Returns the mapping of VLAN to Spanning Tree Group (STG) instance in the
form of a hash reference with key = VLAN id, value = STG instance

(C<rcVlanStgId>)

=item $rapidcity->i_bpduguard_enabled()

Returns true or false depending on whether C<BpduGuard> is enabled on a given
port.  Format is a hash reference with key = C<ifIndex>, value = [true|false]

(C<rcPortBpduFilteringOperEnabled>)

=item $rapidcity->i_edgeport_admin()

Returns 1 or 0 for each port by whether it is configured as an edge port.
Format is a hash reference with key = C<ifIndex>, value = [1|0].  Reads
C<nnMstCistPortAdminEdgeStatus> under MSTP or
C<nnRstDot1dStpPortAdminEdgePort> under RSTP; otherwise, or when that table
has no rows, C<dot1dStpPortAdminEdgePort> through L<SNMP::Info::Bridge>.

=item $rapidcity->i_edgeport_oper()

Returns 1 or 0 for each port by whether it currently operates as an edge
port.  Format is a hash reference with key = C<ifIndex>, value = [1|0].
Reads C<nnMstCistPortOperEdgeStatus> under MSTP or
C<nnRstDot1dStpPortOperEdgePort> under RSTP; otherwise, or when that table
has no rows, C<dot1dStpPortOperEdgePort> through L<SNMP::Info::Bridge>.

=back

=head2 RAPID-CITY Port Table (C<rcPortTable>)

=over

=item $rapidcity->rc_index()

(C<rcPortIndex>)

=item $rapidcity->rc_duplex()

(C<rcPortOperDuplex>)

=item $rapidcity->rc_duplex_admin()

(C<rcPortAdminDuplex>)

=item $rapidcity->rc_speed_admin()

(C<rcPortAdminSpeed>)

=item $rapidcity->rc_auto()

(C<rcPortAutoNegotiate>)

=item $rapidcity->rc_alias()

(C<rcPortName>)

=back

=head2 RAPID-CITY CPU Ethernet Port Table (C<rc2kCpuEthernetPortTable>)

=over

=item $rapidcity->rc_cpu_ifindex()

(C<rc2kCpuEthernetPortIfIndex>)

=item $rapidcity->rc_cpu_admin()

(C<rc2kCpuEthernetPortAdminStatus>)

=item $rapidcity->rc_cpu_oper()

(C<rc2kCpuEthernetPortOperStatus>)

=item $rapidcity->rc_cpu_ip()

(C<rc2kCpuEthernetPortAddr>)

=item $rapidcity->rc_cpu_mask()

(C<rc2kCpuEthernetPortMask>)

=item $rapidcity->rc_cpu_auto()

(C<rc2kCpuEthernetPortAutoNegotiate>)

=item $rapidcity->rc_cpu_duplex_admin()

(C<rc2kCpuEthernetPortAdminDuplex>)

=item $rapidcity->rc_cpu_duplex()

(C<rc2kCpuEthernetPortOperDuplex>)

=item $rapidcity->rc_cpu_speed_admin()

(C<rc2kCpuEthernetPortAdminSpeed>)

=item $rapidcity->rc_cpu_speed_oper()

(C<rc2kCpuEthernetPortOperSpeed>)

=item $rapidcity->rc_cpu_mac()

(C<rc2kCpuEthernetPortMgmtMacAddr>)

=back

=head2 RAPID-CITY VLAN Port Table (C<rcVlanPortTable>)

=over

=item $rapidcity->rc_i_vlan_if()

(C<rcVlanPortIndex>)

=item $rapidcity->rc_i_vlan_num()

(C<rcVlanPortNumVlanIds>)

=item $rapidcity->rc_i_vlan()

(C<rcVlanPortVlanIds>)

=item $rapidcity->rc_i_vlan_type()

(C<rcVlanPortType>)

=item $rapidcity->rc_i_vlan_pvid()

(C<rcVlanPortDefaultVlanId>)

=item $rapidcity->rc_i_vlan_tag()

(C<rcVlanPortPerformTagging>)

=back

=head2 RAPID-CITY VLAN Table (C<rcVlanTable>)

=over

=item $rapidcity->rc_vlan_id()

(C<rcVlanId>)

=item $rapidcity->v_name()

(C<rcVlanName>)

=item $rapidcity->rc_vlan_color()

(C<rcVlanColor>)

=item $rapidcity->rc_vlan_if()

(C<rcVlanIfIndex>)

=item $rapidcity->rc_vlan_stg()

(C<rcVlanStgId>)

=item $rapidcity->rc_vlan_type()

(C<rcVlanType>)

=item $rapidcity->rc_vlan_members()

(C<rcVlanPortMembers>)

=item $rapidcity->rc_vlan_mac()

(C<rcVlanMacAddress>)

=back

=head2 RAPID-CITY IP Address Table (C<rcIpAddrTable>)

=over

=item $rapidcity->rc_ip_index()

(C<rcIpAdEntIfIndex>)

=item $rapidcity->rc_ip_addr()

(C<rcIpAdEntAddr>)

=item $rapidcity->rc_ip_type()

(C<rcIpAdEntIfType>)

=back

=head2 RAPID-CITY Chassis Fan Table (C<rcChasFanTable>)

=over

=item $rapidcity->rc_fan_op()

(C<rcChasFanOperStatus>)

=back

=head2 RAPID-CITY Power Supply Table (C<rcChasPowerSupplyTable>)

=over

=item $rapidcity->rc_ps_op()

(C<rcChasPowerSupplyOperStatus>)

=back

=head2 RAPID-CITY Power Supply Detail Table (C<rcChasPowerSupplyDetailTable>)

=over

=item $rapidcity->rc_ps_type()

(C<rcChasPowerSupplyDetailType>)

=item $rapidcity->rc_ps_serial()

(C<rcChasPowerSupplyDetailSerialNumber>)

=item $rapidcity->rc_ps_rev()

(C<rcChasPowerSupplyDetailHardwareRevision>)

=item $rapidcity->rc_ps_part()

(C<rcChasPowerSupplyDetailPartNumber>)

=item $rapidcity->rc_ps_detail()

(C<rcChasPowerSupplyDetailDescription>)

=back

=head2 RAPID-CITY Card Table (C<rcCardTable>)

=over

=item $rapidcity->rc_c_type()

(C<rcCardType>)

=item $rapidcity->rc_c_serial()

(C<rcCardSerialNumber>)

=item $rapidcity->rc_c_rev()

(C<rcCardHardwareRevision>)

=item $rapidcity->rc_c_part()

(C<rcCardPartNumber>)

=back

=head2 RAPID-CITY 2k Card Table (C<rc2kCardTable>)

=over

=item $rapidcity->rc2k_c_ftype()

(C<rc2kCardFrontType>)

=item $rapidcity->rc2k_c_fdesc()

(C<rc2kCardFrontDescription>)

=item $rapidcity->rc2k_c_fserial()

(C<rc2kCardFrontSerialNum>)

=item $rapidcity->rc2k_c_frev()

(C<rc2kCardFrontHwVersion>)

=item $rapidcity->rc2k_c_fpart()

(C<rc2kCardFrontPartNumber>)

=item $rapidcity->rc2k_c_fdate()

(C<rc2kCardFrontDateCode>)

=item $rapidcity->rc2k_c_fdev()

(C<rc2kCardFrontDeviations>)

=item $rapidcity->rc2k_c_btype()

(C<rc2kCardBackType>)

=item $rapidcity->rc2k_c_bdesc()

(C<rc2kCardBackDescription>)

=item $rapidcity->rc2k_c_bserial()

(C<rc2kCardBackSerialNum>)

=item $rapidcity->rc2k_c_brev()

(C<rc2kCardBackHwVersion>)

=item $rapidcity->rc2k_c_bpart()

(C<rc2kCardBackPartNumber>)

=item $rapidcity->rc2k_c_bdate()

(C<rc2kCardBackDateCode>)

=item $rapidcity->rc2k_c_bdev()

(C<rc2kCardBackDeviations>)

=back

=head2 RAPID-CITY MDA Card Table (C<rc2kMdaCardTable>)

=over

=item $rapidcity->rc2k_mda_type()

(C<rc2kMdaCardType>)

=item $rapidcity->rc2k_mda_desc()

(C<rc2kMdaCardDescription>)

=item $rapidcity->rc2k_mda_serial()

(C<rc2kMdaCardSerialNum>)

=item $rapidcity->rc2k_mda_rev()

(C<rc2kMdaCardHwVersion>)

=item $rapidcity->rc2k_mda_part()

(C<rc2kMdaCardPartNumber>)

=item $rapidcity->rc2k_mda_date()

(C<rc2kMdaCardDateCode>)

=item $rapidcity->rc2k_mda_dev()

(C<rc2kMdaCardDeviations>)

=back

=head2 RAPID-CITY Bridge SPBM MAC Table (C<rcBridgeSpbmMacTable>)

=over

=item $rapidcity->rc_spbm_fw_mac()

Returns reference to hash of forwarding table MAC Addresses

(C<rcBridgeSpbmMacAddr>)

=item $rapidcity->rc_spbm_fw_port()

Returns reference to hash of forwarding table entries port interface
identifier (iid)

(C<rcBridgeSpbmMacCPort>)

=item $rapidcity->rc_spbm_fw_status()

Returns reference to hash of forwarding table entries status

(C<rcBridgeSpbmMacStatus>)

=item $rapidcity->rc_spbm_fw_vlan()

Returns reference to hash of forwarding table entries Customer VLAN ID

(C<rcBridgeSpbmMacCVlanId>)

=item $rapidcity->rc_spbm_fw_isid()

Returns reference to hash of forwarding table entries ISID

(C<rcBridgeSpbmMacIsid>)

=back

=head2 Spanning Tree Instance Globals

C<RSTP> and C<ieee8021d> operating modes do not populate the
C<RAPID-CITY::rcStgTable> but do populate F<BRIDGE-MIB>.  These methods check
F<RAPID-CITY> first and fall back to F<BRIDGE-MIB>.

=over

=item $rapidcity->stp_i_mac()

Returns the bridge address

=item $rapidcity->stp_i_time()

Returns time since last topology change detected. (100ths/second)

=item $rapidcity->stp_i_ntop()

Returns the total number of topology changes detected.

=item $rapidcity->stp_i_root()

Returns root of STP.

=item $rapidcity->stp_i_root_port()

Returns the port number of the port that offers the lowest cost path
to the root bridge.

=item $rapidcity->stp_i_priority()

Returns the port number of the port that offers the lowest cost path
to the root bridge.

=back

=head2 Spanning Tree Protocol Port Table

C<RSTP> and C<ieee8021d> operating modes do not populate the
C<RAPID-CITY::rcStgPortTable> but do populate F<BRIDGE-MIB>.  These methods
check F<RAPID-CITY> first and fall back to F<BRIDGE-MIB>.

=over

=item $rapidcity->stp_p_id()

"The port number of the port for which this entry contains Spanning Tree
Protocol management information."

=item $rapidcity->stp_p_priority()

"The value of the priority field which is contained in the first
(in network byte order) octet of the (2 octet long) Port ID.  The other octet
of the Port ID is given by the value of C<dot1dStpPort>."

=item $rapidcity->stp_p_state()

"The port's current state as defined by application of the Spanning Tree
Protocol."

=item $rapidcity->stp_p_cost()

"The contribution of this port to the path cost of paths towards the spanning
tree root which include this port."

=item $rapidcity->stp_p_root()

"The unique Bridge Identifier of the Bridge recorded as the Root in the
Configuration BPDUs transmitted by the Designated Bridge for the segment to
which the port is attached."

=item $rapidcity->stp_p_bridge()

"The Bridge Identifier of the bridge which this port considers to be the
Designated Bridge for this port's segment."

=item $rapidcity->stp_p_port()

"The Port Identifier of the port on the Designated Bridge for this port's
segment."

=back

=head2 Spanning Tree Trees

These override L<SNMP::Info::Bridge/"Spanning Tree Trees">; records are as
described there.  The protocol is C<mstp> when C<nnMstForceProtocolVersion> is
C<mstp(3)>, else C<rstp> or C<stp> as C<nnRstDot1dStpVersion> says
(C<rstp(2)>, C<stpCompatible(0)>).  Those two objects mean the same across
the family's generations, where C<rcStgProtocolSpecification> does not.
C<rcSysSpanningTreeOperMode> C<nortelStpg> and C<pvst> are not read: those
modes predate 802.1w and 802.1s, and few devices still run them, so a
device in one of them reports no trees.

Under MSTP the CIST is C<cist.0>, from
C<NORTEL-NETWORKS-MULTIPLE-SPANNING-TREE-MIB>, and each row of
C<nnMstBridgePriority> is a C<msti.N> whose STG (N + 1) runs spanning tree.
The VOSS SPBM B-VLAN tree has C<rcStgEnableStp> false, so it is left out of
the trees and its VLANs out of C<stp_vlan_map()>.  The MSTI
bridge ID is the configured priority with the bridge address, as the device
serves it.  Under RSTP and STP the one tree is C<cist.0>, with the bridge and
root from the first C<rcStgTable> row, as VOSS serves no C<dot1dStp> scalar
under RSTP.

The port state under RSTP and STP is C<nnRstDot1wPortStateTransSmState>: the
C<BRIDGE-MIB> and C<rcStgPortTable> states serve forwarding on a blocked port.
Under RSTP and STP C<enabled> is C<rcStgPortEnableStp> for the port and the
tree's STG, else C<dot1dStpPortEnable>.  Under MSTP it is
C<nnMstCistForcePortState> for C<cist.0> and C<nnMstPortForcePortState> for
each C<msti.N>, both indexed by bridge port, with C<disabled(0)> as 0 and
C<enabled(1)> as 1; a port with no row has C<enabled> undef, as neither
C<rcStgPortEnableStp> nor C<dot1dStpPortEnable> carries the MSTP setting.
A port row with no C<bp_index> entry is left out and makes C<ports_complete>
0. An RSTP or STP device that serves no C<nnRstDot1wPortStateTransSmState>
rows also gives C<ports_complete> 0. C<measured> is 0. Only the default
context is read.

=over

=item $rapidcity->stp_protocols()

Returns reference to an array holding the protocol, or nothing when neither
version object is served.

=item $rapidcity->stp_trees()

Returns reference to hash of tree records, or an empty hash when nothing is
served.

=item $rapidcity->stp_tree_ports($tree_key)

Returns reference to hash of the tree's port records keyed by ifIndex.
C<role> is the C<nnMstCistCurrentPortRole>, C<nnMstPortCurrentPortRole> or
C<nnRstDot1wPortRole> value in the shared vocabulary, and C<role_raw> as
served.

=item $rapidcity->stp_trees_complete()

Returns 1 when a protocol is identified and trees are listed, 0 otherwise.

=item $rapidcity->stp_vlan_map()

Under MSTP returns reference to hash mapping VLAN id to C<cist.0> or
C<msti.N>, from C<rcVlanStgId>.  VLANs of an STG that does not run spanning
tree are left out.  Otherwise nothing.

=back

=head2 Spanning Tree Trees Sources

=over

=item $rapidcity->rc_stg_enable()

(C<rcStgEnableStp>)

=item $rapidcity->rc_stp_p_enable()

(C<rcStgPortEnableStp>)

=item $rapidcity->nn_msti_priority()

(C<nnMstBridgePriority>)

=item $rapidcity->nn_msti_root()

(C<nnMstBridgeRegionalRoot>)

=item $rapidcity->nn_cist_p_state()

(C<nnMstCistPortState>)

=item $rapidcity->nn_cist_p_role()

(C<nnMstCistCurrentPortRole>)

=item $rapidcity->nn_cist_p_bridge()

(C<nnMstCistPortDesignatedBridge>)

=item $rapidcity->nn_cist_p_port()

(C<nnMstCistPortDesignatedPort>)

=item $rapidcity->nn_cist_p_enable()

(C<nnMstCistForcePortState>)

=item $rapidcity->nn_cist_p_edge_admin()

(C<nnMstCistPortAdminEdgeStatus>)

=item $rapidcity->nn_cist_p_edge_oper()

(C<nnMstCistPortOperEdgeStatus>)

=item $rapidcity->nn_msti_p_state()

(C<nnMstPortState>)

=item $rapidcity->nn_msti_p_role()

(C<nnMstPortCurrentPortRole>)

=item $rapidcity->nn_msti_p_bridge()

(C<nnMstPortDesignatedBridge>)

=item $rapidcity->nn_msti_p_port()

(C<nnMstPortDesignatedPort>)

=item $rapidcity->nn_msti_p_enable()

(C<nnMstPortForcePortState>)

=item $rapidcity->nn_rst_p_state()

(C<nnRstDot1wPortStateTransSmState>)

=item $rapidcity->nn_rst_p_role()

(C<nnRstDot1wPortRole>)

=item $rapidcity->nn_rst_p_edge_admin()

(C<nnRstDot1dStpPortAdminEdgePort>)

=item $rapidcity->nn_rst_p_edge_oper()

(C<nnRstDot1dStpPortOperEdgePort>)

=item $rapidcity->rc_dot1d_p_bridge()

(C<dot1dStpPortDesignatedBridge>)

=item $rapidcity->rc_dot1d_p_port()

(C<dot1dStpPortDesignatedPort>)

=item $rapidcity->rc_dot1d_p_enable()

(C<dot1dStpPortEnable>)

=back

=head1 SET METHODS

These are methods that provide SNMP set functionality for overridden methods
or provide a simpler interface to complex set operations.  See
L<SNMP::Info/"SETTING DATA VIA SNMP"> for general information on set
operations.

=over

=item $rapidcity->set_i_speed_admin(speed, ifIndex)

Sets port speed, must be supplied with speed and port C<ifIndex>.  Speed
choices are 'auto', '10', '100', '1000'.

 Example:
 my %if_map = reverse %{$rapidcity->interfaces()};
 $rapidcity->set_i_speed_admin('auto', $if_map{'1.1'})
    or die "Couldn't change port speed. ",$rapidcity->error(1);

=item $rapidcity->set_i_duplex_admin(duplex, ifIndex)

Sets port duplex, must be supplied with duplex and port C<ifIndex>.  Speed
choices are 'auto', 'half', 'full'.

  Example:
  my %if_map = reverse %{$rapidcity->interfaces()};
  $rapidcity->set_i_duplex_admin('auto', $if_map{'1.1'})
    or die "Couldn't change port duplex. ",$rapidcity->error(1);

=item $rapidcity->set_i_vlan(vlan, ifIndex)

Changes an access (untagged) port VLAN, must be supplied with the numeric
VLAN ID and port C<ifIndex>.  This method will modify the port's VLAN
membership and PVID (default VLAN).  This method should only be used on end
station (non-trunk) ports.

  Example:
  my %if_map = reverse %{$rapidcity->interfaces()};
  $rapidcity->set_i_vlan('2', $if_map{'1.1'})
    or die "Couldn't change port VLAN. ",$rapidcity->error(1);

=item $rapidcity->set_i_pvid(pvid, ifIndex)

Sets port PVID or default VLAN, must be supplied with the numeric VLAN ID and
port C<ifIndex>.  This method only changes the PVID, to modify an access
(untagged) port use set_i_vlan() instead.

  Example:
  my %if_map = reverse %{$rapidcity->interfaces()};
  $rapidcity->set_i_pvid('2', $if_map{'1.1'})
    or die "Couldn't change port PVID. ",$rapidcity->error(1);

=item $rapidcity->set_add_i_vlan_tagged(vlan, ifIndex)

Adds the port to the egress list of the VLAN, must be supplied with the
numeric VLAN ID and port C<ifIndex>.

  Example:
  my %if_map = reverse %{$rapidcity->interfaces()};
  $rapidcity->set_add_i_vlan_tagged('2', $if_map{'1.1'})
    or die "Couldn't add port to egress list. ",$rapidcity->error(1);

=item $rapidcity->set_remove_i_vlan_tagged(vlan, ifIndex)

Removes the port from the egress list of the VLAN, must be supplied with the
numeric VLAN ID and port C<ifIndex>.

  Example:
  my %if_map = reverse %{$rapidcity->interfaces()};
  $rapidcity->set_remove_i_vlan_tagged('2', $if_map{'1.1'})
    or die "Couldn't add port to egress list. ",$rapidcity->error(1);

=item $rapidcity->set_delete_vlan(vlan)

Deletes the specified VLAN from the device.

=item $rapidcity->set_create_vlan(name, vlan)

Creates the specified VLAN on the device.

Note:  This method only allows creation of Port type VLANs and does not allow
for the setting of the Spanning Tree Group (STG) which defaults to 1.

=back

=cut
