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
    foreach my $method (qw/instant_wlan_mac instant_client_mac instant_client_bssid i_mac qb_fw_mac/) {
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
        my $bssids = $info->i_ssidmac();
        my $macs = $info->fw_mac();
        my $fw_ports = $info->fw_port();
        my $bridge = $info->bp_index();
        is(scalar keys %$ports, 9, 'eight WLANs and the wired uplink');
        is($ports->{1}, 'Ethernet1', 'wired interface preserved');
        is(scalar keys %$ssids, 8, 'all eight SSID entries exposed');
        is(scalar keys %$macs, 10, 'nine clients and wired forwarding entry');
        is($macs->{'1.2.0.0.0.255.2'}, '02:00:00:00:ff:02', 'wired MAC preserved');
        is($bridge->{1}, 1, 'wired bridge mapping preserved');
        foreach my $key (sort keys %$ssids) {
            (my $iid = $key) =~ s/\.0$//;
            ok(exists $ports->{$iid}, 'SSID joins a known interface');
            is($info->i_mac()->{$iid}, $bssids->{$key}, 'interface MAC is BSSID');
            is($info->i_type()->{$iid}, 'ieee80211', 'WLAN has wireless type');
            is($info->i_up()->{$iid}, 'up', 'AP status used for WLAN');
            like($info->i_description()->{$iid}, qr/^Test AP: Test WLAN/, 'readable description');
        }
        foreach my $key (sort grep {/^instant\./} keys %$macs) {
            my $iid = $bridge->{$fw_ports->{$key}};
            ok(defined $iid && exists $ports->{$iid}, 'client joins a WLAN interface');
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
        $fixture = {%$fixture, %$radio_fixture};
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

sub i_index : Tests(2) {
    my $info = shift->{info};
    is($info->i_index()->{1}, 1, 'physical index retained');
    is($info->i_index()->{'2.0.0.0.0.1.0'}, '02:00:00:00:00:01.wlan0', 'stable logical index');
}

sub i_name : Tests(2) {
    my $info = shift->{info};
    is($info->i_name()->{1}, 'Ethernet1', 'physical name retained');
    $info->{store}{instant_ap_name}{'2.0.0.0.0.1'} = 'Renamed AP';
    is($info->i_name()->{'2.0.0.0.0.1.0'}, '02:00:00:00:00:01.wlan0', 'AP rename preserves port identity');
}

sub i_description : Tests(2) {
    my $info = shift->{info};
    is($info->i_description()->{1}, 'Ethernet uplink', 'physical description retained');
    $info->{store}{instant_ap_name} = {};
    $info->{store}{instant_wlan_ssid} = {};
    is($info->i_description()->{'2.0.0.0.0.1.0'}, '02:00:00:00:00:01: WLAN 0', 'description with missing name and SSID');
}

sub i_type : Tests(2) {
    my $info = shift->{info};
    is($info->i_type()->{1}, 'ethernetCsmacd', 'wired type retained');
    is($info->i_type()->{'2.0.0.0.0.1.0'}, 'ieee80211', 'logical port is wireless');
}

sub i_mac : Tests(2) {
    my $info = shift->{info};
    is($info->i_mac()->{1}, '02:00:00:00:ff:01', 'wired MAC retained');
    is($info->i_mac()->{'2.0.0.0.0.1.0'}, '02:00:00:00:00:02', 'logical port uses BSSID');
}

sub i_up : Tests(2) {
    my $info = shift->{info};
    $info->{store}{instant_ap_status}{'2.0.0.0.0.1'} = '2';
    is($info->i_up()->{'2.0.0.0.0.1.0'}, 'down', 'numeric AP down status');
    $info->{store}{instant_ap_status}{'2.0.0.0.0.1'} = 'up';
    is($info->i_up()->{'2.0.0.0.0.1.0'}, 'up', 'enum AP up status');
}

sub i_up_admin : Tests(2) {
    my $info = shift->{info};
    is($info->i_up_admin()->{1}, 'up', 'wired administrative status retained');
    is($info->i_up_admin()->{'2.0.0.0.0.1.0'}, 'up', 'logical status reflects AP status');
}

sub i_ssidlist : Tests(1) {
    my $info = shift->{info};
    is($info->i_ssidlist()->{'2.0.0.0.0.1.0.0'}, 'Test WLAN 1', 'SSID appended to logical interface index');
}

sub i_ssidmac : Tests(1) {
    my $info = shift->{info};
    is($info->i_ssidmac()->{'2.0.0.0.0.1.0.0'}, '02:00:00:00:00:02', 'SSID and BSSID share index');
}

sub i_ssidbcast : Tests(5) {
    my $info = shift->{info};
    foreach my $case ([0, 1], [1, 0], ['disable', 1], ['enable', 0]) {
        $info->{store}{instant_ssid_hide}{0} = $case->[0];
        is($info->i_ssidbcast()->{'2.0.0.0.0.1.0.0'}, $case->[1], "hide $case->[0] translated");
    }
    $info->{store}{instant_ssid_hide}{0} = 'unknown';
    ok(!exists $info->i_ssidbcast()->{'2.0.0.0.0.1.0.0'}, 'unknown broadcast setting omitted');
}

sub bp_index : Tests(1) {
    my $info = shift->{info};
    is($info->bp_index()->{'02:00:00:00:00:02'}, '2.0.0.0.0.1.0', 'BSSID maps to logical interface');
}

sub fw_mac : Tests(1) {
    my $info = shift->{info};
    is($info->fw_mac()->{'instant.2.0.0.0.0.10'}, '02:00:00:00:00:0a', 'associated client MAC');
}

sub fw_port : Tests(1) {
    my $info = shift->{info};
    is($info->fw_port()->{'instant.2.0.0.0.0.10'}, '02:00:00:00:00:02', 'associated client BSSID');
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
        $test->{info}{store}{$method} = \%table;
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
        is(scalar keys %$ports, 17, 'wired port, eight WLANs and eight radios');
        is($ports->{'2.0.0.0.0.1.0'}, '02:00:00:00:00:01.wlan0', 'WLAN identity retained');
        is($ports->{'2.0.0.0.0.1.0.0'}, '02:00:00:00:00:01.radio0', 'radio index does not collide');
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
        ok(!exists $info->i_80211channel()->{'2.0.0.0.0.1.0'}, 'no inferred WLAN channel');
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
        my %expected;
        foreach my $iid (keys %{$fixture->{instant_radio_channel}}) {
            (my $number = $fixture->{instant_radio_channel}{$iid}) =~ s/[ES]$//;
            $expected{"$iid.0"} = 0 + $number;
            like($info->i_description()->{"$iid.0"},
                qr/\Q$fixture->{instant_radio_channel}{$iid}\E\)/, 'raw channel retained in description');
        }
        is_deeply($info->i_80211channel(), \%expected, 'all eight public fixture channels parsed');
        is_deeply($info->i_80211channel('2.0.0.0.0.1.0.0'),
            {'2.0.0.0.0.1.0.0' => $expected{'2.0.0.0.0.1.0.0'}}, 'partial read uses synthetic radio index');
        foreach my $case (['132+', 132], ['36-', 36], ['11', 11], ['116E', 116], ['69S', 69]) {
            $info->{store}{instant_radio_channel}{'2.0.0.0.0.1.0'} = $case->[0];
            is($info->i_80211channel()->{'2.0.0.0.0.1.0.0'}, $case->[1], "$case->[0] channel parsed");
        }
        $info->{store}{instant_radio_channel}{'2.0.0.0.0.1.0'} = 'unknown';
        ok(!exists $info->i_80211channel()->{'2.0.0.0.0.1.0.0'}, 'unknown channel omitted');
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
        is(scalar keys %{$info->dot11_cur_tx_pwr_mw()}, 8, 'all public fixture powers exposed');
        is(scalar keys %{$info->dot11_cur_tx_pwr_mw('2.0.0.0.0.1.0.0')}, 1, 'partial power read is limited to selected radio');
        foreach my $case ([18, 63], [9, 8], [15, 32], [16, 40], [21, 126], [25, 316], [26, 398], [0, 1], [-3, 1]) {
            $info->{store}{instant_radio_power}{'2.0.0.0.0.1.0'} = $case->[0];
            is($info->dot11_cur_tx_pwr_mw()->{'2.0.0.0.0.1.0.0'}, $case->[1], "$case->[0] dBm converted");
        }
        $info->{store}{instant_radio_power}{'2.0.0.0.0.1.0'} = 'unknown';
        ok(!exists $info->dot11_cur_tx_pwr_mw()->{'2.0.0.0.0.1.0.0'}, 'invalid power omitted');
        $info->{store}{instant_radio_power} = {};
        is_deeply($info->dot11_cur_tx_pwr_mw(), {}, 'missing power stays unknown');
        done_testing();
    };
}

