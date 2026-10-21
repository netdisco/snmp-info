package Test::SNMP::Info::Layer3::C9800;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::C9800;

sub startup : Tests(startup => 1) {
  my $test = shift;
  $test->SUPER::startup();
  $test->todo_methods(1);
}

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  $test->{info}->cache({
    '_layers'      => 6,
    '_description' => 'Cisco IOS Software [Cupertino], C9800-CL Software '
      . '(C9800-CL-K9_IOSXE), Version 17.9.4a, RELEASE SOFTWARE (fc3)',
    '_id' => '.1.3.6.1.4.1.9.1.2391',
    'store' => {},
  });
}

sub inherited_classes : Tests(5) {
  my $test = shift;
  isa_ok $test->{info}, 'SNMP::Info::Layer2::Airespace';
  isa_ok $test->{info}, 'SNMP::Info::CiscoVTP';
  isa_ok $test->{info}, 'SNMP::Info::CiscoStats';
  isa_ok $test->{info}, 'SNMP::Info::LLDP';
  isa_ok $test->{info}, 'SNMP::Info::EtherLike';
}

sub serial1 : Tests(3) {
  my $test = shift;

  can_ok $test->{info}, 'serial1';
  is $SNMP::Info::Layer3::C9800::GLOBALS{'serial1'},
    '.1.3.6.1.4.1.9.3.6.3.0', 'Chassis serial is OLD-CISCO-CHASSIS-MIB chassisId';

  $test->{info}->cache({'_serial1' => '9TREOJ3BGE0', 'store' => {}});
  is $test->{info}->serial1, '9TREOJ3BGE0', 'Chassis serial is returned';
}

sub os : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'os';
  is $test->{info}->os, 'ios-xe', 'OS is IOS-XE from sysDescr';
}

sub cisco_comm_indexing : Tests(1) {
  my $test = shift;

  # macsuck ignores qb_fw_vlan when this is true and polls community@vlan
  is $test->{info}->cisco_comm_indexing, 0,
    'Client VLANs come from qb_fw_vlan, not per-VLAN community indexing';
}

sub serial : Tests(4) {
  my $test = shift;

  can_ok $test->{info}, 'serial';
  is $SNMP::Info::Layer3::C9800::FUNCS{'c9800_entity_descr'},
    'entPhysicalDescr', 'Entity descriptions are available';

  $test->{info}->cache({
    '_c9800_entity_descr'  => 1,
    '_c9800_entity_serial' => 1,
    'store' => {
      'c9800_entity_descr' => {
        1   => 'Cisco C9800 Dual Chassis',
        2   => 'Cisco C9800-80-K9 Chassis',
        3   => 'Power Supply Bay',
        500 => 'Cisco C9800-80-K9 Chassis',
      },
      'c9800_entity_serial' => {
        1   => 'SERIAL1',
        2   => 'TESTSERIAL002',
        3   => 'PSU123456',
        500 => 'SERIAL500',
      },
    },
  });
  is $test->{info}->serial, 'SERIAL1 TESTSERIAL002 SERIAL500',
    'Serial concatenates values at chassis indexes 1, 2, and 500';

  $test->{info}->clear_cache;
  is $test->{info}->serial, undef, 'Serial is undefined without chassis data';
}

sub os_ver : Tests(4) {
  my $test = shift;

  can_ok $test->{info}, 'os_ver';
  is $SNMP::Info::Layer3::C9800::GLOBALS{'c9800_os_ver'},
    '.1.3.6.1.2.1.16.19.2.0', 'IOS-XE version scalar is configured';

  $test->{info}->cache({
    '_c9800_os_ver' => '17.15.5',
    'store'          => {},
  });
  is $test->{info}->os_ver, '17.15.5',
    'IOS-XE version is read from the version scalar';

  $test->{info}->clear_cache;
  my $description = 'Cisco IOS Software [Cupertino], C9800-CL Software '
    . '(C9800-CL-K9_IOSXE), Version 17.9.4a, RELEASE SOFTWARE (fc3)';
  $test->{info}->cache({
    '_layers'      => 6,
    '_description' => $description,
    '_id'          => '.1.3.6.1.4.1.9.1.2391',
    'store'        => {},
  });
  is $test->{info}->os_ver, '17.9.4a',
    'IOS-XE version falls back to sysDescr parsing';
}

