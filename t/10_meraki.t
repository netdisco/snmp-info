#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib 'lib';
use SNMP::Info::Layer3::Meraki;

{
    package Local::MerakiTest;
    our @ISA = qw(SNMP::Info::Layer3::Meraki);

    sub description { return $_[0]->{description} }
    sub id          { return $_[0]->{id} }
    sub entity_derived_serial { return $_[0]->{serial} }
}

my $device = bless {
    description => 'Meraki MS120-8FP Cloud Managed PoE Switch',
    id          => '.1.3.6.1.4.1.29671.2.340',
    serial      => 'Q4AC-76H2-SU93',
}, 'Local::MerakiTest';

is($device->vendor(), 'Cisco Meraki', 'reports Meraki vendor');
is($device->model(), 'MS120-8FP', 'extracts model from sysDescr');
is($device->serial1(), 'Q4AC-76H2-SU93', 'uses ENTITY-MIB serial for serial1');
is($device->serial(), 'Q4AC-76H2-SU93', 'retains inherited serial behavior');

$device->{description} = 'Meraki Cloud Managed 802.11n AP';
$device->{id} = 'enterprises.29671.2.37';
is($device->model(), 'MR36', 'uses product OID when sysDescr starts with a generic description');

$device->{description} = undef;
my @product_oids = (
    [27,  'MR33'],
    [35,  'GR10'],
    [37,  'MR36'],
    [38,  'MR46'],
    [41,  'MR76'],
    [50,  'CW9162I'],
    [63,  'CW9179F'],
    [100, 'Z1'],
    [107, 'MX64'],
    [117, 'GX20'],
    [132, 'C8455-G2'],
    [200, 'Meraki VM10'],
    [339, 'MS120-8LP'],
    [340, 'MS120-8FP'],
    [375, 'MS125-48FP'],
    [398, 'MS130-12X'],
    [401, 'MS130-24X'],
    [404, 'MS130-48X'],
    [443, 'MS150-48MP-4X'],
    [483, 'MS130-8P-I'],
);
for my $product (@product_oids) {
    $device->{id} = "enterprises.29671.2.$product->[0]";
    is($device->model(), $product->[1], "maps product sysObjectID suffix $product->[0]");
}

$device->{id} = 'enterprises.29671.2.99999';
is($device->model(), undef, 'does not report an unknown raw sysObjectID as model');

$device->{serial} = undef;
is($device->serial1(), undef, 'returns no serial1 when ENTITY-MIB has none');

done_testing();
