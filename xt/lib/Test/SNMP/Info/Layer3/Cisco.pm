# Test::SNMP::Info::Layer3::Cisco
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

package Test::SNMP::Info::Layer3::Cisco;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Cisco;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $d_string = 'Cisco Internetwork Operating System Software ';
  $d_string .= 'IOS (tm) C1700 Software (C1700-NY-M), ';
  $d_string .= 'Version 12.2(8)YM, EARLY DEPLOYMENT RELEASE SOFTWARE (fc1)';
  my $cache_data = {
    '_layers'      => 78,
    '_description' => $d_string,

    # CISCO-PRODUCTS-MIB::cisco1721
    '_id'                 => '.1.3.6.1.4.1.9.1.444',
    '_vtp_version'        => 2,
    '_i_type'             => 1,
    '_i_description'      => 1,
    '_c_eigrp_peers'      => 1,
    '_c_eigrp_peer_types' => 1,
    'store'               => {
      'i_type' => {
        1 => 'ppp',
        2 => 'ethernetCsmacd',
        3 => 'other',
        4 => 'l2vlan',
        5 => 'l2vlan'
      },
      'i_description' => {
        1 => 'Serial0',
        2 => 'FastEthernet0',
        3 => 'Null0',
        4 => 'FastEthernet0.101-802.1Q vLAN subif',
        5 => 'FastEthernet0.102-802.1Q vLAN subif'
      },
      'c_eigrp_peers' => {
        '0.5.0'      => '1.2.3.4',
        '0.5.1'      => pack("H*", '0A141E28'),
        '0.10.1'     => 'host.my.dns',
        '65536.10.2' => '::1.2.3.4',
        '65536.10.3' => 'fe80::2d0:b7ff:fe21:c6c0'
      },
      'c_eigrp_peer_types' => {
        '0.5.0'      => 'ipv4',
        '0.5.1'      => 'ipv4',
        '0.10.1'     => 'dns',
        '65536.10.2' => 'ipv6',
        '65536.10.3' => 'ipv6',
      },
    },
  };
  $test->{info}->cache($cache_data);
}

# This class is a collection of roles and not meant to instantiated for a
# specific device. Don't test device class and no need to setup data
sub device_type : Tests(1) {
  my $test  = shift;
  my $class = $test->class;

  can_ok($test->{info}, 'device_type');

}

# Only going to test the non-VTP path in this class and assume CiscoVTP will
# test the SUPER::i_vlan method, since this class will handle traditional
# routers that usually don't have VTP.
sub i_vlan : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_vlan');

  my $expected = {4 => 101, 5 => 102};

  cmp_deeply($test->{info}->i_vlan(),
    $expected, q(802.1Q interfaces have expected VLAN values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_vlan(), {}, q(No data data returns empty hash));
}

sub cisco_comm_indexing : Tests(3) {
  my $test = shift;

  can_ok $test->{info}, 'cisco_comm_indexing';
  is($test->{info}->cisco_comm_indexing(),
    1, 'VTP version, Cisco community indexing on');

  $test->{info}->clear_cache();
  is($test->{info}->cisco_comm_indexing(), 0, 'Cisco community indexing off');
}

sub eigrp_peers : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'eigrp_peers');

  my $expected = {
    '0.5.0'      => '1.2.3.4',
    '0.5.1'      => '10.20.30.40',
    '65536.10.2' => '0:0:0:0:0:0:102:304',
    '65536.10.3' => 'fe80:0:0:0:2d0:b7ff:fe21:c6c0'
  };

  cmp_deeply($test->{info}->eigrp_peers(),
    $expected, q(EIGRP peers have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->eigrp_peers(),
    {}, q(No data data returns empty hash));
}

# A served common-tree shape with no stpxSpanningTreeType reports no trees:
# the default tree is VLAN 1's under PVST, VLAN 1's ports under MST.
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

# IOS-XE (IOL) PE shape: mplsL3VpnVrfTable and mplsL3VpnIfConfTable rows, with the
# length-prefixed VRF name as the first index arcs.
my %NAME_IID = (
    red   => '3.114.101.100',
    blue  => '4.98.108.117.101',
    grey  => '4.103.114.101.121',
    green => '5.103.114.101.101.110',
);

