# SNMP::Info::Test
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

package SNMP::Info::Test;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info;

sub _constructor : Tests(11) {
  my $test  = shift;
  my $class = $test->class;
  my $sess  = $test->mock_session;

  can_ok $class, 'new';
  isa_ok $test->{info}, $class, '... and the object it returns';

  is(defined $test->{info}{init}, 1, 'mibs initialized');
  ok(
    scalar keys %{$test->{info}{mibs}},
    'mibs subclass data structure initialized'
  );
  ok(
    scalar keys %{$test->{info}{globals}},
    'globals subclass data structure initialized'
  );
  ok(
    scalar keys %{$test->{info}{funcs}},
    'funcs subclass data structure initialized'
  );
  ok(
    scalar keys %{$test->{info}{munge}},
    'munge subclass data structure initialized'
  );
  is_deeply($test->{info}{store}, {}, 'store initialized');

  is($test->{info}{snmp_comm}, 'public',  'snmp comm arg saved');
  is($test->{info}{snmp_ver},  2,         'snmp version arg saved');
  is($test->{info}{snmp_user}, 'initial', 'snmp user arg saved');
}

sub globals : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'globals');

  subtest 'Globals can() subtest' => sub {

    my $test_globals = $test->{info}->globals;
    foreach my $key (keys %$test_globals) {
      can_ok($test->{info}, $key);
    }
  };
}

sub funcs : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'funcs');

  subtest 'Funcs can() subtest' => sub {

    my $test_funcs = $test->{info}->funcs;
    foreach my $key (keys %$test_funcs) {
      can_ok($test->{info}, $key);
    }
  };
}

# update() needs to be reworked to discard all args except community
# or context as described in documentation

# TODO - Commented out as causing problems during CI build
sub update : Tests(4) {
  my $test = shift;

  # Starting community
  is($test->{info}{sess}{Community}, 'public', 'original community');

  # Change community
  my %update_args = ('Community' => 'new_community',);
  $test->{info}->update(%update_args);
  is($test->{info}{sess}{Community}, 'new_community', 'community changed');

  # Starting context
  is($test->{info}{sess}{Context}, '', 'original context');

  # Change context
  %update_args = ('Context' => 'new_context',);
  $test->{info}->update(%update_args);
  is($test->{info}->{sess}->{Context}, 'new_context', 'context changed');
}

sub cache_and_clear_cache : Tests(9) {
  my $test = shift;

  # Isolate tests to cache method. Populated structure of global 'name' and
  # func 'i_description'
  my $cache_data = {
    '_name'          => 'Test-Name',
    '_i_description' => 1,
    'store'          => {
      'i_description' =>
        {10 => 'Test-Description-10', 20 => 'Test-Description-20'}
    }
  };

  # The empty store hash exists upon initialization and remains when the cache
  # is cleared.
  my $empty_cache = {'store' => {}};

  can_ok($test->{info}, 'cache');
  cmp_deeply($empty_cache, $test->{info}->cache(), 'cache starts empty');
  ok($test->{info}->cache($cache_data), 'insert test data into cache');
  cmp_deeply(
    $cache_data,
    $test->{info}->cache(),
    'cache method returns test data'
  );
  is($test->{info}->name(),
    'Test-Name', 'global method call returned cached data');
  cmp_deeply(
    $test->{info}->i_description(),
    $cache_data->{store}{i_description},
    'funcs method call returned cached data'
  );
  can_ok($test->{info}, 'clear_cache');
  ok($test->{info}->clear_cache(), 'cache cleared');
  cmp_deeply(
    $empty_cache,
    $test->{info}->cache(),
    'no cached data returned after clear_cache method call'
  );
}

sub debug : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'debug');

  ok(
    defined $test->{info}{debug}
      && $test->{info}{debug} == 0
      && $test->{info}->debug() == 0,
    'debug initialized off'
  );
  $test->{info}->debug(1);
  ok($test->{info}{debug} && $test->{info}->debug(), 'debug on');
  $test->{info}->debug(0);
  ok($test->{info}{debug} == 0 && $test->{info}->debug() == 0, 'debug off');
}

