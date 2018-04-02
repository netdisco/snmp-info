# Test::SNMP::Info::Layer1::Cyclades
#
# Copyright (c) 2018 Eric Miller
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

package Test::SNMP::Info::Layer1::Cyclades;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer1::Cyclades;

sub setup : Tests(setup) {
    my $test = shift;
    $test->SUPER::setup;

    my $phy_addr = pack( "H*", '0000944037B3' );

  # Start with a common cache that will serve most tests
  # Just define all alternatives to start with and alternatives in sequence to
  # test short circuits, we can verify conditional coverage with Devel::Cover
    my $cache_data = {
        '_layers'      => 1,
        '_description' => 'My Bogus ACS6008 Description',

        # ACS-MIB::acs6008
        '_id' => '.1.3.6.1.4.1.10418.16.1.5',

        '_acs_os_ver'        => '6.00',
        '_acs8k_os_ver'      => '8.00',
        '_cy5k_os_ver'       => '2.02',
        '_cy_os_ver'         => '3.00',
        '_acs_model'         => 'ACS6032',
        '_acs8k_model'       => 'ACS8032',
        '_cy5k_model'        => 'ACS5024',
        '_cy_model'          => 'TS3000',
        '_acs_serial'        => 'ABC6000',
        '_acs8k_serial'      => 'ABC8000',
        '_cy5k_serial'       => 'ABC5000',
        '_cy_serial'         => 'ABC3000',
        '_acs_ps1_status'    => 'statePowerOn',
        '_acs8k_ps1_status'  => 'statePowerOff',
        '_cy5k_ps1_status'   => 'powerOFF',
        '_cy_ps1_status'     => 'powerON',
        '_acs_ps2_status'    => 'powerNotInstaled',
        '_acs8k_ps2_status'  => 'statePowerOn',
        '_cy5k_ps2_status'   => 'powerON',
        '_cy_ps2_status'     => 'noinstalled',
        '_cy5k_root_ip'      => '2.3.4.5',
        '_cy_root_ip'        => '1.2.3.4',
        '_acs_port_tty'      => 1,
        '_acs8k_port_tty'    => 1,
        '_cy5k_port_tty'     => 1,
        '_cy_port_tty'       => 1,
        '_acs_port_name'     => 1,
        '_acs8k_port_name'   => 1,
        '_cy5k_port_name'    => 1,
        '_cy_port_name'      => 1,
        '_acs_port_speed'    => 1,
        '_acs8k_port_speed'  => 1,
        '_cy5k_port_speed'   => 1,
        '_cy_port_speed'     => 1,
        '_acs_port_cd'       => 1,
        '_acs8k_port_cd'     => 1,
        '_cy5k_port_cd'      => 1,
        '_cy_port_cd'        => 1,
        '_acs_port_socket'   => 1,
        '_acs8k_port_socket' => 1,
        '_cy5k_port_socket'  => 1,
        '_cy_port_socket'    => 1,
        '_i_index'           => 1,
        '_i_description'     => 1,
        '_i_speed'           => 1,
        '_i_up'              => 1,
        '_i_name'            => 1,

        'store' => {
            'i_index'           => { 1 => 1 },
            'i_speed'           => { 1 => 10000000 },
            'i_description'     => { 1 => 'Interface 1 Description' },
            'i_name'            => { 1 => 'Interface 1 Name' },
            'i_up'              => { 1 => 'up' },
            'acs_port_socket'   => { 1 => 'ACS 1 Name', 2 => 'ACS 2 Name' },
            'acs8k_port_socket' => { 1 => '8K 1 Name', 2 => '8K 2 Name' },
            'cy5k_port_socket'  => { 1 => '5K 1 Sock', 2 => '5K 2 Sock' },
            'cy_port_socket'    => { 1 => 'Port 1 Sock', 2 => 'Port 2 Sock' },
            'acs_port_tty'      => { 1 => 'ACS 1 TTY', 2 => 'ACS 2 TTY' },
            'acs8k_port_tty'    => { 1 => '8K 1 TTY', 2 => '8K 2 TTY' },
            'cy5k_port_tty'     => { 1 => '5K 1 TTY', 2 => '5K 2 TTY' },
            'cy_port_tty'       => { 1 => 'Port 1 TTY', 2 => 'Port 2 TTY' },
            'acs_port_name'     => { 1 => 'ACS 1 Name', 2 => 'ACS 2 Name' },
            'acs8k_port_name'   => { 1 => '8K 1 Name', 2 => '8K 2 Name' },
            'cy5k_port_name'    => { 1 => '5K 1 Name', 2 => '5K 2 Name' },
            'cy_port_name'      => { 1 => 'Port 1 Name', 2 => 'Port 2 Name' },
            'acs_port_speed'    => { 1 => 56000, 2 => 112000 },
            'acs8k_port_speed'  => { 1 => 112000, 2 => 384000 },
            'cy5k_port_speed'   => { 1 => 9600, 2 => 56000 },
            'cy_port_speed'     => { 1 => 2400, 2 => 9600 },
            'acs_port_cd'       => { 1 => 'down', 2 => 'up' },
            'acs8k_port_cd'     => { 1 => 'up', 2 => 'down' },
            'cy5k_port_cd'      => { 1 => 'down', 2 => 'down' },
            'cy_port_cd'        => { 1 => 'down', 2 => 'up' },
        }
    };
    $test->{info}->cache($cache_data);
}

