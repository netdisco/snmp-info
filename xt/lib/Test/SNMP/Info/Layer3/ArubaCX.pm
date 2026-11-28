# Test::SNMP::Info::Layer3::ArubaCX
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

package Test::SNMP::Info::Layer3::ArubaCX;

use Test::Class::Most parent => 'My::Test::Class';
use SNMP::Info::Layer3::ArubaCX;
use JSON::PP;

sub startup : Tests(startup => 1) {
    my $test = shift;
    $test->SUPER::startup;
}

sub setup : Tests(setup) {
    my $test = shift;
    $test->SUPER::setup;
    open my $fh, '<', 'xt/fixtures/arubacx-cipt.json' or die $!;
    my $fixture = decode_json( do { local $/; <$fh> } );
    close $fh;
    my %store = ( cipt_addr_type => {}, cipt_addr => {}, cipt_ifindex => {} );
    while ( my ( $idx, $row ) = each %{ $fixture->{rows} } ) {
        $store{cipt_addr_type}{$idx} = $row->{type};
        $store{cipt_addr}{$idx}      = pack( 'H*', $row->{addr_hex} );
        $store{cipt_ifindex}{$idx}   = $row->{port};
    }
    $test->{native6} = '99.2.16.32.1.13.184.' . join( '.', (0) x 11, 200 );
    $store{ip_n2p_phys_addr}
        = { $test->{native6} => pack( 'C6', 2, 0, 0, 0, 1, 200 ) };
    $store{at_paddr}
        = { '99.192.0.2.200' => pack( 'C6', 2, 0, 0, 0, 1, 200 ) };
    $store{at_netaddr} = { '99.192.0.2.200' => '192.0.2.200' };
    $test->{info}->cache(
        {   '_layers'      => 78,
            '_id'          => '.1.3.6.1.4.1.47196.4.1.1.1.309',
            '_description' => 'Aruba JL728B 6200F',
            ( map { ( '_' . $_ ) => 1 } keys %store ),
            store => \%store,
        }
    );
}

sub mac : Tests(4) {
    my $test = shift;
    my $info = $test->{info};
    $info->{_b_mac} = pack( 'H*', '8C85C162C740' );
    $info->{_mac}   = pack( 'H*', '8C85C162C77F' );

    can_ok( $info, 'mac' );
    is( $info->mac(), '8c:85:c1:62:c7:40',
        q(mac__bridge_address_present__returns_bridge_mac) );

    $info->{_b_mac} = pack( 'H*', '000000000000' );
    is( $info->mac(), '8c:85:c1:62:c7:7f',
        q(mac__bridge_address_zero__returns_first_interface_mac) );

    delete $info->{_b_mac};
    is( $info->mac(), '8c:85:c1:62:c7:7f',
        q(mac__bridge_address_missing__returns_first_interface_mac) );
}

sub model : Tests(7) {
    my $test       = shift;
    my $info       = $test->{info};
    my $models     = { 1 => 'JL719C', 12001 => 'JL719C', 13001 => 'JL601A' };
    my $translated = 'arubaWiredSwitchJL719C';
    my $stack;
    no warnings 'redefine';
    local *SNMP::Info::Layer3::ArubaCX::entPhysicalModelName
        = sub { return $models };
    local *SNMP::Info::Layer3::ArubaCX::id
        = sub { return '.1.3.6.1.4.1.47196.4.1.1.1.422' };
    local *SNMP::Info::Layer3::ArubaCX::stack_info = sub { return $stack };
    local *SNMP::translateObj = sub { return $translated };
    is( $info->model,
        '8360-48Y6C v2',
        'Reported root product code translated'
    );
    $models = { 1 => '8360-48Y6C v2' };
    is( $info->model, '8360-48Y6C v2', 'Readable device model preserved' );
    $models = { 1 => 'JL999C' };
    is( $info->model, 'JL999C',
        'Unknown root model preserved over known OID' );
    $models = { 1 => '', 13001 => 'JL601A' };
    is( $info->model,
        '8360-48Y6C v2',
        'Known product OID fallback translated'
    );
    $translated = 'arubaWiredSwitchJL999C';
    is( $info->model, 'JL999C', 'Unknown product OID name preserved' );
    $translated = undef;
    is( $info->model,
        '.1.3.6.1.4.1.47196.4.1.1.1.422',
        'Untranslated OID preserved'
    );
    $models = { 1 => 'JL719C' };
    $stack  = '6200F (stack of 2)';
    is( $info->model, $stack, 'Existing stack result retains precedence' );
}

sub at_paddr : Tests(4) {
    my $test = shift;
    my $data = $test->{info}->at_paddr;
    is( scalar keys %$data, 37, '36 tracked IPv4 rows plus native ARP' );
    is( $data->{'99.192.0.2.200'},
        '02:00:00:00:01:c8', 'Native ARP MAC preserved' );
    is( $data->{'cipt.6.2.0.0.0.0.1.1.1'},
        '02:00:00:00:00:01', 'MAC decoded from index' );
    cmp_deeply(
        [ sort keys %$data ],
        [ sort keys %{ $test->{info}->at_netaddr } ],
        'IPv4 MAC/IP row keys match'
    );
}

sub at_netaddr : Tests(3) {
    my $test = shift;
    my $data = $test->{info}->at_netaddr;
    is( $data->{'99.192.0.2.200'}, '192.0.2.200', 'Native ARP IP preserved' );
    is( $data->{'cipt.6.2.0.0.0.0.1.1.1'},
        '192.0.2.1', 'Binary IPv4 decoded' );
    cmp_deeply(
        $test->{info}->at_netaddr('cipt.6.2.0.0.0.0.1.1.1'),
        { 'cipt.6.2.0.0.0.0.1.1.1' => '192.0.2.1' },
        'Partial query selects tracking row'
    );
}

sub ipv6_n2p_mac : Tests(3) {
    my $test = shift;
    my $data = $test->{info}->ipv6_n2p_mac;
    is( scalar keys %$data, 16,
        '15 tracked IPv6 rows plus native neighbour' );
    is( $data->{ $test->{native6} },
        '02:00:00:00:01:c8',
        'Native IPv6 MAC preserved'
    );
    cmp_deeply(
        [ sort keys %$data ],
        [ sort keys %{ $test->{info}->ipv6_n2p_addr } ],
        'IPv6 MAC/IP row keys match'
    );
}

sub ipv6_n2p_addr : Tests(2) {
    my $test = shift;
    my $data = $test->{info}->ipv6_n2p_addr;
    is( $data->{ $test->{native6} },
        '2001:0db8:0000:0000:0000:0000:0000:00c8',
        'Native IPv6 IP preserved'
    );
    my @tracked = grep {/^cipt\./} keys %$data;
    ok( !grep( { $data->{$_} !~ /^2001:db8:0:0:0:0:0:[0-9a-f]+$/ } @tracked ),
        'All binary IPv6 addresses decoded'
    );
}

sub ipv6_n2p_if : Tests(2) {
    my $test = shift;
    my $data = $test->{info}->ipv6_n2p_if;
    is( $data->{ $test->{native6} },
        99, 'Native neighbour interface preserved' );
    cmp_deeply(
        [ sort keys %$data ],
        [ sort keys %{ $test->{info}->ipv6_n2p_addr } ],
        'IPv6 interface/IP row keys match'
    );
}

