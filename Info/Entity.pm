# SNMP::Info::Entity
# Max Baker <max@warped.org>
#
# Copyright (c) 2004 Max Baker changes from version 0.8 and beyond.
#
# Copyright (c) 2003 Regents of the University of California
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#     * Neither the name of the University of California, Santa Cruz nor the 
#       names of its contributors may be used to endorse or promote products 
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Entity;
$VERSION = 0.8;
# $Id$

use strict;

use Exporter;
use SNMP::Info;

use vars qw/$VERSION $DEBUG %MIBS %FUNCS %GLOBALS %MUNGE $INIT/;
@SNMP::Info::Entity::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::Entity::EXPORT_OK = qw//;

$INIT    = 0;
%MIBS    = ('ENTITY-MIB' => 'entPhysicalSerialNum');

%GLOBALS = (
           );

%FUNCS   = (
            'e_class'   => 'entPhysicalClass',
            'e_descr'   => 'entPhysicalDescr',
            'e_fwver'   => 'entPhysicalFirmwareRev',
            'e_hwver'   => 'entPhysicalHardwareRev',
            'e_map'     => 'entAliasMappingIdentifier',
            'e_model'   => 'entPhysicalModelName',
            'e_name'    => 'entPhysicalName',
            'e_parent'  => 'entPhysicalContainedIn',
            'e_serial'  => 'entPhysicalSerialNum',
            'e_swver'   => 'entPhysicalSoftwareRev',
            'e_type'    => 'entPhysicalVendorType',
           );

%MUNGE   = (
           );

sub e_port {
    my $entity = shift;
    my $e_map  = $entity->e_map();

    my %e_port;

    foreach my $e_id (keys %$e_map) {
        my $id = $e_id;
        $id =~ s/\.0$//;

        my $iid = $e_map->{$e_id};
        $iid =~ s/.*\.//;

        $e_port{$id} = $iid;
    }

    return \%e_port;
}
1;

=head1 NAME

SNMP::Info::Entity - Perl5 Interface to SNMP data stored in ENTITY-MIB.

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $entity = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $entity->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

ENTITY-MIB is used by some Layer 2 devices like HP Switches and Aironet Access Points

Create or use a device subclass that inherit this class.  Do not use directly.

For debugging purposes you can call this class directly as you would SNMP::Info

 my $entity = new SNMP::Info::Entity (...);

=head2 Inherited Classes

none.

=head2 Required MIBs

=over

=item ENTITY-MIB

=back

MIBs can be found at ftp://ftp.cisco.com/pub/mibs/v2/v2.tar.gz

=head1 GLOBALS

none.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Entity Table

=over

=item $entity->e_class()

(C<entPhysicalClass>)

=item $entity->e_descr()

(C<entPhysicalClass>)

=item $entity->e_fwver()

(C<entPhysicalFirmwareRev>)

=item $entity->e_hwver()

(C<entPhysicalHardwareRev>)

=item $entity->e_map()

(C<entAliasMappingIdentifier>)

=item $entity->e_model()

(C<entPhysicalModelName>)

=item $entity->e_name()

(C<entPhysicalName>)

=item $entity->e_parent()

(C<entPhysicalContainedIn>)

=item $entity->e_port()

Maps EntityTable entries to the Interface Table (IfTable) using
$entity->e_map()

=item $entity->e_serial()

(C<entPhysicalSerialNum>)

=item $entity->e_swver()

(C<entPhysicalSoftwareRev>)

=item $entity->e_type()

(C<entPhysicalVendorType>)

=back

=cut
