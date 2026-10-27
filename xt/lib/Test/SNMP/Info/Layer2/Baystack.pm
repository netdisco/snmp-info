# Test::SNMP::Info::Layer2::Baystack
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

package Test::SNMP::Info::Layer2::Baystack;

use Test::Class::Most parent => 'My::Test::Class';
use B ();

use SNMP::Info::Layer2::Baystack;

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
    '_layers' => 2,
    '_description' =>
      'Ethernet Routing Switch 4826GTS-PWR+  HW:04 FW:5.6.0.18  SW:v5.6.1.053',

    # SYNOPTICS-ROOT-MIB::sreg-ERS-4826GTS-PWR-PLUS
    '_id'   => '.1.3.6.1.4.1.45.3.78.1',
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'boss', q(OS returns 'boss'));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'avaya', q(Vendor returns 'avaya'));
}

sub model : Tests(6) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), '4826GTS-PWR-PLUS', q(Model is expected value));

  # Software build 303 must not be read as a BayStack 303
  $test->{info}->clear_cache();
  $test->{info}->cache({
    '_description' => 'Ethernet Routing Switch 4950GTS-PWR+     HW:02       '
      . 'FW:7.2.0.5   SW:v7.6.2.303 BN:303 (c) Extreme Networks',

    # SYNOPTICS-ROOT-MIB::sreg-ERS4950GTS-PWR-PLUS
    '_id' => '.1.3.6.1.4.1.45.3.82.4',
  });
  is($test->{info}->model(), '4950GTS-PWR-PLUS',
    q(Build number 303 in sysDescr does not override model));

  # The BayStack 303 and 304 share one sysObjectID
  $test->{info}->clear_cache();
  $test->{info}->cache({
    '_description' => 'Bay Networks, Inc. BayStack 303 Ethernet Switch '
      . 'Rev: 2.2.19.19-2.1.4.16',

    # SYNOPTICS-ROOT-MIB::sreg-BayStack303-304-Sw
    '_id' => '.1.3.6.1.4.1.45.3.32.1',
  });
  is($test->{info}->model(), '303', q(BayStack 303 model from sysDescr));

  $test->{info}->clear_cache();
  $test->{info}->cache({
    '_description' => 'Bay Networks, Inc. BayStack 304 Ethernet Switch '
      . 'Rev: 2.2.19.19-2.1.4.16',
    '_id' => '.1.3.6.1.4.1.45.3.32.1',
  });
  is($test->{info}->model(), '304', q(BayStack 304 model from sysDescr));

  $test->{info}->clear_cache();
  is($test->{info}->model(), undef, q(No id returns undef model));
}

# An ERS 4950-shaped cache: MSTP CIST rows only, indexed by bridge port, with
# dot1dStpPortEnable disabled and no rcStgPortTable. Bridge port 434 shows a
# port number above 64. MACs are synthetic.
sub _stp_cache {
  my ($test, @extra_ports) = @_;
  my $info = $test->{info};
  $info->clear_cache();

  my $id    = sub { pack('H*', shift) };
  my @ports = (1, 2, 434, @extra_ports);
  my %store = (
    bp_index          => {map { $_ => $_ } 1, 2, 434},
    rc_dot1d_p_enable => {map { $_ => 'disabled' } @ports},
    nn_cist_p_enable  => {map { $_ => 'enabled' } @ports},
    nn_cist_p_state   => {map { $_ => 'forwarding' } @ports},
    nn_cist_p_role    => {map { $_ => 'designated' } @ports},
    nn_cist_p_bridge  =>
      {map { $_ => $id->('800002000000000a') } @ports},
    nn_cist_p_port => {map { $_ => $id->('8001') } @ports},
  );
  $store{nn_cist_p_role}{2} = 'root';
  $store{nn_cist_p_enable}{2} = 'disabled';
  $store{nn_cist_p_state}{434} = 'discarding';
  $store{nn_cist_p_role}{434} = 'alternate';

  my %cache = (
    _nn_mst_version       => 'mstp',
    _nn_mst_brg_address   => $id->('02000000000a'),
    _nn_mst_cist_priority => 32768,
    _nn_mst_cist_root     => $id->('800002000000000b'),
  );
  $info->{store}{$_} = $store{$_} for keys %store;
  $info->{'_' . $_} = 1 for keys %store;
  $info->cache(\%cache);
  return;
}

sub stp_trees : Tests(5) {
  my $test = shift;
  my $info = $test->{info};

  is($info->can('stp_trees'), \&SNMP::Info::RapidCity::stp_trees,
    q(Resolves to RapidCity));

  $test->_stp_cache();
  my $trees = $info->stp_trees();
  cmp_deeply([keys %$trees], ['cist.0'], q(MSTP with CIST rows only));
  cmp_deeply(
    [@{$trees->{'cist.0'}}{qw/protocol measured ports_complete/}],
    ['mstp', 0, 1],
    q(cist.0 protocol, not measured, ports complete)
  );
  is($trees->{'cist.0'}{root}{mac}, '02:00:00:00:00:0b', q(CIST root));

  $test->_stp_cache(900);
  delete $info->{_stp_trees};
  is($info->stp_trees()->{'cist.0'}{ports_complete}, 0,
    q(Row at a bridge port with no bp_index entry: incomplete));
}

