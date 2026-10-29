# Test::SNMP::Info::IEEE802dot3ad
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

package Test::SNMP::Info::IEEE802dot3ad;

use Test::Class::Most parent => 'My::Test::Class';

use File::Find;
use B ();
use SNMP::Info::IEEE802dot3ad;

my $ACTOR   = pack( 'H*', '443839ff0001' );
my $ACTOR_2 = pack( 'H*', '443839ff0002' );
my $PARTNER = pack( 'H*', 'aabbcc000001' );
my $ZEROS   = pack( 'H*', '000000000000' );

sub lag_cache {
  return {
    '_lag_actor_system'        => 1,
    '_lag_actor_key'           => 1,
    '_lag_partner_system'      => 1,
    '_lag_partner_key'         => 1,
    '_lag_port_attached'       => 1,
    '_lag_port_partner_system' => 1,
    '_lag_port_partner_key'    => 1,
    'store'                    => {
      'lag_actor_system'   => {1000001 => $ACTOR, 1000002 => $ACTOR_2},
      'lag_actor_key'      => {1000001 => 1001,   1000002 => 1002},
      'lag_partner_system' => {1000001 => $PARTNER, 1000002 => $ZEROS},
      'lag_partner_key'    => {1000001 => 15, 1000002 => 0},
      'lag_port_attached'  => {1 => 1000001, 2 => 1000001, 3 => 1000003},
      'lag_port_partner_system' =>
        {1 => $PARTNER, 2 => $PARTNER, 3 => $ZEROS},
      'lag_port_partner_key' => {1 => 15, 2 => 15, 3 => 0},
    },
  };
}

sub with_agg_ports {
  my ( $test, $ports, $code ) = @_;

  no warnings 'redefine';
  local *SNMP::Info::IEEE802dot3ad::agg_ports = sub {$ports};
  return $code->();
}

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_ad_lag_ports' => 1,
    'store'         => {

      # Unpacked 'C0' has first two bits set to 1 all others 0
      # Simple example taken from a 24 port switch to minimize
      # unpacked array length
      'ad_lag_ports' => {25 => pack("H*", 'C0')}
    },
  };
  $test->{info}->cache($cache_data);
}

sub agg_ports_lag : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'agg_ports_lag');

  my $expected = {1 => 25, 2 => 25};

  cmp_deeply($test->{info}->agg_ports_lag(),
    $expected, q(Aggregated links have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->agg_ports_lag(), {}, q(No data returns empty hash));
}

sub lag_groups : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'lag_groups');
  $test->{info}->cache(lag_cache());

  my $expected = {
    members => {
      1 => {partner_system => 'aa:bb:cc:00:00:01', partner_key => 15},
      2 => {partner_system => 'aa:bb:cc:00:00:01', partner_key => 15},
    },
    actor_system   => '44:38:39:ff:00:01',
    actor_key      => 1001,
    partner_system => 'aa:bb:cc:00:00:01',
    partner_key    => 15,
    lacp           => 1,
    sources        => {
      members        => 'agg_ports',
      actor_system   => 'IEEE8023-LAG-MIB::dot3adAggActorSystemID',
      actor_key      => 'IEEE8023-LAG-MIB::dot3adAggActorOperKey',
      partner_system => 'IEEE8023-LAG-MIB::dot3adAggPartnerSystemID',
      partner_key    => 'IEEE8023-LAG-MIB::dot3adAggPartnerOperKey',
    },
  };
  my $groups = $test->with_agg_ports({1 => 1000001, 2 => 1000001},
    sub { $test->{info}->lag_groups() });
  cmp_deeply($groups->{1000001}, $expected,
    q(Aggregate record has LACP identity and members from agg_ports));
}

sub lag_groups__zero_partner__no_lacp_partner : Tests(4) {
  my $test = shift;

  $test->{info}->cache(lag_cache());
  my $groups = $test->{info}->lag_groups();
  my $record = $groups->{1000002};

  is($record->{lacp}, 0, q(All-zero partner system means lacp 0));
  is($record->{partner_system}, undef, q(partner_system is undef));
  is($record->{partner_key}, undef, q(partner_key is undef));
  is($record->{actor_system}, '44:38:39:ff:00:02', q(Actor identity kept));
}

sub lag_groups__agg_ports_names_no_member__falls_back_to_attached : Tests(2) {
  my $test = shift;

  $test->{info}->cache(lag_cache());
  my $groups = $test->with_agg_ports({1 => 1000001, 2 => 1000001},
    sub { $test->{info}->lag_groups() });

  cmp_deeply($groups->{1000003}{members},
    {3 => {partner_system => undef, partner_key => undef}},
    q(Port attached to an unlisted aggregate becomes its member));
  is($groups->{1000003}{sources}{members},
    'IEEE8023-LAG-MIB::dot3adAggPortAttachedAggID',
    q(members source names the attached-aggregate leaf));
}

sub lag_groups__aggregator_map__rows_merge_onto_mapped_key : Tests(4) {
  my $test = shift;

  $test->{info}->cache(lag_cache());
  no warnings 'redefine';
  local *SNMP::Info::IEEE802dot3ad::_lag_aggregator_map
    = sub { {1000001 => 1000009, 1000002 => 1000009} };
  my $groups = $test->{info}->lag_groups();

  ok(exists $groups->{1000009}, q(Record keyed on the mapped value));
  ok(!exists $groups->{1000001} && !exists $groups->{1000002},
    q(No record keyed on the unmapped rows));
  is($groups->{1000009}{actor_system}, '44:38:39:ff:00:01',
    q(Lowest row index supplies the identity));
  cmp_deeply([sort keys %{$groups->{1000009}{members}}], [1, 2],
    q(Attached ports follow the map));
}

