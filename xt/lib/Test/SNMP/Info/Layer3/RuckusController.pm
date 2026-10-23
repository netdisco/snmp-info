# Test::SNMP::Info::Layer3::RuckusController

package Test::SNMP::Info::Layer3::RuckusController;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::RuckusController;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;
  $test->{info}->cache({
    '_layers' => 3,
    '_description' => 'Ruckus SmartZone Controller',
    '_id' => '.1.3.6.1.4.1.25053.3.1.11',
    'store' => {},
  });
}

sub vendor : Tests(1) {
  my $test = shift;
  is($test->{info}->vendor(), 'ruckus', 'controller vendor is ruckus');
}

sub os : Tests(1) {
  is(shift->{info}->os(), 'ruckus smartzone/scg', 'controller OS family is identified');
}

sub model : Tests(6) {
  my $test = shift;
  my $info = $test->{info};
  is($info->model(), 'SmartZone', 'generic SmartZone product OID is identified');

  foreach my $case (
    ['.1.3.6.1.4.1.25053.3.1.10', 'SCG'],
    ['.1.3.6.1.4.1.25053.3.1.10.1', 'SCG200'],
    ['.1.3.6.1.4.1.25053.3.1.11.1', 'SZ100'],
    ['.1.3.6.1.4.1.25053.3.1.11.2', 'SZ50'],
  ) {
    my ($oid, $model) = @$case;
    $info->cache({ '_id' => $oid });
    is($info->model(), $model, "$oid maps to $model");
  }

  $info->cache({ '_id' => '.1.3.6.1.4.1.25053.3.1.10.99' });
  is($info->model(), SNMP::Info::Layer3::model($info),
    'unknown controller models fall back to the inherited model');
}

sub device_type : Tests(5) {
  my $test = shift;
  my $info = $test->{info};

  foreach my $oid (
    '.1.3.6.1.4.1.25053.3.1.10',
    '.1.3.6.1.4.1.25053.3.1.10.1',
    '.1.3.6.1.4.1.25053.3.1.11',
    '.1.3.6.1.4.1.25053.3.1.11.1',
  ) {
    $info->cache({
      '_layers' => 0,
      '_description' => 'Ruckus controller',
      '_id' => $oid,
    });
    is($info->device_type(), 'SNMP::Info::Layer3::RuckusController',
      "$oid is detected as a Ruckus controller");
  }

  $info->cache({
    '_layers' => 0,
    '_description' => 'Ruckus access point',
    '_id' => '.1.3.6.1.4.1.25053.3.1.4.121',
  });
  is($info->device_type(), 'SNMP::Info::Layer2::RuckusAP',
    'Ruckus access point OIDs still select the AP class');
}

1;
