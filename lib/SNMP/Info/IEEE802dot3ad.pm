# SNMP::Info::IEEE802dot3ad
#
# Copyright (c) 2018 SNMP::Info Developers
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

package SNMP::Info::IEEE802dot3ad;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Aggregate;

@SNMP::Info::IEEE802dot3ad::ISA = qw/
  SNMP::Info::Aggregate
  Exporter
/;
@SNMP::Info::IEEE802dot3ad::EXPORT_OK = qw/
  agg_ports_lag
/;

our ($VERSION, %MIBS, %FUNCS, %GLOBALS, %MUNGE);

$VERSION = '3.983000';

%MIBS = (
  %SNMP::Info::Aggregate::MIBS,
  'IEEE8023-LAG-MIB' => 'dot3adAggPortSelectedAggID',
);

%GLOBALS = ();

%FUNCS = (
  'ad_lag_ports'    => 'dot3adAggPortListPorts',

  # IEEE8023-LAG-MIB::dot3adAggTable
  'lag_actor_system'   => 'dot3adAggActorSystemID',
  'lag_actor_key'      => 'dot3adAggActorOperKey',
  'lag_partner_system' => 'dot3adAggPartnerSystemID',
  'lag_partner_key'    => 'dot3adAggPartnerOperKey',

  # IEEE8023-LAG-MIB::dot3adAggPortTable
  'lag_port_attached'       => 'dot3adAggPortAttachedAggID',
  'lag_port_partner_system' => 'dot3adAggPortPartnerOperSystemID',
  'lag_port_partner_key'    => 'dot3adAggPortPartnerOperKey',
 );

%MUNGE = (
  'ad_lag_ports'            => \&SNMP::Info::munge_port_list,
  'lag_actor_system'        => \&SNMP::Info::munge_mac,
  'lag_partner_system'      => \&SNMP::Info::munge_mac,
  'lag_port_partner_system' => \&SNMP::Info::munge_mac,
 );

my $LAG_MIB = 'IEEE8023-LAG-MIB::';
my $NO_PARTNER_SYSTEM = '00:00:00:00:00:00';

sub agg_ports_lag {
  my $dev = shift;

  # TODO: implement partial
  my $ports  = $dev->ad_lag_ports();
  my $index  = $dev->bp_index() || {};

  return {} unless ref {} eq ref $ports and scalar keys %$ports;

  my $ret = {};
  foreach my $m ( keys %$ports ) {
    my $idx = $m;
    my $portlist = $ports->{$m};
    next unless $portlist;

    # While dot3adAggTable is indexed by ifIndex, the portlist is indexed
    # with a dot1dBasePort, so we need to use dot1dBasePortIfIndex to map to
    # the ifIndex. If we don't have dot1dBasePortIfIndex assume
    # dot1dBasePort = ifIndex
    for ( my $i = 0; $i <= scalar(@$portlist); $i++ ) {
      my $ifindex = $i+1;
      if ( exists($index->{$i+1}) and defined($index->{$i+1}) ) {
        $ifindex = $index->{$i+1};
      }
      $ret->{$ifindex} = $idx if ( @$portlist[$i] );
    }
  }

  return $ret;
}

sub lag_groups {
  my $self = shift;

  my $groups = {};
  my $map    = $self->_lag_aggregator_map() || {};
  my $rows   = $self->_lag_identity_rows($map);
  foreach my $key ( keys %$rows ) {
    $groups->{$key} = $self->_lag_identity_record( $rows->{$key} );
  }
  $self->_lag_add_members( $groups, $map );
  $self->_lag_vendor_groups($groups);
  $self->_lag_drop_port_rows( $groups, $map );

  return $groups;
}

sub mlag_domains {
  my $self = shift;

  return $self->_lag_vendor_domains() || {};
}

sub lag_groups_complete {
  my $self = shift;

  my $groups  = $self->lag_groups();
  my $domains = $self->mlag_domains();

  foreach my $method ( $self->_lag_walked_methods() ) {
    my $status = $self->walk_status($method) or next;
    return 0 unless $status->{complete};
  }
  return unless scalar keys %$groups or scalar keys %$domains;

  return 1;
}

