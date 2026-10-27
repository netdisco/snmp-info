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
  delete $info->{walk_status};

  my $id = sub { pack('H*', shift) };
  my %store = (bp_index => {1 => 521, 2 => 522});
  my %cache = (
    _description  => 'Juniper Networks, Inc. ex4300-48t, kernel JUNOS 21.4R3',
    _b_mac        => $id->('02000000000a'),
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
      jnx_msti_vlans_1k => {
        '0.1' => "\x00\x40" . "\x00" x 126,
        '0.2' => "\x00\x00\x10" . "\x00" x 125,
      },
      jnx_msti_vlans_2k => {'0.1' => "\x00" x 128, '0.2' => "\x00" x 128},
      jnx_msti_vlans_3k => {'0.1' => "\x00" x 128, '0.2' => "\x00" x 128},
      jnx_msti_vlans_4k => {'0.1' => "\x00" x 128, '0.2' => "\x00" x 128},
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
      jnx_cist_p_enable => {1 => 'enabled', 2 => 'enabled'},
      jnx_msti_p_enable => {map { $_ => 'enabled' } qw/1.1 1.2 2.1 2.2/},
    );
  }
  elsif ($protocol eq 'vstp' or $protocol eq 'vs1') {
    # Context ids 1 and 2 hold the VLAN 10 and VLAN 20 trees' control rows,
    # which are not VLAN ids. The context names carry the VLAN ids. 'vs1'
    # adds VLAN 30 in virtual switch vs1, at context id 3 and bridge port 3.
    my @names = ('', ':gribi', 'default', 'mgmt_junos', 'default::10',
      'default::20', '__mpls-oam__', 'default-switch', '__master.anon__',
      '__pfe_private__', 'default::x', 'default::10::2');
    my %control = (1 => 'shutdown', 2 => 'shutdown');
    if ($protocol eq 'vs1') {
      push @names, 'vs1', 'vs1::30';
      $control{3} = 'shutdown';
      $store{bp_index}{3} = 523;
    }
    %store = (
      %store,
      jnx_mst_control       => \%control,
      jnx_vacm_context_name => _context_name_rows(@names),
    );
  }
  else {
    # 'rstp_vstp': RSTP in the default context beside VSTP on VLAN 20, whose
    # control row sits at context id 1
    my ($bridge_store, $bridge_cache) = $test->_bridge_mib_rows();
    my %control = (0 => 'shutdown');
    if ($protocol eq 'rstp_vstp') {
      $control{1} = 'shutdown';
      $store{jnx_vacm_context_name} = _context_name_rows('', ':gribi',
        'default', 'mgmt_junos', 'default::20', '__mpls-oam__',
        'default-switch', '__master.anon__', '__pfe_private__');
    }
    %store = (%store, %$bridge_store, jnx_mst_control => \%control);
    %cache = (%cache, %$bridge_cache,
      _jnx_stp_version => $protocol eq 'stp' ? 0 : 2);
  }

  $info->{store}{$_} = $store{$_} for keys %store;
  $info->{'_' . $_} = 1 for keys %store;
  $info->cache(\%cache);
  return;
}

# What dot1dStp serves: the default context under RSTP and STP, and a VSTP
# VLAN's own context (the default context serves none under MSTP or VSTP)
sub _bridge_mib_rows {
  my $id = sub { pack('H*', shift) };
  my %store = (
    stp_p_id    => {1 => 1,   2 => 2},
    stp_p_state => {1 => 'forwarding', 2 => 'blocking'},
    stp_p_enable => {1 => 'enabled', 2 => 'enabled'},
    stp_p_bridge => {
      1 => $id->('800002000000000b'), 2 => $id->('800002000000000b'),
    },
    stp_p_port   => {1 => $id->('8001'), 2 => $id->('8002')},
  );
  my %cache = (
    _stp_priority => 32768,
    _stp_root     => $id->('800002000000000b'),
  );
  return (\%store, \%cache);
}

# vacmContextName is indexed by the name as a length-prefixed OID suffix
sub _context_name_rows {
  my @names = @_;
  my $iid = sub { join('.', length($_[0]), map { ord } split //, $_[0]) };
  return {map { $iid->($_) => $_ } @names};
}

# The session sits in the VLAN's own context, which serves that VLAN's tree
# as BRIDGE-MIB, dot1dStpVersion 2 and its own MST control row at id 1. Port
# 1 leads to the root (swB, 0b) and port 2 to the designated bridge swC (0c),
# both on designated port 1, with this bridge at 32768 plus the VLAN, as VLAN
# 20's context serves under VSTP.
sub _enter_vstp_context {
  my ($test, $vlan) = @_;
  my $info = $test->{info};

  my $id = sub { pack('H*', sprintf('%04x%s', @_)) };
  my ($store, $cache) = $test->_bridge_mib_rows();
  $store->{stp_p_bridge} = {
    1 => $id->(0x1000 + $vlan, '02000000000b'),
    2 => $id->(0x8000 + $vlan, '02000000000c'),
  };
  $store->{stp_p_port} = {1 => pack('H*', '8001'), 2 => pack('H*', '8001')};
  $info->{store}{$_} = $store->{$_} for keys %$store;
  $info->{'_' . $_} = 1 for keys %$store;
  $info->{store}{jnx_mst_control} = {1 => 'shutdown'};
  $info->cache({
    %$cache,
    _stp_priority    => 0x8000 + $vlan,
    _stp_root        => $id->(0x1000 + $vlan, '02000000000b'),
    _jnx_stp_version => 2,
  });
  $info->{args}{Community} = 'public';
  $info->session()->{Community} = "default::$vlan\@public";
  return;
}

# Virtual switch vs1's VLAN 30 context, which serves only bridge port 3, as
# blocking and disabled, with this bridge as root
sub _enter_vs1_context {
  my $test = shift;
  my $info = $test->{info};

  my $own = pack('H*', '801e02000000000a');
  my %store = (
    stp_p_id        => {3 => 3},
    stp_p_state     => {3 => 'blocking'},
    stp_p_enable    => {3 => 'disabled'},
    stp_p_bridge    => {3 => $own},
    stp_p_port      => {3 => pack('H*', '8003')},
    jnx_mst_control => {3 => 'shutdown'},
  );
  $info->{store}{$_} = $store{$_} for keys %store;
  $info->{'_' . $_} = 1 for keys %store;
  $info->cache({_stp_priority => 32798, _stp_root => $own,
    _jnx_stp_version => 2});
  $info->{args}{Community} = 'public';
  $info->session()->{Community} = 'vs1::30@public';
  return;
}

sub _bridge {
  my ($priority, $ext, $mac) = @_;
  return {priority => $priority, sys_id_ext => $ext, mac => $mac,
    raw => ignore()};
}

sub _jnx_stp_protocols : Tests(5) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('mstp');
  cmp_deeply($info->_jnx_stp_protocols(), ['mstp'], 'MST started: mstp');
  $test->_stp_cache('rstp');
  cmp_deeply($info->_jnx_stp_protocols(), ['rstp'],
    'dot1dStpVersion 2: rstp');
  $test->_stp_cache('stp');
  cmp_deeply($info->_jnx_stp_protocols(), ['stp'], 'dot1dStpVersion 0: stp');
  $info->{_jnx_stp_version} = 'rstp';
  delete $info->{_jnx_stp_protocols};
  cmp_deeply($info->_jnx_stp_protocols(), ['rstp'], 'Version as a label');
  delete $info->{_jnx_stp_version};
  delete $info->{_jnx_stp_protocols};
  cmp_deeply($info->_jnx_stp_protocols(), [], 'No indicator: empty');
}

sub _jnx_stp_protocols__memoized : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('rstp_vstp');
  my $first = $info->_jnx_stp_protocols();
  cmp_deeply($first, ['rstp', 'vstp'], 'First call');
  delete $info->{store}{jnx_mst_control};
  delete $info->{_jnx_mst_control};
  cmp_deeply($info->_jnx_stp_protocols(), ['rstp', 'vstp'],
    'Control rows gone: the same list');
  $info->clear_cache();
  ok(!exists $info->{_jnx_stp_protocols}, 'clear_cache drops it');
  cmp_deeply($info->_jnx_stp_protocols(), [], 'Recomputed: nothing served');
}

