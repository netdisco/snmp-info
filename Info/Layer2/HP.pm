# SNMP::Info::Layer2::HP - SNMP Interface to HP ProCurve Switches
# Max Baker <max@warped.org>
#
# Copyright (c) 2002,2003 Regents of the University of California
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
$VERSION = 0.4;
# $Id$

use strict;

use Exporter;
use SNMP::Info::Layer2;
use SNMP::Info::MAU;
use SNMP::Info::Entity;

use vars qw/$VERSION $DEBUG %GLOBALS %MIBS %FUNCS %PORTSTAT %MODEL_MAP %MUNGE $INIT/ ;

@SNMP::Info::Layer2::HP::ISA = qw/SNMP::Info::Layer2 SNMP::Info::MAU SNMP::Info::Entity Exporter/;
@SNMP::Info::Layer2::HP::EXPORT_OK = qw//;

# See SNMP::Info for the details of these data structures and interworkings.
$INIT = 0;

%MIBS = ( %SNMP::Info::Layer2::MIBS,
          %SNMP::Info::MAU::MIBS,
          %SNMP::Info::Entity::MIBS,
          'RFC1271-MIB' => 'logDescription',
          'HP-ICF-OID'  => 'hpSwitch4000',
        );

%GLOBALS = (
            %SNMP::Info::Layer2::GLOBALS,
            %SNMP::Info::MAU::GLOBALS,
            %SNMP::Info::Entity::GLOBALS,
            'serial1' => 'entPhysicalSerialNum.1',
           );

%FUNCS   = (
            %SNMP::Info::Layer2::FUNCS,
            %SNMP::Info::MAU::FUNCS,
            %SNMP::Info::Entity::FUNCS,
            'i_type2'   => 'ifType',
            # RFC1271
            'l_descr'   => 'logDescription'
           );

%MUNGE = (
            # Inherit all the built in munging
            %SNMP::Info::Layer2::MUNGE,
            %SNMP::Info::MAU::MUNGE,
            %SNMP::Info::Entity::MUNGE
         );

%MODEL_MAP = ( 
               'J4812A' => '2512',
               'J4819A' => '5308XL',
               'J4813A' => '2524',
               'J4805A' => '5304XL',
               'J4815A' => '3324XL',
               'J4865A' => '4108GL',
               'J4887A' => '4104GL',
               'J4874A' => '9315',
             );

# Method Overrides

# Lookup model number, and translate the part number to the common number
sub model {
    my $hp = shift;
    my $id = $hp->id();
    my $model = &SNMP::translateObj($id);
    
    $model =~ s/^hpswitch//i;

    return defined $MODEL_MAP{$model} ? $MODEL_MAP{$model} : $model;
}

# Some have the serial num in entity mib, some dont.
sub serial {
    my $hp = shift;
    
    # procurve 2xxx have this
    my $serial = $hp->serial1();

    return undef unless defined $serial;
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
        $if{$iid} = $descr if (defined $descr and length $descr);
    }

    return \%if

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

1;
__END__

=head1 NAME

SNMP::Info::Layer2::HP - SNMP Interface to HP Procurve Switches

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a 
HP device through SNMP.  Information is stored in a number of 
MIB's such as IF-MIB, ENTITY-MIB, RFC1271-MIB, HP-ICF-OID, MAU-MIB

MIBs required:

=over

=item RFC1271-MIB

=item HP-ICF-OID

=item ENTITY-MIB

=back

HP MIBs can be found at http://www.hp.com/rnd/software

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 my $hp = new SNMP::Info::Layer2::HP(DestHost  => 'router' , 
                                     Community => 'public' ); 

 See SNMP::Info and SNMP::Info::Layer2 for all the inherited methods.

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

=back

=head1 ChangeLog

Version 0.4 - Removed ENTITY-MIB e_*() methods to separate sub-class


=head1 HP Global Configuration Values

=over

=item $hp->log()

Returns all the log entries from the switch's log that are not Link up or down messages.

=item $hp->model()

Returns the model number of the HP Switch.  Will translate between the HP Part number and 
the common model number with this map :

 %MODEL_MAP = ( 
               'J4812A' => '2512',
               'J4819A' => '5308XL',
               'J4813A' => '2524',
               'J4805A' => '5304XL',
               'J4815A' => '3324XL',
               'J4865A' => '4108GL',
               'J4887A' => '4104GL',
               'J4874A' => '9315',
              );

=item $hp->serial()

Returns serial number if available through SNMP

=item $hp->slots()

Returns number of entries in $hp->e_name that have 'slot' in them.

=item $hp->vendor()

hp

=back

=head1 Overriden Methods from SNMP::Info::Layer2

=over

=item $hp->interfaces() 

=item $hp->i_duplex()

Maps $hp->mau_index() with $hp->mau_link().  Methods inherited from
SNMP::Info::MAU.

=item $hp->i_duplex_admin()

Maps $hp->mau_index() with $hp->mau_auto(), $hp->mau_autostat(),
$hp->typeadmin(), and $mau_autosent().  Methods inherited from
SNMP::Info::MAU.

=item $hp->i_name()

Crosses i_name() with $hp->e_name() using $hp->e_port() and i_alias()

=item $hp->i_type()

Crosses i_type() with $hp->e_descr() using $hp->e_port()

=back
