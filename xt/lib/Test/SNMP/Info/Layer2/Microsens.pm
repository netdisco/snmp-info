# Test::SNMP::Info::Layer2::Microsens
#
# Copyright (c) 2026 df-an and the SNMP::Info Developers
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

package Test::SNMP::Info::Layer2::Microsens;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer2::Microsens;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  my $cache_data = {
    '_layers'               => 2,
    '_description'          => " MICROSENS G6 Switch OS\x00 ",
    '_id'                   => '.1.3.6.1.4.1.3181.10.6.2.1',
    '_name'                 => 'access-switch.example.net',
    '_microsens_model'      => " MS440210M-G6+\x00 ",
    '_microsens_serial'     => " 1234567890\x00 ",
    '_microsens_firmware'   => " 10.5.4a\x00 ",
    'store'                 => {},
  };
  $test->{info}->cache($cache_data);
}

sub device_type : Tests(+5) {
  my $test = shift;
  $test->SUPER::device_type;

  for my $layers (2, 0) {
    $test->{info}{_layers} = $layers;
    is($test->{info}->device_type(), 'SNMP::Info::Layer2::Microsens',
      "MICROSENS G6 detected with sysServices $layers");
  }

  $test->{info}{_layers} = 6;
  isnt($test->{info}->device_type(), 'SNMP::Info::Layer2::Microsens',
    q(MICROSENS is not mapped through the Layer3 enterprise map));

  $test->{info}{_id} = '.1.3.6.1.4.1.3181.10.5.1';
  is($test->{info}->device_type(), 'SNMP::Info::Layer2::Microsens',
    q(Other MICROSENS managed switch generations are detected));

  $test->{info}{_id} = '.1.3.6.1.4.1.3181.11.1';
  is($test->{info}->device_type(), 'SNMP::Info::Layer2::Microsens',
    q(MICROSENS enterprise is detected outside the managed switch subtree));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'microsens', q(Vendor returns 'microsens'));
}

sub name : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'name');
  is($test->{info}->name(), 'access-switch.example.net',
    q(Name is inherited from standard sysName));
}

sub model : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'MS440210M-G6+', q(Model is normalized));

  $test->{info}{_microsens_model} = '';
  is($test->{info}->model(), '.1.3.6.1.4.1.3181.10.6.2.1',
    q(Empty model falls back to the Layer2 model));

  $test->{info}->clear_cache();
  is($test->{info}->model(), '', q(No model data returns an empty model));
}

sub serial : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), '1234567890', q(Serial is normalized));

  $test->{info}{_microsens_serial} = '';
  $test->{info}{_e_parent} = 1;
  $test->{info}{_e_class} = 1;
  $test->{info}{store}{e_parent} = { 1 => 0 };
  $test->{info}{store}{e_class} = { 1 => 'chassis' };
  $test->mock_session->{Data}{'ENTITY-MIB::entPhysicalSerialNum'} = {
    1 => 'ENTITY-SERIAL',
  };
  is($test->{info}->serial(), 'ENTITY-SERIAL',
    q(Empty factory serial falls back to ENTITY-MIB));

  $test->{info}->clear_cache();
  is($test->{info}->serial(), undef, q(No serial data returns undef));
}

sub os : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'microsens',
    q(OS returns the fixed MICROSENS identifier));

  $test->{info}{_description} = 'MICROSENS Generation 5 Firmware';
  is($test->{info}->os(), 'microsens',
    q(OS is independent of the device sysDescr value));

  $test->{info}->clear_cache();
  is($test->{info}->os(), 'microsens',
    q(OS remains available without SNMP sysDescr data));
}

sub os_ver : Tests(6) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '10.5.4a', q(Firmware version is normalized));

  $test->{info}{_microsens_firmware} = " \x00";
  is($test->{info}->os_ver(), undef, q(Blank firmware returns undef));

  $test->{info}{_id} = '.1.3.6.1.4.1.3181.10.5.1';
  is($test->{info}->os_ver(), undef,
    q(Other switch generations without ENTITY-MIB data return undef));

  $test->{info}{_e_parent} = 1;
  $test->{info}{_e_class} = 1;
  $test->{info}{store}{e_parent} = { 1 => 0 };
  $test->{info}{store}{e_class} = { 1 => 'chassis' };
  $test->mock_session->{Data}{'ENTITY-MIB::entPhysicalSoftwareRev'} = {
    1 => 'legacy-firmware',
  };
  is($test->{info}->os_ver(), 'legacy-firmware',
    q(Other switch generations fall back to ENTITY-MIB firmware));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No firmware data returns undef));
}

1;
