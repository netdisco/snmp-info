# Test::SNMP::Info::Bridge
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

package Test::SNMP::Info::Bridge;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::Bridge;

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
    '_dot1qVlanFdbId' =>1,
    'store' => {
      'dot1qVlanFdbId' => { '0.1' => 0, '0.91' => 3, '0.112' => 1, '0.113' => 2}
      },
  };
  $test->{info}->cache($cache_data);
}


sub qb_fdb_index : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'qb_fdb_index' );

    my $expected = { 0 => 1, 3 => 91, 1 => 112, 2 => 113 };
    cmp_deeply( $test->{info}->qb_fdb_index(), $expected, q(FDB to VLAN index returned expected values));

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->qb_fdb_index(),
        {}, q(No data returns empty hash) );
}

sub qb_fdb_index_shared : Tests(2) {
    my $test = shift;

    # Shared VLAN learning: VLANs 10, 20 and 30 all use FDB ID 5
    $test->{info}{store}{dot1qVlanFdbId}
        = { '0.1' => 1, '0.10' => 5, '0.20' => 5, '0.30' => 5 };

    my $expected = { 1 => 1, 5 => undef };
    cmp_deeply( $test->{info}->qb_fdb_index(), $expected,
        q(FDB ID shared by several VLANs maps to no VLAN) );

    my @answers = map { $test->{info}->qb_fdb_index()->{5} // 'undef' } 1 .. 5;
    cmp_deeply( \@answers, [ ('undef') x 5 ],
        q(Shared FDB ID gives the same answer on every call) );
}

sub qb_fw_vlan : Tests(3) {
    my $test = shift;

    can_ok( $test->{info}, 'qb_fw_vlan' );

    $test->{info}{store}{dot1qVlanFdbId}
        = { '0.91' => 3, '0.10' => 5, '0.20' => 5 };
    $test->{info}{'_qb_fw_port'} = 1;
    $test->{info}{store}{qb_fw_port} = {
        '3.0.17.34.51.68.85' => 1,
        '5.0.17.34.51.68.86' => 2,
        '7.0.17.34.51.68.87' => 3,
    };

    my $expected = {
        '3.0.17.34.51.68.85' => 91,
        '5.0.17.34.51.68.86' => undef,
        '7.0.17.34.51.68.87' => 7,
    };
    cmp_deeply( $test->{info}->qb_fw_vlan(), $expected,
        q(Mapped FDB ID gives its VLAN, shared gives none, unmapped is the VID) );

    $test->{info}->clear_cache();
    cmp_deeply( $test->{info}->qb_fw_vlan(), {}, q(No data returns empty hash) );
}

sub stp_decode_ids : Tests(5) {
    my $test = shift;
    my $bid  = \&SNMP::Info::Bridge::_stp_decode_bridge_id;
    my $pid  = \&SNMP::Info::Bridge::_stp_decode_port_id;

    cmp_deeply(
        $bid->('10:00:02:00:00:00:00:0a'),
        {   priority   => 4096,
            sys_id_ext => 0,
            mac        => '02:00:00:00:00:0a',
            raw        => '10:00:02:00:00:00:00:0a'
        },
        q(RSTP bridge ID decodes)
    );
    cmp_deeply(
        $bid->('80:01:02:00:00:00:00:0b'),
        {   priority   => 32768,
            sys_id_ext => 1,
            mac        => '02:00:00:00:00:0b',
            raw        => '80:01:02:00:00:00:00:0b'
        },
        q(PVST VLAN 1 keeps the extension apart)
    );
    cmp_deeply( $pid->('80:02'), { priority => 128, port => 2, raw => '80:02' },
        q(Port ID decodes) );
    is( $bid->(undef), undef, q(Undef bridge ID gives undef) );
    is( $pid->('80'),  undef, q(Short port ID gives undef) );
}

1;
