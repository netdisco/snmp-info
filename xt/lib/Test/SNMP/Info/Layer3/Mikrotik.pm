# Test::SNMP::Info::Layer3::Mikrotik
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

package Test::SNMP::Info::Layer3::Mikrotik;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Mikrotik;

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
    '_layers' => 78,
    '_description' => 'RouterOS CRS125-24G-1S',

    # Examples don't give the actual model in sysObjectID instead it
    # resolves to MIKROTIK-MIB::mikrotikExperimentalModule
    '_id'   => '.1.3.6.1.4.1.14988.1',
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

sub lldp_id : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_id');

  # RouterOS 7.24.5 CHR: MAC chassis IDs arrive as 17 bytes of text
  $test->{info}{'_lldp_rem_id_type'} = 1;
  $test->{info}{'_lldp_rem_id'}      = 1;
  $test->{info}{store}{lldp_rem_id_type}
    = {'0.3.1' => 'macAddress', '0.6.2' => 'macAddress', '0.7.3' => 'local'};
  $test->{info}{store}{lldp_rem_id} = {
    '0.3.1' => '0C:00:1E:5A:27:00',
    '0.6.2' => pack('H*', '001c73aefd0c'),
    '0.7.3' => 'ether2',
  };
  my $expected = {
    '0.3.1' => '0c:00:1e:5a:27:00',
    '0.6.2' => '00:1c:73:ae:fd:0c',
    '0.7.3' => 'ether2',
  };
  cmp_deeply($test->{info}->lldp_id(), $expected,
    q(Text and octet MAC chassis IDs both return formatted MACs));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->lldp_id(), {}, q(No data returns empty hash));
}

sub lldp_loc_id : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_loc_id');

  $test->{info}{'_lldp_loc_id_type'} = 'macAddress';
  $test->{info}{'_lldp_loc_id_os'}   = '0C:00:52:97:B8:00';
  is($test->{info}->lldp_loc_id(), '0c:00:52:97:b8:00',
    q(Text MAC local chassis ID returns formatted MAC));
}

sub mac : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'mac');

  # ifPhysAddress.1 is the loopback on RouterOS
  $test->{info}{'_mac'}              = pack('H*', '000000000000');
  $test->{info}{'_lldp_loc_id_type'} = 'macAddress';
  $test->{info}{'_lldp_loc_id_os'}   = '0C:00:52:97:B8:00';
  is($test->{info}->mac(), '0c:00:52:97:b8:00',
    q(LLDP chassis MAC returned instead of loopback address));

  $test->{info}{'_lldp_loc_id_os'}   = undef;
  $test->{info}{'_lldp_loc_id_type'} = undef;
  is($test->{info}->mac(), '00:00:00:00:00:00',
    q(No LLDP chassis ID falls back to ifPhysAddress.1));
}

