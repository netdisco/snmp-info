# Test::SNMP::Info::Layer2::RuckusAP

package Test::SNMP::Info::Layer2::RuckusAP;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer2::RuckusAP;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  $test->{info}->cache({
    '_layers'      => 0,
    '_description' => 'Ruckus Wireless Inc (C) 2006',
    '_id'          => '.1.3.6.1.4.1.25053.3.1.4.121',
    '_ruckus_model'  => 'R350',
    '_ruckus_serial' => 'SERIAL-REDACTED',
    '_ruckus_sw_rev'        => 1,
    '_ruckus_sw_rev_status' => 1,
    'store' => {
      'ruckus_sw_rev' => {
        1 => '6.0.0.0.1234',
        2 => '6.1.2.0.4172',
      },
      'ruckus_sw_rev_status' => {
        1 => 1,
        2 => 2,
      },
    },
  });
}

sub vendor : Tests(1) {
  my $test = shift;
  is($test->{info}->vendor(), 'ruckus', 'Vendor is ruckus');
}

sub layers : Tests(1) {
  my $test = shift;
  is($test->{info}->layers(), '00000010',
    'Reports layer 2 when the AP does not implement sysServices');
}

sub os : Tests(1) {
  my $test = shift;
  is($test->{info}->os(), 'ruckus', 'OS is ruckus');
}

sub model : Tests(2) {
  my $test = shift;
  is($test->{info}->model(), 'R350', 'Model comes from the hardware MIB');

  # An Unleashed R770 does not answer RUCKUS-HWINFO-MIB.
  $test->{info}->clear_cache();
  $test->{info}->cache({
    '_layers'      => 0,
    '_description' => 'Ruckus Wireless R770',
    '_id'          => '.1.3.6.1.4.1.25053.3.1.4.125',
  });
  is($test->{info}->model(), 'R770',
    'Model comes from sysDescr when the hardware MIB is silent');
}

sub serial : Tests(1) {
  my $test = shift;
  is($test->{info}->serial(), 'SERIAL-REDACTED',
    'Serial comes from the hardware MIB');
}

sub os_ver : Tests(3) {
  my $test = shift;

  is($test->{info}->os_ver(), '6.1.2.0.4172',
    'Returns the revision whose status marks it active');

  $test->{info}->cache({
    '_ruckus_sw_rev'        => 1,
    '_ruckus_sw_rev_status' => 1,
    'store' => {
      'ruckus_sw_rev' => {
        1 => '6.0.0.0.1234',
        2 => '6.1.2.0.4172',
      },
      'ruckus_sw_rev_status' => {
        1 => 'active',
        2 => 'inactive',
      },
    },
  });
  is($test->{info}->os_ver(), '6.0.0.0.1234',
    'Accepts the active enum label as well as its numeric value');

  # An R500 on 9.13 answers ruckusSwRevision.1 but has no ruckusSwRevStatus.
  $test->{info}->clear_cache();
  $test->{info}->cache({
    '_ruckus_sw_rev' => 1,
    'store' => {
      'ruckus_sw_rev' => { 1 => '9.13.3.0.145' },
    },
  });
  is($test->{info}->os_ver(), '9.13.3.0.145',
    'Falls back to the first revision when no row has a status');
}

sub _wireless_cache {
  my $info = shift;
  $info->cache({
    '_i_index' => 1,
    '_ruckus_wlan_ssid' => 1,
    '_ruckus_wlan_bssid' => 1,
    '_ruckus_wlan_channel' => 1,
    '_ruckus_wlan_admin_status' => 1,
    '_ruckus_wlan_bcast_disabled' => 1,
    '_ruckus_wlan_ifindex' => 1,
    'store' => {
      i_index => { 5 => 5, 6 => 6 },
      ruckus_wlan_ssid => {
        5   => 'R_WLAN_IPP',
        6   => 'Wireless2',
        100 => 'Wireless3',
      },
      ruckus_wlan_bssid => {
        5   => pack('C*', 0, 17, 34, 51, 68, 85),
        6   => pack('C*', 0, 17, 34, 51, 68, 102),
        100 => pack('C*', 0, 17, 34, 51, 68, 119),
      },
      ruckus_wlan_channel => { 5 => 44, 6 => 44, 100 => 149 },
      ruckus_wlan_admin_status => { 5 => 1, 6 => 2, 100 => 1 },
      ruckus_wlan_bcast_disabled => { 5 => 2, 6 => 1, 100 => 2 },
      ruckus_wlan_ifindex => { 5 => 5, 6 => 6, 100 => 100 },
    },
  });
}

