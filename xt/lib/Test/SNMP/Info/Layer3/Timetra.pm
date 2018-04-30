# Test::SNMP::Info::Layer3::Timetra
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

package Test::SNMP::Info::Layer3::Timetra;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Timetra;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_layers'      => 79,
    '_description' => 'TiMOS-C-14.0.R5 cpm/hops64 Nokia 7750 SR Copyright',

    # TIMETRA-GLOBAL-MIB::tmnxModelSRa4Reg
    '_id' => '.1.3.6.1.4.1.6527.1.3.9',

    '_lldp_sys_cap'          => pack("H*", '2800'),
    '_i_description'         => 1,
    '_i_name'                => 1,
    '_lldp_rem_cap_spt'      => 1,
    '_lldp_rem_sys_cap'      => 1,
    '_lldp_rem_id_type'      => 1,
    '_lldp_rem_id'           => 1,
    '_lldp_rem_pid_type'     => 1,
    '_lldp_rem_pid'          => 1,
    '_lldp_rem_desc'         => 1,
    '_lldp_rem_sysname'      => 1,
    '_lldp_rman_addr'        => 1,
    '_tmnx_eth_duplex'       => 1,
    '_tmnx_eth_duplex_admin' => 1,
    '_tmnx_eth_auto'         => 1,
    '_el_index'              => 1,
    '_el_duplex'             => 1,
    '_ifStackStatus'         => 1,
    '_ifType'                => 1,
    '_tmnx_fan_state'        => 1,
    '_tmnx_ps1_state'        => 1,
    '_tmnx_ps2_state'        => 1,
    '_tmnxHwID'              => 1,
    'store'                  => {
      'i_description' => {
        '1'        => 'system, Loopback IP interface',
        '40108032' => '1/3/8, 10/100/Gig Ethernet SFP',
      },
      'i_name' => {'1' => 'system', '40108032' => '1/3/8',},
      'lldp_rem_cap_spt' => {'230425271.40108032.1.2' => pack("H*", '2800')},
      'lldp_rem_sys_cap' => {'230425271.40108032.1.2' => pack("H*", '2800')},
      'lldp_rem_id_type' => {'230425271.40108032.1.2' => 'macAddress'},
      'lldp_rem_id' => {'230425271.40108032.1.2' => pack("H*", '34AA99C89AA1')},
      'lldp_rem_pid_type' => {'230425271.40108032.1.2' => 'local'},
      'lldp_rem_pid'      => {'230425271.40108032.1.2' => '44072960'},
      'lldp_rem_desc'     => {'230425271.40108032.1.2' => 'Another-7705-Port'},
      'lldp_rem_sysname'  => {'230425271.40108032.1.2' => 'Another-7705'},
      'lldp_rman_addr' => {'230425271.40108032.1.2.1.4.1.2.3.4' => 'unknown'},

      'tmnx_eth_duplex' => {
        '1.35979264' => 'fullDuplex',
        '1.39878656' => 'fullDuplex',
        '1.39911424' => 'notApplicable',
        '1.39944192' => 'halfDuplex'
      },
      'tmnx_eth_duplex_admin' => {
        '1.35979264' => 'notApplicable',
        '1.39878656' => 'fullDuplex',
        '1.39911424' => 'fullDuplex',
        '1.39944192' => 'halfDuplex'
      },
      'tmnx_eth_auto' => {
        '1.35979264' => 'notApplicable',
        '1.39878656' => 'true',
        '1.39911424' => 'false',
        '1.39944192' => 'false'
      },
      'el_index'      => {67141632 => 67141632,     100696064 => 100696064},
      'el_duplex'     => {67141632 => 'fullDuplex', 100696064 => 'halfDuplex'},
      'ifStackStatus' => {
        '35684352.0'          => 'active',
        '3.1342177281'        => 'active',
        '1342177281.35684352' => 'active',
      },
      'ifType' => {
        '3'          => 'ipForward',
        '35684352'   => 'ethernetCsmacd',
        '1342177281' => 'ieee8023adLag',
      },
      'tmnx_fan_state' =>
        {'1.1' => 'deviceStateOk', '1.2' => 'deviceStateFailed'},
      'tmnx_ps1_state' =>
        {'1.1' => 'deviceStateOk', '1.2' => 'deviceNotEquipped'},
      'tmnx_ps2_state' =>
        {'1.3' => 'deviceStateOutOfService', '1.4' => 'deviceStateUnknown'},
      'tmnxHwID' => {
        '1.50331649' => '.1.3.6.1.4.1.6527.3.1.2.2.1.21.1.4.1.3.1',
        '1.83886081' => '.1.3.6.1.4.1.6527.3.1.2.2.1.5.1.2.1.1'
      },
    }
  };
  $test->{info}->cache($cache_data);
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'nokia', q(Vendor returns 'nokia'));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'TiMOS', q(Vendor returns 'TiMOS'));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), 'C-14.0.R5', q(OS version is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No description returns undef os_ver));
}

