# Test::SNMP::Info::Layer3::F5OS

package Test::SNMP::Info::Layer3::F5OS;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::F5OS;


sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # F5-PLATFORM-STATS-MIB uses SNMP string indexes. Keep the encoded
  # representation here because this is what SNMP::Info receives from SNMP.
  my $platform = '8.112.108.97.116.102.111.114.109';
  my $lcd      = '3.108.99.100';

  my $cache_data = {
    '_layers' => 72,
    '_description' =>
      'F5 rSeries Appliance services version 1.8.3',

    '_id' => '.1.3.6.1.4.1.12276',

    # Cache scalar values directly. SNMP::Info stores cached GLOBAL values
    # in the object's underscore-prefixed entries.
    '_f5_serial' => 'f5-abcd-efgh',

    # Mark mocked SNMP values as already cached. SNMP::Info uses these
    # internal cache flags to decide whether the corresponding value
    # should be read from store or fetched through the SNMP session.
    '_serial1'             => 1,
    '_f5_component_serial' => 1,
    '_f5_component_model'  => 1,
    '_f5_psu_name'         => 1,
    '_f5_psu_serial'       => 1,
    '_f5_psu_part'         => 1,
    '_f5_disk_name'        => 1,
    '_f5_disk_model'       => 1,
    '_f5_disk_vendor'      => 1,
    '_f5_disk_version'     => 1,
    '_f5_disk_serial'      => 1,
    '_i_index'             => 1,
    '_i_name'              => 1,
    '_f5_lldp_local_if'    => 1,
    '_f5_lldp_rem_chassis' => 1,
    '_f5_lldp_rem_port'    => 1,
    '_f5_lldp_rem_ip'      => 1,
    '_f5_lldp_rem_desc'    => 1,

    'store' => {
      # F5-OS-SYSTEM-MIB
      'f5_serial' => 'f5-abcd-efgh',

      # F5-OS-LLDP-MIB local chassis identifier
      'serial1' => '00:11:22:33:44:55',

      # F5-PLATFORM-STATS-MIB::componentInfoTable
      'f5_component_serial' => {
        $platform => 'f5-abcd-efgh',
        $lcd      => 'sub0872r6dgi',
      },

      'f5_component_model' => {
        $platform => 'r12900-DS',
      },

      # F5-PLATFORM-STATS-MIB::psuStatsTable
      'f5_psu_name' => {
        1 => 'psu-1',
        2 => 'psu-2',
      },

      'f5_psu_serial' => {
        1 => 'FZ1234RC0123',
        2 => 'FZ1234RC0124',
      },

      'f5_psu_part' => {
        1 => 'PWR-0388-02',
        2 => 'PWR-0388-02',
      },

      # F5-PLATFORM-STATS-MIB::diskInfoTable
      'f5_disk_name' => {
        1 => 'nvme0n1',
        2 => 'nvme1n1',
      },

      'f5_disk_model' => {
        1 => 'SAMSUNG MZQL21T9HCJR-00A07',
        2 => 'SAMSUNG MZQL21T9HCJR-00A07',
      },

      'f5_disk_vendor' => {
        1 => 'Samsung',
        2 => 'Samsung',
      },

      'f5_disk_version' => {
        1 => 'GDC5602Q',
        2 => 'GDC5602Q',
      },

      'f5_disk_serial' => {
        1 => 'S64GNS0T123456',
        2 => 'S64GNS0T123457',
      },

      # IF-MIB
      #
      # F5OS exposes useful interface names through ifName. These names are
      # also referenced by F5-OS-LLDP-MIB and are therefore required to map
      # LLDP neighbors back to their local ifIndex.
      'i_index' => {
        1 => 1,
        2 => 2,
        3 => 3,
      },

      'i_name' => {
        1 => '1.0',
        2 => '2.0',
        3 => '',
      },

      # F5-OS-LLDP-MIB
      #
      # F5OS does not expose its LLDP neighbors through the standard
      # LLDP-MIB tables used by SNMP::Info. The vendor-specific table uses
      # the local interface name rather than ifIndex.
      'f5_lldp_local_if' => {
        1 => '1.0',
        2 => '2.0',
      },

      'f5_lldp_rem_chassis' => {
        1 => '00:aa:bb:cc:dd:01',
        2 => '00:aa:bb:cc:dd:02',
      },

      'f5_lldp_rem_port' => {
        1 => 'Ethernet1/1',
        2 => 'Ethernet1/2',
      },

      'f5_lldp_rem_ip' => {
        1 => '192.0.2.1',
        2 => '192.0.2.2',
      },

      'f5_lldp_rem_desc' => {
        1 => 'Example switch one',
        2 => 'Example switch two',
      },
    },
  };

  $test->{info}->cache($cache_data);
}


