# SNMP::Info::Layer2::HP4000 - SNMP Interface to older HP ProCurve Switches (1600, 2400, 2424M, 4000 and 8000)
#
# Copyright (c) 2008 Max Baker changes from version 0.8 and beyond.
#
# Copyright (c) 2002,2003 Regents of the University of California
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

package SNMP::Info::Layer2::HP4000;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::MAU;
use SNMP::Info::CDP;

@SNMP::Info::Layer2::HP4000::ISA
    = qw/SNMP::Info::Layer3 SNMP::Info::MAU
    SNMP::Info::CDP Exporter/;
@SNMP::Info::Layer2::HP4000::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %PORTSTAT, %MODEL_MAP, %MUNGE);

$VERSION = '3.70';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::MAU::MIBS,
    %SNMP::Info::CDP::MIBS,
    'RFC1271-MIB'    => 'logDescription',
    'HP-ICF-OID'     => 'hpSwitch4000',
    'HP-VLAN'        => 'hpVlanMemberIndex',
    'STATISTICS-MIB' => 'hpSwitchCpuStat',
    'NETSWITCH-MIB'  => 'hpMsgBufFree',
    'CONFIG-MIB'     => 'hpSwitchConfig',
    'SEMI-MIB'       => 'hpHttpMgSerialNumber',
    'HP-ICF-CHASSIS' => 'hpicfSensorObjectId',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::MAU::GLOBALS,
    %SNMP::Info::CDP::GLOBALS,
    'serial1'      => 'hpHttpMgSerialNumber.0',
    'hp_cpu'       => 'hpSwitchCpuStat.0',
    'hp_mem_total' => 'hpGlobalMemTotalBytes.1',
    'mem_free'     => 'hpGlobalMemFreeBytes.1',
    'mem_used'     => 'hpGlobalMemAllocBytes.1',
    'os_version'   => 'hpSwitchOsVersion.0',
    'os_bin'       => 'hpSwitchRomVersion.0',
    'mac'          => 'hpSwitchBaseMACAddress.0',
    'hp_vlans'     => 'hpVlanNumber',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::MAU::FUNCS,
    %SNMP::Info::CDP::FUNCS,
    'bp_index2' => 'dot1dBasePortIfIndex',
    'i_type2'   => 'ifType',

    # RFC1271
    'l_descr' => 'logDescription',

    # HP-VLAN-MIB
    'hp_v_index'    => 'hpVlanDot1QID',
    'hp_v_name'     => 'hpVlanIdentName',
    'hp_v_state'    => 'hpVlanIdentState',
    'hp_v_type'     => 'hpVlanIdentType',
    'hp_v_status'   => 'hpVlanIdentStatus',
    'hp_v_mac'      => 'hpVlanAddrPhysAddress',
    'hp_v_if_index' => 'hpVlanMemberIndex',
    'hp_v_if_tag'   => 'hpVlanMemberTagged2',

    # CONFIG-MIB::hpSwitchPortTable
    'hp_duplex'       => 'hpSwitchPortEtherMode',
    'hp_duplex_admin' => 'hpSwitchPortFastEtherMode',
    'vendor_i_type'   => 'hpSwitchPortType',

    # HP-ICF-CHASSIS
    'hp_s_oid'    => 'hpicfSensorObjectId',
    'hp_s_name'   => 'hpicfSensorDescr',
    'hp_s_status' => 'hpicfSensorStatus',
);

%MUNGE = (

    # Inherit all the built in munging
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::MAU::MUNGE,
    %SNMP::Info::CDP::MUNGE
);

%MODEL_MAP = (
    'J4093A' => '2424M',
    'J4110A' => '8000M',
    'J4120A' => '1600M',
    'J4121A' => '4000M',
    'J4122A' => '2400M',
    'J4122B' => '2424M',
);

# Method Overrides

sub cpu {
    my $hp = shift;
    return $hp->hp_cpu();
}

sub mem_total {
    my $hp = shift;
    return $hp->hp_mem_total();
}

sub os {
    return 'hp';
}

sub os_ver {
    my $hp         = shift;
    my $os_version = $hp->os_version();
    return $os_version if defined $os_version;

    # Some older ones don't have this value,so we cull it from the description
    my $descr = $hp->description();
    if ( $descr =~ m/revision ([A-Z]{1}\.\d{2}\.\d{2})/ ) {
        return $1;
    }
    return;
}

# Lookup model number, and translate the part number to the common number
sub model {
    my $hp = shift;
    my $id = $hp->id();
    return unless defined $id;
    my $model = &SNMP::translateObj($id);
    return $id unless defined $model;

    $model =~ s/^hpswitch//i;

    return defined $MODEL_MAP{$model} ? $MODEL_MAP{$model} : $model;
}