sub stp_protocols__rstp_beside_vstp : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('rstp_vstp');
  cmp_deeply($info->stp_protocols(), ['rstp', 'vstp'], 'rstp, then vstp');
  is($info->hasRSTP(), 1, 'hasRSTP');
  is($info->hasVSTP(), 1, 'hasVSTP');
  cmp_deeply($info->context_kinds('stp'), ['vlan'], 'vlan contexts for stp');
}

sub stp_trees__rstp_beside_vstp : Tests(5) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('rstp_vstp');
  my $trees = $info->stp_trees();
  cmp_deeply([sort keys %$trees], [qw/cist.0 vlan.20/],
    'The CIST and the VSTP VLAN');
  is($trees->{'cist.0'}{protocol}, 'rstp', 'cist.0 rstp');
  cmp_deeply($trees->{'cist.0'}{contexts}, [{kind => 'none'}],
    'cist.0 in the default context');
  cmp_deeply([@{$trees->{'vlan.20'}}{qw/protocol instance/}],
    ['vstp', 'default'], 'vlan.20 vstp in instance default');
  is($trees->{'vlan.20'}{contexts}[0]{v2c}, 'default::20@%s',
    'vlan.20 v2c community');
}

sub stp_trees__virtual_switch : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('vs1');
  my $trees = $info->stp_trees();
  cmp_deeply([sort keys %$trees], [qw/vlan.10 vlan.20 vlan.30@vs1/],
    'Default instance VLANs, and vs1 keyed by its instance');
  cmp_deeply(
    $trees->{'vlan.30@vs1'},
    {
      type           => 'vlan',
      id             => 30,
      vlan           => 30,
      instance       => 'vs1',
      protocol       => 'vstp',
      measured       => 1,
      ports_complete => 1,
      bridge         => undef,
      root           => undef,
      contexts       => [{
        kind => 'vlan', id => 30, instance => 'vs1', v2c => 'vs1::30@%s',
        v3 => 'vs1::30',
      }],
    },
    'vlan.30@vs1 record, measured'
  );
  cmp_deeply([@{$trees->{'vlan.10'}}{qw/instance measured/}],
    ['default', 1], 'vlan.10 in default, measured');
  is($info->stp_trees_complete(), 1, 'Complete');
}

sub stp_tree_ports__virtual_switch : Tests(8) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('vs1');
  is(scalar $info->stp_tree_ports('vlan.30@vs1'), undef,
    'Default context: nothing');
  like($info->error(1), qr/'vs1::30\@<community>'/,
    'Error names the v2c community');

  $test->_enter_vs1_context();
  my $rows = $info->stp_tree_ports('vlan.30@vs1');
  cmp_deeply([keys %$rows], [523], 'In vs1::30: port 3 as ifIndex 523');
  is($rows->{523}{state}, 'blocking', '523 blocking');
  is($rows->{523}{enabled}, 0, '523 disabled');
  cmp_deeply([@{$rows->{523}}{qw/tree_type tree_id/}], ['vlan', 30],
    'Labeled vlan 30');

  $info->session()->{Community} = 'default::30@public';
  is(scalar $info->stp_tree_ports('vlan.30@vs1'), undef,
    'default::30: refused');
  like($info->error(1), qr/served in context 'vs1::30'/,
    'Error names the wanted context');
  $info->session()->{Community} = 'public';
}

sub stp_tree_ports__vstp_v3 : Tests(3) {
  my $test = shift;
  my $info = $test->{info};
  my $session = $info->session();

  # VLAN 10's context over SNMPv3: this bridge is the root, both ports
  # forwarding
  $test->_stp_cache('vstp');
  my $own = pack('H*', '100a02000000000a');
  my %store = (
    stp_p_id     => {1 => 1, 2 => 2},
    stp_p_state  => {1 => 'forwarding', 2 => 'forwarding'},
    stp_p_enable => {1 => 'enabled', 2 => 'enabled'},
    stp_p_bridge => {1 => $own, 2 => $own},
    stp_p_port   => {1 => pack('H*', '8001'), 2 => pack('H*', '8002')},
    jnx_mst_control => {2 => 'shutdown'},
  );
  $info->{store}{$_} = $store{$_} for keys %store;
  $info->{'_' . $_} = 1 for keys %store;
  $info->cache({_stp_priority => 4106, _stp_root => $own,
    _jnx_stp_version => 2});
  local @{$session}{qw/Version Context/} = (3, 'default::10');

  my $rows = $info->stp_tree_ports('vlan.10');
  cmp_deeply([sort keys %$rows], [521, 522], 'Rows by ifIndex');
  is($rows->{522}{state}, 'forwarding', '522 forwarding');
  cmp_deeply($rows->{522}{designated_bridge},
    _bridge(4096, 10, '02:00:00:00:00:0a'), '522 designated bridge');
}

# Default-instance trees are keyed vlan.N, so vlan.N@default names no tree
sub stp_tree_ports__explicit_default_instance__is_refused : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('vstp');
  is(scalar $info->stp_tree_ports('vlan.20@default'), undef,
    'Default context: nothing');
  like($info->error(1), qr/has no tree 'vlan\.20\@default'/,
    'Error: no such tree');

  $test->_enter_vstp_context(20);
  is(scalar $info->stp_tree_ports('vlan.20@default'), undef,
    'In default::20: nothing');
  ok(scalar keys %{$info->stp_tree_ports('vlan.20')}, 'vlan.20 still reads');
  $info->session()->{Community} = 'public';
}

sub stp_trees_complete__rstp_beside_vstp : Tests(1) {
  my $test = shift;
  $test->_stp_cache('rstp_vstp');
  is($test->{info}->stp_trees_complete(), 1, 'One name, one control row');
}

sub stp_trees_complete__virtual_switch : Tests(1) {
  my $test = shift;
  $test->_stp_cache('vs1');
  is($test->{info}->stp_trees_complete(), 1, 'Three names, three rows');
}

sub stp_trees_complete__phantom_context : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('rstp');
  $info->{store}{jnx_mst_control} = {0 => 2};
  $test->_set_context_names('default', 'default::10');
  cmp_deeply([keys %{$info->stp_trees()}], ['cist.0'],
    'No control row away from context 0: no VSTP tree');
  is($info->stp_trees_complete(), 0, 'A name with no tree: incomplete');
}

sub stp_trees_complete__name_hidden : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('vstp');
  $test->_set_context_names('default::10');
  cmp_deeply([keys %{$info->stp_trees()}], ['vlan.10'], 'One tree named');
  is($info->stp_trees_complete(), 0, 'Two control rows: incomplete');
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
  cmp_deeply([@{$trees->{'cist.0'}}{qw/protocol measured/}], ['stp', 1],
    'STP: protocol set, measured on JUNOS');

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

