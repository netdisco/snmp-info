# Test::SNMP::Info::Layer3::Fortinet
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

package Test::SNMP::Info::Layer3::Fortinet;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Fortinet;

# Remove this startup override once we have full method coverage
sub startup : Tests(startup => 1) {
  my $test = shift;
  $test->SUPER::startup();

  $test->todo_methods(1);
}

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_layers' => 78,
    '_description' => 'firewall',

    # FORTINET-FORTIGATE-MIB::fgt500E
    '_id'   => '.1.3.6.1.4.1.12356.101.1.5005',

    '_fnSysSerial' => 'FG5H0E5810000000',
    '_fgSysVersion' => 'v6.0.11,build0387,200917 (GA)',
    '_i_index' => 1,
    '_orig_i_name' => 1,
    'store' => {
      'i_index'       => {
        1 => 1,
        2 => 2,
        3 => 3
      },
      'orig_i_name'       => {
        1 => "ha",
        2 => "mgmt",
        3 => "port1"
      },
    },
  };
  $test->{info}->cache($cache_data);
}

# Shaped from a FortiSwitch-148F-FPOE on 7.6.0, which serves the FortiSwitch
# MIB system objects and none of the FortiGate ones
sub _prime_fortiswitch {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache({
    '_layers'      => 78,
    '_description' => '',

    # FORTINET-FORTISWITCH-MIB::s148ff
    '_id'         => '.1.3.6.1.4.1.12356.106.1.1486',
    '_fs_version' => 'FortiSwitch-148F-FPOE v7.6.0,build1015,240812 (GA)',

    # ENTITY-MIB: the chassis carries the serial
    '_e_parent' => 1,
    '_e_class'  => 1,
    'store'     => {
      'e_parent' => {1 => 0, 2 => 1},
      'e_class'  => {1 => 'chassis', 2 => 'port'},
    },
  });

  # entity_derived_serial fetches e_serial by partial, which bypasses the
  # cache, so the serial is served by the mocked session
  $info->{sess}{Data}
    = {'ENTITY-MIB::entPhysicalSerialNum' => {1 => 'S148FFTF00000001'}};
}

# Neighbor rows and management address rows as the FortiSwitch serves them:
# the address rows name other local ports and remote indexes
sub _prime_fortiswitch_lldp {
  my $test = shift;
  my $info = $test->{info};

  $info->{"_$_"} = 1 for qw/lldp_rman_addr lldp_rem_id_type lldp_rem_id/;
  $info->{store}{lldp_rem_id_type} = {
    '998707741.10.1' => 'local',
    '998707741.17.2' => 'macAddress',
    '998707741.22.3' => 'networkAddress',
    '998707741.55.6' => 'macAddress',
    '998707741.55.7' => 'macAddress',
  };
  $info->{store}{lldp_rem_id} = {
    '998707741.10.1' => 'XXX-LT-24392',
    '998707741.17.2' => pack('H*', '94c691ac4331'),
    '998707741.22.3' => pack('H*', '010a0a1426'),
    '998707741.55.6' => pack('H*', '80802cba5e2f'),
    '998707741.55.7' => pack('H*', '80802cba93f3'),
  };
  $info->{store}{lldp_rman_addr} = {
    '998707741.23.1.1.172.22.92.147' => 'ifIndex',
    '998707741.55.5.1.172.24.92.1'   => 'ifIndex',
    '998707741.55.6.1.172.24.92.21'  => 'ifIndex',
  };
}

sub fortiswitch_identity : Tests(4) {
  my $test = shift;

  $test->_prime_fortiswitch();
  is($test->{info}->model(), 'FS-148F-FPOE',
    q(model__fortiswitch__returns_model_from_fsSysVersion));
  is($test->{info}->os_ver(), '7.6.0',
    q(os_ver__fortiswitch__returns_version_from_fsSysVersion));
  is($test->{info}->serial(), 'S148FFTF00000001',
    q(serial__fortiswitch__returns_entity_chassis_serial));

  $test->{info}{_fs_version} = undef;
  isnt($test->{info}->model(), undef,
    q(model__fortiswitch_without_fsSysVersion__falls_back_to_sysobjectid));
}

sub lldp_ip : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_ip');

  $test->_prime_fortiswitch();
  $test->_prime_fortiswitch_lldp();
  cmp_deeply(
    $test->{info}->lldp_ip(),
    {
      (map { $_ => '0.0.0.0' }
          qw/998707741.10.1 998707741.17.2 998707741.55.6 998707741.55.7/),
      '998707741.22.3' => '10.10.20.38',
    },
    q(lldp_ip__fortiswitch__uses_chassis_address_or_0.0.0.0)
  );

  # FortiGate management addresses match their rows; neighbors with a MAC
  # chassis ID and no address of their own get the LLDP 0.0.0.0
  $test->{info}{_id} = '.1.3.6.1.4.1.12356.101.1.5005';
  cmp_deeply(
    $test->{info}->lldp_ip(),
    {
      '998707741.23.1' => '172.22.92.147',
      '998707741.55.5' => '172.24.92.1',
      '998707741.55.6' => '172.24.92.21',
      '998707741.17.2' => '0.0.0.0',
      '998707741.55.7' => '0.0.0.0',
    },
    q(lldp_ip__fortigate__keeps_management_addresses)
  );
}

sub lldp_ipv6 : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_ipv6');

  $test->_prime_fortiswitch();
  $test->_prime_fortiswitch_lldp();
  $test->{info}{store}{lldp_rman_addr}
    {'998707741.55.6.2.32.1.13.184.0.0.0.0.0.0.0.0.0.0.0.1'} = 'ifIndex';
  cmp_deeply($test->{info}->lldp_ipv6(), {},
    q(lldp_ipv6__fortiswitch__ignores_management_addresses));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'fortinet', q(Vendor returns 'fortinet'));
}

sub model : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), '500E', q(Model is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->model(), '', q(No model info returns undef model));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'fortios', q(os returns 'fortios'));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '6.0.11', q(os_ver is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), '', q(No os_ver info returns undef os_ver));
}

sub serial : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), 'FG5H0E5810000000', q(serial number is expected value'));
}

1;
