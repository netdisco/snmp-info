# SNMP::Info::Layer3::CiscoSwitch
# $Id$
#
# Copyright (c) 2014 Eric Miller
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

package SNMP::Info::Layer3::CiscoSwitch;

use strict;
use warnings;
use Exporter;
use SNMP::Info::CiscoAgg;
use SNMP::Info::CiscoPortSecurity;
use SNMP::Info::Layer3::Cisco;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

@SNMP::Info::Layer3::CiscoSwitch::ISA = qw/
    SNMP::Info::CiscoAgg
    SNMP::Info::CiscoPortSecurity
    SNMP::Info::Layer3::Cisco
    Exporter
/;

@SNMP::Info::Layer3::CiscoSwitch::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.19';

%MIBS = (
    %SNMP::Info::Layer3::Cisco::MIBS,
    %SNMP::Info::CiscoPortSecurity::MIBS,
    %SNMP::Info::CiscoAgg::MIBS,
);

%GLOBALS = (
    %SNMP::Info::Layer3::Cisco::GLOBALS,
    %SNMP::Info::CiscoPortSecurity::GLOBALS,
    %SNMP::Info::CiscoAgg::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer3::Cisco::FUNCS,
    %SNMP::Info::CiscoPortSecurity::FUNCS,
    %SNMP::Info::CiscoAgg::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::Cisco::MUNGE,
    %SNMP::Info::CiscoPortSecurity::MUNGE,
    %SNMP::Info::CiscoAgg::MUNGE,
);

sub cisco_comm_indexing { return 1; }

1;
__END__

=head1 NAME

SNMP::Info::Layer3::CiscoSwitch - Base class for L3 Cisco switches

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $switch = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $switch->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Base subclass for Cisco Layer 2/3 Switches.  

These devices have switch specific characteristics beyond those in
traditional routers covered by L<SNMP::Info::Layer3::Cisco>. For example,
port security interface information from L<SNMP::Info::CiscoPortSecurity>.

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

 my $swich = new SNMP::Info::Layer3::CiscoSwitch(...);

=head2 Inherited Classes

=over

=item SNMP::Info::CiscoAgg

=item SNMP::Info::CiscoPortSecurity

=item SNMP::Info::Layer3::Cisco

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::CiscoAgg/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoPortSecurity/"Required MIBs"> for its own MIB
requirements.

See L<SNMP::Info::Layer3::Cisco/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $switch->cisco_comm_indexing()

Returns 1.  Use vlan indexing.

=back

=head2 Global Methods imported from SNMP::Info::CiscoAgg

See documentation in L<SNMP::Info::CiscoAgg/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoPortSecurity

See documentation in L<SNMP::Info::CiscoPortSecurity/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::Layer3::Cisco

See documentation in L<SNMP::Info::Layer3::Cisco/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::CiscoAgg

See documentation in L<SNMP::Info::CiscoAgg/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoPortSecurity

See documentation in L<SNMP::Info::CiscoPortSecurity/"TABLE METHODS"> for
details.

=head2 Table Methods imported from SNMP::Info::Layer3::Cisco

See documentation in L<SNMP::Info::Layer3::Cisco/"TABLE METHODS"> for details.

=cut
