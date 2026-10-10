# Test::SNMP::Info::Layer2::TPLink
#
# Copyright (c) 2026 The Netdisco Development Team
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

package Test::SNMP::Info::Layer2::TPLink;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer2::TPLink;

sub sg2218p_port_names {
  my %names = (1 => 'Vlan-interface1');
  $names{49152 + $_} = "gigabitEthernet 1/0/$_" for 1 .. 18;
  return \%names;
}

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  my $port_names = sg2218p_port_names();

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_layers'      => 2,
    '_description' => 'Omada 18-Port Gigabit Smart Switch with 16-Port PoE+',

    # TPLINK-MIB::jetstream_sg2218p
    '_id'                => '.1.3.6.1.4.1.11863.5.190',
    '_b_mac'             => pack('H*', '30DE4BF5F7E2'),
    '_tp_sysinfo_hwver'  => 'SG2218P 1.20',
    '_tp_sysinfo_swver'  => '1.20.6 Build 20250410 Rel.53214',
    '_tp_sysinfo_serial' => '222C014000151',

    '_i_index'       => 1,
    '_i_description' => 1,
    '_i_name'        => 1,
    '_i_alias'       => 1,
    '_el_duplex'     => 1,
    store            => {
      i_index       => {map { $_ => $_ } keys %$port_names},
      i_description => {%$port_names},
      i_name        => {%$port_names},
      i_alias       => {
        (map { $_ => '' } keys %$port_names),
        49153 => 'ac31: Kam (p1)',
        49154 => 'ac31: Kam (p2)',
      },
      el_duplex => {
        49153 => 'fullDuplex',
        49154 => 'halfDuplex',
        49155 => 'unknown',
      },
    },
  };
  $test->{info}->cache($cache_data);
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'TP-Link', q(Vendor returns 'TP-Link'));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'tplink', q(OS returns 'tplink'));
}

sub hasLLDP : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'hasLLDP');
  ok($test->{info}->hasLLDP(), q(Device reports LLDP support));
}

sub hasCDP : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'hasCDP');
  ok(!$test->{info}->hasCDP(), q(Device reports no CDP support));
}

sub hasFDP : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'hasFDP');
  ok(!$test->{info}->hasFDP(), q(Device reports no FDP support));
}

sub hasSONMP : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'hasSONMP');
  ok(!$test->{info}->hasSONMP(), q(Device reports no SONMP support));
}

sub hasEDP : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'hasEDP');
  ok(!$test->{info}->hasEDP(), q(Device reports no EDP support));
}

sub hasAMAP : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'hasAMAP');
  ok(!$test->{info}->hasAMAP(), q(Device reports no AMAP support));
}

sub model : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'model');

  no warnings 'redefine';
  local *SNMP::Info::Layer2::TPLink::e_model
    = sub { die 'ENTITY-MIB polled' };

  is(
    $test->{info}->model(),
    'Omada 18-Port Gigabit Smart Switch with 16-Port PoE+',
    q(Model falls back to sysDescr when TP-Link description is absent)
  );

  $test->{info}{_tp_sysinfo_descr} = 'JetStream 24-Port Gigabit Smart Switch';
  $test->{info}{_tp_sysinfo_hwver} = 'T1600G-28TS 3.0';
  is(
    $test->{info}->model(),
    'JetStream 24-Port Gigabit Smart Switch T1600G-28TS 3.0',
    q(Model appends hardware version to TP-Link description)
  );

  $test->{info}{_tp_sysinfo_descr}
    = 'JetStream T1600G-28TS 3.0 Gigabit Switch';
  is(
    $test->{info}->model(),
    'JetStream T1600G-28TS 3.0 Gigabit Switch',
    q(Model is unchanged when description already holds hardware version)
  );

  $test->{info}->clear_cache();
  is($test->{info}->model(), undef, q(No data returns undef));
}

