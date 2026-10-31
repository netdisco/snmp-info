# Test::SNMP::Info::Layer3
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

package Test::SNMP::Info::Layer3;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3;

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
    '_i_index' => 1,
    '_i_description' => 1,
    'store' => {
      'i_index' => { map {($_ => $_)} (1 .. 8) },
      'i_description' => {
        1 => 'Unique Interface Name',
        2 => 'Duplicate Interface Name',
        3 => 'Duplicate Interface Name',
        4 => "\0",
        5 => "\0",
        6 => " \0",
        7 => "\0 ",
      },
    },
  };
  $test->{info}->cache($cache_data);
}

sub duplicates : Tests(2) {
  my $test = shift;

  my $expected_data = {
    1 => 'Unique Interface Name',
    2 => 'Duplicate Interface Name (2)',
    3 => 'Duplicate Interface Name (3)',
    4 => 4,
    5 => 5,
    6 => 6,
    7 => 7,
    8 => 8,
  };

  can_ok($test->{info}, 'interfaces');
  cmp_deeply($test->{info}->interfaces(),
    $expected_data, 'Call to interfaces() removes duplicates and cleans up');
}

# ipNetToPhysicalTable rows: ifIndex, InetAddressType, then InetAddress with
# its length octet, or without it as on Cisco ASA and FTD
my %N2P_PADDR = (
  '8.1.4.192.168.140.253' => pack('H*', '3890a5fe21bf'),
  '5.1.10.0.0.33'         => pack('H*', '00090f090000'),
  '8.2.16.254.128.0.3.0.0.0.0.186.56.97.255.254.104.139.40'
    => pack('H*', 'b83861688b28'),
);

sub _prime_n2p {
  my $test = shift;

  $test->{info}{'_ip_n2p_phys_addr'} = 1;
  $test->{info}{store}{ip_n2p_phys_addr} = {%N2P_PADDR};
  return;
}

sub at_paddr : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'at_paddr');

  $test->_prime_n2p();
  my $expected = {
    '8.192.168.140.253' => '38:90:a5:fe:21:bf',
    '5.10.0.0.33'       => '00:09:0f:09:00:00',
  };
  cmp_deeply($test->{info}->at_paddr(), $expected,
    q(ipNetToPhysicalTable IPv4 rows keyed like ipNetToMediaTable));

  cmp_deeply($test->{info}->at_paddr('8'),
    {'8.192.168.140.253' => '38:90:a5:fe:21:bf'},
    q(Partial fetch returns the matching ipNetToPhysicalTable rows));

  $test->{info}{'_at_paddr'} = 1;
  $test->{info}{store}{at_paddr}
    = {'3.10.1.1.1' => pack('H*', '001122334455')};
  cmp_deeply($test->{info}->at_paddr(),
    {'3.10.1.1.1' => '00:11:22:33:44:55'},
    q(ipNetToMediaTable is preferred when present));

  $test->{info}->clear_cache();
  is($test->{info}->at_paddr(), undef, q(No data returns undef));
}

sub at_netaddr : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'at_netaddr');

  $test->_prime_n2p();
  my $expected = {
    '8.192.168.140.253' => '192.168.140.253',
    '5.10.0.0.33'       => '10.0.0.33',
  };
  cmp_deeply($test->{info}->at_netaddr(), $expected,
    q(ipNetToPhysicalTable IPv4 addresses come from the row index));

  $test->{info}{'_at_paddr'} = 1;
  $test->{info}{store}{at_paddr}
    = {'3.10.1.1.1' => pack('H*', '001122334455')};
  is($test->{info}->at_netaddr(), undef,
    q(ipNetToMediaTable MACs without addresses take none from n2p table));

  $test->{info}->clear_cache();
  is($test->{info}->at_netaddr(), undef, q(No data returns undef));
}

sub at_index : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'at_index');

  $test->_prime_n2p();
  my $expected = {
    '8.192.168.140.253' => 8,
    '5.10.0.0.33'       => 5,
  };
  cmp_deeply($test->{info}->at_index(), $expected,
    q(ipNetToPhysicalTable IPv4 rows map to their ifIndex));

  $test->{info}->clear_cache();
  is($test->{info}->at_index(), undef, q(No data returns undef));
}

# Some routers, an Extreme VDX among them, list only their own 127.x
# entries in ipNetToMediaTable and the ARP cache in ipNetToPhysicalTable
sub _prime_loopback_media {
  my ($test, %extra) = @_;

  my %paddr = ('3.127.1.0.1' => pack('H*', '0027f8000001'), %extra);
  $test->{info}{'_at_index'}   = 1;
  $test->{info}{'_at_paddr'}   = 1;
  $test->{info}{'_at_netaddr'} = 1;
  $test->{info}{store}{at_index}   = {map { $_ => 3 } keys %paddr};
  $test->{info}{store}{at_paddr}   = \%paddr;
  $test->{info}{store}{at_netaddr}
    = {map { my ($a) = /^\d+\.(.+)$/; ($_ => $a) } keys %paddr};
  return;
}

sub at_paddr__media_table_loopback_only__reads_n2p_table : Tests(3) {
  my $test = shift;

  $test->_prime_loopback_media();
  $test->_prime_n2p();
  my $expected = {
    '8.192.168.140.253' => '38:90:a5:fe:21:bf',
    '5.10.0.0.33'       => '00:09:0f:09:00:00',
  };
  cmp_deeply($test->{info}->at_paddr(), $expected,
    q(MAC addresses come from ipNetToPhysicalTable));
  cmp_deeply($test->{info}->at_netaddr(),
    {'8.192.168.140.253' => '192.168.140.253', '5.10.0.0.33' => '10.0.0.33'},
    q(IPv4 addresses come from ipNetToPhysicalTable));
  cmp_deeply($test->{info}->at_index(),
    {'8.192.168.140.253' => 8, '5.10.0.0.33' => 5},
    q(ifIndexes come from ipNetToPhysicalTable));
}

sub at_paddr__media_table_with_one_real_row__kept : Tests(1) {
  my $test = shift;

  $test->_prime_loopback_media('3.10.1.1.1' => pack('H*', '001122334455'));
  $test->_prime_n2p();
  cmp_deeply($test->{info}->at_paddr(),
    {'3.127.1.0.1' => '00:27:f8:00:00:01',
     '3.10.1.1.1'  => '00:11:22:33:44:55'},
    q(ipNetToMediaTable with any other address is kept as it is));
}

sub at_paddr__media_table_loopback_only_no_n2p__kept : Tests(1) {
  my $test = shift;

  $test->_prime_loopback_media();
  cmp_deeply($test->{info}->at_paddr(),
    {'3.127.1.0.1' => '00:27:f8:00:00:01'},
    q(Loopback rows are returned when ipNetToPhysicalTable has none));
}

1;