sub interfaces : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'interfaces';
  $test->{info}->cache({
    '_i_index'             => 1,
    '_i_description'       => 1,
    '_airespace_apif_slot' => 1,
    '_airespace_if_name'   => 1,
    'store' => {
      'i_index' => {
        1                 => 1,
        '2.0.0.0.0.1.0'   => '02:00:00:00:00:01.0',
      },
      'i_description' => {
        1 => 'GigabitEthernet1',
      },
      'airespace_apif_slot' => {},
      'airespace_if_name'   => {},
    },
  });

  cmp_deeply $test->{info}->interfaces, {
    1               => 'GigabitEthernet1',
    '2.0.0.0.0.1.0' => '02:00:00:00:00:01.0',
  }, 'Regular IOS-XE ports retain their IF-MIB names';
}

sub entities : Tests(4) {
  my $test = shift;

  $test->{info}->cache({
    '_c9800_entity_descr'  => 1,
    '_c9800_entity_class'  => 1,
    '_c9800_entity_serial' => 1,
    '_airespace_ap_model'  => 1,
    '_airespace_ap_name'   => 1,
    '_airespace_ap_loc'    => 1,
    '_airespace_ap_serial' => 1,
    'store' => {
      'c9800_entity_descr' => {
        1  => 'Cisco C9800-80-K9 Chassis',
        10 => 'Power Supply Module 0',
      },
      'c9800_entity_class' => {
        1  => 'chassis',
        10 => 'powerSupply',
      },
      'c9800_entity_serial' => {
        1  => 'CHASSIS001',
        10 => 'PSU001',
      },
      'airespace_ap_model' => {
        '2.0.0.0.0.1' => 'C9120AXI',
      },
      'airespace_ap_name' => {
        '2.0.0.0.0.1' => 'ap-1',
      },
      'airespace_ap_loc' => {
        '2.0.0.0.0.1' => 'Branch office',
      },
      'airespace_ap_serial' => {
        '2.0.0.0.0.1' => 'AP001',
      },
    },
  });

  cmp_deeply $test->{info}->e_index, {
    1               => 1,
    10              => 10,
    '2.0.0.0.0.1'   => 1,
  }, 'Entity index contains the physical chassis inventory and APs';
  cmp_deeply $test->{info}->e_class, {
    1               => 'chassis',
    10              => 'powerSupply',
    '2.0.0.0.0.1'   => 'ap',
  }, 'Entity classes contain the physical modules and APs';
  cmp_deeply $test->{info}->e_serial, {
    1               => 'CHASSIS001',
    10              => 'PSU001',
    '2.0.0.0.0.1'   => 'AP001',
  }, 'Entity serials contain the physical modules and APs';
  is $test->{info}->e_descr->{'2.0.0.0.0.1'},
    'C9120AXI: ap-1 (Branch office)',
    'AP descriptions remain in the merged entity inventory';
}

