# Test::SNMP::Info::Layer3::Juniper
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

package Test::SNMP::Info::Layer3::Juniper;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Juniper;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $d_string = 'Juniper Networks, Inc. ex4200-24t internet router, ';
  $d_string .= 'kernel JUNOS 10.4R6.5 ';

  my $cache_data = {
    '_layers'      => 6,
    '_description' => $d_string,

    # JUNIPER-CHASSIS-DEFINES-MIB::jnxProductNameEX4200
    '_id'                      => '.1.3.6.1.4.1.2636.1.1.1.2.31',
    '_version'                 => '14.1X53-D40.8',
    '_serial'                  => 'AB0123456789',
    '_jnxExVlanPortAccessMode' => 1,
    '_jnx_v_name'              => 1,
    '_jnx_v_index'             => 1,
    '_jnx_v_type'              => 1,

    # Newer table doesn't exist in EX4200, but in cache to simplify testing
    # method code
    '_jnx_els_v_name'   => 1,
    '_jnx_els_v_index'  => 1,
    '_jnx_els_v_type'   => 1,
    '_jnx_els_v_fdb_id' => 1,
    '_bp_index'         => 1,
    '_qb_i_vlan'        => 1,
    '_qb_v_egress'      => 1,
    '_qb_v_untagged'    => 1,
    '_qb_fw_port'       => 1,

    # For pseudo entity testing
    '_box_descr'                   => 'Juniper Virtual Chassis Ethernet Switch',
    '_jnxVirtualChassisMemberRole' => 'master',
    '_jnxContainersWithin'         => 1,
    '_jnxContentsDescr'            => 1,
    '_jnxContentsSerialNo'         => 1,
    '_jnxFruType'                  => 1,
    '_jnxContainersDescr'          => 1,
    '_e_containers_type'           => 1,
    '_jnxContentsPartNo'           => 1,
    '_e_contents_type'             => 1,
    '_jnxContainersWithin'         => 1,

    # For PoE port mapping test
    '_i_description'       => 1,

    'store' => {
      'peth_port_status' => {'1.1' => 'searching', '1.2' => 'otherFault', '1.3' => 'deliveringPower'},
      'i_index'       => {504 => 504, 505 => 505, 506 => 506, 507 => 507, 508 => 508, 509 => 509},
      'i_description' => {
        504 => 'ge-0/0/0',
        505 => 'ge-0/0/0.0',
        506 => 'ge-0/0/1',
        507 => 'ge-0/0/1.0',
        508 => 'ge-0/0/2',
        509 => 'ge-0/0/2.0',
      },
      'jnxExVlanPortAccessMode' => {'2.514' => 'access', '7.513' => 'trunk'},
      'jnx_v_name'  => {2 => 'default', 3 => 'management'},
      'jnx_v_index' => {2 => 0,         3 => 120},
      'jnx_v_type'  => {2 => 'static',  3 => 'static'},

      # Newer table doesn't exist in EX4200, but in cache to simplify testing
      # method code
      'jnx_els_v_name' =>
        {6 => 'VLAN0114_VPN78087', 7 => 'VLAN2088_VPN78117', 8 => 'default'},
      'jnx_els_v_index'  => {6 => 114,      7   => 2088,     8   => 1},
      'jnx_els_v_type'   => {6 => 'static', 7   => 'static', 8   => 'static'},
      'jnx_els_v_fdb_id' => {6 => 393216,   7   => 458752,   8   => 524288},
      'bp_index'         => {4 => 662,      491 => 509,      492 => 510},
      'qb_i_vlan'        => {4 => 0,        491 => 113,      492 => 2088},
      'qb_v_egress'   => {114 => '4', 2088 => '491,492'},
      'qb_v_untagged' => {114 => '4', 2088 => '491,492'},
      'qb_fw_port' =>
        {'393216.0.19.149.30.221.37' => 4, '458752.0.9.245.16.59.121' => 492},

      'jnxContainersWithin' => {1 => 0, 2 => 1, 4 => 1, 7 => 1, 8 => 7, 9 => 1},
      'jnxContentsDescr'    => {
        '1.1.0.0' => '',
        '2.1.1.0' => 'Power Supply: Power Supply 0 @ 0/0/*',
        '2.1.2.0' => 'Power Supply: Power Supply 1 @ 0/1/*',
        '2.2.1.0' => 'Power Supply: Power Supply 0 @ 1/0/*',
        '2.2.2.0' => 'Power Supply: Power Supply 1 @ 1/1/*',
        '4.1.1.1' => 'FAN 0 @ 0/0/0',
        '4.1.2.1' => 'FAN 1 @ 0/1/0',
        '4.2.1.1' => 'FAN 0 @ 1/0/0',
        '4.2.2.1' => 'FAN 1 @ 1/1/0',
        '7.1.0.0' => 'FPC: EX4300-48T @ 0/*/*',
        '7.2.0.0' => 'FPC: EX4300-48T @ 1/*/*',
        '8.1.1.0' => 'PIC: 48x 10/100/1000 Base-T @ 0/0/*',
        '8.1.2.0' => 'PIC: 4x 40GE QSFP+ @ 0/1/*',
        '8.1.3.0' => 'PIC: 4x 1G/10G SFP/SFP+ @ 0/2/*',
        '8.2.1.0' => 'PIC: 48x 10/100/1000 Base-T @ 1/0/*',
        '8.2.2.0' => 'PIC: 4x 40GE QSFP+ @ 1/1/*',
        '8.2.3.0' => 'PIC: 4x 1G/10G SFP/SFP+ @ 1/2/*',
        '9.1.0.0' => 'Routing Engine 0',
        '9.2.0.0' => 'Routing Engine 1'
      },
      'jnxContentsSerialNo' => {
        '2.1.1.0' => '1EDD1234567',
        '2.1.2.0' => '1EDD2345678',
        '2.2.1.0' => '1EDD3456789',
        '2.2.2.0' => '1EDD4567890',
        '7.1.0.0' => 'PE1234567890',
        '7.2.0.0' => 'PE0123456789',
        '8.1.1.0' => 'BUILTIN',
        '8.1.2.0' => 'BUILTIN',
        '8.1.3.0' => 'MY1234567890',
        '8.2.1.0' => 'BUILTIN',
        '8.2.2.0' => 'BUILTIN',
        '8.2.3.0' => 'MY0123456789',
        '9.1.0.0' => 'PE2345678901',
        '9.2.0.0' => 'PE3456789012'
      },
      'jnxFruType' => {
        '2.1.1.0' => 'powerEntryModule',
        '2.1.2.0' => 'powerEntryModule',
        '2.2.1.0' => 'powerEntryModule',
        '2.2.2.0' => 'powerEntryModule',
        '4.1.1.1' => 'fan',
        '4.1.2.1' => 'fan',
        '4.2.1.1' => 'fan',
        '4.2.2.1' => 'fan',
        '7.1.0.0' => 'flexiblePicConcentrator',
        '7.2.0.0' => 'flexiblePicConcentrator',
        '8.1.1.0' => 'portInterfaceCard',
        '8.1.2.0' => 'portInterfaceCard',
        '8.1.3.0' => 'portInterfaceCard',
        '8.2.1.0' => 'portInterfaceCard',
        '8.2.2.0' => 'portInterfaceCard',
        '8.2.3.0' => 'portInterfaceCard',
        '9.1.0.0' => 'routingEngine',
        '9.2.0.0' => 'routingEngine'
      },
      'jnxContentsPartNo' => {
        '2.1.1.0' => '740-046876',
        '2.1.2.0' => '740-046876',
        '2.2.1.0' => '740-046876',
        '2.2.2.0' => '740-046876',
        '7.1.0.0' => '650-044932',
        '7.2.0.0' => '650-044932',
        '8.1.1.0' => 'BUILTIN',
        '8.1.2.0' => 'BUILTIN',
        '8.1.3.0' => '611-063980',
        '8.2.1.0' => 'BUILTIN',
        '8.2.2.0' => 'BUILTIN',
        '8.2.3.0' => '611-063980',
        '9.1.0.0' => '650-044932',
        '9.2.0.0' => '650-044932'
      },

      # These are cached raw
      'e_contents_type' => {
        '1.1.0.0' => '.1.3.6.1.4.1.2636.1.1.2.1.63.0',
        '2.1.1.0' => '.1.3.6.1.4.1.2636.1.1.3.2.63.1.1.0',
        '2.1.2.0' => '.1.3.6.1.4.1.2636.1.1.3.2.63.1.1.0',
        '2.2.1.0' => '.1.3.6.1.4.1.2636.1.1.3.2.63.1.1.0',
        '2.2.2.0' => '.1.3.6.1.4.1.2636.1.1.3.2.63.1.1.0',
        '4.1.1.1' => '.1.3.6.1.4.1.2636.1.1.3.2.63.1.2.0',
        '4.1.2.1' => '.1.3.6.1.4.1.2636.1.1.3.2.63.1.2.0',
        '4.2.1.1' => '.1.3.6.1.4.1.2636.1.1.3.2.63.1.2.0',
        '4.2.2.1' => '.1.3.6.1.4.1.2636.1.1.3.2.63.1.2.0',
        '7.1.0.0' => '.1.3.6.1.4.1.2636.1.1.3.2.63.1.0',
        '7.2.0.0' => '.1.3.6.1.4.1.2636.1.1.3.2.63.1.0',
        '8.1.1.0' => '.1.3.6.1.4.1.2636.1.1.1.4.63.2.0',
        '8.1.2.0' => '.1.3.6.1.4.1.2636.1.1.3.3.12.1.319.0',
        '8.1.3.0' => '.1.3.6.1.4.1.2636.1.1.3.3.12.1.320.0',
        '8.2.1.0' => '.1.3.6.1.4.1.2636.1.1.1.4.63.2.0',
        '8.2.2.0' => '.1.3.6.1.4.1.2636.1.1.3.3.12.1.319.0',
        '8.2.3.0' => '.1.3.6.1.4.1.2636.1.1.3.3.12.1.320.0',
        '9.1.0.0' => '.1.3.6.1.4.1.2636.1.1.2.1.63.1.0',
        '9.2.0.0' => '.1.3.6.1.4.1.2636.1.1.2.1.63.1.0'
      },
      'jnxContainersDescr' => {
        1 => 'chassis frame',
        2 => 'Power Supply slot',
        4 => 'FAN slot',
        7 => 'FPC slot',
        8 => 'PIC slot',
        9 => 'Routing Engine slot'
      },

      # These are cached raw
      'e_containers_type' => {
        1 => '.1.3.6.1.4.1.2636.1.1.2.1.63.0',
        2 => '.1.3.6.1.4.1.2636.1.1.2.2.63.1.1.0',
        4 => '.1.3.6.1.4.1.2636.1.1.2.2.63.1.2.0',
        7 => '.1.3.6.1.4.1.2636.1.1.2.2.63.1.0',
        8 => '.1.3.6.1.4.1.2636.1.1.2.3.63.1.0',
        9 => '.1.3.6.1.4.1.2636.1.1.2.1.63.1.0'
      },
      'jnxContainersWithin' => {1 => 0, 2 => 1, 4 => 1, 7 => 1, 8 => 7, 9 => 1}
    }
  };
  $test->{info}->cache($cache_data);
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'juniper', q(Vendor returns 'juniper'));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'junos', q(OS returns 'junos'));
}

