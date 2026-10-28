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
# (the router interface) from its IPv6 address and neighbors. Each router
# interface is named for its VLAN and is at the chassis MAC; a VLAN
# interface has no MAC. IPv6 interface addresses are typed anycast(2).
my $PFX = '.1.3.6.1.2.1.4.32.1.5';
my $EXOS_MAC = pack('C6', 0x02, 0x00, 0x00, 0x00, 0x00, 0x0a);
my $EXOS_LINK_LOCAL = 'fe80:0:0:0:0:ff:fe00:a';
my @EXOS_ADDRESSES = (
  [1000005, '10.0.0.15',    24],  [1000011, '10.200.0.1', 24],
  [1000015, '10.201.0.1',   24],  [1000017, '10.202.0.1', 24],
  [1000020, '10.204.0.1',   32],  [1000022, '203.0.113.21', 32],
  [1000011, '2001:db8:0:0:0:0:0:1', 64],
  [1000015, '2001:db8:1:0:0:0:0:1', 64],
  [1000017, '2001:db8:2:0:0:0:0:1', 64],
  [1000019, '2001:db8:3:0:0:0:0:1', 64],
  [1000020, '2001:db8:4:0:0:0:0:1', 128],
  [1000011, $EXOS_LINK_LOCAL, 64],
);

# ifName; a router interface is "<vlan> rtif(<address>)"
my %EXOS_IF_NAMES = (
  1000005 => 'Mgmt',  1000006 => 'Mgmt rtif(10.0.0.15/24)',
  1000011 => 'red1',  1000012 => 'red1 rtif(10.200.0.1/24)',
  1000013 => 'blue1', 1000014 => 'blue1 rtif(10.200.0.1/24)',
  1000015 => 'red2',  1000016 => 'red2 rtif(10.201.0.1/24)',
  1000017 => 'blue2', 1000018 => 'blue2 rtif(10.202.0.1/24)',
  1000019 => 'green1',
  1000020 => 'greylo', 1000021 => 'greylo rtif(10.204.0.1/32)',
  1000022 => 'Lo',    1000023 => 'Lo rtif(203.0.113.21/32)',
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
    $type{$iid}   = $ip =~ /:/ ? 'anycast' : 'unicast';
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

# ifName and ifPhysAddress are the same in every context
sub _exos_vrf_cache {
  my %store = (
    i_name => {%EXOS_IF_NAMES},
    i_mac  => {map { $_ => ($EXOS_IF_NAMES{$_} =~ /rtif/ ? $EXOS_MAC : q()) }
        keys %EXOS_IF_NAMES},
    @_,
  );
  my $cache = {
    '_layers'      => 78,
    '_description' =>
      'ExtremeXOS (Stack) version 33.6.1.7 by release-manager',
    '_id'          => '.1.3.6.1.4.1.1916.2.65',
    'store'        => \%store,
  };
  $cache->{"_$_"} = 1 for keys %store;
  return $cache;
}

my @RED_ROUTES = (
  ['10.200.0.0', 24, '10.200.0.1', 1000012],
  ['10.200.0.1', 32, '10.200.0.1', 1000012],
  ['10.201.0.0', 24, '10.201.0.1', 1000016],
  ['10.201.0.1', 32, '10.201.0.1', 1000016],
  ['2001:db8:0:0:0:0:0:0', 64,  '2001:db8:0:0:0:0:0:1', 1000011],
  ['2001:db8:0:0:0:0:0:1', 128, '2001:db8:0:0:0:0:0:1', 1000011],
  ['2001:db8:1:0:0:0:0:0', 64,  '2001:db8:1:0:0:0:0:1', 1000015],
  ['2001:db8:1:0:0:0:0:1', 128, '2001:db8:1:0:0:0:0:1', 1000015],
  ['fe80:0:0:0:0:0:0:0',   64,  $EXOS_LINK_LOCAL,       1000011],
);

my @BLUE_ROUTES = (
  ['10.200.0.0', 24, '10.200.0.1', 1000014],
  ['10.200.0.1', 32, '10.200.0.1', 1000014],
  ['10.202.0.0', 24, '10.202.0.1', 1000018],
  ['10.202.0.1', 32, '10.202.0.1', 1000018],
  ['2001:db8:0:0:0:0:0:0', 64,  '2001:db8:0:0:0:0:0:1', 1000013],
  ['2001:db8:0:0:0:0:0:1', 128, '2001:db8:0:0:0:0:0:1', 1000013],
  ['2001:db8:2:0:0:0:0:0', 64,  '2001:db8:2:0:0:0:0:1', 1000017],
  ['2001:db8:2:0:0:0:0:1', 128, '2001:db8:2:0:0:0:0:1', 1000017],
  ['fe80:0:0:0:0:0:0:0',   64,  $EXOS_LINK_LOCAL,       1000013],
);

my @GREY_ROUTES = (
  ['10.204.0.1',           32,  '10.204.0.1',           1000021],
  ['2001:db8:4:0:0:0:0:1', 128, '2001:db8:4:0:0:0:0:1', 1000020],
  ['fe80:0:0:0:0:0:0:0',   64,  $EXOS_LINK_LOCAL,       1000020],
);

my @DEFAULT_ROUTES = (['203.0.113.21', 32, '203.0.113.21', 1000023]);

# The default and grey contexts also serve red's IPv6 neighbor on red's
# port
my @LEAKED_RED_NEIGHBOR = ([1000011, '2001:db8:0:0:0:0:0:2', 1]);

sub _red_cache {
  return _exos_vrf_cache(
    _exos_address_store(), _exos_route_store(@RED_ROUTES),
    _exos_neighbor_store(
      [1000012, '10.200.0.2', 1], [1000016, '10.201.0.2', 3],
      [1000011, '2001:db8:0:0:0:0:0:2', 1],
      [1000011, 'fe80:0:0:0:0:0:0:2', 1],
      [1000011, 'fe80:0:0:0:0:ff:fe00:201', 1],
      [1000015, '2001:db8:1:0:0:0:0:2', 3],
      [1000015, 'fe80:0:0:0:0:0:0:2', 3],
      [1000015, 'fe80:0:0:0:0:ff:fe00:203', 3],
    ),
  );
}

sub _blue_cache {
  return _exos_vrf_cache(_exos_address_store(),
    _exos_route_store(@BLUE_ROUTES));
}

sub _grey_cache {
  return _exos_vrf_cache(_exos_address_store(),
    _exos_route_store(@GREY_ROUTES),
    _exos_neighbor_store(@LEAKED_RED_NEIGHBOR));
}

sub _default_cache {
  return _exos_vrf_cache(_exos_address_store(),
    _exos_route_store(@DEFAULT_ROUTES),
    _exos_neighbor_store(@LEAKED_RED_NEIGHBOR));
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

sub context_kinds__vrf__xos_not_extremeware : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  cmp_deeply($info->context_kinds('vrf'), ['vrf'],
    'EXOS: one context per VR');
  is($info->context_kinds('stp'), undef, 'EXOS: no other feature has one');
  $info->{_description} = 'Summit48si - Version 7.8.4b4';
  is($info->context_kinds('vrf'), undef, 'ExtremeWare: none');
}

sub snmp_context__vrf__exos__v3_only : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  cmp_deeply($info->snmp_context('vrf', 'red'),
    {kind => 'vrf', id => 'red', v2c => undef, v3 => 'red'},
    'A VR is an SNMPv3 context of its name, with no v2c form');
  is($info->snmp_context('vrf', 'default'), undef, 'default has none');
  is($info->snmp_context('vrf', q()), undef, 'An empty name has none');
  is($info->snmp_context('vlan', 10), undef, 'Another kind has none');
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
  cmp_deeply(scalar $info->i_vrf(), {},
    'A VR the device lacks holds no port');
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

sub _v6 {
  return join ':', unpack '(H4)*', pack 'C*', (_arcs(shift))[2 .. 17];
}

sub _address_list {
  my $rows = shift;
  return [sort map { "$_->{ifindex} $_->{ip}" } values %$rows];
}

sub i_vrf__default_context__router_interface_and_its_vlan : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _default_cache());

  cmp_deeply(scalar $info->i_vrf(),
    {1000022 => 'default', 1000023 => 'default'},
    'The route\'s router interface and the VLAN interface named for it');
  is($info->{_vrf_walked}{default}{i_name}, 1,
    'The ifName walk counts toward the read');
}

