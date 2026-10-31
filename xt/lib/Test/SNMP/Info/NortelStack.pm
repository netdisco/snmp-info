# Test::SNMP::Info::NortelStack
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

package Test::SNMP::Info::NortelStack;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::NortelStack;

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
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

# s5ChasStoreTable rows for one unit, keyed by storage area index; types
# are S5-REG-MIB storage area OIDs under board $board
sub _cache_store {
  my ($test, $board, $versions) = @_;

  my $base = ".1.3.6.1.4.1.45.1.6.1.3.6.$board.0";
  $test->{info}->clear_cache();
  $test->{info}->cache({
    '_ns_store_type'         => 1,
    '_ns_store_ver'          => 1,
    '_s5ChasGrpEncodeFactor' => 1,
    '_s5ChasComRelPos'       => 1,
    'store'                  => {
      'ns_store_type' => {map { ("8.1.0.$_" => "$base.$_") } keys %$versions},
      'ns_store_ver'  => {map { ("8.1.0.$_" => $versions->{$_}) } keys %$versions},
      's5ChasGrpEncodeFactor' => {},
      's5ChasComRelPos'       => {},
    },
  });
}

# ERS 4950GTS-PWR+ (board 830): 1 Flash, 2 BootFW, 3 Dram, 4 PoLFlash,
# 5 SecondaryFlash, 7 InstalledFW, 8 OperSW, 10 BootLoader
sub ns_e_swver : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'ns_e_swver');

  $test->_cache_store(830, {1 => '7.3.0.241......', 3 => '',
    4 => '1.5.0.10', 5 => '7.2.0.213', 8 => '7.3.0.241'});
  cmp_deeply($test->{info}->ns_e_swver(), {'8.1.0' => '7.3.0.241'},
    'ns_e_swver__operational_software_and_flash__returns_operational');

  $test->_cache_store(830, {1 => '7.3.0.241', 3 => '', 4 => '1.5.0.10',
    5 => '7.2.0.213'});
  cmp_deeply($test->{info}->ns_e_swver(), {'8.1.0' => '7.3.0.241'},
    'ns_e_swver__no_operational_software__returns_primary_flash');

  $test->_cache_store(830, {4 => '1.5.0.10'});
  cmp_deeply($test->{info}->ns_e_swver(), {},
    'ns_e_swver__only_pol_flash__returns_nothing');

  # BayStack 250 NMM (board 598): 1 Flash, 2 Dram, 3 Boot
  $test->_cache_store(598, {1 => 'v3.2.1', 2 => 'v3.2.1', 3 => 'v1.0.4'});
  cmp_deeply($test->{info}->ns_e_swver(), {'8.1.0' => 'v3.2.1'},
    'ns_e_swver__hub_flash__returned');
}

sub ns_e_fwver : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'ns_e_fwver');

  $test->_cache_store(830, {1 => '7.3.0.241', 2 => '7.2.0.5',
    7 => '7.2.0.6', 10 => '7.2.0.4'});
  cmp_deeply($test->{info}->ns_e_fwver(), {'8.1.0' => '7.2.0.5'},
    'ns_e_fwver__boot_installed_and_loader__returns_boot_firmware');

  $test->_cache_store(830, {7 => '7.2.0.6', 10 => '7.2.0.4'});
  cmp_deeply($test->{info}->ns_e_fwver(), {'8.1.0' => '7.2.0.6'},
    'ns_e_fwver__no_boot_firmware__returns_installed_firmware');

  $test->_cache_store(598, {1 => 'v3.2.1', 3 => 'v1.0.4'});
  cmp_deeply($test->{info}->ns_e_fwver(), {'8.1.0' => 'v1.0.4'},
    'ns_e_fwver__hub_boot__returned');
}

1;
