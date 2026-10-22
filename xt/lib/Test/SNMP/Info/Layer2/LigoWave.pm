# Test::SNMP::Info::Layer2::LigoWave

package Test::SNMP::Info::Layer2::LigoWave;

use Test::Class::Most parent => 'My::Test::Class';
use SNMP::Info::Layer2::LigoWave;

my $PEER_IP_OID = '.1.3.6.1.4.1.32750.3.10.1.3.2.1.7';
my $PEER_NAME_OID = '.1.3.6.1.4.1.32750.3.10.1.3.2.1.9';
my %COLUMN_OIDS = (
    ligo_wifi_mac        => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.1',
    ligo_wifi_protocol   => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.2',
    ligo_wifi_mode       => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.3',
    ligo_wifi_essid      => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.4',
    ligo_wifi_country    => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.5',
    ligo_wifi_frequency  => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.6',
    ligo_wifi_channel    => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.7',
    ligo_wifi_width      => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.8',
    ligo_wifi_tx_streams => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.9',
    ligo_wifi_tx_power   => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.10',
    ligo_wifi_bitrate    => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.11',
    ligo_wifi_snr        => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.12',
    ligo_wifi_quality    => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.13',
    ligo_wifi_signal     => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.14',
    ligo_wifi_noise      => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.15',
    ligo_wifi_status     => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.16',
    ligo_wifi_state      => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.17',
    ligo_peer_mac        => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.1',
    ligo_peer_associated => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.2',
    ligo_peer_tx_bytes   => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.3',
    ligo_peer_rx_bytes   => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.4',
    ligo_peer_signal     => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.5',
    ligo_peer_noise      => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.6',
    ligo_peer_ip         => $PEER_IP_OID,
    ligo_peer_remote_port => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.8',
    ligo_peer_name       => $PEER_NAME_OID,
    ligo_peer_rx_rate    => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.10',
    ligo_peer_tx_rate    => '.1.3.6.1.4.1.32750.3.10.1.3.2.1.11',
);

sub startup : Tests(startup => 1) {
    my $test = shift;
    $test->SUPER::startup();
    $test->todo_methods(1);
}

sub setup : Tests(setup) {
    my $test = shift;
    $test->SUPER::setup;
    $test->{info}->cache({
        '_description' => 'LigoDLB 5-20ac v7.69.87740',
        '_id' => '.1.3.6.1.4.1.32750',
        '_layers' => 0,
        '_i_name' => 1,
        'store' => {
            'i_name' => {
                510 => 'br0', 410 => 'ath0', 5199 => 'br99',
                21099 => 'eth0.99', 41099 => 'ath0.99',
            },
        },
    });
    $test->{info}{args}{DestHost} = '192.0.2.10';
}

sub device_type : Tests(1) {
    is(shift->{info}->device_type(), 'SNMP::Info::Layer2::LigoWave',
        'LigoDLB detected by enterprise and description');
}

sub identity : Tests(4) {
    my $info = shift->{info};
    is($info->vendor(), 'ligowave', 'Vendor');
    is($info->model(), 'LigoDLB 5-20ac', 'Model');
    is($info->os(), 'LigoWave OS', 'OS');
    is($info->os_ver(), '7.69.87740', 'Firmware version');
}

sub peer_tables : Tests(3) {
    my $test = shift;
    my $peer_iid = '0.6.0.25.59.36.55.77';
    $test->mock_session->{Data} = {
        $PEER_IP_OID => { $peer_iid => '172.30.225.41' },
        $PEER_NAME_OID => { $peer_iid => 'AMT-WIFI2' },
    };
    is_deeply($test->{info}->ligo_peer_ip(),
        { $peer_iid => '172.30.225.41' }, 'Numeric OID peer IP column walked');
    is_deeply($test->{info}->ligo_peer_name(),
        { $peer_iid => 'AMT-WIFI2' }, 'Numeric OID peer name column walked');
    is_deeply($test->{info}->ligo_peer_ip(),
        { $peer_iid => '172.30.225.41' }, 'Peer table uses cache');
}

sub vendor_columns : Tests(28) {
    my $test = shift;
    my $iid = '7';
    my %sample = map { $_ => 1 } keys %COLUMN_OIDS;
    $sample{ligo_wifi_mac} = pack('C*', 0, 25, 59, 31, 174, 77);
    $sample{ligo_peer_mac} = pack('C*', 0, 25, 59, 36, 55, 77);
    $sample{ligo_wifi_essid} = 'AMT-BRIDGE';
    $sample{ligo_wifi_country} = 'GB';
    $sample{ligo_wifi_tx_streams} = 8;
    $sample{ligo_wifi_quality} = 105;
    $sample{ligo_wifi_status} = 1;
    $sample{ligo_wifi_state} = 'up';
    $sample{ligo_peer_ip} = '172.30.225.41';
    $sample{ligo_peer_remote_port} = 0;
    $sample{ligo_peer_name} = 'AMT-WIFI2';

    foreach my $method (sort keys %COLUMN_OIDS) {
        $test->mock_session->{Data} = {
            $COLUMN_OIDS{$method} => { $iid => $sample{$method} },
        };
        my $expected = $sample{$method};
        $expected = '00:19:3b:1f:ae:4d' if $method eq 'ligo_wifi_mac';
        $expected = '00:19:3b:24:37:4d' if $method eq 'ligo_peer_mac';
        is_deeply($test->{info}->$method(), { $iid => $expected },
            "$method numeric OID column walked");
    }
}

sub _check_column {
    my ( $test, $method, $expected ) = @_;
    my $iid = '10';
    $test->mock_session->{Data} = {
        $COLUMN_OIDS{$method} => { $iid => $expected },
    };
    is_deeply($test->{info}->$method(), { $iid => $expected },
        "$method numeric OID column walked");
}

sub ligo_wifi_country : Tests(1) {
    _check_column(shift, 'ligo_wifi_country', 'GB');
}

sub ligo_wifi_tx_streams : Tests(1) {
    _check_column(shift, 'ligo_wifi_tx_streams', 8);
}

sub ligo_wifi_quality : Tests(1) {
    _check_column(shift, 'ligo_wifi_quality', 105);
}

sub ligo_wifi_status : Tests(1) {
    _check_column(shift, 'ligo_wifi_status', 1);
}

sub ligo_wifi_state : Tests(1) {
    _check_column(shift, 'ligo_wifi_state', 'up');
}

sub ligo_peer_remote_port : Tests(1) {
    _check_column(shift, 'ligo_peer_remote_port', 0);
}

sub vlans : Tests(4) {
    my $info = shift->{info};
    is_deeply($info->v_name(), { 99 => 'VLAN 99' },
        'VLAN identified from logical interface names');
    is_deeply($info->v_index(), { 99 => 99 },
        'VLAN index generated from logical interface number');
    is_deeply($info->i_vlan_membership(), {
        5199 => [99], 21099 => [99], 41099 => [99],
    }, 'Logical interfaces mapped to VLAN 99');
    is_deeply($info->i_vlan_membership_untagged(), {},
        'No untagged membership inferred');
}

sub management_address : Tests(3) {
    my $info = shift->{info};
    is_deeply($info->ip_index(), { '192.0.2.10' => 510 },
        'Discovery address is associated with br0 ifIndex');
    is_deeply($info->ip_table(), { '192.0.2.10' => '192.0.2.10' },
        'Discovery address is reported even without IP-MIB');
    is_deeply($info->ip_netmask(), {},
        'No mask is invented when the radio does not expose one');
}

1;