sub model : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), '7750 SRa4', q(Model uses description and id));

  delete $test->{info}{_description};
  is($test->{info}->model(), 'SRa4', q(Model translates to 'SRa4'));

  $test->{info}{_id} = '.1.3.6.1.4.1.6527.1.3.1';
  is($test->{info}->model(), 'SR1', q(Model translates to 'SR1'));

  $test->{info}{_id} = '.100.3.6.1.4.1.6527.1.3.1';
  is($test->{info}->model(), '.100.3.6.1.4.1.6527.1.3.1', q(Model uses id));
}

sub interfaces : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'interfaces');

  my $expected = {'1' => 'system', '40108032' => '1/3/8',};

  cmp_deeply($test->{info}->interfaces(),
    $expected, q(Interface names have expected values));
}

sub lldp_if : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_if');

  my $expected = {'230425271.40108032.1.2' => '40108032',};

  cmp_deeply($test->{info}->lldp_if(),
    $expected, q(Mapping of LLDP interfaces have expected values));
}

# This test will cover that the overwritten private _lldp_addr_index function
# is working properly
sub lldp_addr : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_addr');

  my $expected = {'230425271.40108032.1.2' => '1.2.3.4'};

  cmp_deeply($test->{info}->lldp_addr(),
    $expected, q(Remote LLDP IP has expected value));

  # Exchange the IPv4 address with the same IPv6 address
  $test->{info}{store}{lldp_rman_addr}
    = {'230425271.40108032.1.2.2.16.0.0.0.0.0.0.0.0.0.0.255.255.1.2.3.4' =>
      'unknown'
    };
  $expected
    = {'230425271.40108032.1.2' => '0000:0000:0000:0000:0000:ffff:0102:0304'};

  cmp_deeply($test->{info}->lldp_ipv6(),
    $expected, q(Remote LLDP IPv6 has expected value));
}

# Example from LLDP documentation
# Used as verification that we can map essential L2 topo information
sub topo_example_test : Tests(1) {
  my $test = shift;

  # Print out a map of device ports with LLDP neighbors:
  my $interfaces = $test->{info}->interfaces();
  my $lldp_if    = $test->{info}->lldp_if();
  my $lldp_ip    = $test->{info}->lldp_ip();
  my $lldp_port  = $test->{info}->lldp_port();

  # We only have one entry/key otherwise this should be in a subtest
  foreach my $lldp_key (keys %$lldp_ip) {
    my $iid           = $lldp_if->{$lldp_key};
    my $port          = $interfaces->{$iid};
    my $neighbor      = $lldp_ip->{$lldp_key};
    my $neighbor_port = $lldp_port->{$lldp_key};

    my $string = qq(Port : $port connected to $neighbor / $neighbor_port);
    my $expected_string
      = qq(Port : 1/3/8 connected to 1.2.3.4 / Another-7705-Port);

    is($string, $expected_string,
      q(LLDP example maps device ports with LLDP neighbors));
  }
}

sub i_duplex : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex');

  my $expected
    = {'35979264' => 'full', '39878656' => 'full', '39944192' => 'half'};
  cmp_deeply($test->{info}->i_duplex(),
    $expected, q(Duplex values using 'tmnxPortEtherOperDuplex'));

  delete $test->{info}{'_tmnx_eth_duplex'};
  $expected = {'67141632' => 'full', '100696064' => 'half',};
  cmp_deeply($test->{info}->i_duplex(),
    $expected, q(Duplex values using 'EtherLike-MIB'));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_duplex(), {}, q(No mapping returns empty hash));
}

sub i_duplex_admin : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex_admin');

  my $expected
    = {'39878656' => 'auto', '39911424' => 'full', '39944192' => 'half'};
  cmp_deeply($test->{info}->i_duplex_admin(),
    $expected, q(Duplex admin values using 'tmnxPortEtherDuplex'));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_duplex_admin(),
    {}, q(No mapping returns empty hash));
}

sub agg_ports : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'agg_ports');

  my $expected = {35684352 => 1342177281};

  cmp_deeply($test->{info}->agg_ports(),
    $expected,
    q(Aggregated links have expected values using 'IEEE8023-LAG-MIB'));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->agg_ports(), {}, q(No data returns empty hash));
}


