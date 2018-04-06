# Test::SNMP::Info::FDP
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

package Test::SNMP::Info::FDP;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::FDP;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_fdp_run'        => 'true',
    '_fdp_ip'         => 1,
    '_ifDescr'        => 1,
    '_fdp_port'       => 1,
    '_fdp_cache_type' => 1,
    'store'           => {
      'fdp_ip' => {
        '1.1'  => pack("H*", '0A141E28'),
        '6.1'  => pack("H*", '0A141E29'),
        '68.1' => pack("H*", '0A141E2A'),
        '68.2' => pack("H*", '0A141E2B')
      },
      'ifDescr'  => {'1' => '1/1/1', '6' => '1/1/6', '68' => '1/2/4',},
      'fdp_port' => {
        '1.1'  => 'GigabitEthernet0.1',
        '6.1'  => 'GigabitEthernet0.1',
        '68.1' => 'GigabitEthernet0/7',
        '68.2' => 'ethernet1/2/4'
      },
      'fdp_cache_type' =>
        {'1.1' => 'cdp', '6.1' => 'cdp', '68.1' => 'cdp', '68.2' => 'fdp'},
    }
  };
  $test->{info}->cache($cache_data);
}

sub fdp_run : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'fdp_run');
  is($test->{info}->fdp_run(), 'true', q(FDP running returns 'true'));

  $test->{info}->clear_cache();
  is($test->{info}->fdp_run(), 1, q(FDP run not implemented returns 1));
}

sub hasFDP : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'hasFDP');
  is($test->{info}->hasFDP(), 'true', q(Has FDP));
}

sub fdp_if : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'fdp_if');

  my $expected = {'1.1' => '1', '6.1' => '6', '68.1' => '68', '68.2' => '68'};

  cmp_deeply($test->{info}->fdp_if(),
    $expected, q(Mapping of FDP interfaces have expected values));

  $test->{info}->clear_cache();
  is($test->{info}->fdp_if(), undef, q(No data returns empty hash));
}

# Example from FDP documentation
# Used as verification that we can map essential L2 topo information
sub topo_example_test : Tests(1) {
  my $test = shift;

  # Print out a map of device ports with FDP neighbors:
  my $interfaces = $test->{info}->ifDescr();
  my $fdp_if     = $test->{info}->fdp_if();
  my $fdp_ip     = $test->{info}->fdp_ip();
  my $fdp_port   = $test->{info}->fdp_port();
  my $fdp_type   = $test->{info}->fdp_cache_type();
  my $results    = {};

  # Sorted keys for deterministic order
  foreach my $fdp_key (sort keys %$fdp_ip) {
    my $iid           = $fdp_if->{$fdp_key};
    my $port          = $interfaces->{$iid};
    my $neighbor      = $fdp_ip->{$fdp_key};
    my $neighbor_port = $fdp_port->{$fdp_key};
    my $topo_type     = $fdp_type->{$fdp_key};

    $results->{$port}{$neighbor} = {port => $neighbor_port, type => $topo_type};
  }
  my $expected = {
    '1/1/1' => {'10.20.30.40' => {port => 'GigabitEthernet0.1', type => 'cdp'}},
    '1/1/6' => {'10.20.30.41' => {port => 'GigabitEthernet0.1', type => 'cdp'}},
    '1/2/4' => {
      '10.20.30.42' => {port => 'GigabitEthernet0/7', type => 'cdp'},
      '10.20.30.43' => {port => 'ethernet1/2/4',      type => 'fdp'},
    },
  };

  cmp_deeply($results, $expected,
    q(FDP example maps device ports with FDP neighbors));
}

1;
