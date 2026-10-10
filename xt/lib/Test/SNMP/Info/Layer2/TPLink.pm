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
  $names{32768 + $_} = "port-channel $_" for 1 .. 2;
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
    '_tp_vlan_port_pvid' => 1,
    '_tp_vlan_tagged'    => 1,
    '_tp_vlan_untagged'  => 1,
    store            => {
      tp_vlan_port_pvid => {
        (map { 49152 + $_ => 31 } 1 .. 12),
        (map { 49152 + $_ => 'trunk' } 13 .. 18),
      },
      tp_vlan_tagged => {
        1   => '',
        2   => '1/0/15-18',
        31  => '1/0/15-18',
        98  => '1/0/15-18',
        100 => '1/0/15-18,LAG1',
        255 => '1/0/15-18',
      },
      tp_vlan_untagged => {
        1   => '1/0/13-18',
        2   => '',
        31  => '1/0/1-12',
        98  => '',
        100 => 'LAG1-2,Tunnel1',
        255 => '',
      },
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

sub prime_poe {
  my $test = shift;
  my $info = $test->{info};

  my %names = %{sg2218p_port_names()};
  delete $names{49152 + 17};
  delete $names{49152 + 18};
  $info->{store}{i_description} = \%names;

  $info->{"_$_"} = 1 for qw(
    tp_peth_port_admin tp_peth_port_status tp_peth_port_class
    tp_peth_port_power tp_power_limit
  );
  $info->{_tp_power_limit} = 1500;
  $info->{store}{tp_peth_port_admin}
    = {1 => 'enable', 11 => 'enable', 15 => 'enable', 17 => 'enable'};
  $info->{store}{tp_peth_port_status}
    = {1 => 'on', 11 => 'off', 15 => 'on', 17 => 'on'};
  $info->{store}{tp_peth_port_class} = {
    1  => 'class3',
    11 => 'class-not-defined',
    15 => 'class4',
    17 => 'class0'
  };
  $info->{store}{tp_peth_port_power}
    = {1 => 20, 11 => 0, 15 => 66, 17 => 5};
}

sub _tp_port_map : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  $info->{store}{i_description} = {
    1     => 'Vlan-interface1',
    49153 => 'gigabitEthernet 1/0/1 : copper',
    49154 => 'gigabitEthernet 2/0/5',
    50001 => 'port-channel 3',
    50002 => 'Tunnel1',
  };
  is_deeply(
    $info->_tp_port_map(),
    {'1/0/1' => 49153, '2/0/5' => 49154, 'LAG3' => 50001},
    q(Port map keys u/s/p and LAGn, ignoring the media suffix and others)
  );

  $info->{store}{i_description} = {};
  is_deeply($info->_tp_port_map(), {}, q(No interface descriptions map empty));

  $info->{store}{i_description} = {49153 => 'gigabitEthernet 1/0/1'};
  is_deeply($info->_tp_peth_by_port({1 => 'x', 2 => 'y'}),
    {'1.1' => 'x'}, q(Column rows without an interface are dropped));

  $info->clear_cache();
  is_deeply($info->_tp_peth_by_port({1 => 'x'}),
    {}, q(No interface data rekeys to an empty hash));
}

sub peth_port_ifindex : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'peth_port_ifindex');
  $test->prime_poe;

  no warnings 'redefine';
  local *SNMP::Info::PowerEthernet::peth_port_ifindex
    = sub { die 'RFC 3621 polled' };

  my $expected = {'1.1' => 49153, '1.11' => 49163, '1.15' => 49167};
  is_deeply($info->peth_port_ifindex(), $expected,
    q(PoE ports map to ifIndex via the port map, port 17 omitted));

  $info->{store}{i_description}{49153} = 'gigabitEthernet 1/0/1 : copper';
  is_deeply($info->peth_port_ifindex(), $expected,
    q(A media suffix on the ifDescr still resolves the port));

  $info->clear_cache();
  is_deeply($info->peth_port_ifindex(), {}, q(No data returns empty hash));
}

