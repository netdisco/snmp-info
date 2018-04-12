# Test::SNMP::Info::Layer3::C6500
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

package Test::SNMP::Info::Layer3::C6500;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::C6500;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $d_string = 'Cisco IOS Software, ';
  $d_string .= 's2t54 Software (s2t54-ADVIPSERVICESK9-M), ';
  $d_string .= 'Version 15.1(2)SY3, RELEASE SOFTWARE (fc4)';
  my $cache_data = {
    '_layers'      => 78,
    '_description' => $d_string,

    # CISCO-PRODUCTS-MIB::catalyst65xxVirtualSwitch
    '_id'             => '.1.3.6.1.4.1.9.1.896',
    '_serial1' => '12345678',
    '_serial2' => 'ABC1234D56E',
    '_cvsSwitchMode' => 'multiNode',
    '_e_serial' => 1,
    '_el_duplex'      => 1,
    '_p_port'         => 1,
    '_p_duplex'       => 1,
    '_p_duplex_admin' => 1,
    '_p_speed'        => 1,
    '_mau_index'      => 1,
    '_mau_autostat'   => 1,
    '_mau_type_admin' => 1,
    'store'           => {
      'e_serial' => { 1 => undef, 1000 => 'ABC1234D56F'},
      'el_duplex' => {
        '2'  => 'fullDuplex',
        '3'  => 'halfDuplex',
        '4'  => 'fullDuplex',
        '26' => 'fullDuplex'
      },
      'p_port' => {'0.1' => 2, '0.2' => 3, '0.3' => 4, '2.1' => 26},
      'p_duplex' =>
        {'0.1' => 'auto', '0.2' => 'half', '0.3' => 'full', '2.1' => 'auto'},
      'p_duplex_admin' => {
        '0.1' => pack("H*", 'E0'),
        '0.2' => pack("H*", 'E0'),
        '0.3' => pack("H*", 'E0'),
        '2.1' => pack("H*", '00'),
      },
      'p_speed' => {
        '0.1' => 'autoDetect',
        '0.2' => 's100000000',
        '0.3' => 's100000000',
        '2.1' => 'autoDetect',
      },
      'mau_index'    => {1.1 => 1, 2.1 => 2, 3.1 => 3, 4.1 => 4, 5.1 => 5},
      'mau_autostat' => {
        1.1 => 'enabled',
        2.1 => 'disabled',
        3.1 => 'disabled',
        4.1 => 'disabled',
        5.1 => 'disabled'
      },

      # .1.3.6.1.2.1.26.4.15 = IANA-MAU-MIB::dot3MauType100BaseTXHD
      # .1.3.6.1.2.1.26.4.16 = IANA-MAU-MIB::dot3MauType100BaseTXFD
      # .1.3.6.1.2.1.26.4.35 = IANA-MAU-MIB::dot3MauType10GigBaseLR
      'mau_type_admin' => {
        1.1 => '.0.0',
        2.1 => '.0.0',
        3.1 => '.1.3.6.1.2.1.26.4.15',
        4.1 => '.1.3.6.1.2.1.26.4.16',
        5.1 => '.1.3.6.1.2.1.26.4.35',
      },
    },
  };
  $test->{info}->cache($cache_data);
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'cisco', q(Vendor returns 'cisco'));
}

sub serial : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), '12345678', q(Serial returns 'serial1' first));

  delete $test->{info}{_serial1};
  is($test->{info}->serial(), 'ABC1234D56E', q(Serial returns 'serial2' next));

  delete $test->{info}{_serial2};
  is($test->{info}->serial(), 'ABC1234D56F', q(Serial returns first entity next));

  $test->{info}->clear_cache();
  is($test->{info}->serial(), '', q(Serial returns empty string with no data));
}

sub i_duplex : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex');

  my $expected = {2 => 'full', 3 => 'half', 4 => 'full', 26 => 'full'};

  cmp_deeply($test->{info}->i_duplex(),
    $expected, q(Interfaces have expected duplex values using etherlike));

  delete $test->{info}{_el_duplex};
  delete $test->{info}{store}{el_duplex};
  $expected = {3 => 'half', 4 => 'full', 26 => 'full'};
  cmp_deeply($test->{info}->i_duplex(),
    $expected, q(Interfaces have expected duplex values using ciscostack));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_duplex(),
    {}, q(No duplex data returns empty hash));
}

