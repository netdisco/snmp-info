# Test::SNMP::Info::Layer3::Arista
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

package Test::SNMP::Info::Layer3::Arista;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Arista;

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
  my $d_string = 'Arista Networks EOS version 4.10.4 ';
  $d_string .= 'running on an Arista Networks DCS-7048T-A';
  my $cache_data = {
    '_layers' => 4,
    '_description' => $d_string,

    # ARISTA-PRODUCTS-MIB::aristaDCS7048TA
    '_id'   => '.1.3.6.1.4.1.30065.1.3011.7048.427.3648',
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'EOS', q(OS returns 'EOS'));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'arista', q(Vendor returns 'arista'));
}

sub model : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'DCS7048TA', q(Model is expected value));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '4.10.4', q(OS version is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef,
    q(No description returns undef OS version));
}

# EOS 4.36 cEOSLab with VRFs red, blue, green and grey. The default
# context lists them in aristaVrfTable and aristaVrfIfTable; each VRF
# context serves only its own addresses and neighbors. red (ports 1 and 3)
# and blue (ports 2 and 4) share 10.100.0.1/24 and 2001:db8:100::1/64.
my @VRF_ROWS = (
  [red => 1], [blue => 2], [red => 3], [blue => 4], [green => 5],
  [grey => 5000001],
);

sub _name_index {
  my $name = shift;
  return join('.', length $name, map { ord } split //, $name);
}

sub _v6_arcs {
  my $ip = shift;
  return join('.', unpack('C*', pack('n8', map { hex } split /:/, $ip)));
}

sub _mac { return pack('C6', 2, 0, 0, 0, 0, shift) }

sub _vrf_list_store {
  my %names = map { $_->[0] => 1 } @VRF_ROWS;
  return (
    vrf_arista_rd    => {map { _name_index($_) => 'INVALID' } keys %names},
    vrf_arista_state => {map { _name_index($_) => 'inactive' } keys %names},
    vrf_arista_if    => {map { $_->[1] => $_->[0] } @VRF_ROWS},
  );
}

sub _arista_cache {
  my %store = @_;
  my $d_string = 'Arista Networks EOS version 4.36.0F running on an ';
  $d_string .= 'Arista Networks cEOSLab';
  my $cache = {
    '_layers'      => 4,
    '_description' => $d_string,

    # ARISTA-PRODUCTS-MIB::aristaDCS7048TA
    '_id'   => '.1.3.6.1.4.1.30065.1.3011.7048.427.3648',
    'store' => {_vrf_list_store(), %store},
  };
  $cache->{"_$_"} = 1 for keys %{$cache->{store}};
  return $cache;
}

# ipAddressTable and ipAdEntTable rows: [ifIndex, address, prefix length]
sub _addresses {
  my (%index, %type, %prefix, %adent, %mask);
  foreach my $row (@_) {
    my ($port, $ip, $len) = @$row;
    my ($iid, $pointer);
    if ($ip =~ /:/) {
      my $arcs = _v6_arcs($ip);
      ($iid, $pointer) = ("2.16.$arcs", ".1.3.6.1.2.1.4.32.1.5.$port.2.16.$arcs.$len");
    }
    else {
      ($iid, $pointer) = ("1.4.$ip", ".1.3.6.1.2.1.4.32.1.5.$port.1.4.$ip.$len");
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

# A host's neighbor rows on one port: IPv4 and global IPv6
sub _neighbors {
  my @hosts = @_;
  my (%paddr, %netaddr, %n2p);
  foreach my $host (@hosts) {
    my ($port, $v4, $v6, $mac) = @$host;
    $paddr{"$port.$v4"}   = _mac($mac);
    $netaddr{"$port.$v4"} = $v4;
    $n2p{"$port.1.4.$v4"} = _mac($mac);
    $n2p{"$port.2.16." . _v6_arcs($v6)} = _mac($mac);
  }
  return (at_paddr => \%paddr, at_netaddr => \%netaddr,
    ip_n2p_phys_addr => \%n2p);
}

sub _red_cache {
  return _arista_cache(
    _addresses(
      [1, '10.100.0.1', 24], [3, '10.101.0.1', 24],
      [1, '2001:db8:100:0:0:0:0:1', 64], [3, '2001:db8:101:0:0:0:0:1', 64],
    ),
    _neighbors(
      [1, '10.100.0.2', '2001:db8:100:0:0:0:0:2', 1],
      [3, '10.101.0.2', '2001:db8:101:0:0:0:0:2', 3],
    ),
  );
}

sub _blue_cache {
  return _arista_cache(
    _addresses(
      [2, '10.100.0.1', 24], [4, '10.102.0.1', 24],
      [2, '2001:db8:100:0:0:0:0:1', 64],
    ),
    _neighbors([2, '10.100.0.2', '2001:db8:100:0:0:0:0:2', 2]),
  );
}

# Management0 (ifIndex 999000) is the only port the default context serves
sub _default_cache {
  return _arista_cache(
    _addresses([999000, '172.20.20.23', 24]),
    at_paddr   => {'999000.172.20.20.1' => _mac(9)},
    at_netaddr => {'999000.172.20.20.1' => '172.20.20.1'},
    ip_n2p_phys_addr => {'999000.1.4.172.20.20.1' => _mac(9)},
  );
}

sub _enter_context {
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

sub context_kinds__vrf__is_vrf : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  cmp_deeply($info->context_kinds('vrf'), ['vrf'], 'One context per VRF');
  is($info->context_kinds('stp'), undef, 'Other features have none');
}

sub snmp_context__vrf__cisco_order : Tests(1) {
  my $test = shift;

  cmp_deeply($test->{info}->snmp_context('vrf', 'red'),
    {kind => 'vrf', id => 'red', v2c => '%s@red', v3 => 'red'},
    'Community then @ then the VRF name');
}

sub snmp_context__vrf_default__nothing : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  is($info->snmp_context('vrf', 'default'), undef, 'default has none');
  is($info->snmp_context('vrf', q()), undef, 'An empty name has none');
}

sub vrf_instances : Tests(10) {
  my $test = shift;
  my $info = _use_cache($test, _default_cache());

  my $instances = $info->vrf_instances();
  cmp_deeply([sort keys %$instances], [qw/blue default green grey red/],
    'Each aristaVrfTable row, and default');
  foreach my $name (qw/red blue green grey/) {
    is($instances->{$name}{sources}{list}, 'ARISTA-VRF-MIB',
      "$name is listed by ARISTA-VRF-MIB");
  }
  is($instances->{red}{sources}{members}, 'ARISTA-VRF-MIB',
    'Membership is from aristaVrfIfTable');
  is($instances->{red}{oper}, undef, 'aristaVrfState is not an oper status');
  is($instances->{red}{rd}, undef, 'An INVALID route distinguisher is none');
  ok(!exists $instances->{red}{sources}{rd}, 'And has no rd source');
  is($instances->{red}{contexts}[0]{v2c}, '%s@red', 'Cisco-order community');
}

sub vrf_instances__route_distinguisher_set__rd_kept : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _default_cache());

  $info->{store}{vrf_arista_rd}{_name_index('red')} = '65000:1';
  my $red = $info->vrf_instances()->{red};
  is($red->{rd}, '65000:1', 'A real distinguisher is kept');
  is($red->{sources}{rd}, 'ARISTA-VRF-MIB', 'From ARISTA-VRF-MIB');
}

sub i_vrf : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _default_cache());

  cmp_deeply(scalar $info->i_vrf(),
    {1 => 'red', 3 => 'red', 2 => 'blue', 4 => 'blue', 5 => 'green',
      5000001 => 'grey'},
    'aristaVrfIfTable gives every VRF port in the default context');
}