sub peth_port_admin : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'peth_port_admin');
  $test->prime_poe;

  no warnings 'redefine';
  local *SNMP::Info::PowerEthernet::peth_port_admin
    = sub { die 'RFC 3621 polled' };

  is_deeply($info->peth_port_admin(),
    {'1.1' => 'true', '1.11' => 'true', '1.15' => 'true'},
    q(Admin state is keyed unit.port, port 17 without interface omitted));

  $info->{store}{tp_peth_port_admin}{11} = 'disable';
  is($info->peth_port_admin()->{'1.11'}, 'false', q(Disabled port is false));

  $info->clear_cache();
  is_deeply($info->peth_port_admin(), {}, q(No data returns empty hash));
}

sub peth_port_status : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'peth_port_status');
  $test->prime_poe;

  my $status = $info->peth_port_status();
  is($status->{'1.1'}, 'deliveringPower', q(Powered port is deliveringPower));
  is($status->{'1.11'}, 'searching', q(Unpowered port is searching));

  $info->clear_cache();
  is_deeply($info->peth_port_status(), {}, q(No data returns empty hash));
}

sub peth_port_class : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'peth_port_class');
  $test->prime_poe;

  my $class = $info->peth_port_class();
  is($class->{'1.1'}, 'class3', q(Class is passed through));
  is($class->{'1.11'}, 'class-not-defined', q(Undefined class is passed));

  $info->clear_cache();
  is_deeply($info->peth_port_class(), {}, q(No data returns empty hash));
}

sub peth_port_power : Tests(5) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'peth_port_power');
  $test->prime_poe;

  is_deeply($info->peth_port_power(),
    {'1.1' => 2000, '1.11' => 0, '1.15' => 6600},
    q(Power is scaled by 100, port 17 without interface omitted));
  ok(!exists $info->peth_port_power()->{'1.17'}, q(No key for port 17));

  $info->clear_cache();
  is_deeply($info->peth_port_power(), {}, q(No data returns empty hash));
  $info->{_tp_peth_port_power} = 1;
  is_deeply($info->peth_port_power(), {}, q(No rows returns empty hash));
}

sub peth_power_watts : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'peth_power_watts');
  $test->prime_poe;

  is_deeply($info->peth_power_watts(), {1 => 150},
    q(Power budget is the system limit in watts));

  delete $info->{_tp_power_limit};
  is_deeply($info->peth_power_watts(), {}, q(No limit returns empty hash));
}

sub peth_power_status : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'peth_power_status');
  $test->prime_poe;

  is_deeply($info->peth_power_status(), {1 => 'on'},
    q(Module power is on when a limit is reported));

  delete $info->{_tp_power_limit};
  is_deeply($info->peth_power_status(), {}, q(No limit returns empty hash));
}

sub munge_tp_pvid : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'munge_tp_pvid');
  is(SNMP::Info::Layer2::TPLink::munge_tp_pvid('trunk'),
    1, q(Label trunk maps to VLAN 1));
  is(SNMP::Info::Layer2::TPLink::munge_tp_pvid('general'),
    2, q(Label general maps to 2));
  is(SNMP::Info::Layer2::TPLink::munge_tp_pvid('access'),
    0, q(Label access maps to 0));
  is(SNMP::Info::Layer2::TPLink::munge_tp_pvid(31), 31, q(Numeric stays));
}

sub _tp_vlan_ports : Tests(5) {
  my $test = shift;
  my $info = $test->{info};

  is_deeply(
    $info->_tp_vlan_ports({100 => '1/0/15-16,LAG1-2,1/0/1,Tunnel1,'}),
    {49167 => [100], 49168 => [100], 32769 => [100], 32770 => [100],
      49153 => [100]},
    q(Ranges, LAG ranges and single ports resolve; unknown tokens skipped)
  );
  is_deeply($info->_tp_vlan_ports({1 => ''}), {}, q(Empty list is skipped));
  is_deeply(
    $info->_tp_vlan_ports({100 => '1/0/1,1/0/1', 5 => '1/0/1'}),
    {49153 => [5, 100]},
    q(A VLAN is not repeated and lists are sorted)
  );
  is_deeply($info->_tp_vlan_ports({100 => ' 1/0/1 , LAG1 '}),
    {49153 => [100], 32769 => [100]}, q(Whitespace around tokens is trimmed));
  is_deeply($info->_tp_vlan_ports({100 => '1/0/40-41,LAG9'}),
    {}, q(Ports without an interface are omitted));
}

