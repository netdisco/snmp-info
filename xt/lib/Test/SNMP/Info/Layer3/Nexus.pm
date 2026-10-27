# Test::SNMP::Info::Layer3::Nexus
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

package Test::SNMP::Info::Layer3::Nexus;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Nexus;

# Remove this startup override once we have full method coverage
sub startup : Tests(startup => 1) {
  my $test = shift;
  $test->SUPER::startup();

  $test->todo_methods(1);
}

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $d_string = 'Cisco NX-OS(tm) n7000, Software (n7000-s1-dk9), ';
  $d_string .= 'Version 6.1(4), RELEASE SOFTWARE ';
  my $cache_data = {
    '_layers' => 70,
    '_description' => $d_string,

    # CISCO-ENTITY-VENDORTYPE-OID-MIB::cevChassisN7Kc7009
    '_id'   => '.1.3.6.1.4.1.9.12.3.1.3.932',
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

# A captured NX-OSv, swA (Rapid-PVST+ and MST): no VLAN 1
# port is up, so the default context serves no STP scalar under
# Rapid-PVST+. cContextMappingTable names vlan-N contexts, and mst-N ones
# under MST only.
sub _context_index {
  my $name = shift;
  return join('.', length $name, map { ord } split //, $name);
}

sub _nxos_cache {
  my %arg      = @_;
  my @contexts = (qw/vlan-1 vlan-10 vlan-20/, @{$arg{mst_contexts} || []});
  my %store    = (
    stpx_rstp_port_role => {map { $_ => 'designated' } @{$arg{roles}}},
    vrf_name            => {map { _context_index($_) => '' } @contexts},
    %{$arg{store} || {}},
  );
  return {
    '_layers'        => 70,
    '_description'   => 'Cisco NX-OS(tm) Nexus9000 C9300v, Software (NXOS'
      . ' 64-bit), Version 10.6(2), RELEASE SOFTWARE',
    '_id'            => '.1.3.6.1.4.1.9.12.3.1.3.1951',
    '_stpx_stp_type' => $arg{type},
    %{$arg{scalars} || {}},
    (map { ("_$_" => 1) } keys %store),
    'store' => \%store,
  };
}

sub _nxos_mst_cache {
  my @mst = @_;
  return _nxos_cache(
    type         => 'mst',
    roles        => [qw/0.1 0.2 1.1 1.2 2.1 2.2/],
    mst_contexts => \@mst,
    scalars      => {'_stp_root' => pack('H*', '800002000000000a')},
    store        => {
      stpx_smst_vlans_mapped_1k2k => {
        0 => pack('H*', '7fdff7' . ('ff' x 253)),
        1 => pack('H*', '0020'),
        2 => pack('H*', '000008'),
      },
      stpx_smst_vlans_mapped_3k4k =>
        {0 => pack('H*', ('ff' x 255) . 'fe'), 1 => '', 2 => ''},
    },
  );
}

sub snmp_context : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nxos_mst_cache(qw/mst-0 mst-1 mst-2/));
  cmp_deeply($info->snmp_context('vlan', 10),
    {kind => 'vlan', id => 10, v2c => undef, v3 => 'vlan-10'},
    'VLAN context: SNMPv3 only');
  cmp_deeply($info->snmp_context('mst', 1),
    {kind => 'mst', id => 1, v2c => undef, v3 => 'mst-1'},
    'MST context where the agent lists it');

  $info->clear_cache();
  $info->cache(_nxos_mst_cache());
  is($info->snmp_context('mst', 1), undef, 'No MST context unlisted');
}

sub context_kinds__vrf__is_vrf : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  cmp_deeply($info->context_kinds('vrf'), ['vrf'], 'One context per VRF');
  cmp_deeply($info->context_kinds('stp'), ['vlan', 'mst'],
    'STP answer is unchanged');
}

sub _vrf_context_cache {
  my %mapped = @_;
  my $cache = _nxos_cache(store => {vrf_name => {
    _context_index('vlan-1') => '',
    _context_index('1')      => '',
    map { _context_index($_) => $mapped{$_} } keys %mapped,
  }});
  return $cache;
}

