# Test::SNMP::Info::Layer3::Fortinet
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

package Test::SNMP::Info::Layer3::Fortinet;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Fortinet;

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
    '_layers' => 78,
    '_description' => 'firewall',

    # FORTINET-FORTIGATE-MIB::fgt500E
    '_id'   => '.1.3.6.1.4.1.12356.101.1.5005',

    '_fnSysSerial' => 'FG5H0E5810000000',
    '_fgSysVersion' => 'v6.0.11,build0387,200917 (GA)',
    '_i_index' => 1,
    '_orig_i_name' => 1,
    'store' => {
      'i_index'       => {
        1 => 1,
        2 => 2,
        3 => 3
      },
      'orig_i_name'       => {
        1 => "ha",
        2 => "mgmt",
        3 => "port1"
      },
    },
  };
  $test->{info}->cache($cache_data);
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'fortinet', q(Vendor returns 'fortinet'));
}

sub model : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), '500E', q(Model is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->model(), '', q(No model info returns undef model));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'fortios', q(os returns 'fortios'));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '6.0.11', q(os_ver is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), '', q(No os_ver info returns undef os_ver));
}

sub serial : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), 'FG5H0E5810000000', q(serial number is expected value'));
}

1;
