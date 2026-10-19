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

sub update : Tests(10) {
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

  subtest 'update__changes_community_index__keeps_records_and_option' => sub {
    plan tests => 6;
    my $info = $test->_fresh_walk_info(_ifdescr_timeout(after => 1));
    my $mock = $test->mock_session;
    $info->incomplete_walk('undef');
    $info->i_description();

    delete $info->{args}{Session};
    ok($info->update(Community => 'public@20'), 'update() succeeds');

    # update() swaps in a real session; put the mock back, indexed as update
    # would have left the community
    $info->{sess} = $mock;
    $mock->{Community} = 'public@20';
    My::Test::Class::set_fault($mock, _ifdescr_timeout(after => 2));
    $info->load_i_description();

    my @failures = @{$info->walk_failures()};
    is(scalar @failures, 2, 'both failures survive update()');
    is($failures[0]{context}, '', 'first failure has no context');
    is($failures[1]{context}, '20', 'second failure carries the index');
    unlike(join(' ', grep { defined } map { values %{$_} } @failures),
      qr/public/, 'no outcome contains the community');
    is($info->incomplete_walk(), 'undef', 'option survives update()');
  };
}

sub bulk_order_check : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'bulk_order_check');
  subtest 'bulk_order_check__default__is_1' => sub {
    plan tests => 1;
    is($test->{info}->bulk_order_check(), 1, 'on by default');
  };
  subtest 'bulk_order_check__constructor_0__is_0' => sub {
    plan tests => 3;
    $test->teardown;
    $test->setup;
    my $info = SNMP::Info->new(
      Session => $test->mock_session, BulkOrderCheck => 0);
    is($info->bulk_order_check(), 0, 'constructor 0 turns it off');
    is($info->bulk_order_check(1), 1, 'setter turns it on');
    is($info->bulk_order_check(), 1, 'setter value sticks');
  };
  subtest 'new__bulk_options__not_passed_to_session' => sub {
    plan tests => 2;
    $test->teardown;
    $test->setup;
    my $info = SNMP::Info->new(
      DestHost => 'localhost', Version => 1, Community => 'public',
      BulkOrderCheck => 0, BulkBackoff => 0);
    ok(!exists $info->{sess}{BulkOrderCheck}, 'no BulkOrderCheck in session');
    ok(!exists $info->{sess}{BulkBackoff}, 'no BulkBackoff in session');
  };
}

sub bulk_backoff : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'bulk_backoff');
  subtest 'bulk_backoff__default__is_1' => sub {
    plan tests => 1;
    is($test->{info}->bulk_backoff(), 1, 'on by default');
  };
  subtest 'bulk_backoff__constructor_0__is_0' => sub {
    plan tests => 3;
    $test->teardown;
    $test->setup;
    my $info = SNMP::Info->new(
      Session => $test->mock_session, BulkBackoff => 0);
    is($info->bulk_backoff(), 0, 'constructor 0 turns it off');
    is($info->bulk_backoff(1), 1, 'setter turns it on');
    is($info->bulk_backoff(), 1, 'setter value sticks');
  };
}

