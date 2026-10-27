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

# swC of a three-switch EXOS ring, one builder per protocol (MSTP, 802.1W,
# PVST+). MACs are synthetic: swA 0a, swB 0b, swC 0c.
sub _exos_bid {
    my ( $prio, $sw ) = @_;
    return pack( 'H*', $prio . '0200000000' . $sw );
}

sub _exos_cache {
    my %arg = @_;
    my ( %name, %tag, %mac, %root, %mode, %state, %dbridge, %dport );
    foreach my $inst ( sort keys %{ $arg{domains} } ) {
        my $d = $arg{domains}{$inst};
        $name{$inst} = $d->{name};
        $tag{$inst}  = $d->{tag};
        $mac{$inst}  = _exos_bid( '8000', '0c' );
        $root{$inst} = _exos_bid( @{ $d->{root} } );
        foreach my $if ( sort { $a <=> $b } keys %{ $d->{ports} } ) {
            my $p = $d->{ports}{$if};
            $mode{"$inst.$if"}    = $d->{mode};
            $state{"$inst.$if"}   = $p->[0];
            $dbridge{"$inst.$if"} = _exos_bid( @{ $p->[1] } );
            $dport{"$inst.$if"}   = pack( 'H*', '8002' );
        }
    }
    return {
        '_description' => 'ExtremeXOS (VM) version 33.6.1.14 33.6.1.14',
        '_dot1dStpVersion' => $arg{version},
        map( { ( "_$_" => 1 ) }
            qw/ex_stp_i_name ex_stp_i_tag ex_stp_i_mac stp_i_root
                ex_stp_p_mode stp_p_state stp_p_bridge stp_p_port
                ex_stp_vlan_mask ex_vlan_id/
        ),
        'store' => {
            'ex_stp_i_name'    => \%name,
            'ex_stp_i_tag'     => \%tag,
            'ex_stp_i_mac'     => \%mac,
            'stp_i_root'       => \%root,
            'ex_stp_p_mode'    => \%mode,
            'stp_p_state'      => \%state,
            'stp_p_bridge'     => \%dbridge,
            'stp_p_port'       => \%dport,
            'ex_stp_vlan_mask' => {
                map { ( $_ => pack( 'H*', 'c0' . '00' x 15 ) ) }
                    @{ $arg{vlan_rows} }
            },
            'ex_vlan_id' => { 1000004 => 1, 1000007 => 10, 1000008 => 20 },
        },
    };
}

sub _exos_mstp_cache {
    return _exos_cache(
        version   => 3,
        vlan_rows => [qw/1000004.1 1000007.2 1000008.3/],
        domains   => {
            1 => {
                name  => 's0', tag => 0, mode => 'dot1d',
                root  => [ '8000', '0b' ],
                ports => {
                    1001 => [ 'blocking',   [ '8000', '0a' ] ],
                    1002 => [ 'forwarding', [ '8000', '0b' ] ],
                },
            },
            2 => {
                name  => 's1', tag => 0, mode => 'dot1d',
                root  => [ '1000', '0a' ],
                ports => {
                    1001 => [ 'forwarding', [ '1000', '0a' ] ],
                    1002 => [ 'blocking',   [ '8000', '0b' ] ],
                },
            },
            3 => {
                name  => 's2', tag => 0, mode => 'dot1d',
                root  => [ '1000', '0b' ],
                ports => {
                    1001 => [ 'blocking',   [ '8000', '0a' ] ],
                    1002 => [ 'forwarding', [ '1000', '0b' ] ],
                },
            },
        },
    );
}

sub _exos_rstp_cache {
    return _exos_cache(
        version   => 2,
        vlan_rows => [qw/1000004.1 1000007.1 1000008.1/],
        domains   => {
            1 => {
                name  => 's0', tag => 0, mode => 'dot1d',
                root  => [ '1000', '0a' ],
                ports => {
                    1001 => [ 'forwarding', [ '1000', '0a' ] ],
                    1002 => [ 'blocking',   [ '2000', '0b' ] ],
                },
            },
        },
    );
}

