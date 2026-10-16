# Test::SNMP::Info::LLDP
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

package Test::SNMP::Info::LLDP;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::LLDP;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_lldp_sys_cap'           => pack("H*", '2800'),
    '_i_description'          => 1,
    '_i_alias'                => 1,
    '_lldp_rem_pid'           => 1,
    '_lldp_rman_addr'         => 1,
    '_lldp_rem_pid_type'      => 1,
    '_lldp_rem_desc'          => 1,
    '_lldp_rem_sysdesc'       => 1,
    '_lldp_rem_sysname'       => 1,
    '_lldp_rem_id_type'       => 1,
    '_lldp_rem_id'            => 1,
    '_lldp_loc_id_os'         => pack("H*", 'ABCD12345678'),
    '_lldp_loc_id_type'       => 'macAddress',
    '_lldp_rem_cap_spt'       => 1,
    '_lldp_rem_media_cap_spt' => 1,
    'store'                   => {
      'i_description' =>
        {'10' => 'GigabitEthernet0/0/6', '12' => 'GigabitEthernet0/0/8',},
      'i_alias'           => {'12'                => 'My uplink alias'},
      'lldp_rem_pid'      => {'0.6.1'             => 'Gi0/48'},
      'lldp_rman_addr'    => {'0.6.1.1.4.1.2.3.4' => 'unknown'},
      'lldp_rem_pid_type' => {'0.6.1'             => 'interfaceName'},
      'lldp_rem_desc'     => {'0.6.1'             => 'GigabitEthernet0/48'},
      'lldp_rem_sysdesc' =>
        {'0.6.1' => 'C2960 Software (C2960-LANBASEK9-M), Version 12.2(37)SE'},
      'lldp_rem_sysname'       => {'0.6.1' => 'My C2960'},
      'lldp_rem_id_type'       => {'0.6.1' => 'macAddress'},
      'lldp_rem_id'            => {'0.6.1' => pack("H*", 'ABCD12345678')},
      'lldp_rem_cap_spt'       => {'0.6.1' => pack("H*", '2800')},
      'lldp_rem_media_cap_spt' => {'0.6.1' => pack("H*", '4C')},
    }
  };
  $test->{info}->cache($cache_data);
}

# LLDP-V2-MIB rows in the shapes seen on a PAN-OS vsys capture ('0.17.1.1')
# and a live Comware 7 switch ('22612.2.1.1'), with no LLDP-MIB neighbors
sub _prime_v2 {
  my $test = shift;
  $test->{info}->clear_cache();
  $test->{info}->cache(
    { '_i_description'        => 1,
      '_lldp_v2_rem_id'       => 1,
      '_lldp_v2_rem_id_type'  => 1,
      '_lldp_v2_rem_pid'      => 1,
      '_lldp_v2_rem_pid_type' => 1,
      '_lldp_v2_rem_desc'     => 1,
      '_lldp_v2_rem_sysname'  => 1,
      '_lldp_v2_rem_sysdesc'  => 1,
      '_lldp_v2_rem_cap_spt'  => 1,
      'store'                 => {
        'i_description' => {'2' => 'GigabitEthernet1/0/1', '17' => 'ethernet1/12'},
        'lldp_v2_rem_id' => {
          '0.17.1.1'    => pack("H*", '20283e6ee311'),
          '22612.2.1.1' => pack("H*", '62bd1fc10a13'),
        },
        'lldp_v2_rem_id_type' =>
          {'0.17.1.1' => 'macAddress', '22612.2.1.1' => 'macAddress'},
        'lldp_v2_rem_pid' => {
          '0.17.1.1'    => '10GE2/4/0/7',
          '22612.2.1.1' => pack("H*", '62bd1fc10a13'),
        },
        'lldp_v2_rem_pid_type' =>
          {'0.17.1.1' => 'interfaceName', '22612.2.1.1' => 'macAddress'},
        'lldp_v2_rem_desc' =>
          {'0.17.1.1' => 'Core uplink', '22612.2.1.1' => 'eth1'},
        'lldp_v2_rem_sysname' =>
          {'0.17.1.1' => 'core-router-1', '22612.2.1.1' => 'lab-host'},
        'lldp_v2_rem_sysdesc' => {'22612.2.1.1' => 'Alpine Linux v3.20'},
        'lldp_v2_rem_cap_spt' => {'0.17.1.1' => pack("H*", '28c0')},
      }
    }
  );
  return;
}

