# Test::SNMP::Info::Layer3::SONiC
#
# Copyright (c) 2026 by SNMP::Info Developers.
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
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package Test::SNMP::Info::Layer3::SONiC;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::SONiC;

my $COMMUNITY_DESCR
    = 'SONiC Software Version: SONiC.202505.20-8a1d2f3e - HwSku: '
    . 'Force10-S6000 - Distribution: Debian 12.11 - Kernel: 6.1.0-29-amd64';
my $ENTERPRISE_DESCR
    = 'SONiC Software Version: SONiC.4.4.1-Enterprise_Base - HwSku: '
    . 'Accton-AS7726-32X - Distribution: Debian 11.11 - '
    . 'Kernel: 5.10.0-21-amd64';

# Some enterprise releases wrap sysDescr in double quotes, with a newline.
my $QUOTED_DESCR
    = qq("SONiC Software Version: SONiC.4.4.1-Lite - HwSku: DELL-E3248P - )
    . qq(Distribution: Debian 11.11 - Kernel: 5.10.0-21-amd64\n");

# A community build: dot1dBasePortTable is empty and dot1qTpFdbPort holds
# the ifIndex. EthernetN is ifIndex N+1, PortChannelN is 1000+N.
sub _community_cache {
    return {
        '_layers'        => 72,
        '_description'   => $COMMUNITY_DESCR,
        '_id'            => '.1.3.6.1.4.1.8072.3.2.10',
        '_i_index'       => 1,
        '_i_description' => 1,
        '_qb_fw_port'    => 1,
        'store'          => {
            'i_index'       => { 1 => 0, 9 => 8, 1001 => 1000 },
            'i_description' => {
                1    => 'fortyGigE0/0',
                9    => 'fortyGigE0/8',
                1001 => 'PortChannel1'
            },
            'qb_fw_port' => {
                '10.2.0.94.16.1.17' => 9,
                '10.2.0.94.16.1.20' => 1001,
            },
        },
    };
}

# An enterprise build: dot1dBasePortTable numbers the bridge ports from 0,
# and dot1qTpFdbPort still holds the ifIndex.
sub _enterprise_cache {
    return {
        '_description'   => $QUOTED_DESCR,
        '_id'            => '.1.3.6.1.4.1.4413.1.2.1.2.34',
        '_i_description' => 1,
        '_bp_index'      => 1,
        '_qb_fw_port'    => 1,
        '_qb_i_vlan'     => 1,
        'store'          => {
            'i_description' => {
                1    => 'Eth1/1',
                25   => 'Eth1/25',
                53   => 'Eth1/53',
                57   => 'Eth1/54',
                1000 => 'eth0',
            },
            'bp_index'   => { 0 => 1,   24 => 25, 52 => 53, 56 => 57 },
            'qb_i_vlan'  => { 0 => 220, 24 => 0,  52 => 0,  56 => 0 },
            'qb_fw_port' => {
                '1.0.94.16.2.0.1' => 25,
                '1.0.94.16.2.0.2' => 53,
                '1.0.94.16.2.0.3' => 1000,
            },
        },
    };
}

sub setup : Tests(setup) {
    my $test = shift;
    $test->SUPER::setup;

    $test->{info}->cache( _community_cache() );
}

sub device_type : Tests(7) {
    my $test = shift;

    is( $test->{info}->device_type(),
        'SNMP::Info::Layer3::SONiC',
        q(Community build with the Net-SNMP sysObjectID selects SONiC) );

    my %cases = (
        'Enterprise build with a Broadcom sysObjectID selects SONiC' =>
            [ $ENTERPRISE_DESCR, '.1.3.6.1.4.1.4413.1.2.1.2.34', 'SONiC' ],
        'Enterprise build with a Dell sysObjectID selects SONiC' => [
            $ENTERPRISE_DESCR, '.1.3.6.1.4.1.674.10895.5000.300.1.9',
            'SONiC'
        ],
        'Quoted sysDescr selects SONiC' =>
            [ $QUOTED_DESCR, '.1.3.6.1.4.1.4413.1.2.1.2.34', 'SONiC' ],
        'Other Net-SNMP host stays NetSNMP' => [
            'Linux host 6.1.0-29-amd64 #1 SMP x86_64',
            '.1.3.6.1.4.1.8072.3.2.10',
            'NetSNMP'
        ],
        'Dell PowerConnect stays Dell' => [
            'PowerConnect 6248, 3.3.9.1', '.1.3.6.1.4.1.674.10895.3024',
            'Dell'
        ],
        'SonicWALL stays SonicWALL' => [
            'SonicWALL TZ 400 (SonicOS Enhanced 6.5.4.4)',
            '.1.3.6.1.4.1.8741.1', 'SonicWALL'
        ],
    );
    foreach my $name ( sort keys %cases ) {
        my ( $descr, $id, $class ) = @{ $cases{$name} };
        $test->{info}->clear_cache();
        $test->{info}->cache(
            { '_layers' => 72, '_description' => $descr, '_id' => $id } );
        is( $test->{info}->device_type(),
            "SNMP::Info::Layer3::$class", $name );
    }
}

sub layers : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'layers' );
    is( $test->{info}->layers(),
        '01001110', q(Layers 2 and 3 added to the served sysServices) );

    $test->{info}->clear_cache();
    is( $test->{info}->layers(),
        '00000110', q(No sysServices gives layers 2 and 3) );
}

