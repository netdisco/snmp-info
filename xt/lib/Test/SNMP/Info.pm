# Test::SNMP::Info
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

package Test::SNMP::Info;

use strict;
use warnings;
use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info;

sub constructor : Tests(+3) {
  my $test = shift;
  $test->SUPER::constructor;

  is($test->{info}{snmp_comm}, 'public',  'SNMP comm arg saved');
  is($test->{info}{snmp_ver},  2,         'SNMP version arg saved');
  is($test->{info}{snmp_user}, 'initial', 'SNMP user arg saved');
}

sub update : Tests(9) {
  my $test = shift;

  can_ok($test->{info}, 'update');

  # Starting community
  is($test->{info}{sess}{Community}, 'public', q(Original community 'public'));

  # Change community
  my %update_args = ('Community' => 'new_community',);
  delete $test->{info}{args}{Session};
  ok($test->{info}->update(%update_args), 'Update community');
  is($test->{info}->error(),         undef,           '... and no error');
  is($test->{info}{sess}{Community}, 'new_community', 'Community changed');

TODO: {
    # The update() method creates a new SNMP::Session, v1/2 do not actually
    # need to contact the DestHost for session creation while v3 does.
    # It appears that Net-SNMP 5.8 changes the behavior of v3 session creation
    # so that it doesn't require contact with the DestHost to pass these tests
    # We also could connect to http://snmplabs.com v3 simulator but would
    # prefer to keep those tests isolated to 10_remote_snmplabs.t - we could
    # also move the update() tests to that file.

    my $version = $SNMP::VERSION;
    my ( $major, $minor, $rev ) = split( '\.', $version );

    todo_skip "Skip v3 Context update() tests when using Net-SNMP < 5.8", 4
      if ($major < 5 or $minor < 8);

    # Starting context
    ok(!defined $test->{info}{sess}{Context}, q(Context doesn't exist));

    # Change context
    # Since update() is actually creating new SNMP::Session we can put
    # whatever session arguments needed in %update_args
    %update_args = ('Context' => 'vlan-100', 'Version' => 3,);
    ok($test->{info}->update(%update_args), 'Update Context');
    is($test->{info}->error(),         undef,      '... and no error');
    is($test->{info}->{sess}{Context}, 'vlan-100', 'Context changed');

  }
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
  cmp_deeply($empty_cache, $test->{info}->cache(), 'Cache starts empty');
  ok($test->{info}->cache($cache_data), 'Insert test data into cache');
  cmp_deeply(
    $cache_data,
    $test->{info}->cache(),
    'Cache method returns test data'
  );
  is($test->{info}->name(),
    'Test-Name', 'Global method call returned cached data');
  cmp_deeply(
    $test->{info}->i_description(),
    $cache_data->{store}{i_description},
    'Funcs method call returned cached data'
  );
  can_ok($test->{info}, 'clear_cache');
  ok($test->{info}->clear_cache(), 'cache cleared');
  cmp_deeply(
    $empty_cache,
    $test->{info}->cache(),
    'No cached data returned after clear_cache method call'
  );
}

sub debug : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'debug');

  ok(
    defined $test->{info}{debug}
      && $test->{info}{debug} == 0
      && $test->{info}->debug() == 0,
    'Debug initialized off'
  );
  $test->{info}->debug(1);
  ok($test->{info}{debug} && $test->{info}->debug(), 'Debug on');
  $test->{info}->debug(0);
  ok($test->{info}{debug} == 0 && $test->{info}->debug() == 0, 'Debug off');
}

sub offline : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'offline');

  ok(!defined $test->{info}{Offline}, 'Offline not initialized');
  $test->{info}->offline(1);
  ok($test->{info}{Offline} && $test->{info}->offline(), 'Offline mode on');
  $test->{info}->offline(0);
  ok($test->{info}{Offline} == 0 && $test->{info}->offline() == 0,
    'Offline off');
}

sub bulkwalk : Tests(4) {
  my $test = shift;

  can_ok $test->{info}, 'bulkwalk';

  # Test harness initalizes BulkWalk off, if we didn't provide an arg
  # it would not be defined.
  ok(
    !defined $test->{info}{BulkWalk}
      || ($test->{info}{BulkWalk} == 0 && $test->{info}->bulkwalk() == 0),
    'Bulkwalk initialized off'
  );
  $test->{info}->bulkwalk(1);
  ok($test->{info}{BulkWalk} && $test->{info}->bulkwalk(), 'Bulkwalk on');
  $test->{info}->bulkwalk(0);
  ok($test->{info}{BulkWalk} == 0 && $test->{info}->bulkwalk() == 0,
    'Bulkwalk off');
}

sub loopdetect : Tests(4) {
  my $test = shift;

  can_ok $test->{info}, 'loopdetect';

  ok(!defined $test->{info}{LoopDetect}, 'Loopdetect not initialized');
  $test->{info}->loopdetect(1);
  ok($test->{info}{LoopDetect} && $test->{info}->loopdetect(), 'Loopdetect on');
  $test->{info}->loopdetect(0);
  ok($test->{info}{LoopDetect} == 0 && $test->{info}->loopdetect() == 0,
    'Loopdetect off');
}

