# SNMP::Info::Layer3::Juniper
#
# Copyright (c) 2008 Bill Fenner
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

package SNMP::Info::Layer3::Juniper;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Juniper::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Juniper::EXPORT_OK = qw//;

our ($VERSION, $DEBUG, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.982000';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'JUNIPER-CHASSIS-DEFINES-MIB' => 'jnxChassisDefines',
    'JUNIPER-MIB'                 => 'jnxBoxAnatomy',
    'JUNIPER-IF-MIB'              => 'ifChassisLogicalUnit',
    'JUNIPER-VIRTUALCHASSIS-MIB'  => 'jnxVirtualChassisMemberTable',
    'JUNIPER-VLAN-MIB'            => 'jnxVlanMIBObjects',
    'JUNIPER-L2ALD-MIB'           => 'jnxL2aldVlanFdbId',
    'JUNIPER-MIMSTP-MIB'          => 'jnxMIMstSystemControl',
    'SNMP-VIEW-BASED-ACM-MIB'     => 'vacmContextName',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'serial'    => 'jnxBoxSerialNo',
    'mac'       => 'dot1dBaseBridgeAddress',
    'box_descr' => 'jnxBoxDescr',
    'version'   => 'jnxVirtualChassisMemberSWVersion',
    'vc_model'  => 'jnxVirtualChassisMemberModel',

    # RSTP-MIB, which names only stpCompatible(0) and rstp(2)
    'jnx_stp_version' => 'dot1dStpVersion',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,

    # JUNIPER-VLAN-MIB::jnxExVlanPortGroupTable
    'i_trunk' => 'jnxExVlanPortAccessMode',

    # JUNIPER-MIB
    'e_contents_type'   => 'jnxContentsType',
    'e_containers_type' => 'jnxContainersType',
    'e_hwver'           => 'jnxContentsRevision',

    # JUNIPER-VLAN-MIB::jnxExVlanTable
    'jnx_v_name'  => 'jnxExVlanName',
    'jnx_v_index' => 'jnxExVlanTag',
    'jnx_v_type'  => 'jnxExVlanType',

    # JUNIPER-L2ALD-MIB::jnxL2aldVlanTable
    # Used in Enhanced Layer 2 Software (ELS)
    # replaces JUNIPER-VLAN-MIB::jnxExVlanTable
    # in newer switches
    'jnx_els_v_name'   => 'jnxL2aldVlanName',
    'jnx_els_v_index'  => 'jnxL2aldVlanTag',
    'jnx_els_v_type'   => 'jnxL2aldVlanType',
    'jnx_els_v_fdb_id' => 'jnxL2aldVlanFdbId',

    # JUNIPER-IF-MIB::ifChassisTable
    'i_logical_unit' => 'ifChassisLogicalUnit',

    # SNMP-VIEW-BASED-ACM-MIB::vacmContextTable, names the VSTP contexts
    'jnx_vacm_context_name' => 'vacmContextName',

    # JUNIPER-MIMSTP-MIB, indexed by context
    'jnx_mst_control'       => 'jnxMIMstSystemControl',
    'jnx_mst_brg_address'   => 'jnxMIMstBrgAddress',
    'jnx_mst_cist_root'     => 'jnxMIMstCistRoot',
    'jnx_mst_cist_priority' => 'jnxMIMstCistBridgePriority',

    # JUNIPER-MIMSTP-MIB, indexed <context>.<MSTI>
    'jnx_msti_priority' => 'jnxMIMstMstiBridgePriority',
    'jnx_msti_root'     => 'jnxMIMstMstiBridgeRegionalRoot',
    'jnx_msti_vlans_1k' => 'jnxMIMstInstanceVlanMapped',
    'jnx_msti_vlans_2k' => 'jnxMIMstInstanceVlanMapped2k',
    'jnx_msti_vlans_3k' => 'jnxMIMstInstanceVlanMapped3k',
    'jnx_msti_vlans_4k' => 'jnxMIMstInstanceVlanMapped4k',

    # JUNIPER-MIMSTP-MIB, indexed by bridge port
    'jnx_cist_p_state'  => 'jnxMIMstCistPortState',
    'jnx_cist_p_role'   => 'jnxMIMstCistCurrentPortRole',
    'jnx_cist_p_bridge' => 'jnxMIMstCistPortDesignatedBridge',
    'jnx_cist_p_port'   => 'jnxMIMstCistPortDesignatedPort',

    # JUNIPER-MIMSTP-MIB, indexed <bridge port>.<MSTI>
    'jnx_msti_p_state'  => 'jnxMIMstMstiPortState',
    'jnx_msti_p_role'   => 'jnxMIMstMstiCurrentPortRole',
    'jnx_msti_p_bridge' => 'jnxMIMstMstiPortDesignatedBridge',
    'jnx_msti_p_port'   => 'jnxMIMstMstiPortDesignatedPort',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    'e_containers_type' => \&SNMP::Info::munge_e_type,
    'e_contents_type'   => \&SNMP::Info::munge_e_type,
    'jnx_mst_brg_address' => \&SNMP::Info::munge_mac,
    'jnx_mst_cist_root'   => \&SNMP::Info::munge_prio_mac,
    'jnx_msti_root'       => \&SNMP::Info::munge_prio_mac,
    'jnx_cist_p_bridge'   => \&SNMP::Info::munge_prio_mac,
    'jnx_msti_p_bridge'   => \&SNMP::Info::munge_prio_mac,
    'jnx_cist_p_port'     => \&SNMP::Info::munge_prio_port,
    'jnx_msti_p_port'     => \&SNMP::Info::munge_prio_port,
    'jnx_cist_p_role'     => \&SNMP::Info::munge_dot1s_port_role,
    'jnx_msti_p_role'     => \&SNMP::Info::munge_dot1s_port_role,
);

sub vendor {
    return 'juniper';
}

sub os {
    return 'junos';
}

sub layers {
    my $juniper = shift;

    my $layers = $juniper->SUPER::layers();
    # Some models don't report L2 properly
    my $macs   = $juniper->fw_mac();

    if (keys %$macs) {
        my $l = substr $layers, 6, 1, "1";
    }

    return $layers;
}

sub os_ver {
    my $juniper = shift;

    my $sys_descr  = $juniper->description()  || '';
    my $lldp_descr = $juniper->lldp_sysdesc() || '';

    my $ver = $juniper->version() || '';
    if (not $ver eq '')  {
        return $ver;
    }
    foreach my $descr ($sys_descr, $lldp_descr) {
        if ( $descr =~ m/kernel JUNOS ([^,\s]+)/ ) {
            return $1;
        }
        elsif ( $descr =~ m/version\s(\S+)\s/ ) {
            return $1;
        }
    }
    return;
}

sub model {
    my $l3 = shift;
    my $id = $l3->id();
    # Query the junos device model.
    my $mod = $l3->vc_model() || '';

    if (not $mod eq '') {
        return uc $mod;
    }
    # Fallback to old method
    unless ( defined $id ) {
        print
            " SNMP::Info::Layer3::Juniper::model() - Device does not support sysObjectID\n"
            if $l3->debug();
        return;
    }

    my $model = &SNMP::translateObj($id);

    return $id unless defined $model;

    $model =~ s/^jnxProductName//i;
    return $model;
}