sub vrf_addresses__default_context__address_on_vlan_interface : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _default_cache());

  cmp_deeply(_address_list($info->vrf_addresses('default')),
    ['1000022 203.0.113.21'],
    'The address on the VLAN interface whose router interface has the route');
}

sub vrf_neighbors__default_context__reds_row_dropped : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _default_cache());

  cmp_deeply($info->vrf_neighbors('default'), {},
    'red\'s neighbor the default context serves on red\'s port is dropped');
}

sub vrf_neighbors__grey_context__reds_row_dropped : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _grey_cache());

  _enter_vr($info, 'grey');
  cmp_deeply($info->vrf_neighbors('grey'), {},
    'red\'s neighbor the grey context serves on red\'s port is dropped');
}

sub vrf_addresses__red_context__ipv4_only_vlan_kept : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _exos_vrf_cache(_exos_address_store(),
    _exos_route_store(grep { $_->[3] != 1000015 } @RED_ROUTES)));

  _enter_vr($info, 'red');
  is($info->i_vrf()->{1000015}, 'red',
    'A VLAN with only IPv4 routes is a member through its router interface');
  ok(exists $info->vrf_addresses('red')->{'1000015.10.201.0.1'},
    '... and its IPv4 address is red\'s');
}

sub vrf_addresses__red_context__ipv6_anycast_listed : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _red_cache());

  _enter_vr($info, 'red');
  cmp_deeply(_address_list($info->vrf_addresses('red')),
    [sort '1000011 10.200.0.1', '1000015 10.201.0.1',
      '1000011 ' . _v6('2001:db8:0:0:0:0:0:1'),
      '1000015 ' . _v6('2001:db8:1:0:0:0:0:1'),
      '1000011 ' . _v6($EXOS_LINK_LOCAL)],
    'IPv4 addresses and the IPv6 ones EXOS types anycast(2)');
}

sub vrf_addresses__grey_context__host_addresses : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _grey_cache());

  _enter_vr($info, 'grey');
  cmp_deeply(_address_list($info->vrf_addresses('grey')),
    ['1000020 10.204.0.1', '1000020 ' . _v6('2001:db8:4:0:0:0:0:1')],
    'grey\'s IPv4 and IPv6 host addresses, on the VLAN interface');
}

# Rows EXOS does not serve, to show which rule drops what: one at the
# chassis MAC on a router interface, and the device link-local, which is
# its own only on the port that holds it
sub vrf_neighbors__red_context__own_rows_dropped : Tests(3) {
  my $test  = shift;
  my $cache = _red_cache();
  my $macs  = $cache->{store}{ip_n2p_phys_addr};
  my $local = join '.', _arcs($EXOS_LINK_LOCAL);
  $macs->{'1000012.1.4.10.200.0.9'} = $EXOS_MAC;
  $macs->{"1000011.$local"} = pack('C6', 2, 0, 0, 0, 2, 9);
  $macs->{"1000015.$local"} = pack('C6', 2, 0, 0, 0, 2, 9);
  my $info = _use_cache($test, $cache);

  _enter_vr($info, 'red');
  my $rows = _address_list($info->vrf_neighbors('red'));
  ok(!(grep { $_ eq '1000012 10.200.0.9' } @$rows),
    'A row at the router interface\'s MAC is the device\'s own');
  ok(!(grep { $_ eq '1000011 ' . _v6($EXOS_LINK_LOCAL) } @$rows),
    'The link-local on the port holding it is the device\'s own');
  ok((grep { $_ eq '1000015 ' . _v6($EXOS_LINK_LOCAL) } @$rows),
    '... on another port it is a neighbor');
}


