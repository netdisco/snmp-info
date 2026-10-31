# Test::SNMP::Info::Layer3::ArubaCX
#
# Copyright (c) 2026 SNMP::Info Developers
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

package Test::SNMP::Info::Layer3::ArubaCX;

use Test::Class::Most parent => 'My::Test::Class';
use SNMP::Info::Layer3::ArubaCX;
use JSON::PP;

sub startup : Tests(startup => 1) {
  my $test = shift;
  $test->SUPER::startup;
  $test->todo_methods(1);
}

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;
  open my $fh, '<', 'xt/fixtures/arubacx-cipt.json' or die $!;
  my $fixture = decode_json(do { local $/; <$fh> });
  close $fh;
  my %store = (cipt_addr_type => {}, cipt_addr => {}, cipt_ifindex => {});
  while (my ($idx, $row) = each %{$fixture->{rows}}) {
    $store{cipt_addr_type}{$idx} = $row->{type};
    $store{cipt_addr}{$idx} = pack('H*', $row->{addr_hex});
    $store{cipt_ifindex}{$idx} = $row->{port};
  }
  $test->{native6} = '99.2.16.32.1.13.184.' . join('.', (0) x 11, 200);
  $store{ip_n2p_phys_addr} = {$test->{native6} => pack('C6', 2,0,0,0,1,200)};
  $store{at_paddr} = {'99.192.0.2.200' => pack('C6', 2,0,0,0,1,200)};
  $store{at_netaddr} = {'99.192.0.2.200' => '192.0.2.200'};
  $test->{info}->cache({
    '_layers' => 78,
    '_id' => '.1.3.6.1.4.1.47196.4.1.1.1.309',
    '_description' => 'Aruba JL728B 6200F',
    (map { ('_' . $_) => 1 } keys %store),
    store => \%store,
  });
}

sub mac : Tests(4) {
  my $test = shift;
  my $info = $test->{info};
  $info->{_b_mac} = pack('H*', '8C85C162C740');
  $info->{_mac}   = pack('H*', '8C85C162C77F');

  can_ok($info, 'mac');
  is($info->mac(), '8c:85:c1:62:c7:40',
    q(mac__bridge_address_present__returns_bridge_mac));

  $info->{_b_mac} = pack('H*', '000000000000');
  is($info->mac(), '8c:85:c1:62:c7:7f',
    q(mac__bridge_address_zero__returns_first_interface_mac));

  delete $info->{_b_mac};
  is($info->mac(), '8c:85:c1:62:c7:7f',
    q(mac__bridge_address_missing__returns_first_interface_mac));
}

sub model : Tests(7) {
  my $test = shift;
  my $info = $test->{info};
  my $models = {1=>'JL719C',12001=>'JL719C',13001=>'JL601A'};
  my $translated = 'arubaWiredSwitchJL719C';
  my $stack;
  no warnings 'redefine';
  local *SNMP::Info::Layer3::ArubaCX::entPhysicalModelName = sub { return $models };
  local *SNMP::Info::Layer3::ArubaCX::id = sub { return '.1.3.6.1.4.1.47196.4.1.1.1.422' };
  local *SNMP::Info::Layer3::ArubaCX::stack_info = sub { return $stack };
  local *SNMP::translateObj = sub { return $translated };
  is($info->model, '8360-48Y6C v2', 'Reported root product code translated');
  $models = {1=>'8360-48Y6C v2'};
  is($info->model, '8360-48Y6C v2', 'Readable device model preserved');
  $models = {1=>'JL999C'};
  is($info->model, 'JL999C', 'Unknown root model preserved over known OID');
  $models = {1=>'',13001=>'JL601A'};
  is($info->model, '8360-48Y6C v2', 'Known product OID fallback translated');
  $translated = 'arubaWiredSwitchJL999C';
  is($info->model, 'JL999C', 'Unknown product OID name preserved');
  $translated = undef;
  is($info->model, '.1.3.6.1.4.1.47196.4.1.1.1.422', 'Untranslated OID preserved');
  $models = {1=>'JL719C'};
  $stack = '6200F (stack of 2)';
  is($info->model, $stack, 'Existing stack result retains precedence');
}

