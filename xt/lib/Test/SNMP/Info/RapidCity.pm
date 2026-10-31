# Test::SNMP::Info::RapidCity
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

package Test::SNMP::Info::RapidCity;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::RapidCity;

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
  my $cache_data = {
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

sub _lag_vendor_domains__ist_served_only__no_domain : Tests(1) {
  my $test = shift;

  $test->{info}->cache({
    _rc_ist_status => 'up', _rc_ist_peer => '10.1.1.2', _rc_ist_vlan => 100,
  });
  cmp_deeply($test->{info}->_lag_vendor_domains(), {},
    'The IST is not read without the legacy mixin');
}

sub _lag_vendor_domains__vist_served__reports_vist : Tests(1) {
  my $test = shift;

  $test->{info}->cache({
    _rc_vist_status => 'up', _rc_vist_peer => '10.255.0.2',
    _rc_vist_vlan   => 4000,
  });
  cmp_deeply([keys %{$test->{info}->_lag_vendor_domains()}], ['vist'],
    'The virtual IST is reported');
}

sub i_duplex__port_rows_only : Tests(1) {
  my $test = shift;

  $test->{info}->cache({
    _rc_duplex => 1, _rc_cpu_duplex => 1,
    store => {rc_duplex => {65 => 'full'}, rc_cpu_duplex => {1 => 'half'}},
  });
  cmp_deeply($test->{info}->i_duplex(), {65 => 'full'},
    'Only the rcPortTable rows are reported');
}

sub _lag_vendor_domains__peer_unset__no_domain : Tests(1) {
  my $test = shift;

  $test->{info}->cache({
    _rc_ist_status => 'down', _rc_ist_peer => '0.0.0.0', _rc_ist_vlan => 0,
  });
  cmp_deeply($test->{info}->_lag_vendor_domains(), {},
    'An unset peer address is not a domain');
}

# rcMltPortMembers sets one bit per member ifIndex
sub _prime_mlt_members {
  my ($test, %members_of) = @_;

  my %ports;
  foreach my $id (keys %members_of) {
    my %member = map { $_ => 1 } @{$members_of{$id}};
    $ports{$id} = pack('B*', join('', map { $member{$_} ? 1 : 0 } 0 .. 199));
  }
  $test->{info}->cache({
    _rc_mlt_ports => 1, _rc_mlt_index => 1,
    store => {
      rc_mlt_ports => \%ports,
      rc_mlt_index => {map { $_ => 6143 + $_ } keys %members_of},
    },
  });
  return;
}

sub agg_ports : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'agg_ports');
  $test->_prime_mlt_members(1 => [192, 193], 2 => [194]);
  cmp_deeply($test->{info}->agg_ports(),
    {192 => 6144, 193 => 6144, 194 => 6145}, 'Members map to the MLT');
}

# Each read builds new hashes, so an answer that follows hash order varies
sub agg_ports__port_in_two_mlts__lowest_mlt_wins : Tests(1) {
  my $test = shift;

  my %answers;
  foreach my $read (1 .. 20) {
    $test->_prime_mlt_members(map { $_ => [192] } 1 .. 8);
    $answers{ $test->{info}->agg_ports()->{192} } = 1;
    $test->{info}->clear_cache();
  }
  cmp_deeply([keys %answers], [6144], 'MLT 1 on every read');
}

sub _port_list {
  my %member = map { $_ => 1 } @_;
  return pack('B*', join('', map { $member{$_} ? 1 : 0 } 0 .. 199));
}

# Port shapes from an ERS 4950 walk: rcVlanPortType is access on every
# port, whatever rcVlanPortPerformTagging says.
sub _prime_port_vlans {
  my ($test, $ports) = @_;

  my (%type, %tagging, %untag_def, %pvid, %members);
  foreach my $port (keys %$ports) {
    my $row = $ports->{$port};
    $type{$port}      = $row->{type};
    $tagging{$port}   = $row->{tagging}   if defined $row->{tagging};
    $untag_def{$port} = $row->{untag_def} if defined $row->{untag_def};
    $pvid{$port}      = $row->{pvid};
    push @{$members{$_}}, $port foreach @{$row->{vlans}};
  }
  $test->{info}->cache({
    _rcVlanPortType => 1, _rcVlanPortPerformTagging => 1,
    _rcVlanPortUntagDefaultVlan => 1, _rc_i_vlan_pvid => 1,
    _rc_vlan_members => 1,
    store => {
      rcVlanPortType              => \%type,
      rcVlanPortPerformTagging    => \%tagging,
      rcVlanPortUntagDefaultVlan  => \%untag_def,
      rc_i_vlan_pvid              => \%pvid,
      rc_vlan_members =>
        {map { $_ => _port_list(@{$members{$_}}) } keys %members},
    },
  });
  return;
}

sub i_vlan_membership_untagged : Tests(8) {
  my $test = shift;

  can_ok($test->{info}, 'i_vlan_membership_untagged');
  $test->_prime_port_vlans({
    1 => {type => 'access', tagging => 'untagPvidOnly', pvid => 315,
          vlans => [315, 331]},
    2 => {type => 'access', tagging => 'false', pvid => 315,
          vlans => [315]},
    3 => {type => 'access', pvid => 315, vlans => [315]},
    4 => {type => 'trunk', tagging => 'tagPvidOnly', pvid => 319,
          vlans => [315, 319, 331]},
    5 => {type => 'trunk', tagging => 'true', untag_def => 'true',
          pvid => 319, vlans => [315, 319]},
    50 => {type => 'access', tagging => 'true', pvid => 319,
           vlans => [315, 319, 331]},
    6 => {type => 'access', tagging => 'untagPvidOnly', pvid => 319,
          vlans => [315, 331]},
  });
  my $untagged = $test->{info}->i_vlan_membership_untagged();

  cmp_deeply($untagged->{1}, [315],
    'i_vlan_membership_untagged__untag_pvid_only__returns_pvid_alone');
  cmp_deeply($untagged->{2}, [315],
    'i_vlan_membership_untagged__tagging_false__returns_all_vlans');
  cmp_deeply($untagged->{3}, [315],
    'i_vlan_membership_untagged__no_tagging_access__returns_all_vlans');
  cmp_deeply($untagged->{4}, bag(315, 331),
    'i_vlan_membership_untagged__tag_pvid_only__returns_all_but_pvid');
  cmp_deeply($untagged->{5}, [319],
    'i_vlan_membership_untagged__untag_default_vlan__returns_pvid');
  ok(!exists $untagged->{50},
    'i_vlan_membership_untagged__tagging_true_on_access_type__returns_none');
  ok(!exists $untagged->{6},
    'i_vlan_membership_untagged__pvid_not_a_member__returns_none');
}

1;
