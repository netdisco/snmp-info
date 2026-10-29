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

sub _lag_vendor_domains__ist_and_vist_served__reports_both : Tests(2) {
  my $test = shift;

  $test->{info}->cache({
    _rc_ist_status  => 'up', _rc_ist_peer  => '10.1.1.2',
    _rc_ist_vlan    => 100,
    _rc_vist_status => 'up', _rc_vist_peer => '10.255.0.2',
    _rc_vist_vlan   => 4000,
  });
  my $domains = $test->{info}->_lag_vendor_domains();
  cmp_deeply([sort keys %$domains], [qw/ist vist/], 'Both domains served');
  is($domains->{vist}{peer}, '10.255.0.2', 'vIST peer read');
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

1;