sub device_type : Tests(+6) {
  my $test = shift;
  $test->SUPER::device_type();

  # No sysServices and unknown sysDescr results in SNMP::Info
  my $cache_data
    = {'_layers' => '00000000', '_description' => 'My-Test-sysDescr',};
  $test->{info}->cache($cache_data);

  $test->{info}->debug(1);
  warnings_like { $test->{info}->device_type() }
  [{carped => qr/Might give unexpected results/i}],
    'No sysServices and unknown sysDescr with debug on gives warning';
  $test->{info}->debug(0);
  $test->{info}->clear_cache();

  # Cache has been cleared, empty args and no SNMP data result in undef
  is($test->{info}->device_type(),
    undef, 'No sysServices, no sysDescr results in undef');

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
    'SNMP::Info::Layer7::APC', 'Layer 7 device type by sysObjectID');
  $test->{info}->clear_cache();

  # We will test each specific subclass, so no need to check that logic here
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

  can_ok($test->{info}, 'specify');
  $test->{info}->cache_clear();

  # Specify uses device_type(), use same data as that test to setup
  # test cases here since return values from device_type() with them
  # have been tested

  # device_type returns undef
  $test->{info}->specify();
  is(
    $test->{info}->error(),
    'SNMP::Info::specify() - fatal error: connect failed or missing sysServices and/or sysDescr',
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
  cmp_deeply($test->{info}->if_ignore(),
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
  cmp_deeply($test->{info}->i_speed(),
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
  cmp_deeply($test->{info}->i_speed_raw(),
    $expected_raw, 'Raw high speed interface reported accurately');

  # Note the cache is populated unmunged data now - not sure if that is
  # expected behavior. Clear cache to get data to test that munges are restored.
  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_speed(),
    $expected, 'Munges restored after i_speed_raw() call');
}

sub ip_index : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'ip_index');

  my $cache_data = {
    '_old_ip_index' => 1,
    '_new_ip_index' => 1,
    '_new_ip_type'  => 1,
    'store'        => {
      'old_ip_index' =>
        {'2.3.4.5' => 7, '2.2.2.2' => 11},
      'new_ip_index' =>
        {'1.4.1.2.3.4' => 6, '1.4.10.255.255.255' => 8, '1.4.8.8.8.8' => 10},
      'new_ip_type' =>
        {'1.4.1.2.3.4' => 'unicast', '1.4.10.255.255.255' => 'broadcast', '1.4.8.8.8.8' => 'unicast'},
    }
  };
  $test->{info}->cache($cache_data);

  my $expected = {'2.3.4.5' => 7, '2.2.2.2' => 11};

  cmp_deeply($test->{info}->ip_index(),
    $expected, q(IP addresses mapped to 'ifIndex' using old 'ipAddrTable'));

  delete $test->{info}{_old_ip_index};
  $expected = {'1.2.3.4' => 6, '8.8.8.8' => 10};

  cmp_deeply($test->{info}->ip_index(),
    $expected, q(IP addresses mapped to 'ifIndex' using new 'ipAddressTable'));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->ip_index(), {}, q(No data returns empty hash));
}

sub ip_table : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'ip_table');

  my $cache_data = {
    '_old_ip_table' => 1,
    '_new_ip_index' => 1,
    '_new_ip_type'  => 1,
    'store'        => {
      'old_ip_table' =>
        {'2.3.4.5' => '2.3.4.5', '2.2.2.2' => '2.2.2.2'},
      'new_ip_index' =>
        {'1.4.1.2.3.4' => 6, '1.4.10.255.255.255' => 8, '1.4.8.8.8.8' => 10},
      'new_ip_type' =>
        {'1.4.1.2.3.4' => 'unicast', '1.4.10.255.255.255' => 'broadcast', '1.4.8.8.8.8' => 'unicast'},
    }
  };
  $test->{info}->cache($cache_data);

  my $expected = {'2.3.4.5' => '2.3.4.5', '2.2.2.2' => '2.2.2.2'};

  cmp_deeply($test->{info}->ip_table(),
    $expected, q(IP addresses using old 'ipAddrTable'));

  delete $test->{info}{_old_ip_table};
  $expected = {'1.2.3.4' => '1.2.3.4', '8.8.8.8' => '8.8.8.8'};

  cmp_deeply($test->{info}->ip_table(),
    $expected, q(IP addresses using new 'ipAddressTable'));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->ip_table(), {}, q(No data returns empty hash));
}

sub ip_netmask : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'ip_netmask');

  my $cache_data = {
    '_old_ip_netmask' => 1,
    '_new_ip_prefix' => 1,
    '_new_ip_type'  => 1,
    'store'        => {
      'old_ip_netmask' =>
        {'2.3.4.5' => '255.255.255.0', '2.2.2.2' => '255.255.0.0'},
      'new_ip_prefix' =>
        {'1.4.1.2.3.4' => 'IP-MIB::ipAddressPrefixOrigin.2.ipv4."1.2.3.0".24', '1.4.10.2.3.4' => '.1.3.6.1.2.1.4.32.1.5.6.1.4.10.0.0.0.8', '1.4.8.8.8.8' => '.0.0'},
      'new_ip_type' =>
        {'1.4.1.2.3.4' => 'unicast', '1.4.10.2.3.4' => 'unicast', '1.4.8.8.8.8' => 'unicast'},
    }
  };
  $test->{info}->cache($cache_data);

  my $expected = {'2.3.4.5' => '255.255.255.0', '2.2.2.2' => '255.255.0.0'};

  cmp_deeply($test->{info}->ip_netmask(),
    $expected, q(IP netmask using old 'ipAddrTable'));

  delete $test->{info}{_old_ip_netmask};
  $expected = {'1.2.3.4' => '255.255.255.0', '10.2.3.4' => '255.0.0.0'};

  cmp_deeply($test->{info}->ip_netmask(),
    $expected, q(IP netmask using new 'ipAddressTable'));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->ip_netmask(), {}, q(No data returns empty hash));
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

sub munge_mac : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'munge_mac');

  # This is how these MACs look in a snmpwalk
  my $test_mac       = "01 23 45 67 89 AB";
  my $long_test_mac  = "01 23 45 67 89 AB CD";
  my $short_test_mac = "01 23 45 67 89";

  # However, they come across the wire as octet string, so we need to pack
  # them. Before packing, we need to remove the whitespace
  foreach ($test_mac, $long_test_mac, $short_test_mac) {
    $_ =~ s/\s//g;
    $_ = pack("H*", $_);
  }

  is(SNMP::Info::munge_mac($test_mac),
    "01:23:45:67:89:ab", 'Octet string to colon separated ASCII hex string');
  is(SNMP::Info::munge_mac($long_test_mac),
    undef, 'Too long of an octet string returns undef');
  is(SNMP::Info::munge_mac($short_test_mac),
    undef, 'Too short of an octet string returns undef');
}

sub munge_prio_mac : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'munge_prio_mac');

  # This is how these look in a snmpwalk
  my $test_mac       = "01 23 45 67 89 AB CD EF";
  my $long_test_mac  = "01 23 45 67 89 AB CD EF 02";
  my $short_test_mac = "01 23 45 67 89";

  # However, they come across the wire as octet string, so we need to pack
  # them. Before packing, we need to remove the whitespace
  foreach ($test_mac, $long_test_mac, $short_test_mac) {
    $_ =~ s/\s//g;
    $_ = pack("H*", $_);
  }

  is(SNMP::Info::munge_prio_mac($test_mac),
    "01:23:45:67:89:ab:cd:ef",
    'Octet string to colon separated ASCII hex string');
  is(SNMP::Info::munge_prio_mac($long_test_mac),
    undef, 'Too long of an octet string returns undef');
  is(SNMP::Info::munge_mac($short_test_mac),
    undef, 'Too short of an octet string returns undef');
}