sub lag_groups__static_lag_no_ieee_row__record_from_agg_ports : Tests(3) {
  my $test = shift;

  $test->{info}->cache(lag_cache());
  my $groups = $test->with_agg_ports({5 => 1000005},
    sub { $test->{info}->lag_groups() });
  my $record = $groups->{1000005};

  is($record->{lacp}, 0, q(Static aggregate has lacp 0));
  is($record->{actor_system}, undef, q(No actor identity));
  cmp_deeply([keys %{$record->{members}}], [5], q(Member from agg_ports));
}

sub lag_groups__no_agg_ports__treated_as_empty : Tests(1) {
  my $test = shift;

  $test->{info}->cache(lag_cache());
  ok(!$test->{info}->can('agg_ports'), q(Role itself has no agg_ports));
}

sub mlag_domains : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'mlag_domains');
  cmp_deeply($test->{info}->mlag_domains(), {}, q(Role reports no domains));
}

sub lag_groups_complete : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'lag_groups_complete');
  $test->{info}->cache(lag_cache());
  is($test->{info}->lag_groups_complete(), 1, q(Rows and complete walks));
}

sub lag_groups_complete__no_rows__undef : Tests(1) {
  my $test = shift;

  $test->{info}->cache({'_lag_actor_system' => 1, 'store' => {}});
  is($test->{info}->lag_groups_complete(), undef, q(No rows gives undef));
}

sub lag_groups__attached_value_moved_by_map__member_lands_on_mapped_key
  : Tests(3) {
  my $test = shift;

  $test->{info}->cache({
    '_lag_actor_system'  => 1,
    '_lag_port_attached' => 1,
    'store'              => {
      'lag_actor_system'  => {6153 => $ACTOR},
      'lag_port_attached' => {194  => 6153},
    },
  });
  no warnings 'redefine';
  local *SNMP::Info::IEEE802dot3ad::_lag_aggregator_map
    = sub { {6153 => 194} };
  my $groups = $test->{info}->lag_groups();

  cmp_deeply([keys %{$groups->{194}{members}}], [194],
    q(Member 194 lands on the mapped record 194));
  ok(!exists $groups->{6153}, q(No record keyed on the moved row));
  is($groups->{194}{actor_system}, '44:38:39:ff:00:01',
    q(Identity of the moved row kept));
}

sub lag_groups__port_row_attached_elsewhere__dropped : Tests(3) {
  my $test = shift;

  $test->{info}->cache({
    '_lag_actor_system'  => 1,
    '_lag_port_attached' => 1,
    'store'              => {
      'lag_actor_system'  => {194 => $ACTOR, 6153 => $ACTOR_2, 195 => $ACTOR},
      'lag_port_attached' => {194 => 6153, 195 => 0},
    },
  });
  my $groups = $test->{info}->lag_groups();

  ok(!exists $groups->{194}, q(Port row attached to another aggregate dropped));
  cmp_deeply([keys %{$groups->{6153}{members}}], [194],
    q(The port is a member of the aggregate it is attached to));
  ok(exists $groups->{195}, q(Memberless row attached to nothing stays));
}

sub lag_groups_complete__static_lag_no_rows__returns_1 : Tests(1) {
  my $test = shift;

  $test->{info}->cache({'_lag_actor_system' => 1, 'store' => {}});
  my $complete = $test->with_agg_ports({5 => 1000005},
    sub { $test->{info}->lag_groups_complete() });
  is($complete, 1, q(Static aggregate without IEEE rows is complete));
}

sub lag_groups_complete__walk_incomplete__returns_0 : Tests(1) {
  my $test = shift;

  $test->{info}->cache(lag_cache());
  $test->{info}->{walk_status}{lag_actor_system} = {complete => 0};
  is($test->{info}->lag_groups_complete(), 0, q(Incomplete walk gives 0));
}

sub lag__role_names__collide_with_no_existing_method : Tests(1) {
  my $test = shift;

  my @names = (qw/lag_groups mlag_domains lag_groups_complete/,
    grep { /^lag_/ } keys %SNMP::Info::IEEE802dot3ad::FUNCS);

  my @packages;
  find(
    sub {
      return unless /\.pm$/;
      my $path = $File::Find::name;
      $path =~ s{^.*?lib/}{};
      require $path;
      $path =~ s{\.pm$}{};
      $path =~ s{/}{::}g;
      push @packages, $path;
    },
    'lib/SNMP/Info'
  );

  my @collisions;
  foreach my $package (grep { $_ ne 'SNMP::Info::IEEE802dot3ad' } @packages) {
    no strict 'refs';
    foreach my $name (@names) {
      my $code = *{"${package}::$name"}{CODE};
      push @collisions, "$package defines sub $name"
        if $code and B::svref_2object($code)->GV->STASH->NAME eq $package;
      foreach my $hash (qw/FUNCS GLOBALS/) {
        my $value = ${"${package}::$hash"}{$name};
        next unless defined $value;
        next if $hash eq 'FUNCS'
          and $value eq $SNMP::Info::IEEE802dot3ad::FUNCS{$name};
        push @collisions, "$package has $hash key $name";
      }
    }
  }
  cmp_deeply(\@collisions, [], q(No other class defines a role name));
}

1;