sub fan : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'fan');

  my $expected = 'Fan 2, Chassis 1: Failed';

  is($test->{info}->fan(), $expected, q(Fan returns expected value));

  # Change failed fan state to normal to test alternate message
  $test->{info}{store}{tmnx_fan_state}{'1.2'} = 'deviceStateOk';
  $expected = '2 fans OK';

  is($test->{info}->fan(), $expected, q(Fans OK returns expected value));

  $test->{info}->clear_cache();
  is($test->{info}->fan(), undef, q(No data returns undef));
}

sub ps1_status : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'ps1_status');

  my $expected = 'Chassis 1 PS 1: Ok, Chassis 1 PS 2: NotEquipped';

  is($test->{info}->ps1_status(), $expected, q(PS1 returns expected value));

  $test->{info}->clear_cache();
  is($test->{info}->ps1_status(), undef, q(No data returns undef));
}

sub ps2_status : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'ps2_status');

  my $expected = 'Chassis 1 PS 3: OutOfService, Chassis 1 PS 4: Unknown';

  is($test->{info}->ps2_status(), $expected, q(PS2 returns expected value));

  $test->{info}->clear_cache();
  is($test->{info}->ps2_status(), undef, q(No data returns undef));
}

sub e_index : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'e_index');

  my $expected = {
        '1.50331649' => '1.50331649',
        '1.83886081' => '1.83886081'
      };

  cmp_deeply($test->{info}->e_index(), $expected, q(Entity index returns expected value));

  $test->{info}->clear_cache();
  is($test->{info}->e_index(), undef, q(No data returns undef));
}

sub munge_tmnx_state : Tests(8) {
  my $test = shift;

  can_ok($test->{info}, 'munge_tmnx_state');

  my $expected = 'Unknown';
  is(SNMP::Info::Layer3::Timetra::munge_tmnx_state('deviceStateUnknown'),
    $expected, q(... deviceStateUnknown munges to Unknown));

  $expected = 'NotEquipped';
  is(SNMP::Info::Layer3::Timetra::munge_tmnx_state('deviceNotEquipped'),
    $expected, q(... deviceNotEquipped munges to NotEquipped));

  $expected = 'Ok';
  is(SNMP::Info::Layer3::Timetra::munge_tmnx_state('deviceStateOk'),
    $expected, q(... deviceStateOk munges to Ok));

  $expected = 'Failed';
  is(SNMP::Info::Layer3::Timetra::munge_tmnx_state('deviceStateFailed'),
    $expected, q(... deviceStateFailed munges to Failed));

  $expected = 'OutOfService';
  is(SNMP::Info::Layer3::Timetra::munge_tmnx_state('deviceStateOutOfService'),
    $expected, q(... deviceStateOutOfService munges to OutOfService));

  $expected = 'NotProvisioned';
  is(SNMP::Info::Layer3::Timetra::munge_tmnx_state('deviceNotProvisioned'),
    $expected, q(... deviceNotProvisioned munges to NotProvisioned));

  is(SNMP::Info::Layer3::Timetra::munge_tmnx_state('huh'),
    'huh', q(... anything else not munged));
}

sub munge_tmnx_e_class : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'munge_tmnx_e_class');

  my $expected = 'chassis';
  is(SNMP::Info::Layer3::Timetra::munge_tmnx_e_class('physChassis'),
    $expected, q(... physChassis munges to chassis));

  $expected = 'module';
  is(SNMP::Info::Layer3::Timetra::munge_tmnx_e_class('ioModule'),
    $expected, q(... ioModule munges to module));

  $expected = 'powerSupply';
  is(SNMP::Info::Layer3::Timetra::munge_tmnx_e_class('powerSupply'),
    $expected, q(... powerSupply doesn't munge));

  is(SNMP::Info::Layer3::Timetra::munge_tmnx_state('huh'),
    'huh', q(... anything else not munged));
}

sub munge_tmnx_e_swver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'munge_tmnx_e_swver');

  my $swver = 'TiMOS-I-14.0.R6 iom/hops Nokia 7750 SR Copyright (c) ';
  $swver .= '2000-2016 Nokia. All rights reserved. All use subject to ';
  $swver .= 'applicable license agreements. Built on Mon Nov 21 15:19:29 ';
  $swver .= 'PST 2016 by builder in /rel14.0/b1/R6/panos/main';

  my $expected = 'I-14.0.R6';
  is(SNMP::Info::Layer3::Timetra::munge_tmnx_e_swver($swver),
    $expected, q(... matching version string extracted));

  is(SNMP::Info::Layer3::Timetra::munge_tmnx_e_swver('huh'),
    'huh', q(... anything else not munged));
}

1;
