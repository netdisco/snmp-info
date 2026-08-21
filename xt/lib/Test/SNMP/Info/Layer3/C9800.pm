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

sub inherited_classes : Tests(1) {
  my $test = shift;
  isa_ok $test->{info}, 'SNMP::Info::Layer2::Airespace';
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

1;