sub i_vlan : Tests(7) {
  my $test = shift;
  my $info = $test->{info};

  local *SNMP::Info::Bridge::i_vlan = sub { die 'Q-BRIDGE polled' };

  my $vlans = $info->i_vlan();
  is($vlans->{49153}, 31, q(PVID column gives the VLAN));
  is($vlans->{49165}, 1,  q(Label trunk reads back as VLAN 1));

  delete $info->{_tp_vlan_port_pvid};
  delete $info->{store}{tp_vlan_port_pvid};
  $info->{store}{tp_vlan_untagged}{2} = '1/0/2';
  $vlans = $info->i_vlan();
  is($vlans->{49153}, 31,  q(Derived from the single untagged VLAN));
  is($vlans->{49165}, 1,   q(Derived trunk port is VLAN 1));
  is($vlans->{32769}, 100, q(LAG derived from its untagged VLAN));
  ok(!exists $vlans->{49154}, q(Port untagged in two VLANs is absent));

  $info->clear_cache();
  is_deeply($info->i_vlan(), {}, q(No data gives an empty hash));
}

sub i_vlan_membership : Tests(5) {
  my $test = shift;
  my $info = $test->{info};

  local *SNMP::Info::Bridge::i_vlan_membership
    = sub { die 'Q-BRIDGE polled' };

  my @warnings;
  my $members;
  {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $members = $info->i_vlan_membership();
  }
  cmp_bag($members->{49167}, [1, 2, 31, 98, 100, 255],
    q(Trunk port is in every VLAN that lists it));
  is_deeply($members->{49153}, [31], q(Access port is in its VLAN));
  is_deeply($members->{32769}, [100],
    q(LAG tagged and untagged in one VLAN lists it once));
  is_deeply(\@warnings, [], q(Empty lists and Tunnel1 raise no warnings));

  is_deeply($info->i_vlan_membership(49153), {49153 => [31]},
    q(Partial limits the result to one port));
}

sub i_vlan_membership_untagged : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  local *SNMP::Info::Bridge::i_vlan_membership_untagged
    = sub { die 'Q-BRIDGE polled' };

  my $members = $info->i_vlan_membership_untagged();
  is_deeply($members->{49153}, [31],  q(Access port untagged VLAN));
  is_deeply($members->{49167}, [1],   q(Trunk port untagged in VLAN 1));
  is_deeply($members->{32770}, [100], q(LAG range member untagged));
}

sub prime_fdb {
  my ($test, $ports) = @_;
  $test->{info}{store}{qb_fw_port} = $ports;
  $test->{info}{_qb_fw_port}       = 1;
  $test->{info}{store}{bp_index}   = {};
  $test->{info}{_bp_index}         = 1;
}

sub _tp_bridge_port_ifindex : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  my $port_map = $info->_tp_port_map();
  is($info->_tp_bridge_port_ifindex(5, $port_map),
    49157, q(A single u/s/5 entry resolves the port number));
  is($info->_tp_bridge_port_ifindex(99, $port_map),
    undef, q(A number with no entry returns undef));

  my $stack = {'1/0/5' => 49153, '2/0/5' => 49200};
  is($info->_tp_bridge_port_ifindex(5, $stack),
    undef, q(A number present on two stack units is ambiguous));
  is($info->_tp_bridge_port_ifindex(50, {'1/0/5' => 49153}),
    undef, q(A number only matching as a suffix does not resolve));
}

