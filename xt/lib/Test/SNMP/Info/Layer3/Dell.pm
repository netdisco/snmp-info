# Test::SNMP::Info::Layer3::Dell
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

package Test::SNMP::Info::Layer3::Dell;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Dell;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_layers'      => 4,
    '_description' => 'Powerconnect 8024F, 3.1.4.5, VxWorks 6.5',

    # DELL-REF-MIB::dell8024FSwitch
    '_id'            => '.1.3.6.1.4.1.674.10895.3024',
    '_i_description' => 1,
    '_i_name'        => 1,

    # These don't exist in the 8024F, but pretend they do to simplify fan,
    # ps*, and duplex_admin test code, there is no equivalent in newer models
    '_dell_fan_desc'     => 1,
    '_dell_fan_state'    => 1,
    '_dell_pwr_src'      => 1,
    '_dell_pwr_state'    => 1,
    '_dell_pwr_desc'     => 1,
    '_dell_duplex'       => 1,
    '_dell_duplex_admin' => 1,
    '_dell_auto'         => 1,

    # ENTITY-MIB used for coverage of entity_derived_os_ver in os_ver
    '_e_parent' => 1,
    '_e_class'  => 1,
    'store'     => {
      'i_description' => {
        1 => 'Ethernet Interface',
        2 => 'Ethernet Interface',
        3 => 'Ethernet Interface'
      },
      'i_name'         => {1        => 'g1',     2        => 'g2'},
      'dell_fan_desc'  => {67109249 => 'fan1',   67109250 => 'fan2'},
      'dell_fan_state' => {67109249 => 'normal', 67109250 => 'warning'},
      'dell_pwr_src'   => {67109185 => 'ac',     67109186 => 'unknown'},
      'dell_pwr_state' => {67109185 => 'normal', 67109186 => 'notPresent'},
      'dell_pwr_desc'  => {67109185 => 'ps1',    67109186 => 'ps2'},
      'dell_duplex'       => {1 => 'full',     2 => 'half', 3 => 'unknown'},
      'dell_duplex_admin' => {1 => 'full',     2 => 'half', 3 => 'none'},
      'dell_auto'         => {1 => 'disabled', 2 => 'disabled', 3 => 'enabled'},
      'e_parent' => {1 => 0, 2 => 1, 3 => 2, 54 => 1, 55 => 54},
      'e_class'  => {
        1  => 'stack',
        2  => 'chassis',
        3  => 'module',
        54 => 'chassis',
        55 => 'module'
      },
    },
  };
  $test->{info}->cache($cache_data);
}

# This class is also used for devices that don't have the Dell IANA private
# enterprise number (674). If we ever create a new class to cover these
# devices these tests should serve as a reminder to remove the applicable
# from this class
sub device_type : Tests(+2) {
  my $test = shift;
  $test->SUPER::device_type();

  # IBM BladeCenter 4-Port GB Ethernet Switch Module
  my $cache_data = {
    '_layers'      => 2,
    '_description' => 'IBM Gigabit Ethernet Switch Module',
    '_id'          => '.1.3.6.1.4.1.2'
  };
  $test->{info}->cache($cache_data);
  is($test->{info}->device_type,
    'SNMP::Info::Layer3::Dell',
    'IBM BladeCenter 4-Port GB Ethernet Switch Module');
  $test->{info}->clear_cache();

  # Linksys 2024/2048
  $cache_data = {
    '_layers'      => 2,
    '_description' => '48-Port 10/100/1000 Gigabit Switch w/WebView',
    '_id'          => '.1.3.6.1.4.1.3955.6.1.2024.1'
  };
  $test->{info}->cache($cache_data);
  is($test->{info}->device_type,
    'SNMP::Info::Layer3::Dell', 'Linksys 2024/2048');
  $test->{info}->clear_cache();
}

sub model : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'model');

  is($test->{info}->model(),
    '8024F', q(Model has expected value using 'sysObjectID'));

  # Non Dell sysObjectID's won't resolve and should return a partially
  # resolved OID
  $test->{info}{_id} = '.1.3.6.1.4.1.3955.6.1.2024.1';
  is($test->{info}->model(),
    'enterprises.3955.6.1.2024.1',
    q(Non Dell returns partially resolved 'sysObjectID'));

  # On older switches, sysObjectID will not resolve, this is from
  # Dell-Vendor-MIB::productIdentificationDisplayName which is not populated
  # on newer models such as the dell8024FSwitch which snmp data is in the
  # test setup method to populate the default cache
  $test->{info}{_dell_id_name} = 'PowerConnect 5324';
  is($test->{info}->model(),
    '5324', q(Older 'productIdentificationDisplayName' returns expected model));

  $test->{info}->clear_cache();
  is($test->{info}->model(), undef, q(No id returns undef model));
}