sub interfaces {
    my $hp         = shift;
    my $interfaces = $hp->i_index();
    my $i_descr    = $hp->i_description();

    my %if;
    foreach my $iid ( keys %$interfaces ) {
        my $descr = $i_descr->{$iid};
        next unless defined $descr;
        $if{$iid} = $descr if ( defined $descr and length $descr );
    }

    return \%if
}

sub i_name {
    my $hp      = shift;
    my $i_alias = $hp->i_alias();
    my $e_name  = $hp->e_name();
    my $e_port  = $hp->e_port();

    my %i_name;

    foreach my $port ( keys %$e_name ) {
        my $iid = $e_port->{$port};
        next unless defined $iid;
        my $alias = $i_alias->{$iid};
        next unless defined $iid;
        $i_name{$iid} = $e_name->{$port};

        # Check for alias
        $i_name{$iid} = $alias if ( defined $alias and length($alias) );
    }

    return \%i_name;
}

sub i_duplex {
    my $hp = shift;

    return $hp->mau_i_duplex();
}

sub i_duplex_admin {
    my $hp      = shift;
    my $partial = shift;

    # Try HP MIB first
    my $hp_duplex = $hp->hp_duplex_admin($partial);
    if ( defined $hp_duplex and scalar( keys %$hp_duplex ) ) {

        my %i_duplex;
        foreach my $if ( keys %$hp_duplex ) {
            my $duplex = $hp_duplex->{$if};
            next unless defined $duplex;

            $duplex = 'half' if $duplex =~ /half/i;
            $duplex = 'full' if $duplex =~ /full/i;
            $duplex = 'auto' if $duplex =~ /auto/i;
            $i_duplex{$if} = $duplex;
        }
        return \%i_duplex;
    }
    else {
        return $hp->mau_i_duplex_admin();
    }
}

sub vendor {
    return 'hp';
}

sub log {
    my $hp = shift;

    my $log = $hp->l_descr();

    my $logstring = undef;

    foreach my $val ( values %$log ) {
        next if $val =~ /^Link\s+(Up|Down)/;
        $logstring .= "$val\n";
    }

    return $logstring;
}

sub slots {
    my $hp = shift;

    my $e_name = $hp->e_name();

    return unless defined $e_name;

    my $slots;
    foreach my $slot ( keys %$e_name ) {
        $slots++ if $e_name->{$slot} =~ /slot/i;
    }

    return $slots;
}

sub fan {
    my $hp = shift;
    return &_sensor( $hp, 'fan' );
}

sub ps1_status {
    my $hp = shift;
    return &_sensor( $hp, 'power', '^power supply 1' )
        || &_sensor( $hp, 'power', '^power supply sensor' );
}

sub ps2_status {
    my $hp = shift;
    return &_sensor( $hp, 'power', '^power supply 2' )
        || &_sensor( $hp, 'power', '^redundant' );
}

sub _sensor {
    my $hp          = shift;
    my $search_type = shift || 'fan';
    my $search_name = shift || '';
    my $hp_s_oid    = $hp->hp_s_oid();
    my $result;
    foreach my $sensor ( keys %$hp_s_oid ) {
        my $sensortype = &SNMP::translateObj( $hp_s_oid->{$sensor} );
        if ( $sensortype =~ /$search_type/i ) {
            my $sensorname   = $hp->hp_s_name()->{$sensor};
            my $sensorstatus = $hp->hp_s_status()->{$sensor};
            if ( $sensorname =~ /$search_name/i ) {
                $result = $sensorstatus;
            }
        }
    }
    return $result;
}

# Bridge MIB does not map Bridge Port to ifIndex correctly on older models, but Bridge Port equals ifIndex in these devices
sub bp_index {
    my $hp      = shift;
    my $partial = shift;

    my $if_index = $hp->i_index($partial);
    my %mod_bp_index;
    foreach my $iid ( keys %$if_index ) {
        $mod_bp_index{$iid} = $iid;
    }
    return \%mod_bp_index;
}

# VLAN methods. Devices in this class use the proprietary HP-VLAN-MIB.

sub v_index {
    my $hp      = shift;
    my $partial = shift;

    return $hp->hp_v_index($partial);
}

sub v_name {
    my $hp      = shift;
    my $partial = shift;

    return $hp->hp_v_name($partial);
}