sub connection_descriptions : Tests(3) {
  my $test = shift;

  can_ok $test->{info}, 'i_description';
  $test->{info}->cache({
    '_i_index'              => 1,
    '_i_description'        => 1,
    '_airespace_apif_slot'  => 1,
    '_airespace_if_name'    => 1,
    '_airespace_ap_loc'     => 1,
    '_airespace_ap_name'    => 1,
    '_airespace_ap_model'   => 1,
    '_airespace_ap_ip'      => 1,
    '_airespace_ap_mac'     => 1,
    '_airespace_ap_ethermac' => 1,
    '_c9800_cdp_name'       => 1,
    '_c9800_cdp_address'    => 1,
    '_c9800_cdp_interface'  => 1,
    'store' => {
      'i_index'             => {},
      'i_description'       => {},
      'airespace_apif_slot' => {'2.0.0.0.0.1.0' => 0},
      'airespace_if_name'   => {},
      'airespace_ap_loc'    => {
        '2.0.0.0.0.1' => 'Branch office',
      },
      'airespace_ap_name' => {
        '2.0.0.0.0.1' => 'ap-1',
      },
      'airespace_ap_model' => {
        '2.0.0.0.0.1' => 'C9120AXI',
      },
      'airespace_ap_ip' => {
        '2.0.0.0.0.1' => '192.168.2.10',
      },
      'airespace_ap_mac' => {
        '2.0.0.0.0.1' => pack('C6', 2, 0, 0, 0, 0, 1),
      },
      'airespace_ap_ethermac' => {
        '2.0.0.0.0.1' => pack('C6', 2, 0, 0, 0, 0, 2),
      },
      'c9800_cdp_name' => {
        '2.0.0.0.0.1.2' => 'router-1',
      },
      'c9800_cdp_address' => {
        '2.0.0.0.0.1.2' => pack('C4', 192, 168, 2, 81),
      },
      'c9800_cdp_interface' => {
        '2.0.0.0.0.1.2' => 'Wlan-GigabitEthernet0/1/8',
      },
    },
  });

  is $test->{info}->i_description->{'2.0.0.0.0.1.0'},
    'Branch office; IP 192.168.2.10; Dot3 MAC 02:00:00:00:00:01; '
      . 'Ethernet MAC 02:00:00:00:00:02; '
      . 'Connected via router-1 '
      . 'Wlan-GigabitEthernet0/1/8 (192.168.2.81)',
    'AP port description includes its branch switch connection';

  is $test->{info}->e_descr->{'2.0.0.0.0.1'},
    'C9120AXI: ap-1 (Branch office); IP 192.168.2.10; '
      . 'Dot3 MAC 02:00:00:00:00:01; Ethernet MAC 02:00:00:00:00:02; '
      . 'Connected via router-1 '
      . 'Wlan-GigabitEthernet0/1/8 (192.168.2.81)',
    'AP module description includes its branch switch connection';
}

sub ap_tags : Tests(5) {
  my $test = shift;

  can_ok $test->{info}, 'c9800_ap_policy_tag';
  $test->{info}->cache({
    '_i_index'              => 1,
    '_i_description'        => 1,
    '_airespace_apif_slot'  => 1,
    '_airespace_if_name'    => 1,
    '_airespace_ap_loc'     => 1,
    '_airespace_ap_name'    => 1,
    '_airespace_ap_model'   => 1,
    '_c9800_ap_policy_tag'  => 1,
    '_c9800_ap_site_tag'    => 1,
    '_c9800_ap_rf_tag'      => 1,
    'store' => {
      'i_index'             => {},
      'i_description'       => {},
      'airespace_apif_slot' => {'2.0.0.0.0.1.0' => 0},
      'airespace_if_name'   => {},
      'airespace_ap_loc'    => {
        '2.0.0.0.0.1' => 'Branch office',
        '2.0.0.0.0.3' => 'Main office',
      },
      'airespace_ap_name' => {
        '2.0.0.0.0.1' => 'ap-1',
        '2.0.0.0.0.3' => 'ap-2',
      },
      'airespace_ap_model' => {
        '2.0.0.0.0.1' => 'C9120AXI',
        '2.0.0.0.0.3' => 'C9130AXI',
      },
      'c9800_ap_policy_tag' => {
        '2.0.0.0.0.1' => 'policy-branch',
        '2.0.0.0.0.3' => 'default-policy-tag',
      },
      'c9800_ap_site_tag' => {
        '2.0.0.0.0.1' => 'site-branch',
      },
      'c9800_ap_rf_tag' => {
        '2.0.0.0.0.1' => 'rf-branch',
        '2.0.0.0.0.3' => '',
      },
    },
  });

  is $test->{info}->e_descr->{'2.0.0.0.0.1'},
    'C9120AXI: ap-1 (Branch office); Policy tag policy-branch; '
      . 'Site tag site-branch; RF tag rf-branch',
    'AP module description includes its tags';
  is $test->{info}->e_descr->{'2.0.0.0.0.3'},
    'C9130AXI: ap-2 (Main office); Policy tag default-policy-tag',
    'Missing or empty tags are left out of the module description';
  is $test->{info}->i_description->{'2.0.0.0.0.1.0'},
    'Branch office',
    'AP radio port description does not repeat the AP tags';
  is $test->{info}->c9800_ap_site_tag->{'2.0.0.0.0.1'}, 'site-branch',
    'Site tag is available per AP';
}

