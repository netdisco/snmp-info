# Test::SNMP::Info::CiscoStpExtensions
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

package Test::SNMP::Info::CiscoStpExtensions;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::CiscoStpExtensions;

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

# swC of a three-switch IOL-L2 triangle (Rapid-PVST+, PVST+ and MST):
# trunks are bridge ports 2 and 3, VLAN 1's only port is 4. MSTI 1 carries
# VLAN 10, MSTI 2 VLAN 20. MACs are synthetic: swA 0a.
sub _mst_bitmaps {
    my %arg = @_;
    return (
        '_stpx_smst_vlans_mapped_1k2k' => 1,
        '_stpx_smst_vlans_mapped_3k4k' => 1,
        'stpx_smst_vlans_mapped_1k2k'  => $arg{low},
        'stpx_smst_vlans_mapped_3k4k'  => $arg{high},
    );
}

sub _all_vlans_bitmaps {
    return _mst_bitmaps(
        low  => { 0 => pack( 'H*', 'ff' x 256 ) },
        high => { 0 => pack( 'H*', 'ff' x 256 ) },
    );
}

sub _survey_mst_bitmaps {
    my $msti1 = shift || '0020';
    return _mst_bitmaps(
        low => {
            0 => pack( 'H*', 'ffdff7' . ( 'ff' x 253 ) ),
            1 => pack( 'H*', $msti1 ),
            2 => pack( 'H*', '000008' ),
        },
        high => {
            0 => pack( 'H*', 'ff' x 256 ),
            1 => '',
            2 => '',
        },
    );
}

sub _pvst_vlan_enable {
    return map { $_ => 'enabled' } qw/1 10 20 1002 1003 1004 1005/;
}

sub _iol_pvst_cache {
    my $type = shift;
    my %store = (
        'stpx_pvst_vlan_enable' => { _pvst_vlan_enable() },
        'stpx_faststart_oper'   => {
            map { $_ => 'disabled' } qw/1.4 10.2 10.3 20.2 20.3/
        },
        _all_vlans_bitmaps(),
    );
    if ( $type eq 'rapidPvstPlus' ) {
        $store{stpx_rstp_port_role} = {
            '1.4'  => 'designated',
            '10.2' => 'root',
            '10.3' => 'alternate',
            '20.2' => 'alternate',
            '20.3' => 'root',
        };
    }
    my %flags = map { ( "_$_" => 1 ) } grep { !/^_/ } keys %store;
    my %scalars = map { ( $_ => delete $store{$_} ) } grep {/^_/} keys %store;
    return {
        '_stpx_stp_type' => $type,
        '_stp_root'      => pack( 'H*', '800102000000000c' ),
        %flags, %scalars,
        'store' => \%store,
    };
}

sub _iol_mst_cache {
    my $msti1 = shift;
    my %bitmaps = _survey_mst_bitmaps($msti1);
    my %store = (
        'stpx_pvst_vlan_enable' => { _pvst_vlan_enable() },
        'stpx_rstp_port_role'   => {
            '0.2' => 'root',
            '0.3' => 'alternate',
            '0.4' => 'designated',
            '1.2' => 'root',
            '1.3' => 'alternate',
            '2.2' => 'alternate',
            '2.3' => 'root',
        },
        map { $_ => $bitmaps{$_} } grep { !/^_/ } keys %bitmaps,
    );
    return {
        '_stpx_stp_type' => 'mst',
        '_stp_root'      => pack( 'H*', '800002000000000a' ),
        ( map { ( "_$_" => 1 ) } keys %store ),
        'store' => \%store,
    };
}

sub _vlan_tree {
    my ( $vlan, $protocol ) = @_;
    return {
        type           => 'vlan',
        id             => $vlan,
        vlan           => $vlan,
        protocol       => $protocol,
        measured       => 0,
        ports_complete => 1,
        contexts       => [
            {   kind => 'vlan',
                id   => $vlan,
                v2c  => "%s\@$vlan",
                v3   => "vlan-$vlan"
            }
        ],
        bridge => undef,
        root   => undef,
    };
}

