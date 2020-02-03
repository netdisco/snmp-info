# SNMP::Info::Layer2::Baystack
#
# Copyright (c) 2008 Max Baker changes from version 0.8 and beyond.
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

package SNMP::Info::Layer2::Baystack;

use strict;
use warnings;
use Exporter;
use SNMP::Info::SONMP;
use SNMP::Info::NortelStack;
use SNMP::Info::RapidCity;
use SNMP::Info::Layer3;

@SNMP::Info::Layer2::Baystack::ISA
    = qw/SNMP::Info::SONMP SNMP::Info::NortelStack
    SNMP::Info::RapidCity
    SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer2::Baystack::EXPORT_OK = qw//;

our ($VERSION, %FUNCS, %GLOBALS, %MIBS, %MUNGE);

$VERSION = '3.70';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::RapidCity::MIBS, %SNMP::Info::NortelStack::MIBS,
    %SNMP::Info::SONMP::MIBS,
    'BAY-STACK-PETH-EXT-MIB' => 'bspePethPsePortExtMeasuredPower',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::RapidCity::GLOBALS, %SNMP::Info::NortelStack::GLOBALS,
    %SNMP::Info::SONMP::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::RapidCity::FUNCS, %SNMP::Info::NortelStack::FUNCS,
    %SNMP::Info::SONMP::FUNCS,
    'peth_port_power' => 'bspePethPsePortExtMeasuredPower',
);

# 450's report full duplex as speed = 20mbps?!
$SNMP::Info::SPEED_MAP{20_000_000}    = '10 Mbps';
$SNMP::Info::SPEED_MAP{200_000_000}   = '100 Mbps';
$SNMP::Info::SPEED_MAP{2_000_000_000} = '1.0 Gbps';

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::RapidCity::MUNGE, %SNMP::Info::NortelStack::MUNGE,
    %SNMP::Info::SONMP::MUNGE,
);

sub os {
    my $baystack = shift;
    my $descr    = $baystack->description() || "";
    my $model    = $baystack->model() || "";

    if ( $descr =~ /Business Ethernet Switch.*SW:v/i ) {
        return 'bes';
    }
    if (   ( ( $model =~ /(420|425|BPS)/ ) and ( $descr =~ m/SW:v[1-2]/i ) )
        or ( ( $model =~ /(410|450|380)/ ) ) )
    {
        return 'baystack';
    }
    if ( $model =~ /VSP/ ) {
        return 'vsp';
    }

    return 'boss';
}

sub os_bin {
    my $baystack = shift;
    my $descr    = $baystack->description();
    return unless defined $descr;

    # 303 / 304
    if ( $descr =~ m/Rev: \d+\.(\d+\.\d+\.\d+)-\d+\.\d+\.\d+\.\d+/ ) {
        return $1;
    }

    # 450
    if ( $descr =~ m/FW:V(\d+\.\d+)/ ) {
        return $1;
    }

    if ( $descr =~ m/FW:(\d+\.\d+\.\d+\.\d+)/i ) {
        return $1;
    }
    return;
}

sub vendor {
    return 'avaya';
}

sub model {
    my $baystack = shift;
    my $id       = $baystack->id();
    return unless defined $id;
    my $model = &SNMP::translateObj($id);
    return $id unless defined $model;

    my $descr = $baystack->description();

    return '303' if ( defined $descr and $descr =~ /\D303\D/ );
    return '304' if ( defined $descr and $descr =~ /\D304\D/ );
    return 'BPS' if ( $model =~ /BPS2000/i );

    # Pull sreg- from all
    $model =~ s/^sreg-//;
    # Strip ES/ERS/BayStack etc. from those families
    $model =~ s/^(E(R)?S|BayStack|Ethernet(Routing)?Switch)-?//;
    $model =~ s/-ethSwitchNMM//;

    return $model;
}

sub interfaces {
    my $baystack = shift;
    my $partial  = shift;

    my $i_index      = $baystack->i_index($partial) || {};
    my $index_factor = $baystack->index_factor();
    my $slot_offset  = $baystack->slot_offset();

    my %if;
    foreach my $iid ( keys %$i_index ) {
        my $index = $i_index->{$iid};
        next unless defined $index;

        # Ignore cascade ports
        next if $index > $index_factor * 8;

        my $port = ( $index % $index_factor );
        my $slot = ( int( $index / $index_factor ) ) + $slot_offset;

        my $slotport = "$slot.$port";
        $if{$iid} = $slotport;
    }
    return \%if;
}