sub vendor : Tests(6) {
    my $test = shift;

    can_ok( $test->{info}, 'vendor' );
    is( $test->{info}->vendor(), 'dell', q(Force10 SKU gives dell) );

    $test->{info}{_description} = $ENTERPRISE_DESCR;
    is( $test->{info}->vendor(), 'accton', q(Accton SKU gives accton) );

    $test->{info}{_description} = $QUOTED_DESCR;
    is( $test->{info}->vendor(), 'dell', q(DELL SKU gives dell) );

    $test->{info}{_description}
        = 'SONiC Software Version: SONiC.202505.20-8a1d2f3e - HwSku: '
        . 'ACS-MSN2700 - Distribution: Debian 12.11';
    is( $test->{info}->vendor(), 'sonic', q(Unknown SKU prefix gives sonic) );

    $test->{info}->clear_cache();
    is( $test->{info}->vendor(), 'sonic', q(No sysDescr gives sonic) );
}

sub os : Tests(2) {
    my $test = shift;

    can_ok( $test->{info}, 'os' );
    is( $test->{info}->os(), 'sonic', q(OS returns 'sonic') );
}

sub os_ver : Tests(5) {
    my $test = shift;

    can_ok( $test->{info}, 'os_ver' );
    is( $test->{info}->os_ver(),
        '202505.20-8a1d2f3e', q(Community version from sysDescr) );

    $test->{info}{_description} = $ENTERPRISE_DESCR;
    is( $test->{info}->os_ver(),
        '4.4.1-Enterprise_Base', q(Enterprise version keeps its edition) );

    $test->{info}{_description} = $QUOTED_DESCR;
    is( $test->{info}->os_ver(), '4.4.1-Lite', q(Quoted sysDescr parses) );

    $test->{info}->clear_cache();
    is( $test->{info}->os_ver(), undef, q(No sysDescr returns undef) );
}

sub model : Tests(4) {
    my $test = shift;

    can_ok( $test->{info}, 'model' );
    is( $test->{info}->model(), 'Force10-S6000', q(Model is the HwSku) );

    $test->{info}{_description} = $QUOTED_DESCR;
    is( $test->{info}->model(), 'DELL-E3248P', q(Quoted sysDescr parses) );

    $test->{info}->clear_cache();
    is( $test->{info}->model(), undef, q(No data returns undef) );
}

