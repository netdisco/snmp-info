# Test::SNMP::Info::Layer3::Passport
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

package Test::SNMP::Info::Layer3::Passport;

use Test::Class::Most parent => 'My::Test::Class';
use B ();

use SNMP::Info::Layer3::Passport;

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
    '_layers' => 6,
    '_description' => 'VSP-9012 (3.0.2.0) (GA)',

    # RAPID-CITY::rcVSP9012
    '_id'   => '.1.3.6.1.4.1.2272.201',
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

# swA is the device, swB the root. Ports 192 and 193 are bridge ports that
# Passport maps to the ifIndex of the same number. MACs are synthetic.
sub _stp_cache {
    my ( $test, $protocol ) = @_;
    my $info = $test->{info};
    $info->clear_cache();

    my $id = sub { pack( 'H*', shift ) };
    my %store = (
        i_index       => { 192 => 192, 193 => 193 },
        rc_mlt_index  => {},
        rc_dot1d_p_enable => { 192 => 'enabled', 193 => 'enabled' },
        dot1dStpPortState => { 192 => 'forwarding', 193 => 'forwarding' },
    );
    my %cache = (
        '_layers'      => 6,
        '_description' => 'VSP-9012 (3.0.2.0) (GA)',
        '_id'          => '.1.3.6.1.4.1.2272.201',
    );

    if ( $protocol eq 'mstp' ) {
        $cache{_nn_mst_version}      = 'mstp';
        $cache{_nn_mst_brg_address}  = $id->('02000000000a');
        $cache{_nn_mst_cist_priority} = 32768;
        $cache{_nn_mst_cist_root}    = $id->('800002000000000b');
        %store = (
            %store,
            nn_msti_priority => { 1 => 32768, 2 => 32768, 62 => 32768 },
            nn_msti_root     => {
                1  => $id->('800102000000000b'),
                2  => $id->('800202000000000b'),
                62 => $id->('803e02000000000b'),
            },
            rc_stg_enable =>
                { 1 => 'true', 2 => 'true', 3 => 'true', 63 => 'false' },
            rc_vlan_stg => {
                1    => 1, 10   => 2,  20 => 3,
                4048 => 1, 4051 => 63, 4052 => 63,
            },
            rc_stp_p_enable => { '192.1' => 'false', '193.2' => 'false' },
            nn_cist_p_enable => { 192 => 'enabled', 193 => 'disabled' },
            nn_msti_p_enable => {
                '192.1' => 'enabled', '193.1' => 'disabled',
                '193.2' => 'enabled',
            },
            nn_cist_p_state =>
                { 192 => 'discarding', 193 => 'forwarding' },
            nn_cist_p_role   => { 192 => 1, 193 => 3 },
            nn_cist_p_bridge => {
                192 => $id->('800002000000000b'),
                193 => $id->('800002000000000b'),
            },
            nn_cist_p_port => { 192 => $id->('8001'), 193 => $id->('8002') },
            nn_msti_p_state => {
                '192.1' => 'forwarding', '193.1' => 'discarding',
                '192.2' => 'discarding', '193.2' => 'forwarding',
            },
            nn_msti_p_role => {
                '192.1' => 'root',      '193.1' => 'alternate',
                '192.2' => 'alternate', '193.2' => 'root',
            },
            nn_msti_p_bridge => {
                map { $_ => $id->('800102000000000b') }
                    qw/192.1 193.1 192.2 193.2/
            },
            nn_msti_p_port => {
                map { $_ => $id->('8001') } qw/192.1 193.1 192.2 193.2/
            },
        );
    }
    elsif ( $protocol eq 'rstp' or $protocol eq 'stp' ) {
        $cache{_nn_mst_version} = 'rstp';
        $cache{_nn_rst_version}
            = $protocol eq 'stp' ? 'stpCompatible' : 'rstp';
        %store = (
            %store,
            rc_stp_i_priority => { 1 => 32768 },
            rc_stp_i_mac      => { 1 => $id->('02000000000a') },
            rc_stp_i_root     => { 1 => $id->('800002000000000b') },
            nn_rst_p_state    =>
                { 192 => 'forwarding', 193 => 'discarding' },
            nn_rst_p_role =>
                { 192 => 'rootPort', 193 => 'alternatePort' },
            rc_dot1d_p_bridge => {
                192 => $id->('800002000000000b'),
                193 => $id->('200002000000000b'),
            },
            rc_dot1d_p_port => { 192 => $id->('8001'), 193 => $id->('8002') },
            dot1dStpPortState => { 192 => 'forwarding', 193 => 'forwarding' },
        );
    }

    $info->{store}{$_} = $store{$_} for keys %store;
    $info->{ '_' . $_ } = 1 for keys %store;
    $info->cache( \%cache );
    return;
}