sub layers : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'layers');
  is($test->{info}->layers(), '00000110', q(Original layers unmodified));

  # Set to layer 3 only and with presence of FDB 'qb_fw_port' will turn on
  # layer 2
  $test->{info}{_layers} = 4;
  is($test->{info}->layers(),
    '00000110', q(Layer2 added due to presence of FDB));

  # Delete FDB cache flag, layers still = 4 binary (3 only)
  delete $test->{info}{_qb_fw_port};
  is($test->{info}->layers(), '00000100', q(No layer2 without FDB));

  $test->{info}->clear_cache();
  is($test->{info}->layers(), undef, q(No data returns undef layers));
}

sub os_ver : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(),
    '14.1X53-D40.8',
    q(OS version returned from 'jnxVirtualChassisMemberSWVersion'));

  delete $test->{info}{_version};
  is($test->{info}->os_ver(),
    '10.4R6.5', q(OS version returned from 'sysDescr'));

  delete $test->{info}{_description};
  $test->{info}{_lldp_sysdesc}
    = 'Juniper Networks, Inc. srx240h-poe , version 12.1R3.5 Build date: ';
  is($test->{info}->os_ver(),
    '12.1R3.5', q(OS version returned from 'lldpLocSysDesc'));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No data returns undef OS version));
}

sub model : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'EX4200', q(Model translates id));

  $test->{info}{_id} = '.100.3.6.1.4.1.6527.1.3.1';
  is($test->{info}->model(), '.100.3.6.1.4.1.6527.1.3.1', q(Model uses id));

  $test->{info}{_vc_model} = 'qfx5100-48s-6q';
  is($test->{info}->model(),
    'QFX5100-48S-6Q', q(Model uses 'jnxVirtualChassisMemberModel'));
}

sub serial : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(),
    'AB0123456789', q(Serial returns 'jnxBoxSerialNo'));

  $test->{info}->clear_cache();
  is($test->{info}->serial(), undef, q(No data returns undef serial));
}

sub i_trunk : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_trunk');

  my $expected = {'514' => 'access', '513' => 'trunk'};
  cmp_deeply($test->{info}->i_trunk(),
    $expected, q(Interface trunk status returns expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_trunk(), {}, q(No data returns empty hash));
}

sub qb_fdb_index : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'qb_fdb_index');

  my $expected = {393216 => 114, 458752 => 2088, 524288 => 1};
  cmp_deeply($test->{info}->qb_fdb_index(),
    $expected, q(ELS VLAN to FDB index returned expected values));

  delete $test->{info}{'_jnx_els_v_index'};
  $expected = {2 => 0, 3 => 120};
  cmp_deeply($test->{info}->qb_fdb_index(),
    $expected, q(Older VLAN to FDB index returned expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->qb_fdb_index(), undef, q(No data returns undef));
}