sub _exos_pvst_cache {
    return _exos_cache(
        version   => 0,
        vlan_rows => [qw/1000004.1 1000007.2 1000008.3/],
        domains   => {
            1 => {
                name  => 's0', tag => 0, mode => 'dot1d',
                root  => [ '8000', '0b' ],
                ports => {
                    1001 => [ 'forwarding', [ '8000', '0b' ] ],
                    1002 => [ 'forwarding', [ '8000', '0c' ] ],
                },
            },
            2 => {
                name  => 's1', tag => 10, mode => 'pvstp',
                root  => [ '1000', '0a' ],
                ports => {
                    1001 => [ 'forwarding', [ '1000', '0a' ] ],
                    1002 => [ 'blocking',   [ '8000', '0b' ] ],
                },
            },
            3 => {
                name  => 's2', tag => 20, mode => 'pvstp',
                root  => [ '1000', '0b' ],
                ports => {
                    1001 => [ 'forwarding', [ '8000', '0c' ] ],
                    1002 => [ 'forwarding', [ '1000', '0b' ] ],
                },
            },
        },
    );
}

sub _exos_bid_rec {
    my ( $prio, $sw ) = @_;
    my $raw = join( ':', unpack( '(A2)*', $prio . '0200000000' . $sw ) );
    return {
        priority   => hex($prio) & 0xf000,
        sys_id_ext => hex($prio) & 0x0fff,
        mac        => '02:00:00:00:00:' . $sw,
        raw        => $raw
    };
}

sub stp_trees : Tests(14) {
    my $test = shift;

    can_ok( $test->{info}, 'stp_trees' );
    $test->{info}->cache( _exos_mstp_cache() );
    my $trees = $test->{info}->stp_trees();
    cmp_deeply( [ sort keys %$trees ],
        [qw/domain.1 domain.2 domain.3/], q(One tree per domain) );
    cmp_deeply(
        $trees->{'domain.2'},
        {   type           => 'domain',
            id             => 2,
            name           => 's1',
            protocol       => undef,
            measured       => 1,
            ports_complete => 1,
            contexts       => [ { kind => 'none' } ],
            bridge         => _exos_bid_rec( '8000', '0c' ),
            root           => _exos_bid_rec( '1000', '0a' ),
        },
        q(MSTI domain record)
    );
    is( $trees->{'domain.1'}{protocol}, undef,
        q(Several domains: device-wide version names no domain) );
    ok( !exists $trees->{'domain.1'}{vlan}, q(Untagged domain has no vlan) );

    $test->{info}->clear_cache();
    $test->{info}->cache( _exos_rstp_cache() );
    $trees = $test->{info}->stp_trees();
    cmp_deeply( [ keys %$trees ], ['domain.1'], q(802.1W has one domain) );
    is( $trees->{'domain.1'}{protocol}, 'rstp',
        q(One domain takes the version) );

    $test->{info}->clear_cache();
    $test->{info}->cache( _exos_pvst_cache() );
    $trees = $test->{info}->stp_trees();
    is( $trees->{'domain.1'}{protocol}, 'stp',
        q(s0 under PVST+: version 0 and 802.1D ports) );
    is( $trees->{'domain.2'}{protocol},
        'pvst', q(pvstp ports make s1 PVST+) );
    is( $trees->{'domain.2'}{vlan}, 10, q(s1 carries its tag) );
    is( $trees->{'domain.3'}{vlan}, 20, q(s2 carries its tag) );
    ok( !exists $trees->{'domain.1'}{vlan}, q(s0 tag 0 gives no vlan) );

    $test->{info}->clear_cache();
    $test->{info}->cache( _exos_mstp_cache() );
    $test->{info}->session()->{Context} = 'vlan-10';
    is( $test->{info}->stp_trees(), undef, q(Refused in a context) );
    like( $test->{info}->error(), qr/default context/,
        q(Error names the default context) );
}

sub stp_trees_complete : Tests(2) {
    my $test = shift;

    $test->{info}->cache( _exos_mstp_cache() );
    is( $test->{info}->stp_trees_complete(), 1, q(Every domain read) );

    $test->{info}->clear_cache();
    is( $test->{info}->stp_trees_complete(), 0, q(No domain table read) );
}

