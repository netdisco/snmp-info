# SNMP::Info::Layer3::Juniper
# $Id$
#
# Copyright (c) 2008 Bill Fenner
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

package SNMP::Info::Layer3::Juniper;

use strict;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::LLDP;

@SNMP::Info::Layer3::Juniper::ISA       = qw/SNMP::Info::Layer3 SNMP::Info::LLDP  Exporter/;
@SNMP::Info::Layer3::Juniper::EXPORT_OK = qw//;

use vars qw/$VERSION $DEBUG %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '2.07';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::LLDP::MIBS,
    'JUNIPER-CHASSIS-DEFINES-MIB' => 'jnxChassisDefines',
    'JUNIPER-MIB'                 => 'jnxBoxAnatomy',
    'JUNIPER-VLAN-MIB'            => 'jnxVlanMIBObjects',
);

%GLOBALS = ( %SNMP::Info::Layer3::GLOBALS, 
	     %SNMP::Info::LLDP::GLOBALS,
	     'serial' => 'jnxBoxSerialNo.0', );

%FUNCS = ( %SNMP::Info::Layer3::FUNCS, 
	   %SNMP::Info::LLDP::FUNCS,
	   
	   # JUNIPER-VLAN-MIB::jnxExVlanTable
	   'v_index'    => 'jnxExVlanTag',
	   'v_type'     => 'jnxExVlanType',
	   'v_name'     => 'jnxExVlanName',
	   
	   # JUNIPER-VLAN-MIB::jnxExVlanPortGroupTable
	   'i_trunk'    => 'jnxExVlanPortAccessMode',
);

%MUNGE = ( %SNMP::Info::Layer3::MUNGE, 
	   %SNMP::Info::LLDP::MUNGE,
);

sub vendor {
    return 'juniper';
}

sub os {
    return 'junos';
}

sub os_ver {
    my $juniper = shift;
    my $descr   = $juniper->description();
    return unless defined $descr;

    if ( $descr =~ m/kernel JUNOS (\S+)/ ) {
        return $1;
    }
    return;
}

sub model {
    my $l3 = shift;
    my $id = $l3->id();

    unless ( defined $id ) {
        print
            " SNMP::Info::Layer3::Juniper::model() - Device does not support sysObjectID\n"
            if $l3->debug();
        return;
    }

    my $model = &SNMP::translateObj($id);

    return $id unless defined $model;

    $model =~ s/^jnxProductName//i;
    return $model;
}

# Override the fancy Layer3.pm serial function
sub serial {
    my $juniper = shift;
    return $juniper->orig_serial();
}

# 'i_trunk'    => 'jnxExVlanPortAccessMode',
sub i_trunk {
    my $juniper = shift;
    my $partial = shift;

    my $access  = $juniper->jnxExVlanPortAccessMode($partial);

    my %i_trunk;

    foreach (keys %$access)
    {
	my $old_key = $_;
	m/^\d+\.(\d+)$/o;
	my $new_key = $1;
	$i_trunk{$new_key} = $access->{$old_key};
    }

    return \%i_trunk;
}

# 'v_type'     => 'jnxExVlanType',
sub v_type {
    my $juniper = shift;
    my $partial = shift;

    my $v_type  = $juniper->jnxExVlanType($partial);

    return $v_type;
}

# 'v_index'    => 'jnxExVlanTag',
sub v_index {
    my ($juniper) = shift;
    my ($partial) = shift;

    my ($v_index)  = $juniper->jnxExVlanTag($partial);

    return $v_index;
}

sub i_vlan {
    my $juniper = shift;
    my $partial = shift;

    my $index = $juniper->bp_index();

    # If given a partial it will be an ifIndex, we need to use dot1dBasePort
    if ($partial) {
        my %r_index = reverse %$index;
        $partial = $r_index{$partial};
    }

    my $v_index  = $juniper->jnxExVlanTag();
    my $i_pvid   = $juniper->qb_i_vlan($partial) || {};
    my $i_vlan = {};

    foreach my $bport ( keys %$i_pvid ) {
        my $q_vlan  = $i_pvid->{$bport};
	my $vlan    = $v_index->{$q_vlan};
        my $ifindex = $index->{$bport};
        unless ( defined $ifindex ) {
            print "  Port $bport has no bp_index mapping. Skipping.\n"
                if $DEBUG;
            next;
        }
        $i_vlan->{$ifindex} = $vlan;
    }

    return $i_vlan;
}