sub _bid {
    my ( $prio, $sw ) = @_;
    return {
        priority   => hex($prio) & 0xf000,
        sys_id_ext => hex($prio) & 0x0fff,
        mac        => '02:00:00:00:00:' . $sw,
        raw        => join( ':', unpack( '(A2)*', $prio . '0200000000' . $sw ) ),
    };
}

sub stp_trees : Tests(17) {
    my $test = shift;
    my $info = $test->{info};

    can_ok( $info, 'stp_trees' );
    $info->cache( _iol_pvst_cache('rapidPvstPlus') );
    my $trees = $info->stp_trees();
    cmp_deeply( [ sort keys %$trees ], [qw/vlan.1 vlan.10 vlan.20/],
        q(Rapid-PVST+: running trees only, no 1002-1005, no MST region) );
    cmp_deeply( $trees->{'vlan.10'}, _vlan_tree( 10, 'rapid-pvst' ),
        q(VLAN 10 record) );
    cmp_deeply( $trees->{'vlan.1'}{contexts}, [ { kind => 'none' } ],
        q(VLAN 1 is the default context) );
    cmp_deeply( $trees->{'vlan.1'}{root}, _bid( '8001', '0c' ),
        q(VLAN 1 root from the default context) );

    $info->clear_cache();
    $info->cache( _iol_pvst_cache('pvstPlus') );
    $trees = $info->stp_trees();
    cmp_deeply( [ sort keys %$trees ], [qw/vlan.1 vlan.10 vlan.20/],
        q(PVST+: trees from the fast-start table alone) );
    is( $trees->{'vlan.20'}{protocol}, 'pvst', q(PVST+ protocol) );

    $info->clear_cache();
    $info->cache( _iol_mst_cache() );
    $trees = $info->stp_trees();
    cmp_deeply( [ sort keys %$trees ], [qw/cist.0 msti.1 msti.2/],
        q(MST: the CIST and each MSTI) );
    cmp_deeply(
        $trees->{'cist.0'},
        {   type           => 'cist',
            id             => 0,
            protocol       => 'mstp',
            measured       => 0,
            ports_complete => 0,
            contexts       => [ { kind => 'none' } ],
            bridge         => undef,
            root           => _bid( '8000', '0a' ),
        },
        q(CIST record)
    );
    cmp_deeply(
        $trees->{'msti.1'},
        {   type           => 'msti',
            id             => 1,
            protocol       => 'mstp',
            measured       => 0,
            ports_complete => 1,
            contexts       => _vlan_tree( 10, 'mstp' )->{contexts},
            bridge         => undef,
            root           => undef,
        },
        q(MSTI 1 record, read through VLAN 10)
    );

    $info->clear_cache();
    $info->cache( _iol_mst_cache('0030') );
    cmp_deeply(
        [ map { $_->{id} } @{ $info->stp_trees()->{'msti.1'}{contexts} } ],
        [ 10, 11 ], q(Two VLANs on one MSTI: both contexts, in VLAN order) );

    $info->clear_cache();
    my $cache = _iol_pvst_cache('rapidPvstPlus');
    delete $cache->{_stpx_stp_type};
    $info->cache($cache);
    cmp_deeply( $info->stp_trees(), {}, q(No stpxSpanningTreeType: no trees) );

    $info->clear_cache();
    $cache->{_stpx_stp_type} = 'mistp';
    $info->cache($cache);
    cmp_deeply( $info->stp_trees(), {}, q(MISTP: no trees) );

    $info->clear_cache();
    $cache->{_stpx_stp_type} = 5;
    $info->cache($cache);
    cmp_deeply( [ sort keys %{ $info->stp_trees() } ],
        [qw/vlan.1 vlan.10 vlan.20/], q(Numeric type 5 is Rapid-PVST+) );

    $info->clear_cache();
    $info->cache( _iol_pvst_cache('rapidPvstPlus') );
    $info->session()->{Context} = 'vlan-10';
    is( $info->stp_trees(), undef, q(Refused in a context) );
    like( $info->error(), qr/default context/,
        q(Error names the default context) );
    $info->session()->{Context} = undef;
    ok( 1, q(Context reset) );
}