sub stp_tree_ports : Tests(18) {
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
      enabled           => 1,
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

  $info->{store}{jnx_msti_p_enable}{'1.2'} = 'disabled';
  delete $info->{store}{jnx_msti_p_enable}{'2.2'};
  $rows = $info->stp_tree_ports('msti.2');
  is($rows->{521}{enabled}, 0, 'msti.2: ForcePortState disabled(0) is 0');
  is($rows->{522}{enabled}, undef, 'msti.2: no ForcePortState row is undef');
  $info->{store}{jnx_cist_p_enable}{2} = 0;
  is($info->stp_tree_ports('cist.0')->{522}{enabled}, 0,
    'cist.0: numeric disabled(0) is 0');

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
  delete $info->{_jnx_stp_protocols};
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

sub _jnx_stp_protocols__vstp : Tests(14) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('vstp');
  cmp_deeply($info->_jnx_stp_protocols(), ['vstp'],
    'Control only at other contexts');

  $test->_stp_cache('vstp');
  $info->{store}{jnx_msti_priority} = {'1.1' => 4097};
  $info->{_jnx_msti_priority} = 1;
  cmp_deeply($info->_jnx_stp_protocols(), [], 'MSTI priority row: not vstp');

  $test->_stp_cache('vstp');
  $info->{_jnx_stp_version} = 2;
  cmp_deeply($info->_jnx_stp_protocols(), ['rstp', 'vstp'],
    'dot1dStpVersion beside VSTP: both');

  $test->_stp_cache('vstp');
  $info->{store}{jnx_mst_control}
    = {0 => 'start', 1 => 'shutdown', 2 => 'shutdown'};
  cmp_deeply($info->_jnx_stp_protocols(), ['mstp'],
    'MST started at context 0: mstp alone');

  $test->_stp_cache('vstp');
  $info->{store}{jnx_mst_control} = {0 => 2, 1 => 2};
  cmp_deeply($info->_jnx_stp_protocols(), ['vstp'],
    'A shutdown row at context 0 does not rule VSTP out');

  $test->_stp_cache('vstp');
  $info->{store}{jnx_mst_control} = {1 => 'start', 2 => 'start'};
  cmp_deeply($info->_jnx_stp_protocols(), [], 'MSTP in instances: none');
  is(scalar $info->stp_protocols(), undef, 'MX960 shape: no protocol');
  is($info->hasVSTP(), 0, 'MX960 shape: hasVSTP 0');
  cmp_deeply($info->stp_trees(), {}, 'MX960 shape: no trees');

  $test->_stp_cache('vstp');
  $info->{store}{jnx_mst_control} = {1 => 'shutdown', 2 => 'start'};
  cmp_deeply($info->_jnx_stp_protocols(), [], 'One row started: not vstp');

  $test->_stp_cache('vstp');
  $info->{store}{jnx_mst_control} = {1 => 2, 2 => 2};
  cmp_deeply($info->_jnx_stp_protocols(), ['vstp'],
    'Numeric shutdown(2) rows: vstp');

  $test->_stp_cache('vstp');
  $info->{walk_status}{jnx_mst_control}
    = {complete => 0, reason => 'timeout'};
  cmp_deeply($info->_jnx_stp_protocols(), [],
    'Incomplete control walk: none');
  is(scalar $info->stp_protocols(), undef, 'stp_protocols undef');
  is($info->stp_trees_complete(), 0, 'stp_trees_complete 0');
}

# jnx_msti_priority is walked, not primed, so the walk records the timeout
sub _jnx_is_vstp__msti_walk_times_out__is_0 : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('vstp');
  My::Test::Class::set_fault($test->mock_session,
    {op => 'getnext', after => 0, ErrorNum => -24, ErrorStr => 'Timeout',
      leaf => 'JUNIPER-MIMSTP-MIB::jnxMIMstMstiBridgePriority'});
  cmp_deeply($info->_jnx_stp_protocols(), [],
    'Timed-out MSTI walk: not vstp');
  cmp_deeply($info->walk_status('jnx_msti_priority'),
    superhashof({complete => 0, reason => 'timeout'}),
    'The walk recorded the timeout');
  is($info->hasVSTP(), 0, 'Not hasVSTP');
}

sub _jnx_is_vstp__sparse_control_row__no_warning : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('vstp');
  $info->{store}{jnx_mst_control} = {1 => undef, 2 => 'shutdown'};
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  cmp_deeply($info->_jnx_stp_protocols(), [], 'Undefined row: not vstp');
  cmp_deeply(\@warnings, [], 'No warning');
}

sub stp_protocols__vstp : Tests(7) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('vstp');
  cmp_deeply($info->stp_protocols(), ['vstp'], 'vstp');

  $test->_enter_vstp_context(20);
  is(scalar $info->stp_protocols(), undef, 'VLAN context: nothing');
  like($info->error(1), qr/default context/, 'Error names the context');
  is($info->hasRSTP(), 0, 'VLAN context: not rstp');
  is($info->hasVSTP(), 0, 'VLAN context: no answer');
  is($info->context_kinds('stp'), undef, 'VLAN context: no kinds');
  my $rows = $info->stp_tree_ports('vlan.20');
  cmp_deeply([sort keys %$rows], [521, 522],
    'VLAN context: its ports still read');
  $info->session()->{Community} = 'public';
}

sub context_kinds__vrf__is_vrf : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  cmp_deeply($info->context_kinds('vrf'), ['vrf'], 'One context per instance');
  $test->_stp_cache('vstp');
  cmp_deeply($info->context_kinds('stp'), ['vlan'], 'stp unchanged: VSTP');
  $test->_stp_cache('rstp');
  is($info->context_kinds('stp'), undef, 'stp unchanged: RSTP');
}

sub snmp_context__vrf__junos_order : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  my $context = $info->snmp_context('vrf', 'red');
  cmp_deeply($context,
    {kind => 'vrf', id => 'red', v2c => 'red@%s', v3 => 'red'},
    'Instance name first, v3 is the instance name');
  is(sprintf($context->{v2c}, 'public'), 'red@public', 'Junos order');
  $info->{args}{Community} = 'public';
  $info->session()->{Community} = 'red@public';
  is($info->_walk_context(), 'red', 'The context is derived from red@public');
}

sub vrf_neighbors__red_in_default_context__is_refused : Tests(2) {
  my $test = shift;
  my $info = $test->_prime_jnx_context('default');

  is($info->vrf_neighbors('red'), undef, 'red is refused in the default context');
  like($info->error(1),
    qr/vrf_neighbors\(\) reads instance 'red' from its own context on this device, but this session is in the default context\. Switch with snmp_context\('vrf', 'red'\) first\./,
    'The error names the switch to red');
}

sub snmp_context__vrf_default__nothing : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  is($info->snmp_context('vrf', 'default'), undef, 'default: nothing');
  is($info->snmp_context('vrf', q()),       undef, 'empty name: nothing');
  is($info->snmp_context('vrf'),            undef, 'no name: nothing');
}

sub snmp_context__vlan__unchanged : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  cmp_deeply(
    $info->snmp_context('vlan', 10),
    {kind => 'vlan', id => 10, v2c => 'default::10@%s', v3 => 'default::10'},
    'vlan context unchanged'
  );
  is($info->snmp_context('mst', 1), undef, 'Other kinds: nothing');
}