sub multiple_addresses : Tests(1) {
    my $test    = shift;
    my $clients = $test->{info}->_cipt_clients(1);
    my %groups;
    for my $row ( keys %$clients ) {
        ( my $group = $row ) =~ s/\.\d+$//;
        push @{ $groups{$group} }, $clients->{$row}{addr};
    }
    ok( grep( { scalar @$_ > 1 } values %groups ),
        'Multiple IPv4 addresses for the same MAC/VLAN are retained' );
}

sub invalid_indexes : Tests(1) {
    my $test = shift;
    my $info = $test->{info};
    subtest 'Invalid client indexes and ports' => sub {
        for my $idx (
            '6.256.0.0.0.0.1.1.1',  '6.3.0.0.0.0.1.1.1',
            '6.0.0.0.0.0.0.1.1',    '6.2.0.0.0.0.1.0.1',
            '6.2.0.0.0.0.1.4095.1', '6.2.0.0.0.0.1.1.0'
            )
        {
            $info->{store}{cipt_addr_type}{$idx} = 1;
            $info->{store}{cipt_addr}{$idx}    = pack( 'C4', 192, 0, 2, 99 );
            $info->{store}{cipt_ifindex}{$idx} = 1;
            ok( !exists $info->at_netaddr->{ 'cipt.' . $idx },
                "Invalid row $idx omitted" );
        }
        my $idx = '6.2.0.0.0.0.1.1.1';
        for my $port ( 0, -1, 'invalid' ) {
            $info->{store}{cipt_ifindex}{$idx} = $port;
            ok( !exists $info->at_netaddr->{ 'cipt.' . $idx },
                "Invalid port $port omitted" );
        }
        done_testing;
    };
}

sub tracking_edge_cases : Tests(8) {
    my $test = shift;
    my $info = $test->{info};
    my $idx  = '6.2.0.0.0.0.1.1.1';
    $info->{store}{cipt_addr_type}{$idx} = 'ipv4';
    is( $info->at_netaddr->{ 'cipt.' . $idx },
        '192.0.2.1', 'Address type enum supported' );
    $info->{store}{cipt_addr_type}{$idx} = 3;
    ok( !exists $info->at_netaddr->{ 'cipt.' . $idx },
        'Unsupported address type omitted' );
    $info->{store}{cipt_addr_type}{$idx} = 1;
    $info->{store}{cipt_addr}{$idx}      = 'broken';
    ok( !exists $info->at_paddr->{ 'cipt.' . $idx },
        'Invalid address length omits paired MAC'
    );
    $info->{store}{cipt_addr}{$idx} = pack( 'C4', 192, 0, 2, 1 );
    delete $info->{store}{cipt_ifindex}{$idx};
    ok( !exists $info->at_netaddr->{ 'cipt.' . $idx },
        'Incomplete row omitted' );
    $info->{store}{cipt_addr_type}{'invalid'} = 1;
    $info->{store}{cipt_addr}{'invalid'}      = pack( 'C4', 192, 0, 2, 2 );
    $info->{store}{cipt_ifindex}{'invalid'}   = 1;
    ok( !exists $info->at_netaddr->{'cipt.invalid'},
        'Malformed index omitted' );
    $info->{store}{cipt_addr_type} = {};
    is( scalar keys %{ $info->at_paddr },
        1, 'Empty tracking preserves native ARP' );
    is( scalar keys %{ $info->ipv6_n2p_mac },
        1, 'Empty tracking preserves IPv6 neighbours' );
    $info->clear_cache;
    cmp_deeply( $info->at_netaddr, {},
        'Unsupported tables yield no invented addresses' );
}

sub _prime_xcvr {
    my $test = shift;
    my $info = $test->{info};
    my %ent  = (
        1      => [ 'Stack',   'stack',   0,      'Stack' ],
        101001 => [ 'Chassis', 'chassis', 1,      '6300M Chassis' ],
        120010 => [ '1/1/1',   'port',    101001, 'Switch Port' ],
        120020 => [ '1/1/2',   'port',    101001, 'Switch Port' ],
    );
    my %store = (
        pm_xcvr_port    => { 1 => '1/1/1',          27 => '1/1/27' },
        pm_xcvr_descr   => { 1 => '10G SFP+ LC SR', 27 => '1G SFP LC LX' },
        pm_xcvr_product => { 1 => 'J9150D',         27 => 'J4859D' },
        pm_xcvr_serial  => { 1 => 'TEST0000001',    27 => 'TEST0000027' },
        pm_xcvr_type    => { 1 => '10G-SR',         27 => '1G-LX' },
    );
    foreach my $idx ( keys %ent ) {
        my ( $name, $class, $parent, $descr ) = @{ $ent{$idx} };
        $store{entPhysicalDescr}{$idx} = $descr;
        $store{e_descr}{$idx}          = $descr;
        $store{e_name}{$idx}           = $name;
        $store{e_class}{$idx}          = $class;
        $store{e_parent}{$idx}         = $parent;
        $store{e_model}{$idx}  = $class eq 'chassis' ? 'JL660A'      : '';
        $store{e_serial}{$idx} = $class eq 'chassis' ? 'TESTCHASSIS' : '';
        $store{e_type}{$idx}   = 'zeroDotZero';
        $store{e_fru}{$idx}    = $class eq 'chassis' ? 'true' : 'false';
    }
    $info->{"_$_"} = 1 for keys %store;
    $info->{store}{$_} = $store{$_} for keys %store;
    return;
}

sub _xcvr_rows {
    my ( $test, $method ) = @_;
    my $data = $test->{info}->$method() || {};
    return {
        map  { $_ => $data->{$_} }
        grep { $_ >= 1_000_000_000 } keys %$data
    };
}

sub e_index : Tests(3) {
    my $test = shift;
    $test->_prime_xcvr;
    my $e_index = $test->{info}->e_index;
    is( scalar keys %$e_index, 6,
        'Four real entities plus two transceivers' );
    is( $e_index->{1_000_000_001}, 1_000_000_001, 'Synthetic index value' );
    is( $e_index->{120010},        120010, 'Real entity index unchanged' );
}

sub e_class : Tests(2) {
    my $test = shift;
    $test->_prime_xcvr;
    cmp_deeply(
        $test->_xcvr_rows('e_class'),
        { 1_000_000_001 => 'module', 1_000_000_027 => 'module' },
        'Transceivers are modules'
    );
    is( $test->{info}->e_class->{120010}, 'port', 'Real class unchanged' );
}

sub e_descr : Tests(1) {
    my $test = shift;
    $test->_prime_xcvr;
    cmp_deeply(
        $test->_xcvr_rows('e_descr'),
        {   1_000_000_001 => '10G SFP+ LC SR',
            1_000_000_027 => '1G SFP LC LX'
        },
        'Transceiver descriptions'
    );
}

sub e_name : Tests(1) {
    my $test = shift;
    $test->_prime_xcvr;
    cmp_deeply(
        $test->_xcvr_rows('e_name'),
        {   1_000_000_001 => 'Transceiver 1/1/1',
            1_000_000_027 => 'Transceiver 1/1/27'
        },
        'Transceiver names carry the port'
    );
}

sub e_model : Tests(1) {
    my $test = shift;
    $test->_prime_xcvr;
    cmp_deeply(
        $test->_xcvr_rows('e_model'),
        { 1_000_000_001 => 'J9150D', 1_000_000_027 => 'J4859D' },
        'Transceiver product numbers'
    );
}

