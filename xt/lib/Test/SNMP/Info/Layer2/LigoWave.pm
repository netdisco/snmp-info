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
    ligo_wifi_encryption => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.9',
    ligo_wifi_tx_power   => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.10',
    ligo_wifi_bitrate    => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.11',
    ligo_wifi_snr        => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.12',
    ligo_wifi_max_snr    => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.13',
    ligo_wifi_signal     => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.14',
    ligo_wifi_noise      => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.15',
    ligo_wifi_assoc_count => '.1.3.6.1.4.1.32750.3.10.1.2.1.1.16',
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

sub setup : Tests(setup) {
    my $test = shift;
    $test->SUPER::setup;
    $test->{info}->cache({
        '_description' => 'LigoDLB 5-20ac v7.69.87740',
        '_id' => '.1.3.6.1.4.1.32750',
        '_layers' => 72,
        '_i_name' => 1,
        'store' => {
            'i_name' => {
                510 => 'br0', 410 => 'ath0', 5199 => 'br99',
                21099 => 'eth0.99', 41099 => 'ath0.99',
            },
        },
    });
}

sub device_type : Tests(2) {
    my $info = shift->{info};
    is($info->device_type(), 'SNMP::Info::Layer2::LigoWave',
        'LigoDLB detected by enterprise and description');
    $info->cache({
        '_id' => '.1.3.6.1.4.1.32750',
        '_description' => 'Unrelated device description',
        '_layers' => 72,
    });
    isnt($info->device_type(), 'SNMP::Info::Layer2::LigoWave',
        'Other LigoWave enterprise devices are not classified as DLB');
}

sub vendor : Tests(1) {
    is(shift->{info}->vendor(), 'ligowave', 'Vendor');
}

sub model : Tests(1) {
    is(shift->{info}->model(), 'LigoDLB 5-20ac', 'Model');
}

sub os : Tests(1) {
    is(shift->{info}->os(), 'ligowave os', 'OS');
}

sub os_ver : Tests(1) {
    is(shift->{info}->os_ver(), '7.69.87740', 'Firmware version');
}

sub peer_tables : Tests(3) {
    my $test = shift;
    my $peer_iid = '0.6.2.0.0.0.0.41';
    $test->mock_session->{Data} = {
        $PEER_IP_OID => { $peer_iid => '192.0.2.41' },
        $PEER_NAME_OID => { $peer_iid => 'bridge-peer' },
    };
    is_deeply($test->{info}->ligo_peer_ip(),
        { $peer_iid => '192.0.2.41' }, 'Numeric OID peer IP column walked');
    is_deeply($test->{info}->ligo_peer_name(),
        { $peer_iid => 'bridge-peer' },
        'Numeric OID peer name column walked');
    is_deeply($test->{info}->ligo_peer_ip(),
        { $peer_iid => '192.0.2.41' }, 'Peer table uses cache');
}

