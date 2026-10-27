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
use SNMP::Info::Layer3;
use Sub::Util 'set_subname';
use Carp 'croak';

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

sub vrf_instances__context_kinds_vrf__records_carry_context : Tests(4) {
  my $test = shift;

  my $info = $test->_make_info(
    'Test::SNMP::Info::VRF::VrfContexts',
    ['SNMP::Info::VRF'],
    _context_kinds => sub { $_[1] eq 'vrf' ? ['vrf'] : () },
    _snmp_context  => sub {
      my ($self, $kind, $id) = @_;
      return if $id eq 'grey';
      return {kind => $kind, id => $id, v2c => undef, v3 => "ctx-$id"};
    });
  $test->{info} = $info;
  $test->_prime_vrf_table(with_default => 1);
  my $instances = $info->vrf_instances();
  cmp_deeply($instances->{red}{contexts},
    [{kind => 'vrf', id => 'red', v2c => undef, v3 => 'ctx-red'}],
    q(A VRF record carries the context of its name));
  cmp_deeply($instances->{grey}{contexts}, [],
    q(... or no context where the device answers none));
  cmp_deeply($instances->{default}{contexts}, [{kind => 'none'}],
    q(The default instance stays in the default context));
  my $with_caller = $info->vrf_instances([]);
  cmp_deeply($with_caller->{blue}{contexts},
    [{kind => 'vrf', id => 'blue', v2c => undef, v3 => 'ctx-blue'}],
    q(Every listed VRF is answered the same way));
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

sub _prime_members {
  my $test = shift;
  my %opt  = @_;

  $test->{info}{_vrf_configured} = $opt{configured} if exists $opt{configured};
  my %active = $opt{no_members} ? () : (
    '3.114.101.100.2'          => 'active',
    '3.114.101.100.4'          => 'active',
    '4.98.108.117.101.3'       => 'active',
    '4.98.108.117.101.5'       => 'active',
    '4.103.114.101.121.10'     => 'active',
    '5.103.114.101.101.110.6'  => 'active',
  );
  $test->{info}{_vrf_l3vpn_if} = 1;
  $test->{info}{store}{vrf_l3vpn_if} = \%active;
  return;
}

sub vrf_instances__caller_names_listing_device__ignored : Tests(3) {
  my $test = shift;

  $test->_prime_vrf_table();
  $test->_prime_members(configured => 4);
  my $instances = $test->{info}->vrf_instances(['red', 'orange']);

  is($instances->{red}{listed_by}, 'device',
    q(A name the device served stays device-listed));
  ok(!exists $instances->{orange}, q(A caller name is ignored));
  ok(exists $test->{info}{_vrf_instances},
    q(The device list is memoized));
}

sub vrf_instances__caller_names_unsupported_device__marked_caller : Tests(6) {
  my $test = shift;

  $test->{info}{_vrf_l3vpn_rd}  = 1;
  $test->{info}{_vrf_l3vpn_descr} = 1;
  $test->{info}{_vrf_l3vpn_oper}  = 1;
  $test->{info}{_vrf_l3vpn_rt}    = 1;
  $test->{info}{_vrf_l3vpn_if}    = 1;
  $test->{info}{store}{$_} = {} for
    qw/vrf_l3vpn_rd vrf_l3vpn_descr vrf_l3vpn_oper vrf_l3vpn_rt vrf_l3vpn_if/;

  cmp_deeply([keys %{$test->{info}->vrf_instances()}], ['default'],
    q(No names: default only, even after memoizing));
  my $instances = $test->{info}->vrf_instances(['vr-red']);
  is($instances->{'vr-red'}{listed_by}, 'caller', q(Marked caller));
  is($instances->{'vr-red'}{kind}, 'vrf', q(... a vrf));
  cmp_deeply($instances->{'vr-red'}{sources}, {}, q(... with no sources));
  is($test->{info}->vrf_instances_complete(['vr-red']), 0,
    q(A caller list is never complete));
  is($test->{info}->vrf_instances_complete(), undef,
    q(Without names the device is unsupported));
}

sub i_vrf : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_vrf');
  $test->_prime_vrf_table();
  $test->_prime_members();
  $test->{info}{store}{vrf_l3vpn_if}{'4.98.108.117.101.7'} = 'notInService';
  $test->{info}{store}{vrf_l3vpn_if}{'7.100.101.102.97.117.108.116.8'}
    = 'active';
  cmp_deeply(
    $test->{info}->i_vrf(),
    {2 => 'red', 4 => 'red', 3 => 'blue', 5 => 'blue', 10 => 'grey',
      6 => 'green'},
    q(Active rows map ifIndex to name; inactive and default rows do not)
  );
  $test->{info}->session()->{Community} = 'public@red';
  $test->{info}{args}{Community} = 'public';
  is($test->{info}->i_vrf(), undef, q(Refused in a context));
}

sub i_vrf__membership_rows__maps_ifindex_to_name : Tests(1) {
  my $test = shift;

  $test->_prime_members();
  cmp_deeply(
    $test->{info}->i_vrf(),
    {2 => 'red', 4 => 'red', 3 => 'blue', 5 => 'blue', 10 => 'grey',
      6 => 'green'},
    q(ifIndex maps to VRF name)
  );
}

sub vrf_instances__vendor_hook__used_only_without_mpls_rows : Tests(5) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::Vendor',
    ['SNMP::Info::VRF'],
    _vrf_context_filters => sub { 1 },
    _vrf_vendor_list_methods => sub { return ('vrf_l3vpn_descr') },
    _vrf_vendor_instances => sub {
      my $record = SNMP::Info::VRF::_vrf_record('amber', 'vrf', 'device');
      $record->{sources}{list} = 'VENDOR-MIB';
      return {amber => $record};
    });
  my $instances = $info->vrf_instances();
  cmp_deeply([sort keys %$instances], [qw/amber default/],
    q(Vendor list used without MPLS rows));
  is($instances->{amber}{sources}{list}, 'VENDOR-MIB', q(Vendor source));
  is($info->vrf_instances_complete(), 1,
    q(Context mode skips the split agent rule));

  $info->{walk_status}{vrf_l3vpn_descr} = {complete => 0, reason => 'x'};
  is($info->vrf_instances_complete(), 0, q(Vendor walk counted));
  $info->{walk_status} = {};

  $info->{_vrf_l3vpn_descr} = 1;
  $info->{store}{vrf_l3vpn_descr} = {$NAME_IID{red} => q()};
  delete $info->{_vrf_instances};
  $instances = $info->vrf_instances();
  cmp_deeply([sort keys %$instances], [qw/default red/],
    q(MPLS rows win over the vendor list));
}

sub vrf_instances_complete : Tests(1) {
  my $test = shift;

  can_ok($test->{info}, 'vrf_instances_complete');
}

sub vrf_instances_complete__served_and_mapped__is_1 : Tests(2) {
  my $test = shift;

  $test->_prime_vrf_table();
  $test->_prime_members(configured => 4);
  is($test->{info}->vrf_instances_complete(), 1, q(Complete));
  is($test->{info}->vrf_instances()->{red}{sources}{members},
    'MPLS-L3VPN-STD-MIB', q(Members are a recorded source));
}

sub vrf_instances_complete__no_mib__is_undef : Tests(2) {
  my $test = shift;

  $test->{info}{$_} = 1 for qw/_vrf_l3vpn_rd _vrf_l3vpn_descr
    _vrf_l3vpn_oper _vrf_l3vpn_rt _vrf_l3vpn_if/;
  $test->{info}{store}{$_} = {} for
    qw/vrf_l3vpn_rd vrf_l3vpn_descr vrf_l3vpn_oper vrf_l3vpn_rt vrf_l3vpn_if/;
  is($test->{info}->vrf_instances_complete(), undef, q(Unsupported));
  cmp_deeply([keys %{$test->{info}->vrf_instances()}], ['default'],
    q(Only default is listed));
}

sub vrf_instances_complete__configured_zero__is_1 : Tests(2) {
  my $test = shift;

  $test->{info}{$_} = 1 for qw/_vrf_l3vpn_rd _vrf_l3vpn_descr
    _vrf_l3vpn_oper _vrf_l3vpn_rt _vrf_l3vpn_if/;
  $test->{info}{store}{$_} = {} for
    qw/vrf_l3vpn_rd vrf_l3vpn_descr vrf_l3vpn_oper vrf_l3vpn_rt vrf_l3vpn_if/;
  $test->{info}{_vrf_configured} = 0;
  is($test->{info}->vrf_instances_complete(), 1, q(None configured));
  cmp_deeply([keys %{$test->{info}->vrf_instances()}], ['default'],
    q(Only default is listed));
}

sub vrf_instances_complete__fewer_rows_than_configured__is_0 : Tests(1) {
  my $test = shift;

  $test->_prime_vrf_table();
  $test->_prime_members(configured => 5);
  is($test->{info}->vrf_instances_complete(), 0, q(A row is missing));
}

sub vrf_instances_complete__no_membership_rows__is_0 : Tests(1) {
  my $test = shift;

  $test->_prime_vrf_table();
  $test->_prime_members(configured => 4, no_members => 1);
  is($test->{info}->vrf_instances_complete(), 0, q(Split agent));
}

