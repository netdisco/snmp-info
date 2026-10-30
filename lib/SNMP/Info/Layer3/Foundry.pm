# SNMP::Info::Layer3::Foundry - SNMP Interface to Foundry devices
#
# Copyright (c) 2008 Max Baker changes from version 0.8 and beyond.
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

package SNMP::Info::Layer3::Foundry;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::FDP;

@SNMP::Info::Layer3::Foundry::ISA = qw/
    SNMP::Info::FDP
    SNMP::Info::Layer3
    Exporter
/;
@SNMP::Info::Layer3::Foundry::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %FUNCS, %MIBS, %MUNGE);

$VERSION = '3.984000';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::FDP::MIBS,

    'FOUNDRY-SN-ROOT-MIB'         => 'foundry',
    'FOUNDRY-SN-AGENT-MIB'        => 'snChasPwrSupplyDescription',
    'FOUNDRY-SN-SWITCH-GROUP-MIB' => 'snSwGroupOperMode',
    'FOUNDRY-SN-IP-MIB'           => 'snRtIpPortIfAddress',
    'FOUNDRY-SN-STACKING-MIB'     => 'snStackingOperUnitRole',
    'FDRY-POE-MIB'                => 'snAgentPoeGblPowerCapacityTotal',
    'BROCADE-PRODUCTS-MIB'        => 'brocadeProducts',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::FDP::GLOBALS,

    'mac'        => 'ifPhysAddress.1',
    'chassis'    => 'entPhysicalDescr.1',
    'temp'       => 'snChasActualTemperature',
    'ps1_type'   => 'snChasPwrSupplyDescription.1',
    'ps2_type'   => 'snChasPwrSupplyDescription.2',
    'ps1_status' => 'snChasPwrSupplyOperStatus.1',
    'ps2_status' => 'snChasPwrSupplyOperStatus.2',
    'fan'        => 'snChasFanOperStatus.1',
    'img_ver'    => 'snAgImgVer',
    'ch_serial'  => 'snChasSerNum',

);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::FDP::FUNCS,

    # FOUNDRY-SN-SWITCH-GROUP-MIB
    # snSwPortInfoTable - Switch Port Information Group
    'sw_index'  => 'snSwPortIfIndex',
    'sw_duplex' => 'snSwPortInfoChnMode',
    'sw_type'   => 'snSwPortInfoMediaType',
    'sw_speed'  => 'snSwPortInfoSpeed',

    # FOUNDRY-SN-SWITCH-GROUP-MIB
    #

    # FOUNDRY-SN-AGENT-MIB::snAgentConfigModule2Table
    'ag_mod2_type' => 'snAgentConfigModule2Type',

    # FOUNDRY-SN-AGENT-MIB::snAgentConfigModuleTable
    'ag_mod_type' => 'snAgentConfigModuleType',

    # FOUNDRY-SN-AGENT-MIB::snVLanByPortTable
    'stp_i_id'        => 'snVLanByPortVLanId',
    'stp_i_mac'       => 'snVLanByPortBaseBridgeAddress',
    'stp_i_time'      => 'snVLanByPortStpTimeSinceTopologyChange',
    'stp_i_ntop'      => 'snVLanByPortStpTopChanges',
    'stp_i_root'      => 'snVLanByPortStpDesignatedRoot',
    'stp_i_root_port' => 'snVLanByPortStpRootPort',
    'stp_i_priority'  => 'snVLanByPortStpPriority',

    # FOUNDRY-SN-SWITCH-GROUP-MIB VLAN configuration and membership tables.
    # Use these tables when the standard bridge methods return no data.
    '_vlan_cfg_id'          => 'snVLanByPortCfgVLanId',
    '_vlan_cfg_name'        => 'snVLanByPortCfgVLanName',
    '_vlan_member_vlan_id'  => 'snVLanByPortMemberVLanId',
    '_vlan_member_port_id'  => 'snVLanByPortMemberPortId',
    '_vlan_member_status'   => 'snVLanByPortMemberRowStatus',
    '_vlan_member_tag_mode' => 'snVLanByPortMemberTagMode',

    # FOUNDRY-SN-IP-MIB::snRtIpPortIfAddrTable
    '_ip_if_index'   => 'snRtIpPortIfAddrInterfaceIndex',
    '_ip_if_address' => 'snRtIpPortIfAddress',
    '_ip_if_netmask' => 'snRtIpPortIfSubnetMask',
    '_ip_if_status'  => 'snRtIpPortIfRowStatus',

    # FOUNDRY-SN-AGENT-MIB::snPortStpTable
    'stp_p_id'       => 'snPortStpPortNum',
    'stp_p_stg_id'   => 'snPortStpVLanId',
    'stp_p_priority' => 'snPortStpPortPriority',
    'stp_p_state'    => 'snPortStpPortState',
    'stp_p_cost'     => 'snPortStpPortDesignatedCost',
    'stp_p_root'     => 'snPortStpPortDesignatedRoot',
    'stp_p_bridge'   => 'snPortStpPortDesignatedBridge',
    'stp_p_port'     => 'snPortStpPortDesignatedPort',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::FDP::MUNGE,

    'ag_mod2_type' => \&SNMP::Info::munge_e_type,
    'ag_mod_type'  => \&SNMP::Info::munge_e_type,
    'stp_i_mac'    => \&SNMP::Info::munge_mac,
    'stp_i_root'   => \&SNMP::Info::munge_prio_mac,
    'stp_p_root'   => \&SNMP::Info::munge_prio_mac,
    'stp_p_bridge' => \&SNMP::Info::munge_prio_mac,
    'stp_p_port'   => \&SNMP::Info::munge_prio_port,
);

