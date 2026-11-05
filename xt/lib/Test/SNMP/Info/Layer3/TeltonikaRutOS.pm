# Test::SNMP::Info::Layer3::TeltonikaRutOS
#
# Copyright (c) 2026 The SNMP::Info Developers
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
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package Test::SNMP::Info::Layer3::TeltonikaRutOS;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::TeltonikaRutOS;

my $PRODUCT_OID = '.1.3.6.1.4.1.48690.1.3.0';

sub setup : Tests(setup) {
    my $test = shift;
    $test->SUPER::setup;

    _set_device($test, '.1.3.6.1.4.1.8072.3.2.10');
    _set_oid_values($test, {
        $PRODUCT_OID => 'RUTX1100XXXX',
    });
    $test->{info}->cache({
        '_serial1'             => 'SYNTHETIC-SERIAL-001',
        '_teltonika_model'     => 'RUTX1100XXXX',
        '_teltonika_firmware'  => 'RUTX_R_00.07.22.3',
    });
}

sub _set_device {
    my ($test, $id, $description) = @_;
    $test->{info}->clear_cache;
    $test->{info}->cache({
        '_layers'      => 4,
        '_description' => $description
            // 'Linux test-router 5.10.0 #1 SMP x86_64',
        '_id'          => $id,
        'store'        => {},
    });
}

sub _set_oid_values {
    my ($test, $values) = @_;
    $test->mock_session->{teltonika_oid_values} = $values;
    $test->mock_session->{teltonika_get_calls} = [];
    $test->mock_session->mock(
        'get',
        sub {
            my ($session, $oid) = @_;
            push @{ $session->{teltonika_get_calls} }, $oid;
            return $session->{teltonika_oid_values}{$oid};
        }
    );
}

sub device_type : Tests(+19) {
    my $test = shift;

    my @modern_products = qw(
        RUT200000000
        RUTX1100XXXX
        RUTXR10000000
        RUTM50000000
        RUTC50000000
        TRB500000000
        OTD140000000
        TCR100000000
        TSW212000000
        TAP200000000
    );

    foreach my $product (@modern_products) {
        _set_device($test, '.1.3.6.1.4.1.8072.3.2.10');
        _set_oid_values($test, { $PRODUCT_OID => $product });
        is($test->{info}->device_type(), 'SNMP::Info::Layer3::TeltonikaRutOS',
            "$product detected by modern product code with generic sysObjectID");
    }

    _set_device($test, '.1.3.6.1.4.1.8072.3.2.10');
    _set_oid_values($test, {});
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::NetSNMP',
        'Generic Net-SNMP device without Teltonika product code stays generic');
    $test->{info}->device_type() for 1 .. 2;
    is(scalar(grep { /^\.1\.3\.6\.1\.4\.1\.48690\./ }
            @{ $test->mock_session->{teltonika_get_calls} }), 1,
        'Generic Net-SNMP device is probed once per object, not per call');

    _set_device($test, '.1.3.6.1.4.1.8072.3.2.10');
    _set_oid_values($test, { $PRODUCT_OID => 'RUTX1100XXXX' });
    $test->{info}->offline(1);
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::NetSNMP',
        'Offline Net-SNMP device without cached product code stays generic');
    is_deeply($test->mock_session->{teltonika_get_calls}, [],
        'Offline device receives no Teltonika probes');
    $test->{info}->offline(0);

    _set_device($test, '.1.3.6.1.4.1.8072.3.2.11');
    _set_oid_values($test, {});
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::NetSNMP',
        'Neighboring Net-SNMP product keeps its generic class');
    is_deeply($test->mock_session->{teltonika_get_calls}, [],
        'Neighboring Net-SNMP product receives no Teltonika probes');

    # TSW212 on TSW2_R_00.01.02.2 reports the PROFINET enterprise
    # (PROFIBUS Nutzerorganisation) as its sysObjectID.
    my $tsw212_descr = 'TSW212 V1.0               TSW21200XXXX         '
        . '6001244780           1 V  1  0  0';
    _set_device($test, '.1.3.6.1.4.1.24686', $tsw212_descr);
    _set_oid_values($test, { $PRODUCT_OID => 'TSW21200XXXX' });
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::TeltonikaRutOS',
        'TSW212 with the PROFINET sysObjectID is detected by product code');

    _set_device($test, '.1.3.6.1.4.1.24686', 'PROFINET IO device V2.1');
    _set_oid_values($test, {});
    isnt($test->{info}->device_type(), 'SNMP::Info::Layer3::TeltonikaRutOS',
        'Other PROFINET device is not taken for a Teltonika switch');
    is_deeply($test->mock_session->{teltonika_get_calls}, [],
        'Other PROFINET device receives no Teltonika probes');
}