sub vrf_instances_complete__unknown_count_and_unmapped_row__is_0 : Tests(2) {
  my $test = shift;

  $test->_prime_vrf_table();
  $test->_prime_members();
  $test->{info}{_vrf_configured} = undef;
  is($test->{info}->vrf_instances_complete(), 1,
    q(Unknown count, every row has a port));
  delete $test->{info}{store}{vrf_l3vpn_if}{$_}
    for qw/4.103.114.101.121.10/;
  delete $test->{info}{$_} for qw/_vrf_instances _vrf_members/;
  is($test->{info}->vrf_instances_complete(), 0,
    q(Unknown count, a row with no port));
}

sub vrf_instances_complete__known_count_portless_row__is_1 : Tests(1) {
  my $test = shift;

  $test->_prime_vrf_table();
  $test->_prime_members(configured => 4);
  delete $test->{info}{store}{vrf_l3vpn_if}{'4.103.114.101.121.10'};
  is($test->{info}->vrf_instances_complete(), 1,
    q(A VRF with no ports is allowed when others have them));
}

sub vrf_instances_complete__incomplete_walk__is_0 : Tests(3) {
  my $test = shift;

  foreach my $method (qw/vrf_l3vpn_rd vrf_l3vpn_if vrf_l3vpn_rt/) {
    $test->_prime_vrf_table();
    $test->_prime_members(configured => 4);
    delete $test->{info}{_vrf_instances};
    $test->{info}{walk_status}{$method}
      = {complete => 0, reason => 'timeout'};
    is($test->{info}->vrf_instances_complete(), 0,
      qq(An incomplete walk of $method));
    $test->{info}{walk_status} = {};
  }
}

sub vrf_instances_complete__xr_default_row__not_counted__is_1 : Tests(1) {
  my $test = shift;

  $test->_prime_vrf_table(with_default => 1);
  $test->_prime_members(configured => 4);
  is($test->{info}->vrf_instances_complete(), 1,
    q(The default row is not one of the configured VRFs));
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

sub vrf_private_defaults : Tests(8) {
  my $test = shift;

  is($test->{info}->_vrf_context_filters(), 0, q(No context filtering));
  cmp_deeply($test->{info}->_vrf_vendor_instances(), {}, q(No vendor list));
  cmp_deeply([$test->{info}->_vrf_vendor_list_methods()], [],
    q(No vendor list methods));
  is($test->{info}->_vrf_internal_instance('red'), 0,
    q(No instance is internal in the base role));
  ok(defined &SNMP::Info::VRF::_vrf_default_context_ok,
    q(The default context guard is defined));
  is($test->{info}->_vrf_default_context_leaks(), 0,
    q(The default context serves only its own rows));
  is($test->{info}->_vrf_nd_from_ipv6_mib(), 0,
    q(IPV6-MIB adds no neighbor rows));
  is($test->{info}->_vrf_context_is_instance_name(), 0,
    q(A context's instance comes from the list));
}

sub _vrf_session_context__walk_context_wins : Tests(1) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::CommunityHook',
    ['SNMP::Info::VRF'],
    _vrf_community_context => sub { 'blue' });
  $test->_enter_context($info);
  is($info->_vrf_session_context(), 'red',
    q(The community suffix beats the device's mapping));
}

sub _vrf_session_context__hook_undef__empty : Tests(2) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::NoHook',
    ['SNMP::Info::VRF'],
    _vrf_community_context => sub { return });
  is($info->_vrf_session_context(), q(), q(No answer is the default context));
  is($test->{info}->_vrf_session_context(), q(),
    q(The base role never maps a community));
}

my %BUILT_PACKAGE;

# Builds an object of a test-local package on the same mock session the
# base class uses. @ISA is the parent list as given; hashes merge in
# reverse @ISA order, the package's own entries last, so the first parent
# wins a shared key as AGENTS.md prescribes. A package is built once; a
# later call must ask for the same parents and the same sub names.
sub _make_info {
  my $test = shift;
  my ($package, $parents, %subs) = @_;

  my $shape = join(q(,), @$parents) . q(|) . join(q(,), sort keys %subs);
  croak "_make_info('$package') was already built with a different parent"
    . " list or set of subs ($BUILT_PACKAGE{$package}); use a new package"
    . " name for the new shape."
    if exists $BUILT_PACKAGE{$package} and $BUILT_PACKAGE{$package} ne $shape;

  if (!exists $BUILT_PACKAGE{$package}) {
    $BUILT_PACKAGE{$package} = $shape;
    no strict 'refs';
    @{"${package}::ISA"} = @$parents;
    foreach my $hash (qw/MIBS GLOBALS FUNCS MUNGE/) {
      %{"${package}::$hash"} = map { %{"${_}::$hash"} } reverse @$parents;
    }
    *{"${package}::$_"} = set_subname("${package}::$_", $subs{$_})
      for keys %subs;
  }

  return $package->new(
    'AutoSpecify' => 0,
    'BulkWalk'    => 0,
    'UseEnums'    => 1,
    'RetryNoSuch' => 1,
    'DestHost'    => '127.0.0.1',
    'Community'   => 'public',
    'Version'     => 2,
    'Session'     => $test->mock_session,
    'Debug'       => ($ENV{INFO_TRACE} || 0),
    'DebugSNMP'   => ($ENV{SNMP_TRACE} || 0),
  );
}

# Teardown in My::Test::Class restores the shared session's Community
sub _enter_context {
  my ($test, $info) = @_;

  $info->{args}{Community} = 'public';
  $info->session()->{Community} = 'public@red';
  return;
}

sub reader_context__attribution_in_vrf_context__throws : Tests(2) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::Reader',
    ['SNMP::Info::VRF'],
    probe_reader => sub { $_[0]->_vrf_in_reader_context('red') });
  $test->_enter_context($info);
  is($info->probe_reader(), 0, q(Refused in a context));
  like($info->error(),
    qr/^Test::SNMP::Info::VRF::Reader::probe_reader\(\) reads instance 'red' from the default context, attributing rows by port, on this device\. This session is in context 'red'\. Call update\(\) back to the default context first\./,
    q(Error names the reader, instance, context and the way back));
}

sub reader_context__attribution_default_context__ok : Tests(1) {
  my $test = shift;

  is($test->{info}->_vrf_in_reader_context('red'), 1,
    q(Allowed in the default context));
}

sub reader_context__context_mode_default_context_nondefault_name__throws
  : Tests(4) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::ContextMode',
    ['SNMP::Info::VRF'],
    _vrf_context_filters => sub { 1 },
    probe_reader         => sub { $_[0]->_vrf_in_reader_context($_[1]) });
  is($info->probe_reader('red'), 0,
    q(Refused for a named instance in the default context));
  like($info->error(),
    qr/^\S+\(\) reads instance 'red' from its own context.*snmp_context\('vrf', 'red'\)/s,
    q(Error names the instance and says how to switch));
  is($info->_vrf_in_reader_context('default'), 1,
    q(The default instance reads in the default context));

  $test->_enter_context($info);
  is($info->_vrf_in_reader_context('red'), 1,
    q(Allowed once in a context));
}

sub make_info__two_parents__first_parent_wins_shared_key : Tests(4) {
  my $test = shift;

  no strict 'refs';
  @{"Test::SNMP::Info::VRF::${_}::ISA"} = ('SNMP::Info') for qw/First Second/;
  %{'Test::SNMP::Info::VRF::First::FUNCS'}  = (shared => 'firstLeaf');
  %{'Test::SNMP::Info::VRF::Second::FUNCS'} = (shared => 'secondLeaf',
    only_second => 'otherLeaf');
  my $info = $test->_make_info('Test::SNMP::Info::VRF::TwoParents',
    ['Test::SNMP::Info::VRF::First', 'Test::SNMP::Info::VRF::Second']);
  is($info->funcs()->{shared}, 'firstLeaf',
    q(The first @ISA parent wins a shared key));
  is($info->funcs()->{only_second}, 'otherLeaf',
    q(... and the second parent still contributes its own keys));

  my $again = eval {
    $test->_make_info('Test::SNMP::Info::VRF::TwoParents',
      ['Test::SNMP::Info::VRF::Second'])
  };
  ok(!defined $again, q(A package is not rebuilt with another shape));
  like($@, qr/Test::SNMP::Info::VRF::TwoParents.*already built/s,
    q(... and the error names the package));
}

sub vrf_owner_of : Tests(4) {
  my $test = shift;

  $test->_prime_members();
  my $members = $test->{info}->i_vrf();
  is(SNMP::Info::VRF::_vrf_owner_of($members, 2), 'red',
    q(A member port maps to its VRF));
  is(SNMP::Info::VRF::_vrf_owner_of($members, 99), 'default',
    q(A port absent from i_vrf is in the default instance));

  $test->_enter_context($test->{info});
  is(SNMP::Info::VRF::_vrf_owner_of(scalar $test->{info}->i_vrf(), 2), undef,
    q(Unknown when i_vrf is refused in a context));
  ok(defined &SNMP::Info::VRF::_vrf_owner_of, q(Owner lookup is defined));
}