sub v_type : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'v_type');

  my $expected = {6 => 'static', 7 => 'static', 8 => 'static'};
  cmp_deeply($test->{info}->v_type(),
    $expected, q(ELS VLAN types returned expected values));

  delete $test->{info}{'_jnx_els_v_type'};
  $expected = {2 => 'static', 3 => 'static'};
  cmp_deeply($test->{info}->v_type(),
    $expected, q(Older VLAN types returned expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->v_type(), undef, q(No data returns undef));
}

sub v_index : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'v_index');

  my $expected = {6 => 114, 7 => 2088, 8 => 1};
  cmp_deeply($test->{info}->v_index(),
    $expected, q(ELS VLAN index returned expected values));

  delete $test->{info}{'_jnx_els_v_index'};
  $expected = {2 => 0, 3 => 120};
  cmp_deeply($test->{info}->v_index(),
    $expected, q(Older VLAN index returned expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->v_index(), undef, q(No data returns undef));
}

sub i_vlan : Tests(7) {
  my $test = shift;

  can_ok($test->{info}, 'i_vlan');

  my $expected = {662 => 0, 509 => 113, 510 => 2088};
  cmp_deeply($test->{info}->i_vlan(),
    $expected, q(ELS PVID returned expected values));

  # dot1qPvid is a VLAN ID. Preserve it when it happens to collide with an
  # internal VLAN table index for a different VLAN.
  $test->{info}{store}{bp_index}         = {513 => 510};
  $test->{info}{store}{qb_i_vlan}        = {513 => 15};
  $test->{info}{store}{jnx_els_v_index}  = {8 => 15, 15 => 201};
  $expected                              = {510 => 15};
  cmp_deeply($test->{info}->i_vlan(),
    $expected, q(ELS PVID preserved when VLAN ID collides with internal index));

  delete $test->{info}{'_jnx_els_v_index'};
  $test->{info}{store}{jnx_v_index} = {2 => 0, 3 => 120};
  $test->{info}{store}{bp_index}  = {513 => 505, 514 => 507};
  $test->{info}{store}{qb_i_vlan} = {513 => 3,   514 => 2};
  $expected                       = {505 => 120, 507 => 0};
  cmp_deeply($test->{info}->i_vlan(),
    $expected, q(Older PVID returned expected values));

  # EX3300 12.3R12-S21 walk from PR #581: bridge port 514 (ifIndex 506) is
  # untagged in row 8 (VLAN 15), not row 15 (VLAN 201), which holds port 549
  my $bport_514 = pack('H*', ('00' x 64) . '40');
  my $bport_549 = pack('H*', ('00' x 68) . '08');
  $test->{info}{store}{jnx_v_index}   = {8 => 15, 15 => 201};
  $test->{info}{store}{bp_index}      = {514 => 506};
  $test->{info}{store}{qb_i_vlan}     = {514 => 15};
  $test->{info}{store}{qb_v_untagged} = {8 => $bport_514, 15 => $bport_549};
  $expected                           = {506 => 15};
  cmp_deeply($test->{info}->i_vlan(),
    $expected, q(Older PVID preserved when VLAN ID collides with internal index));

  # 10.4 returns the index; untagged membership confirms 201
  $test->{info}{store}{qb_v_untagged} = {15 => $bport_514};
  $expected                           = {506 => 201};
  cmp_deeply($test->{info}->i_vlan(),
    $expected, q(Older PVID index translated when membership confirms it));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_vlan(), {}, q(No data returns empty hash));
}

sub v_name : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'v_name');

  my $expected
    = {6 => 'VLAN0114_VPN78087', 7 => 'VLAN2088_VPN78117', 8 => 'default'};
  cmp_deeply($test->{info}->v_name(),
    $expected, q(ELS VLAN names returned expected values));

  delete $test->{info}{'_jnx_els_v_name'};
  $expected = {2 => 'default', 3 => 'management'};
  cmp_deeply($test->{info}->v_name(),
    $expected, q(Older VLAN names returned expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->v_name(), undef, q(No data returns undef));
}

sub i_vlan_membership : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'i_vlan_membership');

  # Delete this so we can test new method first
  delete $test->{info}{'_jnx_v_index'};

  my $expected = {662 => [114], 509 => [2088], 510 => [2088]};
  cmp_deeply($test->{info}->i_vlan_membership(),
    $expected, q(ELS VLAN membership returned expected values));

  # Restore so we can trigger test for older devices
  $test->{info}{'_jnx_v_index'} = 1;
  delete $test->{info}{'_jnx_els_v_index'};

  my $padding = '00000000000000000000000000000000' x 4;

  # This has bits 516 - 536 on
  my $portlist2 = $padding . '1FFFFF';

  # This has bits 512 - 515 on
  my $portlist3 = $padding . 'E0';

  # To simplify the expected value, we're only going to define the mapping
  # for five ports
  $test->{info}{store}{bp_index}
    = {513 => 505, 514 => 507, 515 => 509, 516 => 511, 536 => 551};
  $test->{info}{store}{qb_v_egress}
    = {2 => pack("H*", $portlist2), 3 => pack("H*", $portlist3)};

  $expected
    = {505 => [120], 507 => [120], 509 => [120], 511 => [0], 551 => [0]};
  cmp_deeply($test->{info}->i_vlan_membership(),
    $expected, q(VLAN membership returned expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_vlan_membership(),
    undef, q(No data returns undef));
}

# Same code as i_vlan_membership, untagged just uses different leaf
sub i_vlan_membership_untagged : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'i_vlan_membership_untagged');

  # Delete this so we can test new method first
  delete $test->{info}{'_jnx_v_index'};

  my $expected = {662 => [114], 509 => [2088], 510 => [2088]};
  cmp_deeply($test->{info}->i_vlan_membership_untagged(),
    $expected, q(ELS VLAN membership untagged returned expected values));

  # Restore so we can trigger test for older devices
  $test->{info}{'_jnx_v_index'} = 1;
  delete $test->{info}{'_jnx_els_v_index'};

  my $padding = '00000000000000000000000000000000' x 4;

  # This has bits 516 - 536 on
  my $portlist2 = $padding . '1FFFFF';

  # This has bits 512 - 515 on
  my $portlist3 = $padding . 'E0';

  # To simplify the expected value, we're only going to define the mapping
  # for five ports
  $test->{info}{store}{bp_index}
    = {513 => 505, 514 => 507, 515 => 509, 516 => 511, 536 => 551};
  $test->{info}{store}{qb_v_untagged}
    = {2 => pack("H*", $portlist2), 3 => pack("H*", $portlist3)};

  $expected
    = {505 => [120], 507 => [120], 509 => [120], 511 => [0], 551 => [0]};
  cmp_deeply($test->{info}->i_vlan_membership_untagged(),
    $expected, q(VLAN membership untagged returned expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_vlan_membership_untagged(),
    {}, q(No data returns empty hashref));
}

