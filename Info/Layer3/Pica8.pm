# SNMP::Info::Layer3::Pica8
#
# Copyright (c) 2013 Jeroen van Ingen
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

package SNMP::Info::Layer3::Pica8;

use strict;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::LLDP;

@SNMP::Info::Layer3::Pica8::ISA       = qw/SNMP::Info::LLDP SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Pica8::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.18';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::LLDP::MIBS,
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::LLDP::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::LLDP::MUNGE,
);

sub vendor {
    return 'Pica8';
}

sub os {
    my $pica8 = shift;
    my $descr   = $pica8->description();

    return $1 if ( $descr =~ /(\S+)\s+Platform Software/i );
    return;
}

sub os_ver {
    my $pica8 = shift;
    my $descr   = $pica8->description();

    return $1 if ( $descr =~ /Software version ([\d\.]+)/i );
    return;
}

sub model {
    my $pica8 = shift;
    my $descr   = $pica8->description();

    return $1 if ( $descr =~ /Hardware model (P-\d{4})/i );
    return;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Pica8 - SNMP Interface to L3 Devices, Pica8

=head1 AUTHORS

Jeroen van Ingen

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $pica8 = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $pica8->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Pica8 devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::LLDP

=back

=head2 Required MIBs

=over

=item F<PICA-PRIVATE-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

See L<SNMP::Info::LLDP> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $pica8->vendor()

Returns 'Pica8'

=item $pica8->model()

Returns the model name extracted from C<sysDescr>.

=item $pica8->os()

Returns the OS extracted from C<sysDescr>.

=item $pica8->os_ver()

Returns the OS version extracted from C<sysDescr>.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Globals imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP> for details.

=cut
