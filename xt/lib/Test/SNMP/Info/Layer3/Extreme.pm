# Test::SNMP::Info::Layer3::Extreme
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

package Test::SNMP::Info::Layer3::Extreme;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Extreme;

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
    '_layers' => 79,
    '_description' => 'ExtremeXOS version 12.3.4.12 v1234b12-patch1-6 by ',

    # EXTREME-BASE-MIB::summitX450-24x
    '_id'   => '.1.3.6.1.4.1.1916.2.65',
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

sub os : Tests(6) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'xos', q(ExtremeXOS description returns 'xos'));

  $test->{info}{_description}
    = 'Summit48 - Version 4.1.19 (Build 2) by Release_Master';
  is($test->{info}->os(), 'extremeware',
    q(ExtremeWare description returns 'extremeware'));

  $test->{info}{_description} = '5520-48SE-FabricEngine (8.10.1.0)';
  is($test->{info}->os(), 'voss', q(Fabric Engine description returns 'voss'));

  $test->{info}{_description} = 'VSP-7432CQ (8.0.5.0)';
  is($test->{info}->os(), 'voss', q(VSP description returns 'voss'));

  $test->{info}{_description} = 'XA1440 (8.2.0.0_B020) (PRIVATE)';
  is($test->{info}->os(), 'voss', q(XA1440 description returns 'voss'));
}

sub os_ver : Tests(7) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '12.3.4.12', q(ExtremeXOS version parsed));

  $test->{info}{_description}
    = 'Summit48 - Version 4.1.19 (Build 2) by Release_Master';
  is($test->{info}->os_ver(), '4.1.19', q(ExtremeWare version parsed));

  $test->{info}{_description} = '5520-48SE-FabricEngine (8.10.1.0)';
  is($test->{info}->os_ver(), '8.10.1.0', q(Fabric Engine version parsed));

  $test->{info}{_description} = 'VSP-7432CQ (8.0.5.0)';
  is($test->{info}->os_ver(), '8.0.5.0', q(VSP version parsed));

  $test->{info}{_description} = 'XA1440 (8.2.0.0_B020) (PRIVATE)';
  is($test->{info}->os_ver(), '8.2.0.0',
    q(XA1440 version parsed without build suffix));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef,
    q(No description returns undef OS version));
}

sub _prime_vlan_names {
  my $test = shift;

  $test->{info}{'_ex_vlan_descr'} = 1;
  $test->{info}{'_ex_vlan_id'}    = 1;
  $test->{info}{'_qb_v_name'}     = 1;
  $test->{info}{store}{ex_vlan_descr} = {1000004 => 'Default', 1000007 => 'v10'};
  $test->{info}{store}{ex_vlan_id}    = {1000004 => 1, 1000007 => 10};
  $test->{info}{store}{qb_v_name}     = {1 => 'Default', 10 => 'v10'};
  return;
}

sub v_name : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'v_name');

  $test->_prime_vlan_names();
  cmp_deeply($test->{info}->v_name(), {1000004 => 'Default', 1000007 => 'v10'},
    q(extremeVlanIfTable names are keyed by VLAN ifIndex));

  $test->{info}{store}{ex_vlan_descr} = {};
  cmp_deeply($test->{info}->v_name(), {1 => 'Default', 10 => 'v10'},
    q(Without extremeVlanIfTable Q-BRIDGE names are used));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->v_name(), {}, q(No data returns empty hash));
}

sub v_index : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'v_index');

  $test->_prime_vlan_names();
  cmp_deeply($test->{info}->v_index(), {1000004 => 1, 1000007 => 10},
    q(extremeVlanIfTable VLAN IDs are keyed by VLAN ifIndex));

  $test->{info}{store}{ex_vlan_descr} = {};
  $test->{info}{store}{ex_vlan_id}    = {};
  cmp_deeply($test->{info}->v_index(), {1 => 1, 10 => 10},
    q(Without extremeVlanIfTable Q-BRIDGE VLAN IDs are used));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->v_index(), {}, q(No data returns empty hash));
}

