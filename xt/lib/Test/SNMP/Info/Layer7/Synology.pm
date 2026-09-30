# Test::SNMP::Info::Layer7::Synology
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
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package Test::SNMP::Info::Layer7::Synology;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer7::Synology;

my $VERSION_OID = '.1.3.6.1.4.1.6574.1.5.3.0';

sub setup : Tests(setup) {
    my $test = shift;
    $test->SUPER::setup;

    $test->{info}->cache({
        '_layers'          => 0,
        '_description'     => 'Linux test-nas 4.4.302+',
        '_id'              => '.1.3.6.1.4.1.8072.3.2.10',
        '_name'            => 'nas.example.invalid',
        '_synology_model'  => " DS923+ \x00",
        '_synology_serial' => " SYNTHETIC0001 \x00",
        '_synology_ver'    => " DSM 7.3-86009 \x00",
        'store'            => {},
    });

    $test->mock_session->{synology_version} = " DSM 7.3-86009 \x00";
    $test->mock_session->mock(
        'get',
        sub {
            my ($session, $oid) = @_;
            return unless $oid eq $VERSION_OID;
            return $session->{synology_version};
        }
    );
}

sub device_type : Tests(+8) {
    my $test = shift;
    $test->SUPER::device_type;

    $test->{info}{_id} = '.1.3.6.1.4.1.6574.1.5';
    is($test->{info}->device_type(), 'SNMP::Info::Layer7::Synology',
        'Native Synology enterprise with DSM version is detected');

    $test->{info}{_id} = '.1.3.6.1.4.1.8072.3.2.10';
    $test->mock_session->{synology_version} = 'NOSUCHOBJECT';
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::NetSNMP',
        'Generic Net-SNMP agent without the DSM scalar is not Synology');

    $test->mock_session->{synology_version} = undef;
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::NetSNMP',
        'Undefined DSM version safely falls back to generic Net-SNMP');

    $test->mock_session->{synology_version} = 'APM 1.0';
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::NetSNMP',
        'Another Synology product is not assumed to run DSM');

    $test->{info}{_id} = '.1.3.6.1.4.1.6574.1.5';
    is($test->{info}->device_type(), 'SNMP::Info',
        'Native Synology enterprise without a DSM marker is not assumed DSM');

    $test->{info}{_id} = '.1.3.6.1.4.1.8072';
    $test->mock_session->{synology_version} = 'DSM 7.3-86009';
    isnt($test->{info}->device_type(), 'SNMP::Info::Layer7::Synology',
        'Net-SNMP enterprise root does not trigger the DSM probe');

    $test->{info}{_id} = '.1.3.6.1.4.1.8072.3.2.11';
    isnt($test->{info}->device_type(), 'SNMP::Info::Layer7::Synology',
        'Other Net-SNMP platform IDs do not trigger the DSM probe');

    $test->{info}{_id} = '.1.3.6.1.4.1.2021.250.10';
    isnt($test->{info}->device_type(), 'SNMP::Info::Layer7::Synology',
        'Non-Net-SNMP enterprises are not classified by probe data');
}

sub layer_classification : Tests(2) {
    my $test = shift;

    isa_ok($test->{info}, 'SNMP::Info::Layer7',
        'Synology NAS is an application-layer device');
    ok(!$test->{info}->isa('SNMP::Info::Layer3'),
        'Synology does not inherit routing-layer behavior');
}

sub synology_globals : Tests(3) {
    my $test = shift;
    my $globals = $test->{info}->globals();

    is($globals->{synology_model}, '.1.3.6.1.4.1.6574.1.5.1.0',
        'Model OID');
    is($globals->{synology_serial}, '.1.3.6.1.4.1.6574.1.5.2.0',
        'Serial OID');
    is($globals->{synology_ver}, '.1.3.6.1.4.1.6574.1.5.3.0',
        'DSM version OID');
}

sub vendor : Tests(2) {
    my $test = shift;

    can_ok($test->{info}, 'vendor');
    is($test->{info}->vendor(), 'synology',
        q(Vendor returns 'synology'));
}

sub name : Tests(2) {
    my $test = shift;

    can_ok($test->{info}, 'name');
    is($test->{info}->name(), 'nas.example.invalid',
        'Name is inherited from standard sysName');
}

sub model : Tests(3) {
    my $test = shift;

    can_ok($test->{info}, 'model');
    is($test->{info}->model(), 'DS923+',
        'Model is returned without whitespace or trailing NUL bytes');

    $test->{info}{_synology_model} = " \x00";
    ok(defined $test->{info}->model(),
        'Blank Synology model falls back to the inherited model');
}

sub serial : Tests(3) {
    my $test = shift;

    can_ok($test->{info}, 'serial');
    is($test->{info}->serial(), 'SYNTHETIC0001',
        'Serial is returned without whitespace or trailing NUL bytes');

    $test->{info}{_synology_serial} = " \x00";
    is($test->{info}->serial(), undef, 'Blank serial returns undef');
}

sub os : Tests(2) {
    my $test = shift;

    can_ok($test->{info}, 'os');
    is($test->{info}->os(), 'dsm', q(OS returns 'dsm'));
}

sub os_ver : Tests(4) {
    my $test = shift;

    can_ok($test->{info}, 'os_ver');
    is($test->{info}->os_ver(), '7.3-86009',
        'Leading DSM label and surrounding whitespace are removed');

    $test->{info}{_synology_ver} = 'DSM 7.2.2-72806 Update 4';
    is($test->{info}->os_ver(), '7.2.2-72806 Update 4',
        'Complete vendor version suffix is preserved');

    $test->{info}{_synology_ver} = " \x00";
    is($test->{info}->os_ver(), undef, 'Blank DSM version returns undef');
}

1;