# These is no longer defined in the class, but tested due to past issues with
# VLAN mapping due to changes with the introduction of ELS. See issue #67
# Juniper EX4300 Missing/Wrong information #67
sub qb_fw_vlan : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'qb_fw_vlan');

  my $expected
    = {'393216.0.19.149.30.221.37' => 114, '458752.0.9.245.16.59.121' => 2088};
  cmp_deeply($test->{info}->qb_fw_vlan(),
    $expected,
    q(ELS forwarding table entries to VLAN IDs returned expected values));

  delete $test->{info}{'_jnx_els_v_index'};
  $test->{info}{store}{qb_fw_port}
    = {'2.0.19.149.30.221.37' => 513, '3.0.9.245.16.59.121' => 507};
  $expected = {'2.0.19.149.30.221.37' => 0, '3.0.9.245.16.59.121' => 120};
  cmp_deeply($test->{info}->qb_fw_vlan(),
    $expected,
    q(Older forwarding table entries to VLAN IDs returned expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->qb_fw_vlan(), {}, q(No data returns empty hash));
}

# Two member virtual chassis on top of the common entity cache
sub _set_virtual_chassis {
  my $test = shift;

  my $cache = $test->{info}{store};
  $test->{info}{'_jnxVirtualChassisMemberSerialnumber'} = 1;
  $test->{info}{'_jnxVirtualChassisMemberModel'}        = 1;
  $cache->{jnxVirtualChassisMemberRole} = {0 => 'master', 1 => 'backup'};
  $cache->{jnxVirtualChassisMemberSerialnumber}
    = {0 => 'VC0000000001', 1 => 'VC0000000002'};
  $cache->{jnxVirtualChassisMemberModel}
    = {0 => 'ex4300-48t', 1 => 'ex4300-48p'};
  return;
}

sub e_index : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'e_index');

  my $expected = {
    '1'       => '01000000',
    '1.1.0.0' => '01010000',
    '2'       => '02000000',
    '2.1.1.0' => '02010100',
    '2.1.2.0' => '02010200',
    '2.2.1.0' => '02020100',
    '2.2.2.0' => '02020200',
    '4'       => '04000000',
    '4.1.1.1' => '04010101',
    '4.1.2.1' => '04010201',
    '4.2.1.1' => '04020101',
    '4.2.2.1' => '04020201',
    '7'       => '07000000',
    '7.1.0.0' => '07010000',
    '7.2.0.0' => '07020000',
    '8'       => '08000000',
    '8.1.1.0' => '08010100',
    '8.1.2.0' => '08010200',
    '8.1.3.0' => '08010300',
    '8.2.1.0' => '08020100',
    '8.2.2.0' => '08020200',
    '8.2.3.0' => '08020300',
    '9'       => '09000000',
    '9.1.0.0' => '09010000',
    '9.2.0.0' => '09020000'
  };
  cmp_deeply($test->{info}->e_index(),
    $expected, q(Entity index returned expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->e_index(), {}, q(No data returns empty hash));
}

sub e_class : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'e_class');

  my $expected = {
    '1'       => 'chassis',
    '1.1.0.0' => 'container',
    '2'       => 'container',
    '2.1.1.0' => 'powerSupply',
    '2.1.2.0' => 'powerSupply',
    '2.2.1.0' => 'powerSupply',
    '2.2.2.0' => 'powerSupply',
    '4'       => 'container',
    '4.1.1.1' => 'fan',
    '4.1.2.1' => 'fan',
    '4.2.1.1' => 'fan',
    '4.2.2.1' => 'fan',
    '7'       => 'container',
    '7.1.0.0' => 'module',
    '7.2.0.0' => 'module',
    '8'       => 'container',
    '8.1.1.0' => 'module',
    '8.1.2.0' => 'module',
    '8.1.3.0' => 'module',
    '8.2.1.0' => 'module',
    '8.2.2.0' => 'module',
    '8.2.3.0' => 'module',
    '9'       => 'container',
    '9.1.0.0' => 'module',
    '9.2.0.0' => 'module'
  };
  cmp_deeply($test->{info}->e_class(),
    $expected, q(Entity classes returned expected values));

  _set_virtual_chassis($test);
  my $classes = $test->{info}->e_class();
  my %vc_class = map { $_ => $classes->{$_} }
    qw(1 1.1.0.0 1.2.0.0 2.1.0.0 7.1.0.0);
  cmp_deeply(
    \%vc_class,
    {
      '1'       => 'stack',
      '1.1.0.0' => 'chassis',
      '1.2.0.0' => 'chassis',
      '2.1.0.0' => 'container',
      '7.1.0.0' => 'module'
    },
    q(Virtual chassis member frames are chassis under the stack)
  );

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->e_class(), {}, q(No data returns empty hash));
}

sub e_descr : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'e_descr');

  my $expected = {
    '1'       => 'Juniper Virtual Chassis Ethernet Switch',
    '1.1.0.0' => 'chassis frame',
    '2'       => 'Power Supply slot',
    '2.1.1.0' => 'Power Supply: Power Supply 0 @ 0/0/*',
    '2.1.2.0' => 'Power Supply: Power Supply 1 @ 0/1/*',
    '2.2.1.0' => 'Power Supply: Power Supply 0 @ 1/0/*',
    '2.2.2.0' => 'Power Supply: Power Supply 1 @ 1/1/*',
    '4'       => 'FAN slot',
    '4.1.1.1' => 'FAN 0 @ 0/0/0',
    '4.1.2.1' => 'FAN 1 @ 0/1/0',
    '4.2.1.1' => 'FAN 0 @ 1/0/0',
    '4.2.2.1' => 'FAN 1 @ 1/1/0',
    '7'       => 'FPC slot',
    '7.1.0.0' => 'FPC: EX4300-48T @ 0/*/*',
    '7.2.0.0' => 'FPC: EX4300-48T @ 1/*/*',
    '8'       => 'PIC slot',
    '8.1.1.0' => 'PIC: 48x 10/100/1000 Base-T @ 0/0/*',
    '8.1.2.0' => 'PIC: 4x 40GE QSFP+ @ 0/1/*',
    '8.1.3.0' => 'PIC: 4x 1G/10G SFP/SFP+ @ 0/2/*',
    '8.2.1.0' => 'PIC: 48x 10/100/1000 Base-T @ 1/0/*',
    '8.2.2.0' => 'PIC: 4x 40GE QSFP+ @ 1/1/*',
    '8.2.3.0' => 'PIC: 4x 1G/10G SFP/SFP+ @ 1/2/*',
    '9'       => 'Routing Engine slot',
    '9.1.0.0' => 'Routing Engine 0',
    '9.2.0.0' => 'Routing Engine 1'
  };
  cmp_deeply($test->{info}->e_descr(),
    $expected, q(Entity descriptions returned expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->e_descr(), {}, q(No data returns empty hash));
}

sub e_serial : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'e_serial');

  my $expected = {
    '1'       => 'AB0123456789',
    '2.1.1.0' => '1EDD1234567',
    '2.1.2.0' => '1EDD2345678',
    '2.2.1.0' => '1EDD3456789',
    '2.2.2.0' => '1EDD4567890',
    '7.1.0.0' => 'PE1234567890',
    '7.2.0.0' => 'PE0123456789',
    '8.1.3.0' => 'MY1234567890',
    '8.2.3.0' => 'MY0123456789',
    '9.1.0.0' => 'PE2345678901',
    '9.2.0.0' => 'PE3456789012'
  };
  cmp_deeply($test->{info}->e_serial(),
    $expected, q(Entity serial numbers returned expected values));

  _set_virtual_chassis($test);
  delete $expected->{'1'};
  $expected->{'1.1.0.0'} = 'VC0000000001';
  $expected->{'1.2.0.0'} = 'VC0000000002';
  cmp_deeply($test->{info}->e_serial(),
    $expected, q(Virtual chassis member frames have member serials));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->e_serial(), {}, q(No data returns empty hash));
}

