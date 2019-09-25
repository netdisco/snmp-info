# Test::SNMP::Info::Layer7::Neoteris
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

package Test::SNMP::Info::Layer7::Neoteris;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer7::Neoteris;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_layers'      => 72,
    '_description' => 'Pulse Secure, LLC,Pulse Connect Secure,PSA-3000,8.2R7.2 (build 55673)',

    # PULSESECURE-PSG-MIB::ivePSA3000
    # _pulse_os_ver newline is intentional, this is what the appliance returns
    # see netdisco github issue #647
    '_id'             => '.1.3.6.1.4.1.12532.256.2.1',
    '_pulse_os_ver' => "8.3R7.1 (build 65025)\n",
    'store'           => {},
  };
  $test->{info}->cache($cache_data);
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'pulsesecure', q(Vendor returns 'pulsesecure'));
}

sub os_ver  : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '8.3R7.1 (build 65025)', q(os_ver returns '8.3R7.1 (build 65025)'));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'ive', q(OS returns 'ive'));
}

sub model : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'PSA3000', q(model returns 'PSA3000'));
}

sub serial : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), '', q(Serial returns expected value));
}

1;
