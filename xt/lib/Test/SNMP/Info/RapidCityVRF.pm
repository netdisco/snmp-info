# Test::SNMP::Info::RapidCityVRF
#
# Copyright (c) 2026 The SNMP::Info Developers
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

package Test::SNMP::Info::RapidCityVRF;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::RapidCityVRF;
use SNMP::Info::Layer3::VOSS;

# The mixin reads the VRF role of SNMP::Info::VRF and the core's leaves, so
# it is exercised through Layer3::VOSS, the class that lists it
sub setup : Tests(setup) {
  my $test = shift;

  my $class = $test->class;
  $test->class('SNMP::Info::Layer3::VOSS');
  $test->SUPER::setup;
  $test->class($class);

  $test->{info}->cache({'store' => {}});
}

sub _arcs {
  my $ip = shift;
  return $ip =~ /:/
    ? (2, 16, unpack('C*', pack('n8', map { hex } split /:/, $ip)))
    : (1, 4, split /\./, $ip);
}

sub _enter_vr {
  my ($info, $context) = @_;
  $info->session()->{Version} = 3;
  $info->session()->{Context} = $context;
  return;
}

sub _use_cache {
  my ($test, $cache) = @_;
  $test->{info}->clear_cache();
  $test->{info}->cache($cache);
  return $test->{info};
}

sub _v6 {
  return join ':', unpack '(H4)*', pack 'C*', (_arcs(shift))[2 .. 17];
}

sub _address_list {
  my $rows = shift;
  return [sort map { "$_->{ifindex} $_->{ip}" } values %$rows];
}

# VOSS (Fabric Engine 9.4) with VRFs red (vrfid 1), blue (2), green (3,
# IPv6 only), grey (4, a loopback only) and MgmtRouter (512); vrfid 0 is
# GlobalRouter. Each VRF is reached by its rcVrfContextName. A VRF context
# serves only its own rcVrfConfigTable row, its own VLANs and its own
# rcIpAddrTable rows; rcVrfIpVpnTable is whole in every context. The
# default context serves every VLAN, and rcIpAddrTable only for vrfid 0.
my %VOSS_VRF_NAMES = (0 => 'GlobalRouter', 1 => 'red', 2 => 'blue',
  3 => 'green', 4 => 'grey', 512 => 'MgmtRouter');
my %VOSS_CONTEXTS = (0 => q(), 1 => 'vrf1', 2 => 'vrf2', 3 => 'vrf3',
  4 => 'vrf4', 512 => 'vrf512');
my %VOSS_ISIDS = (1 => 30001, 2 => 30002, 3 => 30003, 4 => 30004);

# rcVlanTable: VLAN => [rcVlanIfIndex, rcVlanVrfId]. 4051 is the fabric
# VLAN whose ifIndex carries the routes learned over the fabric.
my %VOSS_VLANS = (1 => [2049, 0], 10 => [2058, 0], 41 => [2089, 1],
  42 => [2090, 2], 43 => [2091, 1], 44 => [2092, 2], 45 => [2093, 3],
  4048 => [6096, 0], 4051 => [6099, 0], 4052 => [6100, 0]);

# rcIpAddrTable rows [ifIndex, address, mask] per rcIpAdEntVrfId; each
# context serves the rows of its own vrfid
my %VOSS_IP_ROWS = (
  0 => [[1344, '10.255.0.13', '255.255.255.255']],
  1 => [[2089, '10.100.1.1', '255.255.255.0'],
    [2091, '10.101.1.1', '255.255.255.0']],
  2 => [[2090, '10.100.1.1', '255.255.255.0'],
    [2092, '10.102.1.1', '255.255.255.0']],
  4 => [[1345, '10.104.1.1', '255.255.255.255']],
);

# rcIpAdEntVrfId, rcIpAdEntAddr and rcIpAdEntNetMask of the rows of
# @vrfids, indexed ifIndex then address
sub _voss_ip_store {
  my (%vrf, %addr, %mask);
  foreach my $vrfid (@_) {
    foreach my $row (@{$VOSS_IP_ROWS{$vrfid} || []}) {
      my ($port, $ip, $netmask) = @$row;
      $vrf{"$port.$ip"}  = $vrfid;
      $addr{"$port.$ip"} = $ip;
      $mask{"$port.$ip"} = $netmask;
    }
  }
  return (vrf_rc_ip_vrf => \%vrf, vrf_rc_ip_addr => \%addr,
    vrf_rc_ip_mask => \%mask);
}

