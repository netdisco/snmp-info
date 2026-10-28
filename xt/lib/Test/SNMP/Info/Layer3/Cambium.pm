# Test::SNMP::Info::Layer3::Cambium
#
# Copyright (c) 2026 Netdisco Contributors
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

package Test::SNMP::Info::Layer3::Cambium;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Cambium;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  my $cache_data = {
    '_layers'              => 78,
    '_description'         => 'Linux GVA-myLab-M 3.14.77 #1 SMP PREEMPT Tue Mar 28 15:35:42 UTC 2023 armv7l',
    '_id'                  => '.1.3.6.1.4.1.17713.21.9.51',
    '_cambium_os_ver'      => '4.7.0.1',
    '_cambium_hw_info'     => 51,
    '_cambium_esn'         => '0004564AABBE',
    '_cambium_epmp_msn'    => 'E4ZK02301102',
    '_cambium_lan_mac'     => '00:04:56:49:AA:AA',
    '_cambium_device_name' => 'GVA-myLab-M',
    'store'                => {},
  };
  $test->{info}->cache($cache_data);
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'Cambium Networks', q(Vendor returns expected value));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'Cambium', q(OS returns expected value));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '4.7.0.1', q(OS version returns expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No data returns undef OS version));
}

sub name : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'name');
  is($test->{info}->name(), 'GVA-myLab-M', q(Name returns expected value));

  $test->{info}->clear_cache();
  is($test->{info}->name(), undef, q(No data returns undef name));
}

sub mac : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'mac');
  is($test->{info}->mac(), '00:04:56:49:AA:AA', q(MAC returns expected value));

  $test->{info}->clear_cache();
  is($test->{info}->mac(), undef, q(No data returns undef MAC));
}

sub serial : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is(
    $test->{info}->serial(),
    'E4ZK02301102 0004564AABBE',
    q(Serial returns EPMPMSN and ESN, joined by space)
  );

  $test->{info}->clear_cache();
  is($test->{info}->serial(), undef, q(No data returns undef serial));
}

sub model : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  like(
    $test->{info}->model(),
    qr/^5 GHz Force 300-19R IP67 Radio \(ROW\/ETSI\)(?: \(ePMPxorn19rip67row\))?$/,
    q(Model returns mapped cambiumHWInfo value and optional sysObjectID suffix)
  );

  $test->{info}->clear_cache();
  is($test->{info}->model(), undef, q(No data returns undef model));
}

1;
