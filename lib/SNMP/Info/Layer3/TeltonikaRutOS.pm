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

$VERSION = '3.985001';

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
    # TELTONIKA-MIB pVlanTable on TSW switches: pVlanName, pVlanVID,
    # pVlanPortsUntag, pVlanPortsTag. The port lists are strings of
    # pName tokens, "port1:u port2:u", or "None".
    'teltonika_vlan_name'     => '.1.3.6.1.4.1.48690.8.2.1.2',
    'teltonika_vlan_id'       => '.1.3.6.1.4.1.48690.8.2.1.3',
    'teltonika_vlan_untagged' => '.1.3.6.1.4.1.48690.8.2.1.4',
    'teltonika_vlan_tagged'   => '.1.3.6.1.4.1.48690.8.2.1.5',
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

# Interfaces keyed by ifDescr, leaving out a name two interfaces share.
sub _teltonika_ifindex_by_name {
    my $dev     = shift;
    my $i_descr = $dev->i_description() || {};

    my %ifindexes_by_name;
    foreach my $ifindex ( keys %$i_descr ) {
        my $name = $i_descr->{$ifindex};
        next unless defined $name;
        push @{ $ifindexes_by_name{$name} }, $ifindex;
    }
    return {
        map  { $_ => $ifindexes_by_name{$_}[0] }
        grep { @{ $ifindexes_by_name{$_} } == 1 } keys %ifindexes_by_name
    };
}

# TSW switches serve dot1dTpFdbPort but no dot1dBasePortIfIndex. Their port
# table rows are numbered as the bridge numbers its ports, so join each row
# to the interface whose ifDescr carries the same name.
sub bp_index {
    my $dev = shift;
    my $standard = $dev->SUPER::bp_index();
    return $standard if ref {} eq ref $standard and scalar keys %$standard;

    my $port_names      = $dev->teltonika_port_name() || {};
    my $ifindex_by_name = $dev->_teltonika_ifindex_by_name();

    my %rows_named;
    foreach my $name ( values %$port_names ) {
        next unless defined $name;
        $rows_named{$name}++;
    }

    my %bp_index;
    foreach my $bridge_port ( keys %$port_names ) {
        my $name = $port_names->{$bridge_port};
        next unless defined $name and $rows_named{$name} == 1;
        my $ifindex = $ifindex_by_name->{$name};
        next unless defined $ifindex;
        $bp_index{$bridge_port} = $ifindex;
    }
    return \%bp_index;
}

# TSW switches serve no Q-BRIDGE-MIB VLAN tables, only pVlanTable, so the
# VLAN methods read it first and fall back to Q-BRIDGE when it is empty.
# RUTX routers serve a pVlanTable of their own under the same OIDs, with
# the port list where TSW has the VLAN ID, so a table whose third column
# is not all VLAN IDs is not read.
sub _teltonika_vlan_ids {
    my $dev = shift;
    my $vlan_ids = $dev->teltonika_vlan_id() || {};
    return unless scalar keys %$vlan_ids;
    foreach my $vlan ( values %$vlan_ids ) {
        return unless defined $vlan and $vlan =~ /^\d+$/;
        return unless $vlan >= 1 and $vlan <= 4094;
    }
    return $vlan_ids;
}

sub v_index {
    my $dev = shift;
    return $dev->_teltonika_vlan_ids() || $dev->SUPER::v_index(@_);
}

sub v_name {
    my $dev = shift;
    return $dev->SUPER::v_name(@_) unless $dev->_teltonika_vlan_ids();
    return $dev->teltonika_vlan_name() || {};
}

sub i_vlan {
    my $dev = shift;
    my $untagged = $dev->_teltonika_untagged()
        or return $dev->SUPER::i_vlan(@_);

    my %i_vlan;
    foreach my $ifindex ( keys %$untagged ) {
        my @vlans = @{ $untagged->{$ifindex} };
        $i_vlan{$ifindex} = $vlans[0] if @vlans == 1;
    }
    return \%i_vlan;
}

sub i_vlan_membership {
    my $dev = shift;
    my $untagged = $dev->_teltonika_untagged()
        or return $dev->SUPER::i_vlan_membership(@_);
    my $tagged = $dev->_teltonika_vlan_ports( 'teltonika_vlan_tagged', 't' );

    my %members;
    foreach my $ports ( $untagged, $tagged ) {
        foreach my $ifindex ( keys %$ports ) {
            $members{$ifindex}{$_} = 1 for @{ $ports->{$ifindex} };
        }
    }
    return {
        map { $_ => [ sort { $a <=> $b } keys %{ $members{$_} } ] }
            keys %members
    };
}

