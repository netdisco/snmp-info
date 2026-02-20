package SNMP::Info::Layer3::EdgeSwitch;

# Copyright (c) 2025 Ambroise Rosset
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

@SNMP::Info::Layer3::EdgeSwitch::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::EdgeSwitch::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.975000';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'EdgeSwitch-SWITCHING-MIB' => 'fastPathSwitching',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'inv_mach_model'  => 'agentInventoryMachineModel',
    'serial1'=> 'agentInventorySerialNumber',
    'sw_ver' => 'agentInventorySoftwareVersion',
);

%FUNCS = ( %SNMP::Info::Layer3::FUNCS, );

%MUNGE = ( %SNMP::Info::Layer3::MUNGE, );

sub vendor {
    return 'broadcom';
}

sub model {
    my $es = shift;
    my $model = $es->inv_mach_model();

    return $model if defined($model);
}

sub os {
    return 'efos';
}

sub os_ver {
    my $es = shift;
    my $os_ver = $es->sw_ver();
    my $os_string = $es->sys_descr();
    if (defined ($os_ver)) {
        return $os_ver;
    } elsif (defined ($os_string) && $os_string =~ /^EFOS, ([\.0-9]+),/) {
        return $1;
    } else {
        return ''; # perhaps we can try sysDescr or some other object...
    }
}

1;

__END__

=head1 NAME

SNMP::Info::Layer3::EdgeSwitch - SNMP Interface to Broadcom EdgeSwitch devices.

=head1 AUTHOR

Ambroise Rosset

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $router = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $router->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Broadcom EdgeSwitch devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<EdgeSwitch-SWITCHING-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=head2 Overrides

=over

=item $router->vendor()

Returns C<'broadcom'>

=item $router->model()

Tries to resolve model string fomr C<"agentInventoryMachineModel">

=item $router->os()

Returns C<'efos'>

=item $router->os_ver()

Tries to resolve version string from C<"agentInventorySoftwareVersion"> or C<"sysDescr">.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut

