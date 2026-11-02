# Test::SNMP::Info::Layer2::Netgear
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

package Test::SNMP::Info::Layer2::Netgear;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer2::Netgear;

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
    '_layers' => 2,
    '_description' =>
      'My Bogus Netgear Description ',

    # We don't have MIBs loaded to resolve so all we need is the right vendor
    '_id'                   => '.1.3.6.1.4.1.4526',
    '_ng_fsosver' => '',
    '_ng_gsmserial' => '',
    '_ng_gsmosver' => '',

    # Shaped from a GS110TP: ifName gN, and an ifAlias column that is
    # empty until a description is configured
    '_i_index'       => 1,
    '_i_description' => 1,
    '_i_name'        => 1,
    '_i_alias'       => 1,
    'store'                 => {
      'i_index'       => {1 => 1, 2 => 2, 13 => 13},
      'i_description' => {
        1  => 'Slot: 0 Port: 1 Gigabit - Level',
        2  => 'Slot: 0 Port: 2 Gigabit - Level',
        13 => ' CPU Interface for Slot: 5 Port: 1'
      },
      'i_name'  => {1 => 'g1',        2 => 'g2', 13 => 'CPU Interface:  5/1'},
      'i_alias' => {1 => 'Uplink A',  2 => '',   13 => ''},
    },
  };
  $test->{info}->cache($cache_data);
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'netgear', q(OS returns 'netgear'));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'netgear', q(Vendor returns 'netgear'));
}

sub i_name : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_name');
  cmp_deeply($test->{info}->i_name(),
    {1 => 'Uplink A', 2 => 'g2', 13 => 'CPU Interface:  5/1'},
    q(i_name__ifalias_set__returns_ifalias));

  delete $test->{info}{store}{i_alias};
  cmp_deeply($test->{info}->i_name(),
    {1 => 'g1', 2 => 'g2', 13 => 'CPU Interface:  5/1'},
    q(i_name__no_ifalias__returns_ifname));
}

sub interfaces : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'interfaces');
  cmp_deeply($test->{info}->interfaces(),
    {1 => 'g1', 2 => 'g2', 13 => 'CPU Interface:  5/1'},
    q(interfaces__ifalias_set__keeps_ifname));
}

1;
