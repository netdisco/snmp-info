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

1;