sub munge_prio_port : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'munge_prio_port');

  # This is how these look in a snmpwalk
  my $test_mac       = "AB CD";
  my $long_test_mac  = "AB CD EF";
  my $short_test_mac = "AB";

  # However, they come across the wire as octet string, so we need to pack
  # them. Before packing, we need to remove the whitespace
  foreach ($test_mac, $long_test_mac, $short_test_mac) {
    $_ =~ s/\s//g;
    $_ = pack("H*", $_);
  }

  is(SNMP::Info::munge_prio_port($test_mac),
    "ab:cd", 'Octet string to colon separated ASCII hex string');
  is(SNMP::Info::munge_prio_port($long_test_mac),
    undef, 'Too long of an octet string returns undef');
  is(SNMP::Info::munge_prio_port($short_test_mac),
    undef, 'Too short of an string returns undef');
}

# Can't see where this code is actually used, remove?
sub munge_octet2hex : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'munge_octet2hex');

  # This is how this looks in a snmpwalk
  my $test_mac = "AB CD";

  # However, is comes across the wire as octet string, so we need to pack
  # it. Before packing, we need to remove the whitespace
  $test_mac =~ s/\s//g;
  $test_mac = pack("H*", $test_mac);

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

sub munge_counter64 : Tests(4) {
  my $test = shift;

  my $hc_octets = 744002524365;

  can_ok($test->{info}, 'munge_counter64');
  is(SNMP::Info::munge_counter64(), undef, 'No arg returns undef');

  # Default is no BigInt
  is(SNMP::Info::munge_counter64(744002524365),
    744002524365, 'No BIGINT returns counter');

SKIP: {
    eval {
      require Math::BigInt;
      1;
    } or do {
      skip "Math::BigInt not installed", 1;
    };

    my $class = $test->class;
    my $sess  = $test->mock_session;
    my $big_int_info
      = $class->new('AutoSpecify' => 0, 'BigInt' => 1, 'Session' => $sess,);

    my $obj = SNMP::Info::munge_counter64(744002524365);
    isa_ok($obj, 'Math::BigInt', 'Test counter64');

  }
}

sub munge_i_up : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'munge_i_up');

  is(SNMP::Info::munge_i_up(),  undef,            'No arg returns undef');
  is(SNMP::Info::munge_i_up(4), 'unknown',        'Unknown status');
  is(SNMP::Info::munge_i_up(7), 'lowerLayerDown', 'Lower layer down status');
}

sub munge_port_list : Tests(6) {
  my $test = shift;

  can_ok($test->{info}, 'munge_port_list');

  # Start with the bit string since in a portlist each port is represented as
  # a bit.
  # These are typically longer bit strings to cover the all ports in a switch
  my $bit_string = '01010101010101010101010101010101';
  my $bits_packed = pack("B*", $bit_string);

  # This is more for documentation than test code. When performing a snmpwalk
  # the output will typically be a hex string. This converts the packed bit
  # string above into a hex string as would be seen in the snmpwalk output.
  my $unpacked_hex_string
    = join(' ', map { sprintf "%02X", $_ } unpack('C*', $bits_packed));

  # This should be the same as $unpacked_hex_string
  my $hex_string = '55 55 55 55';

  # Remove the spaces so we can pack, but preserve $hex_string for comparison
  # testing with $unpacked_hex_string
  (my $new_hex_string = $hex_string) =~ s/\s//g;

  # Pack the hex string for comparison with $bits_packed
  my $new_hex_string_packed = pack("H*", $new_hex_string);

  # Finally unpack again to compare with original $bit_string
  my $new_bit_string = unpack("B*", $new_hex_string_packed);

  # String comparison testing
  is($unpacked_hex_string, $hex_string,
    'Unpacking binary bits into hex string is same as expected hex string');
  is($new_hex_string_packed, $bits_packed,
    'Packed hex string is equivalent to packed bit string');
  is($new_bit_string, $bit_string,
    'Unpacking packed hex string as binary results in original bit string');

  # We are going to get a reference of array of bits back so convert the
  # string to an array
  my $expected = [];
  for my $value (split //, $bit_string) {
    $expected->[++$#$expected] = $value;
  }
  cmp_deeply(SNMP::Info::munge_port_list($bits_packed),
    $expected, 'Portlist packed bit string coverted to ASCII bit array');
  cmp_deeply(SNMP::Info::munge_port_list($new_hex_string_packed),
    $expected, 'Portlist packed hex string coverted to ASCII bit array');
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

sub resolve_desthost : Tests(6) {
  my $test = shift;

  can_ok($test->{info}, 'resolve_desthost');

  is(SNMP::Info::resolve_desthost('1.2.3.4'),
    '1.2.3.4', 'IPv4 address returns unchanged');

  is(SNMP::Info::resolve_desthost('::1.2.3.4'),
    'udp6:0:0:0:0:0:0:102:304', q(IPv6 address returns with 'udp6:' prefix));

  is(
    SNMP::Info::resolve_desthost('udp6:fe80::2d0:b7ff:fe21:c6c0'),
    'udp6:fe80:0:0:0:2d0:b7ff:fe21:c6c0',
    q(Net-SNMP example with 'udp6:' prefix returns expected string)
  );

  is(
    SNMP::Info::resolve_desthost('fe80::2d0:b7ff:fe21:c6c0'),
    'udp6:fe80:0:0:0:2d0:b7ff:fe21:c6c0',
    q(Net-SNMP example IPv6 address returns with 'udp6:' prefix)
  );

  dies_ok { SNMP::Info::resolve_desthost('1.2.3.4.5') } 'Bad IP dies';
}

sub init : Tests(3) {
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

  warnings_exist { $test->{info}->init() }
  [{carped => qr/Net-SNMP\s5.0.1\sseems\sto\sbe\srather\sbuggy/x}],
    'Use of bad Net-SNMP gives warning';

  $SNMP::VERSION = $netsnmp_ver;
}

sub args : Tests(2) {
  my $test = shift;

  # Match args passed to new() in My::Test::Class
  my $sess = $test->mock_session;
  my $args = {
    'AutoSpecify' => 0,
    'BulkWalk'    => 0,
    'UseEnums'    => 1,
    'RetryNoSuch' => 1,
    'DestHost'    => '127.0.0.1',
    'Community'   => 'public',
    'Version'     => 2,
    'Session'     => $sess,
    'Debug'       => ($ENV{INFO_TRACE} || 0),
    'DebugSNMP'   => ($ENV{SNMP_TRACE} || 0),
  };

  can_ok($test->{info}, 'args');
  cmp_deeply($test->{info}->args(),
    $args, 'Args returned match those passed to new()');
}

# Rename this test to prevent conflicts/recursion within test class
sub class_call : Tests(2) {
  my $test  = shift;
  my $class = $test->class;

  can_ok($test->{info}, 'class');
  is($test->{info}->class(), $class, 'Class method returns object class');
}

sub error_throw : Tests(7) {
  my $test = shift;

  my $error_str = "Test Error String\n";

  can_ok($test->{info}, 'error_throw');

  is($test->{info}->error_throw(), undef, 'No error provided returns undef');
  is($test->{info}->error(),       undef, '... and no error()');
  is($test->{info}->error_throw($error_str),
    undef, 'Error provided returns undef');

  # Since we don't call with no_clear flag the error is cleared
  is(
    $test->{info}->error(),
    "Test Error String\n",
    '... and error() returns error string of call'
  );

  # Turn on debug to check carp of error
  $test->{info}->debug(1);
  warning_is { $test->{info}->error_throw($error_str) }
  [{carped => 'Test Error String'}], 'Error carped when debug turned on';
  $test->{info}->debug(0);
  is(
    $test->{info}->error(),
    "Test Error String\n",
    '... and error() returns error string of call'
  );
}

sub nosuch : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'nosuch');
  is($test->{info}->nosuch(), 1, 'RetryNoSuch on by default');
}