sub vendor_columns : Tests(28) {
    my $test = shift;
    my $iid = '7';
    my %sample = map { $_ => 1 } keys %COLUMN_OIDS;
    $sample{ligo_wifi_mac} = pack('C*', 2, 0, 0, 0, 0, 40);
    $sample{ligo_peer_mac} = pack('C*', 2, 0, 0, 0, 0, 41);
    $sample{ligo_wifi_essid} = 'example-ssid';
    $sample{ligo_wifi_country} = 'GB';
    $sample{ligo_wifi_encryption} = 8;
    $sample{ligo_wifi_max_snr} = 105;
    $sample{ligo_wifi_assoc_count} = 7;
    $sample{ligo_wifi_state} = 'up';
    $sample{ligo_peer_ip} = '192.0.2.41';
    $sample{ligo_peer_remote_port} = 0;
    $sample{ligo_peer_name} = 'bridge-peer';

    foreach my $method (sort keys %COLUMN_OIDS) {
        $test->mock_session->{Data} = {
            $COLUMN_OIDS{$method} => { $iid => $sample{$method} },
        };
        my $expected = $sample{$method};
        $expected = '02:00:00:00:00:28' if $method eq 'ligo_wifi_mac';
        $expected = '02:00:00:00:00:29' if $method eq 'ligo_peer_mac';
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

sub ligo_wifi_encryption : Tests(1) {
    _check_column(shift, 'ligo_wifi_encryption', 8);
}

sub ligo_wifi_max_snr : Tests(1) {
    _check_column(shift, 'ligo_wifi_max_snr', 105);
}

sub ligo_wifi_assoc_count : Tests(1) {
    _check_column(shift, 'ligo_wifi_assoc_count', 7);
}

sub ligo_wifi_state : Tests(1) {
    _check_column(shift, 'ligo_wifi_state', 'up');
}

sub ligo_peer_remote_port : Tests(1) {
    _check_column(shift, 'ligo_peer_remote_port', 0);
}

sub v_name : Tests(1) {
    my $info = shift->{info};
    is_deeply($info->v_name(), { 99 => 'VLAN 99' },
        'VLAN identified from logical interface names');
}

sub v_index : Tests(1) {
    my $info = shift->{info};
    is_deeply($info->v_index(), { 99 => 99 },
        'VLAN index generated from logical interface number');
}

sub i_vlan_membership : Tests(1) {
    my $info = shift->{info};
    is_deeply($info->i_vlan_membership(), {
        5199 => [99], 21099 => [99], 41099 => [99],
    }, 'Logical interfaces mapped to VLAN 99');
}

sub i_vlan_membership_untagged : Tests(1) {
    my $info = shift->{info};
    is_deeply($info->i_vlan_membership_untagged(), {},
        'No untagged membership inferred');
}

# Shaped as a DLB 5-20ac walk: the wireless table numbers its one row 10,
# while ath0 is ifIndex 410 and shares its MAC with wifi0, br0 and ath0.99.
sub _wireless_cache {
    my ( $info, %override ) = @_;
    my $radio = pack( 'C*', 2, 0, 0, 0, 1, 1 );
    my $wired = pack( 'C*', 2, 0, 0, 0, 1, 3 );
    my %i_description = (
        210 => 'eth0', 310 => 'wifi0', 410 => 'ath0', 510 => 'br0',
        41099 => 'ath0.99',
    );
    my %i_mac = (
        210 => $wired, 310 => $radio, 410 => $radio, 510 => $radio,
        41099 => $radio,
    );
    $info->cache({
        '_i_index'          => 1,
        '_i_description'    => 1,
        '_i_mac'            => 1,
        '_ligo_wifi_mac'     => 1,
        '_ligo_wifi_essid'   => 1,
        '_ligo_wifi_channel' => 1,
        'store' => {
            'i_index'           => { map { $_ => $_ } keys %i_description },
            'i_description'     => \%i_description,
            'i_mac'             => \%i_mac,
            'ligo_wifi_mac'     => { 10 => $radio },
            'ligo_wifi_essid'   => { 10 => 'example-ssid' },
            'ligo_wifi_channel' => { 10 => 149 },
            %override,
        },
    });
}

sub i_ssidlist : Tests(2) {
    my $info = shift->{info};
    _wireless_cache($info);
    is_deeply($info->i_ssidlist(), { 410 => 'example-ssid' },
        'SSID lands on the athN interface with the radio MAC');

    _wireless_cache($info,
        'ligo_wifi_mac' => { 10 => pack( 'C*', 2, 0, 0, 0, 1, 9 ) });
    is_deeply($info->i_ssidlist(), {},
        'Row with no matching interface MAC is dropped');
}

sub i_ssidmac : Tests(1) {
    my $info = shift->{info};
    _wireless_cache($info);
    is_deeply($info->i_ssidmac(), { 410 => '02:00:00:00:01:01' },
        'BSSID uses the same interface key as the SSID');
}

sub i_80211channel : Tests(2) {
    my $info = shift->{info};
    _wireless_cache($info);
    is_deeply($info->i_80211channel(), { 410 => 149 },
        'Channel lands on the athN interface with the radio MAC');

    my $radio = pack( 'C*', 2, 0, 0, 0, 1, 1 );
    _wireless_cache($info,
        'i_index'       => { 410 => 410, 420 => 420 },
        'i_description' => { 410 => 'ath0', 420 => 'ath1' },
        'i_mac'         => { 410 => $radio, 420 => $radio });
    is_deeply($info->i_80211channel(), {},
        'Row matching several athN interfaces is dropped');
}

1;