my @NEIGHBOR_PARENTS = ('SNMP::Info::VRF', 'SNMP::Info::Layer3');

# ipNetToMediaTable rows of an IOS-XE device: 10.40.0.1 is served on
# ifIndex 2 (red) and ifIndex 3 (blue). IPv6 comes from ipNetToPhysicalTable.
my $RED_V6 = '2.2.16.32.1.13.184.0.64.0.0.0.0.0.0.0.0.0.2';

sub _prime_neighbors {
  my $test = shift;
  my $info = shift;

  # The cache holds the raw octets; the munge turns them into text
  my %arp = map { $_->[0] => pack('C6', 2, 0, 0, 0, 0, $_->[1]) } (
    ['1.192.0.2.1' => 1],
    ['2.10.40.0.1'   => 2],
    ['2.10.40.0.2'   => 3],
    ['3.10.40.0.1'   => 4],
    ['3.10.40.0.2'   => 5],
    ['4.10.41.0.2'   => 6],
  );
  my %ips = map { my $ip = $_; $ip =~ s/^\d+\.//; ($_ => $ip) } keys %arp;
  $info->{_at_paddr}               = 1;
  $info->{_at_netaddr}             = 1;
  $info->{_ip_n2p_phys_addr}       = 1;
  $info->{store}{at_paddr}         = \%arp;
  $info->{store}{at_netaddr}       = \%ips;
  $info->{store}{ip_n2p_phys_addr} = {$RED_V6 => pack('C6', 2, 0, 0, 0, 0, 7)};
  return;
}

# ifPhysAddress as IOS-XE serves it: 10.40.0.1 is the device's own on
# ifIndex 2 and 3, at the port's MAC
sub _prime_port_macs {
  my $info = shift;

  $info->{_i_mac}       = 1;
  $info->{store}{i_mac} = {map { $_->[0] => pack('C6', 2, 0, 0, 0, 0, $_->[1]) }
      [1 => 8], [2 => 2], [3 => 4], [4 => 9]};
  return;
}

sub _neighbor_info {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::Neighbors',
    \@NEIGHBOR_PARENTS);
  $test->{info} = $info;
  $test->_prime_vrf_table();
  $test->_prime_members();
  $test->_prime_neighbors($info);
  return $info;
}

sub vrf_neighbors : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vrf_neighbors');
  my $info = $test->_neighbor_info();
  cmp_deeply(
    $info->vrf_neighbors('blue')->{'3.10.40.0.2'},
    {
      ifindex => 3,
      ip      => '10.40.0.2',
      mac     => '02:00:00:00:00:05',
      family  => 'ipv4',
    },
    q(A neighbor row holds its port, address, MAC and family)
  );
}

sub vrf_neighbors__overlapping_ip__each_vrf_keeps_its_row : Tests(4) {
  my $test = shift;

  my $info = $test->_neighbor_info();
  my $red  = $info->vrf_neighbors('red');
  my $blue = $info->vrf_neighbors('blue');
  cmp_deeply([grep { /^\d+\.10\.40/ } sort keys %$red],
    ['2.10.40.0.1', '2.10.40.0.2'], q(red holds its two rows on ifIndex 2));
  cmp_deeply([sort keys %$blue], ['3.10.40.0.1', '3.10.40.0.2'],
    q(blue holds its two rows on ifIndex 3));
  is($red->{'2.10.40.0.1'}{ip}, '10.40.0.1', q(red has 10.40.0.1));
  isnt($red->{'2.10.40.0.1'}{mac}, $blue->{'3.10.40.0.1'}{mac},
    q(... with a different MAC than blue's 10.40.0.1));
}

sub vrf_neighbors__unmapped_port__belongs_to_default : Tests(1) {
  my $test = shift;

  my $info = $test->_neighbor_info();
  cmp_deeply([sort keys %{$info->vrf_neighbors('default')}],
    ['1.192.0.2.1'], q(default holds the port i_vrf does not list));
}

sub vrf_neighbors__ipv6__attributed_by_ifindex : Tests(3) {
  my $test = shift;

  my $info = $test->_neighbor_info();
  cmp_deeply(
    $info->vrf_neighbors('red')->{$RED_V6},
    {
      ifindex => 2,
      ip      => '2001:0db8:0040:0000:0000:0000:0000:0002',
      mac     => '02:00:00:00:00:07',
      family  => 'ipv6',
    },
    q(red holds the IPv6 row, attributed by its ifIndex)
  );
  ok(!exists $info->vrf_neighbors('blue')->{$RED_V6},
    q(blue does not hold it));
  ok(!exists $info->vrf_neighbors('default')->{$RED_V6},
    q(default does not hold it));
}

sub vrf_neighbors__unknown_name__returns_nothing : Tests(1) {
  my $test = shift;

  my $info = $test->_neighbor_info();
  is(scalar $info->vrf_neighbors('purple'), undef,
    q(An instance the device does not list has no neighbors));
}

sub vrf_instances__caller_names_configured_zero__marked_caller : Tests(4) {
  my $test = shift;

  $test->{info}{$_} = 1 for qw/_vrf_l3vpn_rd _vrf_l3vpn_descr
    _vrf_l3vpn_oper _vrf_l3vpn_rt _vrf_l3vpn_if/;
  $test->{info}{store}{$_} = {} for
    qw/vrf_l3vpn_rd vrf_l3vpn_descr vrf_l3vpn_oper vrf_l3vpn_rt vrf_l3vpn_if/;
  $test->{info}{_vrf_configured} = 0;

  my $instances = $test->{info}->vrf_instances(['vr-red']);
  is($instances->{'vr-red'}{listed_by}, 'caller',
    q(A caller name is used when the device counts zero and serves no row));
  is($test->{info}->vrf_instances_complete(['vr-red']), 0,
    q(... and a list holding a caller name is never complete));
  is($test->{info}->vrf_instances_complete(), 1,
    q(Without names the device still reads none configured));
  ok(!exists $test->{info}->vrf_instances()->{'vr-red'},
    q(... and the caller name is not memoized));
}

sub vrf_instances__empty_served_name__is_default : Tests(4) {
  my $test = shift;

  $test->_prime_vrf_table();
  $test->_prime_members(configured => 4);
  $test->{info}{store}{vrf_l3vpn_oper}{'0'} = 'up';
  $test->{info}{store}{vrf_l3vpn_if}{'0.9'} = 'active';
  my $instances = $test->{info}->vrf_instances();

  ok(!exists $instances->{''}, q(An empty name is not an instance));
  is($instances->{default}{kind}, 'default',
    q(... it is the default instance));
  ok(!exists $test->{info}->i_vrf()->{9},
    q(A port of the empty name is a default port, absent from i_vrf));
  is($test->{info}->vrf_instances_complete(), 1,
    q(The empty-name row is not counted as a configured VRF));
}

sub vrf_instances__rd_and_rt__tagged_with_source : Tests(2) {
  my $test = shift;

  $test->_prime_vrf_table();
  $test->_prime_members(configured => 4);
  my $instances = $test->{info}->vrf_instances();
  cmp_deeply(
    $instances->{red}{sources},
    {
      list    => 'MPLS-L3VPN-STD-MIB',
      members => 'MPLS-L3VPN-STD-MIB',
      rd      => 'MPLS-L3VPN-STD-MIB',
      rt      => 'MPLS-L3VPN-STD-MIB',
    },
    q(A served RD and route targets are tagged with their MIB)
  );
  cmp_deeply(
    $instances->{blue}{sources},
    {list => 'MPLS-L3VPN-STD-MIB', members => 'MPLS-L3VPN-STD-MIB'},
    q(An empty RD and no targets add no tag)
  );
}

our $IF_READS = 0;

sub i_vrf__membership__decoded_once_until_cache_cleared : Tests(4) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::CountedMembers',
    \@NEIGHBOR_PARENTS,
    vrf_l3vpn_if => sub { $IF_READS++; $_[0]->orig_vrf_l3vpn_if() });
  $test->{info} = $info;
  $test->_prime_vrf_table();
  $test->_prime_members(configured => 4);
  $test->_prime_neighbors($info);

  local $IF_READS = 0;
  $info->vrf_instances_complete();
  my $red = $info->vrf_neighbors('red');
  $info->vrf_neighbors('blue');
  is(scalar keys %$red, 4, q(red still holds its rows));
  is($IF_READS, 1,
    q(The membership table is read once across the list and two readers));
  ok(exists $info->{_vrf_members}, q(Membership is memoized));
  $info->clear_cache();
  ok(!exists $info->{_vrf_members}, q(clear_cache drops the memo));
}

sub vrf_neighbors__unknown_name__sets_error : Tests(2) {
  my $test = shift;

  my $info = $test->_neighbor_info();
  is(scalar $info->vrf_neighbors('purple'), undef, q(No rows));
  like($info->error(),
    qr/^\S+vrf_neighbors\(\) reads instance 'purple', which is not in vrf_instances\(\)/,
    q(error() names the instance and says it is not listed));
}

