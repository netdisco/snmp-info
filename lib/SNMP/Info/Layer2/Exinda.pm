# SNMP::Info::Layer2::Exinda
#
# Copyright (c) 2018 nick nauwelaerts
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

package SNMP::Info::Layer2::Exinda;

$VERSION = '3.62';

use strict;

use Exporter;
use SNMP::Info::Layer2;

@SNMP::Info::Layer2::Exinda::ISA = qw/
    SNMP::Info::Layer2
    Exporter
/;
@SNMP::Info::Layer2::Exinda::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
    'EXINDA-MIB' => 'systemHostId',
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer2::MUNGE,
);

sub vendor {
    return "Exinda";
}

sub model {
    my $exinda = shift;

    return $exinda->hardwareSeries();
}

sub serial {
    # exinda units have a hostid and serial,
    # regretfully only hostid is exposed via snmp
    my $exinda = shift;

    return $exinda->systemHostId();
}

sub os {
    return 'exos';
}

sub os_ver {
    my $exinda = shift;

    return $exinda->systemVersion();
}

1;

__END__

=head1 NAME

SNMP::Info::Layer2::Exinda - SNMP Interface to exinda traffic shapers.

=head1 AUTHORS

nick nauwelaerts

=head1 SYNOPSIS

    # Let SNMP::Info determine the correct subclass for you.
    my $exinda = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

    my $class      = $exinda->class();
    print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for exinda traffic shapers

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

=over

=item F<EXINDA-MIB>

=back

=head2 Inherited MIBs

See L<SNMP::Info::Layer2/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $exinda->vendor()

Returns 'Exinda'.

=item $exinda->os()

Returns 'exos'.

=item $exinda->os_ver()

Returns the model extracted from C<systemVersion>.

=item $exinda->model()

Returns the model extracted from C<hardwareSeries>.

=item $exinda->serial()

Returns the model extracted from C<systemHostId>.

=back

=head2 Global Methods imported from SNMP::Info::Layer2
 
See L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=back

=head2 Table Methods imported from SNMP::Info::Layer2
 
See L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=cut
