# Test::SNMP::Info::Layer3::H3C
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

package Test::SNMP::Info::Layer3::H3C;
use Test::Class::Most parent => 'My::Test::Class';
use SNMP::Info::Layer3::H3C;

sub startup : Tests(startup => 1) {
  my $test = shift;
  $test->SUPER::startup;
  $test->todo_methods(1);
}

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;
  my %store = (
    i_index => {map { $_=>$_ } (1,19,32,56,57,58)},
    i_description => {1=>'GigabitEthernet1/0/1',19=>'GigabitEthernet1/0/19',
      32=>'GigabitEthernet1/0/32',56=>'Ten-GigabitEthernet1/2/1',
      57=>'Ten-GigabitEthernet1/2/2',58=>'Bridge-Aggregation1'},
    bp_index => {1=>1,19=>19,32=>32,55=>56,56=>57,225=>58},
    stp_p_state => {1=>'blocking',19=>'forwarding',32=>'disabled',
      55=>'blocking',56=>'blocking',225=>'disabled'},
    ad_port_attached_agg => {1=>0,56=>58,57=>58},
    ad_lag_ports => {58=>pack('C*',(0)x7,3)},
  );
  $test->{info}->cache({
    _layers=>78, _id=>'.1.3.6.1.4.1.25506.1.297',
    _description=>'HP A5120-48G EI Comware Software, Version 5.20.99',
    (map { ('_' . $_)=>1 } keys %store), store=>\%store,
  });
}

sub agg_ports : Tests(2) {
  my $test = shift;
  cmp_deeply($test->{info}->agg_ports, {56=>58,57=>58},
    'Attached indexes preserve selected and unselected membership');
  $test->{info}{store}{ad_port_attached_agg} = {};
  cmp_deeply($test->{info}->agg_ports,
    SNMP::Info::IEEE802dot3ad::agg_ports_lag($test->{info}),
    'Missing attached table retains existing fallback');
}

sub i_stp_state : Tests(5) {
  my $test = shift;
  my $info = $test->{info};
  cmp_deeply($info->i_stp_state, {1=>'blocking',19=>'forwarding',32=>'disabled',58=>'disabled'},
    'Only physical aggregate member STP states omitted');
  $info->{store}{stp_p_state}{225} = 'blocking';
  is($info->i_stp_state->{58}, 'blocking', 'Blocked aggregate retained');
  $info->{store}{ad_port_attached_agg} = {};
  is($info->i_stp_state->{56}, 'blocking', 'Missing membership retains member state');
  $info->{store}{ad_port_attached_agg} = {56=>0,57=>999,1=>'invalid',19=>19};
  is($info->i_stp_state->{56}, 'blocking', 'Zero aggregate retains member state');
  is($info->i_stp_state->{57}, 'blocking', 'Unknown aggregate retains member state');
}

1;
