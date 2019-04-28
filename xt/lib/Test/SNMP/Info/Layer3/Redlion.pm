# Test::SNMP::Info::Layer3::Redlion
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

package Test::SNMP::Info::Layer3::Redlion;

use strict;
use warnings;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Redlion;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_layers'          => 6,
    '_description'     => 'Linux hostname 2.6.39 #1 Fri Dec 8 18:57:40 UTC 2017 armv5tejl',
    '_id'              => '.1.3.6.1.4.1.1890',
    '_sn_serial'       => '682X55900000000',
    '_sn_model'        => 'SN-6921',
    '_sn_os_ver'       => '4.28.95.0',
    'store'            => {},
  };
  $test->{info}->cache($cache_data);
}

sub layers : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'layers');
  is($test->{info}->layers(), '00000110', q(layers returns '00000110'));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'sn', q(OS returns 'sn'));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '4.28.95.0', q(OS version has expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef,
    q(No os version returns undef));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'redlion', q(vendor returns 'redlion'));
}

sub model : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'SN-6921', q(model has expected value));
}

sub serial : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), '682X55900000000', q(serial has expected value));

  $test->{info}->clear_cache();
  is($test->{info}->serial(), undef,
    q(No serial returns undef));
}

1;
