# SNMP::Info::Layer3::PaloAlto
#
# Copyright (c) 2014-2016 Max Kosmach
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

package SNMP::Info::Layer3::PaloAlto;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::PaloAlto::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::PaloAlto::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.70';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'PAN-COMMON-MIB'   => 'panSysSwVersion',
    'PAN-PRODUCTS-MIB' => 'panProductsMibsModule',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'mac'        => 'ifPhysAddress.1',
    # Oids from PAN-COMMON-MIB.
    'os_ver'     => 'panSysSwVersion',
    'serial1'    => 'panSysSerialNumber',
    'pa_model'   => 'panChassisType',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
);

sub vendor {
    return 'palo alto networks';
}

sub model {
    my $pa = shift;
    my $model = $pa->pa_model;
    $model =~ s/^pan//;
    return $model;
}

sub os {
    return 'PAN-OS';
}

sub layers {
    return '01001100';
}

# TODO:
# support fan and temp sensors from ENTITY-SENSOR-MIB
# test with other Palo Alto devices

1;
__END__

=head1 NAME

SNMP::Info::Layer3::PaloAlto - SNMP Interface to Palo Alto devices

=head1 AUTHORS

Max Kosmach

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $pa = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $pa->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Palo Alto devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<PAN-COMMON-MIB>

=item F<PAN-PRODUCTS-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $pa->vendor()

Returns C<'palo alto networks'>.

=item $pa->os()

Returns C<'PAN-OS'>.

=item $pa->model()

Returns the value of C<panChassisType.0>.

=item $pa->os_ver()

Returns the value of C<panSysSwVersion.0>.

=item $pa->serial()

Returns the value of C<panSysSerialNumber.0>.

=back

=head2 Overrides

=over

=item $pa->layers()

Returns 01001100. Palo Alto doesn't report layers, modified to reflect
Layer 3,4,7 functionality.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=cut