sub v_name {
    my $foundry = shift;
    my $partial = shift;

    return $foundry->SUPER::v_name($partial)
        unless $foundry->_foundry_vlan_source() eq 'foundry';

    my $vlan_ids = $foundry->_vlan_cfg_id($partial) || {};
    my $vlan_names = $foundry->_vlan_cfg_name($partial) || {};

    my %v_name;
    foreach my $idx ( keys %$vlan_ids ) {
        my $vlan = $vlan_ids->{$idx};
        next unless defined $vlan;
        my $name = $vlan_names->{$idx};
        $v_name{$vlan} = defined $name ? $name : '';
    }

    return \%v_name;
}

sub _foundry_vlan_source {
    my $foundry = shift;

    return $foundry->{_foundry_vlan_source}
        if defined $foundry->{_foundry_vlan_source};

    my @bridge_data = (
        $foundry->SUPER::v_name(),
        $foundry->SUPER::i_vlan(),
        $foundry->SUPER::i_vlan_membership(),
        $foundry->SUPER::i_vlan_membership_untagged(),
    );

    foreach my $data (@bridge_data) {
        next unless ref $data eq 'HASH';
        return $foundry->{_foundry_vlan_source} = 'bridge'
            if keys %$data;
    }

    my $cfg_ids = $foundry->_vlan_cfg_id() || {};
    my $member_ids = $foundry->_vlan_member_vlan_id() || {};
    return $foundry->{_foundry_vlan_source} = 'foundry'
        if keys %$cfg_ids or keys %$member_ids;

    return $foundry->{_foundry_vlan_source} = 'bridge';
}

sub _vlan_member_rows {
    my $foundry = shift;

    my $vlan_ids = $foundry->_vlan_member_vlan_id()  || {};
    my $port_ids = $foundry->_vlan_member_port_id()  || {};
    my $statuses = $foundry->_vlan_member_status()   || {};
    my $tag_modes = $foundry->_vlan_member_tag_mode() || {};

    my @rows;
    foreach my $idx ( keys %$vlan_ids ) {
        my ($vlan_idx, $port_idx) = $idx =~ /^(\d+)\.(\d+)$/;
        next unless defined $vlan_idx and defined $port_idx;

        my $vlan = $vlan_ids->{$idx};
        my $port = $port_ids->{$idx};
        next unless defined $vlan and defined $port and $vlan and $port;

        my $status = $statuses->{$idx};
        next unless defined $status and $status =~ /^(?:valid|2)(?:\(2\))?$/i;

        push @rows, {
            vlan     => $vlan,
            ifindex  => $port,
            tag_mode => $tag_modes->{$idx},
        };
    }

    return \@rows;
}

sub _foundry_ip_rows {
    my $foundry = shift;

    my $addresses = $foundry->_ip_if_address() || {};
    my $ifindexes = $foundry->_ip_if_index() || {};
    my $netmasks  = $foundry->_ip_if_netmask() || {};
    my $statuses  = $foundry->_ip_if_status() || {};

    my @rows;
    foreach my $idx ( keys %$addresses ) {
        my ($index_if, $index_ip) = $idx =~ /^(\d+)\.(\d+\.\d+\.\d+\.\d+)$/;
        next unless defined $index_if and defined $index_ip;

        my $ifindex = $ifindexes->{$idx};
        my $address = $addresses->{$idx};
        my $netmask = $netmasks->{$idx};
        my $status  = $statuses->{$idx};
        next
            unless defined $ifindex and defined $address and defined $netmask;
        next unless defined $status and $status =~ /^(?:valid|2)(?:\(2\))?$/i;

        push @rows, {
            ifindex => $ifindex,
            address => $address,
            netmask => $netmask,
        };
    }

    return \@rows;
}

sub _foundry_ip_source {
    my $foundry = shift;

    return $foundry->{_foundry_ip_source}
        if defined $foundry->{_foundry_ip_source};

    my $ip_index = $foundry->SUPER::ip_index() || {};
    return $foundry->{_foundry_ip_source} = 'ip_mib'
        if keys %$ip_index;

    my $addresses = $foundry->_ip_if_address() || {};
    return $foundry->{_foundry_ip_source} = 'foundry'
        if keys %$addresses;

    return $foundry->{_foundry_ip_source} = 'ip_mib';
}

sub ip_index {
    my $foundry = shift;

    return $foundry->SUPER::ip_index()
        unless $foundry->_foundry_ip_source() eq 'foundry';

    my %ip_index;
    foreach my $row ( @{ $foundry->_foundry_ip_rows() } ) {
        $ip_index{ $row->{address} } = $row->{ifindex};
    }

    return \%ip_index;
}

sub ip_table {
    my $foundry = shift;

    return $foundry->SUPER::ip_table()
        unless $foundry->_foundry_ip_source() eq 'foundry';

    my %ip_table;
    foreach my $row ( @{ $foundry->_foundry_ip_rows() } ) {
        $ip_table{ $row->{address} } = $row->{address};
    }

    return \%ip_table;
}

sub ip_netmask {
    my $foundry = shift;

    return $foundry->SUPER::ip_netmask()
        unless $foundry->_foundry_ip_source() eq 'foundry';

    my %ip_netmask;
    foreach my $row ( @{ $foundry->_foundry_ip_rows() } ) {
        $ip_netmask{ $row->{address} } = $row->{netmask};
    }

    return \%ip_netmask;
}

sub i_vlan {
    my $foundry = shift;
    my $partial = shift;

    return $foundry->SUPER::i_vlan($partial)
        unless $foundry->_foundry_vlan_source() eq 'foundry';

    my $rows = $foundry->_vlan_member_rows();

    my %i_vlan;
    foreach my $row ( @$rows ) {
        next unless defined $row->{tag_mode};
        next unless $row->{tag_mode} =~ /^(?:untagged|2)(?:\(2\))?$/i;
        next if defined $partial and $row->{ifindex} ne $partial;
        $i_vlan{ $row->{ifindex} } = $row->{vlan};
    }

    return \%i_vlan;
}

