# Test::SNMP::Info::Layer3::Tachyon

package Test::SNMP::Info::Layer3::Tachyon;

use Test::Class::Most parent => 'My::Test::Class';
use SNMP::Info::Layer3::Tachyon;

my %TABLES = (
    tachyon_peer_mac => '.1.3.6.1.4.1.57344.1.2.6.1.1',
    tachyon_peer_ifindex => '.1.3.6.1.4.1.57344.1.2.6.1.3',
    tachyon_ethernet_ifname => '.1.3.6.1.4.1.57344.1.1.3.1.2',
    tachyon_ethernet_link => '.1.3.6.1.4.1.57344.1.1.3.1.5',
    tachyon_ethernet_duplex => '.1.3.6.1.4.1.57344.1.1.3.1.8',
    tachyon_ethernet_admin => '.1.3.6.1.4.1.57344.1.1.3.1.10',
);

sub setup : Tests(setup) {
    my $test = shift;
    $test->SUPER::setup;
    $test->{info}->cache({
        '_layers' => 4,
        '_description' => 'Linux TNA-301 test 1.12.1',
        '_id' => '.1.3.6.1.4.1.57344.1',
        '_tachyon_device_model' => 'TNA-301',
        '_tachyon_serial' => 'SYNTHETIC-SERIAL',
        '_tachyon_firmware' => '1.12.1',
        '_tachyon_description' => 'Tachyon TNA-301',
        '_os_ver' => '1.12.1',
        '_i_index' => 1,
        '_i_description' => 1,
        '_i_name' => 1,
        'store' => {
            'i_index' => { 1 => 1, 2 => 2, 3 => 3 },
            'i_description' => { 1 => 'eth0', 2 => 'br99', 3 => 'eth0.99' },
            'i_name' => { 1 => 'eth0', 2 => 'br99', 3 => 'eth0.99' },
        },
    });
    my $peer_iid = '1.2.3.4';
    $test->mock_session->{Data} = {
        $TABLES{tachyon_peer_mac} => { $peer_iid => pack('C*', 2, 0, 0, 0, 0, 42) },
        $TABLES{tachyon_peer_ifindex} => { $peer_iid => 1 },
        $TABLES{tachyon_ethernet_ifname} => { 1 => 'eth0' },
        $TABLES{tachyon_ethernet_link} => { 1 => 1 },
        $TABLES{tachyon_ethernet_admin} => { 1 => 1 },
        $TABLES{tachyon_ethernet_duplex} => { 1 => 'full' },
    };
}

sub device_type : Tests(5) {
    my $info = shift->{info};
    can_ok($info, 'device_type');
    is($info->device_type(), 'SNMP::Info::Layer3::Tachyon', 'TNA detection');
    $info->cache({ '_layers' => undef });
    is($info->device_type(), 'SNMP::Info::Layer3::Tachyon',
        'TNA detection without sysServices');
    $info->cache({
        '_id' => '.1.3.6.1.4.1.57344.2',
        '_description' => 'TNS-100',
        '_layers' => 6,
    });
    is($info->device_type(), 'SNMP::Info::Layer3',
        'TNS switch keeps the generic class');
    $info->cache({
        '_id' => '.1.3.6.1.4.1.57345',
        '_description' => 'Linux generic-device 5.10.0',
        '_layers' => 4,
    });
    isnt($info->device_type(), 'SNMP::Info::Layer3::Tachyon',
        'Neighboring enterprise is not classified as Tachyon');
}

sub vendor : Tests(1) {
    is(shift->{info}->vendor(), 'tachyon', 'Vendor');
}

sub os : Tests(1) {
    is(shift->{info}->os(), 'tachyon', 'OS');
}

sub model : Tests(2) {
    my $info = shift->{info};
    is($info->model(), 'TNA-301', 'Model from vendor scalar');
    $info->cache({ '_tachyon_device_model' => '' });
    is($info->model(), SNMP::Info::Layer3::model($info), 'Inherited model fallback');
}

