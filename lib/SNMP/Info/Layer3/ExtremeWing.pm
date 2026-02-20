package SNMP::Info::Layer3::ExtremeWing;
#
# Copyright (c) 2019 Netdisco Contributors
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

@SNMP::Info::Layer3::ExtremeWing::ISA = qw/
    SNMP::Info::Layer3
    Exporter
/;
@SNMP::Info::Layer3::ExtremeWing::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.975000';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'WING-MIB' => 'wingCfgMgmtName',
    'WS-SMI'   => 'ws2000',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,

# WiNG APs have a full entity mib, on all the models we tested in 2024 there is a single chassis entry at index 4000.
# The entPhysicalModelName seems to be a better representation of the model than the systemOID (e.g.wingSysoidAP310), 
# so we use the former if available.
# Sample data:
#  .1.3.6.1.2.1.47.1.1.1.1.2.4000 = STRING: "Extreme Networks, Inc. AP7532"
#  .1.3.6.1.2.1.47.1.1.1.1.2.4000 = STRING: "Extreme Networks, Inc. AP310"
#  .1.3.6.1.2.1.47.1.1.1.1.2.4000 = STRING: "Extreme Networks, Inc. AP360"
#  .1.3.6.1.2.1.47.1.1.1.1.2.4000 = STRING: "Extreme Networks, Inc. AP310-1"
#  .1.3.6.1.2.1.47.1.1.1.1.2.4000 = STRING: "Extreme Networks, Inc. NX5500"
#  .1.3.6.1.2.1.47.1.1.1.1.13.4000 = STRING: "AP310i-WR"
#  .1.3.6.1.2.1.47.1.1.1.1.13.4000 = STRING: "AP360i-WR"
#  .1.3.6.1.2.1.47.1.1.1.1.13.4000 = STRING: "AP310i-1-WR"
#  .1.3.6.1.2.1.47.1.1.1.1.13.4000 = STRING: "NX-5500-100R0-WR"
#  .1.3.6.1.2.1.47.1.1.1.1.13.4000 = STRING: "AP-7532-67030-WR"

    'wing_os_ver' => 'entPhysicalSoftwareRev.4000',
    'wing_mfg' => 'entPhysicalMfgName.4000',
    'wing_model' => 'entPhysicalModelName.4000'
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
);

sub vendor {
    my $self = shift;
    return $self->wing_mfg();
}

sub os_ver {
    my $self = shift;
    return $self->wing_os_ver();
}

sub os {
    return 'WiNG';
}

sub model {
    my $self = shift;
    # the super model is the resolved systemOid, use as fallback
    my $pm = $self->SUPER::model();
    my $wm =  $self->wing_model();
    return $wm ? $wm : $pm; 
}



1;

__END__

=head1 NAME

SNMP::Info::Layer3::ExtremeWing - SNMP Interface to Extreme WiNG APs

=head1 AUTHORS

Nick Nauwelaerts, Christian Ramseyer and Netdisco Contributors

=head1 SYNOPSIS

    # Let SNMP::Info determine the correct subclass for you.
    my $self = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

    my $class      = $self->class();
    print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Extreme WiNG APs

WiNG APs have a full entity mib, on all the models we tested in 2024 there
is a single chassis entry at index 4000. This class returns the relevant
bits from this index.


=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<WING-MIB>

=back

=head2 Inherited MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP.

=over

=item $self->os()

Returns 'WiNG'.

=item $self->os_ver()

Returns the os version extracted from C<entPhysicalSoftwareRev>.

=item $self->vendor()

Returns the value from C<entPhysicalMfgName>.

=item $self-model()

Returns the value from C<entPhysicalModelName>.

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
