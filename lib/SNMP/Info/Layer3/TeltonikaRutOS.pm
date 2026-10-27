# SNMP::Info::Layer3::TeltonikaRutOS - SNMP interface to Teltonika RutOS devices
#
# Copyright (c) 2026 by SNMP::Info Developers.
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
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Layer3::TeltonikaRutOS;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3::NetSNMP;

@SNMP::Info::Layer3::TeltonikaRutOS::ISA
    = qw/SNMP::Info::Layer3::NetSNMP Exporter/;
@SNMP::Info::Layer3::TeltonikaRutOS::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.982000';

# Current RutOS devices share this OID layout across router and gateway lines.
# The released 2013 TELTONIKA-MIB_RUT9XX was written for RUT9xx devices and
# assigns .1.1.0, .1.3.0, and .1.6.0 to modemImei, modemManufacturer, and imsi.
# Current RutOS returns serial, product code, and firmware at those same OIDs,
# so use numeric leaves to avoid the legacy MIB's misleading names.
%MIBS = (
    %SNMP::Info::Layer3::NetSNMP::MIBS,
);

%GLOBALS = (
    %SNMP::Info::Layer3::NetSNMP::GLOBALS,
    'serial1'             => '.1.3.6.1.4.1.48690.1.1.0',
    'teltonika_model'     => '.1.3.6.1.4.1.48690.1.3.0',
    'teltonika_firmware'  => '.1.3.6.1.4.1.48690.1.6.0',
);

%FUNCS = (
    %SNMP::Info::Layer3::NetSNMP::FUNCS,
    # TELTONIKA-MIB portTable pName on TSW switches. That MIB shares its
    # module name with the RUT9xx one in netdisco-mibs, so read it by OID.
    'teltonika_port_name' => '.1.3.6.1.4.1.48690.10.2.1.2',
);
%MUNGE = (%SNMP::Info::Layer3::NetSNMP::MUNGE);

sub vendor { return 'teltonika'; }

sub os { return 'rutos'; }

sub model {
    my $dev = shift;
    my $model = $dev->teltonika_model();
    return $model if defined $model and $model =~ /\S/;
    return $dev->SUPER::model();
}

sub os_ver {
    my $dev = shift;
    my $version = $dev->teltonika_firmware();
    return $version if defined $version and $version =~ /\S/;
    return $dev->SUPER::os_ver();
}

sub serial {
    my $dev = shift;
    my $serial = $dev->serial1();
    return $serial if defined $serial and $serial =~ /\S/;
    return $dev->SUPER::serial();
}

# TSW switches serve dot1dTpFdbPort but no dot1dBasePortIfIndex. Their port
# table rows are numbered as the bridge numbers its ports, so join each row
# to the interface whose ifDescr carries the same name.
sub bp_index {
    my $dev = shift;
    my $standard = $dev->SUPER::bp_index();
    return $standard if ref {} eq ref $standard and scalar keys %$standard;

    my $port_names = $dev->teltonika_port_name() || {};
    my $i_descr    = $dev->i_description()       || {};
    my %ifindex_by_name;
    foreach my $ifindex ( keys %$i_descr ) {
        my $name = $i_descr->{$ifindex};
        next unless defined $name;
        push @{ $ifindex_by_name{$name} }, $ifindex;
    }

    my %rows_named;
    foreach my $name ( values %$port_names ) {
        next unless defined $name;
        $rows_named{$name}++;
    }

    my %bp_index;
    foreach my $bridge_port ( keys %$port_names ) {
        my $name = $port_names->{$bridge_port};
        next unless defined $name and $rows_named{$name} == 1;
        my $matches = $ifindex_by_name{$name};
        next unless $matches and @$matches == 1;
        $bp_index{$bridge_port} = $matches->[0];
    }
    return \%bp_index;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::TeltonikaRutOS - SNMP interface to Teltonika RutOS devices

=head1 AUTHOR

SNMP::Info Developers

=head1 SYNOPSIS

 use SNMP::Info;

 my $info = SNMP::Info->new(
     AutoSpecify => 1,
     DestHost    => 'mydevice',
     Community   => 'public',
     Version     => 2,
 );

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3::NetSNMP

=back

=head2 Required MIBs

=over

=item F<UCD-SNMP-MIB>

=item F<NET-SNMP-TC>

=item F<HOST-RESOURCES-MIB>

=item Inherited MIBs

See L<SNMP::Info::Layer3::NetSNMP/Required MIBs> for its inherited
requirements.

=back

=head1 DESCRIPTION

Subclass for current Teltonika RutOS devices that expose the shared product,
serial number, and firmware OIDs under C<.1.3.6.1.4.1.48690.1>. Detection uses
the product code at C<.1.3.6.1.4.1.48690.1.3.0>, including when the device
reports Net-SNMP as its C<sysObjectID>.

=head2 GLOBALS

=over

=item $info->vendor()

Returns C<'teltonika'>.

=item $info->os()

Returns C<'rutos'>.

=item $info->model()

Returns the Teltonika product code.

=item $info->os_ver()

Returns the RutOS firmware version.

=item $info->serial()

Returns the device serial number, falling back to the inherited Net-SNMP
behavior when the Teltonika serial object is empty.

=back

=head1 TABLE METHODS

Interface filtering and system uptime are inherited from
L<SNMP::Info::Layer3::NetSNMP>. Other table methods are inherited from
L<SNMP::Info::Layer3>.

=head2 Overrides

=over

=item $info->bp_index()

Returns reference to hash. Key: bridge port, Value: ifIndex. Uses
C<dot1dBasePortIfIndex> where the device serves it. TSW switches do not,
so each Teltonika port table row is matched to the interface whose
C<ifDescr> equals its name; a name that matches no interface, or several,
is left out.

=back

=head2 Teltonika Port Table (C<portTable>)

=over

=item $info->teltonika_port_name()

Returns reference to hash. Key: port number, Value: port name.

(C<pName>, C<.1.3.6.1.4.1.48690.10.2.1.2>)

=back

=cut
