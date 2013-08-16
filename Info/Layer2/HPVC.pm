# SNMP::Info::Layer2::HPVC - SNMP Interface to HP VirtualConnect Switches
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

package SNMP::Info::Layer2::HPVC;

use strict;
use Exporter;
use SNMP::Info::Layer2;

@SNMP::Info::Layer2::HPVC::ISA
    = qw/SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::HPVC::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.04_001';

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
    'HPVC-MIB'       => 'vcDomainName',
    'CPQSINFO-MIB'   => 'cpqSiSysSerialNum',
    'HPVCMODULE-MIB' => 'vcModuleDomainName',
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
    'serial1'      => 'cpqSiSysSerialNum.0',
    'os_ver'       => 'cpqHoSWRunningVersion.1',
    'os_bin'       => 'cpqHoFwVerVersion.1',
    'productname'  => 'cpqSiProductName.0',
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
    
);

%MUNGE = (
    # Inherit all the built in munging
    %SNMP::Info::Layer2::MUNGE,
);


# Method Overrides

sub os {
    return 'hpvc';
}

sub vendor {
    return 'hp';
}

sub model {
    my $hp = shift;
    return $hp->productname();
}


1;
__END__

=head1 NAME

SNMP::Info::Layer2::HPVC - SNMP Interface to HP Virtual Connect Switches

=head1 AUTHOR

Jeroen van Ingen

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $hp = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $hp->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a 
HP Virtual Connect Switch via SNMP. 

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

 my $hp = new SNMP::Info::Layer2::HPVC(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

=over

=item F<HPVC-MIB>

=item F<CPQSINFO-MIB>

=item F<HPVCMODULE-MIB>

=back

All required MIBs can be found in the netdisco-mibs package.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $hp->os()

Returns C<'hpvc'>

=item $hp->os_bin()

C<cpqHoFwVerVersion.1>

=item $hp->os_ver()

C<cpqHoSWRunningVersion.1>

=item $hp->serial()

C<cpqSiSysSerialNum.0>

=item $hp->vendor()

hp

=item $hp->model()

C<cpqSiProductName.0>

=back

=head2 Globals imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=head1 MUNGES

=over

=back

=head1 SET METHODS

These are methods that provide SNMP set functionality for overridden methods
or provide a simpler interface to complex set operations.  See
L<SNMP::Info/"SETTING DATA VIA SNMP"> for general information on set
operations. 

=cut
