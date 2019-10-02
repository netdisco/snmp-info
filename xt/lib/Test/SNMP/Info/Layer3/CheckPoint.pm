# Test::SNMP::Info::Layer3::CheckPoint
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

package Test::SNMP::Info::Layer3::CheckPoint;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::CheckPoint;

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
    '_layers' => 76,
    # descr is from older ipso based devices
    '_description' => 'i386 FreeBSD 2.1.5. Check Point FireWall-1 Version',

    # CHECKPOINT-MIB::fw
    '_id'   => '.1.3.6.1.4.1.2620.1.1',
    'store' => {},
    '_serial_number' => '0123456789abcdef',
    '_product_name' => 'Check Point 12200',
    '_manufacturer' => 'Checkpoint',
    '_version' => 'R80.20',
  };
  $test->{info}->cache($cache_data);
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'checkpoint', q(OS returns 'checkpoint'));
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'checkpoint', q(Vendor returns 'checkpoint')); 
}

sub os_ver : Tests(2) {
  my $test = shift;
    
  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), 'R80.20',q(OS Version return 'R80.20'));
}

sub serial : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'serial');
  is($test->{info}->serial(), '0123456789abcdef', q(Serial returns '0123456789abcdef'));
}

sub model : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'Check Point 12200', q(Model is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->model(), undef, q(No description returns undef model));
}

sub layers : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'layers');
  is($test->{info}->layers(), '01001100', q(Layers returns '01001100'));
}

1;
