# Test::SNMP::Info::Layer7::Kemp
#
# Copyright (c) 2026 df-an and the SNMP::Info Developers
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

package Test::SNMP::Info::Layer7::Kemp;

use Test::Class::Most parent => 'My::Test::Class';
use SNMP::Info::Layer7::Kemp;

sub setup : Tests(setup) {
    my $test = shift;
    $test->SUPER::setup;
    $test->{info}->cache({
        '_description' => 'Linux KEMP 4.14.137 x86_64',
        '_id' => '.1.3.6.1.4.1.12196.250.10',
        '_layers' => 4,
        '_kemp_vs_ip' => 1,
        '_kemp_vs_addrtype' => 1,
        '_old_ip_table' => 1,
        '_old_ip_index' => 1,
        '_old_ip_netmask' => 1,
        'store' => {
            'kemp_vs_ip' => {
                1 => pack('C4', 192, 0, 2, 10), 2 => pack('C4', 192, 0, 2, 10),
                3 => pack('C4', 192, 0, 2, 1), 4 => pack('n8', 0x2001, 0xdb8, 0, 0, 0, 0, 0, 1),
                5 => pack('C4', 0, 0, 0, 0), 6 => pack('C4', 255, 255, 255, 255),
                7 => '999.0.2.1', 8 => '',
                10 => pack('C4', 192, 0, 2, 20), 11 => pack('C4', 192, 0, 2, 30),
            },
            'kemp_vs_addrtype' => {
                1 => 'ipv4', 2 => 'ipv4', 3 => 1, 4 => 'ipv6',
                5 => 1, 6 => 1, 7 => 1, 8 => 1, 9 => 1, 10 => 1,
            },
            'old_ip_table' => { '192.0.2.1' => '192.0.2.1' },
            'old_ip_index' => { '192.0.2.1' => 2 },
            'old_ip_netmask' => { '192.0.2.1' => '255.255.255.0' },
        },
    });
}

sub device_type : Tests(+3) {
    my $test = shift;
    $test->SUPER::device_type;
    for my $layers (0, 64, 76) {
        $test->{info}{_layers} = $layers;
        is($test->{info}->device_type(), 'SNMP::Info::Layer7::Kemp',
            "LoadMaster detected with sysServices $layers");
    }
}

sub vendor : Tests(1) {
    is(shift->{info}->vendor(), 'kemp', 'Vendor');
}

sub model : Tests(1) {
    is(shift->{info}->model(), 'LoadMaster', 'Model');
}

sub os : Tests(1) {
    is(shift->{info}->os(), 'LMOS', 'LoadMaster OS identifier');
}

sub os_ver : Tests(3) {
    my $test = shift;
    my $version = '7.2.63.3.23e1735.RELEASE.20260625-1143';
    $test->mock_session->{Data}{'B100-MIB::patchVersion'} = { 0 => $version };
    is($test->{info}->os_ver(), $version, 'Firmware read via named MIB scalar');
    $test->mock_session->{Data} = {};
    is($test->{info}->os_ver(), $version, 'Normal scalar caching');
    $test->{info}->clear_cache();
    is($test->{info}->os_ver(), undef, 'Missing firmware after clearing cache');
}

sub serial : Tests(3) {
    my $test = shift;
    my $hex = '80001F8880C405165A36D9A86A00000000';
    $test->mock_session->{Data}{'SNMP-FRAMEWORK-MIB::snmpEngineID'} = {
        0 => pack('H*', $hex),
    };
    is($test->{info}->serial(), 'SNMP-ENGINEID-' . $hex, 'Engine ID surrogate');
    $test->mock_session->{Data} = {};
    $test->{info}->clear_cache();
    is($test->{info}->serial(), undef, 'Missing engine ID');
    $test->{info}{_kemp_engine_id} = '';
    is($test->{info}->serial(), undef, 'Empty engine ID');
}

sub ip_table : Tests(4) {
    my $test = shift;
    is_deeply($test->{info}->ip_table(), {
        '192.0.2.1' => '192.0.2.1', '192.0.2.10' => '192.0.2.10',
        '192.0.2.20' => '192.0.2.20',
    }, 'Merge and deduplicate IPv4 VIPs; reject invalid and non-IPv4 rows');
    is_deeply($test->{info}->old_ip_table(), { '192.0.2.1' => '192.0.2.1' },
        'Inherited cache is unchanged');
    $test->{info}->clear_cache();
    is_deeply($test->{info}->ip_table(), {}, 'Empty tables');
    $test->mock_session->{Data}{'B100-MIB::vSIp'} = { 1 => pack('C4', 192, 0, 2, 10) };
    $test->mock_session->{Data}{'B100-MIB::vSAddrtype'} = { 1 => 'ipv4' };
    $test->{info}->clear_cache();
    is_deeply($test->{info}->ip_table(), { '192.0.2.10' => '192.0.2.10' },
        'Vendor-only address read and munged through named MIB table');
}

sub ip_index : Tests(5) {
    my $test = shift;
    is_deeply($test->{info}->ip_index(), {
        '192.0.2.1' => 2, '192.0.2.10' => 0, '192.0.2.20' => 0,
    }, 'Preserve real interface index; VIPs use unknown index, not service index');
    $test->{info}->clear_cache();
    is_deeply($test->{info}->ip_index(), {}, 'Empty tables');
    $test->{info}->cache({
        '_new_ip_index' => 1, '_new_ip_type' => 1, '_new_ip_prefix' => 1,
        'store' => {
            'new_ip_index' => { '1.4.192.0.2.1' => 2 },
            'new_ip_type' => { '1.4.192.0.2.1' => 'unicast' },
            'new_ip_prefix' => { '1.4.192.0.2.1' => '.1.3.6.1.2.1.4.32.1.5.2.1.4.192.0.2.0.24' },
        },
    });
    is_deeply($test->{info}->ip_index(), { '192.0.2.1' => 2 },
        'Inherited modern IP-MIB fallback with missing vendor tables');
    is_deeply($test->{info}->ip_table(), { '192.0.2.1' => '192.0.2.1' },
        'Modern IP-MIB address fallback');
    is_deeply($test->{info}->ip_netmask(), { '192.0.2.1' => '255.255.255.0' },
        'Modern IP-MIB prefix fallback');
}

sub ip_netmask : Tests(2) {
    my $test = shift;
    is_deeply($test->{info}->ip_netmask(), {
        '192.0.2.1' => '255.255.255.0',
        '192.0.2.10' => '255.255.255.255', '192.0.2.20' => '255.255.255.255',
    }, 'Preserve real subnet masks; additional VIPs use host masks');
    $test->{info}->clear_cache();
    is_deeply($test->{info}->ip_netmask(), {}, 'Empty tables');
}

1;
