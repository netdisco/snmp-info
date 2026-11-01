# Test::SNMP::Info::Layer3::Onyx
#
# Copyright (c) 2026 Hannes Eberhardt
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

package Test::SNMP::Info::Layer3::Onyx;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Onyx;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Shapes from Onyx 3.6 and 3.8 walks: sysServices 72, LLDP rows keyed
  # timemark.lldpRemLocalPortNum.index, local port numbers are bridge ports
  my $cache_data = {
    '_layers'      => 72,
    '_description' => 'Onyx,MSN2410,SWv3.10.4100',
    '_id'          => '.1.3.6.1.4.1.33049.1.1.1.2410',
    '_lldp_rem_id_type' => 1,
    '_lldp_rem_id'      => 1,
    '_bp_index'         => 1,
    '_lldp_lport_id'    => 1,
    '_i_name'           => 1,
    '_lldp_rman_addr'   => 1,
    'store' => {
      'lldp_rem_id_type' => {
        '1000.97.10'  => 'macAddress',
        '1000.193.11' => 'macAddress',
        '1000.61.12'  => 'macAddress',
        '1000.33.13'  => 'networkAddress',
        '1000.37.14'  => 'interfaceName',
      },
      'lldp_rem_id' => {
        '1000.97.10'  => '02:00:00:00:00:10',
        '1000.193.11' => pack('C*', 0x02, 0, 0, 0, 0, 0x11),
        '1000.61.12'  => '02:00:00:00:00:12',
        '1000.33.13'  => pack('C*', 1, 192, 0, 2, 13),
        '1000.37.14'  => 'swp14',
      },
      'bp_index' => {97 => 101, 61 => 116, 33 => 93, 37 => 94},
      'lldp_lport_id' => {
        97 => 'Eth1/25', 193 => 'Eth1/49', 61 => 'Eth1/16',
        33 => 'Eth1/9', 37 => 'Eth1/10', 205 => 'Eth1/52',
      },
      'i_name' => {
        101 => 'Eth1/25', 81 => 'Eth1/49', 116 => 'Eth1/16',
        93 => 'Eth1/9', 94 => 'Eth1/10',
      },
      # lldpRemManAddrIfSubtype, indexed with the address type, length
      # and octets after the remote row's index
      'lldp_rman_addr' => {
        '1000.97.10.1.4.192.0.2.10'  => 'ifIndex',
        '1000.193.11.1.4.192.0.2.11' => 'ifIndex',
        '1000.33.13.1.4.192.0.2.13'  => 'ifIndex',
        '1000.37.14.1.4.192.0.2.14'  => 'ifIndex',
      },
    },
  };
  $test->{info}->cache($cache_data);
}

sub layers : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'layers');
  is($test->{info}->layers(), '01001110',
    q(Layers 2 and 3 are added to sysServices 72));
  is($test->{info}->has_layer(3), 1,
    q(Layer 3 collection is enabled));

  $test->{info}->clear_cache();
  $test->{info}->cache({'_layers' => 6});
  is($test->{info}->layers(), '00000110',
    q(Reported layer 2 and 3 bits are preserved));

  $test->{info}->clear_cache();
  is($test->{info}->layers(), '00000110',
    q(Missing sysServices retains bridge and IP capabilities));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'mellanox', q(Vendor returns 'mellanox'));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'onyx', q(OS returns 'onyx'));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '3.10.4100', q(OS ver is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No description returns undef));
}

sub model : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'MSN2410', q(Model parsed from Onyx sysDescr));

  $test->{info}->clear_cache();
  $test->{info}->cache({
    '_description' => 'Linux Mellanox 2.6.27',
    '_id'          => '.1.3.6.1.4.1.33049.1.1.1.2700',
  });
  isnt($test->{info}->model(), undef,
    'model__no_onyx_sysdescr__falls_back_to_parent');
}

