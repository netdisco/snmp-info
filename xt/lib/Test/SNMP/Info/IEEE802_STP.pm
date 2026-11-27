# Test::SNMP::Info::IEEE802_STP
#
# Copyright (c) 2026 SNMP::Info Developers
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

package Test::SNMP::Info::IEEE802_STP;

use Test::Class::Most parent => 'My::Test::Class';
use SNMP::Info::IEEE802_STP;

my $id = sub { pack( 'H*', shift ) };

# Shapes from an AOS-CX 10.16 walk in MSTP mode: component 1, MSTIs 1 and
# 2, bridge ports equal to ifIndexes, LAGs from 769
sub setup : Tests(setup) {
    my $test = shift;
    $test->SUPER::setup;

    my %store = (
        ieee_stp_version => { 1 => 'mstp' },
        mstp_cist_bridge => { 1 => $id->('1000020000000001') },
        ieee_stp_root    => { 1 => $id->('1000020000000001') },
        mstp_i_bridge    => {
            '1.1' => $id->('1001020000000001'),
            '1.2' => $id->('2002020000000002'),
        },
        mstp_i_root => {
            '1.1' => $id->('1001020000000001'),
            '1.2' => $id->('2002020000000002'),
        },
        mstp_vlan_msti   => { '1.1' => 0, '1.10' => 1, '1.20' => 2 },
        mstp_cist_p_role => {},
        mstp_p_state     => {},
        ieee_stp_p_state => {},
        bp_index         => { 3 => 3, 769 => 769, 770 => 770 },
    );
    $test->{info}->cache(
        { ( map { ( "_$_" => 1 ) } keys %store ), store => \%store } );
}

sub _set_column {
    my ( $test, $column, $values ) = @_;
    my $info = $test->{info};

    $info->{"_$column"} = 1;
    $info->{store}{$column} = $values;
    delete $info->{_stp_trees};
    return;
}

sub hasSTP : Tests(2) {
    my $test = shift;
    my $info = $test->{info};

    is( $info->hasSTP(), 0, 'hasSTP__mstp_version__returns_0' );
    $test->_set_column( 'ieee_stp_version', { 1 => 'stp' } );
    is( $info->hasSTP(), 1, 'hasSTP__stp_version__returns_1' );
}

sub hasRSTP : Tests(2) {
    my $test = shift;
    my $info = $test->{info};

    is( $info->hasRSTP(), 0, 'hasRSTP__mstp_version__returns_0' );
    $test->_set_column( 'ieee_stp_version', { 1 => 'rstp' } );
    is( $info->hasRSTP(), 1, 'hasRSTP__rstp_version__returns_1' );
}

sub hasMSTP : Tests(3) {
    my $test = shift;
    my $info = $test->{info};

    is( $info->hasMSTP(), 1, 'hasMSTP__mstp_version__returns_1' );
    $test->_set_column( 'ieee_stp_version', { 1 => 'rstp' } );
    is( $info->hasMSTP(), 0, 'hasMSTP__rstp_version__returns_0' );
    is( $info->hasRSTP(), 1, 'hasRSTP__rstp_version__returns_1' );
}

sub stp_protocols : Tests(2) {
    my $test = shift;
    my $info = $test->{info};

    cmp_deeply( scalar $info->stp_protocols(),
        ['mstp'], 'stp_protocols__mstp_version__returns_mstp' );

    $test->_set_column( 'ieee_stp_version', {} );
    cmp_deeply(
        scalar $info->stp_protocols(),
        scalar SNMP::Info::Bridge::stp_protocols($info),
        'stp_protocols__no_version__returns_bridge_result'
    );
}

sub stp_trees : Tests(4) {
    my $test = shift;
    my $info = $test->{info};

    my $trees = $info->stp_trees();
    cmp_deeply(
        [ sort keys %$trees ],
        [qw/cist.0 msti.1 msti.2/],
        'stp_trees__mstp__returns_cist_and_each_msti'
    );
    cmp_deeply(
        $trees->{'msti.1'},
        superhashof(
            {   type     => 'msti',
                id       => 1,
                protocol => 'mstp',
                measured => 0,
                bridge   => superhashof(
                    {   priority   => 4096,
                        sys_id_ext => 1,
                        mac        => '02:00:00:00:00:01',
                    }
                ),
            }
        ),
        'stp_trees__msti_1__decodes_bridge_id_with_msti_in_priority'
    );
    cmp_deeply(
        $trees->{'cist.0'},
        {   type           => 'cist',
            id             => 0,
            protocol       => 'mstp',
            measured       => 0,
            ports_complete => 1,
            contexts       => [ { kind => 'none' } ],
            bridge         => superhashof( { priority => 4096 } ),
            root           => superhashof( { priority => 4096 } ),
        },
        'stp_trees__cist__has_cist_bridge_and_root'
    );

    $test->_set_column( 'mstp_p_state',
        { '1.1.769' => 'forwarding', '1.2.771' => 'blocking' } );
    $trees = $info->stp_trees();
    cmp_deeply(
        { map { $_ => $trees->{$_}{ports_complete} } keys %$trees },
        { 'cist.0' => 1, 'msti.1' => 1, 'msti.2' => 0 },
        'stp_trees__msti_port_not_in_bp_index__ports_incomplete'
    );
}

