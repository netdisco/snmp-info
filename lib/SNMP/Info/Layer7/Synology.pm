# SNMP::Info::Layer7::Synology
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
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Layer7::Synology;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer7;

@SNMP::Info::Layer7::Synology::ISA = qw/SNMP::Info::Layer7 Exporter/;
@SNMP::Info::Layer7::Synology::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.978000';

%MIBS = (
    %SNMP::Info::Layer7::MIBS,
);

# Numeric OIDs keep basic inventory independent of Synology MIB installation.
%GLOBALS = (
    %SNMP::Info::Layer7::GLOBALS,
    'synology_model'  => '.1.3.6.1.4.1.6574.1.5.1.0',
    'synology_serial' => '.1.3.6.1.4.1.6574.1.5.2.0',
    'synology_ver'    => '.1.3.6.1.4.1.6574.1.5.3.0',
);

%FUNCS = (
    %SNMP::Info::Layer7::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer7::MUNGE,
);

sub _synology_value {
    my $value = shift;

    return unless defined $value;
    $value =~ s/\x00+$//;
    $value =~ s/^\s+|\s+$//g;

    return length($value) ? $value : undef;
}

sub vendor {
    return 'synology';
}

sub model {
    my $synology = shift;

    my $model = _synology_value($synology->synology_model());
    return $model if defined $model;

    return $synology->SUPER::model();
}

sub serial {
    my $synology = shift;

    return _synology_value($synology->synology_serial());
}

sub os {
    return 'dsm';
}

sub os_ver {
    my $synology = shift;

    my $version = _synology_value($synology->synology_ver());
    return unless defined $version;

    $version =~ s/^DSM\s+//i;
    return $version;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer7::Synology - SNMP Interface to Synology NAS devices

=head1 AUTHOR

df-an and the SNMP::Info Developers

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $synology = new SNMP::Info(
                         AutoSpecify => 1,
                         Debug       => 1,
                         DestHost    => 'mynas',
                         Community   => 'public',
                         Version     => 2
                       )
    or die "Can't connect to DestHost.\n";

 my $class = $synology->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Synology NAS devices running DiskStation Manager (DSM).
Synology's SNMP agent commonly reports the generic Net-SNMP Linux
C<sysObjectID> C<8072.3.2.10>, while C<sysDescr> contains only generic Linux
information.  SNMP::Info therefore confirms DSM using the operating-system
version scalar under enterprise C<6574>.  The same confirmation is used for
native Synology C<sysObjectID> values because the enterprise subtree is also
used by non-DSM Synology products.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer7

=back

=head2 Inherited MIBs

Synology inventory values are queried using numeric OIDs, so Synology's MIB
files do not need to be installed.

See L<SNMP::Info::Layer7/"Required MIBs"> for inherited requirements.

=head1 GLOBALS

=over

=item $synology->vendor()

Returns C<'synology'>.

=item $synology->model()

Returns the model from C<modelName.0>, falling back to the inherited model
method when the Synology scalar is unavailable.

=item $synology->serial()

Returns the device serial number from C<serialNumber.0>.

=item $synology->os()

Returns the lowercase operating-system identifier C<'dsm'>.

=item $synology->os_ver()

Returns the DSM version reported by C<version.0>.  A leading C<DSM> label is
removed while the remaining vendor version is preserved unchanged.

=back

=head2 Globals imported from SNMP::Info::Layer7

See L<SNMP::Info::Layer7/"GLOBALS"> for details.

=head1 TABLE METHODS

=head2 Table Methods imported from SNMP::Info::Layer7

See L<SNMP::Info::Layer7/"TABLE METHODS"> for details.

=cut
