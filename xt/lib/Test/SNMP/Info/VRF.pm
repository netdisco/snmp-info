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
  delete $test->{info}{_vrf_instances};
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

sub vrf_instances_complete__incomplete_walk__is_0 : Tests(2) {
  my $test = shift;

  foreach my $method (qw/vrf_l3vpn_rd vrf_l3vpn_if/) {
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

sub vrf_private_defaults : Tests(3) {
  my $test = shift;

  is($test->{info}->_vrf_context_filters(), 0, q(No context filtering));
  is($test->{info}->_vrf_internal_instance('red'), 0,
    q(No instance is internal in the base role));
  ok(defined &SNMP::Info::VRF::_vrf_default_context_ok,
    q(The default context guard is defined));
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
  is($test->{info}->_vrf_owner_of(2), 'red', q(A member port maps to its VRF));
  is($test->{info}->_vrf_owner_of(99), 'default',
    q(A port absent from i_vrf is in the default instance));

  $test->_enter_context($test->{info});
  is($test->{info}->_vrf_owner_of(2), undef,
    q(Unknown when i_vrf is refused in a context));
  ok(defined &SNMP::Info::VRF::_vrf_owner_of, q(Owner lookup is defined));
}

1;
