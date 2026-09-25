# SNMP::Info::Layer2::Microsens
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

package SNMP::Info::Layer2::Microsens;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer2;

@SNMP::Info::Layer2::Microsens::ISA = qw/SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::Microsens::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.977001';

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
);

# Numeric OIDs from the MICROSENS G6 MIBs keep inventory working when the
# vendor MIB files are not installed. Other MICROSENS switch generations use
# the inherited standard and ENTITY-MIB inventory methods.
%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
    'microsens_model'    => '.1.3.6.1.4.1.3181.10.6.1.32.1.0',
    'microsens_serial'   => '.1.3.6.1.4.1.3181.10.6.1.32.2.0',
    'microsens_firmware' => '.1.3.6.1.4.1.3181.10.6.1.30.106.1.2.0',
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer2::MUNGE,
);

my $clean_value = sub {
    my $value = shift;

    return unless defined $value;
    $value =~ s/^[\x00\s]+//;
    $value =~ s/[\x00\s]+$//;
    return length($value) ? $value : undef;
};

my $is_g6 = sub {
    my $microsens = shift;

    return (($microsens->id() || '')
        =~ /^\.?1\.3\.6\.1\.4\.1\.3181\.10\.6(?:\.|$)/) ? 1 : 0;
};

sub vendor {
    return 'microsens';
}

sub model {
    my $microsens = shift;

    if ($is_g6->($microsens)) {
        my $model = $clean_value->($microsens->microsens_model());
        return $model if defined $model;
    }

    return $microsens->SUPER::model();
}

sub serial {
    my $microsens = shift;

    if ($is_g6->($microsens)) {
        my $serial = $clean_value->($microsens->microsens_serial());
        return $serial if defined $serial;
    }

    return $microsens->SUPER::serial();
}

sub os {
    return 'microsens';
}

sub os_ver {
    my $microsens = shift;

    if ($is_g6->($microsens)) {
        my $version = $clean_value->($microsens->microsens_firmware());
        return $version if defined $version;
    }

    return $clean_value->($microsens->entity_derived_os_ver());
}

1;

__END__

=head1 NAME

SNMP::Info::Layer2::Microsens - SNMP Interface to MICROSENS switches

=head1 AUTHOR

df-an and the SNMP::Info Developers

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $microsens = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $microsens->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for MICROSENS managed switches, including G6 and G6+. Devices are
detected through the MICROSENS enterprise C<sysObjectID>
C<1.3.6.1.4.1.3181> in the Layer2 enterprise map. G6-specific inventory is
read from its documented
C<1.3.6.1.4.1.3181.10.6> subtree; other generations retain the inherited
standard and ENTITY-MIB fallbacks.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

No additional MIB is required. MICROSENS inventory values are queried using
numeric OIDs.

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer2> for its own MIB requirements.

=back

=head1 GLOBALS

=over

=item $microsens->vendor()

Returns C<'microsens'>.

=item $microsens->name()

Returns the standard SNMP C<sysName.0> value inherited from SNMP::Info.

=item $microsens->model()

Returns C<factoryArticleNumber.0> from F<G6-FACTORY-MIB>, falling back to the
model derived by SNMP::Info::Layer2.

=item $microsens->serial()

Returns C<factorySerialNumber.0> from F<G6-FACTORY-MIB>, falling back to the
serial number derived by SNMP::Info::Layer2.

=item $microsens->os()

Returns the fixed operating-system identifier C<'microsens'>.

=item $microsens->os_ver()

Returns C<firmwareRunningVersion.0> from F<G6-SYSTEM-MIB>. Other switch
generations, and G6 devices where this scalar is unavailable, fall back to the
software revision derived from ENTITY-MIB.

=back

=head2 Globals imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2> for details.

=cut