sub e_model : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'e_model');

  $test->{info}{'_e_model'} = 1;
  $test->{info}{store}{e_model} = {5 => 'ENTITY-MODEL'};
  cmp_deeply($test->{info}->e_model(),
    {5 => 'ENTITY-MODEL'}, q(Without virtual chassis returns ENTITY-MIB));

  _set_virtual_chassis($test);
  cmp_deeply(
    $test->{info}->e_model(),
    {
      5         => 'ENTITY-MODEL',
      '1.1.0.0' => 'EX4300-48T',
      '1.2.0.0' => 'EX4300-48P'
    },
    q(Virtual chassis member frames have member models)
  );

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->e_model(), {}, q(No data returns empty hash));
}

sub e_fru : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'e_fru');

  my $expected = {
    '1'       => 'false',
    '1.1.0.0' => 'false',
    '2'       => 'false',
    '2.1.1.0' => 'true',
    '2.1.2.0' => 'true',
    '2.2.1.0' => 'true',
    '2.2.2.0' => 'true',
    '4'       => 'false',
    '4.1.1.1' => 'false',
    '4.1.2.1' => 'false',
    '4.2.1.1' => 'false',
    '4.2.2.1' => 'false',
    '7'       => 'false',
    '7.1.0.0' => 'true',
    '7.2.0.0' => 'true',
    '8'       => 'false',
    '8.1.1.0' => 'false',
    '8.1.2.0' => 'false',
    '8.1.3.0' => 'true',
    '8.2.1.0' => 'false',
    '8.2.2.0' => 'false',
    '8.2.3.0' => 'true',
    '9'       => 'false',
    '9.1.0.0' => 'true',
    '9.2.0.0' => 'true'
  };
  cmp_deeply($test->{info}->e_fru(),
    $expected, q(Entity FRUs returned expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->e_fru(), {}, q(No data returns empty hash));
}

sub e_type : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'e_type');

  my $expected = {
    '1'       => 'jnxChassisEX4300',
    '2'       => 'jnxEX4300SlotPower',
    '1.1.0.0' => 'jnxChassisEX4300',
    '2.1.1.0' => 'jnxEX4300Power',
    '2.1.2.0' => 'jnxEX4300Power',
    '2.2.1.0' => 'jnxEX4300Power',
    '2.2.2.0' => 'jnxEX4300Power',
    '4'       => 'jnxEX4300SlotFan',
    '4.1.1.1' => 'jnxEX4300Fan',
    '4.1.2.1' => 'jnxEX4300Fan',
    '4.2.1.1' => 'jnxEX4300Fan',
    '4.2.2.1' => 'jnxEX4300Fan',
    '7'       => 'jnxEX4300SlotFPC',
    '7.1.0.0' => 'jnxEX4300FPC',
    '7.2.0.0' => 'jnxEX4300FPC',
    '8'       => 'jnxEX4300MediaCardSpacePIC',
    '8.1.1.0' => 'jnxProductEX4300port48T',
    '8.1.2.0' => 'jnxPicEX4300QSFP4Port',
    '8.1.3.0' => 'jnxPicEX4300UplinkSFPPlus4Port',
    '8.2.1.0' => 'jnxProductEX4300port48T',
    '8.2.2.0' => 'jnxPicEX4300QSFP4Port',
    '8.2.3.0' => 'jnxPicEX4300UplinkSFPPlus4Port',
    '9'       => 'jnxEX4300RE0',
    '9.1.0.0' => 'jnxEX4300RE0',
    '9.2.0.0' => 'jnxEX4300RE0'
  };
  cmp_deeply($test->{info}->e_type(),
    $expected, q(Entity types returned expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->e_type(), {}, q(No data returns empty hash));
}

sub e_vendor : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'e_vendor');

  my $expected = {
    '1'       => 'juniper',
    '2'       => 'juniper',
    '1.1.0.0' => 'juniper',
    '2.1.1.0' => 'juniper',
    '2.1.2.0' => 'juniper',
    '2.2.1.0' => 'juniper',
    '2.2.2.0' => 'juniper',
    '4'       => 'juniper',
    '4.1.1.1' => 'juniper',
    '4.1.2.1' => 'juniper',
    '4.2.1.1' => 'juniper',
    '4.2.2.1' => 'juniper',
    '7'       => 'juniper',
    '7.1.0.0' => 'juniper',
    '7.2.0.0' => 'juniper',
    '8'       => 'juniper',
    '8.1.1.0' => 'juniper',
    '8.1.2.0' => 'juniper',
    '8.1.3.0' => 'juniper',
    '8.2.1.0' => 'juniper',
    '8.2.2.0' => 'juniper',
    '8.2.3.0' => 'juniper',
    '9'       => 'juniper',
    '9.1.0.0' => 'juniper',
    '9.2.0.0' => 'juniper'
  };
  cmp_deeply($test->{info}->e_vendor(),
    $expected, q(Entity vendor returned expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->e_vendor(), {}, q(No data returns empty hash));
}

sub e_pos : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'e_pos');

  my $expected = {
    '1'       => '01000000',
    '1.1.0.0' => '01010000',
    '2'       => '02000000',
    '2.1.1.0' => '02010100',
    '2.1.2.0' => '02010200',
    '2.2.1.0' => '02020100',
    '2.2.2.0' => '02020200',
    '4'       => '04000000',
    '4.1.1.1' => '04010101',
    '4.1.2.1' => '04010201',
    '4.2.1.1' => '04020101',
    '4.2.2.1' => '04020201',
    '7'       => '07000000',
    '7.1.0.0' => '07010000',
    '7.2.0.0' => '07020000',
    '8'       => '08000000',
    '8.1.1.0' => '08010100',
    '8.1.2.0' => '08010200',
    '8.1.3.0' => '08010300',
    '8.2.1.0' => '08020100',
    '8.2.2.0' => '08020200',
    '8.2.3.0' => '08020300',
    '9'       => '09000000',
    '9.1.0.0' => '09010000',
    '9.2.0.0' => '09020000'
  };
  cmp_deeply($test->{info}->e_pos(),
    $expected, q(Entity position returned expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->e_pos(), {}, q(No data returns empty hash));
}

sub e_parent : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'e_parent');

  my $expected = {
    '1'       => '00000000',
    '1.1.0.0' => '01000000',
    '2'       => '01000000',
    '2.1.1.0' => '02000000',
    '2.1.2.0' => '02000000',
    '2.2.1.0' => '02000000',
    '2.2.2.0' => '02000000',
    '4'       => '01000000',
    '4.1.1.1' => '04000000',
    '4.1.2.1' => '04000000',
    '4.2.1.1' => '04000000',
    '4.2.2.1' => '04000000',
    '7'       => '01000000',
    '7.1.0.0' => '07000000',
    '7.2.0.0' => '07000000',
    '8'       => '07000000',
    '8.1.1.0' => '08000000',
    '8.1.2.0' => '08000000',
    '8.1.3.0' => '08000000',
    '8.2.1.0' => '08000000',
    '8.2.2.0' => '08000000',
    '8.2.3.0' => '08000000',
    '9'       => '01000000',
    '9.1.0.0' => '09000000',
    '9.2.0.0' => '09000000'
  };
  cmp_deeply($test->{info}->e_parent(),
    $expected, q(Entity parent returned expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->e_parent(), {}, q(No data returns empty hash));
}