sub layers : Tests(2) {
    my $test = shift;

    can_ok( $test->{info}, 'layers' );
    is( $test->{info}->layers(), '01000001', q(Layers returns '01000001') );
}

sub os : Tests(2) {
    my $test = shift;

    can_ok( $test->{info}, 'os' );
    is( $test->{info}->os(), 'avocent', q(Vendor returns 'avocent') );
}

sub os_ver : Tests(6) {
    my $test = shift;

    can_ok( $test->{info}, 'os_ver' );
    is( $test->{info}->os_ver(), '6.00', q(ACS version is expected value) );

    delete $test->{info}{_acs_os_ver};
    is( $test->{info}->os_ver(), '8.00',
        q(ACS 8K version is expected value) );

    delete $test->{info}{_acs8k_os_ver};
    is( $test->{info}->os_ver(), '2.02',
        q(ACS 5K version is expected value) );

    delete $test->{info}{_cy5k_os_ver};
    is( $test->{info}->os_ver(),
        '3.00', q(Original Cyclades version is expected value) );

    delete $test->{info}{_cy_os_ver};
    is( $test->{info}->os_ver(),
        undef, q(No MIB leaf data returns undef os_ver) );
}

sub vendor : Tests(2) {
    my $test = shift;

    can_ok( $test->{info}, 'vendor' );
    is( $test->{info}->vendor(), 'vertiv', q(Vendor returns 'vertiv') );
}

sub model : Tests(7) {
    my $test = shift;

    can_ok( $test->{info}, 'model' );
    is( $test->{info}->model(), 'acs6032', q(ACS model is expected value) );

    delete $test->{info}{_acs_model};
    is( $test->{info}->model(), 'acs8032',
        q(ACS 8K model is expected value) );

    delete $test->{info}{_acs8k_model};
    is( $test->{info}->model(), 'acs5024',
        q(ACS 5K model is expected value) );

    delete $test->{info}{_cy5k_model};
    is( $test->{info}->model(),
        'ts3000', q(Original Cyclades model is expected value) );

    delete $test->{info}{_cy_model};
    is( $test->{info}->model(),
        'acs6008', q(No MIB leaf data returns translated id) );

    # We won't get to class without sysObjectID that matches enterprise id,
    # so use one that isn't defined in MIB
    $test->{info}{_id} = '.1.3.6.1.4.1.10418.16.1.6';
    is( $test->{info}->model(),
        'acsProducts.6',
        q(Unknown id returns partially translated id) );
}

sub serial : Tests(6) {
    my $test = shift;

    can_ok( $test->{info}, 'serial' );
    is( $test->{info}->serial(), 'ABC6000', q(ACS serial is expected value) );

    delete $test->{info}{_acs_serial};
    is( $test->{info}->serial(),
        'ABC8000', q(ACS 8K serial is expected value) );

    delete $test->{info}{_acs8k_serial};
    is( $test->{info}->serial(),
        'ABC5000', q(ACS 5K serial is expected value) );

    delete $test->{info}{_cy5k_serial};
    is( $test->{info}->serial(),
        'ABC3000', q(Original Cyclades serial is expected value) );

    delete $test->{info}{_cy_serial};
    is( $test->{info}->serial(),
        undef, q(No MIB leaf data returns undef serial) );
}

sub root_ip : Tests(4) {
    my $test = shift;

    can_ok( $test->{info}, 'root_ip' );
    is( $test->{info}->root_ip(),
        '2.3.4.5', q(ACS 5K root IP is expected value) );

    delete $test->{info}{_cy5k_root_ip};
    is( $test->{info}->root_ip(),
        '1.2.3.4', q(Original Cyclades root IP is expected value) );

    delete $test->{info}{_cy_root_ip};
    is( $test->{info}->root_ip(),
        undef, q(No MIB leaf data returns undef root IP) );
}