sub snmp_context__vrf_mapped__v3_is_context : Tests(1) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_vrf_context_cache(red => 'red'));
  cmp_deeply($info->snmp_context('vrf', 'red'),
    {kind => 'vrf', id => 'red', v2c => undef, v3 => 'red'},
    'The context mapped to the VRF, v3 only');
}

sub snmp_context__vrf_other_context_name__v3_is_that_name : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_vrf_context_cache('ctx-r' => 'red'));
  cmp_deeply($info->snmp_context('vrf', 'red'),
    {kind => 'vrf', id => 'red', v2c => undef, v3 => 'ctx-r'},
    'A context named otherwise is the VRF context');

  $info->clear_cache();
  $info->cache(_vrf_context_cache('zeta' => 'red', 'alpha' => 'red'));
  is($info->snmp_context('vrf', 'red')->{v3}, 'alpha',
    'With several contexts, the lowest sorted name');
}

sub snmp_context__vrf_unmapped__v3_is_name : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_vrf_context_cache());
  is($info->snmp_context('vrf', 'red')->{v3}, 'red',
    'No mapped context: the VRF name');

  $info->clear_cache();
  $info->cache(_vrf_context_cache(red => 'red', 'ctx-b' => 'blue'));
  is($info->snmp_context('vrf', 'blue')->{v3}, 'ctx-b',
    'Another VRF context does not hide this one');
}

sub snmp_context__vrf_name_is_context_of_other_vrf__nothing : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_vrf_context_cache(red => 'blue'));
  is($info->snmp_context('vrf', 'red'), undef,
    'red is unmapped and its name is blue\'s context: no answer');
  is($info->snmp_context('vrf', 'blue')->{v3}, 'red',
    'blue is served by the context named red');

  _nx_enter_context($info, 'red');
  is($info->vrf_neighbors('red'), undef,
    'A caller-named red cannot read blue\'s context as its own');
}

sub snmp_context__vrf_malformed_context_index__ignored : Tests(1) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nxos_cache(store => {vrf_name => {'2.99.100.101' => 'red'}}));
  is($info->snmp_context('vrf', 'red')->{v3}, 'red',
    'An index whose length prefix is wrong names no context');
}

sub snmp_context__vrf_default__nothing : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_vrf_context_cache());
  is($info->snmp_context('vrf', 'default'), undef, 'default: nothing');
  is($info->snmp_context('vrf', q()),       undef, 'empty name: nothing');
  is($info->snmp_context('vrf'),            undef, 'no name: nothing');
}

# NX-OS 9000v shape: the default context map lists the VLAN 1 contexts with no
# VRF, and one context per VRF named like it.
sub _vrf_list_cache {
  return _vrf_context_cache(
    map { $_ => $_ } qw/red blue grey green/);
}

sub vrf_instances : Tests(8) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_vrf_list_cache());
  my $instances = $info->vrf_instances();
  cmp_deeply([sort keys %$instances], [qw/blue default green grey red/],
    'Each non-empty mapped VRF name, and default');
  foreach my $name (qw/red blue grey green/) {
    is($instances->{$name}{sources}{list}, 'CISCO-CONTEXT-MAPPING-MIB',
      "$name is listed by the context map");
  }
  is($instances->{red}{contexts}[0]{v3}, 'red', 'The context is the name');
  ok(!exists $instances->{'vlan-1'} && !exists $instances->{q()} &&
    !exists $instances->{1}, 'Empty-valued rows are never instances');
  is($instances->{red}{listed_by}, 'device', 'Listed by the device');
}

sub vrf_instances__context_map_value_default__never_an_instance : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_vrf_context_cache(red => 'red', 'ctx-d' => 'default'));
  my $instances = $info->vrf_instances();
  cmp_deeply([sort keys %$instances], [qw/default red/],
    'A context mapped to default adds no instance');
  cmp_deeply($instances->{default}{contexts}, [{kind => 'none'}],
    'default keeps the default context');
  is($info->snmp_context('vrf', 'default'), undef,
    'default has no context to switch to');
}