# EXOS 33.6.1.14: ports 1:1 and 1:2 are bridge ports 1 and 2. Port 1 is
# untagged in VLAN 10 and tagged in VLAN 20, port 2 is untagged in VLAN 1.
# No ifStackTable or extremeVlanEncapsIfTable.
sub _prime_qbridge_vlans {
  my $test = shift;

  $test->{info}{'_bp_index'}      = 1;
  $test->{info}{'_qb_i_vlan'}     = 1;
  $test->{info}{'_qb_v_egress'}   = 1;
  $test->{info}{'_qb_v_untagged'} = 1;
  $test->{info}{store}{bp_index}  = {1 => 1001, 2 => 1002};
  $test->{info}{store}{qb_i_vlan} = {1 => 10, 2 => 1};
  $test->{info}{store}{qb_v_egress}
    = {1 => pack('B*', '01'), 10 => pack('B*', '10'), 20 => pack('B*', '10')};
  $test->{info}{store}{qb_v_untagged}
    = {1 => pack('B*', '01'), 10 => pack('B*', '10'), 20 => pack('B*', '00')};
  return;
}

# ExtremeWare: VLAN interfaces 1000007 (VLAN 10) and 1000008 (VLAN 20) stack
# above ports, VLAN 20 through its encapsulation interface 5000
sub _prime_ifstack_vlans {
  my $test = shift;

  $test->{info}{'_ex_vlan_encap_tag'} = 1;
  $test->{info}{'_ifStackStatus'}     = 1;
  $test->{info}{store}{ex_vlan_encap_tag} = {5000 => 20};
  $test->{info}{store}{ifStackStatus} = {
    '1000007.1001' => 'active',
    '1000008.5000' => 'active',
    '5000.1002'    => 'active',
  };
  return;
}

# Records each set passed to the session as [leaf, iid, value]
sub _capture_sets {
  my $test = shift;

  my @sets;
  $test->{info}{sess}->mock(
    'set',
    sub {
      my ($session, $oid, $value) = @_;
      my ($leaf, $iid) = split(/\./, SNMP::translateObj($oid), 2);
      push @sets, [$leaf, $iid, $value];
      return 1;
    }
  );
  return \@sets;
}

sub set_i_vlan : Tests(7) {
  my $test = shift;

  can_ok($test->{info}, 'set_i_vlan');

  $test->_prime_qbridge_vlans();
  my $sets = $test->_capture_sets();
  ok($test->{info}->set_i_vlan(10, 1002),
    q(Without ifStack VLAN tables setting untagged VLAN succeeds));
  cmp_deeply($sets, [['dot1qPvid', 2, 10]],
    q(Untagged VLAN is set through dot1qPvid on the bridge port));

  @$sets = ();
  $test->_prime_qbridge_vlans();
  $test->{info}->set_i_vlan(20, 1001);
  cmp_deeply(
    $sets,
    [
      ['dot1qVlanStaticEgressPorts', 20, pack('B*', '00')],
      ['dot1qPvid', 1, 20],
    ],
    q(VLAN tagged on the port is removed from the egress list before PVID)
  );

  @$sets = ();
  $test->_prime_qbridge_vlans();
  ok(!defined $test->{info}->set_i_vlan(10, 1003),
    q(ifIndex that is not a bridge port returns undef));
  like($test->{info}->error(), qr/1003 is not a bridge port/,
    q(... and explains why));

  @$sets = ();
  $test->{info}->clear_cache();
  $test->_prime_ifstack_vlans();
  $test->{info}->set_i_vlan(20, 1001);
  cmp_deeply(
    $sets,
    [['ifStackStatus', '1000007.1001', 'destroy'],
     ['ifStackStatus', '1000008.1001', 'createAndGo']],
    q(With ifStack VLAN tables the ifStack method is still used)
  );
}

sub set_i_pvid : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'set_i_pvid');

  $test->_prime_qbridge_vlans();
  my $sets = $test->_capture_sets();
  ok($test->{info}->set_i_pvid(10, 1002),
    q(Without ifStack VLAN tables setting PVID succeeds));
  cmp_deeply($sets, [['dot1qPvid', 2, 10]],
    q(PVID is set through dot1qPvid on the bridge port));

  @$sets = ();
  $test->_prime_qbridge_vlans();
  ok(!defined $test->{info}->set_i_pvid(20, 1001),
    q(PVID of a VLAN tagged on the port returns undef));
  like($test->{info}->error(), qr/set_i_vlan/,
    q(... and points the caller at set_i_vlan));
}

