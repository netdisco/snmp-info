# SNMP::Info::CiscoAgg
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

package SNMP::Info::CiscoAgg;

use strict;
use Exporter;
use SNMP::Info::IEEE802dot3ad 'agg_ports_lag';

@SNMP::Info::CiscoAgg::ISA = qw/
  SNMP::Info::IEEE802dot3ad
  Exporter
/;
@SNMP::Info::CiscoAgg::EXPORT_OK = qw/
  agg_ports
/;

use vars qw/$VERSION %MIBS %FUNCS %GLOBALS %MUNGE/;

$VERSION = '3.15';

%MIBS = (
  %SNMP::Info::IEEE802dot3ad::MIBS,
  'CISCO-PAGP-MIB'   => 'pagpGroupIfIndex',
);

%GLOBALS = ();

%FUNCS = ();

%MUNGE = ();

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

# until we have PAgP data and need to combine with LAG data
sub agg_ports {
  my $ret = {%{agg_ports_pagp(@_)}, %{agg_ports_lag(@_)}};
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
It combines Cisco PAgP and IEEE 802.3ad information.

Use or create in a subclass of SNMP::Info.  Do not use directly.

=head2 Inherited Classes

L<SNMP::Info::IEEE802dot3ad>

=head2 Required MIBs

=over

=item F<CISCO-PAGP-MIB>

=back

MIBs can be found at ftp://ftp.cisco.com/pub/mibs/v2/v2.tar.gz

=head1 METHODS

=over 4

=item C<agg_ports>

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.

=item C<agg_ports_pagp>

Implements the PAgP LAG info retrieval. Merged into C<agg_ports> data
automatically.

=back

=cut
