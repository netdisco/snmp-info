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

$VERSION = '3.68';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'WWP-LEOS-SW-XGRADE-MIB'    => 'wwpLeosBladeRunPackageVer',
    'WWP-LEOS-BLADE-MIB'        => 'wwpLeosBladeId',
    'WWP-LEOS-CHASSIS-MIB'      => 'wwpLeosChassisDeviceId',
    'WWP-LEOS-FLOW-MIB'         => 'wwpLeosFlowLearnType',
    'WWP-LEOS-PORT-MIB'         => 'wwpLeosEtherIngressPvid',
    'WWP-LEOS-VLAN-TAG-MIB'     => 'wwpLeosNumVlans'
);

%GLOBALS = (
    'serial'    => 'wwpLeosSystemSerialNumber',
    'mac'       => 'wwpLeosChassisMacAddress',
    'box_descr' => 'wwpLeosPhyBladeBoardDesc',
    'version'   => 'wwpLeosBladeRunPackageVer'
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    'v_name'    => 'wwpLeosVlanName'
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE
);

sub vendor {
    return 'ciena';
}

sub os {
    return 'SAOS';
}

use Data::Dumper;
sub os_ver {
    my $ciena = shift;
    my $version = $ciena->wwpLeosBladeRunPackageVer || {};
    return values(%$version);
}

sub i_vlan {
    my $ciena = shift;
    my $i_vlan = {};
    my $pvid = $ciena->wwpLeosEtherIngressPvid() || undef;

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
