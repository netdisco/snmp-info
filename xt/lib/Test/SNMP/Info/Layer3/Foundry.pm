# Test::SNMP::Info::Layer3::Foundry
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

package Test::SNMP::Info::Layer3::Foundry;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Foundry;

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
  my $d_string = 'Brocade Communications Systems, Inc. ';
  $d_string .= 'Stacking System ICX6610-48-HPOE, ';
  $d_string .= 'IronWare Version 08.0.00aT7f1 ';
  my $cache_data = {
    '_layers'      => 6,
    '_description' => $d_string,

    # FOUNDRY-SN-ROOT-MIB::snFastIronStackICX6610Switch
    '_id'   => '.1.3.6.1.4.1.1991.1.3.48.3.1',
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

sub _prime_vlan_data {
  my $test = shift;
  my $info = $test->{info};

  $info->{__vlan_cfg_id} = 1;
  $info->{__vlan_cfg_name} = 1;
  $info->{__vlan_member_vlan_id} = 1;
  $info->{__vlan_member_port_id} = 1;
  $info->{__vlan_member_status} = 1;
  $info->{__vlan_member_tag_mode} = 1;
  $info->{store}{_vlan_cfg_id} = {
    1 => 1, 2 => 2, 11 => 11, 13 => 13, 161 => 161,
  };
  $info->{store}{_vlan_cfg_name} = {
    1 => 'DEFAULT-VLAN', 2 => '', 11 => 'ACCESS', 13 => 'MANAGEMENT', 161 => '',
  };

  # Representative rows observed on an ICX7150 running FastIron 09.0.00T213.
  # Table row indexes are vlan.ifIndex; tag mode is tagged(1)/untagged(2).
  $info->{store}{_vlan_member_vlan_id} = {
    '1.65' => 1, '1.66' => 1, '2.1' => 2, '11.1' => 11,
    '11.2' => 11, '11.12' => 11, '13.1' => 13, '99.2' => 99,
  };
  $info->{store}{_vlan_member_port_id} = {
    '1.65' => 65, '1.66' => 66, '2.1' => 1, '11.1' => 1,
    '11.2' => 2, '11.12' => 12, '13.1' => 1, '99.2' => 2,
  };
  $info->{store}{_vlan_member_status} = {
    '1.65' => 'valid', '1.66' => 2, '2.1' => 2, '11.1' => 2,
    '11.2' => 2, '11.12' => 2, '13.1' => 2, '99.2' => 1,
  };
  $info->{store}{_vlan_member_tag_mode} = {
    '1.65' => 2, '1.66' => 'untagged', '2.1' => 1, '11.1' => 'tagged',
    '11.2' => 2, '11.12' => 2, '13.1' => 2, '99.2' => 2,
  };
}

# FastIron's single spanning tree VLAN: every port is an untagged member,
# as on an ICX7150 stack running 08.0.80
sub _prime_single_stp_vlan {
  my $test = shift;
  my $store = $test->{info}{store};

  $store->{_vlan_cfg_id}{4094}   = 4094;
  $store->{_vlan_cfg_name}{4094} = 'Single-spanning-tree-vlan';
  foreach my $port (1, 2, 12) {
    $store->{_vlan_member_vlan_id}{"4094.$port"}  = 4094;
    $store->{_vlan_member_port_id}{"4094.$port"}  = $port;
    $store->{_vlan_member_status}{"4094.$port"}   = 2;
    $store->{_vlan_member_tag_mode}{"4094.$port"} = 2;
  }
}

# Q-BRIDGE data alongside the FastIron tables, port 1 in VLAN 10
sub _prime_qbridge_membership {
  my $test = shift;
  my $info = $test->{info};

  $info->{_bp_index} = 1;
  $info->{store}{bp_index} = {1 => 101};
  $info->{_qb_v_egress} = 1;
  $info->{_qb_cv_egress} = 1;
  $info->{store}{qb_cv_egress} = undef;
  $info->{store}{qb_v_egress} = {10 => pack('B*', '1')};
  $info->{_qb_v_untagged} = 1;
  $info->{_qb_cv_untagged} = 1;
  $info->{store}{qb_cv_untagged} = undef;
  $info->{store}{qb_v_untagged} = {10 => pack('B*', '1')};
  delete $info->{_foundry_member_source};
  delete $info->{_foundry_vlan_source};
}

sub _prime_ip_data {
  my $test = shift;
  my $info = $test->{info};
  my $idx = '16777219.172.16.17.8';

  $info->{__ip_if_index} = 1;
  $info->{__ip_if_address} = 1;
  $info->{__ip_if_netmask} = 1;
  $info->{__ip_if_status} = 1;
  $info->{store}{_ip_if_index} = {$idx => 16777219};
  $info->{store}{_ip_if_address} = {$idx => '172.16.17.8'};
  $info->{store}{_ip_if_netmask} = {$idx => '255.255.255.224'};
  $info->{store}{_ip_if_status} = {$idx => 'valid'};
}

sub _prime_ip_mib_data {
  my $test = shift;
  my $info = $test->{info};

  $info->{_old_ip_index} = 1;
  $info->{_old_ip_table} = 1;
  $info->{_old_ip_netmask} = 1;
  $info->{store}{old_ip_index} = {'192.0.2.10' => 4};
  $info->{store}{old_ip_table} = {'192.0.2.10' => '192.0.2.10'};
  $info->{store}{old_ip_netmask} = {'192.0.2.10' => '255.255.255.0'};
  delete $info->{_foundry_ip_source};
}

sub v_name : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'v_name');
  $test->_prime_vlan_data();

  cmp_deeply(
    $test->{info}->v_name(),
    {
      1 => 'DEFAULT-VLAN', 2 => '', 11 => 'ACCESS',
      13 => 'MANAGEMENT', 161 => '',
    },
    q(Foundry VLAN names include configured VLANs without names)
  );
  cmp_deeply(
    $test->{info}->v_index(),
    {1 => 1, 2 => 2, 11 => 11, 13 => 13, 161 => 161},
    q(Foundry VLAN index includes VLANs without member ports)
  );

  $test->{info}{_v_name} = 1;
  $test->{info}{store}{v_name} = {11 => 'Q-BRIDGE ACCESS'};
  delete $test->{info}{_foundry_vlan_source};
  cmp_deeply(
    $test->{info}->v_name(),
    {11 => 'Q-BRIDGE ACCESS'},
    q(Q-BRIDGE VLAN names take priority when both sources have data)
  );

  $test->{info}{store}{_vlan_cfg_name} = {};
  $test->{info}{store}{_vlan_cfg_id} = {};
  $test->{info}{store}{_vlan_member_vlan_id} = {};
  cmp_deeply(
    $test->{info}->v_name(),
    {11 => 'Q-BRIDGE ACCESS'},
    q(Foundry VLAN names fall back to Q-BRIDGE when its VLAN tables are absent)
  );
}