sub detection_scope : Tests(6) {
    my $test = shift;
    my $base = SNMP::Info->new(AutoSpecify => 0, Session => $test->mock_session);
    $base->cache({_layers => 72, _id => '.1.3.6.1.4.1.14823.1.2.107',
        _description => 'ArubaOS (MODEL: 515), Version 8.10.0.9', store => {}});
    is($base->device_type(), 'SNMP::Info::Layer3::ArubaInstant', 'initial discovery with sysServices 72');
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::ArubaInstant', 'Instant 8.x selected');
    $test->{info}{_description} = 'AOS-8 (MODEL: 515), Version 8.13.0.1-8.13.0.1 LSR';
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::ArubaInstant', 'newer AOS-8 description selected');
    $test->{info}{_description} = 'AOS-10 (MODEL: 635), Version 10.7.1.0-10.7.1.0 SSR';
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::Aruba', 'AOS-10 description excluded');
    $test->{info}{_description} = 'ArubaOS (MODEL: 515), Version 10.4.0.0';
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::Aruba', 'AOS10 retains existing class');
    $test->{info}{_description} = 'ArubaOS (MODEL: Aruba7210-US), Version 8.10.0.9';
    $test->{info}{_id} = '.1.3.6.1.4.1.14823.1.1.32';
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::Aruba', 'controller retains existing class');
}

1;
