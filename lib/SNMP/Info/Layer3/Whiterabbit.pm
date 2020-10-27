# SNMP::Info::Layer3::Whiterabbit - SNMP Interface to Whiterabbit
#
# Copyright (c) 2020 Christoph Handel GSI Helmholtzzentrum fuer
# Schwerionenforschung
#
# Copyright (c) 2008-2009 Max Baker changes from version 0.8 and beyond.
#
# Copyright (c) 2002,2003 Regents of the University of California
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
#     * Neither the name of the University of California, Santa Cruz , 
#       the GSI Helmholtzzentrum fuer Schwerionenforschung, nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission
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
#

package SNMP::Info::Layer3::Whiterabbit;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::MAU;
use SNMP::Info::LLDP;
use SNMP::Info::Bridge;
use Socket;
use Data::Dumper;

@SNMP::Info::Layer3::Whiterabbit::ISA = qw/
    SNMP::Info::Layer3
    SNMP::Info::MAU
    SNMP::Info::Bridge
    SNMP::Info::LLDP
    Exporter
/;
@SNMP::Info::Layer3::Whiterabbit::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %PORTSTAT, %MODEL_MAP, %MUNGE);

$VERSION = '3.70';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::MAU::MIBS,
    %SNMP::Info::LLDP::MIBS,
    %SNMP::Info::Bridge::MIBS,
    'WR-SWITCH-MIB' => 'wrsScalar',
    # 'SN-MSPS-SCX-MIB' => 'snMsps',
    # 'AUTOMATION-SYSTEM-MIB' => 'automationManufacturerId',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::MAU::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,    
    %SNMP::Info::Bridge::GLOBALS,   
    'serial1' => 'wrsVersionSwitchSerialNumber.0', 
    'vendor1' => 'wrsVersionManufacturer.0',
    'os_ver' => 'wrsVersionGwVersion.0',
    # 'ps1_status' => 'snMspsPowerSupply1State.0',
    # 'ps2_status' => 'snMspsPowerSupply2State.0',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::MAU::FUNCS,
    %SNMP::Info::LLDP::FUNCS,    
    %SNMP::Info::Bridge::FUNCS,    
);

%MUNGE = (
    # Inherit all the built in munging
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::MAU::MUNGE,
    %SNMP::Info::LLDP::MUNGE,
    %SNMP::Info::Bridge::MUNGE,
);

sub layers {
    # not reporting anything in sysServices
    # but it sure is a bridge and can do 2 and 3
    return '00000111';
}

sub os {
    return 'whiterabbit';
}

sub vendor {
     my $whiterabbit = shift;
     return $whiterabbit->vendor1();
}
    
sub mac {
    # use dot1dBaseBridgeAddress
    my $whiterabbit = shift;
    return $whiterabbit->b_mac();
}


1;
__END__

=head1 NAME

SNMP::Info::Layer3::Whiterabbit - SNMP Interface to Siemens Whiterabbit Switches

=head1 AUTHOR

Christoph Handel

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $whiterabbit = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $whiterabbit->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a
Siemens Whiterabbit Switch via SNMP.

Tested only with sclance xr524

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::MAU

=item SNMP::Info::LLDP

=item SNMP::Info::Bridge


=back

=head2 Required MIBs

=over

=item F<SN-MSPS-SCX-MIB>

=item F<AUTOMATION-SYSTEM-MIB>

=item F<AUTOMATION-SMI.txt>

=item F<AUTOMATION-SYSTEM-MIB>

=item F<AUTOMATION-TC>

=item F<SIEMENS-SMI>

=back

L<https://support.industry.siemens.com/cs/document/22015045/private-mibs%3A-whiterabbit-x-whiterabbit-w-and-snmp-opc-profile?dti=0&lc=en-DE>

L<https://support.industry.siemens.com/cs/document/67637278/automationmib-now-available-for-download-in-version-v02-00-00-02-?dti=0&lc=en-TN>


=head1 Change Log

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $whiterabbit->layers()

Overwrite snmp value, we support 1-3

=item $whiterabbit->os()

Returns whiterabbit

=item $whiterabbit->vendor()

Returns siemens

=item $whiterabbit->model()

extrace a meaningful name from description

=item $whiterabbit->mac()

use the dot1dBaseBridgeAddress

=item $whiterabbit->os_ver()

clean up os_version string

=item $whiterabbit->i_description()

siemens returns a description including firmware, switch serial, etc
clean it up. Try to use anything past VLAN or Port. And if this fails 
past the last comma

=item $whiterabbit->lldp_ip()

simatic does not implement lldpRemManAddrIfSubtype
but remote system names are available
try to resolve them via DNS and use that

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over 4

=item $whiterabbit->lldp_ip()

Returns reference to hash of ports to remote ips.

simatic does not implement lldpRemManAddrIfSubtype
but remote system names are available
try to resolve them via DNS and use that.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"TABLE METHODS"> for details.

=cut

# vim: filetype=perl ts=4 sw=4 sta et sts=4 ai
