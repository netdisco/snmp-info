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

    # IF-MIB rows of the FAP-231G: radios wifiN, one wlan<R><W> port per
    # VAP whose MAC counts up from its radio's, and Linux pseudo devices
    '_i_index'       => 1,
    '_i_description' => 1,
    '_i_type'        => 1,
    '_i_mac'         => 1,

    # fapRadioTable keyed by radio, fapVapTable by radio.wlan; radio 2
    # is a monitor radio on channel 0
    '_fap_radio_channel' => 1,
    '_fap_radio_tx_pwr'  => 1,
    '_fap_vap_ssid'      => 1,

    # fapStationTable, indexed radio.wlan.<length>.<mac>; one row without
    # the length octet, one on radio 2
    '_fap_sta_ssid' => 1,
    '_fap_sta_vlan' => 1,
    'store'          => {
      'fap_sta_ssid' => {
        '0.1.6.128.150.177.92.153.130' => 'GUEST',
        '1.0.6.40.106.186.61.150.231'  => 'CORP',
        '0.2.96.190.181.42.99.151'     => 'IOT',
        '2.0.6.2.0.0.0.0.1'            => 'CORP',
      },
      'fap_sta_vlan' => {
        '0.1.6.128.150.177.92.153.130' => 4,
        '1.0.6.40.106.186.61.150.231'  => 41,
        '0.2.96.190.181.42.99.151'     => 4,
        '2.0.6.2.0.0.0.0.1'            => 4,
      },
      'fap_radio_channel' => {0 => 1,  1 => 136, 2 => 0},
      'fap_radio_tx_pwr'  => {0 => 13, 1 => 15,  2 => 50},
      'fap_vap_ssid'      =>
        {'0.0' => 'CORP', '0.1' => 'GUEST', '0.2' => 'IOT', '1.0' => 'CORP'},
      'i_index' => {map { $_ => $_ }
          (1, 2, 5, 9, 13, 15, 16, 17, 18, 19, 21, 25, 26, 28, 30, 31, 32,
           33, 34, 44, 45)},
      'i_description' => {
        1  => 'lo',     2  => 'gre0',   5  => 'eth0',   9  => 'ifb0',
        13 => 'wldvlan',
        15 => 'teql0',  16 => 'wifi1',  17 => 'wifi0',  18 => 'soc0',
        19 => 'wifi2',  21 => 'br0',    25 => 'wlan00', 26 => 'wlan10',
        28 => 'wlbgs0', 30 => 'wlan20', 31 => 'wlan02', 32 => 'tc0',
        33 => 'br.ssid.0', 34 => 'tv02',
        44 => 'w00.4',  45 => 'wlan01',
      },
      'i_type' => {
        1  => 'softwareLoopback', 2  => 'tunnel', 5  => 'ethernetCsmacd',
        9  => 'ethernetCsmacd',   15 => 'other',  16 => 'other',
        17 => 'other',            18 => 'other',  19 => 'other',
        21 => 'ethernetCsmacd',   25 => 'ethernetCsmacd',
        26 => 'ethernetCsmacd',   28 => 'ethernetCsmacd',
        30 => 'ethernetCsmacd',   31 => 'ethernetCsmacd',
        34 => 'ethernetCsmacd',   44 => 'ethernetCsmacd',
        45 => 'ethernetCsmacd',
      },
      'i_mac' => {
        5  => pack('H*', '0401a1c4e1b0'),
        9  => pack('H*', '92153b05ec32'),
        16 => pack('H*', '0401a1c4e1c0'),
        17 => pack('H*', '0401a1c4e1b8'),
        19 => pack('H*', '0401a1c4e1c8'),
        21 => pack('H*', '0401a1c4e1b0'),
        25 => pack('H*', '0401a1c4e1b8'),
        26 => pack('H*', '0401a1c4e1c0'),
        28 => pack('H*', '0601a1c4e1b8'),
        30 => pack('H*', '0401a1c4e1c8'),
        31 => pack('H*', '0401a1c4e1ba'),
        34 => pack('H*', '0401a1c4e1ba'),
        44 => pack('H*', '0401a1c4e1b0'),
        45 => pack('H*', '0401a1c4e1b9'),
      },
    },
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