sub walk_recovery : Tests(8) {
  my $test = shift;

  can_ok($test->{info}, '_walk_recovery');
  my $set_state = sub {
    my $info = shift;
    @{$info->_walk_recovery()}{qw(toobig_repeaters getnext failed)} = (5, 1, 2);
  };
  my $initial = {
    toobig_repeaters => undef, getnext => 0, failed => 0, slow_tables => 0,
    slow_repeaters => undef, contexts => {}, tables => {},
  };

  subtest 'walk_recovery__new_object__starts_blank' => sub {
    plan tests => 1;
    $test->teardown;
    $test->setup;
    cmp_deeply($test->{info}->_walk_recovery(), $initial, 'blank state');
  };
  subtest 'walk_recovery__clear_cache__keeps_state' => sub {
    plan tests => 1;
    my $info = $test->{info};
    $set_state->($info);
    $info->clear_cache();
    cmp_deeply($info->_walk_recovery(),
      superhashof({toobig_repeaters => 5, getnext => 1, failed => 2}), 'state unchanged');
  };
  subtest 'walk_recovery__update_same_host__keeps_state' => sub {
    plan tests => 2;
    $test->teardown;
    $test->setup;
    my $info = $test->{info};
    $set_state->($info);
    delete $info->{args}{Session};
    ok($info->update(Community => 'public@10'), 'update() succeeds');
    cmp_deeply($info->_walk_recovery(),
      superhashof({toobig_repeaters => 5, getnext => 1, failed => 2}), 'state unchanged');
  };
  subtest 'walk_recovery__update_same_new_host_twice__resets_once' => sub {
    plan tests => 3;
    $test->teardown;
    $test->setup;
    my $info = $test->{info};
    delete $info->{args}{Session};
    ok($info->update(DestHost => '192.0.2.2'), 'first update() succeeds');
    $set_state->($info);
    ok($info->update(DestHost => '192.0.2.2'), 'second update() succeeds');
    cmp_deeply($info->_walk_recovery(),
      superhashof({toobig_repeaters => 5, getnext => 1, failed => 2}), 'state kept');
  };
  subtest 'walk_recovery__update_back_to_original_host__resets' => sub {
    plan tests => 3;
    $test->teardown;
    $test->setup;
    my $info = $test->{info};
    my $original = $info->{args}{DestHost};
    delete $info->{args}{Session};
    ok($info->update(DestHost => '192.0.2.2'), 'update() to new host');
    $set_state->($info);
    ok($info->update(DestHost => $original), 'update() back');
    cmp_deeply($info->_walk_recovery(), $initial, 'state reset');
  };
  subtest 'walk_recovery__update_new_target__resets_state' => sub {
    my %changes = (
      DestHost   => '192.0.2.2',
      Version    => 1,
      RemotePort => 1161,
    );
    plan tests => scalar keys %changes;
    foreach my $key (sort keys %changes) {
      $test->teardown;
      $test->setup;
      my $info = $test->{info};
      $set_state->($info);
      delete $info->{args}{Session};
      $info->update($key => $changes{$key});
      cmp_deeply($info->_walk_recovery(), $initial, "$key change resets state");
    }
  };
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

sub specify : Tests(6) {
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

  subtest 'specify__subclass__carries_records' => sub {
    plan tests => 3;
    my $info = $test->_fresh_walk_info(_ifdescr_timeout(after => 1));
    $info->i_description();
    $info->cache({
      '_layers'      => 64,
      '_description' => 'My-Test-sysDescr',
      '_id'          => '.1.3.6.1.4.1.318'
    });
    my $sub_obj = $info->specify();
    isa_ok($sub_obj, 'SNMP::Info::Layer7::APC');
    is(scalar @{$sub_obj->walk_failures()}, 1, 'failure carried to new object');
    is($sub_obj->walk_status('i_description')->{complete},
      0, 'walk_status carried to new object');
  };

  subtest 'specify__recovery_and_options__carried_to_subclass' => sub {
    plan tests => 4;
    my $info = $test->{info};
    my $state = $info->_walk_recovery();
    @{$state}{qw(toobig_repeaters getnext failed)} = (5, 1, 2);
    $info->bulk_order_check(0);
    $info->bulk_backoff(0);
    $info->cache({
      '_layers'      => 64,
      '_description' => 'My-Test-sysDescr',
      '_id'          => '.1.3.6.1.4.1.318'
    });
    my $sub_obj = $info->specify();
    isa_ok($sub_obj, 'SNMP::Info::Layer7::APC');
    cmp_deeply($sub_obj->_walk_recovery(),
      superhashof({toobig_repeaters => 5, getnext => 1, failed => 2}), 'state carried');
    is($sub_obj->bulk_order_check(), 0, 'BulkOrderCheck carried');
    is($sub_obj->bulk_backoff(), 0, 'BulkBackoff carried');
  };
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

sub private_load_attr : Tests(19) {
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

  subtest 'walk_status__endofmibview_nosuch__complete' => sub {
    plan tests => 4;
    foreach my $method (
      qw/ifConnectorPresent ifCounterDiscontinuityTime i_octet_out64/)
    {
      is($test->{info}->walk_status($method)->{complete},
        1, "$method recorded complete");
    }

    # i_octet_out64 was walked again by a partial fetch, so its ENDOFMIBVIEW
    # walk shows only as the absence of a failure
    cmp_deeply($test->{info}->walk_failures(), [], 'no walk recorded a failure');
  };
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

sub mock_getnext_end_of_table : Tests(3) {
  my $test = shift;
  my $sess = $test->mock_session;
  $sess->{Data} = {'IF-MIB::ifDescr' => {1 => 'a', 2 => 'b', 3 => 'c'}};

  my $var = SNMP::Varbind->new(['IF-MIB::ifDescr']);
  $sess->getnext($var) for 1 .. 3;
  my $result = $sess->getnext($var);

  is($var->[0], 'unknown',
    'getnext__past_last_row__leaves_the_subtree');
  is($result, q{}, 'getnext__past_last_row__returns_defined_value');

  $var = SNMP::Varbind->new(['IF-MIB::ifDescr']);
  my $calls = 0;
  while ($calls++ < 10) {
    $sess->getnext($var);
    last if $var->[0] ne 'IF-MIB::ifDescr';
  }
  is($calls, 4, 'getnext__leaf_checked_walk__stops_after_last_row');
}

sub mock_session_faults : Tests(13) {
  my $test = shift;
  my $sess = $test->mock_session;
  my $set_fault = \&My::Test::Class::set_fault;
  my $rows = {'IF-MIB::ifDescr' => {1 => 'a', 2 => 'b', 3 => 'c'}};
  my $getnext_fault = {
    op       => 'getnext',
    leaf     => 'IF-MIB::ifDescr',
    after    => 2,
    ErrorNum => -24,
    ErrorStr => 'Timeout',
  };

  subtest
    'getnext__fault_after_two_rows__sets_ErrorNum_and_leaves_varbind' => sub {
    plan tests => 4;
    $sess->{Data}  = $rows;
    $set_fault->($sess, {
      op       => 'getnext',
      leaf     => 'IF-MIB::ifDescr',
      after    => 2,
      ErrorNum => -24,
      ErrorStr => 'Timeout',
    });
    my $var = SNMP::Varbind->new(['IF-MIB::ifDescr']);
    $sess->getnext($var);
    $sess->getnext($var);
    is($var->[1], 2, 'two rows returned');
    my $result = $sess->getnext($var);
    is($result,           undef, 'third getnext returns undef');
    is($sess->{ErrorNum}, -24,   'ErrorNum set');
    is($var->[1],         2,     'varbind left unchanged');
    };

  subtest 'getnext__loop_fault__returns_first_row_again' => sub {
    plan tests => 1;
    $sess->{Data}  = $rows;
    $set_fault->($sess, {
      op    => 'getnext',
      leaf  => 'IF-MIB::ifDescr',
      after => 2,
      loop  => 1,
    });
    my $var = SNMP::Varbind->new(['IF-MIB::ifDescr']);
    $sess->getnext($var);
    $sess->getnext($var);
    $sess->getnext($var);
    is($var->[1], 1, 'first row returned again');
  };

  subtest 'bulkwalk__no_fault__returns_sorted_varbinds' => sub {
    plan tests => 3;
    $sess->{Data} = $rows;
    $set_fault->($sess, undef);
    my $var    = SNMP::Varbind->new(['IF-MIB::ifDescr']);
    my @result = $sess->bulkwalk(0, 20, $var);
    is(scalar @{$result[0]}, 3, 'three varbinds');
    is(join(',', map { $_->[1] } @{$result[0]}), '1,2,3', 'sorted iids');
    is($sess->{ErrorNum}, 0, 'ErrorNum clear');
  };

  subtest 'bulkwalk__fault__returns_undef_with_error' => sub {
    plan tests => 2;
    $sess->{Data}  = $rows;
    $set_fault->($sess, {
      op       => 'bulkwalk',
      leaf     => 'IF-MIB::ifDescr',
      ErrorNum => 1,
      ErrorStr => '(tooBig) Response message would have been too large.',
    });
    my $var    = SNMP::Varbind->new(['IF-MIB::ifDescr']);
    my @result = $sess->bulkwalk(0, 20, $var);
    is($result[0],        undef, 'result undef');
    is($sess->{ErrorNum}, 1,     'ErrorNum set');
  };

  subtest 'get__fault__sets_ErrorNum' => sub {
    plan tests => 2;
    $sess->{Data}  = {'SNMPv2-MIB::sysName' => {0 => 'x'}};
    $set_fault->($sess, {
      op       => 'get',
      leaf     => 'SNMPv2-MIB::sysName',
      ErrorNum => -24,
      ErrorStr => 'Timeout',
    });
    my $var = SNMP::Varbind->new(['SNMPv2-MIB::sysName', 0]);
    $sess->get($var);
    is($sess->{ErrorNum}, -24, 'ErrorNum set');
    $set_fault->($sess, undef);
    $sess->get($var);
    is($sess->{ErrorNum}, 0, 'ErrorNum clear after fault removed');
  };

  subtest 'getnext__fault_cleared__next_walk_has_no_error' => sub {
    plan tests => 3;
    $sess->{Data} = $rows;
    $set_fault->($sess, {%{$getnext_fault}});
    my $var = SNMP::Varbind->new(['IF-MIB::ifDescr']);
    $sess->getnext($var) for 1 .. 3;
    $set_fault->($sess, undef);
    $var = SNMP::Varbind->new(['IF-MIB::ifDescr']);
    my @iids;
    while ($sess->getnext($var)) {
      push @iids, $var->[1];
    }
    is($sess->{ErrorNum}, 0,  'ErrorNum clear');
    is($sess->{ErrorStr}, '', 'ErrorStr clear');
    is(join(',', @iids), '1,2,3', 'all rows returned');
  };

  subtest 'getnext__second_fault_installed__counts_rows_afresh' => sub {
    plan tests => 2;
    $sess->{Data} = $rows;
    $set_fault->($sess, {%{$getnext_fault}});
    my $var = SNMP::Varbind->new(['IF-MIB::ifDescr']);
    $sess->getnext($var) for 1 .. 3;
    $set_fault->($sess, {%{$getnext_fault}});
    $var = SNMP::Varbind->new(['IF-MIB::ifDescr']);
    $sess->getnext($var);
    $sess->getnext($var);
    is($var->[1], 2, 'two rows served before second fault fires');
    is($sess->getnext($var), undef, 'third getnext faults');
  };

  subtest 'bulkwalk__any_call__logs_repeaters_and_nonincreasing' => sub {
    plan tests => 2;
    $sess->{Data} = $rows;
    $set_fault->($sess, undef);
    $sess->{NonIncreasing} = 1;
    my $var = SNMP::Varbind->new(['IF-MIB::ifDescr']);
    $sess->bulkwalk(0, 20, $var);
    cmp_deeply(
      $sess->{_bulkwalk_calls},
      [{repeaters => 20, nonincreasing => 1, leaf => 'IF-MIB::ifDescr'}],
      'call logged'
    );
    delete $sess->{NonIncreasing};
    $set_fault->($sess, undef);
    $sess->bulkwalk(0, 5, $var);
    cmp_deeply(
      $sess->{_bulkwalk_calls},
      [{repeaters => 5, nonincreasing => 0, leaf => 'IF-MIB::ifDescr'}],
      'unset NonIncreasing logged as 0'
    );
  };

  subtest 'bulkwalk__min_repeaters_fault__fails_only_at_or_above_threshold'
    => sub {
    plan tests => 4;
    $sess->{Data} = $rows;
    $set_fault->($sess, {
      op            => 'bulkwalk',
      leaf          => 'IF-MIB::ifDescr',
      min_repeaters => 10,
      ErrorNum      => 1,
      ErrorStr      => 'tooBig',
    });
    my $var    = SNMP::Varbind->new(['IF-MIB::ifDescr']);
    my @result = $sess->bulkwalk(0, 20, $var);
    is($result[0],        undef, 'repeaters 20 returns undef');
    is($sess->{ErrorNum}, 1,     'repeaters 20 sets ErrorNum');
    @result = $sess->bulkwalk(0, 5, $var);
    is(scalar @{$result[0]}, 3, 'repeaters 5 returns three rows');
    is($sess->{ErrorNum},    0, 'repeaters 5 leaves ErrorNum clear');
    };

  subtest 'bulkwalk__times_fault__succeeds_after_n_failures' => sub {
    plan tests => 4;
    $sess->{Data} = $rows;
    $set_fault->($sess, {
      op       => 'bulkwalk',
      leaf     => 'IF-MIB::ifDescr',
      times    => 2,
      ErrorNum => -24,
      ErrorStr => 'Timeout',
    });
    my $var = SNMP::Varbind->new(['IF-MIB::ifDescr']);
    my @result;
    for my $call (1 .. 2) {
      @result = $sess->bulkwalk(0, 20, $var);
      is($sess->{ErrorNum}, -24, "call $call fails");
    }
    @result = $sess->bulkwalk(0, 20, $var);
    is(scalar @{$result[0]}, 3, 'call 3 returns three rows');
    is($sess->{ErrorNum},    0, 'call 3 leaves ErrorNum clear');
  };

  subtest 'bulkwalk__out_of_order_with_nonincreasing__returns_minus_65' => sub {
    plan tests => 2;
    $sess->{Data} = $rows;
    $set_fault->($sess, {
      op           => 'bulkwalk',
      leaf         => 'IF-MIB::ifDescr',
      out_of_order => 1,
      after        => 1,
    });
    $sess->{NonIncreasing} = 1;
    my $var    = SNMP::Varbind->new(['IF-MIB::ifDescr']);
    my @result = $sess->bulkwalk(0, 20, $var);
    is($result[0],        undef, 'result undef');
    is($sess->{ErrorNum}, -65,   'ErrorNum is -65');
  };

  subtest 'bulkwalk__out_of_order_without_nonincreasing__drops_rows_silently'
    => sub {
    plan tests => 2;
    $sess->{Data} = $rows;
    $set_fault->($sess, {
      op           => 'bulkwalk',
      leaf         => 'IF-MIB::ifDescr',
      out_of_order => 1,
      after        => 1,
    });
    $sess->{NonIncreasing} = 0;
    my $var    = SNMP::Varbind->new(['IF-MIB::ifDescr']);
    my @result = $sess->bulkwalk(0, 20, $var);
    is(scalar @{$result[0]}, 1, 'only the in-order row returned');
    is($sess->{ErrorNum},    0, 'ErrorNum clear');
    };

  subtest 'set_fault__arrayref__each_fault_fires_for_its_own_op' => sub {
    plan tests => 3;
    $sess->{Data} = $rows;
    $set_fault->($sess, [
      {%{$getnext_fault}, after => 1},
      {op => 'bulkwalk', leaf => 'IF-MIB::ifDescr', ErrorNum => 1},
    ]);
    $sess->bulkwalk(0, 20, SNMP::Varbind->new(['IF-MIB::ifDescr']));
    is($sess->{ErrorNum}, 1, 'bulkwalk raises its own fault');
    my $var = SNMP::Varbind->new(['IF-MIB::ifDescr']);
    $sess->getnext($var);
    is($sess->{ErrorNum}, 0, 'first getnext answers');
    $sess->getnext($var);
    is($sess->{ErrorNum}, -24, 'second getnext raises the getnext fault');
  };
}

# Walk outcome records, see "Incomplete Walks" in SNMP::Info
my $IFDESCR_ROWS
  = {'IF-MIB::ifDescr' => {1 => 'Loopback', 2 => 'eth0', 3 => 'eth1'}};

sub _ifdescr_timeout {
  my %args = @_;
  return {
    op       => 'getnext',
    leaf     => 'IF-MIB::ifDescr',
    ErrorNum => -24,
    ErrorStr => 'Timeout',
    %args,
  };
}

# Fresh object and session state for each subtest
sub _fresh_walk_info {
  my ($test, $fault) = @_;

  # teardown clears the shared session's ErrorStr, which new() rejects
  $test->teardown;
  $test->setup;
  $test->mock_session->{Data} = {%{$IFDESCR_ROWS}};
  My::Test::Class::set_fault($test->mock_session, $fault);
  return $test->{info};
}

sub walk_status : Tests(27) {
  my $test = shift;

  can_ok($test->{info}, 'walk_status');

  subtest 'walk_status__complete_walk__records_getnext_complete' => sub {
    plan tests => 4;
    my $info = $test->_fresh_walk_info;
    cmp_deeply($info->i_description(), $IFDESCR_ROWS->{'IF-MIB::ifDescr'},
      'all three rows returned');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({
        method   => 'i_description',
        leaf     => 'IF-MIB::ifDescr',
        complete => 1,
        walk     => 'getnext',
        rows     => 3,
        reason   => undef,
        recovery => [],
        context  => '',
      }),
      'outcome records a complete getnext walk'
    );
    cmp_deeply($info->walk_failures(), [], 'no failures recorded');
    cmp_deeply([keys %{$info->walk_status()}],
      ['i_description'], 'walk_status() is keyed by method');
  };

  subtest 'walk_status__timeout_after_two_rows__records_incomplete' => sub {
    plan tests => 4;
    my $info = $test->_fresh_walk_info(_ifdescr_timeout(after => 2));
    cmp_deeply(
      $info->i_description(),
      {1 => 'Loopback', 2 => 'eth0'},
      'partial rows returned'
    );
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({
        complete => 0,
        reason   => 'timeout',
        rows     => 2,
        errornum => -24,
        error    => 'Timeout',
      }),
      'outcome records the timeout'
    );
    is(scalar @{$info->walk_failures()}, 1, 'one failure recorded');
    ok(defined $info->error(), 'error() is set');
  };

  subtest 'walk_status__timeout_on_first_row__records_incomplete_not_empty' =>
    sub {
    plan tests => 1;
    my $info = $test->_fresh_walk_info(_ifdescr_timeout(after => 0));
    $info->i_description();
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({rows => 0, complete => 0}),
      'zero rows is incomplete, not an empty table'
    );
    };

  subtest 'walk_status__timeout__not_reported_as_loop' => sub {
    plan tests => 2;
    my $info = $test->_fresh_walk_info(_ifdescr_timeout(after => 0));
    $info->i_description();
    is($info->walk_status('i_description')->{reason},
      'timeout', 'reason is timeout');
    unlike($info->error(), qr/Looping/, 'error() does not report a loop');
  };

  subtest 'walk_status__loop_detected__records_loop' => sub {
    plan tests => 1;
    my $info = $test->_fresh_walk_info(
      {op => 'getnext', leaf => 'IF-MIB::ifDescr', after => 2, loop => 1});
    $info->i_description();
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({reason => 'loop', complete => 0}),
      'outcome records the loop'
    );
  };

  subtest 'walk_status__partial_get_timeout__records_incomplete' => sub {
    plan tests => 1;
    my $info = $test->_fresh_walk_info(_ifdescr_timeout(op => 'get'));
    $info->i_description(2);
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({complete => 0, reason => 'timeout', partial => 2}),
      'partial GET timeout is incomplete'
    );
  };

  subtest 'walk_status__partial_get_timeout_bulkwalk_on__records_get' => sub {
    plan tests => 3;
    my $info = $test->_fresh_walk_info(_ifdescr_timeout(op => 'get'));
    $info->bulkwalk(1);
    $test->mock_session->clear();
    is($info->i_description(2), undef, 'returns undef as before');
    ok(!$test->mock_session->called('bulkwalk'),
      '... without a bulkwalk after the failed GET');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({
        complete => 0,
        reason   => 'timeout',
        walk     => 'get',
        errornum => -24,
        error    => 'Timeout',
        partial  => 2,
      }),
      'outcome records the GET that failed'
    );
  };

  subtest 'walk_status__v1_nosuchname_past_last_row__complete' => sub {
    plan tests => 2;
    my $info = $test->_fresh_walk_info(
      _ifdescr_timeout(
        after    => 3,
        ErrorNum => 2,
        ErrorStr => '(noSuchName) There is no such variable name in this MIB.'
      )
    );
    $info->{snmp_ver} = 1;
    cmp_deeply($info->i_description(), $IFDESCR_ROWS->{'IF-MIB::ifDescr'},
      'all three rows returned');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({complete => 1, reason => undef, rows => 3}),
      'SNMPv1 noSuchName ends the walk as complete'
    );
  };

  subtest 'walk_status__bulkwalk_complete__records_repeaters' => sub {
    plan tests => 2;
    my $info = $test->_fresh_walk_info;
    $info->bulkwalk(1);
    cmp_deeply($info->i_description(), $IFDESCR_ROWS->{'IF-MIB::ifDescr'},
      'all three rows returned');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({
        walk      => 'bulkwalk',
        repeaters => 20,
        complete  => 1,
        rows      => 3,
      }),
      'outcome records a complete bulkwalk'
    );
  };

  my %bulkwalk_faults = (
    toobig        => [1,   'Response message would have been too big'],
    nonincreasing => [-65, 'OID not increasing'],
    timeout       => [-24, 'Timeout'],
  );
  foreach my $reason (sort keys %bulkwalk_faults) {
    my ($errornum, $errorstr) = @{$bulkwalk_faults{$reason}};
    subtest "walk_status__bulkwalk_${reason}__records_${reason}" => sub {
      plan tests => 3;
      my $info = $test->_fresh_walk_info(
        _ifdescr_timeout(
          op       => 'bulkwalk',
          ErrorNum => $errornum,
          ErrorStr => $errorstr
        )
      );
      $info->bulkwalk(1);

      # With the checks on, these are recovered (bulk_order_recovery and
      # bulk_backoff_recovery)
      $info->bulk_order_check(0) if $reason eq 'nonincreasing';
      $info->bulk_backoff(0);
      is($info->i_description(), undef, 'returns undef');
      ok(!exists $info->{_i_description}, '... and caches nothing');
      cmp_deeply(
        $info->walk_status('i_description'),
        superhashof({
          complete  => 0,
          reason    => $reason,
          walk      => 'bulkwalk',
          errornum  => $errornum,
          error     => $errorstr,
          repeaters => 20,
        }),
        "outcome records $reason"
      );
    };
  }

  subtest 'walk_status__bulkwalk_unknown_objid__complete_absent' => sub {
    plan tests => 4;
    my $info = $test->_fresh_walk_info(
      _ifdescr_timeout(
        op       => 'bulkwalk',
        ErrorNum => -58,
        ErrorStr => 'Unknown object identifier'
      )
    );
    $info->bulkwalk(1);
    is($info->i_description(), undef, 'returns undef');
    ok(!exists $info->{_i_description}, '... and caches nothing');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({complete => 1, reason => 'absent', walk => 'bulkwalk'}),
      'outcome is complete and absent'
    );
    cmp_deeply($info->walk_failures(), [], 'no failure recorded');
  };

  subtest 'walk_status__bulkwalk_nosuchname__complete' => sub {
    plan tests => 4;
    my $info = $test->_fresh_walk_info(
      _ifdescr_timeout(
        op       => 'bulkwalk',
        ErrorNum => 2,
        ErrorStr => '(noSuchName) There is no such variable name in this MIB.'
      )
    );
    $info->bulkwalk(1);
    is($info->i_description(), undef, 'returns undef as before');
    ok(!exists $info->{_i_description}, '... and caches nothing');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({complete => 1, reason => undef, walk => 'bulkwalk'}),
      'noSuchName on GETBULK is complete'
    );
    cmp_deeply($info->walk_failures(), [], 'no failure recorded');
  };

  subtest 'walk_status__bulkwalk_repeaters_option__recorded' => sub {
    plan tests => 1;
    my $info = $test->_fresh_walk_info;
    $info->bulkwalk(1);
    $info->{BulkRepeaters} = 7;
    $info->i_description();
    is($info->walk_status('i_description')->{repeaters},
      7, 'BulkRepeaters is recorded');
  };

  subtest 'walk_status__clear_cache__keeps_records' => sub {
    plan tests => 2;
    my $info = $test->_fresh_walk_info(_ifdescr_timeout(after => 1));
    $info->i_description();
    $info->clear_cache();
    is($info->walk_status('i_description')->{complete},
      0, 'walk_status survives clear_cache()');
    is(scalar @{$info->walk_failures()},
      1, 'walk_failures survives clear_cache()');
  };

  subtest 'walk_status__v3_context__recorded' => sub {
    plan tests => 1;
    my $info = $test->_fresh_walk_info;
    my $mock = $test->mock_session;
    $mock->{Version} = 3;
    $mock->{Context} = 'vlan-30';
    $info->i_description();
    is($info->walk_status('i_description')->{context},
      'vlan-30', 'SNMPv3 Context is recorded');
  };

  my @community_contexts = (
    ['vlan_index',            'public',    'public@20',    '20'],
    ['vrf_name',              'public',    'public@MGMT',  'MGMT'],
    ['base_with_at',          'pa@ssw0rd', 'pa@ssw0rd',    ''],
    ['base_with_at_reindexed', 'pa@ss',    'pa@ss@20',     '20'],
    ['other_community',       'public',    'other@20',     ''],
  );
  foreach my $case (@community_contexts) {
    my ($name, $base, $current, $want) = @{$case};
    subtest "walk_status__community_${name}__context_is_${\ ($want || 'empty')}"
      => sub {
      plan tests => 2;
      my $info = $test->_fresh_community_info($base, $current);
      $info->i_description();
      my $outcome = $info->walk_status('i_description');
      is($outcome->{context}, $want, "context for $current is '$want'");
      ok(!grep({ defined && index($_, $base) >= 0 } values %{$outcome}),
        'no outcome field contains the base community');
      };
  }

  subtest 'walk_status__v3_no_context__community_index_ignored' => sub {
    plan tests => 1;
    my $info = $test->_fresh_community_info('public', 'public@20');
    $test->mock_session->{Version} = 3;
    $info->i_description();
    is($info->walk_status('i_description')->{context},
      '', 'SNMPv3 without Context records no context');
  };

  subtest 'walk_status__v2c_nosuchname_past_last_row__complete' => sub {
    plan tests => 3;
    my $info = $test->_fresh_walk_info(
      _ifdescr_timeout(
        after    => 3,
        ErrorNum => 2,
        ErrorStr => '(noSuchName) There is no such variable name in this MIB.'
      )
    );
    cmp_deeply($info->i_description(), $IFDESCR_ROWS->{'IF-MIB::ifDescr'},
      'all three rows returned');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({complete => 1, reason => undef, rows => 3, errornum => 0}),
      'SNMPv2c noSuchName ends the walk as complete'
    );
    cmp_deeply($info->walk_failures(), [], 'no failure recorded');
  };

  subtest 'walk_status__v2c_generr_past_last_row__incomplete' => sub {
    plan tests => 3;
    my $info = $test->_fresh_walk_info(
      _ifdescr_timeout(
        after    => 3,
        ErrorNum => 5,
        ErrorStr => '(genErr) A general failure occured'
      )
    );
    cmp_deeply($info->i_description(), $IFDESCR_ROWS->{'IF-MIB::ifDescr'},
      'all three rows returned');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({complete => 0, reason => 'error', errornum => 5}),
      'genErr ends the walk as incomplete'
    );
    is(scalar @{$info->walk_failures()}, 1, 'one failure recorded');
  };

  subtest 'walk_status__v2c_partial_get_nosuchname__undef_complete' => sub {
    plan tests => 4;
    my $info = $test->_fresh_walk_info(
      _ifdescr_timeout(
        op       => 'get',
        ErrorNum => 2,
        ErrorStr => '(noSuchName) There is no such variable name in this MIB.'
      )
    );
    $test->mock_session->clear();
    is($info->i_description(2), undef, 'returns undef as before');
    ok(!$test->mock_session->called('getnext'),
      '... without walking after the GET');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({complete => 1, reason => undef, walk => 'get'}),
      'SNMPv2c noSuchName on the GET is complete'
    );
    cmp_deeply($info->walk_failures(), [], 'no failure recorded');
  };
}

