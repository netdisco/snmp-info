package Test::SNMP::Info::Layer3::ArubaInstant;

use Test::Class::Most parent => 'My::Test::Class';
use SNMP::Info::Layer3::ArubaInstant;
use JSON::PP qw/decode_json/;
use File::Slurper qw/read_text/;

sub setup : Tests(setup) {
    my $test = shift;
    $test->SUPER::setup();
    # Anonymised subset of the AP-515 / Instant 8.10.0.9 walk in issue #536.
    # MAC addresses and SSIDs changed, preserving all table relationships.
    my $store = decode_json(read_text('xt/fixtures/aruba-instant-8.10.json'));
    $store->{i_index} = {1 => 1};
    $store->{i_name} = {1 => 'Ethernet1'};
    $store->{i_description} = {1 => 'Ethernet uplink'};
    $store->{i_type} = {1 => 'ethernetCsmacd'};
    $store->{i_mac} = {1 => '02:00:00:00:ff:01'};
    $store->{i_up} = {1 => 'up'};
    $store->{i_up_admin} = {1 => 'up'};
    $store->{bp_index} = {1 => 1};
    $store->{qb_fw_mac} = {'1.2.0.0.0.255.2' => '02:00:00:00:ff:02'};
    $store->{qb_fw_port} = {'1.2.0.0.0.255.2' => 1};
    # SNMP::Info caches octet strings before applying MAC munges.
    foreach my $method (qw/instant_wlan_mac instant_radio_mac instant_client_mac instant_client_bssid i_mac qb_fw_mac/) {
        $store->{$method}{$_} = pack('C6', map {hex $_} split /:/, $store->{$method}{$_})
            foreach keys %{$store->{$method}};
    }
    $test->{info}->cache({
        (map {('_' . $_ => 1)} keys %$store),
        _layers => 72,
        _description => 'ArubaOS (MODEL: 515), Version 8.10.0.9-8.10.0.9 LSR',
        _id => '.1.3.6.1.4.1.14823.1.2.107',
        store => $store,
    });
}