sub i_untagged { goto &i_vlan }

sub i_vlan_membership {
    my $foundry = shift;
    my $partial = shift;

    return $foundry->SUPER::i_vlan_membership($partial)
        unless $foundry->_foundry_vlan_source() eq 'foundry';

    my $rows = $foundry->_vlan_member_rows();

    my %membership;
    foreach my $row ( @$rows ) {
        next if defined $partial and $row->{ifindex} ne $partial;
        push @{ $membership{ $row->{ifindex} } }, $row->{vlan};
    }

    return \%membership;
}

sub i_vlan_membership_untagged {
    my $foundry = shift;
    my $partial = shift;

    return $foundry->SUPER::i_vlan_membership_untagged($partial)
        unless $foundry->_foundry_vlan_source() eq 'foundry';

    my $rows = $foundry->_vlan_member_rows();

    my %membership;
    foreach my $row ( @$rows ) {
        next unless defined $row->{tag_mode};
        next unless $row->{tag_mode} =~ /^(?:untagged|2)(?:\(2\))?$/i;
        next if defined $partial and $row->{ifindex} ne $partial;
        push @{ $membership{ $row->{ifindex} } }, $row->{vlan};
    }

    return \%membership;
}

sub i_ignore {
    my $foundry = shift;
    my $partial = shift;

    my $interfaces = $foundry->interfaces($partial) || {};

    my %i_ignore;
    foreach my $if ( keys %$interfaces ) {
        if ( $interfaces->{$if} =~ /(tunnel|loopback|\blo\b|lb|null)/i ) {
            $i_ignore{$if}++;
        }
    }
    return \%i_ignore;
}

sub i_duplex {
    my $foundry = shift;
    my $partial = shift;

    my $sw_index  = $foundry->sw_index($partial);
    my $sw_duplex = $foundry->sw_duplex($partial);

    unless ( defined $sw_index and defined $sw_duplex ) {
        return $foundry->SUPER::i_duplex();
    }

    my %i_duplex;
    foreach my $sw_port ( keys %$sw_duplex ) {
        my $iid    = $sw_index->{$sw_port};
        my $duplex = $sw_duplex->{$sw_port};
        next if $duplex =~ /none/i;
        $i_duplex{$iid} = 'half' if $duplex =~ /half/i;
        $i_duplex{$iid} = 'full' if $duplex =~ /full/i;
    }
    return \%i_duplex;
}

sub model {
    my $foundry = shift;
    my $id      = $foundry->id();
    my $model   = &SNMP::translateObj($id);

    # EdgeIron
    if ( $id =~ /\.1991\.1\.[45]\./ ) {

        my $e_name = $foundry->e_name();

        # Find entity table entry for "unit.1"
        my $unit_iid = undef;
        foreach my $e ( keys %$e_name ) {
            my $name = $e_name->{$e} || '';
            $unit_iid = $e if $name eq 'unit.1';
        }

        # Find Model Name
        my $e_model = $foundry->e_model();
        if ( defined $e_model->{$unit_iid} ) {
            return $e_model->{$unit_iid};
        }
    }

    return $id unless defined $model;

    $model =~ s/^sn//;
    $model =~ s/Switch//;

    return $model;
}

sub os {
    return 'brocade';
}

sub vendor {
    return 'brocade';
}

sub os_ver {
    my $foundry = shift;

    return $foundry->img_ver() if ( defined $foundry->img_ver() );

    # Some older ones don't have this value,so we cull it from the description
    my $descr = $foundry->description();
    if ( $descr =~ m/Version (\d\S*)/ ) {
        return $1;
    }

    # EdgeIron
    my $e_name = $foundry->e_name();

    # find entity table entry for "stackmanaget.1"
    my $unit_iid = undef;
    foreach my $e ( keys %$e_name ) {
        my $name = $e_name->{$e} || '';
        $unit_iid = $e if $name eq 'stackmanaget.1';
    }

    if ( defined $unit_iid ) {

        # Find Model Name
        my $e_fwver = $foundry->e_fwver();
        if ( defined $e_fwver->{$unit_iid} ) {
            return $e_fwver->{$unit_iid};
        }
    }

    # See if we report from Flash if wouldn't report from running above
    return $foundry->snAgFlashImgVer() if ( defined $foundry->snAgFlashImgVer() );

    # Last resort
    return $foundry->SUPER::os_ver();

}

sub serial {
    my $foundry = shift;

    # Return chassis serial number if available
    return $foundry->ch_serial() if ( $foundry->ch_serial() );

    # If no chassis serial use first module serial
    my $mod_serials = $foundry->snAgentConfigModuleSerialNumber() || {};

    foreach my $mod ( sort keys %$mod_serials ) {
        my $serial = $mod_serials->{$mod} || '';
        next unless defined $serial;
        return $serial;
    }

    # EdgeIron
    my $e_name = $foundry->e_name();

    # find entity table entry for "unit.1"
    my $unit_iid = undef;
    foreach my $e ( keys %$e_name ) {
        my $name = $e_name->{$e} || '';
        $unit_iid = $e if $name eq 'unit.1';
    }

    if ( defined $unit_iid ) {

        # Look up serial of found entry.
        my $e_serial = $foundry->e_serial();
        return $e_serial->{$unit_iid} if defined $e_serial->{$unit_iid};
    }

    # Last resort
    return $foundry->SUPER::serial();
}

sub interfaces {
    my $foundry = shift;
    my $partial = shift;

    my $i_descr = $foundry->i_description($partial) || {};
    my $i_name  = $foundry->i_name($partial)        || {};

    # Use ifName for EdgeIrons else use ifDescr
    foreach my $iid ( keys %$i_name ) {
        my $name = $i_name->{$iid};
        next unless defined $name;
        $i_descr->{$iid} = $name
            if $name =~ /^port\d+/i;
    }

    return $i_descr;
}