# VOSS (Fabric Engine 9.4) with VRFs red (vrfid 1), blue (2), green (3,
# IPv6 only), grey (4, a loopback only) and MgmtRouter (512); vrfid 0 is
# GlobalRouter. Each VRF is reached by its rcVrfContextName. A VRF context
# serves only its own rcVrfConfigTable row, its own VLANs and its own
# rcIpAddrTable rows; rcVrfIpVpnTable is whole in every context. The
# default context serves every VLAN, and rcIpAddrTable only for vrfid 0.
my %VOSS_VRF_NAMES = (0 => 'GlobalRouter', 1 => 'red', 2 => 'blue',
  3 => 'green', 4 => 'grey', 512 => 'MgmtRouter');
my %VOSS_CONTEXTS = (0 => q(), 1 => 'vrf1', 2 => 'vrf2', 3 => 'vrf3',
  4 => 'vrf4', 512 => 'vrf512');
my %VOSS_ISIDS = (1 => 30001, 2 => 30002, 3 => 30003, 4 => 30004);

# rcVlanTable: VLAN => [rcVlanIfIndex, rcVlanVrfId]. 4051 is the fabric
# VLAN whose ifIndex carries the routes learned over the fabric.
my %VOSS_VLANS = (1 => [2049, 0], 10 => [2058, 0], 41 => [2089, 1],
  42 => [2090, 2], 43 => [2091, 1], 44 => [2092, 2], 45 => [2093, 3],
  4048 => [6096, 0], 4051 => [6099, 0], 4052 => [6100, 0]);

# rcIpAddrTable rows [ifIndex, address, mask] per rcIpAdEntVrfId; each
# context serves the rows of its own vrfid
my %VOSS_IP_ROWS = (
  0 => [[1344, '10.255.0.13', '255.255.255.255']],
  1 => [[2089, '10.100.1.1', '255.255.255.0'],
    [2091, '10.101.1.1', '255.255.255.0']],
  2 => [[2090, '10.100.1.1', '255.255.255.0'],
    [2092, '10.102.1.1', '255.255.255.0']],
  4 => [[1345, '10.104.1.1', '255.255.255.255']],
);

# rcIpAdEntVrfId, rcIpAdEntAddr and rcIpAdEntNetMask of the rows of
# @vrfids, indexed ifIndex then address
sub _voss_ip_store {
  my (%vrf, %addr, %mask);
  foreach my $vrfid (@_) {
    foreach my $row (@{$VOSS_IP_ROWS{$vrfid} || []}) {
      my ($port, $ip, $netmask) = @$row;
      $vrf{"$port.$ip"}  = $vrfid;
      $addr{"$port.$ip"} = $ip;
      $mask{"$port.$ip"} = $netmask;
    }
  }
  return (vrf_rc_ip_vrf => \%vrf, vrf_rc_ip_addr => \%addr,
    vrf_rc_ip_mask => \%mask);
}

# ifPhysAddress, the same in every context: each VLAN interface's MAC
# octet, 9 for the fabric VLAN's
my %VOSS_PORT_MAC = (2089 => 1, 2090 => 2, 2091 => 3, 2092 => 4,
  2093 => 5, 6099 => 9);

# inetCidrRouteTable rows as VOSS indexes them, with no length octet before
# either address: [prefix, length, next hop, ifIndex, proto]
sub _voss_route_store {
  my (%if, %proto);
  foreach my $row (@_) {
    my ($prefix, $length, $hop, $port, $proto) = @$row;
    my ($dest_type, undef, @dest) = _arcs($prefix);
    my ($hop_type,  undef, @hop)  = _arcs($hop);
    my $iid = join '.', $dest_type, @dest, $length, 0, $hop_type, @hop;
    $if{$iid}    = $port;
    $proto{$iid} = $proto // 'local';
  }
  return (vrf_cidr_if => \%if, vrf_cidr_proto => \%proto);
}

# ipNetToMediaTable rows [ifIndex, address, MAC] and IPV6-MIB
# ipv6NetToMediaTable rows [ifIndex, IPv6 address, MAC]; a MAC is its last
# octet, or the six octets
sub _voss_mac {
  my $mac = shift;
  return ref $mac ? pack('C6', @$mac) : pack('C6', 2, 0, 0, 0, 0, $mac);
}

sub _voss_neighbor_store {
  my %tables = @_;
  my (%paddr, %netaddr, %nd);
  foreach my $row (@{$tables{arp} || []}) {
    my ($port, $ip, $mac) = @$row;
    $paddr{"$port.$ip"}   = _voss_mac($mac);
    $netaddr{"$port.$ip"} = $ip;
  }
  foreach my $row (@{$tables{nd} || []}) {
    my ($port, $ip, $mac) = @$row;
    my (undef, undef, @octets) = _arcs($ip);
    $nd{join '.', $port, @octets} = _voss_mac($mac);
  }
  return (at_paddr => \%paddr, at_netaddr => \%netaddr,
    i6_n2p_phys_addr => \%nd);
}

# IPV6-MIB ipv6AddrTable ipv6AddrPfxLength rows [ifIndex, address, length]
sub _voss_v6_address_store {
  my %length;
  foreach my $row (@_) {
    my ($port, $ip, $prefix_length) = @$row;
    my (undef, undef, @octets) = _arcs($ip);
    $length{join '.', $port, @octets} = $prefix_length;
  }
  return (i6_addr_pfxlen => \%length);
}

sub _voss_port_macs {
  return (i_mac => {map { $_ => _voss_mac($VOSS_PORT_MAC{$_}) }
      keys %VOSS_PORT_MAC});
}