sub lldp_id : Tests(12) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_id');
  my $id = $test->{info}->lldp_id();
  is($id->{'1000.97.10'}, '02:00:00:00:00:10',
    'lldp_id__ascii_mac__decoded');
  is($id->{'1000.193.11'}, '02:00:00:00:00:11',
    'lldp_id__binary_mac__decoded');
  is($id->{'1000.33.13'}, '192.0.2.13',
    'lldp_id__network_address__decoded');
  is($id->{'1000.37.14'}, 'swp14', q(String chassis ID is preserved));

  my $info = $test->{info};
  $info->{store}{lldp_rem_id_type}{$_} = 'macAddress'
    for qw/1000.41.15 1000.45.16 1000.49.17/;
  $info->{store}{lldp_rem_id}{'1000.41.15'} = pack('H*', '0200000001');
  $info->{store}{lldp_rem_id}{'1000.45.16'} = pack('H*', '02000000000001');
  $info->{store}{lldp_rem_id}{'1000.49.17'} = '';
  $id = $info->lldp_id();
  is($id->{'1000.41.15'}, undef, q(Five-byte MAC is rejected));
  is($id->{'1000.45.16'}, undef, q(Seven-byte MAC is rejected));
  ok(!exists $id->{'1000.49.17'}, q(Empty chassis ID is omitted));

  $info->{store}{lldp_rem_id}{'1000.97.10'} = '02:AA:BB:CC:DD:10';
  is($info->lldp_id()->{'1000.97.10'}, '02:aa:bb:cc:dd:10',
    q(ASCII MAC is returned in lowercase));
  $info->cache({
    '_lldp_loc_id_type' => 'macAddress',
    '_lldp_loc_id_os' => '02:AA:BB:CC:DD:01',
  });
  is($info->lldp_loc_id(), '02:aa:bb:cc:dd:01',
    q(The local chassis ID uses the same decoder));

  $test->_prime_v2();
  cmp_deeply($info->lldp_id(), {
    '1000.17.1.1' => '02:00:00:00:00:17',
    '1000.18.1.2' => '02:00:00:00:00:18',
  }, q(V2 chassis IDs use the nearest-bridge agent));

  $test->_prime_v2();
  $info->{store}{lldp_rem_id} = {'1000.97.10' => '02:00:00:00:00:10'};
  $info->{store}{lldp_rem_id_type} = {'1000.97.10' => 'macAddress'};
  cmp_deeply($info->lldp_id(), {'1000.97.10' => '02:00:00:00:00:10'},
    q(A neighbor present in both MIBs is read from LLDP-MIB once));
}

sub lldp_if : Tests(7) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_if');
  my $if = $test->{info}->lldp_if();
  is($if->{'1000.97.10'}, 101, 'lldp_if__bridge_port__maps_via_bp_index');
  is($if->{'1000.193.11'}, 81,
    'lldp_if__no_bridge_port__maps_lldpLocPortId_to_ifName');
  is($if->{'1000.33.13'}, 93, 'lldp_if__second_bridge_port__maps');

  $test->{info}{'_i_alias'} = 1;
  $test->{info}{'_i_index'} = 1;
  $test->{info}{store}{i_alias} = {81 => 'uplink to core'};
  $test->{info}{store}{i_index} = {81 => 81};
  is($test->{info}->lldp_if()->{'1000.193.11'}, 81,
    q(Name fallback uses ifName when an operator alias is present));

  $test->{info}->clear_cache();
  $test->{info}->cache({
    '_lldp_rem_id_type' => 1, '_bp_index' => 1, '_lldp_lport_id' => 1,
    '_i_name' => 1,
    'store' => {
      'lldp_rem_id_type' => {'1000.205.15' => 'macAddress'},
      'bp_index'         => {},
      'lldp_lport_id'    => {205 => 'Eth1/52'},
      'i_name'           => {101 => 'Eth1/25'},
    },
  });
  cmp_deeply($test->{info}->lldp_if(), {},
    'lldp_if__no_bridge_port_or_name_match__omits_neighbor');

  $test->_prime_v2();
  cmp_deeply($test->{info}->lldp_if(), {
    '1000.17.1.1' => 17, '1000.18.1.2' => 18,
  }, q(V2 local port numbers are ifIndex values, not bridge ports));
}

sub c_ip : Tests(9) {
  my $test = shift;

  can_ok($test->{info}, 'c_ip');
  my $ip = $test->{info}->c_ip();
  is($ip->{'1000.97.10'}, '192.0.2.10', 'c_ip__management_address__kept');
  is($ip->{'1000.61.12'}, '0.0.0.0',
    'c_ip__no_management_address__zero_for_id_lookup');

  cmp_deeply($test->{info}->c_ip(undef, ['lldp']), $ip,
    q(Explicit LLDP selection preserves advertised and missing addresses));
  cmp_deeply($test->{info}->c_ip(undef, []), {},
    q(An empty protocol list excludes LLDP addresses and placeholders));
  cmp_deeply($test->{info}->c_if(undef, []), {},
    q(The address and interface tables honor the same protocol list));
  cmp_deeply($test->{info}->c_ip(undef, ['cdp']), {},
    q(Selecting another protocol does not add LLDP neighbors));

  $test->_prime_v2();
  cmp_deeply($test->{info}->c_ip(), {
    '1000.17.1.1' => '192.0.2.17', '1000.18.1.2' => '0.0.0.0',
  }, q(V2 addresses and placeholders use the same neighbor source));
  $test->{info}{store}{lldp_v2_rman_addr} = {};
  cmp_deeply($test->{info}->c_ip(), {
    '1000.17.1.1' => '0.0.0.0', '1000.18.1.2' => '0.0.0.0',
  }, q(V2 neighbors without management addresses retain placeholders));
}