sub vrf_instances_complete__context_map_walked__is_1 : Tests(1) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_vrf_list_cache());
  is($info->vrf_instances_complete(), 1,
    'A complete context map walk lists every VRF');
}

sub vrf_instances_complete__context_map_partial__is_0 : Tests(1) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_vrf_list_cache());
  $info->{walk_status}{vrf_name} = {complete => 0, reason => 'timeout'};
  is($info->vrf_instances_complete(), 0, 'A partial context map walk');
}

sub vrf_instances__cisco_vrf_mib_rows__context_map_still_listed : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  my $cache = _vrf_list_cache();
  $cache->{_vrf_cv_name} = 1;
  $cache->{_vrf_cv_if}   = 1;
  $cache->{store}{vrf_cv_name} = {1 => 'amber'};
  $cache->{store}{vrf_cv_if}   = {'1.2' => 'active'};
  $info->cache($cache);
  my $instances = $info->vrf_instances();
  cmp_deeply([sort keys %$instances], [qw/blue default green grey red/],
    'The context map lists; CISCO-VRF-MIB adds nothing');
  is($instances->{red}{sources}{list}, 'CISCO-CONTEXT-MAPPING-MIB',
    'The context map is the source');
  ok(!exists $instances->{red}{sources}{members},
    'CISCO-VRF-MIB holds no membership here');
  ok(!exists $info->walk_status()->{vrf_cv_if},
    'CISCO-VRF-MIB interfaces are not walked');
}

sub vrf_instances__mpls_rows_present__ignore_context_map : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  my $cache = _vrf_list_cache();
  $cache->{_vrf_l3vpn_descr} = 1;
  $cache->{store}{vrf_l3vpn_descr} = {'3.114.101.100' => q()};
  $info->cache($cache);
  my $instances = $info->vrf_instances();
  cmp_deeply([sort keys %$instances], [qw/default red/],
    'Only the MPLS-L3VPN row is listed');
  is($instances->{red}{sources}{list}, 'MPLS-L3VPN-STD-MIB',
    'Listed by MPLS-L3VPN-STD-MIB');
  ok(!exists $instances->{blue}, 'The context map adds nothing');
}

sub vrf_name__unchanged : Tests(1) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_vrf_context_cache(red => 'red'));
  cmp_deeply($info->vrf_name(), {
      _context_index('vlan-1') => '',
      _context_index('1')      => '',
      _context_index('red')    => 'red',
    },
    'The raw context map, as served');
}

# Ports of the VRF interfaces on an NX-OS 9000v: red holds two, as does blue
my %NX_PORT = (
  red_a  => 436207616,
  blue_a => 436208128,
  red_b  => 436208640,
  blue_b => 436209152,
  green  => 436209664,
);
my $NX_PFX = '.1.3.6.1.2.1.4.32.1.5';

# The index arcs of an IPv6 address written as eight hex groups
sub _v6_arcs {
  my $ip = shift;
  return join('.', unpack('C*', pack('n8', map { hex } split /:/, $ip)));
}

sub _nx_mac { return pack('C6', 2, 0, 0, 0, 0, shift) }

# The neighbor rows NX-OS serves on one VRF port, in any context: a
# global, an EUI-64 and a link-local IPv6 neighbor. $net is the third
# group of the port's prefix.
sub _nx_port_neighbors {
  my ($port, $net, $mac) = @_;
  my $eui = sprintf('%x', 0x200 + $mac);
  return map { ("$port.2.16." . _v6_arcs($_) => _nx_mac($mac)) } (
    "2001:db8:$net:0:0:0:0:2",
    "2001:db8:$net:0:0:ff:fe00:$eui",
    'fe80:0:0:0:0:0:0:2',
  );
}

