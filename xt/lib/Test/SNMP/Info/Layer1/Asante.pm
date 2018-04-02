# Test::SNMP::Info::Layer1::Asante
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

package Test::SNMP::Info::Layer1::Asante;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer1::Asante;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  my $phy_addr = pack("H*", '0000944037B3');

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_layers' => 1,
    '_description' =>
      'AsanteHub 1012 with SNMP agent and TELNET software v3.0.Compiled ',
    '_id'            => '.1.3.6.1.4.1.298.2.2.1',
    '_rptr_port'     => 1,
    '_asante_up'     => 1,
    '_i_speed'       => 1,
    '_i_mac'         => 1,
    '_i_description' => 1,
    'store'          => {
      'rptr_port' => {'1.1' => '1', '1.2' => '2', '2.1' => '1', '2.2' => '2'},
      'asante_up' => {
        '1.1' => 'others',
        '1.2' => 'linkoff',
        '2.1' => 'linkon',
        '2.2' => 'linkon'
      },
      'i_speed'       => {'1' => 10000000},
      'i_mac'         => {'1' => $phy_addr},
      'i_description' => {'1' => 'AsanteHub 1012 SNMP port'},
    }
  };
  $test->{info}->cache($cache_data);
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'asante', q(Vendor returns 'asante'));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'asante', q(Vendor returns 'asante'));
}


sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '3.0', q(OS version is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No description returns undef os_ver));
}

sub model : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'hub1012', q(Model is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->model(), undef, q(No id returns undef model));
}

sub interfaces : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'interfaces');
  my $expected
    = {'1.1' => '1.1', '1.2' => '1.2', '2.1' => '2.1', '2.2' => '2.2'};

  cmp_deeply($test->{info}->interfaces(),
    $expected, q(Interface indices have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->interfaces(),
    {}, q(Empty SNMP table results in empty hash));
}

sub i_up : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_up');
  my $expected = {'1.2' => 'down', '2.1' => 'up', '2.2' => 'up'};

  cmp_deeply($test->{info}->i_up(),
    $expected, q(Interface operational statuses have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_up(),
    {}, q(Empty SNMP table results in empty hash));
}

sub i_speed : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_speed');

  # Munge in effect
  my $expected = {'1.2' => '10 Mbps'};

  cmp_deeply($test->{info}->i_speed(),
    $expected, q(Interface speeds have expected values));
}

sub i_mac : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_mac');

  # Munge in effect
  my $expected = {'1.2' => '00:00:94:40:37:b3'};

  cmp_deeply($test->{info}->i_mac(),
    $expected, q(Interface speeds have expected values));
}

sub i_description : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_description');

  is($test->{info}->i_description(), undef, q(Interfaces have no descriptions));
}

sub i_name : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_name');

  # Munge in effect
  my $expected = {'1.2' => 'AsanteHub 1012 SNMP port'};

  cmp_deeply($test->{info}->i_name(),
    $expected, q(Interface names have expected values));
}

1;