# Override the fancy Layer3.pm serial function
sub serial {
    my $juniper = shift;
    return $juniper->orig_serial();
}

# 'i_trunk'    => 'jnxExVlanPortAccessMode',
sub i_trunk {
    my $juniper = shift;
    my $partial = shift;

    my $access  = $juniper->jnxExVlanPortAccessMode($partial);

    my %i_trunk;

    foreach (keys %$access)
    {
	    my $old_key = $_;
	    my $new_key = $old_key;
        $new_key = $1 if m/^\d+\.(\d+)$/;
	    $i_trunk{$new_key} = $access->{$old_key};
    }

    return \%i_trunk;
}

# Note: For overridden VLAN methods where we have to distinguish between newer
# ELS and older models we try the newer methods first assuming they will be
# more common to save on network queries. Short circuit operation depends on
# leaf not present and snmp query returning undef
sub qb_fdb_index {
    my $juniper = shift;
    my $partial = shift;

    # Lots of indirection here
    my $v_index = $juniper->jnx_els_v_index($partial);

    if ( ref {} eq ref $v_index and scalar keys %$v_index ) {
        my $fdb_index    = $juniper->jnx_els_v_fdb_id($partial);
        my $qb_fdb_index = {};
        for my $key ( keys(%$v_index) ) {
            my $vlan = $v_index->{$key};
            next unless defined $vlan;
            my $fdb = $fdb_index->{$key};
            next unless defined $fdb;
            $qb_fdb_index->{$fdb} = $vlan;
        }
        return $qb_fdb_index;

    }

    $juniper->jnx_v_index($partial);
}


sub v_type {
    my $juniper = shift;
    my $partial = shift;

    return $juniper->jnx_els_v_type($partial)
        || $juniper->jnx_v_type($partial);
}

sub v_index {
    my ($juniper) = shift;
    my ($partial) = shift;

    return $juniper->jnx_els_v_index($partial)
        || $juniper->jnx_v_index($partial);
}


sub i_vlan {
    my $juniper = shift;
    my $partial = shift;

    my $index = $juniper->bp_index() || {};
    my $types = $juniper->i_type() || {};

    # If given a partial it will be an ifIndex, we need to use dot1dBasePort
    my $if_partial = $partial;
    if ($partial) {
        my %r_index = reverse %$index;
        $partial = $r_index{$partial};
    }

    my $old_index = $juniper->jnx_v_index() || {};
    my $untagged  = scalar keys %$old_index
        ? $juniper->i_vlan_membership_untagged($if_partial) || {}
        : {};
    my $i_pvid = $juniper->qb_i_vlan($partial) || {};
    my $i_vlan = $juniper->SUPER::i_vlan() || {};

    foreach my $bport ( keys %$i_pvid ) {
        my $ifindex = $index->{$bport};
        unless ( defined $ifindex ) {
            print "  Port $bport has no bp_index mapping. Skipping.\n"
                if $DEBUG;
            next;
        }
        $i_vlan->{$ifindex} = $juniper->_pvid_vlan( $i_pvid->{$bport},
            $old_index, $untagged->{$ifindex} );
    }

    # add in i_logical_unit
    my $i_unit = $juniper->ifChassisLogicalUnit();
    foreach my $ifindex (keys %$i_unit) {
        my $type = $types->{$ifindex} or next;
        next unless $type eq 'l2vlan';
        # XXX not sure why this is off by one?!
        my $vlan = $i_unit->{$ifindex} - 1 or next;
        $i_vlan->{$ifindex} = $vlan;
    }

    return $i_vlan;
}

# ELS returns the VLAN ID in dot1qPvid. Pre-ELS releases differ: 10.4
# returns the jnxExVlanTable index, 12.3 the VLAN ID. Prefer the reading the
# port's untagged membership confirms, else keep the index translation.
sub _pvid_vlan {
    my ( $juniper, $pvid, $old_index, $untagged ) = @_;

    my $translated = $old_index->{$pvid};
    return $pvid unless defined $translated;

    my %member = map { $_ => 1 } grep {defined} @{ $untagged || [] };
    return $pvid if $member{$pvid} and !$member{$translated};
    return $translated;
}

sub v_name {
    my $juniper = shift;

    return $juniper->jnx_els_v_name() || $juniper->jnx_v_name();
}

# Index doesn't use VLAN ID, so override the HOA private method here to
# correct the mapping
sub _vlan_hoa {
    my $juniper = shift;
    my ( $v_ports, $partial ) = @_;

    my $index    = $juniper->bp_index();
    my $v_index  = $juniper->v_index($partial);

    my $vlan_hoa = {};
    foreach my $idx ( keys %$v_ports ) {
        next unless ( defined $v_ports->{$idx} );
        my $portlist = $v_ports->{$idx};
        my $ret      = [];
        my $vlan_ndx;

        # Strip TimeFilter if we're using VlanCurrentTable
        ( $vlan_ndx = $idx ) =~ s/^\d+\.//;

        # Convert portlist bit array to bp_index array
        for ( my $i = 0; $i <= $#$portlist; $i++ ) {
            push( @{$ret}, $i + 1 ) if ( @$portlist[$i] );
        }

        #Create HoA ifIndex -> VLAN array
        foreach my $port ( @{$ret} ) {
            my $ifindex = $index->{$port};
            next unless ( defined($ifindex) );    # shouldn't happen
            next if ( defined $partial and $ifindex !~ /^$partial$/ );
            push( @{ $vlan_hoa->{$ifindex} }, $v_index->{$vlan_ndx} );
        }
    }
    return $vlan_hoa;
}

# Older switches use RFC 4363 standard PortList definition, newer ELS switches
# return an ASCII-encoded, comma separated string of port indexes - wow
sub i_vlan_membership {
    my $juniper = shift;
    my $partial = shift;

    # Use presence of JUNIPER-VLAN-MIB::jnxExVlanTag to indicate if we should
    # treat as RFC 4363 standard PortList
    my $old_index = $juniper->jnx_v_index();

    if ( scalar keys %$old_index ) {
        return $juniper->SUPER::i_vlan_membership($partial);
    }

    my $res;

    # This isn't a PortList so use _raw to prevent munge
    my $v_ports = $juniper->qb_cv_egress_raw($partial)
        || $juniper->qb_v_egress_raw($partial);
    my $bp_index = $juniper->bp_index();

    foreach my $vlan ( keys %$v_ports ) {
        my @bp_indexes = split /,/, $v_ports->{$vlan};
        foreach my $idx (@bp_indexes) {
            if (!exists $bp_index->{$idx}) {
                print "  VLAN $vlan has no bp_index mapping. Skipping.\n"
                    if $DEBUG;
                next;
            }
            push @{ $res->{ $bp_index->{$idx} } }, $vlan;
        }
    }
    return $res;
}