sub v_name_single_stp : Tests(2) {
  my $test = shift;

  $test->_prime_vlan_data();
  $test->_prime_single_stp_vlan();
  ok(!exists $test->{info}->v_name()->{4094},
    q(v_name__single_spanning_tree_vlan__is_hidden));

  $test->{info}{_v_name} = 1;
  $test->{info}{store}{v_name}
    = {11 => 'ACCESS', 4094 => 'Single-spanning-tree-vlan'};
  delete $test->{info}{_foundry_vlan_source};
  cmp_deeply($test->{info}->v_name(), {11 => 'ACCESS'},
    q(v_name__single_spanning_tree_vlan_in_qbridge__is_hidden));
}

sub i_vlan : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'i_vlan');
  $test->_prime_vlan_data();

  cmp_deeply(
    $test->{info}->i_vlan(),
    {1 => 13, 2 => 11, 12 => 11, 65 => 1, 66 => 1},
    q(Foundry i_vlan returns each port's untagged VLAN)
  );
  cmp_deeply(
    $test->{info}->i_vlan(2),
    {2 => 11},
    q(Foundry i_vlan supports an ifIndex partial)
  );

  $test->{info}{_bp_index} = 1;
  $test->{info}{store}{bp_index} = {1 => 101};
  $test->{info}{_qb_i_vlan} = 1;
  $test->{info}{store}{qb_i_vlan} = {1 => 10};
  delete $test->{info}{_foundry_vlan_source};
  cmp_deeply($test->{info}->i_vlan(), {101 => 10},
    q(Q-BRIDGE port VLAN data takes priority when both sources have data));

  $test->{info}{store}{_vlan_member_vlan_id} = {};
  $test->{info}{store}{_vlan_member_port_id} = {};
  $test->{info}{store}{_vlan_member_status} = {};
  $test->{info}{store}{_vlan_member_tag_mode} = {};
  delete $test->{info}{_foundry_member_source};
  $test->{info}{store}{_vlan_cfg_id} = {};
  cmp_deeply($test->{info}->i_vlan(), {101 => 10},
    q(Foundry falls back to Q-BRIDGE data when its VLAN tables are absent));
}

