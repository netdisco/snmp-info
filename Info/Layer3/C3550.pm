# SNMP::Info::Layer3::C3550
# Max Baker <max@warped.org>
#
# Copyright (c) 2004 Max Baker changes from version 0.8 and beyond.
# Copyright (c) 2003, Regents of the University of California
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#     * Neither the name of the University of California, Santa Cruz nor the 
#       names of its contributors may be used to endorse or promote products 
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Layer3::C3550;
$VERSION = 0.8;
# $Id$

use strict;

use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::CiscoVTP;
use SNMP::Info::CiscoStack;

use vars qw/$VERSION $DEBUG %GLOBALS %MIBS %FUNCS %MUNGE $INIT/ ;
@SNMP::Info::Layer3::C3550::ISA = qw/ SNMP::Info::Layer3 SNMP::Info::CiscoStack SNMP::Info::CiscoVTP  Exporter/;
@SNMP::Info::Layer3::C3550::EXPORT_OK = qw//;

$DEBUG=0;

# See SNMP::Info for the details of these data structures and 
#       the interworkings.
$INIT = 0;

%MIBS = (
         %SNMP::Info::Layer3::MIBS,  
         %SNMP::Info::CiscoVTP::MIBS,
         %SNMP::Info::CiscoStack::MIBS,
        );

%GLOBALS = (
            %SNMP::Info::Layer3::GLOBALS,
            %SNMP::Info::CiscoVTP::GLOBALS,
            %SNMP::Info::CiscoStack::GLOBALS,
            'ports2'      => 'ifNumber',
           );

%FUNCS = (
            %SNMP::Info::Layer3::FUNCS,
            %SNMP::Info::CiscoVTP::FUNCS,
            %SNMP::Info::CiscoStack::FUNCS,
         );

%MUNGE = (
            # Inherit all the built in munging
            %SNMP::Info::Layer3::MUNGE,
            %SNMP::Info::CiscoVTP::MUNGE,
            %SNMP::Info::CiscoStack::MUNGE,
         );

# Pick and choose

*SNMP::Info::Layer3::C3550::serial     = \&SNMP::Info::CiscoStack::serial;
*SNMP::Info::Layer3::C3550::interfaces = \&SNMP::Info::Layer3::interfaces;
*SNMP::Info::Layer3::C3550::i_duplex   = \&SNMP::Info::CiscoStack::i_duplex;
*SNMP::Info::Layer3::C3550::i_duplex_admin = \&SNMP::Info::CiscoStack::i_duplex_admin;
*SNMP::Info::Layer3::C3550::i_name     = \&SNMP::Info::Layer3::i_name;
*SNMP::Info::Layer3::C3550::i_type     = \&SNMP::Info::CiscoStack::i_type;

sub vendor {
    return 'cisco';
}

sub model {
    my $c3550 = shift;
    my $id = $c3550->id();
    my $model = &SNMP::translateObj($id) || $id;
    $model =~ s/^catalyst//;

    # turn 355048 into 3550-48
    if ($model =~ /^(35\d\d)(\d\d[T]?)$/) {
        $model = "$1-$2";
    }
    return $model;
}

# Ports is encoded into the model number
sub ports {
    my $c3550 = shift;

    my $ports2 = $c3550->ports2();    

    my $id = $c3550->id();
    my $model = &SNMP::translateObj($id);
    if ($model =~ /(12|24|48)[T]?$/) {
        return $1;
    }
    return $ports2;
}


1;
__END__

=head1 NAME

SNMP::Info::Layer3::C3550 - Perl5 Interface to Cisco Catalyst 3550 Layer 2/3 Switches running IOS

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $c3550 = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $c3550->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for Cisco Catalyst 3550 Layer 2/3 Switches.  

These devices run IOS but have some of the same charactersitics as the Catalyst WS-C family (5xxx,6xxx). 
For example, forwarding tables are held in VLANs, and extened interface information
is gleened from CISCO-SWITCH-MIB.

For speed or debugging purposes you can call the subclass directly, but not after determining
a more specific class using the method above. 

 my $c3550 = new SNMP::Info::Layer3::C3550(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::CiscoVTP

=item SNMP::Info::CiscoStack

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See SNMP::Info::Layer3 for its own MIB requirements.

See SNMP::Info::CiscoVTP for its own MIB requirements.

See SNMP::Info::CiscoStack for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $c3550->vendor()

    Returns 'cisco'

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in SNMP::Info::Layer3 for details.

=head2 Global Methods imported from SNMP::Info::CiscoVTP

See documentation in SNMP::Info::CiscoVTP for details.

=head2 Global Methods imported from SNMP::Info::CiscoStack

See documentation in SNMP::Info::CiscoStack for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in SNMP::Info::Layer3 for details.

=head2 Table Methods imported from SNMP::Info::CiscoVTP

See documentation in SNMP::Info::CiscoVTP for details.

=head2 Table Methods imported from SNMP::Info::CiscoStack

See documentation in SNMP::Info::CiscoStack for details.

=cut