sub at_paddr : Tests(4) {
  my $test = shift;
  my $data = $test->{info}->at_paddr;
  is(scalar keys %$data, 37, '36 tracked IPv4 rows plus native ARP');
  is($data->{'99.192.0.2.200'}, '02:00:00:00:01:c8', 'Native ARP MAC preserved');
  is($data->{'cipt.6.2.0.0.0.0.1.1.1'}, '02:00:00:00:00:01', 'MAC decoded from index');
  cmp_deeply([sort keys %$data], [sort keys %{$test->{info}->at_netaddr}], 'IPv4 MAC/IP row keys match');
}

sub at_netaddr : Tests(3) {
  my $test = shift;
  my $data = $test->{info}->at_netaddr;
  is($data->{'99.192.0.2.200'}, '192.0.2.200', 'Native ARP IP preserved');
  is($data->{'cipt.6.2.0.0.0.0.1.1.1'}, '192.0.2.1', 'Binary IPv4 decoded');
  cmp_deeply($test->{info}->at_netaddr('cipt.6.2.0.0.0.0.1.1.1'),
    {'cipt.6.2.0.0.0.0.1.1.1' => '192.0.2.1'}, 'Partial query selects tracking row');
}

sub ipv6_n2p_mac : Tests(3) {
  my $test = shift;
  my $data = $test->{info}->ipv6_n2p_mac;
  is(scalar keys %$data, 16, '15 tracked IPv6 rows plus native neighbour');
  is($data->{$test->{native6}}, '02:00:00:00:01:c8', 'Native IPv6 MAC preserved');
  cmp_deeply([sort keys %$data], [sort keys %{$test->{info}->ipv6_n2p_addr}], 'IPv6 MAC/IP row keys match');
}

sub ipv6_n2p_addr : Tests(2) {
  my $test = shift;
  my $data = $test->{info}->ipv6_n2p_addr;
  is($data->{$test->{native6}}, '2001:0db8:0000:0000:0000:0000:0000:00c8', 'Native IPv6 IP preserved');
  my @tracked = grep { /^cipt\./ } keys %$data;
  ok(!grep({ $data->{$_} !~ /^2001:db8:0:0:0:0:0:[0-9a-f]+$/ } @tracked), 'All binary IPv6 addresses decoded');
}

sub ipv6_n2p_if : Tests(2) {
  my $test = shift;
  my $data = $test->{info}->ipv6_n2p_if;
  is($data->{$test->{native6}}, 99, 'Native neighbour interface preserved');
  cmp_deeply([sort keys %$data], [sort keys %{$test->{info}->ipv6_n2p_addr}], 'IPv6 interface/IP row keys match');
}

sub multiple_addresses : Tests(1) {
  my $test = shift;
  my $clients = $test->{info}->_cipt_clients(1);
  my %groups;
  for my $row (keys %$clients) {
    (my $group = $row) =~ s/\.\d+$//;
    push @{$groups{$group}}, $clients->{$row}{addr};
  }
  ok(grep({ scalar @$_ > 1 } values %groups),
    'Multiple IPv4 addresses for the same MAC/VLAN are retained');
}

sub invalid_indexes : Tests(1) {
  my $test = shift;
  my $info = $test->{info};
  subtest 'Invalid client indexes and ports' => sub {
    for my $idx ('6.256.0.0.0.0.1.1.1', '6.3.0.0.0.0.1.1.1',
                 '6.0.0.0.0.0.0.1.1', '6.2.0.0.0.0.1.0.1',
                 '6.2.0.0.0.0.1.4095.1', '6.2.0.0.0.0.1.1.0') {
      $info->{store}{cipt_addr_type}{$idx} = 1;
      $info->{store}{cipt_addr}{$idx} = pack('C4',192,0,2,99);
      $info->{store}{cipt_ifindex}{$idx} = 1;
      ok(!exists $info->at_netaddr->{'cipt.' . $idx}, "Invalid row $idx omitted");
    }
    my $idx = '6.2.0.0.0.0.1.1.1';
    for my $port (0, -1, 'invalid') {
      $info->{store}{cipt_ifindex}{$idx} = $port;
      ok(!exists $info->at_netaddr->{'cipt.' . $idx}, "Invalid port $port omitted");
    }
    done_testing;
  };
}

