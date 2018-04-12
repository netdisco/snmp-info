# Test::SNMP::Info::CiscoStack
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

package Test::SNMP::Info::CiscoStack;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::CiscoStack;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    # Doesn't matter to our code, but serial1 defined as and integer in MIB,
    # while serial2 is a string. Formatting from snmp walks although
    # actual value modified to not use real serial #'s
    '_serial1' => '12345678',
    '_serial2' => 'ABC1234D56E',
    '_p_port'         => 1,
    '_p_duplex'       => 1,
    '_p_duplex_admin' => 1,
    '_p_speed'        => 1,
    'store'           => {
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
    },
  };
  $test->{info}->cache($cache_data);
}

sub munge_port_status : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'munge_port_status');

  my $expected = 'other ok minorFault majorFault';
  is(SNMP::Info::CiscoStack::munge_port_status(pack("H*", '01020304')),
    $expected, q(Munges statuses to aggregate string));

  # Not sure this is what we really want, but this is how code is
  # written
  is(SNMP::Info::CiscoStack::munge_port_status(pack("H*", '0506')),
    ' ', q(Unknown statuses returns space));
  is(SNMP::Info::CiscoStack::munge_port_status(),
    '', q(Empty arg returns empty string));
}

sub serial : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), '12345678', q(Serial returns 'serial1' first));

  delete $test->{info}{_serial1};
  is($test->{info}->serial(), 'ABC1234D56E', q(Serial returns 'serial2' next));

  delete $test->{info}{_serial2};
  is($test->{info}->serial(), undef, q(Serial returns undef with no data));
}

sub i_duplex : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex');

  my $expected = {3 => 'half', 4 => 'full', 26 => 'full'};
  cmp_deeply($test->{info}->i_duplex(),
    $expected, q(Interfaces have expected duplex values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_duplex(),
    {}, q(No duplex data returns empty hash));
}

sub i_duplex_admin : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex_admin');

  my $expected = {2 => 'auto', 3 => 'half', 4 => 'full', 26 => 'full'};
  cmp_deeply($test->{info}->i_duplex_admin(),
    $expected,
    q(Interfaces have expected duplex admin values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_duplex_admin(),
    {}, q(No duplex admin data returns empty hash));
}

sub i_speed_admin : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_speed_admin');

  my $expected = {2 => 'auto', 3 => '100 Mbps', 4 => '100 Mbps', 26 => 'auto'};

  cmp_deeply($test->{info}->i_speed_admin(),
    $expected, q(Interfaces have expected speed admin values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_speed_admin(),
    {}, q(No speed admin data returns empty hash));
}

sub set_i_speed_admin : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'set_i_speed_admin');

  is($test->{info}->set_i_speed_admin('100', 2),
    1, q(Mock set speed call succeeded));

  is($test->{info}->set_i_speed_admin('auto-x', 2),
    0, q(Mock set speed call to bad speed 'auto-x' fails));
}

sub set_i_duplex_admin : Tests(3) {
  my $test = shift;

  # Set method uses a partial fetch which ignores the cache and reloads data
  # therefore we must use the mocked session.
  my $data = {
    'EtherLike-MIB::dot3StatsDuplexStatus' => {
      '1'  => 'fullDuplex',
      '2'  => 'halfDuplex',
      '3'  => 'fullDuplex',
      '26' => 'fullDuplex'
    },
  };
  $test->{info}{sess}{Data} = $data;

  can_ok($test->{info}, 'set_i_duplex_admin');

  is($test->{info}->set_i_duplex_admin('full', 2),
    1, q(Mock set duplex call succeeded));

  is($test->{info}->set_i_duplex_admin('full-x', 2),
    0, q(Mock set duplex call to bad duplex type 'full-x' fails));
}

1;