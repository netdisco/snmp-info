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
    '_ahSystemSerial' => '12345678',

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
      'i_index' => {3 => 3, 10 => 10, 12 => 12, 15 => 15},
      'i_description' =>
        {3 => 'eth0', 10 => 'wifi0.1', 12 => 'wifi0.2', 15 => 'wifi1.1'},
      'i_mac' => {
        3  => pack("H*", '4018B13A4C40'),
        10 => pack("H*", '4018B13A4C54'),
        12 => pack("H*", '4018B13A4C55'),
        15 => pack("H*", '4018B13A4C68')
      },
      'ah_i_ssidlist' =>
        {3 => 'N/A', 10 => 'MyGuest', 12 => 'MyPrivate', 15 => 'MyGuest'},
      'cd11_txrate' => {
        '10.6.128.150.177.92.153.130' => 6000,
        '15.6.40.106.186.61.150.231'  => 58500,
        '15.6.96.190.181.42.99.151'   => 72200
      },
      'ah_c_vlan' => {
        '10.6.128.150.177.92.153.130' => 50,
        '15.6.40.106.186.61.150.231'  => 1,
        '15.6.96.190.181.42.99.151'   => 1
      },
      'ah_c_ip' => {
        '10.6.128.150.177.92.153.130' => '1.2.3.4',
        '15.6.40.106.186.61.150.231'  => '0.0.0.0',
        '15.6.96.190.181.42.99.151'   => '4.3.2.1'
      },
    }
  };
  $test->{info}->cache($cache_data);
}

sub layers : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'layers');
  is($test->{info}->layers(), '00000111', q(Vendor returns '00000011'));
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

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '6.2r1', q(OS version is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No description returns undef os_ver));
}

sub model : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(),
    'AP121', q(Model with 'Hive' in description sting is expected value));

  $test->{info}{_description} = 'AP250, HiveOS 8.3r2 build-191018';
  is($test->{info}->model(),
    'AP250', q(Model without 'Hive' in description sting is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->model(), undef, q(No description returns undef model));
}

sub serial : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), '12345678', q(Serial is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->serial(), undef,
    q(No serial returns undef));
}

sub i_ssidlist : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_ssidlist');

  my $expected = {10 => 'MyGuest', 12 => 'MyPrivate', 15 => 'MyGuest'};

  cmp_deeply($test->{info}->i_ssidlist(),
    $expected, q(Interface SSIDs have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_ssidlist(), {}, q(No data returns empty hash));
}

sub i_ssidmac : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_ssidmac');

  my $expected = {
    10 => '40:18:b1:3a:4c:54',
    12 => '40:18:b1:3a:4c:55',
    15 => '40:18:b1:3a:4c:68'
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
    '10.6.128.150.177.92.153.130' => 'wifi0.1',
    '15.6.40.106.186.61.150.231'  => 'wifi1.1',
    '15.6.96.190.181.42.99.151'   => 'wifi1.1'
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
    '10.6.128.150.177.92.153.130' => '80:96:b1:5c:99:82',
    '15.6.40.106.186.61.150.231'  => '28:6a:ba:3d:96:e7',
    '15.6.96.190.181.42.99.151'   => '60:be:b5:2a:63:97'
  };

  cmp_deeply($test->{info}->cd11_mac(),
    $expected, q(Wireless clients MACs have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->cd11_mac(), {}, q(No data returns empty hash));
}

sub bp_index : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'bp_index');

  my $expected = {3 => 3, 10 => 10, 12 => 12, 15 => 15};

  cmp_deeply($test->{info}->bp_index(),
    $expected, q(Bridge interface mapping has expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->bp_index(), {}, q(No data returns empty hash));
}

sub qb_fw_port : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'qb_fw_port');

  my $expected = {
    '10.6.128.150.177.92.153.130' => '10',
    '15.6.40.106.186.61.150.231'  => '15',
    '15.6.96.190.181.42.99.151'   => '15'
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
    '10.6.128.150.177.92.153.130' => '80:96:b1:5c:99:82',
    '15.6.40.106.186.61.150.231'  => '28:6a:ba:3d:96:e7',
    '15.6.96.190.181.42.99.151'   => '60:be:b5:2a:63:97'
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
    '10.6.128.150.177.92.153.130' => 50,
    '15.6.40.106.186.61.150.231'  => 1,
    '15.6.96.190.181.42.99.151'   => 1
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
    '10.6.128.150.177.92.153.130' => '80:96:b1:5c:99:82',
    '15.6.40.106.186.61.150.231'  => '28:6a:ba:3d:96:e7',
    '15.6.96.190.181.42.99.151'   => '60:be:b5:2a:63:97'
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
    '10.6.128.150.177.92.153.130' => '1.2.3.4',
    '15.6.96.190.181.42.99.151'   => '4.3.2.1'
  };

  cmp_deeply($test->{info}->at_netaddr(),
    $expected, q(ARP IP entries have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->at_netaddr(), {}, q(No data returns empty hash));
}

1;