sub serial : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'serial' );

    # entity_derived_serial fetches e_serial with a partial, which reads
    # the mocked session rather than the cache.
    $test->{info}->cache(
        {   '_e_parent' => 1,
            '_e_class'  => 1,
            'store'     => {
                'e_parent' => { 1 => 0 },
                'e_class'  => { 1 => 'chassis' },
            },
        }
    );
    $test->{info}{sess}{Data} = { 'ENTITY-MIB::entPhysicalSerialNum' =>
            { 1 => 'TW0000000000000000001' }, };
    is( $test->{info}->serial(),
        'TW0000000000000000001', q(Serial from the ENTITY-MIB chassis) );

    $test->{info}->clear_cache();
    is( $test->{info}->serial(), undef, q(No data returns undef) );
}

sub i_index : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'i_index' );
    cmp_deeply(
        $test->{info}->i_index(),
        { 1 => 1, 9 => 9, 1001 => 1001 },
        q(Each row maps to itself, not to the served ifIndex value)
    );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->i_index(), {}, q(No data returns empty hash) );
}

sub interfaces__community_build__keyed_by_row : Tests(1) {
    my $test = shift;

    cmp_deeply(
        $test->{info}->interfaces(),
        { 1 => 'fortyGigE0/0', 9 => 'fortyGigE0/8', 1001 => 'PortChannel1' },
        q(Interfaces keyed by row)
    );
}

sub bp_index : Tests(4) {
    my $test = shift;

    can_ok( $test->{info}, 'bp_index' );
    cmp_deeply(
        $test->{info}->bp_index(),
        { 1 => 1, 9 => 9, 1001 => 1001 },
        q(No dot1dBasePortTable maps each interface to itself)
    );

    $test->{info}->clear_cache();
    $test->{info}->cache( _enterprise_cache() );
    cmp_deeply(
        $test->{info}->bp_index(),
        { 0 => 1, 24 => 25, 52 => 53, 56 => 57 },
        q(Served dot1dBasePortTable is kept)
    );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->bp_index(), {},
        q(No data returns empty hash) );
}

sub fw_port : Tests(4) {
    my $test = shift;

    can_ok( $test->{info}, 'fw_port' );
    cmp_deeply(
        $test->{info}->fw_port(),
        { '10.2.0.94.16.1.17' => 9, '10.2.0.94.16.1.20' => 1001 },
        q(Community ifIndex values are their own bridge ports)
    );

    $test->{info}->clear_cache();
    $test->{info}->cache( _enterprise_cache() );
    cmp_deeply(
        $test->{info}->fw_port(),
        { '1.0.94.16.2.0.1' => 24, '1.0.94.16.2.0.2' => 52 },
        q(Enterprise ifIndex values map back to bridge ports; eth0 has none)
    );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->fw_port(), {}, q(No data returns empty hash) );
}

sub fw_port__enterprise_build__joins_interfaces : Tests(1) {
    my $test = shift;

    $test->{info}->clear_cache();
    $test->{info}->cache( _enterprise_cache() );
    my $fw_port    = $test->{info}->fw_port();
    my $bp_index   = $test->{info}->bp_index();
    my $interfaces = $test->{info}->interfaces();

    cmp_deeply(
        {   map { $_ => $interfaces->{ $bp_index->{ $fw_port->{$_} } } }
                keys %$fw_port
        },
        { '1.0.94.16.2.0.1' => 'Eth1/25', '1.0.94.16.2.0.2' => 'Eth1/53' },
        q(Each entry reaches the port dot1qTpFdbPort names)
    );
}