sub e_serial : Tests(1) {
    my $test = shift;
    $test->_prime_xcvr;
    cmp_deeply(
        $test->_xcvr_rows('e_serial'),
        { 1_000_000_001 => 'TEST0000001', 1_000_000_027 => 'TEST0000027' },
        'Transceiver serial numbers'
    );
}

sub e_type : Tests(1) {
    my $test = shift;
    $test->_prime_xcvr;
    cmp_deeply(
        $test->_xcvr_rows('e_type'),
        { 1_000_000_001 => '10G-SR', 1_000_000_027 => '1G-LX' },
        'Transceiver types'
    );
}

sub e_fru : Tests(1) {
    my $test = shift;
    $test->_prime_xcvr;
    cmp_deeply(
        $test->_xcvr_rows('e_fru'),
        { 1_000_000_001 => 'true', 1_000_000_027 => 'true' },
        'Transceivers are field replaceable'
    );
}

sub e_parent : Tests(3) {
    my $test = shift;
    $test->_prime_xcvr;
    my $e_parent = $test->{info}->e_parent;
    is( $e_parent->{1_000_000_001}, 120010, 'Parented to matching port' );
    is( $e_parent->{1_000_000_027}, 101001, 'No port entity: chassis' );
    is( $e_parent->{120010},        101001, 'Real parent unchanged' );
}

sub xcvr_no_entities : Tests(2) {
    my $test = shift;
    $test->_prime_xcvr;
    my $info = $test->{info};
    $info->{store}{$_} = {} for qw/entPhysicalDescr e_class e_name e_parent/;
    is( scalar keys %{ $info->e_index },
        2, 'Transceivers without ENTITY-MIB' );
    is( $info->e_parent->{1_000_000_001}, 0, 'Root parent without chassis' );
}

sub xcvr_index_collision : Tests(3) {
    my $test = shift;
    $test->_prime_xcvr;
    my $info = $test->{info};
    $info->{store}{entPhysicalDescr}{1_000_000_027} = 'Real entity';
    $info->{store}{e_descr}{1_000_000_027}          = 'Real entity';
    is( $info->e_index->{1_000_000_027}, 1_000_000_027, 'Real index kept' );
    is( $info->e_descr->{1_000_000_027}, 'Real entity', 'Real row wins' );
    ok( !exists $info->e_model->{1_000_000_027},
        'Colliding transceiver skipped'
    );
}

sub xcvr_empty_table : Tests(2) {
    my $test = shift;
    $test->_prime_xcvr;
    my $info = $test->{info};
    $info->{store}{$_} = {} for grep {/^pm_xcvr_/} keys %{ $info->{store} };
    cmp_deeply(
        $info->e_descr,
        $info->{store}{e_descr},
        'Entity rows unchanged'
    );
    is( scalar keys %{ $info->e_index }, 4, 'No synthetic indexes' );
}

sub xcvr_partial : Tests(2) {
    my $test = shift;
    $test->_prime_xcvr;
    my $info = $test->{info};
    $info->{sess}{Data}
        = { 'ENTITY-MIB::entPhysicalDescr' => { 120010 => 'Switch Port' }, };
    cmp_deeply(
        $info->e_descr(120010),
        { 120010 => 'Switch Port' },
        'Partial fetch returns the real row only'
    );
    cmp_deeply(
        $info->e_index(120010),
        { 120010 => 120010 },
        'Partial e_index returns the real row only'
    );
}

my %MSTP_ROLES  = ( '1.3' => 'designated', '1.769' => 'root' );
my %RPVST_ROLES = ( '1.3' => '6',          '1.769' => '6' );
my %MIXED_ROLES = ( '1.3' => '6',          '1.769' => 'designated' );
my %ALL_UP      = ( 3     => 'up',         769     => 'up',   770 => 'up' );
my %ALL_DOWN    = ( 3     => 'down',       769     => 'down', 770 => 'down' );

my $bridge_id = sub { pack( 'H*', shift ) };

# Shapes from an AOS-CX 10.16 walk in MSTP mode: component 1, MSTIs 1 and
# 2, bridge ports equal to ifIndexes, LAGs from 769. BRIDGE-MIB columns are
# primed too, so a fall through to Bridge.pm would build a tree. Every
# port is up unless the caller passes ifOperStatus rows.
sub _prime_stp {
    my ( $test, $roles, $up ) = @_;
    my $info = $test->{info};

    my %store = (
        ieee_stp_version => { 1 => 'mstp' },
        mstp_cist_bridge => { 1 => $bridge_id->('1000020000000001') },
        ieee_stp_root    => { 1 => $bridge_id->('1000020000000001') },
        mstp_i_bridge    => {
            '1.1' => $bridge_id->('1001020000000001'),
            '1.2' => $bridge_id->('2002020000000002'),
        },
        mstp_i_root => {
            '1.1' => $bridge_id->('1001020000000001'),
            '1.2' => $bridge_id->('2002020000000002'),
        },
        mstp_vlan_msti   => { '1.1' => 0, '1.10' => 1, '1.20' => 2 },
        mstp_cist_p_role => $roles,
        mstp_p_state     => {},
        ieee_stp_p_state => {},
        bp_index         => { 3 => 3,            769 => 769, 770 => 770 },
        stp_p_id         => { 3 => 3,            769 => 769 },
        stp_p_state      => { 3 => 'forwarding', 769 => 'blocking' },
        i_up             => $up // {%ALL_UP},
    );
    foreach my $column ( keys %store ) {
        $info->{"_$column"} = 1;
        $info->{store}{$column} = $store{$column};
    }
    $info->{_stp_root} = $bridge_id->('1000020000000001');
    delete $info->{$_} for qw/_aoscx_stp_protocol _stp_trees/;
    return;
}

my $mac = sub { pack( 'H*', shift ) };

# Shapes from an AOS-CX 10.16 walk in RPVST mode: rows indexed by VLAN, and
# by VLAN and ifIndex. VLAN 10 has this switch as root; VLAN 20 has another
# root; VLAN 30 is disabled. Port 769 has only a designated bridge row.
sub _prime_rpvst {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_stp( {%RPVST_ROLES} );
    my %store = (
        rpvst_v_admin =>
            { 10 => 'enabled', 20 => 'enabled', 30 => 'disabled' },
        rpvst_v_priority      => { 10 => 4096, 20 => 32768 },
        rpvst_v_root_priority => { 10 => 4096, 20 => 4096 },
        rpvst_v_root_mac      => {
            10 => $mac->('020000000001'),
            20 => $mac->('020000000002'),
        },
        rpvst_pv_state => { '10.3' => 'forwarding', '20.770' => 'blocking' },
        rpvst_pv_role  => { '10.3' => 'designated', '20.770' => 'alternate' },
        rpvst_pv_bridge => {
            '10.3'   => $mac->('020000000001'),
            '20.770' => $mac->('020000000002'),
            '20.769' => $mac->('020000000009'),
        },
    );
    foreach my $column ( keys %store ) {
        $info->{"_$column"} = 1;
        $info->{store}{$column} = $store{$column};
    }
    $info->{_rpvst_ext_sysid} = 'true';
    return;
}

