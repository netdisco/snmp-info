# SNMP::Info::Layer3::Redlion
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

package SNMP::Info::Layer3::Redlion;

$VERSION = '3.63';

use strict;

use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Redlion::ISA = qw/
    SNMP::Info::Layer3
    Exporter
/;
@SNMP::Info::Layer3::Redlion::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'RED-LION-RAM-MIB' => 'unitDescription',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
);

sub layers {
    return '00000110';
}

sub vendor {
    return 'redlion';
}

sub os_ver {
    my $redlion = shift;

    return $redlion->unitFirmwareVersion();
}

sub model {
    my $redlion = shift;

    return $redlion->unitDescription();
}

sub serial {
    my $redlion = shift;

    return $redlion->unitSerialNumber();
}


sub os {
    return 'sn';
}

1;

__END__

=head1 NAME

SNMP::Info::Layer3::Redlion - SNMP Interface to 

=head1 AUTHORS

nick nauwelaerts

=head1 SYNOPSIS

    # Let SNMP::Info determine the correct subclass for you.
    my $redlion = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

    my $class      = $redlion->class();
    print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for 

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<RED-LION-RAM-MIB>

=back

=head2 Inherited MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP.

=over

=item $redlion->model()

Returns the model extracted from C<unitDescription>.

=item $redlion->os()

Returns 'ns'.

=item $redlion->os_ver()

Returns the os version extracted from C<unitFirmwareVersion>.

=item $redlion->serial()

Returns the serial extracted from C<unitSerialNumber>.

=item $redlion->vendor()

Returns 'redlion'.

=back

=head2 Global Methods imported from SNMP::Info::Layer3
 
See L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=back

=head2 Table Methods imported from SNMP::Info::Layer3
 
See L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