# The context of the VRFs @$vrfids, the default context when they include
# 0: their rcVrfConfigTable rows, VLANs and rcIpAddrTable rows, then the
# rest of the store
sub _voss_cache {
  my ($vrfids, %rest) = @_;
  my %in_context = map { $_ => 1 } @$vrfids;
  my @vlans = grep { $in_context{$VOSS_VLANS{$_}[1]} } keys %VOSS_VLANS;
  my @ip_rows = $in_context{0} ? (0) : @$vrfids;
  my %store = (
    vrf_rc_name    => {map { $_ => $VOSS_VRF_NAMES{$_} } @$vrfids},
    vrf_rc_context => {map { $_ => $VOSS_CONTEXTS{$_} } @$vrfids},
    vrf_rc_isid    => {%VOSS_ISIDS},
    vrf_rc_vlan_if  => {map { $_ => $VOSS_VLANS{$_}[0] } @vlans},
    vrf_rc_vlan_vrf => {map { $_ => $VOSS_VLANS{$_}[1] } @vlans},
    _voss_ip_store(@ip_rows),
    %rest,
  );
  my $cache = {
    '_layers'      => 6,
    '_description' => '5520-24T-FabricEngine (9.4.0.0)',
    '_id'          => '.1.3.6.1.4.1.1916.2.437',
    'store'        => \%store,
  };
  $cache->{"_$_"} = 1 for keys %store;
  return $cache;
}

# GlobalRouter's routes: its CLIP on 1344, the management CLIP's host
# route on the management VLAN's interface 6138, and those learned over
# the fabric
sub _voss_default_cache {
  return _voss_cache([keys %VOSS_VRF_NAMES],
    _voss_route_store(
      ['10.20.0.0',   24, '127.1.0.10',  6099, 'isIs'],
      ['10.30.0.0',   24, '127.1.0.9',   6099, 'isIs'],
      ['10.254.0.13', 32, '10.254.0.13', 6138],
      ['10.254.0.14', 32, '127.1.0.10',  6099, 'isIs'],
      ['10.254.0.15', 32, '127.1.0.9',   6099, 'isIs'],
      ['10.255.0.13', 32, '10.255.0.13', 1344],
      ['10.255.0.14', 32, '127.1.0.10',  6099, 'isIs'],
      ['10.255.0.15', 32, '127.1.0.9',   6099, 'isIs'],
      ['2001:db8:1255:0:0:0:0:13', 128, '0:0:0:0:0:0:0:0', 1344],
      ['2001:db8:1255:0:0:0:0:15', 128, '0:0:0:0:0:0:0:0', 6099, 'esIs'],
    ));
}

# red's connected routes on its VLANs, and one learned over the fabric
my @VOSS_RED_ROUTES = (
  ['10.100.1.0', 24, '10.100.1.1', 2089],
  ['10.100.3.0', 24, '127.1.0.9',  6099, 'isIs'],
  ['10.101.1.0', 24, '10.101.1.1', 2091],
);

# A VLAN's own address and the broadcast address are served at the VLAN
# interface's MAC and the broadcast MAC; link-locals are the interface's
my $VOSS_BROADCAST = [(0xff) x 6];
my $VOSS_RED_LINK_LOCAL = 'fe80:0:0:0:0:ff:fe00:1';

sub _voss_red_cache {
  return _voss_cache([1], _voss_route_store(@VOSS_RED_ROUTES),
    _voss_port_macs(),
    _voss_neighbor_store(
      arp => [[2089, '10.100.1.1', 1], [2089, '10.100.1.10', 0x0a],
        [2089, '10.100.1.255', $VOSS_BROADCAST],
        [2091, '10.101.1.1', 3], [2091, '10.101.1.10', 0x0c],
        [2091, '10.101.1.255', $VOSS_BROADCAST]],
      nd => [[2089, '2001:db8:1001:0:0:0:0:1', 1],
        [2089, '2001:db8:1001:0:0:0:0:16', 0x0a],
        [2089, $VOSS_RED_LINK_LOCAL, 1]],
    ),
    _voss_v6_address_store([2089, '2001:db8:1001:0:0:0:0:1', 64],
      [2089, $VOSS_RED_LINK_LOCAL, 64]),
  );
}

# blue holds red's 10.100.1.0/24 too, on its own VLAN
sub _voss_blue_cache {
  return _voss_cache([2],
    _voss_route_store(['10.100.1.0', 24, '10.100.1.1', 2090],
      ['10.100.3.0', 24, '127.1.0.9',  6099, 'isIs'],
      ['10.102.1.0', 24, '10.102.1.1', 2092]),
    _voss_port_macs(),
    _voss_neighbor_store(
      arp => [[2090, '10.100.1.1', 2], [2090, '10.100.1.10', 0x0b],
        [2090, '10.100.1.255', $VOSS_BROADCAST],
        [2092, '10.102.1.1', 4], [2092, '10.102.1.10', 0x0d],
        [2092, '10.102.1.255', $VOSS_BROADCAST]],
    ),
  );
}

# grey's loopback has no VLAN; the loopback's own ARP row is served at the
# loopback's MAC, 00:00:00:00:00:02
sub _voss_grey_cache {
  return _voss_cache([4],
    _voss_route_store(['10.104.1.1', 32, '10.104.1.1', 1345],
      ['10.104.3.1', 32, '127.1.0.9', 6099, 'isIs']),
    _voss_port_macs(),
    _voss_neighbor_store(arp => [[1345, '10.104.1.1', [0, 0, 0, 0, 0, 2]]]),
  );
}

# green is IPv6 only and has no inetCidrRouteTable row
sub _voss_green_cache {
  my $link_local = 'fe80:0:0:0:0:ff:fe00:5';
  return _voss_cache([3], _voss_port_macs(),
    _voss_neighbor_store(
      nd => [[2093, '2001:db8:1201:0:0:0:0:1', 5],
        [2093, '2001:db8:1201:0:0:0:0:16', 0x0e],
        [2093, $link_local, 5]],
    ),
    _voss_v6_address_store([2093, '2001:db8:1201:0:0:0:0:1', 64],
      [2093, $link_local, 64]),
  );
}

