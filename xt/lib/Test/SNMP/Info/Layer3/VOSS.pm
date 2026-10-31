# Test::SNMP::Info::Layer3::VOSS
#
# Copyright (c) 2026 The SNMP::Info Developers
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

package Test::SNMP::Info::Layer3::VOSS;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::VOSS;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Fabric Engine 9.4 switch: enterprise 1916, sysServices 6
  $test->{info}->cache({
    '_layers'      => 6,
    '_description' => '5520-24T-FabricEngine (9.4.0.0)',

    # EXTREME-BASE-MIB::extreme552024TFabricEngine
    '_id'   => '.1.3.6.1.4.1.1916.2.437',
    'store' => {},
  });
}

sub _detect {
  my ($test, $layers, $description, $id) = @_;

  $test->{info}->clear_cache();
  $test->{info}->cache({
    '_layers'      => $layers,
    '_description' => $description,
    '_id'          => $id,
    'store'        => {},
  });
  return $test->{info}->device_type();
}

sub device_type : Tests(8) {
  my $test = shift;

  is($test->_detect(6, '5520-24T-FabricEngine (9.4.0.0)',
      '.1.3.6.1.4.1.1916.2.437'),
    'SNMP::Info::Layer3::VOSS', 'Fabric Engine selects VOSS');
  is($test->_detect(6, 'XA1440 (8.2.0.0_B020) (PRIVATE)',
      '.1.3.6.1.4.1.1916.2.337'),
    'SNMP::Info::Layer3::VOSS', 'Build suffix and extra text still select VOSS');
  is($test->_detect(6, 'VSP-7432CQ (8.0.5.0)', '.1.3.6.1.4.1.1916.2.302'),
    'SNMP::Info::Layer3::VOSS', 'VSP under the Extreme enterprise selects VOSS');
  is($test->_detect(78,
      'ExtremeXOS (X440G2-48p-10G4) version 31.7.1.4 31.7.1.4 by release-manager',
      '.1.3.6.1.4.1.1916.2.335'),
    'SNMP::Info::Layer3::Extreme', 'ExtremeXOS with a bracketed model stays Extreme');
  is($test->_detect(78, 'ExtremeWare XOS version 11.6',
      '.1.3.6.1.4.1.1916.2.89'),
    'SNMP::Info::Layer3::Extreme', 'ExtremeWare XOS stays Extreme');
  is($test->_detect(6, 'VSP-8284XSQ (8.8.0.0)', '.1.3.6.1.4.1.2272.205'),
    'SNMP::Info::Layer3::Passport', 'VOSS under enterprise 2272 stays Passport');
  is($test->_detect(6, 'VSP-4450GSX-PWR+ (8.0.1.0)', '.1.3.6.1.4.1.45.3.74.4'),
    'SNMP::Info::Layer2::Baystack', 'Baystack enterprise is unaffected');
  is($test->_detect(78, 'Summit48 - Version 4.1.19 (Build 2) by Release_Master',
      '.1.3.6.1.4.1.1916.2.3'),
    'SNMP::Info::Layer3::Extreme', 'ExtremeWare with a build number stays Extreme');
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'extreme', 'Vendor is extreme');
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'voss', 'OS is voss');
}

sub os_ver : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '9.4.0.0', 'Fabric Engine version');

  $test->{info}{_description} = 'XA1440 (8.2.0.0_B020) (PRIVATE)';
  is($test->{info}->os_ver(), '8.2.0.0', 'Build suffix is not part of version');

  $test->{info}{_description} = 'VSP-7432CQ (8.0.5.0)';
  is($test->{info}->os_ver(), '8.0.5.0', 'VSP version');
}

sub model : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'extreme552024TFabricEngine',
    'Known sysObjectID returns the MIB name');
}

sub serial : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'serial');

  # rcChasSerialNumber is not read
  $test->{info}->cache({
    '_rc_serial' => 'SIM12F9-AC00',
    'store' => {e_parent => {}, e_class => {}},
  });
  is($test->{info}->serial(), undef, 'Chassis serial alone is not the serial');

  $test->{info}->cache({'_serial1' => 'SIM12F9-AC00'});
  is($test->{info}->serial(), 'SIM12F9-AC00', 'serial1 fallback is the serial');
}

sub interfaces__fabric_engine_ports__ifname : Tests(3) {
  my $test = shift;

  $test->{info}->cache({
    '_i_name' => 1, '_i_description' => 1,
    'store' => {
      i_name => {192 => '1/1', 1 => 'Mgmt-clip', 2058 => 'Vlan10 (10.1.1.1)'},
      i_description => {
        192  => 'Extreme Networks 5520-24T-FabricEngine - 1000BaseTX Port 1/1',
        1    => 'Extreme Networks 5520-24T-FabricEngine - Mgmt-clip',
        2058 => 'Extreme Networks 5520-24T-FabricEngine - Vlan 10',
      },
    },
  });
  my $interfaces = $test->{info}->interfaces();
  is($interfaces->{192}, '1/1', 'Port is named by ifName');
  is($interfaces->{1}, 'Mgmt-clip', 'Management clip is named by ifName');
  like($interfaces->{2058}, qr/Vlan 10$/,
    'An interface ifName names by address is named by ifDescr');
}

sub interfaces : Tests(1) {
  can_ok(shift->{info}, 'interfaces');
}

sub mac : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'mac');
  $test->{info}->cache({'_mac' => pack('H*', '0c0012f9ac00')});
  is($test->{info}->mac(), '0c:00:12:f9:ac:00', 'Bridge MAC is the MAC');
}

