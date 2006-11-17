# SNMP::Info::Layer3::C6500
# Max Baker
#
# Copyright (c) 2003,2004,2005 Max Baker
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
#     * Neither the name of the Author, nor 
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

package SNMP::Info::Layer3::C6500;
# $Id$

use strict;

use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::CiscoVTP;
use SNMP::Info::CiscoStack;
use SNMP::Info::CDP;
use SNMP::Info::CiscoStats;
use SNMP::Info::CiscoImage;

use vars qw/$VERSION $DEBUG %GLOBALS %MIBS %FUNCS %MUNGE $INIT/ ;
$VERSION = '1.04';
@SNMP::Info::Layer3::C6500::ISA = qw/ SNMP::Info::Layer3 SNMP::Info::CiscoStack SNMP::Info::CiscoVTP 
                                      SNMP::Info::CiscoStats SNMP::Info::CDP Exporter
                                      SNMP::Info::CiscoImage/;
@SNMP::Info::Layer3::C6500::EXPORT_OK = qw//;

%MIBS =    (
            %SNMP::Info::Layer3::MIBS,  
            %SNMP::Info::CiscoVTP::MIBS,
            %SNMP::Info::CiscoStack::MIBS,
            %SNMP::Info::CDP::MIBS,
            %SNMP::Info::CiscoStats::MIBS,
            %SNMP::Info::CiscoImage::MIBS,
           );

%GLOBALS = (
            %SNMP::Info::Layer3::GLOBALS,
            %SNMP::Info::CiscoVTP::GLOBALS,
            %SNMP::Info::CiscoStack::GLOBALS,
            %SNMP::Info::CDP::GLOBALS,
            %SNMP::Info::CiscoStats::GLOBALS,
            %SNMP::Info::CiscoImage::GLOBALS,
           );

%FUNCS = (
            %SNMP::Info::Layer3::FUNCS,
            %SNMP::Info::CiscoVTP::FUNCS,
            %SNMP::Info::CiscoStack::FUNCS,
            %SNMP::Info::CDP::FUNCS,
            %SNMP::Info::CiscoStats::FUNCS,
            %SNMP::Info::CiscoImage::FUNCS,
         );

%MUNGE = (
            %SNMP::Info::Layer3::MUNGE,
            %SNMP::Info::CiscoVTP::MUNGE,
            %SNMP::Info::CiscoStack::MUNGE,
            %SNMP::Info::CDP::MUNGE,
            %SNMP::Info::CiscoStats::MUNGE,
            %SNMP::Info::CiscoImage::MUNGE,
         );

# Pick and choose

*SNMP::Info::Layer3::C6500::serial     = \&SNMP::Info::CiscoStack::serial;
*SNMP::Info::Layer3::C6500::interfaces = \&SNMP::Info::Layer3::interfaces;
*SNMP::Info::Layer3::C6500::i_duplex   = \&SNMP::Info::CiscoStack::i_duplex;
#*SNMP::Info::Layer3::C6500::i_duplex_admin = \&SNMP::Info::Layer3::i_duplex_admin;
*SNMP::Info::Layer3::C6500::i_name     = \&SNMP::Info::Layer3::i_name;
*SNMP::Info::Layer3::C6500::i_type     = \&SNMP::Info::CiscoStack::i_type;

sub vendor {
    return 'cisco';
}

# There are some buggy 6509's out there.
sub bulkwalk_no { 1; }
sub cisco_comm_indexing { 1; }

1;
__END__

=head1 NAME

SNMP::Info::Layer3::C6500 - Perl5 Interface to Cisco Catalyst 6500 Layer 2/3 Switches running IOS and/or CatOS

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $c6500 = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $c6500->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for Cisco Catalyst 6500 Layer 2/3 Switches.  

These devices run IOS but have some of the same charactersitics as the Catalyst WS-C family (5xxx). 
For example, forwarding tables are held in VLANs, and extened interface information
is gleened from CISCO-SWITCH-MIB.

For speed or debugging purposes you can call the subclass directly, but not after determining
a more specific class using the method above. 

 my $c6500 = new SNMP::Info::Layer3::C6500(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::CiscoVTP

=item SNMP::Info::CiscoStack

=item SNMP::Info::CiscoStats

=item SNMP::Info::CDP

=item SNMP::Info::CiscoImage

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoVTP/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoStack/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoStats/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CDP/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoImage/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $c6500->bulkwalk_no

Return C<1>.  There are some buggy 6509's out there, so bulkwalk
is turned off for this class.

=item $c6500->vendor()

    Returns 'cisco'

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::CiscoVTP

See documentation in L<SNMP::Info::CiscoVTP/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::CiscoStack

See documentation in L<SNMP::Info::CiscoStack/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CDP

See documentation in L<SNMP::Info::CDP/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoStats

See documentation in L<SNMP::Info::CiscoStats/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoImage

See documentation in L<SNMP::Info::CiscoImage/"GLOBALS"> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE ENTRIES"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoVTP

See documentation in L<SNMP::Info::CiscoVTP/"TABLE ENTRIES"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoStack

See documentation in L<SNMP::Info::CiscoStack/"TABLE ENTRIES"> for details.

=head2 Table Methods imported from SNMP::Info::CDP

See documentation in L<SNMP::Info::CDP/"TABLE ENTRIES"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoStats

See documentation in L<SNMP::Info::CiscoStats/"TABLE ENTRIES"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoImage

See documentation in L<SNMP::Info::CiscoImage/"TABLE ENTRIES"> for details.

=cut

