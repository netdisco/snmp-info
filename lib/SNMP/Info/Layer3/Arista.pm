# SNMP::Info::Layer3::Arista
#
# Copyright (c) 2008 Arista Networks, Inc.
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
#     * Neither the name of Arista Networks, Inc. nor the
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

package SNMP::Info::Layer3::Arista;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::MAU;
use SNMP::Info::Aggregate 'agg_ports_ifstack';

@SNMP::Info::Layer3::Arista::ISA = qw/
    SNMP::Info::Aggregate
    SNMP::Info::MAU
    SNMP::Info::Layer3
    Exporter
/;
@SNMP::Info::Layer3::Arista::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.983000';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::MAU::MIBS,
    %SNMP::Info::Aggregate::MIBS,
    'ARISTA-PRODUCTS-MIB' => 'aristaDCS7124S',
    'ARISTA-VRF-MIB'      => 'aristaVrfState',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::MAU::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::MAU::FUNCS,

    # ARISTA-VRF-MIB::aristaVrfTable and aristaVrfIfTable
    'vrf_arista_rd'    => 'aristaVrfRouteDistinguisher',
    'vrf_arista_state' => 'aristaVrfState',
    'vrf_arista_if'    => 'aristaVrfIfMembership',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::MAU::MUNGE,
);

# use MAU-MIB for admin. duplex and admin. speed
*SNMP::Info::Layer3::Arista::i_duplex_admin
    = \&SNMP::Info::MAU::mau_i_duplex_admin;
*SNMP::Info::Layer3::Arista::i_speed_admin
    = \&SNMP::Info::MAU::mau_i_speed_admin;

sub vendor {
    return 'arista';
}

sub os {
    return 'EOS';
}

sub os_ver {
    my $arista = shift;
    my $descr  = $arista->description();

    if (defined ($descr)) {
      my $os_ver = undef;
      $os_ver = $1 if ($descr =~ /\s+EOS\s+version\s+(\S+)\s+/);
      return $os_ver;
    }
    return;
}

sub model {
    my $arista = shift;
    my $id     = $arista->id();

    my $model = &SNMP::translateObj($id);
    return $id unless defined $model;

    $model =~ s/^arista//;
    return $model;
}

# The LLDP MIB leaves it up in the air what the index means.
# On EOS, it's a dot1d port.
sub lldp_if {
    my $arista  = shift;
    my $partial = shift;

    # We pick a column that someone else is likely to want,
    # so that the cache means that hopefully this doesn't
    # cause any more SNMP transactions in total.
    my $desc     = $arista->lldp_rem_desc($partial) || {};
    my $bp_index = $arista->bp_index() || {};

    my $lldp_if = {};
    foreach my $key ( keys %$desc ) {
        my @aOID = split( '\.', $key );
        my $port = $aOID[1];
        $lldp_if->{$key} = $bp_index->{$port};
    }
    return $lldp_if;
}

sub set_i_vlan {
    my ($arista, $vlan, $iid) = @_;
    return $arista->set_qb_i_vlan($vlan, $iid);
}

sub agg_ports { return agg_ports_ifstack(@_) }

