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

sub model : Tests(5) {
    my $info = shift->{info};

    is($info->model(), 'S3230', 'Model from sysDescr without entities');

    # Shapes from an S3230-54TXF walk: the chassis names its model in
    # entPhysicalDescr and leaves entPhysicalModelName empty.
    $info->cache({
        '_e_class' => 1,
        '_e_model' => 1,
        '_e_descr' => 1,
        'store'    => {
            'e_class' => { 512 => 'chassis', 768 => 'container',
                           1280 => 'module' },
            'e_model' => { 512 => '', 768 => '', 1280 => '' },
            'e_descr' => { 512 => 'S3230-54TXF(V1)', 768 => 'Board slot',
                           1280 => '' },
        },
    });
    is($info->model(), 'S3230-54TXF(V1)', 'Chassis description');

    $info->{store}{e_model}{512} = 'S3230-54TXF';
    is($info->model(), 'S3230-54TXF', 'Chassis model name first');

    # The agent serves entPhysicalClass as a Gauge32, so it stays numeric
    $info->{store}{e_class} = { 512 => 3, 768 => 5, 1280 => 9 };
    is($info->model(), 'S3230-54TXF', 'Chassis class served as a number');

    $info->clear_cache();
    $info->cache({ '_description' => 'MyPower (R) Operating System Software' });
    is($info->model(), SNMP::Info::Layer3::model($info),
        'Inherited model without entities or a sysDescr model');
}

sub e_class : Tests(2) {
    my $info = shift->{info};

    # The agent serves entPhysicalClass as a Gauge32, which Net-SNMP does
    # not translate to the PhysicalClass labels
    $info->cache({
        '_e_class' => 1,
        'store'    => { 'e_class' => {
            512 => 3, 768 => 5, 1280 => 9, 3147008 => 6, 3671296 => 7,
            1537 => 10, 99 => 'chassis', 98 => 42 } },
    });
    is_deeply($info->e_class(), {
            512 => 'chassis', 768 => 'container', 1280 => 'module',
            3147008 => 'powerSupply', 3671296 => 'fan', 1537 => 'port',
            99 => 'chassis', 98 => 42 },
        'Numeric classes translated, labels and unknown numbers kept');

    $info->{store}{e_class} = {};
    is_deeply($info->e_class(), {}, 'No entities');
}

sub serial : Tests(3) {
    my $info = shift->{info};

    # MAIPU-SYS-MIB::mpSysDeviceSerialNumber, one row per device
    $info->cache({
        '_mp_device_serial' => 1,
        'store' => { 'mp_device_serial' => {
            2 => '23004725009999', 1 => '23004725001263' } },
    });
    is($info->serial(), '23004725001263', 'Lowest device index');

    $info->{store}{mp_device_serial} = { 1 => '', 2 => '23004725009999' };
    is($info->serial(), '23004725009999', 'Skips an empty serial');

    $info->{store}{mp_device_serial} = {};
    is($info->serial(), SNMP::Info::Layer3::serial($info),
        'Inherited serial without the vendor table');
}

sub _power_and_fans {
    my ( $info, %over ) = @_;

    # Shapes from an S3230-54TXF walk: one fixed AC supply at index 49 and
    # one fan at index 57, all online and normal
    $info->cache({
        '_mp_power_type'   => 1,
        '_mp_power_online' => 1,
        '_mp_power_alarm'  => 1,
        '_mp_fan_online'   => 1,
        '_mp_fan_alarm'    => 1,
        'store'            => {
            'mp_power_type'   => { 49 => 1 },
            'mp_power_online' => { 49 => 1 },
            'mp_power_alarm'  => { 49 => 1 },
            'mp_fan_online'   => { 57 => 1 },
            'mp_fan_alarm'    => { 57 => 1 },
            %over,
        },
    });
    return;
}

sub ps1_type : Tests(2) {
    my $info = shift->{info};

    _power_and_fans($info);
    is($info->ps1_type(), 'AC', 'Alternating current supply');

    _power_and_fans($info, 'mp_power_type' => {});
    is($info->ps1_type(), undef, 'No power table');
}

sub ps2_type : Tests(2) {
    my $info = shift->{info};

    _power_and_fans($info);
    is($info->ps2_type(), undef, 'Single supply has no second');

    _power_and_fans($info, 'mp_power_type' => { 49 => 1, 50 => 4 });
    is($info->ps2_type(), 'DC', 'Second supply, direct current');
}

sub ps1_status : Tests(3) {
    my $info = shift->{info};

    _power_and_fans($info);
    is($info->ps1_status(), 'normal', 'Online and normal');

    _power_and_fans($info, 'mp_power_alarm' => { 49 => 2 });
    is($info->ps1_status(), 'alarm', 'Alarm');

    _power_and_fans($info, 'mp_power_online' => { 49 => 2 });
    is($info->ps1_status(), 'offline', 'Offline before alarm state');
}

sub ps2_status : Tests(2) {
    my $info = shift->{info};

    _power_and_fans($info);
    is($info->ps2_status(), undef, 'Single supply has no second');

    _power_and_fans($info,
        'mp_power_online' => { 49 => 1, 50 => 1 },
        'mp_power_alarm'  => { 49 => 1, 50 => 2 });
    is($info->ps2_status(), 'alarm', 'Second supply by index order');
}

sub fan : Tests(4) {
    my $info = shift->{info};

    _power_and_fans($info);
    is($info->fan(), 'normal', 'All fans normal');

    _power_and_fans($info,
        'mp_fan_online' => { 57 => 1, 58 => 2 },
        'mp_fan_alarm'  => { 57 => 1, 58 => 1 });
    is($info->fan(), 'Fan 2: offline', 'Offline fan named by position');

    _power_and_fans($info,
        'mp_fan_online' => { 57 => 1, 58 => 1 },
        'mp_fan_alarm'  => { 57 => 2, 58 => 2 });
    is($info->fan(), 'Fan 1: alarm, Fan 2: alarm', 'Every failed fan');

    _power_and_fans($info, 'mp_fan_online' => {}, 'mp_fan_alarm' => {});
    is($info->fan(), undef, 'No fan table');
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

sub agg_ports : Tests(4) {
    my $info = shift->{info};

    # Shapes from an S3230 walk: dot3adAggPortAttachedAggID names the
    # aggregation ifIndex for members, 0 for other ports, and the agent
    # serves no dot3adAggPortListPorts.
    $info->clear_cache();
    $info->cache({
        '_i_index'           => 1,
        '_lag_port_attached' => 1,
        'store'              => {
            'i_index' => { map { $_ => $_ } 1, 39, 40, 45, 109, 110 },
            'lag_port_attached' => {
                1 => 0, 39 => 110, 40 => 110, 45 => 109, 109 => 109,
                110 => 110,
            },
        },
    });
    is_deeply($info->agg_ports(), { 39 => 110, 40 => 110, 45 => 109 },
        'Members from the attached aggregator');

    $info->{store}{lag_port_attached} = { 39 => 999, 40 => 'invalid' };
    is_deeply($info->agg_ports(), {},
        'Aggregator that is not an interface, or not an ifIndex');

    $info->{store}{lag_port_attached} = {};
    $info->{'_ad_lag_ports'} = 1;
    $info->{store}{ad_lag_ports} = { 110 => pack('B*', '1100') };
    is_deeply($info->agg_ports(), { 1 => 110, 2 => 110 },
        'Port list when no port names an attached aggregator');

    is_deeply([ $info->_agg_ports_walked() ],
        [qw/lag_port_attached ad_lag_ports bp_index/],
        'Tables agg_ports walks');
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