sub session : Tests(4) {
  my $test = shift;
  my $sess = $test->mock_session;

  can_ok($test->{info}, 'session');
  cmp_deeply($test->{info}->session(), $sess, 'Session returned');

  # This will not be a mocked_session so object type and session will be
  # different
  my $new_sess = SNMP::Session->new(
    DestHost  => '127.0.0.1',
    Community => 'new_public',
    Version   => 2,
  );
  cmp_deeply($test->{info}->session($new_sess),
    $new_sess, 'New session returned');
  isa_ok($test->{info}->session(), 'SNMP::Session', 'New session object');
}


sub store : Tests(4) {
  my $test = shift;

  # The store method itself doesn't enforce the naming, so we'll test
  # with some totally made up data for 2nd attribute
  my $store_data = {
    'i_description' =>
      {10 => 'Test-Description-10', 20 => 'Test-Description-20'},
    'test_attribute' => {Key1 => 'Value 1', Key2 => 'Value 2'}
  };

  can_ok($test->{info}, 'store');

  cmp_deeply($test->{info}->store(), {}, 'Store starts empty');
  ok($test->{info}->store($store_data), 'Insert test data into store');
  cmp_deeply(
    $store_data,
    $test->{info}->store(),
    'Store method returns test data'
  );
}

sub private_global : Tests(14) {
  my $test = shift;

  can_ok($test->{info}, '_global');

  # This private method and dynamic creation of global methods is covered in
  # can() tests. Use these tests to exercise code path for the load_, orig_,
  # _raw, as well as, 'NOSUCHOBJECT' and 'NOSUCHINSTANCE' returns so the method
  # calls will be indirect.

  # Some of these are defined in both SNMPv2-MIB and RFC1213-MIB so use
  # OIDs to to make sure no issues with which one was loaded during tests
  # Data for load_
  my $data = {

    # SNMPv2-MIB::sysContact OID = .1.3.6.1.2.1.1.4
    '.1.3.6.1.2.1.1.4' => {0 => 'NOSUCHOBJECT'},

    # SNMPv2-MIB::sysName OID = .1.3.6.1.2.1.1.5
    '.1.3.6.1.2.1.1.5' => {0 => 'NOSUCHINSTANCE'},

    # We'll use this to check _raw
    # SNMPv2-MIB::sysServices OID = .1.3.6.1.2.1.1.7
    '.1.3.6.1.2.1.1.7' => {0 => 64},

    # This is a leaf that we don't reference in %GLOBALS
    # SNMPv2-MIB::snmpOutTraps OID = .1.3.6.1.2.1.11.29
    '.1.3.6.1.2.1.11.29' => {0 => 245},
  };

  # Lets load cache with data to for initial tests
  my $cache_data = {'_layers' => 4, '_name' => 'CacheTestName',};

  # Cache expected after running tests
  my $expected_cache = {
    '_layers'       => 64,
    '_snmpOutTraps' => 245,
    '_contact'      => undef,
    '_name'         => undef,
    'store'         => {},
  };

  # Load the data for use in the mock session
  $test->{info}{sess}{Data} = $data;

  # Load the cache
  $test->{info}->cache($cache_data);

  is($test->{info}->name(), 'CacheTestName',
    'Call to name() loads cached data');
  is($test->{info}->layers(),
    '00000100', 'Call to layers() loads cached data and munges');
  is($test->{info}->layers_raw(),
    4, 'Call to layers_raw() loads cached data without munge');
  is($test->{info}->load_layers(),
    '01000000', 'Call to load_layers loads new data and munges');
  is($test->{info}->layers_raw(),
    64, 'Call to layers_raw() loads new data without munge');
  is($test->{info}->snmpOutTraps(),
    245, 'Call to snmpOutTraps() resolves MIB leaf and returns data');

  is($test->{info}->load_contact(),
    undef, 'Call to load_contact() returns undef');
  is(
    $test->{info}->error(),
    'SNMP::Info::_global(load_contact) NOSUCHOBJECT',
    '... and throws error indicating NOSUCHOBJECT'
  );
  is($test->{info}->load_name(), undef, 'Call to load_name() returns undef');
  is(
    $test->{info}->error(),
    'SNMP::Info::_global(load_name) NOSUCHINSTANCE',
    '... and throws error indicating NOSUCHINSTANCE'
  );
  cmp_deeply($test->{info}->cache(),
    $expected_cache, 'Cache contains expected data');

  # Simulate session error, i.e. get fails
  $test->{info}{sess}{ErrorStr} = 'Get Failed';

  # We need to force load to make it to error
  is($test->{info}->load_name(), undef, 'Upon session error returned undef');
  is(
    $test->{info}->error(),
    'SNMP::Info::_global(load_name) Get Failed',
    '... and error was thrown'
  );

  # Clear error or will impact future tests
  $test->{info}{sess}{ErrorStr} = undef;
}

