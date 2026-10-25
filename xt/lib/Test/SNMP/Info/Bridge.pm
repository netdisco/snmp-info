# Test::SNMP::Info::Bridge
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

package Test::SNMP::Info::Bridge;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Bridge;

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
    '_dot1qVlanFdbId' =>1,
    'store' => {
      'dot1qVlanFdbId' => { '0.1' => 0, '0.91' => 3, '0.112' => 1, '0.113' => 2}
      },
  };
  $test->{info}->cache($cache_data);
}


sub qb_fdb_index : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'qb_fdb_index' );

    my $expected = { 0 => 1, 3 => 91, 1 => 112, 2 => 113 };
    cmp_deeply( $test->{info}->qb_fdb_index(), $expected, q(FDB to VLAN index returned expected values));

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->qb_fdb_index(),
        {}, q(No data returns empty hash) );
}

sub qb_fdb_index_shared : Tests(2) {
    my $test = shift;

    # Shared VLAN learning: VLANs 10, 20 and 30 all use FDB ID 5
    $test->{info}{store}{dot1qVlanFdbId}
        = { '0.1' => 1, '0.10' => 5, '0.20' => 5, '0.30' => 5 };

    my $expected = { 1 => 1, 5 => undef };
    cmp_deeply( $test->{info}->qb_fdb_index(), $expected,
        q(FDB ID shared by several VLANs maps to no VLAN) );

    my @answers = map { $test->{info}->qb_fdb_index()->{5} // 'undef' } 1 .. 5;
    cmp_deeply( \@answers, [ ('undef') x 5 ],
        q(Shared FDB ID gives the same answer on every call) );
}

sub qb_fw_vlan : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'qb_fw_vlan' );

    $test->{info}{store}{dot1qVlanFdbId}
        = { '0.91' => 3, '0.10' => 5, '0.20' => 5 };
    $test->{info}{'_qb_fw_port'} = 1;
    $test->{info}{store}{qb_fw_port} = {
        '3.0.17.34.51.68.85' => 1,
        '5.0.17.34.51.68.86' => 2,
        '7.0.17.34.51.68.87' => 3,
    };

    my $expected = {
        '3.0.17.34.51.68.85' => 91,
        '5.0.17.34.51.68.86' => undef,
        '7.0.17.34.51.68.87' => 7,
    };
    cmp_deeply( $test->{info}->qb_fw_vlan(), $expected,
        q(Mapped FDB ID gives its VLAN, shared gives none, unmapped is the VID) );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->qb_fw_vlan(), {}, q(No data returns empty hash) );
}

sub stp_decode_ids : Tests(5) {
    my $test = shift;
    my $bid  = \&SNMP::Info::Bridge::_stp_decode_bridge_id;
    my $pid  = \&SNMP::Info::Bridge::_stp_decode_port_id;

    cmp_deeply(
        $bid->('10:00:02:00:00:00:00:0a'),
        {   priority   => 4096,
            sys_id_ext => 0,
            mac        => '02:00:00:00:00:0a',
            raw        => '10:00:02:00:00:00:00:0a'
        },
        q(RSTP bridge ID decodes)
    );
    cmp_deeply(
        $bid->('80:01:02:00:00:00:00:0b'),
        {   priority   => 32768,
            sys_id_ext => 1,
            mac        => '02:00:00:00:00:0b',
            raw        => '80:01:02:00:00:00:00:0b'
        },
        q(PVST VLAN 1 keeps the extension apart)
    );
    cmp_deeply( $pid->('80:02'), { priority => 128, port => 2, raw => '80:02' },
        q(Port ID decodes) );
    is( $bid->(undef), undef, q(Undef bridge ID gives undef) );
    is( $pid->('80'),  undef, q(Short port ID gives undef) );
}