sub stp_tree_ports : Tests(5) {
    my $test = shift;

    can_ok( $test->{info}, 'stp_tree_ports' );
    $test->{info}->cache( _exos_mstp_cache() );
    $test->{info}{_stp_p_enable} = 1;
    $test->{info}{store}{stp_p_enable} = { '2.1001' => 'true' };
    is( $test->{info}->stp_tree_ports('domain.2')->{1001}{enabled},
        1, q(extremeStpPortStpEnabled true gives enabled 1) );
    $test->{info}{store}{stp_p_enable} = {};
    my $port = sub {
        my ( $state, $prio, $sw ) = @_;
        return {
            tree_type         => 'domain',
            tree_id           => 2,
            state             => $state,
            role              => undef,
            role_raw          => undef,
            enabled           => undef,
            designated_bridge => _exos_bid_rec( $prio, $sw ),
            designated_port   =>
                { priority => 128, port => 2, raw => '80:02' },
        };
    };
    cmp_deeply(
        $test->{info}->stp_tree_ports('domain.2'),
        {   1001 => $port->( 'forwarding', '1000', '0a' ),
            1002 => $port->( 'blocking',   '8000', '0b' ),
        },
        q(Only domain 2's rows, keyed by ifIndex)
    );
    is( $test->{info}->stp_tree_ports('domain.9'), undef,
        q(Unknown key refused) );
    like( $test->{info}->error(), qr/no tree 'domain\.9'/,
        q(Error names the unknown key) );
}

sub stp_protocols : Tests(3) {
    my $test = shift;

    $test->{info}->cache( _exos_mstp_cache() );
    cmp_deeply( $test->{info}->stp_protocols(), ['mstp'], q(MSTP) );

    $test->{info}->clear_cache();
    $test->{info}->cache( _exos_rstp_cache() );
    $test->{info}{_dot1dStpVersion} = 'rstp';
    cmp_deeply( $test->{info}->stp_protocols(), ['rstp'],
        q(802.1W, enum label form) );

    $test->{info}->clear_cache();
    $test->{info}->cache( _exos_pvst_cache() );
    cmp_deeply( $test->{info}->stp_protocols(), [ 'stp', 'pvst' ],
        q(PVST+ with an 802.1D s0) );
}

sub hasMSTP : Tests(2) {
    my $test = shift;

    $test->{info}->cache( _exos_mstp_cache() );
    is( $test->{info}->hasMSTP(), 1, q(dot1dStpVersion 3) );

    $test->{info}->clear_cache();
    $test->{info}->cache( _exos_rstp_cache() );
    is( $test->{info}->hasMSTP(), 0, q(Not under 802.1W) );
}

sub hasRSTP : Tests(2) {
    my $test = shift;

    $test->{info}->cache( _exos_rstp_cache() );
    $test->{info}{_dot1dStpVersion} = 'rstp';
    is( $test->{info}->hasRSTP(), 1, q(dot1dStpVersion rstp label) );

    $test->{info}->clear_cache();
    $test->{info}->cache( _exos_mstp_cache() );
    is( $test->{info}->hasRSTP(), 0, q(Not under MSTP) );
}

sub hasPVST : Tests(2) {
    my $test = shift;

    $test->{info}->cache( _exos_pvst_cache() );
    is( $test->{info}->hasPVST(), 1, q(pvstp port mode) );

    $test->{info}->clear_cache();
    $test->{info}->cache( _exos_mstp_cache() );
    is( $test->{info}->hasPVST(), 0, q(No pvstp ports under MSTP) );
}

sub hasSTP : Tests(3) {
    my $test = shift;

    $test->{info}->cache( _exos_pvst_cache() );
    $test->{info}{_dot1dStpVersion} = 'stpCompatible';
    is( $test->{info}->hasSTP(), 1, q(802.1D s0, enum label form) );

    $test->{info}->clear_cache();
    $test->{info}->cache(
        _exos_cache(
            version   => 0,
            vlan_rows => [qw/1000007.2/],
            domains   => {
                2 => {
                    name  => 's1', tag => 10, mode => 'pvstp',
                    root  => [ '1000', '0a' ],
                    ports => { 1001 => [ 'forwarding', [ '1000', '0a' ] ] },
                },
            },
        )
    );
    is( $test->{info}->hasSTP(), 0, q(Every domain in PVST+ mode) );

    $test->{info}->clear_cache();
    $test->{info}->cache( _exos_mstp_cache() );
    is( $test->{info}->hasSTP(), 0, q(Not under MSTP) );
}

sub stp_vlan_map : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'stp_vlan_map' );
    $test->{info}->cache( _exos_mstp_cache() );
    cmp_deeply(
        $test->{info}->stp_vlan_map(),
        { 1 => 'domain.1', 10 => 'domain.2', 20 => 'domain.3' },
        q(MSTP map, one VLAN per domain)
    );

    $test->{info}->clear_cache();
    $test->{info}->cache( _exos_rstp_cache() );
    cmp_deeply(
        $test->{info}->stp_vlan_map(),
        { 1 => 'domain.1', 10 => 'domain.1', 20 => 'domain.1' },
        q(802.1W map, every VLAN on s0)
    );
}