sub stp_trees__second_component__ports_incomplete : Tests(1) {
    my $test = shift;
    my $info = $test->{info};

    $test->_set_column( 'mstp_cist_p_role',
        { '1.3' => 'designated', '2.5' => 'root' } );
    my $trees = $info->stp_trees();
    cmp_deeply(
        { map { $_ => $trees->{$_}{ports_complete} } keys %$trees },
        { 'cist.0' => 0, 'msti.1' => 0, 'msti.2' => 0 },
        'stp_trees__rows_in_second_component__every_tree_ports_incomplete'
    );
}

sub stp_trees__not_mstp__uses_bridge : Tests(2) {
    my $test = shift;
    my $info = $test->{info};

    $test->_set_column( 'ieee_stp_version', { 1 => 'rstp' } );
    $test->_set_column( 'stp_p_id',         { 3 => 3 } );
    $info->{_stp_root}     = $id->('8000020000000009');
    $info->{_stp_priority} = 32768;
    $info->{_b_mac}        = $id->('020000000001');

    my $expected = SNMP::Info::Bridge::stp_trees($info);
    delete $info->{_stp_trees};
    cmp_deeply( [ keys %$expected ],
        ['cist.0'], 'stp_trees__rstp_version__bridge_has_a_dot1d_tree' );
    cmp_deeply( $info->stp_trees(), $expected,
        'stp_trees__rstp_version__returns_bridge_dot1d_tree' );
}

sub stp_vlan_map : Tests(2) {
    my $test = shift;
    my $info = $test->{info};

    cmp_deeply(
        scalar $info->stp_vlan_map(),
        { 1 => 'cist.0', 10 => 'msti.1', 20 => 'msti.2' },
        'stp_vlan_map__mstp__maps_each_vlan_to_its_tree'
    );
    $test->_set_column( 'mstp_vlan_msti', {} );
    is( scalar $info->stp_vlan_map(),
        undef, 'stp_vlan_map__empty_column__returns_nothing' );
}

sub stp_trees_complete : Tests(3) {
    my $test = shift;
    my $info = $test->{info};

    is( $info->stp_trees_complete(),
        1, 'stp_trees_complete__mstp_walks_complete__returns_1' );

    $info->{walk_status}{mstp_i_bridge}
        = { complete => 0, reason => 'timeout' };
    is( $info->stp_trees_complete(),
        0, 'stp_trees_complete__msti_walk_timed_out__returns_0' );

    delete $info->{walk_status}{mstp_i_bridge};
    $test->_set_column(
        'mstp_cist_bridge',
        {   1 => $id->('1000020000000001'),
            2 => $id->('1000020000000001'),
        }
    );
    is( $info->stp_trees_complete(),
        0, 'stp_trees_complete__other_component_served__returns_0' );
}

sub _port_rows {
    my $test = shift;

    $test->_set_column( 'ieee_stp_p_state',
        { '1.3' => 'forwarding', '1.769' => 'forwarding' } );
    $test->_set_column( 'mstp_cist_p_role',
        { '1.3' => 'designated', '1.769' => 'root' } );
    $test->_set_column( 'ieee_stp_p_enable', { '1.3' => 1, '1.769' => 1 } );
    $test->_set_column( 'mstp_p_state',
        { '1.1.769' => 'forwarding', '1.2.770' => 'blocking' } );
    $test->_set_column( 'mstp_p_role',
        { '1.1.769' => 'root', '1.2.770' => 'alternate' } );
    $test->_set_column(
        'mstp_p_bridge',
        {   '1.1.769' => $id->('1001020000000009'),
            '1.2.770' => $id->('2002020000000009'),
        }
    );
    $test->_set_column(
        'ieee_stp_p_bridge',
        {   '1.3'   => $id->('1000020000000001'),
            '1.769' => $id->('1000020000000009'),
        }
    );
    $test->_set_column( 'ieee_stp_p_port',
        { '1.3' => $id->('8003'), '1.769' => $id->('8301') } );
    return;
}