sub i_vlan_membership {
    my $juniper  = shift;
    my $partial = shift;

    my $index = $juniper->bp_index();
    my ($v_index)  = $juniper->jnxExVlanTag($partial);

    my $v_ports = $juniper->qb_v_egress() || {};

    my $i_vlan_membership = {};

    foreach my $idx ( sort keys %$v_ports ) {
        next unless ( defined $v_ports->{$idx} );
        my $portlist = $v_ports->{$idx}; # is an array reference
        my $ret      = [];
        my $vlan_ndx = $idx;

        # Convert portlist bit array to bp_index array
        for ( my $i = 0; $i <= $#$portlist; $i++ ) {
            push( @{$ret}, $i + 1 ) if ( @$portlist[$i] );
        }

        #Create HoA ifIndex -> VLAN array
        foreach my $port ( @{$ret} ) {
            my $ifindex = $index->{$port};
            next unless ( defined($ifindex) );    # shouldn't happen
            next if ( defined $partial and $ifindex !~ /^$partial$/ );
            push ( @{ $i_vlan_membership->{$ifindex} }, $v_index->{$vlan_ndx} );
        }
    }

    return $i_vlan_membership;
}

# Use Q-BRIDGE-MIB for bridge forwarding tables
sub fw_mac {
    my $juniper  = shift;
    my $partial = shift;

    return $juniper->qb_fw_mac($partial);
}

sub fw_port {
    my $juniper  = shift;
    my $partial = shift;

    return $juniper->qb_fw_port($partial);
}

# Use LLDP

sub hasCDP {
    my $juniper = shift;

    return $juniper->hasLLDP();
}

sub c_ip {
    my $juniper  = shift;
    my $partial = shift;

    return $juniper->lldp_ip($partial);
}

sub c_if {
    my $juniper  = shift;
    my $partial = shift;

    return $juniper->lldp_if($partial);
}

sub c_port {
    my $juniper  = shift;
    my $partial = shift;

    return $juniper->lldp_port($partial);
}

sub c_id {
    my $juniper  = shift;
    my $partial = shift;

    return $juniper->lldp_id($partial);
}

sub c_platform {
    my $juniper  = shift;
    my $partial = shift;

    return $juniper->lldp_rem_sysdesc($partial);
}


1;
__END__

=head1 NAME

SNMP::Info::Layer3::Juniper - SNMP Interface to L3 Juniper Devices

=head1 AUTHOR

Bill Fenner

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $juniper = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $juniper->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Generic Juniper Routers running JUNOS

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::LLDP

=back

=head2 Required MIBs

JUNIPER-VLAN-MIB dated "200901090000Z" -- Fri Jan 09 00:00:00 2009 UTC or later.

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::LLDP/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $juniper->vendor()

Returns C<'juniper'>

=item $juniper->os()

Returns C<'junos'>

=item $juniper->os_ver()

Returns the software version extracted from C<sysDescr>.

=item $juniper->model()

Returns the model from C<sysObjectID>, with C<jnxProductName> removed from the
beginning.

=item $juniper->serial()

Returns serial number

(C<jnxBoxSerialNo.0>)

=item $juniper->hasCDP()

    Returns whether LLDP is enabled.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $juniper->v_index()

(C<jnxExVlanTag>)

=item $juniper->v_name()

(C<jnxExVlanName>)

=item $juniper->v_type()

(C<jnxExVlanType>)

=item $juniper->i_vlan()

Returns a mapping between C<ifIndex> and the VLAN tag on interfaces
whose C<ifType> is propVirtual (53).

=item $juniper->i_trunk()

(C<jnxExVlanPortAccessMode>)

=item $bridge->i_vlan()

Returns a mapping between C<ifIndex> and the PVID or default VLAN.

=item $bridge->i_vlan_membership()

Returns reference to hash of arrays: key = C<ifIndex>, value = array of VLAN
IDs.  These are the VLANs which are members of the egress list for the port.

=item $juniper->c_id()

Returns LLDP information.

=item $juniper->c_if()

Returns LLDP information.

=item $juniper->c_ip()

Returns LLDP information.

=item $juniper->c_platform()

Returns LLDP information.

=item $juniper->c_port()

Returns LLDP information.

=back

=head2 Forwarding Table (C<dot1dTpFdbEntry>)

=over 

=item $juniper->fw_mac()

Returns reference to hash of forwarding table MAC Addresses

(C<dot1dTpFdbAddress>)

=item $juniper->fw_port()

Returns reference to hash of forwarding table entries port interface
identifier (iid)

(C<dot1dTpFdbPort>)

=back 

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"TABLE METHODS"> for details.

=cut