# Fresh object constructed with the base community, on a session whose
# community is currently the indexed one
sub _fresh_community_info {
  my ($test, $base, $current) = @_;
  my $info = $test->_fresh_walk_info;
  my $mock = $test->mock_session;
  $mock->{Community} = $current;
  $test->{info} = $test->class->new(%{$info->{args}},
    Community => $base, Session => $mock);
  return $test->{info};
}

sub incomplete_walk : Tests(7) {
  my $test = shift;

  can_ok($test->{info}, 'incomplete_walk');

  subtest 'incomplete_walk__default__is_partial' => sub {
    plan tests => 3;
    my $info = $test->_fresh_walk_info;
    is($info->incomplete_walk(), 'partial', 'unset reads as partial');
    is($info->incomplete_walk('undef'), 'undef', 'setter returns new value');
    is($info->incomplete_walk('bogus'), 'partial',
      'unknown value is treated as partial');
  };

  subtest 'incomplete_walk__undef_mode_timeout__returns_undef_not_cached' =>
    sub {
    plan tests => 4;
    my $info = $test->_fresh_walk_info(_ifdescr_timeout(after => 2));
    $info->incomplete_walk('undef');
    is($info->i_description(), undef, 'returns undef');
    ok(!exists $info->{_i_description}, 'nothing cached');
    is($info->walk_status('i_description')->{rows}, 2, 'outcome records rows');
    is(scalar @{$info->walk_failures()}, 1, 'failure recorded');
  };

  subtest 'incomplete_walk__undef_mode_bulkwalk_loop__returns_undef_not_cached'
    => sub {
    plan tests => 4;
    my $info = $test->_fresh_walk_info(
      {op => 'bulkwalk', leaf => 'IF-MIB::ifDescr', after => 2, loop => 1});
    $info->bulkwalk(1);
    $info->incomplete_walk('undef');
    is($info->i_description(), undef, 'returns undef');
    ok(!exists $info->{_i_description}, 'nothing cached');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof(
        {complete => 0, reason => 'loop', walk => 'bulkwalk', rows => 2}),
      'outcome records the bulkwalk loop'
    );
    is(scalar @{$info->walk_failures()}, 1, 'failure recorded');
    };

  subtest 'incomplete_walk__undef_mode_getnext_loop__returns_undef_not_cached'
    => sub {
    plan tests => 4;
    my $info = $test->_fresh_walk_info(
      {op => 'getnext', leaf => 'IF-MIB::ifDescr', after => 2, loop => 1});
    $info->incomplete_walk('undef');
    is($info->i_description(), undef, 'returns undef');
    ok(!exists $info->{_i_description}, 'nothing cached');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof(
        {complete => 0, reason => 'loop', walk => 'getnext', rows => 2}),
      'outcome records the getnext loop'
    );
    is(scalar @{$info->walk_failures()}, 1, 'failure recorded');
    };

  subtest 'incomplete_walk__partial_mode_timeout__returns_and_caches_partial'
    => sub {
    plan tests => 2;
    my $info = $test->_fresh_walk_info(_ifdescr_timeout(after => 2));
    $info->incomplete_walk('partial');
    cmp_deeply($info->i_description(),
      {1 => 'Loopback', 2 => 'eth0'}, 'partial rows returned');
    ok(exists $info->{_i_description}, 'partial rows cached');
  };

  subtest 'incomplete_walk__undef_mode_complete__unchanged' => sub {
    plan tests => 2;
    my $info = $test->_fresh_walk_info;
    $info->incomplete_walk('undef');
    cmp_deeply($info->i_description(), $IFDESCR_ROWS->{'IF-MIB::ifDescr'},
      'all rows returned');
    ok(exists $info->{_i_description}, 'rows cached');
  };
}

