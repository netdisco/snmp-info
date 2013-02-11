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

$VERSION = '3.00_003';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::LLDP::MIBS,
    'JUNIPER-CHASSIS-DEFINES-MIB' => 'jnxChassisDefines',
    'JUNIPER-MIB'                 => 'jnxBoxAnatomy',
    'JUNIPER-VIRTUALCHASSIS-MIB'  => 'jnxVirtualChassisMemberTable',
    'JUNIPER-VLAN-MIB'            => 'jnxVlanMIBObjects',
);

%GLOBALS = ( %SNMP::Info::Layer3::GLOBALS, 
	     %SNMP::Info::LLDP::GLOBALS,
	     'serial'    => 'jnxBoxSerialNo.0',
	     'mac'       => 'dot1dBaseBridgeAddress',
	     'box_descr' => 'jnxBoxDescr'
	     );

%FUNCS = ( %SNMP::Info::Layer3::FUNCS, 
	   %SNMP::Info::LLDP::FUNCS,
	   
	   # JUNIPER-VLAN-MIB::jnxExVlanTable
	   'v_index'    => 'jnxExVlanTag',
	   'v_type'     => 'jnxExVlanType',
	   'v_name'     => 'jnxExVlanName',
	   
	   # JUNIPER-VLAN-MIB::jnxExVlanPortGroupTable
	   'i_trunk'    => 'jnxExVlanPortAccessMode',
	   
	   # JUNPIER-MIB
           'e_contents_type'   => 'jnxContentsType',
           'e_containers_type' => 'jnxContainersType',
           'e_hwver'           => 'jnxContentsRevision',
);

%MUNGE = ( %SNMP::Info::Layer3::MUNGE, 
	   %SNMP::Info::LLDP::MUNGE,
	   'e_containers_type' => \&SNMP::Info::munge_e_type,
	   'e_contents_type' => \&SNMP::Info::munge_e_type,
);

sub vendor {
    return 'juniper';
}

sub os {
    return 'junos';
}