sub vrf_neighbors__session_red_at_public__reads_red : Tests(5) {
  my $test = shift;
  my $info = $test->_prime_jnx_context('red');

  is($info->session()->{Community}, 'red@public', 'The session is red@public');
  $info->clear_error();
  my $rows = $info->vrf_neighbors('red') || {};
  cmp_deeply([sort { $a <=> $b } keys %{{map { $_->{ifindex} => 1 }
      values %$rows}}], [536, 545], 'red reads its rows in red@public');
  is($info->error(1), undef, 'No error for red');
  is($info->vrf_neighbors('blue'), undef, 'blue is refused');
  like($info->error(1),
    qr/vrf_neighbors\(\) reads instance 'blue' from its own context, but this session is in context 'red'\. Switch with snmp_context\('vrf', 'blue'\) first\./,
    'The error names both contexts and the switch');
  $info->session()->{Community} = 'public';
}

# Junos 26.2 vJunos-switch: mplsL3VpnVrfTable lists red and grey, and
# vacmContextName lists those with blue, green and the internal names.
sub _vrf_cache {
  my %opt = @_;
  my $iid = sub { join('.', length($_[0]), map { ord } split //, $_[0]) };
  my @vacm = ('', qw/red blue grey green :gribi default mgmt_junos
    __mpls-oam__ default-switch __master.anon__ __pfe_private__
    __juniper_private2__ __juniper_private4__ __juniper_services__/,
    @{$opt{vacm_extra} || []});
  my %jnx = map { ("$_->[1].".$iid->($_->[0]) => $_->[0]) } @{$opt{jnx} || []};
  $jnx{"2.".$iid->($_)} = $_ for qw/red grey/;
  return {
    _vrf_l3vpn_rd    => 1,
    _vrf_l3vpn_descr => 1,
    _vrf_l3vpn_oper  => 1,
    _vrf_l3vpn_rt    => 1,
    _vrf_l3vpn_if    => 1,
    _jnx_vacm_context_name => 1,
    _vrf_jnx_vpn_status => 1,
    store => {
      vrf_l3vpn_rd    => {$iid->('red') => '64512:30', $iid->('grey') => '64512:34'},
      vrf_l3vpn_descr => {$iid->('red') => '', $iid->('grey') => ''},
      vrf_l3vpn_oper  => {$iid->('red') => 'up', $iid->('grey') => 'up'},
      vrf_l3vpn_rt    => {},
      vrf_l3vpn_if    => {},
      jnx_vacm_context_name => {map { $iid->($_) => $_ } @vacm},
      vrf_jnx_vpn_status => \%jnx,
    },
  };
}

sub _prime_vrf {
  my ($test, %opt) = @_;
  my $info = $test->{info};
  $info->clear_cache();
  $info->clear_walk_status();
  $info->cache(_vrf_cache(%opt));
  return $info;
}

sub vrf_instances : Tests(16) {
  my $test = shift;
  my $info = $test->_prime_vrf();

  my $instances = $info->vrf_instances();
  cmp_deeply([sort keys %$instances],
    [qw/blue default green grey mgmt_junos red/],
    'MPLS rows, vacm virtual routers and default; no internal name');
  foreach my $name (qw/blue green mgmt_junos/) {
    is($instances->{$name}{kind}, 'virtual-router', "$name is a virtual router");
    is($instances->{$name}{sources}{list}, 'SNMP-VIEW-BASED-ACM-MIB',
      "$name is listed by vacmContextName");
    is($instances->{$name}{listed_by}, 'device', "$name listed by the device");
  }
  is($instances->{blue}{contexts}[0]{v2c}, 'blue@%s', 'Junos order');
  is($instances->{red}{kind}, 'vrf', 'red is MPLS-listed');
  is($instances->{red}{rd}, '64512:30', 'red keeps its route distinguisher');
  is($instances->{red}{sources}{list}, 'MPLS-L3VPN-STD-MIB',
    'red keeps its list source');
  is($instances->{grey}{kind}, 'vrf', 'grey is MPLS-listed');
  is($instances->{default}{kind}, 'default', 'default is the default record');
}

sub vrf_instances__vpls_in_jnx_vpn__excluded : Tests(2) {
  my $test = shift;
  my $info = $test->_prime_vrf(
    vacm_extra => ['vpls1'], jnx => [['vpls1', 4]]);

  my $instances = $info->vrf_instances();
  ok(!exists $instances->{vpls1}, 'A VPLS row in jnxVpnTable is no instance');
  cmp_deeply([sort keys %$instances], [qw/blue default green grey mgmt_junos red/],
    'The rest is unchanged');
}

sub vrf_instances__bgp_ip_vpn_in_jnx_vpn__kept : Tests(2) {
  my $test = shift;
  my $info = $test->_prime_vrf(
    vacm_extra => ['cust'], jnx => [['cust', 2]]);

  my $instances = $info->vrf_instances();
  is($instances->{cust}{kind}, 'vrf', 'A bgpIpVpn row is kept as a VRF');
  is($instances->{cust}{sources}{list}, 'SNMP-VIEW-BASED-ACM-MIB',
    'Listed by vacmContextName');
}

sub vrf_instances__vstp_context_name__not_an_instance : Tests(1) {
  my $test = shift;
  my $info = $test->_prime_vrf(vacm_extra => ['default::10', 'red::20']);

  cmp_deeply([sort keys %{$info->vrf_instances()}],
    [qw/blue default green grey mgmt_junos red/],
    'VSTP contexts are not instances');
}

sub vrf_instances__internal_name_in_mpls__dropped : Tests(2) {
  my $test = shift;
  my $info = $test->_prime_vrf();
  my $name = '__juniper_private1__';
  my $iid = join('.', length($name), map { ord } split //, $name);
  $info->{store}{vrf_l3vpn_rd}{$iid} = '';

  ok(!exists $info->vrf_instances()->{$name},
    'An internal name is dropped from the MPLS list');
  is($info->_vrf_internal_instance('__x__'), 1, 'Double underscores');
}

sub vrf_instances_complete__junos__is_1 : Tests(1) {
  my $test = shift;
  my $info = $test->_prime_vrf();

  is($info->vrf_instances_complete(), 1, 'Complete walks list every instance');
}

sub vrf_instances_complete__no_mpls_internal_vacm_names__is_1 : Tests(3) {
  my $test = shift;
  my $info = $test->_prime_vrf();
  my $iid = sub { join('.', length($_[0]), map { ord } split //, $_[0]) };

  $info->{store}{$_} = {} for qw/vrf_l3vpn_rd vrf_l3vpn_descr
    vrf_l3vpn_oper vrf_jnx_vpn_status/;
  $info->{store}{jnx_vacm_context_name}
    = {map { $iid->($_) => $_ } q(), qw/default default-switch :gribi/};
  is($info->vrf_instances_complete(), 1,
    'Only internal names in vacmContextName: none configured');
  is($info->vrf_instances()->{default}{sources}{list},
    'SNMP-VIEW-BASED-ACM-MIB', 'default is listed by vacmContextName');

  $info = $test->_prime_vrf();
  $info->{store}{$_} = {} for qw/vrf_l3vpn_rd vrf_l3vpn_descr
    vrf_l3vpn_oper vrf_jnx_vpn_status jnx_vacm_context_name/;
  is($info->vrf_instances_complete(), undef,
    'No list served at all: unsupported');
}

sub vrf_instances_complete__vacm_walk_partial__is_0 : Tests(2) {
  my $test = shift;
  my $info = $test->_prime_vrf();

  $info->{walk_status}{jnx_vacm_context_name} = {complete => 0, reason => 'timeout'};
  is($info->vrf_instances_complete(), 0, 'A partial vacmContextName walk');
  $info->{walk_status} = {};
  $info->{walk_status}{vrf_jnx_vpn_status} = {complete => 0, reason => 'timeout'};
  is($info->vrf_instances_complete(), 0, 'A partial jnxVpnName walk');
}

# Junos 26.2 vJunos-switch, per context, synthetic from its captures. The
# router's own port MACs end 01 to 04 and 09; neighbors' end 05 to 08 and
# 0a to 0c. arp rows are ipNetToMediaTable [port, ip, mac]; n2p rows are
# ipNetToPhysicalTable [port, ip, mac, zoned]; nd rows are IPV6-MIB
# ipv6NetToMediaTable [port, ip, mac], mac undef for an empty value; addr
# rows are ipAddressTable [port, ip, network, length, zoned]. A mac of 0
# is all zeros. Every context serves the MPLS-L3VPN membership. Types are
# as Junos serves them: its own addresses static in IPv4 and local in
# IPv6, every other row dynamic.
my %JNX_CONTEXT = (
  default => {
    arp => [
      [13,  '10.0.0.2',    11], [21,  '127.0.0.1', 0],
      [508, '128.0.0.127', 0],  [514, '10.34.0.1', 0],
      # Not in the capture: a grey neighbor with a hardware address
      [514, '10.34.0.2',   12],
      [536, '10.30.0.2',   5], [540, '10.30.0.2', 7],
      [545, '10.31.0.2',   6], [549, '10.32.0.2', 8],
    ],
    n2p => [
      [13,  '10.0.0.2', 11], [21, '127.0.0.1', 0], [514, '10.34.0.1', 0],
      [514, '10.34.0.2', 12], [536, '10.30.0.2', 5],
      [536, '2001:db8:30:0:0:0:0:2', 5],
      [555, '2001:db8:33:0:0:0:0:2', 10],
    ],
    nd => [
      [13,  'fe80:0:0:0:0:0:0:2',        11],
      [514, '2001:db8:34:0:0:0:0:1',     undef],
      [536, 'fe80:0:0:0:0:ff:fe00:301',  5],
      [549, 'fe80:0:0:0:0:ff:fe00:303',  8],
      [555, 'fe80:0:0:0:0:ff:fe00:304',  10],
    ],
    addr => [
      [13,  '10.0.0.15',   '10.0.0.0',  24],
      [21,  '127.0.0.1',   '127.0.0.1', 32],
      [508, '128.0.0.127', '128.0.0.0', 2],
      [514, '10.34.0.1',   '10.34.0.1', 32],
      [536, '10.30.0.1',   '10.30.0.0', 24],
      [545, '10.31.0.1',   '10.31.0.0', 24],
      [549, '10.32.0.1',   '10.32.0.0', 24],
      [536, '2001:db8:30:0:0:0:0:1', '2001:db8:30:0:0:0:0:0', 64],
      [555, '2001:db8:33:0:0:0:0:1', '2001:db8:33:0:0:0:0:0', 64],
    ],
  },
  red => {
    arp => [
      [536, '10.30.0.1', 1], [536, '10.30.0.2', 5],
      [545, '10.31.0.1', 2], [545, '10.31.0.2', 6],
    ],
    n2p => [
      [536, '10.30.0.1', 1], [536, '10.30.0.2', 5],
      [536, '2001:db8:30:0:0:0:0:1', 1], [536, '2001:db8:30:0:0:0:0:2', 5],
      [536, 'fe80:0:0:0:0:0:0:1', 1, 1],
      [545, '10.31.0.1', 2], [545, '10.31.0.2', 6],
      [545, '2001:db8:31:0:0:0:0:1', 2], [545, '2001:db8:31:0:0:0:0:2', 6],
      [545, 'fe80:0:0:0:0:0:0:1', 2, 1],
    ],
    nd => [
      [536, '2001:db8:30:0:0:0:0:1', 1], [536, '2001:db8:30:0:0:0:0:2', 5],
      [536, 'fe80:0:0:0:0:0:0:1', 1], [536, 'fe80:0:0:0:0:0:0:2', 5],
      [536, 'fe80:0:0:0:0:ff:fe00:301', 5],
      [545, '2001:db8:31:0:0:0:0:1', 2], [545, '2001:db8:31:0:0:0:0:2', 6],
      [545, 'fe80:0:0:0:0:0:0:1', 2], [545, 'fe80:0:0:0:0:ff:fe00:303', 6],
    ],
    addr => [
      [536, '10.30.0.1', '10.30.0.0', 24],
      [545, '10.31.0.1', '10.31.0.0', 24],
      [536, '2001:db8:30:0:0:0:0:1', '2001:db8:30:0:0:0:0:0', 64],
      [545, '2001:db8:31:0:0:0:0:1', '2001:db8:31:0:0:0:0:0', 64],
      [536, 'fe80:0:0:0:0:0:0:1', 'fe80:0:0:0:0:0:0:0', 64, 1],
    ],
  },
  blue => {
    addr => [
      [540, '10.30.0.1', '10.30.0.0', 24],
      [549, '10.32.0.1', '10.32.0.0', 24],
      [540, '2001:db8:30:0:0:0:0:1', '2001:db8:30:0:0:0:0:0', 64],
      [549, '2001:db8:32:0:0:0:0:1', '2001:db8:32:0:0:0:0:0', 64],
      [540, 'fe80:0:0:0:0:0:0:1', 'fe80:0:0:0:0:0:0:0', 64, 1],
    ],
  },
  grey => {
    arp => [[514, '10.34.0.1', 0]],
    n2p => [
      [514, '10.34.0.1', 0], [514, '2001:db8:34:0:0:0:0:1', 0],
      [514, 'fe80:0:0:0:e00:c90f:fc2a:b000', 0, 1],
    ],
    nd => [
      [514, '2001:db8:34:0:0:0:0:1',         undef],
      [514, 'fe80:0:0:0:e00:c90f:fc2a:b000', undef],
    ],
    addr => [
      [514, '10.34.0.1', '10.34.0.1', 32],
      [514, '2001:db8:34:0:0:0:0:1', '2001:db8:34:0:0:0:0:1', 128],
      [514, 'fe80:0:0:0:e00:c90f:fc2a:b000',
        'fe80:0:0:0:e00:c90f:fc2a:b000', 128, 1],
    ],
  },
);
my $JNX_PFX = '.1.3.6.1.2.1.4.32.1.5';

# The index arcs of an IPv6 address written as eight hex groups
sub _jnx_v6_arcs {
  my $ip = shift;
  return join('.', unpack('C*', pack('n8', map { hex } split /:/, $ip)));
}

# An InetAddress index: type, length, octets, and four zone octets for ipv6z
sub _jnx_inet_iid {
  my ($ip, $zoned) = @_;
  return "1.4.$ip" if $ip !~ /:/;
  return '4.20.' . _jnx_v6_arcs($ip) . '.0.0.0.0' if $zoned;
  return '2.16.' . _jnx_v6_arcs($ip);
}

sub _jnx_mac {
  my $last = shift;
  return pack('C6', $last ? (2, 0, 0, 0, 0, $last) : (0) x 6);
}

# The router's own rows: its port MACs, or none
sub _jnx_own {
  my $mac = shift;
  return (!$mac or grep { $mac == $_ } 1 .. 4, 9) ? 1 : 0;
}

sub _jnx_neighbor_store {
  my ($store, $tables) = @_;
  foreach my $row (@{$tables->{arp} || []}) {
    my ($port, $ip, $mac) = @$row;
    $store->{at_paddr}{"$port.$ip"}   = _jnx_mac($mac);
    $store->{at_netaddr}{"$port.$ip"} = $ip;
  }
  foreach my $row (@{$tables->{n2p} || []}) {
    my ($port, $ip, $mac, $zoned) = @$row;
    my $iid = "$port." . _jnx_inet_iid($ip, $zoned);
    $store->{ip_n2p_phys_addr}{$iid} = _jnx_mac($mac);
    $store->{ip_n2p_phys_type}{$iid}
      = !_jnx_own($mac) ? 'dynamic' : $ip =~ /:/ ? 'local' : 'static';
  }
  foreach my $row (@{$tables->{nd} || []}) {
    my ($port, $ip, $mac) = @$row;
    my $iid = "$port." . _jnx_v6_arcs($ip);
    $store->{i6_n2p_phys_addr}{$iid} = defined $mac ? _jnx_mac($mac) : q();
    $store->{i6_n2p_phys_type}{$iid} = _jnx_own($mac) ? 'local' : 'dynamic';
  }
  return;
}

# The prefix RowPointer as Junos serves it: an ipv6z prefix has no zone
sub _jnx_address_store {
  my ($store, $tables) = @_;
  foreach my $row (@{$tables->{addr} || []}) {
    my ($port, $ip, $network, $length, $zoned) = @$row;
    my $iid = _jnx_inet_iid($ip, $zoned);
    my $net = $zoned ? '4.20.' . _jnx_v6_arcs($network)
      : _jnx_inet_iid($network);
    $store->{new_ip_index}{$iid}  = $port;
    $store->{new_ip_type}{$iid}   = 'unicast';
    $store->{new_ip_prefix}{$iid} = "$JNX_PFX.$port.$net.$length";
  }
  return;
}

# Enters $context ('default' for the default context) on a cache holding
# that context's tables
sub _prime_jnx_context {
  my ($test, $context) = @_;
  my $info = $test->_prime_vrf();
  my $iid = sub { join('.', length($_[0]), map { ord } split //, $_[0]) };

  my %store = map { $_ => {} } qw/at_paddr at_netaddr old_at_paddr
    old_at_netaddr ip_n2p_phys_addr c_inet_phys_addr i6_n2p_phys_addr
    ip_n2p_phys_type c_inet_phys_type i6_n2p_phys_type new_ip_index new_ip_type new_ip_prefix old_ip_index old_ip_netmask/;
  _jnx_neighbor_store(\%store, $JNX_CONTEXT{$context});
  _jnx_address_store(\%store, $JNX_CONTEXT{$context});
  $store{vrf_l3vpn_if} = {
    $iid->('red')  . '.536' => 'active',
    $iid->('red')  . '.545' => 'active',
    $iid->('grey') . '.514' => 'active',
  };
  foreach my $method (keys %store) {
    $info->{"_$method"} = 1;
    $info->{store}{$method} = $store{$method};
  }

  $info->{args}{Community} = 'public';
  $info->session()->{Version}   = 2;
  $info->session()->{Community}
    = $context eq 'default' ? 'public' : "$context\@public";
  return $info;
}

sub vrf_neighbors__red_context__adds_ipv6_mib_link_locals : Tests(5) {
  my $test = shift;
  my $info = $test->_prime_jnx_context('red');

  my %link_local = map { ("$_->[0]." . _jnx_v6_arcs($_->[1]) => $_->[0]) } (
    [536, 'fe80:0:0:0:0:0:0:2'], [536, 'fe80:0:0:0:0:ff:fe00:301'],
    [545, 'fe80:0:0:0:0:ff:fe00:303'],
  );
  my @global = (
    '536.2.16.' . _jnx_v6_arcs('2001:db8:30:0:0:0:0:2'),
    '545.2.16.' . _jnx_v6_arcs('2001:db8:31:0:0:0:0:2'),
  );
  my $rows = $info->vrf_neighbors('red');
  cmp_deeply([sort keys %$rows], [sort('536.10.30.0.2', '545.10.31.0.2',
      @global, keys %link_local)],
    'IPv4, the IP-MIB globals and the IPV6-MIB link-locals of the'
      . ' neighbors; no own address');
  cmp_deeply(
    $rows->{'536.' . _jnx_v6_arcs('fe80:0:0:0:0:ff:fe00:301')},
    {
      ifindex => 536,
      ip      => 'fe80:0000:0000:0000:0000:00ff:fe00:0301',
      mac     => '02:00:00:00:00:05',
      family  => 'ipv6',
    },
    'An IPV6-MIB row in the form of an IP-MIB one');
  my %seen;
  $seen{"$_->{ifindex} $_->{ip}"}++ for values %$rows;
  cmp_deeply([grep { $seen{$_} > 1 } sort keys %seen], [],
    'No port holds an address twice');
  ok(!exists $rows->{'536.' . _jnx_v6_arcs('2001:db8:30:0:0:0:0:2')},
    'Where both tables list a row, the IP-MIB one is kept');
  is($info->{_vrf_walked}{red}{i6_n2p_phys_addr}, 1,
    'The IPV6-MIB walk is recorded for red');
}

sub vrf_neighbors__red_context__own_addresses_dropped : Tests(4) {
  my $test = shift;
  my $info = $test->_prime_jnx_context('red');

  my $rows = $info->vrf_neighbors('red');
  ok(!exists $rows->{'536.10.30.0.1'},
    'An own IPv4 address, static at the port MAC, matched by address');
  ok(!exists $rows->{'536.2.16.' . _jnx_v6_arcs('2001:db8:30:0:0:0:0:1')},
    'An own IPv6 global address is dropped');
  ok(!exists $info->vrf_addresses('red')->{'545.fe80:0000:0000:0000:0000:'
      . '0000:0000:0001'}, 'ipAddressTable lists fe80::1 on 536 only');
  ok(!exists $rows->{'545.' . _jnx_v6_arcs('fe80:0:0:0:0:0:0:1')},
    '... and its local row on 545 is dropped by its type');
}

sub vrf_neighbors__red_context__neighbor_at_own_link_local_elsewhere__kept
  : Tests(2) {
  my $test = shift;
  my $info = $test->_prime_jnx_context('red');

  my $key = '545.' . _jnx_v6_arcs('fe80:0:0:0:0:0:0:1');
  $info->{store}{i6_n2p_phys_addr}{$key} = _jnx_mac(6);
  $info->{store}{i6_n2p_phys_type}{$key} = 'dynamic';
  my $ll  = 'fe80:0:0:0:0:0:0:9';
  my $iid = '4.20.' . _jnx_v6_arcs($ll) . '.0.0.0.0';
  $info->{store}{new_ip_index}{$iid}  = 545;
  $info->{store}{new_ip_type}{$iid}   = 'unicast';
  $info->{store}{new_ip_prefix}{$iid}
    = "$JNX_PFX.545.4.20." . _jnx_v6_arcs('fe80:0:0:0:0:0:0:0') . '.64';

  my $rows = $info->vrf_neighbors('red');
  is($rows->{$key}{mac}, '02:00:00:00:00:06',
    'A host at fe80::1 on a port where the router holds fe80::9 is kept');
  ok(!exists $rows->{'536.' . _jnx_v6_arcs('fe80:0:0:0:0:0:0:1')},
    'The router\'s own fe80::1 on 536 is still dropped');
}

# Each (port, address) once, wherever ipv6_n2p_*() read the IPv6 rows
sub _jnx_pairs_once {
  my $rows = shift;
  my %seen;
  $seen{"$_->{ifindex} $_->{ip}"}++ for values %$rows;
  return [grep { $seen{$_} > 1 } sort keys %seen];
}

sub vrf_neighbors__ip_mib_ipv4_only__ipv6_mib_rows_once : Tests(4) {
  my $test = shift;
  my $info = $test->_prime_jnx_context('red');

  my $n2p = $info->{store}{ip_n2p_phys_addr};
  delete $n2p->{$_} for grep { !/^\d+\.1\.4\./ } keys %$n2p;
  my $rows = $info->vrf_neighbors('red');
  cmp_deeply(_jnx_pairs_once($rows), [], 'IP-MIB serves IPv4 only: once');
  is(scalar(grep { $_->{family} eq 'ipv6' } values %$rows), 5,
    'The IPV6-MIB rows of the neighbors, each once');

  $info = $test->_prime_jnx_context('red');
  $info->{store}{$_} = {} for qw/ip_n2p_phys_addr ip_n2p_phys_type/;
  $rows = $info->vrf_neighbors('red');
  cmp_deeply(_jnx_pairs_once($rows), [],
    'ipv6_n2p_*() fall back to IPV6-MIB: once');
  is(scalar(grep { $_->{family} eq 'ipv6' } values %$rows), 5,
    '... the same five rows');
}

sub vrf_neighbors__grey_context__own_rows_dropped : Tests(1) {
  my $test = shift;
  my $info = $test->_prime_jnx_context('grey');

  cmp_deeply($info->vrf_neighbors('grey'), {},
    'Its own addresses at a zero or empty MAC are no neighbors');
}

sub vrf_neighbors__default_context__drops_mpls_ports : Tests(2) {
  my $test = shift;
  my $info = $test->_prime_jnx_context('default');

  my $rows = $info->vrf_neighbors('default');
  cmp_deeply([sort keys %$rows], [sort('13.10.0.0.2',
      '13.' . _jnx_v6_arcs('fe80:0:0:0:0:0:0:2'),
      '549.10.32.0.2', '549.' . _jnx_v6_arcs('fe80:0:0:0:0:ff:fe00:303'),
      '555.2.16.' . _jnx_v6_arcs('2001:db8:33:0:0:0:0:2'),
      '555.' . _jnx_v6_arcs('fe80:0:0:0:0:ff:fe00:304'))],
    'Rows on ports of virtual routers, management included, stay here');
  cmp_deeply([grep { /^(?:514|536|545)$/ } map { $_->{ifindex} }
      values %$rows], [], 'No row on a port MPLS-L3VPN gives red or grey');
}

sub vrf_addresses__default_context__drops_mpls_ports : Tests(1) {
  my $test = shift;
  my $info = $test->_prime_jnx_context('default');

  cmp_deeply([sort keys %{$info->vrf_addresses('default')}],
    [sort('13.10.0.0.15', '21.127.0.0.1', '508.128.0.0.127',
      '549.10.32.0.1', '555.2001:0db8:0033:0000:0000:0000:0000:0001')],
    'Addresses on red and grey ports are dropped');
}

sub vrf_subnets__default_context__drops_mpls_ports : Tests(1) {
  my $test = shift;
  my $info = $test->_prime_jnx_context('default');

  cmp_deeply([sort keys %{$info->vrf_subnets('default')}],
    [sort('10.0.0.0/24', '127.0.0.1/32', '128.0.0.0/2', '10.32.0.0/24',
      '2001:0db8:0033:0000:0000:0000:0000:0000/64')],
    'Subnets on red and grey ports are dropped');
}

sub vrf_read_complete__default_with_virtual_routers__is_0 : Tests(3) {
  my $test = shift;
  my $info = $test->_prime_jnx_context('default');

  $info->vrf_neighbors('default');
  is($info->vrf_read_complete('default'), 0,
    'blue and green have no membership the default context serves');

  my $iid = sub { join('.', length($_[0]), map { ord } split //, $_[0]) };
  $info = $test->_prime_jnx_context('default');
  delete $info->{store}{jnx_vacm_context_name}{$iid->($_)} for qw/blue green/;
  $info->vrf_neighbors('default');
  is($info->vrf_read_complete('default'), 0,
    'The management instance alone has no membership here either');

  $info = $test->_prime_jnx_context('default');
  delete $info->{store}{jnx_vacm_context_name}{$iid->($_)}
    for qw/blue green mgmt_junos/;
  $info->vrf_neighbors('default');
  is($info->vrf_read_complete('default'), 1,
    'With every instance a member of MPLS-L3VPN, the read is whole');
}

# The default context with no virtual router listed
sub _prime_jnx_default_mpls_only {
  my $test = shift;
  my $info = $test->_prime_jnx_context('default');
  my $iid = sub { join('.', length($_[0]), map { ord } split //, $_[0]) };
  delete $info->{store}{jnx_vacm_context_name}{$iid->($_)}
    for qw/blue green mgmt_junos/;
  return $info;
}

sub vrf_read_complete__default_portless_mpls_vrf__is_1 : Tests(2) {
  my $test = shift;
  my $info = $test->_prime_jnx_default_mpls_only();
  my $grey = join('.', length('grey'), map { ord } split //, 'grey');

  delete $info->{store}{vrf_l3vpn_if}{"$grey.514"};
  $info->vrf_neighbors('default');
  ok(!$info->vrf_instances()->{grey}{sources}{members},
    'grey holds no port in mplsL3VpnIfConfTable');
  is($info->vrf_read_complete('default'), 1,
    'An MPLS-listed VRF with no port leaks no row into default');
}

sub vrf_read_complete__default_list_rebuilt_partial__is_0 : Tests(2) {
  my $test = shift;
  my $info = $test->_prime_jnx_default_mpls_only();

  $info->vrf_neighbors('default');
  delete $info->{_vrf_instances};
  is($info->vrf_read_complete('default'), 1,
    'The list read again after the cache was cleared is whole');
  delete $info->{_vrf_instances};
  $info->{walk_status}{jnx_vacm_context_name}
    = {complete => 0, reason => 'timeout'};
  is($info->vrf_read_complete('default'), 0,
    'A partial vacmContextName walk may hide a virtual router');
}

sub vrf_read_complete__red__is_1 : Tests(2) {
  my $test = shift;
  my $info = $test->_prime_jnx_context('red');

  $info->vrf_neighbors('red');
  is($info->vrf_read_complete('red'), 1, 'Every walk was complete');
  $info->{walk_status}{i6_n2p_phys_addr}
    = {complete => 0, reason => 'timeout'};
  is($info->vrf_read_complete('red'), 0,
    'A partial ipv6NetToMediaTable walk makes the read incomplete');
}

sub i_vrf__blue_context__blue_ports : Tests(1) {
  my $test = shift;
  my $info = $test->_prime_jnx_context('blue');

  cmp_deeply($info->i_vrf(), {540 => 'blue', 549 => 'blue'},
    'The ports holding an address in blue\'s context');
}

sub i_vrf__default_context__mpls_membership : Tests(1) {
  my $test = shift;
  my $info = $test->_prime_jnx_context('default');

  cmp_deeply($info->i_vrf(), {536 => 'red', 545 => 'red', 514 => 'grey'},
    'The membership MPLS-L3VPN-STD-MIB serves');
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

sub _set_context_names {
  my ($test, @names) = @_;
  my $info = $test->{info};

  $info->{store}{jnx_vacm_context_name} = _context_name_rows(@names);
  $info->{_jnx_vacm_context_name} = 1;
  delete $info->{_stp_trees};
  delete $info->{_jnx_stp_protocols};
  return;
}

sub _jnx_vstp_contexts : Tests(7) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('vstp');
  cmp_deeply($info->_jnx_vstp_contexts(), [['default', 10], ['default', 20]],
    'VLAN ids from instance::N names, not control context ids');

  my $iid_9 = '10.100.101.102.97.117.108.116.58.58.57';
  $info->{store}{jnx_vacm_context_name}{$iid_9} = 'default::9';
  cmp_deeply($info->_jnx_vstp_contexts(),
    [['default', 9], ['default', 10], ['default', 20]],
    'Sorted numerically');

  $test->_set_context_names('default::10', 'vs1::30', 'vs1', 'vs1::0',
    'vs1::4095', '::40', 'default::10::2');
  cmp_deeply($info->_jnx_vstp_contexts(), [['default', 10], ['vs1', 30]],
    'Every instance; only VLAN ids 1 to 4094');

  $test->_set_context_names('xdefault::30', 'default::30');
  cmp_deeply($info->_jnx_vstp_contexts(),
    [['default', 30], ['xdefault', 30]], 'Sorted by instance, then VLAN');

  $test->_stp_cache('vstp');
  $info->{store}{jnx_vacm_context_name} = {};
  cmp_deeply($info->_jnx_vstp_contexts(), [], 'Not served: empty');

  $test->_stp_cache('vstp');
  delete $info->{store}{jnx_vacm_context_name};
  delete $info->{_jnx_vacm_context_name};
  cmp_deeply($info->_jnx_vstp_contexts(), [], 'Absent: empty');
  $info->clear_cache();
  cmp_deeply($info->_jnx_vstp_contexts(), [], 'Cleared: empty');
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
      instance       => 'default',
      protocol       => 'vstp',
      measured       => 1,
      ports_complete => 1,
      bridge         => undef,
      root           => undef,
      contexts       => [{
        kind => 'vlan', id => 20, instance => 'default',
        v2c => 'default::20@%s', v3 => 'default::20',
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

sub stp_tree_ports__vstp : Tests(12) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('vstp');
  is(scalar $info->stp_tree_ports('vlan.20'), undef,
    'Default context: nothing');
  like($info->error(1), qr/default::20/, 'Error names the context');
  like($info->error(1), qr/stp_tree_ports/, 'Error names the method');

  is(scalar $info->stp_tree_ports('vlan.99'), undef,
    'Default context, unknown VLAN: nothing');
  like($info->error(1),
    qr/^SNMP::Info::Layer3::Juniper::stp_tree_ports\(\) has no tree/,
    'Error names the public method');

  $test->_stp_cache('vstp');
  $test->_enter_vstp_context(20);
  my $rows = $info->stp_tree_ports('vlan.20');
  cmp_deeply([sort keys %$rows], [521, 522], 'In context: rows by ifIndex');
  is($rows->{522}{state}, 'blocking', '522 blocking');
  cmp_deeply($rows->{522}{designated_bridge}, _bridge(32768, 20,
    '02:00:00:00:00:0c'), '522 designated bridge, VLAN as extension');
  is($rows->{522}{tree_type}, 'vlan', 'Labeled vlan');
  is($rows->{522}{tree_id}, 20, 'Labeled 20');

  is(scalar $info->stp_tree_ports('vlan.10'), undef,
    'Context of another VLAN: nothing');
  like($info->error(1), qr/default::10/, 'Error names the wanted context');
  $info->session()->{Community} = 'public';
}

sub stp_trees_complete__vstp : Tests(9) {
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

  $test->_stp_cache('vstp');
  $test->_set_context_names('default::10', 'vs1::30');
  cmp_deeply([sort keys %{$info->stp_trees()}], [qw/vlan.10 vlan.30@vs1/],
    'Instance vs1: its VLAN listed beside the default one');
  is($info->stp_trees_complete(), 1, 'Two names, two control rows');

  $test->_stp_cache('vstp');
  $test->_set_context_names('default::10', 'default::20', 'default-switch');
  is($info->stp_trees_complete(), 1, 'Only default::N names: complete');

  $test->_stp_cache('rstp');
  $test->_set_context_names('default', 'default::20');
  cmp_deeply([sort keys %{$info->stp_trees()}], ['cist.0'],
    'A name without a control row: no VSTP tree');
  is($info->stp_trees_complete(), 0, 'and incomplete');
}

sub stp_trees_complete__rstp_contexts : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('rstp');
  $test->_set_context_names('default', 'default-switch', 'mgmt_junos');
  is($info->stp_trees_complete(), 1, 'RSTP, no VLAN context names');

  $test->_stp_cache('stp');
  $test->_set_context_names('default::20');
  is($info->stp_trees_complete(), 0, 'STP, a name with no control row');

  $test->_stp_cache('rstp');
  $test->_set_context_names('vs1::30');
  is($info->stp_trees_complete(), 0, 'RSTP, a vs1 name with no control row');
}

# Junos refuses MSTP and VSTP only within one routing instance, so a VLAN
# context name beside MSTP is VSTP in another instance, which is not listed
sub stp_trees_complete__mstp_with_vlan_context__is_0 : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('mstp');
  is($info->stp_trees_complete(), 1, 'MSTP, no VLAN context names');
  $test->_set_context_names('default', 'vs1', 'vs1::30');
  is($info->stp_trees_complete(), 0, 'MSTP beside vs1::30: incomplete');
  $test->_set_context_names('default::20');
  is($info->stp_trees_complete(), 0, 'MSTP beside default::20: incomplete');
}

sub stp_trees_complete__control_walk_incomplete__is_0 : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  # One name and one control row away from context 0: the counts match
  $test->_stp_cache('rstp_vstp');
  is($info->stp_trees_complete(), 1, 'Complete walk: complete');
  $test->_stp_cache('rstp_vstp');
  $info->{walk_status}{jnx_mst_control}
    = {complete => 0, reason => 'timeout'};
  cmp_deeply($info->stp_protocols(), ['rstp'],
    'Incomplete control walk: VSTP not detected');
  is($info->stp_trees_complete(), 0, 'Incomplete control walk: incomplete');
}

sub stp_vlan_map : Tests(6) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache('mstp');
  cmp_deeply(scalar $info->stp_vlan_map(), {10 => 'msti.1', 20 => 'msti.2'},
    'MSTP: only VLANs mapped to an MSTI');

  $info->{store}{jnx_msti_vlans_2k}{'0.2'} = "\x80" . "\x00" x 127;
  $info->{store}{jnx_msti_vlans_3k}{'0.2'} = "\x80" . "\x00" x 127;
  $info->{store}{jnx_msti_vlans_4k}{'0.1'} = "\x00" x 127 . "\x0f";
  cmp_deeply(
    scalar $info->stp_vlan_map(),
    {
      10 => 'msti.1', 20 => 'msti.2', 1025 => 'msti.2', 2049 => 'msti.2',
      4093 => 'msti.1', 4094 => 'msti.1',
    },
    'Bitmap origins 1025, 2049, 3073; VLANs capped at 4094'
  );

  $test->_stp_cache('mstp');
  $info->{store}{jnx_msti_vlans_1k}{'0.1'} = "\x00\x40";
  cmp_deeply(scalar $info->stp_vlan_map(), {10 => 'msti.1', 20 => 'msti.2'},
    'A short bitmap stands for zero-padding');

  $test->_stp_cache('mstp');
  $info->{store}{$_} = {} for map {"jnx_msti_vlans_${_}k"} 1 .. 4;
  is(scalar $info->stp_vlan_map(), undef, 'MSTP, no VLAN mapped: nothing');

  $test->_stp_cache('rstp');
  is(scalar $info->stp_vlan_map(), undef, 'RSTP: nothing');
  $info->clear_cache();
  is(scalar $info->stp_vlan_map(), undef, 'Nothing served: nothing');
}

1;
