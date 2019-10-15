# SNMP::Info::Layer7::Liebert
#
# Copyright (c) 2018 Netdisco Developers
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

package SNMP::Info::Layer7::Liebert;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer7;

@SNMP::Info::Layer7::Liebert::ISA       = qw/SNMP::Info::Layer7/;
@SNMP::Info::Layer7::Liebert::EXPORT_OK = qw//;

our ($VERSION, %FUNCS, %GLOBALS, %MIBS, %MUNGE);

$VERSION = '3.70';

%MIBS = (
    %SNMP::Info::Layer7::MIBS,
    'LIEBERT-GP-AGENT-MIB' => 'lgpAgentDeviceSerialNumber',
);

%GLOBALS = (
    %SNMP::Info::Layer7::GLOBALS,
    'serial'        => 'lgpAgentDeviceSerialNumber.1',
    'os_ver'        => 'lgpAgentDeviceFirmwareVersion.1',
    'liebert_model' => 'lgpAgentDeviceModel.1',
);

%FUNCS = (%SNMP::Info::Layer7::FUNCS);

%MUNGE = (%SNMP::Info::Layer7::MUNGE);

sub os {
    return 'LiebertOS';
}

sub model {
    my $liebert = shift;

    return $liebert->liebert_model();
}

sub vendor {
    return 'liebert';
}

1;

__END__

=head1 NAME

SNMP::Info::Layer7::Liebert - SNMP Interface to Liebert devices

=head1 AUTHOR

Netdisco Developers

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $liebert = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myhub',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $liebert->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to information obtainable from a Liebert device
through SNMP. See inherited classes' documentation for inherited methods.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer7

=back

=head2 Required MIBs

=over

=item F<LIEBERT-GP-AGENT-MIB>

=back

=head2 Inherited MIBs

See L<SNMP::Info::Layer7/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=head2 Overrides

=over

=item $liebert->vendor()

Returns 'liebert'

=item $liebert->os()

Returns 'LiebertOS'

=item $liebert->os_ver()

(C<lgpAgentDeviceFirmwareVersion.1>)

=item $liebert->model()

(C<lgpAgentDeviceModel.1>)

=item $liebert->serial()

(C<lgpAgentDeviceSerialNumber.1>)

=back

=head2 Globals imported from SNMP::Info::Layer7

See L<SNMP::Info::Layer7/"GLOBALS"> for details.

=head1 TABLE METHODS

=head2 Table Methods imported from SNMP::Info::Layer7

See L<SNMP::Info::Layer7/"TABLE METHODS"> for details.

=cut
