# Test::SNMP::Info::Layer2::FortiAP
#
# Copyright (c) 2026 SNMP::Info Developers
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

package Test::SNMP::Info::Layer2::FortiAP;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer2::FortiAP;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Shaped from a FAP-231G on 7.4: no sysServices, the host name as
  # sysDescr, and fapVersion/fapSerialNum under 12356.120.1
  my $cache_data = {
    '_description' => 'AP-FLOOR2-01',

    # FORTINET-FORTIAP-MIB::fap231g
    '_id'          => '.1.3.6.1.4.1.12356.120.10.23113',
    '_fap_version' => 'FP231G-v7.4-build0771',
    '_fap_serial'  => 'FP231GTF00000001',
    'store'        => {},
  };
  $test->{info}->cache($cache_data);
}

sub layers : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'layers');
  is($test->{info}->layers(), '00000010',
    q(No sysServices defaults to layer 2));

  $test->{info}{_layers} = 6;
  is($test->{info}->layers(), '00000110', q(Served sysServices is kept));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'fortinet', q(Vendor returns 'fortinet'));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'fortiap', q(OS returns 'fortiap'));
}

sub os_ver : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '7.4-build0771',
    q(Version follows the image name));

  # A FAP-U231F image name starts PU, not FP
  $test->{info}{_fap_version} = 'PU231F-v7.0-build0084';
  is($test->{info}->os_ver(), '7.0-build0084', q(U-series image name));

  $test->{info}{_fap_version} = '7.0-build0084';
  is($test->{info}->os_ver(), '7.0-build0084',
    q(A version without an image name is returned as is));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No fapVersion returns undef));
}

sub serial : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), 'FP231GTF00000001', q(Serial from fapSerialNum));

  $test->{info}->clear_cache();
  is($test->{info}->serial(), undef, q(No fapSerialNum returns undef));
}

sub device_type : Tests(4) {
  my $test = shift;

  # device_type runs on the base class, without this class's layers default
  my $info = SNMP::Info->new(AutoSpecify => 0, Session => $test->mock_session);
  my %cases = (
    # FORTINET-FORTIAP-MIB::fap231g, FAP-231G on 7.4
    '.1.3.6.1.4.1.12356.120.10.23113' => 'SNMP::Info::Layer2::FortiAP',

    # FORTINET-FORTIAP-MIB::fapu231f, FAP-U231F on 7.0
    '.1.3.6.1.4.1.12356.120.10.23122' => 'SNMP::Info::Layer2::FortiAP',

    # FORTINET-FORTIGATE-MIB::fgt60F
    '.1.3.6.1.4.1.12356.101.1.644' => 'SNMP::Info::Layer3::Fortinet',
  );
  foreach my $id (sort keys %cases) {
    $info->clear_cache();
    $info->cache({'_description' => 'AP-FLOOR2-01', '_id' => $id});
    is($info->device_type(), $cases{$id}, "device_type__${id}__$cases{$id}");
  }

  # A FortiGate serving sysServices keeps its class
  $info->clear_cache();
  $info->cache({
    '_layers'      => 78,
    '_description' => 'FortiGate-60F',
    '_id'          => '.1.3.6.1.4.1.12356.101.1.644',
  });
  is($info->device_type(), 'SNMP::Info::Layer3::Fortinet',
    q(device_type__fortigate_with_sysservices__Layer3::Fortinet));
}

1;
