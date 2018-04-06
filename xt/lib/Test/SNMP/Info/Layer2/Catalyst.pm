# Test::SNMP::Info::Layer2::Catalyst
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

package Test::SNMP::Info::Layer2::Catalyst;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer2::Catalyst;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $d_string = 'Cisco Systems WS-C5500.Cisco ';
  $d_string .= ' Catalyst Operating System Software, Version 5.5(13a).';
  my $cache_data = {
    '_layers'      => 2,
    '_description' => $d_string,

    # CISCO-STACK-MIB::wsc5500sysID
    '_id'      => '.1.3.6.1.4.1.9.5.17',
    '_m_swver' => 1,
    '_i_index' => 1,
    '_p_port'  => 1,
    '_p_oidx'  => 1,
    '_p_name'  => 1,
    'store'    => {
      'm_swver' => {1     => '5.5(13a)'},
      'i_index' => {1     => 1, 3 => 3, 12 => 12},
      'p_port'  => {'1.1' => 3, '2.1' => 12},
      'p_oidx'  => {'1.1' => 1, '2.1' => 65},
      'p_name'  => {'1.1' => 'My Port Name 1.1', '2.1' => 'My Port Name 2.1'},
    },
  };
  $test->{info}->cache($cache_data);
}

sub i_physical : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_physical');

  my $expected = {3 => 1, 12 => 1};

  cmp_deeply($test->{info}->i_physical(),
    $expected, q(Physical interfaces are identified));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_physical(),
    {}, q(No port data returns empty hash));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'cisco', q(Vendor returns 'cisco'));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'catalyst', q(Vendor returns 'catalyst'));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '5.5(13a)', q(OS version is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(),
    undef, q(No module sw version returns undef OS version));
}

sub bp_index : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'bp_index');

  my $expected = {1 => 3, 65 => 12};

  cmp_deeply($test->{info}->bp_index(),
    $expected, q(Interfaces have expected name values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->bp_index(),
    {}, q(No bridge index data returns empty hash));
}

sub cisco_comm_indexing : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'cisco_comm_indexing';
  is($test->{info}->cisco_comm_indexing(), 1, 'Cisco community indexing on');
}

sub interfaces : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'interfaces');

  my $expected = {1 => 1, 3 => '1/1', 12 => '2/1'};

  cmp_deeply($test->{info}->interfaces(),
    $expected, q(Interfaces have expected values));
}

sub i_name : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_name');

  my $expected =  {3 => 'My Port Name 1.1', 12 => 'My Port Name 2.1'};

  cmp_deeply($test->{info}->i_name(),
    $expected, q(Interfaces have expected name values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_name(), {}, q(No name data returns empty hash));
}

1;
