# SNMP::Info::Aggregate
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

package SNMP::Info::Aggregate;

use strict;
use warnings;
use Exporter;
use SNMP::Info;

@SNMP::Info::Aggregate::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::Aggregate::EXPORT_OK = qw/agg_ports_ifstack/;

our ($VERSION, %MIBS, %FUNCS, %GLOBALS, %MUNGE);

$VERSION = '3.70';

# Load MIB for leafs referenced within class
%MIBS = ('IF-MIB' => 'ifIndex',);

%GLOBALS = ();

%FUNCS = ();

%MUNGE = ();

sub agg_ports_ifstack {
  my $dev = shift;
  my $partial = shift;

  my $ifStack = $dev->ifStackStatus();
  # TODO: if we want to do partial, we need to use inverse status
  my $ifType = $dev->ifType();

  my $ret = {};

  foreach my $idx ( keys %$ifStack ) {
      my ( $higher, $lower ) = split /\./, $idx;
      next if ( $higher == 0 or $lower == 0 );
      if ( $ifType->{ $higher } eq 'ieee8023adLag'  or $ifType->{ $higher } eq 'propMultiplexor') {
          $ret->{ $lower } = $higher;
      }
  }

  return $ret;
}

1;

__END__

=head1 NAME

SNMP::Info::Aggregate - SNMP Interface to ifStackTable Aggregated Links

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
supporting C<ifStackTable>.

Use or create in a subclass of SNMP::Info.  Do not use directly.

=head2 Inherited Classes

L<SNMP::Info>

=head2 Required MIBs

=over

=item F<IF-MIB>

=back

=head1 METHODS

=over 4

=item C<agg_ports_ifstack>

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.

=back

=cut