sub context_kinds__vrf__voss : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  cmp_deeply(scalar $info->context_kinds('vrf'), ['vrf'],
    'One context per VRF');
  is($info->context_kinds('stp'), undef, 'No other feature has one');
}

sub snmp_context__voss_red__v2c_colon_vrfid : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  cmp_deeply(scalar $info->snmp_context('vrf', 'red'),
    {kind => 'vrf', id => 'red', v2c => '%s::1', v3 => 'vrf1'},
    'The v2c form is community::vrfid; v3 is rcVrfContextName');
  is(sprintf($info->snmp_context('vrf', 'red')->{v2c}, 'public'),
    'public::1', 'The form fills in the community');
}

sub snmp_context__voss_mgmt__v2c_colon_512 : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  my $context = $info->snmp_context('vrf', 'MgmtRouter') || {};
  is($context->{v2c}, '%s::512', 'MgmtRouter is vrfid 512');
  is($context->{v3}, 'vrf512', 'Its SNMPv3 context is vrf512');
}

sub snmp_context__voss_default__nothing : Tests(4) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  is($info->snmp_context('vrf', 'default'), undef, 'default has none');
  is($info->snmp_context('vrf', 'GlobalRouter'), undef,
    'Nor GlobalRouter, which is default');
  is($info->snmp_context('vrf', 'purple'), undef, 'Nor an unlisted name');
  is($info->snmp_context('vlan', 41), undef, 'Another kind has none');
}

sub snmp_context__xos__unchanged : Tests(1) {
  my $test = shift;
  my $info = $test->{info};

  cmp_deeply($info->snmp_context('vrf', 'red'),
    {kind => 'vrf', id => 'red', v2c => undef, v3 => 'red'},
    'ExtremeXOS stays SNMPv3 only');
}

sub vrf_instances__voss : Tests(7) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  my $instances = $info->vrf_instances();
  cmp_deeply([sort keys %$instances],
    [qw/MgmtRouter blue default green grey red/],
    'Every rcVrfConfigTable row, with GlobalRouter as default');
  cmp_deeply($instances->{red}, superhashof({
      kind      => 'vrf',
      l3_isid   => 30001,
      listed_by => 'device',
      sources   => {list => 'RAPID-CITY', l3_isid => 'RAPID-CITY',
        members => 'RAPID-CITY'},
      contexts  => [{kind => 'vrf', id => 'red', v2c => '%s::1',
        v3 => 'vrf1'}],
    }), 'red, its I-SID and its context');
  cmp_deeply([map { $instances->{$_}{l3_isid} } qw/blue green grey/],
    [30002, 30003, 30004], q(blue, green and grey I-SIDs));
  cmp_deeply($instances->{grey}{sources},
    {list => q(RAPID-CITY), l3_isid => q(RAPID-CITY)},
    q(grey: an I-SID and no VLAN));
  cmp_deeply($instances->{MgmtRouter}, superhashof({kind => 'vrf',
      l3_isid => undef, sources => {list => 'RAPID-CITY'}}),
    'MgmtRouter is listed as a VRF');
  is($instances->{default}{kind}, 'default', 'default is the global table');
  ok(!exists $instances->{GlobalRouter}, 'No GlobalRouter row');
}

sub vrf_instances_complete__voss__is_1 : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  is($info->vrf_instances_complete(), 1, 'A whole list is complete');
}

sub vrf_instances_complete__voss_partial_walk__is_0 : Tests(2) {
  my $test = shift;

  foreach my $method (qw/vrf_rc_name vrf_rc_vlan_vrf/) {
    my $info = _use_cache($test, _voss_default_cache());
    $info->{walk_status}{$method} = {complete => 0, reason => 'timeout'};
    is($info->vrf_instances_complete(), 0, "A partial $method walk is not");
  }
}

sub i_vrf__voss_default_context : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  cmp_deeply(scalar $info->i_vrf(),
    {2089 => 'red', 2090 => 'blue', 2091 => 'red', 2092 => 'blue',
      2093 => 'green'},
    'Every VRF VLAN; GlobalRouter VLANs and the CLIP are default');
  is($info->error(), undef, 'No error');
}

sub i_vrf__voss_red_context : Tests(3) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_vr($info, 'vrf1');
  cmp_deeply(scalar $info->i_vrf(), {2089 => 'red', 2091 => 'red'},
    'red\'s VLANs; the fabric interface of a learned route is not red\'s');
  is($info->error(), undef, 'No error');
  is($info->{_vrf_walked}{red}{vrf_cidr_proto}, 1,
    'The route protocol walk counts toward the read');
}

sub i_vrf__voss_grey_context__loopback : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_grey_cache());

  _enter_vr($info, 'vrf4');
  cmp_deeply(scalar $info->i_vrf(), {1345 => 'grey'},
    'grey\'s loopback, which has no VLAN');

  my $cache = _voss_grey_cache();
  $cache->{store}{vrf_rc_ip_vrf} = {};
  $info = _use_cache($test, $cache);
  _enter_vr($info, 'vrf4');
  cmp_deeply(scalar $info->i_vrf(), {1345 => 'grey'},
    '... a member by its connected route alone');
}

sub i_vrf__voss_green_context__vlan_only : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _voss_green_cache());

  _enter_vr($info, 'vrf3');
  cmp_deeply(scalar $info->i_vrf(), {2093 => 'green'},
    'green\'s VLAN, with no IPv4 route');
}

