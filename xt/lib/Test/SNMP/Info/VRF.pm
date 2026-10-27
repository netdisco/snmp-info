# Test::SNMP::Info::VRF
#
# Copyright (c) 2026 Eric Miller
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


package Test::SNMP::Info::VRF;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::VRF;

# MPLS-L3VPN-STD-MIB mplsL3VpnVrfTable and mplsL3VpnVrfRTTable as an IOS-XE
# device serves them: the VRF name is a length-prefixed octet string index
my %NAME_IID = (
  red   => '3.114.101.100',
  blue  => '4.98.108.117.101',
  grey  => '4.103.114.101.121',
  green => '5.103.114.101.101.110',
);
my $DEFAULT_IID = '7.100.101.102.97.117.108.116';

sub _prime_vrf_table {
  my $test = shift;
  my %opt  = @_;

  my @iids = values %NAME_IID;
  push @iids, $DEFAULT_IID if $opt{with_default};
  my %served = map { $_ => 1 } @iids;

  my %rd = map { $_ => q{} } @iids;
  $rd{ $NAME_IID{red} } = $opt{red_rd} // '64512:30';

  $test->{info}{_vrf_l3vpn_rd}    = 1;
  $test->{info}{_vrf_l3vpn_descr} = 1;
  $test->{info}{_vrf_l3vpn_oper}  = 1;
  $test->{info}{_vrf_l3vpn_rt}    = 1;
  $test->{info}{store}{vrf_l3vpn_rd}    = \%rd;
  $test->{info}{store}{vrf_l3vpn_descr} = { map { $_ => q{} } keys %served };
  $test->{info}{store}{vrf_l3vpn_oper}  = { map { $_ => 'up' } keys %served };
  $test->{info}{store}{vrf_l3vpn_rt}    = {
    "$NAME_IID{red}.1.1"  => '64512:30',
    "$NAME_IID{red}.1.2"  => '64512:30',
    "$NAME_IID{red}.2.3"  => '64512:31',
  };
  return;
}

sub vrf_instances : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'vrf_instances');

  $test->_prime_vrf_table();
  my $instances = $test->{info}->vrf_instances();
  cmp_deeply([sort keys %$instances], [qw/blue default green grey red/],
    q(Every served VRF and the default instance are listed));
  cmp_deeply(
    $instances->{red},
    superhashof({
      name        => 'red',
      kind        => 'vrf',
      description => undef,
      oper        => 'up',
      rd          => '64512:30',
      listed_by   => 'device',
      contexts    => [{kind => 'none'}],
    }),
    q(A served VRF keeps its distinguisher and operational state)
  );
}

sub vrf_instances__served_table__lists_each_vrf_and_default : Tests(6) {
  my $test = shift;

  $test->_prime_vrf_table();
  my $instances = $test->{info}->vrf_instances();

  cmp_deeply([sort keys %$instances], [qw/blue default green grey red/],
    q(Keys are the served names plus default));
  is($instances->{default}{kind}, 'default', q(default has kind default));
  cmp_deeply($instances->{default}{contexts}, [{kind => 'none'}],
    q(default has one context of kind none));
  is($instances->{red}{rd}, '64512:30', q(red keeps its RD));
  is($instances->{blue}{rd}, undef, q(An empty RD is undef));
  cmp_deeply(
    $instances->{blue},
    superhashof({description => undef, listed_by => 'device'}),
    q(An empty description is undef and the device listed the VRF)
  );
}

sub vrf_instances__xr_default_row__is_not_a_second_instance : Tests(3) {
  my $test = shift;

  $test->_prime_vrf_table(with_default => 1);
  my $instances = $test->{info}->vrf_instances();

  is(scalar keys %$instances, 5, q(A served default row adds no instance));
  is($instances->{default}{kind}, 'default',
    q(The served default row keeps kind default));
  is($instances->{default}{name}, 'default', q(... and its name));
}

sub vrf_instances__route_targets__split_by_type : Tests(4) {
  my $test = shift;

  $test->_prime_vrf_table();
  my $instances = $test->{info}->vrf_instances();

  cmp_deeply($instances->{red}{rt_import}, ['64512:30', '64512:31'],
    q(Import targets include those typed both, sorted));
  cmp_deeply($instances->{red}{rt_export}, ['64512:30', '64512:31'],
    q(Export targets include those typed both, sorted));
  cmp_deeply($instances->{blue}{rt_import}, [],
    q(A VRF with no targets has an empty import list));
  cmp_deeply($instances->{blue}{rt_export}, [], q(... and export list));
}

sub vrf_instances__rd_sentinel__is_undef : Tests(2) {
  my $test = shift;

  $test->_prime_vrf_table(red_rd => '0:0');
  is($test->{info}->vrf_instances()->{red}{rd}, undef,
    q(The 0:0 sentinel is no distinguisher));

  is($test->{info}->_vrf_rd("\x00\x01\xfc\x00\x00\x00\x00\x1e"),
    '00:01:fc:00:00:00:00:1e', q(A binary RD is colon hex));
}

sub vrf_instances__caller_names__are_marked_as_caller : Tests(4) {
  my $test = shift;

  $test->_prime_vrf_table();
  my $instances = $test->{info}->vrf_instances(['red', 'orange']);

  is($instances->{red}{listed_by}, 'device',
    q(A name the device served stays device-listed));
  is($instances->{orange}{listed_by}, 'caller',
    q(An unserved caller name is marked caller));
  is($instances->{orange}{kind}, 'vrf', q(... and is a vrf));
  ok(!exists $test->{info}{_vrf_instances},
    q(Caller names are never memoized));
}

sub vrf_instances__in_a_context__throws_naming_default_context : Tests(2) {
  my $test = shift;

  $test->_prime_vrf_table();
  $test->{info}{args}{Community} = 'public';
  $test->{info}->session()->{Community} = 'public@red';

  is($test->{info}->vrf_instances(), undef,
    q(Refused in a community context));
  like($test->{info}->error(), qr/only the default context/,
    q(Error names the default context));
}

sub decode_name__length_prefixed__returns_name_and_rest : Tests(4) {
  my $test = shift;

  cmp_deeply([$test->{info}->_vrf_decode_name('3.114.101.100.7')],
    ['red', 7], q(Name then the remaining arcs));
  cmp_deeply([$test->{info}->_vrf_decode_name('3.114.101.100')],
    ['red'], q(A name with no remaining arcs));
  cmp_deeply([$test->{info}->_vrf_decode_name('9.114.101.100')],
    [], q(A length longer than the arcs returns nothing));
  cmp_deeply([$test->{info}->_vrf_decode_name('')],
    [], q(An empty index returns nothing));
}

sub vrf_private_defaults : Tests(3) {
  my $test = shift;

  is($test->{info}->_vrf_context_filters(), 0, q(No context filtering));
  is($test->{info}->_vrf_internal_instance('red'), 0,
    q(No instance is internal in the base role));
  ok(defined &SNMP::Info::VRF::_vrf_default_context_ok,
    q(The default context guard is defined));
}

1;
