# Test::SNMP::Info::Layer3::H3C
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

package Test::SNMP::Info::Layer3::H3C;
use Test::Class::Most parent => 'My::Test::Class';
use SNMP::Info::Layer3::H3C;

sub startup : Tests(startup => 1) {
  my $test = shift;
  $test->SUPER::startup;
  $test->todo_methods(1);
}

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;
  my %store = (
    i_index => {map { $_=>$_ } (1,19,32,56,57,58)},
    i_description => {1=>'GigabitEthernet1/0/1',19=>'GigabitEthernet1/0/19',
      32=>'GigabitEthernet1/0/32',56=>'Ten-GigabitEthernet1/2/1',
      57=>'Ten-GigabitEthernet1/2/2',58=>'Bridge-Aggregation1'},
    bp_index => {1=>1,19=>19,32=>32,55=>56,56=>57,225=>58},
    stp_p_state => {1=>'blocking',19=>'forwarding',32=>'disabled',
      55=>'blocking',56=>'blocking',225=>'disabled'},
    ad_port_attached_agg => {1=>0,56=>58,57=>58},
    ad_lag_ports => {58=>pack('C*',(0)x7,3)},
  );
  $test->{info}->cache({
    _layers=>78, _id=>'.1.3.6.1.4.1.25506.1.297',
    _description=>'HP A5120-48G EI Comware Software, Version 5.20.99',
    (map { ('_' . $_)=>1 } keys %store), store=>\%store,
  });
}

sub agg_ports : Tests(2) {
  my $test = shift;
  cmp_deeply($test->{info}->agg_ports, {56=>58,57=>58},
    'Attached indexes preserve selected and unselected membership');
  $test->{info}{store}{ad_port_attached_agg} = {};
  cmp_deeply($test->{info}->agg_ports,
    SNMP::Info::IEEE802dot3ad::agg_ports_lag($test->{info}),
    'Missing attached table retains existing fallback');
}

sub i_stp_state : Tests(5) {
  my $test = shift;
  my $info = $test->{info};
  cmp_deeply($info->i_stp_state, {1=>'blocking',19=>'forwarding',32=>'disabled',58=>'disabled'},
    'Only physical aggregate member STP states omitted');
  $info->{store}{stp_p_state}{225} = 'blocking';
  is($info->i_stp_state->{58}, 'blocking', 'Blocked aggregate retained');
  $info->{store}{ad_port_attached_agg} = {};
  is($info->i_stp_state->{56}, 'blocking', 'Missing membership retains member state');
  $info->{store}{ad_port_attached_agg} = {56=>0,57=>999,1=>'invalid',19=>19};
  is($info->i_stp_state->{56}, 'blocking', 'Zero aggregate retains member state');
  is($info->i_stp_state->{57}, 'blocking', 'Unknown aggregate retains member state');
}

my $COMWARE7
    = 'H3C Comware Platform Software, Software Version 7.1.059, Alpha 7159';
my $COMWARE5
    = 'H3C Comware Platform Software, Software Version 5.20, Release 2208';