sub offline : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'offline');

  ok(!defined $test->{info}{Offline}, 'offline not initialized');
  $test->{info}->offline(1);
  ok($test->{info}{Offline} && $test->{info}->offline(), 'offline mode on');
  $test->{info}->offline(0);
  ok($test->{info}{Offline} == 0 && $test->{info}->offline() == 0,
    'offline off');
}

sub bulkwalk : Tests(4) {
  my $test = shift;

  can_ok $test->{info}, 'bulkwalk';

  # Test harness initalizes BulkWalk off, if we didn't provide an arg
  # it would not be defined.
  ok(
    !defined $test->{info}{BulkWalk}
      || ($test->{info}{BulkWalk} == 0 && $test->{info}->bulkwalk() == 0),
    'bulkwalk initialized off'
  );
  $test->{info}->bulkwalk(1);
  ok($test->{info}{BulkWalk} && $test->{info}->bulkwalk(), 'bulkwalk on');
  $test->{info}->bulkwalk(0);
  ok($test->{info}{BulkWalk} == 0 && $test->{info}->bulkwalk() == 0,
    'bulkwalk off');
}

sub loopdetect : Tests(4) {
  my $test = shift;

  can_ok $test->{info}, 'loopdetect';

  ok(!defined $test->{info}{LoopDetect}, 'loopdetect not initialized');
  $test->{info}->loopdetect(1);
  ok($test->{info}{LoopDetect} && $test->{info}->loopdetect(), 'loopdetect on');
  $test->{info}->loopdetect(0);
  ok($test->{info}{LoopDetect} == 0 && $test->{info}->loopdetect() == 0,
    'loopdetect off');
}

sub device_type : Tests(8) {
  my $test = shift;

  can_ok($test->{info}, 'device_type');

  # Empty args and no SNMP data should result in undef
  is($test->{info}->device_type(),
    undef, 'No sysServices, no sysDescr results in undef');

  # Populate cache for tests rather than mocking session to limit code hit
  # on these tests
  my $cache_data
    = {'_layers' => '00000000', '_description' => 'My-Test-sysDescr',};
  $test->{info}->cache($cache_data);

  is($test->{info}->device_type(),
    'SNMP::Info', 'No sysServices and unknown sysDescr results in SNMP::Info');

  $test->{info}->debug(1);
  warnings_like { $test->{info}->device_type() }
  [{carped => qr/Might give unexpected results/i}],
    'No sysServices and unknown sysDescr with debug on gives warning';
  $test->{info}->debug(0);
  $test->{info}->clear_cache();

  # Test one oid per layer hash just to verify oid mapping, no need to test
  # every hash key - chose an id that is unique per layer

  # Layer 3
  $cache_data = {
    '_layers'      => 4,
    '_description' => 'My-Test-sysDescr',
    '_id'          => '.1.3.6.1.4.1.18'
  };
  $test->{info}->cache($cache_data);
  is($test->{info}->device_type,
    'SNMP::Info::Layer3::BayRS', 'Layer 3 device type by sysObjectID');
  $test->{info}->clear_cache();

  # Layer 2
  $cache_data = {
    '_layers'      => 2,
    '_description' => 'My-Test-sysDescr',
    '_id'          => '.1.3.6.1.4.1.11898'
  };
  $test->{info}->cache($cache_data);
  is($test->{info}->device_type,
    'SNMP::Info::Layer2::Orinoco', 'Layer 2 device type by sysObjectID');
  $test->{info}->clear_cache();

  # Layer 1
  $cache_data = {
    '_layers'      => 1,
    '_description' => 'My-Test-sysDescr',
    '_id'          => '.1.3.6.1.4.1.2925'
  };
  $test->{info}->cache($cache_data);
  is(
    $test->{info}->device_type,
    'SNMP::Info::Layer1::Cyclades',
    'Layer 1 device type by sysObjectID'
  );
  $test->{info}->clear_cache();

  # Layer 7
  $cache_data = {
    '_layers'      => 64,
    '_description' => 'My-Test-sysDescr',
    '_id'          => '.1.3.6.1.4.1.318'
  };
  $test->{info}->cache($cache_data);
  is($test->{info}->device_type,
    'SNMP::Info::Layer7::APC', 'Layer 1 device type by sysObjectID');
  $test->{info}->clear_cache();

  # Add Regex tests if needed
}

