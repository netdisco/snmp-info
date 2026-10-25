# Test::SNMP::Info::Layer3::CiscoSwitch
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

package Test::SNMP::Info::Layer3::CiscoSwitch;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::CiscoSwitch;
use Test::SNMP::Info::CiscoStpExtensions;

# This class is a collection of roles and not meant to instantiated for a
# specific device. Don't test device class and no need to setup data
sub device_type : Tests(1) {
  my $test  = shift;
  my $class = $test->class;

  can_ok($test->{info}, 'device_type');

}

sub cisco_comm_indexing : Tests(2) {
  my $test = shift;

  can_ok $test->{info}, 'cisco_comm_indexing';
  is($test->{info}->cisco_comm_indexing(), 1, 'Cisco community indexing on');
}

sub stp_trees : Tests(4) {
  my $test = shift;
  my $info = $test->{info};

  my $cache = Test::SNMP::Info::CiscoStpExtensions::_iol_pvst_cache(
    'rapidPvstPlus');
  $cache->{_description} = 'Cisco IOS Software [IOSXE], Linux Software'
    . ' (X86_64BI_LINUX_L2-ADVENTERPRISEK9-M), Version 17.18.2';
  $info->cache($cache);
  my @measured = map { $_->{measured} } values %{$info->stp_trees()};
  cmp_deeply(\@measured, [1, 1, 1], 'IOS XE trees are measured');

  $info->clear_cache();
  $cache->{_description} = 'Cisco Systems WS-C5505 Cisco Catalyst Operating'
    . ' System Software';
  $info->cache($cache);
  @measured = map { $_->{measured} } values %{$info->stp_trees()};
  cmp_deeply(\@measured, [0, 0, 0], 'CatOS trees are not measured');

  # Neither per-port table served: stpxPVSTVlanEnable, Ethernet VLANs only
  $info->clear_cache();
  delete $cache->{$_}, delete $cache->{store}{substr $_, 1}
    for qw/_stpx_faststart_oper _stpx_rstp_port_role/;
  $info->cache($cache);
  cmp_deeply([sort { $a <=> $b } map { $_->{id} } values %{$info->stp_trees()}],
    [1, 10, 20, 1002 .. 1005], 'No VTP types: every enabled VLAN');

  $info->clear_cache();
  $cache->{_v_type} = 1;
  $cache->{store}{v_type} = {
    '1.1'    => 'ethernet',  '1.10'   => 'ethernet', '1.20' => 'ethernet',
    '1.1002' => 'fddi',      '1.1003' => 'tokenRing',
    '1.1004' => 'fddiNet',   '1.1005' => 'trNet',
  };
  $info->cache($cache);
  cmp_deeply([sort keys %{$info->stp_trees()}],
    [qw/vlan.1 vlan.10 vlan.20/], 'VTP defaults 1002 to 1005 dropped');
}

1;