sub _prime_mpls_rows {
    my $test = shift;
    my $info = $test->{info};

    $info->{_vrf_l3vpn_descr} = 1;
    $info->{_vrf_l3vpn_if}    = 1;
    $info->{store}{vrf_l3vpn_descr} = { map { $_ => q() } values %NAME_IID };
    $info->{store}{vrf_l3vpn_if}    = {
        "$NAME_IID{red}.2"   => 'active',
        "$NAME_IID{red}.4"   => 'active',
        "$NAME_IID{blue}.3"  => 'active',
        "$NAME_IID{blue}.5"  => 'active',
        "$NAME_IID{green}.6" => 'active',
        "$NAME_IID{grey}.10" => 'active',
    };
    return;
}

# CISCO-VRF-MIB as an IOS-XE PE serves it: cvVrfName by cvVrfIndex, and
# cvVrfInterfaceRowStatus by cvVrfIndex.ifIndex
sub _prime_cisco_vrf_mib {
    my $test = shift;
    my $info = $test->{info};

    $info->{_vrf_cv_name} = 1;
    $info->{_vrf_cv_if}   = 1;
    $info->{store}{vrf_cv_name}
        = { 1 => 'red', 2 => 'blue', 3 => 'green', 4 => 'grey' };
    $info->{store}{vrf_cv_if} = {
        '1.2' => 'active', '1.4'  => 'active', '2.3' => 'active',
        '2.5' => 'active', '3.6'  => 'active', '4.10' => 'active',
    };
    return;
}

sub vrf_instances__cisco_vrf_mib__fallback : Tests(5) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_cisco_vrf_mib();
    my $instances = $info->vrf_instances();
    cmp_deeply( [ sort keys %$instances ],
        [qw/blue default green grey red/],
        q(Each CISCO-VRF-MIB name and default are listed) );
    is( $instances->{red}{sources}{list},
        'CISCO-VRF-MIB', q(The list source is the vendor MIB) );
    cmp_deeply(
        $info->i_vrf(),
        {   2  => 'red',  4 => 'red',   3 => 'blue',
            5  => 'blue', 6 => 'green', 10 => 'grey'
        },
        q(The vendor interface rows give i_vrf)
    );
    cmp_deeply(
        [ grep { $instances->{$_}{sources}{members} } sort keys %$instances ],
        [qw/blue green grey red/],
        q(Each instance holding a port records the members source)
    );
    is( $instances->{red}{sources}{members},
        'CISCO-VRF-MIB', q(The members source is the vendor MIB) );
}

sub vrf_instances__mpls_list_vendor_members__members_source_is_mpls
    : Tests(1) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_mpls_rows();
    my $instances = $info->vrf_instances();
    is( $instances->{red}{sources}{members},
        'MPLS-L3VPN-STD-MIB', q(MPLS-L3VPN-STD-MIB rows name their MIB) );
}

sub vrf_instances__vendor_list__contexts_set_once : Tests(1) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_cisco_vrf_mib();
    my %calls;
    no warnings qw/once redefine/;
    local *SNMP::Info::Layer3::Cisco::_vrf_set_contexts
        = sub { $calls{ $_[1]{name} }++; return };
    $info->vrf_instances();
    cmp_deeply( \%calls,
        { map { $_ => 1 } qw/red blue green grey default/ },
        q(Each vendor-listed record gets its contexts once) );
}

sub i_vrf__cisco_vrf_mib_rows_skipped__only_active_valid_named : Tests(1) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_cisco_vrf_mib();
    $info->{store}{vrf_cv_name}{5} = 'default';
    $info->{store}{vrf_cv_name}{6} = q();
    $info->{store}{vrf_cv_name}{7} = 'mgmt';
    $info->{store}{vrf_cv_if} = {
        '1.2'   => 'active',
        '1.4'   => 'notInService',
        '2.3.9' => 'active',
        '2'     => 'active',
        '5.7'   => 'active',
        '6.8'   => 'active',
        '9.11'  => 'active',
        '7.12'  => 'active',
    };
    no warnings qw/once redefine/;
    local *SNMP::Info::Layer3::Cisco::_vrf_internal_instance
        = sub { return $_[1] eq 'mgmt' ? 1 : 0 };
    cmp_deeply( $info->i_vrf(), { 2 => 'red' },
        q(Inactive, malformed, default, internal, unnamed and unknown rows skip)
    );
}