sub fw_port : Tests(11) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'fw_port');
  $test->prime_fdb({
    '1.8.85.49.126.102.254' => 0,
    '1.8.0.39.251.118.93'   => 1,
    '1.24.3.115.157.158.198' => 18,
    '1.116.77.40.117.3.36'  => 49170,
  });

  my $fw = $info->fw_port();
  ok(!exists $fw->{'1.8.85.49.126.102.254'},
    q(Port 0 means not learned and is skipped));
  is($fw->{'1.8.0.39.251.118.93'}, 49153,
    q(Port 1 is port 1/0/1, not ifIndex 1 Vlan-interface1));
  is($fw->{'1.24.3.115.157.158.198'}, 49170, q(Port 18 maps to 1/0/18));
  is($fw->{'1.116.77.40.117.3.36'}, 49170, q(An existing ifIndex is kept));

  $info->{store}{i_description}{49200} = 'gigabitEthernet 2/0/5';
  $info->{store}{i_description}{49153} = 'gigabitEthernet 1/0/5';
  $test->prime_fdb({'1.1.2.3.4.5.6' => 5});
  is_deeply($info->fw_port(), {'1.1.2.3.4.5.6' => 5},
    q(Port 5 on a stack is ambiguous and stays unresolved));

  $info->{store}{i_description}{49153} = 'gigabitEthernet 1/0/1';
  delete $info->{store}{i_description}{49200};
  delete $info->{store}{qb_fw_port};
  delete $info->{_qb_fw_port};
  $info->{_fw_port}       = 1;
  $info->{store}{fw_port} = {
    '8.85.49.126.102.254' => 1,
    '0.39.251.118.93.1'   => 18,
  };
  is_deeply(
    $info->fw_port(),
    {'8.85.49.126.102.254' => 49153, '0.39.251.118.93.1' => 49170},
    q(BRIDGE-MIB column is resolved when Q-BRIDGE is absent)
  );

  $info->{store}{fw_port} = {
    '8.85.49.126.102.254' => '1/0/7',
    '0.39.251.118.93.1'   => 'LAG1',
    '1.2.3.4.5.6'         => 'Tunnel1',
  };
  my $text = $info->fw_port();
  is($text->{'8.85.49.126.102.254'}, 49159, q(Text port 1/0/7 maps via port map));
  is($text->{'0.39.251.118.93.1'}, 32769, q(Text port LAG1 maps via port map));
  is($text->{'1.2.3.4.5.6'}, 'Tunnel1', q(Unknown text port stays as reported));

  delete $info->{_fw_port};
  delete $info->{store}{fw_port};
  $info->clear_cache();
  is_deeply($info->fw_port(), {}, q(No data returns empty hash));
}

sub qb_fw_port : Tests(6) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'qb_fw_port');
  my $column = {'1.8.0.39.251.118.93' => 1, '1.24.3.115.157.158.198' => 18};
  $test->prime_fdb({%$column});
  is_deeply($info->qb_fw_port(), $column,
    q(A present Q-BRIDGE column is returned unchanged));

  delete $info->{store}{qb_fw_port};
  delete $info->{_qb_fw_port};
  $info->{_tpl2BridgeManageDynPort} = 1;
  $info->{store}{tpl2BridgeManageDynPort} = {
    '0.10.235.1.2.3.10' => '1/0/7',
    '0.10.235.1.2.3.20' => '7',
  };
  is_deeply(
    $info->qb_fw_port(),
    {'10.0.10.235.1.2.3' => 49159, '20.0.10.235.1.2.3' => 49159},
    q(Without Q-BRIDGE the vendor table resolves u/s/p and port numbers)
  );

  $info->{store}{tpl2BridgeManageDynPort}
    = {'0.10.235.1.2.3.30' => 'LAG9', '0.10.235.1.2.3.40' => '0'};
  is_deeply($info->qb_fw_port(), {'30.0.10.235.1.2.3' => 'LAG9'},
    q(Unresolved vendor port keeps its raw value and port 0 is dropped));

  $info->clear_cache();
  is_deeply($info->qb_fw_port(), {}, q(Both tables absent returns empty hash));
}

