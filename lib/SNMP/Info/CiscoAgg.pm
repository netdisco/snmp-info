# SNMP::Info::CiscoAgg
#
# Copyright (c) 2019 SNMP::Info Developers
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

package SNMP::Info::CiscoAgg;

use strict;
#use warnings;
use Exporter;
use SNMP::Info::IEEE802dot3ad;

@SNMP::Info::CiscoAgg::ISA = qw/
  SNMP::Info::IEEE802dot3ad
  Exporter
/;

@SNMP::Info::CiscoAgg::EXPORT_OK = qw/
  agg_ports
  agg_ports_cisco
  agg_ports_lag
  agg_ports_pagp
/;

use vars qw/$DEBUG $VERSION %MIBS %FUNCS %GLOBALS %MUNGE/;

$VERSION = '3.65';

%MIBS = (
  %SNMP::Info::IEEE802dot3ad::MIBS,
  'CISCO-PAGP-MIB'         => 'pagpGroupIfIndex',
  'CISCO-LAG-MIB'          => 'clagAggPortListPorts',
  'CISCO-IF-EXTENSION-MIB' => 'cieIfLastInTime',
);

%GLOBALS = ();

%FUNCS = (
  %SNMP::Info::IEEE802dot3ad::FUNCS,
  'lag_ports'         => 'clagAggPortListPorts',
  'lag_members'       => 'clagAggPortListInterfaceIndexList',
);

%MUNGE = (
  %SNMP::Info::IEEE802dot3ad::MUNGE,
  'lag_ports'     => \&SNMP::Info::munge_port_list,
  'lag_members'   => \&munge_port_ifindex,
);

sub munge_port_ifindex {
    my $plist = shift;
    return unless defined $plist;
    return unless length $plist;

    my $list = [ map {sprintf "%d", hex($_)} unpack( "(A8)*", join( '' ,  map { sprintf "%02x", $_} unpack( "(C4)*", $plist ) ))  ];

    return $list;
}

sub agg_ports_cisco {
  my $dev = shift;
  my $group = $dev->lag_members;

  my $mapping = {};
  for my $master (keys %$group) {
    my $slaves = $group->{$master};
    for my $slave (@$slaves) {
      $mapping->{$slave} = $master;
    }
  }

  return $mapping;
}

sub agg_ports_pagp {
  my $dev = shift;

  # Note that this mapping will miss any interfaces that are down during
  # polling. If one of the members is up, we could use
  # pagpAdminGroupCapability to figure things out, but if they're all
  # down, we're hosed. Since we could be hosed anyway, we skip the fancy
  # stuff.
  my $mapping = {};
  my $group = $dev->pagpGroupIfIndex;
  for my $slave (keys %$group) {
    my $master = $group->{$slave};
    next if($master == 0 || $slave == $master);

    $mapping->{$slave} = $master;
  }

  return $mapping;
}

sub agg_ports_lag {
  my $dev = shift;

  # same note as for agg_ports_pagp, it will miss mappings if interfaces
  # are down or lacp is not synced.

  my $mapping = {};
  my $group = $dev->dot3adAggPortSelectedAggID;
  for my $slave (keys %$group) {
    my $master = $group->{$slave};
    next if($master == 0 || $slave == $master);

    $mapping->{$slave} = $master;
  }

  return $mapping;
}


# combine PAgP, LAG & Cisco proprietary data
sub agg_ports {
  my $ret = {%{agg_ports_pagp(@_)}, %{agg_ports_lag(@_)}, %{agg_ports_cisco(@_)}};
  return $ret;
}

1;

__END__

=head1 NAME

SNMP::Info::CiscoAgg - SNMP Interface to Cisco Aggregated Links

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

This class provides access to Aggregated Links configuration on Cisco devices.
It combines Cisco PAgP, Cisco proprietary info and IEEE 802.3ad information.

Use or create in a subclass of SNMP::Info.  Do not use directly.

=head2 Inherited Classes

L<SNMP::Info::IEEE802dot3ad>

=head2 Required MIBs

=over

=item F<CISCO-PAGP-MIB>

=item F<CISCO-LAG-MIB>

=item F<CISCO-IF-EXTENSION-MIB>

=back

MIBs can be found at ftp://ftp.cisco.com/pub/mibs/v2/v2.tar.gz

=head1 METHODS

=over 4

=item C<agg_ports>

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.

=item C<agg_ports_cisco>

Implements the cisco LAG info retrieval. Merged into C<agg_ports> data
automatically. Will fetch all members of C<clagAggPortListInterfaceIndexList>
even if they are not running an aggregation protocol.

=item C<agg_ports_pagp>

Implements the PAgP LAG info retrieval. Merged into C<agg_ports> data
automatically.

=item C<lag_members>

Mimics C<ad_lag_ports> from L<SNMP::Info::IEEE802dot3ad> but based on ifindex
instead of instead of bp_index.

=back

=head2 OVERRIDES

=over

=item C<agg_ports_lag>

This will retrieve LAG ports based on C<dot3adAggPortSelectedAggID> data.
It will be merged into C<agg_ports> data.

=back

=head2 Table Methods imported from SNMP::Info::IEEE802dot3ad

=over

See documentation in L<SNMP::Info::IEEE802dot3ad> for details.

=back

=head1 MUNGES

=over

=item C<munge_port_ifindex>

Takes C<clagAggPortListInterfaceIndexList>, uses the index as master port, then
returns all members as ifindex. Works with single or multiple slaves to a master.

=back

=cut
