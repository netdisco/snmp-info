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

sub stp_trees_complete__mstp_list_incomplete__returns_0 : Tests(1) {
    my $test = shift;

    $test->_stp_cache('mstp');
    $test->incomplete_on_read( $test->{info}, 'nn_msti_priority' );
    is( $test->{info}->stp_trees_complete(), 0, q(MSTI list walk incomplete) );
}

sub stp_trees_complete__rstp_port_walk_incomplete__ports_not_complete : Tests(2) {
    my $test = shift;

    $test->_stp_cache('rstp');
    $test->incomplete_on_read( $test->{info}, 'nn_rst_p_state' );
    is( $test->{info}->stp_trees_complete(),
        1, q(RSTP: port walk does not list trees) );
    is( $test->{info}->stp_trees()->{'cist.0'}{ports_complete},
        0, q(RSTP port walk incomplete: ports not complete) );
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


sub i_edgeport_oper__passport_class__resolves_to_rapidcity : Tests(1) {
    my $test = shift;

    is( B::svref_2object( $test->{info}->can('i_edgeport_oper') )
            ->STASH->NAME,
        'SNMP::Info::RapidCity',
        q(Passport resolves i_edgeport_oper to RapidCity) );
}

sub i_edgeport_oper__nnrst_only__maps_through_bp_index : Tests(1) {
    my $test = shift;
    my $info = $test->{info};

    $test->_stp_cache('rstp');
    $info->{store}{nn_cist_p_edge_oper} = {};
    $info->{store}{nn_rst_p_edge_oper}  = { 192 => 'false', 193 => 'true' };
    $info->{"_$_"} = 1 for qw/nn_cist_p_edge_oper nn_rst_p_edge_oper/;

    cmp_deeply( $info->i_edgeport_oper(),
        { 192 => 0, 193 => 1 },
        q(nnRstDot1dStpPortOperEdgePort keyed by ifIndex) );
}

# Shaped like the VOSS lab recording: MLT 1 is the virtual IST channel,
# MLTs 10 and 20 are SMLTs. Members are ifIndexes 192 to 195. Port lists
# are port lists, one bit per ifIndex.
sub _prime_mlt {
  my ($test, $flavor) = @_;
  my $info = $test->{info};

  $info->clear_cache();
  my $store = {
    i_index => {map { $_ => $_ } 192 .. 195},
    rc_mlt_index => {1 => 6144, 10 => 6153, 20 => 6163},
    rc_mlt_ports => {},
    rc_mlt_type  => {1 => 'virtualIstMLT', 10 => 'splitMLT',
      20 => 'splitMLT'},
    rc_mlt_run_type => {1 => 'virtualIstMLT', 10 => 'splitMLT',
      20 => 'splitMLT'},
  };
  foreach my $mlt ([1, 192, 193], [10, 194], [20, 195]) {
    my ($id, @ports) = @$mlt;
    my %member = map { $_ => 1 } @ports;
    $store->{rc_mlt_ports}{$id}
      = pack('B*', join('', map { $member{$_} ? 1 : 0 } 0 .. 199));
  }
  my %cache = (
    '_layers'      => 6,
    '_description' => 'VSP-9012 (3.0.2.0) (GA)',
    '_id'          => '.1.3.6.1.4.1.2272.201',
    store          => $store,
  );
  if ($flavor eq 'vist') {
    %cache = (%cache,
      _rc_vist_status => 'up', _rc_vist_peer => '10.255.0.2',
      _rc_vist_vlan => 4000, _rc_smlt_sys_id => pack('H*', '00040a0b0c0d'),
      _rc_ist_status => 'down', _rc_ist_peer => '0.0.0.0',
      _rc_ist_vlan => 0);
  }
  else {
    $store->{rc_mlt_index} = {1 => 6144, 10 => 6153};
    $store->{rc_mlt_type}->{1} = 'istMLT';
    $store->{rc_mlt_run_type}->{1} = 'istMLT';
    %cache = (%cache,
      _rc_ist_status => 'up', _rc_ist_peer => '10.1.1.2',
      _rc_ist_vlan => 100,
      _rc_vist_status => 'down', _rc_vist_peer => '0.0.0.0',
      _rc_vist_vlan => 0);
  }
  $cache{'_' . $_} = 1 for keys %$store;
  $info->cache(\%cache);
  return;
}

sub mlag_domains : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'mlag_domains');
  $test->_prime_mlt('vist');
  cmp_deeply(
    $test->{info}->mlag_domains(),
    {
      vist => {
        kind       => 'vist',
        system_mac => '00:04:0a:0b:0c:0d',
        peer       => '10.255.0.2',
        vlan       => 4000,
        status     => 'up',
        sources    => {
          system_mac => 'RAPID-CITY::rcLacpGlobalSmltSysId',
          peer       => 'RAPID-CITY::rcVirtualIstPeerIp',
          vlan       => 'RAPID-CITY::rcVirtualIstVlanId',
          status     => 'RAPID-CITY::rcVirtualIstSessionStatus',
        },
      },
    },
    'Only the served vIST domain is reported'
  );
}