sub vrf_context_hooks__xos_and_extremeware__unchanged : Tests(4) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  $info->{_description} = 'Summit48si - Version 7.8.4b4';
  is($info->_vrf_context_filters(), 0, 'ExtremeWare: no context mode');
  cmp_deeply($info->_vrf_vendor_instances(), {}, 'ExtremeWare: no list');
  $info->{_description}
    = 'ExtremeXOS (Stack) version 33.6.1.7 by release-manager';
  cmp_deeply($info->_vrf_vendor_instances(), {}, 'EXOS: no list');
  cmp_deeply($info->_vrf_vendor_membership(), {}, 'EXOS: no membership');
}


sub vrf_neighbors__voss_red_context : Tests(3) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_vr($info, 'vrf1');
  my $rows = $info->vrf_neighbors('red');
  cmp_deeply(_address_list($rows),
    [sort '2089 10.100.1.10', '2091 10.101.1.10',
      '2089 ' . _v6('2001:db8:1001:0:0:0:0:16')],
    'The hosts only: not the own rows, nor the broadcast ones');
  cmp_deeply($rows->{'2089.10.100.1.10'},
    {ifindex => 2089, ip => '10.100.1.10', mac => '02:00:00:00:00:0a',
      family => 'ipv4'}, 'A host row');
  is(scalar(grep { $_->{family} eq 'ipv6' } values %$rows), 1,
    'The IPv6 host, from IPV6-MIB');
}

# A VRF context that serves no rcVrfConfigTable row for its own VRF:
# the reader cannot confirm the context, and says how to check
sub vrf_neighbors__voss_context_without_own_row__error : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_cache([]));

  _enter_vr($info, 'vrf512');
  is($info->vrf_neighbors('MgmtRouter'), undef, 'No rows');
  like($info->error(),
    qr/cannot confirm that context 'vrf512' belongs to instance 'MgmtRouter'/,
    'The error names the unconfirmed context');
}

sub vrf_addresses__voss_red_context : Tests(3) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_vr($info, 'vrf1');
  my $rows = $info->vrf_addresses('red');
  cmp_deeply(_address_list($rows),
    [sort '2089 10.100.1.1', '2091 10.101.1.1',
      '2089 ' . _v6('2001:db8:1001:0:0:0:0:1'),
      '2089 ' . _v6($VOSS_RED_LINK_LOCAL)],
    'IPv4 from rcIpAddrTable, IPv6 from ipv6AddrTable');
  cmp_deeply($rows->{'2089.10.100.1.1'},
    {ifindex => 2089, ip => '10.100.1.1', prefix_len => 24,
      family => 'ipv4'}, 'The prefix length of rcIpAdEntNetMask');
  is($rows->{'2089.' . _v6('2001:db8:1001:0:0:0:0:1')}{prefix_len}, 64,
    'The IPv6 prefix length');
}

sub vrf_addresses__voss_red_context_no_routes__from_rc_ip_addr_table
  : Tests(2) {
  my $test  = shift;
  my $cache = _voss_red_cache();
  delete @{$cache->{store}}{qw/vrf_cidr_if vrf_cidr_proto/};
  my $info = _use_cache($test, $cache);

  _enter_vr($info, 'vrf1');
  cmp_deeply([grep {/\./} @{_address_list($info->vrf_addresses('red'))}],
    ['2089 10.100.1.1', '2091 10.101.1.1'],
    'A route is no address source: rcIpAddrTable alone gives them');
  is($info->{_vrf_walked}{red}{vrf_rc_ip_mask}, 1,
    'The rcIpAdEntNetMask walk counts toward the read');
}

# Rows of another vrfid are not this VRF's, whatever the context serves
sub vrf_vendor_address_rows__voss_other_vrfid__dropped : Tests(1) {
  my $test  = shift;
  my $cache = _voss_red_cache();
  my $store = $cache->{store};
  $store->{vrf_rc_ip_vrf}{'2090.10.100.1.1'}  = 2;
  $store->{vrf_rc_ip_addr}{'2090.10.100.1.1'} = '10.100.1.1';
  $store->{vrf_rc_ip_mask}{'2090.10.100.1.1'} = '255.255.255.0';
  my $info = _use_cache($test, $cache);

  _enter_vr($info, 'vrf1');
  cmp_deeply(
    [sort grep {/\.\d+\.\d+\.\d+$/} keys %{
        $info->_vrf_vendor_address_rows('red')}],
    ['2089.10.100.1.1', '2091.10.101.1.1'], 'Only vrfid 1\'s rows');
}

sub vrf_addresses__voss_grey_context__loopback : Tests(4) {
  my $test = shift;
  my $info = _use_cache($test, _voss_grey_cache());

  _enter_vr($info, 'vrf4');
  cmp_deeply($info->vrf_addresses('grey'),
    {'1345.10.104.1.1' => {ifindex => 1345, ip => '10.104.1.1',
        prefix_len => 32, family => 'ipv4'}},
    'The loopback address, from rcIpAddrTable');
  cmp_deeply($info->vrf_neighbors('grey'), {},
    'The loopback\'s own ARP row is not a neighbor');
  cmp_deeply([keys %{$info->vrf_subnets('grey')}], ['10.104.1.1/32'],
    'Its subnet is the address; a learned host route is not grey\'s');

  my $cache = _voss_grey_cache();
  $cache->{store}{$_} = {} for qw/vrf_rc_ip_vrf vrf_rc_ip_addr vrf_rc_ip_mask/;
  $info = _use_cache($test, $cache);
  _enter_vr($info, 'vrf4');
  cmp_deeply($info->vrf_addresses('grey'), {},
    'With rcIpAddrTable empty, its connected route gives no address');
}

sub vrf_neighbors__voss_green_context__ipv6_only : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_green_cache());

  _enter_vr($info, 'vrf3');
  cmp_deeply(_address_list($info->vrf_neighbors('green')),
    ['2093 ' . _v6('2001:db8:1201:0:0:0:0:16')],
    'The IPv6 host on green\'s VLAN, from IPV6-MIB');
  cmp_deeply(_address_list($info->vrf_addresses('green')),
    [sort map { '2093 ' . _v6($_) } '2001:db8:1201:0:0:0:0:1',
      'fe80:0:0:0:0:ff:fe00:5'],
    'Its IPv6 addresses');
}

