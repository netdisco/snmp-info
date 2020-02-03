# Test::SNMP::Info::Layer3::Scalance
#
# Copyright (c) 2019 Christoph Handel GSI Helmholtzzentrum fuer
# Schwerionenforschung

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
#     * Neither the name of the University of California, Santa Cruz,
#       the GSI Helmholtzzentrum fuer Schwerionenforschung nor the
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

package Test::SNMP::Info::Layer3::Scalance;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Scalance;

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
  my $version = "V06.02.02";
  my $model = 'Siemens, SIMATIC NET, SCALANCE XR524-8C 2PS, 6GK5 524-8GS00-4AR2, HW: Version 1';
  my $serial = 'SVPL1234567';
  my $iprefix = "$model FW: Version version, $serial";
  
  my $cache_data = {
    '_layers' => 74,
    '_description' => "$model, FW: Version $version, $serial",
    '_id'   => '.1.3.6.1.4.1.4329.6.1.2',
    # i have no idea why i need to add i_description here
    # guess something with calling SUPER
    '_i_description' => {},
    'store' => {
        'i_description' => {
            1 => "$iprefix, Ethernet Port, R0/S0/X1 P1",
            2 => "$iprefix, L3 VLAN, VLAN1",
            3 => "$iprefix, loopback",
        },
    },
  };
  $test->{info}->cache($cache_data);
}

sub layers : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'layers');
  is($test->{info}->layers(), '00000111', q(Layers returns '00000111'));
}

sub model : Tests(2) {
  my $test = shift;
  is($test->{info}->model(), 'SCALANCE XR524-8C 2PS', q(Model extracted));
}

sub i_description : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'interfaces');

  my $expected = {1 => 'R0/S0/X1 P1', 2 => 'VLAN1', 3 => 'loopback'};

  cmp_deeply($test->{info}->i_description(),
    $expected, q(i_description have expected values));
}

1;

# vim: filetype=perl ts=4 sw=4 sta et sts=4 ai