sub set_i_vlan {
    my ($foundry, $vlan, $iid) = @_;
    my $i_vlan = $foundry->i_vlan($iid);

    if ( defined $i_vlan ) {
        print
            "Changing VLAN from $i_vlan->{$iid} to $vlan on IfIndex: $iid\n"
            if $foundry->debug();

        # quietly try to remove new vlan association
        $foundry->set_snVLanByPortMemberRowStatus( 3, "${vlan}.${iid}" );
        sleep 1;
        # try to remove old vlan association
        my $rv_rem = $foundry->set_snVLanByPortMemberRowStatus( 3, "$i_vlan->{$iid}.$iid" );
        sleep 1;

        unless ($rv_rem) {
            print "Unable to remove untagged(?) VLAN $i_vlan->{$iid} from IfIndex: $iid\n"
              if $foundry->debug();
            #    $foundry->error_throw(
            #        "Unable to remove VLAN $i_vlan->{$iid} from interface: $iid");
            #    return;
        }

        # try to add new one untagged
        my $rv_add = $foundry->set_multi([
            ['snVLanByPortMemberRowStatus', "${vlan}.${iid}", 4],
            ['snVLanByPortMemberTagMode',   "${vlan}.${iid}", 2],
        ]);
        sleep 1;

        unless ($rv_add) {
            print "Unable to add untagged VLAN $vlan to IfIndex: $iid\n"
              if $foundry->debug();

            # did not work to add new untagged so add tagged
            my $rv_add_tagged = $foundry->set_multi([
              ['snVLanByPortMemberRowStatus', "${vlan}.${iid}", 4],
              ['snVLanByPortMemberTagMode',   "${vlan}.${iid}", 1],
            ]);
            sleep 1;

            if ($rv_add_tagged) {
                my $rv_change_untagged = $foundry->set_snVLanByPortMemberTagMode( 2, "${vlan}.${iid}" );
                sleep 1;
                return $rv_change_untagged if $rv_change_untagged;
            }

            # try to remove old vlan association
            # $foundry->set_snVLanByPortMemberRowStatus( 3, "${vlan}.${iid}" );

            # then change to untagged
            $foundry->error_throw(
                "Unable to add VLAN $vlan to interface: $iid");
            return;
        }

        return $rv_add;
    }
    $foundry->error_throw("Can't find ifIndex: $iid - Is it an access port?");
    return;
}

# Entity MIB is supported on the Brocade NetIron XMR, NetIron MLX, MLXe,
# NetIron CES, NetIron CER, and older EdgeIron series devices.
# Try Entity MIB methods first and fall back to Pseudo ENTITY-MIB methods for
# other devices.
# e_fwver, e_hwver, e_swver not supported in pseudo methods, no need to
# override

sub e_index {
    my $foundry = shift;
    my $partial = shift;

    return $foundry->SUPER::e_index($partial)
        || $foundry->brcd_e_index($partial);
}

sub e_class {
    my $foundry = shift;
    my $partial = shift;

    return $foundry->SUPER::e_class($partial)
        || $foundry->brcd_e_class($partial);
}

sub e_descr {
    my $foundry = shift;
    my $partial = shift;

    return $foundry->SUPER::e_descr($partial)
        || $foundry->brcd_e_descr($partial);
}

sub e_name {
    my $foundry = shift;
    my $partial = shift;

    return $foundry->SUPER::e_name($partial)
        || $foundry->brcd_e_name($partial);
}

sub e_parent {
    my $foundry = shift;
    my $partial = shift;

    return $foundry->SUPER::e_parent($partial)
        || $foundry->brcd_e_parent($partial);
}

sub e_pos {
    my $foundry = shift;
    my $partial = shift;

    return $foundry->SUPER::e_pos($partial) || $foundry->brcd_e_pos($partial);
}

sub e_serial {
    my $foundry = shift;
    my $partial = shift;

    return $foundry->SUPER::e_serial($partial)
        || $foundry->brcd_e_serial($partial);
}

sub e_type {
    my $foundry = shift;
    my $partial = shift;

    return $foundry->SUPER::e_type($partial)
        || $foundry->brcd_e_type($partial);
}

sub e_vendor {
    my $foundry = shift;
    my $partial = shift;

    return $foundry->SUPER::e_vendor($partial)
        || $foundry->brcd_e_vendor($partial);
}

# Pseudo ENTITY-MIB methods

# This class supports both stackable and chassis based switches, identify if
# we have a stackable so that we return appropriate entPhysicalClass

# Identify if the stackable is actually a stack vs. single switch
sub _brcd_stack_master {
    my $foundry = shift;

    my $roles = $foundry->snStackingOperUnitRole() || {};

    foreach my $iid ( keys %$roles ) {
        my $role = $roles->{$iid};
        next unless $role;
        if ( $role eq 'active' ) {
            return $iid;
        }
    }
    return;
}

sub brcd_e_index {
    my $foundry = shift;
    my $partial = shift;

    my $stack_master = $foundry->_brcd_stack_master();
    my $brcd_e_idx
        = $foundry->snAgentConfigModule2Description($partial)
        || $foundry->snAgentConfigModuleDescription($partial)
        || {};

    my %brcd_e_index;
    if ($stack_master) {

        # Stack Entity
        $brcd_e_index{0} = 1;
    }

    foreach my $iid ( keys %$brcd_e_idx ) {

        my $index = $iid;

        # Format into consistent integer format so that numeric sorting works
        if ( $iid =~ /(\d+)\.(\d+)/ ) {
            $index = "$1" . sprintf "%02d", $2;
        }
        $brcd_e_index{$iid} = $index;
    }
    return \%brcd_e_index;
}

