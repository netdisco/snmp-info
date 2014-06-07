# SNMP::Info::Layer7::Neoteris
#
# Copyright (c) 2012 Eric Miller
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

package SNMP::Info::Layer7::Neoteris;

use strict;
use Exporter;
use SNMP::Info::Layer7;

@SNMP::Info::Layer7::Neoteris::ISA       = qw/SNMP::Info::Layer7 Exporter/;
@SNMP::Info::Layer7::Neoteris::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.14';

%MIBS = (
    %SNMP::Info::Layer7::MIBS,
    'UCD-SNMP-MIB'       => 'versionTag',
    'JUNIPER-IVE-MIB'    => 'productVersion',
);

%GLOBALS = (
    %SNMP::Info::Layer7::GLOBALS,
    'os_ver' => 'productVersion',
    'cpu'    => 'iveCpuUtil',
);

%FUNCS = ( %SNMP::Info::Layer7::FUNCS, );

%MUNGE = ( %SNMP::Info::Layer7::MUNGE, );

sub vendor {
    return 'juniper';
}

sub os {
    return 'ive';
}

sub serial {
    return '';
}

1;
__END__

=head1 NAME

SNMP::Info::Layer7::Neoteris - SNMP Interface to Juniper SSL VPN appliances

=head1 AUTHORS

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $neoteris = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $neoteris->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Juniper SSL VPN appliances

=head2 Inherited Classes

=over

=item SNMP::Info::Layer7

=back

=head2 Required MIBs

=over

=item F<UCD-SNMP-MIB>

=item F<JUNIPER-IVE-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer7> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $neoteris->vendor()

Returns 'juniper'.

=item $neoteris->os()

Returns C<'ive'>.

=item $neoteris->os_ver()

C<productVersion>

=item $neoteris->cpu()

C<iveCpuUtil>

=item $neoteris->serial()

Returns ''.

=back

=head2 Globals imported from SNMP::Info::Layer7

See documentation in L<SNMP::Info::Layer7> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer7

See documentation in L<SNMP::Info::Layer7> for details.

=cut