sub error : Tests(7) {
  my $test = shift;

  can_ok($test->{info}, 'error');
  ok(!exists $test->{info}{error}, 'Error not present');
  $test->{info}{error} = 'Test Error';
  is($test->{info}->error(), 'Test Error', 'Test Error present');
  is($test->{info}->error(), undef,        'Test Error cleared upon read');
  $test->{info}{error} = 'Test Error 2';
  is($test->{info}->error(1),
    'Test Error 2', 'Test Error 2 present and no clear flag set');
  is($test->{info}->error(0),
    'Test Error 2', 'Test Error 2 still present on next read');
  is($test->{info}->error(),
    undef, 'Test Error 2 cleared upon read with flag set to false');
}

sub has_layer : Tests(6) {
  my $test = shift;

  can_ok $test->{info}, 'has_layer';
  $test->{info}->clear_cache();

  # Populate cache, one key/value so don't bother going through the
  # cache() method.
  # Layers holds the unmunged value (decimal)
  $test->{info}{'_layers'} = 1;
  is($test->{info}->has_layer(1), 1, 'Has layer 1');

  $test->{info}{'_layers'} = 2;
  is($test->{info}->has_layer(2), 1, 'Has layer 2');

  $test->{info}{'_layers'} = 4;
  is($test->{info}->has_layer(3), 1, 'Has layer 3');

  # We don't use layers 4-6 for classification, skip testing

  $test->{info}{'_layers'} = 64;
  is($test->{info}->has_layer(7), 1, 'Has layer 7');

  # Check for undef layers
  $test->{info}{'_layers'} = undef;
  is($test->{info}->has_layer(7), undef, 'Undef layers returns undef');
}

sub snmp_comm : Tests(4) {
  my $test = shift;

  can_ok $test->{info}, 'snmp_comm';

  # Define before test to be sure instead of relying on initalization
  $test->{info}{snmp_comm} = 'publicv1';
  $test->{info}{snmp_ver}  = 1;
  is($test->{info}->snmp_comm(), 'publicv1',
    'Version 1 returns SNMP community');

  $test->{info}{snmp_comm} = 'publicv2';
  $test->{info}{snmp_ver}  = 2;
  is($test->{info}->snmp_comm(), 'publicv2',
    'Version 2 returns SNMP community');

  $test->{info}{snmp_user} = 'initialv3';
  $test->{info}{snmp_ver}  = 3;
  is($test->{info}->snmp_comm(), 'initialv3', 'Version 3 returns SNMP user');
}

sub snmp_ver : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'snmp_ver';

  # Define before test to be sure instead of relying on initalization
  $test->{info}{snmp_ver} = 1;
  is($test->{info}->snmp_ver(), 1, 'SNMP version returned');
}

