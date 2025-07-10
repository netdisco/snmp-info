# Test::SNMP::Info::Layer3::EdgeSwitch
#
# Copyright (c) 2025 Ambroise Rosset
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

package Test::SNMP::Info::Layer3::EdgeSwitch;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::EdgeSwitch;

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
    '_layers' => 6,
    '_description' =>
      'EFOS, 3.9.0.2, Linux 4.15.18-d60bb35b, 2016.05.00.06 ',

    # 
    '_id'   => '.1.3.6.1.4.1.4413',
    '_inv_mach_model' => 'BES-53248',
    '_serial1' => 'XXXXXXXXXXXXX',
    '_sw_ver' => '3.9.0.2',
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

1;
