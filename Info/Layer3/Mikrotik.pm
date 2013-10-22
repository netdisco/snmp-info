# SNMP::Info::Layer3::Mikrotik
# $Id$
#
# Copyright (c) 2011 Jeroen van Ingen
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

package SNMP::Info::Layer3::Mikrotik;

use strict;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Mikrotik::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Mikrotik::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.08';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'HOST-RESOURCES-MIB'       => 'hrSystem',
    'MIKROTIK-MIB'             => 'mtxrLicVersion',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'hrSystemUptime' => 'hrSystemUptime',
    'os_ver'         => 'mtxrLicVersion',
);

%FUNCS = ( %SNMP::Info::Layer3::FUNCS, );

%MUNGE = ( %SNMP::Info::Layer3::MUNGE, );

sub vendor {
    return 'mikrotik';
}

sub model {
    my $mikrotik = shift;
    my $descr = $mikrotik->description() || '';
    my $model = undef;
    $model = $1 if ( $descr =~ /^RouterOS\s+(\S+)$/i );
    return $model;
}

sub os {
    return 'routeros';
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Mikrotik - SNMP Interface to Mikrotik devices

=head1 AUTHORS

Jeroen van Ingen
initial version based on SNMP::Info::Layer3::NetSNMP by Bradley Baetz and Bill Fenner

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $mikrotik = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $mikrotik->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Mikrotik devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<HOST-RESOURCES-MIB>

=item F<MIKROTIK-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $mikrotik->vendor()

Returns C<'mikrotik'>.

=item $mikrotik->os()

Returns C<'routeros'>.

=item $mikrotik->model()

Tries to extract the device model from C<sysDescr>.

=item $mikrotik->os_ver()

Returns the value of C<mtxrLicVersion>.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

None.

=over

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.


=cut
