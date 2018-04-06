# Test::SNMP::Info::Layer2::Orinoco
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

package Test::SNMP::Info::Layer2::Orinoco;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer2::Orinoco;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_layers'      => 2,
    '_description' => ' AP-2000 v2.4.5(758)  SN-02UT15570603 v2.0.10',

    # NTWS-REGISTRATION-DEVICES-MIB::ntwsSwitch2380
    '_id'            => '.1.3.6.1.4.1.11898.2.4.6',
    '_i_index'       => 1,
    '_i_description' => 1,
    'store'          => {
      'i_index'       => {1 => 1,     2 => 2,     3 => 3,      4 => 4},
      'i_description' => {1 => 'dp0', 2 => 'lo0', 3 => 'wlc0', 4 => 'empty1'}
    },
  };
  $test->{info}->cache($cache_data);
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'orinoco', q(OS returns 'orinoco'));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '2.4.5', q(OS version returns expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No description returns undef));
}

sub os_bin : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_bin');
  is($test->{info}->os_bin(),
    '2.0.10', q(Firmware version returns expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_bin(), undef, q(No description returns undef));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'proxim', q(Vendor returns 'proxim'));
}

sub model : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'AP-2000', q(Model has expected value));

  $test->{info}->clear_cache();
  is($test->{info}->model(), undef, q(No description returns undef));
}

sub serial : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), '02UT15570603', q(Serial has expected value));

  $test->{info}->clear_cache();
  is($test->{info}->serial(), undef, q(No description returns undef));
}

sub i_ignore : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_ignore');

  my $expected = {2 => 1, 4 => 1};

  cmp_deeply($test->{info}->i_ignore(),
    $expected, q(Interfaces have expected values));
}

sub interfaces : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'interfaces');

  my $expected = {1 => 'dp0', 3 => 'wlc0'};

  cmp_deeply($test->{info}->interfaces(),
    $expected, q(Interfaces have expected values));
}

1;