# Address tables of the context: ipAddressTable rows by type, length and
# octets, with the RowPointer form NX-OS serves, and ipAdEntTable rows
sub _nx_addresses {
  my @rows = @_;
  my (%index, %type, %prefix, %adent, %mask);
  foreach my $row (@rows) {
    my ($port, $ip, $len) = @$row;
    my ($iid, $pointer);
    if ($ip =~ /:/) {
      my $arcs = _v6_arcs($ip);
      ($iid, $pointer) = ("2.16.$arcs", "$NX_PFX.$port.2.$arcs.$len");
    }
    else {
      (my $net = $ip) =~ s/\.\d+$/.0/;
      ($iid, $pointer) = ("1.4.$ip", "$NX_PFX.$port.1.$net.$len");
      $adent{$ip} = $port;
      $mask{$ip}  = '255.255.255.0';
    }
    $index{$iid}  = $port;
    $type{$iid}   = 'unicast';
    $prefix{$iid} = $pointer;
  }
  return (
    new_ip_index   => \%index,
    new_ip_type    => \%type,
    new_ip_prefix  => \%prefix,
    old_ip_index   => \%adent,
    old_ip_netmask => \%mask,
  );
}

# The session's SNMPv3 context, as a caller switches it
sub _nx_enter_context {
  my ($info, $context) = @_;
  $info->session()->{Version} = 3;
  $info->session()->{Context} = $context;
  return;
}

# NX-OS 9000v, red context: red's two ports hold 10.10.10.1/24, 10.11.0.1/24 and
# 2001:db8:10::1/64, 2001:db8:11::1/64; two ARP and six IPv6 neighbors
sub _nx_red_cache {
  my ($red_a, $red_b) = @NX_PORT{qw/red_a red_b/};
  my $cache = _vrf_list_cache();
  my %store = (
    _nx_addresses(
      [$red_a, '10.10.10.1', 24], [$red_b, '10.11.0.1', 24],
      [$red_a, '2001:db8:10:0:0:0:0:1', 64],
      [$red_b, '2001:db8:11:0:0:0:0:1', 64],
    ),
    at_paddr   => {
      "$red_a.10.10.10.2" => _nx_mac(1),
      "$red_b.10.11.0.2"  => _nx_mac(3),
    },
    at_netaddr => {
      "$red_a.10.10.10.2" => '10.10.10.2',
      "$red_b.10.11.0.2"  => '10.11.0.2',
    },
    ip_n2p_phys_addr => {
      "$red_a.1.4.10.10.10.2" => _nx_mac(1),
      "$red_b.1.4.10.11.0.2"  => _nx_mac(3),
      _nx_port_neighbors($red_a, 10, 1),
      _nx_port_neighbors($red_b, 11, 3),
    },
  );
  $cache->{store} = {%{$cache->{store}}, %store};
  $cache->{"_$_"} = 1 for keys %store;
  return $cache;
}

# NX-OS 9000v, default context: no address row, and the IPv6 neighbors of every VRF
# port, which the default context serves although no port is its own
sub _nx_default_cache {
  my $cache = _vrf_list_cache();
  my %store = (
    _nx_addresses(),
    at_paddr         => {},
    at_netaddr       => {},
    ip_n2p_phys_addr => {
      _nx_port_neighbors($NX_PORT{red_a},  10, 1),
      _nx_port_neighbors($NX_PORT{blue_a}, 10, 2),
      _nx_port_neighbors($NX_PORT{red_b},  11, 3),
      _nx_port_neighbors($NX_PORT{blue_b}, 12, 3),
      _nx_port_neighbors($NX_PORT{green},  13, 4),
      "$NX_PORT{blue_b}.2.16." . _v6_arcs('fe80:0:0:0:0:ff:fe00:203')
        => _nx_mac(3),
    },
  );
  $cache->{store} = {%{$cache->{store}}, %store};
  $cache->{"_$_"} = 1 for keys %store;
  return $cache;
}

sub i_vrf : Tests(1) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nx_red_cache());
  _nx_enter_context($info, 'red');
  cmp_deeply(scalar $info->i_vrf(),
    {$NX_PORT{red_a} => 'red', $NX_PORT{red_b} => 'red'},
    'The ports holding an address in the red context');
}