sub interfaces : Tests(1) {
    my $test = shift;
    subtest 'Netdisco SSID and client joins' => sub {
        my $info = $test->{info};
        my $ports = $info->interfaces();
        my $ssids = $info->i_ssidlist();
        my $macs = $info->fw_mac();
        my $fw_ports = $info->fw_port();
        my $bridge = $info->bp_index();
        my $channels = $info->i_80211channel();
        is_deeply($ports, {
            1                 => 'Ethernet1',
            '2.0.0.0.0.1.0.0' => '02:00:00:00:00:01.radio0',
            '2.0.0.0.0.1.1.0' => '02:00:00:00:00:01.radio1',
        }, 'interfaces__wlans_on_two_radios__one_port_per_radio');
        is(scalar keys %$ssids, 8, 'all eight SSID entries exposed');
        is(scalar keys %$macs, 10, 'nine clients and wired forwarding entry');
        is($macs->{'1.2.0.0.0.255.2'}, '02:00:00:00:ff:02', 'wired MAC preserved');
        is($bridge->{1}, 1, 'wired bridge mapping preserved');
        foreach my $key (sort keys %$ssids) {
            (my $iid = $key) =~ s/\.\d+$//;
            ok(exists $ports->{$iid}, 'interfaces__ssid_key_minus_wlan__is_a_port');
        }
        foreach my $key (sort grep {/^instant\./} keys %$macs) {
            my $iid = $bridge->{$fw_ports->{$key}};
            is($ports->{$iid // ''}, '02:00:00:00:00:01.radio0',
                'interfaces__client_on_bssid_f0__joins_radio0');
            ok(exists $channels->{$iid // ''},
                'interfaces__client_port__has_a_channel_row');
        }
        is(scalar keys %{$info->i_ssidbcast()}, 8, 'broadcast flags join SSIDs');
        done_testing();
    };
}

sub missing_and_invalid_data : Tests(1) {
    my $test = shift;
    subtest 'Missing and invalid entries' => sub {
        my $info = $test->{info};
        my ($client) = sort keys %{$info->{store}{instant_client_mac}};
        $info->{store}{instant_client_bssid}{$client} = pack('C6', 2, 0, 0, 255, 255, 255);
        ok(!exists $info->fw_mac()->{"instant.$client"}, 'unknown BSSID client omitted');
        $info->{store}{instant_wlan_mac}{'invalid'} = pack('C6', 2, 0, 0, 255, 255, 255);
        $info->{store}{instant_wlan_mac}{'2.0.0.0.0.1.99'} = pack('C6', (0) x 6);
        is(scalar keys %{$info->i_ssidmac()}, 8, 'invalid WLAN entries omitted');
        $info->{store}{instant_wlan_mac} = {};
        $info->{store}{instant_radio_channel} = {};
        $info->{store}{instant_radio_mac} = {};
        is_deeply($info->interfaces(), {1 => 'Ethernet1'}, 'missing Instant tables retain wired ports');
        is_deeply($info->i_ssidlist(), {}, 'no SSIDs without BSSIDs');
        is_deeply($info->i_ssidmac(), {}, 'no BSSIDs');
        is_deeply($info->i_ssidbcast(), {}, 'no orphan broadcast flags');
        is(scalar keys %{$info->fw_mac()}, 1, 'no unmatched wireless clients');
        done_testing();
    };
}

sub raw_table_reads : Tests(1) {
    my $test = shift;
    subtest 'Read AI-AP-MIB tables through the SNMP session' => sub {
        my $info = $test->{info};
        my $fixture = decode_json(read_text('xt/fixtures/aruba-instant-8.10.json'));
        my $radio_fixture = decode_json(read_text('xt/fixtures/aruba-instant-8.4-radios.json'));
        $fixture->{$_} = {%{$fixture->{$_} || {}}, %{$radio_fixture->{$_}}}
            foreach keys %$radio_fixture;
        my $session_data = {};
        foreach my $method (keys %$fixture) {
            my $leaf = $SNMP::Info::Layer3::ArubaInstant::FUNCS{$method};
            my %table = %{$fixture->{$method}};
            if ($method =~ /(?:mac|bssid)$/) {
                $table{$_} = pack('C6', map {hex $_} split /:/, $table{$_})
                    foreach keys %table;
            }
            $session_data->{"AI-AP-MIB::$leaf"} = \%table;
        }
        $test->mock_session->{Data} = $session_data;
        $info->clear_cache();
        foreach my $method (sort keys %$fixture) {
            is_deeply($info->$method(), $fixture->{$method}, "$method reads and munges the MIB table");
        }
        is(scalar keys %{$info->i_ssidlist()}, 8, 'eight WLANs from raw SNMP tables');
        is(scalar keys %{$info->fw_mac()}, 9, 'nine clients from raw SNMP tables');
        done_testing();
    };
}

sub i_index : Tests(3) {
    my $info = shift->{info};
    is($info->i_index()->{1}, 1, 'physical index retained');
    is($info->i_index()->{'2.0.0.0.0.1.0.0'}, '02:00:00:00:00:01.radio0', 'stable radio index');
    ok(!exists $info->i_index()->{'2.0.0.0.0.1.0'}, 'i_index__wlan__is_not_a_port');
}

sub i_name : Tests(2) {
    my $info = shift->{info};
    is($info->i_name()->{1}, 'Ethernet1', 'physical name retained');
    $info->{store}{instant_ap_name}{'2.0.0.0.0.1'} = 'Renamed AP';
    is($info->i_name()->{'2.0.0.0.0.1.0.0'}, '02:00:00:00:00:01.radio0', 'AP rename preserves port identity');
}

sub i_description : Tests(2) {
    my $info = shift->{info};
    is($info->i_description()->{1}, 'Ethernet uplink', 'physical description retained');
    $info->{store}{instant_ap_name} = {};
    is($info->i_description()->{'2.0.0.0.0.1.0.0'}, '02:00:00:00:00:01: Radio 0 (channel 132+)', 'description with missing AP name');
}

sub i_type : Tests(2) {
    my $info = shift->{info};
    is($info->i_type()->{1}, 'ethernetCsmacd', 'wired type retained');
    is($info->i_type()->{'2.0.0.0.0.1.0.0'}, 'ieee80211', 'radio port is wireless');
}

sub i_mac : Tests(2) {
    my $info = shift->{info};
    is($info->i_mac()->{1}, '02:00:00:00:ff:01', 'wired MAC retained');
    is($info->i_mac()->{'2.0.0.0.0.1.1.0'}, '02:00:00:00:01:e0', 'radio port uses radio MAC');
}

sub i_up : Tests(2) {
    my $info = shift->{info};
    $info->{store}{instant_radio_status}{'2.0.0.0.0.1.0'} = '2';
    is($info->i_up()->{'2.0.0.0.0.1.0.0'}, 'down', 'numeric radio down status');
    $info->{store}{instant_radio_status}{'2.0.0.0.0.1.0'} = '1';
    is($info->i_up()->{'2.0.0.0.0.1.0.0'}, 'up', 'numeric radio up status');
}

sub i_up_admin : Tests(2) {
    my $info = shift->{info};
    is($info->i_up_admin()->{1}, 'up', 'wired administrative status retained');
    is($info->i_up_admin()->{'2.0.0.0.0.1.0.0'}, 'up', 'radio status used for administrative status');
}

sub _mac {
    return pack('C6', map {hex $_} split /:/, shift);
}

sub i_ssidlist : Tests(10) {
    my $test = shift;
    my $info = $test->{info};
    my $ssids = $info->i_ssidlist();
    is($ssids->{'2.0.0.0.0.1.0.0.0'}, 'Test WLAN 1', 'i_ssidlist__bssid_f0__on_radio0');
    is($ssids->{'2.0.0.0.0.1.1.0.1'}, 'Test WLAN 1', 'i_ssidlist__bssid_e0__on_radio1');

    $info->{store}{instant_wlan_mac}{'2.0.0.0.0.1.2'} = _mac('02:00:00:00:01:00');
    ok(!grep({/\.2$/} keys %{$info->i_ssidlist()}), 'i_ssidlist__bssid_below_every_radio__wlan_omitted');

    $info->{store}{instant_wlan_mac}{'2.0.0.0.0.1.2'} = _mac('02:00:00:00:02:00');
    ok(!grep({/\.2$/} keys %{$info->i_ssidlist()}), 'i_ssidlist__bssid_16_above_radio__wlan_omitted');

    $info->{store}{instant_wlan_mac}{'2.0.0.0.0.1.2'} = _mac('02:00:00:00:01:f1');
    $info->{store}{instant_radio_channel}{'2.0.0.0.0.2.0'} = '36';
    $info->{store}{instant_radio_mac}{'2.0.0.0.0.2.0'} = _mac('02:00:00:00:01:f1');
    $ssids = $info->i_ssidlist();
    ok(exists $ssids->{'2.0.0.0.0.1.0.0.2'} && !exists $ssids->{'2.0.0.0.0.2.0.0.2'},
        'i_ssidlist__closer_radio_on_other_ap__not_chosen');

    # AP 3: radios 32 addresses apart, wider than the 16 Aruba documents.
    $info->{store}{instant_radio_channel}{'2.0.0.0.0.3.0'} = '36';
    $info->{store}{instant_radio_channel}{'2.0.0.0.0.3.1'} = '1';
    $info->{store}{instant_radio_mac}{'2.0.0.0.0.3.0'} = _mac('02:00:00:00:05:00');
    $info->{store}{instant_radio_mac}{'2.0.0.0.0.3.1'} = _mac('02:00:00:00:05:20');
    $info->{store}{instant_wlan_ssid}{"2.0.0.0.0.3.$_"} = 'Wide WLAN' foreach 0 .. 2;
    $info->{store}{instant_wlan_mac}{'2.0.0.0.0.3.0'} = _mac('02:00:00:00:05:18');
    $info->{store}{instant_wlan_mac}{'2.0.0.0.0.3.1'} = _mac('02:00:00:00:05:38');
    $info->{store}{instant_wlan_mac}{'2.0.0.0.0.3.2'} = _mac('02:00:00:00:05:40');
    $ssids = $info->i_ssidlist();
    is($ssids->{'2.0.0.0.0.3.0.0.0'}, 'Wide WLAN', 'i_ssidlist__bssid_24_above_radio_below_next__on_that_radio');
    is($ssids->{'2.0.0.0.0.3.1.0.1'}, 'Wide WLAN', 'i_ssidlist__highest_radio__range_as_wide_as_gap_below');
    ok(!grep({/^2\.0\.0\.0\.0\.3\..*\.2$/} keys %$ssids), 'i_ssidlist__bssid_a_full_gap_above_highest_radio__omitted');

    $test->_load_radios();
    $info->{store}{instant_radio_mac}{'2.0.0.0.0.5.0'} = _mac('02:00:00:00:03:f0');
    $info->{store}{instant_radio_mac}{'2.0.0.0.0.5.1'} = _mac('02:00:00:00:03:e0');
    $info->{store}{instant_radio_mac}{'2.0.0.0.0.5.2'} = _mac('02:00:00:00:04:00');
    $info->{store}{instant_wlan_mac}{'2.0.0.0.0.5.0'} = _mac('02:00:00:00:03:f1');
    $info->{store}{instant_wlan_mac}{'2.0.0.0.0.5.1'} = _mac('02:00:00:00:03:e1');
    $info->{store}{instant_wlan_mac}{'2.0.0.0.0.5.2'} = _mac('02:00:00:00:04:01');
    $info->{store}{instant_wlan_ssid}{"2.0.0.0.0.5.$_"} = 'Tri WLAN' foreach 0 .. 2;
    $ssids = $info->i_ssidlist();
    is_deeply([map { $ssids->{$_} } '2.0.0.0.0.5.0.0.0', '2.0.0.0.0.5.1.0.1', '2.0.0.0.0.5.2.0.2'],
        ['Tri WLAN', 'Tri WLAN', 'Tri WLAN'], 'i_ssidlist__tri_radio_ap__maps_all_three');
    my $ports = $info->interfaces();
    ok(!grep({ (my $iid = $_) =~ s/\.\d+$//; !exists $ports->{$iid} } keys %$ssids),
        'i_ssidlist__every_key_minus_wlan__is_a_port');
}

# Radio 5.0's MAC sits between 5.1's and 5.2's. Without it, 5.1's range
# would run up to 5.2's MAC and take 5.0's WLAN and clients.
sub wlan_radios__middle_radio_mac_missing__only_its_wlans_omitted : Tests(8) {
    my $test = shift;
    my $info = $test->{info};
    $test->_load_radios();
    $info->{store}{instant_radio_mac}{'2.0.0.0.0.5.1'} = _mac('02:00:00:00:03:e0');
    $info->{store}{instant_radio_mac}{'2.0.0.0.0.5.2'} = _mac('02:00:00:00:04:00');
    delete $info->{store}{instant_radio_mac}{'2.0.0.0.0.5.0'};
    $info->{store}{instant_wlan_mac}{'2.0.0.0.0.5.0'} = _mac('02:00:00:00:03:f1');
    $info->{store}{instant_wlan_mac}{'2.0.0.0.0.5.1'} = _mac('02:00:00:00:03:e1');
    $info->{store}{instant_wlan_mac}{'2.0.0.0.0.5.2'} = _mac('02:00:00:00:04:01');
    $info->{store}{instant_wlan_ssid}{"2.0.0.0.0.5.$_"} = 'Tri WLAN' foreach 0 .. 2;
    $info->{store}{instant_client_bssid}{'2.0.0.0.0.11'} = _mac('02:00:00:00:03:f1');
    $info->{store}{instant_client_bssid}{'2.0.0.0.0.12'} = _mac('02:00:00:00:03:e1');

    my $ssids = $info->i_ssidlist();
    ok(!exists $ssids->{'2.0.0.0.0.5.1.0.0'},
        'wlan_radios__middle_radio_mac_missing__its_wlan_not_on_radio_below');
    ok(!grep({/^2\.0\.0\.0\.0\.5\.\d\.0\.0$/} keys %$ssids),
        'wlan_radios__middle_radio_mac_missing__its_wlan_on_no_radio');
    ok(!exists $info->bp_index()->{'02:00:00:00:03:f1'},
        'wlan_radios__middle_radio_mac_missing__its_bssid_not_bridged');
    ok(!exists $info->fw_mac()->{'instant.2.0.0.0.0.11'},
        'wlan_radios__middle_radio_mac_missing__its_client_omitted');
    is($ssids->{'2.0.0.0.0.5.1.0.1'}, 'Tri WLAN',
        'wlan_radios__middle_radio_mac_missing__radio_below_keeps_own_wlan');
    is($ssids->{'2.0.0.0.0.5.2.0.2'}, 'Tri WLAN',
        'wlan_radios__middle_radio_mac_missing__radio_above_keeps_own_wlan');
    is($info->bp_index()->{ $info->fw_port()->{'instant.2.0.0.0.0.12'} },
        '2.0.0.0.0.5.1.0',
        'wlan_radios__middle_radio_mac_missing__radio_below_keeps_client');
    is($ssids->{'2.0.0.0.0.1.0.0.0'}, 'Test WLAN 1',
        'wlan_radios__radio_mac_missing__other_aps_still_mapped');
}

sub i_ssidmac : Tests(2) {
    my $info = shift->{info};
    is($info->i_ssidmac()->{'2.0.0.0.0.1.0.0.0'}, '02:00:00:00:01:f0', 'SSID and BSSID share index on radio0');
    is($info->i_ssidmac()->{'2.0.0.0.0.1.1.0.1'}, '02:00:00:00:01:e0', 'SSID and BSSID share index on radio1');
}

sub i_ssidbcast : Tests(5) {
    my $info = shift->{info};
    foreach my $case ([0, 1], [1, 0], ['disable', 1], ['enable', 0]) {
        $info->{store}{instant_ssid_hide}{0} = $case->[0];
        is($info->i_ssidbcast()->{'2.0.0.0.0.1.0.0.0'}, $case->[1], "hide $case->[0] translated");
    }
    $info->{store}{instant_ssid_hide}{0} = 'unknown';
    ok(!exists $info->i_ssidbcast()->{'2.0.0.0.0.1.0.0.0'}, 'unknown broadcast setting omitted');
}

sub bp_index : Tests(3) {
    my $info = shift->{info};
    is($info->bp_index()->{'02:00:00:00:01:f0'}, '2.0.0.0.0.1.0.0', 'bp_index__bssid__maps_to_radio_port');
    is($info->bp_index()->{1}, 1, 'BRIDGE-MIB mapping retained');
    $info->{store}{qb_fw_mac}{'1.2.0.0.0.255.3'} = _mac('02:00:00:00:ff:03');
    $info->{store}{qb_fw_port}{'1.2.0.0.0.255.3'} = 50;
    $info->{store}{qb_fw_mac}{'1.2.0.0.0.255.4'} = _mac('02:00:00:00:ff:04');
    $info->{store}{qb_fw_port}{'1.2.0.0.0.255.4'} = 0;
    my $bridge = $info->bp_index();
    ok(!exists $bridge->{50} && !exists $bridge->{0}, 'bp_index__qbridge_ports__no_identity_rows');
}

sub fw_mac : Tests(5) {
    my $info = shift->{info};
    is($info->fw_mac()->{'instant.2.0.0.0.0.10'}, '02:00:00:00:00:0a', 'associated client MAC');

    $info->{store}{instant_wlan_mac}{'2.0.0.0.0.1.2'} = _mac('02:00:00:00:01:00');
    $info->{store}{instant_client_bssid}{'2.0.0.0.0.11'} = _mac('02:00:00:00:01:00');
    ok(!exists $info->fw_mac()->{'instant.2.0.0.0.0.11'}
        && !exists $info->bp_index()->{'02:00:00:00:01:00'},
        'fw_mac__client_on_wlan_no_radio_fits__client_omitted');

    $info->{store}{instant_radio_channel}{'2.0.0.0.0.1.0'} = '';
    my $iid = $info->bp_index()->{$info->fw_port()->{'instant.2.0.0.0.0.10'}};
    ok(($info->interfaces()->{$iid // ''} // '') eq '02:00:00:00:00:01.radio0'
        && !exists $info->i_80211channel()->{'2.0.0.0.0.1.0.0'},
        'fw_mac__radio_without_channel__client_still_on_radio_port');

    delete $info->{store}{instant_radio_channel}{'2.0.0.0.0.1.0'};
    $iid = $info->bp_index()->{$info->fw_port()->{'instant.2.0.0.0.0.10'}};
    is($info->interfaces()->{$iid // ''}, '02:00:00:00:00:01.radio0',
        'fw_mac__radio_missing_from_channel_table__client_still_on_radio_port');

    $info->{store}{instant_client_bssid}{'2.0.0.0.0.10'} = _mac('02:00:00:00:02:00');
    ok(!exists $info->fw_mac()->{'instant.2.0.0.0.0.10'}, 'fw_mac__unmapped_bssid__client_omitted');
}

sub fw_port : Tests(1) {
    my $info = shift->{info};
    is($info->fw_port()->{'instant.2.0.0.0.0.10'}, '02:00:00:00:01:f0', 'associated client BSSID');
}

# aiClientTable rows, keyed by client MAC, for clients on a mapped BSSID.
sub cd11_mac : Tests(4) {
    my $info = shift->{info};
    is($info->cd11_mac()->{'2.0.0.0.0.10'}, '02:00:00:00:00:0a', 'cd11_mac__client__mac_from_index');

    # The client MAC is the table's index, so the class reads no column for it.
    delete $info->{store}{instant_client_mac};
    delete $info->{'_instant_client_mac'};
    is($info->cd11_mac()->{'2.0.0.0.0.18'}, '02:00:00:00:00:12',
        'cd11_mac__aiClientMACAddress_not_walked__mac_from_bssid_index');
    is($info->fw_mac()->{'instant.2.0.0.0.0.18'}, '02:00:00:00:00:12',
        'fw_mac__aiClientMACAddress_not_walked__client_still_reported');

    $info->{store}{instant_client_bssid}{'2.0.0.0.300.1'} = _mac('02:00:00:00:01:f0');
    ok(!exists $info->cd11_mac()->{'2.0.0.0.300.1'}, 'cd11_mac__index_not_a_mac__client_omitted');
}

sub cd11_ssid : Tests(2) {
    my $info = shift->{info};
    is($info->cd11_ssid()->{'2.0.0.0.0.10'}, 'Test WLAN 1', 'cd11_ssid__client_on_bssid_f0__ssid_of_that_wlan');
    $info->{store}{instant_client_bssid}{'2.0.0.0.0.11'} = _mac('02:00:00:00:01:e2');
    is($info->cd11_ssid()->{'2.0.0.0.0.11'}, 'Test WLAN 3', 'cd11_ssid__client_on_bssid_e2__ssid_of_that_wlan');
}

sub cd11_txrate : Tests(3) {
    my $info = shift->{info};
    my $rates = $info->cd11_txrate();
    is_deeply($rates->{'2.0.0.0.0.10'}, [433], 'cd11_txrate__client__mbps_in_arrayref');
    my @keys = sort keys %$rates;
    is_deeply([map { [sort keys %{$info->$_()}] } qw/cd11_mac cd11_ssid cd11_sigqual
        cd11_uptime cd11_txbyte cd11_rxbyte cd11_txpkt cd11_rxpkt/],
        [map { \@keys } 1 .. 8], 'cd11_txrate__every_cd11_method__same_keys');
    $info->{store}{instant_client_bssid}{'2.0.0.0.0.10'} = _mac('02:00:00:00:02:00');
    ok(!exists $info->cd11_txrate()->{'2.0.0.0.0.10'}, 'cd11_txrate__unmapped_bssid_client__omitted');
}

sub cd11_sigqual : Tests(1) {
    my $info = shift->{info};
    is($info->cd11_sigqual()->{'2.0.0.0.0.10'}, 40, 'cd11_sigqual__client__aiClientSNR');
}

sub cd11_sigstrength : Tests(1) {
    my $info = shift->{info};
    is_deeply($info->cd11_sigstrength(), {}, 'cd11_sigstrength__no_rssi_in_ai_ap_mib__empty');
}

sub cd11_uptime : Tests(1) {
    my $info = shift->{info};
    is($info->cd11_uptime()->{'2.0.0.0.0.10'}, 1202700, 'cd11_uptime__client__aiClientUptime');
}

sub cd11_txbyte : Tests(1) {
    my $info = shift->{info};
    is($info->cd11_txbyte()->{'2.0.0.0.0.10'}, 865753936, 'cd11_txbyte__client__aiClientTxDataBytes');
}

sub cd11_rxbyte : Tests(1) {
    my $info = shift->{info};
    is($info->cd11_rxbyte()->{'2.0.0.0.0.10'}, 558334355, 'cd11_rxbyte__client__aiClientRxDataBytes');
}

sub cd11_txpkt : Tests(1) {
    my $info = shift->{info};
    is($info->cd11_txpkt()->{'2.0.0.0.0.10'}, 978033, 'cd11_txpkt__client__aiClientTxDataFrames');
}

sub cd11_rxpkt : Tests(1) {
    my $info = shift->{info};
    is($info->cd11_rxpkt()->{'2.0.0.0.0.10'}, 11704, 'cd11_rxpkt__client__aiClientRxDataFrames');
}

# AP-225 / 8.4.0.0 radio rows from LibreNMS tests/snmpsim/aruba-instant.snmprec.
# MAC addresses anonymised; channels, powers, statuses and indexes retained.
sub _load_radios {
    my $test = shift;
    my $fixture = decode_json(read_text('xt/fixtures/aruba-instant-8.4-radios.json'));
    foreach my $method (keys %$fixture) {
        my %table = %{$fixture->{$method}};
        if ($method eq 'instant_radio_mac') {
            $table{$_} = pack('C6', map {hex $_} split /:/, $table{$_}) foreach keys %table;
        }
        $test->{info}{store}{$method} = {%{$test->{info}{store}{$method} || {}}, %table};
        $test->{info}{'_' . $method} = 1;
    }
    return $fixture;
}

sub radio_interfaces : Tests(1) {
    my $test = shift;
    $test->_load_radios();
    subtest 'Separate radio interfaces and channel joins' => sub {
        my $info = $test->{info};
        my $ports = $info->interfaces();
        is(scalar keys %$ports, 11, 'wired port and ten radios');
        ok(!grep({/\.wlan\d+$/} values %$ports), 'radio_interfaces__wlans__are_not_ports');
        is($ports->{'2.0.0.0.0.4.0.0'}, '02:00:00:00:00:04.radio0', 'radio index does not collide');
        foreach my $iid (keys %{$info->i_80211channel()}) {
            ok(exists $ports->{$iid}, 'channel joins a known radio port');
            like($ports->{$iid}, qr/\.radio\d+$/, 'channel is assigned to a radio');
            is($info->i_type()->{$iid}, 'ieee80211', 'radio is wireless');
        }
        foreach my $iid (keys %{$info->_radios()}) {
            my $source = $info->_radios()->{$iid}{source};
            ok(!exists $info->i_mac()->{$iid}, 'missing radio MAC stays unknown')
                unless exists $info->{store}{instant_radio_mac}{$source};
        }
        is(scalar keys %{$info->i_ssidlist()}, 8, 'radio interfaces do not invent SSIDs');
        is(scalar keys %{$info->fw_mac()}, 10, 'client and wired entries retained');
        done_testing();
    };
}

sub i_80211channel : Tests(1) {
    my $test = shift;
    my $fixture = $test->_load_radios();
    subtest 'Instant channel formats' => sub {
        my $info = $test->{info};
        my %expected = ('2.0.0.0.0.1.0.0' => 132, '2.0.0.0.0.1.1.0' => 11);
        foreach my $iid (keys %{$fixture->{instant_radio_channel}}) {
            (my $number = $fixture->{instant_radio_channel}{$iid}) =~ s/[ES]$//;
            $expected{"$iid.0"} = 0 + $number;
            like($info->i_description()->{"$iid.0"},
                qr/\Q$fixture->{instant_radio_channel}{$iid}\E\)/, 'raw channel retained in description');
        }
        is_deeply($info->i_80211channel(), \%expected, 'fixture channels parsed on every radio');
        is_deeply($info->i_80211channel('2.0.0.0.0.4.0.0'),
            {'2.0.0.0.0.4.0.0' => $expected{'2.0.0.0.0.4.0.0'}}, 'partial read uses synthetic radio index');
        foreach my $case (['132+', 132], ['36-', 36], ['11', 11], ['116E', 116], ['69S', 69]) {
            $info->{store}{instant_radio_channel}{'2.0.0.0.0.4.0'} = $case->[0];
            is($info->i_80211channel()->{'2.0.0.0.0.4.0.0'}, $case->[1], "$case->[0] channel parsed");
        }
        $info->{store}{instant_radio_channel}{'2.0.0.0.0.4.0'} = 'unknown';
        ok(!exists $info->i_80211channel()->{'2.0.0.0.0.4.0.0'}, 'unknown channel omitted');
        $info->{store}{instant_radio_channel} = {};
        is_deeply($info->i_80211channel(), {}, 'missing radio table returns empty channel map');
        done_testing();
    };
}

sub dot11_cur_tx_pwr_mw : Tests(1) {
    my $test = shift;
    $test->_load_radios();
    subtest 'dBm to integer milliwatts' => sub {
        my $info = $test->{info};
        is(scalar keys %{$info->dot11_cur_tx_pwr_mw()}, 10, 'powers exposed on every radio');
        is(scalar keys %{$info->dot11_cur_tx_pwr_mw('2.0.0.0.0.4.0.0')}, 1, 'partial power read is limited to selected radio');
        foreach my $case ([18, 63], [9, 8], [15, 32], [16, 40], [21, 126], [25, 316], [26, 398], [0, 1], [-3, 1]) {
            $info->{store}{instant_radio_power}{'2.0.0.0.0.4.0'} = $case->[0];
            is($info->dot11_cur_tx_pwr_mw()->{'2.0.0.0.0.4.0.0'}, $case->[1], "$case->[0] dBm converted");
        }
        $info->{store}{instant_radio_power}{'2.0.0.0.0.4.0'} = 'unknown';
        ok(!exists $info->dot11_cur_tx_pwr_mw()->{'2.0.0.0.0.4.0.0'}, 'invalid power omitted');
        $info->{store}{instant_radio_power} = {};
        is_deeply($info->dot11_cur_tx_pwr_mw(), {}, 'missing power stays unknown');
        done_testing();
    };
}

sub device_type : Tests(9) {
    my $test = shift;
    $test->SUPER::device_type();
    my $base = SNMP::Info->new(AutoSpecify => 0, Session => $test->mock_session);
    $base->cache({_layers => 72, _id => '.1.3.6.1.4.1.14823.1.2.107',
        _description => 'ArubaOS (MODEL: 515), Version 8.10.0.9', store => {}});
    is($base->device_type(), 'SNMP::Info::Layer3::ArubaInstant', 'initial discovery with sysServices 72');
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::ArubaInstant', 'Instant 8.x selected');
    $test->{info}{_description} = 'AOS-8 (MODEL: 515), Version 8.13.0.1-8.13.0.1 LSR';
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::ArubaInstant', 'newer AOS-8 description selected');
    $test->{info}{_description} = 'AOS-10 (MODEL: 635), Version 10.7.1.0-10.7.1.0 SSR';
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::Aruba', 'AOS-10 description excluded');
    # LibreNMS AP-105 capture: older Instant remains on the existing class.
    $test->{info}{_id} = '.1.3.6.1.4.1.14823.1.2.71';
    $test->{info}{_description} = 'ArubaOS (MODEL: 105), Version 6.4.4.8-4.2.4.12';
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::Aruba', 'Instant 6.4 retains existing class');
    $test->{info}{_id} = '.1.3.6.1.4.1.14823.1.2.107';
    $test->{info}{_description} = 'ArubaOS (MODEL: 515), Version 10.4.0.0';
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::Aruba', 'AOS10 retains existing class');
    $test->{info}{_description} = 'ArubaOS (MODEL: Aruba7210-US), Version 8.10.0.9';
    $test->{info}{_id} = '.1.3.6.1.4.1.14823.1.1.32';
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::Aruba', 'controller retains existing class');
}

1;
