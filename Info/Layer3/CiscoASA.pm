# SNMP::Info::Layer3::CiscoASA
# $Id$
#
# Copyright (c) 2013 Moe Kraus
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
# LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Layer3::CiscoASA;

use strict;
use Exporter;
use SNMP::Info::CiscoVTP;
use SNMP::Info::CDP;
use SNMP::Info::CiscoStats;
use SNMP::Info::CiscoImage;
use SNMP::Info::CiscoRTT;
use SNMP::Info::CiscoQOS;
use SNMP::Info::CiscoConfig;
use SNMP::Info::CiscoPower;
use SNMP::Info::Layer3;
use SNMP::Info::Layer3::Cisco;

@SNMP::Info::Layer3::CiscoASA::ISA = qw/SNMP::Info::CiscoVTP SNMP::Info::CDP
    SNMP::Info::CiscoStats SNMP::Info::CiscoImage
    SNMP::Info::CiscoRTT  SNMP::Info::CiscoQOS
    SNMP::Info::CiscoConfig SNMP::Info::CiscoPower
    SNMP::Info::Layer3::Cisco
    SNMP::Info::Layer3
    Exporter/;
@SNMP::Info::Layer3::CiscoASA::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.00_004';

%MIBS = (
       %SNMP::Info::Layer3::Cisco::MIBS,
);

%GLOBALS = (
       %SNMP::Info::Layer3::Cisco::GLOBALS,
);

%FUNCS = (
       %SNMP::Info::Layer3::Cisco::FUNCS,
    'mac_table' => 'ifPhysAddress',
);

%MUNGE = (
       %SNMP::Info::Layer3::Cisco::MUNGE,
    'mac_table'  => \&SNMP::Info::munge_mac, );

sub b_mac {
       my ($asa) = shift;
       my $macs = $asa->mac_table();
       my @macs;
       # gather physical addresses
       foreach my $i ( keys %$macs ) {
               my $mac = $macs->{$i};
               # don't catch the bad macs with zeroed OUI
               if ( $mac !~ m/(0{1,2}:){3}/ ) {
                       push( @macs, $mac);
               }
               @macs = sort( @macs );
       }
       # return the least mac
       return $macs[0];
}

sub i_description {
    my $self = shift;
    my $partial   = shift;

    my $i_descr = $self->orig_i_description($partial) || {};

    foreach my $ifindex ( keys %$i_descr ) {
        $i_descr->{$ifindex} =~ /'(.*)'/;
        $i_descr->{$ifindex} = $1
            if defined $1;
    }

    return $i_descr;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::CiscoASA - Cisco Adaptive Security Appliance

=head1 AUTHOR

Moe Kraus

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $cisco = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $asa->class();
 print "SNMP::Info determined this device to fall under subclass: $class\n";

=head1 DESCRIPTION

Subclass for Cisco ASAs

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3::Cisco

=back

=head2 Required MIBs

=over

=item F<CISCO-EIGRP-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3::Cisco/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $asa->b_mac()

Returns base mac.
Overrides base mac function in L<SNMP::Info::Layer3>.

=item $asa->i_description()

Overrides base interface description function in L<SNMP::Info> to return the
configured interface name instead of "Adaptive Security Appliance
'$configured interface name' interface".

=back

=head2 Global Methods imported from SNMP::Info::CiscoVTP

See documentation in L<SNMP::Info::CiscoVTP/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CDP

See documentation in L<SNMP::Info::CDP/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoStats

See documentation in L<SNMP::Info::CiscoStats/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoImage

See documentation in L<SNMP::Info::CiscoImage/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoRTT

See documentation in L<SNMP::Info::CiscoRTT/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoQOS

See documentation in L<SNMP::Info::CiscoQOS/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoConfig

See documentation in L<SNMP::Info::CiscoConfig/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoPower

See documentation in L<SNMP::Info::CiscoPower/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::Layer3::Cisco

See documentation in L<SNMP::Info::Layer3::Cisco/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a
reference to a hash.

=head2 Table Methods imported from SNMP::Info::CiscoVTP

See documentation in L<SNMP::Info::CiscoVTP/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CDP

See documentation in L<SNMP::Info::CDP/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoStats

See documentation in L<SNMP::Info::CiscoStats/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoImage

See documentation in L<SNMP::Info::CiscoImage/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoRTT

See documentation in L<SNMP::Info::CiscoRTT/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoQOS

See documentation in L<SNMP::Info::CiscoQOS/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::Layer3::Cisco

See documentation in L<SNMP::Info::Layer3::Cisco/"TABLE METHODS"> for details.

=cut
