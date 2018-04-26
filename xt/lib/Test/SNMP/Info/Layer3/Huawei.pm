# Test::SNMP::Info::Layer3::Huawei
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

package Test::SNMP::Info::Layer3::Huawei;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Huawei;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $d_string
    = 'Huawei Versatile Routing Platform Software VRP (R) software, ';
  $d_string .= 'Version 8.100 (CE6810EI V100R005C10SPC200) ';

  my $cache_data = {
    '_layers'      => 4,
    '_description' => $d_string,

    # HUAWEI-MIB::ce6810-48S4Q-EI
    '_id'                  => '.1.3.6.1.4.1.2011.2.239.12',
    '_i_index'             => 1,
    '_i_description'       => 1,
    '_hw_eth_duplex'       => 1,
    '_hw_eth_auto'         => 1,
    '_el_index'            => 1,
    '_el_duplex'           => 1,
    '_hw_trunk_if_idx'     => 1,
    '_hw_trunk_entry'      => 1,
    '_ad_lag_ports'        => 1,
    '_hw_l2if_port_idx'    => 1,
    '_bp_index'            => 1,
    '_hw_phy_port_slot'    => 1,
    '_hw_peth_power_watts' => 1,
    '_hw_peth_port_admin'  => 1,
    '_hw_peth_port_status' => 1,
    '_hw_peth_port_class'  => 1,
    '_hw_peth_port_power'  => 1,

    'store' => {
      'i_index'       => {1 => 1, 6 => 6, 7 => 7, 8 => 8},
      'i_description' => {
        1 => 'InLoopBack0',
        6 => 'GigabitEthernet0/0/1',
        7 => 'GigabitEthernet0/0/2',
        8 => 'GigabitEthernet0/0/3'
      },
      'hw_eth_duplex'   => {6 => 'full',    7  => 'full',     8 => 'half'},
      'hw_eth_auto'     => {6 => 'enabled', 7  => 'disabled', 8 => 'disabled'},
      'el_index'        => {9 => 9,         10 => 10},
      'el_duplex'       => {9 => 'full',    10 => 'half'},
      'hw_trunk_if_idx' => {0 => 121},
      'hw_trunk_entry'   => {'0.55' => 'valid',   '0.110' => 'valid'},
      'ad_lag_ports'     => {34     => pack("H*", '00000060')},
      'hw_l2if_port_idx' => {26     => 30,        27      => 31},
      'bp_index'         => {2      => 1,         7       => 3},
      'hw_phy_port_slot' => {6      => 0,         7       => 0, 8 => 0},
      'hw_peth_power_watts' => {0 => 369600},
      'hw_peth_port_admin' => {6 => 'enabled', 7 => 'disabled', 8 => 'enabled'},
      'hw_peth_port_status' =>
        {6 => 'Powered', 7 => 'Disabled', 8 => 'Detecting'},
      'hw_peth_port_class' => {6 => 3,    7 => 0, 8 => 0},
      'hw_peth_port_power' => {6 => 3763, 7 => 0, 8 => 0},
    },
  };
  $test->{info}->cache($cache_data);
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'Huawei', q(Vendor returns 'Huawei'));
}

sub os : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'VRP', q(OS returns 'VRP' when description matches));

  $test->{info}->clear_cache();
  is($test->{info}->os(), 'huawei', q(... and 'huawei' when it doesn't));
}

sub os_ver : Tests(7) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');

  is(
    $test->{info}->os_ver(),
    '8.100 V100R005C10SPC200',
    q(OS version returned from 'sysDescr' example 1)
  );

  my $descr = 'Version 3.40, Release 0311P07 Quidway Series Router AR28-31 ';
  $test->{info}{_description} = $descr;

  is($test->{info}->os_ver(),
    '3.40 0311P07', q(OS version returned from 'sysDescr'example 2));

  $descr = 'Version 3.40, Feature 0308 Quidway Series Router AR46-40 ';
  $test->{info}{_description} = $descr;

  is($test->{info}->os_ver(),
    '3.40 0308', q(OS version returned from 'sysDescr'example 3));

  $descr = 'Version 3.40, Feature 0121L01.Quidway Router AR18-34E.';
  $test->{info}{_description} = $descr;

  is($test->{info}->os_ver(),
    '3.40 0121L01', q(OS version returned from 'sysDescr'example 4));

  $descr = 'software,Version 5.120 (AR151 V200R003C01SPC100) ';
  $test->{info}{_description} = $descr;

  is(
    $test->{info}->os_ver(),
    '5.120 V200R003C01SPC100',
    q(OS version returned from 'sysDescr'example 5)
  );

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No data returns undef OS version));
}

# Not overriden in class, but tested anyway
sub model : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'ce6810-48S4Q-EI', q(Model translates id));
}

sub i_ignore : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_ignore');

  my $expected = {1 => 1};
  cmp_deeply($test->{info}->i_ignore(),
    $expected, q(Loopback interface ignored));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_ignore(), {}, q(No matches returns empty hash));
}

sub bp_index : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'bp_index');

  my $expected = {26 => 30, 27 => 31};
  cmp_deeply($test->{info}->bp_index(),
    $expected, q(Bridge to interface index mapping using 'hwL2IfPortIfIndex'));

  delete $test->{info}{'_hw_l2if_port_idx'};
  $expected = {2 => 1, 7 => 3};
  cmp_deeply($test->{info}->bp_index(),
    $expected,
    q(Bridge to interface index mapping using 'dot1dBasePortIfIndex'));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->bp_index(), undef,
    q(No mapping returns empty hash));
}