sub prime_tp_lldp {
  my $test = shift;
  my $info = $test->{info};

  $info->{"_$_"} = 1 for qw(
    lldp_rem_id tp_lldp_rem_id tp_lldp_rem_pid tp_lldp_rem_desc
    tp_lldp_rem_sysname tp_lldp_rem_sysdesc tp_lldp_rem_cap_spt
    tp_lldp_rman
  );
  $info->{store}{lldp_rem_id}    = {};
  $info->{store}{tp_lldp_rem_id} = {
    '49167.1' => '48:A9:8A:C1:AC:58',
    '49168.1' => '48:A9:8A:C0:3C:40',
    '49170.1' => 'E8:28:C1:26:B9:C0',
  };
  $info->{store}{tp_lldp_rem_pid} = {
    '49167.1' => 'trunk: Up (eth1)',
    '49168.1' => 'trunk: Up (eth1)',
    '49170.1' => 'gi1/0/6',
  };
  $info->{store}{tp_lldp_rem_desc} = {
    '49167.1' => 'trunk: Switch (br1)/trunk: Up (eth1)',
    '49168.1' => 'trunk: Switch (br1)/trunk: Up (eth1)',
    '49170.1' => 'trunk: sw31 (p06)',
  };
  $info->{store}{tp_lldp_rem_sysname} = {
    '49167.1' => 'w131.soada',
    '49168.1' => 'w104.soada',
    '49170.1' => 'sw22.soada',
  };
  $info->{store}{tp_lldp_rem_sysdesc} = {
    '49167.1' => 'MikroTik RouterOS 7.19 (stable) cAPGi-5HaxD2HaxD',
    '49168.1' => 'MikroTik RouterOS 7.19.1 (stable) cAPGi-5HaxD2HaxD',
    '49170.1' =>
      'MES2324B 28-port 1G/10G Managed Switch, Software version: 4.0.24.1',
  };
  $info->{store}{tp_lldp_rem_cap_spt}
    = {map { $_ => 'Bridge Router ' } qw(49167.1 49168.1 49170.1)};
  $info->{store}{tp_lldp_rman} = {
    '49167.1' => '::169.254.2.131',
    '49168.1' => '::169.254.2.104',
    '49170.1' => '::',
  };
}

sub prime_std_lldp {
  my $test = shift;
  my $info = $test->{info};

  $info->{"_$_"} = 1 for qw(
    lldp_rem_id lldp_rem_id_type lldp_rem_pid lldp_rem_pid_type
    lldp_lport_desc lldp_rman_addr i_description i_alias
    lldp_rem_desc lldp_rem_sysname lldp_rem_sysdesc lldp_rem_cap_spt
  );
  $info->{store}{i_description} = sg2218p_port_names();
  $info->{store}{lldp_rem_id} = {'0.15.1' => pack('H*', '48A98AC1AC58')};
  $info->{store}{lldp_rem_id_type}  = {'0.15.1' => 'macAddress'};
  $info->{store}{lldp_rem_pid}      = {'0.15.1' => 'gi1/0/6'};
  $info->{store}{lldp_rem_pid_type} = {'0.15.1' => 'interfaceName'};
  $info->{store}{lldp_lport_desc}   = {15 => 'ac31: Kam (p15)'};
  $info->{store}{i_alias}           = {49167 => 'ac31: Kam (p15)'};
  $info->{store}{lldp_rem_desc}     = {'0.15.1' => 'sw31 port 6'};
  $info->{store}{lldp_rem_sysname}  = {'0.15.1' => 'sw22.soada'};
  $info->{store}{lldp_rem_sysdesc}
    = {'0.15.1' => 'MES2324B 28-port 1G/10G Managed Switch'};
  $info->{store}{lldp_rem_cap_spt} = {'0.15.1' => pack('H*', '2800')};
  $info->{store}{lldp_rman_addr} = {
    '0.15.1.1.4.169.254.2.131' => 'ifIndex',
    '0.15.1.2.16.254.128.0.0.0.0.0.0.0.0.0.0.0.0.0.1' => 'ifIndex',
  };

  # lldp_if reads lldpLocPortDesc as a partial, which bypasses the cache.
  $info->{sess}{Data}
    = {'LLDP-MIB::lldpLocPortDesc' => {15 => 'ac31: Kam (p15)'}};
}

sub _tp_lldp_standard : Tests(6) {
  my $test = shift;
  my $info = $test->{info};

  $test->prime_std_lldp;
  ok($info->_tp_lldp_standard(),
    q(LLDP-MIB neighbor rows select the standard));

  $info->clear_cache();
  $test->prime_tp_lldp;
  ok(!$info->_tp_lldp_standard(),
    q(No LLDP-MIB neighbor rows select the TP-Link table));

  $info->clear_cache();
  ok(!$info->_tp_lldp_standard(),
    q(No data at all selects the TP-Link table));

  {
    $info->clear_cache();
    my $calls = 0;
    no warnings 'redefine';
    local *SNMP::Info::Layer2::TPLink::lldp_rem_id
      = sub { $calls++; return {} };
    $info->_tp_lldp_standard() for 1 .. 3;
    is($calls, 1, q(An empty LLDP-MIB walk is done once, not on every call));

    $info->clear_cache();
    $info->_tp_lldp_standard();
    is($calls, 2, q(clear_cache resets the decision));
  }

  $info->clear_cache();
  $test->prime_std_lldp;
  ok($info->_tp_lldp_standard(),
    q(After clear_cache the decision follows the new data));
}