sub at_netaddr : Tests(5) {
    my $test = shift;

    can_ok( $test->{info}, 'at_netaddr' );

    # ipNetToMediaTable keyed by SONiC's own VLAN index, PhysAddress only,
    # beside ipNetToPhysicalTable keyed by the kernel's ifindex
    $test->{info}->cache(
        {   '_at_paddr'         => 1,
            '_ip_n2p_phys_addr' => 1,
            'store'             => {
                'at_paddr' => {
                    '2010.192.0.2.11'  => pack( 'H*', '02005e100111' ),
                    '2020.192.0.2.140' => pack( 'H*', '02005e100112' ),
                },
                'ip_n2p_phys_addr' => {
                    '37.1.4.192.0.2.11'  => pack( 'H*', '02005e100111' ),
                    '39.1.4.192.0.2.140' => pack( 'H*', '02005e100112' ),
                },
            },
        }
    );
    cmp_deeply(
        $test->{info}->at_netaddr(),
        {   '2010.192.0.2.11'  => '192.0.2.11',
            '2020.192.0.2.140' => '192.0.2.140'
        },
        q(Addresses from the ipNetToMediaTable index, keyed like at_paddr)
    );

    $test->{info}->clear_cache();
    $test->{info}->cache(
        {   '_ip_n2p_phys_addr' => 1,
            'store'             => {
                'ip_n2p_phys_addr' =>
                    { '1000.1.4.192.0.2.1' => pack( 'H*', '02005e100101' ) },
            },
        }
    );
    cmp_deeply(
        $test->{info}->at_netaddr(),
        { '1000.192.0.2.1' => '192.0.2.1' },
        q(ipNetToPhysicalTable alone gives addresses keyed like at_paddr)
    );

    $test->{info}->clear_cache();
    $test->{info}->cache(
        {   '_old_at_paddr' => 1,
            'store'         => {
                'old_at_paddr' =>
                    { '2.1.192.0.2.1' => pack( 'H*', '02005e100101' ) },
            },
        }
    );
    cmp_deeply(
        $test->{info}->at_netaddr(),
        { '2.1.192.0.2.1' => '192.0.2.1' },
        q(atTable rows keyed like at_paddr)
    );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->at_netaddr(),
        {}, q(No data returns empty hash) );
}

# lldpRemTable under time mark 0, lldpRemManAddrTable under a later one,
# and MAC chassis IDs served as text
sub _lldp_cache {
    return {
        '_i_description'    => 1,
        '_lldp_rem_id_type' => 1,
        '_lldp_rem_id'      => 1,
        '_lldp_rman_addr'   => 1,
        'store'             => {
            'i_description' => { 1 => 'fortyGigE0/0', 5 => 'fortyGigE0/4' },
            'lldp_rem_id_type' => {
                '0.1.1' => 'macAddress',
                '0.5.1' => 'macAddress',
                '0.9.2' => 'local',
            },
            'lldp_rem_id' => {
                '0.1.1' => '02:00:5e:10:00:a1',
                '0.5.1' => pack( 'H*', '02005e1000a2' ),
                '0.9.2' => 'host-a',
            },
            'lldp_rman_addr' => { '62.1.1.1.4.192.0.2.2' => 'ifIndex' },
        },
    };
}

sub lldp_loc_id_type : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'lldp_loc_id_type' );

    $test->{info}->cache(
        {   '_lldp_loc_id_type'  => undef,
            '_sonic_loc_id_type' => 'macAddress',
        }
    );
    is( $test->{info}->lldp_loc_id_type(),
        'macAddress', q(Subtype without its .0 instance is read) );

    $test->{info}{_lldp_loc_id_type} = 'local';
    is( $test->{info}->lldp_loc_id_type(),
        'local', q(Subtype with its .0 instance is preferred) );
}

sub lldp_loc_id_os : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'lldp_loc_id_os' );

    $test->{info}->cache(
        {   '_lldp_loc_id_os'  => undef,
            '_sonic_loc_id_os' => '02:00:5e:10:00:0c',
        }
    );
    is( $test->{info}->lldp_loc_id_os(),
        '02:00:5e:10:00:0c', q(Chassis ID without its .0 instance is read) );

    $test->{info}{_lldp_loc_id_os} = 'switch-a';
    is( $test->{info}->lldp_loc_id_os(),
        'switch-a', q(Chassis ID with its .0 instance is preferred) );
}