sub specify : Tests(4) {
  my $test = shift;

  can_ok $test->{info}, 'specify';
  $test->{info}->cache_clear();

  # Specify uses device_type(), use same data as that test to setup
  # test cases here since return values from device_type() with them
  # have been tested

  # device_type returns undef
  $test->{info}->specify();
  is(
    $test->{info}->error(),
    'SNMP::Info::specify() - Could not get info from device',
    'Undef device type throws error'
  );
  $test->{info}->cache_clear();

  # Populate cache for following tests
  my $cache_data
    = {'_layers' => '00000000', '_description' => 'My-Test-sysDescr',};
  $test->{info}->cache($cache_data);

  isa_ok($test->{info}->specify(),
    'SNMP::Info', 'SNMP::Info device_type returns self');
  $test->{info}->cache_clear();

  # Layer 7 - SNMP::Info::Layer7::APC
  $cache_data = {
    '_layers'      => 64,
    '_description' => 'My-Test-sysDescr',
    '_id'          => '.1.3.6.1.4.1.318'
  };
  $test->{info}->cache($cache_data);
  isa_ok($test->{info}->specify(),
    'SNMP::Info::Layer7::APC',
    'Layer 7 device type returns new object of same type');
  $test->{info}->clear_cache();
}

sub cisco_comm_indexing : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'cisco_comm_indexing';
  is($test->{info}->cisco_comm_indexing(), 0, 'Cisco community indexing off');
}

sub if_ignore : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'if_ignore';
  is_deeply($test->{info}->if_ignore(),
    {}, 'No ignored interfaces for this class');
}

sub bulkwalk_no : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'bulkwalk_no';
  is($test->{info}->bulkwalk_no(), 0, 'Bulkwalk not turned off in this class');
}

sub i_speed : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'i_speed';

  # Method uses partial fetches which ignores the cache and reloads data
  # therefore we must use the mocked session. Populate the session data
  # so that the mock_getnext() has data to fetch.
  my $data = {

    # Need to use OID for ifSpeed since it could resolve to a fully qualified
    # name as either RFC1213-MIB::ifSpeed or IF-MIB::ifSpeed dependent upon
    # which MIB got loaded last which is based upon random hash ordering. Using
    # a fully qualified name with mock session we would need to know which MIB
    # "owned" the OID since the MIB hash is indexed by OID. This is not an
    # issue in live code since what is fed to getnext for a fully qualified
    # name is what is returned.
    '.1.3.6.1.2.1.2.2.1.5' => {38 => 0, 49 => 4294967295, 501 => 1000000000,},
    'IF-MIB::ifHighSpeed'  => {38 => 0, 49 => 32000,      501 => 1000,},
  };
  my $expected = {38 => 0, 49 => '32 Gbps', 501 => '1.0 Gbps',};
  $test->{info}{sess}{Data} = $data;
  is_deeply($test->{info}->i_speed(),
    $expected, 'High speed interface reported accurately');
}

sub i_speed_raw : Tests(3) {
  my $test = shift;

  can_ok $test->{info}, 'i_speed_raw';

  # Method uses partial fetches which ignores the cache and reloads data
  # therefore we must use the mocked session. Populate the session data
  # so that the mock_getnext() has data to fetch.
  my $data = {

    # Need to use OID for ifSpeed since it could resolve to a fully qualified
    # name as either RFC1213-MIB::ifSpeed or IF-MIB::ifSpeed dependent upon
    # which MIB got loaded last which is based upon random hash ordering. Using
    # a fully qualified name with mock session we would need to know which MIB
    # "owned" the OID since the MIB hash is indexed by OID. This is not an
    # issue in live code since what is fed to getnext for a fully qualified
    # name is what is returned.
    '.1.3.6.1.2.1.2.2.1.5' => {38 => 0, 49 => 4294967295, 501 => 1000000000,},
    'IF-MIB::ifHighSpeed'  => {38 => 0, 49 => 32000,      501 => 1000,},
  };
  my $expected     = {38 => 0, 49 => '32 Gbps',   501 => '1.0 Gbps',};
  my $expected_raw = {38 => 0, 49 => 32000000000, 501 => 1000000000,};
  $test->{info}{sess}{Data} = $data;
  is_deeply($test->{info}->i_speed_raw(),
    $expected_raw, 'Raw high speed interface reported accurately');

  # Note the cache is populated unmunged data now - not sure if that is
  # expected behavior. Clear cache to get data to test that munges are restored.
  $test->{info}->clear_cache();
  is_deeply($test->{info}->i_speed(),
    $expected, 'Munges restored after i_speed_raw() call');
}

