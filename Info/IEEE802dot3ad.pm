# SNMP::Info::IEEE802dot3ad
#
# Copyright (c) 2014 SNMP::Info Developers
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
use Exporter;
use SNMP::Info::Aggregate;

@SNMP::Info::IEEE802dot3ad::ISA = qw/
  SNMP::Info::Aggregate
  Exporter
/;
@SNMP::Info::IEEE802dot3ad::EXPORT_OK = qw/
  agg_ports_lag
/;

use vars qw/$VERSION %MIBS %FUNCS %GLOBALS %MUNGE/;

$VERSION = '3.11';

%MIBS = (
  %SNMP::Info::Aggregate::MIBS,
  'IEEE8023-LAG-MIB' => 'dot3adAggPortSelectedAggID',
);

%GLOBALS = ();

%FUNCS = ();

%MUNGE = ();

sub agg_ports_lag {
  my $dev = shift;

  # TODO: implement partial
  my $masters = $dev->dot3adAggActorOperKey;
  my $slaves  = $dev->dot3adAggPortActorOperKey;

  return {} unless
    ref {} eq ref $masters and scalar keys %$masters
    and ref {} eq ref $slaves and scalar keys %$slaves;

  my $ret = {};
  foreach my $s (keys %$slaves) {
      next if $slaves->{$s} == 0;
      foreach my $m (keys %$masters) {
          next unless $masters->{$m} == $slaves->{$s};
          $ret->{$s} = $m;
          last;
      }
  }

  return $ret;
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

=over 4

=item C<agg_ports_lag>

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.

=back

=cut
