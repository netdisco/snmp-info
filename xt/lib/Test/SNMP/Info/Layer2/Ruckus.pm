# Test::SNMP::Info::Layer2::Ruckus

package Test::SNMP::Info::Layer2::Ruckus;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer2::Ruckus;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  $test->{info}->cache({
    '_layers'      => 0,
    '_description' => 'Ruckus Wireless Inc (C) 2006',
    '_id'          => '.1.3.6.1.4.1.25053.3.1.4.121',
    '_ruckus_model'  => 'R350',
    '_ruckus_serial' => 'SERIAL-REDACTED',
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

sub os : Tests(1) {
  my $test = shift;
  is($test->{info}->os(), 'ruckus', 'OS is ruckus');
}

sub model : Tests(1) {
  my $test = shift;
  is($test->{info}->model(), 'R350', 'Model comes from the hardware MIB');
}

sub serial : Tests(1) {
  my $test = shift;
  is($test->{info}->serial(), 'SERIAL-REDACTED', 'Serial comes from the hardware MIB');
}

sub os_ver : Tests(2) {
  my $test = shift;

  is($test->{info}->os_ver(), '6.1.2.0.4172',
    'Returns the revision whose status marks it active');

  $test->{info}->cache({
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
}

1;
