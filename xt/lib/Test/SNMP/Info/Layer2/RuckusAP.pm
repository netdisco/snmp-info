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

# Shaped like an R350 on 6.1.2: the WLAN table is indexed by WLAN number,
# which ruckusWLANIfIndex repeats; it is not an IF-MIB ifIndex, and rows 2
# and 32 collide with unrelated interfaces. WLANs 0-31 are on wifi0 and
# 32-63 on wifi1. Row 64 has no wifi2, so it stays on its own interface;
# row 102 has neither.
sub _wireless_cache {
  my $info = shift;
  my $mac = sub { pack 'C*', 0x8c, 0x7a, 0x15, 0x00, @_ };
  $info->cache({
    '_i_index' => 1,
    '_i_description' => 1,
    '_ruckus_wlan_ssid' => 1,
    '_ruckus_wlan_bssid' => 1,
    '_ruckus_wlan_channel' => 1,
    '_ruckus_wlan_admin_status' => 1,
    '_ruckus_wlan_bcast_disabled' => 1,
    '_ruckus_wlan_name' => 1,
    '_ruckus_wlan_vlan' => 1,
    'store' => {
      i_index =>
        { map { $_ => $_ } 1, 2, 4, 7, 8, 11, 12, 13, 20, 21, 32, 40 },
      i_description => {
        1  => 'lo',     2  => 'tif0',   4  => 'eth0',
        7  => 'wifi1',  8  => 'wifi0',
        11 => 'wlan0',  12 => 'wlan1',  13 => 'wlan2',
        20 => 'wlan32', 21 => 'wlan33', 32 => 'br5',
        40 => 'wlan64',
      },
      ruckus_wlan_name => {
        ( map { $_ => "wlan$_" } 0, 1, 2, 4, 32, 33, 36, 64 ),
        102 => 'recovery-ssid',
      },
      ruckus_wlan_ssid => {
        0  => 'Staff', 1  => 'Guest', 2  => 'IoT',   4   => 'Spare',
        32 => 'Staff', 33 => 'Guest', 36 => 'Spare', 64  => 'Lab',
        102 => 'Recovery',
      },
      ruckus_wlan_bssid => {
        0  => $mac->( 0x10, 0xa0 ), 1  => $mac->( 0x10, 0xa1 ),
        2  => $mac->( 0x10, 0xa2 ), 4  => $mac->( 0x10, 0xa4 ),
        32 => $mac->( 0x10, 0xa8 ), 33 => $mac->( 0x10, 0xa9 ),
        36 => $mac->( 0x10, 0xac ), 64 => $mac->( 0x10, 0xb0 ),
        102 => $mac->( 0x10, 0xbf ),
      },
      ruckus_wlan_channel => {
        ( map { $_ => 6 } 0, 1, 2, 4, 102 ),
        ( map { $_ => 56 } 32, 33, 36 ),
        64 => 37,
      },
      ruckus_wlan_admin_status => {
        ( map { $_ => 1 } 0, 1, 2, 32, 33, 64, 102 ),
        4 => 2, 36 => 2,
      },
      ruckus_wlan_bcast_disabled => {
        ( map { $_ => 2 } 0, 2, 4, 32, 33, 36, 64, 102 ),
        1 => 1,
      },
      ruckus_wlan_vlan => {
        0  => 642, 1  => 642, 2  => 10,  4   => 72,
        32 => 642, 33 => 387, 36 => 72,  64  => 488,
        63 => 0,   102 => 1,
      },
    },
  });
}

# Clients on WLAN 2 (wifi0), 32 (wifi1), 4 (disabled) and 102 (no port).
sub _station_cache {
  my $info = shift;
  _wireless_cache($info);
  $info->{_ruckus_station_mac} = 1;
  $info->{store}{ruckus_station_mac} = {
    '2.6.0.17.34.51.68.85'   => pack( 'C*', 0, 17, 34, 51, 68, 85 ),
    '32.6.0.17.34.51.68.102' => pack( 'C*', 0, 17, 34, 51, 68, 102 ),
    '4.6.0.17.34.51.68.119'  => pack( 'C*', 0, 17, 34, 51, 68, 119 ),
    '102.6.0.17.34.51.68.136' => pack( 'C*', 0, 17, 34, 51, 68, 136 ),
  };
}

sub interfaces : Tests(1) {
  my $test = shift;
  _wireless_cache($test->{info});
  is_deeply($test->{info}->interfaces(), {
    1 => 'lo', 2 => 'tif0', 4 => 'eth0', 7 => 'wifi1', 8 => 'wifi0',
    32 => 'br5', 40 => 'wlan64',
  }, 'WLAN interfaces on a radio are dropped; one with no radio stays');
}

sub i_ssidlist : Tests(2) {
  my $test = shift;
  _wireless_cache($test->{info});
  is_deeply($test->{info}->i_ssidlist(), {
    '8.0'   => 'Staff', '8.1' => 'Guest', '8.2' => 'IoT',
    '7.32'  => 'Staff', '7.33' => 'Guest',
    '40.64' => 'Lab',
  }, 'active WLANs are keyed to their radio, or their own interface');
  is_deeply($test->{info}->i_ssidlist(7), {
    '7.32' => 'Staff', '7.33' => 'Guest',
  }, 'a partial selects one radio');
}

