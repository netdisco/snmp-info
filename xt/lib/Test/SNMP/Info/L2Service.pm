# Test::SNMP::Info::L2Service
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

package Test::SNMP::Info::L2Service;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::L2Service;

my @ROWS = (
    { vlan => 10, type => 'isid', id => 20010 },
    {   vlan     => 10,
        type     => 'vni',
        id       => 30010,
        ifindex  => 0,
        instance => 'tenant-a'
    },
    { vlan => undef, type => 'isid', id => 20099, ifindex => 196 },
);

sub with_source {
    my ( $test, $rows, $walked, $code ) = @_;

    no warnings 'redefine';
    local *SNMP::Info::L2Service::_l2sb_vendor_rows   = sub {@$rows};
    local *SNMP::Info::L2Service::_l2sb_vendor_walked = sub {@$walked};
    return $code->();
}

sub l2_service_bindings : Tests(2) {
    my $test = shift;

    can_ok( $test->{info}, 'l2_service_bindings' );
    cmp_deeply( $test->{info}->l2_service_bindings(),
        {}, q(No source gives an empty hash) );
}

sub l2_service_bindings__rows__keyed_by_every_field : Tests(1) {
    my $test = shift;

    my $bindings = $test->with_source( \@ROWS, [],
        sub { $test->{info}->l2_service_bindings() } );
    cmp_deeply(
        $bindings,
        {   'isid.20010.10.0.' => {
                vlan     => 10,
                type     => 'isid',
                id       => 20010,
                ifindex  => 0,
                instance => undef
            },
            'vni.30010.10.0.tenant-a' => {
                vlan     => 10,
                type     => 'vni',
                id       => 30010,
                ifindex  => 0,
                instance => 'tenant-a'
            },
            'isid.20099..196.' => {
                vlan     => undef,
                type     => 'isid',
                id       => 20099,
                ifindex  => 196,
                instance => undef
            },
        },
        q(Each row keyed type.id.vlan.ifindex.instance, every field present)
    );
}

sub l2_service_bindings__same_binding_twice__one_row : Tests(1) {
    my $test = shift;

    my $bindings = $test->with_source( [ $ROWS[0], { %{ $ROWS[0] } } ],
        [], sub { $test->{info}->l2_service_bindings() } );
    is( scalar keys %$bindings, 1, q(A binding two sources report is one row) );
}

sub l2_service_bindings_complete : Tests(1) {
    my $test = shift;

    is( $test->{info}->l2_service_bindings_complete(),
        undef, q(No source gives undef) );
}

sub l2_service_bindings_complete__walks_whole__returns_1 : Tests(1) {
    my $test = shift;

    $test->{info}{walk_status}{src} = { complete => 1, rows => 4 };
    my $complete = $test->with_source( [ $ROWS[0] ], ['src'],
        sub { $test->{info}->l2_service_bindings_complete() } );
    is( $complete, 1, q(Complete walk gives 1) );
}

sub l2_service_bindings_complete__rows_none_bound__returns_1 : Tests(1) {
    my $test = shift;

    $test->{info}{walk_status}{src} = { complete => 1, rows => 4 };
    my $complete = $test->with_source( [], ['src'],
        sub { $test->{info}->l2_service_bindings_complete() } );
    is( $complete, 1, q(Table served with no bindings is complete) );
}

sub l2_service_bindings_complete__walk_short__returns_0 : Tests(1) {
    my $test = shift;

    $test->{info}{walk_status}{src}   = { complete => 1, rows => 4 };
    $test->{info}{walk_status}{other} = { complete => 0, rows => 0 };
    my $complete = $test->with_source( [ $ROWS[0] ], [ 'src', 'other' ],
        sub { $test->{info}->l2_service_bindings_complete() } );
    is( $complete, 0, q(One short walk gives 0) );
}

sub l2_service_bindings_complete__table_not_served__undef : Tests(1) {
    my $test = shift;

    $test->{info}{walk_status}{src} = { complete => 1, rows => 0 };
    my $complete = $test->with_source( [], ['src'],
        sub { $test->{info}->l2_service_bindings_complete() } );
    is( $complete, undef, q(Device serving no rows gives undef) );
}

sub l2_service_bindings_complete__device_reports_none__returns_1 : Tests(2) {
    my $test = shift;

    no warnings 'redefine';
    local *SNMP::Info::L2Service::_l2sb_vendor_none = sub {1};
    my $complete = $test->with_source( [], ['src'],
        sub { $test->{info}->l2_service_bindings_complete() } );
    is( $complete, 1, q(Device answering it has no service gives 1) );

    $test->{info}{walk_status}{src} = { complete => 0, rows => 0 };
    $complete = $test->with_source( [ $ROWS[0] ], ['src'],
        sub { $test->{info}->l2_service_bindings_complete() } );
    is( $complete, 0, q(Rows read override the hook) );
}

sub l2_service_bindings_complete__never_walked__undef : Tests(1) {
    my $test = shift;

    my $complete = $test->with_source( [], ['src'],
        sub { $test->{info}->l2_service_bindings_complete() } );
    is( $complete, undef, q(Source the class did not read gives undef) );
}

1;