sub i_vlan_single_stp : Tests(3) {
  my $test = shift;

  $test->_prime_vlan_data();
  $test->_prime_single_stp_vlan();
  cmp_deeply(
    $test->{info}->i_vlan(),
    {1 => 13, 2 => 11, 12 => 11, 65 => 1, 66 => 1},
    q(i_vlan__single_spanning_tree_vlan__is_not_the_port_vlan)
  );
  cmp_deeply(
    $test->{info}->i_vlan_membership(),
    {1 => bag(2, 11, 13), 2 => [11], 12 => [11], 65 => [1], 66 => [1]},
    q(i_vlan_membership__single_spanning_tree_vlan__is_hidden)
  );
  cmp_deeply(
    $test->{info}->i_vlan_membership_untagged(),
    {1 => [13], 2 => [11], 12 => [11], 65 => [1], 66 => [1]},
    q(i_vlan_membership_untagged__single_spanning_tree_vlan__is_hidden)
  );
}

sub i_untagged : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_untagged');
  $test->_prime_vlan_data();
  cmp_deeply($test->{info}->i_untagged(), $test->{info}->i_vlan(),
    q(Foundry i_untagged aliases the untagged VLAN mapping));
}

sub i_vlan_membership : Tests(6) {
  my $test = shift;

  can_ok($test->{info}, 'i_vlan_membership');
  $test->_prime_vlan_data();

  cmp_deeply(
    $test->{info}->i_vlan_membership(),
    {1 => bag(2, 11, 13), 2 => [11], 12 => [11], 65 => [1], 66 => [1]},
    q(Foundry membership includes tagged and untagged VLANs but skips invalid rows)
  );
  cmp_deeply(
    $test->{info}->i_vlan_membership(2),
    {2 => [11]},
    q(Foundry membership supports an ifIndex partial)
  );

  $test->_prime_qbridge_membership();
  cmp_deeply(
    $test->{info}->i_vlan_membership(),
    {1 => bag(2, 11, 13), 2 => [11], 12 => [11], 65 => [1], 66 => [1]},
    q(i_vlan_membership__fastiron_tag_mode_present__prefers_fastiron)
  );

  $test->{info}{store}{_vlan_member_tag_mode} = {};

  delete $test->{info}{_foundry_member_source};
  cmp_deeply($test->{info}->i_vlan_membership(), {101 => [10]},
    q(i_vlan_membership__no_fastiron_tag_mode__uses_qbridge));

  $test->{info}{store}{_vlan_member_vlan_id} = {};
  $test->{info}{store}{_vlan_member_port_id} = {};
  $test->{info}{store}{_vlan_member_status} = {};
  $test->{info}{store}{_vlan_member_tag_mode} = {};
  delete $test->{info}{_foundry_member_source};
  $test->{info}{store}{_vlan_cfg_id} = {};
  cmp_deeply($test->{info}->i_vlan_membership(), {101 => [10]},
    q(Foundry falls back to Q-BRIDGE membership when its VLAN tables are absent));
}

