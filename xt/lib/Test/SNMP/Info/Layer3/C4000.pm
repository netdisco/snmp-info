# Test::SNMP::Info::Layer3::C4000
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

package Test::SNMP::Info::Layer3::C4000;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::C4000;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $d_string = 'Cisco IOS Software, IOS-XE Software, ';
  $d_string .= 'Catalyst 4500 L3 Switch Software (cat4500e-UNIVERSALK9-M), ';
  $d_string .= 'Version 03.09.01.E RELEASE SOFTWARE (fc1)';
  my $cache_data = {
    '_layers'      => 6,
    '_description' => $d_string,

    # CISCO-PRODUCTS-MIB::cat4xxxVirtualSwitch
    '_id'             => '.1.3.6.1.4.1.9.1.1732',
    '_fan_state'      => 1,
    '_fan_descr'      => 1,
        '_mau_index'        => 1,
          '_mau_autostat'   => 1,
          '_mau_type_admin' => 1,
          'store'           => {
          'fan_state' => {
            101 => 'normal',
            102 => 'warning',
            103 => 'notPresent',
            201 => 'shutdown',
            202 => 'critical',
            203 => 'notFunctioning'
          },
          'fan_descr' => {
            101 => 'chassis-1 Chassis Fan Tray 1',
            102 => 'chassis-1 Power Supply 1 Fan',
            103 => 'chassis-1 Power Supply 2 Fan',
            201 => 'chassis-2 Chassis Fan Tray 1',
            202 => 'chassis-2 Power Supply 1 Fan',
            203 => 'chassis-2 Power Supply 2 Fan'
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

sub fan : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'fan');

  my $expected = 'chassis-1 Chassis Fan Tray 1: normal, ';
  $expected .= 'chassis-1 Power Supply 1 Fan: warning, ';
  $expected .= 'chassis-1 Power Supply 2 Fan: notPresent, ';
  $expected .= 'chassis-2 Chassis Fan Tray 1: shutdown, ';
  $expected .= 'chassis-2 Power Supply 1 Fan: critical, ';
  $expected .= 'chassis-2 Power Supply 2 Fan: notFunctioning';
  is($test->{info}->fan(), $expected, q(Vendor returns 'cisco'));

  $test->{info}->clear_cache();
  is($test->{info}->fan(), undef, q(No data returns undef));
}

sub i_duplex_admin : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex_admin');

  my $expected
    = {1 => 'auto', 2 => 'auto', 3 => 'half', 4 => 'full'};

  cmp_deeply($test->{info}->i_duplex_admin(),
    $expected, q(Interfaces have expected duplex admin values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_duplex_admin(),
    {}, q(No duplex admin data returns empty hash));
}

sub i_speed_admin : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_speed_admin');

  my $expected = {1 => 'auto', 2 => 'auto', 3 => '100 Mbps', 4 => '100 Mbps', 5 => '10 Gbps'};

  cmp_deeply($test->{info}->i_speed_admin(),
    $expected, q(Interfaces have expected speed admin values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_speed_admin(),
    {}, q(No speed admin data returns empty hash));
}

sub set_i_speed_admin : Tests(3) {
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
    1, q(Mock set speed call succeeded));

  is($test->{info}->set_i_speed_admin('auto-x', 2),
    undef, q(Mock set speed call to bad speed 'auto-x' fails));
}

sub set_i_duplex_admin : Tests(3) {
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

  can_ok($test->{info}, 'set_i_duplex_admin');

  is($test->{info}->set_i_duplex_admin('full', 3),
    1, q(Mock set duplex call succeeded));

  is($test->{info}->set_i_duplex_admin('full-x', 2),
    undef, q(Mock set duplex call to bad duplex type 'full-x' fails));
}

1;