sub vrf_instances__mpls_rows__cisco_vrf_mib_unread : Tests(3) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_mpls_rows();
    $test->_prime_cisco_vrf_mib();
    $info->{store}{vrf_cv_name}{5} = 'amber';
    my $instances = $info->vrf_instances();
    is( $instances->{red}{sources}{list},
        'MPLS-L3VPN-STD-MIB', q(MPLS-L3VPN-STD-MIB lists) );
    ok( !exists $instances->{amber}, q(The vendor MIB adds no instance) );
    $info->vrf_instances_complete();
    ok( !( grep { /^vrf_cv_/ } keys %{ $info->walk_status() } ),
        q(Neither CISCO-VRF-MIB table was walked) );
}

sub vrf_instances_complete__cisco_vrf_mib__is_1 : Tests(2) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_cisco_vrf_mib();
    is( $info->vrf_instances_complete(), 1, q(A whole vendor list) );

    $info->{walk_status}{vrf_cv_if} = { complete => 0, reason => 'timeout' };
    is( $info->vrf_instances_complete(),
        0, q(A partial vendor interface walk may hide ports) );
}

sub vrf_instances_complete__mpls_rows_cv_walk_partial__is_1 : Tests(1) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_mpls_rows();
    $info->{walk_status}{vrf_cv_name} = { complete => 0, reason => 'timeout' };
    $info->{walk_status}{vrf_cv_if}   = { complete => 0, reason => 'timeout' };
    is( $info->vrf_instances_complete(),
        1, q(A vendor walk not used for the list does not count) );
}

# IOS-XE PE: the address tables hold 10.40.0.1/24 on blue's port 3 only, and the
# routes of both VRFs hold 10.40.0.0/24.
sub vrf_subnets__overlap__restored_from_routes : Tests(2) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_mpls_rows();
    my $pfx = '.1.3.6.1.2.1.4.32.1.5';
    $info->{_new_ip_index}  = 1;
    $info->{_new_ip_type}   = 1;
    $info->{_new_ip_prefix} = 1;
    $info->{store}{new_ip_index}  = { '1.4.10.40.0.1' => 3 };
    $info->{store}{new_ip_type}   = { '1.4.10.40.0.1' => 'unicast' };
    $info->{store}{new_ip_prefix}
        = { '1.4.10.40.0.1' => "$pfx.3.1.4.10.40.0.0.24" };

    my $hop = '2.0.0.1.4.0.0.0.0';
    my %route
        = ( "$NAME_IID{red}.1.4.10.40.0.0.24.$hop"  => [ 'local', 2 ],
            "$NAME_IID{blue}.1.4.10.40.0.0.24.$hop" => [ 'local', 3 ], );
    $info->{_vrf_l3vpn_rte_if}    = 1;
    $info->{_vrf_l3vpn_rte_proto} = 1;
    $info->{store}{vrf_l3vpn_rte_proto}
        = { map { $_ => $route{$_}[0] } keys %route };
    $info->{store}{vrf_l3vpn_rte_if}
        = { map { $_ => $route{$_}[1] } keys %route };

    cmp_deeply( $info->vrf_subnets('red')->{'10.40.0.0/24'},
        superhashof( { ifindex => 2, sources => ['route'] } ),
        q(Red's subnet comes back from its connected route) );
    cmp_deeply( $info->vrf_subnets('blue')->{'10.40.0.0/24'},
        superhashof( { ifindex => 3, sources => [ 'address', 'route' ] } ),
        q(Blue's subnet is found both ways) );
}

sub vrf_instances_complete__cisco_vrf_mib_default_row_only__is_1 : Tests(3) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_cisco_vrf_mib();
    $info->{store}{vrf_cv_name} = { 1 => 'default' };
    $info->{store}{vrf_cv_if}   = {};
    cmp_deeply( [ keys %{ $info->vrf_instances() } ],
        ['default'], q(The global row is no VRF) );
    is( $info->vrf_instances_complete(), 1, q(None configured) );
    ok( !exists $info->vrf_instances( ['amber'] )->{amber},
        q(Caller names add nothing) );
}

1;