# ifPhysAddress, the same in every context: each VLAN interface's MAC
# octet, 9 for the fabric VLAN's
my %VOSS_PORT_MAC = (2089 => 1, 2090 => 2, 2091 => 3, 2092 => 4,
  2093 => 5, 6099 => 9);

# inetCidrRouteTable rows as VOSS indexes them, with no length octet before
# either address: [prefix, length, next hop, ifIndex, proto]
sub _voss_route_store {
  my (%if, %proto);
  foreach my $row (@_) {
    my ($prefix, $length, $hop, $port, $proto) = @$row;
    my ($dest_type, undef, @dest) = _arcs($prefix);
    my ($hop_type,  undef, @hop)  = _arcs($hop);
    my $iid = join '.', $dest_type, @dest, $length, 0, $hop_type, @hop;
    $if{$iid}    = $port;
    $proto{$iid} = $proto // 'local';
  }
  return (vrf_cidr_if => \%if, vrf_cidr_proto => \%proto);
}

# ipNetToMediaTable rows [ifIndex, address, MAC] and IPV6-MIB
# ipv6NetToMediaTable rows [ifIndex, IPv6 address, MAC]; a MAC is its last
# octet, or the six octets
sub _voss_mac {
  my $mac = shift;
  return ref $mac ? pack('C6', @$mac) : pack('C6', 2, 0, 0, 0, 0, $mac);
}

sub _voss_neighbor_store {
  my %tables = @_;
  my (%paddr, %netaddr, %nd);
  foreach my $row (@{$tables{arp} || []}) {
    my ($port, $ip, $mac) = @$row;
    $paddr{"$port.$ip"}   = _voss_mac($mac);
    $netaddr{"$port.$ip"} = $ip;
  }
  foreach my $row (@{$tables{nd} || []}) {
    my ($port, $ip, $mac) = @$row;
    my (undef, undef, @octets) = _arcs($ip);
    $nd{join '.', $port, @octets} = _voss_mac($mac);
  }
  return (at_paddr => \%paddr, at_netaddr => \%netaddr,
    i6_n2p_phys_addr => \%nd);
}

# IPV6-MIB ipv6AddrTable ipv6AddrPfxLength rows [ifIndex, address, length]
sub _voss_v6_address_store {
  my %length;
  foreach my $row (@_) {
    my ($port, $ip, $prefix_length) = @$row;
    my (undef, undef, @octets) = _arcs($ip);
    $length{join '.', $port, @octets} = $prefix_length;
  }
  return (i6_addr_pfxlen => \%length);
}

sub _voss_port_macs {
  return (i_mac => {map { $_ => _voss_mac($VOSS_PORT_MAC{$_}) }
      keys %VOSS_PORT_MAC});
}

# The context of the VRFs @$vrfids, the default context when they include
# 0: their rcVrfConfigTable rows, VLANs and rcIpAddrTable rows, then the
# rest of the store
sub _voss_cache {
  my ($vrfids, %rest) = @_;
  my %in_context = map { $_ => 1 } @$vrfids;
  my @vlans = grep { $in_context{$VOSS_VLANS{$_}[1]} } keys %VOSS_VLANS;
  my @ip_rows = $in_context{0} ? (0) : @$vrfids;
  my %store = (
    vrf_rc_name    => {map { $_ => $VOSS_VRF_NAMES{$_} } @$vrfids},
    vrf_rc_context => {map { $_ => $VOSS_CONTEXTS{$_} } @$vrfids},
    vrf_rc_isid    => {%VOSS_ISIDS},
    vrf_rc_vlan_if  => {map { $_ => $VOSS_VLANS{$_}[0] } @vlans},
    vrf_rc_vlan_vrf => {map { $_ => $VOSS_VLANS{$_}[1] } @vlans},
    _voss_ip_store(@ip_rows),
    %rest,
  );
  my $cache = {
    '_layers'      => 6,
    '_description' => '5520-24T-FabricEngine (9.4.0.0)',
    '_id'          => '.1.3.6.1.4.1.1916.2.437',
    'store'        => \%store,
  };
  $cache->{"_$_"} = 1 for keys %store;
  return $cache;
}

