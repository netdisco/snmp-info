# SNMP::Info::Layer3::Siemens - SNMP interface to Siemens automation devices
#
# Copyright (c) 2026
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
#     * Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

package SNMP::Info::Layer3::Siemens;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Siemens::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Siemens::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.979000';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
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
    return 'siemens';
}

sub os {
    return 'siemens';
}

sub model {
    my $siemens = shift;
    my $descr = $siemens->description();

    return unless defined $descr;

    if ( $descr =~ /^Siemens,?\s*SIMATIC\s+(?:S7|HMI),\s*([^,]+)/i ) {
        return $1 if lc($1) ne 'unknown';
    }
    return $1 if $descr =~ /^Siemens,?\s*(SIMOCODE\s+[^,]+)/i;
    return $1 if $descr =~ /^Siemens,?\s*SINAMICS,\s*([^,]+)/i;
    return $1 if $descr =~ /^Siemens\s+Soft\s+starter\s+([^,]+)/i;
    return $1 if $descr =~ /\b(6[A-Z0-9]{3}\s+\d{3}-[A-Z0-9]+-[A-Z0-9]+)\b/i;

    return;
}

sub os_ver {
    my $siemens = shift;
    my $descr = $siemens->description();

    return unless defined $descr;

    if ( $descr =~ /\b(?:FW|SW):\s*(?:Version\s*)?V?\s*([\w.-]+(?:\s+[\w.-]+){0,2})/i ) {
        my $version = $1;
        $version =~ s/\s+/./g;
        return $version;
    }

    return;
}

sub serial {
    my $siemens = shift;
    my $descr = $siemens->description();

    return unless defined $descr;

    return $1 if $descr =~ /\b(?:SN:\s*)?(S\s+C-[A-Z0-9]+)\b/i;

    return $siemens->SUPER::serial();
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Siemens - SNMP interface to Siemens automation devices

=head1 DESCRIPTION

Provides manufacturer, model, firmware, and serial details for Siemens SIMATIC
S7 controllers, SIMATIC HMIs, SIMOCODE motor management devices, SINAMICS
drives, and soft starters whose
C<sysDescr> uses the Siemens product description format. SCALANCE devices
continue to use L<SNMP::Info::Layer3::Scalance>.

=head1 METHODS

=head2 Overrides

=over 4

=item $siemens->vendor()

Returns C<siemens>.

=item $siemens->os()

Returns C<siemens>.

=item $siemens->model()

Extracts the product model from the Siemens C<sysDescr> string.

=item $siemens->os_ver()

Extracts the firmware or software version from the Siemens C<sysDescr> string.

=item $siemens->serial()

Extracts a serial number from the Siemens C<sysDescr> string, falling back to
the inherited serial number method when the description has no match.

=back

=cut
