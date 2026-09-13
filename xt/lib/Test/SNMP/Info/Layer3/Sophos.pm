# Test::SNMP::Info::Layer3::Sophos
#
# Copyright (c) 2026 The SNMP::Info Developers
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

package Test::SNMP::Info::Layer3::Sophos;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Sophos;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests.
  # SFOS does not implement sysServices, so there is no '_layers' to cache;
  # the class reports its own layers and is selected by sysObjectID.
  my $cache_data = {
    '_description' => 'SFOS 22.0.1 MR-1-Build490',
    '_id'          => '.1.3.6.1.4.1.2604.5',
    '_os_ver'      => '22.0.1 MR-1-Build490',
    '_serial1'     => 'XXXXXXXXXXXXX',
    '_sfos_model'  => 'XGS118_XN01_SFOS',
    'store'        => {},
  };
  $test->{info}->cache($cache_data);
}

sub layers : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'layers');
  is($test->{info}->layers(), '01001100', q(Layers returns '01001100'));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'sophos', q(Vendor returns 'sophos'));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'sfos', q(OS returns 'sfos'));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '22.0.1 MR-1-Build490',
    q(OS version is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No data returns undef OS version));
}

sub model : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'XGS118_XN01_SFOS', q(Model is expected value));

  # %l3sysoidmap keys on the bare enterprise number, so appliances under
  # other 2604 subtrees reach this class too without serving sfosDeviceType.
  # They must not lose the model the inherited method would have given them.
  delete $test->{info}->{'_sfos_model'};
  ok(defined $test->{info}->model(),
    q(Without sfosDeviceType the model falls back to the inherited method));

  $test->{info}->clear_cache();
  is($test->{info}->model(), undef, q(No data returns undef model));
}

sub serial : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), 'XXXXXXXXXXXXX', q(Serial is expected value));
}

1;