# Private hooks: vendor classes override these.
sub _lag_vendor_domains { return {} }

sub _lag_vendor_groups { return }

sub _lag_vendor_walked { return }

# Aggregator row index => key of the record that row describes
sub _lag_aggregator_map {
  my $self = shift;

  my $rows = $self->lag_actor_system() || {};
  return { map { $_ => $_ } keys %$rows };
}

sub _lag_walked_methods {
  my $self = shift;

  return (
    qw/lag_actor_system lag_actor_key lag_partner_system lag_partner_key
      lag_port_attached lag_port_partner_system lag_port_partner_key/,
    $self->_lag_vendor_walked()
  );
}

# Hashref: record key => the aggregator row that supplies its identity.
# A row indexed by a port attached to a different aggregator is that port's
# idle aggregator, so it loses to any other row mapped onto the same key.
sub _lag_identity_rows {
  my ( $self, $map ) = @_;

  my $rows     = $self->lag_actor_system() || {};
  my $attached = $self->lag_port_attached() || {};
  my ( %preferred_row, %lowest_row );
  foreach my $row ( sort { $a <=> $b } keys %$rows ) {
    my $key = defined $map->{$row} ? $map->{$row} : $row;
    $lowest_row{$key} = $row unless exists $lowest_row{$key};
    my $target = $attached->{$row};
    next if $target and $target != $row;
    $preferred_row{$key} = $row unless exists $preferred_row{$key};
  }
  return { %lowest_row, %preferred_row };
}

# A member port's own row, when the port is attached to another aggregate
# and nothing else describes it, is not an aggregate
sub _lag_drop_port_rows {
  my ( $self, $groups, $map ) = @_;

  my $attached = $self->lag_port_attached() || {};
  foreach my $key ( keys %$groups ) {
    my $record = $groups->{$key};
    next if scalar keys %{ $record->{members} };
    next if $record->{mc} or $record->{peer_link};
    my $target = $attached->{$key} or next;
    $target = $map->{$target} if defined $map->{$target};
    delete $groups->{$key} if $target != $key;
  }
  return;
}

sub _lag_partner_or_undef {
  my $system = shift;

  return if !defined $system or $system eq $NO_PARTNER_SYSTEM;
  return $system;
}

sub _lag_identity_record {
  my ( $self, $row ) = @_;

  my $record  = _lag_new_record();
  my %columns = (
    actor_system   => [ lag_actor_system   => 'dot3adAggActorSystemID' ],
    actor_key      => [ lag_actor_key      => 'dot3adAggActorOperKey' ],
    partner_system => [ lag_partner_system => 'dot3adAggPartnerSystemID' ],
    partner_key    => [ lag_partner_key    => 'dot3adAggPartnerOperKey' ],
  );
  foreach my $field ( keys %columns ) {
    my ( $method, $leaf ) = @{ $columns{$field} };
    my $value = ( $self->$method() || {} )->{$row};
    $record->{$field} = $value;
    $record->{sources}{$field} = $LAG_MIB . $leaf if defined $value;
  }
  $self->_lag_settle_partner($record);
  return $record;
}

# An all-zero partner system means LACP found no partner
sub _lag_settle_partner {
  my ( $self, $record ) = @_;

  $record->{partner_system}
    = _lag_partner_or_undef( $record->{partner_system} );
  if ( defined $record->{partner_system} ) {
    $record->{lacp} = 1;
    return;
  }
  $record->{partner_key} = undef;
  delete $record->{sources}{partner_system};
  delete $record->{sources}{partner_key};
  return;
}

sub _lag_new_record {
  return {
    members        => {},
    actor_system   => undef,
    actor_key      => undef,
    partner_system => undef,
    partner_key    => undef,
    lacp           => 0,
    sources        => {},
  };
}

sub _lag_agg_ports {
  my $self = shift;

  return {} unless $self->can('agg_ports');
  my $ports = $self->agg_ports();
  return ref {} eq ref $ports ? $ports : {};
}

