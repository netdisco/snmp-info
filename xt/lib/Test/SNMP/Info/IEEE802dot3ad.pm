# Test::SNMP::Info::IEEE802dot3ad
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

package Test::SNMP::Info::IEEE802dot3ad;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::IEEE802dot3ad;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_ad_lag_ports' => 1,
    'store'         => {

      # Unpacked 'C0' has first two bits set to 1 all others 0
      # Simple example taken from a 24 port switch to minimize
      # unpacked array length
      'ad_lag_ports' => {25 => pack("H*", 'C0')}
    },
  };
  $test->{info}->cache($cache_data);
}

sub agg_ports_lag : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'agg_ports_lag');

  my $expected = {1 => 25, 2 => 25};

  cmp_deeply($test->{info}->agg_ports_lag(),
    $expected, q(Aggregated links have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->agg_ports_lag(), {}, q(No data returns empty hash));
}

1;