sub c_ip : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'c_ip');

  # mt1 in the RouterOS 7.24.5 lab: mt2 (0.3.1) is managed on a VLAN
  # interface and advertises only an IPv6 link-local address; ce1 (0.6.2)
  # advertises 10.0.99.3; 0.7.3 sends no chassis ID
  my $mt2_v6 = join('.', 2, 16, 254, 128, (0) x 6, 168, 193, 171, 255, 254,
    1, 66, 84);
  $test->{info}{"_$_"} = 1
    for qw/lldp_rman_addr lldp_rem_id_type lldp_rem_id/;
  $test->{info}{store}{lldp_rman_addr} = {
    "0.3.1.$mt2_v6"       => 'ifIndex',
    '0.6.2.1.4.10.0.99.3' => 'ifIndex',
    '0.7.3.1.4.10.0.99.4' => 'ifIndex',
  };
  $test->{info}{store}{lldp_rem_id_type}
    = {'0.3.1' => 'macAddress', '0.6.2' => 'macAddress'};
  $test->{info}{store}{lldp_rem_id}
    = {'0.3.1' => '0C:00:1E:5A:27:00', '0.6.2' => '00:1C:73:AE:FD:0C'};

  my $expected
    = {'0.3.1' => '0.0.0.0', '0.6.2' => '10.0.99.3', '0.7.3' => '10.0.99.4'};
  cmp_deeply($test->{info}->c_ip(undef, ['lldp']), $expected,
    q(Neighbor with a chassis ID but no IPv4 address returns 0.0.0.0));

  # sw5 sends LLDP with no management address on ifIndex 6 and its address
  # by CDP, so the table has it; mt7 on ifIndex 7 has no address anywhere
  $test->_prime_mndp();
  my $info = $test->{info};
  $info->{"_$_"} = 1 for qw/lldp_rem_id_type lldp_rem_id lldp_rman_addr/;
  $info->{store}{lldp_rem_pid}
    = {'0.6.2' => 'Ethernet1', '0.6.9' => 'Gi0/1', '0.7.8' => 'ether1'};
  $info->{store}{lldp_rem_sysname}
    = {'0.6.2' => 'ce1', '0.6.9' => 'sw5', '0.7.8' => 'mt7'};
  $info->{store}{lldp_rem_id_type}
    = {map { $_ => 'macAddress' } qw/0.6.2 0.6.9 0.7.8/};
  $info->{store}{lldp_rem_id} = {
    '0.6.2' => '00:1C:73:AE:FD:0C',
    '0.6.9' => '00:00:5E:00:53:05',
    '0.7.8' => '0C:00:00:00:00:07',
  };
  $info->{store}{lldp_rman_addr} = {'0.6.2.1.4.10.0.99.3' => 'ifIndex'};
  $expected = {
    '0.6.2' => '10.0.99.3',
    '0.6.9' => '10.0.99.5',
    '0.7.8' => '0.0.0.0',
    3       => '10.0.99.2',
  };
  cmp_deeply($info->c_ip(undef, ['lldp', 'mndp']), $expected,
    q(LLDP neighbor without an address takes the table's, else 0.0.0.0));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->c_ip(undef, ['lldp']), {},
    q(No data returns empty hash));
}


# mt1 in the RouterOS 7.24.5 lab with mt2 sending only MNDP. mtxrNeighborTable
# also lists ce1 (index 2), which LLDP-MIB reports on ifIndex 6; index 4 has
# no IP; index 5 is a different neighbor heard only by CDP on ifIndex 6.
sub _prime_mndp {
  my $test = shift;
  my $info = $test->{info};

  $info->clear_cache();
  $info->{"_$_"} = 1 for qw/i_description i_alias lldp_rem_pid
    lldp_rem_sysname mt_nbr_ip mt_nbr_mac mt_nbr_identity mt_nbr_platform
    mt_nbr_if/;
  $info->{store} = {
    i_description    => {3 => 'ether2', 6 => 'ether5'},
    i_alias          => {},
    lldp_rem_pid     => {'0.6.2' => 'Ethernet1'},
    lldp_rem_sysname => {'0.6.2' => 'ce1'},
    mt_nbr_ip =>
      {2 => '10.0.99.3', 3 => '10.0.99.2', 4 => '0.0.0.0', 5 => '10.0.99.5'},
    mt_nbr_mac => {
      2 => pack('H*', 'aac1ab001076'),
      3 => pack('H*', 'aac1ab014254'),
      4 => pack('H*', 'aac1ab000004'),
      5 => pack('H*', '00005e005305'),
    },
    mt_nbr_identity => {2 => 'ce1',    3 => 'mt2', 4 => 'mt4', 5 => 'sw5'},
    mt_nbr_platform =>
      {2 => 'Arista', 3 => 'MikroTik', 4 => 'MikroTik', 5 => 'Cisco'},
    mt_nbr_if => {2 => 6, 3 => 3, 4 => 4, 5 => 6},
  };
}

sub hasMNDP : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'hasMNDP');

  $test->_prime_mndp();
  is($test->{info}->hasMNDP(), 1, q(Neighbor table rows return 1));

  $test->{info}->clear_cache();
  is($test->{info}->hasMNDP(), undef, q(No neighbor table returns undef));
}

sub mndp_if : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'mndp_if');

  $test->_prime_mndp();
  cmp_deeply($test->{info}->mndp_if(), {3 => 3, 5 => 6},
    q(Skips LLDP duplicates and neighbors without an IP));
  cmp_deeply($test->{info}->mndp_if(3), {3 => 3},
    q(Partial returns the one neighbor));
}