sub peth_port_ifindex : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'peth_port_ifindex');

  my $expected = {'1.1' => 504, '1.2' => 506, '1.3' => 508};

  cmp_deeply($test->{info}->peth_port_ifindex(),
    $expected, q(POE port 'ifIndex' mapping returns expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->peth_port_ifindex(),
    {}, q(No data returns empty hash));
}


# swA ports 1 and 2 are bridge ports mapped to ifIndex 521 and 522. MACs are
# synthetic. The device is swA, with swB as the root.
sub _stp_cache {
  my ($test, $protocol) = @_;
  my $info = $test->{info};
  $info->clear_cache();

  my $id = sub { pack('H*', shift) };
  my %store = (
    bp_index    => {1 => 521, 2 => 522},
    stp_p_id    => {1 => 1,   2 => 2},
    stp_p_state => {1 => 'forwarding', 2 => 'blocking'},
    stp_p_enable => {1 => 'enabled', 2 => 'enabled'},
    stp_p_bridge => {
      1 => $id->('800002000000000b'), 2 => $id->('800002000000000b'),
    },
    stp_p_port   => {1 => $id->('8001'), 2 => $id->('8002')},
  );
  my %cache = (
    _description  => 'Juniper Networks, Inc. ex4300-48t, kernel JUNOS 21.4R3',
    _b_mac        => $id->('02000000000a'),
    _stp_priority => 32768,
    _stp_root     => $id->('800002000000000b'),
  );

  if ($protocol eq 'mstp') {
    %store = (
      %store,
      jnx_mst_control       => {0 => 'start'},
      jnx_mst_brg_address   => {0 => $id->('02000000000a')},
      jnx_mst_cist_priority => {0 => 32768},
      jnx_mst_cist_root     => {0 => $id->('200002000000000b')},
      jnx_msti_priority     => {'0.1' => 4097, '0.2' => 32770},
      jnx_msti_root         => {
        '0.1' => $id->('100102000000000b'),
        '0.2' => $id->('800202000000000a'),
      },
      jnx_msti_vlans_1k => {'0.1' => "\x00\x40", '0.2' => "\x00\x00\x10"},
      jnx_msti_vlans_2k => {'0.1' => "\x00" x 16, '0.2' => "\x00" x 16},
      jnx_msti_vlans_3k => {'0.1' => "\x00" x 16, '0.2' => "\x00" x 16},
      jnx_msti_vlans_4k => {'0.1' => "\x00" x 16, '0.2' => "\x00" x 16},
      jnx_cist_p_state  => {1 => 'forwarding', 2 => 'discarding'},
      jnx_cist_p_role   => {1 => 'root',       2 => 'alternate'},
      jnx_cist_p_bridge => {
        1 => $id->('200002000000000b'), 2 => $id->('200002000000000b'),
      },
      jnx_cist_p_port => {1 => $id->('8001'), 2 => $id->('8002')},
      jnx_msti_p_state => {
        '1.1' => 'forwarding', '1.2' => 'forwarding',
        '2.1' => 'forwarding', '2.2' => 'discarding',
      },
      jnx_msti_p_role => {
        '1.1' => 'designated', '1.2' => 'root',
        '2.1' => 'designated', '2.2' => 'alternate',
      },
      jnx_msti_p_bridge => {
        map { $_ => $id->('100102000000000b') } qw/1.1 1.2 2.1 2.2/
      },
      jnx_msti_p_port => {
        map { $_ => $id->('8001') } qw/1.1 1.2 2.1 2.2/
      },
    );
  }
  elsif ($protocol eq 'vstp') {
    # Context ids 1 and 2 hold the VLAN 10 and VLAN 20 trees' control rows,
    # which are not VLAN ids. The context names carry the VLAN ids.
    my $iid = sub { join('.', length($_[0]), map { ord } split //, $_[0]) };
    my @names = ('', ':gribi', 'default', 'mgmt_junos', 'default::10',
      'default::20', '__mpls-oam__', 'default-switch', '__master.anon__',
      '__pfe_private__', 'default::x', 'default::10::2', 'xdefault::30');
    %store = (
      %store,
      jnx_mst_control       => {1 => 'shutdown', 2 => 'shutdown'},
      jnx_vacm_context_name => {map { $iid->($_) => $_ } @names},
    );
  }
  else {
    $store{jnx_mst_control} = {0 => 'shutdown'};
    $cache{_jnx_stp_version} = $protocol eq 'stp' ? 0 : 2;
  }

  $info->{store}{$_} = $store{$_} for keys %store;
  $info->{'_' . $_} = 1 for keys %store;
  $info->cache(\%cache);
  return;
}

sub _bridge {
  my ($priority, $ext, $mac) = @_;
  return {priority => $priority, sys_id_ext => $ext, mac => $mac,
    raw => ignore()};
}

sub _jnx_stp_protocol : Tests(5) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('mstp');
  is($info->_jnx_stp_protocol(), 'mstp', 'MST started: mstp');
  $test->_stp_cache('rstp');
  is($info->_jnx_stp_protocol(), 'rstp', 'dot1dStpVersion 2: rstp');
  $test->_stp_cache('stp');
  is($info->_jnx_stp_protocol(), 'stp', 'dot1dStpVersion 0: stp');
  $info->{_jnx_stp_version} = 'rstp';
  is($info->_jnx_stp_protocol(), 'rstp', 'Version as a label');
  delete $info->{_jnx_stp_version};
  is($info->_jnx_stp_protocol(), undef, 'No indicator: undef');
}

sub hasSTP : Tests(3) {
  my $test = shift;
  $test->_stp_cache('stp');
  is($test->{info}->hasSTP(), 1, 'stp');
  $test->_stp_cache('rstp');
  is($test->{info}->hasSTP(), 0, 'Not under rstp');
  $test->_stp_cache('mstp');
  is($test->{info}->hasSTP(), 0, 'Not under mstp');
}

sub hasRSTP : Tests(2) {
  my $test = shift;
  $test->_stp_cache('rstp');
  is($test->{info}->hasRSTP(), 1, 'rstp');
  $test->_stp_cache('mstp');
  is($test->{info}->hasRSTP(), 0, 'Not under mstp');
}

sub hasMSTP : Tests(2) {
  my $test = shift;
  $test->_stp_cache('mstp');
  is($test->{info}->hasMSTP(), 1, 'mstp');
  $test->_stp_cache('rstp');
  is($test->{info}->hasMSTP(), 0, 'Not under rstp');
}

sub stp_protocols : Tests(5) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('mstp');
  cmp_deeply($info->stp_protocols(), ['mstp'], 'mstp');
  $test->_stp_cache('rstp');
  cmp_deeply($info->stp_protocols(), ['rstp'], 'rstp');
  $test->_stp_cache('stp');
  cmp_deeply($info->stp_protocols(), ['stp'], 'stp');

  $test->_stp_cache('rstp');
  delete $info->{_jnx_stp_version};
  delete $info->{store}{jnx_mst_control};
  cmp_deeply($info->stp_protocols(), ['dot1d'],
    'BRIDGE-MIB tree and no indicator: dot1d');

  $info->clear_cache();
  is(scalar $info->stp_protocols(), undef, 'Nothing served: undef');
}