sub i_mac {
    my $baystack = shift;
    my $partial  = shift;

    my $i_mac = $baystack->orig_i_mac($partial) || {};

    my %i_mac;

    # Baystack 303's with a hw rev < 2.11.4.5 report the mac as all zeros
    foreach my $iid ( keys %$i_mac ) {
        my $mac = $i_mac->{$iid};
        next unless defined $mac;
        next if $mac eq '00:00:00:00:00:00';
        $i_mac{$iid} = $mac;
    }
    return \%i_mac;
}

sub i_name {
    my $baystack = shift;
    my $partial  = shift;

    my $i_index = $baystack->i_index($partial)     || {};
    my $i_alias = $baystack->i_alias($partial)     || {};
    my $i_name2 = $baystack->orig_i_name($partial) || {};

    my %i_name;
    foreach my $iid ( keys %$i_name2 ) {
        my $name  = $i_name2->{$iid};
        my $alias = $i_alias->{$iid};
        $i_name{$iid}
            = ( defined $alias and $alias !~ /^\s*$/ )
            ? $alias
            : $name;
    }

    return \%i_name;
}

sub index_factor {
    my $baystack = shift;
    my $model    = $baystack->model() || "";
    my $os       = $baystack->os();
    my $os_ver   = $baystack->os_ver();
    my $op_mode  = $baystack->ns_op_mode();

    $op_mode = 'pure' unless defined $op_mode;
    if ( $os_ver =~ m/^(\d+)\./ ) {
        $os_ver = $1;
    } else {
        $os_ver = 1;
    }

    my $index_factor = 32;
    $index_factor = 64
        if ( ( $model =~ /(470)/ )
        or ( $os =~ m/(boss|bes)/ ) and ( $op_mode eq 'pure' ) );
    $index_factor = 128
        if ( ( $model =~ /(5[56]\d\d)|VSP|4950|59100/ )
        and ( $os_ver >= 6 ) );

    return $index_factor;
}



# Newer devices support ENTITY-MIB, use if available otherwise use proprietary
# methods.

sub e_index {
    my $stack   = shift;
    my $partial = shift;

    return $stack->SUPER::e_index($partial) || $stack->ns_e_index($partial);
}

sub e_class {
    my $stack   = shift;
    my $partial = shift;

    return $stack->SUPER::e_class($partial) || $stack->ns_e_class($partial);
}

sub e_descr {
    my $stack   = shift;
    my $partial = shift;

    return $stack->SUPER::e_descr($partial) || $stack->ns_e_descr($partial);
}

sub e_name {
    my $stack   = shift;
    my $partial = shift;

    return $stack->SUPER::e_name($partial) || $stack->ns_e_name($partial);
}

sub e_fwver {
    my $stack   = shift;
    my $partial = shift;

    return $stack->SUPER::e_fwver($partial) || $stack->ns_e_fwver($partial);
}

sub e_hwver {
    my $stack   = shift;
    my $partial = shift;

    return $stack->SUPER::e_hwver($partial) || $stack->ns_e_hwver($partial);
}

sub e_parent {
    my $stack   = shift;
    my $partial = shift;

    return $stack->SUPER::e_parent($partial) || $stack->ns_e_parent($partial);
}

sub e_pos {
    my $stack   = shift;
    my $partial = shift;

    return $stack->SUPER::e_pos($partial) || $stack->ns_e_pos($partial);
}

sub e_serial {
    my $stack   = shift;
    my $partial = shift;

    return $stack->SUPER::e_serial($partial) || $stack->ns_e_serial($partial);
}

sub e_swver {
    my $stack   = shift;
    my $partial = shift;

    return $stack->SUPER::e_swver($partial) || $stack->ns_e_swver($partial);
}

sub e_type {
    my $stack   = shift;
    my $partial = shift;

    return $stack->SUPER::e_type($partial) || $stack->ns_e_type($partial);
}