sub os_ver {
    my $juniper = shift;

    my $descr        = $juniper->description() || '';
    my $lldp_descr   = $juniper->lldp_sysdesc() || '';

    if ( $descr =~ m/kernel JUNOS (\S+)/ ) {
        return $1;
    }
    elsif ( $lldp_descr =~ m/version\s(\S+)\s/ ) {
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

# Pseudo ENTITY-MIB methods

# This class supports both virtual chassis (stackable) and physical chassis
# based devices, identify if we have a virtual chassis so that we return
# appropriate entPhysicalClass and correct ordering

sub _e_is_virtual {
    my $juniper = shift;

    my $v_test = $juniper->jnxVirtualChassisMemberRole() || {};
    
    #If we are functioning as a stack someone should be master
    foreach my $iid ( keys %$v_test ) {
	my $role = $v_test->{$iid};
	return 1 if ($role =~ /master/i);
    }
    return 0;
}

sub _e_virtual_index {
    my $juniper = shift;

    my $containers = $juniper->jnxContainersWithin() || {};
    my $members    = $juniper->jnxVirtualChassisMemberRole() || {};
    
    my %v_index;
    foreach my $key (keys %$containers) {
	foreach my $member ( keys %$members ) {
	    # Virtual chassis members start at zero
	    $member++;
	    # We will be duplicating and eliminating some keys,
	    # but this is for the benefit of e_parent()
	    my $index  = sprintf ("%02d", $key) . sprintf ("%02d", $member) . "0000";
	    my $iid = "$key\.$member\.0\.0";
	    $v_index{$iid} = $index;
	}
	unless ($containers->{$key}) {
	    my $index = sprintf ("%02d", $key) . "000000";
	    $v_index{$key} = $index;
	}
    }
    return \%v_index;
}

sub e_index {
    my $juniper = shift;

    my $contents   = $juniper->jnxContentsDescr() || {};
    my $containers = $juniper->jnxContainersDescr() || {};
    my $virtuals   = $juniper->_e_virtual_index() || {};
    my $is_virtual = $juniper->_e_is_virtual();

    # Format into consistent integer format so that numeric sorting works     
    my %e_index;
    if ($is_virtual) {
	foreach my $key ( keys %$virtuals ) {
	    $e_index{$key} = $virtuals->{$key};
	}
    }
    else {
	foreach my $key ( keys %$containers ) {
	    $e_index{$key} = sprintf ("%02d", $key) . "000000";
	}
    }
    foreach my $key ( keys %$contents ) {
	$e_index{$key} = join( '', map { sprintf "%02d", $_ } split /\./, $key );
    }
 
    return \%e_index;
}

sub e_class {
    my $juniper = shift;

    my $e_index    = $juniper->e_index() || {};
    my $fru_type   = $juniper->jnxFruType() || {};
    my $c_type     = $juniper->jnxContainersDescr() || {};
    my $is_virtual = $juniper->_e_is_virtual();

    my %e_class;
    foreach my $iid ( keys %$e_index ) {
	
	my $type      = $fru_type->{$iid} || 0;
	my $container = $c_type->{$iid} || 0;
	
        if ( $type =~ /power/i  ) {
            $e_class{$iid} = 'powerSupply';
        }
        elsif ( $type =~ /fan/i ) {
            $e_class{$iid} = 'fan';
        }
	elsif ( $type ) {
	    $e_class{$iid} = 'module';
	}
	# Shouldn't get here if we have type which means
	# we only have container, chassis, and stack left
        elsif (($container =~ /chassis/i) and (!$is_virtual) ) {
            $e_class{$iid} = 'chassis';
        }
        elsif (($container =~ /chassis/i) and ($is_virtual)) {
            $e_class{$iid} = 'stack';
	}
	# Were calling the second level chassis a container in the case
	# of a virtual chassis but not sure that it really matters
        else {
            $e_class{$iid} = 'container';
        }
    }
    return \%e_class;
}

sub e_descr {
    my $juniper = shift;

    my $e_index    = $juniper->e_index() || {};
    my $box_descr  = $juniper->box_descr;
    my $contents   = $juniper->jnxContentsDescr() || {};
    my $containers = $juniper->jnxContainersDescr() || {};

    my %e_descr;
    foreach my $iid ( keys %$e_index ) {
	
	my $content_descr   = $contents->{$iid} || 0;
	my $container_descr = $containers->{$iid} || 0;
	
	if ($content_descr) {
	    $e_descr{$iid} = $content_descr;
	}
	elsif ($container_descr and $container_descr !~ /chassis/) {
	    $e_descr{$iid} = $container_descr;
	}
	elsif ($container_descr and $container_descr =~ /chassis/) {
	    $e_descr{$iid} = $box_descr;
	}
	# We should only be left with virtual entries created in
	# _e_virtual_index()
	elsif ($iid =~ /^(\d+)\.(\d+)(\.0)+?/) {
	    my $descr = $containers->{$1};
	    $e_descr{$iid} = $descr;
	}
	# Anything past here undef
    }
    return \%e_descr;
}

sub e_serial {
    my $juniper = shift;

    my $e_index    = $juniper->e_index() || {};
    my $serials    = $juniper->jnxContentsSerialNo() || {};
    my $e_class    = $juniper->e_class() || {};
    my $is_virtual = $juniper->_e_is_virtual();
    my $box_serial = $juniper->serial();

    my %e_serial;
    foreach my $iid ( keys %$e_index ) {
	my $serial = $serials->{$iid} || '';
	my $class  = $e_class->{$iid} || '';
	# Chassis serial number is seperate on true chassis
	# Virtual chassis (stack) report master switch serial
	if (!$is_virtual and ($class =~ /chassis/i)){
	    $e_serial{$iid} = $box_serial;
	}
	elsif (($serial !~ /^\w/) or ($serial =~ /builtin/i)) {
	    next;
	}
	else {
	    $e_serial{$iid} = $serial;
	}
    }
    return  \%e_serial;
}

sub e_fru {
    my $juniper = shift;

    my $e_index = $juniper->e_index() || {};
    my $frus    = $juniper->jnxContentsPartNo() || {};

    my %e_fru;
    foreach my $iid ( keys %$e_index ) {
	my $fru = $frus->{$iid} || '';
	if ( ($fru !~ /^\w/) or ($fru =~ /builtin/i)) {
	    $e_fru{$iid} = "false";
	}
	else {
	    $e_fru{$iid} = "true";
	}
    }
    return  \%e_fru;
}

sub e_type {
    my $juniper = shift;

    my $e_index    = $juniper->e_index() || {};
    my $contents   = $juniper->e_contents_type() || {};
    my $containers = $juniper->e_containers_type() || {};

    my %e_type;
    foreach my $iid ( keys %$e_index ) {
	
	my $content_type   = $contents->{$iid} || 0;
	my $container_type = $containers->{$iid} || 0;
	
	if ($content_type) {
	    $content_type =~ s/\.0//;
	    $e_type{$iid} = $content_type;
	}
	elsif ($container_type) {
	    $container_type =~ s/\.0//;
	    $e_type{$iid} = $container_type;
	}
	# We should only be left with virtual entries created in
	# _e_virtual_index()
	elsif ($iid =~ /^(\d+)\.(\d+)(\.0)+?/) {
	    my $descr = $containers->{$1};
	    $descr =~ s/\.0//;
	    $e_type{$iid} = $descr;
	}
	# Anything past here undef
    }
    return \%e_type;
}

sub e_vendor {
    my $juniper = shift;

    my $e_idx = $juniper->e_index() || {};

    my %e_vendor;
    foreach my $iid ( keys %$e_idx ) {
        $e_vendor{$iid} = 'juniper';
    }
    return \%e_vendor;
}

sub e_pos {
    my $juniper = shift;

    # We could look at index levels, but his will work as well
    return $juniper->e_index();
}

sub e_parent {
    my $juniper = shift;

    my $e_idx      = $juniper->e_index() || {};
    my $c_within   = $juniper->jnxContainersWithin() || {};
    my $e_descr    = $juniper->e_descr() || {};
    my $is_virtual = $juniper->_e_is_virtual();
    
    my %e_parent;
    foreach my $iid ( keys %$e_idx ) {
        next unless $iid;
	
	my ($idx, $l1,$l2, $l3) = split /\./, $iid;
	my $within = $c_within->{$idx};
	my $descr  = $e_descr->{$iid};
	
        if ( !$is_virtual and ($iid =~ /^(\d+)\.\d+/) ) {
            $e_parent{$iid} = sprintf ("%02d", $1) . "000000";
        }
	elsif ( $is_virtual and ($descr =~ /chassis/i) and ($iid =~ /^(\d+)\.(\d+)(\.0)+?/) ) {
	    $e_parent{$iid} = sprintf ("%02d", $1) . "000000";
	}
	elsif ( $is_virtual and ($iid =~ /^(\d+)\.(\d+)(\.0)+?/) ) {
	    $e_parent{$iid} = sprintf ("%02d", $within) . sprintf ("%02d", $2) . "0000";
	}
	elsif ( $is_virtual and ($iid =~ /^(\d+)\.(\d+)\.[1-9]+/) ) {
	    $e_parent{$iid} = sprintf ("%02d", $1) . sprintf ("%02d", $2) . "0000";
	}
	elsif ( defined $within and $iid =~ /\d+/ ) {
            $e_parent{$iid} = sprintf ("%02d", $within) . "000000";
	}
        else {
            next;
        }
    }
    return \%e_parent;
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

Subclass for Juniper Devices running JUNOS

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::LLDP

=back

=head2 Required MIBs

=over

=item F<JUNIPER-VLAN-MIB> dated "200901090000Z" or later.

=item F<JUNIPER-CHASSIS-DEFINES-MIB>

=item F<JUNIPER-MIB>

=item F<JUNIPER-VIRTUALCHASSIS-MIB>

=back

=head2 Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::LLDP/"Required MIBs"> for its own MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $juniper->vendor()

Returns 'juniper'

=item $juniper->os()

Returns 'junos'

=item $juniper->os_ver()

Returns the software version extracted first from C<sysDescr> or
C<lldpLocSysDesc> if not available in C<sysDescr>.

=item $juniper->model()

Returns the model from C<sysObjectID>, with C<jnxProductName> removed from the
beginning.

=item $juniper->serial()

Returns serial number

(C<jnxBoxSerialNo.0>)

=item $juniper->mac()

Returns the MAC address used by this bridge when it must be referred
to in a unique fashion.

(C<dot1dBaseBridgeAddress>)

=item $juniper->box_descr()

The name, model, or detailed description of the device.

(C<jnxBoxDescr.0>)

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

=item $juniper->i_trunk()

(C<jnxExVlanPortAccessMode>)

=item $juniper->i_vlan()

Returns a mapping between C<ifIndex> and the PVID or default VLAN.

=item $juniper->i_vlan_membership()

Returns reference to hash of arrays: key = C<ifIndex>, value = array of VLAN
IDs.  These are the VLANs which are members of the egress list for the port.

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

=head2 Pseudo F<ENTITY-MIB> information

These methods emulate F<ENTITY-MIB> Physical Table methods using
F<JUNIPER-MIB> and F<JUNIPER-VIRTUALCHASSIS-MIB>. 

=over

=item $juniper->e_index()

Returns reference to hash.  Key: IID, Value: Integer, Indices are combined
into a eight digit integer, each index is two digits padded with leading zero
if required.

=item $juniper->e_class()

Returns reference to hash.  Key: IID, Value: General hardware type.

=item $juniper->e_descr()

Returns reference to hash.  Key: IID, Value: Human friendly name

=item $juniper->e_hwver()

Returns reference to hash.  Key: IID, Value: Hardware version

=item $juniper->e_vendor()

Returns reference to hash.  Key: IID, Value: juniper

=item $juniper->e_serial()

Returns reference to hash.  Key: IID, Value: Serial number

=item $juniper->e_pos()

Returns reference to hash.  Key: IID, Value: The relative position among all
entities sharing the same parent.

=item $juniper->e_type()

Returns reference to hash.  Key: IID, Value: Type of component/sub-component
as defined in F<JUNIPER-CHASSIS-DEFINES-MIB>.

=item $juniper->e_parent()

Returns reference to hash.  Key: IID, Value: The value of e_index() for the
entity which 'contains' this entity.  A value of zero indicates	this entity
is not contained in any other entity.

=item $entity->e_fru()

BOOLEAN. Is a Field Replaceable unit?

(C<entPhysicalFRU>)

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"TABLE METHODS"> for details.

=cut
