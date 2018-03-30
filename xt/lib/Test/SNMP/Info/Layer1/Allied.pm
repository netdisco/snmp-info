# Test::SNMP::Info::Layer1::Allied
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

package Test::SNMP::Info::Layer1::Allied;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer1::Allied;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_layers'      => 1,
    '_description' => 'My Allied hub AT-1234T version 3.10',
    '_id'          => '.1.3.6.1.4.1.207.1.2.1',
    '_i_name'      => 1,
    '_i_up'        => 1,
    '_ati_p_name'  => 1,
    '_ati_up'      => 1,
    '_rptr_up'     => 1,
    'store'        => {
      'i_name'     => {'1'   => '1 Port Name'},
      'i_up'       => {'1'   => 'up'},
      'ati_p_name' => {'1.1' => "", '1.2' => '1.2 Port Name', '1.3' => ""},
      'ati_up'     => {'1.2' => 'nolinktesterror', '1.3' => 'linktesterror'},
      'rptr_up' => {
        '1.1' => 'operational',
        '1.2' => 'operational',
        '1.3' => 'operational'
      },
    }
  };
  $test->{info}->cache($cache_data);
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'allied', q(Vendor returns 'allied'));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'allied', q(Vendor returns 'allied'));
}


sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '3.10', q(OS version is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No description returns undef os_ver));
}

sub model : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'AT-1234T', q(Model is expected value));
  
  $test->{info}->clear_cache();
  is($test->{info}->model(), undef, q(No description returns undef model));  
}

sub i_name : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_name');

  my $expected = {'1' => '1 Port Name', '1.2' => '1.2 Port Name',};

  is_deeply($test->{info}->i_name(),
    $expected, q(Interface names have expected values));
}

sub i_up : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_up');

  my $expected = {'1' => 'up', '1.1' => 'up', '1.2' => 'up', '1.3' => 'down'};

  is_deeply($test->{info}->i_up(),
    $expected, q(Interface operational statuses have expected values));
}

1;