# A row with no hardware address is no evidence of a host. Ports 2 and 4
# are red's, 3 and 5 blue's, 6 green's; each holds one IPv4 and one IPv6
# row.
my %RAW_MAC = (
  2 => undef,
  3 => q(),
  4 => '00:00:00:00:00:00',
  5 => '02:00:00:00:00:05',
  6 => '0000.0000.0000',
);
my $V6_ROW_ARCS = '32.1.13.184.0.64.0.0.0.0.0.0.0.0.0';

sub _raw_mac_rows {
  my $value = shift;
  return {map { ("$_.10.40.0.$_" => $value->($_)) } keys %RAW_MAC};
}

sub _raw_mac_v6_rows {
  my $value = shift;
  return {map { ("$_.2.16.$V6_ROW_ARCS.$_" => $value->($_)) } keys %RAW_MAC};
}

sub vrf_neighbors__zero_mac__dropped : Tests(4) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::RawMacs',
    \@NEIGHBOR_PARENTS,
    at_paddr      => sub { _raw_mac_rows(sub { $RAW_MAC{$_[0]} }) },
    at_netaddr    => sub { _raw_mac_rows(sub { "10.40.0.$_[0]" }) },
    ipv6_n2p_mac  => sub { _raw_mac_v6_rows(sub { $RAW_MAC{$_[0]} }) },
    ipv6_n2p_addr => sub {
      _raw_mac_v6_rows(sub { sprintf '2001:0db8:0040:0000:0000:0000:0000:%04x',
        $_[0] }) },
    ipv6_n2p_if   => sub { _raw_mac_v6_rows(sub { $_[0] }) },
  );
  $test->{info} = $info;
  $test->_prime_vrf_table();
  $test->_prime_members();

  cmp_deeply($info->vrf_neighbors('red'), {},
    q(Undef and all-zero MACs are dropped, IPv4 and IPv6));
  my $blue = $info->vrf_neighbors('blue');
  cmp_deeply([sort keys %$blue], ['5.10.40.0.5', "5.2.16.$V6_ROW_ARCS.5"],
    q(An empty MAC is dropped; a real one is kept));
  is($blue->{'5.10.40.0.5'}{mac}, '02:00:00:00:00:05', q(... with its MAC));
  cmp_deeply($info->vrf_neighbors('green'), {},
    q(A dotted all-zero MAC is dropped));
}

# A context's ARP table can serve the subnet broadcast address at the
# broadcast MAC, which names no neighbor
sub vrf_neighbors__broadcast_mac__dropped : Tests(3) {
  my $test = shift;

  my $info      = $test->_neighbor_info();
  my $broadcast = pack('C6', (0xff) x 6);
  $info->{store}{at_paddr}{'2.10.40.0.255'}   = $broadcast;
  $info->{store}{at_netaddr}{'2.10.40.0.255'} = '10.40.0.255';
  $info->{store}{ip_n2p_phys_addr}{$RED_V6}   = $broadcast;
  my $red = $info->vrf_neighbors('red');
  ok(!exists $red->{'2.10.40.0.255'}, q(The broadcast row is dropped));
  ok(!(grep { $_->{family} eq 'ipv6' } values %$red),
    q(... in IPv6 too));
  ok(exists $red->{'2.10.40.0.2'}, q(A host on the same port is kept));
}

sub vrf_neighbors__role_without_neighbor_methods__has_no_rows : Tests(1) {
  my $test = shift;

  $test->_prime_vrf_table();
  cmp_deeply($test->{info}->vrf_neighbors('default'), {},
    q(A class with no at_* or ipv6_n2p_* methods contributes no rows));
}

sub vrf_neighbors__context_mode__rows_on_context_address_ports : Tests(2) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::NeighborContext',
    \@NEIGHBOR_PARENTS, _vrf_context_filters => sub { 1 });
  $test->{info} = $info;
  $test->_prime_members();
  $test->_prime_neighbors($info);
  $test->_prime_addresses($info);
  delete $info->{store}{new_ip_index}{'1.4.10.41.0.1'};
  $test->_enter_context($info);
  my $rows = $info->vrf_neighbors('red');
  cmp_deeply([sort keys %$rows],
    [sort('1.192.0.2.1', '2.10.40.0.2', '3.10.40.0.2')],
    q(Rows on ports with an address in the context, whatever i_vrf says,)
      . q( less the addresses the context holds));
  is($rows->{'3.10.40.0.2'}{ifindex}, 3, q(... with its own ifIndex));
}

# IOS-XE serves its own ARP rows static at the port MAC. 10.40.0.1 is on
# ifIndex 2 (red) and 3 (blue), but ipAddressTable lists it on 3 only.
sub vrf_neighbors__collapsed_own_address__dropped_where_listed : Tests(3) {
  my $test = shift;

  my $info = $test->_address_info();
  $test->_prime_neighbors($info);
  _prime_port_macs($info);
  ok(!exists $info->vrf_neighbors('blue')->{'3.10.40.0.1'},
    q(blue holds 10.40.0.1, so its own row is dropped));
  ok(exists $info->vrf_neighbors('blue')->{'3.10.40.0.2'},
    q(... and its neighbor kept));
  ok(!exists $info->vrf_neighbors('red')->{'2.10.40.0.1'},
    q(red's copy is dropped too: it is at its port's MAC));
}

sub vrf_neighbors__row_at_own_port_mac__dropped : Tests(4) {
  my $test = shift;

  my $info = $test->_neighbor_info();
  _prime_port_macs($info);
  my $red = $info->vrf_neighbors('red');
  ok(!exists $red->{'2.10.40.0.1'},
    q(A row at its port's ifPhysAddress is the device's own));
  ok(exists $red->{'2.10.40.0.2'}, q(... a host on that port is kept));
  is($info->{_vrf_walked}{red}{i_mac}, 1,
    q(The ifPhysAddress walk counts toward the read));

  $info->{store}{at_paddr}{'4.10.41.0.2'} = pack('C6', 2, 0, 0, 0, 0, 2);
  ok(exists $info->vrf_neighbors('red')->{'4.10.41.0.2'},
    q(The MAC of another port is no match));
}

# EOS types its hosts' link-locals local(5) at the host's MAC
sub vrf_neighbors__local_type__kept : Tests(2) {
  my $test = shift;

  my $info = $test->_neighbor_info();
  my $red_v4 = '2.1.4.10.40.0.2';
  $info->{_ip_n2p_phys_type}       = 1;
  $info->{store}{ip_n2p_phys_type} = {$red_v4 => 'local', $RED_V6 => 5};
  my $red = $info->vrf_neighbors('red');
  ok(exists $red->{'2.10.40.0.2'}, q(An IPv4 row typed local is kept));
  ok(exists $red->{$RED_V6}, q(... and an IPv6 row typed local(5)));
}

sub i_vrf__context_mode__ports_with_context_addresses : Tests(3) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::NeighborContext',
    \@NEIGHBOR_PARENTS, _vrf_context_filters => sub { 1 });
  $test->{info} = $info;
  $test->_prime_vrf_table();
  $test->_prime_members();
  $test->_prime_addresses($info);
  cmp_deeply(scalar $info->i_vrf(), {map { $_ => 'default' } 1 .. 4},
    q(In the default context, its address ports are default));

  $test->_enter_context($info);
  cmp_deeply(scalar $info->i_vrf(), {map { $_ => 'red' } 1 .. 4},
    q(In red's context, its address ports are red, whatever members say));

  $info->session()->{Community} = 'public@vlan-1';
  is(scalar $info->i_vrf(), undef, q(Nothing in a context no VRF has));
}

sub i_vrf__context_ports_from_routes__hook : Tests(3) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::RoutePorts',
    \@NEIGHBOR_PARENTS,
    _vrf_context_filters           => sub { 1 },
    _vrf_context_ports_from_routes => sub { 1 });
  $test->{info} = $info;
  $test->_prime_vrf_table();
  $test->_prime_members();
  $test->_prime_addresses($info);
  $info->{_vrf_cidr_if} = 1;
  $info->{store}{vrf_cidr_if} = {'a' => 2, 'b' => 2, 'c' => 3, 'd' => 0};
  $test->_enter_context($info);
  cmp_deeply(scalar $info->i_vrf(), {2 => 'red', 3 => 'red'},
    q(The ports the routes use, not the ports holding an address));
  ok(exists $info->{_vrf_walked}{red}{vrf_cidr_if},
    q(The route walk counts toward the read));
  $info->{store}{vrf_cidr_if} = {};
  cmp_deeply(scalar $info->i_vrf(), {},
    q(A context with no route has no port));
}