sub walk_failures : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'walk_failures');

  subtest 'walk_failures__retry_succeeds__failure_sticks' => sub {
    plan tests => 3;
    my $info = $test->_fresh_walk_info(_ifdescr_timeout(after => 1));
    $info->i_description();
    My::Test::Class::set_fault($test->mock_session, undef);
    $info->load_i_description();
    is($info->walk_status('i_description')->{complete},
      1, 'walk_status shows the latest success');
    is(scalar @{$info->walk_failures()}, 1, 'failure still recorded');
    is($info->walk_failures()->[0]{reason}, 'timeout', '... as a timeout');
  };
}

sub clear_walk_status : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'clear_walk_status');

  subtest 'clear_walk_status__after_failure__empties_both' => sub {
    plan tests => 2;
    my $info = $test->_fresh_walk_info(_ifdescr_timeout(after => 1));
    $info->i_description();
    $info->clear_walk_status();
    cmp_deeply($info->walk_status(),   {}, 'walk_status emptied');
    cmp_deeply($info->walk_failures(), [], 'walk_failures emptied');
  };
}

# More IF-MIB tables, for tests that walk several tables on one connection
my $MORE_IF_ROWS = {
  'IF-MIB::ifName'  => {1 => 'lo', 2 => 'e0', 3 => 'e1'},
  'IF-MIB::ifAlias' => {1 => 'loop', 2 => 'uplink', 3 => 'downlink'},
  'IF-MIB::ifMtu'   => {1 => 65536, 2 => 1500, 3 => 1500},
};

