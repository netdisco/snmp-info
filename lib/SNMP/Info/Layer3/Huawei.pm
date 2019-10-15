# SNMP::Info::Layer3::Huawei
#
# Copyright (c) 2018 Jeroen van Ingen and Eric Miller
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

package SNMP::Info::Layer3::Huawei;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::IEEE802dot3ad;

@SNMP::Info::Layer3::Huawei::ISA = qw/
    SNMP::Info::IEEE802dot3ad
    SNMP::Info::Layer3
    Exporter
    /;
@SNMP::Info::Layer3::Huawei::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.70';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::IEEE802dot3ad::MIBS,
    'HUAWEI-MIB'               => 'quidway',
    'HUAWEI-PORT-MIB'          => 'hwEthernetDuplex',
    'HUAWEI-IF-EXT-MIB'        => 'hwTrunkIfIndex',
    'HUAWEI-L2IF-MIB'          => 'hwL2IfPortIfIndex',
    'HUAWEI-POE-MIB'           => 'hwPoePower',
    'HUAWEI-ENTITY-EXTENT-MIB' => 'hwEntityFanState',
);

%GLOBALS = ( %SNMP::Info::Layer3::GLOBALS, );

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::IEEE802dot3ad::FUNCS,

    # HUAWEI-PORT-MIB::hwEthernetTable
    'hw_eth_speed_admin' => 'hwEthernetSpeedSet',
    'hw_eth_duplex'      => 'hwEthernetDuplex',
    'hw_eth_auto'        => 'hwEthernetNegotiation',
    'hw_eth_frame_len'   => 'hwEthernetJumboframeMaxLength',

    # HUAWEI-PORT-MIB::hwPhysicalPortTable
    'hw_phy_port_slot' => 'hwPhysicalPortInSlot',

    # HUAWEI-IF-EXT-MIB::hwTrunkIfTable
    'hw_trunk_if_idx' => 'hwTrunkIfIndex',
    'hw_trunk_entry'  => 'hwTrunkValidEntry',

    # HUAWEI-L2IF-MIB::hwL2IfTable
    'hw_l2if_port_idx' => 'hwL2IfPortIfIndex',

    # HUAWEI-POE-MIB::hwPoePortTable
    'hw_peth_port_admin'  => 'hwPoePortEnable',
    'hw_peth_port_status' => 'hwPoePortPowerStatus',
    'hw_peth_port_class'  => 'hwPoePortPdClass',
    'hw_peth_port_power'  => 'hwPoePortConsumingPower',

    # HUAWEI-POE-MIB::hwPoeSlotTable
    'peth_power_watts'       => 'hwPoeSlotMaximumPower',
    'peth_power_consumption' => 'hwPoeSlotConsumingPower',
    'peth_power_threshold'   => 'hwPoeSlotPowerUtilizationThreshold',

    # HUAWEI-ENTITY-EXTENT-MIB::hwFanStatusTable
    'hw_fan_state' => 'hwEntityFanState',
    'hw_fan_descr' => 'hwEntityFanDesc',

    # HUAWEI-ENTITY-EXTENT-MIB::hwPwrStatusTable
    'hw_pwr_state' => 'hwEntityPwrState',
    'hw_pwr_descr' => 'hwEntityPwrDesc',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::IEEE802dot3ad::MUNGE,
    'hw_peth_port_admin' => \&SNMP::Info::Layer3::Huawei::munge_hw_peth_admin,
    'peth_power_watts'   => \&SNMP::Info::Layer3::Huawei::munge_hw_peth_power,
    'peth_power_consumption' =>
        \&SNMP::Info::Layer3::Huawei::munge_hw_peth_power,
    'hw_peth_port_status' =>
        \&SNMP::Info::Layer3::Huawei::munge_hw_peth_status,
    'hw_peth_port_class' => \&SNMP::Info::Layer3::Huawei::munge_hw_peth_class,
);

sub vendor {
    return "huawei";
}