sub hasMSTP : Tests(6) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_stp( {%MSTP_ROLES} );
    is( $info->hasMSTP(), 1, 'hasMSTP__mstp_cist_roles__returns_1' );
    $test->_prime_stp( { %MSTP_ROLES, '2.5' => '6' } );
    is( $info->hasMSTP(), 1,
        'hasMSTP__role_6_on_second_component__reads_lowest_only' );
    $test->_prime_stp( {%RPVST_ROLES} );
    is( $info->hasMSTP(), 0, 'hasMSTP__all_cist_roles_6__returns_0' );
    $test->_prime_stp( {%MIXED_ROLES}, { 3 => 'down', 769 => 'up' } );
    is( $info->hasMSTP(), 1,
        'hasMSTP__role_6_on_down_port_beside_defined_role__returns_1' );
    $test->_prime_stp( {%MIXED_ROLES}, { 3 => 'down', 769 => 'up' } );
    is( $info->hasMSTP(), 1,
        'hasMSTP__defined_role_on_up_port_only__returns_1' );
    $test->_prime_stp( {%RPVST_ROLES}, {%ALL_DOWN} );
    is( $info->hasMSTP(), 0,
        'hasMSTP__all_role_6_every_port_down__returns_0' );
}

# CIST rows only on two link aggregations, as AOS-CX 10.16 serves them:
# each aggregation's own ifOperStatus down, its members' as given
sub _prime_lag_members {
    my ( $test, $member_up ) = @_;
    my $info = $test->{info};

    $test->_prime_stp( { '1.769' => '6', '1.770' => '6' },
        { 1 => $member_up, 2 => 'down', 769 => 'down', 770 => 'down' } );
    my %store = (
        raw_ad_lag_ports => { 769 => '1/1/1', 770 => '1/1/2' },
        i_index          => { 1   => 1, 2 => 2, 769 => 769, 770 => 770 },
        i_description    => {
            1   => '1/1/1',
            2   => '1/1/2',
            769 => 'lag1',
            770 => 'lag2'
        },
    );
    foreach my $column ( keys %store ) {
        $info->{"_$column"} = 1;
        $info->{store}{$column} = $store{$column};
    }
    return;
}

# Bridge port 3 is ifIndex 1003, so a swap of the two keys changes the answer
sub _prime_bridge_port_remap {
    my ( $test, $up ) = @_;
    my $info = $test->{info};

    $test->_prime_stp( { '1.3' => '6' }, $up );
    $info->{_bp_index} = 1;
    $info->{store}{bp_index} = { 3 => 1003 };
    return;
}

sub hasRapidPVST : Tests(10) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_stp( {%MSTP_ROLES} );
    is( $info->hasRapidPVST(), 0,
        'hasRapidPVST__mstp_cist_roles__returns_0' );
    $test->_prime_stp( {%RPVST_ROLES} );
    is( $info->hasRapidPVST(), 1,
        'hasRapidPVST__all_cist_roles_6_with_up_port__returns_1' );
    $test->_prime_stp( {%RPVST_ROLES}, { 3 => 'down', 769 => 'up' } );
    is( $info->hasRapidPVST(), 1,
        'hasRapidPVST__all_cist_roles_6_one_port_up__returns_1' );
    $test->_prime_stp( {%MIXED_ROLES} );
    is( $info->hasRapidPVST(), 0,
        'hasRapidPVST__defined_role_beside_role_6__returns_0' );
    $test->_prime_stp( {%RPVST_ROLES}, {%ALL_DOWN} );
    is( $info->hasRapidPVST(), 0,
        'hasRapidPVST__all_cist_roles_6_every_port_down__returns_0' );
    $test->_prime_stp( { %RPVST_ROLES, '2.5' => 'designated' } );
    is( $info->hasRapidPVST(), 1,
        'hasRapidPVST__defined_role_on_second_component__reads_lowest_only' );
    $test->_prime_lag_members('up');
    is( $info->hasRapidPVST(), 1,
        'hasRapidPVST__all_role_6_lag_down_member_up__returns_1' );
    $test->_prime_lag_members('down');
    is( $info->hasRapidPVST(), 0,
        'hasRapidPVST__all_role_6_lag_and_members_down__returns_0' );
    $test->_prime_bridge_port_remap( { 1003 => 'up', 3 => 'down' } );
    is( $info->hasRapidPVST(), 1,
        'hasRapidPVST__bridge_port_maps_to_up_ifindex__returns_1' );
    $test->_prime_bridge_port_remap( { 1003 => 'down', 3 => 'up' } );
    is( $info->hasRapidPVST(), 0,
        'hasRapidPVST__bridge_port_number_up_but_ifindex_down__returns_0' );
}

sub hasSTP : Tests(1) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_stp( {%MSTP_ROLES} );
    $info->{store}{ieee_stp_version} = { 1 => 'rstp' };
    is( $info->hasSTP(), 0, 'hasSTP__rstp_version__returns_0' );
}

sub hasRSTP : Tests(1) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_stp( {%MSTP_ROLES} );
    $info->{store}{ieee_stp_version} = { 1 => 'rstp' };
    is( $info->hasRSTP(), 0, 'hasRSTP__rstp_version__returns_0' );
}

sub stp_protocols : Tests(4) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_rpvst();
    cmp_deeply( scalar $info->stp_protocols(),
        ['rapid-pvst'],
        'stp_protocols__all_cist_roles_6__returns_rapid_pvst' );

    $test->_prime_stp( {%MSTP_ROLES} );
    cmp_deeply( scalar $info->stp_protocols(),
        ['mstp'], 'stp_protocols__mstp_cist_roles__returns_mstp' );
    $test->_prime_stp( {} );
    cmp_deeply( scalar $info->stp_protocols(),
        ['dot1d'], 'stp_protocols__no_cist_roles__returns_bridge_mib_dot1d' );
    $test->_prime_stp( {%RPVST_ROLES}, {%ALL_DOWN} );
    is( scalar $info->stp_protocols(),
        undef,
        'stp_protocols__every_role_6_every_port_down__returns_nothing' );
}

