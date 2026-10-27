# Test::SNMP::Info::Layer3::CiscoSwitch
#
# Copyright (c) 2018 Eric Miller
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

package Test::SNMP::Info::Layer3::CiscoSwitch;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::CiscoSwitch;
use Test::SNMP::Info::CiscoStpExtensions;

# This class is a collection of roles and not meant to instantiated for a
# specific device. Don't test device class and no need to setup data
sub device_type : Tests(1) {
  my $test  = shift;
  my $class = $test->class;

  can_ok($test->{info}, 'device_type');

}

sub cisco_comm_indexing : Tests(3) {
  my $test = shift;

  can_ok $test->{info}, 'cisco_comm_indexing';
  is($test->{info}->cisco_comm_indexing(), 1, 'Cisco community indexing on');
  cmp_deeply($test->{info}->context_kinds('fdb'), ['vlan'],
    'FDB in VLAN contexts');
}

sub context_kinds__vrf__nothing : Tests(1) {
  my $test = shift;

  is($test->{info}->context_kinds('vrf'), undef,
    'Attribution devices have no VRF contexts');
}

sub snmp_context__vrf__nothing : Tests(1) {
  my $test = shift;

  is($test->{info}->snmp_context('vrf', 'red'), undef,
    'No VRF context to switch to');
}

sub stp_trees : Tests(6) {
  my $test = shift;
  my $info = $test->{info};

  my $cache = Test::SNMP::Info::CiscoStpExtensions::_iol_pvst_cache(
    'rapidPvstPlus');
  $cache->{_description} = 'Cisco IOS Software [IOSXE], Linux Software'
    . ' (X86_64BI_LINUX_L2-ADVENTERPRISEK9-M), Version 17.18.2';
  $info->cache($cache);
  my @measured = map { $_->{measured} } values %{$info->stp_trees()};
  cmp_deeply(\@measured, [1, 1, 1], 'IOS XE trees are measured');
  cmp_deeply($info->stp_trees()->{'vlan.10'}{contexts},
    [{kind => 'vlan', id => 10, v2c => '%s@10', v3 => 'vlan-10'}],
    'The mixin names the VLAN context through the device class');

  $cache->{_bp_index} = 1;
  $cache->{store}{bp_index} = {4 => 4};
  $cache->{store}{stpx_rstp_port_role}{'1.4'} = 'backUp';
  $info->cache($cache);
  my $backup = $info->stp_tree_ports('vlan.1')->{4};
  cmp_deeply([@{$backup}{qw/role role_raw/}], ['backup', 'backUp'],
    'The merged munge normalizes backUp, the raw value is kept');

  $info->clear_cache();
  $cache->{_description} = 'Cisco Systems WS-C5505 Cisco Catalyst Operating'
    . ' System Software';
  $info->cache($cache);
  @measured = map { $_->{measured} } values %{$info->stp_trees()};
  cmp_deeply(\@measured, [0, 0, 0], 'CatOS trees are not measured');

  # Neither per-port table served: stpxPVSTVlanEnable, Ethernet VLANs only
  $info->clear_cache();
  delete $cache->{$_}, delete $cache->{store}{substr $_, 1}
    for qw/_stpx_faststart_oper _stpx_rstp_port_role/;
  $info->cache($cache);
  cmp_deeply(
    [sort { $a <=> $b } map { $_->{id} } values %{$info->stp_trees()}],
    [1, 10, 20, 1002 .. 1005], 'No VTP types: every enabled VLAN');

  $info->clear_cache();
  $cache->{_v_type} = 1;
  $cache->{store}{v_type} = {
    '1.1'    => 'ethernet',  '1.10'   => 'ethernet', '1.20' => 'ethernet',
    '1.1002' => 'fddi',      '1.1003' => 'tokenRing',
    '1.1004' => 'fddiNet',   '1.1005' => 'trNet',
  };
  $info->cache($cache);
  cmp_deeply([sort keys %{$info->stp_trees()}],
    [qw/vlan.1 vlan.10 vlan.20/], 'VTP defaults 1002 to 1005 dropped');
}

# An IOS-XE device detects as this class, so the VRF role must reach it
# through Layer3. mplsL3VpnVrfTable as such a device serves it, with one VRF.
sub vrf_instances__through_layer3__resolves : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  ok($info->can('vrf_instances'), q(vrf_instances resolves));
  is($info->funcs()->{vrf_l3vpn_rd}, 'mplsL3VpnVrfRD',
    q(The role's table methods are merged into the class));

  my $red = '3.114.101.100';
  $info->{"_$_"} = 1 for qw/vrf_l3vpn_rd vrf_l3vpn_descr vrf_l3vpn_oper
    vrf_l3vpn_rt vrf_l3vpn_if/;
  $info->{store}{vrf_l3vpn_rd}    = {$red => '64512:30'};
  $info->{store}{vrf_l3vpn_descr} = {$red => q{}};
  $info->{store}{vrf_l3vpn_oper}  = {$red => 'up'};
  $info->{store}{vrf_l3vpn_rt}    = {};
  $info->{store}{vrf_l3vpn_if}    = {"$red.2" => 'active'};
  cmp_deeply([sort keys %{$info->vrf_instances()}], ['default', 'red'],
    q(The served VRF and default are listed));
}

# A device that serves only the atTable: ipNetToMediaTable is left
# unprimed, so the mock serves none and Layer3's at_paddr falls back to
# old_at_paddr, whose walk is recorded under its own name
sub vrf_read_complete__attable_walk_incomplete__is_0 : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  my $red = '3.114.101.100';
  $info->{"_$_"} = 1 for qw/vrf_l3vpn_rd vrf_l3vpn_descr vrf_l3vpn_oper
    vrf_l3vpn_rt vrf_l3vpn_if old_at_paddr old_at_netaddr/;
  $info->{store}{vrf_l3vpn_rd}    = {$red => '64512:30'};
  $info->{store}{vrf_l3vpn_descr} = {$red => q{}};
  $info->{store}{vrf_l3vpn_oper}  = {$red => 'up'};
  $info->{store}{vrf_l3vpn_rt}    = {};
  $info->{store}{vrf_l3vpn_if}    = {"$red.2" => 'active'};
  $info->{store}{old_at_paddr}
    = {'2.1.10.40.0.2' => pack('C6', 2, 0, 0, 0, 0, 1)};
  $info->{store}{old_at_netaddr} = {'2.1.10.40.0.2' => '10.40.0.2'};

  ok(scalar keys %{$info->vrf_neighbors('red')},
    q(red's neighbor comes from the atTable fallback));
  is($info->vrf_read_complete('red'), 1, q(Complete walks read 1));
  $info->{walk_status}{old_at_paddr} = {complete => 0, reason => 'timeout'};
  is($info->vrf_read_complete('red'), 0,
    q(An incomplete atTable walk makes the read incomplete));
}

1;