sub lldp_if : Tests(5) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'lldp_if');
  $test->prime_tp_lldp;
  is_deeply(
    $info->lldp_if(),
    {'49167.1' => 49167, '49168.1' => 49168, '49170.1' => 49170},
    q(TP-Link neighbors map to the ifIndex in their index, keyed once)
  );

  $test->{info}->clear_cache();
  $test->prime_std_lldp;
  is_deeply($info->lldp_if(), {'0.15.1' => 49167},
    q(LLDP-MIB neighbors map through lldpLocPortDesc and ifAlias));
  ok(!exists $info->{'_tp_lldp_rem_id'},
    q(The TP-Link neighbor table is not loaded when LLDP-MIB has rows));

  $info->clear_cache();
  is_deeply($info->lldp_if(), {}, q(No data returns empty hash));
}

sub lldp_ip : Tests(6) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'lldp_ip');
  $test->prime_tp_lldp;
  is_deeply(
    $info->lldp_ip(),
    {'49167.1' => '169.254.2.131', '49168.1' => '169.254.2.104'},
    q(IPv4-mapped addresses are unwrapped and '::' is omitted)
  );

  $info->{store}{tp_lldp_rman}
    = {'49167.1' => '10.0.0.1', '49170.1' => 'fe80::1'};
  is_deeply($info->lldp_ip(), {'49167.1' => '10.0.0.1'},
    q(A plain IPv4 address is kept and IPv6 is never reported));

  $info->clear_cache();
  $test->prime_std_lldp;
  is_deeply($info->lldp_ip(), {'0.15.1' => '169.254.2.131'},
    q(LLDP-MIB management addresses are used when LLDP-MIB has rows));
  ok(!exists $info->{'_tp_lldp_rem_id'},
    q(The TP-Link neighbor table is not loaded when LLDP-MIB has rows));

  $info->clear_cache();
  is_deeply($info->lldp_ip(), {}, q(No data returns empty hash));
}

sub lldp_ipv6 : Tests(6) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'lldp_ipv6');
  $test->prime_tp_lldp;
  is_deeply($info->lldp_ipv6(), {},
    q('::' and IPv4-mapped addresses are not IPv6 neighbors));

  $info->{store}{tp_lldp_rman}{'49170.1'} = 'fe80::1';
  is_deeply($info->lldp_ipv6(), {'49170.1' => 'fe80::1'},
    q(A real IPv6 address is reported as given));

  $info->clear_cache();
  $test->prime_std_lldp;
  is_deeply(
    $info->lldp_ipv6(),
    {'0.15.1' => 'fe80:0000:0000:0000:0000:0000:0000:0001'},
    q(LLDP-MIB IPv6 management addresses are used when LLDP-MIB has rows)
  );
  ok(!exists $info->{'_tp_lldp_rem_id'},
    q(The TP-Link neighbor table is not loaded when LLDP-MIB has rows));

  $info->clear_cache();
  is_deeply($info->lldp_ipv6(), {}, q(No data returns empty hash));
}

sub lldp_port : Tests(8) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'lldp_port');
  $test->prime_tp_lldp;
  my $ports = $info->lldp_port();
  is($ports->{'49170.1'}, 'gi1/0/6',
    q(Remote port id from column 6, not the local port));
  is(scalar keys %$ports, 3, q(Every neighbor has a remote port));

  $info->{store}{tp_lldp_rem_pid} = {};
  is($info->lldp_port()->{'49170.1'}, 'trunk: sw31 (p06)',
    q(Remote port description is used when the port id is absent));

  $info->{store}{tp_lldp_rem_desc} = {};
  is_deeply($info->lldp_port(), {},
    q(Neighbors with neither port field are omitted));

  $info->clear_cache();
  $test->prime_std_lldp;
  is_deeply($info->lldp_port(), {'0.15.1' => 'gi1/0/6'},
    q(LLDP-MIB remote ports are used when LLDP-MIB has rows));
  ok(!exists $info->{'_tp_lldp_rem_id'},
    q(The TP-Link neighbor table is not loaded when LLDP-MIB has rows));

  $info->clear_cache();
  is_deeply($info->lldp_port(), {}, q(No data returns empty hash));
}

