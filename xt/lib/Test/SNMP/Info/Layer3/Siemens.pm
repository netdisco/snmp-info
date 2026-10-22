# Test::SNMP::Info::Layer3::Siemens

package Test::SNMP::Info::Layer3::Siemens;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Siemens;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  $test->{info}->cache({
    '_layers' => 78,
    '_description' => 'Siemens, SIMATIC S7, CPU315-2 PN/DP, 6ES7 315-2EH14-0AB0, HW: 7, FW: V3.2.11, S C-F1V122652015',
    '_id' => '.0.0',
    'store' => {},
  });
}

sub device_type : Tests(7) {
  my $test = shift;

  is($test->{info}->device_type(), 'SNMP::Info::Layer3::Siemens',
    'SIMATIC S7 description selects Siemens class');

  $test->{info}->cache({
    '_layers' => 76,
    '_description' => 'Siemens, SINAMICS, G120 CU240E-2, 6SL3 244-0BB12-1FA0, HW: Version 401, FW: Version V04.71.52',
    '_id' => '.0.0',
    'store' => {},
  });
  is($test->{info}->device_type(), 'SNMP::Info::Layer3::Siemens',
    'SINAMICS description selects Siemens class');

  # The HMI answers no sysServices and reports a Windows CE sysObjectID.
  $test->{info}->clear_cache();
  $test->{info}->cache({
    '_description' => 'Siemens, SIMATIC HMI, TP700 Comfort, 6AV2 124-0GC01-0AX0, HW: 0, SW: V 16 0 0',
    '_id' => '.1.3.6.1.4.1.311.1.1.3.3',
    'store' => {},
  });
  is($test->{info}->device_type(), 'SNMP::Info::Layer3::Siemens',
    'SIMATIC HMI without sysServices selects Siemens class');

  $test->{info}->cache({
    '_layers' => 76,
    '_description' => 'Siemens Soft starter 3RW44 Profinet',
    '_id' => '.0.0',
    'store' => {},
  });
  is($test->{info}->device_type(), 'SNMP::Info::Layer3::Siemens',
    'soft starter description selects Siemens class');

  $test->{info}->cache({
    '_layers' => 76,
    '_description' => 'Siemens, SIMOCODE pro V PN, 3UF7 011-1AB00-0, FW: Version V01.02.00',
    '_id' => '.0.0',
    'store' => {},
  });
  is($test->{info}->device_type(), 'SNMP::Info::Layer3::Siemens',
    'SIMOCODE description selects Siemens class');

  $test->{info}->cache({
    '_layers' => 92,
    '_description' => 'Siemens, SIMATIC NET, SCALANCE XR524-8C 2PS, 6GK5 524-8GS00-4AR2',
    '_id' => '.1.3.6.1.4.1.4329.6.1.2',
    'store' => {},
  });
  is($test->{info}->device_type(), 'SNMP::Info::Layer3::Scalance',
    'SCALANCE devices retain their existing class');

  $test->{info}->cache({
    '_layers' => 92,
    '_description' => 'Siemens Industrial PC, unrelated description',
    '_id' => '.1.3.6.1.4.1.2021',
    'store' => {},
  });
  is($test->{info}->device_type(), 'SNMP::Info::Layer3::NetSNMP',
    'unmatched Siemens description retains sysObjectID classification');
}

sub vendor : Tests(1) {
  my $test = shift;
  is($test->{info}->vendor(), 'siemens', 'Vendor is siemens');
}

sub os : Tests(1) {
  my $test = shift;
  is($test->{info}->os(), 'siemens', 'OS is siemens');
}