sub _lldp_rem : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  cmp_deeply($info->_lldp_rem('lldp_rem_id'),
    {'0.6.1' => pack("H*", 'ABCD12345678')},
    q(LLDP-MIB rows pass through));

  $test->_prime_v2;
  $info->{store}{lldp_v2_rem_id}{'22612.2.2.1'} = pack("H*", '62bd1fc10a13');
  $info->{store}{lldp_v2_rem_id}{'22612.2.3.1'} = pack("H*", '62bd1fc10a13');
  cmp_deeply(
    [sort keys %{$info->_lldp_rem('lldp_rem_id')}],
    ['0.17.1.1', '22612.2.1.1', '22612.2.2.1', '22612.2.3.1'],
    q(Without lldpV2DestAddressTable every agent is kept)
  );

  $info->{'_lldp_v2_dest_mac'} = 1;
  $info->{store}{lldp_v2_dest_mac} = {
    1 => pack("H*", '0180c200000e'),
    2 => pack("H*", '0180c2000003'),
    3 => pack("H*", '0180c2000000'),
  };
  cmp_deeply(
    [sort keys %{$info->_lldp_rem('lldp_rem_id')}],
    ['0.17.1.1', '22612.2.1.1'],
    q(Only the nearest-bridge agent is kept)
  );
}

sub hasLLDP : Tests(6) {
  my $test = shift;

  can_ok($test->{info}, 'hasLLDP');
  is($test->{info}->hasLLDP(), 1, q(Has 'lldpLocSysCapEnabled' has LLDP));

  delete $test->{info}{_lldp_sys_cap};
  is($test->{info}->hasLLDP(),
    1, q(No 'lldpLocSysCapEnabled', but has neighbors, has LLDP));

  $test->{info}->clear_cache();
  is($test->{info}->hasLLDP(),
    undef, q(No 'lldpLocSysCapEnabled' and no neighbors, no LLDP undef));

  $test->{info}{'_lldp_v2_sys_cap'} = pack("H*", '2800');
  is($test->{info}->hasLLDP(), 1,
    q(Has 'lldpV2LocSysCapEnabled' has LLDP));

  $test->{info}->clear_cache();
  $test->{info}{'_lldp_v2_rem_id'} = 1;
  $test->{info}{store}{lldp_v2_rem_id}
    = {'0.17.1.1' => pack("H*", '20283e6ee311')};
  is($test->{info}->hasLLDP(), 1, q(Only LLDP-V2-MIB neighbors, has LLDP));
}

sub _lldp_source : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  is($info->_lldp_source(), 'v1', q(LLDP-MIB neighbors use LLDP-MIB));

  $info->clear_cache();
  $info->cache(
    { '_lldp_rem_id'    => 1,
      '_lldp_v2_rem_id' => 1,
      'store'           => {
        'lldp_rem_id'    => {'22612.2.1'   => pack("H*", '62bd1fc10a13')},
        'lldp_v2_rem_id' => {'22612.2.1.1' => pack("H*", '62bd1fc10a13')},
      }
    }
  );
  is($info->_lldp_source(), 'v1',
    q(Neighbors in both MIBs use LLDP-MIB only));

  $info->clear_cache();
  $info->cache(
    { '_lldp_sys_cap'   => pack("H*", '2800'),
      '_lldp_rem_id'    => 1,
      '_lldp_v2_rem_id' => 1,
      'store'           => {
        'lldp_rem_id'    => {},
        'lldp_v2_rem_id' => {'0.17.1.1' => pack("H*", '20283e6ee311')},
      }
    }
  );
  is($info->_lldp_source(), 'v2',
    q(LLDP-MIB capabilities do not block LLDP-V2-MIB neighbors));

  $info->clear_cache();
  ok(!defined $info->_lldp_source() && !exists $info->{_lldp_source},
    q(No neighbors in either MIB is not memoized));
}

