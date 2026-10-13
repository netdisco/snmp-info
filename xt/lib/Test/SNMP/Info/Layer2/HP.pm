# Test::SNMP::Info::Layer2::HP
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

package Test::SNMP::Info::Layer2::HP;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer2::HP;

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
    '_layers' => 2,
    '_description' =>
      'HP J4887A ProCurve Switch 4104GL, revision G.05.02, ROM G.05.01',
    '_id'   => '.1.3.6.1.4.1.11.2.3.7.11.27',
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'hp', q(OS returns 'hp'));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'hp', q(Vendor returns 'hp'));
}

sub model : Tests(23) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'model');

  # Exercise naming from HP-ICF-OID without requiring a device or recent MIBs.
  my @cases = (
    ['arubaJL071A', '3810M-24G'],
    ['arubaJL072A', '3810M-48G'],
    ['arubaJL073A', '3810M-24G-PoE+'],
    ['arubaJL074A', '3810M-48G-PoE+'],
    ['arubaJL075A', '3810M-16SFP+'],
    ['arubaJL076A', '3810M-40G-8SR-PoE+'],
    ['arubaJL077A', '3810M-16SR-PoE+'],
    ['arubaSwitchR0M67A', '2930M-40G-8SR-PoE-Class6'],
    ['arubaSwitchR0M68A', '2930M-24SR-PoE-Class6'],
    ['arubaSwitchJL693A', '2930F-12G-PoE+-2G-2SFP+'],
    ['arubaSwitchJL692A', '2930F-8G-PoE+-2SFP+-TAA'],
    ['arubaSwitchJL263A', '2930F-24G-PoE+-4SFP+-TAA'],
    ['arubaSwitchJL264A', '2930F-48G-PoE+-4SFP+-TAA'],
    ['arubaSwitchJL559A', '2930F-48G-PoE+-4SFP+-740W-TAA'],
    ['hpSwitchJ4887A', '4104GL'],
    ['arubaSwitchJL253A', '2930F-24G-4SFP+'],
    ['arubaSwitchJL999A', 'JL999A'],
    ['arubaJL999A', 'JL999A'],
    ['arubaUnrelated', 'arubaUnrelated'],
    ['ARUBAJL075A', '3810M-16SFP+'],
  );

  {
    no warnings 'redefine';
    local *SNMP::Info::Layer2::HP::id = sub {
      return '.1.3.6.1.4.1.11.2.3.7.11.27';
    };
    my $translated;
    local *SNMP::translateObj = sub { return $translated; };
    for my $case (@cases) {
      $translated = $case->[0];
      is($info->model(), $case->[1], "$translated resolves to $case->[1]");
    }

    $translated = undef;
    is($info->model(), '.1.3.6.1.4.1.11.2.3.7.11.27',
      'Failed translation returns the original OID');
  }

  {
    no warnings 'redefine';
    local *SNMP::Info::Layer2::HP::id = sub { return; };
    is($info->model(), undef, 'Undefined device ID returns undef');
  }
}

1;
