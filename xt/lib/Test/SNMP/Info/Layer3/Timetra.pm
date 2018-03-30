# Test::SNMP::Info::Layer3::Timetra
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

package Test::SNMP::Info::Layer3::Timetra;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Timetra;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_layers'            => 79,
    '_description'       => 'TiMOS-B-6.1.R4 both/hops ALCATEL-LUCENT SAR 7705 ',
    '_id'                => '.1.3.6.1.4.1.6527.6.1.1.2.2',
    '_lldp_sys_cap'      => pack("H*", '2800'),
    '_i_description'     => 1,
    '_i_name'            => 1,
    '_lldp_rem_cap_spt'  => 1,
    '_lldp_rem_sys_cap'  => 1,
    '_lldp_rem_id_type'  => 1,
    '_lldp_rem_id'       => 1,
    '_lldp_rem_pid_type' => 1,
    '_lldp_rem_pid'      => 1,
    '_lldp_rem_desc'     => 1,
    '_lldp_rem_sysname'  => 1,
    '_lldp_rman_addr'    => 1,
    'store'              => {
      'i_description' => {
        '1'        => 'system, Loopback IP interface',
        '40108032' => '1/3/8, 10/100/Gig Ethernet SFP',
      },
      'i_name' => {'1' => 'system', '40108032' => '1/3/8',},
      'lldp_rem_cap_spt' => {'230425271.40108032.1.2' => pack("H*", '2800')},
      'lldp_rem_sys_cap' => {'230425271.40108032.1.2' => pack("H*", '2800')},
      'lldp_rem_id_type' => {'230425271.40108032.1.2' => 'macAddress'},
      'lldp_rem_id' => {'230425271.40108032.1.2' => pack("H*", '34AA99C89AA1')},
      'lldp_rem_pid_type' => {'230425271.40108032.1.2' => 'local'},
      'lldp_rem_pid'      => {'230425271.40108032.1.2' => '44072960'},
      'lldp_rem_desc'     => {'230425271.40108032.1.2' => 'Another-7705-Port'},
      'lldp_rem_sysname'  => {'230425271.40108032.1.2' => 'Another-7705'},
      'lldp_rman_addr' => {'230425271.40108032.1.2.1.4.1.2.3.4' => 'unknown'},
    }
  };
  $test->{info}->cache($cache_data);
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'nokia', q(Vendor returns 'nokia'));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'TiMOS', q(Vendor returns 'TiMOS'));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), 'B-6.1.R4', q(OS version is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No description returns undef os_ver));
}

sub model : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), '7705', q(Model uses description));

  delete $test->{info}{_description};
  is($test->{info}->model(),
    'timetra.6.1.1.2.2', q(Model partially translated id));

  $test->{info}{_id} = '.1.3.6.1.4.1.6527.1.3.1';
  is($test->{info}->model(), 'SR1', q(Model translates id));

  $test->{info}{_id} = '.100.3.6.1.4.1.6527.1.3.1';
  is($test->{info}->model(), '.100.3.6.1.4.1.6527.1.3.1', q(Model uses id));
}

sub interfaces : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'interfaces');

  my $expected = {'1' => 'system', '40108032' => '1/3/8',};

  cmp_deeply($test->{info}->interfaces(),
    $expected, q(Interface names have expected values));
}

sub lldp_if : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_if');

  my $expected = {'230425271.40108032.1.2' => '40108032',};

  cmp_deeply($test->{info}->lldp_if(),
    $expected, q(Mapping of LLDP interfaces have expected values));
}

# This test will cover that the overwritten private _lldp_addr_index function
# is working properly
sub lldp_addr : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_addr');

  my $expected = {'230425271.40108032.1.2' => '1.2.3.4'};

  cmp_deeply($test->{info}->lldp_addr(),
    $expected, q(Remote LLDP IP has expected value));

  # Exchange the IPv4 address with the same IPv6 address
  $test->{info}{store}{lldp_rman_addr}
    = {'230425271.40108032.1.2.2.16.0.0.0.0.0.0.0.0.0.0.255.255.1.2.3.4' =>
      'unknown'
    };
  $expected
    = {'230425271.40108032.1.2' => '0000:0000:0000:0000:0000:ffff:0102:0304'};

  cmp_deeply($test->{info}->lldp_ipv6(),
    $expected, q(Remote LLDP IPv6 has expected value));
}

# Example from LLDP documentation
# Used as verification that we can map essential L2 topo information
sub topo_example_test : Tests(1) {
  my $test = shift;

  # Print out a map of device ports with LLDP neighbors:
  my $interfaces = $test->{info}->interfaces();
  my $lldp_if    = $test->{info}->lldp_if();
  my $lldp_ip    = $test->{info}->lldp_ip();
  my $lldp_port  = $test->{info}->lldp_port();

  # We only have one entry/key otherwise this should be in a subtest
  foreach my $lldp_key (keys %$lldp_ip) {
    my $iid           = $lldp_if->{$lldp_key};
    my $port          = $interfaces->{$iid};
    my $neighbor      = $lldp_ip->{$lldp_key};
    my $neighbor_port = $lldp_port->{$lldp_key};

    my $string = qq(Port : $port connected to $neighbor / $neighbor_port);
    my $expected_string
      = qq(Port : 1/3/8 connected to 1.2.3.4 / Another-7705-Port);

    is($string, $expected_string,
      q(LLDP example maps device ports with LLDP neighbors));
  }
}

1;
