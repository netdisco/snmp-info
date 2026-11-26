# Test::SNMP::Info::Layer3::Maipu

package Test::SNMP::Info::Layer3::Maipu;

use Test::Class::Most parent => 'My::Test::Class';
use SNMP::Info::Layer3::Maipu;

my $SYSDESCR
    = 'MyPower (R) Operating System Software, MyPower S3230 version '
    . '9.7.400.1, compiled on Sep 18 2023, 10:04:13 Copyright (C) 2023 '
    . 'Maipu Communication Technology Co.,Ltd.All Rights Reserved.';

sub setup : Tests(setup) {
    my $test = shift;
    $test->SUPER::setup;

    # Shapes from an S3230 walk: sysServices 4, bridge ports 1-54 that
    # equal their ifIndex, link aggregations at ifIndex 109 and up that the
    # base port table omits, and FDB rows indexed VLAN.6.MAC.
    my $cache_data = {
        '_layers'      => 4,
        '_description' => $SYSDESCR,
        '_id'          => '.1.3.6.1.4.1.5651.1.102.5639',
        '_b_ports'     => 54,
        '_i_index'     => 1,
        '_bp_index'    => 1,
        '_qb_fw_port'  => 1,
        'store'        => {
            'i_index' => {
                1         => 1,
                2         => 2,
                53        => 53,
                109       => 109,
                110       => 110,
                541851651 => 541851651,
            },
            'bp_index'   => { 1 => 1, 2 => 2, 53 => 53 },
            'qb_fw_port' => {
                '200.6.2.0.0.0.0.1' => 53,
                '200.6.2.0.0.0.0.2' => 109,
                '3.6.2.0.0.0.0.3'   => 1,
            },
        },
    };
    $test->{info}->cache($cache_data);
}

sub device_type : Tests(5) {
    my $info = shift->{info};

    can_ok($info, 'device_type');
    is($info->device_type(), 'SNMP::Info::Layer3::Maipu',
        'Switch reporting layer 3 only');

    $info->cache({ '_layers' => 6 });
    is($info->device_type(), 'SNMP::Info::Layer3::Maipu',
        'Switch reporting layers 2 and 3');

    $info->cache({
        '_id'          => '.1.3.6.1.4.1.5651.1.101.2',
        '_description' => 'MyPower (R) Operating System Software',
        '_layers'      => 4,
    });
    is($info->device_type(), 'SNMP::Info::Layer3',
        'Maipu router keeps the generic class');

    $info->cache({ '_id' => '.1.3.6.1.4.1.56510.1.102.1' });
    is($info->device_type(), 'SNMP::Info::Layer3',
        'Neighboring enterprise is not Maipu');
}

sub vendor : Tests(1) {
    is(shift->{info}->vendor(), 'maipu', 'Vendor');
}

sub os : Tests(1) {
    is(shift->{info}->os(), 'mypower', 'OS');
}

sub os_ver : Tests(3) {
    my $info = shift->{info};

    is($info->os_ver(), '9.7.400.1', 'Version from sysDescr');

    $info->cache({
        '_description' => 'MyPower (R) Operating System Software, '
            . 'MyPower S3230 Version 9.7.400.1' });
    is($info->os_ver(), '9.7.400.1', 'Capitalized and at end of sysDescr');

    $info->cache({ '_description' => 'MyPower S3230' });
    is($info->os_ver(), undef, 'No version in sysDescr');
}

sub model : Tests(2) {
    my $info = shift->{info};

    is($info->model(), 'S3230', 'Model from sysDescr');

    $info->cache({ '_description' => 'MyPower (R) Operating System Software' });
    is($info->model(), SNMP::Info::Layer3::model($info),
        'Inherited model without a sysDescr model');
}

sub layers : Tests(2) {
    my $info = shift->{info};

    is($info->layers(), '00000110', 'Bridge ports add layer 2');

    $info->cache({ '_b_ports' => 0 });
    is($info->layers(), '00000100', 'No bridge ports keeps layer 3 only');
}

sub qb_fw_mac : Tests(3) {
    my $test = shift;
    my $info = $test->{info};

    my $expected = {
        '200.6.2.0.0.0.0.1' => '02:00:00:00:00:01',
        '200.6.2.0.0.0.0.2' => '02:00:00:00:00:02',
        '3.6.2.0.0.0.0.3'   => '02:00:00:00:00:03',
    };
    is_deeply($info->qb_fw_mac(), $expected,
        'MAC without the length octet the agent puts in the index');
    is_deeply($info->fw_mac(), $expected, 'fw_mac takes the decoded MACs');

    $info->clear_cache();
    $info->cache({
        '_qb_fw_port' => 1,
        'store'       => { 'qb_fw_port' => { '200.2.0.0.0.0.4' => 1 } },
    });
    is_deeply($info->qb_fw_mac(), { '200.2.0.0.0.0.4' => '02:00:00:00:00:04' },
        'Standard FDB ID and MAC index');
}

sub bp_index : Tests(4) {
    my $info = shift->{info};

    my $bp_index = $info->bp_index();
    is_deeply($bp_index,
        { 1 => 1, 2 => 2, 53 => 53, 109 => 109, 110 => 110,
          541851651 => 541851651 },
        'Interfaces missing from the base port table map to themselves');

    my $fw_port = $info->fw_port();
    is_deeply([ grep { !exists $bp_index->{$_} } values %$fw_port ], [],
        'Every forwarding port maps to an interface');

    $info->clear_cache();
    $info->cache({
        '_i_index' => 1,
        'store'    => { 'i_index' => { 1 => 1, 109 => 109, 110 => 110 } },
    });
    is_deeply($info->bp_index(110), { 110 => 110 },
        'Partial for an aggregation port maps only that port');
    is_deeply($info->bp_index(999), {}, 'Partial for no interface');
}

1;
