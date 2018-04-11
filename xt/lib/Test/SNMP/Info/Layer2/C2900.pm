# Test::SNMP::Info::Layer2::C2900
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

package Test::SNMP::Info::Layer2::C2900;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer2::C2900;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $d_string = 'Cisco Internetwork Operating System Software ';
  $d_string .= 'IOS (tm) C2900XL Software (C2900XL-C3H2S-M), ';
  $d_string .= 'Version 12.0(5)XU, RELEASE SOFTWARE (fc1)';
  my $cache_data = {
    '_layers'      => 2,
    '_description' => $d_string,

    # CISCO-PRODUCTS-MIB::catalyst2924MXL
    '_id'                   => '.1.3.6.1.4.1.9.1.220',
    '_i_index'              => 1,
    '_i_description'        => 1,
    '_c2900_p_index'        => 1,
    '_c2900_p_duplex'       => 1,
    '_c2900_p_duplex_admin' => 1,
    '_c2900_p_speed_admin'  => 1,
    '_p_port'               => 1,
    'store'                 => {
      'i_index'       => {2 => 2, 3 => 3, 26 => 26},
      'i_description' => {
        2  => 'FastEthernet0/1',
        3  => 'FastEthernet0/2',
        26 => 'FastEthernet2/1'
      },
      'c2900_p_index' => {'0.1' => 2, '0.2' => 3, '2.1' => 26},
      'c2900_p_duplex' =>
        {'0.1' => 'fullduplex', '0.2' => 'halfduplex', '2.1' => 'fullduplex'},
      'c2900_p_duplex_admin' => {
        '0.1' => 'autoNegotiate',
        '0.2' => 'autoNegotiate',
        '2.1' => 'fullduplex'
      },
      'c2900_p_speed_admin' =>
        {'0.1' => 'autoDetect', '0.2' => 'autoDetect', '2.1' => 's100000000'},
      'p_port' => {'0.1' => 2, '0.2' => 3, '2.1' => 26},

    },
  };
  $test->{info}->cache($cache_data);
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'cisco', q(Vendor returns 'cisco'));
}

sub cisco_comm_indexing : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'cisco_comm_indexing';
  is($test->{info}->cisco_comm_indexing(), 1, 'Cisco community indexing on');
}

sub i_duplex : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex');

  my $expected = {2 => 'full', 3 => 'half', 26 => 'full'};

  cmp_deeply($test->{info}->i_duplex(),
    $expected, q(Interfaces have expected duplex values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_duplex(),
    {}, q(No duplex data returns empty hash));
}

sub i_duplex_admin : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex_admin');

  my $expected = {2 => 'auto', 3 => 'auto', 26 => 'full'};

  cmp_deeply($test->{info}->i_duplex_admin(),
    $expected, q(Interfaces have expected duplex admin values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_duplex_admin(),
    {}, q(No duplex admin data returns empty hash));
}

sub i_speed_admin : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_speed_admin');

  my $expected = {2 => 'auto', 3 => 'auto', 26 => '100 Mbps'};

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
    undef, q(Mock set speed call to bad speed 'auto-x' fails));
}

sub set_i_duplex_admin : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'set_i_duplex_admin');

  is($test->{info}->set_i_duplex_admin('full', 2),
    1, q(Mock set duplex call succeeded));

  is($test->{info}->set_i_duplex_admin('full-x', 2),
    undef, q(Mock set duplex call to bad duplex type 'full-x' fails));
}

sub interfaces : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'interfaces');

  my $expected
    = {2 => 'FastEthernet0/1', 3 => 'FastEthernet0/2', 26 => 'FastEthernet2/1'};

  cmp_deeply($test->{info}->interfaces(),
    $expected, q(Interfaces have expected values));
}

1;
