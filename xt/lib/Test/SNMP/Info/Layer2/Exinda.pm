# Test::SNMP::Info::Layer2::Exinda
#
# Copyright (c) 2019 nick nauwelaerts
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

package Test::SNMP::Info::Layer2::Exinda;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer2::Exinda;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_id'          => '.1.3.6.1.4.1.21091',
    '_layers'      => 72,
    '_description' => 'Linux exinda-8063 3.10.72-72EXINDAsmp #0 SMP @1484583999 x86_64',

    '_serial1' => '109836a9a4a9',
    '_exinda_model'  => '8063',
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'exos', q(os returns 'exos'));

  # hardcoded, so no check for undef
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'exinda');
  is($test->{info}->vendor(), 'exinda', q(vendor returns 'exinda'));

  # hardcoded, so no check for undef
}

sub layers : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'layers');
  is($test->{info}->layers(), '01001110', q(layers returns '01001110'));

  # hardcoded, so no check for undef
}

sub model : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), '8063', q(model is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->model(), undef, q(no data returns undef model));
}

sub mac : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'mac');
  is($test->{info}->mac(), '10:98:36:a9:a4:a9', q(mac is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->mac(), undef, q(no data returns undef mac));
}


1;
