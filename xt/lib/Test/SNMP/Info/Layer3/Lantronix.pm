# Test::SNMP::Info::Layer3::Lantronix
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

package Test::SNMP::Info::Layer3::Lantronix;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Lantronix;

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
    '_layers' => 79,
    '_description' => 'My Name V5.2.0.0R24 (01234567A8BC)',

    # LANTRONIX-MIB::evo
    '_id'   => '.1.3.6.1.4.1.244.1.13',
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

my $eds_descr     = 'Lantronix EDS16PR V6.0.0.0R5 (0519086817IR5G)';
my $eds5000_descr = 'Lantronix EDS5016 2.1.0.0R3 (00C0F2000001)';

sub _set_description {
  my ($test, $description) = @_;

  $test->{info}->clear_cache();
  $test->{info}->cache({'_description' => $description});
}

sub os : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'EvolutionOS',
    q(Renamed EDS is EvolutionOS by sysObjectID));

  # LANTRONIX-MIB::slc
  $test->{info}->clear_cache();
  $test->{info}->cache({
    '_description' => 'SLC 8.4.0.0R1',
    '_id'          => '.1.3.6.1.4.1.244.1.1',
  });
  is($test->{info}->os(), 'LantronixOS', q(SLC is LantronixOS));

  $test->_set_description($eds_descr);
  is($test->{info}->os(), 'EvolutionOS', q(EDS is EvolutionOS));

  $test->_set_description($eds5000_descr);
  is($test->{info}->os(), 'EvolutionOS',
    q(EDS5000 without a V before the version is EvolutionOS));
}

sub os_ver : Tests(6) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '5.2.0.0R24',
    q(Renamed EDS version from the end of sysDescr));

  $test->_set_description($eds_descr);
  is($test->{info}->os_ver(), '6.0.0.0R5', q(EDS version after V));

  $test->_set_description($eds5000_descr);
  is($test->{info}->os_ver(), '2.1.0.0R3', q(EDS5000 version without V));

  $test->{info}->clear_cache();
  $test->{info}->cache({
    '_description' => $eds5000_descr,
    '_slc_os_ver'  => '8.4.0.0R1',
  });
  is($test->{info}->os_ver(), '8.4.0.0R1', q(SLC firmware is preferred));

  $test->_set_description('Lantronix EDS16PR');
  is($test->{info}->os_ver(), undef, q(No version in sysDescr returns undef));
}

sub serial : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), '01234567A8BC',
    q(Renamed EDS serial from the end of sysDescr));

  $test->_set_description($eds_descr);
  is($test->{info}->serial(), '0519086817IR5G', q(EDS serial));

  $test->_set_description($eds5000_descr);
  is($test->{info}->serial(), '00C0F2000001',
    q(EDS5000 serial without V before the version));
}

sub model : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), undef,
    q(Renamed EDS sysDescr carries no model));

  $test->_set_description($eds_descr);
  is($test->{info}->model(), 'EDS16PR', q(EDS model));

  $test->_set_description($eds5000_descr);
  is($test->{info}->model(), 'EDS5016', q(EDS5000 model));
}

1;