sub _bridge {
    my ( $priority, $ext, $mac ) = @_;
    return {
        priority   => $priority,
        sys_id_ext => $ext,
        mac        => $mac,
        raw        => ignore(),
    };
}

sub _rc_stp_protocol : Tests(6) {
    my $test = shift;
    my $info = $test->{info};

    $test->_stp_cache('mstp');
    is( $info->_rc_stp_protocol(), 'mstp', q(MST version mstp) );
    $test->_stp_cache('rstp');
    is( $info->_rc_stp_protocol(), 'rstp', q(nnRst version rstp) );
    $test->_stp_cache('stp');
    is( $info->_rc_stp_protocol(), 'stp', q(nnRst version stpCompatible) );
    $info->{_nn_rst_version} = 2;
    is( $info->_rc_stp_protocol(), 'rstp', q(nnRst version as a number) );
    $test->_stp_cache('none');
    is( $info->_rc_stp_protocol(), undef, q(Neither object served) );
    is( $info->_rc_stp_measured('mstp'), 0, q(Not measured here) );
}

sub hasSTP : Tests(3) {
    my $test = shift;
    $test->_stp_cache('stp');
    is( $test->{info}->hasSTP(), 1, q(stp) );
    $test->_stp_cache('rstp');
    is( $test->{info}->hasSTP(), 0, q(Not under rstp) );
    $test->_stp_cache('none');
    is( $test->{info}->hasSTP(), 0, q(Nothing served) );
}

sub hasRSTP : Tests(2) {
    my $test = shift;
    $test->_stp_cache('rstp');
    is( $test->{info}->hasRSTP(), 1, q(rstp) );
    $test->_stp_cache('mstp');
    is( $test->{info}->hasRSTP(), 0, q(Not under mstp) );
}

sub hasMSTP : Tests(2) {
    my $test = shift;
    $test->_stp_cache('mstp');
    is( $test->{info}->hasMSTP(), 1, q(mstp) );
    $test->_stp_cache('rstp');
    is( $test->{info}->hasMSTP(), 0, q(Not under rstp) );
}

sub stp_protocols : Tests(3) {
    my $test = shift;
    my $info = $test->{info};

    $test->_stp_cache('mstp');
    cmp_deeply( $info->stp_protocols(), ['mstp'], q(mstp) );
    $test->_stp_cache('rstp');
    cmp_deeply( $info->stp_protocols(), ['rstp'], q(rstp) );
    $test->_stp_cache('none');
    is( scalar $info->stp_protocols(), undef, q(STG mode: undef) );
}

