# Test::SNMP::Info::Layer3::DLink
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

package Test::SNMP::Info::Layer3::DLink;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::DLink;

# Remove this startup override once we have full method coverage
sub startup : Tests(startup => 1) {
  my $test = shift;
  $test->SUPER::startup();

  $test->todo_methods(1);
}

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_layers' => 6,
    '_description' => 'DGS-3620-28SC Gigabit Ethernet Switch',
    '_i_name' => 1,

    # SWDGS3620PRIMGMT-MIB::dlink-Dgs3620Prod-Dgs3620-28SC
    '_id'   => '.1.3.6.1.4.1.171.10.118.2',
    'store' => {
        i_name => { 1 => 'One', 2 => 'Two' },
    },
  };
  $test->{info}->cache($cache_data);
}

sub layers : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'layers');
  is($test->{info}->layers(), '00000110', q(Original layers unmodified));

  # The DGS-F3008P answers no sysServices
  $test->{info}->clear_cache();
  is($test->{info}->layers(), '00000110',
    q(No sysServices defaults to layers 2 and 3));
}

my $dgs_f_descr = 'D-LINK DGS-F3008P-4S HW V1 Firmware V5.2.10.1-ged9dba8ff '
  . 'SerialNo H3008P0000001, L2 Ethernet PoE Switch';

sub device_type : Tests(3) {
  my $test = shift;

  # device_type runs on the base class, whose layers() has no D-Link default.
  # The DGS-F3008P reports a sysObjectID outside D-Link's enterprise.
  my $info = SNMP::Info->new(AutoSpecify => 0, Session => $test->mock_session);
  my %cases = (
    $dgs_f_descr => 'SNMP::Info::Layer3::DLink',
    'D-Link DGS-1100-08 Gigabit Smart Switch' => 'SNMP::Info::Layer3::DLink',
    'L2 Ethernet PoE Switch' => 'SNMP::Info',
  );
  foreach my $descr (sort keys %cases) {
    $info->clear_cache();
    $info->cache({
      '_description' => $descr,
      '_id'          => '.1.3.6.1.4.1.4294967295.3.2.16',
    });
    is($info->device_type(), $cases{$descr},
      "device_type__no_sysservices_${descr}__$cases{$descr}");
  }
}

sub interfaces : Tests(4) {
  my $test = shift;

  $test->{info}{'_i_index'}       = 1;
  $test->{info}{'_i_description'} = 1;
  $test->{info}{store}{i_index}   = {1 => 1, 2 => 2, 3 => 3};
  $test->{info}{store}{i_description} = {
    1 => 'D-Link Test Switch Port 1',
    2 => 'D-Link Test Switch Port 2',
    3 => 'Loopback1',
  };

  my $expected_data = {
    1 => 'One',
    2 => 'Two',
    3 => 'Loopback1',
  };

  cmp_deeply($test->{info}->interfaces(),
    $expected_data, 'Call to interfaces() prefers ifName, else ifDescr');

  $test->{info}{store}{i_name} = {1 => 'One', 2 => '', 3 => '  '};
  $expected_data = {
    1 => 'One',
    2 => 'D-Link Test Switch Port 2',
    3 => 'Loopback1',
  };

  cmp_deeply($test->{info}->interfaces(),
    $expected_data, 'Blank ifName falls back to ifDescr');

  delete $test->{info}{'_i_name'};
  delete $test->{info}{store}{i_name};
  $expected_data = {
    1 => 'D-Link Test Switch Port 1',
    2 => 'D-Link Test Switch Port 2',
    3 => 'Loopback1',
  };

  cmp_deeply($test->{info}->interfaces(),
    $expected_data, 'No ifName returns ifDescr for every port');

  $test->{info}->clear_cache();
  is($test->{info}->interfaces(), undef, 'No data returns undef interfaces');
}

sub _dgs_f_cache {
  my $test = shift;

  $test->{info}->clear_cache();
  $test->{info}->cache({
    '_description' => $dgs_f_descr,
    '_id'          => '.1.3.6.1.4.1.4294967295.3.2.16',
  });
}

sub model : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'DGS-3620-28SC Gigabit Ethernet Switch',
    q(Other models keep the existing source));

  $test->_dgs_f_cache();
  is($test->{info}->model(), 'DGS-F3008P-4S', q(DGS-F model from sysDescr));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), undef, q(Other sysDescr has no os_ver));

  $test->_dgs_f_cache();
  is($test->{info}->os_ver(), '5.2.10.1-ged9dba8ff',
    q(DGS-F firmware from sysDescr));
}

sub serial : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'serial');

  $test->_dgs_f_cache();
  is($test->{info}->serial(), 'H3008P0000001', q(DGS-F serial from sysDescr));
}

1;