sub i_vlan_membership_untagged {
    my $juniper = shift;
    my $partial = shift;

    # Use presence of JUNIPER-VLAN-MIB::jnxExVlanTag to indicate if we should
    # treat as RFC 4363 standard PortList
    my $old_index = $juniper->jnx_v_index() || {};

    if ( scalar keys %$old_index ) {
        return $juniper->SUPER::i_vlan_membership_untagged($partial);
    }

    my $types = $juniper->i_type() || {};
    my $res = {};

    # This isn't a PortList so use _raw to prevent munge
    my $v_ports = $juniper->qb_cv_untagged_raw($partial)
        || $juniper->qb_v_untagged_raw($partial);
    my $bp_index = $juniper->bp_index();

    foreach my $vlan ( keys %$v_ports ) {
        my @bp_indexes = split /,/, $v_ports->{$vlan};
        foreach my $idx (@bp_indexes) {
            if (!exists $bp_index->{$idx}) {
                print "  untagged VLAN $vlan has no bp_index mapping. Skipping.\n"
                    if $DEBUG;
                next;
            }
            push @{ $res->{ $bp_index->{$idx} } }, $vlan;
        }
    }

    # add in i_logical_unit
    my $i_unit = $juniper->ifChassisLogicalUnit();
    foreach my $ifindex (keys %$i_unit) {
        my $type = $types->{$ifindex} or next;
        next unless $type eq 'l2vlan';
        # XXX not sure why this is off by one?!
        my $vlan = $i_unit->{$ifindex} - 1 or next;
        push @{ $res->{ $ifindex } }, $vlan;
    }

    return $res;
}

# Pseudo ENTITY-MIB methods

# This class supports both virtual chassis (stackable) and physical chassis
# based devices, identify if we have a virtual chassis so that we return
# appropriate entPhysicalClass and correct ordering

sub _e_is_virtual {
    my $juniper = shift;

    my $v_test = $juniper->jnxVirtualChassisMemberRole() || {};

    #If we are functioning as a stack someone should be master
    foreach my $iid ( keys %$v_test ) {
	my $role = $v_test->{$iid};
	return 1 if ($role =~ /master/i);
    }
    return 0;
}

sub _e_virtual_index {
    my $juniper = shift;

    my $containers = $juniper->jnxContainersWithin()         || {};
    my $members    = $juniper->jnxVirtualChassisMemberRole() || {};

    my %v_index;
    foreach my $key ( keys %$containers ) {
        foreach my $member ( keys %$members ) {

            # Virtual chassis members start at zero
            $member++;

            # We will be duplicating and eliminating some keys,
            # but this is for the benefit of e_parent()
            my $index = sprintf( "%02d", $key )
                . sprintf( "%02d", $member ) . "0000";
            my $iid = "$key\.$member\.0\.0";
            $v_index{$iid} = $index;
        }
        unless ( $containers->{$key} ) {
            my $index = sprintf( "%02d", $key ) . "000000";
            $v_index{$key} = $index;
        }
    }
    return \%v_index;
}

# Member frames are the K.N.0.0 rows built by _e_virtual_index() under the
# chassis frame container K, for virtual chassis member id N-1
sub _e_vc_member {
    my $juniper = shift;
    my $iid     = shift;

    return unless $iid =~ /^(\d+)\.(\d+)\.0\.0$/;
    my ( $container, $slot ) = ( $1, $2 );

    my $containers = $juniper->jnxContainersDescr() || {};
    my $descr      = $containers->{$container} || '';
    return unless $descr =~ /chassis/i;
    return $slot - 1;
}

sub e_index {
    my $juniper = shift;

    my $contents   = $juniper->jnxContentsDescr() || {};
    my $containers = $juniper->jnxContainersDescr() || {};
    my $virtuals   = $juniper->_e_virtual_index() || {};
    my $is_virtual = $juniper->_e_is_virtual();

    # Format into consistent integer format so that numeric sorting works
    my %e_index;
    if ($is_virtual) {
	foreach my $key ( keys %$virtuals ) {
	    $e_index{$key} = $virtuals->{$key};
	}
    }
    else {
	foreach my $key ( keys %$containers ) {
	    $e_index{$key} = sprintf ("%02d", $key) . "000000";
	}
    }
    foreach my $key ( keys %$contents ) {
	$e_index{$key} = join( '', map { sprintf "%02d", $_ } split /\./, $key );
    }

    return \%e_index;
}

sub e_class {
    my $juniper = shift;

    my $e_index    = $juniper->e_index() || {};
    my $fru_type   = $juniper->jnxFruType() || {};
    my $c_type     = $juniper->jnxContainersDescr() || {};
    my $is_virtual = $juniper->_e_is_virtual();

    my %e_class;
    foreach my $iid ( keys %$e_index ) {
	
	my $type      = $fru_type->{$iid} || 0;
	my $container = $c_type->{$iid} || 0;

        if ( $type =~ /power/i  ) {
            $e_class{$iid} = 'powerSupply';
        }
        elsif ( $type =~ /fan/i ) {
            $e_class{$iid} = 'fan';
        }
	elsif ( $type ) {
	    $e_class{$iid} = 'module';
	}
	# Shouldn't get here if we have type which means
	# we only have container, chassis, and stack left
        elsif (($container =~ /chassis/i) and (!$is_virtual) ) {
            $e_class{$iid} = 'chassis';
        }
        elsif (($container =~ /chassis/i) and ($is_virtual)) {
            $e_class{$iid} = 'stack';
	}
        elsif ( $is_virtual and defined $juniper->_e_vc_member($iid) ) {
            $e_class{$iid} = 'chassis';
        }
        else {
            $e_class{$iid} = 'container';
        }
    }
    return \%e_class;
}

sub e_descr {
    my $juniper = shift;

    my $e_index    = $juniper->e_index() || {};
    my $box_descr  = $juniper->box_descr;
    my $contents   = $juniper->jnxContentsDescr() || {};
    my $containers = $juniper->jnxContainersDescr() || {};

    my %e_descr;
    foreach my $iid ( keys %$e_index ) {
	
	my $content_descr   = $contents->{$iid} || 0;
	my $container_descr = $containers->{$iid} || 0;

	if ($content_descr) {
	    $e_descr{$iid} = $content_descr;
	}
	elsif ($container_descr and $container_descr !~ /chassis/) {
	    $e_descr{$iid} = $container_descr;
	}
	elsif ($container_descr and $container_descr =~ /chassis/) {
	    $e_descr{$iid} = $box_descr;
	}
	# We should only be left with virtual entries created in
	# _e_virtual_index()
	elsif ($iid =~ /^(\d+)\.(\d+)(\.0)+?/) {
	    my $descr = $containers->{$1};
	    $e_descr{$iid} = $descr;
	}
	# Anything past here undef
    }
    return \%e_descr;
}

sub e_serial {
    my $juniper = shift;

    my $e_index    = $juniper->e_index() || {};
    my $serials    = $juniper->jnxContentsSerialNo() || {};
    my $e_class    = $juniper->e_class() || {};
    my $is_virtual = $juniper->_e_is_virtual();
    my $box_serial = $juniper->serial();
    my $vc_serials
        = $is_virtual ? $juniper->jnxVirtualChassisMemberSerialnumber() : {};
    $vc_serials ||= {};

    my %e_serial;
    foreach my $iid ( keys %$e_index ) {
	my $serial = $serials->{$iid} || '';
	my $class  = $e_class->{$iid} || '';
	my $member = $juniper->_e_vc_member($iid);
	# Chassis serial number is seperate on true chassis
	# Virtual chassis members report their own serial
	if (!$is_virtual and ($class =~ /chassis/i)){
	    $e_serial{$iid} = $box_serial;
	}
	elsif ( $class eq 'chassis' and defined $member
	    and $vc_serials->{$member} )
	{
	    $e_serial{$iid} = $vc_serials->{$member};
	}
	elsif (($serial !~ /^\w/) or ($serial =~ /builtin/i)) {
	    next;
	}
	else {
	    $e_serial{$iid} = $serial;
	}
    }
    return  \%e_serial;
}