sub i_duplex_admin : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex_admin');

  my $expected = {2 => 'auto', 3 => 'half', 4 => 'full', 26 => 'auto'};

  cmp_deeply($test->{info}->i_duplex_admin(),
    $expected, q(Interfaces have expected duplex admin values using etherlike));

  delete $test->{info}{_el_duplex};
  delete $test->{info}{store}{el_duplex};
  $expected = {2 => 'auto', 3 => 'half', 4 => 'full', 26 => 'full'};
  cmp_deeply($test->{info}->i_duplex_admin(),
    $expected,
    q(Interfaces have expected duplex admin values using ciscostack));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_duplex_admin(),
    {}, q(No duplex admin data returns empty hash));
}

sub is_virtual_switch : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'is_virtual_switch');
  is($test->{info}->is_virtual_switch(), 1, q(Multi node returns 1));

  $test->{info}{_cvsSwitchMode} = 'standalone';
  is($test->{info}->is_virtual_switch(), 0, q(Standalone retuns 0));

  $test->{info}->clear_cache();
  is($test->{info}->is_virtual_switch(), 0, q(No data returns 0));
}

sub set_i_duplex_admin : Tests(5) {
  my $test = shift;

  # Set method uses a partial fetch which ignores the cache and reloads data
  # therefore we must use the mocked session.
  my $data = {
    'MAU-MIB::ifMauDefaultType' => {
        1.1 => '.0.0',
        2.1 => '.0.0',
        3.1 => '.1.3.6.1.2.1.26.4.15',
        4.1 => '.1.3.6.1.2.1.26.4.16',
        5.1 => '.1.3.6.1.2.1.26.4.35',
    },
  };
  $test->{info}{sess}{Data} = $data;

  can_ok($test->{info}, 'mau_set_i_duplex_admin');

  is($test->{info}->mau_set_i_duplex_admin('full', 3),
    1, q(VSS mock set duplex call succeeded));

  is($test->{info}->mau_set_i_duplex_admin('full-x', 2),
    undef, q(VSS mock set duplex call to bad duplex type 'full-x' fails));

  # Test non-VSS
  delete $test->{info}{_cvsSwitchMode};

  # Set method uses a partial fetch which ignores the cache and reloads data
  # therefore we must use the mocked session.
  $data = {
    'EtherLike-MIB::dot3StatsDuplexStatus' => {
      '1'  => 'fullDuplex',
      '2'  => 'halfDuplex',
      '3'  => 'fullDuplex',
      '26' => 'fullDuplex'
    },
  };
  $test->{info}{sess}{Data} = $data;

  is($test->{info}->set_i_duplex_admin('full', 2),
    1, q(Non-VSS mock set duplex call succeeded));

  is($test->{info}->set_i_duplex_admin('full-x', 2),
    0, q(Non-VSS mock set duplex call to bad duplex type 'full-x' fails));
}

sub set_i_speed_admin : Tests(5) {
  my $test = shift;

  # Set method uses a partial fetch which ignores the cache and reloads data
  # therefore we must use the mocked session.
  my $data = {
    'MAU-MIB::ifMauDefaultType' => {
        1.1 => '.0.0',
        2.1 => '.0.0',
        3.1 => '.1.3.6.1.2.1.26.4.15',
        4.1 => '.1.3.6.1.2.1.26.4.16',
        5.1 => '.1.3.6.1.2.1.26.4.35',
    },
  };
  $test->{info}{sess}{Data} = $data;
  can_ok($test->{info}, 'set_i_speed_admin');

  is($test->{info}->set_i_speed_admin('100', 3),
    1, q(VSS mock set speed call succeeded));

  is($test->{info}->set_i_speed_admin('auto-x', 2),
    undef, q(VSS mock set speed call to bad speed 'auto-x' fails));

  # Test non-VSS
  delete $test->{info}{_cvsSwitchMode};

  is($test->{info}->set_i_speed_admin('100', 2),
    1, q(Non-VSS mock set speed call succeeded));

  is($test->{info}->set_i_speed_admin('auto-x', 2),
    0, q(Non-VSS mock set speed call to bad speed 'auto-x' fails));
}

1;
