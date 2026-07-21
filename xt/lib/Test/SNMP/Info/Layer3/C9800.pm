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
        2   => 'FXS2402Q0C1',
        3   => 'PSU123456',
        500 => 'SERIAL500',
      },
    },
  });
  is $test->{info}->serial, 'SERIAL1 FXS2402Q0C1 SERIAL500',
    'Serial concatenates values at chassis indexes 1, 2, and 500';

  $test->{info}->clear_cache;
  is $test->{info}->serial, undef, 'Serial is undefined without chassis data';
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
