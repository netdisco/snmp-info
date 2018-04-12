# Test::SNMP::Info::Layer2::Nexans
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

package Test::SNMP::Info::Layer2::Nexans;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer2::Nexans;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_layers'      => 2,
    '_description' => 'GigaSwitch 641 Desk SFP-I ES3 (HW3/ENHANCED/SECURITY/V4.14W)',

    # NEXANS-MIB::gigaSwitch641DeskSfpTp
    '_id'                   => '.1.3.6.1.4.1.266.1.3.70',
    '_infoMgmtFirmwareVersion' => 'HW3/ENHANCED/SECURITY/V4.14W',
    '_infoSeriesNo'         => '12345ABC',
    '_nexans_i_name'        => 1,
    'store'                 => {
      'nexans_i_name' => {
        '2' => 'testing',
        '3' => '',
        '5' => 'myUplink'
      },
    },
  };
  $test->{info}->cache($cache_data);
}

sub munge_i_duplex : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'munge_i_duplex');
  is(SNMP::Info::Layer2::Nexans::munge_i_duplex('up100Fdx'), 'full', q(Full duplex munges));
  is(SNMP::Info::Layer2::Nexans::munge_i_duplex('up100Hdx'), 'half', q(Half duplex munges));
  is(SNMP::Info::Layer2::Nexans::munge_i_duplex(), undef, q(Null returns undef));
  is(SNMP::Info::Layer2::Nexans::munge_i_duplex('down'), 'down', q(Down returns unmunged));
}

sub munge_i_duplex_admin : Tests(6) {
  my $test = shift;

  can_ok($test->{info}, 'munge_i_duplex_admin');
  is(SNMP::Info::Layer2::Nexans::munge_i_duplex_admin('fix100Fdx'), 'full', q(Full duplex munges));
  is(SNMP::Info::Layer2::Nexans::munge_i_duplex_admin('fix10Hdx'), 'half', q(Half duplex munges));
  is(SNMP::Info::Layer2::Nexans::munge_i_duplex_admin('autoneg'), 'auto', q(Half duplex munges));
  is(SNMP::Info::Layer2::Nexans::munge_i_duplex_admin(), undef, q(Null returns undef));
  is(SNMP::Info::Layer2::Nexans::munge_i_duplex_admin('unk'), 'unk', q(Unknown returns unmunged));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'nexans', q(Vendor returns 'nexans'));
}

sub model : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'gigaSwitch641DeskSfpTp', q(Model returns expected value));

  $test->{info}->clear_cache();
  is($test->{info}->model(), '', q(No id returns empty string));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'nexanos', q(Vendor returns 'nexanos'));
}

sub os_ver : Test(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), 'HW3/ENHANCED/SECURITY/V4.14W', q(OS Version has expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), '', q(No data returns empty string));
}

sub serial : Test(3) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), '12345ABC', q(Serial has expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), '', q(No data returns undef));
}

sub i_name : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_name');

  my $expected
    = {2 => 'testing', 3 => '3', 5 => 'myUplink'};

  cmp_deeply($test->{info}->i_name(),
    $expected, q(Interface names have expected values));
}

1;