sub brcd_e_class {
    my $foundry = shift;
    my $partial = shift;

    my $e_idx = $foundry->brcd_e_index($partial) || {};

    my %e_class;
    foreach my $iid ( keys %$e_idx ) {
        if ( $iid == 0 ) {
            $e_class{$iid} = 'stack';
        }

        # Were going to assume chassis at slot/index 1
        # If this turns out to be false in some cases we can check
        # snAgentConfigModuleNumberOfCpus as other modules won't have cpus?
        elsif ( $iid =~ /1$/ ) {
            $e_class{$iid} = 'chassis';
        }
        else {
            $e_class{$iid} = 'module';
        }
    }
    return \%e_class;
}

sub brcd_e_descr {
    my $foundry = shift;
    my $partial = shift;

    my $brcd_e_idx = $foundry->brcd_e_index($partial) || {};
    my $m_descrs
        = $foundry->snAgentConfigModule2Description($partial)
        || $foundry->snAgentConfigModuleDescription($partial)
        || {};

    my %brcd_e_descr;
    foreach my $iid ( keys %$brcd_e_idx ) {

        if ( $iid == 0 ) {
            $brcd_e_descr{$iid} = $foundry->description();
        }

        my $descr = $m_descrs->{$iid};
        next unless defined $descr;

        $brcd_e_descr{$iid} = $descr;
    }
    return \%brcd_e_descr;
}

sub brcd_e_name {
    my $foundry = shift;
    my $partial = shift;

    my $stack_master = $foundry->_brcd_stack_master();
    my $e_idx = $foundry->brcd_e_index($partial) || {};

    my %brcd_e_name;
    foreach my $iid ( keys %$e_idx ) {
        if ( $iid == 0 ) {
            $brcd_e_name{$iid} = 'Stack Master Unit';
        }

        elsif ( $stack_master && $iid =~ /(\d+)\.1$/ ) {
            $brcd_e_name{$iid} = "Switch Stack Unit $1";
        }
        elsif ( $iid =~ /1$/ ) {
            $brcd_e_name{$iid} = "Switch";
        }
        else {
            $brcd_e_name{$iid} = 'Module';
        }
    }
    return \%brcd_e_name;
}

sub brcd_e_vendor {
    my $foundry = shift;
    my $partial = shift;

    my $e_idx = $foundry->brcd_e_index($partial) || {};

    my %brcd_e_vendor;
    foreach my $iid ( keys %$e_idx ) {
        my $vendor = 'brocade';

        $brcd_e_vendor{$iid} = $vendor;
    }
    return \%brcd_e_vendor;
}

sub brcd_e_serial {
    my $foundry = shift;
    my $partial = shift;

    my $e_idx = $foundry->brcd_e_index($partial) || {};
    my $serials
        = $foundry->snAgentConfigModule2SerialNumber($partial)
        || $foundry->snAgentConfigModuleSerialNumber($partial)
        || {};

    my %brcd_e_serial;
    foreach my $iid ( keys %$e_idx ) {

        if ( $iid == 0 ) {
            $brcd_e_serial{$iid} = $foundry->serial();
        }

        my $serial = $serials->{$iid};
        next unless defined $serial;

        $brcd_e_serial{$iid} = $serial;
    }
    return \%brcd_e_serial;
}

sub brcd_e_type {
    my $foundry = shift;
    my $partial = shift;

    my $e_idx = $foundry->brcd_e_index($partial) || {};
    my $types
        = $foundry->ag_mod2_type($partial)
        || $foundry->ag_mod_type($partial)
        || {};

    my %brcd_e_type;
    foreach my $iid ( keys %$e_idx ) {

        if ( $iid == 0 ) {
            $brcd_e_type{$iid} = $foundry->model();
        }

        my $type = $types->{$iid};
        next unless defined $type;

        $brcd_e_type{$iid} = $type;
    }
    return \%brcd_e_type;
}

sub brcd_e_pos {
    my $foundry = shift;
    my $partial = shift;

    my $e_idx = $foundry->brcd_e_index($partial) || {};

    my %brcd_e_pos;
    foreach my $iid ( keys %$e_idx ) {

        my $pos;
        if ( $iid == 0 ) {
            $pos = -1;
        }
        elsif ( $iid =~ /(\d+)\.1$/ ) {
            $pos = $1;
        }
        elsif ( $iid =~ /(\d+)$/ ) {
            $pos = $1;
        }

        $brcd_e_pos{$iid} = $pos;
    }
    return \%brcd_e_pos;
}

sub brcd_e_parent {
    my $foundry = shift;
    my $partial = shift;

    my $stack_master = $foundry->_brcd_stack_master();
    my $e_idx = $foundry->brcd_e_index($partial) || {};

    my %brcd_e_parent;
    foreach my $iid ( keys %$e_idx ) {

        if ( $iid == 0 ) {
            $brcd_e_parent{$iid} = 0;
        }
        elsif ( $stack_master && $iid =~ /(\d+)\.1$/ ) {
            $brcd_e_parent{$iid} = 1;
        }
        elsif ( $iid =~ /1$/ ) {
            $brcd_e_parent{$iid} = 0;
        }
        elsif ( $iid =~ /(\d+).\d+/ ) {
            $brcd_e_parent{$iid} = "$1" . "01";
        }

        # assume non-stacked and chassis at index 1
        else {
            $brcd_e_parent{$iid} = 1;
        }
    }
    return \%brcd_e_parent;
}