# swC of a three-switch triangle. Ports 2 and 3 face the other switches, 4 is
# an access port, 5 is a member of Bridge-Aggregation1. MACs are synthetic.
sub _stp_cache {
    my ( $test, $version, $description ) = @_;
    my $info = $test->{info};

    my $id = sub { pack( 'H*', shift ) };
    my %store = (
        i_index       => { map { $_ => $_ } ( 2 .. 5, 58 ) },
        i_description => {
            ( map { $_ => "GigabitEthernet1/0/$_" } 2 .. 5 ),
            58 => 'Bridge-Aggregation1',
        },
        bp_index             => { map { $_ => $_ } 2 .. 5 },
        ad_port_attached_agg => { 5 => 58 },
        stp_p_enable         => { 2 => 2, 3 => 1, 4 => 1, 5 => 1 },
        h3c_stp_i_id         => { 0 => 0, 1 => 1, 2 => 2 },
        h3c_stp_i_bridge     => {
            0 => $id->('800002000000000c'),
            1 => $id->('800102000000000c'),
            2 => $id->('800202000000000c'),
        },
        h3c_stp_i_root => {
            0 => $id->('800002000000000a'),
            1 => $id->('100102000000000a'),
            2 => $id->('100202000000000b'),
        },
        h3c_stp_p_state => {
            '0.2' => 'forwarding', '0.3' => 'forwarding',
            '0.4' => 'discarding', '0.5' => 'forwarding',
            '1.3' => 'forwarding', '1.4' => 'discarding',
            '1.5' => 'forwarding', '2.3' => 'discarding',
            '2.4' => 'forwarding', '2.5' => 'forwarding',
        },
        h3c_stp_vlan_mst => { 1 => 0, 10 => 1, 20 => 2, 30 => 0 },
        stp_p_id         => { map { $_ => $_ } 2 .. 5 },
        stp_p_state      => {
            2 => 'forwarding', 3 => 'forwarding',
            4 => 'blocking',   5 => 'forwarding',
        },
    );
    $store{h3c_stp_p_bridge} = {
        map { $_ => $id->('800002000000000a') }
            keys %{ $store{h3c_stp_p_state} }
    };
    $store{h3c_stp_p_port} = {
        map { $_ => $id->('8004') } keys %{ $store{h3c_stp_p_state} }
    };
    $store{stp_p_bridge} = { map { $_ => $id->('100002000000000a') } 2 .. 5 };
    $store{stp_p_port}   = { map { $_ => $id->('8002') } 2 .. 5 };

    $info->{store}{$_} = $store{$_} for keys %store;
    $info->{ '_' . $_ } = 1 for keys %store;
    $info->cache(
        {   _description     => $description,
            _h3c_stp_version => $version,
            _b_mac           => $id->('02000000000c'),
            _stp_priority    => 32768,
            _stp_root        => $id->('100002000000000a'),
        }
    );
    return;
}

sub _h3c_stp_protocol__served_versions__maps_enum_and_number : Tests(7) {
    my $test = shift;
    my $info = $test->{info};
    my %cases = (
        stp => 'stp', 0 => 'stp', rstp => 'rstp',
        2   => 'rstp', mstp => 'mstp', 3 => 'mstp',
    );
    foreach my $served ( sort keys %cases ) {
        $info->{_h3c_stp_version} = $served;
        is( $info->_h3c_stp_protocol(), $cases{$served}, "Version $served" );
    }
    delete $info->{_h3c_stp_version};
    is( $info->_h3c_stp_protocol(), undef, 'Not served' );
}

sub _h3c_comware7__sysdescr__only_version_7_matches : Tests(2) {
    my $test = shift;
    $test->{info}{_description} = $COMWARE7;
    is( $test->{info}->_h3c_comware7(), 1, 'Comware 7' );
    $test->{info}{_description} = $COMWARE5;
    is( $test->{info}->_h3c_comware7(), 0, 'Comware 5' );
}

sub hasSTP : Tests(2) {
    my $test = shift;
    $test->_stp_cache( 'stp', $COMWARE7 );
    is( $test->{info}->hasSTP(), 1, 'Force version stp' );
    $test->{info}{_h3c_stp_version} = 'mstp';
    is( $test->{info}->hasSTP(), 0, 'Not under mstp' );
}

sub hasRSTP : Tests(2) {
    my $test = shift;
    $test->_stp_cache( 'rstp', $COMWARE7 );
    is( $test->{info}->hasRSTP(), 1, 'Force version rstp' );
    $test->{info}{_h3c_stp_version} = 'mstp';
    is( $test->{info}->hasRSTP(), 0, 'Not under mstp' );
}

sub hasMSTP : Tests(2) {
    my $test = shift;
    $test->_stp_cache( 'mstp', $COMWARE7 );
    is( $test->{info}->hasMSTP(), 1, 'Force version mstp' );
    $test->{info}{_h3c_stp_version} = 'rstp';
    is( $test->{info}->hasMSTP(), 0, 'Not under rstp' );
}