sub _context_kinds {
    my ( $arista, $feature ) = @_;

    return ['vrf'] if ( $feature // '' ) eq 'vrf';
    return;
}

# A VRF is a context named like it; the v2c community is community@VRF
sub _snmp_context {
    my ( $arista, $kind, $id ) = @_;

    return unless ( $kind // '' ) eq 'vrf';
    return if !defined $id or $id eq q() or $id eq 'default';
    return { kind => 'vrf', id => $id, v2c => "%s\@$id", v3 => $id };
}

# Each VRF reads in its own context. The default context serves only the
# default instance's rows, but its aristaVrfIfTable names every VRF port.
sub _vrf_context_filters { return 1; }

sub _vrf_default_context_members { return 1; }

# A VRF context, named for its VRF, serves no aristaVrfTable row
sub _vrf_context_is_instance_name { return 1; }

# aristaVrfTable is indexed by the length-prefixed VRF name. INVALID is no
# route distinguisher. aristaVrfState is not read into oper: see the POD.
# The table has no row for the default VRF, so a whole walk of it lists
# default even with no row.
sub _vrf_vendor_instances {
    my $arista = shift;

    my $rd    = $arista->vrf_arista_rd()    || {};
    my $state = $arista->vrf_arista_state() || {};
    my %iids  = map { $_ => 1 } keys %$rd, keys %$state;

    my %instances;
    foreach my $iid ( keys %iids ) {
        my ($name) = $arista->_vrf_decode_name($iid);
        next if !defined $name or !length $name or $name eq 'default';

        my $record = SNMP::Info::VRF::_vrf_record( $name, 'vrf', 'device' );
        my $served = $rd->{$iid};
        $record->{rd} = $arista->_vrf_rd($served)
            if defined $served and $served ne 'INVALID';
        $record->{sources}{list} = 'ARISTA-VRF-MIB';
        $record->{sources}{rd}   = 'ARISTA-VRF-MIB' if defined $record->{rd};
        $instances{$name} = $record;
    }
    $arista->_vrf_list_default( \%instances, 'ARISTA-VRF-MIB' )
        if %iids or $arista->_arista_vrf_table_answered();
    return \%instances;
}

# True when both aristaVrfTable walks were recorded complete. An absent
# outcome is a poller MIB problem, not an answer from the device.
sub _arista_vrf_table_answered {
    my $arista = shift;

    foreach my $method (qw/vrf_arista_rd vrf_arista_state/) {
        my $status = $arista->walk_status($method) or return 0;
        return 0 if !$status->{complete} or defined $status->{reason};
    }
    return 1;
}

sub _vrf_vendor_list_methods {
    return qw/vrf_arista_rd vrf_arista_state vrf_arista_if/;
}

# aristaVrfIfMembership is indexed by ifIndex and holds the VRF name
sub _vrf_vendor_membership {
    my $arista = shift;

    my $rows = $arista->vrf_arista_if() || {};
    return {
        map  { $_ => $rows->{$_} }
        grep { length( $rows->{$_} // q() ) and $rows->{$_} ne 'default' }
            keys %$rows
    };
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Arista - SNMP Interface to Arista Networks EOS

=head1 AUTHOR

Bill Fenner

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $arista = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
		 	)
    or die "Can't connect to DestHost.\n";

 my $class      = $arista->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Arista Networks EOS-based devices

=head2 Inherited Classes

=over

=item SNMP::Info::Aggregate

=item SNMP::Info::Layer3

=item SNMP::Info::MAU

=back

=head2 Required MIBs

=over

=item F<ARISTA-PRODUCTS-MIB>

=item F<ARISTA-VRF-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::Aggregate/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::MAU/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar values from SNMP

=over

=item $arista->vendor()

Returns 'arista'

=item $arista->model()

Tries to reference $arista->id() to one of the product MIBs listed above

Removes 'arista' from the name for readability.

=item $arista->os()

Returns 'EOS'

=item $arista->os_ver()

Grabs the os version from C<sysDescr>

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $arista->i_duplex_admin()

Returns info from F<MAU-MIB>

=item $arista->i_speed_admin()

Returns info from F<MAU-MIB>

=item $arista->lldp_if()

Returns the mapping to the SNMP Interface Table.

=item $arista->vrf_arista_rd()

Returns the route distinguisher of each VRF, keyed by the length-prefixed
VRF name. EOS serves C<INVALID> for a VRF with none.

(C<aristaVrfRouteDistinguisher>)

=item $arista->vrf_arista_state()

Returns the state of each VRF, C<active> or C<inactive>, keyed by the
length-prefixed VRF name.

(C<aristaVrfState>)

=item $arista->vrf_arista_if()

Returns the name of the VRF each routed interface is in, keyed by ifIndex.

(C<aristaVrfIfMembership>)

=item C<agg_ports>

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.

=back

=head2 VRF Instances

See L<SNMP::Info::VRF/"VRF Instances"> for the readers. EOS has no
C<MPLS-L3VPN-STD-MIB>, so F<ARISTA-VRF-MIB> lists the VRFs and the ports
they hold; the source is C<ARISTA-VRF-MIB>. A route distinguisher of
C<INVALID> is none. C<oper> is undef: EOS 4.36 serves C<aristaVrfState>
C<inactive> for VRFs its CLI shows routing, so the state is not used as an
operational status. A port C<aristaVrfIfTable> gives C<default> is a port
of the default instance, absent from C<i_vrf()>.

C<aristaVrfTable> has no row for the default VRF, so a device with no VRF
serves it no row at all. A complete walk of C<aristaVrfRouteDistinguisher>
and C<aristaVrfState> lists C<default> with the source C<ARISTA-VRF-MIB>
even then, and C<vrf_instances_complete()> reports 1, none configured (see
L<SNMP::Info::VRF/"Completeness">).
Where neither walk was recorded, such as on an object primed from a cache,
or the poller could not resolve the MIB, the list reads as unsupported,
undef. A device that does not implement the MIB answers the walk as one
with no VRF does, so it reads none.

Each VRF reads in its own context, which serves only that VRF's addresses
and neighbors. The default context serves the default instance only, such
as C<Management0>, yet C<i_vrf()> there maps every VRF port from
C<aristaVrfIfTable>. A VRF context serves no F<ARISTA-VRF-MIB> row, so
C<i_vrf()> there takes the instance from the context name, which is the
VRF name.

=over

=item $arista->context_kinds($feature)

See L<SNMP::Info/"context_kinds">. Returns C<['vrf']> for C<vrf>.

=item $arista->snmp_context($kind, $id)

For C<vrf>, the answer is C<{ kind =E<gt> 'vrf', id =E<gt> $name,
v2c =E<gt> '%s@$name', v3 =E<gt> $name }>: the community, C<@>, then the VRF
name. The default VRF and an empty name have no context, so nothing is
returned.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"TABLE METHODS"> for details.

=head1 SET METHODS

These are methods that provide SNMP set functionality for overridden methods
or provide a simpler interface to complex set operations.  See
L<SNMP::Info/"SETTING DATA VIA SNMP"> for general information on set
operations.

=over

=item set_i_vlan()

=back

=cut