# swC of a three-switch RSTP ring: port 1 root towards swA, port 2
# alternate towards swB. MACs are synthetic.
sub _stp_rstp_cache {
    return {
        '_b_mac'        => pack( 'H*', '02000000000c' ),
        '_stp_priority' => 32768,
        '_stp_root'     => pack( 'H*', '100002000000000a' ),
        '_stp_p_id'     => 1,
        '_stp_p_state'  => 1,
        '_stp_p_bridge' => 1,
        '_stp_p_port'   => 1,
        '_bp_index'     => 1,
        'store'         => {
            'stp_p_id'     => { 1 => 1, 2 => 2 },
            'stp_p_state'  => { 1 => 'forwarding', 2 => 'blocking' },
            'stp_p_bridge' => {
                1 => pack( 'H*', '100002000000000a' ),
                2 => pack( 'H*', '200002000000000b' )
            },
            'stp_p_port' =>
                { 1 => pack( 'H*', '8002' ), 2 => pack( 'H*', '8002' ) },
            'bp_index' => { 1 => 3, 2 => 4 },
        },
    };
}

sub stp_protocols : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'stp_protocols' );

    $test->{info}->cache( _stp_rstp_cache() );
    cmp_deeply( $test->{info}->stp_protocols(),
        ['dot1d'], q(BRIDGE-MIB tree served, protocol not served) );

    $test->{info}->clear_cache();
    is( $test->{info}->stp_protocols(), undef, q(No STP data gives no protocols) );
}

sub stp_trees : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'stp_trees' );

    $test->{info}->cache( _stp_rstp_cache() );
    my $expected = {
        'cist.0' => {
            type           => 'cist',
            id             => 0,
            protocol       => undef,
            measured       => 0,
            ports_complete => 1,
            context        => { kind => 'none' },
            bridge         => {
                priority   => 32768,
                sys_id_ext => 0,
                mac        => '02:00:00:00:00:0c',
                raw        => '80:00:02:00:00:00:00:0c'
            },
            root => {
                priority   => 4096,
                sys_id_ext => 0,
                mac        => '02:00:00:00:00:0a',
                raw        => '10:00:02:00:00:00:00:0a'
            },
        }
    };
    cmp_deeply( $test->{info}->stp_trees(),
        $expected, q(Default tree reported as the common tree) );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->stp_trees(), {}, q(No STP data gives no trees) );
}

sub stp_trees_memo : Tests(3) {
    my $test = shift;

    $test->{info}->cache( _stp_rstp_cache() );
    my $first = $test->{info}->stp_trees();
    ok( exists $first->{'cist.0'}, q(First call builds the tree list) );

    delete $test->{info}{store}{stp_p_id};
    delete $test->{info}{_stp_p_id};
    delete $test->{info}{_stp_root};
    ok( exists $test->{info}->stp_trees()->{'cist.0'},
        q(Second call returns the memoized list) );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->stp_trees(), {},
        q(clear_cache drops the memoized list) );
}

sub stp_trees_context : Tests(5) {
    my $test = shift;
    my $sess = $test->{info}->session();

    $test->{info}->cache( _stp_rstp_cache() );
    $sess->{Context} = 'vlan-10';
    is( $test->{info}->stp_trees(), undef, q(Refused in a v3 context) );
    like( $test->{info}->error(), qr/vlan-10.*default context/s,
        q(Error names the context and the default context) );

    delete $sess->{Context};
    $sess->{Community} = $test->{info}{args}{Community} . '@10';
    is( $test->{info}->stp_trees(), undef, q(Refused in a community context) );
    like( $test->{info}->error(), qr/'10'/, q(Error names the VLAN context) );

    local $test->{info}{args}{Community} = 'p@ss';
    $sess->{Community} = 'p@ss';
    ok( exists $test->{info}->stp_trees()->{'cist.0'},
        q(A community containing @ is still the default context) );
}

sub stp_trees_complete : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'stp_trees_complete' );

    $test->{info}->cache( _stp_rstp_cache() );
    is( $test->{info}->stp_trees_complete(), 0,
        q(Common-tree default may hide MSTIs) );

    $test->{info}->clear_cache();
    is( $test->{info}->stp_trees_complete(), undef, q(No trees gives undef) );
}