sub stp_trees : Tests(21) {
    my $test = shift;
    my $info = $test->{info};

    is( $info->can('stp_trees'), \&SNMP::Info::RapidCity::stp_trees,
        q(Resolves to RapidCity) );

    $test->_stp_cache('mstp');
    my $trees = $info->stp_trees();
    cmp_deeply( [ sort keys %$trees ], [qw/cist.0 msti.1 msti.2/],
        q(MSTP: the SPBM tree, STP disabled, is left out) );
    cmp_deeply(
        $trees->{'cist.0'},
        {   type           => 'cist',
            id             => 0,
            protocol       => 'mstp',
            measured       => 0,
            ports_complete => 1,
            contexts       => [ { kind => 'none' } ],
            bridge         => _bridge( 32768, 0, '02:00:00:00:00:0a' ),
            root           => _bridge( 32768, 0, '02:00:00:00:00:0b' ),
        },
        q(MSTP: cist.0 record)
    );
    cmp_deeply(
        $trees->{'msti.1'}{bridge},
        _bridge( 32768, 0, '02:00:00:00:00:0a' ),
        q(msti.1 bridge: configured priority, no MSTI number)
    );
    is( $trees->{'msti.2'}{root}{priority}, 32768, q(msti.2 root) );
    is( $trees->{'msti.1'}{measured}, 0, q(MSTI not measured) );
    is( $info->stp_trees(), $trees, q(Memoized) );

    $info->{store}{nn_msti_p_state}{'9.1'} = 'forwarding';
    delete $info->{_stp_trees};
    $trees = $info->stp_trees();
    is( $trees->{'msti.1'}{ports_complete}, 0,
        q(Row at an unmapped port: that tree incomplete) );
    is( $trees->{'msti.2'}{ports_complete}, 1, q(Others stay complete) );
    is( $trees->{'cist.0'}{ports_complete}, 1, q(CIST stays complete) );

    $test->_stp_cache('mstp');
    $info->{store}{rc_stg_enable}{63} = 'true';
    $trees = $info->stp_trees();
    cmp_deeply( [ sort keys %$trees ], [qw/cist.0 msti.1 msti.2 msti.62/],
        q(Tree reappears when its STG runs) );

    $test->_stp_cache('rstp');
    $trees = $info->stp_trees();
    cmp_deeply( [ keys %$trees ], ['cist.0'], q(RSTP: the CIST only) );
    cmp_deeply(
        $trees->{'cist.0'},
        {   type           => 'cist',
            id             => 0,
            protocol       => 'rstp',
            measured       => 0,
            ports_complete => 1,
            contexts       => [ { kind => 'none' } ],
            bridge         => _bridge( 32768, 0, '02:00:00:00:00:0a' ),
            root           => _bridge( 32768, 0, '02:00:00:00:00:0b' ),
        },
        q(RSTP: cist.0 record)
    );

    delete $info->{store}{nn_rst_p_state};
    delete $info->{_stp_trees};
    is( $info->stp_trees()->{'cist.0'}{ports_complete},
        0, q(RSTP without state rows: incomplete) );

    $test->_stp_cache('stp');
    is( $info->stp_trees()->{'cist.0'}{protocol}, 'stp', q(STP protocol) );

    $test->_stp_cache('none');
    cmp_deeply( $info->stp_trees(), {}, q(STG mode: no trees) );

    $test->_stp_cache('mstp');
    $info->session()->{Context} = 'vlan-10';
    is( scalar $info->stp_trees(), undef, q(Non-default context: nothing) );
    $info->session()->{Context} = '';

    $test->_stp_cache('mstp');
    $info->{store}{rc_stg_enable}
        = { 1 => 'true', 2 => 2, 3 => 'true', 63 => 'false' };
    cmp_deeply( [ sort keys %{ $info->stp_trees() } ],
        [qw/cist.0 msti.2/], q(Enable value 2 is not running) );

    $test->_stp_cache('mstp');
    delete $info->{store}{rc_stg_enable};
    cmp_deeply( [ sort keys %{ $info->stp_trees() } ],
        [qw/cist.0 msti.1 msti.2 msti.62/],
        q(No enable rows: STGs count as running) );
}

sub stp_tree_ports : Tests(21) {
    my $test = shift;
    my $info = $test->{info};

    $test->_stp_cache('mstp');
    my $rows = $info->stp_tree_ports('cist.0');
    cmp_deeply( [ sort keys %$rows ], [ 192, 193 ], q(CIST rows) );
    cmp_deeply(
        $rows->{192},
        {   tree_type         => 'cist',
            tree_id           => 0,
            state             => 'discarding',
            role              => 'alternate',
            role_raw          => 1,
            enabled           => 1,
            designated_bridge => _bridge( 32768, 0, '02:00:00:00:00:0b' ),
            designated_port   =>
                { priority => 128, port => 1, raw => '80:01' },
        },
        q(cist.0: 192 discarding, alternate)
    );
    is( $rows->{193}{enabled}, 0,
        q(cist.0: 193 disabled by nnMstCistForcePortState) );

    $rows = $info->stp_tree_ports('msti.1');
    is( $rows->{193}{state}, 'discarding', q(msti.1: 193 discarding) );
    is( $rows->{193}{role},  'alternate',  q(msti.1: 193 alternate) );
    is( $rows->{192}{tree_id}, 1, q(msti.1: tree id) );
    is( $rows->{192}{enabled}, 1, q(msti.1: 192 enabled by ForcePortState) );
    is( $rows->{193}{enabled}, 0, q(msti.1: 193 disabled by ForcePortState) );
    $rows = $info->stp_tree_ports('msti.2');
    is( $rows->{193}{enabled}, 1, q(msti.2: 193 enabled by ForcePortState) );
    is( $rows->{192}{enabled}, undef,
        q(msti.2: 192 no ForcePortState row, never rcStg or dot1d) );
    is( $rows->{193}{role}, 'root', q(msti.2: 193 root) );

    $info->{store}{nn_cist_p_enable} = { 192 => 1, 193 => 0 };
    $rows = $info->stp_tree_ports('cist.0');
    cmp_deeply( [ map { $rows->{$_}{enabled} } 192, 193 ], [ 1, 0 ],
        q(Numeric ForcePortState: 0 gives 0, not undef) );
    delete $info->{store}{nn_cist_p_enable}{193};
    delete $info->{_stp_trees};
    $rows = $info->stp_tree_ports('cist.0');
    is( $rows->{193}{enabled}, undef,
        q(cist.0: 193 no ForcePortState row, rcStg and dot1d not used) );

    $info->{store}{nn_cist_p_state}{9} = 'forwarding';
    delete $info->{_stp_trees};
    cmp_deeply( [ sort keys %{ $info->stp_tree_ports('cist.0') } ],
        [ 192, 193 ], q(Row at an unmapped port is absent) );
    is( $info->stp_trees()->{'cist.0'}{ports_complete}, 0, q(and flagged) );

    is( scalar $info->stp_tree_ports('msti.62'), undef,
        q(Unknown key: none) );
    like( $info->error(1), qr/stp_tree_ports\(\) has no tree 'msti\.62'/,
        q(Error names the method) );

    $test->_stp_cache('rstp');
    $rows = $info->stp_tree_ports('cist.0');
    cmp_deeply(
        $rows->{193},
        {   tree_type         => 'cist',
            tree_id           => 0,
            state             => 'discarding',
            role              => 'alternate',
            role_raw          => 'alternatePort',
            enabled           => 1,
            designated_bridge => _bridge( 8192, 0, '02:00:00:00:00:0b' ),
            designated_port   =>
                { priority => 128, port => 2, raw => '80:02' },
        },
        q(RSTP: 193 discarding though dot1dStpPortState says forwarding)
    );

    delete $info->{store}{nn_rst_p_state};
    cmp_deeply( $info->stp_tree_ports('cist.0'), {},
        q(RSTP without state rows: no rows, never the BRIDGE-MIB state) );

    $test->_stp_cache('none');
    is( scalar $info->stp_tree_ports('cist.0'), undef, q(STG mode: none) );
}

