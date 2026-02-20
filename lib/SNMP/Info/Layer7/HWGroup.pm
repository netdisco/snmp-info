# SNMP::Info::Layer7::HWGroup
#
# Copyright (c) 2022 Netdisco Developers
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

package SNMP::Info::Layer7::HWGroup;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer7;

@SNMP::Info::Layer7::HWGroup::ISA       = qw/SNMP::Info::Layer7/;
@SNMP::Info::Layer7::HWGroup::EXPORT_OK = qw//;

our ($VERSION, %FUNCS, %GLOBALS, %MIBS, %MUNGE);

$VERSION = '3.975000';

%MIBS = (
    %SNMP::Info::Layer7::MIBS,
    'HWG-STE-MIB' => 'hwgroup',
);

%GLOBALS = (%SNMP::Info::Layer7::GLOBALS);

%FUNCS = (%SNMP::Info::Layer7::FUNCS);

%MUNGE = (%SNMP::Info::Layer7::MUNGE);

#sub os {
#    return '';
#}

#sub model {
#    return '';
#}

#sub vendor {
#    return '';
#}

1;

__END__

=head1 NAME

SNMP::Info::Layer7::HWGroup - SNMP Interface to HW Group devices

=head1 AUTHOR

Netdisco Developers

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $hwgroup = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myhub',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $hwgroup->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to information obtainable from an HW Group device
through SNMP. See inherited classes' documentation for inherited methods.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer7

=back

=head2 Required MIBs

=over

=item F<HWG-STE-MIB>

=back

=head2 Inherited MIBs

See L<SNMP::Info::Layer7/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

#=head2 Overrides
#
#=over
#
#=item $hwgroup->vendor()
#
#Returns 'hwgroup'
#
#=item $hwgroup->os()
#
#Returns 'hwgroup'
#
#=item $hwgroup->os_ver()
#
#(C<lgpAgentDeviceFirmwareVersion.1>)
#
#=item $hwgroup->model()
#
#(C<lgpAgentDeviceModel.1>)
#
#=item $hwgroup->serial()
#
#(C<lgpAgentDeviceSerialNumber.1>)
#
#=back

=head2 Globals imported from SNMP::Info::Layer7

See L<SNMP::Info::Layer7/"GLOBALS"> for details.

=head1 TABLE METHODS

=head2 Table Methods imported from SNMP::Info::Layer7

See L<SNMP::Info::Layer7/"TABLE METHODS"> for details.

=cut