# A row in the standard index shape, with length octets
sub vrf_subnets__voss_standard_route_index__read_by_fallback : Tests(1) {
  my $test  = shift;
  my $cache = _voss_red_cache();
  my $iid   = '1.4.10.110.1.0.24.0.1.4.10.110.1.1';
  $cache->{store}{vrf_cidr_if}{$iid}    = 2089;
  $cache->{store}{vrf_cidr_proto}{$iid} = 'local';
  my $info = _use_cache($test, $cache);

  _enter_vr($info, 'vrf1');
  cmp_deeply($info->vrf_subnets('red')->{'10.110.1.0/24'},
    superhashof({ifindex => 2089, sources => ['route']}),
    'The standard parser reads a row the VOSS one rejects');
}

sub vrf_subnets__voss_overlap__each_vrf_its_own : Tests(6) {
  my $test = shift;

  my $info = _use_cache($test, _voss_red_cache());
  _enter_vr($info, 'vrf1');
  my $red = $info->vrf_subnets('red');
  cmp_deeply($red->{'10.100.1.0/24'},
    superhashof({ifindex => 2089, sources => ['address', 'route']}),
    'red\'s 10.100.1.0/24 is on red\'s VLAN');
  ok(!exists $red->{'10.100.3.0/24'}, 'A route learned over the fabric'
    . ' is not a subnet of red\'s');
  ok(exists $red->{'2001:0db8:1001:0000:0000:0000:0000:0000/64'},
    'red\'s IPv6 subnet, from its address');

  $info = _use_cache($test, _voss_blue_cache());
  _enter_vr($info, 'vrf2');
  my $blue = $info->vrf_subnets('blue');
  cmp_deeply($blue->{'10.100.1.0/24'},
    superhashof({ifindex => 2090, sources => ['address', 'route']}),
    'blue\'s 10.100.1.0/24 is on blue\'s VLAN');
  ok(exists $info->vrf_addresses('blue')->{'2090.10.100.1.1'},
    'blue holds the shared address on its own VLAN');
  cmp_deeply(_address_list($info->vrf_neighbors('blue')),
    ['2090 10.100.1.10', '2092 10.102.1.10'], 'blue\'s hosts');
}


# The default context's ipAddrTable lists every VRF's addresses, and
# MgmtRouter's on the out-of-band port 3, with no VRF, and 0.0.0.0 on the
# management VLAN's interface. GlobalRouter's are
# those on its ports, and the management CLIP's on ifIndex 1, whose host
# route sits on the management VLAN's interface.
sub _voss_default_ipadent_cache {
  my $cache = _voss_default_cache();
  my %ips = ('0.0.0.0' => 6138, '10.0.0.15' => 3, '10.100.1.1' => 2089,
    '10.101.1.1' => 2091,
    '10.102.1.1' => 2092, '10.104.1.1' => 1345, '10.254.0.13' => 1,
    '10.255.0.13' => 1344);
  $cache->{store}{old_ip_index} = {%ips};
  $cache->{store}{old_ip_netmask} = {map { $_ => '255.255.255.0' } keys %ips};
  $cache->{store}{old_ip_netmask}{$_} = '255.255.255.255'
    for qw/10.104.1.1 10.254.0.13 10.255.0.13/;
  $cache->{store}{old_ip_netmask}{'0.0.0.0'} = '0.0.0.0';
  $cache->{"_$_"} = 1 for qw/old_ip_index old_ip_netmask/;
  return $cache;
}

sub vrf_addresses__voss_default_context__globalrouter_only : Tests(5) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_ipadent_cache());

  my $rows = $info->vrf_addresses('default');
  cmp_deeply(_address_list($rows), ['1 10.254.0.13', '1344 10.255.0.13'],
    'GlobalRouter\'s CLIP and the management CLIP; 0.0.0.0 is none');
  ok(!exists $info->vrf_subnets('default')->{'0.0.0.0/0'},
    'No 0.0.0.0/0 subnet');
  cmp_deeply($rows->{'1.10.254.0.13'},
    {ifindex => 1, ip => '10.254.0.13', prefix_len => 32,
      family => 'ipv4'},
    '10.254.0.13 stays on ifIndex 1, not its route\'s interface');
  is($rows->{'1344.10.255.0.13'}{prefix_len}, 32,
    'The CLIP both tables serve is one row');

  $info = _use_cache($test, _voss_default_cache());
  cmp_deeply(_address_list($info->vrf_addresses('default')),
    ['1344 10.255.0.13'], 'Without ipAddrTable, rcIpAddrTable of vrfid 0');
}

sub vrf_instances_complete__voss_global_and_mgmt_routers_only__is_1
  : Tests(6) {
  my $test = shift;

  foreach my $vrfids ([0], [0, 512]) {
    my $label = join '+', map { $VOSS_VRF_NAMES{$_} } @$vrfids;
    my $info = _use_cache($test, _voss_cache($vrfids));
    is($info->vrf_instances_complete(), 1, "$label: read in full");
    is($info->vrf_instances()->{default}{sources}{list}, 'RAPID-CITY',
      "$label: rcVrfConfigTable lists default");
    ok(!exists $info->vrf_instances(['red'])->{red},
      "$label: caller names add nothing");
  }
}

