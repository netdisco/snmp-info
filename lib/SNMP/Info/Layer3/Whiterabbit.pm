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
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::MAU::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,    
    %SNMP::Info::Bridge::GLOBALS,   
    'serial1' => 'wrsVersionSwitchSerialNumber.0', 
    'vendor1' => 'wrsVersionManufacturer.0',
    'os_ver' => 'wrsVersionSwVersion.0',
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
    # but it sure is a bridge and can do 2
    # at some later point it might get 3, so put it in layer3 right from the start
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

SNMP::Info::Layer3::Whiterabbit - SNMP Interface to Whiterabbit Switches

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
Whiterabbit Switch via SNMP.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::MAU

=item SNMP::Info::LLDP

=item SNMP::Info::Bridge


=back

=head2 Required MIBs

=over

=item F<>WR-SWITCH-MIB>

=item F< WRS-PRODUCTS-MIB>

=back

L<https://github.com/GSI-CS-CO/wrs_mibs.git>

=head1 Change Log

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $whiterabbit->layers()

Overwrite snmp value, we support 1-3

=item $whiterabbit->os()

staticly returns whiterabbit

=item $whiterabbit->vendor()

return manufacturer as read from device. e.g. seven solutions, creotech, etc.

=item $whiterabbit->model()

as returned by mib. no meaningful translation

=item $whiterabbit->mac()

use the dot1dBaseBridgeAddress

=item $whiterabbit->os_ver()

including git hash

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::Bridge

See documentation in L<SNMP::Info::Bridge/"TABLE METHODS"> for details.

=cut

# vim: filetype=perl ts=4 sw=4 sta et sts=4 ai
