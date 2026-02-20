# SNMP::Info::Layer3::C1300
#
# Copyright (c) 2008 C1300 Networks, Inc.
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
#     * Neither the name of C1300 Networks, Inc. nor the
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

package SNMP::Info::Layer3::C1300;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::MAU;
use SNMP::Info::Aggregate 'agg_ports_ifstack';

@SNMP::Info::Layer3::C1300::ISA = qw/
    SNMP::Info::Aggregate
    SNMP::Info::MAU
    SNMP::Info::Layer3
    SNMP::Info::Bridge
    Exporter
/;
@SNMP::Info::Layer3::C1300::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.975000';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::MAU::MIBS,
    %SNMP::Info::Aggregate::MIBS,
    %SNMP::Info::Bridge::MIBS,
    'CISCO-PRODUCTS-MIB' => 'ciscoIGS',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::MAU::GLOBALS,
    %SNMP::Info::Bridge::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::MAU::FUNCS,
    %SNMP::Info::Bridge::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::MAU::MUNGE,
    %SNMP::Info::Bridge::MUNGE,
);

# use MAU-MIB for admin. duplex and admin. speed
*SNMP::Info::Layer3::C1300::i_duplex_admin
    = \&SNMP::Info::MAU::mau_i_duplex_admin;
*SNMP::Info::Layer3::C1300::i_speed_admin
    = \&SNMP::Info::MAU::mau_i_speed_admin;

sub v_name { return (shift)->dot1qVlanStaticName }

sub vendor {
    return 'Cisco';
}

sub os {
    return 'IOS';
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::C1300 - SNMP Interface to C1300 Networks EOS

=head1 AUTHOR

Bill Fenner

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $C1300 = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
		 	)
    or die "Can't connect to DestHost.\n";

 my $class      = $C1300->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for C1300 Networks EOS-based devices

=head2 Inherited Classes

=over

=item SNMP::Info::Aggregate

=item SNMP::Info::Layer3

=item SNMP::Info::MAU

=back

=head2 Required MIBs

=over

=item F<C1300-PRODUCTS-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::Aggregate/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::MAU/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar values from SNMP

=over

=item $C1300->vendor()

Returns 'C1300'

=item $C1300->model()

Tries to reference $C1300->id() to one of the product MIBs listed above

Removes 'C1300' from the name for readability.

=item $C1300->os()

Returns 'EOS'

=item $C1300->os_ver()

Grabs the os version from C<sysDescr>

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $C1300->v_name()

The VLAN Names.

=item $C1300->i_duplex_admin()

Returns info from F<MAU-MIB>

=item $C1300->i_speed_admin()

Returns info from F<MAU-MIB>

=item $C1300->lldp_if()

Returns the mapping to the SNMP Interface Table.

=item C<agg_ports>

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"TABLE METHODS"> for details.

=head1 SET METHODS

These are methods that provide SNMP set functionality for overridden methods
or provide a simpler interface to complex set operations.  See
L<SNMP::Info/"SETTING DATA VIA SNMP"> for general information on set
operations.

=over

=item set_i_vlan()

=back

=cut
