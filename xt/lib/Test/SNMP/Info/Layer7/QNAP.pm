# Test::SNMP::Info::Layer7::QNAP
#
# Copyright (c) 2026 The SNMP::Info Developers
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the University of California, Santa Cruz nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR # ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package Test::SNMP::Info::Layer7::QNAP;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer7::QNAP;

sub setup : Tests(setup) {
    my $test = shift;
    $test->SUPER::setup;

    # Current QTS-MIB device. QNAP does not always implement sysServices.
    $test->{info}->cache({
        '_layers'             => 0,
        '_description'        => 'Linux TS-X41 5.2.5.3145',
        '_id'                 => '.1.3.6.1.4.1.55062.1',
        '_name'               => 'standard-qnap-name',
        '_qnap_qts_hostname'  => ' MY-NAS-EXT ',
        '_qnap_qts_model'     => ' TS-431P ',
        '_qnap_qts_serial'    => ' Q193C41816 ',
        '_qnap_qts_firmware'  => " 5.2.5.3145 \x00",
        '_qnap_quts_model'    => undef,
        '_qnap_quts_hostname' => undef,
        '_qnap_quts_serial'   => undef,
        '_qnap_quts_firmware' => undef,
        'store'               => {},
    });
}

sub device_type : Tests(+4) {
    my $test = shift;
    $test->SUPER::device_type;

    $test->{info}{_id} = '.1.3.6.1.4.1.24681.2';
    is($test->{info}->device_type(), 'SNMP::Info::Layer7::QNAP',
        'Legacy enterprise is detected without sysServices');

    $test->{info}{_id} = '.1.3.6.1.4.1.55062.1';
    is($test->{info}->device_type(), 'SNMP::Info::Layer7::QNAP',
        'Current QTS enterprise is detected without sysServices');

    $test->{info}{_id} = '.1.3.6.1.4.1.55062.2';
    is($test->{info}->device_type(), 'SNMP::Info::Layer7::QNAP',
        'Current QuTS hero enterprise is detected without sysServices');

    $test->{info}{_id} = '.1.3.6.1.4.1.55062';
    is($test->{info}->device_type(), 'SNMP::Info::Layer7::QNAP',
        'Generic current enterprise root is detected without sysServices');
}

sub layer_classification : Tests(3) {
    my $test = shift;

    isa_ok($test->{info}, 'SNMP::Info::Layer7',
        'QNAP is an application-layer device');
    ok(!$test->{info}->isa('SNMP::Info::Layer3'),
        'QNAP does not inherit routing-layer behavior');

    $test->{info}{_layers} = 64;
    is($test->{info}->device_type(), 'SNMP::Info::Layer7::QNAP',
        'QNAP enterprise is detected with Layer7 sysServices');
}

sub vendor : Tests(2) {
    my $test = shift;

    can_ok($test->{info}, 'vendor');
    is($test->{info}->vendor(), 'qnap', q(Vendor returns 'qnap'));
}

sub qnap_globals : Tests(9) {
    my $test = shift;
    my $globals = $test->{info}->globals();

    is($globals->{qnap_qts_hostname}, '.1.3.6.1.4.1.55062.1.12.4.0',
        'QTS hostname OID');
    is($globals->{qnap_qts_model}, '.1.3.6.1.4.1.55062.1.12.3.0',
        'QTS model OID');
    is($globals->{qnap_qts_serial}, '.1.3.6.1.4.1.55062.1.12.5.0',
        'QTS serial OID');
    is($globals->{qnap_qts_firmware}, '.1.3.6.1.4.1.55062.1.12.6.0',
        'QTS firmware OID');
    is($globals->{qnap_quts_hostname}, '.1.3.6.1.4.1.55062.2.12.4.0',
        'QuTS hero hostname OID');
    is($globals->{qnap_quts_model}, '.1.3.6.1.4.1.55062.2.12.3.0',
        'QuTS hero model OID');
    is($globals->{qnap_quts_serial}, '.1.3.6.1.4.1.55062.2.12.5.0',
        'QuTS hero serial OID');
    is($globals->{qnap_quts_firmware}, '.1.3.6.1.4.1.55062.2.12.6.0',
        'QuTS hero firmware OID');
    is($globals->{qnap_legacy_model}, '.1.3.6.1.4.1.24681.1.2.12.0',
        'Legacy model OID');
}