# ---------------------------------------------------------------------------
# Device identification
# ---------------------------------------------------------------------------

sub device_type : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'device_type');

  is(
    $test->{info}->device_type(),
    'SNMP::Info::Layer3::F5OS',
    q(Device type identifies the F5OS class)
  );
}


sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');

  is(
    $test->{info}->vendor(),
    'f5',
    q(Vendor returns 'f5')
  );
}


sub os : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os');

  is(
    $test->{info}->os(),
    'f5os',
    q(OS returns 'f5os')
  );
}


sub f5os_version : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'f5os_version');

  is(
    $test->{info}->f5os_version(),
    '1.8.3',
    q(F5OS version is extracted from sysDescr)
  );
}


sub os_ver : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'os_ver');

  is(
    $test->{info}->os_ver(),
    '1.8.3',
    q(OS version returns '1.8.3')
  );
}


sub model : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'model');

  is(
    $test->{info}->model(),
    'r12900-DS',
    q(Model is taken from the platform component)
  );
}


sub serial : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'serial');

  is(
    $test->{info}->serial(),
    'f5-abcd-efgh',
    q(Serial is taken from F5-OS-SYSTEM-MIB)
  );
}


# ---------------------------------------------------------------------------
# Interfaces
# ---------------------------------------------------------------------------

sub interfaces : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'interfaces');

  cmp_deeply(
    $test->{info}->interfaces(),
    {
      1 => '1.0',
      2 => '2.0',
      3 => 3,
    },
    'Interfaces use ifName and fall back to ifIndex'
  );
}


# ---------------------------------------------------------------------------
# LLDP
#
# F5OS does not provide the standard LLDP tables expected by SNMP::Info.
# The F5OS implementation therefore translates the vendor-specific
# F5-OS-LLDP-MIB data into the normal SNMP::Info LLDP API.
# ---------------------------------------------------------------------------

sub hasLLDP : Tests(3) {
  my $test = shift;

  can_ok($test->{info}, 'hasLLDP');

  is(
    $test->{info}->hasLLDP(),
    1,
    'LLDP support is detected from F5OS neighbor data'
  );

  # Test the negative path as well. Keep the cache flag set because this
  # represents a successful SNMP query which returned an empty neighbor table,
  # rather than an uncached value which should trigger another SNMP request.
  $test->{info}{store}{f5_lldp_rem_chassis} = {};

  is(
    $test->{info}->hasLLDP(),
    undef,
    'LLDP support is not reported without neighbor data'
  );
}


sub lldp_if : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_if');

  cmp_deeply(
    $test->{info}->lldp_if(),
    {
      1 => 1,
      2 => 2,
    },
    'LLDP local interface names are mapped to ifIndex'
  );
}


sub lldp_port : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_port');

  cmp_deeply(
    $test->{info}->lldp_port(),
    {
      1 => 'Ethernet1/1',
      2 => 'Ethernet1/2',
    },
    'LLDP remote ports are returned correctly'
  );
}


sub lldp_id : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_id');

  cmp_deeply(
    $test->{info}->lldp_id(),
    {
      1 => '00:aa:bb:cc:dd:01',
      2 => '00:aa:bb:cc:dd:02',
    },
    'LLDP remote chassis identifiers are returned correctly'
  );
}


sub lldp_ip : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_ip');

  cmp_deeply(
    $test->{info}->lldp_ip(),
    {
      1 => '192.0.2.1',
      2 => '192.0.2.2',
    },
    'LLDP remote management addresses are returned correctly'
  );
}


sub lldp_platform : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'lldp_platform');

  cmp_deeply(
    $test->{info}->lldp_platform(),
    {
      1 => 'Example switch one',
      2 => 'Example switch two',
    },
    'LLDP remote descriptions are returned as platform information'
  );
}


# ---------------------------------------------------------------------------
# ENTITY-MIB compatibility
#
# F5OS does not expose the standard ENTITY-MIB data required by SNMP::Info.
# The F5OS class builds an equivalent entity hierarchy from the available
# F5 platform, PSU and disk tables. These tests verify the resulting public
# SNMP::Info entity API rather than the internal representation.
# ---------------------------------------------------------------------------

