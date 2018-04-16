# Test::SNMP::Info::Entity
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

package Test::SNMP::Info::Entity;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Entity;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_entPhysicalDescr' => 1,
    '_e_map'            => 1,
    '_e_parent'         => 1,
    '_e_class'          => 1,
    'store'             => {
      'entPhysicalDescr' => {1 => 1, 2 => 2, 3 => 3, 54 => 54, 55 => 55},
      'e_map'            => {
        '1019.0' => 'ifIndex.1',
        '1031.0' => 'ifIndex.2',
        '2019.0' => 'ifIndex.3',
        '2031.0' => 'ifIndex.4'
      },
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

sub e_index : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'e_index');

  my $expected = {1 => 1, 2 => 2, 3 => 3, 54 => 54, 55 => 55};

  cmp_deeply($test->{info}->e_index(),
    $expected, q(Entity Physical Index using 'entPhysicalDescr'));

  $test->{info}->clear_cache();
  is($test->{info}->e_index(), undef, q(No data returns undef));
}

sub e_port : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'e_port');

  my $expected = {1019 => 1, 1031 => 2, 2019 => 3, 2031 => 4};

  cmp_deeply($test->{info}->e_port(),
    $expected, q(Entity cross reference to 'ifIndex'));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->e_port(), {}, q(No data returns empty hash));
}

sub entity_derived_serial : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'entity_derived_serial');

  # The call to SUPER::serial() will use the entity_derived_serial method
  # which uses a partial fetch for e_serial which ignores the cache
  # and reloads data therefore we must use the mocked session.
  my $data = {
    'ENTITY-MIB::entPhysicalSerialNum' => {
      1  => undef,
      2  => 'AB01CDE2345678901234F00',
      3  => undef,
      54 => 'AB01CDE2345678901234F01',
      55 => undef
    },
  };
  $test->{info}{sess}{Data} = $data;

  is($test->{info}->entity_derived_serial(),
    'AB01CDE2345678901234F00',
    q(Serial has expected value using 'entPhysicalSerialNum'));

  # Clear previous mock session data from cache and data
  delete $test->{info}{_e_serial};
  delete $test->{info}{store}{e_serial};
  $test->{info}{sess}{Data} = {};

  # New mock data for partial call
  $data = {
    'ENTITY-MIB::entPhysicalDescr' => {
      1  => undef,
      2  => 'AS5350 chassis, Hw Serial#: 12345, Hw Revision: T',
      3  => undef,
      54 => 'AS5350 Cpu Card,  Hw Serial#: 23456, Hw Revision: T',
      55 => undef
    },
  };
  $test->{info}{sess}{Data} = $data;
  is($test->{info}->entity_derived_serial(),
    '12345', q(Serial has expected value using 'entPhysicalDescr'));

  $test->{info}->clear_cache();
  is($test->{info}->entity_derived_serial(),
    undef, q(No data returns undef serial));
}

sub entity_derived_os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'entity_derived_os_ver');

  # The call to SUPER::serial() will use the entity_derived_serial method
  # which uses a partial fetch for e_serial which ignores the cache
  # and reloads data therefore we must use the mocked session.
  my $data
    = {'ENTITY-MIB::entPhysicalSoftwareRev' =>
      {1 => undef, 2 => '5.1.2.3', 3 => undef, 54 => '6.1.2.3', 55 => undef},
    };
  $test->{info}{sess}{Data} = $data;

  is($test->{info}->entity_derived_os_ver(),
    '5.1.2.3', q(OS version has expected value using 'entPhysicalSoftwareRev'));

  $test->{info}->clear_cache();
  is($test->{info}->entity_derived_os_ver(), undef, q(No data returns undef));
}

1;
