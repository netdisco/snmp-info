# Test::SNMP::Info::Layer2::ZyXEL_DSLAM
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

package Test::SNMP::Info::Layer2::ZyXEL_DSLAM;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer2::ZyXEL_DSLAM;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_layers'      => 2,
    '_description' => 'My 8-port ADSL Module(Annex A) version 1.2.3 ',

    # No registration MIB, just use enterprise ID
    '_id'           => '.1.3.6.1.4.1.890',
    '_ip_addresses' => 1,
    'store' =>
      {'ip_addresses' => {'2.3.4.5' => '2.3.4.5', '1.2.3.4' => '1.2.3.4'}},
  };
  $test->{info}->cache($cache_data);
}

sub layers : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'layers');
  is($test->{info}->layers(), '00000010', q(Layers returns '00000011'));

  $test->{info}->clear_cache();
  is($test->{info}->layers(), '00000011', q(Layers returns '00000011'));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'zyxel', q(Vendor returns 'zyxel'));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'zyxel', q(OS returns 'zyxel'));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '1.2.3', q(OS version returns expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef,
    q(No description returns undef OS version));
}

sub model : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'AAM1008-61', q(Model is expected value));

  $test->{info}->{_description}
    = 'My 8-port ADSL Module(Annex B) version 1.2.3';
  is($test->{info}->model(), 'AAM1008-63', q(Model is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->model(), undef, q(No description returns undef model));
}

sub ip : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'ip');
  is($test->{info}->ip(), '2.3.4.5', q(IP returns expected value));

  $test->{info}->clear_cache();
  is($test->{info}->ip(), undef, q(No data returns undef));
}

1;