sub name : Tests(5) {
    my $test = shift;

    can_ok($test->{info}, 'name');
    is($test->{info}->name(), 'MY-NAS-EXT',
        'QTS hostname is returned and whitespace is removed');

    $test->{info}{_id} = '.1.3.6.1.4.1.55062.2';
    $test->{info}{_qnap_quts_hostname} = ' PBS-NAS-A-Back ';
    is($test->{info}->name(), 'PBS-NAS-A-Back',
        'QuTS hero hostname is selected from its subtree');

    $test->{info}{_qnap_quts_hostname} = '';
    $test->{info}{_qnap_qts_hostname} = '';
    is($test->{info}->name(), 'standard-qnap-name',
        'Missing QNAP hostname falls back to sysName');

    $test->{info}->clear_cache();
    is($test->{info}->name(), undef, 'No data returns undef name');
}

sub model : Tests(6) {
    my $test = shift;

    can_ok($test->{info}, 'model');
    is($test->{info}->model(), 'TS-431P',
        'Current model is returned and whitespace is removed');

    $test->{info}{_id} = '.1.3.6.1.4.1.55062.2';
    $test->{info}{_qnap_quts_model} = ' TS-h973AX ';
    is($test->{info}->model(), 'TS-h973AX',
        'QuTS hero model is selected from its subtree');

    $test->{info}{_qnap_quts_model} = '';
    $test->{info}{_qnap_qts_model} = '   ';
    $test->{info}{_qnap_legacy_model} = 'TS-459 Pro II';
    is($test->{info}->model(), 'TS-459 Pro II', 'Legacy model fallback');

    $test->{info}{_qnap_legacy_model} = '';
    ok(defined $test->{info}->model(),
        'Missing QNAP model falls back to inherited model');

    $test->{info}->clear_cache();
    is($test->{info}->model(), undef, 'No data returns undef model');
}

sub serial : Tests(6) {
    my $test = shift;

    can_ok($test->{info}, 'serial');
    is($test->{info}->serial(), 'Q193C41816',
        'Current serial is returned and whitespace is removed');

    $test->{info}{_id} = '.1.3.6.1.4.1.55062.2';
    $test->{info}{_qnap_quts_serial} = ' QUTSHERO123 ';
    is($test->{info}->serial(), 'QUTSHERO123',
        'QuTS hero serial is selected from its subtree');

    $test->{info}{_qnap_quts_serial} = '';
    $test->{info}{_qnap_qts_serial} = '';
    $test->{info}{_e_parent} = 1;
    $test->{info}{_e_class} = 1;
    $test->{info}{store}{e_parent} = {1 => 0};
    $test->{info}{store}{e_class} = {1 => 'chassis'};
    $test->mock_session->{Data}{'ENTITY-MIB::entPhysicalSerialNum'}
        = {1 => 'LEGACY123'};
    is($test->{info}->serial(), 'LEGACY123', 'Legacy ENTITY-MIB fallback');

    $test->{info}{_qnap_qts_serial} = '   ';
    $test->mock_session->{Data}{'ENTITY-MIB::entPhysicalSerialNum'}
        = {1 => '  LEGACY456  '};
    delete $test->{info}{_e_serial};
    delete $test->{info}{store}{e_serial};
    is($test->{info}->serial(), 'LEGACY456',
        'Fallback serial whitespace is removed');

    $test->{info}->clear_cache();
    is($test->{info}->serial(), undef, 'No data returns undef serial');
}

sub os : Tests(9) {
    my $test = shift;

    can_ok($test->{info}, 'os');
    is($test->{info}->os(), 'qts',
        'Explicit QTS subtree returns lowercase qts');

    $test->{info}{_id} = '.1.3.6.1.4.1.55062.2';
    $test->{info}{_qnap_quts_firmware} = 'h5.2.10.3577';
    is($test->{info}->os(), 'quts hero',
        'Explicit QuTS hero subtree returns lowercase quts hero');

    $test->{info}{_id} = '.1.3.6.1.4.1.55062';
    $test->{info}{_qnap_qts_firmware} = undef;
    is($test->{info}->os(), 'quts hero',
        'Generic current sysObjectID uses h-prefixed firmware fallback');

    $test->{info}{_id} = '.1.3.6.1.4.1.24681.2';
    $test->{info}{_qnap_quts_firmware} = undef;
    $test->{info}{_qnap_qts_firmware} = undef;
    $test->{info}{_description} = 'Linux TS-X73A h5.2.10.3577';
    is($test->{info}->os(), 'quts hero',
        'Legacy sysObjectID uses h-prefixed sysDescr fallback');

    $test->{info}{_description} = 'Linux TS-459 4.2.6.20240618';
    is($test->{info}->os(), 'qts',
        'Legacy sysObjectID with numeric firmware returns qts');

    $test->{info}{_description} = '';
    $test->{info}{_e_parent} = 1;
    $test->{info}{_e_class} = 1;
    $test->{info}{store}{e_parent} = {1 => 0};
    $test->{info}{store}{e_class} = {1 => 'chassis'};
    $test->mock_session->{Data}{'ENTITY-MIB::entPhysicalSoftwareRev'}
        = {1 => 'h4.5.4.2474'};
    is($test->{info}->os(), 'quts hero',
        'Legacy ENTITY-MIB h-prefixed firmware returns quts hero');

    $test->mock_session->{Data} = {};
    delete $test->{info}{_e_swver};
    delete $test->{info}{store}{e_swver};
    is($test->{info}->os(), 'qts',
        'Unknown QNAP firmware safely defaults to qts');

    $test->{info}{_id} = '.1.3.6.1.4.1.55062.1';
    $test->{info}{_description} = 'Linux TS-X73A h5.2.10.3577';
    is($test->{info}->os(), 'qts',
        'Explicit QTS subtree takes precedence over firmware fallback');
}