sub i_vrf__default_context__default_ports_only : Tests(1) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nx_default_cache());
  cmp_deeply(scalar $info->i_vrf(), {},
    'No port holds an address in the default context');
}

sub vrf_neighbors__default_context__drops_leaked_ipv6 : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nx_default_cache());
  is(scalar keys %{$info->ipv6_n2p_mac()}, 16,
    'The default context serves every VRF port\'s IPv6 neighbors');
  cmp_deeply($info->vrf_neighbors('default'), {},
    'None of them is on a port of the default instance');
}

sub vrf_neighbors__red_context__red_rows : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nx_red_cache());
  _nx_enter_context($info, 'red');
  $info->{store}{ip_n2p_phys_addr}{"$NX_PORT{blue_a}.2.16."
      . _v6_arcs('2001:db8:10:0:0:0:0:2')} = _nx_mac(2);
  my $rows = $info->vrf_neighbors('red');
  my @rows = values %$rows;
  is(scalar @rows, 8, 'Eight neighbor rows, a row on a blue port dropped');
  is(scalar(grep { $_->{family} eq 'ipv4' } @rows), 2, 'Two are IPv4');
  is(scalar(grep { $_->{family} eq 'ipv6' } @rows), 6, 'Six are IPv6');
  cmp_deeply([sort map { $_->{ifindex} } @rows],
    [($NX_PORT{red_a}) x 4, ($NX_PORT{red_b}) x 4],
    'All on red ports');
}

sub vrf_neighbors__wrong_context__error : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nx_red_cache());
  _nx_enter_context($info, 'blue');
  is($info->vrf_neighbors('red'), undef, 'No rows from blue\'s context');
  like($info->error(),
    qr/vrf_neighbors\(\) reads instance 'red' from its own context, but this session is in context 'blue'\. Switch with snmp_context\('vrf', 'red'\) first\./,
    'The error names both contexts and the switch');
}

sub i_vrf__context_no_instance_has__error : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nx_red_cache());
  _nx_enter_context($info, 'zzz');
  is(scalar $info->i_vrf(), undef, 'No ports for an unclaimed context');
  like($info->error(),
    qr/i_vrf\(\) maps the ports of the instance whose context this session is in, but no instance in vrf_instances\(\) has the context 'zzz'\. Switch to the context snmp_context\('vrf'\) gives for a name vrf_instances\(\) lists\./,
    'The error names the context and the way to a listed one');
}

sub vrf_neighbors__default_name_in_vrf_context__error : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nx_red_cache());
  _nx_enter_context($info, 'red');
  is($info->vrf_neighbors('default'), undef,
    'No rows of red\'s context under the name default');
  like($info->error(),
    qr/vrf_neighbors\(\) reads instance 'default' from the default context on this device\. This session is in context 'red'\. Call update\(\) back to the default context first\./,
    'The error names the context and the way back');
}

# NX-OS 9000v, green context: one IPv6 address, and its connected and host routes
sub vrf_subnets__green_context__ipv6_only : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  my $port   = $NX_PORT{green};
  my ($net, $own, $peer)
    = map { _v6_arcs("2001:db8:13:0:0:0:0:$_") } 0, 1, 2;
  my %proto = (
    "2.16.$net.64.2.0.0.2.16.$own"   => 'local',
    "2.16.$own.128.2.0.0.2.16.$own"  => 'local',
    "2.16.$peer.128.2.0.0.2.16.$peer" => 'other',
  );
  my $cache = _vrf_list_cache();
  my %store = (
    _nx_addresses([$port, '2001:db8:13:0:0:0:0:1', 64]),
    vrf_cidr_proto => \%proto,
    vrf_cidr_if    => {map { $_ => $port } keys %proto},
  );
  $cache->{store} = {%{$cache->{store}}, %store};
  $cache->{"_$_"} = 1 for keys %store;

  $info->clear_cache();
  $info->cache($cache);
  _nx_enter_context($info, 'green');
  my $subnets = $info->vrf_subnets('green');
  cmp_deeply([keys %$subnets],
    ['2001:0db8:0013:0000:0000:0000:0000:0000/64'],
    'The one IPv6 subnet, no host route');
  is($subnets->{(keys %$subnets)[0]}{family}, 'ipv6', 'Family ipv6');
}

