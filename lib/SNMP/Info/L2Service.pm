# SNMP::Info::L2Service
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

package SNMP::Info::L2Service;

use strict;
use warnings;
use Exporter;
use SNMP::Info;

@SNMP::Info::L2Service::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::L2Service::EXPORT_OK = qw//;

our ( $VERSION, %MIBS, %FUNCS, %GLOBALS, %MUNGE );

$VERSION = '3.985005';

%MIBS    = ();
%GLOBALS = ();
%FUNCS   = ();
%MUNGE   = ();

my @FIELDS = qw/type id vlan ifindex instance/;

sub l2_service_bindings {
    my $self = shift;

    my %bindings;
    foreach my $row ( $self->_l2sb_vendor_rows() ) {
        my %binding = map { $_ => $row->{$_} } @FIELDS;
        $binding{ifindex} ||= 0;
        $bindings{ _l2sb_key( \%binding ) } = \%binding;
    }
    return \%bindings;
}

sub l2_service_bindings_complete {
    my $self = shift;

    my @methods = $self->_l2sb_vendor_walked();
    return unless @methods;
    my $bindings = $self->l2_service_bindings();
    return 1 if !keys %$bindings and $self->_l2sb_vendor_none();

    my $rows = 0;
    foreach my $method (@methods) {
        my $status = $self->walk_status($method) or next;
        return 0 unless $status->{complete};
        $rows += $status->{rows} || 0;
    }
    return unless $rows or keys %$bindings;
    return 1;
}

sub _l2sb_key {
    my $binding = shift;
    return join '.', map { defined $binding->{$_} ? $binding->{$_} : '' }
        @FIELDS;
}

sub _l2sb_vendor_rows   { return }
sub _l2sb_vendor_walked { return }
sub _l2sb_vendor_none   { return }

1;

__END__

=head1 NAME

SNMP::Info::L2Service - SNMP Interface to layer 2 service bindings

=head1 AUTHOR

SNMP::Info Developers

=head1 SYNOPSIS

    my $info = SNMP::Info->new(
        AutoSpecify => 1,
        DestHost    => 'myswitch',
        Community   => 'public',
        Version     => 2
    ) or die "Can't connect to DestHost.\n";

    my $bindings = $info->l2_service_bindings();
    foreach my $binding ( values %$bindings ) {
        printf "VLAN %s is %s %s\n", $binding->{vlan} // '-',
            $binding->{type}, $binding->{id};
    }

    my $complete = $info->l2_service_bindings_complete();
    warn "service bindings were not fully read\n"
        if defined $complete and !$complete;

=head1 DESCRIPTION

Fabric and overlay networks carry a VLAN across the network inside a
service ID: an SPB I-SID or a VXLAN VNI. The service ID, not the VLAN
number, says which VLANs on different devices share a broadcast domain.
This role reports each binding a device holds between a local VLAN and a
service ID. Grouping bindings into domains is the caller's work: a service
ID can be reused in fabrics that are not connected.

The role reads no table itself. A device class supplies the rows through
the hooks under L</"For Class Authors">.

=head2 Inherited Classes

=over

=item SNMP::Info

=back

=head2 Required MIBs

None.

=head2 For Class Authors

=over 4

=item C<_l2sb_vendor_rows()>

Returns a list of HASH references, one per binding, with the fields
described under C<l2_service_bindings()>. Leave out a binding the device
reports as unassigned, such as an I-SID of 0. The default returns an empty
list.

=item C<_l2sb_vendor_walked()>

Returns the names of the table methods C<_l2sb_vendor_rows()> reads, so
that C<l2_service_bindings_complete()> checks their walks. The default
returns an empty list.

=item C<_l2sb_vendor_none()>

Returns true when the device answered that it has no service configured,
so C<_l2sb_vendor_rows()> read no table and an empty result is complete.
The default returns false.

=back

=head1 GLOBALS

None.

=head1 TABLE METHODS

=over

=item $info->l2_service_bindings()

Returns a reference to a hash of bindings. Each value is a reference to a
hash with these fields:

=over

=item C<vlan>

The local VLAN ID, or undef where the binding has no local VLAN.

=item C<type>

The kind of service ID: C<isid> for an SPB I-SID, C<vni> for a VXLAN VNI.

=item C<id>

The service ID.

=item C<ifindex>

0 when the binding covers the whole VLAN, otherwise the ifIndex of the
port it is bound to.

=item C<instance>

The switching instance the VLAN belongs to, where a device has more than
one; undef otherwise.

=back

The key joins C<type>, C<id>, C<vlan>, C<ifindex> and C<instance> with
dots, an undef field as the empty string, for example C<isid.20010.10.0.>.
C<instance> is last because an instance name can contain dots. A caller
needs only the values.

An L3 VNI binds a VNI to a VRF, not to a VLAN, and is not reported.

=item $info->l2_service_bindings_complete()

Returns 1 when every table the class reads was walked in full, so that
C<l2_service_bindings()> is the whole set, empty or not, or when the
device answered that it has no service configured. Returns 0 when a
walk was cut short, so bindings may be missing. Returns undef when the
class has no source, or the device serves none of the tables it reads.

=back

=cut