sub e_vendor {
    my $stack   = shift;
    my $partial = shift;

    return $stack->SUPER::e_vendor($partial) || $stack->ns_e_vendor($partial);
}

# fix for stack of switches without POE on module 1
# https://sourceforge.net/tracker/?func=detail&aid=3317739&group_id=70362&atid=527529
sub peth_port_ifindex {
    my $stack = shift;
    my $partial = shift;

    my %peth_port_ifindex = ();
    my $poe_port_st = $stack->peth_port_status($partial);
    my $if_index = $stack->interfaces($partial);

    foreach my $i (keys %$if_index) {
        next unless defined $poe_port_st->{$if_index->{$i}};
        $peth_port_ifindex{$if_index->{$i}} = $i;
    }
    return \%peth_port_ifindex;
}

# Currently only ERS 4800 v5.8+ support the rcBridgeSpbmMacTable
# which holds the FDB for a SPBM edge deployment.
#
# Q-BRIDGE still holds some entries when the rcBridgeSpbmMacTable is in use
# so we merge hash entries.

sub fw_mac {
    my $rapidcity = shift;

    my $qb = $rapidcity->SUPER::fw_mac() || {};
    my $spbm = $rapidcity->rc_spbm_fw_mac() || {};
    my $fw_mac = { %$qb, %$spbm };

    return $fw_mac;
}

sub fw_port {
    my $rapidcity = shift;

    my $qb = $rapidcity->SUPER::fw_port() || {};
    my $spbm = $rapidcity->rc_spbm_fw_port() || {};
    my $fw_port = { %$qb, %$spbm };

    return $fw_port;
}

sub fw_status {
    my $rapidcity = shift;

    my $qb = $rapidcity->SUPER::fw_status() || {};
    my $spbm = $rapidcity->rc_spbm_fw_status() || {};
    my $fw_status = { %$qb, %$spbm };

    return $fw_status;
}

sub qb_fw_vlan {
    my $rapidcity = shift;

    my $qb = $rapidcity->SUPER::qb_fw_vlan() || {};
    my $spbm = $rapidcity->rc_spbm_fw_vlan() || {};
    my $qb_fw_vlan = { %$qb, %$spbm };

    return $qb_fw_vlan;
}

# Baystack uses S5-AGENT-MIB (loaded in NortelStack) versus RAPID-CITY
sub stp_ver {
    my $rapidcity = shift;

    return $rapidcity->s5AgSysSpanningTreeOperMode()
      || $rapidcity->SUPER::stp_ver();
}

1;

__END__

=head1 NAME

SNMP::Info::Layer2::Baystack - SNMP Interface to Avaya Ethernet Switch
(Baystack) and VSP 7000 series switches

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $baystack = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
  or die "Can't connect to DestHost.\n";

 my $class = $baystack->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from an
Avaya Ethernet Switch (formerly Nortel/Bay Baystack) and VSP 7000 series
through SNMP.

=head2 Inherited Classes

=over

=item SNMP::Info::SONMP

=item SNMP::Info::NortelStack

=item SNMP::Info::RapidCity

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<BAY-STACK-PETH-EXT-MIB>

=back

=head2 Inherited MIBs

See L<SNMP::Info::SONMP/"Required MIBs"> for its MIB requirements.

See L<SNMP::Info::NortelStack/"Required MIBs"> for its MIB requirements.

See L<SNMP::Info::RapidCity/"Required MIBs"> for its MIB requirements.

See L<SNMP::Info::Layer3/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $baystack->vendor()

Returns 'avaya'

=item $baystack->model()

Cross references $baystack->id() to the F<SYNOPTICS-MIB> and returns
the results.  303s and 304s have the same ID, so we have a hack
to return depending on which it is.

Returns BPS for Business Policy Switch

For others extracts and returns the switch numeric designation.

=item $baystack->os()

Returns 'baystack' or 'boss' depending on software version.

=item $baystack->os_bin()

Returns the firmware version extracted from C<sysDescr>.

=item $baystack->stp_ver()

Returns the particular STP version running on this device.

Values: C<nortelStpg>, C<pvst>, C<rstp>, C<mstp>, C<ieee8021d>

(C<s5AgSysSpanningTreeOperMode>)

=back

=head2 Overrides

=over

=item  $baystack->index_factor()