sub stp_protocols : Tests(4) {
    my $test = shift;
    my $info = $test->{info};
    is( scalar $info->stp_protocols(),
        undef, 'Nothing served: no protocols' );
    $test->_stp_cache( 'mstp', $COMWARE7 );
    cmp_deeply( $info->stp_protocols(), ['mstp'], 'mstp' );
    $info->{_h3c_stp_version} = 'rstp';
    cmp_deeply( $info->stp_protocols(), ['rstp'], 'rstp' );
    $info->{_h3c_stp_version} = 'stp';
    cmp_deeply( $info->stp_protocols(), ['stp'], 'stp' );
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

sub stp_trees : Tests(13) {
    my $test = shift;
    my $info = $test->{info};

    $test->_stp_cache( 'mstp', $COMWARE7 );
    my $trees = $info->stp_trees();
    cmp_deeply( [ sort keys %$trees ], [qw/cist.0 msti.1 msti.2/],
        'MSTP: one tree per instance' );
    cmp_deeply(
        $trees->{'msti.1'},
        {   type           => 'msti',
            id             => 1,
            protocol       => 'mstp',
            measured       => 1,
            ports_complete => 1,
            contexts       => [ { kind => 'none' } ],
            bridge         => _bridge( 32768, 1, '02:00:00:00:00:0c' ),
            root           => _bridge( 4096,  1, '02:00:00:00:00:0a' ),
        },
        'MSTP: msti.1 record, MSTID in the bridge ID low 12 bits'
    );
    is( $trees->{'cist.0'}{type}, 'cist', 'Instance 0 is the CIST' );
    is( $trees->{'msti.2'}{root}{mac}, '02:00:00:00:00:0b', 'msti.2 root' );

    $info->{store}{h3c_stp_p_state}{'1.9'} = 'forwarding';
    delete $info->{_stp_trees};
    $trees = $info->stp_trees();
    is( $trees->{'msti.1'}{ports_complete},
        0, 'A state row at an unmapped bridge port: that tree incomplete' );
    is( $trees->{'msti.2'}{ports_complete}, 1, 'Other trees stay complete' );
    is( $trees->{'cist.0'}{ports_complete}, 1, 'The CIST stays complete' );
    is( $info->stp_trees(), $trees, 'Memoized' );

    $info->{store}{h3c_stp_p_state}{'1.9'} = 'forwarding';
    $test->_stp_cache( 'rstp', $COMWARE7 );
    delete $info->{_stp_trees};
    $trees = $info->stp_trees();
    cmp_deeply( [ keys %$trees ], ['cist.0'], 'RSTP: the CIST only' );
    cmp_deeply(
        [ @{ $trees->{'cist.0'} }{qw/protocol measured/} ],
        [ 'rstp', 1 ],
        'RSTP: protocol and measured'
    );

    $info->{_h3c_stp_version} = 'stp';
    delete $info->{_stp_trees};
    cmp_deeply(
        [ @{ $info->stp_trees()->{'cist.0'} }{qw/protocol measured/} ],
        [ 'stp', 0 ],
        'STP: protocol set, not measured'
    );

    $test->_stp_cache( 'mstp', $COMWARE5 );
    delete $info->{_stp_trees};
    is( $info->stp_trees()->{'msti.1'}{measured},
        0, 'Comware 5 under MSTP: not measured' );

    delete $info->{_h3c_stp_version};
    delete $info->{_stp_trees};
    cmp_deeply( $info->stp_trees(), {}, 'No force version: no trees' );
}

sub stp_tree_ports : Tests(12) {
    my $test = shift;
    my $info = $test->{info};

    $test->_stp_cache( 'mstp', $COMWARE7 );
    my $rows = $info->stp_tree_ports('msti.2');
    cmp_deeply(
        $rows->{3},
        {   tree_type         => 'msti',
            tree_id           => 2,
            state             => 'discarding',
            role              => undef,
            role_raw          => undef,
            enabled           => 1,
            designated_bridge => _bridge( 32768, 0, '02:00:00:00:00:0a' ),
            designated_port   => {
                priority => 128,
                port     => 4,
                raw      => '80:04',
            },
        },
        'MSTP: port 3 discarding, no role served'
    );
    is( $rows->{4}{state}, 'forwarding', 'MSTP: port 4 forwarding' );
    cmp_deeply( [ sort keys %$rows ], [ 3, 4 ],
        'Only the instance rows; aggregate member 5 dropped' );
    is( $info->stp_tree_ports('cist.0')->{2}{enabled},
        0, 'CIST port 2: STP disabled on the port' );
    is( $info->stp_tree_ports('cist.0')->{2}{state},
        'forwarding', 'CIST port 2 state' );

    $info->{store}{h3c_stp_p_state}{'1.9'} = 'forwarding';
    delete $info->{_stp_trees};
    cmp_deeply( [ sort keys %{ $info->stp_tree_ports('msti.1') } ],
        [ 3, 4 ], 'Unmapped bridge port dropped' );

    $info->{store}{ad_port_attached_agg} = {};
    cmp_deeply( [ sort keys %{ $info->stp_tree_ports('msti.1') } ],
        [ 3, 4, 5 ], 'Without membership the port is kept' );

    is( scalar $info->stp_tree_ports('msti.7'),
        undef, 'Unknown key: nothing' );
    like(
        $info->error(1),
        qr/stp_tree_ports\(\) has no tree 'msti\.7'/,
        'Error names the method'
    );

    $test->_stp_cache( 'rstp', $COMWARE7 );
    $info->{store}{ad_port_attached_agg} = { 5 => 58 };
    delete $info->{_stp_trees};
    $rows = $info->stp_tree_ports('cist.0');
    cmp_deeply( [ sort keys %$rows ], [ 2, 3, 4 ],
        'RSTP: BRIDGE-MIB rows, aggregate member dropped' );
    is( $rows->{4}{state}, 'blocking',
        'RSTP: state from BRIDGE-MIB, not the instance table copy' );
    is( $rows->{2}{enabled}, 0, 'RSTP: enabled from dot1dStpPortEnable' );
}

sub stp_trees_complete : Tests(5) {
    my $test = shift;
    my $info = $test->{info};
    is( $info->stp_trees_complete(), 0, 'No trees: not complete' );
    $test->_stp_cache( 'mstp', $COMWARE7 );
    is( $info->stp_trees_complete(), 1, 'MSTP trees read' );
    $test->_stp_cache( 'rstp', $COMWARE7 );
    delete $info->{_stp_trees};
    is( $info->stp_trees_complete(), 1, 'RSTP tree read' );
    $test->_pvst_cache($COMWARE7);
    is( $info->stp_trees_complete(), 1, 'PVST: every VLAN tree listed' );
    $info->session()->{Context} = 'vlan-10';
    is( $info->stp_trees_complete(),
        0, 'PVST in a context: no trees listed' );
}

sub stp_vlan_map : Tests(4) {
    my $test = shift;
    my $info = $test->{info};
    $test->_stp_cache( 'mstp', $COMWARE7 );
    cmp_deeply(
        scalar $info->stp_vlan_map(),
        {   1  => 'cist.0',
            10 => 'msti.1',
            20 => 'msti.2',
            30 => 'cist.0',
        },
        'MSTP: VLAN to tree key'
    );
    $info->{store}{h3c_stp_vlan_mst} = {};
    is( scalar $info->stp_vlan_map(), undef, 'MSTP, empty map: nothing' );
    $info->{_h3c_stp_version} = 'rstp';
    is( scalar $info->stp_vlan_map(), undef,
        'RSTP: the region map is unused' );
    delete $info->{_h3c_stp_version};
    is( scalar $info->stp_vlan_map(), undef, 'Nothing served: nothing' );
}

# swC with force version rstp: the instance table lists VLANs 1, 10, 20 and
# 4094 as well as 0, and no bridge, root or port-state column is served.
sub _pvst_cache {
    my ( $test, $description ) = @_;
    my $info = $test->{info};

    $test->_stp_cache( 'rstp', $description );
    $info->{store}{h3c_stp_i_id}
        = { map { $_ => $_ } ( 0, 1, 10, 20, 4094 ) };
    $info->{store}{$_} = {} for qw/h3c_stp_i_bridge h3c_stp_i_root
        h3c_stp_p_state h3c_stp_p_bridge h3c_stp_p_port/;
    $info->{walk_status} = {};
    delete $info->{_stp_trees};
    return;
}

sub pvst_trees : Tests(9) {
    my $test = shift;
    my $info = $test->{info};

    $test->_pvst_cache($COMWARE7);
    my $trees = $info->stp_trees();
    cmp_deeply( [ sort keys %$trees ],
        [ sort qw/vlan.1 vlan.10 vlan.20 vlan.4094/ ],
        'PVST: one tree per VLAN' );
    cmp_deeply(
        $trees->{'vlan.10'},
        {   type           => 'vlan',
            id             => 10,
            vlan           => 10,
            protocol       => 'pvst',
            measured       => 1,
            ports_complete => 0,
            contexts       => [],
            bridge         => undef,
            root           => undef,
        },
        'PVST: vlan.10 record, no context serves it'
    );
    cmp_deeply( $info->stp_protocols(), ['pvst'], 'stp_protocols' );
    is( $info->hasRSTP(), 0, 'Not hasRSTP' );
    cmp_deeply( $info->stp_tree_ports('vlan.10'), {}, 'No port data' );
    is( $info->stp_trees_complete(), 1, 'Every VLAN tree is listed' );

    $info->{walk_status}{h3c_stp_i_bridge}
        = { complete => 1, reason => 'absent' };
    cmp_deeply( $info->stp_protocols(), ['pvst'],
        'Absent column: still pvst' );

    $test->_pvst_cache($COMWARE5);
    is( $info->stp_trees()->{'vlan.10'}{measured}, 0,
        'Comware 5: not measured' );

    $test->_stp_cache( 'rstp', $COMWARE7 );
    $info->{store}{h3c_stp_i_bridge} = {};
    delete $info->{_stp_trees};
    cmp_deeply( $info->stp_protocols(), ['rstp'],
        'Empty bridge column but port states served: rstp' );
}

sub pvst_unreadable_column : Tests(4) {
    my $test = shift;
    my $info = $test->{info};

    $test->_pvst_cache($COMWARE7);
    $info->{walk_status}{h3c_stp_i_bridge}
        = { complete => 0, reason => 'timeout' };
    is( scalar $info->stp_protocols(), undef,
        'Timed-out column: no protocol' );
    cmp_deeply( $info->stp_trees(), {}, 'No trees' );
    is( $info->stp_trees_complete(), 0, 'Not complete' );
    cmp_deeply( [ sort keys %{ $info->i_stp_state() } ], [ 2, 3, 4 ],
        'i_stp_state keeps its values' );
}

# The bridge column is walked, not primed, so the walk itself records its
# timeout during the first call
sub _h3c_stp_protocol__first_walk_times_out__is_unknown : Tests(4) {
    my $test = shift;
    my $info = $test->{info};

    $test->_pvst_cache($COMWARE7);
    delete $info->{_h3c_stp_i_bridge};
    delete $info->{store}{h3c_stp_i_bridge};
    My::Test::Class::set_fault(
        $test->mock_session,
        {   op       => 'getnext',
            leaf     => 'HH3C-LswMSTP-MIB::hh3cdot1sMstiBridgeID',
            after    => 0,
            ErrorNum => -24,
            ErrorStr => 'Timeout',
        }
    );
    is( scalar $info->stp_protocols(), undef, 'First call: no protocol' );
    cmp_deeply(
        $info->walk_status('h3c_stp_i_bridge'),
        superhashof( { complete => 0, reason => 'timeout' } ),
        'The walk recorded the timeout'
    );

    $test->_pvst_cache($COMWARE7);
    delete $info->{_h3c_stp_i_bridge};
    delete $info->{store}{h3c_stp_i_bridge};
    My::Test::Class::set_fault( $test->mock_session,
        $test->mock_session->{Fault} );
    cmp_deeply( [ sort keys %{ $info->i_stp_state() } ], [ 2, 3, 4 ],
        'First call to i_stp_state: values kept' );
    is( $info->hasPVST(), 0, 'Not hasPVST' );
}

sub hasPVST : Tests(3) {
    my $test = shift;
    my $info = $test->{info};
    $test->_pvst_cache($COMWARE7);
    is( $info->hasPVST(), 1, 'PVST tables' );
    $info->{walk_status}{h3c_stp_i_bridge}
        = { complete => 0, reason => 'timeout' };
    is( $info->hasPVST(), 0, 'Unreadable column: not known' );
    $test->_stp_cache( 'rstp', $COMWARE7 );
    is( $info->hasPVST(), 0, 'RSTP tables' );
}

sub i_stp_state_pvst : Tests(3) {
    my $test = shift;
    my $info = $test->{info};

    $test->_pvst_cache($COMWARE7);
    cmp_deeply( $info->i_stp_state(), {}, 'PVST on Comware 7: nothing' );
    $test->_pvst_cache($COMWARE5);
    cmp_deeply( [ sort keys %{ $info->i_stp_state() } ], [ 2, 3, 4 ],
        'PVST on Comware 5: values kept' );
    $test->_stp_cache( 'rstp', $COMWARE7 );
    cmp_deeply( [ sort keys %{ $info->i_stp_state() } ], [ 2, 3, 4 ],
        'RSTP on Comware 7: values kept' );
}

1;