# ipAddrTable serves 0.0.0.0 on an interface, and a connected route has
# the next hop 0.0.0.0: that interface is no port of the context
sub vrf_neighbors__voss_default_unspecified_next_hop__no_port : Tests(2) {
  my $test = shift;
  my $cache = _voss_default_ipadent_cache();
  my %routes = _voss_route_store(['10.9.0.0', 24, '0.0.0.0', 6141]);
  my %arp = _voss_neighbor_store(arp => [[6140, '10.9.0.5', 7],
      [6141, '10.9.0.6', 8]]);
  $cache->{store}{old_ip_index}{'0.0.0.0'} = 6140;
  foreach my $method (keys %routes, keys %arp) {
    my $rows = $routes{$method} || $arp{$method};
    $cache->{store}{$method} = {%{$cache->{store}{$method} || {}}, %$rows};
    $cache->{"_$method"} = 1;
  }
  my $info = _use_cache($test, $cache);

  my $rows = $info->vrf_neighbors('default');
  ok(exists $rows->{'6141.10.9.0.6'}, 'The route\'s interface is a port');
  ok(!exists $rows->{'6140.10.9.0.5'},
    'The interface holding 0.0.0.0 is not');
}

sub _enter_community {
  my ($info, $community) = @_;
  $info->{args}{Community}      = 'public';
  $info->session()->{Version}   = 2;
  $info->session()->{Community} = $community;
  return;
}

sub _vrf_community_context__voss_red_context__returns_vrf1 : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, 'public-red');
  is($info->_vrf_community_context(), 'vrf1',
    'The one row red\'s context serves names its context');
}

sub _vrf_community_context__voss_mgmt_context__returns_vrf512 : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _voss_cache([512], _voss_port_macs()));

  _enter_community($info, 'public-mgmt');
  is($info->_vrf_community_context(), 'vrf512',
    'The management router\'s row names vrf512');
}

sub _vrf_community_context__voss_default_context__returns_empty : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  _enter_community($info, 'public');
  is($info->_vrf_community_context(), q(),
    'The default context serves every row');
  is($info->_vrf_session_context(), q(), 'The session reads the default');
}

sub _vrf_community_context__voss_only_global_router__returns_empty : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _voss_cache([0]));

  _enter_community($info, 'public');
  is($info->_vrf_community_context(), q(), 'vrfid 0 alone is the default');
}

sub _vrf_community_context__voss_table_not_served__undef : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  $info->{store}{vrf_rc_context} = undef;
  _enter_community($info, 'public-red');
  is($info->_vrf_community_context(), undef, 'No rows are served');
  is($info->_vrf_session_context(), q(), 'The session reads the default');
}

sub _vrf_community_context__voss_v3__undef_without_walking : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_vr($info, 'vrf1');
  my $walks = 0;
  no warnings 'redefine';
  local *SNMP::Info::Layer3::Extreme::vrf_rc_context
    = sub { $walks++; return {} };
  is($info->_vrf_community_context(), undef, 'No answer over SNMPv3');
  is($walks, 0, 'The VRF table was not walked');
}

sub _vrf_community_context__xos__undef : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _red_cache());

  $info->{store}{vrf_rc_context} = {1 => 'vrf1'};
  _enter_community($info, 'public-red');
  is($info->_vrf_community_context(), undef,
    'ExtremeXOS answers no v2c session');
}

sub vrf_neighbors__voss_mapped_community_red__reads_red : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, 'public-red');
  my $rows = $info->vrf_neighbors('red');
  cmp_deeply(_address_list($rows),
    [sort '2089 10.100.1.10', '2091 10.101.1.10',
      '2089 ' . _v6('2001:db8:1001:0:0:0:0:16')],
    'The same hosts as over the SNMPv3 context');
  is($info->error(), undef, 'No error');
}

sub vrf_instances__voss_mapped_community__refused : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, 'public-red');
  is($info->vrf_instances(), undef, 'The list is refused over red');
  like($info->error(), qr/only the default context.*context 'vrf1'/s,
    'The error names the default context and the session\'s');
}

sub _vrf_community_context__voss_row_without_context__undef : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  $info->{store}{vrf_rc_context} = {1 => q()};
  _enter_community($info, q(public-red));
  is($info->_vrf_community_context(), undef,
    q(A VRF row naming no context is not the default context));
}

sub vrf_neighbors__voss_mapped_community_red__default_refused : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, q(public-red));
  is($info->vrf_neighbors(q(default)), undef, q(default is refused over red));
  like($info->error(), qr/default context.*context 'vrf1'/s,
    q(The error names the session's context));
}

sub _vrf_session_context__voss_colon_community__vrf1 : Tests(1) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, 'public::1');
  is($info->_vrf_session_context(), 'vrf1',
    'The one row the context serves names the context');
}

sub _vrf_session_context__voss_at_suffix__ignored : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_default_cache());

  _enter_community($info, 'public@vrf1');
  is($info->_walk_context(), 'vrf1', 'The suffix parses as a context');
  is($info->_vrf_session_context(), q(),
    'The default context rows win over the suffix');
}

sub vrf_neighbors__voss_colon_community_red__reads_red : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, 'public::1');
  my $rows = $info->vrf_neighbors('red');
  cmp_deeply(_address_list($rows),
    [sort '2089 10.100.1.10', '2091 10.101.1.10',
      '2089 ' . _v6('2001:db8:1001:0:0:0:0:16')],
    'The same hosts as over the SNMPv3 context');
  is($info->error(), undef, 'No error');
}

sub vrf_instances__voss_colon_community__refused : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, 'public::1');
  is($info->vrf_instances(), undef, 'The list is refused over red');
  like($info->error(), qr/only the default context.*context 'vrf1'/s,
    'The error names the default context and the session\'s');
}

sub vrf_neighbors__voss_colon_community_red__default_refused : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, q(public::1));
  is($info->vrf_neighbors(q(default)), undef, q(default is refused over red));
  like($info->error(), qr/default context.*context 'vrf1'/s,
    q(The error names the session's context));
}

sub i_vrf__voss_colon_community_red__red_ports : Tests(2) {
  my $test = shift;
  my $info = _use_cache($test, _voss_red_cache());

  _enter_community($info, q(public::1));
  cmp_deeply(scalar $info->i_vrf(), {2089 => 'red', 2091 => 'red'},
    q(red's VLANs, as over the SNMPv3 context));
  is($info->error(), undef, q(No error));
}

1;
