# SNMP::Info::Layer3::Lantronix
# $Id$
#
# Copyright (c) 2012 J R Binks
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

package SNMP::Info::Layer3::Lantronix;

use strict;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Lantronix::ISA = qw/
    SNMP::Info::Layer3
    Exporter
    /;
@SNMP::Info::Layer3::Lantronix::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE/;

$VERSION = '3.15';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'LANTRONIX-MIB'     => 'products',
    'LANTRONIX-SLC-MIB' => 'slcNetwork',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'slc_os_ver'       => 'slcSystemFWRev',
    'slc_serial'       => 'slcSystemSerialNo',
    'slc_model'        => 'slcSystemModel',
    'slc_psu_a_status' => 'slcDevPowerSupplyA',
    'slc_psu_b_status' => 'slcDevPowerSupplyB',
);

%FUNCS = ( %SNMP::Info::Layer3::FUNCS, );

%MUNGE = ( %SNMP::Info::Layer3::MUNGE, );

# General notes:
#
# Products like the EDS have very minimal MIB support for the basics.
# Much information has to be derived from sysDescr string.
#
sub vendor {
    return 'lantronix';
}

sub os {
    my $device = shift;
    my $descr = $device->description() || '';
    my $os;

    # On EDS, it is called the "Evolution OS"
    # Not sure what, if any, name it has a name on other products
    $os = 'EvolutionOS' if ( $descr =~ m/Lantronix EDS\w+ V([\d\.R]+)/ );

    return 'LantronixOS';
}

sub os_ver {
    my $device = shift;
    my $descr = $device->description() || '';
    my $slc_os_ver = $device->slc_os_ver;
    my $os_ver;

    return $slc_os_ver if defined $slc_os_ver;

    return unless defined $descr;

    # EDS: "Lantronix EDS16PR V4.0.0.0R15 (1307.....X)"
    $os_ver = $1 if ( $descr =~ m/Lantronix EDS\w+ V([\d\.R]+)/ );

    return $os_ver;
}

sub serial {
    my $device = shift;
    my $descr = $device->description() || '';
    my $slc_serial = $device->slc_serial;
    my $serial;

    return $slc_serial if defined $slc_serial;

    return unless defined $descr;

    # EDS: "Lantronix EDS16PR V4.0.0.0R15 (1307.....X)"
    $serial = $1 if ( $descr =~ m/Lantronix EDS\w+ V[\d\.R]+ \((\w+)\)/ );

    return $serial;
}       

sub model {
    my $device = shift;
    my $descr = $device->description() || '';
    my $slc_model = $device->slc_model;
    my $model;

    return $slc_model if defined $slc_model;

    return unless defined $descr;

    # EDS: "Lantronix EDS16PR V4.0.0.0R15 (1307.....X)"
    $model = $1 if ( $descr =~ m/Lantronix (EDS\w+)/ );

    return $model;
}

sub ps1_status {
    my $device = shift;
    my $slc_psu_a_status = $device->slc_psu_a_status;

    return $slc_psu_a_status if defined $slc_psu_a_status;

    return;
}

sub ps2_status {
    my $device = shift;
    my $slc_psu_b_status = $device->slc_psu_b_status;

    return $slc_psu_b_status if defined $slc_psu_b_status;

    return;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Lantronix - SNMP Interface to Lantronix devices such as terminal servers

=head1 AUTHOR

J R Binks

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $device = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'mydevice',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $device->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Lantronix devices such as terminal servers.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<LANTRONIX-MIB>

=item F<LANTRONIX-SLC-MIB>

=back

=head2 Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP.

=over

=item $device->vendor()

Returns 'lantronix'.

=item $device->os()

Returns 'EvolutionOS' for EDS devices.

=item $device->os_ver()

Returns the software version.

=item $device->model()

Returns the model.

=item $device->serial()

Returns the serial number.

=item $device->ps1_status()

Power supply 1 status

=item $device->ps2_status()

Power supply 2 status

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=over

=back

=head2 Overrides

=over

=item $device->i_ignore()

Returns reference to hash.  Increments value of IID if port is to be ignored.

=back

=head2 Lantronix specific items

None at present.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