sub stp_voss_unread : Tests(4) {
    my $test = shift;

    $test->{info}->cache(
        {   '_description'  => '5520-24T-FabricEngine (9.4.0.0)',
            '_b_mac'        => pack( 'H*', '02000000000c' ),
            '_stp_priority' => 32768,
            '_stp_root'     => pack( 'H*', '100002000000000a' ),
            '_stp_p_id'     => 1,
            'store'         => { 'stp_p_id' => { 1 => 1, 2 => 2 } },
        }
    );
    cmp_deeply( $test->{info}->stp_trees(), {}, q(VOSS: no EXOS domains) );
    is( $test->{info}->stp_trees_complete(), 0, q(VOSS: trees unread) );
    is( $test->{info}->stp_protocols(), undef, q(VOSS: no protocols) );
    is( $test->{info}->os(), 'voss', q(Fixture is VOSS) );
}

# EXOS 33.6 shape: VRs configured, yet MPLS-L3VPN-STD-MIB counts zero and
# lists no row
sub _prime_vrf_none_counted {
  my $test = shift;
  $test->{info}{$_} = 1 for qw/_vrf_l3vpn_rd _vrf_l3vpn_descr
    _vrf_l3vpn_oper _vrf_l3vpn_rt _vrf_l3vpn_if/;
  $test->{info}{store}{$_} = {} for
    qw/vrf_l3vpn_rd vrf_l3vpn_descr vrf_l3vpn_oper vrf_l3vpn_rt vrf_l3vpn_if/;
  $test->{info}{_vrf_configured} = 0;
  return;
}

sub vrf_instances_complete : Tests(2) {
  my $test = shift;

  $test->_prime_vrf_none_counted();
  is($test->{info}->vrf_instances_complete(),
    undef, q(EXOS zero configured count reads unsupported, not none));
  cmp_deeply([keys %{$test->{info}->vrf_instances()}],
    ['default'], q(Only default is listed));
}

sub vrf_instances_complete__exos_caller_names__is_0 : Tests(1) {
  my $test = shift;

  $test->_prime_vrf_none_counted();
  is($test->{info}->vrf_instances_complete(['vr-red']),
    0, q(A caller name still reads incomplete));
}

sub vrf_instances_complete__not_exos__unchanged : Tests(1) {
  my $test = shift;

  $test->_prime_vrf_none_counted();
  $test->{info}{_description} = '5520-48SE-FabricEngine (8.10.1.0)';
  is($test->{info}->vrf_instances_complete(),
    1, q(VOSS keeps the standard reading of a zero count));
}

