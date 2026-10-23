# Test::SNMP::Info::Layer3::TeltonikaRutOS
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

package Test::SNMP::Info::Layer3::TeltonikaRutOS;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::TeltonikaRutOS;

my $PRODUCT_OID = '.1.3.6.1.4.1.48690.1.3.0';
my $LEGACY_PRODUCT_OID = '.1.3.6.1.4.1.48690.1.8.0';

sub setup : Tests(setup) {
    my $test = shift;
    $test->SUPER::setup;

    _set_device($test, '.1.3.6.1.4.1.8072.3.2.10');
    _set_oid_values($test, {
        $PRODUCT_OID => 'RUTX1100XXXX',
    });
    $test->{info}->cache({
        '_serial1'             => 'SYNTHETIC-SERIAL-001',
        '_teltonika_model'     => 'RUTX1100XXXX',
        '_teltonika_firmware'  => 'RUTX_R_00.07.22.3',
    });
}

sub _set_device {
    my ($test, $id) = @_;
    $test->{info}->clear_cache;
    $test->{info}->cache({
        '_layers'      => 4,
        '_description' => 'Linux test-router 5.10.0 #1 SMP x86_64',
        '_id'          => $id,
        'store'        => {},
    });
}

sub _set_oid_values {
    my ($test, $values) = @_;
    $test->mock_session->{teltonika_oid_values} = $values;
    $test->mock_session->mock(
        'get',
        sub {
            my ($session, $oid) = @_;
            return $session->{teltonika_oid_values}{$oid};
        }
    );
}

sub device_type_variants : Tests(+12) {
    my $test = shift;

    my @modern_products = qw(
        RUT200000000
        RUTX1100XXXX
        RUTXR10000000
        RUTM50000000
        RUTC50000000
        TRB500000000
        OTD140000000
        TCR100000000
        TSW212000000
        TAP200000000
    );

    foreach my $product (@modern_products) {
        _set_device($test, '.1.3.6.1.4.1.8072.3.2.10');
        _set_oid_values($test, { $PRODUCT_OID => $product });
        is($test->{info}->device_type(), 'SNMP::Info::Layer3::TeltonikaRutOS',
            "$product detected by modern product code with generic sysObjectID");
    }

    _set_device($test, '.1.3.6.1.4.1.48690');
    _set_oid_values($test, {
        $PRODUCT_OID        => 'Teltonika',
        $LEGACY_PRODUCT_OID => 'RUT950U02XXX',
    });
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::Teltonika',
        'Legacy RUT9xx product code keeps the original class');

    _set_device($test, '.1.3.6.1.4.1.8072.3.2.10');
    _set_oid_values($test, {});
    is($test->{info}->device_type(), 'SNMP::Info::Layer3::NetSNMP',
        'Generic Net-SNMP device without Teltonika product code stays generic');
}

sub vendor : Tests(1) {
    my $test = shift;
    is($test->{info}->vendor(), 'teltonika', 'Vendor');
}

sub os : Tests(1) {
    my $test = shift;
    is($test->{info}->os(), 'rutos', 'OS');
}

sub model : Tests(1) {
    my $test = shift;
    is($test->{info}->model(), 'RUTX1100XXXX', 'Product code');
}

sub os_ver : Tests(1) {
    my $test = shift;
    is($test->{info}->os_ver(), 'RUTX_R_00.07.22.3', 'RutOS firmware');
}

sub serial : Tests(1) {
    my $test = shift;
    is($test->{info}->serial(), 'SYNTHETIC-SERIAL-001', 'Serial');
}

1;