sub stp_tree_ports : Tests(7) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache();
  my $rows = $info->stp_tree_ports('cist.0');
  cmp_deeply([sort { $a <=> $b } keys %$rows], [1, 2, 434],
    q(Rows keyed by ifIndex, one above 64));
  is($rows->{434}{state}, 'discarding', q(State as served));
  is($rows->{434}{role}, 'alternate', q(Role normalized));
  is($rows->{2}{role_raw}, 'root', q(Role as served));
  cmp_deeply([map { $rows->{$_}{enabled} } 1, 2, 434], [1, 0, 1],
    q(enabled from nnMstCistForcePortState, not dot1dStpPortEnable));

  $test->_stp_cache(900);
  cmp_deeply([sort { $a <=> $b } keys %{$info->stp_tree_ports('cist.0')}],
    [1, 2, 434], q(Row at an unmapped bridge port is absent));

  $test->_stp_cache();
  is(scalar $info->stp_tree_ports('msti.1'), undef, q(No MSTI rows: no tree));
}

# The nnMst ForcePortState columns are indexed by bridge port, not ifIndex
sub stp_tree_ports_enable_index : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache();
  $info->{store}{bp_index} = {1 => 101, 2 => 102, 434 => 534};
  $info->{store}{nn_cist_p_enable} = {1 => 'enabled', 2 => 'disabled'};
  my $rows = $info->stp_tree_ports('cist.0');
  cmp_deeply([map { $rows->{$_}{enabled} } 101, 102], [1, 0],
    q(ForcePortState read at the bridge port, not the ifIndex));
  is($rows->{534}{enabled}, undef,
    q(No ForcePortState row: undef, never dot1dStpPortEnable));
}

# Under RSTP rcStgPortEnableStp is indexed by ifIndex, dot1dStpPortEnable by
# bridge port
sub stp_tree_ports_rstp_enable_index : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $test->_stp_cache();
  my %store = (
    bp_index          => {1 => 101, 2 => 102},
    nn_rst_p_state    => {1 => 'forwarding', 2 => 'forwarding'},
    rc_dot1d_p_enable => {1 => 'disabled', 2 => 'enabled'},
    rc_stp_p_enable   => {'101.1' => 'true'},
    nn_cist_p_enable  => {1 => 'disabled', 2 => 'disabled'},
  );
  $info->{store}{$_} = $store{$_} for keys %store;
  $info->{'_' . $_} = 1 for keys %store;
  $info->cache({
    _nn_mst_version => 'rstp', _nn_rst_version => 'rstp',
    _nn_mst_brg_address => 'x',
  });
  delete $info->{_stp_trees};
  my $rows = $info->stp_tree_ports('cist.0');
  is($rows->{101}{enabled}, 1,
    q(RSTP: rcStgPortEnableStp read at the ifIndex));
  is($rows->{102}{enabled}, 1,
    q(RSTP: no rcStgPort row, dot1dStpPortEnable at the bridge port));
}

# Versions as _rc_stp_protocol reads them: nnMstForceProtocolVersion, then
# nnRstDot1dStpVersion. No protocol primes neither.
my %faststart_versions = (
  mstp => {_nn_mst_version => 'mstp'},
  rstp => {_nn_mst_version => 'rstp', _nn_rst_version => 'rstp'},
  stp  => {_nn_mst_version => 'rstp', _nn_rst_version => 'stpCompatible'},
);