sub lldp_if : Tests(6) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_if');

  # The LLDP class ISA 'SNMP::Info' but does not include %SNMP::Info::FUNCS
  # in %SNMP::Info::LLDP::FUNCS so we need to insert i_description and i_alias
  # so that we can test this method, otherwise even though values are in cache
  # the AUTOLOAD method for them won't be created
  $test->{info}{funcs}{i_description} = 'ifDescr';
  $test->{info}{funcs}{i_alias}       = 'ifAlias';

  # Method uses a partial fetch which ignores the cache and reloads data
  # therefore we must use the mocked session. Populate the session data
  # so that the mock_getnext() has data to fetch.
  my $data = {'LLDP-MIB::lldpLocPortDesc' => {6 => 'GigabitEthernet0/0/6'}};
  $test->{info}{sess}{Data} = $data;

  my $expected = {'0.6.1' => '10'};

  cmp_deeply($test->{info}->lldp_if(),
    $expected, q(Mapping of LLDP interface using 'ifDescr' has expected value));

  # Case where ifIndex isn't used as LldpPortNumber and
  # lldpLocPortDesc cross references to ifAlias. This is from a
  # Huawei VRP S5720
  # Use a different cache index to ensure different test results
  $test->{info}{store}{lldp_rem_pid} = {'5656.8.1' => 'interfaceName'};
  $data = {'LLDP-MIB::lldpLocPortDesc' => {8 => 'My uplink alias'}};
  $test->{info}{sess}{Data} = $data;

  $expected = {'5656.8.1' => '12'};

  cmp_deeply($test->{info}->lldp_if(),
    $expected, q(Mapping of LLDP interface using 'ifAlias' has expected value));

  # Default / last resort no matching ifDescr or ifAlias so assume
  # LldpPortNumber is the same as ifIndex
  # Use a different cache index to ensure different test results
  $test->{info}{store}{lldp_rem_pid} = {'0.11.1' => 'interfaceName'};
  $test->{info}{sess}{Data} = {};

  $expected = {'0.11.1' => '11'};

  cmp_deeply($test->{info}->lldp_if(),
    $expected, q(Mapping of LLDP interface using 'ifIndex' has expected value));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->lldp_if(), {}, q(No data returns empty hash));

  $test->_prime_v2;
  cmp_deeply($test->{info}->lldp_if(), {'0.17.1.1' => 17, '22612.2.1.1' => 2},
    q(LLDP-V2-MIB takes the ifIndex from the index));
}

sub lldp_ip : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_ip');

  my $expected = {'0.6.1' => '1.2.3.4'};

  cmp_deeply($test->{info}->lldp_ip(),
    $expected, q(Remote LLDP IPv4 has expected value));

  # Exchange the IPv4 address with the same IPv6 address
  $test->{info}{store}{lldp_rman_addr}
    = {'0.6.1.2.16.0.0.0.0.0.0.0.0.0.0.255.255.1.2.3.4' => 'unknown'};

  cmp_deeply($test->{info}->lldp_ip(),
    {}, q(Address format other than IPv4 returns empty hash));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->lldp_ip(), {}, q(No data returns empty hash));
}

sub lldp_ipv6 : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_ipv6');

  my $expected = {'0.6.1' => '0000:0000:0000:0000:0000:ffff:0102:0304'};

  cmp_deeply($test->{info}->lldp_ipv6(),
    {}, q(Address format other than IPv6 returns empty hash));

  # Exchange the IPv4 address with the same IPv6 address
  $test->{info}{store}{lldp_rman_addr}
    = {'0.6.1.2.16.0.0.0.0.0.0.0.0.0.0.255.255.1.2.3.4' => 'ifIndex'};

  cmp_deeply($test->{info}->lldp_ipv6(),
    $expected, q(Remote LLDP IPv6 has expected value));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->lldp_ip(), {}, q(No data returns empty hash));
}

sub lldp_mac : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_mac');

  my $expected = {'0.6.1' => '01:23:45:67:89:ab'};

  cmp_deeply($test->{info}->lldp_mac(),
    {}, q(Address format other than MAC returns empty hash));

  # Exchange the IPv4 address with MAC
  $test->{info}{store}{lldp_rman_addr}
    = {'0.6.1.6.6.01.35.69.103.137.171' => 'ifIndex'};

  cmp_deeply($test->{info}->lldp_mac(),
    $expected, q(Remote LLDP MAC has expected value));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->lldp_mac(), {}, q(No data returns empty hash));
}