sub private_set : Tests(12) {
  my $test = shift;

  can_ok($test->{info}, '_set');

  # Load cache with data so we can check that _set clears
  my $cache_data = {'_name' => 'CacheTestName',};

  $test->{info}->cache($cache_data);
  is($test->{info}{_name}, 'CacheTestName', 'Cache has a name');

  # Simple set
  is($test->{info}->_set('name', 'TestName', 0),
    1, 'Valid non-array ref name _set() returned 1');
  is($test->{info}{_name}, undef, '... and now cache is cleared');

  # 4 element array
  my $arg_array = ['name', 'TestName', 0];
  is($test->{info}->_set($arg_array),
    1, 'Valid array reference name _set() returned 1');

  # Reference to an array of 4 element arrays, also see set_multi
  my $arg_aoa = [['name', 'TestName', 0]];
  is($test->{info}->_set($arg_aoa),
    1, 'Valid array of arrays reference name _set() returned 1');

  # Bogus args
  my $bogus_args = {'name' => 'TestName'};
  is($test->{info}->_set($bogus_args), undef, 'Invalid args returned undef');
  like(
    $test->{info}->error(),
    qr/SNMP::Info::_set.+-\sFailed/x,
    '... and error was thrown'
  );

  # Bogus attr
  is($test->{info}->_set('no_name', 'TestName', 0),
    undef, 'Invalid attr returned undef');
  like(
    $test->{info}->error(),
    qr/SNMP::Info::_set.+-\sFailed\sto\sfind/x,
    '... and error was thrown'
  );

  # Simulate session error, i.e. set fails
  $test->{info}{sess}{ErrorStr} = 'Set Failed';
  is($test->{info}->_set('name', 'TestName', 0),
    undef, 'Upon session error returned undef');
  is(
    $test->{info}->error(),
    'SNMP::Info::_set Set Failed',
    '... and error was thrown'
  );

  # Clear error or will impact future tests
  $test->{info}{sess}{ErrorStr} = undef;
}

sub private_make_setter : Tests(10) {
  my $test = shift;

  # This private method is covered in other tests
  can_ok($test->{info}, '_make_setter');

  # This private method and dynamic creation of methods is covered in
  # can() tests. Use these tests to exercise code path for non-multi SNMP sets
  # so the method calls will be indirect. This will indirectly exercise the
  # AUTOLOAD and can methods as well.

  # Load cache with data so we can check that _set clears
  my $cache_data = {'_name' => 'CacheTestName',};

  $test->{info}->cache($cache_data);
  is($test->{info}{_name}, 'CacheTestName', 'Cache has a name');

  # Set on %GLOBALS entry name
  is($test->{info}->set_name('TestName'),
    1, 'SNMP set on global name with no iid returned 1');
  is($test->{info}{_name}, undef, '... and now cache is cleared');

  # Same set on the MIB leaf
  is($test->{info}->set_sysName('TestName'),
    1, 'SNMP set on MIB leaf sysName with no iid returned 1');

  # Can provide IID to global if wanted
  is($test->{info}->set_name('TestName', 0),
    1, 'SNMP set on global name with iid returned 1');

  # Set on a %FUNCS table method
  is($test->{info}->set_i_alias('TestPortName', 3),
    1, 'SNMP set on func i_description with iid returned 1');

  # Same set on the table MIB leaf
  is($test->{info}->set_ifAlias('TestPortName', 3),
    1, 'SNMP set on MIB leaf ifAlias with iid returned 1');

  # Simulate session error, i.e. set fails
  $test->{info}{sess}{ErrorStr} = 'Set Failed';
  is($test->{info}->set_i_alias('TestPortName', 3),
    undef, 'Upon session error returned undef');
  is(
    $test->{info}->error(),
    'SNMP::Info::_set Set Failed',
    '... and error was thrown'
  );

  # Clear error or will impact future tests
  $test->{info}{sess}{ErrorStr} = undef;
}

sub set_multi : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'set_multi');

 # This is contrived and mock set always returns true, so this test case
 # could be improved. The multi_set method is meant for use similar to a
 # database transaction where all sets must be completed in one atomic operation
  my $multi_set = [
    ['i_up_admin',    2,            3],
    ['i_description', 'Port Down',  3],
    ['ifDescr',       'Test Descr', 4],
  ];

  is($test->{info}->set_multi($multi_set), 1, 'Valid multi_set() returned 1');

  $multi_set = [
    ['i_up_admin',    2,           3],
    ['i_description', 'Port Down', 3],
    ['bogus_set',     'What?',     4],
  ];

  is($test->{info}->set_multi($multi_set),
    undef, 'Invalid multi_set() returned undef');

}

sub load_all : Tests(6) {
  my $test = shift;

  can_ok($test->{info}, 'load_all');

  # This method uses load_ and will not utilize the cache so we need to define
  # data for the mocked session's get/getnext methods

  # Use OIDs to prevent resolution conflicts of fully qualified names between
  # RFC1213-MIB and IF-MIB dependant upon which was loaded first via random
  # hash ordering. We only need a subset of data to verify the method is
  # working, no need to have data for all funcs the method calls. Use a subset
  # of the IF-MIB::ifTable and IF-MIB::ifXTable
  my $data = {
    '.1.3.6.1.2.1.2.2.1.1' => {1 => 1, 2 => 2, 3 => 3,},
    '.1.3.6.1.2.1.2.2.1.2' => {
      1 => 'Loopback',
      2 => '1/3/1, 10/100 Ethernet TX',
      3 => '1/3/2, 10/100 Ethernet TX'
    },
    '.1.3.6.1.2.1.2.2.1.3'     => {1 => 24,   2 => 6,         3 => 6},
    '.1.3.6.1.2.1.2.2.1.4'     => {1 => 1500, 2 => 1514,      3 => 1514},
    '.1.3.6.1.2.1.2.2.1.5'     => {1 => 0,    2 => 100000000, 3 => 1000000000,},
    '.1.3.6.1.2.1.31.1.1.1.15' => {1 => 0,    2 => 100,       3 => 1000,},
  };

  # Data is stored unmunged, OID's will be resolved and cache entries stored
  # under %FUNCS names
  my $expected_data = {
    'i_index'       => {1 => 1, 2 => 2, 3 => 3,},
    'i_description' => {
      1 => 'Loopback',
      2 => '1/3/1, 10/100 Ethernet TX',
      3 => '1/3/2, 10/100 Ethernet TX'
    },
    'i_type'       => {1 => 24,   2 => 6,         3 => 6},
    'i_mtu'        => {1 => 1500, 2 => 1514,      3 => 1514},
    'i_speed'      => {1 => 0,    2 => 100000000, 3 => 1000000000,},
    'i_speed_high' => {1 => 0,    2 => 100,       3 => 1000,},

    # In base class defined as ifIndex
    'interfaces' => {1 => 1, 2 => 2, 3 => 3,},
  };

  # Start with some data in store to verify it is overwritten
  my $store_data
    = {'i_description' =>
      {10 => 'Test-Description-10', 20 => 'Test-Description-20'},
    };

  cmp_deeply($test->{info}->store(), {}, 'Store starts empty');
  ok($test->{info}->store($store_data), 'Insert test data into store');
  cmp_deeply($test->{info}->store(), $store_data,
    '... store now has test data');

  # Load the data for use in the mock session
  $test->{info}{sess}{Data} = $data;

  cmp_deeply($test->{info}->load_all(),
    $expected_data, 'Call to load_all() returns expected data');
  cmp_deeply($test->{info}->store(),
    $expected_data, '... and store now has expected data from load_all()');
}