sub stp_trees : Tests(10) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_rpvst();
    my $trees = $info->stp_trees() || {};
    cmp_deeply( [ sort keys %$trees ],
        [qw/vlan.10 vlan.20/], 'stp_trees__rpvst__lists_enabled_vlans_only' );
    cmp_deeply(
        $trees->{'vlan.10'}{root},
        {   priority   => 4096,
            sys_id_ext => 10,
            mac        => '02:00:00:00:00:01',
            raw        => undef,
        },
        'stp_trees__rpvst_own_root__fills_sys_id_ext'
    );
    cmp_deeply(
        $trees->{'vlan.20'}{root},
        {   priority   => 4096,
            sys_id_ext => undef,
            mac        => '02:00:00:00:00:02',
            raw        => undef,
        },
        'stp_trees__rpvst_other_root__leaves_sys_id_ext_undef'
    );
    cmp_deeply(
        $trees->{'vlan.20'}{bridge},
        {   priority   => 32768,
            sys_id_ext => 20,
            mac        => '02:00:00:00:00:01',
            raw        => undef,
        },
        'stp_trees__rpvst__builds_bridge_from_own_mac'
    );
    cmp_deeply(
        $trees->{'vlan.20'},
        superhashof(
            {   type           => 'vlan',
                id             => 20,
                vlan           => 20,
                protocol       => 'rapid-pvst',
                measured       => 1,
                ports_complete => 1,
                contexts       => [ { kind => 'none' } ],
            }
        ),
        'stp_trees__rpvst__labels_tree_rapid_pvst'
    );

    $test->_prime_stp( {%MSTP_ROLES} );
    is( $info->stp_trees()->{'msti.1'}{measured},
        1, 'stp_trees__mstp_cist_roles__marks_trees_measured' );
    $test->_prime_stp( {} );
    cmp_deeply( [ keys %{ $info->stp_trees() } ],
        ['cist.0'], 'stp_trees__no_cist_roles__returns_bridge_mib_tree' );
    is( $info->stp_trees()->{'cist.0'}{measured},
        0, 'stp_trees__no_cist_roles__marks_bridge_mib_tree_not_measured' );
    $test->_prime_stp( {%MIXED_ROLES}, { 3 => 'down', 769 => 'up' } );
    cmp_deeply(
        [ sort keys %{ $info->stp_trees() } ],
        [qw/cist.0 msti.1 msti.2/],
        'stp_trees__mstp_with_one_port_down__lists_cist_and_mstis'
    );
    $test->_prime_stp( {%RPVST_ROLES}, {%ALL_DOWN} );
    cmp_deeply( $info->stp_trees(), {},
        'stp_trees__all_role_6_every_port_down__returns_empty_hash' );
}

sub stp_trees_complete : Tests(4) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_rpvst();
    is( $info->stp_trees_complete(),
        1, 'stp_trees_complete__rpvst_trees__returns_1' );
    $test->_prime_rpvst();
    $info->{store}{rpvst_v_admin} = { 30 => 'disabled' };
    is( $info->stp_trees_complete(),
        0, 'stp_trees_complete__rpvst_no_enabled_vlan__returns_0' );

    $test->_prime_stp( {} );
    is( $info->stp_trees_complete(),
        0, 'stp_trees_complete__no_cist_roles__returns_0_as_bridge_mib' );
    $test->_prime_stp( {%RPVST_ROLES}, {%ALL_DOWN} );
    is( $info->stp_trees_complete(),
        0, 'stp_trees_complete__every_role_6_every_port_down__returns_0' );
}

sub stp_vlan_map : Tests(3) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_rpvst();
    cmp_deeply(
        scalar $info->stp_vlan_map(),
        { 10 => 'vlan.10', 20 => 'vlan.20' },
        'stp_vlan_map__rpvst__maps_each_vlan_to_its_tree'
    );

    $test->_prime_stp( {%MSTP_ROLES} );
    is( $info->stp_vlan_map()->{20},
        'msti.2', 'stp_vlan_map__mstp_cist_roles__maps_vlan_to_msti' );
    $test->_prime_stp( {%MIXED_ROLES}, { 3 => 'down', 769 => 'up' } );
    is( $info->stp_vlan_map()->{20},
        'msti.2', 'stp_vlan_map__role_6_on_down_port__maps_vlan_to_msti' );
}

sub stp_tree_ports : Tests(8) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_rpvst();
    my $rows = $info->stp_tree_ports('vlan.20') || {};
    cmp_deeply(
        $rows->{770},
        superhashof(
            {   tree_type => 'vlan',
                tree_id   => 20,
                state     => 'blocking',
                role      => 'alternate',
                role_raw  => 'alternate',
                enabled   => undef,
            }
        ),
        'stp_tree_ports__rpvst__returns_port_vlan_row'
    );
    cmp_deeply(
        $rows->{770}{designated_bridge},
        {   priority   => 4096,
            sys_id_ext => undef,
            mac        => '02:00:00:00:00:02',
            raw        => undef,
        },
        'stp_tree_ports__rpvst_root_mac__takes_root_priority'
    );
    cmp_deeply(
        $rows->{769}{designated_bridge},
        {   priority   => undef,
            sys_id_ext => undef,
            mac        => '02:00:00:00:00:09',
            raw        => undef,
        },
        'stp_tree_ports__rpvst_other_mac__keeps_mac_only'
    );
    is( $rows->{770}{designated_port},
        undef, 'stp_tree_ports__rpvst__leaves_designated_port_undef' );

    $test->_prime_stp( {%MSTP_ROLES} );
    is( $info->stp_tree_ports('cist.0')->{769}{role},
        'root', 'stp_tree_ports__mstp_cist_roles__returns_cist_rows' );
    $test->_prime_stp( {} );
    is( $info->stp_tree_ports('cist.0')->{769}{state},
        'blocking',
        'stp_tree_ports__no_cist_roles__returns_bridge_mib_rows' );
    $test->_prime_stp( {%RPVST_ROLES}, {%ALL_DOWN} );
    is( scalar $info->stp_tree_ports('cist.0'),
        undef,
        'stp_tree_ports__every_role_6_every_port_down__returns_nothing' );
    like(
        $info->error(),
        qr/has no tree 'cist\.0'/,
        'stp_tree_ports__every_role_6_every_port_down__sets_error'
    );
}

sub i_stp_state : Tests(2) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_stp( {%RPVST_ROLES} );
    cmp_deeply( $info->i_stp_state(), {},
        'i_stp_state__all_cist_roles_6__returns_empty_hash' );
    $test->_prime_stp( {%MSTP_ROLES} );
    cmp_deeply(
        $info->i_stp_state(),
        { 3 => 'forwarding', 769 => 'blocking' },
        'i_stp_state__mstp_cist_roles__returns_bridge_port_states'
    );
}

sub stp_tree_ports_own_mac : Tests(1) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_rpvst();
    $info->{store}{rpvst_pv_bridge}{'20.5'} = $mac->('020000000001');
    cmp_deeply(
        $info->stp_tree_ports('vlan.20')->{5}{designated_bridge},
        {   priority   => 32768,
            sys_id_ext => 20,
            mac        => '02:00:00:00:00:01',
            raw        => undef,
        },
        'stp_tree_ports__rpvst_own_mac_other_root__takes_own_priority'
    );
}

sub stp_trees_ext_sysid_off : Tests(2) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_rpvst();
    $info->{_rpvst_ext_sysid} = 'false';
    my $tree = $info->stp_trees()->{'vlan.10'};
    is( $tree->{bridge}{sys_id_ext},
        undef, 'stp_trees__rpvst_ext_sysid_off__bridge_has_no_sys_id_ext' );
    is( $tree->{root}{sys_id_ext},
        undef, 'stp_trees__rpvst_ext_sysid_off__own_root_has_no_sys_id_ext' );
}