# EXOS 33.6 with virtual routers red, blue, green and grey, as SNMPv3
# contexts. The address table is the same in every context. Routes and
# neighbors are scoped, and a VLAN's IPv4 route sits on a different ifIndex
# (the router interface) from its IPv6 address and neighbors.
my $PFX = '.1.3.6.1.2.1.4.32.1.5';
my @EXOS_ADDRESSES = (
  [1000005, '10.0.0.15',    24],  [1000011, '10.200.0.1', 24],
  [1000015, '10.201.0.1',   24],  [1000017, '10.202.0.1', 24],
  [1000020, '10.204.0.1',   32],  [1000022, '203.0.113.21', 32],
  [1000011, '2001:db8:0:0:0:0:0:1', 64],
  [1000015, '2001:db8:1:0:0:0:0:1', 64],
  [1000017, '2001:db8:2:0:0:0:0:1', 64],
  [1000019, '2001:db8:3:0:0:0:0:1', 64],
  [1000020, '2001:db8:4:0:0:0:0:1', 128],
);

sub _arcs {
  my $ip = shift;
  return $ip =~ /:/
    ? (2, 16, unpack('C*', pack('n8', map { hex } split /:/, $ip)))
    : (1, 4, split /\./, $ip);
}

sub _exos_address_store {
  my (%index, %type, %prefix);
  foreach my $row (@EXOS_ADDRESSES) {
    my ($port, $ip, $length) = @$row;
    my $iid = join '.', _arcs($ip);
    $index{$iid}  = $port;
    $type{$iid}   = 'unicast';
    $prefix{$iid} = "$PFX.$port.$iid.$length";
  }
  return (new_ip_index => \%index, new_ip_type => \%type,
    new_ip_prefix => \%prefix);
}

# inetCidrRouteTable rows: [prefix, length, next hop, ifIndex, proto]
sub _exos_route_store {
  my (%if, %proto);
  foreach my $row (@_) {
    my ($prefix, $length, $hop, $port, $proto) = @$row;
    my @hop  = _arcs($hop);
    my @dest = _arcs($prefix);
    my $iid  = join '.', @dest, $length, 0, @hop;
    $if{$iid}    = $port;
    $proto{$iid} = $proto // 'local';
  }
  return (vrf_cidr_if => \%if, vrf_cidr_proto => \%proto);
}

# ipNetToPhysicalTable rows: [ifIndex, address, MAC octet]
sub _exos_neighbor_store {
  my %mac;
  foreach my $row (@_) {
    my ($port, $ip, $octet) = @$row;
    $mac{join '.', $port, _arcs($ip)} = pack('C6', 2, 0, 0, 0, 2, $octet);
  }
  return (ip_n2p_phys_addr => \%mac);
}

sub _exos_vrf_cache {
  my %store = @_;
  my $cache = {
    '_layers'      => 78,
    '_description' => 'ExtremeXOS (Stack) version 33.6.1.7 by release-manager',
    '_id'          => '.1.3.6.1.4.1.1916.2.65',
    'store'        => \%store,
  };
  $cache->{"_$_"} = 1 for keys %store;
  return $cache;
}

my @RED_ROUTES = (
  ['10.200.0.0', 24, '10.200.0.1', 1000012], ['10.200.0.1', 32, '10.200.0.1', 1000012],
  ['10.201.0.0', 24, '10.201.0.1', 1000016], ['10.201.0.1', 32, '10.201.0.1', 1000016],
  ['2001:db8:0:0:0:0:0:0', 64, '2001:db8:0:0:0:0:0:1', 1000011],
  ['2001:db8:1:0:0:0:0:0', 64, '2001:db8:1:0:0:0:0:1', 1000015],
);

my @BLUE_ROUTES = (
  ['10.200.0.0', 24, '10.200.0.1', 1000014], ['10.200.0.1', 32, '10.200.0.1', 1000014],
  ['10.202.0.0', 24, '10.202.0.1', 1000018],
  ['2001:db8:0:0:0:0:0:0', 64, '2001:db8:0:0:0:0:0:1', 1000013],
  ['2001:db8:2:0:0:0:0:0', 64, '2001:db8:2:0:0:0:0:1', 1000017],
);