sub ps1_status : Tests(6) {
    my $test = shift;

    can_ok( $test->{info}, 'ps1_status' );
    is( $test->{info}->ps1_status(),
        'statePowerOn', q(ACS power supply 1 status is expected value) );

    delete $test->{info}{_acs_ps1_status};
    is( $test->{info}->ps1_status(),
        'statePowerOff', q(ACS 8K power supply 1 status is expected value) );

    delete $test->{info}{_acs8k_ps1_status};
    is( $test->{info}->ps1_status(),
        'powerOFF', q(ACS 5K power supply 1 status is expected value) );

    delete $test->{info}{_cy5k_ps1_status};
    is( $test->{info}->ps1_status(),
        'powerON',
        q(Original Cyclades power supply 1 status is expected value) );

    delete $test->{info}{_cy_ps1_status};
    is( $test->{info}->ps1_status(),
        undef, q(No MIB leaf data returns undef power supply 1 status) );
}

sub ps2_status : Tests(6) {
    my $test = shift;

    can_ok( $test->{info}, 'ps2_status' );
    is( $test->{info}->ps2_status(),
        'powerNotInstaled', q(ACS power supply 2 status is expected value) );

    delete $test->{info}{_acs_ps2_status};
    is( $test->{info}->ps2_status(),
        'statePowerOn', q(ACS 8K power supply 2 status is expected value) );

    delete $test->{info}{_acs8k_ps2_status};
    is( $test->{info}->ps2_status(),
        'powerON', q(ACS 5K power supply 2 status is expected value) );

    delete $test->{info}{_cy5k_ps2_status};
    is( $test->{info}->ps2_status(),
        'noinstalled',
        q(Original Cyclades power supply 2 status is expected value) );

    delete $test->{info}{_cy_ps2_status};
    is( $test->{info}->ps2_status(),
        undef, q(No MIB leaf data returns undef power supply 2 status) );
}

sub i_index : Tests(6) {
    my $test = shift;

    can_ok( $test->{info}, 'i_index' );

    my $expected = {
        '1'          => '1',
        'ACS 1 Name' => 'ACS 1 Name',
        'ACS 2 Name' => 'ACS 2 Name'
    };
    cmp_deeply( $test->{info}->i_index(),
        $expected, q(ACS interface indices have expected values) );

    delete $test->{info}{_acs_port_socket};
    delete $test->{info}{store}{acs_port_socket};
    $expected = {
        '1'         => '1',
        '8K 1 Name' => '8K 1 Name',
        '8K 2 Name' => '8K 2 Name'
    };
    cmp_deeply( $test->{info}->i_index(),
        $expected, q(ACS 8K interface indices have expected values) );

    delete $test->{info}{_acs8k_port_socket};
    delete $test->{info}{store}{acs8k_port_socket};
    $expected = {
        '1'         => '1',
        '5K 1 Sock' => '5K 1 Sock',
        '5K 2 Sock' => '5K 2 Sock'
    };
    cmp_deeply( $test->{info}->i_index(),
        $expected, q(ACS 5K interface indices have expected values) );

    delete $test->{info}{_cy5k_port_socket};
    delete $test->{info}{store}{cy5k_port_socket};
    $expected = {
        '1'           => '1',
        'Port 1 Sock' => 'Port 1 Sock',
        'Port 2 Sock' => 'Port 2 Sock'
    };
    cmp_deeply( $test->{info}->i_index(),
        $expected,
        q(Original Cyclades interface indices have expected values) );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->interfaces(),
        {}, q(Empty SNMP table results in empty hash) );
}