# GlobalRouter's routes: its CLIP on 1344, the management CLIP's host
# route on the management VLAN's interface 6138, and those learned over
# the fabric
sub _voss_default_cache {
  return _voss_cache([keys %VOSS_VRF_NAMES],
    _voss_route_store(
      ['10.20.0.0',   24, '127.1.0.10',  6099, 'isIs'],
      ['10.30.0.0',   24, '127.1.0.9',   6099, 'isIs'],
      ['10.254.0.13', 32, '10.254.0.13', 6138],
      ['10.254.0.14', 32, '127.1.0.10',  6099, 'isIs'],
      ['10.254.0.15', 32, '127.1.0.9',   6099, 'isIs'],
      ['10.255.0.13', 32, '10.255.0.13', 1344],
      ['10.255.0.14', 32, '127.1.0.10',  6099, 'isIs'],
      ['10.255.0.15', 32, '127.1.0.9',   6099, 'isIs'],
      ['2001:db8:1255:0:0:0:0:13', 128, '0:0:0:0:0:0:0:0', 1344],
      ['2001:db8:1255:0:0:0:0:15', 128, '0:0:0:0:0:0:0:0', 6099, 'esIs'],
    ));
}

# red's connected routes on its VLANs, and one learned over the fabric
my @VOSS_RED_ROUTES = (
  ['10.100.1.0', 24, '10.100.1.1', 2089],
  ['10.100.3.0', 24, '127.1.0.9',  6099, 'isIs'],
  ['10.101.1.0', 24, '10.101.1.1', 2091],
);

# A VLAN's own address and the broadcast address are served at the VLAN
# interface's MAC and the broadcast MAC; link-locals are the interface's
my $VOSS_BROADCAST = [(0xff) x 6];
my $VOSS_RED_LINK_LOCAL = 'fe80:0:0:0:0:ff:fe00:1';

sub _voss_red_cache {
  return _voss_cache([1], _voss_route_store(@VOSS_RED_ROUTES),
    _voss_port_macs(),
    _voss_neighbor_store(
      arp => [[2089, '10.100.1.1', 1], [2089, '10.100.1.10', 0x0a],
        [2089, '10.100.1.255', $VOSS_BROADCAST],
        [2091, '10.101.1.1', 3], [2091, '10.101.1.10', 0x0c],
        [2091, '10.101.1.255', $VOSS_BROADCAST]],
      nd => [[2089, '2001:db8:1001:0:0:0:0:1', 1],
        [2089, '2001:db8:1001:0:0:0:0:16', 0x0a],
        [2089, $VOSS_RED_LINK_LOCAL, 1]],
    ),
    _voss_v6_address_store([2089, '2001:db8:1001:0:0:0:0:1', 64],
      [2089, $VOSS_RED_LINK_LOCAL, 64]),
  );
}

# blue holds red's 10.100.1.0/24 too, on its own VLAN
sub _voss_blue_cache {
  return _voss_cache([2],
    _voss_route_store(['10.100.1.0', 24, '10.100.1.1', 2090],
      ['10.100.3.0', 24, '127.1.0.9',  6099, 'isIs'],
      ['10.102.1.0', 24, '10.102.1.1', 2092]),
    _voss_port_macs(),
    _voss_neighbor_store(
      arp => [[2090, '10.100.1.1', 2], [2090, '10.100.1.10', 0x0b],
        [2090, '10.100.1.255', $VOSS_BROADCAST],
        [2092, '10.102.1.1', 4], [2092, '10.102.1.10', 0x0d],
        [2092, '10.102.1.255', $VOSS_BROADCAST]],
    ),
  );
}

# grey's loopback has no VLAN; the loopback's own ARP row is served at the
# loopback's MAC, 00:00:00:00:00:02
sub _voss_grey_cache {
  return _voss_cache([4],
    _voss_route_store(['10.104.1.1', 32, '10.104.1.1', 1345],
      ['10.104.3.1', 32, '127.1.0.9', 6099, 'isIs']),
    _voss_port_macs(),
    _voss_neighbor_store(arp => [[1345, '10.104.1.1', [0, 0, 0, 0, 0, 2]]]),
  );
}

# green is IPv6 only and has no inetCidrRouteTable row
sub _voss_green_cache {
  my $link_local = 'fe80:0:0:0:0:ff:fe00:5';
  return _voss_cache([3], _voss_port_macs(),
    _voss_neighbor_store(
      nd => [[2093, '2001:db8:1201:0:0:0:0:1', 5],
        [2093, '2001:db8:1201:0:0:0:0:16', 0x0e],
        [2093, $link_local, 5]],
    ),
    _voss_v6_address_store([2093, '2001:db8:1201:0:0:0:0:1', 64],
      [2093, $link_local, 64]),
  );
}

