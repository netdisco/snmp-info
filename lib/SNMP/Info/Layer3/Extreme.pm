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

$VERSION = '3.70';

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
    # EXTREME-STP-EXTENSIONS-MIB::extremeStpPortTable
    'stp_p_priority' => 'extremeStpPortPortPriority',
    'stp_p_state'    => 'extremeStpPortPortState',
    'stp_p_cost'     => 'extremeStpPortPathCost',
    'stp_p_root'     => 'extremeStpPortDesignatedRoot',
    'stp_p_bridge'   => 'extremeStpPortDesignatedBridge',
    'stp_p_port'     => 'extremeStpPortDesignatedPort',
);

%MUNGE = (

    # Inherit all the built in munging
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::MAU::MUNGE,
    %SNMP::Info::EDP::MUNGE,
    'ex_fw_mac'        => \&SNMP::Info::munge_mac,
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

    return 'extremeware';
}


sub os_ver {
    my $extreme = shift;
    my $descr   = $extreme->description();
    return unless defined $descr;

    if ( $descr =~ m/Version\s+([^ ]+)/i ) {
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
    return $extreme->ex_vlan_descr();
}

sub v_index {
    my $extreme = shift;
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

sub set_i_vlan {
    my $extreme = shift;
    return $extreme->_extreme_set_i_vlan( 0, @_ );
}

sub set_i_pvid {
    my $extreme = shift;
    return $extreme->_extreme_set_i_vlan( 1, @_ );
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

Returns C<xos> or C<extremeware> depending on description()

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

Returns VLAN IDs

=item $extreme->v_name()

Returns VLAN names

(C<extremeVlanIfDescr>)

=item $extreme->bp_index()

Returns reference to hash of bridge port table entries map back to interface
identifier (iid)

Returns (C<ifIndex>) for both key and value since we're using
F<EXTREME-FDB-MIB> rather than F<BRIDGE-MIB>.

=item $extreme->peth_port_power()

Power supplied by PoE ports, in milliwatts

(C<extremePethPortMeasuredPower>)

=item $extreme->peth_power_watts()

The configured maximum amount of in-line power available to the slot.

(C<extremePethSlotPowerLimit>)

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

=item $extreme->stp_p_cost()

(C<extremeStpPortPathCost>)

=item $extreme->stp_p_root()

(C<extremeStpPortDesignatedRoot>)

=item $extreme->stp_p_bridge()

(C<extremeStpPortDesignatedBridge>)

=item $extreme->stp_p_port()

(C<extremeStpPortDesignatedPort>)

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

=over

=item $extreme->set_i_vlan ( vlan, ifIndex )

Changes an access (untagged) port VLAN, must be supplied with the numeric
VLAN ID and port C<ifIndex>.  This method should only be used on end station
(non-trunk) ports.

  Example:
  my %if_map = reverse %{$extreme->interfaces()};
  $extreme->set_i_vlan('2', $if_map{'FastEthernet0/1'})
    or die "Couldn't change port VLAN. ",$extreme->error(1);

=item $extreme->set_i_pvid ( pvid, ifIndex )

Sets port default VLAN, must be supplied with the numeric VLAN ID and
port C<ifIndex>.  This method should only be used on trunk ports.

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