sub vendor : Tests(1) {
    my $test = shift;
    is($test->{info}->vendor(), 'teltonika', 'Vendor');
}

sub os : Tests(1) {
    my $test = shift;
    is($test->{info}->os(), 'rutos', 'OS');
}

sub model : Tests(2) {
    my $test = shift;
    my $info = $test->{info};
    is($info->model(), 'RUTX1100XXXX', 'Product code');
    $info->cache({ '_teltonika_model' => '' });
    is($info->model(), SNMP::Info::Layer3::model($info),
        'Unknown product falls back to inherited model');
}

sub os_ver : Tests(2) {
    my $test = shift;
    my $info = $test->{info};
    is($info->os_ver(), 'RUTX_R_00.07.22.3', 'RutOS firmware');
    $info->cache({ '_teltonika_firmware' => '' });
    is($info->os_ver(), '5.10.0', 'Missing firmware falls back to Net-SNMP');
}

sub serial : Tests(1) {
    my $test = shift;
    is($test->{info}->serial(), 'SYNTHETIC-SERIAL-001', 'Serial');
}

sub base_class : Tests(1) {
    isa_ok(shift->{info}, 'SNMP::Info::Layer3::NetSNMP');
}

sub i_ignore : Tests(1) {
    my $info = shift->{info};
    $info->cache({
        '_i_index' => 1,
        '_i_description' => 1,
        'store' => {
            'i_index' => { 1 => 1, 2 => 2, 3 => 3 },
            'i_description' => { 1 => 'lo', 2 => 'lo0', 3 => 'eth0' },
        },
    });
    is_deeply($info->i_ignore(), { 1 => 1, 2 => 1 },
        'Inherited Net-SNMP behavior ignores loopback interfaces');
}

sub uptime : Tests(1) {
    my $info = shift->{info};
    $info->cache({ '_hrSystemUptime' => 123456 });
    is($info->uptime(), 123456,
        'Inherited Net-SNMP behavior uses system uptime');
}


# The pVlanTable of a TSW202 on TSW2_R_00.01.06.3 and 00.01.10.4: the
# access ports untagged in VLAN 1400, the SFP uplinks untagged in VLAN 1
# and tagged in 1400. A VLAN with no ports of a kind reads "None".
my %TSW_VLAN_STORE = (
    'teltonika_vlan_name' => { 1 => 'vlan1', 2 => 'vlan2' },
    'teltonika_vlan_id'   => { 1 => 1,       2 => 1400 },
    'teltonika_vlan_untagged' => {
        1 => 'sfp1:u sfp2:u',
        2 => join( ' ', map {"port$_:u"} 1 .. 8 ),
    },
    'teltonika_vlan_tagged' => { 1 => 'None', 2 => 'sfp1:t sfp2:t' },
);

my %TSW_NO_VLAN_TABLE = (
    'teltonika_vlan_name'     => {},
    'teltonika_vlan_id'       => {},
    'teltonika_vlan_untagged' => {},
    'teltonika_vlan_tagged'   => {},
);

# ifIndex 3 to 10 are port1 to port8, 11 and 12 the SFP ports.
my @TSW_ACCESS_IFINDEX = ( 3 .. 10 );

