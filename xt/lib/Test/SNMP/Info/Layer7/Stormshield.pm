# Test::SNMP::Info::Layer7::Stormshield
#
# Copyright (c) 2025 snmp-info Developers
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

package Test::SNMP::Info::Layer7::Stormshield;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer7::Stormshield;

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
    '_layers'      => 72,
    '_description' => 'NS-BSD SNSS1A13B0001 amd64',
    '_id'            => '.1.3.6.1.4.1.11256.2.0',

    # STORMSHIELD-HA-MIB::snsFwSerial
    '_hamib_serial' => {
      '0' => 'SNSS1A13B0001',
      '1' => 'SNSS1A13B0002',
    },
    '_hamib_model' => {
      '0' => 'SN-S-Series-220',
      '1' => 'SN-S-Series-220'
    },
    '_hamib_version' => {
      '0' => '4.3.0',
      '1' => '4.3.0'
    },

    # STORMSHIELD-PROPERTY-MIB::snsSerialNumber
    '_propmib_serial' => 'SNSS1A13B0001',
    '_propmib_model' => 'SN-S-Series-220',
    '_propmib_version' => '4.3.0',

    'store'        => {
      'hamib_model' => {
        '0' => 'SN-S-Series-220',
        '1' => 'SN-S-Series-220'
      },
      'hamib_serial' => {
        '0' => 'SNSS1A13B0001',
        '1' => 'SNSS1A13B0002',
      }
    }
  };
  $test->{info}->cache($cache_data);
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'SNS', q(OS returns 'SNS'));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'stormshield', q(Vendor returns 'stormshield'));
}

sub serial : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is(
    $test->{info}->serial(),
    'SNSS1A13B0001 SNSS1A13B0002',
    q(Serial returns expected concatenated values));

  $test->{info}->clear_cache();
  is($test->{info}->serial(), '', q(No data returns empty string));
}

sub model : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'SN-S-Series-220', q(Model returns expected value));

  $test->{info}->clear_cache();
  is($test->{info}->model(), '', q(No data returns empty string));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '4.3.0', q(OS version returns expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), '', q(No data returns empty string));
}



1;
