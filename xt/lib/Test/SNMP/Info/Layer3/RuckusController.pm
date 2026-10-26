# Test::SNMP::Info::Layer3::RuckusController

package Test::SNMP::Info::Layer3::RuckusController;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::RuckusController;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;
  # Node table index: the serial as a length-prefixed string
  my $node = _node_iid('SYNTHETIC-SZ-SERIAL');
  my $peer = _node_iid('SYNTHETIC-PEER-SERIAL');
  $test->{info}->cache({
    '_layers' => 78,
    '_description' => 'SmartZone',
    '_id' => '.1.3.6.1.4.1.25053.3.1.11.1',
    '_ruckus_sz_serial' => 'SYNTHETIC-SZ-SERIAL',
    '_ruckus_node_model' => 1,
    '_ruckus_node_version' => 1,
    'store' => {
      'ruckus_node_model'   => { $node => 'vSZ-E',       $peer => 'vSZ-H' },
      'ruckus_node_version' => { $node => '6.1.2.0.487', $peer => '6.1.1.0.959' },
    },
  });
}

sub _node_iid {
  my $serial = shift;
  return join('.', length $serial, map { ord } split //, $serial);
}

sub layers : Tests(2) {
  my $test = shift;
  my $info = $test->{info};
  $info->cache({ '_layers' => 6 });
  is($info->layers(), '00000110', 'served sysServices are used');

  $info->cache({ '_layers' => undef });
  is($info->layers(), '01001110', 'no sysServices gives layers 2, 3, 4 and 7');
}

sub os_ver : Tests(3) {
  my $test = shift;
  my $info = $test->{info};
  is($info->os_ver(), '6.1.2.0.487', 'os_ver is this node\'s version');

  $info->cache({ '_ruckus_sz_serial' => 'SYNTHETIC-PEER-SERIAL' });
  is($info->os_ver(), '6.1.1.0.959', 'the node row follows the serial');

  $info->cache({ '_ruckus_node_model' => 0, '_ruckus_node_version' => 0,
    'store' => {} });
  is($info->os_ver(), undef, 'no node table gives no version');
}

sub vendor : Tests(1) {
  my $test = shift;
  is($test->{info}->vendor(), 'ruckus', 'controller vendor is ruckus');
}

sub os : Tests(1) {
  is(shift->{info}->os(), 'ruckus smartzone/scg', 'controller OS family is identified');
}

sub serial : Tests(3) {
  my $test = shift;
  my $info = $test->{info};
  is($info->serial(), 'SYNTHETIC-SZ-SERIAL',
    'serial is read from the SmartZone system MIB');

  $info->cache({
    '_ruckus_sz_serial' => '',
    '_ruckus_scg_serial' => 'SYNTHETIC-SCG-SERIAL',
  });
  is($info->serial(), 'SYNTHETIC-SCG-SERIAL',
    'serial falls back to the SmartCell Gateway system MIB');

  $info->cache({ '_ruckus_sz_serial' => '', '_ruckus_scg_serial' => '' });
  is($info->serial(), SNMP::Info::Layer3::serial($info),
    'empty vendor serials use the inherited serial method');
}

sub model : Tests(8) {
  my $test = shift;
  my $info = $test->{info};
  is($info->model(), 'vSZ-E', 'model is this node\'s model');

  my $single = _node_iid('SYNTHETIC-ONLY-NODE');
  $info->cache({
    '_ruckus_sz_serial' => '', '_ruckus_scg_serial' => '',
    '_ruckus_node_version' => 0,
    'store' => { 'ruckus_node_model' => { $single => 'SZ104' } },
  });
  is($info->model(), 'SZ104', 'a single node row is used without a serial');

  $info->cache({ '_ruckus_node_model' => 0,
    '_id' => '.1.3.6.1.4.1.25053.3.1.11', 'store' => {} });
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

  $info->cache({ '_id' => '.1.3.6.1.4.1.25053.3.1.12.99' });
  is($info->model(), SNMP::Info::Layer3::model($info),
    'unknown controller models fall back to the inherited model');
}

sub device_type : Tests(7) {
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

  $info->cache({
    '_layers' => 6,
    '_description' => 'Ruckus Wireless ZoneDirector',
    '_id' => '.1.3.6.1.4.1.25053.3.1.5.15',
  });
  isnt($info->device_type(), 'SNMP::Info::Layer3::RuckusController',
    'ZoneDirector does not select the controller class');

  $info->cache({
    '_layers' => 0,
    '_description' => 'Ruckus controller',
    '_id' => '.1.3.6.1.4.1.25053.3.1.12.99',
  });
  isnt($info->device_type(), 'SNMP::Info::Layer3::RuckusController',
    'Unknown neighboring product OIDs do not select controller class');
}

1;