# Topo routines will need to be tested in sub classes for conditionals
sub has_topo : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'has_topo');
  is($test->{info}->has_topo(), undef, 'Base class has no topo');
}

sub get_topo_data : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, '_get_topo_data');
  is($test->{info}->_get_topo_data(), undef, 'Base class has no topo data');
}

sub c_ip : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'c_ip');
  is($test->{info}->c_ip(), undef, 'Base class has no topo');
}

sub c_if : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'c_if');
  is($test->{info}->c_if(), undef, 'Base class has no topo');
}

sub c_port : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'c_port');
  is($test->{info}->c_port(), undef, 'Base class has no topo');
}

sub c_id : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'c_id');
  is($test->{info}->c_id(), undef, 'Base class has no topo');
}

sub c_platform : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'c_platform');
  is($test->{info}->c_platform(), undef, 'Base class has no topo');
}

sub c_cap : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'c_cap');
  is($test->{info}->c_cap(), undef, 'Base class has no topo');
}

# Munges aren't methods, the are functions so calling convention is different
sub munge_speed : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'munge_speed');
  is(SNMP::Info::munge_speed('2488000000'),
    'OC-48', 'Speed munged according to map');
}

sub munge_highspeed : Tests(6) {
  my $test = shift;

  can_ok($test->{info}, 'munge_highspeed');
  is(SNMP::Info::munge_highspeed('15000000'), '15 Tbps', 'Tbps munge');
  is(SNMP::Info::munge_highspeed('1500000'),
    '1.5 Tbps', 'Fractional Tbps munge');
  is(SNMP::Info::munge_highspeed('15000'), '15 Gbps',  'Gbps munge');
  is(SNMP::Info::munge_highspeed('1500'),  '1.5 Gbps', 'Fractional Gbps munge');
  is(SNMP::Info::munge_highspeed('100'),   '100 Mbps', 'Mbps munge');
}

sub munge_ip : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'munge_ip');
  my $test_ip = pack("C4", split /\./, "123.4.5.6");
  is(SNMP::Info::munge_ip($test_ip),
    "123.4.5.6", 'Binary IP to dotted ASCII munge');
}

sub munge_mac : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'munge_mac');

  # The munge expects an octet string, pack a decimal string into
  # representation munge is expecting
  my $test_mac = pack("C*", split /\./, "01.35.69.103.137.171");
  is(SNMP::Info::munge_mac($test_mac),
    "01:23:45:67:89:ab", 'Octet string to colon separated ASCII hex string');
  my $bogus_mac = pack("C*", split /\./, "01.35.69.103.137.171.02");
  is(SNMP::Info::munge_mac($bogus_mac), undef,
    'Bad octet string returns undef');
}

sub munge_prio_mac : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'munge_prio_mac');

  # The munge expects an octet string, pack a decimal string into
  # representation munge is expecting
  my $test_mac = pack("C*", split /\./, "01.35.69.103.137.171.205.239");
  is(SNMP::Info::munge_prio_mac($test_mac),
    "01:23:45:67:89:ab:cd:ef",
    'Octet string to colon separated ASCII hex string');
  my $bogus_mac = pack("C*", split /\./, "01.35.69.103.137.171.205.239.02");
  is(SNMP::Info::munge_prio_mac($bogus_mac),
    undef, 'Bad octet string returns undef');
}

sub munge_prio_port : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'munge_prio_port');

  # The munge expects an octet string, pack a decimal string into
  # representation munge is expecting
  my $test_mac = pack("C*", split /\./, "171.205");
  is(SNMP::Info::munge_prio_port($test_mac),
    "ab:cd", 'Octet string to colon separated ASCII hex string');
  my $bogus_mac = pack("C*", split /\./, "171.205.02");
  is(SNMP::Info::munge_prio_port($bogus_mac),
    undef, 'Bad octet string returns undef');
}