sub e_model {
    my $juniper = shift;

    my $e_model = $juniper->orig_e_model() || {};
    return $e_model unless $juniper->_e_is_virtual();

    my $e_class   = $juniper->e_class() || {};
    my $vc_models = $juniper->jnxVirtualChassisMemberModel() || {};

    my %e_model = %$e_model;
    foreach my $iid ( keys %$e_class ) {
        next unless $e_class->{$iid} eq 'chassis';
        my $member = $juniper->_e_vc_member($iid);
        next unless defined $member and $vc_models->{$member};
        $e_model{$iid} = uc $vc_models->{$member};
    }
    return \%e_model;
}

sub e_fru {
    my $juniper = shift;

    my $e_index = $juniper->e_index() || {};
    my $frus    = $juniper->jnxContentsPartNo() || {};

    my %e_fru;
    foreach my $iid ( keys %$e_index ) {
	my $fru = $frus->{$iid} || '';
	if ( ($fru !~ /^\w/) or ($fru =~ /builtin/i)) {
	    $e_fru{$iid} = "false";
	}
	else {
	    $e_fru{$iid} = "true";
	}
    }
    return  \%e_fru;
}

sub e_type {
    my $juniper = shift;

    my $e_index    = $juniper->e_index() || {};
    my $contents   = $juniper->e_contents_type() || {};
    my $containers = $juniper->e_containers_type() || {};

    my %e_type;
    foreach my $iid ( keys %$e_index ) {
	
	my $content_type   = $contents->{$iid} || 0;
	my $container_type = $containers->{$iid} || 0;
	
	if ($content_type) {
	    $content_type =~ s/\.0//;
	    $e_type{$iid} = $content_type;
	}
	elsif ($container_type) {
	    $container_type =~ s/\.0//;
	    $e_type{$iid} = $container_type;
	}
	# We should only be left with virtual entries created in
	# _e_virtual_index()
	elsif ($iid =~ /^(\d+)\.(\d+)(\.0)+?/) {
	    my $descr = $containers->{$1};
	    $descr =~ s/\.0//;
	    $e_type{$iid} = $descr;
	}
	# Anything past here undef
    }
    return \%e_type;
}

sub e_vendor {
    my $juniper = shift;

    my $e_idx = $juniper->e_index() || {};

    my %e_vendor;
    foreach my $iid ( keys %$e_idx ) {
        $e_vendor{$iid} = 'juniper';
    }
    return \%e_vendor;
}

sub e_pos {
    my $juniper = shift;

    # We could look at index levels, but this will work as well
    return $juniper->e_index();
}

sub e_parent {
    my $juniper = shift;

    my $e_idx    = $juniper->e_index()             || {};
    my $c_within = $juniper->jnxContainersWithin() || {};
    my $e_descr  = $juniper->e_descr()             || {};
    my $is_virtual = $juniper->_e_is_virtual();

    my %e_parent;
    foreach my $iid ( keys %$e_idx ) {
        next unless $iid;

        my ( $idx, $l1, $l2, $l3 ) = split /\./, $iid;
        my $within = $c_within->{$idx};
        my $descr  = $e_descr->{$iid};

        if ( !$is_virtual and ( $iid =~ /^(\d+)\.\d+/ ) ) {
            $e_parent{$iid} = sprintf( "%02d", $1 ) . "000000";
        }
        elsif ( $is_virtual
            and ( $descr =~ /chassis/i )
            and ( $iid =~ /^(\d+)\.(\d+)(\.0)+?/ ) )
        {
            $e_parent{$iid} = sprintf( "%02d", $1 ) . "000000";
        }
        elsif ( $is_virtual and ( $iid =~ /^(\d+)\.(\d+)(\.0)+?/ ) ) {
            $e_parent{$iid}
                = sprintf( "%02d", $within ) . sprintf( "%02d", $2 ) . "0000";
        }
        elsif ( $is_virtual and ( $iid =~ /^(\d+)\.(\d+)\.[1-9]+/ ) ) {
            $e_parent{$iid}
                = sprintf( "%02d", $1 ) . sprintf( "%02d", $2 ) . "0000";
        }
        elsif ( defined $within and $iid =~ /\d+/ ) {
            $e_parent{$iid} = sprintf( "%02d", $within ) . "000000";
        }
        else {
            next;
        }
    }
    return \%e_parent;
}

sub peth_port_ifindex {
    my $peth    = shift;
    my $partial = shift;

    my $peth_port_ifindex = {};
    my $i_descr = $peth->i_description();

    # Juniper doesn't have a translator, but the ports follow a standardized layout.
    # Only the power status from the first member in a virtual chassis is reported.
    foreach my $i ( keys %$i_descr ) {
        # Juniper's port numbering is PHYS-FPC/PIC/PORT, only looking at PIC 0
        if ($i_descr->{$i} =~ m/^(fe|ge|xe|et)-(\d+)\/(0)\/(\d+)$/) {
            # Juniper port numbering begins at 0, but for PowerEthernet it begins at 1
            my $mod = $2+1;
            my $port = $4+1;
            $peth_port_ifindex->{"$mod.$port"} = $i;
        }
    }
    return $peth_port_ifindex;
}

