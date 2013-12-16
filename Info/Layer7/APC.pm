# SNMP::Info::Layer7::APC - SNMP Interface to APC UPS devices
#
# Copyright (c) 2011 Jeroen van Ingen
#
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

package SNMP::Info::Layer7::APC;

use strict;
use Exporter;
use SNMP::Info::Layer7;

@SNMP::Info::Layer7::APC::ISA
    = qw/SNMP::Info::Layer7 Exporter/;
@SNMP::Info::Layer7::APC::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.10';

%MIBS = (
    %SNMP::Info::Layer7::MIBS,
    'PowerNet-MIB' => 'upsBasicIdentModel',
);

%GLOBALS = (
    %SNMP::Info::Layer7::GLOBALS,
    'ups_serial'   => 'upsAdvIdentSerialNumber.0',
    'mgmt_serial'  => 'experimental.2.4.1.2.1',
    'os_ver'       => 'experimental.2.4.1.4.1',
    'os_bin'       => 'experimental.2.4.1.4.2',
    'ups_model'    => 'upsBasicIdentModel.0',
    'ps1_status'   => 'upsBasicOutputStatus.0',
    'ps2_status'   => 'upsBasicBatteryStatus.0',
);

%FUNCS = (
    %SNMP::Info::Layer7::FUNCS,
    
);

%MUNGE = (
    # Inherit all the built in munging
    %SNMP::Info::Layer7::MUNGE,
);


# Method Overrides

sub os {
    return 'aos';
}

sub vendor {
    return 'apc';
}

sub model {
    my $apc = shift;
    return $apc->ups_model();
}

sub serial {
    my $apc = shift;
    my $ups = $apc->ups_serial() || 'unknown';
    my $mgmt = $apc->mgmt_serial() || 'unknown';
    return sprintf("UPS: %s, management card: %s", $ups, $mgmt);
}

sub ps1_type {
    return 'UPS status';
}

sub ps2_type {
    return 'Battery status';
}

1;
__END__

=head1 NAME

SNMP::Info::Layer7::APC - SNMP Interface to APC UPS devices

=head1 AUTHOR

Jeroen van Ingen

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $apc = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $apc->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a 
APC UPS via SNMP. 

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

 my $apc = new SNMP::Info::Layer7::APC(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer7

=back

=head2 Required MIBs

=over

=item F<POWERNET-MIB>

=back

All required MIBs can be found in the netdisco-mibs package.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $apc->os()

Returns C<'aos'>

=item $apc->os_bin()

C<POWERNET-MIB::experimental.2.4.1.4.2>

=item $apc->os_ver()

C<POWERNET-MIB::experimental.2.4.1.4.1>

=item $apc->serial()

Combines the UPS serial C<upsAdvIdentSerialNumber.0> with the management
card serial C<POWERNET-MIB::experimental.2.4.1.2.1> into a pretty string.

=item $apc->vendor()

Returns C<'apc'>

=item $apc->model()

C<upsBasicIdentModel.0>

=item $apc->ps1_type()

Returns 'UPS status'

=item $apc->ps1_status()

Returns the main UPS status from C<upsBasicOutputStatus.0>

=item $apc->ps2_type()

Returns 'Battery status'

=item $apc->ps2_status()

Returns the battery status from C<upsBasicBatteryStatus.0>

=back

=head2 Globals imported from SNMP::Info::Layer7

See documentation in L<SNMP::Info::Layer7/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=back

=head2 Table Methods imported from SNMP::Info::Layer7

See documentation in L<SNMP::Info::Layer7/"TABLE METHODS"> for details.

=head1 MUNGES

=over

=back

=head1 SET METHODS

These are methods that provide SNMP set functionality for overridden methods
or provide a simpler interface to complex set operations.  See
L<SNMP::Info/"SETTING DATA VIA SNMP"> for general information on set
operations. 

=cut