sub device_type_variants : Tests(3) {
  my $test = shift;

  my @descriptions = (
    'Cisco IOS Software [IOSXE], CW9800 Software (C9800_IOSXE-K9), '
      . 'Version 17.15.5, RELEASE SOFTWARE (fc3)',
    'Cisco IOS Software [Dublin], C9800-CL Software (C9800-CL-K9_IOSXE), '
      . 'Version 17.12.6a, RELEASE SOFTWARE (fc2)',
    'Cisco IOS Software [Dublin], C9800 Software (C9800_IOSXE-K9), '
      . 'Version 17.12.6, RELEASE SOFTWARE (fc1)',
  );

  foreach my $description (@descriptions) {
    $test->{info}->cache({
      '_layers'      => 6,
      '_description' => $description,
      '_id'          => '.1.3.6.1.4.1.9.1.2391',
      'store'        => {},
    });
    is $test->{info}->device_type, 'SNMP::Info::Layer3::C9800',
      "Device type for $description";
    $test->{info}->clear_cache;
  }
}

sub _cache_vtp_ports {
  my $test = shift;

  # Gi1 (ifIndex 1) trunks VLANs 100 and 200 with native VLAN 1;
  # Gi3 (ifIndex 3) is an access port in VLAN 1; the Airespace interface
  # table, AireOS only, carries a dynamic interface on VLAN 448
  my $enabled = '0' x 1024;
  substr($enabled, $_, 1, '1') for (100, 200);

  $test->{info}->cache({
    '_vtp_trunk_native'    => 1,
    '_i_pvid'              => 1,
    '_vtp_trunk_dyn'       => 1,
    '_vtp_trunk_dyn_stat'  => 1,
    '_vtp_trunk_vlans'     => 1,
    '_i_vlan2'             => 1,
    '_v_state'             => 1,
    '_airespace_if_vlan'   => 1,
    '_i_index'             => 1,
    '_i_description'       => 1,
    '_airespace_apif_slot' => 1,
    '_airespace_if_name'   => 1,
    'store'                => {
      'airespace_if_vlan'   => {'4.99.114.117.122' => 448},
      'i_index'             => {1 => 1, 3 => 3},
      'i_description'       => {1 => 'GigabitEthernet1', 3 => 'GigabitEthernet3'},
      'airespace_apif_slot' => {},
      'airespace_if_name'   => {},
      'i_pvid'             => {1 => 1, 3 => 1},
      'vtp_trunk_native'   => {1 => 1, 3 => 1},
      'vtp_trunk_dyn'      => {1 => 'on', 3 => 'auto'},
      'vtp_trunk_dyn_stat' => {1 => 'trunking', 3 => 'notTrunking'},
      'vtp_trunk_vlans'    => {1 => pack('B*', $enabled)},
      'i_vlan2'            => {3 => 1},
      'v_state'            => {
        '1.1'   => 'operational',
        '1.100' => 'operational',
        '1.200' => 'operational',
      },
    },
  });
}

sub i_vlan : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'i_vlan';
  $test->_cache_vtp_ports;
  cmp_deeply $test->{info}->i_vlan,
    {1 => 1, 3 => 1, '4.99.114.117.122' => 448},
    'Native and access VLANs from CISCO-VTP-MIB beside Airespace interfaces';
}