sub i_vlan_membership_untagged : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'i_vlan_membership_untagged');
  $test->_prime_vlan_data();
  cmp_deeply(
    $test->{info}->i_vlan_membership_untagged(),
    {1 => [13], 2 => [11], 12 => [11], 65 => [1], 66 => [1]},
    q(Foundry untagged membership includes only untagged rows)
  );

  $test->_prime_qbridge_membership();
  cmp_deeply(
    $test->{info}->i_vlan_membership_untagged(),
    {1 => [13], 2 => [11], 12 => [11], 65 => [1], 66 => [1]},
    q(i_vlan_membership_untagged__fastiron_tag_mode_present__prefers_fastiron)
  );

  $test->{info}{store}{_vlan_member_tag_mode} = {};

  delete $test->{info}{_foundry_member_source};
  cmp_deeply($test->{info}->i_vlan_membership_untagged(), {101 => [10]},
    q(i_vlan_membership_untagged__no_fastiron_tag_mode__uses_qbridge));

  $test->{info}{store}{_vlan_member_vlan_id} = {};
  $test->{info}{store}{_vlan_member_port_id} = {};
  $test->{info}{store}{_vlan_member_status} = {};
  $test->{info}{store}{_vlan_member_tag_mode} = {};
  delete $test->{info}{_foundry_member_source};
  $test->{info}{store}{_vlan_cfg_id} = {};
  cmp_deeply($test->{info}->i_vlan_membership_untagged(), {101 => [10]},
    q(Foundry falls back to Q-BRIDGE untagged membership when its VLAN tables are absent));
}

sub ip_index : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'ip_index');
  $test->_prime_ip_data();
  cmp_deeply($test->{info}->ip_index(), {'172.16.17.8' => 16777219},
    q(Foundry maps interface addresses to ifIndex));

  $test->_prime_ip_mib_data();
  cmp_deeply($test->{info}->ip_index(), {'192.0.2.10' => 4},
    q(Standard IP-MIB data takes priority when both sources have data));

  $test->{info}{store}{_ip_if_address} = {};
  cmp_deeply($test->{info}->ip_index(), {'192.0.2.10' => 4},
    q(Foundry falls back to the standard IP-MIB address table));
}

sub ip_table : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'ip_table');
  $test->_prime_ip_data();
  cmp_deeply($test->{info}->ip_table(), {'172.16.17.8' => '172.16.17.8'},
    q(Foundry returns IP address table keyed by address));

  $test->_prime_ip_mib_data();
  cmp_deeply($test->{info}->ip_table(), {'192.0.2.10' => '192.0.2.10'},
    q(Standard IP-MIB data takes priority when both sources have data));

  $test->{info}{store}{_ip_if_address} = {};
  cmp_deeply($test->{info}->ip_table(), {'192.0.2.10' => '192.0.2.10'},
    q(Foundry falls back to the standard IP-MIB address table));
}

sub ip_netmask : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'ip_netmask');
  $test->_prime_ip_data();
  cmp_deeply($test->{info}->ip_netmask(), {'172.16.17.8' => '255.255.255.224'},
    q(Foundry returns the interface subnet mask));

  $test->_prime_ip_mib_data();
  cmp_deeply($test->{info}->ip_netmask(), {'192.0.2.10' => '255.255.255.0'},
    q(Standard IP-MIB data takes priority when both sources have data));

  $test->{info}{store}{_ip_if_address} = {};
  cmp_deeply($test->{info}->ip_netmask(), {'192.0.2.10' => '255.255.255.0'},
    q(Foundry falls back to the standard IP-MIB address table));
}