sub _red_cache {
  return _exos_vrf_cache(
    _exos_address_store(), _exos_route_store(@RED_ROUTES),
    _exos_neighbor_store(
      [1000012, '10.200.0.2', 1], [1000016, '10.201.0.2', 3],
      [1000011, '2001:db8:0:0:0:0:0:2', 1], [1000011, 'fe80:0:0:0:0:0:0:2', 1],
      [1000011, 'fe80:0:0:0:0:ff:fe00:201', 1],
      [1000015, '2001:db8:1:0:0:0:0:2', 3], [1000015, 'fe80:0:0:0:0:0:0:2', 3],
      [1000015, 'fe80:0:0:0:0:ff:fe00:203', 3],
    ),
  );
}

sub _blue_cache {
  return _exos_vrf_cache(_exos_address_store(),
    _exos_route_store(@BLUE_ROUTES));
}

sub _enter_vr {
  my ($info, $context) = @_;
  $info->session()->{Version} = 3;
  $info->session()->{Context} = $context;
  return;
}

sub _use_cache {
  my ($test, $cache) = @_;
  $test->{info}->clear_cache();
  $test->{info}->cache($cache);
  return $test->{info};
}

sub context_kinds__vrf__xos_only : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  cmp_deeply($info->context_kinds('vrf'), ['vrf'], 'EXOS: one context per VR');
  is($info->context_kinds('stp'), undef, 'EXOS: no other feature has one');
  $info->{_description} = '5520-48SE-FabricEngine (8.10.1.0)';
  is($info->context_kinds('vrf'), undef, 'VOSS: none');
  $info->{_description} = 'Summit48si - Version 7.8.4b4';
  is($info->context_kinds('vrf'), undef, 'ExtremeWare: none');
}

sub snmp_context__vrf__v3_only : Tests(5) {
  my $test = shift;
  my $info = $test->{info};

  cmp_deeply($info->snmp_context('vrf', 'red'),
    {kind => 'vrf', id => 'red', v2c => undef, v3 => 'red'},
    'A VR is an SNMPv3 context of its name, with no v2c form');
  is($info->snmp_context('vrf', 'default'), undef, 'default has none');
  is($info->snmp_context('vrf', q()), undef, 'An empty name has none');
  is($info->snmp_context('vlan', 10), undef, 'Another kind has none');
  $info->{_description} = '5520-48SE-FabricEngine (8.10.1.0)';
  is($info->snmp_context('vrf', 'red'), undef, 'VOSS: none');
}

sub vrf_instances__caller_names__listed_by_caller : Tests(7) {
  my $test = shift;

  $test->_prime_vrf_none_counted();
  my $instances = $test->{info}->vrf_instances([qw/red blue green grey/]);
  cmp_deeply([sort keys %$instances], [qw/blue default green grey red/],
    'The caller names and default');
  is($instances->{red}{listed_by}, 'caller', 'Listed by the caller');
  cmp_deeply($instances->{red}{contexts},
    [{kind => 'vrf', id => 'red', v2c => undef, v3 => 'red'}],
    'Each in the SNMPv3 context of its name');
  is($instances->{grey}{contexts}[0]{v3}, 'grey', 'grey too');
  is($test->{info}->vrf_instances_complete([qw/red blue green grey/]), 0,
    'A caller list is never complete');
  is($instances->{default}{listed_by}, 'device', 'default is the device\'s');
  is($test->{info}->vrf_instances_complete(), undef,
    'Without names the list stays unknown');
}

sub i_vrf__red_context__route_ports : Tests(3) {
  my $test = shift;
  my $info = _use_cache($test, _red_cache());

  _enter_vr($info, 'red');
  cmp_deeply(scalar $info->i_vrf(),
    {1000011 => 'red', 1000012 => 'red', 1000015 => 'red', 1000016 => 'red'},
    'The interfaces red\'s routes use, IPv6 and IPv4 ports both');
  is($info->error(), undef, 'No error');
  ok(!exists $info->{_vrf_instances}, 'No list is read in the context');
}

