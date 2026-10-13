# Test::SNMP::Info::Layer3::IBMGbTor
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

package Test::SNMP::Info::Layer3::IBMGbTor;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::IBMGbTor;

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
    '_description' => 'IBM Networking Operating System RackSwitch G8264',

    # IBM-GbTOR-G8264-MIB::g8264
    '_id'   => '.1.3.6.1.4.1.26543.1.7.6',
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

sub prime_std_lldp {
  my $test = shift;
  my $info = $test->{info};

  $info->{"_$_"} = 1 for qw(
    lldp_sys_cap lldp_rem_id lldp_rem_id_type lldp_rem_pid lldp_rem_pid_type
    lldp_rem_desc lldp_rem_sysname lldp_rem_sysdesc lldp_rman_addr
    bp_index i_description i_alias
  );
  $info->{store}{lldp_sys_cap}     = pack('H*', '2800');
  $info->{store}{lldp_rem_id}      = {'0.51.2' => pack('H*', '020000aa0001')};
  $info->{store}{lldp_rem_id_type} = {'0.51.2' => 'macAddress'};
  $info->{store}{lldp_rem_pid}     = {'0.51.2' => 'xe-0/0/1'};
  $info->{store}{lldp_rem_pid_type} = {'0.51.2' => 'interfaceName'};
  $info->{store}{lldp_rem_desc}    = {'0.51.2' => 'uplink port'};
  $info->{store}{lldp_rem_sysname} = {'0.51.2' => 'core-sw1'};
  $info->{store}{lldp_rem_sysdesc} = {'0.51.2' => 'Example Core Switch'};
  $info->{store}{lldp_rman_addr}
    = {'0.51.2.1.4.192.0.2.10' => 'ifIndex'};
  $info->{store}{bp_index}      = {51 => 179, 52 => 180};
  $info->{store}{i_description} = {179 => 'Ethernet51', 180 => 'Ethernet52'};
  $info->{store}{i_alias}       = {179 => '', 180 => ''};

  # lldp_if reads lldpLocPortDesc as a partial, which bypasses the cache.
  $info->{sess}{Data} = {'LLDP-MIB::lldpLocPortDesc' => {51 => 'XGE3'}};
  return;
}

sub prime_ibm_lldp {
  my $test = shift;
  my $info = $test->{info};

  $info->{"_$_"} = 1 for qw(
    lldp_rem_id lldp_port_status ibm_lldp_rem_id ibm_lldp_rem_id_type
    ibm_lldp_rem_sysname lldpInfoRemoteDevicesLocalPort
    lldpInfoRemoteDevicesSystemDescription lldp_rman_type
    ibm_lldp_rman_addr i_description i_alias
  );
  $info->{store}{lldp_rem_id}      = {};
  $info->{store}{lldp_port_status} = {1 => 'enabledRxTx', 2 => 'disabled'};
  $info->{store}{ibm_lldp_rem_id}      = {1 => 'access-sw2'};
  $info->{store}{ibm_lldp_rem_id_type} = {1 => 'local'};
  $info->{store}{ibm_lldp_rem_sysname} = {1 => 'access-sw2'};
  $info->{store}{lldpInfoRemoteDevicesLocalPort} = {1 => 'XGE1'};
  $info->{store}{lldpInfoRemoteDevicesSystemDescription}
    = {1 => 'Example Access Switch'};
  $info->{store}{lldp_rman_type}     = {'1.1' => 'ipV4'};
  $info->{store}{ibm_lldp_rman_addr} = {'1.1' => '192.0.2.20'};
  $info->{store}{i_description}      = {17 => 'XGE1'};
  $info->{store}{i_alias}            = {17 => ''};
  return;
}

sub _ibm_lldp_standard : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  $test->prime_std_lldp;
  ok($info->_ibm_lldp_standard(),
    q(LLDP-MIB neighbor rows select the standard table));

  $info->clear_cache();
  $test->prime_ibm_lldp;
  ok(!$info->_ibm_lldp_standard(),
    q(No LLDP-MIB neighbor rows select the IBM table));

  $info->clear_cache();
  $test->prime_std_lldp;
  ok($info->_ibm_lldp_standard(),
    q(clear_cache resets the decision));
}

sub hasLLDP : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'hasLLDP');
  $test->prime_std_lldp;
  ok($info->hasLLDP(), q(Standard LLDP-MIB local data reports LLDP));

  $info->clear_cache();
  $test->prime_ibm_lldp;
  ok($info->hasLLDP(), q(IBM port table with Rx enabled reports LLDP));

  $info->clear_cache();
  $info->{"_$_"} = 1 for qw(lldp_rem_id lldp_port_status);
  $info->{store}{lldp_rem_id}      = {};
  $info->{store}{lldp_port_status} = {1 => 'disabled'};
  ok(!$info->hasLLDP(), q(No LLDP data reports no LLDP));
}

sub lldp_if : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'lldp_if');
  $test->prime_std_lldp;
  is_deeply($info->lldp_if(), {'0.51.2' => 179},
    q(LLDP-MIB local port maps through the bridge port to ifIndex));

  delete $info->{store}{bp_index}{51};
  is_deeply($info->lldp_if(), {'0.51.2' => 51},
    q(A port absent from bp_index keeps the inherited mapping));

  $info->clear_cache();
  $test->prime_ibm_lldp;
  is_deeply($info->lldp_if(), {1 => 17},
    q(IBM table local port maps through ifDescr when LLDP-MIB is empty));
}

sub lldp_id : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'lldp_id');
  $test->prime_std_lldp;
  is_deeply($info->lldp_id(), {'0.51.2' => '02:00:00:aa:00:01'},
    q(LLDP-MIB chassis id is returned when present));

  $info->clear_cache();
  $test->prime_ibm_lldp;
  is_deeply($info->lldp_id(), {1 => 'access-sw2'},
    q(IBM table remote id is returned when LLDP-MIB is empty));
}

sub lldp_rem_sysname : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'lldp_rem_sysname');
  $test->prime_std_lldp;
  is_deeply($info->lldp_rem_sysname(), {'0.51.2' => 'core-sw1'},
    q(LLDP-MIB system name is returned when present));

  $info->clear_cache();
  $test->prime_ibm_lldp;
  is_deeply($info->lldp_rem_sysname(), {1 => 'access-sw2'},
    q(IBM table system name is returned when LLDP-MIB is empty));
}

sub lldp_platform : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'lldp_platform');
  $test->prime_std_lldp;
  is_deeply($info->lldp_platform(), {'0.51.2' => 'Example Core Switch'},
    q(LLDP-MIB system description is returned when present));

  $info->clear_cache();
  $test->prime_ibm_lldp;
  is_deeply($info->lldp_platform(), {1 => 'Example Access Switch'},
    q(IBM table system description is returned when LLDP-MIB is empty));
}

sub lldp_ip : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'lldp_ip');
  $test->prime_std_lldp;
  is_deeply($info->lldp_ip(), {'0.51.2' => '192.0.2.10'},
    q(LLDP-MIB management address is returned when present));

  $info->clear_cache();
  $test->prime_ibm_lldp;
  is_deeply($info->lldp_ip(), {1 => '192.0.2.20'},
    q(IBM table management address is returned when LLDP-MIB is empty));
}

1;