sub os {
    my $huawei = shift;
    my $descr  = $huawei->description();

    if ( defined ($descr) && $descr =~ /\b(VRP)\b/ ) {
        return $1;
    }
    return "huawei";
}

sub os_ver {
    my $huawei = shift;

    my $entity_os = $huawei->entity_derived_os_ver();
    if ( defined $entity_os and $entity_os !~ /^\s*$/ ) {
        return $entity_os;
    }

    my $descr  = $huawei->description();
    my $os_ver = undef;

    if (defined ($descr) && $descr =~ /Version\s            # Start match on Version string
                   ([\d\.]+)            # Capture the primary version in 1
                   ,?                   # There may be a comma
                   \s                   # Always a space
                   (?:Release|Feature)? # Don't capture stanza if present
                   (?:\(\w+)?           # If paren & model don't capture
                   \s                   # Always a space
                   (\w+)                # If 2nd part of version capture in 2
                   /xi
        )
    {
        $os_ver = $2 ? "$1 $2" : $1;
    }

    return $os_ver;
}

sub mac {
    my $huawei  = shift;

    return $huawei->b_mac();
}

sub i_ignore {
    my $huawei  = shift;
    my $partial = shift;

    my $interfaces = $huawei->interfaces($partial) || {};

    my %i_ignore;
    foreach my $if ( keys %$interfaces ) {

        # lo0 etc
        if ( $interfaces->{$if} =~ /\b(inloopback|console)\d*\b/ix ) {
            $i_ignore{$if}++;
        }
    }
    return \%i_ignore;
}

sub bp_index {
    my $huawei = shift;

    my $hw_index = $huawei->hw_l2if_port_idx();
    return $hw_index
        if ( ref {} eq ref $hw_index and scalar keys %$hw_index );

    return $huawei->SUPER::bp_index();
}

sub i_duplex {
    my $huawei  = shift;
    my $partial = shift;

    my $hw_duplex = $huawei->hw_eth_duplex($partial);
    return $hw_duplex
        if ( ref {} eq ref $hw_duplex and scalar keys %$hw_duplex );

    return $huawei->SUPER::i_duplex($partial);
}

sub i_duplex_admin {
    my $huawei  = shift;
    my $partial = shift;

    my $hw_duplex_admin = $huawei->hw_eth_duplex($partial) || {};
    my $hw_auto         = $huawei->hw_eth_auto($partial)   || {};

    my %i_duplex_admin;
    foreach my $if ( keys %$hw_duplex_admin ) {
        my $duplex = $hw_duplex_admin->{$if};
        next unless defined $duplex;
        my $auto = $hw_auto->{$if} || 'disabled';

        my $string = 'other';
        $string = 'half' if ( $duplex =~ /half/i and $auto =~ /disabled/i );
        $string = 'full' if ( $duplex =~ /full/i and $auto =~ /disabled/i );
        $string = 'auto' if $auto =~ /enabled/i;

        $i_duplex_admin{$if} = $string;
    }
    return \%i_duplex_admin;
}

sub agg_ports {
    my $huawei = shift;

    # First use proprietary MIB for broader implementation across
    # devices type / os and no xref of hwL2IfPortIfIndex
    my $masters = $huawei->hw_trunk_if_idx();
    my $slaves  = $huawei->hw_trunk_entry();

    my $ret = {};

    if (    ref {} eq ref $masters
        and scalar keys %$masters
        and ref {} eq ref $slaves
        and scalar keys %$slaves )
    {
        foreach my $s ( keys %$slaves ) {
            next if $slaves->{$s} ne 'valid';
            my ( $trunk, $sl_idx ) = split( /\./, $s );
            foreach my $m ( keys %$masters ) {
                next unless $m == $trunk;
                next unless defined $masters->{$m};
                $ret->{$sl_idx} = $masters->{$m};
                last;
            }
        }
        return $ret;
    }

    # If for some reason we don't get the info, try IEEE8023-LAG-MIB
    return $huawei->agg_ports_lag();
}

# The standard IEEE 802.af POWER-ETHERNET-MIB has an index of module.port
# The HUAWEI-POE-MIB only indexes by ifIndex, we need to match the standard
# for so method calls across classes work the same
#
sub peth_port_ifindex {
    my $huawei = shift;

    my $peth_port_status = $huawei->hw_peth_port_status() || {};
    my $peth_port_slot   = $huawei->hw_phy_port_slot()    || {};
    my $i_descr          = $huawei->i_description()       || {};

    my $peth_port_ifindex = {};

    foreach my $i ( keys %$peth_port_status ) {
        my $slot = 0;
        if ( exists $peth_port_slot->{$i}
            && defined $peth_port_slot->{$i} )
        {
            $slot = $peth_port_slot->{$i};
        }
        elsif ( exists $i_descr->{$i}
            && $i_descr->{$i} =~ /(\d+)(?:\/\d+){2,3}$/x )
        {
            $slot = $1;
        }
        $peth_port_ifindex->{"$slot.$i"} = $i;
    }
    return $peth_port_ifindex;
}

sub peth_port_admin {
    my $huawei = shift;

    my $port_admin   = $huawei->hw_peth_port_admin() || {};
    my $port_ifindex = $huawei->peth_port_ifindex()  || {};

    my $peth_port_admin = {};

    foreach my $idx ( keys %$port_ifindex ) {
        my $ifindex = $port_ifindex->{$idx};
        my $admin   = $port_admin->{$ifindex};
        next unless $admin;

        $peth_port_admin->{$idx} = $admin;
    }
    return $peth_port_admin;
}

sub peth_port_status {
    my $huawei = shift;

    my $port_status  = $huawei->hw_peth_port_status() || {};
    my $port_ifindex = $huawei->peth_port_ifindex()   || {};

    my $peth_port_status = {};

    foreach my $idx ( keys %$port_ifindex ) {
        my $ifindex = $port_ifindex->{$idx};
        my $status  = $port_status->{$ifindex};
        next unless $status;

        $peth_port_status->{$idx} = $status;
    }
    return $peth_port_status;
}

sub peth_port_class {
    my $huawei = shift;

    my $port_class   = $huawei->hw_peth_port_class() || {};
    my $port_ifindex = $huawei->peth_port_ifindex()  || {};

    my $peth_port_class = {};

    foreach my $idx ( keys %$port_ifindex ) {
        my $ifindex = $port_ifindex->{$idx};
        my $class   = $port_class->{$ifindex};
        next unless $class;

        $peth_port_class->{$idx} = $class;
    }
    return $peth_port_class;
}

sub peth_port_power {
    my $huawei = shift;

    my $port_power   = $huawei->hw_peth_port_power() || {};
    my $port_ifindex = $huawei->peth_port_ifindex()  || {};

    my $peth_port_power = {};

    foreach my $idx ( keys %$port_ifindex ) {
        my $ifindex = $port_ifindex->{$idx};
        my $power   = $port_power->{$ifindex};
        next unless defined $power;

        $peth_port_power->{$idx} = $power;
    }
    return $peth_port_power;
}

sub peth_port_neg_power {
    my $huawei = shift;

    my $peth_port_status = $huawei->peth_port_status()  || {};
    my $peth_port_class  = $huawei->peth_port_class()   || {};
    my $port_ifindex     = $huawei->peth_port_ifindex() || {};

    my $huaweimax = {
        'class0' => 12950,
        'class1' => 3840,
        'class2' => 6490,
        'class3' => 12950,
        'class4' => 25500
    };

    my $peth_port_neg_power = {};

    foreach my $idx ( keys %$port_ifindex ) {
        if ( $peth_port_status->{$idx} eq 'deliveringPower' ) {
            $peth_port_neg_power->{$idx}
                = $huaweimax->{ $peth_port_class->{$idx} };
        }
    }
    return $peth_port_neg_power;
}

sub fan {
    my $huawei = shift;

    my $fan   = $huawei->hw_fan_descr() || {};
    my $state = $huawei->hw_fan_state() || {};

    if ( scalar keys %$state ) {
        my @messages = ();

        foreach my $k ( keys %$state ) {
            next if $state->{$k} and $state->{$k} eq 'normal';
            my ($slot, $num) = split(/\./, $k);
            my $descr = "Slot $slot,Fan $num";
            $descr = $fan->{$k} if ($fan->{$k});

            push @messages, "$descr: $state->{$k}";
        }

        push @messages, ( ( scalar keys %$state ) . " fans OK" )
            if scalar @messages == 0;

        return ( join ", ", @messages );
    }
    return;
}

sub ps1_status {
    my $huawei = shift;

    my $pwr_state = $huawei->hw_pwr_state() || {};
    my $pwr_descr = $huawei->hw_pwr_descr() || {};

    my $ret = "";
    my $s   = "";
    foreach my $i ( sort keys %$pwr_state ) {
        my ( $slot, $num ) = split( /\./, $i );
        next unless $num == 1;
        my $descr = "Slot $slot,PS $num";
        $descr = $pwr_descr->{$i} if ($pwr_descr->{$i});

        $ret .= $s . $descr . ": " . $pwr_state->{$i};
        $s = ", ";
    }
    return if ( $s eq "" );
    return $ret;
}

sub ps2_status {
    my $huawei = shift;

    my $pwr_state = $huawei->hw_pwr_state() || {};
    my $pwr_descr = $huawei->hw_pwr_descr() || {};

    my $ret = "";
    my $s   = "";
    foreach my $i ( sort keys %$pwr_state ) {
        my ( $slot, $num ) = split( /\./, $i );
        next unless $num == 2;
        my $descr = "Slot $slot,PS $num";
        $descr = $pwr_descr->{$i} if ($pwr_descr->{$i});

        $ret .= $s . $descr . ": " . $pwr_state->{$i};
        $s = ", ";
    }
    return if ( $s eq "" );
    return $ret;
}

sub i_mtu {
    my $huawei = shift;

    my $mtus   = $huawei->SUPER::i_mtu()     || {};
    my $frames = $huawei->hw_eth_frame_len() || {};

    foreach my $idx ( keys %$mtus ) {
        my $frame_sz = $frames->{$idx};
        next unless $frame_sz;

        $mtus->{$idx} = $frame_sz;
    }
    return $mtus;
}

sub munge_hw_peth_admin {
    my $admin = shift;

    $admin =~ s/enabled/true/;
    $admin =~ s/disabled/false/;
    return $admin;
}

sub munge_hw_peth_power {
    my $pwr = shift;

    $pwr = $pwr / 1000;
    return sprintf( "%.0f", $pwr );
}

sub munge_hw_peth_class {
    my $pwr = shift;

    return "class$pwr";
}

# The values are from the MIB reference guide
sub munge_hw_peth_status {
    my $pwr = shift;

    # The status is an octet string rather than enum
    # so use regex rather than hash lookup
    $pwr = 'disabled'        if $pwr =~ /Disabled/i;
    $pwr = 'searching'       if $pwr =~ /(Powering|Power-ready|Detecting)/ix;
    $pwr = 'deliveringPower' if $pwr =~ /Powered/i;
    $pwr = 'fault'           if $pwr =~ /fault/i;

    return $pwr;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer3::Huawei - SNMP Interface to Huawei switches and routers.

=head1 AUTHORS

Jeroen van Ingen and Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $huawei = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $huawei->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Huawei switches

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::IEEE802dot3ad

=back

=head2 Required MIBs

=over

=item F<HUAWEI-MIB>

=item F<HUAWEI-PORT-MIB>

=item F<HUAWEI-IF-EXT-MIB>

=item F<HUAWEI-L2IF-MIB>

=item F<HUAWEI-POE-MIB>

=item F<HUAWEI-ENTITY-EXTENT-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

See L<SNMP::Info::IEEE802dot3ad> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $huawei->vendor()

Returns 'huawei'.

=item $huawei->os()

Returns 'VRP' if contained in C<sysDescr>, 'huawei' otherwise.

=item $huawei->os_ver()

Returns the software version derived from the C<ENTITY-MIB> or
extracted from C<sysDescr>.

=item $huawei->mac()

Base MAC of the device.

(C<dot1dBaseBridgeAddress>)

=item $huawei->fan()

Return the status of all fans from the F<HUAWEI-ENTITY-EXTENT-MIB>. Returns
a string indicating the number of fans 'OK' or identification of any fan without
a 'normal' operating status

=item $huawei->ps1_status()

Return the status of the first power supply in each chassis or switch from
the F<HUAWEI-ENTITY-EXTENT-MIB>

=item $huawei->ps2_status()

Return the status of the second power supply in each chassis or switch from
the F<HUAWEI-ENTITY-EXTENT-MIB>

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $huawei->i_duplex()

Returns reference to map of IIDs to current link duplex.

=item $huawei->i_duplex_admin()

Returns reference to hash of IIDs to admin duplex setting.

=back

=head2 POE Slot Table

=over

=item $huawei->peth_power_watts()

The slot's power supply's capacity, in watts.

C<hwPoeSlotMaximumPower>

=item $huawei->peth_power_consumption()

How much power, in watts, this power supply has been committed to
deliver.

C<hwPoeSlotConsumingPower>

=item $huawei->peth_power_threshold()

The threshold (in percent) of consumption required to raise an
alarm.

C<hwPoeSlotPowerUtilizationThreshold>

=back

=head2 Overrides

=over

=item $huawei->i_ignore()

Returns reference to hash.  Increments value of IID if port is to be ignored.

Ignores InLoopback and Console interfaces

=item $huawei->bp_index()

Returns a mapping between C<ifIndex> and the Bridge Table. Uses
C<hwL2IfPortIfIndex> for the most complete mapping and falls back to
C<dot1dBasePortIfIndex> if not available.

=item C<agg_ports>

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports. Attempts to use C<hwTrunkIfTable>
first and then C<dot3adAggPortListPorts> if that is unavailable.

=item C<i_mtu>

Interface MTU value. Overridden with corresponding frame size entry from
C<hwEthernetJumboframeMaxLength> if one exists.

=back

=head2 Power Port Table

The index of these methods have been normalized to slot.port and values
munged to provide compatibility with the IEEE 802.3af F<POWER-ETHERNET-MIB>
and equivalent L<SNMP::Info::PowerEthernet> methods.

=over

=item $huawei->peth_port_admin()

Administrative status: is this port permitted to deliver power?

=item $huawei->peth_port_status()

Current status: is this port delivering power, searching, disabled, etc?

=item $huawei->peth_port_class()

Device class: if status is delivering power, this represents the 802.3af
class of the device being powered.

=item $huawei->peth_port_power()

Power supplied the port, in milliwatts

=item $huawei->peth_port_ifindex()

Returns an index of slot.port to an C<ifIndex>. Slot defaults to zero
meaning chassis or box if there is no C<ifIndex> to slot mapping available in
C<hwPhysicalPortInSlot>. Mapping the index to slot.port is a normalization
function to provide compatibility with the IEEE 802.3af F<POWER-ETHERNET-MIB>.

=item $huawei->peth_port_neg_power()

The power, in milliwatts, that has been committed to this port.
This value is derived from the 802.3af class of the device being
powered.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Table Methods imported from SNMP::Info::IEEE802dot3ad

See documentation in L<SNMP::Info::IEEE802dot3ad> for details.

=head1 Data Munging Callback Subroutines

=over

=item $huawei->munge_hw_peth_admin()

Normalizes C<hwPoePortEnable> values to 'true' or 'false'.

=item $huawei->munge_hw_peth_class()

Normalizes C<hwPoePortPdClass> values by prepending 'class'.

=item $huawei->munge_hw_peth_power()

Converts and rounds to a whole number milliwatts to watts.

=item $huawei->munge_hw_peth_status()

Normalizes C<hwPoePortPowerStatus> values to those that would be returned by
the the IEEE 802.3af F<POWER-ETHERNET-MIB>.

=back

=cut
