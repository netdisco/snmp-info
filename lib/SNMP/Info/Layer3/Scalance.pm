# SNMP::Info::Layer3::Scalance - SNMP Interface to Siemens Scalance
#
# Copyright (c) 2019 Christoph Handel GSI Helmholtzzentrum fuer
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

package SNMP::Info::Layer3::Scalance;

use strict;
use warnings;
use Exporter;
use Socket;
use SNMP::Info::Layer3;
use SNMP::Info::MAU;

@SNMP::Info::Layer3::Scalance::ISA = qw/
    SNMP::Info::Layer3
    SNMP::Info::MAU
    Exporter
/;
@SNMP::Info::Layer3::Scalance::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %PORTSTAT, %MODEL_MAP, %MUNGE);

$VERSION = '3.71';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::MAU::MIBS,
    'SN-MSPS-SCX-MIB' => 'snMsps',
    'AUTOMATION-SYSTEM-MIB' => 'automationManufacturerId',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::MAU::GLOBALS,
    'serial1'      => 'automationSerialNumber.0',
    'ps1_status' => 'snMspsPowerSupply1State.0',
    'ps2_status' => 'snMspsPowerSupply2State.0',
    'os_ver'   => 'automationSwRevision.0',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::MAU::FUNCS,
);

%MUNGE = (
    # Inherit all the built in munging
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::MAU::MUNGE,
);

sub layers {
    # at least x500 reports value 72, which is layer 4+7
    # but it sure is a bridge and can do 2 and 3
    return '00000111';
}

sub os {
    return 'scalance';
}

sub vendor {
    return 'siemens';
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

sub mac {
    # use dot1dBaseBridgeAddress
    my $scalance = shift;
    return $scalance->b_mac();
}

sub os_ver {
    # clean up os_ver string
    my $scalance = shift;
    my $result = $scalance->SUPER::os_ver();
    $result =~ s/^V//;
    return $result;
}

sub i_description {
    # munge interface descriptions, from
    #
    # Siemens, SIMATIC NET, SCALANCE XR524-8C 2PS, 6GK5 524-8GS00-4AR2, 
    #    HW: Version 1, FW: Version V06.02.02, SERIAL, Ethernet Port, R0/S0/X1 P16
    #
    # to
    #
    # R0/S0/X1 P16

    my $scalance = shift;

    my $orig = $scalance->SUPER::i_description();
    my %result;
    foreach my $iid ( keys %$orig ) {
        my $descr = $orig->{$iid};
        my $short;
        ($short) = $descr =~ /.*(?:Port, |VLAN, )(.*)$/;
        if ( ! $short ) {
            # splitting at VLAN/PORT failed, just the part after the last comma
            ($short) = $descr =~ /.*, (.*)$/;
        }
        $result{$iid} = $short;
    }
    return \%result;
}

sub lldp_ip {
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

SNMP::Info::Layer3::Scalance - SNMP Interface to Siemens Scalance Switches

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

Tested only with scalance xr524

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::MAU

=back

=head2 Required MIBs

=over

=item F<AUTOMATION-SMI>

=item F<AUTOMATION-SYSTEM-MIB>

=item F<AUTOMATION-TC>

=item F<SIEMENS-SMI>

=item F<SN-MSPS-SCX-MIB>

=back

L<https://support.industry.siemens.com/cs/document/22015045/private-mibs%3A-scalance-x-scalance-w-and-snmp-opc-profile?dti=0&lc=en-DE>

L<https://support.industry.siemens.com/cs/document/67637278/automationmib-now-available-for-download-in-version-v02-00-00-02-?dti=0&lc=en-TN>


=head1 Change Log

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $scalance->layers()

Overwrite snmp value, we support 1-3

=item $scalance->os()

Returns scalance

=item $scalance->vendor()

Returns siemens

=item $scalance->model()

extract a meaningful name from description

=item $scalance->mac()

use the dot1dBaseBridgeAddress

=item $scalance->os_ver()

clean up os_version string

=item $scalance->i_description()

siemens returns a description including firmware, switch serial, etc
clean it up. Try to use anything past VLAN or Port. And if this fails 
past the last comma

=item $scalance->lldp_ip()

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

=item $scalance->lldp_ip()

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