# the CISCO-VTP-MIB set and untagged methods read one port at a time, and
# partial fetches go to the session rather than the cache
sub _session_vtp_ports {
  my $test = shift;

  my $data = $test->mock_session->{Data};
  $data->{'IF-MIB::ifIndex'} = {1 => 1, 3 => 3};
  $data->{'IF-MIB::ifDescr'}
    = {1 => 'GigabitEthernet1', 3 => 'GigabitEthernet3'};
  $data->{'CISCO-VTP-MIB::vlanTrunkPortNativeVlan'}   = {1 => 1, 3 => 1};
  $data->{'CISCO-VTP-MIB::vlanTrunkPortDynamicState'} = {1 => 'on', 3 => 'auto'};
  $data->{'CISCO-VLAN-MEMBERSHIP-MIB::vmVlan'}        = {3 => 1};
  $data->{'CISCO-VTP-MIB::vlanTrunkPortSetSerialNo'}  = {0 => 7};

  my $enabled = '0' x 1024;
  substr($enabled, $_, 1, '1') for (100, 200);
  $data->{'CISCO-VTP-MIB::vlanTrunkPortVlansEnabled'}
    = {1 => pack('B*', $enabled)};
}

sub i_untagged : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'i_untagged';
  $test->_cache_vtp_ports;
  $test->_session_vtp_ports;
  cmp_deeply $test->{info}->i_untagged(1), {1 => 1},
    'Untagged VLAN of a trunk is its CISCO-VTP-MIB native VLAN';
}

sub set_vtp_vlans : Tests(6) {
  my $test = shift;

  $test->_cache_vtp_ports;
  $test->_session_vtp_ports;
  my @sets;
  $test->{info}{sess}->mock('set', sub {
    my ($session, $oid, $value) = @_;
    my ($leaf, $iid) = split(/\./, SNMP::translateObj($oid), 2);
    push @sets, [$leaf, $iid, $value];
    return 1;
  });

  ok $test->{info}->set_i_pvid(200, 1), 'Native VLAN set on a trunk';
  ok $test->{info}->set_i_vlan(100, 3), 'Access VLAN set on an access port';
  ok $test->{info}->set_i_untagged(200, 1), 'Untagged VLAN set on a trunk';
  cmp_deeply \@sets, [
    ['vlanTrunkPortNativeVlan', 1, 200],
    ['vmVlan',                  3, 100],
    ['vlanTrunkPortNativeVlan', 1, 200],
  ], 'VLAN changes go through CISCO-VTP-MIB, not Q-BRIDGE-MIB';

  # VLAN 1 exists only in CISCO-VTP-MIB, so Q-BRIDGE-MIB validation would
  # refuse it
  @sets = ();
  ok $test->{info}->set_add_i_vlan_tagged(1, 1), 'Tagged VLAN added to a trunk';
  cmp_deeply [map { [ @$_[0, 1] ] } @sets], [
    ['vlanTrunkPortVlansEnabled', 1],
    ['vlanTrunkPortSetSerialNo',  0],
  ], '... through the CISCO-VTP-MIB trunk VLAN list and set serial';
}

sub i_vlan_membership : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'i_vlan_membership';
  $test->_cache_vtp_ports;
  cmp_deeply $test->{info}->i_vlan_membership,
    {1 => bag(100, 200), 3 => [1]},
    'Trunk and access membership come from CISCO-VTP-MIB';
}

sub i_vlan_membership_untagged : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'i_vlan_membership_untagged';
  $test->_cache_vtp_ports;
  cmp_deeply $test->{info}->i_vlan_membership_untagged,
    {1 => [1], 3 => [1], '4.99.114.117.122' => [448]},
    'Untagged membership follows i_vlan, Airespace interfaces included';
}

sub i_duplex : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'i_duplex';
  $test->{info}->cache({
    '_el_index'         => 1,
    '_el_duplex'        => 1,
    '_airespace_duplex' => 1,
    'store'             => {
      'el_index'         => {1 => 1, 2 => 2},
      'el_duplex'        => {1 => 'fullDuplex', 2 => 'halfDuplex'},
      'airespace_duplex' => {29 => 'auto'},
    },
  });
  cmp_deeply $test->{info}->i_duplex, {1 => 'full', 2 => 'half', 29 => 'auto'},
    'Duplex from EtherLike-MIB beside the Airespace port duplex';
}

