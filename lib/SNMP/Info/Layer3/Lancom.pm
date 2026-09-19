# SNMP::Info::Layer3::Lancom
#
# Copyright (c) 2026 df-an and the SNMP::Info Developers
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

package SNMP::Info::Layer3::Lancom;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

our @ISA = qw(
    SNMP::Info::Layer3
    Exporter
);

our (
    $VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.977001';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,

    # LCOS Status > Hardware-Info
    'lancom_model'  => '.1.3.6.1.4.1.2356.11.1.47.6.0',
    'lancom_serial' => '.1.3.6.1.4.1.2356.11.1.47.7.0',
    'lancom_fw'     => '.1.3.6.1.4.1.2356.11.1.47.9.0',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
);

sub vendor {
    return 'lancom';
}

sub model {
    my $self = shift;
    return $self->lancom_model();
}

sub serial {
    my $self = shift;
    return $self->lancom_serial();
}

sub os {
    return 'LCOS';
}

sub os_ver {
    my $self = shift;

    my $version = $self->lancom_fw();
    return unless defined($version) && length($version);

    $version =~ s/\s*\/.*$//;
    $version =~ s/^\s+|\s+$//g;

    return $version;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer3::Lancom - SNMP Interface to LANCOM LCOS devices

=head1 AUTHORS

df-an and the SNMP::Info Developers

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $lancom = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $lancom->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for LANCOM devices running LCOS.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

No additional MIB is required. The LANCOM hardware information is queried using
numeric OIDs.

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar values from SNMP.

=over

=item $lancom->model()

Returns the LANCOM model name.

=item $lancom->serial()

Returns the LANCOM serial number.

=item $lancom->os()

Returns C<'LCOS'>.

=item $lancom->os_ver()

Returns the LCOS firmware version. A date or other suffix following C<' / '>
is removed from the value reported by the device.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=cut