sub mndp_ip : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'mndp_ip');

  $test->_prime_mndp();
  cmp_deeply($test->{info}->mndp_ip(), {3 => '10.0.99.2', 5 => '10.0.99.5'},
    q(Neighbor addresses));
}

sub mndp_id : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'mndp_id');

  $test->_prime_mndp();
  cmp_deeply($test->{info}->mndp_id(),
    {3 => 'aa:c1:ab:01:42:54', 5 => '00:00:5e:00:53:05'},
    q(Neighbor IDs are their MAC addresses));
}

sub mndp_platform : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'mndp_platform');

  $test->_prime_mndp();
  cmp_deeply($test->{info}->mndp_platform(), {3 => 'MikroTik', 5 => 'Cisco'},
    q(Neighbor platforms));
}

sub mndp_port : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'mndp_port');
  cmp_deeply($test->{info}->mndp_port(), {}, q(No remote port in the table));
}

sub mndp_cap : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'mndp_cap');
  cmp_deeply($test->{info}->mndp_cap(), {}, q(No capabilities in the table));
}

sub model : Tests(6) {
  my $test = shift;

  can_ok($test->{info}, 'model');

  is($test->{info}->model(), 'CRS125-24G-1S',
    q(RouterOS 6 sysDescr returns the board));

  $test->{info}{'_description'}
    = 'RouterOS CCR2004-1G-12S+2XS 7.24.2 (stable)';
  is($test->{info}->model(), 'CCR2004-1G-12S+2XS',
    q(Recent RouterOS 7 sysDescr with version returns the board));

  $test->{info}{'_description'} = 'RouterOS RB5009UPr+S+ 7.19.6 (long-term)';
  is($test->{info}->model(), 'RB5009UPr+S+',
    q(Long-term channel sysDescr returns the board));

  $test->{info}{'_description'} = 'RouterOS RB 750';
  is($test->{info}->model(), 'RB 750', q(Older RB sysDescr returns the board));

  $test->{info}{'_mt_board_name'} = 'RB750Gr3';
  is($test->{info}->model(), 'RB750Gr3', q(mtxrBoardName is preferred));
}

sub _prime_gauges {
  my $test = shift;

  # RouterOS 7.24 CCR2004: whole degrees in mtxrGaugeTable
  $test->{info}{'_mt_gauge_name'}  = 1;
  $test->{info}{'_mt_gauge_value'} = 1;
  $test->{info}{store}{mt_gauge_name} = {
    17   => 'cpu-temperature',
    7001 => 'fan1-speed',
    7101 => 'board-temperature1',
    7102 => 'board-temperature2',
  };
  $test->{info}{store}{mt_gauge_value}
    = {17 => 41, 7001 => 3825, 7101 => 33, 7102 => 36};
  return;
}

sub board_temp : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'board_temp');

  $test->{info}{'_mtxrHlTemperature'} = 350;
  is($test->{info}->board_temp(), 35,
    q(Legacy mtxrHlTemperature returns degrees from tenths));

  delete $test->{info}{'_mtxrHlTemperature'};
  $test->_prime_gauges();
  is($test->{info}->board_temp(), 33,
    q(RouterOS 7 returns board-temperature1 from the gauge table));

  $test->{info}->clear_cache();
  warnings_are { $test->{info}->board_temp() } [],
    q(No data returns without warnings);
}

sub cpu_temp : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'cpu_temp');

  $test->{info}{'_mtxrHlProcessorTemperature'} = 440;
  is($test->{info}->cpu_temp(), 44,
    q(Legacy mtxrHlProcessorTemperature returns degrees from tenths));

  delete $test->{info}{'_mtxrHlProcessorTemperature'};
  $test->_prime_gauges();
  is($test->{info}->cpu_temp(), 41,
    q(RouterOS 7 returns cpu-temperature from the gauge table));

  $test->{info}->clear_cache();
  warnings_are { $test->{info}->cpu_temp() } [],
    q(No data returns without warnings);
}

1;
