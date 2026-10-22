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
  is($test->{info}->serial(), 'SERIAL-REDACTED', 'Serial comes from the hardware MIB');
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

1;