sub i_duplex : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex');

  my $expected = {6 => 'full', 7 => 'full', 8 => 'half'};
  cmp_deeply($test->{info}->i_duplex(),
    $expected, q(Duplex values using 'hwEthernetDuplex'));

  delete $test->{info}{'_hw_eth_duplex'};
  $expected = {9 => 'full', 10 => 'half'};
  cmp_deeply($test->{info}->i_duplex(),
    $expected, q(Duplex values using 'EtherLike-MIB'));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_duplex(), {}, q(No mapping returns empty hash));
}

sub i_duplex_admin : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex_admin');

  my $expected = {6 => 'auto', 7 => 'full', 8 => 'half'};
  cmp_deeply($test->{info}->i_duplex_admin(),
    $expected, q(Duplex admin values using 'hwEthernetDuplex'));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_duplex_admin(),
    {}, q(No mapping returns empty hash));
}

sub agg_ports : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'agg_ports');

  my $expected = {55 => 121, 110 => 121};

  cmp_deeply($test->{info}->agg_ports(),
    $expected,
    q(Aggregated links have expected values using 'HUAWEI-IF-EXT-MIB'));

  delete $test->{info}{_hw_trunk_if_idx};
  $expected = {30 => 34, 31 => 34};

  cmp_deeply($test->{info}->agg_ports(),
    $expected,
    q(Aggregated links have expected values using 'IEEE8023-LAG-MIB'));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->agg_ports(), {}, q(No data returns empty hash));
}

sub peth_port_ifindex : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'peth_port_ifindex');

  my $expected = {'0.6' => 6, '0.7' => 7, '0.8' => 8},;

  cmp_deeply($test->{info}->peth_port_ifindex(),
    $expected, q(POE port 'ifIndex' mapping returns expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->peth_port_ifindex(),
    {}, q(No data returns empty hash));
}

sub peth_port_admin : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'peth_port_admin');

  my $expected = {'0.6' => 'true', '0.7' => 'false', '0.8' => 'true'};

  cmp_deeply($test->{info}->peth_port_admin(),
    $expected, q(POE port admin status returns expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->peth_port_admin(),
    {}, q(No data returns empty hash));
}

sub peth_port_status : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'peth_port_status');

  my $expected
    = {'0.6' => 'deliveringPower', '0.7' => 'disabled', '0.8' => 'searching'};

  cmp_deeply($test->{info}->peth_port_status(),
    $expected, q(POE port status returns expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->peth_port_status(),
    {}, q(No data returns empty hash));
}

sub peth_port_class : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'peth_port_class');

  my $expected = {'0.6' => 'class3', '0.7' => 'class0', '0.8' => 'class0'};

  cmp_deeply($test->{info}->peth_port_class(),
    $expected, q(POE port class returns expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->peth_port_class(),
    {}, q(No data returns empty hash));
}

sub peth_port_power : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'peth_port_power');

  my $expected = {'0.6' => 3763, '0.7' => 0, '0.8' => 0};

  cmp_deeply($test->{info}->peth_port_power(),
    $expected, q(POE port power returns expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->peth_port_power(),
    {}, q(No data returns empty hash));
}

sub peth_port_neg_power : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'peth_port_neg_power');

  my $expected = {'0.6' => 12950};

  cmp_deeply($test->{info}->peth_port_neg_power(),
    $expected, q(POE port negotiated power returns expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->peth_port_neg_power(),
    {}, q(No data returns empty hash));
}

sub munge_hw_peth_admin : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'munge_hw_peth_admin');

  my $expected = 'true';
  is(SNMP::Info::Layer3::Huawei::munge_hw_peth_admin('enabled'),
    $expected, q(... enabled munges to true));

  $expected = 'false';
  is(SNMP::Info::Layer3::Huawei::munge_hw_peth_admin('disabled'),
    $expected, q(... disabled munges to false));

  is(SNMP::Info::Layer3::Huawei::munge_hw_peth_admin('huh'),
    'huh', q(... anything else not munged));
}

sub munge_hw_peth_power : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'munge_hw_peth_power');

  my $expected = '370';
  is(SNMP::Info::Layer3::Huawei::munge_hw_peth_power('369600'),
    $expected, q(... mW converted/rounded to W));
}

sub munge_hw_peth_class : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'munge_hw_peth_class');

  my $expected = 'class3';
  is(SNMP::Info::Layer3::Huawei::munge_hw_peth_class(3),
    $expected, q(... 'class' text added to numeric class));
}

sub munge_hw_peth_status : Tests(6) {
  my $test = shift;

  can_ok($test->{info}, 'munge_hw_peth_status');

  my $expected = 'disabled';
  is(SNMP::Info::Layer3::Huawei::munge_hw_peth_status('Disabled'),
    $expected, q(... Disabled munges to disabled));

  $expected = 'searching';
  is(SNMP::Info::Layer3::Huawei::munge_hw_peth_status('Detecting'),
    $expected, q(... Detecting munges to searching));

  $expected = 'deliveringPower';
  is(SNMP::Info::Layer3::Huawei::munge_hw_peth_status('Powered'),
    $expected, q(... Powered munges to deliveringPower));

  $expected = 'fault';
  is(SNMP::Info::Layer3::Huawei::munge_hw_peth_status('Other-fault'),
    $expected, q(... Other-fault munges to fault));

  is(SNMP::Info::Layer3::Huawei::munge_hw_peth_status('huh'),
    'huh', q(... anything else not munged));
}

1;
