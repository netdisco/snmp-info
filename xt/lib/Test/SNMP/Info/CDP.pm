# Test::SNMP::Info::CDP
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

package Test::SNMP::Info::CDP;

use strict;
use warnings;
use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::CDP;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_cdp_run'          => 'true',
    '_cdp_ip'           => 1,
    '_cdp_addr'         => 1,
    '_cdp_proto'        => 1,
    '_cdp_capabilities' => 1,
    '_cdp_dev_id'       => 1,
    '_cdp_dev_port'     => 1,
    'store'             => {
      'cdp_addr'  => {'2.1' => pack("H*", '0A141E28'), '3.1' => 'xyz'},
      'cdp_proto' => {'2.1' => 'ip',                   '3.1' => 'chaos'},
      'cdp_capabilities' => {'2.1' => pack("H*", '00000228')},
      'cdp_dev_id'       => {'2.1' => pack("H*", 'ABCD12345678')},
      'cdp_dev_port'     => {'2.1' => 'My-Port-Name'},
    }
  };
  $test->{info}->cache($cache_data);
}

sub hasCDP : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'hasCDP');
  is($test->{info}->hasCDP(), 1, q(Has 'cdpGlobalRun' has CDP));

  delete $test->{info}{_cdp_run};
  is($test->{info}->hasCDP(),
    1, q(No 'cdpGlobalRun', but has neighbors, has CDP));

  $test->{info}->clear_cache();
  is($test->{info}->hasCDP(),
    undef, q(No 'cdpGlobalRun' and no neighbors, no CDP));
}

sub cdp_if : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'cdp_if');

  my $expected = {'2.1' => 2};

  cmp_deeply($test->{info}->cdp_if(),
    $expected, q(Mapping of CDP interface has expected value));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->cdp_if(), {}, q(No data returns empty hash));
}

sub cdp_ip : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'cdp_ip');

  my $expected = {'2.1' => '10.20.30.40'};

  cmp_deeply($test->{info}->cdp_ip(),
    $expected, q(Remote CDP IPv4 has expected value));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->cdp_ip(), {}, q(No data returns empty hash));
}

sub cdp_cap : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'cdp_cap');

  my $expected = ['IGMP', 'Supports-STP-Dispute', 'Switch'];

  my $caps = $test->{info}->cdp_cap();

  cmp_set($caps->{'2.1'}, $expected, q(Caps emumerated correctly));

  $test->{info}{store}{cdp_capabilities} = {'2.1' => pack("H*", '00000000')};

  cmp_deeply($test->{info}->cdp_cap(), {}, q(Cap of zeros return empty hash));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->cdp_cap(), {}, q(No data returns empty hash));
}

sub cdp_id : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'cdp_id');

  my $expected = {'2.1' => 'ab:cd:12:34:56:78'};

  cmp_deeply($test->{info}->cdp_id(),
    $expected, q(Remote ID packed MAC has expected value));

  $test->{info}{store}{cdp_dev_id} = {'2.1' => 'My-Device-Name'};
  $expected = {'2.1' => 'My-Device-Name'};

  cmp_deeply($test->{info}->cdp_id(),
    $expected, q(Remote ID text has expected value));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->cdp_id(), {}, q(No data returns empty hash));
}

sub cdp_port : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'cdp_port');

  my $expected = {'2.1' => 'My-Port-Name'};

  cmp_deeply($test->{info}->cdp_port(),
    $expected, q(Remote ID text has expected value));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->cdp_port(), {}, q(No data returns empty hash));
}

sub munge_power : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'munge_power');

  is(SNMP::Info::CDP::munge_power(123456),
    '123.456', q(... munges millwatts to watts));
}

1;
