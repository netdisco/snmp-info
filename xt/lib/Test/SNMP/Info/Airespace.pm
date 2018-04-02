# Test::SNMP::Info::Airespace
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
# THIS SOFTWARE IS PROVIDED BY THE COPYRSNMP::Info::AdslLineIGHT HOLDERS AND CONTRIBUTORS "AS IS"
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

package Test::SNMP::Info::Airespace;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Airespace;

# Remove this startup override once we have full method coverage
sub startup : Tests(startup => 1) {
  my $test = shift;
  $test->SUPER::startup();

  $test->todo_methods(1);
}

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup();

  # Start with a common cache that will serve most tests
  # ieee8023adLag example from Cisco 65xx VSS snmpwalk
  my $cache_data = {
    '_airespace_serial'     => 'ABC1234567D',
    '_i_index'              => 1,
    '_i_name'               => 1,
    '_i_description'        => 1,
    '_i_type'               => 1,
    '_i_up'                 => 1,
    '_airespace_apif_slot'  => 1,
    '_airespace_if_name'    => 1,
    '_airespace_ap_name'    => 1,
    '_airespace_ap_loc'     => 1,
    '_airespace_apif_type'  => 1,
    '_airespace_if_type'    => 1,
    '_airespace_apif'       => 1,
    '_airespace_apif_admin' => 1,
    'store'                 => {
      'i_index' => {'1' => 1,},
      'i_name'  => {'1' => 'Unit - 0 Slot - 1 Port - 1',},
      'i_description' =>
        {'1' => 'Unit: 0 Slot: 1 Port: 1 Gigabit - Level 0x50a0001',},
      'i_type' => {'1' => 'ethernetCsmacd',},
      'i_up'   => {'1' => 'up',},
      'airespace_apif_slot' =>
        {'0.11.133.20.89.48.0' => 0, '0.11.133.20.89.48.1' => 1,},
      'airespace_if_name' => {
        '10.109.97.110.97.103.101.109.101.110.116' => 'management',
        '9.115.116.118.45.100.104.99.112.97'       => 'ssid-int',
      },
      'airespace_ap_name' => {'0.11.133.20.89.48' => 'My AP Name',},
      'airespace_ap_loc'  => {'0.11.133.20.89.48' => 'My AP location',},
      'airespace_apif_type' =>
        {'0.11.133.20.89.48.0' => 'dot11a', '0.11.133.20.89.48.1' => 'dot11b',},
      'airespace_if_type' => {
        '10.109.97.110.97.103.101.109.101.110.116' => 'static',
        '9.115.116.118.45.100.104.99.112.97'       => 'dynamic',
      },
      'airespace_apif' =>
        {'0.11.133.20.89.48.0' => 'up', '0.11.133.20.89.48.1' => 'down',},
      'airespace_apif_admin' => {
        '0.11.133.20.89.48.0' => 'enable',
        '0.11.133.20.89.48.1' => 'disable',
      },
    }
  };
  $test->{info}->cache($cache_data);
}

sub layers : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'layers');
  is($test->{info}->layers(), '00000111', q(Layers returns '00000111'));
}

sub serial : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), 'ABC1234567D', q(Serial returns expected value));
}

sub i_index : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_index');

  my $expected = {
    '1'                                        => 1,
    '0.11.133.20.89.48.0'                      => '00:0b:85:14:59:30.0',
    '0.11.133.20.89.48.1'                      => '00:0b:85:14:59:30.1',
    '10.109.97.110.97.103.101.109.101.110.116' => 'management',
    '9.115.116.118.45.100.104.99.112.97'       => 'ssid-int',
  };

  cmp_deeply($test->{info}->i_index(),
    $expected, q(Interface indices have expected values));
}

sub interfaces : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'interfaces');

  my $expected = {
    '1'                                        => '1.1',
    '0.11.133.20.89.48.0'                      => '00:0b:85:14:59:30.0',
    '0.11.133.20.89.48.1'                      => '00:0b:85:14:59:30.1',
    '10.109.97.110.97.103.101.109.101.110.116' => 'management',
    '9.115.116.118.45.100.104.99.112.97'       => 'ssid-int',
  };

  cmp_deeply($test->{info}->interfaces(),
    $expected, q(Interfaces have expected values));
}

sub i_name : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_name');

  my $expected = {
    '1'                                        => 'Unit - 0 Slot - 1 Port - 1',
    '0.11.133.20.89.48.0'                      => 'My AP Name',
    '0.11.133.20.89.48.1'                      => 'My AP Name',
    '10.109.97.110.97.103.101.109.101.110.116' => 'management',
    '9.115.116.118.45.100.104.99.112.97'       => 'ssid-int',
  };

  cmp_deeply($test->{info}->i_name(),
    $expected, q(Interface names have expected values));
}

sub i_description : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_description');

  my $expected = {
    '1' => 'Unit: 0 Slot: 1 Port: 1 Gigabit - Level 0x50a0001',
    '0.11.133.20.89.48.0'                      => 'My AP location',
    '0.11.133.20.89.48.1'                      => 'My AP location',
    '10.109.97.110.97.103.101.109.101.110.116' => 'management',
    '9.115.116.118.45.100.104.99.112.97'       => 'ssid-int',
  };

  cmp_deeply($test->{info}->i_description(),
    $expected, q(Interface descriptions have expected values));
}

sub i_type : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_type');

  my $expected = {
    '1'                                        => 'ethernetCsmacd',
    '0.11.133.20.89.48.0'                      => 'dot11a',
    '0.11.133.20.89.48.1'                      => 'dot11b',
    '10.109.97.110.97.103.101.109.101.110.116' => 'static',
    '9.115.116.118.45.100.104.99.112.97'       => 'dynamic',
  };

  cmp_deeply($test->{info}->i_type(),
    $expected, q(Interface types have expected values));
}

sub i_up : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_up');

  my $expected = {
    '1'                   => 'up',
    '0.11.133.20.89.48.0' => 'up',
    '0.11.133.20.89.48.1' => 'down',
  };

  cmp_deeply($test->{info}->i_up(),
    $expected, q(Interface types have expected values));
}

sub i_up_admin : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_up_admin');

  my $expected = {
    '1'                   => 'up',
    '0.11.133.20.89.48.0' => 'enable',
    '0.11.133.20.89.48.1' => 'disable',
  };

  cmp_deeply($test->{info}->i_up_admin(),
    $expected, q(Interface types have expected values));
}

1;