# The index of snAgentPoePortTable is snAgentPoePortNumber which equals
# ifIndex; however, to emulate POWER-ETHERNET-MIB we need a "module.port"
# index.  If ifDescr has the format x/x/x use it to determine the module
# otherwise default to 1.  Unfortunately, this means we can't map any
# snAgentPoePortTable leafs directly and partials will not be supported.
sub peth_port_ifindex {
    my $foundry = shift;

    my $indexes = $foundry->snAgentPoePortNumber();
    my $descrs  = $foundry->i_description();

    my $peth_port_ifindex = {};
    foreach my $i ( keys %$indexes ) {
        my $descr = $descrs->{$i};
        next unless $descr;

        my $new_idx = "1.$i";

        if ( $descr =~ /(\d+)\/\d+\/\d+/ ) {
            $new_idx = "$1.$i";
        }
        $peth_port_ifindex->{$new_idx} = $i;
    }
    return $peth_port_ifindex;
}

sub peth_port_admin {
    my $foundry = shift;

    my $p_index      = $foundry->peth_port_ifindex()     || {};
    my $admin_states = $foundry->snAgentPoePortControl() || {};

    my $peth_port_admin = {};
    foreach my $i ( keys %$p_index ) {
        my ( $module, $port ) = split( /\./, $i );
        my $state = $admin_states->{$port};

        if ( $state =~ /enable/ ) {
            $peth_port_admin->{$i} = 'true';
        }
        else {
            $peth_port_admin->{$i} = 'false';
        }
    }
    return $peth_port_admin;
}

sub peth_port_neg_power {
    my $foundry = shift;

    my $p_index         = $foundry->peth_port_ifindex()   || {};
    my $peth_port_class = $foundry->snAgentPoePortClass() || {};

    my $poemax = {
        '0' => 12950,
        '1' => 3840,
        '2' => 6490,
        '3' => 12950,
        '4' => 25500
    };

    my $peth_port_neg_power = {};
    foreach my $i ( keys %$p_index ) {
        my ( $module, $port ) = split( /\./, $i );
        my $power = $poemax->{ $peth_port_class->{$port} };
        next unless $power;

        $peth_port_neg_power->{$i} = $power;
    }
    return $peth_port_neg_power;
}

sub peth_port_power {
    my $foundry = shift;

    my $p_index       = $foundry->peth_port_ifindex()      || {};
    my $port_consumed = $foundry->snAgentPoePortConsumed() || {};

    my $peth_port_power = {};
    foreach my $i ( keys %$p_index ) {
        my ( $module, $port ) = split( /\./, $i );
        my $power = $port_consumed->{$port};
        next unless $power;

        $peth_port_power->{$i} = $power;
    }
    return $peth_port_power;
}

sub peth_port_class {
    my $foundry = shift;

    my $p_index    = $foundry->peth_port_ifindex()   || {};
    my $port_class = $foundry->snAgentPoePortClass() || {};

    my $peth_port_class = {};
    foreach my $i ( keys %$p_index ) {
        my ( $module, $port ) = split( /\./, $i );
        my $power = $port_class->{$port};
        next unless $power;

        $peth_port_class->{$i} = "class$power";
    }
    return $peth_port_class;
}

sub peth_port_status {
    my $foundry = shift;

    my $p_index      = $foundry->peth_port_ifindex()     || {};
    my $admin_states = $foundry->snAgentPoePortControl() || {};

    my $peth_port_status = {};
    foreach my $i ( keys %$p_index ) {
        my ( $module, $port ) = split( /\./, $i );
        my $state = $admin_states->{$port};

        if ( $state =~ /enable/ ) {
            $peth_port_status->{$i} = 'deliveringPower';
        }
        else {
            $peth_port_status->{$i} = 'disabled';
        }
    }
    return $peth_port_status;
}

sub peth_power_status {
    my $foundry = shift;
    my $partial = shift;

    my $watts = $foundry->snAgentPoeUnitPowerCapacityTotal($partial) || {};

    my $peth_power_status = {};
    foreach my $i ( keys %$watts ) {
        $peth_power_status->{$i} = 'on';
    }
    return $peth_power_status;
}

sub peth_power_watts {
    my $foundry = shift;
    my $partial = shift;

    my $watts_total = $foundry->snAgentPoeUnitPowerCapacityTotal($partial)
        || {};

    my $peth_power_watts = {};
    foreach my $i ( keys %$watts_total ) {
        my $total = $watts_total->{$i};
        next unless $total;

        $peth_power_watts->{$i} = $total / 1000;
    }
    return $peth_power_watts;
}

sub peth_power_consumption {
    my $foundry = shift;
    my $partial = shift;

    my $watts_total = $foundry->snAgentPoeUnitPowerCapacityTotal($partial)
        || {};
    my $watts_free = $foundry->snAgentPoeUnitPowerCapacityFree($partial)
        || {};

    my $peth_power_consumed = {};
    foreach my $i ( keys %$watts_total ) {
        my $total = $watts_total->{$i};
        next unless $total;
        my $free = $watts_free->{$i} || 0;

        $peth_power_consumed->{$i} = ( $total - $free ) / 1000;
    }
    return $peth_power_consumed;
}

sub agg_ports {
  my $dev = shift;

  # TODO: implement partial
  my $trunks = $dev->snMSTrunkPortList;
  my $ports  = $dev->snSwPortIfIndex; # sw_index()

  return {} unless
    ref {} eq ref $trunks and scalar keys %$trunks
    and ref {} eq ref $ports and scalar keys %$ports;

  my $ret = {};
  foreach my $m (keys %$trunks) {
      next unless $m and exists $ports->{$m} and defined $ports->{$m};

      foreach my $s (unpack('n*', $trunks->{$m})) {
          next if $s == $m;
          next unless $s and exists $ports->{$s} and defined $ports->{$s};

          $ret->{ $ports->{$s} } = $ports->{$m};
      }
  }

  return $ret;
}

sub _agg_ports_walked { return qw/snMSTrunkPortList snSwPortIfIndex/ }