sub stp_tree_ports : Tests(11) {
    my $test = shift;
    my $info = $test->{info};
    $test->_port_rows();

    my $cist = $info->stp_tree_ports('cist.0');
    cmp_deeply(
        $cist->{769},
        superhashof(
            {   tree_type         => 'cist',
                tree_id           => 0,
                state             => 'forwarding',
                role              => 'root',
                role_raw          => 'root',
                enabled           => 1,
                designated_bridge => superhashof( { priority => 4096 } ),
                designated_port   => superhashof( { port     => 769 } ),
            }
        ),
        'stp_tree_ports__cist__row_has_state_role_and_designated'
    );

    my $msti = $info->stp_tree_ports('msti.2');
    cmp_deeply(
        $msti,
        {   770 => superhashof(
                {   tree_type         => 'msti',
                    tree_id           => 2,
                    state             => 'blocking',
                    role              => 'alternate',
                    role_raw          => 'alternate',
                    enabled           => undef,
                    designated_bridge => superhashof( { priority => 8192 } ),
                    designated_port   => undef,
                }
            )
        },
        'stp_tree_ports__msti__row_has_msti_state_and_no_designated_port'
    );
    is( $msti->{770}{designated_port},
        undef, 'stp_tree_ports__msti__designated_port_undef' );

    $test->_set_column( 'mstp_cist_p_role',
        { '1.3' => 'designated', '1.769' => 6 } );
    my $odd = $info->stp_tree_ports('cist.0')->{769};
    is( $odd->{role},     undef, 'stp_tree_ports__role_6__role_undef' );
    is( $odd->{role_raw}, '6',   'stp_tree_ports__role_6__role_raw_kept' );

    $test->_set_column( 'mstp_p_role',
        { '1.1.769' => 6, '1.2.770' => 'master' } );
    my $msti_odd = $info->stp_tree_ports('msti.1')->{769};
    is( $msti_odd->{role}, undef, 'stp_tree_ports__msti_role_6__role_undef' );
    is( $msti_odd->{role_raw}, '6',
        'stp_tree_ports__msti_role_6__role_raw_kept' );
    is( $info->stp_tree_ports('msti.2')->{770}{role},
        'master', 'stp_tree_ports__msti_role_master__role_master' );

    $info->error(1);
    ok( $info->stp_trees(), 'stp_tree_ports__mstp_primed__trees_held' );
    my $none = $info->stp_tree_ports('msti.9');
    is( $none, undef, 'stp_tree_ports__unknown_key__returns_nothing' );
    ok( $info->error(1), 'stp_tree_ports__unknown_key__sets_error' );
}

sub stp_tree_ports__cist_port_not_in_bp_index : Tests(2) {
    my $test = shift;
    my $info = $test->{info};

    $test->_set_column( 'ieee_stp_p_state',
        { '1.3' => 'forwarding', '1.999' => 'forwarding' } );
    my $trees = $info->stp_trees();
    is( $trees->{'cist.0'}{ports_complete},
        0, 'stp_trees__cist_state_row_not_in_bp_index__ports_incomplete' );
    cmp_deeply( [ keys %{ $info->stp_tree_ports('cist.0') } ],
        [3], 'stp_tree_ports__unmapped_port__row_skipped' );
}

sub stp_trees__no_version_column__hook_mstp : Tests(2) {
    my $test = shift;
    my $info = $test->{info};

    $test->_set_column( 'ieee_stp_version', {} );
    no warnings 'redefine';
    local *SNMP::Info::IEEE802_STP::_ieee_stp_protocol = sub {'mstp'};
    cmp_deeply(
        [ sort keys %{ $info->stp_trees() || {} } ],
        [qw/cist.0 msti.1 msti.2/],
        'stp_trees__no_version_hook_mstp__trees_built_from_cist_bridge'
    );

    $test->_set_column( 'mstp_cist_bridge', {} );
    $test->_set_column( 'mstp_cist_p_role', { '1.3' => 'designated' } );
    ok( $info->stp_trees()->{'msti.1'},
        'stp_trees__no_version_no_cist_bridge__component_from_cist_role' );
}

sub i_edgeport_admin : Tests(3) {
    my $test = shift;
    my $info = $test->{info};

    $test->_set_column( 'ieee_rstp_p_edge_admin',
        { '1.3' => 1, '1.769' => 2 } );
    cmp_deeply(
        scalar $info->i_edgeport_admin(),
        { 3 => 1, 769 => 0 },
        'i_edgeport_admin__rstp_column__by_ifindex'
    );

    $test->_set_column( 'ieee_rstp_p_edge_admin', {} );
    $test->_set_column( 'mstp_cist_p_edge_admin', { '1.3' => 1 } );
    cmp_deeply(
        scalar $info->i_edgeport_admin(),
        { 3 => 1 },
        'i_edgeport_admin__rstp_empty__uses_cist_column'
    );

    $test->_set_column( 'mstp_cist_p_edge_admin', {} );
    cmp_deeply(
        scalar $info->i_edgeport_admin(),
        scalar SNMP::Info::Bridge::i_edgeport_admin($info),
        'i_edgeport_admin__both_empty__returns_bridge_result'
    );
}

sub i_edgeport_oper : Tests(2) {
    my $test = shift;
    my $info = $test->{info};

    $test->_set_column( 'ieee_rstp_p_edge_oper',
        { '1.3' => 2, '1.769' => 2 } );
    cmp_deeply(
        scalar $info->i_edgeport_oper(),
        { 3 => 0, 769 => 0 },
        'i_edgeport_oper__rstp_column__by_ifindex'
    );

    $test->_set_column( 'ieee_rstp_p_edge_oper', {} );
    $test->_set_column( 'mstp_cist_p_edge_oper', { '1.3' => 1 } );
    cmp_deeply(
        scalar $info->i_edgeport_oper(),
        { 3 => 1 },
        'i_edgeport_oper__rstp_empty__uses_cist_column'
    );
}

1;