# Members from agg_ports; an aggregate agg_ports names no member of falls
# back to the ports that report themselves attached to it
sub _lag_add_members {
  my ( $self, $groups, $map ) = @_;

  my %from_agg_ports;
  my $agg_ports = $self->_lag_agg_ports();
  foreach my $port ( keys %$agg_ports ) {
    $from_agg_ports{ $agg_ports->{$port} }{$port} = 1;
  }
  my %from_attached;
  my $attached = $self->lag_port_attached() || {};
  foreach my $port ( keys %$attached ) {
    next unless $attached->{$port};
    my $key = defined $map->{ $attached->{$port} }
      ? $map->{ $attached->{$port} }
      : $attached->{$port};
    $from_attached{$key}{$port} = 1;
  }

  foreach my $key ( keys %from_agg_ports ) {
    $self->_lag_place_members( $groups, $key, $from_agg_ports{$key},
      'agg_ports' );
  }
  foreach my $key ( grep { !$from_agg_ports{$_} } keys %from_attached ) {
    $self->_lag_place_members( $groups, $key, $from_attached{$key},
      $LAG_MIB . 'dot3adAggPortAttachedAggID' );
  }
  return;
}

sub _lag_place_members {
  my ( $self, $groups, $key, $ports, $source ) = @_;

  my $record = $groups->{$key} ||= _lag_new_record();
  my $systems = $self->lag_port_partner_system() || {};
  my $keys    = $self->lag_port_partner_key()    || {};
  foreach my $port ( keys %$ports ) {
    my $system = _lag_partner_or_undef( $systems->{$port} );
    $record->{members}{$port} = {
      partner_system => $system,
      partner_key    => defined $system ? $keys->{$port} : undef,
    };
  }
  $record->{sources}{members} = $source;
  return;
}

1;

__END__

=head1 NAME

SNMP::Info::IEEE802dot3ad - SNMP Interface to IEEE Aggregated Links

=head1 AUTHOR

SNMP::Info Developers

=head1 SYNOPSIS

    # Let SNMP::Info determine the correct subclass for you.
    my $info = new SNMP::Info(
        AutoSpecify => 1,
        Debug       => 1,
        DestHost    => 'myswitch',
        Community   => 'public',
        Version     => 2
    ) or die "Can't connect to DestHost.\n";

List one device's aggregates, its multi-chassis domains, and whether the
tables were read in full:

    my $interfaces = $info->interfaces();
    my $groups     = $info->lag_groups();

    foreach my $agg ( sort { $a <=> $b } keys %$groups ) {
        my $group = $groups->{$agg};
        printf "%s: lacp %s, actor %s, partner %s\n",
            $interfaces->{$agg}, $group->{lacp},
            $group->{actor_system}   // 'none',
            $group->{partner_system} // 'none';

        foreach my $port ( sort { $a <=> $b } keys %{ $group->{members} } ) {
            print "  member $interfaces->{$port}\n";
        }
        if ( my $mc = $group->{mc} ) {
            printf "  %s group %s in domain %s\n", $mc->{kind},
                $mc->{group}, $mc->{domain} // 'none';
        }
        print "  peer link\n" if $group->{peer_link};
    }

    my $domains = $info->mlag_domains();
    foreach my $id ( sort keys %$domains ) {
        my $domain = $domains->{$id};
        printf "%s %s: peer %s, system %s\n", $domain->{kind}, $id,
            $domain->{peer} // 'none', $domain->{system_mac} // 'none';
    }

    my $complete = $info->lag_groups_complete();
    warn "LAG tables were not fully read\n"
        if defined $complete and !$complete;

