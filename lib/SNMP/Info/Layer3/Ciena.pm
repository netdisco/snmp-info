# SNMP::Info::Layer3::Ciena - SNMP Interface to Ciena Devices
#
# Copyright (c) 2019 by The Netdisco Developer Team.
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


package SNMP::Info::Layer3::Ciena;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Ciena::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Ciena::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.71';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'WWP-LEOS-SW-XGRADE-MIB' => 'wwpLeosBladeRunPackageVer',
    'WWP-LEOS-BLADE-MIB'     => 'wwpLeosBladeId',
    'WWP-LEOS-CHASSIS-MIB'   => 'wwpLeosChassisDeviceId',
    'WWP-LEOS-FLOW-MIB'      => 'wwpLeosFlowLearnType',
    'WWP-LEOS-PORT-MIB'      => 'wwpLeosEtherIngressPvid',
    'WWP-LEOS-VLAN-TAG-MIB'  => 'wwpLeosNumVlans',
    'WWP-PRODUCTS-MIB'       => 'wwpProductsMIB'
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'ciena_serial' => 'wwpLeosSystemSerialNumber',
    'mac'          => 'dot1dBaseBridgeAddress'
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    'v_name'     => 'wwpLeosVlanName',
    'ps_type'    => 'wwpLeosChassisPowerSupplyType',
    'ps_status'  => 'wwpLeosChassisPowerSupplyState',
    'ps_name'    => 'wwpLeosChassisPowerSupplyModuleLabel',
    'fan_type'   => 'wwpLeosChassisFanModuleType',
    'fan_status' => 'wwpLeosChassisFanModuleStatus',
    'fan_name'   => 'wwpLeosChassisFanModuleNum'
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE
);

sub vendor {
    return 'ciena';
}

sub os {
    return 'saos';
}

sub os_ver {
    my $ciena = shift;
    my $version = $ciena->wwpLeosBladeRunPackageVer || {};
    return values(%$version);
}

sub serial {
    my $ciena = shift;
    return $ciena->ciena_serial();
}

# Override lldp_if function to translate the port with bp_index
sub lldp_if {
    my $ciena = shift;
    my $lldp = $ciena->SUPER::lldp_if;
    my $bp_index = $ciena->bp_index;
    foreach my $iface (keys %$lldp) {
        my $orig_iface = $lldp->{$iface};
        $lldp->{$iface} = $bp_index->{$orig_iface};
    }
    return $lldp;
}

sub i_vlan {
    my $ciena = shift;
    my $i_vlan = {};
    my $pvid = $ciena->wwpLeosEtherIngressPvid() || undef;

    # bp_index needed to resolve correct port id
    my $bp_index = $ciena->bp_index;
    if (defined $pvid) {
        foreach my $i (keys %$pvid) {
            $i_vlan->{$bp_index->{$i}} = $pvid->{$i};
        }
    }
    return $i_vlan;
}

sub i_vlan_membership {
    my $ciena = shift;
    my $i_vlan_membership = {};

    my $vlans = $ciena->wwpLeosVlanMemberPortId();
    # bp_index needed to resolve correct port id
    my $bp_index = $ciena->bp_index;
    foreach my $vlan (keys %$vlans) {
        push @{$i_vlan_membership->{$bp_index->{$vlans->{$vlan}}}} , (split(/\./,$vlan))[0];
    }
    return $i_vlan_membership;
}

sub qb_fw_vlan {
    my $ciena = shift;
    my $qb_fw_vlan = {};
    my $learn_entries = $ciena->wwpLeosFlowLearnType();
    foreach my $entry (keys %$learn_entries) {
        my @params = (split(/\./, $entry));
        $qb_fw_vlan->{join('.', @params[1..6])} = $params[8];
    }
    return $qb_fw_vlan;
}

sub fan {
    my $ciena = shift;

    my $fan_status = $ciena->fan_status || {};
    my $fan_type = $ciena->fan_type;
    my $fan_name = $ciena->fan_name;
    my @messages;

    foreach my $fan (keys %$fan_status) {
        if ($fan_status->{$fan} ne "ok") {
            push @messages, sprintf("%s fan %s failed.", $fan_type->{$fan}, $fan_name->{$fan});
        }
    }
    return sprintf("%s fans OK", scalar keys %$fan_status) if scalar @messages  == 0;

    return join(", ", @messages);
}
sub ps1_type {
    my $ciena = shift;
    my $ps_type = $ciena->ps_type;
    return $ps_type->{'1'} if defined $ps_type->{'1'};
}

sub ps1_status {
    my $ciena = shift;
    my $ps_status = $ciena->ps_status;
    return $ps_status->{'1'} if defined $ps_status->{'1'};
}
sub ps2_type {
    my $ciena = shift;
    my $ps_type = $ciena->ps_type;
    return $ps_type->{'2'} if defined $ps_type->{'2'};
}

sub ps2_status {
    my $ciena = shift;
    my $ps_status = $ciena->ps_status;
    return $ps_status->{'2'} if defined $ps_status->{'2'};
}
=head1 DESCRIPTION
Subclass for Ciena Devices running SAOS

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<WWP-LEOS-SW-XGRADE-MIB>

=item F<WWP-LEOS-BLADE-MIB>

=item F<WWP-LEOS-CHASSIS-MIB>

=item F<WWP-LEOS-FLOW-MIB>

=item F<WWP-LEOS-PORT-MIB>

=item F<WWP-LEOS-VLAN-TAG-MIB>

=item F<WWP-PRODUCTS-MIB>

=back

=head2 Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $ciena->vendor()

Returns 'ciena'

=item $ciena->os()

Returns 'saos'

=item $ciena->os_ver()

Returns the running software package extracted with C<wwpLeosBladeRunPackageVer>

=item $ciena->serial()

Returns serial number
(C<wwpLeosSystemSerialNumber>)

=item $ciena->mac()

Returns the MAC address used by this bridge when it must be referred
to in a unique fashion.

(C<dot1dBaseBridgeAddress>)

=item $huawei->fan()

Return the status of all fans. Returns a string indicating the number of fans 'OK'  or
identification of any fan without a 'normal' operating status.

=item $ciena->ps1_status()

Return the status of the first power supply

=item $ciena->ps1_type()

Return the type of the first power supply

=item $ciena->ps2_status()

Return the status of the second power supply

=item $ciena->ps2_type()

Return the type of the second power supply

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $ciena->lldp_if()

Returns the mapping to the SNMP Interface Table. Overridden to translate to correct ethernet port with bp_index

=item $ciena->i_vlan()

Returns a mapping between C<ifIndex> and the PVID or default VLAN.

=item $ciena->i_vlan_membership()

Returns reference to hash of arrays: key = C<ifIndex>, value = array of VLAN
IDs.

=item $ciena->qb_fw_vlan()

Returns reference to hash of forwarding table entries VLAN ID, using C<wwpLeosFlowLearnType>

=item $ciena->ps_name()

Returns reference to hash of the power supplies and their names.

=item $ciena->ps_type()

Returns reference to hash of the power supplies and their type (ex. AC, DC, etc.)

=item $ciena->ps_status()

Returns reference to hash of the power supplies and their status.

=item $ciena->fan_name()

Returns reference to hash of fans and their names. In this case, it is simply a number.

=item $ciena->fan_type()

Returns reference to hash of fans and their types (ex. fixed, modular, etc.)

=item $ciena->fan_status)

Returns reference to hash of fans and their status

=back
