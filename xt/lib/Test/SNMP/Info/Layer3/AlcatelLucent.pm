# Test::SNMP::Info::Layer3::AlcatelLucent
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

package Test::SNMP::Info::Layer3::AlcatelLucent;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::AlcatelLucent;

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
    '_layers' => 72,

    # This is made up as no snmpwalk of device
    '_description' => '5.1.6.165.R02 Service Release, January 11, 2006.',

    # ALCATEL-IND1-DEVICES::deviceOmniSwitch660248
    '_id'   => '.1.3.6.1.4.1.6486.800.1.1.2.1.3.1.5',
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'AOS', q(OS returns 'AOS'));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'alcatel-lucent', q(Vendor returns 'alcatel-lucent'));
}

sub model : Tests(6) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'model');
  is($info->model(), 'OmniSwitch660248', q(Model is expected value));

  # AOS 8 sysObjectIDs sit in the .6486.801 tree, which netdisco-mibs does
  # not define; a virtual chassis lists one chassis entity per member
  my $aos8_id  = '.1.3.6.1.4.1.6486.801.1.1.2.1.11.1.9';
  my $entities = {
    '_e_class' => 1,
    '_e_model' => 1,
    'store'    => {
      'e_class' => {
        210 => 'chassis', 209 => 'chassis', 275 => 'powerSupply'},
      'e_model' => {
        210 => 'OS6860E-P48', 209 => 'OS6860E-U28', 275 => 'YM-1151D'},
    },
  };

  $info->clear_cache();
  $info->cache({
    %$entities,
    '_id'          => $aos8_id,
    '_description' => 'Alcatel-Lucent Enterprise OS6360-P48X 8.10.105.R02 GA,'
      . ' December 03, 2024.',
  });
  is($info->model(), 'OS6360-P48X',
    q(AOS 8 model comes from sysDescr when it names one));

  # An AOS 6 device newer than the netdisco-mibs device list
  $info->clear_cache();
  $info->cache({
    '_id'          => '.1.3.6.1.4.1.6486.800.1.1.2.1.12.1.8',
    '_description' =>
      'Alcatel-Lucent OS6450-48 6.6.4.177.R01 GA, May 24, 2013.',
  });
  is($info->model(), 'OS6450-48',
    q(Untranslated AOS 6 model comes from sysDescr));

  $info->clear_cache();
  $info->cache({
    %$entities,
    '_id'          => $aos8_id,
    '_description' => '8.5.255.R02 GA, August 29, 2018.',
  });
  is($info->model(), 'OS6860E-U28',
    q(Without a model in sysDescr, the first chassis entity is used));

  $info->clear_cache();
  $info->cache({'_id' => $aos8_id});
  is($info->model(), 'alcatel.801.1.1.2.1.11.1.9',
    q(With neither source, the untranslated ID is returned));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '5.1.6.165.R02', q(OS version is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef,
    q(No description returns undef OS version));
}

# Primes the standard and vendor copies of one POWER-ETHERNET-MIB column.
# The standard pethPsePortTable decides the source for every peth method.
sub _prime_peth {
  my ($test, $method, $std_rows, $alu_rows, $std_status) = @_;

  my $info = $test->{info};
  $info->clear_cache();
  $info->{'_std_peth_port_status'}     = 1;
  $info->{store}{std_peth_port_status} = $std_status;
  $info->{"_std_$method"}              = 1;
  $info->{store}{"std_$method"}        = $std_rows;
  $info->{"_alu_$method"}              = 1;
  $info->{store}{"alu_$method"}        = $alu_rows;
  return;
}

sub _peth_source_tests {
  my ($test, $method, $std_rows, $alu_rows) = @_;

  can_ok($test->{info}, $method);

  my $std_status = {'1.1' => 'deliveringPower'};
  $test->_prime_peth($method, $std_rows, $alu_rows, $std_status);
  cmp_deeply($test->{info}->$method(), $std_rows,
    qq($method uses standard POWER-ETHERNET-MIB when it has rows));

  $test->_prime_peth($method, {}, $alu_rows, {});
  cmp_deeply($test->{info}->$method(), $alu_rows,
    qq($method falls back to ALU-POWER-ETHERNET-MIB));

  # Never mix: a populated standard port table selects the standard copy
  # even when this particular standard column is empty.
  return if $method eq 'peth_port_status';
  $test->_prime_peth($method, {}, $alu_rows, $std_status);
  cmp_deeply($test->{info}->$method(), {},
    qq($method does not mix vendor rows into standard data));
  return;
}

sub peth_port_admin : Tests(4) {
  my $test = shift;
  $test->_peth_source_tests('peth_port_admin',
    {'1.1' => 'true', '1.2' => 'false'}, {'1.7' => 'true'});
}