# Need to rename from all to prevent name conflict
sub my_all : Tests(9) {
  my $test = shift;

  can_ok($test->{info}, 'all');

  # Use OIDs to prevent resolution conflicts of fully qualified names between
  # RFC1213-MIB and IF-MIB dependant upon which was loaded first via random
  # hash ordering. We only need a bare minimum of data to verify the method is
  # working since it relies on load_all() which has its own tests.
  my $data = {
    '.1.3.6.1.2.1.2.2.1.2' => {
      1 => 'Loopback',
      2 => '1/3/1, 10/100 Ethernet TX',
      3 => '1/3/2, 10/100 Ethernet TX'
    },
  };

  # Data is stored unmunged, OID's will be resolved and cache entries stored
  # under %FUNCS names
  my $expected_data = {
    'i_description' => {
      1 => 'Loopback',
      2 => '1/3/1, 10/100 Ethernet TX',
      3 => '1/3/2, 10/100 Ethernet TX'
    },
  };

  # Start with some data in store to verify it is overwritten on first call
  # and whatever is in store() is returned on subsequent calls to all
  my $store_data
    = {'i_description' =>
      {10 => 'Test-Description-10', 20 => 'Test-Description-20'},
    };

  cmp_deeply($test->{info}->store(), {}, 'Store starts empty');
  ok($test->{info}->store($store_data), 'Insert test data into store');
  cmp_deeply($test->{info}->store(), $store_data,
    '... store now has test data');

  # Load the data for use in the mock session
  $test->{info}{sess}{Data} = $data;

  cmp_deeply($test->{info}->all(),
    $expected_data, 'Call to all() returns expected data');
  cmp_deeply($test->{info}->store(),
    $expected_data, '... and store now has expected data from all()');

  ok($test->{info}->store($store_data), 'Re-insert test data into store');
  cmp_deeply($test->{info}->store(),
    $store_data, '... store again has test data');

  cmp_deeply($test->{info}->all(),
    $expected_data,
    '... call to all() returns test data, no call to load_all()');
}

sub private_load_attr : Tests(18) {
  my $test = shift;

  can_ok($test->{info}, '_load_attr');

  # This private method and dynamic creation of table aka func methods is
  # covered in can() tests. Use these tests to exercise code path for
  # the load_, orig_, _raw, as well as, 'NOSUCHOBJECT', 'NOSUCHINSTANCE',
  # and 'ENDOFMIBVIEW' returns so the method calls will be indirect.

  # Currently mocked session in test harness doesn't support bulkwalk, so
  # that code path is not tested

  # Some of these are defined in both SNMPv2-MIB and RFC1213-MIB so use
  # OIDs to to make sure no issues with which one was loaded during tests
  # Data for load_
  my $data = {
    '.1.3.6.1.2.1.2.2.1.2' => {
      1 => 'Loopback',
      2 => '1/3/1, 10/100 Ethernet TX',
      3 => '1/3/2, 10/100 Ethernet TX'
    },
    '.1.3.6.1.2.1.2.2.1.8'      => {1 => 4,       2 => 'up',   3 => 7},
    'IF-MIB::ifPromiscuousMode' => {1 => 'false', 2 => 'true', 3 => 'false'},
    'IF-MIB::ifConnectorPresent'         => {0 => 'NOSUCHOBJECT'},
    'IF-MIB::ifCounterDiscontinuityTime' => {0 => 'NOSUCHINSTANCE'},
    'IF-MIB::ifHCOutOctets' =>
      {1 => 0, 2 => 1828306359704, 3 => 1002545943585, 4 => 'ENDOFMIBVIEW'},

    # Tables to test partial and full OIDs
    '.1.3.6.1.4.1.171.12.1.1.12'   => {1 => 'partial', 2 => 'oid', 3 => 'data'},
    '.100.3.6.1.4.1.171.12.1.1.12' => {2 => 'full',    3 => 'oid', 4 => 'leaf'},
  };

  # Load cache with data to for initial tests
  my $cache_data = {
    '_i_description' => 1,
    '_i_up'          => 1,
    'store'          => {
      'i_description' =>
        {10 => 'Test-Description-10', 20 => 'Test-Description-20'},
      'i_up' => {10 => 6, 20 => 7}
    }
  };

  # Cache expected after running tests
  # Note: i_up starts in cache and call to load_i_up for new data increments
  # the cache counter
  # Note: We don't call load_i_description so the data from cache never gets
  # replaced
  # Note: munge_i_up only munges integers 4-7 as 1-3 are already enumerated
  my $expected_cache = {
    '_i_description'              => 1,
    '_i_up'                       => 2,
    '_ifPromiscuousMode'          => 1,
    '_ifConnectorPresent'         => undef,
    '_ifCounterDiscontinuityTime' => undef,
    '_i_octet_out64'              => 1,
    'store'                       => {
      'i_description' =>
        {10 => 'Test-Description-10', 20 => 'Test-Description-20'},
      'i_up'              => {1 => 4,       2 => 'up',   3 => 7},
      'ifPromiscuousMode' => {1 => 'false', 2 => 'true', 3 => 'false'},
      'i_octet_out64' => {1 => 0, 2 => 1828306359704, 3 => 1002545943585}
    }
  };

  my $expected_cache_munge_iup = {10 => 'notPresent', 20 => 'lowerLayerDown'};
  my $expected_load_munge_iup
    = {1 => 'unknown', 2 => 'up', 3 => 'lowerLayerDown'};

  my $expected_load_raw_iftype = {1 => 24, 2 => 6, 3 => 6};

  # Load the data for use in the mock session
  $test->{info}{sess}{Data} = $data;

  # Load the cache
  $test->{info}->cache($cache_data);

  cmp_deeply(
    $test->{info}->i_description(),
    $cache_data->{'store'}{'i_description'},
    'Call to i_description() loads cached data'
  );
  cmp_deeply($test->{info}->i_up(),
    $expected_cache_munge_iup, 'Call to i_up() loads cached data and munges');
  cmp_deeply(
    $test->{info}->i_up_raw(),
    $cache_data->{'store'}{'i_up'},
    'Call to i_up_raw() loads cached data without munge'
  );
  cmp_deeply($test->{info}->load_i_up(),
    $expected_load_munge_iup, 'Call to load_i_up() loads new data and munges');
  cmp_deeply(
    $test->{info}->i_up_raw(),
    $expected_cache->{'store'}{'i_up'},
    'Call to i_up_raw() loads new data without munge'
  );

  # Test ability to use MIB leaf
  cmp_deeply(
    $test->{info}->ifPromiscuousMode(),
    $data->{'IF-MIB::ifPromiscuousMode'},
    'Call to ifPromiscuousMode() resolves MIB leaf and returns data'
  );

  # Test error conditions
  is($test->{info}->load_ifConnectorPresent(),
    undef, 'Call to load_ifConnectorPresent() returns undef');
  is(
    $test->{info}->error(),
    'SNMP::Info::_load_attr: load_ifConnectorPresent :  NOSUCHOBJECT',
    '... and throws error indicating NOSUCHOBJECT'
  );
  is($test->{info}->load_ifCounterDiscontinuityTime(),
    undef, 'Call to load_ifCounterDiscontinuityTime() returns undef');
  is(
    $test->{info}->error(),
    'SNMP::Info::_load_attr: load_ifCounterDiscontinuityTime :  NOSUCHINSTANCE',
    '... and throws error indicating NOSUCHINSTANCE'
  );

  # 'ENDOFMIBVIEW' isn't an error condition, it just stops the walk
  # Ask for raw since don't want munge_counter64 to turn results into objects
  # and want to compare to what will be stored in cache at the end
  cmp_deeply(
    $test->{info}->i_octet_out64_raw(),
    $expected_cache->{'store'}{'i_octet_out64'},
    'Call to i_up_raw() loads new data without munge'
  );

  # Test partial fetches
  cmp_deeply(
    $test->{info}->i_octet_out64_raw(3),
    +{3 => 1002545943585},
    'Partial call to i_octet_out64_raw(3) data without munge'
  );
  cmp_deeply(
    $test->{info}->i_description(2),
    +{2 => '1/3/1, 10/100 Ethernet TX'},
    'Partial call to i_description(2) loads new data'
  );
  ok(!exists $test->{info}{store}{i_description}{2},
    '... and does not store it in cache');

  cmp_deeply($test->{info}->cache(),
    $expected_cache, 'Cache contains expected data');

  # Test OID based table fetches
  # This is from Layer3::DLink will only partially resolve
  $test->{info}{funcs}{partial_oid} = '.1.3.6.1.4.1.171.12.1.1.12';

  my $expected_p_oid_data = {1 => 'partial', 2 => 'oid', 3 => 'data'};

  cmp_deeply($test->{info}->partial_oid(),
    $expected_p_oid_data, 'Partial translated OID leaf returns expected data');

  # This is a bogus OID will not translate at all
  $test->{info}{funcs}{full_oid} = '.100.3.6.1.4.1.171.12.1.1.12';

  my $expected_f_oid_data = {2 => 'full', 3 => 'oid', 4 => 'leaf'};

  cmp_deeply($test->{info}->full_oid(),
    $expected_f_oid_data, 'Full OID leaf returns expected data');
}

