# Test::SNMP::Info::Layer3::Lancom
#
# Copyright (c) 2026 df-an and the SNMP::Info Developers
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

package Test::SNMP::Info::Layer3::Lancom;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Lancom;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  my $cache_data = {
    '_layers'        => 4,
    '_description'   => 'LANCOM 1926VAG',
    '_id'            => '.1.3.6.1.4.1.2356.11.1.47',
    '_lancom_model'  => 'LANCOM 1926VAG',
    '_lancom_serial' => '4004217917100012',
    '_lancom_fw'     => '10.50.1482SU15 / 07.09.2024',
    'store'          => {},
  };
  $test->{info}->cache($cache_data);
}

sub model : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'LANCOM 1926VAG', q(Model is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->model(), undef, q(No model data returns undef));
}

sub serial : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), '4004217917100012',
    q(Serial number is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->serial(), undef, q(No serial data returns undef));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'LCOS', q(OS returns 'LCOS'));
}

sub os_ver : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '10.50.1482SU15',
    q(Firmware date suffix is removed));

  $test->{info}{_lancom_fw} = '  10.42.0012RU3  ';
  is($test->{info}->os_ver(), '10.42.0012RU3',
    q(Firmware without suffix is trimmed));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No firmware data returns undef));

  $test->{info}{_lancom_fw} = '';
  is($test->{info}->os_ver(), undef, q(Empty firmware data returns undef));
}

1;