Required by SNMP::Info::SONMP.  Number representing the number of ports
reserved per slot within the device MIB.

Index factor on the Baystack switches are determined by the formula: Index
Factor = 64 if (model = 470 or (os eq 'boss' and operating in pure mode))
or else Index factor = 32.

Returns either 32 or 64 based upon the formula.

=back

=head2 Global Methods imported from SNMP::Info::SONMP

See L<SNMP::Info::SONMP/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::NortelStack

See L<SNMP::Info::NortelStack/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::RapidCity

See L<SNMP::Info::RapidCity/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $baystack->interfaces()

Returns reference to the map between IID and physical Port.

  Slot and port numbers on the Baystack switches are determined by the
  formula:

  port = (Interface index % Index factor)
  slot = (int(Interface index / Index factor)) + Slot offset

  The physical port name is returned as slot.port.

=item $baystack->i_ignore()

Returns reference to hash of IIDs to ignore.

=item $baystack->i_mac()

Returns the C<ifPhysAddress> table entries.

Removes all entries matching '00:00:00:00:00:00' -- Certain
revisions of Baystack firmware report all zeros for each port mac.

=item $baystack->i_name()

Crosses C<ifName> with C<ifAlias> and returns the human set port name if
exists.

=item $baystack->peth_port_ifindex()

Maps the C<pethPsePortTable> to C<ifIndex> by way of the F<ENTITY-MIB>.

=item $baystack->peth_port_power()

Power supplied by PoE ports, in milliwatts

(C<bspePethPsePortExtMeasuredPower>)

=back

=head2 F<ENTITY-MIB> Information

For older devices which do not support F<ENTITY-MIB>, these methods emulate
Physical Table methods using F<S5-CHASSIS-MIB>.  See
L<SNMP::Info::NortelStack/"TABLE METHODS"> for details on ns_e_* methods.

=over

=item $baystack->e_index()

If the device doesn't support C<entPhysicalDescr>, this will try ns_e_index().
Note that this is based on C<entPhysicalDescr> due to implementation
details of SNMP::Info::Entity::e_index().

=item $baystack->e_class()

If the device doesn't support C<entPhysicalClass>, this will try ns_e_class().

=item $baystack->e_descr()

If the device doesn't support C<entPhysicalDescr>, this will try ns_e_descr().

=item $baystack->e_name()

If the device doesn't support C<entPhysicalName>, this will try ns_e_name().

=item $baystack->e_fwver()

If the device doesn't support C<entPhysicalFirmwareRev>, this will try
ns_e_fwver().

=item $baystack->e_hwver()

If the device doesn't support C<entPhysicalHardwareRev>, this will try
ns_e_hwver().

=item $baystack->e_parent()

If the device doesn't support C<entPhysicalContainedIn>, this will try
ns_e_parent().

=item $baystack->e_pos()

If the device doesn't support C<entPhysicalParentRelPos>, this will try
ns_e_pos().

=item $baystack->e_serial()

If the device doesn't support C<entPhysicalSerialNum>, this will try
ns_e_serial().

=item $baystack->e_swver()

If the device doesn't support C<entPhysicalSoftwareRev>, this will try
ns_e_swver().

=item $baystack->e_type()

If the device doesn't support C<entPhysicalVendorType>, this will try
ns_e_type().

=item $baystack->e_vendor()

If the device doesn't support C<entPhysicalMfgName>, this will try
ns_e_vendor().

=back

=head2 Layer 2 Forwarding Database

These methods try to obtain the layer 2 forwarding database entries via the
normal bridge methods as well as SPBM entries via rapid city methods.

=over

=item $baystack->fw_mac()

Returns reference to hash of forwarding table MAC Addresses

=item $baystack->fw_port()

Returns reference to hash of forwarding table entries port interface
identifier (iid)

=item $baystack->qb_fw_vlan()

Returns reference to hash of forwarding table entries VLAN ID

=item $baystack->fw_status()

Returns reference to hash of forwarding table entries status

=back

=head2 Table Methods imported from SNMP::Info::SONMP

See L<SNMP::Info::SONMP/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::NortelStack

See L<SNMP::Info::NortelStack/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::RapidCity

See L<SNMP::Info::RapidCity/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