sub stp_tree_ports : Tests(2) {
    my $test = shift;

    can_ok( $test->{info}, 'stp_tree_ports' );

    $test->{info}->cache( _stp_rstp_cache() );
    my $expected = {
        3 => {
            tree_type         => 'cist',
            tree_id           => 0,
            state             => 'forwarding',
            role              => undef,
            designated_bridge => {
                priority   => 4096,
                sys_id_ext => 0,
                mac        => '02:00:00:00:00:0a',
                raw        => '10:00:02:00:00:00:00:0a'
            },
            designated_port => { priority => 128, port => 2, raw => '80:02' },
        },
        4 => {
            tree_type         => 'cist',
            tree_id           => 0,
            state             => 'blocking',
            role              => undef,
            designated_bridge => {
                priority   => 8192,
                sys_id_ext => 0,
                mac        => '02:00:00:00:00:0b',
                raw        => '20:00:02:00:00:00:00:0b'
            },
            designated_port => { priority => 128, port => 2, raw => '80:02' },
        },
    };
    cmp_deeply( $test->{info}->stp_tree_ports('cist.0'),
        $expected, q(Ports keyed by iid with designated bridge and port) );
}

sub stp_tree_ports_unknown_key : Tests(2) {
    my $test = shift;

    $test->{info}->cache( _stp_rstp_cache() );
    is( $test->{info}->stp_tree_ports('pvst.10'), undef,
        q(Unknown tree key gives undef) );
    like( $test->{info}->error(), qr/pvst\.10.*stp_trees/,
        q(Error names the key and where keys come from) );
}

sub stp_tree_ports_unmapped : Tests(2) {
    my $test = shift;

    $test->{info}->cache( _stp_rstp_cache() );
    delete $test->{info}{store}{bp_index}{2};
    my $ports = $test->{info}->stp_tree_ports('cist.0');
    ok( !exists $ports->{4}, q(Row with no bp_index mapping is dropped) );
    is( $test->{info}->stp_trees()->{'cist.0'}{ports_complete},
        0, q(Dropped row marks the tree's ports incomplete) );
}

sub stp_tree_ports_bad_bridge : Tests(2) {
    my $test = shift;

    $test->{info}->cache( _stp_rstp_cache() );
    $test->{info}{store}{stp_p_bridge}{2} = pack( 'H*', '02000000000b' );
    my $port = $test->{info}->stp_tree_ports('cist.0')->{4};
    is( $port->{state}, 'blocking', q(Port keeps its state) );
    is( $port->{designated_bridge},
        undef, q(Malformed designated bridge gives undef) );
}

sub stp_trees_ports_complete_upfront : Tests(1) {
    my $test = shift;

    $test->{info}->cache( _stp_rstp_cache() );
    delete $test->{info}{store}{bp_index}{2};
    is( $test->{info}->stp_trees()->{'cist.0'}{ports_complete},
        0, q(Unmapped port row marks the list incomplete before port reads) );
}

sub stp_vlan_map : Tests(2) {
    my $test = shift;

    can_ok( $test->{info}, 'stp_vlan_map' );

    $test->{info}->cache( _stp_rstp_cache() );
    is( $test->{info}->stp_vlan_map(), undef,
        q(One BRIDGE-MIB tree serves no VLAN map) );
}

sub stp_default_context_ok : Tests(2) {
    my $test = shift;

    $test->{info}->cache( _stp_rstp_cache() );
    $test->{info}->session()->{Context} = 'vlan-10';
    is( $test->{info}->stp_trees(), undef, q(Refused in a context) );
    like(
        $test->{info}->error(),
        qr/stp_trees\(\).*'vlan-10'.*default context/s,
        q(Error names the method, the context and the default context)
    );
}

sub stp_has_protocol_absent : Tests(4) {
    my $test = shift;

    foreach my $method (qw/hasSTP hasRSTP hasMSTP hasPVST/) {
        ok( !$test->{info}->can($method),
            qq(Base class does not claim to detect $method) );
    }
}

1;
