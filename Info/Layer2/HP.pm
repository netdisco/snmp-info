# SNMP::Info::Layer2::HP - SNMP Interface to HP ProCurve Switches
# Max Baker <max@warped.org>
#
# Copyright (c) 2002, Regents of the University of California
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

package SNMP::Info::Layer2::HP;
$VERSION = 0.1;

use strict;

use Exporter;
use SNMP::Info::Layer2;
use SNMP::Info::MAU;

use vars qw/$VERSION $DEBUG %GLOBALS %MIBS %FUNCS %PORTSTAT 
            %MYGLOBALS %MYMIBS %MYFUNCS %MYMUNGE %MUNGE $INIT/ ;
@SNMP::Info::Layer2::HP::ISA = qw/SNMP::Info::Layer2 SNMP::Info::MAU Exporter/;
@SNMP::Info::Layer2::HP::EXPORT_OK = qw//;

$DEBUG=0;
$SNMP::debugging=$DEBUG;

# See SNMP::Info for the details of these data structures and 
#       the interworkings.
$INIT = 0;

%MYMIBS = ( 'ENTITY-MIB'  => 'entPhysicalSerialNum',
            'RFC1271-MIB' => 'logDescription',
            'HP-ICF-OID'  => 'hpSwitch4000',
          );

%MIBS = ( %SNMP::Info::Layer2::MIBS,
          %SNMP::Info::MAU::MIBS,
          %MYMIBS );

%MYGLOBALS = ('serial1' => 'entPhysicalSerialNum.1',
#              'model'  => 'entPhysicalModelName.1',
             );
%GLOBALS = (
            %SNMP::Info::Layer2::GLOBALS,
            %SNMP::Info::MAU::GLOBALS,
            %MYGLOBALS
            );

%MYFUNCS = (
            'i_type2'   => 'ifType',
            'e_map'     => 'entAliasMappingIdentifier',
            'e_name'    => 'entPhysicalName',
            'e_class'   => 'entPhysicalClass',
            'e_parent'  => 'entPhysicalContainedIn',
            'e_descr'   => 'entPhysicalDescr',
            'e_type'    => 'entPhysicalVendorType',
            'e_model'   => 'entPhysicalModelName',
            'e_hwver'   => 'entPhysicalHardwareRev',
            'e_swver'   => 'entPhysicalSoftwareRev',
            'e_fwver'   => 'entPhysicalFirmwareRev',
            'e_serial'  => 'entPhysicalSerialNum',
            # RFC1271
            'l_descr'   => 'logDescription'

           );
%FUNCS   = (
            %SNMP::Info::Layer2::FUNCS,
            %SNMP::Info::MAU::FUNCS,
            %MYFUNCS
        );

%MYMUNGE = (
           );

%MUNGE = (
            # Inherit all the built in munging
            %SNMP::Info::Layer2::MUNGE,
            %SNMP::Info::MAU::MUNGE,
            %MYMUNGE
         );


# Method Overrides

# Some have the serial num in entity mib, some dont.
sub serial {
    my $hp = shift;
    
    # procurve 2xxx have this
    my $serial = $hp->serial1();

    # 4xxx dont
    return undef if $serial =~ /nosuchobject/i;

    return $serial; 
}

sub interfaces {
    my $hp = shift;
    my $interfaces = $hp->i_index();
    my $i_descr    = $hp->i_description(); 

    my %if;
    foreach my $iid (keys %$interfaces){
        my $descr = $i_descr->{$iid};
        next unless defined $descr;
        #$if{$iid} = $iid;
        $if{$iid} = $descr if (defined $descr and length $descr);
    }

    return \%if

}