sub tracking_edge_cases : Tests(8) {
  my $test = shift;
  my $info = $test->{info};
  my $idx = '6.2.0.0.0.0.1.1.1';
  $info->{store}{cipt_addr_type}{$idx} = 'ipv4';
  is($info->at_netaddr->{'cipt.' . $idx}, '192.0.2.1', 'Address type enum supported');
  $info->{store}{cipt_addr_type}{$idx} = 3;
  ok(!exists $info->at_netaddr->{'cipt.' . $idx}, 'Unsupported address type omitted');
  $info->{store}{cipt_addr_type}{$idx} = 1;
  $info->{store}{cipt_addr}{$idx} = 'broken';
  ok(!exists $info->at_paddr->{'cipt.' . $idx}, 'Invalid address length omits paired MAC');
  $info->{store}{cipt_addr}{$idx} = pack('C4', 192,0,2,1);
  delete $info->{store}{cipt_ifindex}{$idx};
  ok(!exists $info->at_netaddr->{'cipt.' . $idx}, 'Incomplete row omitted');
  $info->{store}{cipt_addr_type}{'invalid'} = 1;
  $info->{store}{cipt_addr}{'invalid'} = pack('C4',192,0,2,2);
  $info->{store}{cipt_ifindex}{'invalid'} = 1;
  ok(!exists $info->at_netaddr->{'cipt.invalid'}, 'Malformed index omitted');
  $info->{store}{cipt_addr_type} = {};
  is(scalar keys %{$info->at_paddr}, 1, 'Empty tracking preserves native ARP');
  is(scalar keys %{$info->ipv6_n2p_mac}, 1, 'Empty tracking preserves IPv6 neighbours');
  $info->clear_cache;
  cmp_deeply($info->at_netaddr, {}, 'Unsupported tables yield no invented addresses');
}

sub _prime_xcvr {
  my $test = shift;
  my $info = $test->{info};
  my %ent = (
    1      => ['Stack',    'stack',   0,      'Stack'],
    101001 => ['Chassis',  'chassis', 1,      '6300M Chassis'],
    120010 => ['1/1/1',    'port',    101001, 'Switch Port'],
    120020 => ['1/1/2',    'port',    101001, 'Switch Port'],
  );
  my %store = (
    pm_xcvr_port    => {1 => '1/1/1', 27 => '1/1/27'},
    pm_xcvr_descr   => {1 => '10G SFP+ LC SR', 27 => '1G SFP LC LX'},
    pm_xcvr_product => {1 => 'J9150D', 27 => 'J4859D'},
    pm_xcvr_serial  => {1 => 'TEST0000001', 27 => 'TEST0000027'},
    pm_xcvr_type    => {1 => '10G-SR', 27 => '1G-LX'},
  );
  foreach my $idx (keys %ent) {
    my ($name, $class, $parent, $descr) = @{$ent{$idx}};
    $store{entPhysicalDescr}{$idx} = $descr;
    $store{e_descr}{$idx}  = $descr;
    $store{e_name}{$idx}   = $name;
    $store{e_class}{$idx}  = $class;
    $store{e_parent}{$idx} = $parent;
    $store{e_model}{$idx}  = $class eq 'chassis' ? 'JL660A' : '';
    $store{e_serial}{$idx} = $class eq 'chassis' ? 'TESTCHASSIS' : '';
    $store{e_type}{$idx}   = 'zeroDotZero';
    $store{e_fru}{$idx}    = $class eq 'chassis' ? 'true' : 'false';
  }
  $info->{"_$_"} = 1 for keys %store;
  $info->{store}{$_} = $store{$_} for keys %store;
  return;
}

sub _xcvr_rows {
  my ($test, $method) = @_;
  my $data = $test->{info}->$method() || {};
  return {map { $_ => $data->{$_} } grep { $_ >= 1_000_000_000 } keys %$data};
}

sub e_index : Tests(3) {
  my $test = shift;
  $test->_prime_xcvr;
  my $e_index = $test->{info}->e_index;
  is(scalar keys %$e_index, 6, 'Four real entities plus two transceivers');
  is($e_index->{1_000_000_001}, 1_000_000_001, 'Synthetic index value');
  is($e_index->{120010}, 120010, 'Real entity index unchanged');
}

sub e_class : Tests(2) {
  my $test = shift;
  $test->_prime_xcvr;
  cmp_deeply($test->_xcvr_rows('e_class'),
    {1_000_000_001 => 'module', 1_000_000_027 => 'module'},
    'Transceivers are modules');
  is($test->{info}->e_class->{120010}, 'port', 'Real class unchanged');
}