sub _cache_vlan_names {
  my $test = shift;

  # VLAN 300 is switched locally by FlexConnect APs and is not defined on
  # the controller, so only its clients name it
  $test->{info}->cache({
    '_v_name'             => 1,
    '_airespace_sta_vlan' => 1,
    '_airespace_sta_if'   => 1,
    'store'               => {
      'v_name' => {
        '1.1'   => 'default',
        '1.100' => 'AP-MGMT',
        '1.200' => 'lab-client',
        '1.425' => 'VLAN0425',
      },
      'airespace_sta_vlan' => {
        '170.177.43.0.0.0' => 300,
        '170.225.74.0.0.0' => 200,
        '170.225.74.0.0.1' => 425,
      },
      'airespace_sta_if' => {
        '170.177.43.0.0.0' => 'flex-only',
        '170.225.74.0.0.0' => 'lab-client',
        '170.225.74.0.0.1' => 'stv-guest',
      },
    },
  });
}

sub v_name : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'v_name';
  $test->_cache_vlan_names;
  cmp_deeply $test->{info}->v_name, {
    '1.1'   => 'default',
    '1.100' => 'AP-MGMT',
    '1.200' => 'lab-client',
    '1.425' => 'stv-guest',
    '300'   => 'flex-only',
  }, 'VTP names first, client names fill gaps and default names';
}

sub v_index : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'v_index';
  $test->_cache_vlan_names;
  cmp_deeply $test->{info}->v_index, {
    '1.1'   => 1,
    '1.100' => 100,
    '1.200' => 200,
    '1.425' => 425,
    '300'   => 300,
  }, 'VLAN index is the VLAN ID for VTP and client-only VLANs';
}

sub _cache_radio_wlans {
  my $test = shift;

  # cLApRadioWlanInfoTable: AP base radio MAC, slot, WLAN index
  $test->{info}->cache({
    '_c9800_radio_wlan_ssid'  => 1,
    '_c9800_radio_wlan_bssid' => 1,
    '_airespace_ess_bcast'    => 1,
    'store'                   => {
      'c9800_radio_wlan_ssid' => {
        '170.156.251.64.2.0.0.2' => 'lab-flex',
        '170.156.251.64.2.0.1.2' => 'lab-flex',
        '170.243.46.64.2.0.0.1'  => 'lab-local',
      },
      'c9800_radio_wlan_bssid' => {
        '170.156.251.64.2.0.0.2' => pack('H*', 'aa9cfb400200'),
        '170.156.251.64.2.0.1.2' => pack('H*', 'aa9cfb40020f'),
        '170.243.46.64.2.0.0.1'  => pack('H*', 'aaf32e400200'),
      },
      'airespace_ess_bcast' => {1 => 'enable', 2 => 'disable'},
    },
  });
}

sub i_ssidlist : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'i_ssidlist';
  $test->_cache_radio_wlans;
  cmp_deeply $test->{info}->i_ssidlist, {
    '170.156.251.64.2.0.0.2' => 'lab-flex',
    '170.156.251.64.2.0.1.2' => 'lab-flex',
    '170.243.46.64.2.0.0.1'  => 'lab-local',
  }, 'SSIDs are listed per AP radio port and WLAN';
}

sub i_ssidmac : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'i_ssidmac';
  $test->_cache_radio_wlans;
  cmp_deeply $test->{info}->i_ssidmac, {
    '170.156.251.64.2.0.0.2' => 'aa:9c:fb:40:02:00',
    '170.156.251.64.2.0.1.2' => 'aa:9c:fb:40:02:0f',
    '170.243.46.64.2.0.0.1'  => 'aa:f3:2e:40:02:00',
  }, 'BSSIDs come from the controller per radio and WLAN';
}

sub i_ssidbcast : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'i_ssidbcast';
  $test->_cache_radio_wlans;
  cmp_deeply $test->{info}->i_ssidbcast, {
    '170.156.251.64.2.0.0.2' => 0,
    '170.156.251.64.2.0.1.2' => 0,
    '170.243.46.64.2.0.0.1'  => 1,
  }, 'Broadcast follows the WLAN broadcast setting';
}

sub has_topo : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'has_topo';
  $test->{info}->cache({
    '_lldp_sys_cap' => pack('H*', '2800'),
    '_cdp_run'      => 'true',
    'store'         => {},
  });
  cmp_deeply $test->{info}->has_topo, ['lldp', 'cdp'],
    'Topology includes LLDP beside CDP';
}

1;