sub i_vlan_membership_untagged {
    my $dev = shift;
    return $dev->_teltonika_untagged()
        || $dev->SUPER::i_vlan_membership_untagged(@_);
}

sub _teltonika_untagged {
    my $dev = shift;
    return $dev->_teltonika_vlan_ports( 'teltonika_vlan_untagged', 'u' );
}

# ifIndex => [VLAN IDs] from one pVlanTable port list column, keeping the
# tokens that carry that column's suffix and name exactly one interface.
# Undef when the device serves no TSW pVlanTable rows.
sub _teltonika_vlan_ports {
    my ( $dev, $column, $suffix ) = @_;
    my $vlan_ids = $dev->_teltonika_vlan_ids() or return;

    my $port_lists      = $dev->$column() || {};
    my $ifindex_by_name = $dev->_teltonika_ifindex_by_name();

    my %vlans_by_ifindex;
    foreach my $row ( keys %$port_lists ) {
        my $vlan = $vlan_ids->{$row};
        next unless defined $vlan and defined $port_lists->{$row};
        foreach my $token ( split ' ', $port_lists->{$row} ) {
            next unless $token =~ /^(\S+):\Q$suffix\E$/;
            my $ifindex = $ifindex_by_name->{$1};
            push @{ $vlans_by_ifindex{$ifindex} }, $vlan if defined $ifindex;
        }
    }
    foreach my $vlans ( values %vlans_by_ifindex ) {
        @$vlans = sort { $a <=> $b } @$vlans;
    }
    return \%vlans_by_ifindex;
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

=item $info->v_index()

Returns reference to hash. Key: C<pVlanTable> row, Value: VLAN ID
(C<pVlanVID>). TSW switches serve no F<Q-BRIDGE-MIB> VLAN tables; where
C<pVlanTable> has no rows, the inherited method is used. RUTX routers
serve a different C<pVlanTable> at the same OIDs; a table whose
C<pVlanVID> column holds anything but VLAN IDs is not read, and the
F<Q-BRIDGE-MIB> methods are used instead, here and in the methods below.

=item $info->v_name()

Returns reference to hash. Key: C<pVlanTable> row, Value: VLAN name
(C<pVlanName>). Where C<pVlanTable> has no rows, C<dot1qVlanStaticName> is
used.

=item $info->i_vlan()

Returns reference to hash. Key: ifIndex, Value: the VLAN ID the port is
untagged in (C<pVlanPortsUntag>). A port untagged in more than one VLAN
has no single native VLAN and is left out. Where C<pVlanTable> has no
rows, C<dot1qPvid> is used.

=item $info->i_vlan_membership()

Returns reference to hash of arrays. Key: ifIndex, Value: VLAN IDs the
port is tagged or untagged in (C<pVlanPortsTag>, C<pVlanPortsUntag>).
Ports are matched by name to the interface whose C<ifDescr> equals it; a
name that matches no interface, or several, is left out. Where
C<pVlanTable> has no rows, the F<Q-BRIDGE-MIB> egress ports are used.

=item $info->i_vlan_membership_untagged()

Returns reference to hash of arrays. Key: ifIndex, Value: VLAN IDs the
port is untagged in (C<pVlanPortsUntag>). Where C<pVlanTable> has no rows,
the F<Q-BRIDGE-MIB> untagged ports are used.

=back

=head2 Teltonika Port Table (C<portTable>)

=over

=item $info->teltonika_port_name()

Returns reference to hash. Key: port number, Value: port name.

(C<pName>, C<.1.3.6.1.4.1.48690.10.2.1.2>)

=back

=head2 Teltonika VLAN Table (C<pVlanTable>)

=over

=item $info->teltonika_vlan_name()

Returns reference to hash. Key: VLAN row, Value: VLAN name.

(C<pVlanName>, C<.1.3.6.1.4.1.48690.8.2.1.2>)

=item $info->teltonika_vlan_id()

Returns reference to hash. Key: VLAN row, Value: VLAN ID.

(C<pVlanVID>, C<.1.3.6.1.4.1.48690.8.2.1.3>)

=item $info->teltonika_vlan_untagged()

Returns reference to hash. Key: VLAN row, Value: the untagged ports, as
port names with a C<:u> suffix separated by spaces, or C<None>.

(C<pVlanPortsUntag>, C<.1.3.6.1.4.1.48690.8.2.1.4>)

=item $info->teltonika_vlan_tagged()

Returns reference to hash. Key: VLAN row, Value: the tagged ports, as
port names with a C<:t> suffix separated by spaces, or C<None>.

(C<pVlanPortsTag>, C<.1.3.6.1.4.1.48690.8.2.1.5>)

=back

=cut