sub os_ver : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');

  no warnings 'redefine';
  local *SNMP::Info::Entity::entity_derived_os_ver
    = sub { die 'ENTITY-MIB polled' };

  is(
    $test->{info}->os_ver(),
    '1.20.6 Build 20250410 Rel.53214',
    q(OS version returned from TP-Link software version)
  );

  delete $test->{info}{_tp_sysinfo_swver};
  $test->{info}{_description} = 'JetStream Switch Software version 2.0.1';
  is($test->{info}->os_ver(), '2.0.1',
    q(OS version parsed from sysDescr when software version is absent));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No data returns undef));
}

sub serial : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'serial');

  no warnings 'redefine';
  local *SNMP::Info::Entity::entity_derived_serial
    = sub { die 'ENTITY-MIB polled' };

  is($test->{info}->serial(), '222C014000151',
    q(Serial returned from TP-Link system information));

  $test->{info}->clear_cache();
  is($test->{info}->serial(), undef, q(No data returns undef));
}

sub mac : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'mac');

  is($test->{info}->mac(), '30:de:4b:f5:f7:e2',
    q(Base MAC has expected value));

  delete $test->{info}{_b_mac};
  $test->{info}{_tp_sysinfo_mac} = '74-DA-88-68-2A-D2';
  is($test->{info}->mac(), '74:DA:88:68:2A:D2',
    q(MAC falls back to TP-Link system information));

  $test->{info}->clear_cache();
  is($test->{info}->mac(), undef, q(No data returns undef));
}

sub ps1_status : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'ps1_status');

  $test->{info}{_ps1_status} = 'normal';
  is($test->{info}->ps1_status(), 'normal',
    q(PS1 status text is passed through));

  $test->{info}->clear_cache();
  is($test->{info}->ps1_status(), undef, q(No data returns undef));
}

sub ps2_status : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'ps2_status');

  $test->{info}{_ps2_status} = 'normal';
  is($test->{info}->ps2_status(), 'normal',
    q(PS2 status text is passed through));

  $test->{info}->clear_cache();
  is($test->{info}->ps2_status(), undef, q(No data returns undef));
}

sub munge_power : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'munge_power');

  is(SNMP::Info::Layer2::TPLink::munge_power(1500),
    150, q(... tenths of a watt converted to watts));
  is(SNMP::Info::Layer2::TPLink::munge_power(0), 0, q(... zero stays zero));
  is(SNMP::Info::Layer2::TPLink::munge_power(undef),
    0, q(... undef munges to zero));
}

sub i_name : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'i_name');

  my $names = $test->{info}->i_name();
  is($names->{49153}, 'ac31: Kam (p1)',
    q(Port name is the ifAlias when one is set));
  is($names->{49155}, 'gigabitEthernet 1/0/3',
    q(Port name is the ifName when the ifAlias is blank));

  delete $test->{info}{_i_alias};
  $test->{info}{_tp_port_config_descr} = 1;
  $test->{info}{store}{tp_port_config_descr} = {49153 => 'uplink'};
  $names = $test->{info}->i_name();
  is_deeply(
    [@{$names}{49153, 49155}],
    ['uplink', 'gigabitEthernet 1/0/3'],
    q(Port name falls back to the port config description, then the ifName)
  );

  delete $test->{info}{_tp_port_config_descr};
  $names = $test->{info}->i_name();
  is_deeply($names, sg2218p_port_names(),
    q(Port name is the ifName when no alias source exists));
}

sub i_duplex : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex');

  is_deeply(
    $test->{info}->i_duplex(),
    {49153 => 'full', 49154 => 'half'},
    q(Duplex comes from EtherLike keyed by ifIndex, unknown omitted)
  );

  delete $test->{info}{_el_duplex};
  $test->{info}{_tp_lldp_oper_mau} = 1;
  $test->{info}{store}{tp_lldp_oper_mau} = {
    49153 => 'speed(1000M)/duplex(Full)',
    49154 => 'other',
  };
  is_deeply(
    $test->{info}->i_duplex(),
    {49153 => 'full', 49154 => 'unknown'},
    q(Duplex falls back to the LLDP MAU string when EtherLike is absent)
  );

  $test->{info}->clear_cache();
  is_deeply($test->{info}->i_duplex(), {}, q(No data returns an empty hash));
}

1;