sub private_show_attr : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, '_show_attr');

  # Load cache with data
  my $cache_data = {'_i_up' => 1, 'store' => {'i_up' => {10 => 6, 20 => 7}}};

  # Load the cache
  $test->{info}->cache($cache_data);

  my $expected_munge = {10 => 'notPresent', 20 => 'lowerLayerDown'};

  # Minimal tests as this method is heavily covered in other testing
  cmp_deeply($test->{info}->_show_attr('i_up'),
    $expected_munge, 'Shows munged data from cache without raw flag');
  cmp_deeply(
    $test->{info}->_show_attr('i_up', 1),
    $cache_data->{'store'}{'i_up'},
    'Shows unmunged data from cache with raw flag'
  );
}

sub snmp_connect_ip : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'snmp_connect_ip');

  is($test->{info}->snmp_connect_ip('127.0.0.1', 2, 'public'),
    undef, 'Connect to loopback returns undef');
  is($test->{info}->snmp_connect_ip('0.0.0.0', 2, 'public'),
    undef, 'Connect to zeros returns undef');

  # Live call moved to 10_remote_snmplabs.t
}

sub modify_port_list : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'modify_port_list');

  # Let munge_port_list do the work of converting this into the portlist array
  my $orig_plist = SNMP::Info::munge_port_list(pack("B*", '01010101'));
  my $new_plist_1    = pack("B*", '01110101');
  my $new_plist_0    = pack("B*", '01110001');
  my $expanded_plist = pack("B*", '0111000100000001');

  # This call will actually modify $orig_plist
  is($test->{info}->modify_port_list($orig_plist, 2, 1),
    $new_plist_1, 'Bit in offset position 2 changed to on');

  # Here we start with modified $orig_plist, now '01110101'
  is($test->{info}->modify_port_list($orig_plist, 5, 0),
    $new_plist_0, 'Bit in offset position 5 changed to off');

  # Modified $orig_plist, now '01110001'
  is($test->{info}->modify_port_list($orig_plist, 15, 1),
    $expanded_plist,
    'Bit in offset position 15 changed to on and portlist array expanded');
}

sub private_cache : Tests(1) {
  my $test = shift;

  # This method is covered in private_global and private_load_attr
  # tests so just cover with can() here
  can_ok($test->{info}, '_cache');
}

sub private_munge : Tests(1) {
  my $test = shift;

  # This method is covered in private_global and private_load_attr
  # tests so just cover with can() here
  can_ok($test->{info}, '_munge');
}