# A served common-tree shape still reports no trees, since the default tree is
# not the common tree: per-VLAN STP.
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
    is( $test->{info}->stp_protocols(), undef, q(No protocols reported) );
    is( $test->{info}->stp_trees_complete(),
        0, q(Trees may exist unread) );
}

# snMSTrunkPortList lists the trunk's ports, its master among them, as
# 16-bit switch port indexes
sub _prime_trunk {
    my ( $test, @ports ) = @_;

    $test->{info}->cache(
        {   '_snMSTrunkPortList' => 1,
            '_snSwPortIfIndex'   => 1,
            'store'              => {
                'snMSTrunkPortList' => { 1 => pack( 'n*', @ports ) },
                'snSwPortIfIndex' => { 1 => 101, 2 => 102, 3 => 103 },
            },
        }
    );
    return;
}

# Runs $code, dying instead of hanging when it loops
sub _within_seconds {
    my ( $seconds, $code ) = @_;

    local $SIG{ALRM} = sub { die "timed out\n" };
    alarm $seconds;
    my $result = eval { $code->() };
    my $error  = $@;
    alarm 0;
    die $error if $error;
    return $result;
}

sub agg_ports : Tests(2) {
    my $test = shift;

    can_ok( $test->{info}, 'agg_ports' );
    $test->_prime_trunk( 1, 2, 3 );
    cmp_deeply(
        _within_seconds( 5, sub { $test->{info}->agg_ports() } ),
        { 102 => 101, 103 => 101 },
        q(Members map to the master; the master is not its own member)
    );
}

sub agg_ports__member_without_ifindex__skipped_without_looping : Tests(1) {
    my $test = shift;

    $test->_prime_trunk( 1, 2, 9, 3 );
    cmp_deeply(
        _within_seconds( 5, sub { $test->{info}->agg_ports() } ),
        { 102 => 101, 103 => 101 },
        q(Port 9 has no ifIndex; the ports after it are still read)
    );
}

# Shaped from an ICX7150-C12-POE on FastIron 10.0.10: a powered device on
# port 2, nothing on port 1, no PoE hardware on the uplinks. Port 3 is
# disabled for coverage.
sub _prime_poe_fastiron10 {
    my $test = shift;

    my %store = (
        'i_description' => {
            1   => 'GigabitEthernet1/1/1',
            2   => 'GigabitEthernet1/1/2',
            3   => 'GigabitEthernet1/1/3',
            65  => 'GigabitEthernet1/2/1',
            129 => '10GigabitEthernet1/3/1',
        },
        'snAgentPoePortNumber' =>
            { 1 => 1, 2 => 2, 3 => 3, 65 => 65, 129 => 129 },
        'snAgentPoePortControl' => {
            1   => 'enable',
            2   => 'enable',
            3   => 'disable',
            65  => 'other',
            129 => 'other'
        },
        'snAgentPoePortWattage' =>
            { 1 => 0, 2 => 30000, 3 => 0, 65 => 0, 129 => 0 },
        'snAgentPoePortClass' =>
            { 1 => 0, 2 => 0, 3 => 0, 65 => 0, 129 => 0 },
        'snAgentPoePortConsumed' =>
            { 1 => 0, 2 => 6900, 3 => 0, 65 => 0, 129 => 0 },
        'snAgentPoePortPDClass' =>
            { 1 => 0, 2 => 4, 3 => 0, 65 => 0, 129 => 0 },
    );
    $test->{info}->cache(
        { ( map { ( "_$_" => 1 ) } keys %store ), 'store' => \%store } );
    return;
}