SNMP::Info reports each device on its own; grouping aggregates across
devices is the caller's work. This example takes one object per polled
device. It finds the actor systems that several devices present, as the
two switches of an MLAG pair or the members of an ESI-LAG set do, and the
aggregates on other devices whose partner is such a system:

    # %devices: host name => SNMP::Info object
    my %presented_by;    # actor system => { host => [ aggregate ifIndex ] }
    foreach my $host ( sort keys %devices ) {
        my $groups = $devices{$host}->lag_groups();
        foreach my $agg ( sort { $a <=> $b } keys %$groups ) {
            my $system = $groups->{$agg}{actor_system} // next;
            push @{ $presented_by{$system}{$host} }, $agg;
        }
    }

    foreach my $host ( sort keys %devices ) {
        my $groups = $devices{$host}->lag_groups();
        foreach my $agg ( sort { $a <=> $b } keys %$groups ) {
            my $partner = $groups->{$agg}{partner_system} // next;
            my $peers   = $presented_by{$partner} or next;
            next unless keys %$peers > 1;
            printf "%s aggregate %s faces %s as one LACP system %s\n",
                $host, $agg, join( ' and ', sort keys %$peers ), $partner;
        }
    }

=head1 DESCRIPTION

SNMP::Info::IEEE802dot3ad reports a device's link aggregates from
F<IEEE8023-LAG-MIB>: each aggregate's members, its LACP actor and partner,
and, where the device class reads a vendor source, its multi-chassis
group and the device's multi-chassis domains.

Every class that inherits L<SNMP::Info::Layer2> or L<SNMP::Info::Layer3>
has these methods.

These methods report only what the device returns. They never infer an
aggregate, a partner or a domain from another device. A field the device
does not serve is undef or absent.

L<SNMP::Info::Layer3::Nexus>, L<SNMP::Info::Layer3::Extreme> and
L<SNMP::Info::RapidCity> fill C<mc> and C<mlag_domains()>; Nexus and
RapidCity also fill C<peer_link>. Members come from each class's
C<agg_ports()>, for example in L<SNMP::Info::Layer3::Juniper> and
L<SNMP::Info::Layer3::Extreme>.

=head2 Terms

=over

=item aggregate

Ports the device bundles into one logical link: a port-channel, LAG, MLT,
trunk or C<ae> interface.

=item aggregator row

A row of the F<IEEE8023-LAG-MIB> C<dot3adAggTable>, indexed by ifIndex,
holding the LACP actor and partner of one aggregator. Some devices also
serve a row for each member port.

=item actor

This device's end of an LACP aggregate: its LACP system ID and
operational key.

=item partner

The far end of an LACP aggregate, as this device reports it.

=item static aggregate

An aggregate that does not run LACP. It has no partner.

=item multi-chassis group

An aggregate whose members are split across two devices that present it
to the far end as one aggregate: a Cisco vPC, an Extreme MLAG port, or an
SMLT.

=item multi-chassis domain

The pairing of two devices that serve multi-chassis groups together: a
vPC domain, an MLAG peer, or an IST or virtual IST session.

=item peer link

The aggregate that joins the two devices of a multi-chassis domain, such
as a vPC peer link or an IST.

=back

ESI-LAG has no field of its own. It shows only as one actor system that
several devices present, as the second SYNOPSIS example finds.

=head2 Inherited Classes

L<SNMP::Info::Aggregate>

=head2 Required MIBs

=over

=item F<IEEE8023-LAG-MIB>

=back

=head2 For Class Authors

A device class adapts these methods by overriding four private hooks.
Each has a default here.

=over 4

=item C<_lag_aggregator_map()>

Returns a HASH reference mapping each aggregator row's ifIndex to the key
of the record that row describes. The default maps each row to itself.
Override it when C<agg_ports()> keys an aggregate by a different ifIndex,
so the row and the members land on one record: L<SNMP::Info::RapidCity>
maps an MLT's row to its designated port, L<SNMP::Info::Layer3::Juniper>
maps a logical unit's row to its physical C<ae> interface.

=item C<_lag_vendor_groups($groups)>

Receives the records after the identity and members are placed, and adds
or changes records in place, such as C<mc> and C<peer_link>. A new record
starts from C<SNMP::Info::IEEE802dot3ad::_lag_new_record()>. The return
value is ignored. The default does nothing.

=item C<_lag_vendor_domains()>

Returns the C<mlag_domains()> HASH reference. The default returns an
empty one.

=item C<_lag_vendor_walked()>