sub _out_of_order_info {
  my ($test, %args) = @_;
  my $info = $test->_fresh_walk_info({
    op           => 'bulkwalk',
    leaf         => 'IF-MIB::ifDescr',
    out_of_order => 1,
    after        => 1,
  });
  $info->bulkwalk(1);
  $info->bulk_order_check($args{check}) if defined $args{check};
  $test->mock_session->{NonIncreasing} = $args{nonincreasing}
    if defined $args{nonincreasing};
  return $info;
}

sub bulk_order_recovery : Tests(9) {
  my $test = shift;
  my $out_of_order_step = {
    walk      => 'bulkwalk',
    repeaters => 20,
    reason    => 'nonincreasing',
    errornum  => -65,
  };

  subtest 'bulk_order__out_of_order_agent__rewalks_with_getnext' => sub {
    plan tests => 4;
    my $info = $test->_out_of_order_info;
    cmp_deeply($info->i_description(), $IFDESCR_ROWS->{'IF-MIB::ifDescr'},
      'all three rows returned');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({
        complete  => 1,
        reason    => undef,
        errornum  => 0,
        error     => undef,
        rows      => 3,
        walk      => 'getnext',
        repeaters => undef,
        recovery  => [$out_of_order_step],
      }),
      'outcome records the GETNEXT re-walk with the failure cleared'
    );
    cmp_deeply($info->_walk_recovery(),
      superhashof({getnext => 0, failed => 1}),
      'connection not switched to GETNEXT');
    cmp_deeply(
      $info->_walk_table({qual_leaf => 'IF-MIB::ifDescr'}),
      superhashof({getnext => 1}),
      'ifDescr table switched to GETNEXT'
    );
  };

  subtest
    'bulk_order__bulkwalk_call__forces_nonincreasing_and_restores_callers_value'
    => sub {
    plan tests => 4;
    foreach my $callers_value (0, 1) {
      my $info = $test->_out_of_order_info(nonincreasing => $callers_value);
      my $sess = $test->mock_session;
      $info->i_description();
      is($sess->{_bulkwalk_calls}[0]{nonincreasing},
        1, "caller value $callers_value: bulkwalk sent NonIncreasing 1");
      is($sess->{NonIncreasing}, $callers_value,
        "caller value $callers_value: restored after the walk");
    }
    };

  subtest 'bulk_order__second_table_after_switch__still_bulkwalks' => sub {
    plan tests => 2;
    my $info = $test->_out_of_order_info;
    my $sess = $test->mock_session;
    $info->i_description();
    $info->i_mtu();
    cmp_deeply($test->_bulkwalk_repeaters, [20, 20], 'second table bulkwalks');
    cmp_deeply(
      $info->walk_status('i_mtu'),
      superhashof({walk => 'bulkwalk', recovery => []}),
      'second table walked by bulkwalk with no recovery'
    );
  };

  subtest 'bulk_order__two_hashed_tables__each_pays_once' => sub {
    plan tests => 5;
    my $info = $test->_out_of_order_info;
    my $sess = $test->mock_session;
    $sess->{Data} = {%{$IFDESCR_ROWS}, %{$MORE_IF_ROWS}};
    My::Test::Class::set_fault(
      $sess,
      [
        {op => 'bulkwalk', leaf => 'IF-MIB::ifDescr', out_of_order => 1,
          after => 1},
        {op => 'bulkwalk', leaf => 'IF-MIB::ifName', out_of_order => 1,
          after => 1},
      ]
    );
    $info->i_description();
    $info->i_name();
    $info->i_mtu();
    cmp_deeply($test->_bulkwalk_repeaters, [20, 20, 20],
      'one bulkwalk per table');
    foreach my $method (qw(i_description i_name)) {
      cmp_deeply(
        $info->walk_status($method),
        superhashof({walk => 'getnext', recovery => [$out_of_order_step]}),
        "$method re-walked by GETNEXT after one step"
      );
    }
    cmp_deeply(
      $info->walk_status('i_mtu'),
      superhashof({walk => 'bulkwalk', recovery => []}),
      'i_mtu bulkwalked'
    );
    cmp_deeply($info->_walk_recovery(), superhashof({failed => 2}),
      'two failures counted');
  };

  subtest 'bulk_order__hashed_table__rewalked_by_getnext_in_next_context'
    => sub {
    plan tests => 2;
    my $info = $test->_out_of_order_info;
    my $sess = $test->mock_session;
    $info->i_description();
    my $calls_before = scalar @{$sess->{_bulkwalk_calls} || []};
    $sess->{Community} = 'public@20';
    $info->clear_cache;
    $info->i_description();
    is(scalar @{$sess->{_bulkwalk_calls} || []},
      $calls_before, 'no new bulkwalk call in the next context');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({walk => 'getnext', recovery => []}),
      'table walked by GETNEXT with no recovery'
    );
  };

  subtest 'bulk_order__partial_fetch_out_of_order__rewalks_from_partial' =>
    sub {
    plan tests => 2;
    my $info = $test->_out_of_order_info;
    $test->mock_session->{Data} = {
      'IF-MIB::ifDescr' => {
        1     => 'x',
        2     => 'NOSUCHINSTANCE',
        '2.1' => 'a',
        '2.2' => 'b',
        3     => 'c',
      }
    };
    cmp_deeply($info->i_description(2), {'2.1' => 'a', '2.2' => 'b'},
      'rows under the partial returned');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({
        complete => 1,
        partial  => 2,
        walk     => 'getnext',
        rows     => 2,
        recovery => [$out_of_order_step],
      }),
      'outcome records the GETNEXT re-walk of the partial'
    );
    };

  subtest 'bulk_order__out_of_order_at_two_failures__reaches_cap' => sub {
    plan tests => 4;
    my $info = $test->_backoff_info(min_repeaters => 6);
    my $sess = $test->mock_session;
    $info->i_description();
    My::Test::Class::set_fault($sess, {
      op => 'bulkwalk', leaf => 'IF-MIB::ifName', out_of_order => 1,
      after => 1});
    cmp_deeply($info->i_name(), $MORE_IF_ROWS->{'IF-MIB::ifName'},
      'second table rows returned by GETNEXT');
    cmp_deeply(
      $info->walk_status('i_name'),
      superhashof({
        walk     => 'getnext',
        recovery => [{%{$out_of_order_step}, repeaters => 5}],
      }),
      'second table records the out-of-order step at 5'
    );
    cmp_deeply($info->_walk_recovery(),
      superhashof({toobig_repeaters => 5, getnext => 1, failed => 3}),
      'third failure reaches the cap');
    My::Test::Class::set_fault($sess, undef);
    $info->i_alias();
    cmp_deeply($test->_bulkwalk_repeaters, [], 'third table: no bulkwalk');
  };

  subtest 'bulk_order__check_off__keeps_todays_silent_drop' => sub {
    plan tests => 2;
    my $info = $test->_out_of_order_info(check => 0, nonincreasing => 0);
    is(scalar keys %{$info->i_description() || {}},
      1, 'only the in-order row returned');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({complete => 1, walk => 'bulkwalk'}),
      'outcome cannot see the dropped rows'
    );
  };

  subtest 'bulk_order__check_off_caller_nonincreasing__keeps_todays_failure'
    => sub {
    plan tests => 2;
    my $info = $test->_out_of_order_info(check => 0, nonincreasing => 1);
    is($info->i_description(), undef, 'returns undef');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({
        reason   => 'nonincreasing',
        complete => 0,
        recovery => [],
      }),
      'outcome records the failure without recovery'
    );
    };
}

