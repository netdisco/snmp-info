# Test::SNMP::Info::RapidCityLegacy
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

package Test::SNMP::Info::RapidCityLegacy;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::RapidCity;
use SNMP::Info::RapidCityLegacy;

# The legacy mixin reads the core's leaves, so it is exercised the way
# Layer3::Passport and Layer2::Baystack combine them
{
  package Test::SNMP::Info::RapidCityLegacy::WithCore;

  our (@ISA, %MIBS, %GLOBALS, %FUNCS, %MUNGE);
  @ISA = qw/SNMP::Info::RapidCityLegacy SNMP::Info::RapidCity Exporter/;

  %MIBS    = (%SNMP::Info::RapidCity::MIBS, %SNMP::Info::RapidCityLegacy::MIBS);
  %GLOBALS = (%SNMP::Info::RapidCity::GLOBALS,
    %SNMP::Info::RapidCityLegacy::GLOBALS);
  %FUNCS = (%SNMP::Info::RapidCity::FUNCS, %SNMP::Info::RapidCityLegacy::FUNCS);
  %MUNGE = (%SNMP::Info::RapidCity::MUNGE, %SNMP::Info::RapidCityLegacy::MUNGE);
}

sub setup : Tests(setup) {
  my $test = shift;

  my $class = $test->class;
  $test->class('Test::SNMP::Info::RapidCityLegacy::WithCore');
  $test->SUPER::setup;
  $test->class($class);

  $test->{info}->cache({'store' => {}});
}

sub i_duplex : Tests(1) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex');
}

sub i_duplex__cpu_port_rows__merged : Tests(1) {
  my $test = shift;

  $test->{info}->cache({
    _rc_duplex => 1, _rc_cpu_duplex => 1,
    store => {rc_duplex => {65 => 'full'}, rc_cpu_duplex => {1 => 'half'}},
  });
  cmp_deeply($test->{info}->i_duplex(), {65 => 'full', 1 => 'half'},
    'CPU Ethernet rows are added to the port rows');
}

sub i_duplex_admin : Tests(1) {
  my $test = shift;

  can_ok($test->{info}, 'i_duplex_admin');
}

sub i_duplex_admin__cpu_auto__auto : Tests(1) {
  my $test = shift;

  $test->{info}->cache({
    _rc_cpu_duplex_admin => 1, _rc_cpu_auto => 1,
    store => {
      rc_cpu_duplex_admin => {1 => 'full'}, rc_cpu_auto => {1 => 'true'},
    },
  });
  cmp_deeply($test->{info}->i_duplex_admin(), {1 => 'auto'},
    'An auto-negotiating CPU Ethernet port reports auto');
}

sub _lag_vendor_domains__ist_and_vist_served__reports_both : Tests(2) {
  my $test = shift;

  $test->{info}->cache({
    _rc_ist_status  => 'up', _rc_ist_peer  => '10.1.1.2',
    _rc_ist_vlan    => 100,
    _rc_vist_status => 'up', _rc_vist_peer => '10.255.0.2',
    _rc_vist_vlan   => 4000,
  });
  my $domains = $test->{info}->_lag_vendor_domains();
  cmp_deeply([sort keys %$domains], [qw/ist vist/], 'Both domains served');
  is($domains->{vist}{peer}, '10.255.0.2', 'vIST peer read');
}

sub rc_spbm_fw_mac : Tests(1) {
  my $test = shift;

  can_ok($test->{info}, 'rc_spbm_fw_mac');
}

sub rc_spbm_fw_mac__isid_mac_index__splits : Tests(1) {
  my $test = shift;

  $test->{info}->cache({
    _rc_spbm_fw_port => 1,
    store => {rc_spbm_fw_port => {'20010.0.1.2.3.4.5' => 3}},
  });
  cmp_deeply($test->{info}->rc_spbm_fw_mac(),
    {'20010.0.1.2.3.4.5' => '00:01:02:03:04:05'},
    'The MAC is the last six index components');
}

sub rc_spbm_fw_isid : Tests(1) {
  my $test = shift;

  can_ok($test->{info}, 'rc_spbm_fw_isid');
}

sub rc_spbm_fw_isid__isid_mac_index__splits : Tests(1) {
  my $test = shift;

  $test->{info}->cache({
    _rc_spbm_fw_port => 1,
    store => {rc_spbm_fw_port => {'20010.0.1.2.3.4.5' => 3}},
  });
  cmp_deeply($test->{info}->rc_spbm_fw_isid(), {'20010.0.1.2.3.4.5' => 20010},
    'The ISID is the first index component');
}

1;
