package SNMP::Info::Layer3::Redlion;
#
# Copyright (c) 2019 nick nauwelaerts
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

use strict;
use warnings;

use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Redlion::ISA = qw/
    SNMP::Info::Layer3
    Exporter
/;
@SNMP::Info::Layer3::Redlion::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.71';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'RED-LION-RAM-MIB' => 'unitDescription',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'sn_model'  => 'unitDescription',
    'sn_os_ver' => 'unitFirmwareVersion',
    'sn_serial' => 'unitSerialNumber',
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

    return $redlion->sn_os_ver();
}

sub model {
    my $redlion = shift;

    return $redlion->sn_model();
}

sub serial {
    my $redlion = shift;

    return $redlion->sn_serial();
}

# is actually just an embedded linux
# 'sn' refers to "sixnet", the original creators of the device
# layer2::sixnet is for redlion's switch offerings.
# (they also have a different enterprise oid)
sub os {
    return 'sn';
}

1;

__END__

=head1 NAME

SNMP::Info::Layer3::Redlion - SNMP Interface to redlion routers

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

Subclass for redlion routers.

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

=item $redlion->layers()

Returns '00000110' since sysServices returns undef.

=item $redlion->model()

Returns the model extracted from C<unitDescription>.

=item $redlion->os()

Returns 'sn'.

=item $redlion->os_ver()

Returns the os version extracted from C<unitFirmwareVersion>.

=item $redlion->serial()

Returns the serial extracted from C<unitSerialNumber>. Must be enabled
in the snmp setup of the device to show this.

=item $redlion->vendor()

Returns 'redlion'.

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