sub stp_trees : Tests(16) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('rstp');
  my $trees = $info->stp_trees();
  cmp_deeply([keys %$trees], ['cist.0'], 'RSTP: the CIST only');
  cmp_deeply([@{$trees->{'cist.0'}}{qw/protocol measured/}], ['rstp', 1],
    'RSTP: protocol, measured on JUNOS');
  cmp_deeply($trees->{'cist.0'}{root}{mac}, '02:00:00:00:00:0b', 'RSTP root');

  $test->_stp_cache('stp');
  $trees = $info->stp_trees();
  cmp_deeply([@{$trees->{'cist.0'}}{qw/protocol measured/}], ['stp', 0],
    'STP: protocol set, not measured');

  $test->_stp_cache('mstp');
  $trees = $info->stp_trees();
  cmp_deeply([sort keys %$trees], [qw/cist.0 msti.1 msti.2/],
    'MSTP: one tree per instance');
  cmp_deeply(
    $trees->{'cist.0'},
    {
      type           => 'cist',
      id             => 0,
      protocol       => 'mstp',
      measured       => 1,
      ports_complete => 1,
      contexts       => [{kind => 'none'}],
      bridge         => _bridge(32768, 0, '02:00:00:00:00:0a'),
      root           => _bridge(8192,  0, '02:00:00:00:00:0b'),
    },
    'MSTP: cist.0 record'
  );
  cmp_deeply(
    $trees->{'msti.1'}{bridge},
    _bridge(4096, 1, '02:00:00:00:00:0a'),
    'MSTP: msti.1 bridge, configured priority plus the MSTI number'
  );
  cmp_deeply(
    $trees->{'msti.2'}{bridge},
    _bridge(32768, 2, '02:00:00:00:00:0a'),
    'MSTP: msti.2 bridge'
  );
  is($trees->{'msti.1'}{root}{mac}, '02:00:00:00:00:0b', 'msti.1 root');
  is($info->stp_trees(), $trees, 'Memoized');

  $info->{store}{jnx_msti_p_state}{'9.1'} = 'forwarding';
  delete $info->{_stp_trees};
  $trees = $info->stp_trees();
  is($trees->{'msti.1'}{ports_complete}, 0,
    'Port row without a bp_index entry: that tree incomplete');
  is($trees->{'msti.2'}{ports_complete}, 1, 'Other trees stay complete');

  $test->_stp_cache('rstp');
  delete $info->{_jnx_stp_version};
  delete $info->{store}{jnx_mst_control};
  $trees = $info->stp_trees();
  cmp_deeply([keys %$trees], ['cist.0'], 'No indicator: BRIDGE-MIB tree');
  cmp_deeply([@{$trees->{'cist.0'}}{qw/protocol measured/}], [undef, 0],
    'No indicator: protocol undef, not measured');

  $test->_stp_cache('mstp');
  $info->session()->{Context} = 'vlan-10';
  is(scalar $info->stp_trees(), undef, 'Non-default context: nothing');
  $info->session()->{Context} = '';

  $info->clear_cache();
  cmp_deeply($info->stp_trees(), {}, 'Nothing served: no trees');
}

sub stp_tree_ports : Tests(15) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('mstp');
  my $rows = $info->stp_tree_ports('cist.0');
  cmp_deeply([sort keys %$rows], [521, 522], 'MSTP: CIST rows by ifIndex');
  cmp_deeply(
    $rows->{522},
    {
      tree_type         => 'cist',
      tree_id           => 0,
      state             => 'discarding',
      role              => 'alternate',
      role_raw          => 'alternate',
      enabled           => undef,
      designated_bridge => _bridge(8192, 0, '02:00:00:00:00:0b'),
      designated_port   => {priority => 128, port => 2, raw => '80:02'},
    },
    'MSTP: 522 discarding, alternate'
  );
  is($rows->{521}{role}, 'root', 'MSTP: 521 root');

  $rows = $info->stp_tree_ports('msti.2');
  is($rows->{522}{state}, 'discarding', 'msti.2: 522 discarding');
  is($rows->{522}{tree_id}, 2, 'msti.2: tree id');
  is($rows->{521}{role}, 'root', 'msti.2: 521 root');

  $info->{store}{jnx_msti_p_state}{'9.1'} = 'forwarding';
  delete $info->{_stp_trees};
  cmp_deeply([sort keys %{$info->stp_tree_ports('msti.1')}], [521, 522],
    'Row at an unmapped bridge port is absent');
  is($info->stp_trees()->{'msti.1'}{ports_complete}, 0, 'and flagged');

  is(scalar $info->stp_tree_ports('msti.7'), undef, 'Unknown key: nothing');
  like($info->error(1), qr/stp_tree_ports\(\) has no tree 'msti\.7'/,
    'Error names the method');

  $test->_stp_cache('rstp');
  $rows = $info->stp_tree_ports('cist.0');
  cmp_deeply([sort keys %$rows], [521, 522], 'RSTP: BRIDGE-MIB rows');
  is($rows->{522}{state}, 'blocking', 'RSTP: state');
  is($rows->{522}{enabled}, 1, 'RSTP: enabled from dot1dStpPortEnable');
  $test->_stp_cache('stp');
  cmp_deeply([sort keys %{$info->stp_tree_ports('cist.0')}], [521, 522],
    'STP: BRIDGE-MIB rows');
  $info->clear_cache();
  is(scalar $info->stp_tree_ports('cist.0'), undef, 'Nothing served: none');
}

sub stp_trees_complete : Tests(5) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  is($info->stp_trees_complete(), 0, 'Nothing served');
  $test->_stp_cache('mstp');
  is($info->stp_trees_complete(), 1, 'MSTP');
  $test->_stp_cache('rstp');
  is($info->stp_trees_complete(), 1, 'RSTP');
  delete $info->{_jnx_stp_version};
  delete $info->{store}{jnx_mst_control};
  delete $info->{_stp_trees};
  is($info->stp_trees_complete(), 0, 'dot1d fallback: protocol unknown');
  $info->clear_cache();
  is($info->stp_trees_complete(), 0, 'Cleared again');
}

sub hasVSTP : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('vstp');
  is($info->hasVSTP(), 1, 'vstp');
  is($info->hasRSTP(), 0, 'Not rstp');
  is($info->hasMSTP(), 0, 'Not mstp');
  $test->_stp_cache('rstp');
  is($info->hasVSTP(), 0, 'Not under rstp');
}

