# SNMP::Info::Entity
# Max Baker <max@warped.org>
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
$VERSION = 0.4;
# $Id$

use strict;

use Exporter;
use SNMP::Info;

use vars qw/$VERSION $DEBUG %MIBS %FUNCS %GLOBALS %MUNGE $INIT/;
@SNMP::Info::Entity::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::Entity::EXPORT_OK = qw//;

=head1 NAME

SNMP::Info::Entity - Perl5 Interface to ENTITY-MIB 

=head1 DESCRIPTION

ENTITY-MIB is used by Layer 2 devices like HP Switches and Aironet Access Points

Inherits all methods from SNMP::Info

Use this module from another device subclass, not directly.

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

See SNMP::Info

=cut
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

=head2 Entity Table

=over

=item $hp->e_class()

(C<entPhysicalClass>)

=item $hp->e_descr()

(C<entPhysicalClass>)

=item $hp->e_fwver()

(C<entPhysicalFirmwareRev>)

=item $hp->e_hwver()

(C<entPhysicalHardwareRev>)

=item $hp->e_map()

(C<entAliasMappingIdentifier>)

=item $hp->e_model()

(C<entPhysicalModelName>)

=item $hp->e_name()

(C<entPhysicalName>)

=item $hp->e_parent()

(C<entPhysicalContainedIn>)

=item $hp->e_port()

Maps EntityTable entries to the Interface Table (IfTable) using
$hp->e_map()

=cut
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

=item $hp->e_serial()

(C<entPhysicalSerialNum>)

=item $hp->e_swver()

(C<entPhysicalSoftwareRev>)

=item $hp->e_type()

(C<entPhysicalVendorType>)

=back

=cut

1;
