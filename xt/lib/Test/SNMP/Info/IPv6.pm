# Test::SNMP::Info::IPv6
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

package Test::SNMP::Info::IPv6;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::IPv6;

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
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

# RouterOS 7.24.5: addresses only in IPV6-MIB ipv6AddrTable, keyed by
# ifIndex and the 16 address octets
my $GLOBAL     = '32.1.13.184.0.16.0.0.0.0.0.0.0.0.0.1';
my $ANYCAST    = '32.1.13.184.0.16.0.0.0.0.0.0.0.0.0.2';
my $LINK_LOCAL = '254.128.0.0.0.0.0.0.168.193.171.255.254.125.243.52';

sub _prime_ipv6_mib {
  my $test = shift;

  $test->{info}{'_i6_addr_pfxlen'}  = 1;
  $test->{info}{'_i6_addr_anycast'} = 1;
  $test->{info}{store}{i6_addr_pfxlen} = {
    "8.$GLOBAL"     => 64,
    "9.$ANYCAST"    => 64,
    "7.$LINK_LOCAL" => 64,
    "8.$LINK_LOCAL" => 64,
  };
  $test->{info}{store}{i6_addr_anycast} = {
    "8.$GLOBAL"     => 'false',
    "9.$ANYCAST"    => 'true',
    "7.$LINK_LOCAL" => 'false',
    "8.$LINK_LOCAL" => 'false',
  };
  return;
}

sub ipv6_index : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'ipv6_index');

  $test->_prime_ipv6_mib();
  my $expected = {
    "2.16.$GLOBAL"             => 8,
    "2.16.$ANYCAST"            => 9,
    "4.20.$LINK_LOCAL.0.0.0.7" => 7,
    "4.20.$LINK_LOCAL.0.0.0.8" => 8,
  };
  cmp_deeply($test->{info}->ipv6_index(), $expected,
    q(IPV6-MIB rows keyed as InetAddress, link-local zoned by ifIndex));

  $test->{info}{'_ip_addr6_index'} = 1;
  $test->{info}{store}{ip_addr6_index} = {"2.16.$GLOBAL" => 5};
  cmp_deeply($test->{info}->ipv6_index(), {"2.16.$GLOBAL" => 5},
    q(IP-MIB is preferred when present));

  $test->{info}->clear_cache();
  is($test->{info}->ipv6_index(), undef, q(No data returns undef));
}

sub ipv6_type : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'ipv6_type');

  $test->_prime_ipv6_mib();
  my $expected = {
    "2.16.$GLOBAL"             => 'unicast',
    "2.16.$ANYCAST"            => 'anycast',
    "4.20.$LINK_LOCAL.0.0.0.7" => 'unicast',
    "4.20.$LINK_LOCAL.0.0.0.8" => 'unicast',
  };
  cmp_deeply($test->{info}->ipv6_type(), $expected,
    q(IPV6-MIB anycast flag maps to anycast, otherwise unicast));

  $test->{info}->clear_cache();
  is($test->{info}->ipv6_type(), undef, q(No data returns undef));
}

sub ipv6_addr_prefixlength : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'ipv6_addr_prefixlength');

  $test->_prime_ipv6_mib();
  my $expected = {
    "2.16.$GLOBAL"             => 64,
    "2.16.$ANYCAST"            => 64,
    "4.20.$LINK_LOCAL.0.0.0.7" => 64,
    "4.20.$LINK_LOCAL.0.0.0.8" => 64,
  };
  cmp_deeply($test->{info}->ipv6_addr_prefixlength(), $expected,
    q(IPV6-MIB prefix lengths returned under the same keys));

  $test->{info}->clear_cache();
  is($test->{info}->ipv6_addr_prefixlength(), undef,
    q(No data returns undef));
}

sub ipv6_addr : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'ipv6_addr');

  $test->_prime_ipv6_mib();
  my $link_local = 'fe80:0000:0000:0000:a8c1:abff:fe7d:f334';
  my $expected = {
    "2.16.$GLOBAL"             => '2001:0db8:0010:0000:0000:0000:0000:0001',
    "2.16.$ANYCAST"            => '2001:0db8:0010:0000:0000:0000:0000:0002',
    "4.20.$LINK_LOCAL.0.0.0.7" => $link_local,
    "4.20.$LINK_LOCAL.0.0.0.8" => $link_local,
  };
  cmp_deeply($test->{info}->ipv6_addr(), $expected,
    q(IPV6-MIB addresses parse from the InetAddress keys));
}

1;