sub i_stp_state {
    my $foundry  = shift;
    my $partial = shift;

    my $bp_index    = $foundry->bp_index($partial);
    my $stp_p_state = $foundry->dot1dStpPortState($partial);

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

# Default tree is not the common tree: per-VLAN STP (snPortStp*)
sub _stp_default_is_common { return 0; }

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Foundry - SNMP Interface to Ruckus (Brocade / Foundry Networks)
ICX switches.

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $foundry = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $foundry->class();

 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to information obtainable from Ruckus ICX switches (Brocade
/ Foundry Networks) devices through SNMP.
See inherited classes' documentation for inherited methods.

Reports no spanning tree: these devices run per-VLAN STP, which
F<BRIDGE-MIB> does not describe.  C<stp_trees()> is empty,
C<stp_protocols()> returns nothing, and C<stp_trees_complete()> returns 0
(see L<SNMP::Info::Bridge/"Spanning Tree Trees">).

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3;

=item SNMP::Info::FDP;

=back

=head2 Required MIBs

=over

=item F<BROCADE-PRODUCTS-MIB>

=item F<FOUNDRY-SN-ROOT-MIB>

=item F<FOUNDRY-SN-AGENT-MIB>

=item F<FOUNDRY-SN-SWITCH-GROUP-MIB>

=item F<FOUNDRY-SN-IP-MIB>

=item F<FOUNDRY-SN-STACKING-MIB>

=item F<FDRY-POE-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::FDP/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $foundry->model()

Returns model type.  Checks $foundry->id() against the F<FOUNDRY-SN-ROOT-MIB>
and removes 'C<sn>' and 'C<Switch>'.  EdgeIron models determined
through F<ENTITY-MIB>.

=item $foundry->vendor()

Returns 'brocade'

=item $foundry->os()

Returns 'brocade'

=item $foundry->os_ver()

Returns the software version

=item $foundry->mac()

Returns MAC Address of root port.

(C<ifPhysAddress.1>)

=item $foundry->chassis()

Returns Chassis type.

(C<entPhysicalDescr.1>)

=item $foundry->serial()

Returns serial number of device.

=item $foundry->temp()

Returns the chassis temperature

(C<snChasActualTemperature>)

=item $foundry->ps1_type()

Returns the description for the first power supply.

(C<snChasPwrSupplyDescription.1>)

=item $foundry->ps1_status()

Returns the status of the first power supply.

(C<snChasPwrSupplyOperStatus.1>)

=item $foundry->ps2_type()

Returns the description for the second power supply.

(C<snChasPwrSupplyDescription.2>)

=item $foundry->ps2_status()

Returns the status of the second power supply.

(C<snChasPwrSupplyOperStatus.2>)

=item $foundry->fan()

Returns the status of the chassis fan.

(C<snChasFanOperStatus.1>)

=item $foundry->img_ver()

Returns device image version.

(C<snAgImgVer.0>)

=item $foundry->ch_serial()

Returns chassis serial number.

(C<snChasSerNum.0>)

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::FDP

See documentation in L<SNMP::Info::FDP/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a
reference to a hash.

=head2 Overrides

=over

=item $foundry->interfaces()

Returns reference to hash of interface names to iids.

=item $foundry->i_ignore()

Returns reference to hash of interfaces to be ignored.

Ignores interfaces with descriptions of  tunnel,loopback,null

=item $foundry->i_duplex()

Returns reference to hash of interface link duplex status.

Crosses $foundry->sw_duplex() with $foundry->sw_index()

=item $foundry->i_stp_state()

Returns the mapping of (C<dot1dStpPortState>) to the interface
index (iid).

=item $foundry->agg_ports()

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.  The master port is not listed
as a member of its own bundle.

=back

=head2 F<ENTITY-MIB> Information

F<ENTITY-MIB> is supported on the Brocade NetIron XMR, NetIron MLX, MLXe,
NetIron CES, NetIron CER, and older EdgeIron series devices.  For other
devices which do not support it, these methods emulate Physical Table methods
using F<FOUNDRY-SN-AGENT-MIB>.  See Pseudo F<ENTITY-MIB> information below
for details on brcd_e_* methods.

=over

=item $foundry->e_index()

If the device doesn't support C<entPhysicalDescr>, this will
try brcd_e_index().

Note that this is based on C<entPhysicalDescr> due to implementation
details of SNMP::Info::Entity::e_index().

=item $foundry->e_class()

If the device doesn't support C<entPhysicalClass>, this will try
brcd_e_class().

=item $foundry->e_descr()

If the device doesn't support C<entPhysicalDescr>, this will try
brcd_e_descr().

=item $foundry->e_name()

If the device doesn't support C<entPhysicalName>, this will try
brcd_e_name().

=item $foundry->e_parent()

If the device doesn't support C<entPhysicalContainedIn>, this will try
brcd_e_parent().

=item $foundry->e_pos()

If the device doesn't support C<entPhysicalParentRelPos>, this will try
brcd_e_pos().

=item $foundry->e_serial()

If the device doesn't support C<entPhysicalSerialNum>, this will try
brcd_e_serial().

=item $foundry->e_type()

If the device doesn't support C<entPhysicalVendorType>, this will try
brcd_e_type().

=item $foundry->e_vendor()

If the device doesn't support C<entPhysicalMfgName>, this will try
brcd_e_vendor().

=back

=head2 Pseudo F<ENTITY-MIB> information

These methods emulate F<ENTITY-MIB> Physical Table methods using
F<FOUNDRY-SN-AGENT-MIB>.

=over

=item $foundry->brcd_e_index()

Returns reference to hash.  Key: IID, Value: Integer, Indices are combined
into an integer, each index is two digits padded with leading zero if
required.

=item $foundry->brcd_e_class()

Returns reference to hash.  Key: IID, Value: General hardware type.

Returns 'stack' for the stack master in an active stack, 'chassis' for
base switches that contain modules, and 'module' for others.

=item $foundry->brcd_e_descr()

Returns reference to hash.  Key: IID, Value: Human friendly name

(C<snAgentConfigModule2Description>) or
(C<snAgentConfigModuleDescription>)

=item $foundry->brcd_e_name()

Returns reference to hash.  Key: IID, Value: Human friendly name

=item $foundry->brcd_e_vendor()

Returns reference to hash.  Key: IID, Value: brocade

=item $foundry->brcd_e_serial()

Returns reference to hash.  Key: IID, Value: Serial number

Serial number is $foundry->serial() for a stack master unit and
(C<snAgentConfigModule2SerialNumber>) or
(C<snAgentConfigModuleSerialNumber>) for all others.

=item $foundry->brcd_e_type()

Returns reference to hash.  Key: IID, Value: Type of component/sub-component
as defined under C<snAgentConfigModule2Type> or C<snAgentConfigModule2Type>
in F<FOUNDRY-SN-AGENT-MIB>.

=item $foundry->brcd_e_pos()

Returns reference to hash.  Key: IID, Value: The relative position among all
entities sharing the same parent.

(C<s5ChasComSubIndx>)

=item $foundry->brcd_e_parent()

Returns reference to hash.  Key: IID, Value: The value of brcd_e_index()
for the entity which 'contains' this entity.  A value of zero indicates
this entity is not contained in any other entity.

=back

=head2 Foundry Switch Port Information Table (C<snSwPortIfTable>)

=over

=item $foundry->sw_index()

Returns reference to hash.  Maps Table to Interface IID.

(C<snSwPortIfIndex>)

=item $foundry->sw_duplex()

Returns reference to hash.   Current duplex status for switch ports.

(C<snSwPortInfoChnMode>)

=item $foundry->sw_type()

Returns reference to hash.  Current Port Type .

(C<snSwPortInfoMediaType>)

=item $foundry->sw_speed()

Returns reference to hash.  Current Port Speed.

(C<snSwPortInfoSpeed>)

=back

=head2 Power Over Ethernet Port Table

These methods emulate the F<POWER-ETHERNET-MIB> Power Source Entity (PSE)
Port Table C<pethPsePortTable> methods using the F<FDRY-POE-MIB> Power
over Ethernet Port Table C<snAgentPoePortTable>.

=over

=item $foundry->peth_port_ifindex()

Creates an index of module.port to align with the indexing of the
C<pethPsePortTable> with a value of C<ifIndex>.  The module defaults 1
if otherwise unknown.

=item $foundry->peth_port_admin()

Administrative status: is this port permitted to deliver power?

C<pethPsePortAdminEnable>

=item $foundry->peth_port_status()

Current status: is this port delivering power.

=item $foundry->peth_port_class()

Device class: if status is delivering power, this represents the 802.3af
class of the device being powered.

=item $foundry->peth_port_neg_power()

The power, in milliwatts, that has been committed to this port.
This value is derived from the 802.3af class of the device being
powered.

=item $foundry->peth_port_power()

The power, in milliwatts, that the port is delivering.

=back

=head2 Power Over Ethernet Module Table

These methods emulate the F<POWER-ETHERNET-MIB> Main Power Source Entity
(PSE) Table C<pethMainPseTable> methods using the F<FDRY-POE-MIB> Power
over Ethernet Port Table C<snAgentPoeModuleTable >.

=over

=item $foundry->peth_power_watts()

The power supply's capacity, in watts.

=item $foundry->peth_power_status()

The power supply's operational status.

=item $foundry->peth_power_consumption()

How much power, in watts, this power supply has been committed to
deliver.

=back

=head2 VLAN methods

FastIron ICX devices may not implement or populate the Q-BRIDGE-MIB tables
used by the base bridge class. These methods prefer non-empty standard bridge
data and use the Foundry port VLAN configuration and membership tables when
the standard methods return no data.

=over

=item $foundry->v_name()

Returns VLAN names keyed by VLAN ID, including configured VLANs with no
member ports.

=item $foundry->i_vlan()

Returns the untagged VLAN for each interface index.

=item $foundry->i_untagged()

Alias for C<i_vlan()>.

=item $foundry->i_vlan_membership()

Returns all VLAN memberships keyed by interface index.

=item $foundry->i_vlan_membership_untagged()

Returns untagged VLAN memberships keyed by interface index.

=back

=head2 IP address methods

When standard IP-MIB methods return data, C<ip_index()>, C<ip_table()>,
and C<ip_netmask()> preserve those results. If the standard methods return
no data, the Foundry IP interface table supplies the address, interface
index, and subnet mask.

=over

=item $foundry->ip_index()

Maps IPv4 addresses to interface indexes.

=item $foundry->ip_table()

Returns the IPv4 address table keyed by address.

=item $foundry->ip_netmask()

Maps IPv4 addresses to their subnet masks.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::FDP

See documentation in L<SNMP::Info::FDP/"TABLE METHODS"> for details.

=head1 SET METHODS

These are methods that provide SNMP set functionality for overridden methods
or provide a simpler interface to complex set operations.  See
L<SNMP::Info/"SETTING DATA VIA SNMP"> for general information on set
operations.

=over

=item $foundry->set_i_vlan ( vlan, ifIndex )

Changes an access (untagged) port VLAN, must be supplied with the numeric
VLAN ID and port C<ifIndex>.  This method should only be used on end station
(non-trunk) ports.

  Example:
  my %if_map = reverse %{$foundry->interfaces()};
  $foundry->set_i_vlan('2', $if_map{'FastEthernet0/1'})
    or die "Couldn't change port VLAN. ",$foundry->error(1);

=back

=cut
