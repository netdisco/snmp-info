# Test::SNMP::Info::Layer2::C1900
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

package Test::SNMP::Info::Layer2::C1900;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer2::C1900;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_layers'      => 11,
    '_description' => 'Cisco Systems Catalyst 1900,V9.00.06 ',

    # CISCO-STACK-MIB::wsc1900sysID
    '_id'                 => '.1.3.6.1.4.1.9.5.18',
    '_c1900_flash_status' => 'V9.00.06     written from 100.200.003.004',
    '_bridgeGroupAllowMembershipOverlap'  => 'disabled',
    '_i_index'                            => 1,
    '_i_description'                      => 1,
    '_i_name'                             => 1,
    '_c1900_p_ifindex'                    => 1,
    '_c1900_p_duplex'                     => 1,
    '_c1900_p_duplex_admin'               => 1,
    '_c1900_p_name'                       => 1,
    '_bridgeGroupMemberPortOfBridgeGroup' => 1,
    'store'                               => {
      'i_index'         => {1 => 1, 2 => 2, 3 => 3, 4 => 4},
      'i_description'   => {1 => 1, 2 => 2, 3 => 3, 4 => 4},
      'i_name'          => {1 => 1, 2 => 2, 3 => 3, 4 => 'AUI'},
      'c1900_p_ifindex' => {1 => 1, 2 => 2, 3 => 3, 4 => 4},
      'c1900_p_duplex'  => {
        1 => 'full-duplex',
        2 => 'half-duplex',
        3 => 'full-duplex',
        4 => 'half-duplex',
      },
      'c1900_p_duplex_admin' =>
        {1 => 'enabled', 2 => 'disabled', 3 => 'flow control', 4 => 'auto',},
      'c1900_p_name' => {1 => 'My Port Name', 2 => undef, 3 => ' ', 4 => '',},
      'bridgeGroupMemberPortOfBridgeGroup' => {
        '1.1' => 'true',
        '1.2' => 'true',
        '1.3' => 'false',
        '1.4' => 'false',
        '2.1' => 'false',
        '2.2' => 'false',
        '2.3' => 'true',
        '2.4' => 'false',
        '3.1' => 'false',
        '3.2' => 'false',
        '3.3' => 'false',
        '3.4' => 'true',
      },

    },
  };
  $test->{info}->cache($cache_data);
}

sub bulkwalk_no : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'bulkwalk_no';
  is($test->{info}->bulkwalk_no(), 1, 'Bulkwalk turned off in this class');
}

sub cisco_comm_indexing : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'cisco_comm_indexing';
  is($test->{info}->cisco_comm_indexing(), 1, 'Cisco community indexing on');
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'cisco', q(Vendor returns 'cisco'));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'catalyst', q(OS returns 'catalyst'));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '9.00.06', q(OS version is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef,
    q(No description returns undef OS version));
}

sub interfaces : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'interfaces');

  my $expected = {1 => 1, 2 => 2, 3 => 3, 4 => 4,};

  cmp_deeply($test->{info}->interfaces(),
    $expected, q(Interfaces have expected values));
}

sub i_duplex : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex');

  my $expected = {1 => 'full', 2 => 'half', 3 => 'full', 4 => 'half',};

  cmp_deeply($test->{info}->i_duplex(),
    $expected, q(Interfaces have expected duplex values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_duplex(),
    {}, q(No duplex data returns empty hash));
}

sub i_duplex_admin : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex_admin');

  my $expected = {1 => 'full', 2 => 'half', 3 => 'full', 4 => 'auto',};

  cmp_deeply($test->{info}->i_duplex_admin(),
    $expected, q(Interfaces have expected duplex admin values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_duplex_admin(),
    {}, q(No duplex admin data returns empty hash));
}

sub i_name : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_name');

  my $expected = {1 => 'My Port Name', 2 => 2, 3 => 3, 4 => 'AUI',};

  cmp_deeply($test->{info}->i_name(),
    $expected, q(Interfaces have expected name values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_name(), {}, q(No name data returns empty hash));
}

sub set_i_duplex_admin : Tests(4) {
  my $test = shift;

  # Set method uses a partial fetch which ignores the cache and reloads data
  # therefore we must use the mocked session.
  my $data = {

    # This is defined in %FUNCS as c1900_p_ifindex
    'STAND-ALONE-ETHERNET-SWITCH-MIB::swPortIfIndex' =>
      {1 => 1, 2 => 2, 3 => 3, 4 => 4},
  };
  $test->{info}{sess}{Data} = $data;

  can_ok($test->{info}, 'set_i_duplex_admin');

  is($test->{info}->set_i_duplex_admin('full', 2),
    1, q(Mock set duplex call succeeded));

  is($test->{info}->set_i_duplex_admin('full', 5),
    0, q(Mock set duplex call to non-existant port fails));

  is($test->{info}->set_i_duplex_admin('full-x', 2),
    0, q(Mock set duplex call to bad duplex type 'full-x' fails));
}

sub i_vlan : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'i_vlan');

  my $expected = {1 => 1, 2 => 1, 3 => 2, 4 => 3};

  cmp_deeply($test->{info}->i_vlan(),
    $expected, q(Interfaces have expected PVID values));

  delete $test->{info}{'_bridgeGroupAllowMembershipOverlap'};
  $test->{info}{'_vlanAllowMembershipOverlap'} = 'enabled';
  cmp_deeply($test->{info}->i_vlan(),
    {}, q(VLAN overlap enabled returns empty hash));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_vlan(), {}, q(No VLAN data returns empty hash));
}

sub i_vlan_membership : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_vlan_membership');

  my $expected = {1 => [1], 2 => [1], 3 => [2], 4 => [3]};

  cmp_deeply($test->{info}->i_vlan_membership(),
    $expected, q(Interfaces have expected VLAN values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_vlan_membership(),
    {}, q(No VLAN data returns empty hash));
}

sub i_vlan_membership_untagged : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_vlan_membership_untagged');

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_vlan_membership_untagged(),
    {}, q(VLAN untagged membership not applicable returns empty hash));
}

sub bp_index : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'bp_index');

  my $expected = {1 => 1, 2 => 2, 3 => 3, 4 => 4,};

  cmp_deeply($test->{info}->bp_index(),
    $expected, q(Interfaces have expected name values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->bp_index(),
    {}, q(No bridge index data returns empty hash));
}

1;