# e_port maps EntityTable entries to IfTable
sub e_port {
    my $hp = shift;
    my $e_map = $hp->e_map();

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

sub i_type {
    my $hp = shift;
    my $e_descr = $hp->e_descr();
    my $e_port = $hp->e_port();

    # Grab default values to pass through
    my $i_type = $hp->i_type2();

    # Now Stuff in the entity-table values
    foreach my $port (keys %$e_descr){
        my $iid = $e_port->{$port};
        next unless defined $iid;
        my $type = $e_descr->{$port};
        $type =~ s/^HP ?//;
        $i_type->{$iid} = $type;
    }
    
    return $i_type;

}

sub i_name {
    my $hp = shift;
    my $i_alias    = $hp->i_alias();
    my $e_name     = $hp->e_name();
    my $e_port     = $hp->e_port();

    my %i_name;

    foreach my $port (keys %$e_name){
        my $iid = $e_port->{$port};
        next unless defined $iid;
        my $alias = $i_alias->{$iid};
        next unless defined $iid;
        $i_name{$iid} = $e_name->{$port};

        # Check for alias
        $i_name{$iid} = $alias if (defined $alias and length($alias));
    }
    
    return \%i_name;
}

sub vendor {
    return 'hp';
}

sub log {
    my $hp=shift;

    my $log = $hp->l_descr();

    my $logstring = undef;

    foreach my $val (values %$log){
        next if $val =~ /^Link\s+(Up|Down)/;
        $logstring .= "$val\n"; 
    }

    return $logstring; 
}

sub slots {
    my $hp=shift;
    
    my $e_name = $hp->e_name();

    return undef unless defined $e_name;

    my $slots;
    foreach my $slot (keys %$e_name) {
        $slots++ if $e_name->{$slot} =~ /slot/i;
    }

    return $slots;
}

#sub fan {
#    my $hp = shift;
#
#    my %ents = reverse %{$hp->e_name()};
#
#    my $fan = $ents{'Fan'};
#
#}

sub i_duplex {
    my $hp = shift;

    my $mau_index = $hp->mau_index();
    my $mau_link = $hp->mau_link();

    my %i_duplex;
    foreach my $mau_port (keys %$mau_link){
        my $iid = $mau_index->{$mau_port};
        next unless defined $iid;

        my $linkoid = $mau_link->{$mau_port};
        my $link = &SNMP::translateObj($linkoid);
        next unless defined $link;

        my $duplex = undef;

        if ($link =~ /fd$/i) {
            $duplex = 'full';
        } elsif ($link =~ /hd$/i){
            $duplex = 'half';
        }

        $i_duplex{$iid} = $duplex if defined $duplex;
    }
    return \%i_duplex;
}


sub i_duplex_admin {
    my $hp = shift;

    my $interfaces   = $hp->interfaces();
    my $mau_index    = $hp->mau_index();
    my $mau_auto     = $hp->mau_auto();
    my $mau_autostat = $hp->mau_autostat();
    my $mau_typeadmin = $hp->mau_type_admin();
    my $mau_autosent = $hp->mau_autosent();

    my %mau_reverse = reverse %$mau_index;

    my %i_duplex_admin;
    foreach my $iid (keys %$interfaces){
        my $mau_index = $mau_reverse{$iid};
        next unless defined $mau_index;

        my $autostat = $mau_autostat->{$mau_index};
        
        # HP25xx has this value
        if (defined $autostat and $autostat =~ /enabled/i){
            $i_duplex_admin{$iid} = 'auto';
            next;
        } 
        
        my $type = $mau_autosent->{$mau_index};
    
        next unless defined $type;

        if ($type == 0) {
            $i_duplex_admin{$iid} = 'none';
            next;
        }

        my $full = $hp->_isfullduplex($type);
        my $half = $hp->_ishalfduplex($type);

        if ($full and !$half){
            $i_duplex_admin{$iid} = 'full';
        } elsif ($half) {
            $i_duplex_admin{$iid} = 'half';
        } 
    } 
    
    return \%i_duplex_admin;
}

#sub i_up_admin {
#    my $hp = shift;
#    
#    my $mau_index    = $hp->mau_index();
#    my $mau_status = $hp->mau_status();
#
#    my %i_up_admin;
#    foreach my $mau_port (keys %$mau_status){
#        my $iid = $mau_index->{$mau_port};
#        next unless defined $iid;
#        my $status = $mau_status->{$mau_port};
#        
#        $i_up_admin{$iid} = ($status =~ /shutdown/i) ? 
#                            'down' : 'up';
#    }
#
#    return \%i_up_admin;  
#
#}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::HP - SNMP Interface to HP Procurve Switches

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a 
HP device through SNMP.  Information is stored in a number of 
MIB's such as IF-MIB, ENTITY-MIB, RFC1271-MIB, HP-ICF-OID, MAU-MIB

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 my $hp = new SNMP::Info::Layer2::HP(DestHost  => 'router' , 
                              Community => 'public' ); 

=head1 CREATING AN OBJECT

=over

=item  new SNMP::Info::Layer2::HP()

Arguments passed to new() are passed on to SNMP::Session::new()
    

    my $hp = new SNMP::Info::Layer2::HP(
        DestHost => $host,
        Community => 'public',
        Version => 3,...
        ) 
    die "Couldn't connect.\n" unless defined $hp;

=item  $hp->session()

Sets or returns the SNMP::Session object

    # Get
    my $sess = $hp->session();

    # Set
    my $newsession = new SNMP::Session(...);
    $hp->session($newsession);

=item  $hp->all(), $hp->load_all()

Runs each of the HP List methods and returns a hash reference.

$hp->all() will call $hp->load_all() once and then return cahced valued.  
Use $hp->load_all() to reload from the device.

=back

=head1 HP Global Configuration Values

=over

=item $hp->name()
(B<sysName>)

=item $hp->ip()
(B<sysIpAddr>)

=item $hp->netmask()
(B<sysNetMask>)

=item $hp->broadcast()
(B<sysBroadcast>)

=item $hp->location()
(B<sysLocation>)

=item $hp->contact()
(B<sysContact>)

=item $hp->description()
(B<sysDescr>)

=item $hp->layers()
(B<sysServices>)

=item $hp->serial()
(B<chassisSerialNumberString>)

=item $hp->model()
(B<chassisModel>)

=item $hp->ps1_type()
(B<chassisPs1Type>)

=item $hp->ps2_type()
(B<chassisPs2Type>)

=item $hp->ps1_status()
(B<chassisPs1Status>)

=item $hp->ps2_status()
(B<chassisPs2Status>)

=item $hp->slots()
(B<chassisNumSlots>)

=item $hp->fan()
(B<chassisFanStatus>)

=back

=head1 CATALYST TABLE ENTRIES

=head2 Module table

=over

=item $hp->m_type(), $hp->load_m_type()
(B<moduleType>)

=item $hp->m_model(), $hp->load_m_model()
(B<moduleModel>)

=item $hp->m_serial(), $hp->load_m_serial()
(B<moduleSerialNumber>)

=item $hp->m_status(), $hp->load_m_status()
(B<moduleStatus>)

=item $hp->m_name(), $hp->load_m_name()
(B<moduleName>)

=item $hp->m_ports(), $hp->load_m_ports()
(B<moduleNumPorts>)

=item $hp->m_ports_status(), $hp->load_m_ports_status()
 Returns a list of space separated status strings for the ports.
   To see the status of port 4 :
        @ports_status = split(' ', $hp->m_ports_status() );
        $port4 = $ports_status[3];

(B<modulePortStatus>)

=item $hp->m_ports_hwver(), $hp->load_m_ports_hwver()
(B<moduleHwVersion>)

=item $hp->m_ports_fwver(), $hp->load_m_ports_fwver()
(B<moduleFwVersion>)

=item $hp->m_ports_swver(), $hp->load_m_ports_swver()
(B<moduleSwVersion>)

=item $hp->m_ports_ip(), $hp->load_m_ports_ip()
(B<moduleIPAddress>)

=item $hp->m_ports_sub1(), $hp->load_m_ports_sub1()
(B<moduleSubType>)

=item $hp->m_ports_sub2(), $hp->load_m_ports_sub2()
(B<moduleSubType2>)


=back

=head2 Port Entry Table

=over

=item $hp->p_name(), $hp->load_p_name()
(B<portName>)

=item $hp->p_type(), $hp->load_p_type()
(B<portType>)

=item $hp->p_status(), $hp->load_p_status()
(B<portOperStatus>)

=item $hp->p_status2(), $hp->load_p_status2()
(B<portAdditionalStatus>)

=item $hp->p_speed(), $hp->load_p_speed()
(B<portAdminSpeed>)

=item $hp->p_duplex(), $hp->load_p_duplex()
(B<portDuplex>)

=item $hp->p_port(), $hp->load_p_port()
(B<portIfIndex>)

=back

=head2 VLAN Entry Table

ftp://ftp.cisco.com/pub/mibs/supportlists/wsc5000/wsc5000-communityIndexing.html

=over

=item $hp->v_state(), $hp->load_v_state()
(B<vtpVlanState>)

=item $hp->v_type(), $hp->load_v_type()
(B<vtpVlanType>)

=item $hp->v_name(), $hp->load_v_name()
(B<vtpVlanName>)

=item $hp->v_mtu(), $hp->load_v_mtu()
(B<vtpVlanMtu>)

=back