sub vendor : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'dell', q(Vendor returns 'dell'));

  $test->{info}{_id} = '.1.3.6.1.4.1.3955.6.1.2024.1';
  is($test->{info}->vendor(), 'linksys', q(Vendor returns 'linksys'));

  $test->{info}{_id} = '.1.3.6.1.4.1.2';
  is($test->{info}->vendor(), 'ibm', q(Vendor returns 'ibm'));

  $test->{info}->clear_cache();
  is($test->{info}->vendor(),
    'undef', q(No 'sysObjectID' returns 'undef' string));
}

sub os : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'dell', q(OS returns 'dell'));

  $test->{info}{_id} = '.1.3.6.1.4.1.3955.6.1.2024.1';
  is($test->{info}->os(), 'linksys', q(OS returns 'linksys'));

  $test->{info}{_id} = '.1.3.6.1.4.1.2';
  is($test->{info}->os(), 'ibm', q(OS returns 'ibm'));

  $test->{info}->clear_cache();
  is($test->{info}->os(), 'undef', q(No 'sysObjectID' returns 'undef' string));
}

sub os_ver : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');

  # The call to SUPER::serial() will use the entity_derived_serial method
  # which uses a partial fetch for e_serial which ignores the cache
  # and reloads data therefore we must use the mocked session.
  my $data
    = {'ENTITY-MIB::entPhysicalSoftwareRev' =>
      {1 => undef, 2 => '5.1.2.3', 3 => undef, 54 => '6.1.2.3', 55 => undef},
    };
  $test->{info}{sess}{Data} = $data;

  is($test->{info}->os_ver(),
    '5.1.2.3', q(OS version has expected value using 'ENTITY-MIB'));

  $test->{info}->clear_cache();

  # Manually populate cache entry
  $test->{info}{_dell_os_ver} = '1.0.0.45';
  is($test->{info}->os_ver(),
    '1.0.0.45',
    q(OS version has expected value using 'productIdentificationVersion'));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No data retruns undef));
}

sub fan : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'fan');
  is($test->{info}->fan(), 'fan2: warning', q(Returns fan not in normal state));

  # All fans normal returns a distinct string for this class
  $test->{info}{store}{dell_fan_state}
    = {67109249 => 'normal', 67109250 => 'normal'};
  is($test->{info}->fan(), '2 fans OK', q(All fans ok));

  $test->{info}->clear_cache();
  is($test->{info}->fan(), undef, q(No fan data returns undef));
}

sub ps1_type : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'ps1_type');
  is($test->{info}->ps1_type(), 'ac');

  $test->{info}->clear_cache();
  is($test->{info}->ps1_type(),
    undef, q(No power supply data returns type undef));
}

sub ps2_type : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'ps2_type');
  is($test->{info}->ps2_type(), 'unknown');

  $test->{info}->clear_cache();
  is($test->{info}->ps2_type(),
    undef, q(No power supply data returns type undef));
}

sub ps1_status : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'ps1_status');
  is($test->{info}->ps1_status(), 'normal');

  $test->{info}->clear_cache();
  is($test->{info}->ps1_status(),
    undef, q(No power supply data returns status undef));
}

sub ps2_status : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'ps2_status');
  is($test->{info}->ps2_status(), 'notPresent');

  $test->{info}->clear_cache();
  is($test->{info}->ps2_status(),
    undef, q(No power supply data returns status undef));
}

sub interfaces : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'interfaces');

  my $expected = {1 => 'g1', 2 => 'g2', 3 => 'Ethernet Interface'};

  cmp_deeply($test->{info}->interfaces(),
    $expected, q(Interfaces have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->interfaces(), {}, q(No data returns empty hash));
}

sub i_duplex : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex');

  my $expected = {1 => 'full', 2 => 'half'};

  cmp_deeply($test->{info}->i_duplex(),
    $expected, q(Interfaces have expected duplex values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_duplex(),
    {}, q(No duplex admin data returns empty hash));
}

sub i_duplex_admin : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex_admin');

  my $expected = {1 => 'full', 2 => 'half', 3 => 'auto'};

  cmp_deeply($test->{info}->i_duplex_admin(),
    $expected, q(Interfaces have expected duplex admin values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_duplex_admin(),
    {}, q(No duplex admin data returns empty hash));
}

sub qb_fdb_index : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'qb_fdb_index');
  is($test->{info}->qb_fdb_index(), undef);

}

1;