sub i_edgeport_oper : Tests(5) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_rpvst();
    my %store = (
        iqb_i_vlan         => { '1.3'  => 10, '1.770'  => 20, '1.4'  => 30 },
        bp_index           => { 3      => 3,  4        => 4,  770    => 770 },
        rpvst_pv_edge_oper => { '10.3' => 1,  '20.770' => 2,  '20.3' => 2 },
    );
    foreach my $column ( keys %store ) {
        $info->{"_$column"} = 1;
        $info->{store}{$column} = $store{$column};
    }
    cmp_deeply(
        $info->i_edgeport_oper(),
        { 3 => 1, 770 => 0 },
        'i_edgeport_oper__rpvst__reads_native_vlan_row_only'
    );
    $test->_prime_stp( {%RPVST_ROLES}, {%ALL_DOWN} );
    cmp_deeply( $info->i_edgeport_oper(),
        {}, 'i_edgeport_oper__unknown_mode__returns_empty_hash' );
    $test->_prime_stp( {} );
    $info->{_is_edgeport_oper} = 1;
    $info->{store}{is_edgeport_oper} = { 3 => 1, 769 => 2 };
    cmp_deeply(
        $info->i_edgeport_oper(),
        { 3 => 1, 769 => 0 },
        'i_edgeport_oper__no_cist_roles__returns_bridge_mib_edge_rows'
    );
    $test->_prime_stp( {%MSTP_ROLES} );
    $info->{_ieee_rstp_p_edge_oper} = 1;
    $info->{store}{ieee_rstp_p_edge_oper} = { '1.3' => 1, '1.769' => 2 };
    cmp_deeply(
        $info->i_edgeport_oper(),
        { 3 => 1, 769 => 0 },
        'i_edgeport_oper__mstp__returns_rstp_edge_rows'
    );
    $test->_prime_rpvst();
    $info->{_ieee_rstp_p_edge_admin} = 1;
    $info->{store}{ieee_rstp_p_edge_admin} = { '1.3' => 1, '1.769' => 2 };
    cmp_deeply(
        $info->i_edgeport_admin(),
        { 3 => 1, 769 => 0 },
        'i_edgeport_admin__rpvst__returns_rstp_edge_rows'
    );
}

sub _prime_columns {
    my ( $test, %store ) = @_;
    my $info = $test->{info};
    foreach my $column ( keys %store ) {
        $info->{"_$column"} = 1;
        $info->{store}{$column} = $store{$column};
    }
    return;
}

sub v_name : Tests(3) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_columns(
        iqb_v_name => { '1.1' => 'DEFAULT_VLAN_1', '1.10' => 'VLAN10' },
        v_name     => { 1     => 'Q-BRIDGE 1' },
    );
    cmp_deeply(
        $info->v_name(),
        { 1 => 'DEFAULT_VLAN_1', 10 => 'VLAN10' },
        'v_name__ieee_rows_served__returns_component_one_by_vlan'
    );

    delete $info->{_iqb_v_name};
    delete $info->{store}{iqb_v_name};
    cmp_deeply(
        $info->v_name(),
        { 1 => 'Q-BRIDGE 1' },
        'v_name__ieee_column_not_served__returns_q_bridge_rows'
    );

    $test->_prime_columns( iqb_v_name => { '2.10' => 'VLAN10' } );
    cmp_deeply(
        $info->v_name(),
        { 1 => 'Q-BRIDGE 1' },
        'v_name__no_component_one_rows__returns_q_bridge_rows'
    );
}

sub qb_i_vlan : Tests(2) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_columns(
        iqb_i_vlan => { '1.3' => 10, '1.770' => 20 },
        qb_i_vlan  => { 3     => 1 },
    );
    cmp_deeply(
        $info->qb_i_vlan(),
        { 3 => 10, 770 => 20 },
        'qb_i_vlan__ieee_rows_served__returns_component_one_by_port'
    );

    delete $info->{_iqb_i_vlan};
    delete $info->{store}{iqb_i_vlan};
    cmp_deeply(
        $info->qb_i_vlan(),
        { 3 => 1 },
        'qb_i_vlan__ieee_column_not_served__returns_q_bridge_rows'
    );
}

sub i_vlan_type : Tests(2) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_columns(
        iqb_i_vlan_type => { '1.3' => 'admitAll' },
        qb_i_vlan_type  => { 3     => 'admitOnlyVlanTagged' },
    );
    cmp_deeply(
        $info->i_vlan_type(),
        { 3 => 'admitAll' },
        'i_vlan_type__ieee_rows_served__returns_component_one_by_port'
    );

    delete $info->{_iqb_i_vlan_type};
    delete $info->{store}{iqb_i_vlan_type};
    cmp_deeply(
        $info->i_vlan_type(),
        { 3 => 'admitOnlyVlanTagged' },
        'i_vlan_type__ieee_column_not_served__returns_q_bridge_rows'
    );
}

# One port list per method pair: IEEE8021-Q-BRIDGE-MIB first, Q-BRIDGE-MIB
# second. Port lists are munged into arrays of bits. A column no row serves
# reads undef over SNMP, so it is removed rather than primed empty.
sub _port_list_fallback {
    my ( $test, $method ) = @_;
    my $info = $test->{info};

    $test->_prime_columns(
        "i$method" => { '1.10' => pack( 'H*', '80' ) },
        $method    => { 10     => pack( 'H*', '40' ) },
    );
    cmp_deeply(
        $info->$method(),
        { '1.10' => [ 1, 0, 0, 0, 0, 0, 0, 0 ] },
        "${method}__ieee_rows_served__returns_ieee_rows"
    );

    delete $info->{"_i$method"};
    delete $info->{store}{"i$method"};
    cmp_deeply(
        $info->$method(),
        { 10 => [ 0, 1, 0, 0, 0, 0, 0, 0 ] },
        "${method}__ieee_column_not_served__returns_q_bridge_rows"
    );
    return;
}

sub qb_v_egress : Tests(2) { shift->_port_list_fallback('qb_v_egress') }

sub qb_cv_egress : Tests(2) { shift->_port_list_fallback('qb_cv_egress') }

sub qb_v_untagged : Tests(2) {
    shift->_port_list_fallback('qb_v_untagged');
}

sub qb_cv_untagged : Tests(2) {
    shift->_port_list_fallback('qb_cv_untagged');
}

sub os : Tests(1) {
    my $test = shift;
    is( $test->{info}->os(),
        'arubaos-cx', 'os__any_device__returns_arubaos_cx' );
}

sub os_ver : Tests(2) {
    my $test = shift;
    my $info = $test->{info};
    my $revs = { 1 => 'FL.10.16.1006' };
    no warnings 'redefine';
    local *SNMP::Info::Layer3::ArubaCX::entPhysicalSoftwareRev
        = sub { return $revs };
    is( $info->os_ver(), 'FL.10.16.1006',
        'os_ver__chassis_revision_served__returns_it' );
    $revs = undef;
    is( $info->os_ver(), undef, 'os_ver__not_served__returns_undef' );
}

sub vendor : Tests(3) {
    my $test = shift;
    my $info = $test->{info};
    my $mfg  = { 1 => 'Aruba' };
    no warnings 'redefine';
    local *SNMP::Info::Layer3::ArubaCX::entPhysicalMfgName
        = sub { return $mfg };
    is( $info->vendor(), 'aruba',
        'vendor__manufacturer_served__returns_it_lowercased' );
    $mfg = { 1 => '' };
    is( $info->vendor(), 'aruba',
        'vendor__empty_manufacturer__returns_aruba' );
    $mfg = undef;
    is( $info->vendor(), 'aruba', 'vendor__not_served__returns_aruba' );
}

sub fan : Tests(3) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_columns(
        fan_names  => { '1.1.1' => 'Tray-1/1/1', '1.1.2' => 'Tray-1/1/2' },
        fan_states => { '1.1.1' => 'ok',         '1.1.2' => 'fault' },
    );
    is( $info->fan(),
        'Tray-1/1/1: ok, Tray-1/1/2: fault',
        'fan__names_and_states_served__lists_each_fan'
    );

    $test->_prime_columns( fan_states => { '1.1.1' => 'ok' } );
    is( $info->fan(),
        'Tray-1/1/1: ok, Tray-1/1/2: n/a',
        'fan__state_missing__reports_n_a'
    );

    $test->_prime_columns( fan_names => {}, fan_states => {} );
    is( $info->fan(), '', 'fan__no_fans__returns_empty_string' );
}