Returns the names of the table methods the class's hooks read, so that
C<lag_groups_complete()> checks their walks too. The default returns an
empty list.

=back

The record rules:

=over 4

=item Members

Members come from C<agg_ports()> when the class defines it; each value
becomes a record key, so it should equal the key C<_lag_aggregator_map()>
gives the aggregate's own row, or the row and its members land on two
records. An aggregate C<agg_ports()> names no member of takes
as members the ports whose C<dot3adAggPortAttachedAggID> names it, through
C<_lag_aggregator_map()>.

=item Identity

When several aggregator rows map to one key, the actor and partner come
from the lowest-numbered row that is not a port attached to a different
aggregator. When every row is such a port, they come from the lowest
row.

=item Dropped rows

After C<_lag_vendor_groups()>, a record is removed when it has no
members, no C<mc> and no C<peer_link>, and its key is a port attached to
a different aggregate. That row is the member port's own idle aggregator,
not an aggregate.

=back

=head1 METHODS

=over 4

=item C<agg_ports_lag>

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.

=item C<lag_groups>

Returns a HASH reference with one record per aggregate. The key is the
ifIndex C<agg_ports()> uses for the aggregate, else the ifIndex of its
aggregator row. On most devices this is the aggregate interface. The
exceptions:

=over 4

=item *

Passport and Baystack devices key an MLT by its designated port when it
has one (L<SNMP::Info::RapidCity>).

=item *

Junos devices key an aggregate by the physical C<ae> interface, not its
logical unit (L<SNMP::Info::Layer3::Juniper>).

=item *

Extreme devices key an aggregate by its load sharing master port, and
an MLAG port with no load sharing row by the port
(L<SNMP::Info::Layer3::Extreme>).

=back

Each record has these fields:

=over 4

=item C<members>

HASH reference keyed by member ifIndex. Each value is a HASH reference
with C<partner_system> and C<partner_key>, the partner that member port
reports (C<dot3adAggPortPartnerOperSystemID>,
C<dot3adAggPortPartnerOperKey>). Both are undef when the port reports no
partner, including a partner system ID of all zeros. C<members> is empty
when the device names no member.

=item C<actor_system>, C<actor_key>

The actor's LACP system ID and operational key, from the aggregator row.
Undef when the device serves no aggregator row for the aggregate, as for a
static aggregate on some devices.

=item C<partner_system>, C<partner_key>

The partner's LACP system ID and operational key, from the aggregator row.
Both are undef when the device reports no partner, including a partner
system ID of all zeros.

=item C<lacp>

1 when C<partner_system> is defined, 0 otherwise. It is 0 for a static
aggregate and for an LACP aggregate that has not found its partner.

=item C<mc>

Present only on a multi-chassis group. A HASH reference with these keys:

=over 4

=item C<kind>

C<vpc> (Cisco NX-OS), C<mlag> (Extreme EXOS) or C<smlt> (Passport and
Baystack).

=item C<group>

The device's identifier for the group: the vPC id, the MLAG port id
(C<extremeMlagPortId>) or the MLT id.

=item C<domain>

The key in C<mlag_domains()> of the domain the group belongs to. Undef
when the device serves none for the group.

=item C<state>

The group's state, as the device serves it: the vPC host link status,
the MLAG local link status or the MLT running type. Undef when the device
serves none.

=back

=item C<peer_link>

Present, with the value 1, only on the aggregate that is a multi-chassis
domain's peer link.

=item C<sources>

HASH reference naming the MIB object each field with a value was read
from, such as C<IEEE8023-LAG-MIB::dot3adAggActorSystemID>. The
C<members> source is C<agg_ports> when C<agg_ports()> lists the members,
else C<IEEE8023-LAG-MIB::dot3adAggPortAttachedAggID>, or a vendor object
the device class names.

=back

