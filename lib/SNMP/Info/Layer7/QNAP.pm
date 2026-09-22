# SNMP::Info::Layer7::QNAP
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

package SNMP::Info::Layer7::QNAP;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Entity;
use SNMP::Info::Layer7;

@SNMP::Info::Layer7::QNAP::ISA =
    qw/SNMP::Info::Layer7 SNMP::Info::Entity Exporter/;
@SNMP::Info::Layer7::QNAP::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.977001';

%MIBS = (
    %SNMP::Info::Layer7::MIBS,
    %SNMP::Info::Entity::MIBS,
);

# Numeric OIDs allow inventory to work without installing QNAP's MIB files.
# QTS-MIB uses enterprise 55062 with separate QTS (.1) and QuTS hero (.2)
# subtrees.  Older devices use NAS-MIB (enterprise 24681), which exposes the
# model but not dedicated serial number or firmware scalars.
%GLOBALS = (
    %SNMP::Info::Layer7::GLOBALS,
    %SNMP::Info::Entity::GLOBALS,
    'qnap_qts_hostname'   => '.1.3.6.1.4.1.55062.1.12.4.0',
    'qnap_qts_model'      => '.1.3.6.1.4.1.55062.1.12.3.0',
    'qnap_qts_serial'     => '.1.3.6.1.4.1.55062.1.12.5.0',
    'qnap_qts_firmware'   => '.1.3.6.1.4.1.55062.1.12.6.0',
    'qnap_quts_hostname'  => '.1.3.6.1.4.1.55062.2.12.4.0',
    'qnap_quts_model'     => '.1.3.6.1.4.1.55062.2.12.3.0',
    'qnap_quts_serial'    => '.1.3.6.1.4.1.55062.2.12.5.0',
    'qnap_quts_firmware'  => '.1.3.6.1.4.1.55062.2.12.6.0',
    'qnap_legacy_model'   => '.1.3.6.1.4.1.24681.1.2.12.0',
);

%FUNCS = (
    %SNMP::Info::Layer7::FUNCS,
    %SNMP::Info::Entity::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer7::MUNGE,
    %SNMP::Info::Entity::MUNGE,
);

sub _qnap_value {
    my $value = shift;

    return unless defined $value;
    $value =~ s/\x00+$//;
    $value =~ s/^\s+|\s+$//g;
    return length($value) ? $value : undef;
}

sub _qnap_sysobjectid {
    my $qnap = shift;

    my $id = _qnap_value($qnap->id());
    return '' unless defined $id;

    $id =~ s/^\.//;
    return $id;
}

sub _qnap_current_value {
    my ($qnap, $qts_method, $quts_method) = @_;

    my $id = _qnap_sysobjectid($qnap);
    my @methods = $id =~ /^1\.3\.6\.1\.4\.1\.55062\.2(?:\.|$)/
        ? ($quts_method, $qts_method)
        : ($qts_method, $quts_method);

    for my $method (@methods) {
        my $value = _qnap_value($qnap->$method());
        return $value if defined $value;
    }

    return;
}

sub _qnap_description_version {
    my $qnap = shift;

    # QTS example:       Linux TS-X41 5.2.5.3145
    # QuTS hero example: Linux TS-X73A h5.2.10.3577
    # Keep this deliberately strict so an unrelated Linux kernel version is
    # not accepted after an arbitrary description.
    my $description = $qnap->description() || '';
    return $1
        if $description
        =~ /^Linux\s+
            (?:(?:TS|TVS|TBS|HS|SS|IS|TES|ES|GM|TL|TR|QGD|QVP)-\S+|QBoat\S*)
            \s+([hH]?(?:\d+\.){2,3}\d+(?:[-+][[:alnum:]._-]+)?)(?:\s|$)/x;

    return;
}

sub _qnap_primary_firmware_version {
    my $qnap = shift;

    my $version = _qnap_current_value(
        $qnap, 'qnap_qts_firmware', 'qnap_quts_firmware'
    );
    return $version if defined $version;

    $version = _qnap_description_version($qnap);
    return $version if defined $version;

    return;
}

sub _qnap_entity_firmware_version {
    my $qnap = shift;

    my $e_parent = $qnap->e_parent() || {};
    my $e_class  = $qnap->e_class() || {};

    for my $iid (sort keys %$e_parent) {
        my $parent = $e_parent->{$iid};
        my $class  = $e_class->{$iid} || '';
        next unless (defined $parent && $parent eq '0')
            || $class eq 'chassis';

        # Read the original ENTITY-MIB leaf directly.  Calling e_swver() here
        # would recurse into the QNAP override below.
        my $versions = $qnap->entPhysicalSoftwareRev($iid) || {};
        my $version  = _qnap_value($versions->{$iid});
        return $version if defined $version;
    }

    return;
}

sub _qnap_firmware_version {
    my $qnap = shift;

    my $version = _qnap_primary_firmware_version($qnap);
    return $version if defined $version;

    return _qnap_entity_firmware_version($qnap);
}

