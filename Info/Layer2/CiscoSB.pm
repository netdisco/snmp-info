# SNMP::Info::Layer2::CiscoSB
# $Id$
#
# Copyright (c) 2013 Nic Bernstein
#
# Copyright (c) 2008-2009 Max Baker changes from version 0.8 and beyond.
#
# Copyright (c) 2003 Regents of the University of California
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

package SNMP::Info::Layer2::CiscoSB;

use strict;
use Exporter;
use SNMP::Info::Layer2;
use SNMP::Info::Entity;
use SNMP::Info::EtherLike;
use SNMP::Info::CiscoStats;
use SNMP::Info::CiscoConfig;
use SNMP::Info::CDP;

@SNMP::Info::Layer2::CiscoSB::ISA
    = qw/SNMP::Info::Layer2 SNMP::Info::Entity SNMP::Info::EtherLike
    SNMP::Info::CiscoStats SNMP::Info::CiscoConfig SNMP::Info::CDP Exporter/;
@SNMP::Info::Layer2::CiscoSB::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE/;

$VERSION = '3.22';

# This will be filled in with the device's index into the EntPhysicalEntry
# table by the serial() function.
our $index = undef;

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
    %SNMP::Info::Entity::GLOBALS,
    %SNMP::Info::EtherLike::GLOBALS,
    %SNMP::Info::CiscoStats::GLOBALS,
    %SNMP::Info::CiscoConfig::GLOBALS,
    %SNMP::Info::CDP::GLOBALS,
    'descr'  => 'sysDescr'
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
    %SNMP::Info::Entity::FUNCS,
    %SNMP::Info::EtherLike::FUNCS,
    %SNMP::Info::CiscoStats::FUNCS,
    %SNMP::Info::CiscoConfig::FUNCS,
    %SNMP::Info::CDP::FUNCS,
);

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
    %SNMP::Info::Entity::MIBS,
    %SNMP::Info::EtherLike::MIBS,
    %SNMP::Info::CiscoStats::MIBS,
    %SNMP::Info::CiscoConfig::MIBS,
    %SNMP::Info::CDP::MIBS,
);

%MUNGE = (
    %SNMP::Info::Layer2::MUNGE,
    %SNMP::Info::Entity::MUNGE,
    %SNMP::Info::EtherLike::MUNGE,
    %SNMP::Info::CiscoStats::MUNGE,
    %SNMP::Info::CiscoConfig::MUNGE,
    %SNMP::Info::CDP::MUNGE,
);


sub vendor {
    return 'cisco';
}

# Walk the entPhysicalSerialNum table and return the first serial found
sub serial {
    my $ciscosb  = shift;
    my $e_serial = $ciscosb->e_serial();

    # Find entity table entry for this unit
    foreach my $e ( sort keys %$e_serial ) {
        if (defined $e_serial->{$e} and $e_serial->{$e} !~ /^\s*$/) {
            return $e_serial->{$e};
        }
    }
}

sub os_ver {
    my $ciscosb = shift;
    my $os_ver  = $ciscosb->e_swver();

    return $os_ver->{$index} if defined $index;
}
  
# Grab e_model from Entity and tag on e_hwver
sub model {
    my $ciscosb = shift;
    my $e_model   = $ciscosb->e_model();
    my $e_hwver = $ciscosb->e_hwver();

    if (defined ($index)) {
        my $model = "$e_model->{$index} $e_hwver->{$index}";
        return $model;
    }
    return $ciscosb->description();
}

# ifDescr is the same for all interfaces in a class, but the ifName is
# unique, so let's use that for port name.
sub interfaces {
    my $ciscosb = shift;
    my $partial = shift;

    my $interfaces = $ciscosb->i_name($partial);

    return $interfaces;
}


1;
__END__

=head1 NAME

SNMP::Info::Layer2::CiscoSB - SNMP Interface to Cisco Small Business series

=head1 AUTHOR

Nic Bernstein (shamelessly stolen from Max Baker's Aironet code)

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $ciscosb = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $ciscosb->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides interface to SNMP Data available on Cisco Small Business (nee LinkSys)
managed switches. [i.e. those matching enterprises(1).cisco(9).otherEnterprises(6).ciscosb(1)]

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=item SNMP::Info::Entity

=item SNMP::Info::EtherLike

=item SNMP::Info::CiscoStats

=item SNMP::Info::CiscoConfig

=back

=head2 Required MIBs

=over

=item Inherited Classes

MIBs required by the inherited classes listed above.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $ciscosb->vendor()

Returns 'cisco'

=item $ciscosb->os_ver()

Returns software version (C<entPhysicalSoftwareRev>)

=item $ciscosb->serial()

Returns serial number of unit (C<entPhysicalSerialNum>)

=item $ciscosb->model()

Returns model and hardware revision of unit
(C<entPhysicalModelName+entPhysicalHardwareRev>)

=back

=head2 Globals imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::Entity

See documentation in L<SNMP::Info::Entity/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::EtherLike

See documentation in L<SNMP::Info::EtherLike/"GLOBALS"> for details.

=head1 TABLE METHODS

=head2 Overrides

=over

=item $ciscosb->interfaces()

Uses the i_name() field.

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::Entity

See documentation in L<SNMP::Info::Entity/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::EtherLike

See documentation in L<SNMP::Info::EtherLike/"TABLE METHODS"> for details.

=cut
