# Test::SNMP::Info::Layer2::Mellanox
#
# Copyright (c) 2026 Hannes Eberhardt
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

package Test::SNMP::Info::Layer2::Mellanox;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer2::Mellanox;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Shapes from Onyx 3.6 and 3.8 walks: sysServices 72, LLDP rows keyed
  # timemark.lldpRemLocalPortNum.index, local port numbers are bridge ports
  my $cache_data = {
    '_layers'      => 72,
    '_description' => 'Onyx,MSN2410,SWv3.10.4100',
    '_id'          => '.1.3.6.1.4.1.33049.1.1.1.2410',
    '_lldp_rem_id_type' => 1,
    '_lldp_rem_id'      => 1,
    '_bp_index'         => 1,
    '_lldp_lport_id'    => 1,
    '_i_name'           => 1,
    '_lldp_rman_addr'   => 1,
    'store' => {
      'lldp_rem_id_type' => {
        '1000.97.10'  => 'macAddress',
        '1000.193.11' => 'macAddress',
        '1000.61.12'  => 'macAddress',
        '1000.33.13'  => 'networkAddress',
        '1000.37.14'  => 'interfaceName',
      },
      'lldp_rem_id' => {
        '1000.97.10'  => '02:00:00:00:00:10',
        '1000.193.11' => pack('C*', 0x02, 0, 0, 0, 0, 0x11),
        '1000.61.12'  => '02:00:00:00:00:12',
        '1000.33.13'  => pack('C*', 1, 192, 0, 2, 13),
        '1000.37.14'  => 'swp14',
      },
      'bp_index' => {97 => 101, 61 => 116, 33 => 93, 37 => 94},
      'lldp_lport_id' => {
        97 => 'Eth1/25', 193 => 'Eth1/49', 61 => 'Eth1/16',
        33 => 'Eth1/9', 37 => 'Eth1/10', 205 => 'Eth1/52',
      },
      'i_name' => {
        101 => 'Eth1/25', 81 => 'Eth1/49', 116 => 'Eth1/16',
        93 => 'Eth1/9', 94 => 'Eth1/10',
      },
      # lldpRemManAddrIfSubtype, indexed with the address type, length
      # and octets after the remote row's index
      'lldp_rman_addr' => {
        '1000.97.10.1.4.192.0.2.10'  => 'ifIndex',
        '1000.193.11.1.4.192.0.2.11' => 'ifIndex',
        '1000.33.13.1.4.192.0.2.13'  => 'ifIndex',
        '1000.37.14.1.4.192.0.2.14'  => 'ifIndex',
      },
    },
  };
  $test->{info}->cache($cache_data);
}

sub layers : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'layers');
  is($test->{info}->layers(), '01001010',
    'layers__sysservices_72__adds_layer_2');

  $test->{info}->clear_cache();
  $test->{info}->cache({'_layers' => 6});
  is($test->{info}->layers(), '00000110',
    'layers__layer_2_already_served__unchanged');
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'mellanox', q(Vendor returns 'mellanox'));
}

sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');
  is($test->{info}->os(), 'onyx', q(OS returns 'onyx'));
}

sub os_ver : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');
  is($test->{info}->os_ver(), '3.10.4100', q(OS ver is expected value));

  $test->{info}->clear_cache();
  is($test->{info}->os_ver(), undef, q(No description returns undef));
}

sub model : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'MSN2410', q(Model parsed from Onyx sysDescr));

  $test->{info}->clear_cache();
  $test->{info}->cache({
    '_description' => 'Linux Mellanox 2.6.27',
    '_id'          => '.1.3.6.1.4.1.33049.1.1.1.2700',
  });
  isnt($test->{info}->model(), undef,
    'model__no_onyx_sysdescr__falls_back_to_parent');
}

sub lldp_id : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_id');
  my $id = $test->{info}->lldp_id();
  is($id->{'1000.97.10'}, '02:00:00:00:00:10',
    'lldp_id__ascii_mac__decoded');
  is($id->{'1000.193.11'}, '02:00:00:00:00:11',
    'lldp_id__binary_mac__decoded');
  is($id->{'1000.33.13'}, '192.0.2.13',
    'lldp_id__network_address__decoded');
}

sub lldp_if : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_if');
  my $if = $test->{info}->lldp_if();
  is($if->{'1000.97.10'}, 101, 'lldp_if__bridge_port__maps_via_bp_index');
  is($if->{'1000.193.11'}, 81,
    'lldp_if__no_bridge_port__maps_lldpLocPortId_to_ifName');
  is($if->{'1000.33.13'}, 93, 'lldp_if__second_bridge_port__maps');

  $test->{info}->clear_cache();
  $test->{info}->cache({
    '_lldp_rem_id_type' => 1, '_bp_index' => 1, '_lldp_lport_id' => 1,
    '_i_name' => 1,
    'store' => {
      'lldp_rem_id_type' => {'1000.205.15' => 'macAddress'},
      'bp_index'         => {},
      'lldp_lport_id'    => {205 => 'Eth1/52'},
      'i_name'           => {101 => 'Eth1/25'},
    },
  });
  cmp_deeply($test->{info}->lldp_if(), {},
    'lldp_if__no_bridge_port_or_name_match__omits_neighbor');
}

sub c_ip : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'c_ip');
  my $ip = $test->{info}->c_ip();
  is($ip->{'1000.97.10'}, '192.0.2.10', 'c_ip__management_address__kept');
  is($ip->{'1000.61.12'}, '0.0.0.0',
    'c_ip__no_management_address__zero_for_id_lookup');
}

sub device_type : Tests(3) {
  my $test = shift;

  # device_type runs on the base class, whose layers() has no Onyx override
  my $info = SNMP::Info->new(AutoSpecify => 0, Session => $test->mock_session);
  my %cases = (
    'Onyx,MSN2410,SWv3.6.6102' =>
      ['.1.3.6.1.4.1.33049.1.1.1.2410', 'SNMP::Info::Layer2::Mellanox'],
    'Onyx,MSN2700,SWv3.8.1000' =>
      ['.1.3.6.1.4.1.33049.1.1.1.2700', 'SNMP::Info::Layer2::Mellanox'],
    'Linux Mellanox 2.6.27-MELLANOXuni-m460ex EFM_PPC_M460EX' =>
      ['.1.3.6.1.4.1.33049.2.3.2.1', 'SNMP::Info::Layer7'],
  );
  foreach my $descr (sort keys %cases) {
    my ($id, $class) = @{$cases{$descr}};
    $info->clear_cache();
    $info->cache({'_layers' => 72, '_description' => $descr, '_id' => $id});
    is($info->device_type(), $class, "device_type__${descr}__$class");
  }
}

1;