# The common LLDP role's V2 index is timemark.ifIndex.agent.index.
sub _prime_v2 {
  my $test = shift;
  $test->{info}->clear_cache();
  $test->{info}->cache({
    '_lldp_rem_id'          => 1,
    '_lldp_rem_id_type'     => 1,
    '_lldp_v2_rem_id'       => 1,
    '_lldp_v2_rem_id_type'  => 1,
    '_lldp_v2_rem_pid'      => 1,
    '_lldp_v2_dest_mac'     => 1,
    '_lldp_v2_rman_addr'    => 1,
    '_bp_index'            => 1,
    'store' => {
      'lldp_rem_id'      => {},
      'lldp_rem_id_type' => {},
      'lldp_v2_rem_id' => {
        '1000.17.1.1' => '02:00:00:00:00:17',
        '1000.18.1.2' => pack('H*', '020000000018'),
        '1000.17.2.1' => '02:00:00:00:00:99',
      },
      'lldp_v2_rem_id_type' => {
        map { $_ => 'macAddress' } qw/1000.17.1.1 1000.18.1.2 1000.17.2.1/
      },
      'lldp_v2_rem_pid' => {
        '1000.17.1.1' => 'swp17', '1000.18.1.2' => 'swp18',
        '1000.17.2.1' => 'swp99',
      },
      'lldp_v2_dest_mac' => {
        1 => pack('H*', '0180c200000e'),
        2 => pack('H*', '0180c2000003'),
      },
      'lldp_v2_rman_addr' => {
        '1000.17.1.1.1.4.192.0.2.17' => 'ifIndex',
        '1000.17.2.1.1.4.192.0.2.99' => 'ifIndex',
      },
      'bp_index' => {17 => 101, 18 => 102},
    },
  });
  return;
}

sub at_paddr : Tests(5) {
  my $test = shift;
  $test->_prime_neighbor_cache();
  my $info = $test->{info};

  can_ok($info, 'at_paddr');
  cmp_deeply($info->at_paddr(), {
    '51001.192.0.2.130' => '02:00:00:00:01:30',
    '4.198.51.100.254' => '02:00:00:00:02:54',
  }, q(Standard ARP MAC addresses are normalized));
  cmp_deeply([sort keys %{$info->at_paddr()}],
    [sort keys %{$info->at_netaddr()}],
    q(ARP MAC and IP tables use the same keys));

  my $interfaces = $info->interfaces();
  my $index = $info->at_index();
  cmp_deeply({map { $_ => $interfaces->{$index->{$_}} } keys %$index}, {
    '51001.192.0.2.130' => 'vlan1', '4.198.51.100.254' => 'mgmt0',
  }, q(ARP interfaces resolve to the VLAN and management ports));

  $info->clear_cache();
  is($info->at_paddr(), undef, q(An empty ARP cache returns no entries));
}

sub at_netaddr : Tests(2) {
  my $test = shift;
  $test->_prime_neighbor_cache();

  can_ok($test->{info}, 'at_netaddr');
  cmp_deeply($test->{info}->at_netaddr(), {
    '51001.192.0.2.130' => '192.0.2.130',
    '4.198.51.100.254' => '198.51.100.254',
  }, q(Standard ARP IP addresses are available));
}

sub at_index : Tests(2) {
  my $test = shift;
  $test->_prime_neighbor_cache();

  can_ok($test->{info}, 'at_index');
  cmp_deeply($test->{info}->at_index(), {
    '51001.192.0.2.130' => 51001, '4.198.51.100.254' => 4,
  }, q(Standard ARP rows retain their ifIndex));
}

sub ipv6_n2p_mac : Tests(4) {
  my $test = shift;
  my $iid = $test->_prime_neighbor_cache();
  my $info = $test->{info};

  can_ok($info, 'ipv6_n2p_mac');
  cmp_deeply($info->ipv6_n2p_mac(), {$iid => '02:00:00:00:00:01'},
    q(Standard IPv6 neighbor MAC addresses are normalized));
  cmp_deeply([sort keys %{$info->ipv6_n2p_mac()}],
    [sort keys %{$info->ipv6_n2p_addr()}],
    q(IPv6 neighbor MAC and IP tables use the same keys));
  cmp_deeply($info->ipv6_n2p_if(), {$iid => 4},
    q(IPv6 neighbors retain their management ifIndex));
}