sub stp_trees_complete : Tests(4) {
    my $test = shift;
    my $info = $test->{info};

    $test->_stp_cache('none');
    is( $info->stp_trees_complete(), 0, q(STG mode) );
    $test->_stp_cache('mstp');
    is( $info->stp_trees_complete(), 1, q(MSTP) );
    $test->_stp_cache('rstp');
    is( $info->stp_trees_complete(), 1, q(RSTP) );
    $info->session()->{Context} = 'vlan-10';
    is( $info->stp_trees_complete(), 0, q(Non-default context: no trees) );
    $info->session()->{Context} = '';
}

sub stp_vlan_map : Tests(4) {
    my $test = shift;
    my $info = $test->{info};

    $test->_stp_cache('mstp');
    cmp_deeply(
        scalar $info->stp_vlan_map(),
        { 1 => 'cist.0', 10 => 'msti.1', 20 => 'msti.2', 4048 => 'cist.0' },
        q(MSTP: VLANs of the SPBM tree are left out)
    );
    $info->{store}{rc_vlan_stg} = {};
    is( scalar $info->stp_vlan_map(), undef, q(MSTP, empty map: nothing) );
    $test->_stp_cache('rstp');
    is( scalar $info->stp_vlan_map(), undef, q(RSTP: nothing) );
    $test->_stp_cache('none');
    is( scalar $info->stp_vlan_map(), undef, q(STG mode: nothing) );
}

sub i_stp_state_rstp : Tests(1) {
    my $test = shift;

    $test->_stp_cache('rstp');
    cmp_deeply( $test->{info}->i_stp_state(),
        { 192 => 'forwarding', 193 => 'forwarding' },
        q(i_stp_state keeps the BRIDGE-MIB values) );
}

sub i_edgeport_admin__passport_class__resolves_to_rapidcity : Tests(1) {
    my $test = shift;

    is( B::svref_2object( $test->{info}->can('i_edgeport_admin') )
            ->STASH->NAME,
        'SNMP::Info::RapidCity',
        q(Passport resolves i_edgeport_admin to RapidCity) );
}

# VSP-shaped: nnRst rows at bridge ports that Passport maps to the ifIndex of
# the same number
sub i_edgeport_admin__nnrst_only__maps_through_bp_index : Tests(1) {
    my $test = shift;
    my $info = $test->{info};

    $test->_stp_cache('rstp');
    $info->{store}{nn_cist_p_edge_admin} = {};
    $info->{store}{nn_rst_p_edge_admin}  = { 192 => 'false', 193 => 'true' };
    $info->{"_$_"} = 1 for qw/nn_cist_p_edge_admin nn_rst_p_edge_admin/;

    cmp_deeply( $info->i_edgeport_admin(),
        { 192 => 0, 193 => 1 },
        q(nnRstDot1dStpPortAdminEdgePort keyed by ifIndex) );
}

1;