sub mlag_domains__ers_ist__ist_domain : Tests(2) {
  my $test = shift;

  $test->_prime_mlt('ist');
  my $domains = $test->{info}->mlag_domains();
  cmp_deeply([keys %$domains], ['ist'], 'Only the IST domain is reported');
  cmp_deeply(
    $domains->{ist},
    {
      kind    => 'ist',
      peer    => '10.1.1.2',
      vlan    => 100,
      status  => 'up',
      sources => {
        peer   => 'RAPID-CITY::rcMltIstPeerIp',
        vlan   => 'RAPID-CITY::rcMltIstVlanId',
        status => 'RAPID-CITY::rcMltIstSessionStatus',
      },
    },
    '... with system_mac absent when the device does not serve it'
  );
}

sub lag_groups__splitmlt__adds_smlt_mc : Tests(4) {
  my $test = shift;

  $test->_prime_mlt('vist');
  my $groups = $test->{info}->lag_groups();
  cmp_deeply(
    $groups->{6153}{mc},
    {kind => 'smlt', group => 10, domain => 'vist', state => 'splitMLT'},
    'SMLT 10 gets mc'
  );
  is($groups->{6163}{mc}{group}, 20, 'SMLT 20 gets mc');
  is($groups->{6153}{sources}{mc}, 'RAPID-CITY::rcMltMltType',
    '... and names its source');
  cmp_deeply([keys %{$groups->{6153}{members}}], [194],
    'Members still come from agg_ports');
}

sub lag_groups__splitmlt__ist_domain : Tests(1) {
  my $test = shift;

  $test->_prime_mlt('ist');
  is($test->{info}->lag_groups()->{6153}{mc}{domain}, 'ist',
    'ERS SMLT belongs to the ist domain');
}

sub lag_groups__vist_mlt__peer_link : Tests(4) {
  my $test = shift;

  $test->_prime_mlt('vist');
  my $groups = $test->{info}->lag_groups();
  is($groups->{6144}{peer_link}, 1, 'vIST MLT is the peer link');
  is($groups->{6144}{sources}{peer_link}, 'RAPID-CITY::rcMltMltType',
    '... and names its source');
  ok(!exists $groups->{6144}{mc}, '... without mc');
  ok(!exists $groups->{6153}{peer_link}, 'An SMLT is not the peer link');
}

sub lag_groups__ist_mlt__peer_link : Tests(1) {
  my $test = shift;

  $test->_prime_mlt('ist');
  is($test->{info}->lag_groups()->{6144}{peer_link}, 1,
    'istMLT is the peer link');
}

sub lag_groups__no_ist_served__no_domains_and_no_mc : Tests(2) {
  my $test = shift;

  $test->_prime_mlt('vist');
  $test->{info}->cache(
    {_rc_vist_peer => '0.0.0.0', _rc_vist_status => 'down'});
  cmp_deeply($test->{info}->mlag_domains(), {}, 'No domain served');
  ok(!exists $test->{info}->lag_groups()->{6153}{mc},
    'An SMLT without a served domain gets no mc');
}

