# SNMP::Info::Layer3::Fortinet
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

package SNMP::Info::Layer3::Fortinet;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Fortinet::ISA
    = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Fortinet::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %FUNCS, %MIBS, %MUNGE);

$VERSION = '3.70';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'FORTINET-CORE-MIB'      => 'fnSysSerial',
    'FORTINET-FORTIGATE-MIB' => 'fgVdMaxVdoms',
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

sub vendor {
    return 'fortinet';
}

# fortios 5.4 and higher can have empty ifDescr. use ifName (but
# without the ifAlias fixup that's done in layer3::i_name()) which
# mimics fortios >5.4
# copied from an old Layer3.pm which did not have duplicate
# description fixup
sub interfaces {
    my $fortinet = shift;
    my $partial  = shift;

    my $interfaces   = $fortinet->i_index($partial);
    my $descriptions = $fortinet->orig_i_name($partial);

    my %interfaces = ();
    foreach my $iid ( keys %$interfaces ) {
        my $desc = $descriptions->{$iid};
        next unless defined $desc;

        $interfaces{$iid} = $desc;
    }

    return \%interfaces;
}

sub model {
    my $fortinet = shift;
    my $id = $fortinet->id() || '';

    my $model = &SNMP::translateObj($id);

    return $id unless defined $model;

    $model =~ s/^f[grsw][tfw]?//i;
    return $model;
}

sub os {
    return 'fortios';
}

sub os_ver {
    my $fortinet = shift;

    my $ver = $fortinet->fgSysVersion() || '';

    if ( $ver =~ /(\d+[\.\d]+)/ ) {
        return $1;
    }

    return $ver;
}

sub serial {
    my $fortinet = shift;

    return $fortinet->fnSysSerial();
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Fortinet - SNMP Interface to Fortinet network devices.

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $fortinet = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $fortinet->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for Fortinet network devices.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<FORTINET-CORE-MIB>

=item F<FORTINET-FORTIGATE-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $fortinet->vendor()

Returns 'fortinet'

=item $fortinet->model()

Returns the chassis model.

=item $fortinet->os()

Returns 'fortios'

=item $fortinet->os_ver()

Returns the software version extracted from (C<systemVersion>).

=item $fortinet->serial()

Returns the chassis serial number.

(C<fnSysSerial>)

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $fortinet->interfaces();

Returns the map between SNMP Interface Identifier (iid) and C<ifName>.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