sub context_kinds__vrf__voss : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  cmp_deeply(scalar $info->context_kinds('vrf'), ['vrf'],
    'One context per VRF');
  is($info->context_kinds('stp'), undef, 'No other feature has one');
}

sub snmp_context__voss_red__v2c_colon_vrfid : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  cmp_deeply(scalar $info->snmp_context('vrf', 'red'),
    {kind => 'vrf', id => 'red', v2c => '%s::1', v3 => 'vrf1'},
    'The v2c form is community::vrfid; v3 is rcVrfContextName');
  is(sprintf($info->snmp_context('vrf', 'red')->{v2c}, 'public'),
    'public::1', 'The form fills in the community');
}

sub snmp_context__voss_mgmt__v2c_colon_512 : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  my $context = $info->snmp_context('vrf', 'MgmtRouter') || {};
  is($context->{v2c}, '%s::512', 'MgmtRouter is vrfid 512');
  is($context->{v3}, 'vrf512', 'Its SNMPv3 context is vrf512');
}

sub snmp_context__voss_default__nothing : Tests(4) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  is($info->snmp_context('vrf', 'default'), undef, 'default has none');
  is($info->snmp_context('vrf', 'GlobalRouter'), undef,
    'Nor GlobalRouter, which is default');
  is($info->snmp_context('vrf', 'purple'), undef, 'Nor an unlisted name');
  is($info->snmp_context('vlan', 41), undef, 'Another kind has none');
}

sub vrf_instances__voss : Tests(7) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  my $instances = $info->vrf_instances();
  cmp_deeply([sort keys %$instances],
    [qw/MgmtRouter blue default green grey red/],
    'Every rcVrfConfigTable row, with GlobalRouter as default');
  cmp_deeply($instances->{red}, superhashof({
      kind      => 'vrf',
      l3_isid   => 30001,
      listed_by => 'device',
      sources   => {list => 'RAPID-CITY', l3_isid => 'RAPID-CITY',
        members => 'RAPID-CITY'},
      contexts  => [{kind => 'vrf', id => 'red', v2c => '%s::1',
        v3 => 'vrf1'}],
    }), 'red, its I-SID and its context');
  cmp_deeply([map { $instances->{$_}{l3_isid} } qw/blue green grey/],
    [30002, 30003, 30004], q(blue, green and grey I-SIDs));
  cmp_deeply($instances->{grey}{sources},
    {list => q(RAPID-CITY), l3_isid => q(RAPID-CITY)},
    q(grey: an I-SID and no VLAN));
  cmp_deeply($instances->{MgmtRouter}, superhashof({kind => 'vrf',
      l3_isid => undef, sources => {list => 'RAPID-CITY'}}),
    'MgmtRouter is listed as a VRF');
  is($instances->{default}{kind}, 'default', 'default is the global table');
  ok(!exists $instances->{GlobalRouter}, 'No GlobalRouter row');
}

sub vrf_instances_complete__voss__is_1 : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  is($info->vrf_instances_complete(), 1, 'A whole list is complete');
}

sub vrf_instances_complete__voss_partial_walk__is_0 : Tests(2) {
  my $test = shift;

  foreach my $method (qw/vrf_rc_name vrf_rc_vlan_vrf/) {
    my $info = _use_cache($test, _voss_default_cache());
    $info->{walk_status}{$method} = {complete => 0, reason => 'timeout'};
    is($info->vrf_instances_complete(), 0, "A partial $method walk is not");
  }
}

sub i_vrf__voss_default_context : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  cmp_deeply(scalar $info->i_vrf(),
    {2089 => 'red', 2090 => 'blue', 2091 => 'red', 2092 => 'blue',
      2093 => 'green'},
    'Every VRF VLAN; GlobalRouter VLANs and the CLIP are default');
  is($info->error(), undef, 'No error');
}

sub i_vrf__voss_red_context : Tests(3) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_vr($info, 'vrf1');
  cmp_deeply(scalar $info->i_vrf(), {2089 => 'red', 2091 => 'red'},
    'red\'s VLANs; the fabric interface of a learned route is not red\'s');
  is($info->error(), undef, 'No error');
  is($info->{_vrf_walked}{red}{vrf_cidr_proto}, 1,
    'The route protocol walk counts toward the read');
}

sub i_vrf__voss_grey_context__loopback : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_grey_cache());

  _enter_vr($info, 'vrf4');
  cmp_deeply(scalar $info->i_vrf(), {1345 => 'grey'},
    'grey\'s loopback, which has no VLAN');

  my $cache = _voss_grey_cache();
  $cache->{store}{vrf_rc_ip_vrf} = {};
  $info = _use_cache($test, $cache);
  _enter_vr($info, 'vrf4');
  cmp_deeply(scalar $info->i_vrf(), {1345 => 'grey'},
    '... a member by its connected route alone');
}