sub private_validate_autoload_method : Tests(8) {
  my $test = shift;

  can_ok($test->{info}, '_validate_autoload_method');

  subtest '%GLOBALS _validate_autoload_method() subtest' => sub {

    foreach my $prefix ('', 'load_', 'orig_') {
      my $test_global = "$prefix" . 'contact';
      cmp_deeply(
        $test->{info}->_validate_autoload_method("$test_global"),
        ['.1.3.6.1.2.1.1.4.0', 0],
        qq(Global '$test_global' validates)
      );
    }
    cmp_deeply(
      $test->{info}->_validate_autoload_method('set_contact'),
      ['.1.3.6.1.2.1.1.4', 0],
      q(Global 'set_contact' validates)
    );
    cmp_deeply(
      $test->{info}->_validate_autoload_method('contact_raw'),
      ['.1.3.6.1.2.1.1.4.0', 0],
      q(Global 'contact_raw' validates)
    );
  };

  # Use a leaf we don't have defined in %GLOBALS that is read/write to pass
  # all tests, we'll test access separately
  subtest 'Single instance MIB leaf _validate_autoload_method() subtest' =>
    sub {

    foreach my $prefix ('', 'load_', 'orig_') {
      my $test_global = "$prefix" . 'snmpEnableAuthenTraps';
      cmp_deeply(
        $test->{info}->_validate_autoload_method("$test_global"),
        ['.1.3.6.1.2.1.11.30.0', 0],
        qq(MIB leaf '$test_global' validates)
      );
    }
    cmp_deeply(
      $test->{info}->_validate_autoload_method('set_snmpEnableAuthenTraps'),
      ['.1.3.6.1.2.1.11.30', 0],
      q(MIB leaf 'set_snmpEnableAuthenTraps' validates)
    );
    cmp_deeply(
      $test->{info}->_validate_autoload_method('snmpEnableAuthenTraps_raw'),
      ['.1.3.6.1.2.1.11.30.0', 0],
      q(MIB leaf 'snmpEnableAuthenTraps_raw' validates)
    );
    };

  subtest '%FUNCS _validate_autoload_method() subtest' => sub {

    foreach my $prefix ('', 'load_', 'orig_') {
      my $test_global = "$prefix" . 'i_alias';
      cmp_deeply(
        $test->{info}->_validate_autoload_method("$test_global"),
        ['.1.3.6.1.2.1.31.1.1.1.18', 1],
        qq(Func '$test_global' validates)
      );
    }
    cmp_deeply(
      $test->{info}->_validate_autoload_method('set_i_alias'),
      ['.1.3.6.1.2.1.31.1.1.1.18', 1],
      q(Func 'set_i_alias' validates)
    );
    cmp_deeply(
      $test->{info}->_validate_autoload_method('i_alias_raw'),
      ['.1.3.6.1.2.1.31.1.1.1.18', 1],
      q(Func 'i_alias_raw' validates)
    );
  };

  # Use a leaf we don't have defined in %FUNCS that is read/write to pass
  # all tests, we'll test access separately
  subtest 'Table MIB leaf _validate_autoload_method() subtest' => sub {

    foreach my $prefix ('', 'load_', 'orig_') {
      my $test_global = "$prefix" . 'ifPromiscuousMode';
      cmp_deeply(
        $test->{info}->_validate_autoload_method("$test_global"),
        ['.1.3.6.1.2.1.31.1.1.1.16', 1],
        qq(Func '$test_global' validates)
      );
    }
    cmp_deeply(
      $test->{info}->_validate_autoload_method('set_ifPromiscuousMode'),
      ['.1.3.6.1.2.1.31.1.1.1.16', 1],
      q(Func 'set_ifPromiscuousMode' validates)
    );
    cmp_deeply(
      $test->{info}->_validate_autoload_method('ifPromiscuousMode_raw'),
      ['.1.3.6.1.2.1.31.1.1.1.16', 1],
      q(Func 'ifPromiscuousMode_raw' validates)
    );
  };

  is($test->{info}->_validate_autoload_method('ifStackHigherLayer'),
    undef, q(MIB leaf 'ifStackHigherLayer' not-accessible, returns undef));

  # Test that read-only leaf won't validate set_
  is($test->{info}->_validate_autoload_method('set_i_lastchange'),
    undef,
    q(Func 'i_lastchange' is read-only, 'set_i_lastchange' returns undef));

  # Check fully qualified MIB leaf w substitutions validates
  cmp_deeply(
    $test->{info}->_validate_autoload_method('IF_MIB__ifConnectorPresent'),
    ['.1.3.6.1.2.1.31.1.1.1.17', 1],
    q(Fully qualified 'IF_MIB__ifConnectorPresent' validates)
  );
}

# Prefix with private as we don't want to accidentally override in test class
sub private_can : Tests(9) {
  my $test = shift;

  # This method is heavily covered across tests, just verify here that
  # a successful call places the method in the symbol table

  # See perldoc Symbol, specifically Symbol::delete_package. We can't assume
  # symbols are deleted with the object between tests. Since we can() all
  # globals and funcs during tests use MIB leafs to test table and scalar
  # methods. The symbol_test() method is defined in My::Test::Class
  # Note: if these tests start to fail make sure we aren't using the leaf
  # in other tests

  # This leaf tests the global path SNMPv2-MIB::snmpInBadCommunityNames
  is($test->symbol_test('snmpInBadCommunityNames'),
    0, q(Method 'snmpInBadCommunityNames' is not defined in the symbol table));
  can_ok($test->{info}, 'snmpInBadCommunityNames');
  is($test->symbol_test('snmpInBadCommunityNames'),
    1, q(Method 'snmpInBadCommunityNames' is now defined in the symbol table));

  # This leaf tests the table path IF-MIB::ifCounterDiscontinuityTime
  is($test->symbol_test('ifCounterDiscontinuityTime'),
    0,
    q(Method 'ifCounterDiscontinuityTime' is not defined in the symbol table));
  can_ok($test->{info}, 'ifCounterDiscontinuityTime');
  is($test->symbol_test('ifCounterDiscontinuityTime'),
    1,
    q(Method 'ifCounterDiscontinuityTime' is now defined in the symbol table));

  # This leaf tests the set_ path SNMPv2-MIB::snmpSetSerialNo
  is($test->symbol_test('set_snmpSetSerialNo'),
    0, q(Method 'set_snmpSetSerialNo' is not defined in the symbol table));
  can_ok($test->{info}, 'set_snmpSetSerialNo');
  is($test->symbol_test('set_snmpSetSerialNo'),
    1, q(Method 'set_snmpSetSerialNo' is now defined in the symbol table));
}

# Prefix with private as we don't want to accidentally override in test class
sub private_autoload : Tests(3) {
  my $test = shift;

  # This method is covered in other tests, just verify here that
  # a successful call places the method in the symbol table. Since can() does
  # the majority of the work call a method without calling can() first. Same
  # as noted in the private_can test we need to use a leaf not used elsewhere
  # (IP-MIB::ipDefaultTTL) to make sure method isn't in the symbol table first.
  # AUTOLOAD calls the method after inserted in the symbol table, so we
  # populate cache to return some data

  # Load the cache
  my $cache_data = {'_ipDefaultTTL' => 64};
  $test->{info}->cache($cache_data);

  is($test->symbol_test('ipDefaultTTL'),
    0, q(Method 'ipDefaultTTL' is not defined in the symbol table));
  is($test->{info}->ipDefaultTTL(),
    64, q(Method 'ipDefaultTTL' called and returned expected data'));
  is($test->symbol_test('ipDefaultTTL'),
    1, q(Method 'ipDefaultTTL' is now defined in the symbol table));
}

# Prefix with private as we don't want to accidentally override in test class
sub private_destroy : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'DESTROY');
  is($test->{info}->DESTROY(), undef, 'DESTROY returns undef');
}

1;
