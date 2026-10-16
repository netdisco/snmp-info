# Test::SNMP::Info::Layer3::CiscoASA
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

package Test::SNMP::Info::Layer3::CiscoASA;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::CiscoASA;

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
    '_layers' => 4,
    '_description' => 'Cisco Adaptive Security Appliance Version 9.2(1)',

    # CISCO-PRODUCTS-MIB::ciscoASA5505
    '_id'   => '.1.3.6.1.4.1.9.1.745',
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

sub ipv6_index : Tests(2) {
  my $test = shift;

  my $global = '32.1.13.184.0.16.0.0.0.0.0.0.0.0.0.1';
  $test->{info}{'_i6_addr_pfxlen'} = 1;
  $test->{info}{store}{i6_addr_pfxlen} = {"8.$global" => 64};

  is($test->{info}->ipv6_index(), undef,
    q(IPV6-MIB addresses are not read, as parse_inetaddress expects no length));
  is($test->{info}->ipv6_addr_prefixlength(), undef,
    q(IPV6-MIB prefix lengths are not read));
}

sub i_description : Tests(4) {
  my $test = shift;

  $test->{info}{'_i_index'}       = 1;
  $test->{info}{'_i_description'} = 1;
  $test->{info}{store}{i_index} = {2 => 2, 14 => 14, 15 => 15};
  $test->{info}{store}{i_description} = {
    2  => q(Adaptive Security Appliance 'outside' interface),
    14 => 'Internal-Data0/0',
    15 => 'Internal-Data0/1',
  };
  my $expected = {
    2  => 'outside',
    14 => 'Internal-Data0/0',
    15 => 'Internal-Data0/1',
  };

  can_ok($test->{info}, 'i_description');
  is_deeply($test->{info}->i_description(), $expected,
    q(Quoted name is extracted, unquoted descriptions are kept));

  # #229: a failed match leaves $1 holding the caller's last capture
  'tunnel 31902 up' =~ /(\d+)/;
  is_deeply($test->{info}->i_description(), $expected,
    q(Unquoted descriptions ignore a capture made by the caller));
  is_deeply($test->{info}->interfaces(), $expected,
    q(No duplicate interface names are made up));
}

1;