sub i_vrf__voss_green_context__vlan_only : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _voss_green_cache());

  _enter_vr($info, 'vrf3');
  cmp_deeply(scalar $info->i_vrf(), {2093 => 'green'},
    'green\'s VLAN, with no IPv4 route');
}


sub vrf_neighbors__voss_red_context : Tests(3) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_vr($info, 'vrf1');
  my $rows = $info->vrf_neighbors('red');
  cmp_deeply(_address_list($rows),
    [sort '2089 10.100.1.10', '2091 10.101.1.10',
      '2089 ' . _v6('2001:db8:1001:0:0:0:0:16')],
    'The hosts only: not the own rows, nor the broadcast ones');
  cmp_deeply($rows->{'2089.10.100.1.10'},
    {ifindex => 2089, ip => '10.100.1.10', mac => '02:00:00:00:00:0a',
      family => 'ipv4'}, 'A host row');
  is(scalar(grep { $_->{family} eq 'ipv6' } values %$rows), 1,
    'The IPv6 host, from IPV6-MIB');
}

# A VRF context that serves no rcVrfConfigTable row for its own VRF:
# the reader cannot confirm the context, and says how to check
sub vrf_neighbors__voss_context_without_own_row__error : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_cache([]));

  _enter_vr($info, 'vrf512');
  is($info->vrf_neighbors('MgmtRouter'), undef, 'No rows');
  like($info->error(),
    qr/cannot confirm that context 'vrf512' belongs to instance 'MgmtRouter'/,
    'The error names the unconfirmed context');
}

sub vrf_addresses__voss_red_context : Tests(3) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_vr($info, 'vrf1');
  my $rows = $info->vrf_addresses('red');
  cmp_deeply(_address_list($rows),
    [sort '2089 10.100.1.1', '2091 10.101.1.1',
      '2089 ' . _v6('2001:db8:1001:0:0:0:0:1'),
      '2089 ' . _v6($VOSS_RED_LINK_LOCAL)],
    'IPv4 from rcIpAddrTable, IPv6 from ipv6AddrTable');
  cmp_deeply($rows->{'2089.10.100.1.1'},
    {ifindex => 2089, ip => '10.100.1.1', prefix_len => 24,
      family => 'ipv4'}, 'The prefix length of rcIpAdEntNetMask');
  is($rows->{'2089.' . _v6('2001:db8:1001:0:0:0:0:1')}{prefix_len}, 64,
    'The IPv6 prefix length');
}

sub vrf_addresses__voss_red_context_no_routes__from_rc_ip_addr_table
  : Tests(2) {
  my $test  = shift;
  my $cache = _voss_red_cache();
  delete @{$cache->{store}}{qw/vrf_cidr_if vrf_cidr_proto/};
  my $info = _use_cache($test, $cache);

  _enter_vr($info, 'vrf1');
  cmp_deeply([grep {/\./} @{_address_list($info->vrf_addresses('red'))}],
    ['2089 10.100.1.1', '2091 10.101.1.1'],
    'A route is no address source: rcIpAddrTable alone gives them');
  is($info->{_vrf_walked}{red}{vrf_rc_ip_mask}, 1,
    'The rcIpAdEntNetMask walk counts toward the read');
}

# Rows of another vrfid are not this VRF's, whatever the context serves
sub vrf_vendor_address_rows__voss_other_vrfid__dropped : Tests(1) {
  my $test  = shift;
  my $cache = _voss_red_cache();
  my $store = $cache->{store};
  $store->{vrf_rc_ip_vrf}{'2090.10.100.1.1'}  = 2;
  $store->{vrf_rc_ip_addr}{'2090.10.100.1.1'} = '10.100.1.1';
  $store->{vrf_rc_ip_mask}{'2090.10.100.1.1'} = '255.255.255.0';
  my $info = _use_cache($test, $cache);

  _enter_vr($info, 'vrf1');
  cmp_deeply(
    [sort grep {/\.\d+\.\d+\.\d+$/} keys %{
        $info->_vrf_vendor_address_rows('red')}],
    ['2089.10.100.1.1', '2091.10.101.1.1'], 'Only vrfid 1\'s rows');
}