sub vrf_neighbors__context_mode_other_context__throws : Tests(2) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::NeighborContext',
    \@NEIGHBOR_PARENTS, _vrf_context_filters => sub { 1 });
  $test->{info} = $info;
  $test->_prime_neighbors($info);
  $test->_enter_context($info);
  is(scalar $info->vrf_neighbors('blue'), undef, q(Refused in red's context));
  like($info->error(),
    qr/^\S+vrf_neighbors\(\) reads instance 'blue' from its own context, but this session is in context 'red'\. Switch with snmp_context\('vrf', 'blue'\) first\./,
    q(Error names both and the switch));
}

sub vrf_neighbors__attribution_in_vrf_context__throws : Tests(2) {
  my $test = shift;

  my $info = $test->_neighbor_info();
  $test->_enter_context($info);
  is(scalar $info->vrf_neighbors('red'), undef, q(Refused in a context));
  like($info->error(), qr/^\S+vrf_neighbors\(\) reads instance 'red'/,
    q(Error names the reader));
}

# ipAddressTable rows of an IOS-XE device. The ipv6z index is type 4,
# length 20: sixteen address octets then four zone octets.
my $V6_ONE = '32.1.13.184.0.64.0.0.0.0.0.0.0.0.0.1';
my $V6_TWO = '32.1.13.184.0.64.0.0.0.0.0.0.0.0.0.2';
my $PFX_OID = '.1.3.6.1.2.1.4.32.1.5';

sub _prime_addresses {
  my $test = shift;
  my $info = shift;
  my %opt  = @_;

  my %ifindex = (
    '1.4.10.40.0.1'      => 3,
    '1.4.10.41.0.1'      => 4,
    '1.4.192.0.2.14'   => 1,
    "4.20.$V6_ONE.30.0.0.1" => 2,
    "4.20.$V6_TWO.30.0.0.1" => 3,
    '1.4.10.42.0.255'    => 5,
    %{$opt{extra_ifindex} || {}},
  );
  my %type = map { $_ => 'unicast' } keys %ifindex;
  $type{'1.4.10.42.0.255'} = 'broadcast';
  my %prefix = (
    '1.4.10.40.0.1'      => "$PFX_OID.3.1.4.10.40.0.0.24",
    '1.4.10.41.0.1'      => "$PFX_OID.4.1.4.10.41.0.0.24",
    '1.4.192.0.2.14'   => "$PFX_OID.1.1.4.192.0.2.0.24",
    "4.20.$V6_ONE.30.0.0.1" => "$PFX_OID.2.2.16.$V6_ONE.64",
    "4.20.$V6_TWO.30.0.0.1" => '.0.0',
    '1.4.10.42.0.255'    => "$PFX_OID.5.1.4.10.42.0.0.24",
    %{$opt{extra_prefix} || {}},
  );
  $info->{_new_ip_index}  = 1;
  $info->{_new_ip_type}   = 1;
  $info->{_new_ip_prefix} = 1;
  $info->{store}{new_ip_index}  = \%ifindex;
  $info->{store}{new_ip_type}   = {%type, %{$opt{extra_type} || {}}};
  $info->{store}{new_ip_prefix} = \%prefix;
  return;
}

sub _address_info {
  my $test = shift;
  my %opt  = @_;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::Addresses',
    \@NEIGHBOR_PARENTS);
  $test->{info} = $info;
  $test->_prime_vrf_table();
  $test->_prime_members();
  $test->_prime_addresses($info, %opt);
  return $info;
}

sub vrf_addresses : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vrf_addresses');
  my $info = $test->_address_info();
  cmp_deeply(
    $info->vrf_addresses('blue')->{'3.10.40.0.1'},
    {ifindex => 3, ip => '10.40.0.1', prefix_len => 24, family => 'ipv4'},
    q(An address row holds its port, address, prefix length and family)
  );
}