# This has been really been tested in the lldp_ip, lldp_ipv6, and lldp_mac but
# tested here for completeness
sub lldp_addr : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_addr');

  $test->{info}{store}{lldp_rman_addr} = {
    '0.6.1.1.4.1.2.3.4'                              => 'unknown',
    '0.8.1.2.16.0.0.0.0.0.0.0.0.0.0.255.255.1.2.3.4' => 'ifIndex',
    '0.10.1.6.6.01.35.69.103.137.171'                => 'ifIndex'
  };

  my $expected = {
    '0.6.1'  => '1.2.3.4',
    '0.8.1'  => '0000:0000:0000:0000:0000:ffff:0102:0304',
    '0.10.1' => '01:23:45:67:89:ab',
  };

  cmp_deeply($test->{info}->lldp_addr(),
    $expected, q(Remote LLDP addresses have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->lldp_addr(), {}, q(No data returns empty hash));
}

sub lldp_port : Tests(11) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_port');

  my $expected = {'0.6.1' => 'Gi0/48'};

  cmp_deeply($test->{info}->lldp_port(),
    $expected, q(Remote port type 'interfaceName' uses 'lldpRemPortId'));

  # Default to lldpRemPortDesc by making type interfaceAlias
  $test->{info}{store}{lldp_rem_pid_type} = {'0.6.1' => 'interfaceAlias'};

  $expected = {'0.6.1' => 'GigabitEthernet0/48'};

  cmp_deeply($test->{info}->lldp_port(),
    $expected, q(Remote port type 'interfaceAlias' uses 'lldpRemPortDesc'));

  # Netgear XSM7224S - local type w/ ifName
  $test->{info}{store} = {
    lldp_rem_pid_type => {'0.11.1' => 'local'},
    lldp_rem_desc     => {'0.11.1' => ''},
    lldp_rem_pid      => {'0.11.1' => '1/0/1'},
  };

  $expected = {'0.11.1' => '1/0/1'};

  cmp_deeply($test->{info}->lldp_port(),
    $expected, q(Remote port type 'local' and 'lldpRemPortId' not digits));

  # Alcatel/Nokia - local type w/ ifIndex
  $test->{info}{store} = {
    lldp_rem_pid_type => {'0.15.1' => 'local'},
    lldp_rem_desc     => {'0.15.1' => 'My port descr'},
    lldp_rem_pid      => {'0.15.1' => '123'},
  };

  $expected = {'0.15.1' => 'My port descr'};

  cmp_deeply($test->{info}->lldp_port(),
    $expected,
    q(Remote port type 'local' and 'ifIndex' uses 'lldpRemPortDesc'));

  # MAC /w descr
  $test->{info}{store} = {
    lldp_rem_pid_type => {'0.16.1' => 'macAddress'},
    lldp_rem_desc     => {'0.16.1' => 'My mac port descr'},
    lldp_rem_pid      => {'0.16.1' => pack("H*", '12345678AB')},
  };

  $expected = {'0.16.1' => 'My mac port descr'};

  cmp_deeply($test->{info}->lldp_port(),
    $expected, q(Remote port type 'macAddress' uses 'lldpRemPortDesc'));

  # MAC w/o descr
  $test->{info}{store} = {
    lldp_rem_pid_type => {'0.16.1' => 'macAddress'},
    lldp_rem_desc     => {'0.16.1' => ''},
    lldp_rem_pid      => {'0.16.1' => pack("H*", '2345678ABCDE')},
  };

  $expected = {'0.16.1' => '23:45:67:8a:bc:de'};

  cmp_deeply($test->{info}->lldp_port(), $expected,
    q(Remote port type 'macAddress' no 'lldpRemPortDesc' uses 'lldpRemPortId'));

  # Ethernet Routing Switch single
  $test->{info}{store} = {
    lldp_rem_sysdesc  => {'0.25.1' => 'Ethernet Routing Switch 4550T-PWR'},
    lldp_rem_pid_type => {'0.25.1' => 'macAddress'},
    lldp_rem_desc     => {'0.25.1' => 'Port 50'},
    lldp_rem_pid      => {'0.25.1' => pack("H*", '2345678ABC')},
  };

  $expected = {'0.25.1' => '1.50'};

  cmp_deeply($test->{info}->lldp_port(),
    $expected, q(Remote Ethernet Routing Switch 'lldpRemPortDesc' munged));

  # Ethernet Routing Switch single
  $test->{info}{store} = {
    lldp_rem_sysdesc  => {'1.25.1' => 'Ethernet Routing Switch 4550T-PWR'},
    lldp_rem_pid_type => {'1.25.1' => 'macAddress'},
    lldp_rem_desc     => {'1.25.1' => 'Unit 2 Port 50'},
    lldp_rem_pid      => {'1.25.1' => pack("H*", '2345678ABC')},
  };

  $expected = {'1.25.1' => '2.50'};

  cmp_deeply($test->{info}->lldp_port(),
    $expected,
    q(Remote Ethernet Routing Switch stack 'lldpRemPortDesc' munged));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->lldp_port(), {}, q(No data returns empty hash));

  $test->_prime_v2;
  cmp_deeply(
    $test->{info}->lldp_port(),
    {'0.17.1.1' => '10GE2/4/0/7', '22612.2.1.1' => 'eth1'},
    q(LLDP-V2-MIB interfaceName port ID, and description over a MAC port ID)
  );
}