# Shaped as a TSW202: ifDescr numbers port1 to sfp2 from ifIndex 3, and
# the Teltonika port table numbers the same ports from 1, as the bridge does.
sub _tsw_cache {
    my ( $info, %store ) = @_;
    my @ports = ( map( {"port$_"} 1 .. 8 ), 'sfp1', 'sfp2' );
    my %i_description = (
        1 => 'lo', 2 => 'eth0',
        ( map { ( $_ + 3 ) => $ports[$_] } 0 .. $#ports ),
        13 => 'br0', 14 => 'br0.1', 15 => 'br0.1400',
    );
    $info->cache({
        '_i_index'                 => 1,
        '_i_description'           => 1,
        '_teltonika_port_name'     => 1,
        '_teltonika_vlan_name'     => 1,
        '_teltonika_vlan_id'       => 1,
        '_teltonika_vlan_untagged' => 1,
        '_teltonika_vlan_tagged'   => 1,
        'store' => {
            'i_index'       => { map { $_ => $_ } keys %i_description },
            'i_description' => \%i_description,
            'teltonika_port_name' =>
                { map { ( $_ + 1 ) => $ports[$_] } 0 .. $#ports },
            %TSW_VLAN_STORE,
            %store,
        },
    });
}

sub _prime_qbridge {
    my ( $info, %store ) = @_;
    $info->cache({
        ( map { ( "_$_" => 1 ) } keys %store ),
        'store' => \%store,
    });
}

sub bp_index : Tests(4) {
    my $info = shift->{info};

    _tsw_cache($info);
    is_deeply(
        $info->bp_index(),
        { map { $_ => $_ + 2 } 1 .. 10 },
        'Without BRIDGE-MIB ports, each bridge port joins ifDescr by name'
    );

    _tsw_cache( $info,
        'teltonika_port_name' =>
            { 1 => 'port1', 2 => 'port9', 3 => 'port2', 4 => 'port2' } );
    is_deeply( $info->bp_index(), { 1 => 3 },
        'A name matching no ifDescr, or matched twice, is left out' );

    _tsw_cache( $info, 'teltonika_port_name' => {} );
    ok( !%{ $info->bp_index() || {} },
        'A device without the port table gets no mapping' );

    _tsw_cache($info);
    $info->cache({
        '_bp_index' => 1,
        'store'     => { 'bp_index' => { 1 => 7, 2 => 8 } },
    });
    is_deeply( $info->bp_index(), { 1 => 7, 2 => 8 },
        'BRIDGE-MIB dot1dBasePortIfIndex is used whenever it is served' );
}

# The RUTX pVlanTable as Teltonika documents it, at the TSW column OIDs:
# pVlanNum where TSW has pVlanName, pVlanPorts where TSW has pVlanVID, and
# pVlanVID where TSW has pVlanPortsUntag. No RUTX walk was available.
my %RUTX_VLAN_STORE = (
    'teltonika_vlan_name'     => { 1 => 1,      2 => 2 },
    'teltonika_vlan_id'       => { 1 => 'LAN1', 2 => 'LAN2 LAN3' },
    'teltonika_vlan_untagged' => { 1 => 1,      2 => 20 },
    'teltonika_vlan_tagged'   => {},
);

sub v_index : Tests(3) {
    my $info = shift->{info};

    _tsw_cache($info);
    is_deeply( $info->v_index(), { 1 => 1, 2 => 1400 },
        'Each pVlanTable row gives its VLAN ID' );

    _tsw_cache( $info, %RUTX_VLAN_STORE );
    _prime_qbridge( $info, 'v_name' => { 10 => 'users' } );
    is_deeply( $info->v_index(), { 10 => 10 },
        'A RUTX pVlanTable, port lists in place of VLAN IDs, is not read' );

    _tsw_cache( $info, %TSW_NO_VLAN_TABLE );
    _prime_qbridge( $info, 'v_name' => { 10 => 'users' } );
    is_deeply( $info->v_index(), { 10 => 10 },
        'Without pVlanTable rows, Q-BRIDGE VLANs are used' );
}

sub v_name : Tests(2) {
    my $info = shift->{info};

    _tsw_cache($info);
    is_deeply( $info->v_name(), { 1 => 'vlan1', 2 => 'vlan2' },
        'Each pVlanTable row gives its VLAN name' );

    _tsw_cache( $info, %TSW_NO_VLAN_TABLE );
    _prime_qbridge( $info, 'v_name' => { 10 => 'users' } );
    is_deeply( $info->v_name(), { 10 => 'users' },
        'Without pVlanTable rows, dot1qVlanStaticName is used' );
}

sub i_vlan : Tests(3) {
    my $info = shift->{info};

    _tsw_cache($info);
    is_deeply(
        $info->i_vlan(),
        { ( map { $_ => 1400 } @TSW_ACCESS_IFINDEX ), 11 => 1, 12 => 1 },
        'Each port takes the VLAN it is untagged in as its native VLAN'
    );

    _tsw_cache( $info,
        'teltonika_vlan_untagged' =>
            { 1 => 'port1:u', 2 => 'port1:u port2:u' },
        'teltonika_vlan_tagged' => { 1 => 'None', 2 => 'None' } );
    is_deeply( $info->i_vlan(), { 4 => 1400 },
        'A port untagged in two VLANs has no single native VLAN' );

    _tsw_cache( $info, %TSW_NO_VLAN_TABLE );
    _prime_qbridge( $info,
        'bp_index' => { 1 => 3 }, 'qb_i_vlan' => { 1 => 20 } );
    is_deeply( $info->i_vlan(), { 3 => 20 },
        'Without pVlanTable rows, dot1qPvid is used' );
}

sub i_vlan_membership : Tests(5) {
    my $info = shift->{info};

    _tsw_cache($info);
    is_deeply(
        $info->i_vlan_membership(),
        {   ( map { $_ => [1400] } @TSW_ACCESS_IFINDEX ),
            11 => [ 1, 1400 ],
            12 => [ 1, 1400 ],
        },
        'Each port is a member of the VLANs it is tagged or untagged in'
    );

    _tsw_cache( $info,
        'teltonika_vlan_untagged' => { 1 => 'port9:u port1', 2 => 'None' },
        'teltonika_vlan_tagged'   => { 1 => 'sfp1:u', 2 => 'sfp2:t' } );
    is_deeply( $info->i_vlan_membership(), { 12 => [1400] },
        'A token naming no port, or lacking its column suffix, is left out' );

    _tsw_cache( $info,
        'teltonika_vlan_untagged' => { 1 => 'None', 2 => 'None' },
        'teltonika_vlan_tagged'   => { 1 => 'None', 2 => 'None' } );
    is_deeply( $info->i_vlan_membership(), {},
        'VLANs with no ports give no memberships' );

    _tsw_cache( $info, %RUTX_VLAN_STORE );
    _prime_qbridge( $info,
        'bp_index' => { 1 => 3 }, 'qb_cv_egress' => { '0.20' => "\x80" } );
    is_deeply( $info->i_vlan_membership(), { 3 => [20] },
        'A RUTX pVlanTable leaves memberships to Q-BRIDGE' );

    _tsw_cache( $info, %TSW_NO_VLAN_TABLE );
    _prime_qbridge( $info,
        'bp_index' => { 1 => 3 }, 'qb_cv_egress' => { '0.20' => "\x80" } );
    is_deeply( $info->i_vlan_membership(), { 3 => [20] },
        'Without pVlanTable rows, Q-BRIDGE egress ports are used' );
}

sub i_vlan_membership_untagged : Tests(2) {
    my $info = shift->{info};

    _tsw_cache($info);
    is_deeply(
        $info->i_vlan_membership_untagged(),
        {   ( map { $_ => [1400] } @TSW_ACCESS_IFINDEX ),
            11 => [1],
            12 => [1],
        },
        'Each port lists the VLANs it is untagged in'
    );

    _tsw_cache( $info, %TSW_NO_VLAN_TABLE );
    _prime_qbridge( $info,
        'bp_index' => { 1 => 3 }, 'qb_cv_untagged' => { '0.20' => "\x80" } );
    is_deeply( $info->i_vlan_membership_untagged(), { 3 => [20] },
        'Without pVlanTable rows, Q-BRIDGE untagged ports are used' );
}

1;