sub peth_port_status : Tests(4) {
  my $test = shift;
  $test->_peth_source_tests('peth_port_status',
    {'1.1' => 'deliveringPower', '1.2' => 'searching'},
    {'1.7' => 'searching'});

  $test->_prime_peth('peth_port_status', {}, {}, {});
  cmp_deeply($test->{info}->peth_port_status(), {},
    q(No data returns empty hash));
}

sub peth_port_class : Tests(4) {
  my $test = shift;
  $test->_peth_source_tests('peth_port_class',
    {'1.1' => 'class3'}, {'1.7' => 'class0'});
}

sub peth_power_watts : Tests(4) {
  my $test = shift;
  $test->_peth_source_tests('peth_power_watts', {1 => 770}, {1 => 240});
}

sub peth_power_status : Tests(4) {
  my $test = shift;
  $test->_peth_source_tests('peth_power_status', {1 => 'on'}, {1 => 'off'});
}

sub peth_power_consumption : Tests(4) {
  my $test = shift;
  $test->_peth_source_tests('peth_power_consumption', {1 => 52}, {1 => 7});
}

sub peth_power_threshold : Tests(4) {
  my $test = shift;
  $test->_peth_source_tests('peth_power_threshold', {1 => 99}, {1 => 80});
}

sub peth_port_ifindex : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'peth_port_ifindex');

  $test->_prime_peth('peth_port_status',
    {'1.1' => 'deliveringPower', '2.10' => 'searching'},
    {'1.7' => 'searching'}, {});
  cmp_deeply($test->{info}->peth_port_ifindex(),
    {'1.1' => 1001, '2.10' => 2010},
    q(Standard PoE ports map to OmniSwitch ifIndex values));

  $test->_prime_peth('peth_port_status', {}, {'1.7' => 'searching'}, {});
  cmp_deeply($test->{info}->peth_port_ifindex(),
    {'1.7' => 1007}, q(Vendor PoE ports map to OmniSwitch ifIndex values));
}

sub alu8_vpa_type : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'alu8_vpa_type');

  $info->{'_alu8_vpa_type'}     = 1;
  $info->{store}{alu8_vpa_type} = {'12.1001' => 1, '5.1001' => 2};
  cmp_deeply($info->alu8_vpa_type(), {'12.1001' => 1, '5.1001' => 2},
    q(Cached AOS 8 vpaType rows are returned));

  $info->clear_cache();
  is($info->alu8_vpa_type(), undef, q(No data returns undef));

  # The column has no MIB node, so the walk relies on the generic handling
  # of an untranslated tag (#639)
  my $walked = $test->_fresh_vpa_info();
  cmp_deeply($walked->alu8_vpa_type(), {'5.1001' => 1, '12.1001' => 2},
    q(AOS 8 vpaType rows are walked by numeric OID));
}

sub _fresh_vpa_info {
  my $test = shift;
  # teardown clears the shared session's ErrorStr, which new() rejects
  $test->teardown;
  $test->setup;
  $test->mock_session->{Data} = {
    '.1.3.6.1.4.1.6486.801.1.2.1.3.1.1.2.1.1.3' =>
      {'5.1001' => 1, '12.1001' => 2},
  };
  return $test->{info};
}

sub i_vlan : Tests(6) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'i_vlan');

  $info->{'_bp_index'}         = 1;
  $info->{store}{bp_index}     = {1 => 1001, 2 => 1002};
  $info->{'_i_index'}          = 1;
  $info->{store}{i_index}      = {1001 => 1001, 1002 => 1002};
  $info->{'_qb_i_vlan'}        = 1;
  $info->{store}{qb_i_vlan}    = {1 => 10, 2 => 20};
  $info->{'_alu_vpa_type'}     = 1;
  $info->{store}{alu_vpa_type} = {'30.1001' => 'cfgDefault'};
  cmp_deeply($info->i_vlan(), {1001 => 10, 1002 => 20},
    q(PVID from Q-BRIDGE-MIB is used when present));

  $info->{store}{qb_i_vlan}    = {};
  $info->{store}{alu_vpa_type} = {
    '30.1001' => 'cfgDefault',
    '40.1001' => 'qTagged',
    '50.1002' => 'cfgDefault',
  };
  $info->{'_alu8_vpa_type'}     = 1;
  $info->{store}{alu8_vpa_type} = {'60.1003' => 1};
  cmp_deeply($info->i_vlan(), {1001 => 30, 1002 => 50},
    q(AOS 6 cfgDefault VPA rows give the native VLAN));

  $info->{store}{alu_vpa_type}  = {};
  $info->{store}{alu8_vpa_type} = {
    '12.1001' => 1,
    '5.1001'  => 2,
    '3.1013'  => 1,
    '1.1020'  => 1,
    '7.1020'  => 1,
  };
  cmp_deeply($info->i_vlan(), {1001 => 12, 1013 => 3},
    q(AOS 8 cfgDefault VPA rows give the native VLAN, skipping ambiguous));

  cmp_deeply($info->i_vlan(1013), {1013 => 3},
    q(Partial fetch returns only the requested ifIndex));

  $info->clear_cache();
  cmp_deeply($info->i_vlan(), {}, q(No data returns empty hash));
}