sub e_descr : Tests(1) {
  my $test = shift;
  $test->_prime_xcvr;
  cmp_deeply($test->_xcvr_rows('e_descr'),
    {1_000_000_001 => '10G SFP+ LC SR', 1_000_000_027 => '1G SFP LC LX'},
    'Transceiver descriptions');
}

sub e_name : Tests(1) {
  my $test = shift;
  $test->_prime_xcvr;
  cmp_deeply($test->_xcvr_rows('e_name'),
    {1_000_000_001 => 'Transceiver 1/1/1',
     1_000_000_027 => 'Transceiver 1/1/27'},
    'Transceiver names carry the port');
}

sub e_model : Tests(1) {
  my $test = shift;
  $test->_prime_xcvr;
  cmp_deeply($test->_xcvr_rows('e_model'),
    {1_000_000_001 => 'J9150D', 1_000_000_027 => 'J4859D'},
    'Transceiver product numbers');
}

sub e_serial : Tests(1) {
  my $test = shift;
  $test->_prime_xcvr;
  cmp_deeply($test->_xcvr_rows('e_serial'),
    {1_000_000_001 => 'TEST0000001', 1_000_000_027 => 'TEST0000027'},
    'Transceiver serial numbers');
}

sub e_type : Tests(1) {
  my $test = shift;
  $test->_prime_xcvr;
  cmp_deeply($test->_xcvr_rows('e_type'),
    {1_000_000_001 => '10G-SR', 1_000_000_027 => '1G-LX'},
    'Transceiver types');
}

sub e_fru : Tests(1) {
  my $test = shift;
  $test->_prime_xcvr;
  cmp_deeply($test->_xcvr_rows('e_fru'),
    {1_000_000_001 => 'true', 1_000_000_027 => 'true'},
    'Transceivers are field replaceable');
}

sub e_parent : Tests(3) {
  my $test = shift;
  $test->_prime_xcvr;
  my $e_parent = $test->{info}->e_parent;
  is($e_parent->{1_000_000_001}, 120010, 'Parented to matching port');
  is($e_parent->{1_000_000_027}, 101001, 'No port entity: chassis');
  is($e_parent->{120010}, 101001, 'Real parent unchanged');
}

sub xcvr_no_entities : Tests(2) {
  my $test = shift;
  $test->_prime_xcvr;
  my $info = $test->{info};
  $info->{store}{$_} = {} for qw/entPhysicalDescr e_class e_name e_parent/;
  is(scalar keys %{$info->e_index}, 2, 'Transceivers without ENTITY-MIB');
  is($info->e_parent->{1_000_000_001}, 0, 'Root parent without chassis');
}

sub xcvr_index_collision : Tests(3) {
  my $test = shift;
  $test->_prime_xcvr;
  my $info = $test->{info};
  $info->{store}{entPhysicalDescr}{1_000_000_027} = 'Real entity';
  $info->{store}{e_descr}{1_000_000_027} = 'Real entity';
  is($info->e_index->{1_000_000_027}, 1_000_000_027, 'Real index kept');
  is($info->e_descr->{1_000_000_027}, 'Real entity', 'Real row wins');
  ok(!exists $info->e_model->{1_000_000_027}, 'Colliding transceiver skipped');
}

sub xcvr_empty_table : Tests(2) {
  my $test = shift;
  $test->_prime_xcvr;
  my $info = $test->{info};
  $info->{store}{$_} = {} for grep {/^pm_xcvr_/} keys %{$info->{store}};
  cmp_deeply($info->e_descr, $info->{store}{e_descr}, 'Entity rows unchanged');
  is(scalar keys %{$info->e_index}, 4, 'No synthetic indexes');
}

sub xcvr_partial : Tests(2) {
  my $test = shift;
  $test->_prime_xcvr;
  my $info = $test->{info};
  $info->{sess}{Data} = {
    'ENTITY-MIB::entPhysicalDescr' => {120010 => 'Switch Port'},
  };
  cmp_deeply($info->e_descr(120010), {120010 => 'Switch Port'},
    'Partial fetch returns the real row only');
  cmp_deeply($info->e_index(120010), {120010 => 120010},
    'Partial e_index returns the real row only');
}

1;
