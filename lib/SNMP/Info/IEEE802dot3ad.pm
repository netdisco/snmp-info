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
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $info->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

This class provides access to Aggregated Links configuration on devices
implementing C<IEEE8023-LAG-MIB>.

Use or create in a subclass of SNMP::Info.  Do not use directly.

=head2 Inherited Classes

L<SNMP::Info::Aggregate>

=head2 Required MIBs

=over

=item F<IEEE8023-LAG-MIB>

=back

=head1 METHODS

The role reports only what the device returns: it never infers a group from
another device, and a field the device does not serve is undef or absent.

=over 4

=item C<agg_ports_lag>

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.

=item C<lag_groups>

Returns a HASH reference with one record per aggregate, keyed by the
aggregate's ifIndex. When several F<IEEE8023-LAG-MIB> rows describe one
aggregate, the identity comes from the lowest row that is not a port
attached to a different aggregator. Each record has these fields:

=over 4

=item C<members>

HASH reference keyed by member ifIndex. Each value is a HASH reference with
C<partner_system> and C<partner_key>, the partner the member port reports
(undef when it reports none).

=item C<actor_system>, C<actor_key>

The local LACP system ID and operational key, or undef for an aggregate with
no F<IEEE8023-LAG-MIB> row (a static aggregate).

=item C<partner_system>, C<partner_key>

The remote LACP system ID and operational key. Both are undef when the device
reports no partner, including a partner system ID of all zeros.

=item C<lacp>

1 when a partner system is reported, 0 otherwise.

=item C<mc>, C<peer_link>

Present only when a class that reads a vendor multi-chassis source reports
them. C<mc> is a HASH reference with C<kind>, C<group>, C<domain> and
C<state>; C<peer_link> is 1 for the channel carrying the peer link.

=item C<sources>

HASH reference naming where each reported field was read, such as
C<IEEE8023-LAG-MIB::dot3adAggActorSystemID>. The C<members> source is
C<agg_ports> when the class's C<agg_ports()> lists members of the aggregate,
otherwise C<IEEE8023-LAG-MIB::dot3adAggPortAttachedAggID>.

=back

A class that defines C<agg_ports()> supplies the members; an aggregate it
lists but the device does not describe in C<IEEE8023-LAG-MIB> gets a record
with C<lacp> 0.

An F<IEEE8023-LAG-MIB> row for a member port that is attached to a different
aggregate, and that nothing else describes, is not reported as an aggregate.

=item C<mlag_domains>

Returns a HASH reference keyed by the device's own multi-chassis domain or
peer identifier. Empty in this role; classes that read a vendor source
supply the records.

=item C<lag_groups_complete>

Returns 0 when a walk the records depend on was incomplete (see
L<SNMP::Info/"Incomplete Walks">), including a walk that failed before
returning any row. Otherwise returns undef when C<lag_groups> and
C<mlag_domains> are both empty, and 1 when there are records. A caller can
tell a device with no aggregates (undef) from one that could not be read (0).

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