# Can't see where this code is actually used, remove?
sub munge_octet2hex : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'munge_octet2hex');

  # The munge expects an octet string, pack a decimal string into
  # representation munge is expecting
  my $test_mac = pack("C*", split /\./, "171.205");
  is(SNMP::Info::munge_octet2hex($test_mac),
    "abcd", 'Octet string to ASCII hex string');
}

sub munge_dec2bin : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'munge_dec2bin');

  # This is layers munge, use L3 test case
  is(SNMP::Info::munge_dec2bin(4), '00000100', 'Binary char to ASCII binary');
}

sub munge_bits : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'munge_bits');

  my $bits = pack("B*", '00010110');

  is(SNMP::Info::munge_bits($bits),
    '00010110', 'SNMP2 BITS field to ASCII bit string');
}

# TODO
#sub munge_counter64 : Tests() {
#  my $test = shift;
#
#}

sub munge_i_up : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'munge_i_up');

  is(SNMP::Info::munge_i_up(),  undef,            'No arg returns undef');
  is(SNMP::Info::munge_i_up(4), 'unknown',        'Unknown status');
  is(SNMP::Info::munge_i_up(7), 'lowerLayerDown', 'Lower layer down status');
}

sub munge_port_list : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'munge_port_list');

  # These are typically longer bit strings to cover the all ports in a switch
  my $bit_string = '01010101010101010101010101010101';
  my $bits = pack("B*", $bit_string);

  # We are going to get a reference of array of bits back so convert the
  # string to an array
  my $expected = [];
  for my $value (split //, $bit_string) {
    $expected->[++$#$expected] = $value;
  }
  is_deeply(SNMP::Info::munge_port_list($bits),
    $expected, 'Portlist octet string coverted to ASCII bit array');
}

sub munge_null : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'munge_null');

  # See if all possible control characters and nulls are removed
  my $cntl_string = "Test\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09";
  $cntl_string .= "This\x0A\x0B\x0C\x0D\x0E\x0F";
  $cntl_string .= "Crazy\x11\x12\x13\x14\x15\x16\x17\x18\x19";
  $cntl_string .= "Cntl\x1A\x1B\x1C\x1D\x1E\x1F";
  $cntl_string .= "\x7FString";

  # This is layers munge, use L3 test case
  is(SNMP::Info::munge_null($cntl_string),
    'TestThisCrazyCntlString', 'Null and control characters removed');
}

sub munge_e_type : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'munge_e_type');

  # This is just calling SNMP::translateOb, so rather than loading another MIB
  # let's just resolve an OID we don't use from a loaded MIB.
  is(SNMP::Info::munge_e_type('.1.3.6.1.2.1.11.4'),
    'snmpInBadCommunityNames', 'OID translated properly');

  # Bogus OID
  is(SNMP::Info::munge_e_type('.100.3.6.1.2.1.11.4'),
    '.100.3.6.1.2.1.11.4', 'OID returned when unable to translate');
}

sub init : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'init');

  # When the test info object was created init() was called so all of the
  # entries in %MIBS should be loaded
  subtest 'Base MIBs loaded subtest' => sub {

    my $base_mibs = $test->{info}->mibs();

    foreach my $key (keys %$base_mibs) {
      my $qual_name = "$key" . '::' . "$base_mibs->{$key}";
      ok(defined $SNMP::MIB{$base_mibs->{$key}}, "$qual_name defined");
      like(SNMP::translateObj($qual_name),
        qr/^(\.\d+)+$/, "$qual_name translates to a OID");
    }
  };
  
  # Get SNMP::Version so we can restore
  my $netsnmp_ver = $SNMP::VERSION;
  local $SNMP::VERSION = '5.0.1';
  
  warnings_like { $test->{info}->init() }
  [{carped => qr/Net-SNMP\s5.0.1\sseems\sto\sbe\srather\sbuggy/x}],
    'Use of bad Net-SNMP gives warning';
  
  $SNMP::VERSION = $netsnmp_ver;
}


1;