sub _jnx_stp_protocol__vstp : Tests(6) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('vstp');
  is($info->_jnx_stp_protocol(), 'vstp', 'Control only at other contexts');

  $test->_stp_cache('vstp');
  $info->{store}{jnx_msti_priority} = {'1.1' => 4097};
  $info->{_jnx_msti_priority} = 1;
  is($info->_jnx_stp_protocol(), undef, 'MSTI priority row: not vstp');

  $test->_stp_cache('vstp');
  $info->{_jnx_stp_version} = 2;
  is($info->_jnx_stp_protocol(), 'rstp', 'dot1dStpVersion wins');

  $test->_stp_cache('vstp');
  $info->{walk_status}{jnx_mst_control}
    = {complete => 0, reason => 'timeout'};
  is($info->_jnx_stp_protocol(), undef, 'Incomplete control walk: undef');
  delete $info->{store}{stp_p_id};
  delete $info->{_stp_root};
  is(scalar $info->stp_protocols(), undef, 'stp_protocols undef');
  is($info->stp_trees_complete(), 0, 'stp_trees_complete 0');
}

sub stp_protocols__vstp : Tests(1) {
  my $test = shift;

  $test->_stp_cache('vstp');
  cmp_deeply($test->{info}->stp_protocols(), ['vstp'], 'vstp');
}

sub _context_kinds : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('vstp');
  cmp_deeply($info->context_kinds('stp'), ['vlan'], 'VSTP: vlan for stp');
  is($info->context_kinds('fdb'), undef, 'VSTP: nothing for fdb');
  $test->_stp_cache('mstp');
  is($info->context_kinds('stp'), undef, 'MSTP: nothing');
  $test->_stp_cache('rstp');
  is($info->context_kinds('stp'), undef, 'RSTP: nothing');
}

sub _snmp_context : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  cmp_deeply(
    $info->snmp_context('vlan', 10),
    {kind => 'vlan', id => 10, v2c => 'default::10@%s', v3 => 'default::10'},
    'vlan context: instance first for v2c'
  );
  is($info->snmp_context('mst', 1), undef, 'No mst context');
}

sub _jnx_vstp_vlans : Tests(5) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('vstp');
  cmp_deeply($info->_jnx_vstp_vlans(), [10, 20],
    'VLAN ids from default::N names only, not control context ids');

  my $iid_9 = '10.100.101.102.97.117.108.116.58.58.57';
  $info->{store}{jnx_vacm_context_name}{$iid_9} = 'default::9';
  cmp_deeply($info->_jnx_vstp_vlans(), [9, 10, 20], 'Sorted numerically');

  $test->_stp_cache('vstp');
  $info->{store}{jnx_vacm_context_name} = {};
  cmp_deeply($info->_jnx_vstp_vlans(), [], 'Not served: empty');

  $test->_stp_cache('vstp');
  delete $info->{store}{jnx_vacm_context_name};
  delete $info->{_jnx_vacm_context_name};
  cmp_deeply($info->_jnx_vstp_vlans(), [], 'Absent: empty');
  $info->clear_cache();
  cmp_deeply($info->_jnx_vstp_vlans(), [], 'Cleared: empty');
}

sub stp_trees__vstp : Tests(8) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('vstp');
  my $trees = $info->stp_trees();
  cmp_deeply([sort keys %$trees], [qw/vlan.10 vlan.20/],
    'Exactly the VSTP VLANs');
  cmp_deeply(
    $trees->{'vlan.20'},
    {
      type           => 'vlan',
      id             => 20,
      vlan           => 20,
      protocol       => 'vstp',
      measured       => 1,
      ports_complete => 1,
      bridge         => undef,
      root           => undef,
      contexts       => [{
        kind => 'vlan', id => 20, v2c => 'default::20@%s',
        v3 => 'default::20',
      }],
    },
    'vlan.20 record'
  );
  is($info->stp_trees(), $trees, 'Memoized');

  $test->_stp_cache('vstp');
  $info->{store}{jnx_vacm_context_name} = {};
  cmp_deeply($info->stp_trees(), {}, 'vacmContextName not served: no trees');

  $test->_stp_cache('vstp');
  $info->session()->{Context} = 'default::20';
  is(scalar $info->stp_trees(), undef, 'Non-default context: nothing');
  $info->session()->{Context} = '';

  $test->_stp_cache('mstp');
  cmp_deeply([sort keys %{$info->stp_trees()}], [qw/cist.0 msti.1 msti.2/],
    'MSTP unchanged');
  $test->_stp_cache('rstp');
  cmp_deeply([keys %{$info->stp_trees()}], ['cist.0'], 'RSTP unchanged');
}

sub stp_tree_ports__vstp : Tests(9) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('vstp');
  is(scalar $info->stp_tree_ports('vlan.20'), undef,
    'Default context: nothing');
  like($info->error(1), qr/default::20/, 'Error names the context');
  like($info->error(1), qr/stp_tree_ports/, 'Error names the method');

  $test->_stp_cache('vstp');
  $info->{args}{Community} = 'public';
  $info->session()->{Community} = 'default::20@public';
  my $rows = $info->stp_tree_ports('vlan.20');
  cmp_deeply([sort keys %$rows], [521, 522], 'In context: rows by ifIndex');
  is($rows->{522}{state}, 'blocking', '522 blocking');
  is($rows->{522}{tree_type}, 'vlan', 'Labeled vlan');
  is($rows->{522}{tree_id}, 20, 'Labeled 20');

  is(scalar $info->stp_tree_ports('vlan.10'), undef,
    'Context of another VLAN: nothing');
  like($info->error(1), qr/default::10/, 'Error names the wanted context');
  $info->session()->{Community} = 'public';
}

sub stp_trees_complete__vstp : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('vstp');
  is($info->stp_trees_complete(), 1, 'vacmContextName served');

  $test->_stp_cache('vstp');
  $info->{walk_status}{jnx_vacm_context_name}
    = {complete => 0, reason => 'timeout'};
  is($info->stp_trees_complete(), 0, 'Context walk incomplete');

  $test->_stp_cache('vstp');
  $info->{store}{jnx_vacm_context_name} = {};
  is($info->stp_trees_complete(), 0, 'vacmContextName not served');

  $test->_stp_cache('vstp');
  $info->{store}{jnx_vacm_context_name} = {'0' => ''};
  is($info->stp_trees_complete(), 0, 'No VSTP contexts named');
}

sub stp_vlan_map : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('mstp');
  cmp_deeply(scalar $info->stp_vlan_map(), {10 => 'msti.1', 20 => 'msti.2'},
    'MSTP: only VLANs mapped to an MSTI');

  $info->{store}{jnx_msti_vlans_2k}{'0.2'} = "\x80" . "\x00" x 15;
  $info->{store}{jnx_msti_vlans_3k}{'0.2'} = "\x80" . "\x00" x 15;
  $info->{store}{jnx_msti_vlans_4k}{'0.1'} = "\x00" x 127 . "\x0f";
  cmp_deeply(
    scalar $info->stp_vlan_map(),
    {
      10 => 'msti.1', 20 => 'msti.2', 1025 => 'msti.2', 2049 => 'msti.2',
      4093 => 'msti.1', 4094 => 'msti.1',
    },
    'Bitmap origins 1025, 2049, 3073; VLANs capped at 4094'
  );

  $test->_stp_cache('rstp');
  is(scalar $info->stp_vlan_map(), undef, 'RSTP: nothing');
  $info->clear_cache();
  is(scalar $info->stp_vlan_map(), undef, 'Nothing served: nothing');
}

1;
