# Test::SNMP::Info::Layer3::Cisco
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

package Test::SNMP::Info::Layer3::Cisco;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Cisco;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $d_string = 'Cisco Internetwork Operating System Software ';
  $d_string .= 'IOS (tm) C1700 Software (C1700-NY-M), ';
  $d_string .= 'Version 12.2(8)YM, EARLY DEPLOYMENT RELEASE SOFTWARE (fc1)';
  my $cache_data = {
    '_layers'      => 78,
    '_description' => $d_string,

    # CISCO-PRODUCTS-MIB::cisco1721
    '_id'                 => '.1.3.6.1.4.1.9.1.444',
    '_vtp_version'        => 2,
    '_i_type'             => 1,
    '_i_description'      => 1,
    '_c_eigrp_peers'      => 1,
    '_c_eigrp_peer_types' => 1,
    'store'               => {
      'i_type' => {
        1 => 'ppp',
        2 => 'ethernetCsmacd',
        3 => 'other',
        4 => 'l2vlan',
        5 => 'l2vlan'
      },
      'i_description' => {
        1 => 'Serial0',
        2 => 'FastEthernet0',
        3 => 'Null0',
        4 => 'FastEthernet0.101-802.1Q vLAN subif',
        5 => 'FastEthernet0.102-802.1Q vLAN subif'
      },
      'c_eigrp_peers' => {
        '0.5.0'      => '1.2.3.4',
        '0.5.1'      => pack("H*", '0A141E28'),
        '0.10.1'     => 'host.my.dns',
        '65536.10.2' => '::1.2.3.4',
        '65536.10.3' => 'fe80::2d0:b7ff:fe21:c6c0'
      },
      'c_eigrp_peer_types' => {
        '0.5.0'      => 'ipv4',
        '0.5.1'      => 'ipv4',
        '0.10.1'     => 'dns',
        '65536.10.2' => 'ipv6',
        '65536.10.3' => 'ipv6',
      },
    },
  };
  $test->{info}->cache($cache_data);
}

# This class is a collection of roles and not meant to instantiated for a
# specific device. Don't test device class and no need to setup data
sub device_type : Tests(1) {
  my $test  = shift;
  my $class = $test->class;

  can_ok($test->{info}, 'device_type');

}

# Only going to test the non-VTP path in this class and assume CiscoVTP will
# test the SUPER::i_vlan method, since this class will handle traditional
# routers that usually don't have VTP.
sub i_vlan : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_vlan');

  my $expected = {4 => 101, 5 => 102};

  cmp_deeply($test->{info}->i_vlan(),
    $expected, q(802.1Q interfaces have expected VLAN values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_vlan(), {}, q(No data data returns empty hash));
}

sub cisco_comm_indexing : Tests(3) {
  my $test = shift;

  can_ok $test->{info}, 'cisco_comm_indexing';
  is($test->{info}->cisco_comm_indexing(),
    1, 'VTP version, Cisco community indexing on');

  $test->{info}->clear_cache();
  is($test->{info}->cisco_comm_indexing(), 0, 'Cisco community indexing off');
}

sub eigrp_peers : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'eigrp_peers');

  my $expected = {
    '0.5.0'      => '1.2.3.4',
    '0.5.1'      => '10.20.30.40',
    '65536.10.2' => '0:0:0:0:0:0:102:304',
    '65536.10.3' => 'fe80:0:0:0:2d0:b7ff:fe21:c6c0'
  };

  cmp_deeply($test->{info}->eigrp_peers(),
    $expected, q(EIGRP peers have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->eigrp_peers(),
    {}, q(No data data returns empty hash));
}

1;