sub _faststart_cache {
  my ($test, $protocol, %store) = @_;
  $test->{info}->clear_cache();
  $test->{info}->cache({
    (map { ("_$_" => 1) } keys %store),
    %{$faststart_versions{$protocol // ''} || {}},
    store => \%store,
  });
  return;
}

sub i_faststart_enabled__baystack_class__resolves_to_rapidcity : Tests(1) {
  my $test = shift;

  is(
    B::svref_2object($test->{info}->can('i_faststart_enabled'))
      ->STASH->NAME,
    'SNMP::Info::RapidCity',
    q(Baystack resolves i_faststart_enabled to RapidCity)
  );
}

sub i_faststart_enabled__mstp__reads_nnmst_by_ifindex : Tests(1) {
  my $test = shift;

  $test->_faststart_cache('mstp',
    nn_cist_p_edge_admin => {1 => 'true', 2 => 'false', 434 => 'true'},
    nn_rst_p_edge_admin  => {1 => 'false', 2 => 'true', 9 => 'true'},
    is_edgeport_admin    => {1 => 'false'},
    bp_index             => {1 => 1001, 2 => 1002, 434 => 1434, 9 => 1009},
  );
  cmp_deeply(
    $test->{info}->i_faststart_enabled(),
    {1001 => 1, 1002 => 0, 1434 => 1},
    q(MSTP: nnMstCistPortAdminEdgeStatus only, mapped to ifIndex)
  );
}

sub i_faststart_enabled__nnmst_numeric__maps_1_and_2 : Tests(1) {
  my $test = shift;

  $test->_faststart_cache('mstp',
    nn_cist_p_edge_admin => {1 => 1, 2 => 2},
    bp_index             => {1 => 1001, 2 => 1002},
  );
  cmp_deeply(
    $test->{info}->i_faststart_enabled(),
    {1001 => 1, 1002 => 0},
    q(TruthValue true(1) and false(2) read as 1 and 0)
  );
}

sub i_faststart_enabled__rstp__reads_nnrst : Tests(1) {
  my $test = shift;

  $test->_faststart_cache('rstp',
    nn_cist_p_edge_admin => {},
    nn_rst_p_edge_admin  => {1 => 'false', 2 => 'true'},
    is_edgeport_admin    => {1 => 'true'},
    bp_index             => {1 => 1001, 2 => 1002},
  );
  cmp_deeply(
    $test->{info}->i_faststart_enabled(),
    {1001 => 0, 1002 => 1},
    q(RSTP: nnRstDot1dStpPortAdminEdgePort)
  );
}

sub i_faststart_enabled__rstp_with_nnmst_rows__ignores_nnmst : Tests(1) {
  my $test = shift;

  $test->_faststart_cache('rstp',
    nn_cist_p_edge_admin => {1 => 'true', 2 => 'true', 3 => 'true'},
    nn_rst_p_edge_admin  => {1 => 'false', 2 => 'true'},
    bp_index             => {1 => 1001, 2 => 1002, 3 => 1003},
  );
  cmp_deeply(
    $test->{info}->i_faststart_enabled(),
    {1001 => 0, 1002 => 1},
    q(RSTP: nnMst rows are not read)
  );
}

sub i_faststart_enabled__mstp_with_only_nnrst__falls_back_to_rstp_mib :
  Tests(1) {
  my $test = shift;

  $test->_faststart_cache('mstp',
    nn_cist_p_edge_admin => {},
    nn_rst_p_edge_admin  => {1 => 'true', 2 => 'true'},
    is_edgeport_admin    => {1 => 'false', 2 => 'true'},
    bp_index             => {1 => 1001, 2 => 1002},
  );
  cmp_deeply(
    $test->{info}->i_faststart_enabled(),
    {1001 => 0, 1002 => 1},
    q(MSTP with no nnMst rows: dot1dStpPortAdminEdgePort, not nnRst)
  );
}

sub i_faststart_enabled__rstp_nortel_tables_empty__falls_back_to_rstp_mib :
  Tests(1) {
  my $test = shift;

  $test->_faststart_cache('rstp',
    nn_cist_p_edge_admin => {},
    nn_rst_p_edge_admin  => {},
    is_edgeport_admin    => {1 => 'true', 2 => 'false'},
    bp_index             => {1 => 1001, 2 => 1002},
  );
  cmp_deeply(
    $test->{info}->i_faststart_enabled(),
    {1001 => 1, 1002 => 0},
    q(dot1dStpPortAdminEdgePort when neither Nortel table has rows)
  );
}

sub i_faststart_enabled__no_mstp_or_rstp__falls_back_to_rstp_mib :
  Tests(2) {
  my $test = shift;

  my %store = (
    nn_cist_p_edge_admin => {1 => 'true', 2 => 'true'},
    nn_rst_p_edge_admin  => {1 => 'true', 2 => 'true'},
    is_edgeport_admin    => {1 => 'false', 2 => 'true'},
    bp_index             => {1 => 1001, 2 => 1002},
  );
  $test->_faststart_cache(undef, %store);
  cmp_deeply(
    $test->{info}->i_faststart_enabled(),
    {1001 => 0, 1002 => 1},
    q(No protocol detected: dot1dStpPortAdminEdgePort)
  );

  $test->_faststart_cache('stp', %store);
  cmp_deeply(
    $test->{info}->i_faststart_enabled(),
    {1001 => 0, 1002 => 1},
    q(STP compatible: dot1dStpPortAdminEdgePort)
  );
}

sub i_faststart_enabled__port_absent_from_bp_index__skipped : Tests(1) {
  my $test = shift;

  $test->_faststart_cache('mstp',
    nn_cist_p_edge_admin => {1 => 'true', 9 => 'true'},
    bp_index             => {1 => 1001},
  );
  cmp_deeply($test->{info}->i_faststart_enabled(),
    {1001 => 1}, q(Bridge port without a bp_index row is skipped));
}

1;