sub i_vrf__red_context__own_ports : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _red_cache());

  _enter_context($info, 'red');
  cmp_deeply(scalar $info->i_vrf(), {1 => 'red', 3 => 'red'},
    'The ports holding an address in the red context');
}

sub vrf_instances_complete : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _default_cache());

  is($info->vrf_instances_complete(), 1, 'A whole list is complete');

  $info->{walk_status}{vrf_arista_state}
    = {complete => 0, reason => 'timeout'};
  is($info->vrf_instances_complete(), 0, 'A partial state walk is not');
}

sub vrf_neighbors__red_context__own_rows : Tests(4) {
  my $test = shift;
  my $info = _use_cache($test, _red_cache());

  _enter_context($info, 'red');
  my @rows = values %{$info->vrf_neighbors('red')};
  cmp_deeply([sort map { "$_->{ifindex} $_->{ip}" } @rows],
    [sort '1 10.100.0.2', '3 10.101.0.2',
      '1 2001:0db8:0100:0000:0000:0000:0000:0002',
      '3 2001:0db8:0101:0000:0000:0000:0000:0002'],
    'The hosts on ports 1 and 3, IPv4 and IPv6');
  is(scalar(grep { $_->{ip} =~ /^10\.10[01]\.0\.1$/ } @rows), 0,
    'No row of the router itself');
  is(scalar(grep { $_->{ifindex} == 999000 } @rows), 0,
    'None on Management0');
  is(scalar @rows, 4, 'Four rows');
}

sub vrf_neighbors__default_context__management_only : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _default_cache());

  cmp_deeply([map { "$_->{ifindex} $_->{ip}" }
      values %{$info->vrf_neighbors('default')}],
    ['999000 172.20.20.1'], 'Only the Management0 neighbor');
}

sub vrf_addresses__blue_context__shared_subnet : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _blue_cache());

  _enter_context($info, 'blue');
  my @shared = grep { $_->{ip} eq '10.100.0.1' }
    values %{$info->vrf_addresses('blue')};
  cmp_deeply([map { $_->{ifindex} } @shared], [2],
    'blue holds the shared address on port 2');
  ok(exists $info->vrf_subnets('blue')->{'10.100.0.0/24'},
    'And the shared subnet');
}

sub vrf_addresses__grey_context__loopback_no_neighbor : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test,
    _arista_cache(_addresses([5000001, '10.200.0.1', 32])));

  _enter_context($info, 'grey');
  cmp_deeply([map { $_->{ifindex} } values %{$info->vrf_addresses('grey')}],
    [5000001], 'The loopback address is in grey\'s context');
  cmp_deeply($info->vrf_neighbors('grey'), {}, 'It has no neighbor');
}

1;