sub vrf_addresses__voss_grey_context__loopback : Tests(4) {
  my $test = shift;
  my $info = _use_cache($test, _voss_grey_cache());

  _enter_vr($info, 'vrf4');
  cmp_deeply($info->vrf_addresses('grey'),
    {'1345.10.104.1.1' => {ifindex => 1345, ip => '10.104.1.1',
        prefix_len => 32, family => 'ipv4'}},
    'The loopback address, from rcIpAddrTable');
  cmp_deeply($info->vrf_neighbors('grey'), {},
    'The loopback\'s own ARP row is not a neighbor');
  cmp_deeply([keys %{$info->vrf_subnets('grey')}], ['10.104.1.1/32'],
    'Its subnet is the address; a learned host route is not grey\'s');

  my $cache = _voss_grey_cache();
  $cache->{store}{$_} = {} for qw/vrf_rc_ip_vrf vrf_rc_ip_addr vrf_rc_ip_mask/;
  $info = _use_cache($test, $cache);
  _enter_vr($info, 'vrf4');
  cmp_deeply($info->vrf_addresses('grey'), {},
    'With rcIpAddrTable empty, its connected route gives no address');
}

sub vrf_neighbors__voss_green_context__ipv6_only : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_green_cache());

  _enter_vr($info, 'vrf3');
  cmp_deeply(_address_list($info->vrf_neighbors('green')),
    ['2093 ' . _v6('2001:db8:1201:0:0:0:0:16')],
    'The IPv6 host on green\'s VLAN, from IPV6-MIB');
  cmp_deeply(_address_list($info->vrf_addresses('green')),
    [sort map { '2093 ' . _v6($_) } '2001:db8:1201:0:0:0:0:1',
      'fe80:0:0:0:0:ff:fe00:5'],
    'Its IPv6 addresses');
}

# A row in the standard index shape, with length octets
sub vrf_subnets__voss_standard_route_index__read_by_fallback : Tests(1) {
  my $test  = shift;
  my $cache = _voss_red_cache();
  my $iid   = '1.4.10.110.1.0.24.0.1.4.10.110.1.1';
  $cache->{store}{vrf_cidr_if}{$iid}    = 2089;
  $cache->{store}{vrf_cidr_proto}{$iid} = 'local';
  my $info = _use_cache($test, $cache);

  _enter_vr($info, 'vrf1');
  cmp_deeply($info->vrf_subnets('red')->{'10.110.1.0/24'},
    superhashof({ifindex => 2089, sources => ['route']}),
    'The standard parser reads a row the VOSS one rejects');
}

sub vrf_subnets__voss_overlap__each_vrf_its_own : Tests(6) {
  my $test = shift;

  my $info = _use_cache($test, _voss_red_cache());
  _enter_vr($info, 'vrf1');
  my $red = $info->vrf_subnets('red');
  cmp_deeply($red->{'10.100.1.0/24'},
    superhashof({ifindex => 2089, sources => ['address', 'route']}),
    'red\'s 10.100.1.0/24 is on red\'s VLAN');
  ok(!exists $red->{'10.100.3.0/24'}, 'A route learned over the fabric'
    . ' is not a subnet of red\'s');
  ok(exists $red->{'2001:0db8:1001:0000:0000:0000:0000:0000/64'},
    'red\'s IPv6 subnet, from its address');

  $info = _use_cache($test, _voss_blue_cache());
  _enter_vr($info, 'vrf2');
  my $blue = $info->vrf_subnets('blue');
  cmp_deeply($blue->{'10.100.1.0/24'},
    superhashof({ifindex => 2090, sources => ['address', 'route']}),
    'blue\'s 10.100.1.0/24 is on blue\'s VLAN');
  ok(exists $info->vrf_addresses('blue')->{'2090.10.100.1.1'},
    'blue holds the shared address on its own VLAN');
  cmp_deeply(_address_list($info->vrf_neighbors('blue')),
    ['2090 10.100.1.10', '2092 10.102.1.10'], 'blue\'s hosts');
}


