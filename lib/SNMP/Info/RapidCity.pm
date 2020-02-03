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

$VERSION = '3.70';

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
index (iid).

=item $rapidcity->mst_vlan2instance()

Returns the mapping of VLAN to Spanning Tree Group (STG) instance in the
form of a hash reference with key = VLAN id, value = STG instance

(C<rcVlanStgId>)

=item $rapidcity->i_bpduguard_enabled()

Returns true or false depending on whether C<BpduGuard> is enabled on a given
port.  Format is a hash reference with key = C<ifIndex>, value = [true|false]

(C<rcPortBpduFilteringOperEnabled>)

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