# The protocols the default context reports: 'mstp' when MST is started at
# context 0, else the BRIDGE-MIB protocol dot1dStpVersion names, then 'vstp'
# when VSTP runs, beside that protocol or alone. Empty in any other context.
sub _jnx_stp_protocols {
    my $juniper = shift;

    # A VSTP VLAN's own context serves that VLAN's tree as RSTP
    return [] if length $juniper->_walk_context();
    return $juniper->{_jnx_stp_protocols}
        if $juniper->{_jnx_stp_protocols};

    my $control   = $juniper->jnx_mst_control() || {};
    my $default   = $juniper->_jnx_default_protocol($control);
    my @protocols = grep {defined} $default;
    push @protocols, 'vstp'
        if ( $default // '' ) ne 'mstp' and $juniper->_jnx_is_vstp($control);
    $juniper->{_jnx_stp_protocols} = \@protocols;
    return \@protocols;
}

sub _jnx_default_protocol {
    my ( $juniper, $control ) = @_;

    my $started = $control->{0};
    return 'mstp' if defined $started and $started =~ /^(?:start|1)$/;

    my $version = $juniper->jnx_stp_version();
    return unless defined $version;
    return 'rstp' if $version =~ /^(?:rstp|2)$/;
    return 'stp'  if $version =~ /^(?:stpCompatible|0)$/;
    return;
}

# VSTP has no flag of its own: each VLAN's control row sits at a context
# other than 0 and reads shutdown, and no MSTI exists. A started row there is
# MSTP inside a routing instance. The row at context 0 is the default
# context's own and says nothing about VSTP.
sub _jnx_is_vstp {
    my ( $juniper, $control ) = @_;

    my @contexts = grep { $_ ne '0' } keys %$control;
    return 0 unless @contexts;
    return 0 if grep { $control->{$_} !~ /^(?:shutdown|2)$/ } @contexts;
    return 0 if $juniper->_jnx_walk_incomplete('jnx_mst_control');
    return 0 if keys %{ $juniper->jnx_msti_priority() || {} };
    return 1;
}

sub _jnx_walk_incomplete {
    my ( $juniper, $method ) = @_;

    my $status = $juniper->walk_status($method);
    return $status && !$status->{complete} ? 1 : 0;
}

sub _jnx_runs {
    my ( $juniper, $protocol ) = @_;

    my $protocols = $juniper->_jnx_stp_protocols();
    return ( grep { $_ eq $protocol } @$protocols ) ? 1 : 0;
}

sub hasSTP {
    my $juniper = shift;
    return $juniper->_jnx_runs('stp');
}

sub hasRSTP {
    my $juniper = shift;
    return $juniper->_jnx_runs('rstp');
}

sub hasMSTP {
    my $juniper = shift;
    return $juniper->_jnx_runs('mstp');
}

sub hasVSTP {
    my $juniper = shift;
    return $juniper->_jnx_runs('vstp');
}

sub _context_kinds {
    my ( $juniper, $feature ) = @_;

    return unless ( $feature // '' ) eq 'stp';
    return unless $juniper->_jnx_runs('vstp');
    return ['vlan'];
}

# Junos puts the VLAN context first in the v2c community, the reverse of
# Cisco's community@VLAN
sub _snmp_context {
    my ( $juniper, $kind, $id ) = @_;

    return unless ( $kind // '' ) eq 'vlan' and defined $id;
    return {
        kind => 'vlan',
        id   => $id,
        v2c  => "default::$id\@%s",
        v3   => "default::$id",
    };
}

sub _jnx_vlan_context {
    my ( $instance, $vlan ) = @_;

    my $name = "${instance}::$vlan";
    return {
        kind     => 'vlan',
        id       => $vlan,
        instance => $instance,
        v2c      => "$name\@%s",
        v3       => $name,
    };
}

# The VSTP trees as [instance, VLAN] pairs, from the context names the agent
# binds, <instance>::<vlan>. Nothing else names them: the MST control rows
# carry context ids, and the VLAN table lists VLANs that do not run VSTP.
sub _jnx_vstp_contexts {
    my $juniper = shift;

    my $names = $juniper->jnx_vacm_context_name() || {};
    my %pairs;
    foreach my $name ( values %$names ) {
        next unless defined $name and $name =~ /^([^:]+)::([1-9]\d{0,3})$/;
        my ( $instance, $vlan ) = ( $1, $2 + 0 );
        $pairs{$name} = [ $instance, $vlan ] if $vlan <= 4094;
    }
    return [ sort { $a->[0] cmp $b->[0] or $a->[1] <=> $b->[1] }
            values %pairs ];
}

sub _jnx_vstp_served {
    my $juniper = shift;

    return 0 if $juniper->_jnx_walk_incomplete('jnx_vacm_context_name');
    return keys %{ $juniper->jnx_vacm_context_name() || {} } ? 1 : 0;
}

sub _jnx_vstp_trees {
    my $juniper = shift;

    my $measured = $juniper->_jnx_measured('vstp');
    my %trees;
    foreach my $pair ( @{ $juniper->_jnx_vstp_contexts() } ) {
        my ( $instance, $vlan ) = @$pair;
        my $default = $instance eq 'default';
        my $key     = $default ? "vlan.$vlan" : "vlan.$vlan\@$instance";

        $trees{$key} = {
            type           => 'vlan',
            id             => $vlan,
            vlan           => $vlan,
            instance       => $instance,
            protocol       => 'vstp',
            measured       => $measured,
            ports_complete => 1,
            contexts       => [ _jnx_vlan_context( $instance, $vlan ) ],
            bridge         => undef,
            root           => undef,
        };
    }
    return \%trees;
}

sub stp_protocols {
    my $juniper = shift;

    return unless $juniper->_stp_default_context_ok();
    my $protocols = $juniper->_jnx_stp_protocols();
    return [@$protocols] if @$protocols;
    return unless $juniper->_stp_dot1d_tree();
    return ['dot1d'];
}

sub stp_trees {
    my $juniper = shift;

    return unless $juniper->_stp_default_context_ok();
    return $juniper->{_stp_trees} if $juniper->{_stp_trees};

    my $vstp = $juniper->_jnx_runs('vstp');
    my ($default) = grep { $_ ne 'vstp' } @{ $juniper->_jnx_stp_protocols() };
    my %trees
        = ( $default // '' ) eq 'mstp' ? %{ $juniper->_jnx_mstp_trees() }
        : ( $default or !$vstp ) ? %{ $juniper->_jnx_dot1d_trees($default) }
        :                          ();
    %trees = ( %trees, %{ $juniper->_jnx_vstp_trees() } ) if $vstp;

    $juniper->{_stp_trees} = \%trees if keys %trees;
    return \%trees;
}

sub _jnx_measured {
    my ( $juniper, $protocol ) = @_;

    return 0 unless defined $protocol;
    return 0 unless $protocol =~ /^(?:stp|rstp|mstp|vstp)$/;
    return $juniper->os() eq 'junos' ? 1 : 0;
}

sub _jnx_dot1d_trees {
    my ( $juniper, $protocol ) = @_;

    my $record = $juniper->_stp_dot1d_tree() or return {};
    return {
        'cist.0' => {
            %$record,
            protocol => $protocol,
            measured => $juniper->_jnx_measured($protocol),
        }
    };
}

sub _jnx_tree_key {
    my $instance = shift;
    return $instance ? "msti.$instance" : 'cist.0';
}

# Instances with a port row at a bridge port that bp_index does not map
sub _jnx_unmapped_instances {
    my $juniper = shift;

    my $bp_index = $juniper->bp_index() || {};
    my %unmapped;
    foreach my $port ( keys %{ $juniper->jnx_cist_p_state() || {} } ) {
        $unmapped{0} = 1 unless defined $bp_index->{$port};
    }
    foreach my $row ( keys %{ $juniper->jnx_msti_p_state() || {} } ) {
        my ( $port, $instance ) = split /\./, $row, 2;
        $unmapped{$instance} = 1 unless defined $bp_index->{$port};
    }
    return \%unmapped;
}

sub _jnx_mstp_trees {
    my $juniper = shift;

    my $address    = ( $juniper->jnx_mst_brg_address() || {} )->{0};
    my $priorities = $juniper->jnx_msti_priority() || {};
    my $roots      = $juniper->jnx_msti_root() || {};
    my $cist_prio  = ( $juniper->jnx_mst_cist_priority() || {} )->{0};
    my $cist_root  = ( $juniper->jnx_mst_cist_root() || {} )->{0};
    my $unmapped   = $juniper->_jnx_unmapped_instances();
    my $measured   = $juniper->_jnx_measured('mstp');

    my %instances = ( 0 => [ $cist_prio, $cist_root ] );
    foreach my $row ( keys %$priorities ) {
        my ( $context, $instance ) = split /\./, $row, 2;
        next unless $context == 0;
        $instances{$instance} = [ $priorities->{$row}, $roots->{$row} ];
    }

    my %trees;
    foreach my $instance ( keys %instances ) {
        my ( $priority, $root ) = @{ $instances{$instance} };
        $trees{ _jnx_tree_key($instance) } = {
            type           => $instance ? 'msti' : 'cist',
            id             => $instance,
            protocol       => 'mstp',
            measured       => $measured,
            ports_complete => $unmapped->{$instance} ? 0 : 1,
            contexts       => [ { kind => 'none' } ],
            bridge         =>
                scalar SNMP::Info::Bridge::_stp_bridge_id_from( $priority,
                $address ),
            root => scalar SNMP::Info::Bridge::_stp_decode_bridge_id($root),
        };
    }
    return \%trees;
}

sub stp_tree_ports {
    my ( $juniper, $tree_key ) = @_;

    my ( $vlan, $instance )
        = ( $tree_key // '' ) =~ /^vlan\.(\d+)(?:\@(?!default$)([^:\@]+))?$/;
    return $juniper->_jnx_vstp_tree_ports( $tree_key,
        ( $instance // 'default' ) . "::$vlan" )
        if defined $vlan;

    my $tree = $juniper->_stp_tree_for_key($tree_key) or return;
    return $juniper->_stp_dot1d_port_rows($tree)
        unless ( $tree->{protocol} || '' ) eq 'mstp';
    return $juniper->_jnx_mstp_port_rows($tree);
}

# A VSTP tree is read only inside its own context, which serves BRIDGE-MIB
# for that VLAN alone, so the key itself labels the rows there
sub _jnx_vstp_tree_ports {
    my ( $juniper, $tree_key, $wanted ) = @_;

    my $context = $juniper->_walk_context();
    if ( length $context ) {
        return $juniper->_jnx_vstp_wrong_context( $tree_key, $wanted,
            $context )
            unless $context eq $wanted;
        my ($vlan) = $wanted =~ /::(\d+)$/;
        return $juniper->_stp_dot1d_port_rows(
            { type => 'vlan', id => $vlan + 0 } );
    }

    $juniper->_stp_tree_for_key($tree_key) or return;
    $juniper->error_throw(
        "SNMP::Info::Layer3::Juniper::stp_tree_ports(): tree '$tree_key' is"
            . " served in its own context (v2c '$wanted\@<community>',"
            . " v3 '$wanted'): switch to one with update() and call"
            . " stp_tree_ports('$tree_key') there.\n" );
    return;
}

sub _jnx_vstp_wrong_context {
    my ( $juniper, $tree_key, $wanted, $context ) = @_;

    $juniper->error_throw(
        "SNMP::Info::Layer3::Juniper::stp_tree_ports(): tree '$tree_key' is"
            . " served in context '$wanted', but this session is in context"
            . " '$context': switch to '$wanted' with update() and call"
            . " stp_tree_ports('$tree_key') there.\n" );
    return;
}

sub _jnx_mstp_port_rows {
    my ( $juniper, $tree ) = @_;

    my $cist   = $tree->{id} == 0;
    my $prefix = $cist ? 'jnx_cist_p_' : 'jnx_msti_p_';
    my %served;
    foreach my $column (qw/state role role_raw bridge port/) {
        my $method = $prefix . $column;
        $served{$column} = $juniper->$method() || {};
    }
    my $bp_index = $juniper->bp_index() || {};

    my %rows;
    foreach my $row ( keys %{ $served{state} } ) {
        my ( $port, $instance ) = split /\./, $row, 2;
        next if !$cist and $instance != $tree->{id};

        my $iid = $bp_index->{$port};
        next unless defined $iid;
        $rows{$iid} = {
            tree_type         => $tree->{type},
            tree_id           => $tree->{id},
            state             => $served{state}{$row},
            role              => $served{role}{$row},
            role_raw          => $served{role_raw}{$row},
            enabled           => undef,
            designated_bridge =>
                scalar SNMP::Info::Bridge::_stp_decode_bridge_id(
                $served{bridge}{$row} ),
            designated_port =>
                scalar SNMP::Info::Bridge::_stp_decode_port_id(
                $served{port}{$row} ),
        };
    }
    return \%rows;
}

sub stp_trees_complete {
    my $juniper = shift;

    return 0 unless @{ $juniper->_jnx_stp_protocols() };
    return 0 if $juniper->_jnx_walk_incomplete('jnx_mst_control');
    my $trees = $juniper->stp_trees() || {};
    return 0
        if $juniper->_jnx_runs('vstp')
        and !$juniper->_jnx_vstp_served();
    return 0 if $juniper->_jnx_vlan_contexts_unlisted();
    return keys %$trees ? 1 : 0;
}

# Each VSTP tree has one control row at a context other than 0 and one
# <instance>::<vlan> name. Counts that differ mean a name with no tree behind
# it, or a tree whose name the agent's view hides. Under MSTP any such name
# is VSTP in another routing instance, whose tree is not listed.
sub _jnx_vlan_contexts_unlisted {
    my $juniper = shift;

    my $names = @{ $juniper->_jnx_vstp_contexts() };
    return $names ? 1 : 0 if $juniper->_jnx_runs('mstp');

    my $control = $juniper->jnx_mst_control() || {};
    my $rows    = grep { $_ ne '0' } keys %$control;
    return $rows == $names ? 0 : 1;
}

# Each bitmap holds 1024 VLANs, most significant bit first; a short bitmap
# stands for zero-padding
sub stp_vlan_map {
    my $juniper = shift;

    return unless $juniper->_jnx_runs('mstp');

    my %first_vlan = (
        jnx_msti_vlans_1k => 1,
        jnx_msti_vlans_2k => 1025,
        jnx_msti_vlans_3k => 2049,
        jnx_msti_vlans_4k => 3073,
    );
    my %map;
    foreach my $method ( keys %first_vlan ) {
        my $bitmaps = $juniper->$method() || {};
        foreach my $row ( keys %$bitmaps ) {
            my ( $context, $instance ) = split /\./, $row, 2;
            next unless $context == 0;
            $map{$_} = _jnx_tree_key($instance) for _jnx_mapped_vlans(
                $bitmaps->{$row}, $first_vlan{$method} );
        }
    }
    return \%map;
}

sub _jnx_mapped_vlans {
    my ( $bitmap, $first_vlan ) = @_;

    my @vlans;
    my $bit = 0;
    foreach my $set ( split //, unpack( 'B*', $bitmap // '' ) ) {
        my $vlan = $first_vlan + $bit++;
        push @vlans, $vlan if $set and $vlan <= 4094;
    }
    return @vlans;
}

# Default tree is not the common tree: the BRIDGE-MIB tree is only the
# default context's under RSTP and STP
sub _stp_default_is_common { return 0; }

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Juniper - SNMP Interface to L3 Juniper Devices

=head1 AUTHOR

Bill Fenner

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $juniper = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $juniper->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Juniper Devices running JUNOS

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<JUNIPER-VLAN-MIB> dated "200901090000Z" or later.

=item F<JUNIPER-CHASSIS-DEFINES-MIB>

=item F<JUNIPER-MIB>

=item F<JUNIPER-VIRTUALCHASSIS-MIB>

=item F<JUNIPER-L2ALD-MIB>

=item F<JUNIPER-MIMSTP-MIB>

=item F<SNMP-VIEW-BASED-ACM-MIB>

=back

=head2 Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $juniper->vendor()

Returns 'juniper'

=item $juniper->os()

Returns 'junos'

=item $juniper->layers()

Checks forwarding table for Layer 2 support since some routers with switches
do not report layers properly.

=item $juniper->os_ver()

Returns the software version extracted first from C<sysDescr> or
C<lldpLocSysDesc> if not available in C<sysDescr>.

=item $juniper->model()

Returns the model from C<sysObjectID>, with C<jnxProductName> removed from the
beginning.

=item $juniper->serial()

Returns serial number

(C<jnxBoxSerialNo>)

=item $juniper->mac()

Returns the MAC address used by this bridge when it must be referred
to in a unique fashion.

(C<dot1dBaseBridgeAddress>)

=item $juniper->box_descr()

The name, model, or detailed description of the device.

(C<jnxBoxDescr>)

=item $juniper->version()

(C<jnxVirtualChassisMemberSWVersion>)

=item $juniper->vc_model()

(C<jnxVirtualChassisMemberModel>)

=item $juniper->jnx_stp_version()

(C<dot1dStpVersion>)

=item $juniper->hasSTP()

Returns 1 when C<dot1dStpVersion> is C<stpCompatible(0)> and MSTP is not
started, else 0.  VSTP can run beside it.

=item $juniper->hasRSTP()

Returns 1 when C<dot1dStpVersion> is C<rstp(2)> and MSTP is not started,
else 0.  VSTP can run beside it.

=item $juniper->hasMSTP()

Returns 1 when C<jnxMIMstSystemControl> for context 0 is C<start(1)>, else 0.

=item $juniper->hasVSTP()

Returns 1 when C<jnxMIMstSystemControl> does not start MSTP at context 0,
its walk completed with rows at contexts other than 0 that all read
C<shutdown(2)>, and C<jnxMIMstMstiBridgePriority> has none, else 0.  The
device sets no flag for VSTP.  The row at context 0 belongs to the default
context, so C<shutdown(2)> there, or a C<dot1dStpVersion>, does not rule VSTP
out: RSTP or STP can run beside it.  A row reading C<start(1)> at a context
other than 0 is MSTP inside a routing instance, which is not VSTP.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $juniper->qb_fdb_index()

Returns reference to hash: key = FDB ID, value = VLAN ID.

=item $juniper->v_index()

Returns (C<jnxL2aldVlanTag>) or (C<jnxExVlanTag>) depending upon switch
software version

=item $juniper->v_name()

Returns (C<jnxL2aldVlanName>) or (C<jnxExVlanName>) depending upon switch
software version

=item $juniper->v_type()

Returns (C<jnxL2aldVlanType>) or (C<jnxExVlanType>) depending upon switch
software version

=item $juniper->i_trunk()

(C<jnxExVlanPortAccessMode>)

=item $juniper->i_vlan()

Returns a mapping between C<ifIndex> and the PVID or default VLAN.

=item $juniper->i_vlan_membership()

Returns reference to hash of arrays: key = C<ifIndex>, value = array of VLAN
IDs.  These are the VLANs which are members of the egress list for the port.

=item $juniper->i_vlan_membership_untagged()

Returns reference to hash of arrays: key = C<ifIndex>, value = array of VLAN
IDs.  These are the VLANs which are members of the untagged egress list for
the port.

=item $juniper->peth_port_ifindex()

Returns reference to a hash: key= PowerEthernet MIB interface number,
value = C<ifIndex>. As Juniper does not provide a mapping function,
this does it manually.
For example, ge-0/0/1 registers as PowerEthernet interface '1.2'


=item $juniper->jnx_vacm_context_name()

(C<vacmContextName>)

=item $juniper->jnx_mst_control()

(C<jnxMIMstSystemControl>)

=item $juniper->jnx_mst_brg_address()

(C<jnxMIMstBrgAddress>)

=item $juniper->jnx_mst_cist_root()

(C<jnxMIMstCistRoot>)

=item $juniper->jnx_mst_cist_priority()

(C<jnxMIMstCistBridgePriority>)

=item $juniper->jnx_msti_priority()

(C<jnxMIMstMstiBridgePriority>)

=item $juniper->jnx_msti_root()

(C<jnxMIMstMstiBridgeRegionalRoot>)

=item $juniper->jnx_msti_vlans_1k()

(C<jnxMIMstInstanceVlanMapped>)

=item $juniper->jnx_msti_vlans_2k()

(C<jnxMIMstInstanceVlanMapped2k>)

=item $juniper->jnx_msti_vlans_3k()

(C<jnxMIMstInstanceVlanMapped3k>)

=item $juniper->jnx_msti_vlans_4k()

(C<jnxMIMstInstanceVlanMapped4k>)

=item $juniper->jnx_cist_p_state()

(C<jnxMIMstCistPortState>)

=item $juniper->jnx_cist_p_role()

(C<jnxMIMstCistCurrentPortRole>)

=item $juniper->jnx_cist_p_bridge()

(C<jnxMIMstCistPortDesignatedBridge>)

=item $juniper->jnx_cist_p_port()

(C<jnxMIMstCistPortDesignatedPort>)

=item $juniper->jnx_msti_p_state()

(C<jnxMIMstMstiPortState>)

=item $juniper->jnx_msti_p_role()

(C<jnxMIMstMstiCurrentPortRole>)

=item $juniper->jnx_msti_p_bridge()

(C<jnxMIMstMstiPortDesignatedBridge>)

=item $juniper->jnx_msti_p_port()

(C<jnxMIMstMstiPortDesignatedPort>)

=back

=head2 Spanning Tree Trees

These override L<SNMP::Info::Bridge/"Spanning Tree Trees">; records are as
described there.  The default context's protocol is C<mstp> when
C<jnxMIMstSystemControl> for context 0 is C<start(1)>, else C<rstp> or
C<stp> as C<dot1dStpVersion> says (C<rstp(2)>, C<stpCompatible(0)>).  VSTP
(C<vstp>) runs alone or beside RSTP or STP.  Junos refuses MSTP and VSTP in
one routing instance, but VSTP in a virtual switch can run beside MSTP in
the default instance; that tree is not listed.  Under MSTP the CIST is
C<cist.0> and each row of C<jnxMIMstMstiBridgePriority> is a C<msti.N>, from
C<JUNIPER-MIMSTP-MIB>; the MSTI bridge ID is the configured priority plus the
MSTI number, with the bridge address.  Under RSTP and STP the default
context's tree is the C<BRIDGE-MIB> tree C<cist.0>, and any VSTP trees are
listed beside it.  When
no indicator is served but C<BRIDGE-MIB> serves the tree, C<cist.0> is
reported with an undefined protocol, C<stp_protocols()> is C<['dot1d']> and
C<stp_trees_complete()> is 0.  C<measured> is 1 under STP, RSTP, MSTP and
VSTP.  C<enabled> is undef under MSTP, which does not serve
C<dot1dStpPortEnable>.  A port row with no C<bp_index>
entry is left out and makes C<ports_complete> 0.  Only the default context
is read, except for VSTP below.

Under VSTP each VLAN's tree (protocol C<vstp>) is served whole as
C<BRIDGE-MIB> in its own context, named C<instance::N> for VLAN N in routing
instance C<instance>.  The instance is C<default> unless VSTP runs in a
virtual switch.  The tree key is C<vlan.N> in the C<default> instance and
C<vlan.N@instance> in any other, and the record adds C<instance>.  Its one
context is C<< { kind => 'vlan', id => N, instance => instance, v2c =>
'instance::N@%s', v3 => 'instance::N' } >>.  SNMPv2c reaches it with the
community C<instance::N@community>, the instance first; C<community@N> (the
Cisco order) does not work on Junos.  SNMPv3 uses the context C<instance::N>,
which needs an exact VACM C<context-prefix instance::N> on the device.
L<SNMP::Info/"snmp_context"> answers for the C<default> instance only; use
the tree record's context for the others.  A tree record's contexts carry
C<instance>, C<default> included, so they are not deep-equal to
C<snmp_context('vlan', N)>, which has no C<instance> key.  A
C<vlan.N@default> key is not a tree: C<default> trees are keyed C<vlan.N>.
Under VSTP alone the default context serves no C<dot1dStp> object.

The VLANs and instances come from C<vacmContextName>, keeping the names of
the form C<instance::N> with N from 1 to 4094.  The MST control rows and the
VLAN table are not used for the list: the first carry context ids, and the
second lists VLANs that do not run VSTP.  When the agent's view excludes
C<SNMP-VIEW-BASED-ACM-MIB> (1.3.6.1.6.3.16), the VLAN list is unknown:
C<stp_trees()> holds no VSTP tree and C<stp_trees_complete()> is 0.  Grant
the community or user read access to 1.3.6.1.6.3.16.  Other VLAN contexts get
no reply at all, not an error, so ask only the listed ones.  A VSTP record
has an undefined C<bridge> and C<root>, which only its own context serves.

Each VSTP tree has one C<jnxMIMstSystemControl> row at a context other than
0, and the agent lists one C<instance::N> name for it.  A listed name can
have no tree behind it, since a VACM C<context-prefix> entry lists its name
without VSTP; C<stp_tree_ports()> in such a context returns no rows.  A tree
can also go unlisted when the agent's view hides its name.  So unless MSTP
is started, C<stp_trees_complete()> is 0 if the number of C<instance::N>
names differs from the number of control rows at contexts other than 0.
Every control row at a context other than 0 counts, whatever it reads, so
MSTP started inside a routing instance beside RSTP or STP in the default
context also makes it 0.  A name with no tree and a tree with a hidden name
cancel out in the count, and then neither is detected.
Under MSTP it is 0 when any C<instance::N> name is listed, since that is VSTP
in another routing instance, which is not listed as a tree.
C<stp_trees_complete()> is also 0 whenever the C<jnxMIMstSystemControl> walk
was incomplete.

=over

=item $juniper->stp_protocols()

Returns reference to an array holding the default context's protocol, then
C<vstp> when VSTP runs (C<['rstp', 'vstp']> beside RSTP, C<['vstp']> alone),
C<['dot1d']> when only C<BRIDGE-MIB> is served, or nothing.  Protocol
methods answer only in the default context: C<stp_protocols()> reports an
error in any other, and C<hasSTP()> to C<hasVSTP()> return 0.

=item $juniper->stp_trees()

Returns reference to hash of tree records, or an empty hash when nothing is
served.

=item $juniper->stp_tree_ports($tree_key)

Returns reference to hash of the tree's port records keyed by ifIndex.  A
C<vlan.N> key is read in the session's own context C<default::N>, and a
C<vlan.N@instance> key in C<instance::N>; in any other context it returns
nothing, with C<error()> naming the context to use.
Under MSTP C<role> is the C<jnxMIMstCistCurrentPortRole> or
C<jnxMIMstMstiCurrentPortRole> value in the shared vocabulary, and C<role_raw>
as served.

=item $juniper->stp_trees_complete()

Returns 1 when a protocol is identified and trees are listed, 0 otherwise,
including when only C<BRIDGE-MIB> is served.  When VSTP runs, also 0 unless
C<vacmContextName> was served and its walk completed.  Always 0 when the
C<jnxMIMstSystemControl> walk was incomplete.  Unless MSTP is started, also 0
when the number of C<instance::N> names in C<vacmContextName> differs from
the number of C<jnxMIMstSystemControl> rows at contexts other than 0: a name
with no tree behind it, or a tree whose name is hidden or missing.  Under
MSTP, 0 when C<vacmContextName> lists any C<instance::N> name: VSTP in
another routing instance, whose tree is not listed.

=item $juniper->stp_vlan_map()

Under MSTP returns reference to hash mapping VLAN id to C<msti.N>, from the
four C<jnxMIMstInstanceVlanMapped> bitmaps (VLANs 1 to 4094).  Only VLANs
mapped to an MSTI appear: the device serves no row for the CIST.  Otherwise
nothing.

=back

=head2 Pseudo F<ENTITY-MIB> information

These methods emulate F<ENTITY-MIB> Physical Table methods using
F<JUNIPER-MIB> and F<JUNIPER-VIRTUALCHASSIS-MIB>.

=over

=item $juniper->e_index()

Returns reference to hash.  Key: IID, Value: Integer, Indices are combined
into a eight digit integer, each index is two digits padded with leading zero
if required.

=item $juniper->e_class()

Returns reference to hash.  Key: IID, Value: General hardware type.  A
virtual chassis is a C<stack> with one C<chassis> per member.

=item $juniper->e_descr()

Returns reference to hash.  Key: IID, Value: Human friendly name

=item $juniper->e_hwver()

Returns reference to hash.  Key: IID, Value: Hardware version

=item $juniper->e_vendor()

Returns reference to hash.  Key: IID, Value: juniper

=item $juniper->e_serial()

Returns reference to hash.  Key: IID, Value: Serial number.  In a virtual
chassis each member frame reports its own serial
(C<jnxVirtualChassisMemberSerialnumber>).

=item $juniper->e_model()

Returns reference to hash.  Key: IID, Value: Model name.  In a virtual
chassis each member frame reports its own model
(C<jnxVirtualChassisMemberModel>); other entries are from
F<ENTITY-MIB> (C<entPhysicalModelName>).

=item $juniper->e_pos()

Returns reference to hash.  Key: IID, Value: The relative position among all
entities sharing the same parent.

=item $juniper->e_type()

Returns reference to hash.  Key: IID, Value: Type of component/sub-component
as defined in F<JUNIPER-CHASSIS-DEFINES-MIB>.

=item $juniper->e_parent()

Returns reference to hash.  Key: IID, Value: The value of e_index() for the
entity which 'contains' this entity.  A value of zero indicates	this entity
is not contained in any other entity.

=item $entity->e_fru()

BOOLEAN. Is a Field Replaceable unit?

(C<entPhysicalFRU>)

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