sub snmp_context__vlan_and_mst__unchanged : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nxos_mst_cache(qw/mst-0 mst-1/));
  cmp_deeply($info->snmp_context('vlan', 10),
    {kind => 'vlan', id => 10, v2c => undef, v3 => 'vlan-10'}, 'vlan');
  cmp_deeply($info->snmp_context('mst', 1),
    {kind => 'mst', id => 1, v2c => undef, v3 => 'mst-1'}, 'mst');
  is($info->snmp_context('mst', 2), undef, 'unlisted mst');
}

sub context_kinds : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  cmp_deeply($info->context_kinds('stp'), ['vlan', 'mst'],
    'STP trees in VLAN and MST contexts');
  cmp_deeply($info->context_kinds('fdb'), ['vlan'], 'FDB in VLAN contexts');
}

sub stp_trees : Tests(7) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(
    _nxos_cache(type => 'rapidPvstPlus', roles => [qw/10.1 10.2 20.1 20.2/]));
  my $trees = $info->stp_trees();
  cmp_deeply([sort keys %$trees], [qw/vlan.10 vlan.20/],
    'Rapid-PVST+: trees from the role table');
  cmp_deeply($trees->{'vlan.10'}{contexts},
    [{kind => 'vlan', id => 10, v2c => undef, v3 => 'vlan-10'}],
    'VLAN 10 read over SNMPv3');
  is($trees->{'vlan.10'}{root}, undef,
    'No root served in the default context');
  is($trees->{'vlan.10'}{measured}, 1, 'NX-OS Rapid-PVST+ is measured');

  $info->clear_cache();
  $info->cache(_nxos_mst_cache(qw/mst-0 mst-1 mst-2/));
  $trees = $info->stp_trees();
  cmp_deeply(
    [@{$trees->{'cist.0'}}{qw/contexts ports_complete/}],
    [[{kind => 'mst', id => 0, v2c => undef, v3 => 'mst-0'}], 0],
    'CIST read in mst-0; whether it maps ports to ifIndex is unmeasured');
  cmp_deeply([map { $_->{v3} } @{$trees->{'msti.1'}{contexts}}],
    [qw/mst-1 vlan-10/], 'MSTI 1: its own context first, then VLAN 10');

  $info->clear_cache();
  $info->cache(_nxos_mst_cache());
  cmp_deeply(
    [@{$info->stp_trees()->{'cist.0'}}{qw/contexts ports_complete/}],
    [[{kind => 'none'}], 0],
    'Without mst-0 the CIST falls back to the default context');
}

sub vrf_instances_complete__vlan_contexts_only__is_1 : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_vrf_context_cache());
  cmp_deeply([keys %{$info->vrf_instances()}], ['default'],
    'Only VLAN contexts mapped: default only');
  is($info->vrf_instances()->{default}{sources}{list},
    'CISCO-CONTEXT-MAPPING-MIB', 'The context map lists default');
  is($info->vrf_instances_complete(), 1, 'None configured');
  ok(!exists $info->vrf_instances(['red'])->{red},
    'Caller names add nothing');
}

# snmpCommunityTable as NX-OS serves it: the name only on the session's own
# row, the context on every row. Indexes are length-prefixed decimal strings.
my %NX_COMMUNITY_ROW = (
  'public'       => ['9.45.49.50.51.52.53.54.55.56', q()],
  'public-red'   => ['9.45.50.51.52.53.54.55.56.57', 'red'],
  'public-blue'  => ['9.45.51.52.53.54.55.56.57.48', 'blue'],
  'public-green' => ['9.45.52.53.54.55.56.57.48.49', 'green'],
  'public-grey'  => ['9.45.53.54.55.56.57.48.49.50', 'grey'],
);