sub _backoff_info {
  my ($test, %fault) = @_;
  my $info = $test->_fresh_walk_info({
    op       => 'bulkwalk',
    leaf     => 'IF-MIB::ifDescr',
    ErrorNum => 1,
    ErrorStr => 'Response message would have been too big',
    %fault,
  });
  $test->mock_session->{Data} = {%{$IFDESCR_ROWS}, %{$MORE_IF_ROWS}};
  $info->bulkwalk(1);
  return $info;
}

sub _bulkwalk_repeaters {
  my $test = shift;
  return [map { $_->{repeaters} }
      @{$test->mock_session->{_bulkwalk_calls} || []}];
}

sub _backoff_step {
  my ($repeaters, $reason) = @_;
  my %errornum = (toobig => 1, timeout => -24);
  return {
    walk      => 'bulkwalk',
    repeaters => $repeaters,
    reason    => $reason,
    errornum  => $errornum{$reason},
  };
}

# A bulkwalk timeout and a GETNEXT timeout on each leaf: the target never
# answers
sub _unreachable_info {
  my ($test, @leaves) = @_;
  my $info = $test->_backoff_info;
  My::Test::Class::set_fault($test->mock_session, [
    map {
      ( _ifdescr_timeout(op => 'bulkwalk', leaf => $_),
        _ifdescr_timeout(leaf => $_))
    } @leaves
  ]);
  return $info;
}

