# SNMP::Info::Layer3::Teltonika
#
# Copyright (c) 2020 Jeroen van Ingen
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

package SNMP::Info::Layer3::Teltonika;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Teltonika::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Teltonika::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.73';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'UCD-SNMP-MIB'        => 'versionTag',
    'NET-SNMP-TC'         => 'netSnmpAliasDomain',
    'HOST-RESOURCES-MIB'  => 'hrSystem',
    'TELTONIKA-MIB'       => 'routerName',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'snmpd_vers'     => 'versionTag',
    'hrSystemUptime' => 'hrSystemUptime',
    'serial1'        => 'serial',
    'os_ver'         => 'firmwareVersion',
);

%FUNCS = ( %SNMP::Info::Layer3::FUNCS, );

%MUNGE = ( %SNMP::Info::Layer3::MUNGE, );

sub vendor {
    return 'teltonika';
}

sub os {
    return 'rutos';
}

sub model {
    my $dev = shift;
    return $dev->productCode();
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Teltonika - SNMP Interface to Teltonika devices

=head1 AUTHORS

Jeroen van Ingen
initial version based on SNMP::Info::Layer3::PacketFront

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

 my $class      = $info->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Teltonika devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<UCD-SNMP-MIB>

=item F<NET-SNMP-TC>

=item F<HOST-RESOURCES-MIB>

=item F<TELTONIKA-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $info->vendor()

Returns C<'teltonika'>.

=item $info->os()

Returns C<'rutos'>.

=item $info->os_ver()

Returns the value of C<firmwareVersion>.

=item $info->model()

Returns the value of C<productCode>.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.


=cut
