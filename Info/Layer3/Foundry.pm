# SNMP::Info::Layer3::Foundry - SNMP Interface to Foundry devices
# $Id$
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
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::FDP;
use SNMP::Info::LLDP;

@SNMP::Info::Layer3::Foundry::ISA = qw/SNMP::Info::FDP SNMP::Info::LLDP
    SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Foundry::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %FUNCS %MIBS %MUNGE/;

$VERSION = '3.10';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::LLDP::MIBS,
    %SNMP::Info::FDP::MIBS,
    'FOUNDRY-SN-ROOT-MIB'         => 'foundry',
    'FOUNDRY-SN-AGENT-MIB'        => 'snChasPwrSupplyDescription',
    'FOUNDRY-SN-SWITCH-GROUP-MIB' => 'snSwGroupOperMode',
    'FOUNDRY-SN-STACKING-MIB'     => 'snStackingOperUnitRole',
    'FOUNDRY-POE-MIB'             => 'snAgentPoeGblPowerCapacityTotal',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,
    %SNMP::Info::FDP::GLOBALS,
    'mac'        => 'ifPhysAddress.1',
    'chassis'    => 'entPhysicalDescr.1',
    'temp'       => 'snChasActualTemperature',
    'ps1_type'   => 'snChasPwrSupplyDescription.1',
    'ps1_status' => 'snChasPwrSupplyOperStatus.1',
    'fan'        => 'snChasFanOperStatus.1',
    'img_ver'    => 'snAgImgVer',
    'ch_serial'  => 'snChasSerNum',

);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::LLDP::FUNCS,
    %SNMP::Info::FDP::FUNCS,

    # FOUNDRY-SN-SWITCH-GROUP-MIB
    # snSwPortInfoTable - Switch Port Information Group
    'sw_index'  => 'snSwPortIfIndex',
    'sw_duplex' => 'snSwPortInfoChnMode',
    'sw_type'   => 'snSwPortInfoMediaType',
    'sw_speed'  => 'snSwPortInfoSpeed',

    # FOUNDRY-SN-AGENT-MIB::snAgentConfigModule2Table
    'ag_mod2_type' => 'snAgentConfigModule2Type',

    # FOUNDRY-SN-AGENT-MIB::snAgentConfigModuleTable
    'ag_mod_type' => 'snAgentConfigModuleType',

);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE, %SNMP::Info::LLDP::MUNGE,
    %SNMP::Info::FDP::MUNGE,
    'ag_mod2_type' => \&SNMP::Info::munge_e_type,
    'ag_mod_type'  => \&SNMP::Info::munge_e_type,
);

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

# Reported hangs on a EdgeIron 24G
sub stp_p_state {
    my $foundry = shift;
    my $partial = shift;

    my $descr = $foundry->description();
    if ( $descr =~ m/\bEdgeIron 24G\b/ ) {
        return;
    }

    return $foundry->SUPER::stp_p_state($partial) || {};

}

# Entity MIB is supported on the Brocade NetIron XMR, NetIron MLX, MLXe,
# NetIron CES, NetIron CER, and older EdgeIron series devices.
# Try Entity MIB methods first and fall back to Pseudo ENTITY-MIB methods for
# other devices.
# e_fwver, e_hwver, e_swver not supported in psuedo methods, no need to
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

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Foundry - SNMP Interface to Brocade (Foundry) Network
Devices

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $foundry = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 1
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class = $foundry->class();

 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for Brocade (Foundry) Networks devices.

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above.

 my $foundry = new SNMP::Info::Layer3::Foundry(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3;

=item SNMP::Info::FDP;

=item SNMP::Info::LLDP;

=back

=head2 Required MIBs

=over

=item F<FOUNDRY-SN-ROOT-MIB>

=item F<FOUNDRY-SN-AGENT-MIB>

=item F<FOUNDRY-SN-SWITCH-GROUP-MIB>

=item F<FOUNDRY-SN-STACKING-MIB>

=item F<FOUNDRY-POE-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::FDP/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::LLDP/"Required MIBs"> for its own MIB requirements.

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

Returns the Description for the power supply

(C<snChasPwrSupplyDescription.1>)

=item $foundry->ps1_status()

Returns the status of the power supply.

(C<snChasPwrSupplyOperStatus.1>)

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

=head2 Global Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"GLOBALS"> for details.

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

=item $foundry->stp_p_state()

"The port's current state as defined by application of the Spanning Tree
Protocol.

Skipped if device is an EdgeIron 24G due to reports of hangs.

(C<dot1dStpPortState>)

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
Port Table C<pethPsePortTable> methods using the F<FOUNDRY-POE-MIB> Power
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
(PSE) Table C<pethMainPseTable> methods using the F<FOUNDRY-POE-MIB> Power
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

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::FDP

See documentation in L<SNMP::Info::FDP/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"TABLE METHODS"> for details.

=cut