sub set_add_i_vlan_tagged : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'set_add_i_vlan_tagged');

  $test->_prime_qbridge_vlans();
  my $sets = $test->_capture_sets();
  ok($test->{info}->set_add_i_vlan_tagged(20, 1002),
    q(Without ifStack VLAN tables adding a tagged VLAN succeeds));
  cmp_deeply($sets, [['dot1qVlanStaticEgressPorts', 20, pack('B*', '11')]],
    q(Bridge port is added to the VLAN egress list));

  @$sets = ();
  $test->_prime_qbridge_vlans();
  ok(!defined $test->{info}->set_add_i_vlan_tagged(30, 1002),
    q(VLAN missing from the egress table returns undef));
  like($test->{info}->error(), qr/VLAN 30 does not exist/,
    q(... and says the VLAN must be created first));
}

sub set_remove_i_vlan_tagged : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'set_remove_i_vlan_tagged');

  $test->_prime_qbridge_vlans();
  my $sets = $test->_capture_sets();
  ok($test->{info}->set_remove_i_vlan_tagged(20, 1001),
    q(Without ifStack VLAN tables removing a tagged VLAN succeeds));
  cmp_deeply($sets, [['dot1qVlanStaticEgressPorts', 20, pack('B*', '00')]],
    q(Bridge port is removed from the VLAN egress list));

  @$sets = ();
  $test->_prime_qbridge_vlans();
  ok(!defined $test->{info}->set_remove_i_vlan_tagged(10, 1001),
    q(Removing the untagged VLAN of the port returns undef));
  like($test->{info}->error(), qr/untagged/,
    q(... and says the VLAN is untagged on the port));
}

sub _prime_stp {
  my ($test, %store) = @_;

  $test->{info}->clear_cache();
  $test->{info}->cache({
    (map { ('_' . $_) => 1 } keys %store), store => \%store,
  });
  return;
}

sub i_stp_state : Tests(6) {
  my $test = shift;

  can_ok($test->{info}, 'i_stp_state');

  $test->_prime_stp(
    dot1dStpPortState => {1 => 'forwarding', 3 => 'blocking',
      12 => 'forwarding'},
    bp_index    => {1 => 1001, 3 => 1003},
    stp_p_state => {'1.1001' => 'forwarding'},
  );
  cmp_deeply($test->{info}->i_stp_state(),
    {1001 => 'forwarding', 1003 => 'blocking'},
    q(BRIDGE-MIB port states are keyed by ifIndex, unmapped ports skipped));

  $test->_prime_stp(
    dot1dStpPortState => {},
    bp_index    => {1 => 1001, 3 => 1003},
    stp_p_state => {'1.1001' => 'forwarding', '1.1003' => 'blocking'},
  );
  cmp_deeply($test->{info}->i_stp_state(), {},
    q(Without BRIDGE-MIB STP the vendor table is not used));

  # Without dot1dBasePortIfIndex, bp_index falls back to an ifIndex
  # identity map, so a bridge port number is read as an ifIndex.
  $test->_prime_stp(
    dot1dStpPortState => {1 => 'forwarding', 2 => 'blocking'},
    bp_index => {},
    i_index  => {1 => 1, 1001 => 1001},
  );
  cmp_deeply($test->{info}->i_stp_state(), {1 => 'forwarding'},
    q(Without dot1dBasePortIfIndex a port number matching an ifIndex is kept));

  $test->_prime_stp(
    dot1dStpPortState => {1 => 'forwarding'},
    bp_index => {},
    i_index  => {1001 => 1001},
  );
  cmp_deeply($test->{info}->i_stp_state(), {},
    q(Without dot1dBasePortIfIndex a port number matching no ifIndex is skipped));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_stp_state(), {}, q(No data returns empty hash));
}

# A served common-tree shape: the default must stay off until the family's own
# STP role reads its trees (s0 is the Default VLAN's tree under PVST+).
sub stp_trees_default_off : Tests(3) {
    my $test = shift;

    $test->{info}->cache(
        {   '_b_mac'        => pack( 'H*', '02000000000c' ),
            '_stp_priority' => 32768,
            '_stp_root'     => pack( 'H*', '100002000000000a' ),
            '_stp_p_id'     => 1,
            'store'         => { 'stp_p_id' => { 1 => 1, 2 => 2 } },
        }
    );
    cmp_deeply( $test->{info}->stp_trees(), {}, q(No common-tree default) );
    is( $test->{info}->stp_flavors(), undef, q(No flavors reported) );
    is( $test->{info}->stp_trees_complete(),
        0, q(Trees may exist unread) );
}

1;