sub bulk_backoff_recovery : Tests(21) {
  my $test = shift;

  subtest 'bulk_backoff__toobig_above_5__succeeds_at_5' => sub {
    plan tests => 4;
    my $info = $test->_backoff_info(min_repeaters => 6);
    cmp_deeply($info->i_description(), $IFDESCR_ROWS->{'IF-MIB::ifDescr'},
      'all three rows returned');
    cmp_deeply($test->_bulkwalk_repeaters, [20, 10, 5],
      'repeaters halved down to 5');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({
        walk      => 'bulkwalk',
        repeaters => 5,
        complete  => 1,
        recovery  =>
          [_backoff_step(20, 'toobig'), _backoff_step(10, 'toobig')],
      }),
      'outcome records the backed-off bulkwalk'
    );
    cmp_deeply($info->_walk_recovery(),
      superhashof({toobig_repeaters => 5, failed => 2, getnext => 0}),
      'connection keeps the lowered value');
  };

  subtest 'bulk_backoff__lowered_value__sticks_for_next_table' => sub {
    plan tests => 2;
    my $info = $test->_backoff_info(min_repeaters => 6);
    $info->i_description();
    My::Test::Class::set_fault($test->mock_session, undef);
    $info->i_name();
    cmp_deeply($test->_bulkwalk_repeaters, [5],
      'next table starts at the lowered value');
    cmp_deeply(
      $info->walk_status('i_name'),
      superhashof({walk => 'bulkwalk', repeaters => 5, recovery => []}),
      'next table records the lowered value without recovery'
    );
  };

  subtest 'bulk_backoff__timeout_every_call__ends_on_getnext_after_three' =>
    sub {
    plan tests => 5;
    my $info = $test->_backoff_info(ErrorNum => -24, ErrorStr => 'Timeout');
    cmp_deeply($info->i_description(), $IFDESCR_ROWS->{'IF-MIB::ifDescr'},
      'all three rows returned by GETNEXT');
    cmp_deeply($test->_bulkwalk_repeaters, [20, 10, 5],
      'three bulkwalks tried');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({
        walk      => 'getnext',
        repeaters => undef,
        complete  => 1,
        recovery  => [map { _backoff_step($_, 'timeout') } 20, 10, 5],
      }),
      'outcome records three timeouts then GETNEXT'
    );
    cmp_deeply($info->_walk_recovery(),
      superhashof({getnext => 0, failed => 3}),
      'connection not switched to GETNEXT');
    cmp_deeply($info->_walk_table({qual_leaf => 'IF-MIB::ifDescr'}),
      superhashof({getnext => 1}), 'the timed-out table uses GETNEXT');
    };

  subtest 'bulk_backoff__slow_agent__probes_once_then_backs_off' => sub {
    plan tests => 5;
    my $info = $test->_backoff_info(
      min_repeaters => 11,
      ErrorNum      => -24,
      ErrorStr      => 'Timeout'
    );
    my $sess = $test->mock_session;
    $sess->clear();
    cmp_deeply($info->i_description(), $IFDESCR_ROWS->{'IF-MIB::ifDescr'},
      'all three rows returned');
    cmp_deeply([map { scalar $sess->call_pos($_) } 1 .. 4],
      ['bulkwalk', 'getnext', 'bulkwalk', undef],
      'one GETNEXT probe between the timeout and the retry');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({
        walk      => 'bulkwalk',
        repeaters => 10,
        complete  => 1,
        recovery  => [_backoff_step(20, 'timeout')],
      }),
      'outcome records the backed-off bulkwalk'
    );
    cmp_deeply($info->_walk_recovery(),
      superhashof({toobig_repeaters => undef, getnext => 0, failed => 1}),
      'connection keeps no lowered value');
    cmp_deeply($info->_walk_table({qual_leaf => 'IF-MIB::ifDescr'}),
      superhashof({repeaters => 10}), 'the table keeps the lowered value');
  };

  subtest 'bulk_backoff__unreachable_target__records_timeout_without_recovery'
    => sub {
    plan tests => 5;
    my $info = $test->_unreachable_info('IF-MIB::ifDescr');
    is($info->i_description(), undef, 'returns undef');
    ok(!exists $info->{_i_description}, 'nothing cached');
    cmp_deeply($test->_bulkwalk_repeaters, [20], 'one bulkwalk tried');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({
        complete  => 0,
        reason    => 'timeout',
        errornum  => -24,
        walk      => 'bulkwalk',
        repeaters => 20,
        recovery  => [],
      }),
      'outcome records the bulkwalk timeout without recovery'
    );
    cmp_deeply($info->_walk_recovery(),
      superhashof({failed => 0, contexts => {'' => 1}}),
      'the context is marked unreachable, not counted as failed');
    };

  subtest 'bulk_backoff__unreachable_context__later_tables_skip_bulkwalk_and_probe'
    => sub {
    plan tests => 4;
    my $info = $test->_unreachable_info(
      map {"IF-MIB::$_"} qw(ifDescr ifName));
    my $sess = $test->mock_session;
    $sess->{Community} = 'public@20';
    $info->i_description();
    $sess->clear();
    $info->i_name();
    cmp_deeply($test->_bulkwalk_repeaters, [20],
      'only the first table bulkwalked');
    cmp_deeply([map { scalar $sess->call_pos($_) } 1 .. 2],
      ['getnext', undef], 'the second table sent one GETNEXT, no probe');
    cmp_deeply(
      $info->walk_status('i_name'),
      superhashof({
        complete => 0,
        reason   => 'timeout',
        walk     => 'getnext',
        recovery => [],
        context  => '20',
      }),
      'outcome records the GETNEXT timeout'
    );
    cmp_deeply($info->_walk_recovery(),
      superhashof({failed => 0, contexts => {'20' => 1}}),
      'nothing counted against the connection');
    };

  subtest 'bulk_backoff__unreachable_context__other_context_still_bulkwalks'
    => sub {
    plan tests => 3;
    my $info = $test->_unreachable_info(
      map {"IF-MIB::$_"} qw(ifDescr ifName));
    my $sess = $test->mock_session;
    $sess->{Community} = 'public@20';
    $info->i_description();
    $info->i_name();
    $sess->{Community} = 'public';
    My::Test::Class::set_fault($sess, undef);
    $info->clear_cache;
    cmp_deeply($info->i_mtu(), $MORE_IF_ROWS->{'IF-MIB::ifMtu'},
      'rows returned in the live context');
    cmp_deeply($test->_bulkwalk_repeaters, [20],
      'one bulkwalk at 20');
    cmp_deeply(
      $info->walk_status('i_mtu'),
      superhashof({complete => 1, walk => 'bulkwalk', context => ''}),
      'outcome records a complete bulkwalk'
    );
    };

  subtest 'bulk_backoff__ten_unreachable_contexts__backstop_untouched' => sub {
    plan tests => 3;
    my $info = $test->_unreachable_info('IF-MIB::ifDescr');
    my $sess = $test->mock_session;
    foreach my $vlan (1 .. 10) {
      $sess->{Community} = "public\@$vlan";
      My::Test::Class::set_fault($sess, $sess->{Fault});
      $info->clear_cache;
      $info->i_description();
    }
    cmp_deeply($info->_walk_recovery(),
      superhashof({failed => 0, getnext => 0}), 'backstop untouched');
    cmp_deeply($test->_bulkwalk_repeaters, [20],
      'the last context tried one bulkwalk');
    cmp_deeply([sort { $a <=> $b } keys %{$info->_walk_recovery()->{contexts}}],
      [1 .. 10], 'ten contexts marked');
    };

  subtest 'bulk_backoff__recovered_walk_cut_short__returns_partial_rows' =>
    sub {
    plan tests => 3;
    my $info = $test->_backoff_info(ErrorNum => -24, ErrorStr => 'Timeout');

    # The probe's answer is the first of the three rows 'after' counts
    My::Test::Class::set_fault($test->mock_session, [
      $test->mock_session->{Fault}, _ifdescr_timeout(after => 3)]);
    cmp_deeply($info->i_description(), {1 => 'Loopback', 2 => 'eth0'},
      'rows before the GETNEXT timeout returned');
    ok(exists $info->{_i_description}, 'partial rows cached');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({
        complete  => 0,
        reason    => 'timeout',
        errornum  => -24,
        walk      => 'getnext',
        repeaters => undef,
        rows      => 2,
        recovery  => [map { _backoff_step($_, 'timeout') } 20, 10, 5],
      }),
      'outcome records the recovery and the cut-short GETNEXT walk'
    );
    };

  subtest
    'bulk_backoff__lowered_bulk_repeaters_after_toobig__starts_at_caller_value'
    => sub {
    plan tests => 2;
    my $info = $test->_backoff_info(min_repeaters => 11);
    $info->i_description();
    is($info->_walk_recovery()->{toobig_repeaters}, 10, 'toobig value learned');
    $info->{BulkRepeaters} = 6;
    My::Test::Class::set_fault($test->mock_session, undef);
    $info->i_name();
    cmp_deeply($test->_bulkwalk_repeaters, [6], 'caller value obeyed');
    };

  subtest 'bulk_backoff__table_learned_value__used_for_that_table_only' =>
    sub {
    plan tests => 1;
    my $info = $test->_backoff_info();
    My::Test::Class::set_fault($test->mock_session, undef);
    $info->_walk_table_set({qual_leaf => 'IF-MIB::ifDescr'}, repeaters => 5);
    $info->i_description();
    $info->i_name();
    cmp_deeply($test->_bulkwalk_repeaters, [5, 20],
      'learned value applies to its own table only');
    };

  subtest 'bulk_backoff__repeaters_below_floor__goes_straight_to_getnext' =>
    sub {
    plan tests => 3;
    my $info = $test->_backoff_info;
    $info->{BulkRepeaters} = 4;
    cmp_deeply($info->i_description(), $IFDESCR_ROWS->{'IF-MIB::ifDescr'},
      'all three rows returned by GETNEXT');
    cmp_deeply($test->_bulkwalk_repeaters, [4], 'one bulkwalk tried');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({
        walk      => 'getnext',
        repeaters => undef,
        recovery  => [_backoff_step(4, 'toobig')],
      }),
      'outcome records one tooBig then GETNEXT'
    );
    };

  subtest 'bulk_backoff__cap_reached_before_floor__later_tables_skip_bulkwalk'
    => sub {
    plan tests => 9;
    my $info = $test->_backoff_info(min_repeaters => 21);
    my $sess = $test->mock_session;
    $info->{BulkRepeaters} = 40;
    $info->i_description();
    cmp_deeply($test->_bulkwalk_repeaters, [40, 20],
      'table 1: tooBig at 40, then 20');
    is($info->walk_status('i_description')->{repeaters},
      20, 'table 1 bulkwalked at 20');

    My::Test::Class::set_fault($sess, {
      op => 'bulkwalk', leaf => 'IF-MIB::ifName', min_repeaters => 11,
      ErrorNum => -24, ErrorStr => 'Timeout'});
    $info->i_name();
    cmp_deeply($test->_bulkwalk_repeaters, [20, 10],
      'table 2: timeout at 20, then 10');
    is($info->walk_status('i_name')->{repeaters}, 10,
      'table 2 bulkwalked at 10');

    My::Test::Class::set_fault($sess, {
      op => 'bulkwalk', leaf => 'IF-MIB::ifAlias', min_repeaters => 6,
      ErrorNum => 1, ErrorStr => 'Response message would have been too big'});
    cmp_deeply($info->i_alias(), $MORE_IF_ROWS->{'IF-MIB::ifAlias'},
      'table 3 rows returned by GETNEXT');
    cmp_deeply($test->_bulkwalk_repeaters, [20],
      'table 3: tooBig at 20 reaches the cap');
    cmp_deeply(
      $info->walk_status('i_alias'),
      superhashof({
        walk     => 'getnext',
        recovery => [_backoff_step(20, 'toobig')],
      }),
      'table 3 walked by GETNEXT although 5 is not below the floor'
    );

    My::Test::Class::set_fault($sess, undef);
    $info->i_mtu();
    cmp_deeply($test->_bulkwalk_repeaters, [], 'table 4: no bulkwalk');
    cmp_deeply(
      $info->walk_status('i_mtu'),
      superhashof({walk => 'getnext', recovery => []}),
      'table 4 walked by GETNEXT with no recovery'
    );
    };

  subtest 'bulk_backoff__one_slow_table__others_keep_20' => sub {
    plan tests => 3;
    my $info = $test->_backoff_info(
      min_repeaters => 11, ErrorNum => -24, ErrorStr => 'Timeout');
    $info->$_() for qw(i_description i_name i_mtu);
    cmp_deeply($test->_bulkwalk_repeaters, [20, 10, 20, 20],
      'only the slow table backs off');
    for my $method (qw(i_name i_mtu)) {
      cmp_deeply(
        $info->walk_status($method),
        superhashof({repeaters => 20, recovery => []}),
        "$method bulkwalked at 20 without recovery"
      );
    }
  };

  subtest 'bulk_backoff__learned_table__reused_in_next_context' => sub {
    plan tests => 4;
    my $info = $test->_backoff_info(
      min_repeaters => 11, ErrorNum => -24, ErrorStr => 'Timeout');
    is($info->{args}{Community}, 'public', 'base community is public');
    $info->i_description();
    $test->mock_session->{Community} = 'public@20';
    $info->clear_cache;
    $test->mock_session->clear();
    $info->i_description();
    my $calls = $test->_bulkwalk_repeaters;
    is($calls->[-1], 10, 'next context starts from the learned value');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({repeaters => 10, recovery => [], context => '20'}),
      'record shows the learned value and the context'
    );
    cmp_deeply($info->_walk_recovery(),
      superhashof({toobig_repeaters => undef, getnext => 0}),
      'the connection learned nothing');
  };

  subtest 'bulk_backoff__toobig_and_timeout_tables__each_at_own_scope' => sub {
    plan tests => 4;
    my $info = $test->_backoff_info();
    My::Test::Class::set_fault($test->mock_session, [
      {op => 'bulkwalk', leaf => 'IF-MIB::ifDescr', min_repeaters => 11,
        ErrorNum => 1, ErrorStr => 'Response message would have been too big'},
      {op => 'bulkwalk', leaf => 'IF-MIB::ifName', min_repeaters => 6,
        ErrorNum => -24, ErrorStr => 'Timeout'},
    ]);
    $info->$_() for qw(i_description i_name i_mtu);
    cmp_deeply($test->_bulkwalk_repeaters, [20, 10, 10, 5, 10],
      'tooBig lowers later tables, the timeout only its table');
    is($info->_walk_recovery()->{toobig_repeaters}, 10, 'tooBig value kept');
    cmp_deeply($info->_walk_table({qual_leaf => 'IF-MIB::ifName'}),
      superhashof({repeaters => 5}), 'timed-out table keeps 5');
    cmp_deeply($info->walk_status('i_mtu'),
      superhashof({repeaters => 10, recovery => []}), 'ifMtu walked at 10');
  };

  subtest 'bulk_backoff__off__failed_bulkwalk_returns_undef_as_today' => sub {
    plan tests => 3;
    my $info = $test->_backoff_info;
    $info->bulk_backoff(0);
    is($info->i_description(), undef, 'returns undef');
    cmp_deeply($test->_bulkwalk_repeaters, [20], 'one bulkwalk tried');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({reason => 'toobig', complete => 0, recovery => []}),
      'outcome records the failure without recovery'
    );
  };

  subtest 'bulk_backoff__off_timeout__sends_no_probe' => sub {
    plan tests => 3;
    my $info = $test->_backoff_info(ErrorNum => -24, ErrorStr => 'Timeout');
    my $sess = $test->mock_session;
    $info->bulk_backoff(0);
    $sess->clear();
    is($info->i_description(), undef, 'returns undef');
    ok(!$sess->called('getnext'), 'no GETNEXT probe sent');
    cmp_deeply($info->_walk_recovery(),
      superhashof({toobig_repeaters => undef, getnext => 0, failed => 0}),
      'recovery state unchanged');
  };

  subtest 'bulk_backoff__generr__not_retried' => sub {
    plan tests => 3;
    my $info = $test->_backoff_info(
      ErrorNum => 5,
      ErrorStr => '(genErr) A general failure occured'
    );
    is($info->i_description(), undef, 'returns undef');
    cmp_deeply($test->_bulkwalk_repeaters, [20], 'one bulkwalk tried');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({reason => 'error', complete => 0, recovery => []}),
      'outcome records the error without recovery'
    );
  };

  subtest 'bulk_backoff__minus_58__not_retried' => sub {
    plan tests => 3;
    my $info = $test->_backoff_info(
      ErrorNum => -58,
      ErrorStr => 'Unknown object identifier'
    );
    is($info->i_description(), undef, 'returns undef');
    cmp_deeply($test->_bulkwalk_repeaters, [20], 'one bulkwalk tried');
    cmp_deeply(
      $info->walk_status('i_description'),
      superhashof({reason => 'absent', complete => 1, recovery => []}),
      'outcome records absent without recovery'
    );
  };

  subtest 'bulk_backoff__bulkwalk_off__never_calls_bulkwalk' => sub {
    plan tests => 2;
    my $info = $test->_backoff_info;
    $info->bulkwalk(0);
    cmp_deeply($info->i_description(), $IFDESCR_ROWS->{'IF-MIB::ifDescr'},
      'all three rows returned by GETNEXT');
    cmp_deeply($test->_bulkwalk_repeaters, [], 'no bulkwalk call logged');
  };
}

# Prefix with private as we don't want to accidentally override in test class
sub private_destroy : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'DESTROY');
  is($test->{info}->DESTROY(), undef, 'DESTROY returns undef');
}

1;