sub i_ssidmac : Tests(1) {
  my $test = shift;
  _wireless_cache($test->{info});
  is_deeply($test->{info}->i_ssidmac(), {
    '8.0'   => '8c:7a:15:00:10:a0', '8.1'  => '8c:7a:15:00:10:a1',
    '8.2'   => '8c:7a:15:00:10:a2', '7.32' => '8c:7a:15:00:10:a8',
    '7.33'  => '8c:7a:15:00:10:a9', '40.64' => '8c:7a:15:00:10:b0',
  }, 'each BSSID has the same key as its SSID');
}

sub i_ssidbcast : Tests(1) {
  my $test = shift;
  _wireless_cache($test->{info});
  is_deeply($test->{info}->i_ssidbcast(), {
    '8.0' => 1, '8.1' => 0, '8.2' => 1, '7.32' => 1, '7.33' => 1,
    '40.64' => 1,
  }, 'SSID broadcast state is the inverse of the disable flag');
}

sub i_80211channel : Tests(2) {
  my $test = shift;
  _wireless_cache($test->{info});
  is_deeply($test->{info}->i_80211channel(), { 8 => 6, 7 => 56, 40 => 37 },
    'one channel per radio port');
  is_deeply($test->{info}->i_80211channel(8), { 8 => 6 },
    'a partial selects one radio');
}

sub i_vlan_membership : Tests(2) {
  my $test = shift;
  _wireless_cache($test->{info});
  is_deeply($test->{info}->i_vlan_membership(), {
    8 => [ 10, 642 ], 7 => [ 387, 642 ], 40 => [488],
  }, 'each port carries the VLANs of its active WLANs, once each');
  is_deeply($test->{info}->i_vlan_membership(7), { 7 => [ 387, 642 ] },
    'a partial selects one radio');
}

sub qb_fw_vlan : Tests(1) {
  my $test = shift;
  _station_cache($test->{info});
  is_deeply($test->{info}->qb_fw_vlan(), {
    '2.6.0.17.34.51.68.85'   => 10,
    '32.6.0.17.34.51.68.102' => 642,
  }, 'each placed client carries its WLAN VLAN, keyed like fw_mac');
}

sub fw_mac : Tests(1) {
  my $test = shift;
  _station_cache($test->{info});
  is_deeply($test->{info}->fw_mac(), {
    '2.6.0.17.34.51.68.85'   => '00:11:22:33:44:55',
    '32.6.0.17.34.51.68.102' => '00:11:22:33:44:66',
  }, 'clients of active WLANs with a port are decoded');
}

sub fw_port : Tests(1) {
  my $test = shift;
  _station_cache($test->{info});
  is_deeply($test->{info}->fw_port(), {
    '2.6.0.17.34.51.68.85'   => 8,
    '32.6.0.17.34.51.68.102' => 7,
  }, 'each client is on its radio port, not the ifIndex of its WLAN number');
}

sub fw_ssid : Tests(1) {
  my $test = shift;
  _station_cache($test->{info});
  is_deeply($test->{info}->fw_ssid(), {
    '2.6.0.17.34.51.68.85'   => 'IoT',
    '32.6.0.17.34.51.68.102' => 'Staff',
  }, 'each client carries its WLAN SSID');
}

sub bp_index : Tests(1) {
  my $test = shift;
  _station_cache($test->{info});
  my $bp_index = $test->{info}->bp_index();
  my $fw_port  = $test->{info}->fw_port();
  is_deeply([ sort { $a <=> $b } map { $bp_index->{$_} } values %$fw_port ],
    [ 7, 8 ], 'every client port maps through bp_index to a radio');
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

sub cd11_txrate : Tests(2) {
  my $test = shift;
  $test->{info}->cache({
    '_ruckus_station_rks_txrate' => 1,
    '_ruckus_station_stats_ssid' => 1,
    'store' => {
      ruckus_station_rks_txrate => { '5.0.17.34.51.68.85' => 200000 },
      ruckus_station_stats_ssid => { '5.6.0.17.34.51.68.85' => 'Staff' },
    },
  });
  is_deeply($test->{info}->cd11_txrate(), {
    '5.6.0.17.34.51.68.85' => [200],
  }, 'PHY rate is normalized to Mbps and the station stats index');
  is_deeply([ sort keys %{ $test->{info}->cd11_txrate() } ],
    [ sort keys %{ $test->{info}->cd11_ssid() } ],
    'rate keys join the SSID keys of the same station');
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

sub device_type : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  foreach my $id (qw/.1.3.6.1.4.1.25053.3.1.4.89
      .1.3.6.1.4.1.25053.3.1.4.101/) {
    $info->clear_cache();
    $info->cache({
      '_description' => 'Ruckus Wireless Inc (C) 2006 ',
      '_id'          => $id,
    });
    is($info->device_type(), 'SNMP::Info::Layer2::RuckusAP',
      "AP product OID $id without sysServices selects RuckusAP");
  }

  $info->clear_cache();
  $info->cache({
    '_layers'      => 6,
    '_description' => 'Ruckus Wireless ZD1200',
    '_id'          => '.1.3.6.1.4.1.25053.3.1.5.15',
  });
  isnt($info->device_type(), 'SNMP::Info::Layer2::RuckusAP',
    'a ZoneDirector does not select RuckusAP');

  $info->clear_cache();
  $info->cache({
    '_layers'      => 6,
    '_description' => 'Ruckus SmartZone',
    '_id'          => '.1.3.6.1.4.1.25053.3.1.11.1',
  });
  is($info->device_type(), 'SNMP::Info::Layer3::RuckusController',
    'a SmartZone controller keeps its own class');
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