# Shaped from an ICX6450-24-HPOE on FastIron 08.0: no
# snAgentPoePortPDClass, and the class is reported in snAgentPoePortClass.
sub _prime_poe_fastiron8 {
    my $test = shift;

    my %store = (
        'i_description' => {
            1  => 'GigabitEthernet1/1/1',
            2  => 'GigabitEthernet1/1/2',
            65 => 'GigabitEthernet1/2/1',
        },
        'snAgentPoePortNumber'  => { 1 => 1, 2 => 2, 65 => 65 },
        'snAgentPoePortControl' =>
            { 1 => 'enable', 2 => 'enable', 65 => 'other' },
        'snAgentPoePortWattage'  => { 1 => 15400, 2 => 30000, 65 => 0 },
        'snAgentPoePortClass'    => { 1 => 3,     2 => 0,     65 => 0 },
        'snAgentPoePortConsumed' => { 1 => 6948,  2 => 0,     65 => 0 },
    );
    $test->{info}->cache(
        { ( map { ( "_$_" => 1 ) } keys %store ), 'store' => \%store } );
    return;
}

sub peth_port_ifindex : Tests(2) {
    my $test = shift;

    can_ok( $test->{info}, 'peth_port_ifindex' );
    $test->_prime_poe_fastiron10();
    cmp_deeply(
        $test->{info}->peth_port_ifindex(),
        { '1.1' => 1, '1.2' => 2, '1.3' => 3 },
        q(Ports without inline power capability are not PoE ports)
    );
}

sub peth_port_admin : Tests(2) {
    my $test = shift;

    can_ok( $test->{info}, 'peth_port_admin' );
    $test->_prime_poe_fastiron10();
    cmp_deeply(
        $test->{info}->peth_port_admin(),
        { '1.1' => 'true', '1.2' => 'true', '1.3' => 'false' },
        q(Admin state from snAgentPoePortControl)
    );
}

sub peth_port_status : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'peth_port_status' );
    $test->_prime_poe_fastiron10();
    cmp_deeply(
        $test->{info}->peth_port_status(),
        {   '1.1' => 'searching',
            '1.2' => 'deliveringPower',
            '1.3' => 'disabled'
        },
        q(Only a port consuming power is delivering it)
    );

    $test->{info}->clear_cache();
    $test->_prime_poe_fastiron8();
    cmp_deeply(
        $test->{info}->peth_port_status(),
        { '1.1' => 'deliveringPower', '1.2' => 'searching' },
        q(FastIron 08.0 status from consumed power)
    );
}

sub peth_port_class : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'peth_port_class' );
    $test->_prime_poe_fastiron10();
    cmp_deeply(
        $test->{info}->peth_port_class(),
        { '1.2' => 'class4' },
        q(Class the powered device signalled, not the configured class)
    );

    $test->{info}->clear_cache();
    $test->_prime_poe_fastiron8();
    cmp_deeply(
        $test->{info}->peth_port_class(),
        { '1.1' => 'class3' },
        q(Without snAgentPoePortPDClass the class is snAgentPoePortClass)
    );
}

sub peth_port_neg_power : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'peth_port_neg_power' );
    $test->_prime_poe_fastiron10();
    cmp_deeply(
        $test->{info}->peth_port_neg_power(),
        { '1.2' => 30000 },
        q(Allocated power of the port delivering power)
    );

    $test->{info}->clear_cache();
    $test->_prime_poe_fastiron8();
    cmp_deeply(
        $test->{info}->peth_port_neg_power(),
        { '1.1' => 15400 },
        q(No allocation reported for a port without a powered device)
    );
}

sub peth_port_power : Tests(2) {
    my $test = shift;

    can_ok( $test->{info}, 'peth_port_power' );
    $test->_prime_poe_fastiron10();
    cmp_deeply(
        $test->{info}->peth_port_power(),
        { '1.2' => 6900 },
        q(Consumed power of ports drawing power)
    );
}

