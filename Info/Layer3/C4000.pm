# SNMP::Info::Layer3::C4000
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

package SNMP::Info::Layer3::C4000;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3::CiscoSwitch;
use SNMP::Info::MAU;

@SNMP::Info::Layer3::C4000::ISA = qw/
    SNMP::Info::Layer3::CiscoSwitch
    SNMP::Info::MAU
    Exporter/;
@SNMP::Info::Layer3::C4000::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.17';

%MIBS = (
    %SNMP::Info::MAU::MIBS,
    %SNMP::Info::Layer3::CiscoSwitch::MIBS,
    'CISCO-ENVMON-MIB' => 'ciscoEnvMonMIB',
);

%GLOBALS = (
    %SNMP::Info::MAU::GLOBALS,
    %SNMP::Info::Layer3::CiscoSwitch::GLOBALS,
    'ps1_type'   => 'ciscoEnvMonSupplyStatusDescr.1',
    'ps1_status' => 'ciscoEnvMonSupplyState.1',
    'ps2_type'   => 'ciscoEnvMonSupplyStatusDescr.2',
    'ps2_status' => 'ciscoEnvMonSupplyState.2',
);

%FUNCS = (
    %SNMP::Info::MAU::FUNCS,
    %SNMP::Info::Layer3::CiscoSwitch::FUNCS,
    'fan_state' => 'ciscoEnvMonFanState',
    'fan_descr' => 'ciscoEnvMonFanStatusDescr',
);

%MUNGE
    = ( %SNMP::Info::MAU::MUNGE, %SNMP::Info::Layer3::CiscoSwitch::MUNGE, );

# Override Inheritance for these specific methods
# use MAU-MIB for admin. duplex and admin. speed
*SNMP::Info::Layer3::C4000::i_duplex_admin
    = \&SNMP::Info::MAU::mau_i_duplex_admin;
*SNMP::Info::Layer3::C4000::i_speed_admin
    = \&SNMP::Info::MAU::mau_i_speed_admin;

*SNMP::Info::Layer3::C4000::set_i_duplex_admin
    = \&SNMP::Info::MAU::mau_set_i_duplex_admin;
*SNMP::Info::Layer3::C4000::set_i_speed_admin
    = \&SNMP::Info::MAU::mau_set_i_speed_admin;

sub fan {
    my $c4000     = shift;
    my $fan_state = $c4000->fan_state();
    my $fan_descr = $c4000->fan_descr();
    my $ret       = "";
    my $s         = "";
    foreach my $i ( sort { $a <=> $b } keys %$fan_state ) {
        $ret .= $s . $fan_descr->{$i} . ": " . $fan_state->{$i};
        $s = ", ";
    }
    return if ( $s eq "" );
    return $ret;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::C4000 - SNMP Interface to Cisco Catalyst 4000 Layer 2/3
Switches running IOS

=head1 AUTHOR

Bill Fenner

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $c4000 = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $c4000->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for Cisco Catalyst 4000 Layer 2/3 Switches.  

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

 my $c4000 = new SNMP::Info::Layer3::C4000(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3::CiscoSwitch

=item SNMP::Info::MAU

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3::CiscoSwitch/"Required MIBs"> for its own MIB
requirements.

See L<SNMP::Info::MAU/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=head2 Overrides

=over

=item $c4000->fan()

Returns fan status

=back

=head2 Globals imported from SNMP::Info::Layer3::CiscoSwitch

See documentation in L<SNMP::Info::Layer3::CiscoSwitch/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $c4000->i_duplex()

Parses mau_index and mau_link to return the duplex information for
interfaces.

=item $c4000->i_duplex_admin()

Parses C<mac_index>,C<mau_autostat>,C<mau_type_admin> in
order to find the admin duplex setting for all the interfaces.

Returns either (auto,full,half).

=item $c4000->i_speed_admin()

Returns administrative speed for interfaces.

=item $c4000->set_i_speed_admin(speed, ifIndex)

Sets port speed, must be supplied with speed and port C<ifIndex>.

Speed choices are '10', '100', '1000', 'auto'.

=item $c4000->set_i_duplex_admin(duplex, ifIndex)

Sets port duplex, must be supplied with duplex and port C<ifIndex>.

Duplex choices are 'auto', 'half', 'full'.

=back

=head2 Table Methods imported from SNMP::Info::Layer3::CiscoSwitch

See documentation in L<SNMP::Info::Layer3::CiscoSwitch/"TABLE METHODS"> for
details.

=head2 Table Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"TABLE METHODS"> for details.

=cut