sub stp_trees_complete : Tests(2) {
    my $test = shift;

    $test->{info}->cache( _iol_pvst_cache('rapidPvstPlus') );
    is( $test->{info}->stp_trees_complete(), 1, q(Rapid-PVST+ trees read) );

    $test->{info}->clear_cache();
    is( $test->{info}->stp_trees_complete(), 0, q(No indicator: unread) );
}

sub stp_protocols : Tests(4) {
    my $test = shift;
    my $info = $test->{info};

    my %expect = (
        rapidPvstPlus => ['rapid-pvst'],
        pvstPlus      => ['pvst'],
    );
    foreach my $type ( sort keys %expect ) {
        $info->clear_cache();
        $info->cache( _iol_pvst_cache($type) );
        cmp_deeply( $info->stp_protocols(), $expect{$type}, $type );
    }
    $info->clear_cache();
    $info->cache( _iol_mst_cache() );
    cmp_deeply( $info->stp_protocols(), ['mstp'], q(mst) );

    $info->clear_cache();
    is( $info->stp_protocols(), undef, q(No indicator: no protocols) );
}

sub hasPVST : Tests(2) {
    my $test = shift;

    $test->{info}->cache( _iol_pvst_cache('pvstPlus') );
    is( $test->{info}->hasPVST(), 1, q(pvstPlus) );
    $test->{info}->clear_cache();
    $test->{info}->cache( _iol_pvst_cache('rapidPvstPlus') );
    is( $test->{info}->hasPVST(), 0, q(Not under Rapid-PVST+) );
}

sub hasRapidPVST : Tests(2) {
    my $test = shift;

    $test->{info}->cache( _iol_pvst_cache('rapidPvstPlus') );
    is( $test->{info}->hasRapidPVST(), 1, q(rapidPvstPlus) );
    $test->{info}->clear_cache();
    $test->{info}->cache( _iol_mst_cache() );
    is( $test->{info}->hasRapidPVST(), 0, q(Not under MST) );
}

sub hasMSTP : Tests(2) {
    my $test = shift;

    $test->{info}->cache( _iol_mst_cache() );
    is( $test->{info}->hasMSTP(), 1, q(mst) );
    $test->{info}->clear_cache();
    $test->{info}->cache( _iol_pvst_cache('rapidPvstPlus') );
    is( $test->{info}->hasMSTP(), 0, q(MST region served outside MST) );
}

sub stp_vlan_map : Tests(6) {
    my $test = shift;

    $test->{info}->cache( _iol_mst_cache() );
    my $map = $test->{info}->stp_vlan_map();
    is( scalar keys %$map, 4094, q(Every VLAN 1 to 4094 mapped) );
    ok( !exists $map->{0}, q(No VLAN 0) );
    is( $map->{1},    'cist.0', q(VLAN 1 on the CIST) );
    is( $map->{10},   'msti.1', q(VLAN 10 on MSTI 1) );
    is( $map->{20},   'msti.2', q(VLAN 20 on MSTI 2) );

    $test->{info}->clear_cache();
    $test->{info}->cache( _iol_pvst_cache('rapidPvstPlus') );
    is( $test->{info}->stp_vlan_map(), undef, q(No map under PVST) );
}

sub snmp_context : Tests(2) {
    my $test = shift;

    cmp_deeply(
        $test->{info}->snmp_context( 'vlan', 10 ),
        { kind => 'vlan', id => 10, v2c => '%s@10', v3 => 'vlan-10' },
        q(VLAN context names)
    );
    is( $test->{info}->snmp_context( 'mst', 1 ), undef,
        q(No MST context on IOS) );
}

1;
