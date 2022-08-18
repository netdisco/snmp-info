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

sub i_vlan : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'i_vlan');

  my $expected = {662 => 0, 509 => 113, 510 => 2088};
  cmp_deeply($test->{info}->i_vlan(),
    $expected, q(ELS PVID returned expected values));

  delete $test->{info}{'_jnx_els_v_index'};
  $test->{info}{store}{bp_index}  = {513 => 505, 514 => 507};
  $test->{info}{store}{qb_i_vlan} = {513 => 3,   514 => 2};
  $expected                       = {505 => 120, 507 => 0};
  cmp_deeply($test->{info}->i_vlan(),
    $expected, q(Older PVID returned expected values));

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

sub e_class : Tests(3) {
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

sub e_serial : Tests(3) {
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

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->e_serial(), {}, q(No data returns empty hash));
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

1;
