# Test::SNMP::Info::Layer3::Ciena
#
# Copyright (c) 2026 SNMP::Info Developers
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

package Test::SNMP::Info::Layer3::Ciena;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Ciena;

# Remove this startup override once we have full method coverage
sub startup : Tests(startup => 1) {
  my $test = shift;
  $test->SUPER::startup();

  $test->todo_methods(1);
}

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Made-up data: bridge port N maps to ifIndex 10000N, while a few low
  # ifIndex values also exist, as on SAOS 10 devices
  my $cache_data = {
    '_layers'         => 2,
    '_description'    => 'My Bogus Ciena Description',
    '_id'             => '.1.3.6.1.4.1.6141.1.98',
    '_i_description'  => 1,
    '_i_alias'        => 1,
    '_bp_index'       => 1,
    '_lldp_rem_pid'   => 1,
    'store'           => {
      'i_description' => {
        3      => 'Ciena Interface: mgmt',
        4      => 'Ciena Interface: agg1',
        100003 => 'Ciena Port 1/3',
        100007 => 'Ciena Port 1/7',
        100008 => 'Ciena Port 1/8',
      },
      'i_alias'  => {},
      'bp_index' => {3 => 100003, 7 => 100007, 8 => 100008},
      'lldp_rem_pid' => {
        '1001.7.1'  => 'port 1',
        '1002.8.1'  => 'port 2',
        '1003.3.1'  => 'port 3',
        '1004.50.1' => 'port 4',
      },
    },
  };
  $test->{info}->cache($cache_data);
}

sub lldp_if : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_if');

  # lldp_lport_desc is a partial fetch, served from the mocked session
  $test->{info}{sess}{Data} = {
    'LLDP-MIB::lldpLocPortDesc' => {
      3  => 'Ciena Port 1/3',
      7  => 'Ciena Port 1/7',
      50 => 'Ciena Interface: agg1',
    }
  };

  my $expected = {
    '1001.7.1'  => 100007,
    '1002.8.1'  => 100008,
    '1003.3.1'  => 100003,
    '1004.50.1' => 4,
  };

  cmp_deeply($test->{info}->lldp_if(), $expected,
    q(Local ports map to ifIndex once, with or without lldpLocPortDesc));
}

1;