sub i_vlan {
    my $hp = shift;

    # the hpvlanmembertagged2 table has an entry in the form of
    #   vlan.interface = /untagged/no/tagged/auto
    my $i_vlan      = {};
    my $hp_v_index  = $hp->hp_v_index();
    my $hp_v_if_tag = $hp->hp_v_if_tag();
    foreach my $row ( keys %$hp_v_if_tag ) {
        my ( $index, $if ) = split( /\./, $row );

        my $tag  = $hp_v_if_tag->{$row};
        my $vlan = $hp_v_index->{$index};

        next unless ( defined $tag and $tag =~ /untagged/ );

        $i_vlan->{$if} = $vlan if defined $vlan;
    }

    return $i_vlan;
}

sub i_vlan_membership {
    my $hp = shift;

    my $i_vlan_membership = {};
    my $hp_v_index        = $hp->hp_v_index();
    my $hp_v_if_tag       = $hp->hp_v_if_tag();
    foreach my $row ( keys %$hp_v_if_tag ) {
        my ( $index, $if ) = split( /\./, $row );

        my $tag  = $hp_v_if_tag->{$row};
        my $vlan = $hp_v_index->{$index};

        next unless ( defined $tag );
        next if ( $tag eq 'no' );

        push( @{ $i_vlan_membership->{$if} }, $vlan );
    }

    return $i_vlan_membership;
}

sub i_vlan_membership_untagged {
    my $hp  = shift;
    my $partial = shift;

    my $vlans = $hp->i_vlan($partial);
    my $i_vlan_membership = {};
    foreach my $port (keys %$vlans) {
        my $vlan = $vlans->{$port};
        push( @{ $i_vlan_membership->{$port} }, $vlan );
    }

    return $i_vlan_membership;
}

sub set_i_vlan {
    my $hp = shift;
    my $rv;

    my $hp_v_index  = $hp->hp_v_index();
    my $hp_v_if_tag = $hp->hp_v_if_tag();
    if (defined $hp_v_index and scalar(keys %$hp_v_index)){
        my $vlan = shift;
        my $iid = shift;
        my $old_untagged;
        # Hash to lookup VLAN index of the VID (dot1q tag)
        my %vl_trans = reverse %$hp_v_index;

        # Translate the VLAN identifier (tag) value to the index used by the HP-VLAN MIB
        my $vlan_index = $vl_trans{$vlan};
        if (defined $vlan_index) {

            # First, loop through table to determine current untagged vlan for the port we're about to change
            foreach my $row (keys %$hp_v_if_tag){
                my ($index,$if) = split(/\./,$row);
                if ($if == $iid and $hp_v_if_tag->{$row} =~ /untagged/) {
                    # Store the row information of the current untagged VLAN and temporarily set it to tagged
                    $old_untagged = $row;
                    $rv = $hp->set_hp_v_if_tag(1, $row);
                    last;
                }
            }

            # Then set our port untagged in the desired VLAN
            my $rv = $hp->set_hp_v_if_tag(2, "$vlan_index.$iid");
            if (defined $rv) {
                # If vlan change is successful, remove VLAN that used to be untagged from the port
                if (defined $old_untagged) {
                    $rv = $hp->set_hp_v_if_tag(3, $old_untagged);
                    $hp->error_throw("Error removing previous untagged vlan from port, should never happen...\n") unless defined $rv;
                }
            } else {
                # If vlan change was not successful, try to revert to the old situation.
                if (defined $old_untagged) {
                    $rv = $hp->set_hp_v_if_tag(2, $old_untagged) if defined $old_untagged;
                    if (defined $rv) {
                        $hp->error_throw("VLAN change failed, restored port to previous configuration.\n");
                    } else {
                        $hp->error_throw("VLAN change failed, unable to restore old configuration. Check device.\n");
                    }
                }
            }
        } else {
            $hp->error_throw("Requested VLAN (VLAN ID: $vlan) not available on device.\n");
        }
    } else {
        $hp->error_throw("Error retrieving VLAN information from device.\n");
    }
    return $rv;
}