sub model : Tests(4) {
  my $test = shift;

  can_ok($test->{info}, 'model');
  is($test->{info}->model(), 'FP231G',
    q(model__fap_version__returns_image_name));

  $test->{info}{_fap_version} = 'PU231F-v7.0-build0084';
  is($test->{info}->model(), 'PU231F', q(model__u_series__returns_image_name));

  $test->{info}{_fap_version} = '7.0-build0084';
  my $fallback = $test->{info}->model();
  ok(defined $fallback && $fallback ne '7.0-build0084',
    q(model__no_image_name__falls_back_to_sysobjectid));
}

sub i_ignore : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_ignore');
  cmp_deeply([sort { $a <=> $b } keys %{$test->{info}->i_ignore()}],
    [1, 2, 9, 15, 18], q(i_ignore__linux_pseudo_devices__are_ignored));
}

sub _drop_interface {
  my ($test, $iid) = @_;
  my $store = $test->{info}{store};
  delete $store->{$_}{$iid} for qw(i_index i_description i_type i_mac);
}

sub interfaces : Tests(5) {
  my $test = shift;

  can_ok($test->{info}, 'interfaces');
  my $interfaces = $test->{info}->interfaces();
  cmp_deeply([sort { $a <=> $b } keys %$interfaces],
    [1, 2, 5, 9, 13, 15, 16, 17, 18, 19, 21],
    q(interfaces__vap_and_ssid_ports__are_not_ports));
  is($interfaces->{17}, 'wifi0', q(interfaces__radio__keeps_its_name));

  $test->_drop_interface(16);
  ok(exists $test->{info}->interfaces()->{26},
    q(interfaces__radio_without_port__keeps_vap_ports));

  $test->{info}{store}{fap_vap_ssid} = {};
  ok(exists $test->{info}->interfaces()->{32},
    q(interfaces__no_vap_rows__keeps_ssid_ports));
}

sub i_80211channel : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'i_80211channel');
  cmp_deeply($test->{info}->i_80211channel(), {17 => 1, 16 => 136},
    q(i_80211channel__monitor_radio__is_omitted));
}

sub dot11_cur_tx_pwr_mw : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'dot11_cur_tx_pwr_mw');
  cmp_deeply($test->{info}->dot11_cur_tx_pwr_mw(), {17 => 20, 16 => 32},
    q(dot11_cur_tx_pwr_mw__dbm__returns_mw));
}

sub i_ssidlist : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_ssidlist');
  cmp_deeply(
    $test->{info}->i_ssidlist(),
    {'17.0' => 'CORP', '17.1' => 'GUEST', '17.2' => 'IOT', '16.0' => 'CORP'},
    q(i_ssidlist__vap__keys_to_radio)
  );

  $test->_drop_interface(16);
  cmp_deeply(
    $test->{info}->i_ssidlist(),
    {'17.0' => 'CORP', '17.1' => 'GUEST', '17.2' => 'IOT'},
    q(i_ssidlist__radio_without_port__is_omitted)
  );
}

sub i_ssidmac : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'i_ssidmac');
  cmp_deeply(
    $test->{info}->i_ssidmac(),
    {
      '17.0' => '04:01:a1:c4:e1:b8',
      '17.1' => '04:01:a1:c4:e1:b9',
      '17.2' => '04:01:a1:c4:e1:ba',
      '16.0' => '04:01:a1:c4:e1:c0'
    },
    q(i_ssidmac__vap_port__returns_its_mac)
  );

  $test->_drop_interface(31);
  ok(!exists $test->{info}->i_ssidmac()->{'17.2'},
    q(i_ssidmac__vap_port_missing__omits_bssid));
}

