# Test::SNMP::Info::Layer3::Meraki
#
# Copyright (c) 2024 SNMP::Info Developers
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

package Test::SNMP::Info::Layer3::Meraki;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Layer3::Meraki;

sub setup : Tests(setup) {
  my $test = shift;
  $test->SUPER::setup;

  # Start with a common cache that will serve most tests
  my $cache_data = {
    '_layers' => 6,

    # No MIB to resolve, just use enterprise ID
    '_id'   => '.1.3.6.1.4.1.29671',
    'store' => {},
  };
  $test->{info}->cache($cache_data);
}

sub layers : Tests(2) {
    my $test = shift;

    can_ok( $test->{info}, 'layers' );
    is( $test->{info}->layers(), '00000110', q(Layers returns '00000110') );
}

sub vendor : Tests(2) {
  my $test = shift;

  can_ok($test->{info}, 'vendor');
  is($test->{info}->vendor(), 'cisco meraki',
    q(Vendor returns 'cisco meraki'));
}

sub model : Tests(9) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'model');

  my $model_for = sub {
    my ($descr, $id) = @_;
    $info->clear_cache();
    $info->cache({'_description' => $descr, '_id' => $id});
    return $info->model();
  };

  is($model_for->(
      'Meraki MS120-8FP Cloud Managed PoE Switch',
      '.1.3.6.1.4.1.29671.2.340'
    ),
    'MS120-8FP',
    q(model__switch_sysdescr__returns_model_token));
  is($model_for->(
      'Meraki MR36 Cloud Managed Indoor AP', '.1.3.6.1.4.1.29671.2.37'
    ),
    'MR36',
    q(model__ap_sysdescr__returns_model_token));
  is($model_for->(
      '=Meraki MR28 Cloud Managed AP', '.1.3.6.1.4.1.29671.2.28'
    ),
    'MR28',
    q(model__sysdescr_with_leading_equals__returns_model_token));
  is($model_for->(
      'Meraki Cloud Managed 802.11n AP', '.1.3.6.1.4.1.29671.2.37'
    ),
    'MR36',
    q(model__generic_sysdescr__maps_product_oid));
  is($model_for->(undef, '.1.3.6.1.4.1.29671.2.388'),
    'C9300', q(model__cloud_managed_c9300_oid__returns_C9300));
  is($model_for->(undef, '.1.3.6.1.4.1.29671.2.102'),
    'MX80', q(model__legacy_mx80_oid__returns_MX80));
  like($model_for->(undef, '.1.3.6.1.4.1.29671.2.99999'),
    qr/29671[.]2[.]99999$/,
    q(model__unmapped_oid__falls_back_to_inherited_model));

  $info->clear_cache();
  is($info->model(), undef, q(model__no_data__returns_undef));
}

sub serial1 : Tests(3) {
  my $test = shift;
  my $info = $test->{info};

  can_ok($info, 'serial1');

  # entity_derived_serial makes a partial fetch of e_serial, which
  # bypasses the cache, so the serial comes from the mocked session.
  $info->cache({
    '_e_parent' => 1,
    '_e_class'  => 1,
    'store'     => {
      'e_parent' => {2000 => 0},
      'e_class'  => {2000 => 'chassis'},
    },
  });
  $info->{sess}{Data}
    = {'ENTITY-MIB::entPhysicalSerialNum' => {2000 => 'Q2AB-CDEF-GHIJ'}};
  is($info->serial1(), 'Q2AB-CDEF-GHIJ',
    q(serial1__entity_chassis_serial__returns_it));

  $info->clear_cache();
  $info->{sess}{Data} = {};
  is($info->serial1(), undef, q(serial1__no_entity_serial__returns_undef));
}

1;