sub vrf_addresses__ipv4__attributed_by_ifindex : Tests(5) {
  my $test = shift;

  my $info    = $test->_address_info();
  my $red     = $info->vrf_addresses('red');
  my $blue    = $info->vrf_addresses('blue');
  my $default = $info->vrf_addresses('default');
  cmp_deeply($red->{'4.10.41.0.1'},
    superhashof({ifindex => 4, ip => '10.41.0.1', prefix_len => 24}),
    q(red holds the address on its port));
  ok(!exists $red->{'3.10.40.0.1'} && !grep({ $_->{ip} eq '10.40.0.1' } values %$red),
    q(red does not hold 10.40.0.1, which the device collapsed to blue));
  ok(!exists $blue->{'4.10.41.0.1'}, q(blue does not hold red's address));
  cmp_deeply([sort keys %$default], ['1.192.0.2.14'],
    q(default holds the address on the unlisted port));
  ok(!(grep { $_->{ip} eq '10.42.0.255' } map { values %$_ } $red, $blue, $default),
    q(A broadcast row is not an address));
}

sub vrf_addresses__anycast_type__kept : Tests(3) {
  my $test = shift;

  my $arcs = '32.1.13.184.0.65.0.0.0.0.0.0.0.0.0';
  my $iid  = "2.16.$arcs.1";
  my $info = $test->_address_info(
    extra_ifindex => {$iid => 4},
    extra_type    => {$iid => 'anycast'},
    extra_prefix  => {$iid => "$PFX_OID.4.2.16.$arcs.0.64"},
  );
  my $ip = '2001:0db8:0041:0000:0000:0000:0000:0001';
  cmp_deeply($info->vrf_addresses('red')->{"4.$ip"},
    {ifindex => 4, ip => $ip, prefix_len => 64, family => 'ipv6'},
    q(An anycast row is the instance's own address));
  ok(exists $info->vrf_addresses('red')->{'4.10.41.0.1'},
    q(... beside the unicast ones));
  ok(!(grep { $_->{ip} eq '10.42.0.255' }
      values %{$info->vrf_addresses('default')}),
    q(A broadcast row is still not an address));
}

sub vrf_addresses__ipv6z__zone_stripped : Tests(4) {
  my $test = shift;

  my $info = $test->_address_info();
  my $red  = $info->vrf_addresses('red');
  cmp_deeply(
    $red->{'2.2001:0db8:0040:0000:0000:0000:0000:0001'},
    {
      ifindex    => 2,
      ip         => '2001:0db8:0040:0000:0000:0000:0000:0001',
      prefix_len => 64,
      family     => 'ipv6',
    },
    q(red holds the IPv6 address in ipv6_n2p_addr's form, without the zone)
  );
  is(scalar keys %$red, 2, q(red holds its IPv4 row and the IPv6 row));
  my $blue = $info->vrf_addresses('blue');
  is($blue->{'3.2001:0db8:0040:0000:0000:0000:0000:0002'}{prefix_len}, undef,
    q(A zeroDotZero prefix pointer gives an undef prefix length));
  is($blue->{'3.2001:0db8:0040:0000:0000:0000:0000:0002'}{family}, 'ipv6',
    q(... and the family is still ipv6));
}

sub vrf_addresses__same_address_two_ports__both_kept : Tests(4) {
  my $test = shift;

  my $info = $test->_address_info(
    extra_ifindex => {'3.8.10.40.0.1.0.0.0.2' => 2, '3.8.10.40.0.1.0.0.0.3' => 3},
    extra_prefix  => {
      '3.8.10.40.0.1.0.0.0.2' => "$PFX_OID.2.1.4.10.40.0.0.24",
      '3.8.10.40.0.1.0.0.0.3' => "$PFX_OID.3.1.4.10.40.0.0.24",
    },
  );
  my $red  = $info->vrf_addresses('red');
  my $blue = $info->vrf_addresses('blue');
  cmp_deeply($red->{'2.10.40.0.1'}, superhashof({ifindex => 2, ip => '10.40.0.1'}),
    q(red holds the zoned copy on ifIndex 2));
  cmp_deeply($blue->{'3.10.40.0.1'}, superhashof({ifindex => 3, ip => '10.40.0.1'}),
    q(blue keeps the copy on ifIndex 3));
  is(scalar(grep { $_->{ip} eq '10.40.0.1' } values %$red), 1,
    q(red holds the address once));
  is(scalar(grep { $_->{ip} eq '10.40.0.1' } values %$blue), 1,
    q(blue holds the address once, though two table rows land on ifIndex 3));
}

sub vrf_addresses__zoned_copies_same_port__one_row_first_in_sorted_index_order
  : Tests(2) {
  my $test = shift;

  my $info = $test->_address_info(
    extra_ifindex => {'3.8.10.43.0.1.0.0.0.9' => 2, '3.8.10.43.0.1.0.0.0.1' => 2},
    extra_prefix  => {
      '3.8.10.43.0.1.0.0.0.9' => "$PFX_OID.2.1.4.10.43.0.0.16",
      '3.8.10.43.0.1.0.0.0.1' => "$PFX_OID.2.1.4.10.43.0.0.24",
    },
  );
  my $rows = $info->vrf_addresses('red');
  is(scalar(grep { $_->{ip} eq '10.43.0.1' } values %$rows), 1,
    q(Two zoned copies on one port make one row));
  is($rows->{'2.10.43.0.1'}{prefix_len}, 24,
    q(... from the copy first in sorted index order, so the choice is stable));
}

sub vrf_addresses__no_ipaddresstable__falls_back_to_ipadent : Tests(4) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::AddressesOld',
    \@NEIGHBOR_PARENTS);
  $test->{info} = $info;
  $test->_prime_vrf_table();
  $test->_prime_members();
  $info->{_old_ip_index}   = 1;
  $info->{_old_ip_netmask} = 1;
  $info->{store}{old_ip_index} = {
    '10.40.0.1'    => 3,
    '10.41.0.1'    => 4,
    '192.0.2.14' => 1,
    '10.44.0.1'    => 2,
  };
  $info->{store}{old_ip_netmask} = {
    '10.40.0.1'    => '255.255.255.0',
    '10.41.0.1'    => '255.255.255.0',
    '192.0.2.14' => '255.255.255.0',
    '10.44.0.1'    => '255.0.255.0',
  };
  cmp_deeply(
    $info->vrf_addresses('blue'),
    {
      '3.10.40.0.1' => {
        ifindex => 3, ip => '10.40.0.1', prefix_len => 24, family => 'ipv4',
      },
    },
    q(blue reads its address from ipAdEntTable)
  );
  is($info->vrf_addresses('red')->{'4.10.41.0.1'}{prefix_len}, 24,
    q(red gets its address and mask length too));
  is($info->vrf_addresses('red')->{'2.10.44.0.1'}{prefix_len}, undef,
    q(A mask that is not contiguous gives an undef length));
  cmp_deeply([keys %{$info->vrf_addresses('default')}], ['1.192.0.2.14'],
    q(default holds the unlisted port's address));
}

sub vrf_addresses__ipaddresstable_has_ipv4__ipadent_ignored : Tests(1) {
  my $test = shift;

  my $info = $test->_address_info();
  $info->{_old_ip_index} = 1;
  $info->{store}{old_ip_index} = {'10.99.0.1' => 3};
  ok(!(grep { $_->{ip} eq '10.99.0.1' } values %{$info->vrf_addresses('blue')}),
    q(ipAdEntTable is read only when ipAddressTable yields no IPv4 row));
}

sub vrf_addresses__vendor_rows__standard_row_wins : Tests(5) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::VendorRows',
    \@NEIGHBOR_PARENTS,
    _vrf_vendor_address_rows => sub {
      return {
        '3.10.40.0.1'  => {ifindex => 3, ip => '10.40.0.1',
          prefix_len => 16, family => 'ipv4'},
        '3.10.99.0.1'  => {ifindex => 3, ip => '10.99.0.1',
          prefix_len => 24, family => 'ipv4'},
        '2.10.98.0.1'  => {ifindex => 2, ip => '10.98.0.1',
          prefix_len => 24, family => 'ipv4'},
      };
    });
  $test->{info} = $info;
  $test->_prime_vrf_table();
  $test->_prime_members();
  $test->_prime_addresses($info);

  my $blue = $info->vrf_addresses('blue');
  is($blue->{'3.10.40.0.1'}{prefix_len}, 24,
    q(A standard row wins over a vendor row for the same port and address));
  cmp_deeply($blue->{'3.10.99.0.1'},
    {ifindex => 3, ip => '10.99.0.1', prefix_len => 24, family => 'ipv4'},
    q(A vendor row for an address the standard rows lack is added));
  ok(!exists $blue->{'2.10.98.0.1'},
    q(A vendor row on another instance's port is not blue's));
  cmp_deeply($info->vrf_addresses('red')->{'2.10.98.0.1'},
    superhashof({ifindex => 2, ip => '10.98.0.1'}),
    q(... it is red's));
  is(scalar(grep { $_->{ip} eq '10.40.0.1' } values %$blue), 1,
    q(The shared address is held once));
}

# The unspecified address of either family is no interface address, and
# its network would be the whole address space
sub vrf_addresses__unspecified_address__dropped : Tests(4) {
  my $test = shift;

  my $v6_zero = join '.', (0) x 16;
  my %zero = ('1.4.0.0.0.0' => '1.1.4.0.0.0.0.0',
    "2.16.$v6_zero" => "2.2.16.$v6_zero.0");
  my $info = $test->_address_info(
    extra_ifindex => {map { $_ => 3 } keys %zero},
    extra_prefix  => {map { $_ => "$PFX_OID.3.$zero{$_}" } keys %zero},
  );
  my $rows = $info->vrf_addresses('blue');
  ok(!(grep { $_->{ip} eq '0.0.0.0' } values %$rows), q(IPv4 0.0.0.0));
  ok(!(grep { $_->{ip} =~ /^[0:]+$/ } values %$rows), q(IPv6 ::));
  ok(exists $rows->{'3.10.40.0.1'}, q(... and the port's address is kept));
  cmp_deeply([grep { m{/0$} } keys %{$info->vrf_subnets('blue')}], [],
    q(No subnet of length 0));
}

sub vrf_addresses__unknown_name__returns_nothing : Tests(1) {
  my $test = shift;

  my $info = $test->_address_info();
  is(scalar $info->vrf_addresses('purple'), undef,
    q(An instance the device does not list has no addresses));
}

sub vrf_addresses__role_without_address_methods__has_no_rows : Tests(1) {
  my $test = shift;

  $test->_prime_vrf_table();
  cmp_deeply($test->{info}->vrf_addresses('default'), {},
    q(A device serving neither address table gives no rows));
}

sub vrf_addresses__context_mode__rows_not_filtered_by_owner : Tests(1) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::AddressContext',
    \@NEIGHBOR_PARENTS, _vrf_context_filters => sub { 1 });
  $test->{info} = $info;
  $test->_prime_members();
  $test->_prime_addresses($info);
  $test->_enter_context($info);
  my $rows = $info->vrf_addresses('red');
  cmp_deeply([sort grep { /^\d+\.10\./ || /^1\./ } keys %$rows],
    ['1.192.0.2.14', '3.10.40.0.1', '4.10.41.0.1'],
    q(Every unicast row the context serves is kept, whatever i_vrf says));
}

sub vrf_addresses__attribution_in_vrf_context__throws : Tests(2) {
  my $test = shift;

  my $info = $test->_address_info();
  $test->_enter_context($info);
  is(scalar $info->vrf_addresses('red'), undef, q(Refused in a context));
  like($info->error(), qr/^\S+vrf_addresses\(\) reads instance 'red'/,
    q(Error names the reader));
}

# mplsL3VpnVrfRteTable rows of an IOS-XE device. Red's 10.40.0.0/24 is
# served here though the address tables keep 10.40.0.1 only on blue's port.
# The index after the name is destType.destLen.dest.pfxLen.policyLen.policy
# .nhType.nhLen.nh.
my $RED_NAME     = $NAME_IID{red};
my $BLUE_NAME    = $NAME_IID{blue};
my $ZERO_V4_HOP  = '1.4.0.0.0.0';
my $ZERO_V6_HOP  = '2.16.' . join(q(.), (0) x 16);
my $NET_V6_BYTES = '32.1.13.184.0.64.0.0.0.0.0.0.0.0.0.0';

sub _prime_routes {
  my $test = shift;
  my $info = shift;

  my %rows = (
    "$RED_NAME.1.4.10.40.0.0.24.2.0.0.$ZERO_V4_HOP"  => ['local',   2],
    "$RED_NAME.1.4.10.40.0.1.32.2.0.0.$ZERO_V4_HOP"  => ['local',   2],
    "$RED_NAME.1.4.10.40.9.0.24.2.0.0.$ZERO_V4_HOP"  => ['ospf',    2],
    "$RED_NAME.2.16.$NET_V6_BYTES.64.2.0.0.$ZERO_V6_HOP" => ['local', 2],
    "$BLUE_NAME.1.4.10.40.0.0.24.2.0.0.$ZERO_V4_HOP" => ['local',   3],
  );
  $info->{_vrf_l3vpn_rte_if}    = 1;
  $info->{_vrf_l3vpn_rte_proto} = 1;
  $info->{store}{vrf_l3vpn_rte_proto}
    = {map { $_ => $rows{$_}[0] } keys %rows};
  $info->{store}{vrf_l3vpn_rte_if} = {map { $_ => $rows{$_}[1] } keys %rows};
  return;
}

sub _subnet_info {
  my $test = shift;
  my %opt  = @_;

  my $info
    = $opt{routes}
    ? $test->_make_info('Test::SNMP::Info::VRF::SubnetRoutes',
    \@NEIGHBOR_PARENTS, _vrf_subnets_from_routes => sub {1})
    : $test->_make_info('Test::SNMP::Info::VRF::Addresses',
    \@NEIGHBOR_PARENTS);
  $test->{info} = $info;
  $test->_prime_vrf_table();
  $test->_prime_members();
  $test->_prime_addresses($info);
  $test->_prime_routes($info);
  return $info;
}

sub vrf_subnets : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vrf_subnets');
  my $info = $test->_subnet_info();
  cmp_deeply(
    $info->vrf_subnets('blue')->{'10.40.0.0/24'},
    {
      prefix  => '10.40.0.0',
      len     => 24,
      family  => 'ipv4',
      ifindex => 3,
      sources => ['address']
    },
    q(A subnet record holds its prefix, length, port and sources)
  );
}

sub vrf_subnets__from_addresses__network_and_length : Tests(4) {
  my $test = shift;

  my $info = $test->_subnet_info();
  cmp_deeply(
    $info->vrf_subnets('blue')->{'10.40.0.0/24'},
    superhashof({sources => ['address']}),
    q(Blue holds the network of its address, not the host address)
  );
  ok(!exists $info->vrf_subnets('blue')->{'10.40.0.1/24'},
    q(The host address is not a prefix));
  cmp_deeply(
    $info->vrf_subnets('red')->{'2001:0db8:0040:0000:0000:0000:0000:0000/64'},
    superhashof({family => 'ipv6', len => 64, ifindex => 2}),
    q(An IPv6 address gives its masked network));
  ok(!(grep { /^10\.42\./ } keys %{$info->vrf_subnets('blue')}),
    q(A broadcast-typed address row gives no subnet));
}

sub vrf_subnets__link_local_address__dropped : Tests(2) {
  my $test = shift;

  my $info = $test->_subnet_info();
  my $link_local = '254.128.0.0.0.0.0.0.0.0.0.0.0.0.0.1';
  my $iid        = "4.20.$link_local.30.0.0.1";
  $info->{store}{new_ip_index}{$iid}  = 2;
  $info->{store}{new_ip_type}{$iid}   = 'unicast';
  $info->{store}{new_ip_prefix}{$iid} = "$PFX_OID.2.2.16.$link_local.10";
  my $red = $info->vrf_subnets('red');
  cmp_deeply([grep { /^fe80/ } keys %$red], [],
    q(An address in fe80::/10 gives no subnet whatever its prefix length));
  ok(exists $red->{'2001:0db8:0040:0000:0000:0000:0000:0000/64'},
    q(... and the global IPv6 subnet is kept));
}

sub vrf_subnets__no_prefix_length__no_subnet : Tests(1) {
  my $test = shift;

  my $info = $test->_subnet_info();
  $info->{store}{new_ip_prefix}{'1.4.10.40.0.1'} = '.0.0';
  cmp_deeply($info->vrf_subnets('blue'), {},
    q(An address with no prefix length gives no subnet));
}

sub vrf_subnets__routes_off__collapsed_subnet_absent : Tests(2) {
  my $test = shift;

  my $info = $test->_subnet_info();
  ok(!exists $info->vrf_subnets('red')->{'10.40.0.0/24'},
    q(Red's collapsed subnet is not claimed without routes));
  ok(exists $info->vrf_subnets('red')->{'10.41.0.0/24'},
    q(... while its address-derived subnet stays));
}

sub vrf_subnets__routes_on__collapsed_subnet_from_route : Tests(8) {
  my $test = shift;

  my $info = $test->_subnet_info(routes => 1);
  my $red  = $info->vrf_subnets('red');
  cmp_deeply(
    $red->{'10.40.0.0/24'},
    {
      prefix  => '10.40.0.0',
      len     => 24,
      family  => 'ipv4',
      ifindex => 2,
      sources => ['route']
    },
    q(Red's collapsed subnet comes back from its connected route)
  );
  ok(!exists $red->{'10.40.0.1/32'}, q(A host route is not a subnet));
  ok(!grep({ $_->{len} == 32 } values %$red), q(No /32 is held));
  ok(!exists $red->{'10.40.9.0/24'}, q(A route of another protocol is not));
  cmp_deeply(
    $red->{'2001:0db8:0040:0000:0000:0000:0000:0000/64'}{sources},
    ['address', 'route'], q(An IPv6 prefix found both ways lists both));
  cmp_deeply(
    $info->vrf_subnets('blue')->{'10.40.0.0/24'},
    superhashof({ifindex => 3, sources => ['address', 'route']}),
    q(A prefix found both ways lists address first)
  );
  ok(!exists $info->vrf_subnets('blue')->{'10.40.9.0/24'},
    q(Another instance's routes are not blue's));
  is(scalar $info->vrf_subnets('purple'), undef,
    q(An instance the device does not list has no subnets));
}

sub vrf_subnets__context_mode__connected_route_read : Tests(3) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::SubnetContext',
    \@NEIGHBOR_PARENTS,
    _vrf_context_filters     => sub {1},
    _vrf_subnets_from_routes => sub {1});
  $test->{info} = $info;
  $test->_prime_members();
  $info->{_vrf_cidr_if}    = 1;
  $info->{_vrf_cidr_proto} = 1;
  $info->{store}{vrf_cidr_proto} = {
    "1.4.10.40.0.0.24.2.0.0.$ZERO_V4_HOP"  => 'local',
    "1.4.10.40.0.1.32.2.0.0.$ZERO_V4_HOP"  => 'local',
    "1.4.10.43.0.0.24.2.0.0.$ZERO_V4_HOP"  => 'ospf',
  };
  $info->{store}{vrf_cidr_if} = {
    "1.4.10.40.0.0.24.2.0.0.$ZERO_V4_HOP" => 2,
    "1.4.10.40.0.1.32.2.0.0.$ZERO_V4_HOP" => 2,
    "1.4.10.43.0.0.24.2.0.0.$ZERO_V4_HOP" => 2,
  };
  $test->_enter_context($info);
  my $subnets = $info->vrf_subnets('red');
  cmp_deeply(
    $subnets->{'10.40.0.0/24'},
    superhashof({ifindex => 2, sources => ['route']}),
    q(A context-mode route with no name in its index gives a subnet)
  );
  ok(!exists $subnets->{'10.40.0.1/32'}, q(A host route is not a subnet));
  ok(!exists $subnets->{'10.43.0.0/24'}, q(A non-connected route is not));
}

# destType.destLen.dest.pfxLen.policyLen.policy.nhType.nhLen.nh of a route
sub _route_iid {
  my ($family, $prefix, $length) = @_;

  my @octets = $family eq 'ipv4'
    ? split(/\./, $prefix)
    : unpack('C*', pack('n8', map { hex } split /:/, $prefix));
  my ($type, $hop) = $family eq 'ipv4'
    ? ('1.4', $ZERO_V4_HOP) : ('2.16', $ZERO_V6_HOP);
  return join('.', $type, @octets, $length, '2.0.0', $hop);
}

# Special-purpose space, with one ordinary prefix per family beside it
my @SPECIAL_ROUTES = (
  ['ipv4', '0.0.0.0',                            8],
  ['ipv4', '127.0.0.0',                          8],
  ['ipv4', '224.0.0.0',                          4],
  ['ipv4', '255.255.255.255',                    32],
  ['ipv6', '0:0:0:0:0:0:0:0',                    127],
  ['ipv6', 'fe80:0:0:0:0:0:0:0',                 10],
  ['ipv6', 'ff00:0:0:0:0:0:0:0',                 8],
  ['ipv6', '2001:db8:50:0:0:0:0:0',              64],
  ['ipv4', '10.50.0.0',                          24],
);

sub vrf_subnets__special_purpose_routes__dropped_attribution : Tests(3) {
  my $test = shift;

  my $info = $test->_subnet_info(routes => 1);
  foreach my $route (@SPECIAL_ROUTES) {
    my $iid = "$RED_NAME." . _route_iid(@$route);
    $info->{store}{vrf_l3vpn_rte_proto}{$iid} = 'local';
    $info->{store}{vrf_l3vpn_rte_if}{$iid}    = 2;
  }
  my $red = $info->vrf_subnets('red');
  cmp_deeply(
    [grep { /^(?:0\.|127\.|224\.|255\.|0000:0000:0000:0000:0000:0000:0000:0000|fe80|ff00)/ } keys %$red],
    [], q(No route into special-purpose space is a subnet));
  ok(exists $red->{'10.50.0.0/24'}, q(An ordinary IPv4 route is kept));
  ok(exists $red->{'2001:0db8:0050:0000:0000:0000:0000:0000/64'},
    q(An ordinary IPv6 route is kept));
}

sub vrf_subnets__special_purpose_routes__dropped_context : Tests(3) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::SubnetContext',
    \@NEIGHBOR_PARENTS,
    _vrf_context_filters     => sub {1},
    _vrf_subnets_from_routes => sub {1});
  $test->{info} = $info;
  $test->_prime_members();
  my %iid = map { _route_iid(@$_) => 1 } @SPECIAL_ROUTES;
  $info->{_vrf_cidr_if}    = 1;
  $info->{_vrf_cidr_proto} = 1;
  $info->{store}{vrf_cidr_proto} = {map { $_ => 'local' } keys %iid};
  $info->{store}{vrf_cidr_if}    = {map { $_ => 2 } keys %iid};
  $test->_enter_context($info);
  my $subnets = $info->vrf_subnets('red');
  cmp_deeply([sort keys %$subnets],
    ['10.50.0.0/24', '2001:0db8:0050:0000:0000:0000:0000:0000/64'],
    q(Only the ordinary prefixes remain));
  is($subnets->{'10.50.0.0/24'}{sources}[0], 'route', q(... from routes));
  is(scalar(grep { $_->{family} eq 'ipv6' } values %$subnets), 1,
    q(One IPv6 subnet));
}

sub vrf_subnets__special_purpose_prefix_in_addresses__kept : Tests(2) {
  my $test = shift;

  my $info = $test->_subnet_info(routes => 1);
  $info->{store}{new_ip_index}{'1.4.127.0.0.1'}  = 2;
  $info->{store}{new_ip_type}{'1.4.127.0.0.1'}   = 'unicast';
  $info->{store}{new_ip_prefix}{'1.4.127.0.0.1'} = "$PFX_OID.2.1.4.127.0.0.0.8";
  my $iid = "$RED_NAME." . _route_iid('ipv4', '127.0.0.0', 8);
  $info->{store}{vrf_l3vpn_rte_proto}{$iid} = 'local';
  $info->{store}{vrf_l3vpn_rte_if}{$iid}    = 2;
  my $subnet = $info->vrf_subnets('red')->{'127.0.0.0/8'};
  ok($subnet, q(A prefix the address tables list is kept));
  cmp_deeply($subnet->{sources}, ['address', 'route'],
    q(... and still lists both sources));
}

sub vrf_subnets__attribution_in_vrf_context__throws : Tests(2) {
  my $test = shift;

  my $info = $test->_subnet_info();
  $test->_enter_context($info);
  is(scalar $info->vrf_subnets('red'), undef, q(Refused in a context));
  like($info->error(), qr/^\S+vrf_subnets\(\) reads instance 'red'/,
    q(Error names the reader));
}

sub vrf_subnets__route_ifindex_zero__is_undef : Tests(2) {
  my $test = shift;

  my $info  = $test->_subnet_info(routes => 1);
  my $route = "$RED_NAME.1.4.10.45.0.0.24.2.0.0.$ZERO_V4_HOP";
  $info->{store}{vrf_l3vpn_rte_proto}{$route} = 'local';
  $info->{store}{vrf_l3vpn_rte_if}{$route}    = 0;
  my $subnet = $info->vrf_subnets('red')->{'10.45.0.0/24'};
  ok($subnet, q(A connected route with no interface still gives a subnet));
  is($subnet->{ifindex}, undef,
    q(... and ifIndex 0, InterfaceIndexOrZero's none, is undef));
}

sub vrf_subnets__context_mode_route_ifindex_zero__is_undef : Tests(2) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::SubnetContext',
    \@NEIGHBOR_PARENTS,
    _vrf_context_filters     => sub {1},
    _vrf_subnets_from_routes => sub {1});
  $test->{info} = $info;
  $test->_prime_members();
  my $iid = "1.4.10.45.0.0.24.2.0.0.$ZERO_V4_HOP";
  $info->{_vrf_cidr_if}    = 1;
  $info->{_vrf_cidr_proto} = 1;
  $info->{store}{vrf_cidr_proto} = {$iid => 'local'};
  $info->{store}{vrf_cidr_if}    = {$iid => 0};
  $test->_enter_context($info);
  my $subnet = $info->vrf_subnets('red')->{'10.45.0.0/24'};
  ok($subnet, q(A context-mode connected route with no interface is a subnet));
  is($subnet->{ifindex}, undef, q(... and its ifIndex 0 is undef));
}

sub vrf_subnets__context_mode_non_numeric_index__skipped : Tests(1) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::SubnetContext',
    \@NEIGHBOR_PARENTS,
    _vrf_context_filters     => sub {1},
    _vrf_subnets_from_routes => sub {1});
  $test->{info} = $info;
  $test->_prime_members();
  my $iid = "1.4.10.47.x.0.24.2.0.0.$ZERO_V4_HOP";
  $info->{_vrf_cidr_if}    = 1;
  $info->{_vrf_cidr_proto} = 1;
  $info->{store}{vrf_cidr_proto} = {$iid => 'local'};
  $info->{store}{vrf_cidr_if}    = {$iid => 2};
  $test->_enter_context($info);
  cmp_deeply($info->vrf_subnets('red'), {},
    q(A route index that is not digits and dots gives no subnet));
}

sub vrf_ip_octets__short_ipv4__returns_nothing : Tests(2) {
  my $test = shift;

  cmp_deeply([SNMP::Info::VRF::_vrf_ip_octets('ipv4', '10.46.0')], [],
    q(An IPv4 address of three octets has no octets));
  cmp_deeply([SNMP::Info::VRF::_vrf_ip_octets('ipv4', '10.46.0.1')],
    [10, 46, 0, 1], q(... and one of four keeps them));
}

# Every reader of red, with routes on, so each source table is walked
sub _read_red {
  my $test = shift;

  my $info = $test->_subnet_info(routes => 1);
  $test->_prime_neighbors($info);
  $info->vrf_neighbors('red');
  $info->vrf_subnets('red');
  return $info;
}

sub vrf_read_complete : Tests(1) {
  my $test = shift;

  can_ok($test->{info}, 'vrf_read_complete');
}

sub vrf_read_complete__clean_walks__is_1 : Tests(3) {
  my $test = shift;

  my $info = $test->_read_red();
  is($info->vrf_read_complete('red'), 1, q(Every walk was complete));
  cmp_deeply(
    [sort keys %{$info->{_vrf_walked}{red}}],
    superbagof(qw/at_paddr at_netaddr ip_n2p_phys_addr new_ip_index
      new_ip_prefix vrf_l3vpn_if vrf_l3vpn_rte_proto/),
    q(The readers recorded the tables they walked for red)
  );
  is($info->vrf_read_complete('purple'), undef,
    q(A name no reader walked is unknown));
}

sub vrf_read_complete__incomplete_walk__is_0 : Tests(8) {
  my $test = shift;

  my $info = $test->_read_red();
  $info->vrf_addresses('blue');
  $info->{walk_status}{at_paddr} = {complete => 0, reason => 'timeout'};
  is($info->vrf_read_complete('red'), 0,
    q(An incomplete ARP walk makes red's read incomplete));
  is($info->vrf_read_complete('blue'), 1,
    q(... but not blue's, whose reader did not walk it));

  foreach my $method (qw/ip_n2p_phys_addr new_ip_index vrf_l3vpn_rte_if
    old_at_paddr old_at_netaddr/) {
    $info->{walk_status} = {$method => {complete => 0, reason => 'timeout'}};
    is($info->vrf_read_complete('red'), 0,
      qq(An incomplete walk of $method makes red's read incomplete));
  }

  $info->{walk_status} = {at_paddr => {complete => 1, reason => 'absent'}};
  is($info->vrf_read_complete('red'), 1,
    q(An absent table is complete));
}


sub vrf_read_complete__after_update__is_undef : Tests(2) {
  my $test = shift;

  my $info = $test->_read_red();
  is($info->vrf_read_complete('red'), 1, q(Read in this session));
  $info->clear_cache();
  is($info->vrf_read_complete('red'), undef,
    q(After clear_cache, and so update(), no reader has run));
}

sub vrf_instances_complete__incomplete_descr_or_oper__is_0 : Tests(2) {
  my $test = shift;

  foreach my $method (qw/vrf_l3vpn_descr vrf_l3vpn_oper/) {
    $test->_prime_vrf_table();
    $test->_prime_members(configured => 4);
    delete $test->{info}{$_} for qw/_vrf_instances _vrf_vendor_listed/;
    $test->{info}{walk_status}{$method}
      = {complete => 0, reason => 'timeout'};
    is($test->{info}->vrf_instances_complete(), 0,
      qq(An incomplete walk of $method));
    $test->{info}{walk_status} = {};
  }
}

sub vrf_instances__served_table__default_carries_list_source : Tests(1) {
  my $test = shift;

  $test->_prime_vrf_table();
  is($test->{info}->vrf_instances()->{default}{sources}{list},
    'MPLS-L3VPN-STD-MIB', q(The list source that served rows lists default));
}

# An agent that serves mplsL3VpnVrfTable rows only for an internal instance
# serves the list, which holds no VRF
sub vrf_instances_complete__mpls_internal_row_only__is_1 : Tests(4) {
  my $test = shift;

  my $info = $test->_make_info('Test::SNMP::Info::VRF::InternalOnly',
    ['SNMP::Info::VRF'],
    _vrf_internal_instance => sub { ($_[1] // q()) =~ /^__.*__$/ ? 1 : 0 });
  my $internal = join '.', 8, map {ord} split //, '__mgmt__';
  $info->{"_$_"} = 1 for qw/vrf_l3vpn_rd vrf_l3vpn_descr vrf_l3vpn_oper
    vrf_l3vpn_rt vrf_l3vpn_if/;
  $info->{store}{$_} = {} for qw/vrf_l3vpn_rd vrf_l3vpn_rt vrf_l3vpn_if/;
  $info->{store}{vrf_l3vpn_descr} = {$internal => q()};
  $info->{store}{vrf_l3vpn_oper}  = {$internal => 'up'};

  cmp_deeply([keys %{$info->vrf_instances()}], ['default'],
    q(The internal instance is not listed));
  is($info->vrf_instances()->{default}{sources}{list}, 'MPLS-L3VPN-STD-MIB',
    q(... but its row lists default));
  is($info->vrf_instances_complete(), 1, q(None configured));
  ok(!exists $info->vrf_instances(['vr-red'])->{'vr-red'},
    q(Caller names add nothing));
}

1;
