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
  $test->{info}{store}{_vlan_cfg_id} = {};
  cmp_deeply($test->{info}->i_vlan(), {101 => 10},
    q(Foundry falls back to Q-BRIDGE data when its VLAN tables are absent));
}

sub i_untagged : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_untagged');
  $test->_prime_vlan_data();
  cmp_deeply($test->{info}->i_untagged(), $test->{info}->i_vlan(),
    q(Foundry i_untagged aliases the untagged VLAN mapping));
}

sub i_vlan_membership : Tests(5) {
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

  $test->{info}{_bp_index} = 1;
  $test->{info}{store}{bp_index} = {1 => 101};
  $test->{info}{_qb_v_egress} = 1;
  $test->{info}{_qb_cv_egress} = 1;
  $test->{info}{store}{qb_cv_egress} = undef;
  $test->{info}{store}{qb_v_egress} = {10 => pack('B*', '1')};
  delete $test->{info}{_foundry_vlan_source};
  cmp_deeply($test->{info}->i_vlan_membership(), {101 => [10]},
    q(Q-BRIDGE membership takes priority when both sources have data));

  $test->{info}{store}{_vlan_member_vlan_id} = {};
  $test->{info}{store}{_vlan_member_port_id} = {};
  $test->{info}{store}{_vlan_member_status} = {};
  $test->{info}{store}{_vlan_member_tag_mode} = {};
  $test->{info}{store}{_vlan_cfg_id} = {};
  cmp_deeply($test->{info}->i_vlan_membership(), {101 => [10]},
    q(Foundry falls back to Q-BRIDGE membership when its VLAN tables are absent));
}

sub i_vlan_membership_untagged : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'i_vlan_membership_untagged');
  $test->_prime_vlan_data();
  cmp_deeply(
    $test->{info}->i_vlan_membership_untagged(),
    {1 => [13], 2 => [11], 12 => [11], 65 => [1], 66 => [1]},
    q(Foundry untagged membership includes only untagged rows)
  );

  $test->{info}{_bp_index} = 1;
  $test->{info}{store}{bp_index} = {1 => 101};
  $test->{info}{_qb_v_untagged} = 1;
  $test->{info}{_qb_cv_untagged} = 1;
  $test->{info}{store}{qb_cv_untagged} = undef;
  $test->{info}{store}{qb_v_untagged} = {10 => pack('B*', '1')};
  delete $test->{info}{_foundry_vlan_source};
  cmp_deeply($test->{info}->i_vlan_membership_untagged(), {101 => [10]},
    q(Q-BRIDGE untagged membership takes priority when both sources have data));

  $test->{info}{store}{_vlan_member_vlan_id} = {};
  $test->{info}{store}{_vlan_member_port_id} = {};
  $test->{info}{store}{_vlan_member_status} = {};
  $test->{info}{store}{_vlan_member_tag_mode} = {};
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

sub lag_groups_complete__trunk_walk_incomplete__returns_0 : Tests(2) {
    my $test = shift;

    $test->_prime_trunk( 1, 2, 3 );
    is( $test->{info}->lag_groups_complete(), 1, q(Trunk read in full) );
    $test->{info}{walk_status}{snMSTrunkPortList} = { complete => 0 };
    is( $test->{info}->lag_groups_complete(),
        0, q(Incomplete trunk walk gives 0) );
}

1;
