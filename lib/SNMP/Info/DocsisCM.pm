# SNMP::Info::DocsisCM - SNMP Interface to DOCSIS Cable Modems
#
# Copyright (c) 2019 by The Netdisco Developer Team.
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

package SNMP::Info::DocsisCM;

use strict;
use warnings;
use Exporter;

use SNMP::Info::Layer2;

@SNMP::Info::DocsisCM::ISA       = qw/SNMP::Info::Layer2 Exporter/;
@SNMP::Info::DocsisCM::EXPORT_OK = qw//;

our ($VERSION, %MIBS, %FUNCS, %GLOBALS, %MUNGE);

$VERSION = '3.70';
 
%MIBS = (
    %SNMP::Info::Layer2::MIBS
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS
);

%FUNCS  = (
    %SNMP::Info::Layer2::FUNCS
);

%MUNGE = (
    %SNMP::Info::Layer2::MUNGE
);

sub vendor {
    my $cm = shift;
    my $descr = $cm->description();
    return $1 if $descr =~ /VENDOR: (.*?);/;
}

sub model {
    my $cm = shift;
    my $descr = $cm->description();
    return $1 if $descr =~ /MODEL: (.*?)>>/;
}

sub os {
    return "CM";
}

sub os_ver {
    my $cm = shift;
    my $descr = $cm->description();
    return $1 if $descr =~ /SW_REV: (.*?);/;
}

1;
__END__

=head1 NAME

SNMP::Info::DocsisCM - SNMP Interface for DOCSIS Cable Modems

=head1 DESCRIPTION
SNMP::Info::DocsisCM is a subclass of SNMP::Info that provides info
about a given cable modem. Extracts data from the sysDescr, which is 
mandated in the DOCSIS specification to match
"HW_REV: <value>; VENDOR: <value>; BOOTR: <value>; SW_REV: <value>; MODEL: <value>"

=head2 Inherited Classes

None.

=head2 Required MIBs

None.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $cm->vendor()

Returns the vendor of the cable modem.

=item $cm->model()

Returns the model of the cable modem.

=item $cm->os()

Returns 'cm', as the actual os is vendor and model dependent.

=item $cm->os_ver()

Returns the version of the software, extracted from the SW_REV field.

=back

