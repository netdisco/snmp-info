# Test::SNMP::Info::Layer2::Aerohive
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

package Test::SNMP::Info::Layer2::Aerohive;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer2::Aerohive;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {

    # Example walk had no sysServices returned
    #'_layers'      => 1,
    '_description' => 'HiveAP121, HiveOS 6.2r1 release build1924',
    '_ahSystemSerial' => '02511610111621',
    # not documented, oid '.1.3.6.1.4.1.26928.1.3.2.0'
    '_ah_mac' => '4018:b13a:4c40',

    # AH-SMI-MIB::ahProduct
    '_id'            => '.1.3.6.1.4.1.26928.1',
    '_i_index'       => 1,
    '_i_description' => 1,
    '_i_mac'         => 1,
    '_ah_i_ssidlist' => 1,
    '_cd11_txrate'   => 1,
    '_ah_c_vlan'     => 1,
    '_ah_c_ip'       => 1,
    'store'          => {
      'i_index' => {4 => 4, 6 => 6, 7 => 7, 9 => 9, 15 => 15, 16 => 16, 20 => 20},
      'i_description' =>
        {4 => 'eth0', 6 => 'wifi0', 7 => 'wifi1', 9 => 'mgt0', 15 => 'wifi0.1', 16 => 'wifi0.2', 20 => 'wifi1.1'},
      'i_mac' => {
# mgt0 always has lowest mac, most of the time shared with eth0
# wifi0 shares it's mac with wifi0.1 (same goes for wifi1/wifi1.1)
# wifi0's mac address is 14 digits higher as base mac
# wifi1's mac address is 10 digits higher as wifi0
        4  => pack("H*", '4018B13A4C40'),
        6  => pack("H*", '4018B13A4C54'),
        7  => pack("H*", '4018B13A4C64'),
        9  => pack("H*", '4018B13A4C40'),
        15 => pack("H*", '4018B13A4C54'),
        16 => pack("H*", '4018B13A4C55'),
        20 => pack("H*", '4018B13A4C64')
      },
      'ah_i_ssidlist' =>
        {4 => 'N/A', 6 => 'N/A', 7 => 'N/A', 9 => 'N/A', 15 => 'MyGuest', 16 => 'MyPrivate', 20 => 'MyGuest'},
      'cd11_txrate' => {
        '15.6.128.150.177.92.153.130' => 6000,
        '20.6.40.106.186.61.150.231'  => 58500,
        '20.6.96.190.181.42.99.151'   => 72200
      },
      'ah_c_vlan' => {
        '15.6.128.150.177.92.153.130' => 50,
        '20.6.40.106.186.61.150.231'  => 1,
        '20.6.96.190.181.42.99.151'   => 1
      },
      'ah_c_ip' => {
        '15.6.128.150.177.92.153.130' => '1.2.3.4',
        '20.6.40.106.186.61.150.231'  => '0.0.0.0',
        '20.6.96.190.181.42.99.151'   => '4.3.2.1'
      },
    }
  };
  $test->{info}->cache($cache_data);
}

sub layers : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'layers');
  is($test->{info}->layers(), '00000111', q(Layers returns '00000111'));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'aerohive', q(Vendor returns 'aerohive'));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'hiveos', q(OS returns 'hiveos'));
}

sub os_ver : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '6.2r1', q(OS version is expected value));

  $test->{info}{_description} = 'AP250, HiveOS 10.0r8 build-236132';
  is($test->{info}->os_ver(),
    '10.0r8', q(10.0r8 is expected os version));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No description returns undef os_ver));
}

sub mac : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'mac');

  my $expected = '40:18:b1:3a:4c:40';

  is($test->{info}->mac(),
    $expected, q(mac address derived from ah_mac is expected value));

  $test->{info}{_ah_mac} = undef;
  is($test->{info}->mac(),
    $expected, q(mac address derived from lowest interface mac is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->mac(), undef, q(No mac returns undef mac));
}

sub model : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(),
    'AP121', q(Model with 'Hive' in description is expected value));

  $test->{info}{_description} = 'AP250, HiveOS 8.3r2 build-191018';
  is($test->{info}->model(),
    'AP250', q(Model without 'Hive' in description is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->model(), undef, q(No description returns undef model));
}

sub serial : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), '02511610111621', q(Serial is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->serial(), undef,
    q(No serial returns undef));
}

sub i_ssidlist : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_ssidlist');

  my $expected = {15 => 'MyGuest', 16 => 'MyPrivate', 20 => 'MyGuest'};

  cmp_deeply($test->{info}->i_ssidlist(),
    $expected, q(Interface SSIDs have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_ssidlist(), {}, q(No data returns empty hash));
}