sub e_swver {
    my ($qnap, $partial) = @_;

    my $versions = $qnap->entPhysicalSoftwareRev($partial) || {};
    my $version  = _qnap_primary_firmware_version($qnap);
    return $versions unless defined $version;

    my $e_parent = $qnap->e_parent() || {};
    my $e_class  = $qnap->e_class() || {};
    my %result   = %$versions;

    # Netdisco's module inventory prefers the chassis e_swver value over the
    # device os_ver value.  Some QNAP agents publish only major.minor.patch in
    # entPhysicalSoftwareRev, while QTS-MIB/sysDescr contains the complete
    # vendor firmware (including build and the QuTS hero "h" prefix).  Keep
    # ENTITY-MIB support for legacy inventory, but make its chassis value agree
    # with os_ver so every Netdisco view receives the same complete version.
    for my $iid (keys %result) {
        my $parent = $e_parent->{$iid};
        my $class  = $e_class->{$iid} || '';
        next unless (defined $parent && $parent eq '0')
            || $class eq 'chassis';

        $result{$iid} = $version;
    }

    return \%result;
}

sub vendor {
    return 'qnap';
}

sub name {
    my $qnap = shift;

    my $name = _qnap_current_value(
        $qnap, 'qnap_qts_hostname', 'qnap_quts_hostname'
    );
    return $name if defined $name;

    return _qnap_value($qnap->SUPER::name());
}

sub model {
    my $qnap = shift;

    my $model = _qnap_current_value(
        $qnap, 'qnap_qts_model', 'qnap_quts_model'
    );
    return $model if defined $model;

    $model = _qnap_value($qnap->qnap_legacy_model());
    return $model if defined $model;

    return $qnap->SUPER::model();
}

sub serial {
    my $qnap = shift;

    my $serial = _qnap_current_value(
        $qnap, 'qnap_qts_serial', 'qnap_quts_serial'
    );
    return $serial if defined $serial;

    return _qnap_value($qnap->entity_derived_serial());
}

sub os {
    my $qnap = shift;

    my $id = _qnap_sysobjectid($qnap);
    return 'quts hero'
        if $id =~ /^1\.3\.6\.1\.4\.1\.55062\.2(?:\.|$)/;
    return 'qts'
        if $id =~ /^1\.3\.6\.1\.4\.1\.55062\.1(?:\.|$)/;

    # Legacy agents and some firmware versions expose only a generic QNAP
    # sysObjectID.  QuTS hero firmware versions are prefixed with "h".
    my $version = _qnap_firmware_version($qnap);
    return 'quts hero' if defined $version && $version =~ /^h\d/i;

    return 'qts';
}

sub os_ver {
    my $qnap = shift;

    my $version = _qnap_firmware_version($qnap);
    return $version if defined $version;

    return;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer7::QNAP - SNMP Interface to QNAP NAS devices

=head1 AUTHOR

df-an and the SNMP::Info Developers

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $qnap = new SNMP::Info(
                         AutoSpecify => 1,
                         Debug       => 1,
                         DestHost    => 'mynas',
                         Community   => 'public',
                         Version     => 2
                       )
    or die "Can't connect to DestHost.\n";

 my $class = $qnap->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for QNAP NAS devices running QTS or QuTS hero.  Devices using both
the legacy QNAP enterprise number C<24681> and the current enterprise number
C<55062> are detected automatically from C<sysObjectID>.  Current QTS and
QuTS hero inventory is read from the C<55062.1> and C<55062.2> subtrees,
respectively.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer7

=item SNMP::Info::Entity

=back

=head2 Inherited MIBs

QNAP inventory values are queried using numeric OIDs, so neither F<NAS-MIB>
nor F<QTS-MIB> needs to be installed.

See L<SNMP::Info::Layer7/"Required MIBs"> and L<SNMP::Info::Entity> for
inherited requirements.

=head1 GLOBALS

=over

=item $qnap->vendor()

Returns C<'qnap'>.

=item $qnap->name()

Returns C<hostname.0> from the QTS or QuTS hero subtree of QTS-MIB, falling
back to the standard SNMP C<sysName.0> value.

=item $qnap->model()

Returns C<systemModel.0> from the QTS or QuTS hero subtree of QTS-MIB,
falling back to C<modelName.0> from NAS-MIB on legacy devices.

=item $qnap->serial()

Returns C<serialNumber.0> from the QTS or QuTS hero subtree of QTS-MIB.
Legacy devices fall back to the serial number derived from ENTITY-MIB.

=item $qnap->os()

Returns the lowercase operating-system family identifier C<'qts'> or
C<'quts hero'>.  The explicit QTS-MIB subtree takes precedence.  For legacy
or generic QNAP C<sysObjectID> values, a firmware version beginning with C<h>
identifies QuTS hero; all other QNAP devices fall back to QTS.

=item $qnap->os_ver()

Returns C<firmwareVersion.0> from the QTS or QuTS hero subtree of QTS-MIB.
Legacy devices fall back to a firmware version in QNAP's C<sysDescr> format
and then to ENTITY-MIB.  The QuTS hero C<h> prefix is preserved so the full
vendor version, for example C<h5.2.10.3577>, remains available for security
advisory and vulnerability matching.

=item $qnap->e_swver()

Returns ENTITY-MIB software revisions for component inventory.  For a chassis
entry, a complete QTS-MIB or QNAP C<sysDescr> firmware version takes precedence
over a shortened C<entPhysicalSoftwareRev> value.  This keeps the module
inventory consistent with C<os_ver()> without changing Netdisco report code.

=back

=cut
