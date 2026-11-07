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

# Neighbor rows of a FortiLink-managed FortiSwitch, whose chassis ID column
# came back under a later time mark than the other neighbor columns
my $TIME_MARK         = '1805327064';
my $LATER_TIME_MARK   = '1805354436';
my %FORTILINK_CHASSIS = (
  '79.13' => '020000a10001',
  '79.14' => '020000a10001',
  '80.11' => '020000b20001',
  '80.12' => '020000b20101',
);

sub _prime_fortilink_lldp {
  my $test = shift;
  my $info = $test->{info};

  $info->{"_$_"} = 1 for qw/lldp_rem_id_type lldp_rem_id lldp_rem_pid/;
  $info->{store}{lldp_rem_id_type}
    = {map { ("$TIME_MARK.$_" => 'macAddress') } keys %FORTILINK_CHASSIS};
  $info->{store}{lldp_rem_pid} = {
    "$TIME_MARK.79.13" => 'port55',
    "$TIME_MARK.79.14" => 'port56',
    "$TIME_MARK.80.11" => 'port24',
    "$TIME_MARK.80.12" => 'port24',
  };
  $info->{store}{lldp_rem_id} = {
    map { ("$LATER_TIME_MARK.$_" => pack('H*', $FORTILINK_CHASSIS{$_})) }
      keys %FORTILINK_CHASSIS
  };
  return;
}

sub lldp_rem__fortiswitch_columns_under_different_time_marks__share_keys
  : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  $test->_prime_fortiswitch();
  $test->_prime_fortilink_lldp();
  my @keys = map {"0.$_"} sort keys %FORTILINK_CHASSIS;

  cmp_deeply(
    $info->lldp_id(),
    {
      '0.79.13' => '02:00:00:a1:00:01',
      '0.79.14' => '02:00:00:a1:00:01',
      '0.80.11' => '02:00:00:b2:00:01',
      '0.80.12' => '02:00:00:b2:01:01',
    },
    q(lldp_id__fortiswitch_columns_under_different_time_marks__joins)
  );
  cmp_deeply([sort keys %{$info->lldp_ip()}], \@keys,
    q(lldp_ip__fortiswitch__keys_match_lldp_id));
  cmp_deeply([sort keys %{$info->_lldp_rem('lldp_rem_pid')}], \@keys,
    q(lldp_rem__fortiswitch__every_column_drops_the_time_mark));
}

sub lldp_rem__fortiswitch_one_neighbor_under_two_time_marks__later_wins
  : Tests(1) {
  my $test = shift;
  my $info = $test->{info};

  $test->_prime_fortiswitch();
  $test->_prime_fortilink_lldp();
  $info->{store}{lldp_rem_pid}{"$LATER_TIME_MARK.79.13"} = 'port57';
  is($info->_lldp_rem('lldp_rem_pid')->{'0.79.13'}, 'port57',
    q(lldp_rem__one_neighbor_under_two_time_marks__later_row_kept));
}

# FortiSwitch 7.4.6 serves the chassis IDs as text, every column under one
# time mark
sub lldp_id__fortiswitch_text_chassis_ids__read : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $test->_prime_fortiswitch();
  $test->_prime_fortilink_lldp();
  $info->{store}{lldp_rem_id} = {
    map {
      my $hex = $FORTILINK_CHASSIS{$_};
      ("$TIME_MARK.$_" => join(':', $hex =~ /(..)/g))
    } keys %FORTILINK_CHASSIS
  };
  cmp_deeply(
    $info->lldp_id(),
    {
      '0.79.13' => '02:00:00:a1:00:01',
      '0.79.14' => '02:00:00:a1:00:01',
      '0.80.11' => '02:00:00:b2:00:01',
      '0.80.12' => '02:00:00:b2:01:01',
    },
    q(lldp_id__fortiswitch_text_chassis_ids__read)
  );

  $info->{_mac}              = pack('H*', '020000a10002');
  $info->{_lldp_loc_id_type} = 'macAddress';
  $info->{_lldp_loc_id_os}   = '02:00:00:a1:00:01';
  is($info->mac(), '02:00:00:a1:00:01',
    q(mac__fortiswitch_text_chassis_id__returns_it));
}

sub lldp_rem__fortigate__keeps_the_time_mark : Tests(1) {
  my $test = shift;
  my $info = $test->{info};

  $test->_prime_fortilink_lldp();
  cmp_deeply(
    [sort keys %{$info->_lldp_rem('lldp_rem_pid')}],
    [map {"$TIME_MARK.$_"} sort keys %FORTILINK_CHASSIS],
    q(lldp_rem__fortigate__keys_unchanged)
  );
}

sub mac : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'mac');

  $info->{_mac} = pack('H*', '020000a10002');
  is($info->mac(), '02:00:00:a1:00:02',
    q(mac__fortigate__returns_interface_address));

  $test->_prime_fortiswitch();
  $info->{_mac}              = pack('H*', '020000a10002');
  $info->{_lldp_loc_id_type} = 'macAddress';
  $info->{_lldp_loc_id_os}   = pack('H*', '020000a10001');
  is($info->mac(), '02:00:00:a1:00:01',
    q(mac__fortiswitch__returns_lldp_chassis_id));

  $info->{_lldp_loc_id_type} = 'local';
  $info->{_lldp_loc_id_os}   = 'S148FFTF00000001';
  is($info->mac(), '02:00:00:a1:00:02',
    q(mac__fortiswitch_chassis_id_not_a_mac__returns_interface_address));
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
      (map { $_ => '0.0.0.0' } qw/0.10.1 0.17.2 0.55.6 0.55.7/),
      '0.22.3' => '10.10.20.38',
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