sub os_ver : Tests(8) {
    my $test = shift;

    can_ok($test->{info}, 'os_ver');
    is($test->{info}->os_ver(), '5.2.5.3145',
        'QTS firmware is returned and whitespace is removed');

    $test->{info}{_id} = '.1.3.6.1.4.1.55062.2';
    $test->{info}{_qnap_quts_firmware} = ' h5.2.10.3577 ';
    is($test->{info}->os_ver(), 'h5.2.10.3577',
        'QuTS hero firmware and its h prefix are preserved');

    $test->{info}{_qnap_quts_firmware} = '';
    $test->{info}{_qnap_qts_firmware} = '';
    $test->{info}{_e_parent} = 1;
    $test->{info}{_e_class} = 1;
    $test->{info}{store}{e_parent} = {1 => 0};
    $test->{info}{store}{e_class} = {1 => 'chassis'};
    $test->mock_session->{Data}{'ENTITY-MIB::entPhysicalSoftwareRev'}
        = {1 => '4.3.6.2665'};
    $test->{info}{_description} = 'Linux TS-X73A h5.2.10.3577';
    is($test->{info}->os_ver(), 'h5.2.10.3577',
        'QuTS hero sysDescr firmware fallback preserves h prefix');

    $test->{info}{_description} = '';
    is($test->{info}->os_ver(), '4.3.6.2665',
        'Legacy ENTITY-MIB firmware fallback');

    $test->mock_session->{Data} = {};
    delete $test->{info}{_e_swver};
    delete $test->{info}{store}{e_swver};
    $test->{info}{_description} = 'Linux TS-X41 5.2.5.3145';
    is($test->{info}->os_ver(), '5.2.5.3145',
        'QTS sysDescr firmware fallback');

    $test->{info}{_description} = 'Linux generic-host 6.1.0-18-amd64 x86_64';
    is($test->{info}->os_ver(), undef,
        'Generic Linux kernel sysDescr is not accepted as QNAP firmware');

    $test->{info}->clear_cache();
    is($test->{info}->os_ver(), undef, 'No data returns undef OS version');
}

sub entity_inventory_version : Tests(7) {
    my $test = shift;

    $test->{info}{_e_parent} = 1;
    $test->{info}{_e_class} = 1;
    $test->{info}{store}{e_parent} = {1 => 0, 2 => 1};
    $test->{info}{store}{e_class} = {1 => 'chassis', 2 => 'module'};
    $test->mock_session->{Data}{'ENTITY-MIB::entPhysicalSoftwareRev'} = {
        1 => '5.2.5',
        2 => '1.0',
    };

    can_ok($test->{info}, 'e_swver');
    my $versions = $test->{info}->e_swver();
    is($versions->{1}, '5.2.5.3145',
        'QTS chassis inventory uses the complete firmware version');
    is($versions->{2}, '1.0',
        'Non-chassis component software version remains unchanged');

    $test->{info}{_id} = '.1.3.6.1.4.1.55062.2';
    $test->{info}{_qnap_quts_firmware} = ' h5.2.10.3577 ';
    $versions = $test->{info}->e_swver();
    is($versions->{1}, 'h5.2.10.3577',
        'QuTS hero chassis inventory preserves h prefix and build');

    $test->{info}{_qnap_quts_firmware} = '';
    $test->{info}{_qnap_qts_firmware} = '';
    $test->{info}{_description} = 'Linux TS-X83XU h5.2.10.3577';
    $versions = $test->{info}->e_swver();
    is($versions->{1}, 'h5.2.10.3577',
        'QNAP sysDescr supplies the complete chassis inventory version');

    $test->{info}{_description} = '';
    $versions = $test->{info}->e_swver();
    is($versions->{1}, '5.2.5',
        'Legacy ENTITY-MIB-only chassis version remains available');
    is($test->{info}->os_ver(), '5.2.5',
        'Legacy ENTITY-MIB-only firmware remains the os_ver fallback');
}

1;