sub i_ssidlist : Tests(1) {
  my $test = shift;
  _wireless_cache($test->{info});
  is_deeply($test->{info}->i_ssidlist(), { '5.5' => 'R_WLAN_IPP' },
    'only active WLANs mapped to real IF-MIB interfaces are returned');
}

sub i_ssidmac : Tests(1) {
  my $test = shift;
  _wireless_cache($test->{info});
  is_deeply($test->{info}->i_ssidmac(), { '5.5' => '00:11:22:33:44:55' },
    'active WLAN BSSID uses the SSID interface key');
}

sub i_ssidbcast : Tests(1) {
  my $test = shift;
  _wireless_cache($test->{info});
  is_deeply($test->{info}->i_ssidbcast(), { '5.5' => 1 },
    'SSID broadcast state is the inverse of the disable flag');
}

sub i_80211channel : Tests(1) {
  my $test = shift;
  _wireless_cache($test->{info});
  is_deeply($test->{info}->i_80211channel(), { 5 => 44 },
    'active WLAN channels map to real IF-MIB indexes');
}

sub fw_mac : Tests(1) {
  my $test = shift;
  _wireless_cache($test->{info});
  $test->{info}{_ruckus_station_mac} = 1;
  $test->{info}{store}{ruckus_station_mac} = {
    '5.6.0.17.34.51.68.85' => pack('C*', 0, 17, 34, 51, 68, 85),
  };
  is($test->{info}->fw_mac()->{'5.6.0.17.34.51.68.85'}, '00:11:22:33:44:55',
    'associated station MAC is decoded');
}

sub fw_port : Tests(2) {
  my $test = shift;
  _wireless_cache($test->{info});
  $test->{info}{_ruckus_station_mac} = 1;
  $test->{info}{store}{ruckus_station_mac} = {
    '5.6.0.17.34.51.68.85' => pack('C*', 0, 17, 34, 51, 68, 85),
  };
  is($test->{info}->fw_port()->{'5.6.0.17.34.51.68.85'}, 5,
    'associated station maps to its AP interface');

  # The station index starts with an ifIndex, whatever the WLAN row number.
  $test->{info}{store}{ruckus_wlan_admin_status} = { 1 => 1 };
  $test->{info}{store}{ruckus_wlan_ifindex}      = { 1 => 5 };
  is($test->{info}->fw_port()->{'5.6.0.17.34.51.68.85'}, 5,
    'station maps by ifIndex when the WLAN row number differs');
}

sub fw_ssid : Tests(1) {
  my $test = shift;
  _wireless_cache($test->{info});
  $test->{info}{_ruckus_station_mac} = 1;
  $test->{info}{store}{ruckus_station_mac} = {
    '5.6.0.17.34.51.68.85' => pack('C*', 0, 17, 34, 51, 68, 85),
    '100.6.0.17.34.51.68.102' => pack('C*', 0, 17, 34, 51, 68, 102),
  };
  is_deeply($test->{info}->fw_ssid(), {
    '5.6.0.17.34.51.68.85' => 'R_WLAN_IPP',
  }, 'station maps only through an active WLAN with a real interface');
}

sub bp_index : Tests(1) {
  my $test = shift;
  _wireless_cache($test->{info});
  is_deeply($test->{info}->bp_index(), { 5 => 5, 6 => 6 },
    'AP interface indexes map to themselves');
}

sub cd11_mac : Tests(1) {
  my $test = shift;
  $test->{info}->cache({
    '_ruckus_station_stats_mac' => 1,
    'store' => { ruckus_station_stats_mac => {
      '5.6.0.17.34.51.68.85' => pack('C*', 0, 17, 34, 51, 68, 85),
    } },
  });
  is_deeply($test->{info}->cd11_mac(), {
    '5.6.0.17.34.51.68.85' => '00:11:22:33:44:55',
  }, 'wireless metrics MAC is decoded');
}

sub cd11_ssid : Tests(1) {
  my $test = shift;
  $test->{info}->cache({
    '_ruckus_station_stats_ssid' => 1,
    'store' => { ruckus_station_stats_ssid => {
      '5.6.0.17.34.51.68.85' => 'R_WLAN_IPP',
    } },
  });
  is_deeply($test->{info}->cd11_ssid(), {
    '5.6.0.17.34.51.68.85' => 'R_WLAN_IPP',
  }, 'wireless metrics include the associated SSID');
}