sub bp_index : Tests(3) {
  my $test = shift;

  $test->{info}->cache({
    '_bp_index' => 1, '_i_index' => 1,
    'store' => {
      bp_index => {},
      i_index  => {1 => 1, 192 => 192, 193 => 193},
    },
  });
  cmp_deeply($test->{info}->bp_index(), {1 => 1, 192 => 192, 193 => 193},
    'Without BRIDGE-MIB ports, ifIndexes map to themselves');

  $test->{info}->cache({'store' => {bp_index => {192 => 192}}});
  cmp_deeply($test->{info}->bp_index(), {192 => 192},
    'BRIDGE-MIB ports are used where served');

  can_ok($test->{info}, 'bp_index');
}

# Bit position is the ifIndex: Fabric Engine ports start at 192
sub _port_list {
  my %member = map { $_ => 1 } @_;
  return pack('B*', join('', map { $member{$_} ? 1 : 0 } 0 .. 199));
}

sub i_vlan_membership__ifindex_192_up__maps_ports : Tests(2) {
  my $test = shift;

  $test->{info}->cache({
    '_rc_vlan_members' => 1,
    'store' => {rc_vlan_members => {10 => _port_list(193), 20 => _port_list(192, 193)}},
  });
  my $membership = $test->{info}->i_vlan_membership();
  cmp_deeply([sort { $a <=> $b } @{$membership->{193}}], [10, 20],
    'Bit 193 puts port 193 in the VLAN');
  cmp_deeply($membership->{192}, [20], 'Bit 192 is port 192');
}

sub i_vlan_membership__qbridge_served__prefers_it : Tests(1) {
  my $test = shift;

  $test->{info}->cache({
    '_bp_index' => 1, '_qb_cv_egress' => 1, '_rc_vlan_members' => 1,
    'store' => {
      bp_index        => {1 => 192},
      qb_cv_egress    => {'0.10' => pack('B*', '1')},
      rc_vlan_members => {20 => _port_list(193)},
    },
  });
  cmp_deeply($test->{info}->i_vlan_membership(), {192 => [10]},
    'Q-BRIDGE membership is used where served');
}

sub i_vlan_membership : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_vlan_membership');
  $test->{info}->cache({'_rc_vlan_members' => 1, 'store' => {rc_vlan_members => {}}});
  is($test->{info}->i_vlan_membership(), undef, 'No VLAN rows is undef');
}

sub i_vlan__qbridge_served__prefers_it : Tests(1) {
  my $test = shift;

  $test->{info}->cache({
    '_bp_index' => 1, '_qb_i_vlan' => 1, '_rc_i_vlan_pvid' => 1,
    'store' => {
      bp_index       => {1 => 192},
      qb_i_vlan      => {1 => 10},
      rc_i_vlan_pvid => {192 => 20},
    },
  });
  cmp_deeply($test->{info}->i_vlan(), {192 => 10},
    'Q-BRIDGE PVID is used where served');
}

sub i_vlan : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_vlan');
  $test->{info}->cache({'_rc_i_vlan_pvid' => 1, 'store' => {rc_i_vlan_pvid => {192 => 10}}});
  cmp_deeply($test->{info}->i_vlan(), {192 => 10}, 'PVID by ifIndex');

  $test->{info}->cache({'store' => {rc_i_vlan_pvid => {}}});
  is($test->{info}->i_vlan(), undef, 'No port rows is undef');
}

sub i_vlan_membership_untagged__qbridge_served__prefers_it : Tests(1) {
  my $test = shift;

  $test->{info}->cache({
    '_bp_index' => 1, '_qb_cv_untagged' => 1, '_rc_vlan_members' => 1,
    'store' => {
      bp_index        => {1 => 192},
      qb_cv_untagged  => {'0.10' => pack('B*', '1')},
      rc_vlan_members => {20 => _port_list(193)},
    },
  });
  cmp_deeply($test->{info}->i_vlan_membership_untagged(), {192 => [10]},
    'Q-BRIDGE untagged membership is used where served');
}

sub i_vlan_membership_untagged : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_vlan_membership_untagged');
  $test->{info}->cache({
    '_rc_vlan_members' => 1, '_rc_i_vlan_pvid' => 1,
    '_rcVlanPortType' => 1, '_rcVlanPortPerformTagging' => 1,
    '_rcVlanPortUntagDefaultVlan' => 1,
    'store' => {
      rc_vlan_members => {10 => _port_list(195, 196, 197)},
      rc_i_vlan_pvid  => {195 => 10, 196 => 10, 197 => 0},
      rcVlanPortType  => {195 => 'access', 196 => 'access', 197 => 'trunk'},
      rcVlanPortPerformTagging => {195 => 'false', 196 => 'false', 197 => 'true'},
    },
  });
  my $untagged = $test->{info}->i_vlan_membership_untagged();
  cmp_deeply($untagged, {195 => [10], 196 => [10]},
    'Ports with no untagged VLAN have no row');

  $test->{info}->cache({'store' => {rc_vlan_members => {}, rc_i_vlan_pvid => {}}});
  is($test->{info}->i_vlan_membership_untagged(), undef, 'No rows is undef');
}

sub agg_ports__mlt_members__map_to_mlt : Tests(1) {
  my $test = shift;

  $test->{info}->cache({
    '_rc_mlt_ports' => 1, '_rc_mlt_index' => 1,
    'store' => {
      rc_mlt_ports => {1 => _port_list(194, 195)},
      rc_mlt_index => {1 => 6144},
    },
  });
  cmp_deeply($test->{info}->agg_ports(), {194 => 6144, 195 => 6144},
    'MLT members map to the MLT ifIndex');
}

sub rc_cpu_duplex__legacy_leaf__absent : Tests(2) {
  my $test = shift;

  ok(!$test->{info}->can('rc_cpu_duplex'), 'No CPU port duplex method');
  ok(!$test->{info}->can('rc_ist_peer'), 'No legacy IST method');
}

1;