sub ipv6_n2p_addr : Tests(2) {
  my $test = shift;
  my $iid = $test->_prime_neighbor_cache();

  can_ok($test->{info}, 'ipv6_n2p_addr');
  cmp_deeply($test->{info}->ipv6_n2p_addr(), {
    $iid => 'fe80:0000:0000:0000:0000:0000:0000:0001',
  }, q(Standard IPv6 neighbor addresses are decoded));
}

sub pae_authconfig_state : Tests(2) {
  my $test = shift;

  isa_ok($test->{info}, 'SNMP::Info::PortAccessEntity');
  $test->{info}{'_pae_authconfig_state'} = 1;
  $test->{info}{store}{pae_authconfig_state} = {81 => 'authenticated'};
  cmp_deeply($test->{info}->pae_authconfig_state(), {81 => 'authenticated'},
    q(Port access data remains available with Layer3));
}

sub _prime_neighbor_cache {
  my $test = shift;
  my $iid = join('.', 4, 2, 16, 254, 128, (0) x 13, 1);

  # ipNetToMediaTable indices from the two Onyx 3.10 walks, with test IPs.
  # The IPv6 row checks the inherited IP-MIB format; no vendor parser is used.
  $test->{info}->clear_cache();
  $test->{info}->cache({
    '_at_paddr' => 1, '_at_netaddr' => 1, '_at_index' => 1,
    '_ip_n2p_phys_addr' => 1, '_i_index' => 1, '_i_description' => 1,
    'store' => {
      'at_paddr' => {
        '51001.192.0.2.130' => pack('H*', '020000000130'),
        '4.198.51.100.254' => pack('H*', '020000000254'),
      },
      'at_netaddr' => {
        '51001.192.0.2.130' => '192.0.2.130',
        '4.198.51.100.254' => '198.51.100.254',
      },
      'at_index' => {'51001.192.0.2.130' => 51001, '4.198.51.100.254' => 4},
      'ip_n2p_phys_addr' => {$iid => pack('H*', '020000000001')},
      'i_index' => {4 => 4, 51001 => 51001},
      'i_description' => {4 => 'mgmt0', 51001 => 'vlan1'},
    },
  });
  return $iid;
}

sub device_type : Tests(11) {
  my $test = shift;

  # device_type runs on the base class, whose layers() has no Onyx override
  my $info = SNMP::Info->new(AutoSpecify => 0, Session => $test->mock_session);
  my %cases = (
    'Onyx,MSN2410,SWv3.6.6102' =>
      ['.1.3.6.1.4.1.33049.1.1.1.2410', 'SNMP::Info::Layer3::Onyx'],
    'Onyx,MSN2700,SWv3.8.1000' =>
      ['.1.3.6.1.4.1.33049.1.1.1.2700', 'SNMP::Info::Layer3::Onyx'],
    'Onyx,MSN2010,SWv3.10.4606' =>
      ['.1.3.6.1.4.1.33049.1.1.1.2010', 'SNMP::Info::Layer3::Onyx'],
    'Onyx,SN2700M,SWv3.10.4606' =>
      ['.1.3.6.1.4.1.33049.1.1.1.270015', 'SNMP::Info::Layer3::Onyx'],
    'Mellanox SB7780' =>
      ['.1.3.6.1.4.1.33049.1.1.1.7780', 'SNMP::Info::Layer7'],
    'Mellanox SX6018G' =>
      ['.1.3.6.1.4.1.33049.1.1.1.60181', 'SNMP::Info::Layer7'],
    'Linux Onyx,MSN2700,SWv3.8.1000' =>
      ['.1.3.6.1.4.1.33049.1.1.1.2700', 'SNMP::Info::Layer7'],
    'Onyx,MSN2410,SWv3.10.4100' =>
      ['.1.3.6.1.4.1.33049.1.1.10.2410', 'SNMP::Info::Layer7'],
    'Linux Mellanox 2.6.27-MELLANOXuni-m460ex EFM_PPC_M460EX' =>
      ['.1.3.6.1.4.1.33049.2.3.2.1', 'SNMP::Info::Layer7'],
  );
  foreach my $descr (sort keys %cases) {
    my ($id, $class) = @{$cases{$descr}};
    $info->clear_cache();
    $info->cache({'_layers' => 72, '_description' => $descr, '_id' => $id});
    is($info->device_type(), $class, "device_type__${descr}__$class");
  }

  $info->clear_cache();
  $info->cache({
    '_description' => 'Onyx,MSN2010,SWv3.10.4606',
    '_id' => '.1.3.6.1.4.1.33049.1.1.1.2010',
  });
  is($info->device_type(), 'SNMP::Info::Layer3::Onyx',
    q(Onyx without sysServices still selects the Onyx class));
  is($test->{info}->device_type(), 'SNMP::Info::Layer3::Onyx',
    q(Adding layer 3 preserves the selected Onyx class));
}

1;