sub model : Tests(5) {
    my $test = shift;

    can_ok( $test->{info}, 'model' );
    is( $test->{info}->model(),
        'FastIronStackICX6610', q(A stack keeps the sysObjectID name) );

    my %cases = (
        'Ruckus Wireless, Inc. ICX7150-C12-POE, IronWare Version '
            . '10.0.10g_cd11T213 Compiled on Sep  1 2026 at 00:52:40 '
            . 'labeled as SPR10010g_cd11' => [
            '.1.3.6.1.4.1.1991.1.3.64.3.1.1.2',
            'ICX7150-C12-POE',
            q(FastIron 10 standalone model from sysDescr)
            ],
        'Brocade Communications Systems, Inc. ICX6450-24-HPOE, IronWare '
            . 'Version 08.0.30tT311 Compiled on Jun 28 2021 at 23:03:01 '
            . 'labeled as ICX64S08030t' => [
            '.1.3.6.1.4.1.1991.1.3.58.1.2.1.1',
            'ICX6450-24-HPOE',
            q(FastIron 08 standalone model from sysDescr)
            ],
        'Foundry Networks, Inc. FESX424, IronWare Version 03.1.00b36T3e1 '
            . 'Compiled on Feb 27 2006 at 14:37:58 labeled as SXR03100b36' =>
            [
            '.1.3.6.1.4.1.1991.1.3.34.1.1.1.2', 'FESX424Router',
            q(Non-ICX model from sysObjectID)
            ],
    );
    foreach my $descr ( sort keys %cases ) {
        my ( $id, $model, $name ) = @{ $cases{$descr} };
        $test->{info}->clear_cache();
        $test->{info}->cache(
            { '_description' => $descr, '_id' => $id, 'store' => {} } );
        is( $test->{info}->model(), $model, $name );
    }
}

# Shaped from an ICX7150-C12-POE on FastIron 10.0.10, which keys
# ifMauAutoNegTable by ifIndex alone. Port 129 is fixed at 1 Gbps.
sub _prime_port_config {
    my ( $test, $autoneg_keys ) = @_;

    my %store = (
        '_mau_autoneg_admin' => {
            $autoneg_keys->[0] => 'enabled',
            $autoneg_keys->[1] => 'disabled',
        },
        '_sw_if_speed'  => { 1 => 'sAutoSense', 129 => 's1G' },
        '_sw_if_duplex' => { 1 => 'fullDuplex', 129 => 'fullDuplex' },
    );
    $test->{info}->cache(
        { ( map { ( "_$_" => 1 ) } keys %store ), 'store' => \%store } );
    return;
}

sub i_speed_admin : Tests(4) {
    my $test = shift;

    can_ok( $test->{info}, 'i_speed_admin' );
    $test->_prime_port_config( [ 1, 129 ] );
    cmp_deeply(
        $test->{info}->i_speed_admin(),
        { 1 => 'auto', 129 => '1.0 Gbps' },
        q(Auto-negotiating port is auto, a fixed port its configured speed)
    );

    $test->{info}->clear_cache();
    $test->_prime_port_config( [ '1.1', '129.1' ] );
    cmp_deeply(
        $test->{info}->i_speed_admin(),
        { 1 => 'auto', 129 => '1.0 Gbps' },
        q(ifMauAutoNegTable keyed by ifIndex and MAU index)
    );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->i_speed_admin(),
        {}, q(No MAU-MIB, as on FastIron 08.0, gives nothing) );
}

sub i_duplex_admin : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'i_duplex_admin' );
    $test->_prime_port_config( [ 1, 129 ] );
    cmp_deeply(
        $test->{info}->i_duplex_admin(),
        { 1 => 'auto', 129 => 'full' },
        q(Auto-negotiating port is auto, a fixed port its configured duplex)
    );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->i_duplex_admin(),
        {}, q(No MAU-MIB, as on FastIron 08.0, gives nothing) );
}

sub lag_groups_complete__trunk_walk_incomplete__returns_0 : Tests(2) {
    my $test = shift;

    $test->_prime_trunk( 1, 2, 3 );
    is( $test->{info}->lag_groups_complete(), 1, q(Trunk read in full) );
    $test->{info}{walk_status}{snMSTrunkPortList} = { complete => 0 };
    is( $test->{info}->lag_groups_complete(),
        0, q(Incomplete trunk walk gives 0) );
}

1;