sub lag_groups__designated_port__mc_and_peer_link_on_agg_ports_key : Tests(5) {
  my $test = shift;

  $test->_prime_mlt('vist');
  $test->{info}->cache({
    store => {
      %{$test->{info}->{store}},
      rc_mlt_dp => {1 => 192, 10 => 194},
    },
    _rc_mlt_dp => 1,
  });
  my $groups = $test->{info}->lag_groups();
  is($groups->{192}{peer_link}, 1, 'peer_link on the designated port key');
  is($groups->{194}{mc}{group}, 10, 'mc on the designated port key');
  ok(exists $groups->{194}{members}{194},
    '... together with the members');
  ok(!exists $groups->{6144} && !exists $groups->{6153},
    'No separate record under rcMltIfIndex');
  is($groups->{6163}{mc}{group}, 20,
    'An MLT without a designated port keeps rcMltIfIndex');
}

# VOSS 8.8 in SPBM mode: the standard table has a row on each member port
# and on each MLT's ifIndex; rcMltDesignatedPort names the member port.
sub lag_groups__voss_designated_port__identity_meets_agg_ports_key
  : Tests(12) {
  my $test = shift;

  $test->_prime_mlt('vist');
  my $info  = $test->{info};
  my $actor = pack('H*', '0200cb120350');
  my $zeros = pack('H*', '000000000000');
  my $partner = pack('H*', '005100acc000');
  my %ports = (1 => [192, 193], 10 => [194], 20 => [195]);
  my %store = %{$info->{store}};
  $store{rc_mlt_index} = {1 => 6144, 10 => 6153, 20 => 6163};
  $store{rc_mlt_dp}    = {1 => 192, 10 => 194, 20 => 195};
  $store{rc_mlt_type}  = {1 => 'normalMLT', 10 => 'splitMLT',
    20 => 'splitMLT'};
  foreach my $id (keys %ports) {
    my %member = map { $_ => 1 } @{$ports{$id}};
    $store{rc_mlt_ports}{$id}
      = pack('B*', join('', map { $member{$_} ? 1 : 0 } 0 .. 199));
  }
  $store{lag_actor_system}
    = {map { $_ => $actor } 194, 195, 6153, 6163};
  $store{lag_partner_system}
    = {194 => $zeros, 195 => $zeros, 6153 => $partner, 6163 => $partner};
  $store{lag_partner_key} = {194 => 0, 195 => 0, 6153 => 10, 6163 => 20};
  $store{lag_port_attached} = {194 => 6153, 195 => 6163};
  $info->cache({store => \%store, _rc_mlt_dp => 1, _rc_mlt_type => 1,
    _lag_actor_system => 1, _lag_partner_system => 1, _lag_partner_key => 1,
    _lag_port_attached => 1});
  my $groups = $info->lag_groups();

  cmp_deeply([sort { $a <=> $b } keys %$groups], [192, 194, 195],
    'One record per aggregate, none on the MLT ifIndex or its member rows');
  cmp_deeply([sort keys %{$groups->{192}{members}}], [192, 193],
    'MLT 1 has both members');
  is($groups->{192}{lacp}, 0, '... lacp 0');
  ok(!exists $groups->{192}{mc}, '... and no mc');
  is($groups->{194}{actor_system}, '02:00:cb:12:03:50',
    'SMLT 10 carries the identity of its standard rows');
  cmp_deeply([keys %{$groups->{194}{members}}], [194], '... and its member');
  is($groups->{194}{mc}{group}, 10, '... and mc');
  is($groups->{194}{partner_system}, '00:51:00:ac:c0:00',
    '... and the partner of the MLT aggregator row');
  is($groups->{194}{lacp}, 1, '... lacp 1');
  is($groups->{195}{partner_key}, 20, 'SMLT 20 carries its partner key');
  is($groups->{195}{lacp}, 1, '... lacp 1');
  is($groups->{195}{mc}{group}, 20, 'SMLT 20 has mc on its own key');
}

sub lag_groups__passport_class__resolves_to_rapidcity_hooks : Tests(4) {
  my $test = shift;

  foreach my $hook (qw/_lag_vendor_domains _lag_vendor_groups
    _lag_vendor_walked _lag_aggregator_map/) {
    no strict 'refs';
    my $name = 'SNMP::Info::RapidCity::' . $hook;
    ok(
      defined &{$name} && $test->{info}->can($hook) == \&{$name},
      "$hook resolves to RapidCity, not the IEEE802dot3ad default"
    );
  }
}

1;
