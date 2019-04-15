# Test::SNMP::Info::Layer3::Lenovo
#
# Copyright (c) 2019 nick nauwelaerts
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

package Test::SNMP::Info::Layer3::Lenovo;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Lenovo;

# XXX can be removed when agg_ports_cnos is implemented
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
    '_id'          => '.1.3.6.1.4.1.19046.1.7.32',
    '_layers'      => 14,
    '_description' => 'Lenovo ThinkSystem NE1032 RackSwitch',

    '_i_index'      => 1,
    '_i_speed_high' => 1,
    'store' => {
      'i_index' => {
         2      => 2,
         10310  => 10310,
         103999 => 103999,
         410001 => 410001,
      },
      'i_speed_high' => {
         2      => 1000,
         10310  => 0,
         103999 => 20000,
         410001 => 10000,
      },
    },
  };
  $test->{info}->cache($cache_data);
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'cnos', q(OS returns 'cnos'));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'lenovo', q(Vendor returns 'lenovo'));
}

sub i_speed : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_speed');

  my $expected = {
    2      => "1.0 Gbps",
    10310  => "0 Mbps",
    103999 => "20 Gbps",
    410001 => "10 Gbps",
  };

  cmp_deeply($test->{info}->i_speed(),
    $expected, q(i_speed data has expected values));

  # do we want undef or empty hash?
  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_speed(), undef, q(i_speed no data returns empty undef));
}

sub i_speed_raw : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_speed_raw');

  # set original mib data to make sure we simulate everything correctly
  my $data = {
    'IF-MIB::ifSpeed' => {
      2      => 1000000000,
      10310  => 8000,
      103999 => 2820130816,
      410001 => 1410065408,
    },
    'IF-MIB::ifHighSpeed' => {
      2      => 1000,
      10310  => 0,
      103999 => 20000,
      410001 => 10000,
    },
  };
  $test->{info}{sess}{Data} = $data;

  my $expected = {
    2      => 1000000000,
    10310  => 8000,
    103999 => 20000000000,
    410001 => 10000000000,
  };

  cmp_deeply($test->{info}->i_speed_raw(),
    $expected, q(i_speed_raw data has expected values));

  delete $test->{info}{_i_speed_raw};
  delete $test->{info}{store}{i_speed_raw};
  $test->{info}{sess}{Data} = {};
  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_speed_raw(), {}, q(i_speed_raw no data returns empty hash));
}

1;
