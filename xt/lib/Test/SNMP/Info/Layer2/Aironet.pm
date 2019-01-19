# Test::SNMP::Info::Layer2::Aironet
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

package Test::SNMP::Info::Layer2::Aironet;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer2::Aironet;

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
  my $d_string = 'Cisco IOS Software, C1240 Software (C1240-K9W7-M), ';
  $d_string .= 'Version 12.3(11)JA, RELEASE SOFTWARE (fc2) ';

  my $cache_data = {
    '_layers'      => 2,
    '_description' => $d_string,

    # CISCO-PRODUCTS-MIB::ciscoAIRAP1240
    '_id'            => '.1.3.6.1.4.1.9.1.685',
    '_i_description' => 1,
    '_e_descr'       => 1,
    'store'          => {
      'i_description' => {
        1 => 'Dot11Radio0',
        2 => 'Dot11Radio1',
        3 => 'FastEthernet0',
        4 => 'Null0',
        5 => 'BVI1',
        6 => 'Dot11Radio0.64-802.1Q vLAN subif',
        7 => 'Dot11Radio1.64-802.1Q vLAN subif',
        8 => 'FastEthernet0.1-802.1Q vLAN subif',
        9 => 'FastEthernet0.64-802.1Q vLAN subif'
      },
       'e_descr' => {
        1 => 'Cisco Aironet 1240 Series (IEEE 802.11a/g) Access Point',
        2 => '802.11G Radio',
        3 => '802.11A Radio',
        4 => 'PowerPCElvis Ethernet',
      },

    },
  };
  $test->{info}->cache($cache_data);
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'cisco', q(Vendor returns 'cisco'));
}

sub interfaces : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'interfaces');

  my $expected = {
        1 => 'Dot11Radio0',
        2 => 'Dot11Radio1',
        3 => 'FastEthernet0',
        4 => 'Null0',
        5 => 'BVI1',
        6 => 'Dot11Radio0.64-802.1Q vLAN subif',
        7 => 'Dot11Radio1.64-802.1Q vLAN subif',
        8 => 'FastEthernet0.1-802.1Q vLAN subif',
        9 => 'FastEthernet0.64-802.1Q vLAN subif'
      };

  cmp_deeply($test->{info}->interfaces(),
    $expected, q(Interfaces have expected values));
}

sub description : Tests(4) {
  my $test = shift;

  my $expected = 'Cisco Aironet 1240 Series (IEEE 802.11a/g) Access Point';
  $expected .= '  ';
  $expected .= 'Cisco IOS Software, C1240 Software (C1240-K9W7-M), ';
  $expected .= 'Version 12.3(11)JA, RELEASE SOFTWARE (fc2) ';

  can_ok($test->{info}, 'description');
  is($test->{info}->description(), $expected, q(Description is expected value));

  $test->{info}{_description} = undef;
  $expected = 'Cisco Aironet 1240 Series (IEEE 802.11a/g) Access Point';
  $expected .= '  ';
  is($test->{info}->description(), $expected, q(Description is expected value just using Entity MIB));

  $test->{info}->clear_cache();
  is($test->{info}->description(), undef,
    q(No data returns undef));
}

1;
