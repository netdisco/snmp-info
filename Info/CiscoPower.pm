# SNMP::Info::CiscoPower
# $Id$
#
# Copyright (c) 2008 Bill Fenner
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

package SNMP::Info::CiscoPower;

use strict;
use Exporter;
use SNMP::Info;

@SNMP::Info::CiscoPower::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::CiscoPower::EXPORT_OK = qw//;

use vars qw/$VERSION %MIBS %FUNCS %GLOBALS %MUNGE/;

$VERSION = '3.22';

%MIBS = ( 'CISCO-POWER-ETHERNET-EXT-MIB' => 'cpeExtPsePortEntPhyIndex',
          'CISCO-CDP-MIB' => 'cdpCachePowerConsumption' );

%GLOBALS = ();

%FUNCS = ( 
    'cpeth_ent_phy'     => 'cpeExtPsePortEntPhyIndex', 
    'peth_port_power'   => 'cpeExtPsePortPwrConsumption', 
);

%MUNGE = ();

# Cisco overcame the limitation of the module.port index of the
# pethPsePortTable by adding another mapping table, which maps
# a pethPsePortTable row to an entPhysicalTable index, which can
# then be mapped to ifIndex.
sub peth_port_ifindex {
    my $cpeth   = shift;
    my $partial = shift;

    my $ent_phy = $cpeth->cpeth_ent_phy($partial);
    my $e_port  = $cpeth->e_port();

    my $peth_port_ifindex = {};
    foreach my $i ( keys %$ent_phy ) {
        if ( $e_port->{ $ent_phy->{$i} } ) {
            $peth_port_ifindex->{$i} = $e_port->{ $ent_phy->{$i} };
        }
    }
    return $peth_port_ifindex;
}

# peth_port_neg_power uses the same index as the other peth_port_* tables.
# However, cdpCachePowerConsumption uses <ifIndex>.<neighbor>.
# Therefore, we have to invert peth_port_ifindex, to get to
# the index that is expected and the rest of the code can re-invert it.
sub peth_port_neg_power {
    my $cpeth   = shift;
    my $partial = shift;

    # Ignoring partial, since it's not easy to implement properly.
    my $index = $cpeth->peth_port_ifindex();
    my %inverse_index;
    foreach my $i ( keys %$index ) {
	$inverse_index{ $index->{$i} } = $i;
    }
    my $neg_power = $cpeth->cdpCachePowerConsumption();
    my $peth_port_neg_power = {};
    foreach my $i ( keys %$neg_power ) {
	my( $ifIndex, $nbrIndex ) = split( /\./, $i );
	if ( defined( $inverse_index{ $ifIndex } ) ) {
		$peth_port_neg_power->{ $inverse_index{ $ifIndex } } = $neg_power->{ $i };
	}
    }
    return $peth_port_neg_power;
}

1;

__END__

=head1 NAME

SNMP::Info::CiscoPower - SNMP Interface to data stored in
F<CISCO-POWER-ETHERNET-EXT-MIB>.

=head1 AUTHOR

Bill Fenner

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $poe = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $poe->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

The Info::PowerEthernet class needs a per-device helper function to
properly map the C<pethPsePortTable> to C<ifIndex> values.  This class
provides that helper, using F<CISCO-POWER-ETHERNET-EXT-MIB>.
It does not define any helpers for the extra values that this MIB
contains.

Create or use a device subclass that inherit this class.  Do not use directly.

For debugging purposes you can call this class directly as you would
SNMP::Info

 my $poe = new SNMP::Info::CiscoPower (...);

=head2 Inherited Classes

none.

Note that it requires that the device inherits from Info::Entity.

=head2 Required MIBs

=over

=item F<CISCO-POWER-ETHERNET-EXT-MIB>

=back

=head1 GLOBALS

none.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Power Port Table

=over

=item $poe->peth_port_ifindex()

Maps the C<pethPsePortTable> to C<ifIndex> by way of the F<ENTITY-MIB>.

=item $poe->peth_port_power()

Power supplied by PoE ports, in milliwatts
(C<cpeExtPsePortPwrConsumption>)
 
=back

=head2 CDP Port table

=over

=item $poe->peth_port_neg_power()

Power negotiated using CDP, in milliwatts
(C<cdpCachePowerConsumption>)

=back

=cut