sub interfaces : Tests(6) {
    my $test = shift;

    can_ok( $test->{info}, 'interfaces' );
    my $expected = {
        '1'          => 'Interface 1 Description',
        'ACS 1 Name' => 'ACS 1 TTY',
        'ACS 2 Name' => 'ACS 2 TTY'
    };
    cmp_deeply( $test->{info}->interfaces(),
        $expected, q(ACS interfaces have expected values) );

    delete $test->{info}{_acs_port_socket};
    delete $test->{info}{store}{acs_port_socket};
    delete $test->{info}{_acs_port_tty};
    delete $test->{info}{store}{acs_port_tty};
    $expected = {
        '1'         => 'Interface 1 Description',
        '8K 1 Name' => '8K 1 TTY',
        '8K 2 Name' => '8K 2 TTY'
    };
    cmp_deeply( $test->{info}->interfaces(),
        $expected, q(ACS 8K interfaces have expected values) );

    delete $test->{info}{_acs8k_port_socket};
    delete $test->{info}{store}{acs8k_port_socket};
    delete $test->{info}{_acs8k_port_tty};
    delete $test->{info}{store}{acs8k_port_tty};
    $expected = {
        '1'         => 'Interface 1 Description',
        '5K 1 Sock' => '5K 1 TTY',
        '5K 2 Sock' => '5K 2 TTY'
    };
    cmp_deeply( $test->{info}->interfaces(),
        $expected, q(ACS 5K interfaces have expected values) );

    delete $test->{info}{_cy5k_port_socket};
    delete $test->{info}{store}{cy5k_port_socket};
    delete $test->{info}{_cy5k_port_tty};
    delete $test->{info}{store}{cy5k_port_tty};
    $expected = {
        '1'           => 'Interface 1 Description',
        'Port 1 Sock' => 'Port 1 TTY',
        'Port 2 Sock' => 'Port 2 TTY'
    };
    cmp_deeply( $test->{info}->interfaces(),
        $expected, q(Original Cyclades interfaces have expected values) );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->interfaces(),
        {}, q(Empty SNMP table results in empty hash) );
}

sub i_speed : Tests(6) {
    my $test = shift;

    can_ok( $test->{info}, 'i_speed' );

    # Munge in effect
    my $expected = {
        '1'          => '10 Mbps',
        'ACS 1 Name' => 56000,
        'ACS 2 Name' => 112000
    };
    cmp_deeply( $test->{info}->i_speed(),
        $expected, q(ACS interface speeds have expected values) );

    delete $test->{info}{_acs_port_socket};
    delete $test->{info}{store}{acs_port_socket};
    delete $test->{info}{_acs_port_speed};
    delete $test->{info}{store}{acs_port_speed};
    $expected = {
        '1'         => '10 Mbps',
        '8K 1 Name' => 112000,
        '8K 2 Name' => 384000
    };
    cmp_deeply( $test->{info}->i_speed(),
        $expected, q(ACS 8K interface speeds have expected values) );

    delete $test->{info}{_acs8k_port_socket};
    delete $test->{info}{store}{acs8k_port_socket};
    delete $test->{info}{_acs8k_port_speed};
    delete $test->{info}{store}{acs8k_port_speed};
    $expected = {
        '1'         => '10 Mbps',
        '5K 1 Sock' => 9600,
        '5K 2 Sock' => 56000
    };
    cmp_deeply( $test->{info}->i_speed(),
        $expected, q(ACS 5K interface speeds have expected values) );

    delete $test->{info}{_cy5k_port_socket};
    delete $test->{info}{store}{cy5k_port_socket};
    delete $test->{info}{_cy5k_port_speed};
    delete $test->{info}{store}{cy5k_port_speed};
    $expected = {
        '1'           => '10 Mbps',
        'Port 1 Sock' => 2400,
        'Port 2 Sock' => 9600
    };
    cmp_deeply( $test->{info}->i_speed(),
        $expected,
        q(Original Cyclades interface speeds have expected values) );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->i_speed(),
        {}, q(Empty SNMP table results in empty hash) );
}

sub i_up : Tests(6) {
    my $test = shift;

    can_ok( $test->{info}, 'i_up' );

    my $expected = {
        '1'          => 'up',
        'ACS 1 Name' => 'down',
        'ACS 2 Name' => 'up'
    };
    cmp_deeply( $test->{info}->i_up(),
        $expected, q(ACS interface statuses have expected values) );

    delete $test->{info}{_acs_port_socket};
    delete $test->{info}{store}{acs_port_socket};
    delete $test->{info}{_acs_port_cd};
    delete $test->{info}{store}{acs_port_cd};
    $expected = {
        '1'         => 'up',
        '8K 1 Name' => 'up',
        '8K 2 Name' => 'down'
    };
    cmp_deeply( $test->{info}->i_up(),
        $expected, q(ACS 8K interface statuses have expected values) );

    delete $test->{info}{_acs8k_port_socket};
    delete $test->{info}{store}{acs8k_port_socket};
    delete $test->{info}{_acs8k_port_cd};
    delete $test->{info}{store}{acs8k_port_cd};
    $expected = {
        '1'         => 'up',
        '5K 1 Sock' => 'down',
        '5K 2 Sock' => 'down'
    };
    cmp_deeply( $test->{info}->i_up(),
        $expected, q(ACS 5K interface statuses have expected values) );

    delete $test->{info}{_cy5k_port_socket};
    delete $test->{info}{store}{cy5k_port_socket};
    delete $test->{info}{_cy5k_port_cd};
    delete $test->{info}{store}{cy5k_port_cd};
    $expected = {
        '1'           => 'up',
        'Port 1 Sock' => 'down',
        'Port 2 Sock' => 'up'
    };
    cmp_deeply( $test->{info}->i_up(),
        $expected,
        q(Original Cyclades interface statuses have expected values) );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->i_up(),
        {}, q(Empty SNMP table results in empty hash) );
}