sub i_vrf__unknown_vr_context__no_ports : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _exos_vrf_cache(
    _exos_address_store(), _exos_route_store()));

  _enter_vr($info, 'purple');
  cmp_deeply(scalar $info->i_vrf(), {}, 'A VR the device lacks holds no port');
}

sub vrf_addresses__blue_context__not_reds : Tests(3) {
  my $test = shift;
  my $info = _use_cache($test, _blue_cache());

  _enter_vr($info, 'blue');
  my $rows = $info->vrf_addresses('blue');
  cmp_deeply([sort map { "$_->{ifindex} $_->{ip}" } values %$rows],
    ['1000017 10.202.0.1', '1000017 2001:0db8:0002:0000:0000:0000:0000:0001'],
    'Only the addresses on blue\'s route ports');
  ok(!(grep { $_->{ip} eq '10.200.0.1' } values %$rows),
    'Not red\'s 10.200.0.1');
  is(scalar(grep { $_->{ifindex} == 1000005 } values %$rows), 0,
    'Not the management port');
}

sub vrf_addresses__unknown_vr__empty : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _exos_vrf_cache(
    _exos_address_store(), _exos_route_store()));

  _enter_vr($info, 'purple');
  cmp_deeply($info->vrf_addresses('purple'), {}, 'No route, no address');
}

sub vrf_neighbors__red_context__both_families : Tests(3) {
  my $test = shift;
  my $info = _use_cache($test, _red_cache());

  _enter_vr($info, 'red');
  my @rows = values %{$info->vrf_neighbors('red')};
  my @vlan_one = map { "1000011 $_" }
    '2001:0db8:0000:0000:0000:0000:0000:0002',
    'fe80:0000:0000:0000:0000:0000:0000:0002',
    'fe80:0000:0000:0000:0000:00ff:fe00:0201';
  my @vlan_two = map { "1000015 $_" }
    '2001:0db8:0001:0000:0000:0000:0000:0002',
    'fe80:0000:0000:0000:0000:0000:0000:0002',
    'fe80:0000:0000:0000:0000:00ff:fe00:0203';
  cmp_deeply([sort map { "$_->{ifindex} $_->{ip}" } @rows],
    [sort '1000012 10.200.0.2', '1000016 10.201.0.2', @vlan_one, @vlan_two],
    'IPv4 on the router interfaces, IPv6 on the VLAN ones, as the CLI lists');
  is(scalar @rows, 8, 'Eight rows');
  is(scalar(grep { $_->{ip} eq '10.200.0.1' } @rows), 0,
    'None of the router\'s own addresses');
}

sub vrf_neighbors__unknown_vr__empty : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _exos_vrf_cache(
    _exos_address_store(), _exos_route_store(),
    _exos_neighbor_store([1000012, '10.200.0.2', 1])));

  _enter_vr($info, 'purple');
  cmp_deeply($info->vrf_neighbors('purple'), {}, 'A VR with no route');
}

sub vrf_subnets__blue_context__overlap_from_route : Tests(4) {
  my $test = shift;
  my $info = _use_cache($test, _blue_cache());

  _enter_vr($info, 'blue');
  my $subnets = $info->vrf_subnets('blue');
  cmp_deeply($subnets->{'10.200.0.0/24'},
    superhashof({ifindex => 1000014, sources => ['route']}),
    'blue\'s 10.200.0.0/24 is read from its connected route');
  cmp_deeply($subnets->{'10.202.0.0/24'}{sources}, ['address', 'route'],
    'A subnet in both the address table and the routes lists both');
  ok(!exists $subnets->{'10.201.0.0/24'}, 'red\'s subnet is not blue\'s');
  ok(!exists $subnets->{'10.200.0.1/32'}, 'A host route is not a subnet');
}

sub vrf_subnets__voss__no_context_mode : Tests(2) {
  my $test = shift;
  my $info = $test->{info};

  $info->{_description} = '5520-48SE-FabricEngine (8.10.1.0)';
  is($info->_vrf_context_filters(), 0, 'VOSS: no context filtering');
  is($info->_vrf_context_ports_from_routes(), 0, 'VOSS: no route ports');
}

1;
