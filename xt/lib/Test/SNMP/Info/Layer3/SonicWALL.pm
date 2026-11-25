# Test::SNMP::Info::Layer3::SonicWALL
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

package Test::SNMP::Info::Layer3::SonicWALL;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::SonicWALL;

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
    '_description' => 'SonicWALL PRO 2040 Enhanced (SonicOS Enhanced 4.2.0.1-12e)',

    # SONICWALL-SMI::sonicwallFw
    '_id'   => '.1.3.6.1.4.1.8741.1',

    # SONICWALL-COMMON-MIB::snwlSysFirmwareVersion
    '_sw_firmware' => 'SonicOS Enhanced 4.2.0.1-12e',
    'store'        => {},
  };
  $test->{info}->cache($cache_data);
}

sub os_ver : Tests(7) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '4.2.0.1-12e',
    q(SonicOS Enhanced firmware returns the version after the edition));

  my %firmware_forms = (
    'SonicOS Enhanced 6.2.4.2-20n' => '6.2.4.2-20n',
    'SonicOS 7.0.1-R1456'          => '7.0.1-R1456',
    'SonicOS 7.3.4-7013-R10134'    => '7.3.4-7013-R10134',
    '8.6.0.3-11sv'                 => '8.6.0.3-11sv',
  );
  foreach my $firmware (sort keys %firmware_forms) {
    $test->{info}->cache({'_sw_firmware' => $firmware});
    is($test->{info}->os_ver(), $firmware_forms{$firmware},
      qq(os_ver from '$firmware' is $firmware_forms{$firmware}));
  }

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), '', q(No firmware version returns empty os_ver));
}

1;