sub cd11_txrate : Tests(1) {
  my $test = shift;
  $test->{info}->cache({
    '_ruckus_station_rks_txrate' => 1,
    'store' => { ruckus_station_rks_txrate => {
      '5.0.17.34.51.68.85' => 200000,
    } },
  });
  is_deeply($test->{info}->cd11_txrate(), {
    '5.6.0.17.34.51.68.85' => [200],
  }, 'PHY rate is normalized to Mbps and the station stats index');
}

sub cd11_rateset : Tests(2) {
  my $test = shift;
  $test->{info}->cache({
    '_ruckus_station_rates' => 1,
    'store' => { ruckus_station_rates => {
      '5.6.0.17.34.51.68.85' => '6 12 24',
    } },
  });
  is_deeply($test->{info}->cd11_rateset(), {
    '5.6.0.17.34.51.68.85' => [6, 12, 24],
  }, 'supported rates are decoded as Mbps');

  $test->{info}->cache({
    '_ruckus_station_rates' => 1,
    'store' => { ruckus_station_rates => {
      '5.6.0.17.34.51.68.85' => '1 2 5.5 11',
    } },
  });
  is_deeply($test->{info}->cd11_rateset(), {
    '5.6.0.17.34.51.68.85' => [1, 2, 5.5, 11],
  }, 'fractional rates in a rate string are kept');
}

sub cd11_sigstrength : Tests(1) {
  my $test = shift;
  $test->{info}->cache({
    '_ruckus_station_stats_rssi' => 1,
    'store' => { ruckus_station_stats_rssi => {
      '5.6.0.17.34.51.68.85' => 37,
    } },
  });
  is_deeply($test->{info}->cd11_sigstrength(), {
    '5.6.0.17.34.51.68.85' => 37,
  }, 'station RSSI is returned');
}

sub cd11_rxpkt : Tests(1) {
  my $test = shift;
  $test->{info}->cache({ '_ruckus_station_stats_rxpkt' => 1,
    'store' => { ruckus_station_stats_rxpkt => {
      '5.6.0.17.34.51.68.85' => 12,
    } } });
  is_deeply($test->{info}->cd11_rxpkt(), {
    '5.6.0.17.34.51.68.85' => 12,
  }, 'received data frames are returned');
}

sub cd11_txpkt : Tests(1) {
  my $test = shift;
  $test->{info}->cache({ '_ruckus_station_stats_txpkt' => 1,
    'store' => { ruckus_station_stats_txpkt => {
      '5.6.0.17.34.51.68.85' => 34,
    } } });
  is_deeply($test->{info}->cd11_txpkt(), {
    '5.6.0.17.34.51.68.85' => 34,
  }, 'transmitted data frames are returned');
}

sub cd11_rxbyte : Tests(1) {
  my $test = shift;
  $test->{info}->cache({ '_ruckus_station_stats_rxbyte' => 1,
    'store' => { ruckus_station_stats_rxbyte => {
      '5.6.0.17.34.51.68.85' => 1200,
    } } });
  is_deeply($test->{info}->cd11_rxbyte(), {
    '5.6.0.17.34.51.68.85' => 1200,
  }, 'received bytes are returned');
}

sub cd11_txbyte : Tests(1) {
  my $test = shift;
  $test->{info}->cache({ '_ruckus_station_stats_txbyte' => 1,
    'store' => { ruckus_station_stats_txbyte => {
      '5.6.0.17.34.51.68.85' => 3400,
    } } });
  is_deeply($test->{info}->cd11_txbyte(), {
    '5.6.0.17.34.51.68.85' => 3400,
  }, 'transmitted bytes are returned');
}

sub ruckus_mibs : Tests(1) {
  my %mibs = %SNMP::Info::Layer2::RuckusAP::MIBS;
  is_deeply(
    [ @mibs{qw/RUCKUS-HWINFO-MIB RUCKUS-SWINFO-MIB RUCKUS-WLAN-MIB/} ],
    [qw/ruckusHwInfoModelNumber ruckusSwRevision ruckusWLANSSID/],
    'identity and wireless methods load their declared Ruckus MIBs'
  );
}

1;