my %sta = (
  guest => '0.1.6.128.150.177.92.153.130',
  corp  => '1.0.6.40.106.186.61.150.231',
  iot   => '0.2.96.190.181.42.99.151',
  mon   => '2.0.6.2.0.0.0.0.1',
);

sub _by_station {
  my %by_name = @_;
  return {map { $sta{$_} => $by_name{$_} } keys %by_name};
}

my %sta_mac = (
  guest => '80:96:b1:5c:99:82',
  corp  => '28:6a:ba:3d:96:e7',
  iot   => '60:be:b5:2a:63:97',
  mon   => '02:00:00:00:00:01',
);

sub qb_fw_mac : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'qb_fw_mac');
  cmp_deeply($test->{info}->qb_fw_mac(), _by_station(%sta_mac),
    q(qb_fw_mac__unprefixed_index__decodes_mac));

  $test->_drop_interface(16);
  ok(!exists $test->{info}->qb_fw_mac()->{$sta{corp}},
    q(qb_fw_mac__radio_without_port__drops_station));
}

sub qb_fw_port : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'qb_fw_port');
  cmp_deeply($test->{info}->qb_fw_port(),
    _by_station(guest => 17, corp => 16, iot => 17, mon => 19),
    q(qb_fw_port__station__returns_radio_ifindex));

  $test->_drop_interface(16);
  ok(!exists $test->{info}->qb_fw_port()->{$sta{corp}},
    q(qb_fw_port__radio_without_port__drops_station));
}

sub qb_fw_vlan : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'qb_fw_vlan');
  cmp_deeply($test->{info}->qb_fw_vlan(),
    _by_station(guest => 4, corp => 41, iot => 4, mon => 4),
    q(qb_fw_vlan__station__returns_fapStaVlanId));
}

sub bp_index : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'bp_index');
  my $bp_index = $test->{info}->bp_index();
  cmp_deeply([map { $bp_index->{$_} } 16, 17, 19], [16, 17, 19],
    q(bp_index__radio_port__maps_to_itself));
}

sub bp_index_bridge : Tests(2) {
  my $test = shift;

  # A BRIDGE-MIB map whose bridge port 16 is a wired port, not radio wifi1
  $test->{info}{'_bp_index'} = 1;
  $test->{info}{store}{bp_index} = {1 => 5, 16 => 21};

  my $bp_index = $test->{info}->bp_index();
  is($bp_index->{16}, 21, q(bp_index__bridge_port_collides__keeps_bridge_map));
  cmp_deeply($test->{info}{store}{bp_index}, {1 => 5, 16 => 21},
    q(bp_index__radio_ports_added__leaves_cache_unchanged));
}

sub fw_port : Tests(1) {
  my $test = shift;

  my $bp_index = $test->{info}->bp_index();
  my @unmapped = grep { !exists $bp_index->{$_} }
    values %{$test->{info}->fw_port()};
  is(scalar @unmapped, 0, q(fw_port__every_station_port__is_in_bp_index));
}

sub cd11_txrate : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'cd11_txrate');
  cmp_deeply($test->{info}->cd11_txrate(),
    _by_station(map { $_ => [] } keys %sta),
    q(cd11_txrate__no_rate_column__returns_empty_rate_per_station));
}

sub cd11_mac : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'cd11_mac');
  cmp_deeply($test->{info}->cd11_mac(), _by_station(%sta_mac),
    q(cd11_mac__station__decodes_index_mac));
}

sub cd11_ssid : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'cd11_ssid');
  cmp_deeply($test->{info}->cd11_ssid(),
    _by_station(guest => 'GUEST', corp => 'CORP', iot => 'IOT', mon => 'CORP'),
    q(cd11_ssid__station__returns_fapStaSSID));
}

sub cd11_port : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'cd11_port');
  cmp_deeply($test->{info}->cd11_port(),
    _by_station(guest => 'wifi0', corp => 'wifi1', iot => 'wifi0',
      mon => 'wifi2'),
    q(cd11_port__station__returns_radio_port));
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