sub model : Tests(7) {
  my $test = shift;

  is($test->{info}->model(), 'CPU315-2 PN/DP', 'SIMATIC S7 model extracted');

  $test->{info}->cache({
    '_description' => 'Siemens, SIMATIC S7, IM151-3PN, 6ES7 151-3AA23-0AB0',
  });
  is($test->{info}->model(), 'IM151-3PN', 'SIMATIC ET 200S model extracted');

  $test->{info}->cache({
    '_description' => 'Siemens, SINAMICS, G120 CU240E-2, 6SL3 244-0BB12-1FA0',
  });
  is($test->{info}->model(), 'G120 CU240E-2', 'SINAMICS model extracted');

  $test->{info}->cache({
    '_description' => 'Siemens, SIMOCODE pro V PN, 3UF7 011-1AB00-0, FW: Version V01.02.00',
  });
  is($test->{info}->model(), 'SIMOCODE pro V PN', 'SIMOCODE model extracted');

  $test->{info}->cache({
    '_description' => 'Siemens Soft starter 3RW44 Profinet',
  });
  is($test->{info}->model(), '3RW44 Profinet', 'Soft starter model extracted');

  $test->{info}->cache({
    '_description' => 'Siemens, SIMATIC HMI, unknown, 6AV2 124-0GC01-0AX0, HW: 0, SW: V 16 0 0',
  });
  is($test->{info}->model(), '6AV2 124-0GC01-0AX0', 'HMI part number used when model is unknown');

  $test->{info}->cache({
    '_description' => 'Siemens, SIMATIC S7, IM151-8 PN/DP CPU, 6ES7 151-8AB01-0AB0 , HW: 3, FW: V3.2.10, S C-X4U421302009',
  });
  is($test->{info}->model(), 'IM151-8 PN/DP CPU', 'SIMATIC S7 model extracted when the order number has a trailing space');
}

sub os_ver : Tests(6) {
  my $test = shift;

  $test->{info}->cache({
    '_description' => 'Siemens, SIMATIC S7, CPU315-2 PN/DP, FW: V3.2.11',
  });
  is($test->{info}->os_ver(), '3.2.11', 'SIMATIC firmware version extracted');

  $test->{info}->cache({
    '_description' => 'Siemens, SINAMICS, G120, FW: Version V04.71.52',
  });
  is($test->{info}->os_ver(), '04.71.52', 'SINAMICS firmware version extracted');

  $test->{info}->cache({
    '_description' => 'Siemens, SIMOCODE pro V PN, 3UF7 011-1AB00-0, FW: Version V01.02.00',
  });
  is($test->{info}->os_ver(), '01.02.00', 'SIMOCODE firmware version extracted');

  $test->{info}->cache({
    '_description' => 'Siemens, SIMATIC HMI, unknown, 6AV2 124-0GC01-0AX0, SW: V 16 0 0',
  });
  is($test->{info}->os_ver(), '16.0.0', 'HMI software version extracted');

  $test->{info}->cache({
    '_description' => 'Siemens, SIMATIC HMI, TP700, SW: V 16 0 0 Build 12',
  });
  is($test->{info}->os_ver(), '16.0.0', 'HMI version stops before trailing build text');

  $test->{info}->cache({
    '_description' => 'Siemens, SIMATIC HMI, TP700, FW: V.4.2.3',
  });
  is($test->{info}->os_ver(), '4.2.3', 'HMI version accepts V.x notation');
}

sub serial : Tests(3) {
  my $test = shift;

  $test->{info}->cache({
    '_description' => 'Siemens, SIMATIC S7, CPU315-2 PN/DP, FW: V3.2.11, S C-F1V122652015',
  });
  is($test->{info}->serial(), 'S C-F1V122652015', 'SIMATIC serial extracted');

  $test->{info}->cache({
    '_description' => 'Siemens, SIMATIC S7, IM151-3PN, FW: V7.0.5, SN: S C-FDCW23442015',
  });
  is($test->{info}->serial(), 'S C-FDCW23442015', 'SIMATIC serial with SN label extracted');

  $test->{info}->cache({
    '_description' => 'Siemens device reports S C-UNRELATED elsewhere in the description',
  });
  is($test->{info}->serial(), undef, 'serial pattern must follow the product separator');
}

1;