sub _nx_community_cache {
  my ($community, $cache) = @_;
  $cache ||= _vrf_list_cache();
  my (%names, %contexts);
  foreach my $own (keys %NX_COMMUNITY_ROW) {
    my ($index, $context) = @{$NX_COMMUNITY_ROW{$own}};
    $names{$index}    = $own eq $community ? $own : q();
    $contexts{$index} = $context;
  }
  $cache->{store}{vrf_comm_name}    = \%names;
  $cache->{store}{vrf_comm_context} = \%contexts;
  $cache->{_vrf_comm_name}          = 1;
  $cache->{_vrf_comm_context}       = 1;
  return $cache;
}

sub _nx_enter_community {
  my ($info, $community) = @_;
  $info->{args}{Community}         = 'public';
  $info->session()->{Version}      = 2;
  $info->session()->{Community}    = $community;
  return;
}

sub _vrf_community_context__mapped_community__returns_its_context : Tests(1) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nx_community_cache('public-red'));
  _nx_enter_community($info, 'public-red');
  is($info->_vrf_community_context(), 'red',
    'The context of the row carrying the session community');
}

sub _vrf_community_context__default_community__returns_empty : Tests(1) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nx_community_cache('public'));
  _nx_enter_community($info, 'public');
  is($info->_vrf_community_context(), q(),
    'The default community maps to the default context');
}

sub _vrf_community_context__no_matching_row__undef : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nx_community_cache('public-red'));
  _nx_enter_community($info, 'public-other');
  is($info->_vrf_community_context(), undef, 'No row equals the community');

  $info->clear_cache();
  $info->cache(_vrf_list_cache());
  $info->{store}{vrf_comm_name} = undef;
  _nx_enter_community($info, 'public-red');
  is($info->_vrf_community_context(), undef, 'The table is not served');
}

sub _vrf_community_context__v3__undef_without_walking : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_vrf_list_cache());
  _nx_enter_context($info, 'red');
  my $walks = 0;
  no warnings 'redefine';
  local *SNMP::Info::Layer3::Nexus::vrf_comm_name = sub { $walks++; return {} };
  is($info->_vrf_community_context(), undef, 'No answer over SNMPv3');
  is($walks, 0, 'The community table was not walked');
}

sub _vrf_session_context__mapped_community__follows_session : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nx_community_cache(q(public)));
  _nx_enter_community($info, q(public));
  is($info->_vrf_session_context(), q(), q(The default session));
  $info->clear_cache();
  $info->cache(_nx_community_cache('public-red'));
  _nx_enter_community($info, 'public-red');
  is($info->_vrf_session_context(), 'red', 'A red session');
  $info->clear_cache();
  $info->cache(_nx_community_cache('public'));
  _nx_enter_community($info, 'public');
  is($info->_vrf_session_context(), q(), 'The default session after update()');
}

sub vrf_neighbors__mapped_community_red__reads_red : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nx_community_cache('public-red', _nx_red_cache()));
  _nx_enter_community($info, 'public-red');
  my @rows = values %{$info->vrf_neighbors('red')};
  is(scalar @rows, 8, 'Eight red neighbor rows');
  cmp_deeply([sort map { $_->{ifindex} } @rows],
    [($NX_PORT{red_a}) x 4, ($NX_PORT{red_b}) x 4], 'All on red ports');
}

sub vrf_neighbors__mapped_community_red__default_throws : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nx_community_cache('public-red', _nx_red_cache()));
  _nx_enter_community($info, 'public-red');
  is($info->vrf_neighbors('default'), undef, 'No default rows over red');
  like($info->error(),
    qr/reads instance 'default' from the default context.*in context 'red'/s,
    'The error names the context');
}

sub vrf_instances__mapped_community__throws_not_default : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nx_community_cache('public-red'));
  _nx_enter_community($info, 'public-red');
  is($info->vrf_instances(), undef, 'The list is refused over red');
  like($info->error(), qr/only the default context.*context 'red'/s,
    'The error names the default context');
}

sub vrf_instances__default_community__lists : Tests(1) {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->cache(_nx_community_cache('public'));
  _nx_enter_community($info, 'public');
  ok($info->vrf_instances()->{red}, 'The default community lists the VRFs');
}

1;
