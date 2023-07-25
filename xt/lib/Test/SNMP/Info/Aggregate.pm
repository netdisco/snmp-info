# Test::SNMP::Info::Aggregate
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
# THIS SOFTWARE IS PROVIDED BY THE COPYRSNMP::Info::AdslLineIGHT HOLDERS AND CONTRIBUTORS "AS IS"
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

package Test::SNMP::Info::Aggregate;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Aggregate;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  # ieee8023adLag example from Cisco 65xx VSS snmpwalk
  my $cache_data = {
    '_ifStackStatus' => 1,
    '_ifType'        => 1,
    'store'          => {
      'ifStackStatus' => {
        '0.1'     => 'active',
        '1.0'     => 'active',
        '10.0'    => 'active',
        '20.0'    => 'active',
        '80.0'    => 'active',
        '90.0'    => 'active',
        '0.163'   => 'active',
        '163.10'  => 'active',
        '163.90'  => 'active',
        '0.8193'  => 'active',
        '5010.10102' => 'active',
        '5010.10103' => 'active',
        '8193.20' => 'active',
        '8193.80' => 'active',
      },
      'ifType' => {
        '1'    => 'ethernetCsmacd',
        '10'   => 'ethernetCsmacd',
        '20'   => 'ethernetCsmacd',
        '80'   => 'ethernetCsmacd',
        '90'   => 'ethernetCsmacd',
        '10102' => 'ethernetCsmacd',
        '10103' => 'ethernetCsmacd',
        '163'  => 'ieee8023adLag',
        '5010' => 'propVirtual',
        '8193' => 'propMultiplexor',
      },
    }
  };
  $test->{info}->cache($cache_data);
}

sub agg_ports_ifstack : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'agg_ports_ifstack');

  my $expected
    = {'10' => '163', '90' => '163', '20' => '8193', '80' => '8193',};

  cmp_deeply($test->{info}->agg_ports_ifstack(),
    $expected, q(Aggregated links have expected values));
}

1;