sub os_ver : Tests(2) {
    my $info = shift->{info};
    is($info->os_ver(), '1.12.1', 'Firmware from vendor scalar');
    $info->cache({ '_tachyon_firmware' => '' });
    is($info->os_ver(), undef, 'Inherited firmware fallback');
}

sub serial : Tests(1) {
    is(shift->{info}->serial(), 'SYNTHETIC-SERIAL', 'Serial');
}

sub description : Tests(2) {
    my $info = shift->{info};
    is($info->description(), 'Linux TNA-301 test 1.12.1', 'sysDescr first');
    $info->cache({ '_description' => '' });
    is($info->description(), 'Tachyon TNA-301', 'Vendor description fallback');
}

sub layers : Tests(3) {
    my $test = shift;
    my $info = $test->{info};
    is($info->layers(), '00000110', 'peers add layer 2 to served layers');
    $info->cache({ '_layers' => undef });
    is($info->layers(), '00000110', 'no sysServices gives layer 3, plus 2 with peers');
    $info->clear_cache();
    $info->cache({ '_layers' => undef });
    $test->mock_session->{Data}{ $TABLES{tachyon_peer_mac} } = {};
    is($info->layers(), '00000100', 'no sysServices and no peers gives layer 3');
}

sub fw_mac : Tests(2) {
    my $test = shift;
    is_deeply($test->{info}->fw_mac(), { '1.2.3.4' => '02:00:00:00:00:2a' }, 'Peer MACs');
    $test->{info}->clear_cache();
    $test->mock_session->{Data}{ $TABLES{tachyon_peer_mac} }
        = { 1 => '02:00:00:00:00:2B' };
    is_deeply($test->{info}->fw_mac(), { 1 => '02:00:00:00:00:2b' },
        'Peer MACs served as text');
}

sub fw_port : Tests(1) {
    is_deeply(shift->{info}->fw_port(), { '1.2.3.4' => 1 }, 'Peer interface indexes');
}

sub fw_status : Tests(1) {
    is_deeply(shift->{info}->fw_status(), { '1.2.3.4' => 3 }, 'Active peer status');
}

sub bp_index : Tests(2) {
    my $test = shift;
    my $info = $test->{info};
    is_deeply($info->bp_index(), { 1 => 1, 2 => 2, 3 => 3 }, 'Bridge port index map');
    $info->clear_cache();
    $info->cache({
        '_i_description' => 1,
        'store' => { 'i_description' => { 1 => 'eth0', 50 => 'wlan0' } },
    });
    $test->mock_session->{Data}{ $TABLES{tachyon_peer_ifindex} } = { '1.2.3.4' => 50 };
    is_deeply($info->bp_index(), { 1 => 1, 50 => 50 },
        'Interfaces map to themselves without an ifIndex column');
}

sub i_up : Tests(1) {
    is_deeply(shift->{info}->i_up(), { 1 => 'up' }, 'Ethernet operational status');
}

sub i_up_admin : Tests(1) {
    is_deeply(shift->{info}->i_up_admin(), { 1 => 'up' }, 'Ethernet administrative status');
}

sub i_duplex : Tests(1) {
    is_deeply(shift->{info}->i_duplex(), { 1 => 'full' }, 'Ethernet duplex');
}

sub i_type : Tests(1) {
    is_deeply(shift->{info}->i_type(), { 1 => 'ethernetCsmacd' }, 'Ethernet interface type');
}

sub i_vlan : Tests(1) {
    is_deeply(shift->{info}->i_vlan(), { 2 => 99, 3 => 99 }, 'VLANs from logical interface names');
}

sub v_name : Tests(1) {
    is_deeply(shift->{info}->v_name(), { 99 => '99' }, 'VLAN name');
}

sub i_vlan_membership : Tests(1) {
    is_deeply(shift->{info}->i_vlan_membership(), { 2 => [99], 3 => [99] }, 'Logical VLAN membership');
}

sub i_vlan_membership_untagged : Tests(1) {
    is_deeply(shift->{info}->i_vlan_membership_untagged(), {}, 'No untagged membership inferred');
}

1;
