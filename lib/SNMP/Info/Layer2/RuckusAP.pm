# SNMP::Info::Layer2::RuckusAP - SNMP interface to Ruckus access points
#
# Copyright (c) 2026 The SNMP::Info Developers
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

package SNMP::Info::Layer2::RuckusAP;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer2;

our ($VERSION, %GLOBALS, %FUNCS, %MIBS, %MUNGE);
$VERSION = '3.982000';
@SNMP::Info::Layer2::RuckusAP::ISA = qw(SNMP::Info::Layer2 Exporter);
@SNMP::Info::Layer2::RuckusAP::EXPORT_OK = qw//;

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
    'RUCKUS-HWINFO-MIB' => 'ruckusHwInfoModelNumber',
    'RUCKUS-SWINFO-MIB' => 'ruckusSwRevision',
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
    'ruckus_model'  => 'ruckusHwInfoModelNumber',
    'ruckus_serial' => 'ruckusHwInfoSerialNumber',
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
    'ruckus_sw_rev'        => 'ruckusSwRevision',
    'ruckus_sw_rev_status' => 'ruckusSwRevStatus',
);

%MUNGE = (
    %SNMP::Info::Layer2::MUNGE,
);

sub model {
    my $self = shift;
    my $description = $self->description() || '';
    my ($unleashed_model) = $description =~ /^Ruckus Wireless ([A-Z]\d{3}\w*)/;
    return $self->ruckus_model() || $unleashed_model || $self->SUPER::model();
}

sub vendor { return 'ruckus'; }
sub os { return 'ruckus'; }
sub os_ver {
    my $self = shift;
    my $revisions = $self->ruckus_sw_rev() || {};
    my $statuses  = $self->ruckus_sw_rev_status() || {};

    foreach my $index ( sort { $a <=> $b } keys %$revisions ) {
        my $status = $statuses->{$index};
        my $revision = $revisions->{$index};
        next unless defined $status;
        next unless defined $revision and $revision =~ /\S/;
        return $revision
            if $status =~ /^(?:active|2)$/i;
    }

    # Some firmware (R500 on 9.13) answers ruckusSwRevision with no status.
    my ($first_revision) = grep { defined and /\S/ }
        @$revisions{ sort { $a <=> $b } keys %$revisions };
    return $first_revision if !%$statuses and defined $first_revision;

    return $self->SUPER::os_ver();
}
sub serial {
    my $self = shift;
    my $serial = $self->ruckus_serial();
    return $serial if defined $serial and $serial !~ /^\s*$/;
    return $self->SUPER::serial();
}

1;

__END__

=head1 NAME

SNMP::Info::Layer2::RuckusAP - SNMP interface to Ruckus access points

=head1 AUTHOR

SNMP::Info Developers

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $ruckus = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myap',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $ruckus->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides model, serial number, and software version information for Ruckus
access points registered below the Ruckus wireless product OID branches, and
for Unleashed access points identified by C<sysDescr>.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

=over

=item F<RUCKUS-HWINFO-MIB>

=item F<RUCKUS-SWINFO-MIB>

=back

=head2 Inherited MIBs

See L<SNMP::Info::Layer2/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These methods return scalar values.

=over

=item $ruckus->ruckus_model()

Returns the model number reported by the access point.

(C<ruckusHwInfoModelNumber>)

=item $ruckus->ruckus_serial()

Returns the serial number reported by the access point.

(C<ruckusHwInfoSerialNumber>)

=back

=head2 Overrides

=over

=item $ruckus->vendor()

Returns C<ruckus>.

=item $ruckus->os()

Returns C<ruckus>.

=item $ruckus->model()

Returns the model from C<ruckusHwInfoModelNumber>. Unleashed access points
do not answer it, so the model named in C<sysDescr> is used next, then the
inherited model method.

=item $ruckus->serial()

Returns the serial number from C<ruckusHwInfoSerialNumber>, falling back to
the inherited serial method.

=item $ruckus->os_ver()

Returns the software revision whose C<ruckusSwRevStatus> is active. When no
revision has a status, returns the lowest-indexed revision, then falls back
to the inherited method.

=back

=head2 Global Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Ruckus Software Revision Table (C<ruckusSwRevTable>)

=over

=item $ruckus->ruckus_sw_rev()

Returns reference to hash. Key: revision index, Value: software revision.

(C<ruckusSwRevision>)

=item $ruckus->ruckus_sw_rev_status()

Returns reference to hash. Key: revision index, Value: C<active> for the
running revision, otherwise C<inactive>.

(C<ruckusSwRevStatus>)

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=cut
