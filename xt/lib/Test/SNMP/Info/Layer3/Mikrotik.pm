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

sub c_ip : Tests(3) {
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

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->c_ip(undef, ['lldp']), {},
    q(No data returns empty hash));
}

1;