sub i_ssidmac : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_ssidmac');

  my $expected = {
    15 => '40:18:b1:3a:4c:54',
    16 => '40:18:b1:3a:4c:55',
    20 => '40:18:b1:3a:4c:64'
  };

  cmp_deeply($test->{info}->i_ssidmac(),
    $expected, q(Wireless MACs have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_ssidmac(), {}, q(No data returns empty hash));
}

sub cd11_port : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'cd11_port');

  my $expected = {
    '15.6.128.150.177.92.153.130' => 'wifi0.1',
    '20.6.40.106.186.61.150.231'  => 'wifi1.1',
    '20.6.96.190.181.42.99.151'   => 'wifi1.1'
  };

  cmp_deeply($test->{info}->cd11_port(),
    $expected, q(Wireless clients map to wireless interfaces));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->cd11_port(), {}, q(No data returns empty hash));
}

sub cd11_mac : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'cd11_mac');

  my $expected = {
    '15.6.128.150.177.92.153.130' => '80:96:b1:5c:99:82',
    '20.6.40.106.186.61.150.231'  => '28:6a:ba:3d:96:e7',
    '20.6.96.190.181.42.99.151'   => '60:be:b5:2a:63:97'
  };

  cmp_deeply($test->{info}->cd11_mac(),
    $expected, q(Wireless clients MACs have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->cd11_mac(), {}, q(No data returns empty hash));
}

sub bp_index : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'bp_index');

  # aerohive->bp_index uses load_i_index, which clears cached data, so
  # mock up the needed snmp data.
  my $data
    = {'IF-MIB::ifIndex' =>
        {4 => 4, 6 => 6, 7 => 7, 9 => 9, 15 => 15, 16 => 16, 20 => 20},
       'RFC1213-MIB::ifIndex' =>
        {4 => 4, 6 => 6, 7 => 7, 9 => 9, 15 => 15, 16 => 16, 20 => 20},
    };
  $test->{info}{sess}{Data} = $data;

  my $expected = {4 => 4, 6 => 6, 7 => 7, 9 => 9, 15 => 15, 16 => 16, 20 => 20};

  cmp_deeply($test->{info}->bp_index(),
    $expected, q(Bridge interface mapping has expected values));

  # and now delete the data so we can test for empty returns
  delete $test->{info}{_i_index};
  delete $test->{info}{store}{i_index};
  $test->{info}{sess}{Data} = {};
  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->bp_index(), {}, q(No data returns empty hash));
}

sub qb_fw_port : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'qb_fw_port');

  my $expected = {
    '15.6.128.150.177.92.153.130' => '15',
    '20.6.40.106.186.61.150.231'  => '20',
    '20.6.96.190.181.42.99.151'   => '20'
  };

  cmp_deeply($test->{info}->qb_fw_port(),
    $expected, q(MAC interface mapping has expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->qb_fw_port(), {}, q(No data returns empty hash));
}

sub qb_fw_mac : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'qb_fw_mac');

  my $expected = {
    '15.6.128.150.177.92.153.130' => '80:96:b1:5c:99:82',
    '20.6.40.106.186.61.150.231'  => '28:6a:ba:3d:96:e7',
    '20.6.96.190.181.42.99.151'   => '60:be:b5:2a:63:97'
  };

  cmp_deeply($test->{info}->qb_fw_mac(),
    $expected, q(MAC forwarding entries has expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->qb_fw_mac(), {}, q(No data returns empty hash));
}

sub qb_fw_vlan : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'qb_fw_vlan');

  my $expected = {
    '15.6.128.150.177.92.153.130' => 50,
    '20.6.40.106.186.61.150.231'  => 1,
    '20.6.96.190.181.42.99.151'   => 1
  };

  cmp_deeply($test->{info}->qb_fw_vlan(),
    $expected, q(MAC forwarding entries has expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->qb_fw_vlan(), {}, q(No data returns empty hash));
}

sub at_paddr : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'at_paddr');

  my $expected = {
    '15.6.128.150.177.92.153.130' => '80:96:b1:5c:99:82',
    '20.6.40.106.186.61.150.231'  => '28:6a:ba:3d:96:e7',
    '20.6.96.190.181.42.99.151'   => '60:be:b5:2a:63:97'
  };

  cmp_deeply($test->{info}->at_paddr(),
    $expected, q(ARP MAC entries have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->at_paddr(), {}, q(No data returns empty hash));
}

sub at_netaddr : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'at_netaddr');

  my $expected = {
    '15.6.128.150.177.92.153.130' => '1.2.3.4',
    '20.6.96.190.181.42.99.151'   => '4.3.2.1'
  };

  cmp_deeply($test->{info}->at_netaddr(),
    $expected, q(ARP IP entries have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->at_netaddr(), {}, q(No data returns empty hash));
}

1;
