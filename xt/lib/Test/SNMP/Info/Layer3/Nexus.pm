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

# Shaped like the lab NX-OS recording: vPC domain 1, Po10 static
sub _prime_vpc {
  my ($test, %extra) = @_;

  $test->{info}->clear_cache();
  my %store = (
    vpc_role           => {1 => 'primary'},
    vpc_system_mac     => {1 => pack('H*', '002304eebe01')},
    vpc_keepalive_peer => {1 => pack('C4', 10, 0, 0, 2)},
    vpc_keepalive_stat => {1 => 'alive'},
    vpc_peer_link      => {1 => 369098752},
    vpc_host_link_if   => {'1.10' => 369098761, '1.20' => 369098771},
    vpc_host_link_stat => {'1.10' => 'up',      '1.20' => 'downStar'},
    pagpGroupIfIndex   => {369098500 => 369098761, 369098501 => 369098761},
    %extra,
  );
  $test->{info}->cache({
    (map { ('_' . $_) => 1 } keys %store),
    '_layers' => 70,
    store     => \%store,
  });
  return;
}

sub mlag_domains : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'mlag_domains');
  $test->_prime_vpc();
  cmp_deeply(
    $test->{info}->mlag_domains(),
    {
      1 => {
        kind       => 'vpc',
        system_mac => '00:23:04:ee:be:01',
        role       => 'primary',
        peer       => '10.0.0.2',
        peer_link  => 369098752,
        status     => 'alive',
        sources    => {
          system_mac => 'CISCO-VPC-MIB::cVpcSystemOperMacAddress',
          role       => 'CISCO-VPC-MIB::cVpcRoleStatus',
          peer       => 'CISCO-VPC-MIB::cVpcPeerKeepAliveDestAddr',
          peer_link  => 'CISCO-VPC-MIB::cVpcStatusPeerLinkIfIndex',
          status     => 'CISCO-VPC-MIB::cVpcPeerKeepAliveStatus',
        },
      }
    },
    'vPC domain 1 record'
  );
}

sub lag_groups__vpc_host_link__adds_mc : Tests(3) {
  my $test = shift;

  $test->_prime_vpc();
  my $groups = $test->{info}->lag_groups();
  cmp_deeply(
    $groups->{369098761}{mc},
    {kind => 'vpc', group => 10, domain => 1, state => 'up'},
    'Host link 10 gives mc'
  );
  is($groups->{369098761}{sources}{mc},
    'CISCO-VPC-MIB::cVpcStatusHostLinkIfIndex', '... and names its source');
  is($groups->{369098771}{mc}{state}, 'downStar',
    'A host link with no members still gets a record');
}

sub lag_groups__vpc_peer_link__marked : Tests(2) {
  my $test = shift;

  $test->_prime_vpc();
  my $groups = $test->{info}->lag_groups();
  is($groups->{369098752}{peer_link}, 1, 'Peer link channel marked');
  ok(!exists $groups->{369098761}{peer_link},
    'A host link is not marked as the peer link');
}

sub lag_groups__static_vpc__record_without_lacp : Tests(3) {
  my $test = shift;

  $test->_prime_vpc();
  my $record = $test->{info}->lag_groups()->{369098761};
  is($record->{lacp}, 0, 'Static vPC channel: lacp 0');
  is($record->{partner_system}, undef, '... with no partner');
  is($record->{mc}{group}, 10, '... and mc set');
}

sub agg_ports__nexus__unchanged : Tests(2) {
  my $test = shift;

  $test->_prime_vpc();
  my $expected = SNMP::Info::CiscoAgg::agg_ports($test->{info});
  cmp_deeply($test->{info}->agg_ports(), $expected,
    'agg_ports equals CiscoAgg agg_ports');
  cmp_deeply(
    $expected,
    {369098500 => 369098761, 369098501 => 369098761},
    '... and lists the static channel members'
  );
}

1;