# The default context's ipAddrTable lists every VRF's addresses, and
# MgmtRouter's on the out-of-band port 3, with no VRF, and 0.0.0.0 on the
# management VLAN's interface. GlobalRouter's are
# those on its ports, and the management CLIP's on ifIndex 1, whose host
# route sits on the management VLAN's interface.
sub _voss_default_ipadent_cache {
  my $cache = _voss_default_cache();
  my %ips = ('0.0.0.0' => 6138, '10.0.0.15' => 3, '10.100.1.1' => 2089,
    '10.101.1.1' => 2091,
    '10.102.1.1' => 2092, '10.104.1.1' => 1345, '10.254.0.13' => 1,
    '10.255.0.13' => 1344);
  $cache->{store}{old_ip_index} = {%ips};
  $cache->{store}{old_ip_netmask} = {map { $_ => '255.255.255.0' } keys %ips};
  $cache->{store}{old_ip_netmask}{$_} = '255.255.255.255'
    for qw/10.104.1.1 10.254.0.13 10.255.0.13/;
  $cache->{store}{old_ip_netmask}{'0.0.0.0'} = '0.0.0.0';
  $cache->{"_$_"} = 1 for qw/old_ip_index old_ip_netmask/;
  return $cache;
}

sub vrf_addresses__voss_default_context__globalrouter_only : Tests(5) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_ipadent_cache());

  my $rows = $info->vrf_addresses('default');
  cmp_deeply(_address_list($rows), ['1 10.254.0.13', '1344 10.255.0.13'],
    'GlobalRouter\'s CLIP and the management CLIP; 0.0.0.0 is none');
  ok(!exists $info->vrf_subnets('default')->{'0.0.0.0/0'},
    'No 0.0.0.0/0 subnet');
  cmp_deeply($rows->{'1.10.254.0.13'},
    {ifindex => 1, ip => '10.254.0.13', prefix_len => 32,
      family => 'ipv4'},
    '10.254.0.13 stays on ifIndex 1, not its route\'s interface');
  is($rows->{'1344.10.255.0.13'}{prefix_len}, 32,
    'The CLIP both tables serve is one row');

  $info = _use_cache($test, _voss_default_cache());
  cmp_deeply(_address_list($info->vrf_addresses('default')),
    ['1344 10.255.0.13'], 'Without ipAddrTable, rcIpAddrTable of vrfid 0');
}

sub vrf_instances_complete__voss_global_and_mgmt_routers_only__is_1
  : Tests(6) {
  my $test = shift;

  foreach my $vrfids ([0], [0, 512]) {
    my $label = join '+', map { $VOSS_VRF_NAMES{$_} } @$vrfids;
    my $info = _use_cache($test, _voss_cache($vrfids));
    is($info->vrf_instances_complete(), 1, "$label: read in full");
    is($info->vrf_instances()->{default}{sources}{list}, 'RAPID-CITY',
      "$label: rcVrfConfigTable lists default");
    ok(!exists $info->vrf_instances(['red'])->{red},
      "$label: caller names add nothing");
  }
}

# ipAddrTable serves 0.0.0.0 on an interface, and a connected route has
# the next hop 0.0.0.0: that interface is no port of the context
sub vrf_neighbors__voss_default_unspecified_next_hop__no_port : Tests(2) {
  my $test = shift;
  my $cache = _voss_default_ipadent_cache();
  my %routes = _voss_route_store(['10.9.0.0', 24, '0.0.0.0', 6141]);
  my %arp = _voss_neighbor_store(arp => [[6140, '10.9.0.5', 7],
      [6141, '10.9.0.6', 8]]);
  $cache->{store}{old_ip_index}{'0.0.0.0'} = 6140;
  foreach my $method (keys %routes, keys %arp) {
    my $rows = $routes{$method} || $arp{$method};
    $cache->{store}{$method} = {%{$cache->{store}{$method} || {}}, %$rows};
    $cache->{"_$method"} = 1;
  }
  my $info = _use_cache($test, $cache);

  my $rows = $info->vrf_neighbors('default');
  ok(exists $rows->{'6141.10.9.0.6'}, 'The route\'s interface is a port');
  ok(!exists $rows->{'6140.10.9.0.5'},
    'The interface holding 0.0.0.0 is not');
}

sub _enter_community {
  my ($info, $community) = @_;
  $info->{args}{Community}      = 'public';
  $info->session()->{Version}   = 2;
  $info->session()->{Community} = $community;
  return;
}

sub _vrf_community_context__voss_red_context__returns_vrf1 : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, 'public-red');
  is($info->_vrf_community_context(), 'vrf1',
    'The one row red\'s context serves names its context');
}

sub _vrf_community_context__voss_mgmt_context__returns_vrf512 : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _voss_cache([512], _voss_port_macs()));

  _enter_community($info, 'public-mgmt');
  is($info->_vrf_community_context(), 'vrf512',
    'The management router\'s row names vrf512');
}

