# SNMP::Info::Layer2::Scalance - SNMP Interface to Siemens Scalance
#
# Copyright (c) 2008-2009 Max Baker changes from version 0.8 and beyond.
#
# Copyright (c) 2002,2003 Regents of the University of California
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

package SNMP::Info::Layer2::Scalance;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer2;
use SNMP::Info::MAU;
use SNMP::Info::LLDP;
use SNMP::Info::Bridge;
use Socket;

@SNMP::Info::Layer2::Scalance::ISA = qw/
    SNMP::Info::Layer2
    SNMP::Info::MAU
    SNMP::Info::Bridge
    SNMP::Info::LLDP
    Exporter
/;
@SNMP::Info::Layer2::Scalance::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %PORTSTAT, %MODEL_MAP, %MUNGE);

$VERSION = '3.68';

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
    %SNMP::Info::MAU::MIBS,
    %SNMP::Info::LLDP::MIBS,
    %SNMP::Info::Bridge::MIBS,
    'SN-MSPS-SCX-MIB' => 'snMsps',
    'AUTOMATION-SYSTEM-MIB' => 'automationManufacturerId',
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
    %SNMP::Info::MAU::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,    
    %SNMP::Info::Bridge::GLOBALS,    
    'serial1'      => 'automationSerialNumber.0',
    'sn_ps1_status' => 'snMspsPowerSupply1State.0',
    'sn_ps2_status' => 'snMspsPowerSupply2State.0',
    'os_version'   => 'automationSwRevision.0',
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
    %SNMP::Info::MAU::FUNCS,
    %SNMP::Info::LLDP::FUNCS,    
    %SNMP::Info::Bridge::FUNCS,    
);

%MUNGE = (
    # Inherit all the built in munging
    %SNMP::Info::Layer2::MUNGE,
    %SNMP::Info::MAU::MUNGE,
    %SNMP::Info::LLDP::MUNGE,
    %SNMP::Info::Bridge::MUNGE,    
);


# Method Overrides
#

# sub layers {
#     # at least x500 reports value 72, which is layer 4+7
#     # but it sure is a bridge and can do 2 and 3
#     #       07654321
#     return '01001110';
# }

sub os {
    return 'scalance';
}

sub os_ver {
    my $scalance = shift;
    my $os_version = $scalance->os_version();
    $os_version =~ s/^V//;
    return $os_version;
}

sub serial {
    my $scalance = shift;
    my $serial = $scalance->serial1();
    return $serial;
}

sub model {
    my $scalance = shift;
    # object id is only the general class (x500, x400, etc)
    # extract something meaningful from the description
    # my $id = $scalance->id();
    my $description = $scalance->description();
    # Siemens, SIMATIC NET, SCALANCE XR524-8C 2PS, 6GK5 524-8GS00-4AR2, HW: Version 1,...
    $description =~ s/.*?(SCALANCE .*?),.*/$1/;
    return $description;
}

sub ps1_status {
    my $scalance = shift;
    return $scalance->sn_ps1_status();
}
sub ps2_status {
    my $scalance = shift;
    return $scalance->sn_ps2_status();
}

sub mac {
    # use dot1dBaseBridgeAddress
    my $scalance = shift;
    return $scalance->b_mac();
}

sub vendor {
    return 'siemens';
}

sub lldp_ip {
    # simatic does not implement lldpRemManAddrIfSubtype
    # but remote system names are available
    # try to resolve them via DNS and use that
    my $scalance = shift;
    my %result;
    my $remotes = $scalance->lldp_rem_sysname();
    foreach my $port ( keys %$remotes) {
	my $ip = gethostbyname($remotes->{$port});
	if ($ip) {
	    $result{$port} = inet_ntoa($ip);
	}
    }
    return \%result
};


1;
__END__

=head1 NAME

SNMP::Info::Layer2::Scalance - SNMP Interface to Siemens Scalance Switches

=head1 AUTHOR

Christoph Handel

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $scalance = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $scalance->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a
Siemens Scalance Switch via SNMP.

Tested only with sclance xr524

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

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

L<https://support.industry.siemens.com/cs/document/22015045/private-mibs%3A-scalance-x-scalance-w-and-snmp-opc-profile?dti=0&lc=en-DE>

L<https://support.industry.siemens.com/cs/document/67637278/automationmib-now-available-for-download-in-version-v02-00-00-02-?dti=0&lc=en-TN>


=head1 Change Log

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $scalance->os()

Returns scalance

=item $scalance->os_ver()

Uses os_version() and cleans it up.

=item $scalance->os_version()

C<automationSwRevision.0>

=item $scalance->serial()

Returns serial number if available through SNMP C<automationSerialNumber.0>


=item $scalance->vendor()

siemens

=item $scalance->ps1_status()

Power supply 1 status

=item $scalance->ps2_status()

Power supply 2 status

=item $scalance->mac()

use the value of C<dot1dBaseBridgeAddress.0>

=back

=head2 Globals imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over 4

=item $scalance->lldp_ip()

Returns reference to hash of ports to remote ips.

simatic does not implement lldpRemManAddrIfSubtype
but remote system names are available
try to resolve them via DNS and use that.

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"TABLE METHODS"> for details.

=cut