sub lldp_id : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_id');

  my $expected = {'0.6.1' => 'ab:cd:12:34:56:78'};

  cmp_deeply($test->{info}->lldp_id(),
    $expected, q(Remote LLDP ID type 'macAddress' has expected value));

  $test->{info}{store} = {
    lldp_rem_id_type => {'1.25.1' => 'networkAddress'},
    lldp_rem_id      => {'1.25.1' => pack("H*", '010A141E28')},
  };

  $expected = {'1.25.1' => '10.20.30.40'};

  cmp_deeply($test->{info}->lldp_id(),
    $expected, q(Remote LLDP ID type 'networkAddress' has expected value));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->lldp_id(), {}, q(No data returns empty hash));

  $test->_prime_v2;
  cmp_deeply(
    $test->{info}->lldp_id(),
    {'0.17.1.1' => '20:28:3e:6e:e3:11', '22612.2.1.1' => '62:bd:1f:c1:0a:13'},
    q(LLDP-V2-MIB chassis IDs)
  );
}

sub lldp_loc_id : Tests(2) {
  my $test = shift;
  can_ok($test->{info}, 'lldp_loc_id');


  my $expected = 'ab:cd:12:34:56:78';

  cmp_deeply($test->{info}->lldp_loc_id(),
    $expected, q(Local LLDP ID type 'macAddress' has expected value));
}



sub lldp_platform : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_platform');

  my $expected
    = {'0.6.1' => 'C2960 Software (C2960-LANBASEK9-M), Version 12.2(37)SE'};

  cmp_deeply($test->{info}->lldp_platform(),
    $expected, q(Remote platform using 'lldpRemSysDesc'));

  delete $test->{info}{_lldp_rem_sysdesc};

  $expected = {'0.6.1' => 'My C2960'};

  cmp_deeply($test->{info}->lldp_platform(),
    $expected, q(Remote platform using 'lldpRemSysName'));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->lldp_platform(), {}, q(No data returns empty hash));

  $test->_prime_v2;
  cmp_deeply(
    $test->{info}->lldp_platform(),
    {'0.17.1.1' => 'core-router-1', '22612.2.1.1' => 'Alpine Linux v3.20'},
    q(LLDP-V2-MIB platform from description, else name)
  );
}

sub lldp_cap : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_cap');

  my $expected = ['bridge', 'router'];

  my $caps = $test->{info}->lldp_cap();

  cmp_set($caps->{'0.6.1'}, $expected,
    q(Caps emumerated correctly));

  $test->{info}{store}{lldp_rem_cap_spt} = {'0.6.1' => pack("H*", '0000')};

  cmp_deeply($test->{info}->lldp_cap(), {}, q(Cap of zeros return empty hash));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->lldp_cap(), {}, q(No data returns empty hash));

  $test->_prime_v2;
  cmp_deeply(
    $test->{info}->lldp_cap(),
    {'0.17.1.1' => [qw/bridge router cVLANComponent sVLANComponent/]},
    q(LLDP-V2-MIB capability bits 8 and 9 are named)
  );
}

sub lldp_media_cap : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_media_cap');

  my $expected = {'0.6.1' => ['networkPolicy', 'extendedPD', 'inventory']};

  cmp_deeply($test->{info}->lldp_media_cap(),
    $expected, q(Caps emumerated correctly));

  $test->{info}{store}{lldp_rem_media_cap_spt}
    = {'0.6.1' => pack("H*", '0000')};

  cmp_deeply($test->{info}->lldp_media_cap(),
    {}, q(Cap of zeros return empty hash));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->lldp_media_cap(), {},
    q(No data returns empty hash));
}

1;
