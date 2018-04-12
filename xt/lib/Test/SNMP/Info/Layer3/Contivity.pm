# Test::SNMP::Info::Layer3::Contivity
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

package Test::SNMP::Info::Layer3::Contivity;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Contivity;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_layers'      => 79,
    '_description' => 'CES V05_05.202',

    # NEWOAK-MIB::vpnRouter1750
    '_id'            => '.1.3.6.1.4.1.2505.1750',
    '_e_model'       => 1,
    '_e_serial'      => 1,
    '_i_mac'         => 1,
    '_i_description' => 1,
    '_i_name'        => 1,
    'store'          => {
      'e_model'  => {1 => 'CES1750D'},
      'e_serial' => {1 => '12345'},
      'i_mac'    => {
        1     => '',
        2     => pack("H*", '00140D123456'),
        3     => pack("H*", '00140D1234AB'),
        6     => pack("H*", '000000000034'),
        65656 => '',
      },
      'i_description' => {
        1     => 'lo',
        2     => 'fei0',
        3     => 'fei1',
        6     => 'clip',
        65656 => 'BOS(NU)::Type=IPSec,LE=1.2.3.4,RE=2.3.4.5'
      },
      'i_name' => {
        1     => 'lo.0.0.0.0',
        2     => 'fei.0.1',
        3     => 'fei.2.1',
        6     => 'clip.0.0.0.0',
        65656 => 'My Tunnel Name'
      }
    }
  };
  $test->{info}->cache($cache_data);
}

sub layers : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'layers');
  is($test->{info}->layers(), '00000100', q(Layers returns '00000111'));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'avaya', q(Vendor returns 'avaya'));
}

sub model : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'CES1750', q(Model is expected value));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'contivity', q(OS returns 'contivity'));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '05_05.202', q(OS version is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef,
    q(No description returns undef OS version));
}

sub mac : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'mac');
  is($test->{info}->mac(), '00:14:0d:12:34:56', q(MAC is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->mac(), undef, q(No data returns undef));
}

sub serial : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), '12345', q(Serial is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->serial(), undef, q(No data returns undef));
}

sub interfaces : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'interfaces');

  my $expected = {2 => 'fei0', 3 => 'fei1'};

  cmp_deeply($test->{info}->interfaces(),
    $expected, q(Interfaces have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->interfaces(), {}, q(No data returns empty hash));
}

sub i_name : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_name');

  my $expected = {2 => 'fei.0.1', 3 => 'fei.2.1'};

  cmp_deeply($test->{info}->i_name(),
    $expected, q(Interface names have expected values));

  $test->{info}->clear_cache();
  cmp_deeply($test->{info}->i_name(), {}, q(No data returns empty hash));
}

1;