sub v_name : Tests(6) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'v_name');

  # Shaped from an AOS 8 walk: vlanTable is indexed by VLAN number, and a
  # virtual chassis lists its internal VLAN 4094 there too
  my $aos8_names = {
    1    => 'VLAN 1',
    10   => 'TOIP',
    17   => 'AFFICHEUR',
    4094 => 'VCM IPC',
  };
  $info->{'_alu8_vlan_descr'}     = 1;
  $info->{store}{alu8_vlan_descr} = $aos8_names;
  $info->{'_qb_v_name'}           = 1;
  $info->{store}{qb_v_name}       = {1 => 'VLAN 1', 10 => 'VLAN 10'};
  $info->{'_alu_vlan_descr'}      = 1;
  $info->{store}{alu_vlan_descr}  = {1 => 'vlan 1', 12 => 'vlan 12'};
  cmp_deeply($info->v_name(), $aos8_names,
    q(AOS 8 vlanDescription names are used when present));

  cmp_deeply($info->v_index(),
    {1 => 1, 10 => 10, 17 => 17, 4094 => 4094},
    q(v_index maps each AOS 8 VLAN number to itself));

  $info->{store}{alu8_vlan_descr} = {};
  cmp_deeply($info->v_name(), {1 => 'VLAN 1', 10 => 'VLAN 10'},
    q(Q-BRIDGE-MIB names are used when AOS 8 vlanTable is empty));

  $info->{store}{qb_v_name} = {};
  cmp_deeply($info->v_name(), {1 => 'vlan 1', 12 => 'vlan 12'},
    q(AOS 6 vlanDescription names are used when Q-BRIDGE-MIB is empty));

  $info->clear_cache();
  is($info->v_name(), undef, q(No data returns undef));
}

# Primes the power supply entities and both copies of chasEntPhysOperStatus
sub _prime_ps {
  my ($test, $aos6_rows, $aos8_rows) = @_;

  my $info = $test->{info};
  $info->clear_cache();
  $info->{'_e_class'}                    = 1;
  $info->{store}{e_class}                = {
    209 => 'chassis', 275 => 'powerSupply', 282 => 'powerSupply'};
  $info->{'_alu_chas_oper_status'}       = 1;
  $info->{store}{alu_chas_oper_status}   = $aos6_rows;
  $info->{'_alu8_chas_oper_status'}      = 1;
  $info->{store}{alu8_chas_oper_status}  = $aos8_rows;
  return $info;
}

sub ps1_status : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'ps1_status');

  my $info = $test->_prime_ps({275 => 'up', 282 => 'down'}, {275 => 2});
  is($info->ps1_status(), 'up',
    q(AOS 6 chasEntPhysOperStatus is used when present));

  # AOS 8 values are numbers: no loaded MIB defines the column
  $info = $test->_prime_ps({}, {275 => 1, 282 => 7});
  is($info->ps1_status(), 'up', q(AOS 8 status is mapped to its label));

  $info = $test->_prime_ps({}, {});
  is($info->ps1_status(), undef, q(No status returns undef));
}

sub ps2_status : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'ps2_status');

  my $info = $test->_prime_ps({}, {275 => 1, 282 => 7});
  is($info->ps2_status(), 'unpowered',
    q(AOS 8 status of the second supply is mapped to its label));

  $info = $test->_prime_ps({}, {275 => 1, 282 => 99});
  is($info->ps2_status(), 99, q(An AOS 8 status with no label is kept));
}

sub munge_alu8_chas_oper_status : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'munge_alu8_chas_oper_status');
  is(SNMP::Info::Layer3::AlcatelLucent::munge_alu8_chas_oper_status(7),
    'unpowered', q(Known AOS 8 status number returns its label));
  is(SNMP::Info::Layer3::AlcatelLucent::munge_alu8_chas_oper_status('up'),
    'up', q(A label is returned unchanged));
  is(SNMP::Info::Layer3::AlcatelLucent::munge_alu8_chas_oper_status(undef),
    undef, q(Undef returns undef));
}

1;