sub i_description : Tests(6) {
    my $test = shift;

    can_ok( $test->{info}, 'i_description' );

    my $expected = {
        '1'          => 'Interface 1 Description',
        'ACS 1 Name' => 'ACS 1 Name',
        'ACS 2 Name' => 'ACS 2 Name'
    };
    cmp_deeply( $test->{info}->i_description(),
        $expected, q(ACS interface descriptions have expected values) );

    delete $test->{info}{_acs_port_socket};
    delete $test->{info}{store}{acs_port_socket};
    delete $test->{info}{_acs_port_name};
    delete $test->{info}{store}{acs_port_name};
    $expected = {
        '1'         => 'Interface 1 Description',
        '8K 1 Name' => '8K 1 Name',
        '8K 2 Name' => '8K 2 Name'
    };
    cmp_deeply( $test->{info}->i_description(),
        $expected, q(ACS 8K interface descriptions have expected values) );

    delete $test->{info}{_acs8k_port_socket};
    delete $test->{info}{store}{acs8k_port_socket};
    delete $test->{info}{_acs8k_port_name};
    delete $test->{info}{store}{acs8k_port_name};
    $expected = {
        '1'         => 'Interface 1 Description',
        '5K 1 Sock' => '5K 1 Name',
        '5K 2 Sock' => '5K 2 Name'
    };
    cmp_deeply( $test->{info}->i_description(),
        $expected, q(ACS 5K interface descriptions have expected values) );

    delete $test->{info}{_cy5k_port_socket};
    delete $test->{info}{store}{cy5k_port_socket};
    delete $test->{info}{_cy5k_port_name};
    delete $test->{info}{store}{cy5k_port_name};
    $expected = {
        '1'           => 'Interface 1 Description',
        'Port 1 Sock' => 'Port 1 Name',
        'Port 2 Sock' => 'Port 2 Name'
    };
    cmp_deeply( $test->{info}->i_description(),
        $expected,
        q(Original Cyclades interface descriptions have expected values) );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->i_description(),
        {}, q(Empty SNMP table results in empty hash) );
}

sub i_name : Tests(6) {
    my $test = shift;

    can_ok( $test->{info}, 'i_name' );

    my $expected = {
        '1'          => 'Interface 1 Name',
        'ACS 1 Name' => 'ACS 1 Name',
        'ACS 2 Name' => 'ACS 2 Name'
    };
    cmp_deeply( $test->{info}->i_name(),
        $expected, q(ACS interface descriptions have expected values) );

    delete $test->{info}{_acs_port_socket};
    delete $test->{info}{store}{acs_port_socket};
    delete $test->{info}{_acs_port_name};
    delete $test->{info}{store}{acs_port_name};
    $expected = {
        '1'         => 'Interface 1 Name',
        '8K 1 Name' => '8K 1 Name',
        '8K 2 Name' => '8K 2 Name'
    };
    cmp_deeply( $test->{info}->i_name(),
        $expected, q(ACS 8K interface descriptions have expected values) );

    delete $test->{info}{_acs8k_port_socket};
    delete $test->{info}{store}{acs8k_port_socket};
    delete $test->{info}{_acs8k_port_name};
    delete $test->{info}{store}{acs8k_port_name};
    $expected = {
        '1'         => 'Interface 1 Name',
        '5K 1 Sock' => '5K 1 Name',
        '5K 2 Sock' => '5K 2 Name'
    };
    cmp_deeply( $test->{info}->i_name(),
        $expected, q(ACS 5K interface descriptions have expected values) );

    delete $test->{info}{_cy5k_port_socket};
    delete $test->{info}{store}{cy5k_port_socket};
    delete $test->{info}{_cy5k_port_name};
    delete $test->{info}{store}{cy5k_port_name};
    $expected = {
        '1'           => 'Interface 1 Name',
        'Port 1 Sock' => 'Port 1 Name',
        'Port 2 Sock' => 'Port 2 Name'
    };
    cmp_deeply( $test->{info}->i_name(),
        $expected,
        q(Original Cyclades interface descriptions have expected values) );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->i_name(),
        {}, q(Empty SNMP table results in empty hash) );
}

1;