sub set_i_vlan_tagged {
    my $hp = shift;
    my $vlan = shift;
    my $iid = shift;
    my $rv;

    my $hp_v_index  = $hp->hp_v_index();
    if (defined $hp_v_index and scalar(keys %$hp_v_index)){
        # Hash to lookup VLAN index of the VID (dot1q tag)
        my %vl_trans = reverse %$hp_v_index;

        # Translate the VLAN identifier (tag) value to the index used by the HP-VLAN MIB
        my $vlan_index = $vl_trans{$vlan};
        if (defined $vlan_index) {
            # Set our port tagged in the desired VLAN
            $rv = $hp->set_hp_v_if_tag(1, "$vlan_index.$iid");
        } else {
            $hp->error_throw("Requested VLAN (VLAN ID: $vlan) not available on device.\n");
        }
    }
    return $rv;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::HP4000 - SNMP Interface to older HP ProCurve Switches (1600, 2400, 2424M, 4000 and 8000)

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $hp = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $hp->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a
HP ProCurve Switch via SNMP.

Note:  Some HP Switches will connect via SNMP version 1, but a lot of config
data will not be available.  Make sure you try and connect with Version 2
first, and then fail back to version 1.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2


=item SNMP::Info::MAU

=back

=head2 Required MIBs

=over

=item F<RFC1271-MIB>

Included in V2 mibs from Cisco

=item F<HP-ICF-OID>

=item F<HP-VLAN>

(this MIB new with SNMP::Info 0.8)

=item F<STATISTICS-MIB>

=item F<NETSWITCH-MIB>

=item F<CONFIG-MIB>

=back

The last five MIBs listed are from HP and can be found at
L<http://www.hp.com/rnd/software> or
L<http://www.hp.com/rnd/software/MIBs.htm>

=head1 Change Log

Version 0.4 - Removed F<ENTITY-MIB> e_*() methods to separate sub-class -
SNMP::Info::Entity

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $hp->cpu()

Returns CPU Utilization in percentage.

=item $hp->log()

Returns all the log entries from the switch's log that are not Link up or
down messages.

=item $hp->mem_free()

Returns bytes of free memory

=item $hp->mem_total()

Return bytes of total memory

=item $hp->mem_used()

Returns bytes of used memory

=item $hp->model()

Returns the model number of the HP Switch.  Will translate between the HP Part
number and the common model number with this map :

 %MODEL_MAP = (
                'J4093A' => '2424M',
                'J4110A' => '8000M',
                'J4120A' => '1600M',
                'J4121A' => '4000M',
                'J4122A' => '2400M',
                'J4122B' => '2424M',
                );

=item $hp->os()

Returns hp

=item $hp->os_bin()

C<hpSwitchRomVersion.0>

=item $hp->os_ver()

Tries to use os_version() and if that fails will try and cull the version from
the description field.

=item $hp->os_version()

C<hpSwitchOsVersion.0>

=item $hp->serial()

Returns serial number if available through SNMP

=item $hp->slots()

Returns number of entries in $hp->e_name that have 'slot' in them.

=item $hp->vendor()

hp

=item $hp->fan()

Returns fan status

=item $hp->ps1_status()

Power supply 1 status

=item $hp->ps2_status()

Power supply 2 status

=back

=head2 Globals imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $hp->interfaces()

Uses $hp->i_description()

=item $hp->i_duplex()

Returns reference to map of IIDs to current link duplex.

=item $hp->i_duplex_admin()

Returns reference to hash of IIDs to admin duplex setting.

=item $hp->vendor_i_type()

Returns reference to hash of IIDs to HP specific port type
(C<hpSwitchPortType>).

=item $hp->i_name()

Crosses i_name() with $hp->e_name() using $hp->e_port() and i_alias()

=item $hp->i_vlan()

Returns a mapping between C<ifIndex> and the PVID (default VLAN) or untagged
port when using F<HP-VLAN>.

=item $hp->i_vlan_membership()

Returns reference to hash of arrays: key = C<ifIndex>, value = array of VLAN
IDs.  These are the VLANs which are members of the egress list for the port.
It is the union of tagged, untagged, and auto ports.

  Example:
  my $interfaces = $hp->interfaces();
  my $vlans      = $hp->i_vlan_membership();

  foreach my $iid (sort keys %$interfaces) {
    my $port = $interfaces->{$iid};
    my $vlan = join(',', sort(@{$vlans->{$iid}}));
    print "Port: $port VLAN: $vlan\n";
  }

=item $hp->i_vlan_membership_untagged()

Returns reference to hash of arrays: key = C<ifIndex>, value = array of VLAN
IDs.  These are the VLANs which are members of the untagged egress list for
the port.

=item $hp->v_index()

Returns VLAN IDs

=item $hp->v_name()

Returns VLAN names

=item $hp->bp_index()

Returns reference to hash of bridge port table entries map back to interface
identifier (iid)

Returns (C<ifIndex>) for both key and value for 1600, 2424, 4000, and 8000
models since they seem to have problems with F<BRIDGE-MIB>

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"TABLE METHODS"> for details.

=head1 SET METHODS

These are methods that provide SNMP set functionality for overridden methods
or provide a simpler interface to complex set operations.  See
L<SNMP::Info/"SETTING DATA VIA SNMP"> for general information on set
operations.

=over

=item set_i_vlan()

=item set_i_vlan_tagged()

=back

=cut