sub e_index : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'e_index');

  cmp_deeply(
    $test->{info}->e_index(),
    {
      1    => 1,
      1001 => 1001,
      2001 => 2001,
      2002 => 2002,
      3001 => 3001,
      3002 => 3002,
    },
    'Entity indexes are generated correctly'
  );
}


sub e_class : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'e_class');

  cmp_deeply(
    $test->{info}->e_class(),
    {
      1    => 'chassis',
      1001 => 'module',
      2001 => 'powerSupply',
      2002 => 'powerSupply',
      3001 => 'module',
      3002 => 'module',
    },
    'Entity classes are generated correctly'
  );
}


sub e_name : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'e_name');

  cmp_deeply(
    $test->{info}->e_name(),
    {
      1    => 'platform',
      1001 => 'lcd',
      2001 => 'psu-1',
      2002 => 'psu-2',
      3001 => 'nvme0n1',
      3002 => 'nvme1n1',
    },
    'Entity names are generated correctly'
  );
}


sub e_model : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'e_model');

  cmp_deeply(
    $test->{info}->e_model(),
    {
      1    => 'r12900-DS',
      2001 => 'PWR-0388-02',
      2002 => 'PWR-0388-02',
      3001 => 'SAMSUNG MZQL21T9HCJR-00A07',
      3002 => 'SAMSUNG MZQL21T9HCJR-00A07',
    },
    'Entity models are generated correctly'
  );
}


sub e_serial : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'e_serial');

  cmp_deeply(
    $test->{info}->e_serial(),
    {
      1    => 'f5-abcd-efgh',
      1001 => 'sub0872r6dgi',
      2001 => 'FZ1234RC0123',
      2002 => 'FZ1234RC0124',
      3001 => 'S64GNS0T123456',
      3002 => 'S64GNS0T123457',
    },
    'Entity serial numbers are generated correctly'
  );
}


sub e_vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'e_vendor');

  cmp_deeply(
    $test->{info}->e_vendor(),
    {
      1    => 'F5',
      3001 => 'Samsung',
      3002 => 'Samsung',
    },
    'Entity vendors are generated correctly'
  );
}


sub e_fwver : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'e_fwver');

  cmp_deeply(
    $test->{info}->e_fwver(),
    {
      3001 => 'GDC5602Q',
      3002 => 'GDC5602Q',
    },
    'Entity firmware versions are generated correctly'
  );
}


sub e_parent : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'e_parent');

  cmp_deeply(
    $test->{info}->e_parent(),
    {
      1    => 0,
      1001 => 1,
      2001 => 1,
      2002 => 1,
      3001 => 1,
      3002 => 1,
    },
    'Entity hierarchy is generated correctly'
  );
}


sub e_pos : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'e_pos');

  cmp_deeply(
    $test->{info}->e_pos(),
    {
      1    => -1,
      1001 => 1,
      2001 => 2,
      2002 => 3,
      3001 => 4,
      3002 => 5,
    },
    'Entity positions are generated deterministically'
  );
}


sub e_descr : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'e_descr');

  cmp_deeply(
    $test->{info}->e_descr(),
    {},
    'No entity description is invented without source data'
  );
}


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

sub f5os_string_indexes : Tests(3) {
  my $test = shift;

  # F5 platform tables use OCTET STRING values as part of their SNMP indexes.
  # Net-SNMP presents these indexes as a length followed by the decimal value
  # of every character. Verify both valid and malformed representations.

  my @decoded =
    SNMP::Info::Layer3::F5OS::_f5_decode_string_indexes(
      '8.112.108.97.116.102.111.114.109'
    );

  is_deeply(
    \@decoded,
    ['platform'],
    'Single string index is decoded correctly'
  );

  @decoded =
    SNMP::Info::Layer3::F5OS::_f5_decode_string_indexes(
      '3.102.111.111.3.98.97.114'
    );

  is_deeply(
    \@decoded,
    ['foo', 'bar'],
    'Multiple consecutive string indexes are decoded correctly'
  );

  @decoded =
    SNMP::Info::Layer3::F5OS::_f5_decode_string_indexes(
      '8.112.108'
    );

  is(
    scalar @decoded,
    0,
    'Malformed string index is rejected'
  );
}


1;