sub _vrf_community_context__voss_default_context__returns_empty : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  _enter_community($info, 'public');
  is($info->_vrf_community_context(), q(),
    'The default context serves every row');
  is($info->_vrf_session_context(), q(), 'The session reads the default');
}

sub _vrf_community_context__voss_only_global_router__returns_empty : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _voss_cache([0]));

  _enter_community($info, 'public');
  is($info->_vrf_community_context(), q(), 'vrfid 0 alone is the default');
}

sub _vrf_community_context__voss_table_not_served__undef : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  $info->{store}{vrf_rc_context} = undef;
  _enter_community($info, 'public-red');
  is($info->_vrf_community_context(), undef, 'No rows are served');
  is($info->_vrf_session_context(), q(), 'The session reads the default');
}

sub _vrf_community_context__voss_v3__undef_without_walking : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_vr($info, 'vrf1');
  my $walks = 0;
  no warnings 'redefine';
  local *SNMP::Info::Layer3::VOSS::vrf_rc_context
    = sub { $walks++; return {} };
  is($info->_vrf_community_context(), undef, 'No answer over SNMPv3');
  is($walks, 0, 'The VRF table was not walked');
}

sub vrf_neighbors__voss_mapped_community_red__reads_red : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, 'public-red');
  my $rows = $info->vrf_neighbors('red');
  cmp_deeply(_address_list($rows),
    [sort '2089 10.100.1.10', '2091 10.101.1.10',
      '2089 ' . _v6('2001:db8:1001:0:0:0:0:16')],
    'The same hosts as over the SNMPv3 context');
  is($info->error(), undef, 'No error');
}

sub vrf_instances__voss_mapped_community__refused : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, 'public-red');
  is($info->vrf_instances(), undef, 'The list is refused over red');
  like($info->error(), qr/only the default context.*context 'vrf1'/s,
    'The error names the default context and the session\'s');
}

sub _vrf_community_context__voss_row_without_context__vrfid_marker
  : Tests(3) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  $info->{store}{vrf_rc_context} = {1 => q()};
  _enter_community($info, q(public-red));
  is($info->_vrf_community_context(), q(vrfid 1),
    q(A VRF row naming no context is not the default context));
  is($info->vrf_neighbors(q(default)), undef, q(default is refused there));
  is($info->vrf_instances(), undef, q(The list is refused there));
}

sub vrf_neighbors__voss_mapped_community_red__default_refused : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, q(public-red));
  is($info->vrf_neighbors(q(default)), undef, q(default is refused over red));
  like($info->error(), qr/default context.*context 'vrf1'/s,
    q(The error names the session's context));
}

sub _vrf_session_context__voss_colon_community__vrf1 : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, 'public::1');
  is($info->_vrf_session_context(), 'vrf1',
    'The one row the context serves names the context');
}

sub _vrf_session_context__voss_at_suffix__ignored : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  _enter_community($info, 'public@vrf1');
  is($info->_walk_context(), 'vrf1', 'The suffix parses as a context');
  is($info->_vrf_session_context(), q(),
    'The default context rows win over the suffix');
}

sub vrf_neighbors__voss_colon_community_red__reads_red : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, 'public::1');
  my $rows = $info->vrf_neighbors('red');
  cmp_deeply(_address_list($rows),
    [sort '2089 10.100.1.10', '2091 10.101.1.10',
      '2089 ' . _v6('2001:db8:1001:0:0:0:0:16')],
    'The same hosts as over the SNMPv3 context');
  is($info->error(), undef, 'No error');
}

sub vrf_instances__voss_colon_community__refused : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, 'public::1');
  is($info->vrf_instances(), undef, 'The list is refused over red');
  like($info->error(), qr/only the default context.*context 'vrf1'/s,
    'The error names the default context and the session\'s');
}

sub vrf_neighbors__voss_colon_community_red__default_refused : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, q(public::1));
  is($info->vrf_neighbors(q(default)), undef, q(default is refused over red));
  like($info->error(), qr/default context.*context 'vrf1'/s,
    q(The error names the session's context));
}

sub i_vrf__voss_colon_community_red__red_ports : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, q(public::1));
  cmp_deeply(scalar $info->i_vrf(), {2089 => 'red', 2091 => 'red'},
    q(red's VLANs, as over the SNMPv3 context));
  is($info->error(), undef, q(No error));
}

sub vrf_instances__no_rc_vrf_rows__default_only : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_cache([]));

  cmp_deeply([keys %{$info->vrf_instances()}], ['default'],
    'An empty rcVrfName gives exactly the default instance');
  is($info->error(), undef, 'No error');
}