sub stack_info : Tests(3) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_columns(
        vsf_prod_names => {
            1 => '6300M 48G CL4 PoE 4SFP56 Swch',
            2 => '6300M 48G CL4 PoE 4SFP56 Swch',
        },
    );
    $info->{_vsf_topology} = 'chain';
    is( $info->stack_info(),
        '6300M (stack of 2)',
        'stack_info__vsf_chain__returns_family_and_member_count'
    );

    $info->{_vsf_topology} = 'standalone';
    is( $info->stack_info(), undef, 'stack_info__standalone__returns_undef' );

    delete $info->{_vsf_topology};
    is( $info->stack_info(), undef, 'stack_info__no_vsf__returns_undef' );
}

sub agg_ports : Tests(2) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_columns(
        raw_ad_lag_ports => { 769 => '1/1/1,1/1/2', 770 => '1/1/3' },
        i_index       => { 1 => 1, 2 => 2, 3 => 3, 769 => 769, 770 => 770 },
        i_description => {
            1   => '1/1/1',
            2   => '1/1/2',
            3   => '1/1/3',
            769 => 'lag1',
            770 => 'lag2'
        },
    );
    cmp_deeply(
        $info->agg_ports(),
        { 1 => 769, 2 => 769, 3 => 770 },
        'agg_ports__comma_separated_member_names__maps_members_to_lag'
    );

    $test->_prime_columns( raw_ad_lag_ports => {} );
    cmp_deeply( $info->agg_ports(), {},
        'agg_ports__no_lags__returns_empty_hash' );
}

sub _prime_pvids {
    my $test = shift;
    $test->_prime_columns(
        iqb_i_vlan => { '1.3' => 10, '1.4' => 0, '1.769' => 0, '1.770' => 1 },
        bp_index   => { 3     => 3,  4     => 4, 769     => 769, 770 => 770 },
    );
    return;
}

sub i_vlan : Tests(2) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_pvids();
    cmp_deeply(
        $info->i_vlan(),
        { 3 => 10, 770 => 1 },
        'i_vlan__pvid_0_served__omits_ports_with_no_native_vlan'
    );
    cmp_deeply(
        $info->qb_i_vlan(),
        { 3 => 10, 4 => 0, 769 => 0, 770 => 1 },
        'qb_i_vlan__pvid_0_served__returns_it_as_served'
    );
}

sub i_untagged : Tests(1) {
    my $test = shift;
    my $info = $test->{info};

    $test->_prime_pvids();
    cmp_deeply(
        $info->i_untagged(),
        { 3 => 10, 770 => 1 },
        'i_untagged__pvid_0_served__omits_ports_with_no_native_vlan'
    );
}

sub vsx_system_mac : Tests(4) {
    my $test = shift;
    my $info = $test->{info};

    $info->{_vsx_system_mac} = '02:00:cb:12:06:00';
    is( $info->vsx_system_mac(),
        '02:00:cb:12:06:00', 'vsx_system_mac__text_form__returns_mac' );
    $info->{_vsx_system_mac} = '02-00-CB-12-06-00';
    is( $info->vsx_system_mac(),
        '02:00:cb:12:06:00',
        'vsx_system_mac__dashed_upper_case__returns_normalized_mac' );
    $info->{_vsx_system_mac} = pack( 'H*', '0200cb120600' );
    is( $info->vsx_system_mac(),
        '02:00:cb:12:06:00', 'vsx_system_mac__octets__returns_mac' );
    $info->{_vsx_system_mac} = 'garbage';
    is( $info->vsx_system_mac(),
        undef, 'vsx_system_mac__not_a_mac__returns_undef' );
}

sub vsx_keepalive_peer : Tests(9) {
    my $test = shift;
    my $info = $test->{info};

    $info->{_vsx_keepalive_peer} = '10.127.255.1';
    is( $info->vsx_keepalive_peer(),
        '10.127.255.1', 'vsx_keepalive_peer__text_form__returns_address' );
    $info->{_vsx_keepalive_peer} = pack( 'C4', 10, 127, 255, 1 );
    is( $info->vsx_keepalive_peer(),
        '10.127.255.1', 'vsx_keepalive_peer__octets__returns_address' );
    $info->{_vsx_keepalive_peer} = '2001:db8:0:0::12';
    is( $info->vsx_keepalive_peer(),
        '2001:db8:0:0:0:0:0:12',
        'vsx_keepalive_peer__ipv6_text_of_octet_length__returns_address' );
    $info->{_vsx_keepalive_peer} = '0.0.0.0';
    is( $info->vsx_keepalive_peer(),
        undef, 'vsx_keepalive_peer__unset_address__returns_undef' );
    $info->{_vsx_keepalive_peer} = ':::';
    is( $info->vsx_keepalive_peer(),
        undef, 'vsx_keepalive_peer__colons_only__returns_undef' );
    $info->{_vsx_keepalive_peer} = '1.2.3.400';
    is( $info->vsx_keepalive_peer(),
        undef, 'vsx_keepalive_peer__octet_out_of_range__returns_undef' );
    $info->{_vsx_keepalive_peer} = '2001:DB8::12';
    my $from_text = $info->vsx_keepalive_peer();
    $info->{_vsx_keepalive_peer}
        = pack( 'H*', '20010db8000000000000000000000012' );
    is( $from_text,
        $info->vsx_keepalive_peer(),
        'vsx_keepalive_peer__ipv6_text_and_octets__return_same_form'
    );
    ok( defined $from_text,
        'vsx_keepalive_peer__ipv6_text__returns_address' );
    $info->{_vsx_keepalive_peer} = '';
    is( $info->vsx_keepalive_peer(),
        undef, 'vsx_keepalive_peer__empty__returns_undef' );
}

sub vsx_role : Tests(1) {
    my $test = shift;
    $test->{info}{_vsx_role} = 'primary';
    is( $test->{info}->vsx_role(),
        'primary', 'vsx_role__served__returns_role' );
}

sub vsx_isl_port : Tests(1) {
    my $test = shift;
    $test->{info}{_vsx_isl_port} = 'lag256';
    is( $test->{info}->vsx_isl_port(),
        'lag256', 'vsx_isl_port__served__returns_interface_name' );
}

sub vsx_isl_state : Tests(1) {
    my $test = shift;
    $test->{info}{_vsx_isl_state} = 'inSync';
    is( $test->{info}->vsx_isl_state(),
        'inSync', 'vsx_isl_state__served__returns_state' );
}

sub vsx_keepalive_state : Tests(1) {
    my $test = shift;
    $test->{info}{_vsx_keepalive_state} = 'inSyncEstablished';
    is( $test->{info}->vsx_keepalive_state(),
        'inSyncEstablished', 'vsx_keepalive_state__served__returns_state' );
}

sub vsx_agg_type : Tests(1) {
    my $test = shift;
    $test->_prime_columns(
        vsx_agg_type => { 778 => 'multiChassis', 788 => 'point2Point' } );
    cmp_deeply(
        $test->{info}->vsx_agg_type(),
        { 778 => 'multiChassis', 788 => 'point2Point' },
        'vsx_agg_type__served__returns_type_by_ifindex'
    );
}