An example record, a vPC running LACP:

    369098761 => {
        members => {
            436207616 => {
                partner_system => '02:00:00:00:00:20',
                partner_key    => 1,
            },
        },
        actor_system   => '02:00:00:00:00:01',
        actor_key      => 32778,
        partner_system => '02:00:00:00:00:20',
        partner_key    => 1,
        lacp           => 1,
        mc             => {
            kind   => 'vpc',
            group  => 10,
            domain => 1,
            state  => 'up',
        },
        sources => {
            members        => 'agg_ports',
            actor_system   => 'IEEE8023-LAG-MIB::dot3adAggActorSystemID',
            actor_key      => 'IEEE8023-LAG-MIB::dot3adAggActorOperKey',
            partner_system => 'IEEE8023-LAG-MIB::dot3adAggPartnerSystemID',
            partner_key    => 'IEEE8023-LAG-MIB::dot3adAggPartnerOperKey',
            mc             => 'CISCO-VPC-MIB::cVpcStatusHostLinkIfIndex',
        },
    }

=item C<mlag_domains>

Returns a HASH reference with one record per multi-chassis domain, keyed
by the domain's identifier on the device: the vPC domain id, the MLAG
peer name, or C<vist> or C<ist>. Empty when the device class reads no
multi-chassis source or the device serves no domain. Each record has
C<kind> and C<sources>. The other fields are filled only for some
vendors; a field the device does not serve is undef or absent:

=over 4

=item C<kind>

C<vpc> (Cisco NX-OS), C<mlag> (Extreme EXOS), or C<vist> or C<ist> (a
virtual IST or an IST, on Passport and Baystack).

=item C<system_mac>

The LACP system ID the domain presents for its multi-chassis groups.

=item C<role>

The device's role in the domain. Cisco NX-OS only.

=item C<peer>

The address of the other device of the domain.

=item C<peer_link>

The ifIndex of the peer link aggregate, a key of C<lag_groups()>. Cisco
NX-OS only.

=item C<status>

The state of the session with the other device, as the device serves it.

=item C<vlan>

The VLAN the IST or virtual IST runs on. Passport and Baystack only.

=item C<sources>

HASH reference naming the MIB object each field with a value was read
from, as in C<lag_groups()>.

=back

An example record, a vPC domain:

    1 => {
        kind       => 'vpc',
        system_mac => '02:00:00:00:00:01',
        role       => 'primary',
        peer       => '192.0.2.2',
        peer_link  => 369098752,
        status     => 'alive',
        sources    => {
            system_mac => 'CISCO-VPC-MIB::cVpcSystemOperMacAddress',
            role       => 'CISCO-VPC-MIB::cVpcRoleStatus',
            peer       => 'CISCO-VPC-MIB::cVpcPeerKeepAliveDestAddr',
            peer_link  => 'CISCO-VPC-MIB::cVpcStatusPeerLinkIfIndex',
            status     => 'CISCO-VPC-MIB::cVpcPeerKeepAliveStatus',
        },
    }

=item C<lag_groups_complete>

Returns whether the F<IEEE8023-LAG-MIB> and vendor multi-chassis tables
behind C<lag_groups()> and C<mlag_domains()> were read in full. A walk
that only a class's C<agg_ports()> makes counts only where that class
lists it (Extreme and Juniper do). It performs the walks itself. It
returns:

=over 4

=item C<0>

A walk of one of those tables was incomplete (see
L<SNMP::Info/"Incomplete Walks">), including a walk that failed before
returning any row. The records may be missing data.

=item C<undef>

Every walk completed, and both methods returned no record. The device
has no aggregate and no domain.

=item C<1>

Every walk completed, and at least one method returned a record.

=back

=back

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over 4

=item C<ad_lag_ports>

(C<dot3adAggPortListPorts>)

=item C<lag_actor_system>

(C<dot3adAggActorSystemID>)

=item C<lag_actor_key>

(C<dot3adAggActorOperKey>)

=item C<lag_partner_system>

(C<dot3adAggPartnerSystemID>)

=item C<lag_partner_key>

(C<dot3adAggPartnerOperKey>)

=item C<lag_port_attached>

(C<dot3adAggPortAttachedAggID>)

=item C<lag_port_partner_system>

(C<dot3adAggPortPartnerOperSystemID>)

=item C<lag_port_partner_key>

(C<dot3adAggPortPartnerOperKey>)

=back

=cut