sub lldp_id : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'lldp_id');
  $test->prime_tp_lldp;
  is_deeply(
    $info->lldp_id(),
    {
      '49167.1' => '48:A9:8A:C1:AC:58',
      '49168.1' => '48:A9:8A:C0:3C:40',
      '49170.1' => 'E8:28:C1:26:B9:C0',
    },
    q(TP-Link chassis ids are returned as the device reports them)
  );

  $info->clear_cache();
  $test->prime_std_lldp;
  is_deeply($info->lldp_id(), {'0.15.1' => '48:a9:8a:c1:ac:58'},
    q(LLDP-MIB chassis ids are formatted by the standard method));

  $info->clear_cache();
  is_deeply($info->lldp_id(), {}, q(No data returns empty hash));
}

sub lldp_platform : Tests(7) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'lldp_platform');
  $test->prime_tp_lldp;
  is($info->lldp_platform()->{'49170.1'},
    'MES2324B 28-port 1G/10G Managed Switch, Software version: 4.0.24.1',
    q(Platform is the remote system description));

  $info->{store}{tp_lldp_rem_sysdesc} = {};
  is($info->lldp_platform()->{'49170.1'}, 'sw22.soada',
    q(Remote system name is used when the description is absent));

  $info->{store}{tp_lldp_rem_sysname} = {};
  is_deeply($info->lldp_platform(), {},
    q(Neighbors with neither field are omitted));

  $info->clear_cache();
  $test->prime_std_lldp;
  is_deeply(
    $info->lldp_platform(),
    {'0.15.1' => 'MES2324B 28-port 1G/10G Managed Switch'},
    q(LLDP-MIB remote descriptions are used when LLDP-MIB has rows)
  );
  ok(!exists $info->{'_tp_lldp_rem_id'},
    q(The TP-Link neighbor table is not loaded when LLDP-MIB has rows));

  $info->clear_cache();
  is_deeply($info->lldp_platform(), {}, q(No data returns empty hash));
}

sub lldp_cap : Tests(7) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'lldp_cap');
  $test->prime_tp_lldp;
  cmp_deeply(
    $info->lldp_cap(),
    {map { $_ => bag('bridge', 'router') } qw(49167.1 49168.1 49170.1)},
    q(Capability text is mapped to standard names)
  );

  $info->{store}{tp_lldp_rem_cap_spt} = {
    '49167.1' => 'WLAN Access Point Gizmo Station Only',
    '49168.1' => 'DOCSIS Cable Device Telephone Repeater Other',
  };
  cmp_deeply(
    $info->lldp_cap(),
    {
      '49167.1' => bag('wlanAccessPoint', 'stationOnly'),
      '49168.1' =>
        bag('docsisCableDevice', 'telephone', 'repeater', 'other'),
    },
    q(Multi-word names are matched and unknown words dropped)
  );

  $info->{store}{tp_lldp_rem_cap_spt} = {'49167.1' => 'Gizmo'};
  is_deeply($info->lldp_cap(), {}, q(Only unknown words yields no entry));

  $info->clear_cache();
  $test->prime_std_lldp;
  cmp_deeply($info->lldp_cap(), {'0.15.1' => bag('bridge', 'router')},
    q(LLDP-MIB capability bits are decoded when LLDP-MIB has rows));
  ok(!exists $info->{'_tp_lldp_rem_id'},
    q(The TP-Link neighbor table is not loaded when LLDP-MIB has rows));

  $info->clear_cache();
  is_deeply($info->lldp_cap(), {}, q(No data returns empty hash));
}

sub topology : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  $test->prime_tp_lldp;
  my @neighbors = qw(49167.1 49168.1 49170.1);
  cmp_deeply([keys %{$info->c_id()}], bag(@neighbors),
    q(c_id has every TP-Link neighbor once));
  cmp_deeply([keys %{$info->c_if()}], bag(@neighbors),
    q(c_if has every TP-Link neighbor once));
  cmp_deeply([keys %{$info->c_port()}], bag(@neighbors),
    q(c_port has every TP-Link neighbor once));
  cmp_deeply([keys %{$info->c_ip()}], bag(qw(49167.1 49168.1)),
    q(c_ip has the neighbors with an IPv4 address));
}

1;