sub lldp_loc_id : Tests(4) {
    my $test = shift;

    can_ok( $test->{info}, 'lldp_loc_id' );

    $test->{info}->cache(
        {   '_lldp_loc_id_type' => 'macAddress',
            '_lldp_loc_id_os'   => '02:00:5E:10:00:0A',
        }
    );
    is( $test->{info}->lldp_loc_id(),
        '02:00:5e:10:00:0a', q(Text MAC chassis ID reads) );

    $test->{info}{_lldp_loc_id_os} = pack( 'H*', '02005e10000b' );
    is( $test->{info}->lldp_loc_id(),
        '02:00:5e:10:00:0b', q(Octet MAC chassis ID reads) );

    $test->{info}->clear_cache();
    is( $test->{info}->lldp_loc_id(), undef, q(No data returns undef) );
}

sub mac : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'mac' );

    $test->{info}->cache(
        {   '_lldp_loc_id_type' => 'macAddress',
            '_lldp_loc_id_os'   => '02:00:5e:10:00:0a',
        }
    );
    is( $test->{info}->mac(),
        '02:00:5e:10:00:0a', q(MAC is the LLDP chassis ID) );

    $test->{info}{_lldp_loc_id_type} = 'local';
    $test->{info}{_lldp_loc_id_os}   = 'switch-a';
    is( $test->{info}->mac(),
        undef, q(Non-MAC chassis ID falls back to the inherited mac) );
}

sub lldp_id : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'lldp_id' );

    $test->{info}->clear_cache();
    $test->{info}->cache( _lldp_cache() );
    cmp_deeply(
        $test->{info}->lldp_id(),
        {   '0.1.1' => '02:00:5e:10:00:a1',
            '0.5.1' => '02:00:5e:10:00:a2',
            '0.9.2' => 'host-a',
        },
        q(Text and octet MAC chassis IDs both read)
    );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->lldp_id(), {}, q(No data returns empty hash) );
}

sub lldp_ip__man_addr_under_later_time_mark__joins_neighbor : Tests(1) {
    my $test = shift;

    $test->{info}->clear_cache();
    $test->{info}->cache( _lldp_cache() );
    cmp_deeply(
        $test->{info}->lldp_ip(),
        { '0.1.1' => '192.0.2.2', '0.5.1' => '0.0.0.0' },
        q(Management address joins its neighbor across time marks)
    );
}

sub i_vlan : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'i_vlan' );

    $test->{info}->clear_cache();
    $test->{info}->cache( _enterprise_cache() );
    cmp_deeply(
        $test->{info}->i_vlan(),
        { 1 => 220 },
        q(Ports with a dot1qPvid of 0 are left out)
    );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->i_vlan(), {}, q(No data returns empty hash) );
}

sub i_untagged : Tests(2) {
    my $test = shift;

    can_ok( $test->{info}, 'i_untagged' );

    $test->{info}->clear_cache();
    $test->{info}->cache( _enterprise_cache() );
    cmp_deeply(
        $test->{info}->i_untagged(),
        { 1 => 220 },
        q(Ports with a dot1qPvid of 0 are left out)
    );
}

sub i_vlan_membership : Tests(2) {
    my $test = shift;

    can_ok( $test->{info}, 'i_vlan_membership' );
    cmp_deeply( $test->{info}->i_vlan_membership(),
        {}, q(VLAN port lists are not read) );
}

sub i_vlan_membership_untagged : Tests(2) {
    my $test = shift;

    can_ok( $test->{info}, 'i_vlan_membership_untagged' );
    cmp_deeply( $test->{info}->i_vlan_membership_untagged(),
        {}, q(VLAN port lists are not read) );
}

1;