# A VSX primary with multi-chassis LAGs lag10 and lag20 and ISL lag256
sub _prime_vsx {
    my ( $test, %globals ) = @_;
    my $info = $test->{info};

    my %scalars = (
        vsx_role            => 'primary',
        vsx_system_mac      => '02:00:cb:12:06:00',
        vsx_isl_port        => 'lag256',
        vsx_isl_state       => 'inSync',
        vsx_keepalive_peer  => '10.127.255.1',
        vsx_keepalive_state => 'inSyncEstablished',
        %globals,
    );
    $info->{"_$_"} = $scalars{$_} for keys %scalars;
    delete $info->{"_$_"} for grep { !defined $scalars{$_} } keys %scalars;
    $test->_prime_columns(
        vsx_agg_type  => { 778 => 'multiChassis', 788 => 'multiChassis' },
        i_index       => { 778 => 778,     788 => 788,     1024 => 1024 },
        i_description => { 778 => 'lag10', 788 => 'lag20', 1024 => 'lag256' },
    );
    return;
}

sub mlag_domains : Tests(1) {
    my $test = shift;
    $test->_prime_vsx();
    cmp_deeply(
        $test->{info}->mlag_domains(),
        {   vsx => {
                kind       => 'vsx',
                system_mac => '02:00:cb:12:06:00',
                role       => 'primary',
                peer       => '10.127.255.1',
                peer_link  => 1024,
                status     => 'inSync',
                sources    => {
                    system_mac =>
                        'ARUBAWIRED-VSX-MIB::arubaWiredVsxDeviceOperSystemID',
                    role => 'ARUBAWIRED-VSX-MIB::arubaWiredVsxDeviceRole',
                    peer =>
                        'ARUBAWIRED-VSX-MIB::arubaWiredVsxKeepAlivePeerIPAddr',
                    peer_link => 'ARUBAWIRED-VSX-MIB::arubaWiredVsxIslPort',
                    status => 'ARUBAWIRED-VSX-MIB::arubaWiredVsxIslOperState',
                },
            }
        },
        'mlag_domains__vsx_pair__returns_vsx_domain'
    );
}

sub mlag_domains__standalone__returns_empty_hash : Tests(1) {
    my $test = shift;
    cmp_deeply( $test->{info}->mlag_domains(),
        {}, 'mlag_domains__standalone__returns_empty_hash' );
}

sub mlag_domains__role_not_configured_isl_zero__returns_empty_hash : Tests(1)
{
    my $test = shift;
    $test->_prime_vsx( vsx_role => 'notConfigured', vsx_isl_port => '0' );
    cmp_deeply( $test->{info}->mlag_domains(),
        {},
        'mlag_domains__role_not_configured_isl_zero__returns_empty_hash' );
}

sub mlag_domains__isl_name_unknown__peer_link_absent : Tests(3) {
    my $test = shift;
    $test->_prime_vsx( vsx_isl_port => 'lag99' );
    my $domain = $test->{info}->mlag_domains()->{vsx};
    ok( $domain, 'mlag_domains__isl_name_unknown__domain_still_reported' );
    ok( !exists $domain->{peer_link},
        'mlag_domains__isl_name_unknown__peer_link_absent' );
    ok( !exists $domain->{sources}{peer_link},
        'mlag_domains__isl_name_unknown__peer_link_source_absent' );
}

sub mlag_domains__peer_not_parseable__peer_absent : Tests(3) {
    my $test = shift;
    $test->_prime_vsx( vsx_keepalive_peer => '' );
    my $domain = $test->{info}->mlag_domains()->{vsx};
    ok( $domain, 'mlag_domains__peer_not_parseable__domain_still_reported' );
    ok( !exists $domain->{peer},
        'mlag_domains__peer_not_parseable__peer_absent' );
    ok( !exists $domain->{sources}{peer},
        'mlag_domains__peer_not_parseable__peer_source_absent' );
}

sub lag_groups__vsx_multichassis__adds_mc : Tests(2) {
    my $test = shift;
    $test->_prime_vsx();
    my $record = $test->{info}->lag_groups()->{778};
    cmp_deeply(
        $record->{mc},
        { kind => 'vsx', group => 10, domain => 'vsx', state => undef },
        'lag_groups__vsx_multichassis__adds_mc'
    );
    is( $record->{sources}{mc},
        'ARUBAWIRED-VSX-MIB::arubaWiredVsxAggregatorType',
        'lag_groups__vsx_multichassis__names_mc_source'
    );
}

sub lag_groups__vsx_isl__marked_peer_link : Tests(3) {
    my $test = shift;
    $test->_prime_vsx();
    my $groups = $test->{info}->lag_groups();
    is( $groups->{1024}{peer_link},
        1, 'lag_groups__vsx_isl__marked_peer_link' );
    is( $groups->{1024}{sources}{peer_link},
        'ARUBAWIRED-VSX-MIB::arubaWiredVsxIslPort',
        'lag_groups__vsx_isl__names_peer_link_source'
    );
    ok( !exists $groups->{778}{peer_link},
        'lag_groups__vsx_multichassis__not_marked_peer_link' );
}

sub lag_groups__vsx_not_in_lag_mib__gets_record : Tests(1) {
    my $test = shift;
    $test->_prime_vsx();
    is( $test->{info}->lag_groups()->{788}{mc}{group},
        20, 'lag_groups__vsx_not_in_lag_mib__gets_record' );
}

sub lag_groups__lag_name_not_lagN__group_is_name : Tests(1) {
    my $test = shift;
    $test->_prime_vsx();
    $test->_prime_columns( i_description =>
            { 778 => 'uplink', 788 => 'lag20', 1024 => 'lag256' } );
    is( $test->{info}->lag_groups()->{778}{mc}{group},
        'uplink', 'lag_groups__lag_name_not_lagN__group_is_name' );
}

sub lag_groups__no_domain__no_mc : Tests(2) {
    my $test = shift;
    $test->_prime_vsx( vsx_role => undef, vsx_isl_port => undef );
    my $groups = $test->{info}->lag_groups();
    cmp_deeply( $test->{info}->mlag_domains(),
        {}, 'lag_groups__no_domain__domain_absent' );
    ok( !( $groups->{778} && $groups->{778}{mc} ),
        'lag_groups__no_domain__no_mc' );
}

sub lag_groups__point2point__no_mc : Tests(2) {
    my $test = shift;
    $test->_prime_vsx();
    $test->_prime_columns(
        vsx_agg_type => { 778 => 'point2Point', 788 => 'multiChassis' } );
    my $groups = $test->{info}->lag_groups();
    ok( $groups->{788}{mc}, 'lag_groups__multichassis__still_gets_mc' );
    ok( !( $groups->{778} && $groups->{778}{mc} ),
        'lag_groups__point2point__no_mc'
    );
}

sub lag_groups_complete__vsx_walk_incomplete__returns_0 : Tests(1) {
    my $test = shift;
    $test->_prime_vsx();
    $test->{info}{walk_status}{vsx_agg_type} = { complete => 0 };
    is( $test->{info}->lag_groups_complete(),
        0, 'lag_groups_complete__vsx_walk_incomplete__returns_0' );
}

1;
