# SNMP::Info::Layer2::C1900
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

package SNMP::Info::Layer2::C1900;
$VERSION = 0.6;
# $Id$
use strict;

use Exporter;
use SNMP::Info::Layer2;

@SNMP::Info::Layer2::C1900::ISA = qw/SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::C1900::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD $INIT $DEBUG/;

# Set for No CDP
%GLOBALS = (
            %SNMP::Info::Layer2::GLOBALS,
            'c1900_flash_status'    => 'upgradeFlashBankStatus',
            );

%FUNCS   = (%SNMP::Info::Layer2::FUNCS,
            'i_type2'              => 'ifType',
            'i_name2'              => 'ifName',
            # ESSWITCH-MIB
            'c1900_p_index'        => 'swPortIndex',
            'c1900_p_ifindex'      => 'swPortIfIndex',
            'c1900_p_duplex'       => 'swPortDuplexStatus', 
            'c1900_p_duplex_admin' => 'swPortFullDuplex', 
            'c1900_p_name'         => 'swPortName', 
            'c1900_p_up_admin'     => 'swPortAdminStatus', 
            'c1900_p_type'         => 'swPortMediaCapability',
            'c1900_p_media'        => 'swPortConnectorType',
            );

%MIBS    = (
            %SNMP::Info::Layer2::MIBS,
            # Also known as the ESSWITCH-MIB
            'STAND-ALONE-ETHERNET-SWITCH-MIB' =>  'series2000'
            );

%MUNGE   = (%SNMP::Info::Layer2::MUNGE,
            );

sub vendor {
    return 'cisco';
}
sub os {
    return 'catalyst';
}

sub os_ver {
    my $c1900 = shift;

    # Check for superclass one
    my $os_ver = $c1900->SUPER::os_ver();
    return $os_ver if defined $os_ver;
    
    my $c1900_flash_status = $c1900->c1900_flash_status();
    return undef unless defined $c1900_flash_status;

    if ($c1900_flash_status =~ m/V(\d+\.\d+(\.\d+)?)/){
        return $1;
    }  
    return undef;
}

sub interfaces {
    my $c1900 = shift;
    my $i_descr = $c1900->i_description();

    foreach my $iid (keys %$i_descr){
        $i_descr->{$iid} =~ s/\s*$//;
    }
    return $i_descr;
}

sub i_duplex {
    my $c1900 = shift;
    
    my $interfaces     = $c1900->interfaces();
    my $c1900_p_index  = $c1900->c1900_p_index();
    my $c1900_p_duplex = $c1900->c1900_p_duplex();
 

    my %reverse_1900 = reverse %$c1900_p_index;

    my %i_duplex;
    foreach my $if (keys %$interfaces){
        my $port_1900 = $reverse_1900{$if};
        next unless defined $port_1900;
        my $duplex = $c1900_p_duplex->{$port_1900};
        next unless defined $duplex; 
    
        $duplex = 'half' if $duplex =~ /half/i;
        $duplex = 'full' if $duplex =~ /full/i;
        $i_duplex{$if}=$duplex; 
    }
    return \%i_duplex;
}

sub i_duplex_admin {
    my $c1900 = shift;
    
    my $interfaces     = $c1900->interfaces();
    my $c1900_p_index  = $c1900->c1900_p_index();
    my $c1900_p_admin  = $c1900->c1900_p_duplex_admin();
 

    my %reverse_1900 = reverse %$c1900_p_index;

    my %i_duplex_admin;
    foreach my $if (keys %$interfaces){
        my $port_1900 = $reverse_1900{$if};
        next unless defined $port_1900;
        my $duplex = $c1900_p_admin->{$port_1900};
        next unless defined $duplex; 
    
        $duplex = 'half' if $duplex =~ /disabled/i;
        $duplex = 'full' if $duplex =~ /flow control/i;
        $duplex = 'full' if $duplex =~ /enabled/i;
        $duplex = 'auto' if $duplex =~ /auto/i;
        $i_duplex_admin{$if}=$duplex; 
    }
    return \%i_duplex_admin;
}

sub i_type {
    my $c1900 = shift;

    my $i_type        = $c1900->i_type2();
    my $c1900_p_index = $c1900->c1900_p_index();
    my $c1900_p_type  = $c1900->c1900_p_type();
    my $c1900_p_media = $c1900->c1900_p_media();

    foreach my $p_iid (keys %$c1900_p_index){
        my $port  = $c1900_p_index->{$p_iid};
        my $type  = $c1900_p_type->{$p_iid};
        my $media = $c1900_p_media->{$p_iid};

        next unless defined $port;
        next unless defined $type;
        next unless defined $media;

        $i_type->{$port} = "$type $media";
    }

    return $i_type;
}

sub i_name {
    my $c1900 = shift;
    my $i_name = $c1900->i_name2();
    my $c1900_p_name = $c1900->c1900_p_name();
    
    foreach my $port (keys %$c1900_p_name){
        my $name = $c1900_p_name->{$port};
        next unless defined $name;
        next unless $name !~ /^\s*$/;
        $i_name->{$port} = $name;
    }
    
    return $i_name;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::C1900 - Perl5 Interface to SNMP data from Cisco Catlyst 1900 Network Switches running CatOS

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $c1900 = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 1
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $c1900->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a Catalyst 1900 device through SNMP. 
See SNMP::Info for full documentation

Note that most of these devices only talk SNMP version 1, but not all.

For speed or debugging purposes you can call the subclass directly, but not after determining
a more specific class using the method above. 

 my $c1900 = new SNMP::Info::Layer2::C1900(...);

=head2 Inherited classes

=over

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

=over

=item STAND-ALONE-ETHERNET-SWITCH-MIB (ESSWITCH-MIB)

ESSWITCH-MIB is included in the Version 1 MIBS from Cisco.

They can be found at ftp://ftp.cisco.com/pub/mibs/v1/v1.tar.gz

=item Inherited Classes' MIBs

MIBs listed in SNMP::Info::Layer2

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $c1900->c1900_flash_status()

Usually contains the version of the software loaded in flash.
Used by os_ver()

B<STAND-ALONE-ETHERNET-SWITCH-MIB::upgradeFlashBankStatus>

=item $c1900->os()

Returns 'catalyst'

=item $c1900->os_ver()

Returns CatOS version if obtainable.  First tries to use 
SNMP::Info::CiscoStats->os_ver() .  If that fails then it 
checks for the presence of $c1900->c1900_flash_status() and culls
the version from there.

=item $c1900->vendor()

Returns 'cisco' :)

=back

=head2 Globals imported from SNMP::Info::Layer2

See documentation in SNMP::Info::Layer2 for details.

=head1 TABLE ENTRIES

=head2 Overrides

=over

=item $c1900->i_duplex()

Returns reference to map of IIDs to current link duplex

Crosses $c1900->c1900_p_index() with $c1900->c1900_p_duplex;

=item $c1900->i_duplex_admin()

Returns reference to hash of IIDs to admin duplex setting

Crosses $c1900->c1900_p_index() with $c1900->c1900_p_duplex_admin;

=item $c1900->i_name()

Crosses ifName with c1900_p_name() and returns the human set port name if exists.

=item $c1900->i_type()

Returns reference to hash of IID to port type

Takes the default ifType and overrides it with 

c1900_p_type() and c1900_p_media()  if they exist.

=back

=head2 STAND-ALONE-ETHERNET-SWITCH-MIB Switch Port Table Entries:

=over

=item $c1900->c1900_p_index()

Maps the Switch Port Table to the IID

B<swPortIfIndex>

=item $c1900->c1900_p_duplex()

Gives Port Duplex Info

B<swPortDuplexStatus>

=item $c1900->c1900_p_duplex_admin()

Gives admin setting for Duplex Info

B<swPortFullDuplex>

=item $c1900->c1900_p_name()

Gives human set name for port 

B<swPortName>

=item $c1900->c1900_p_up_admin()

Gives Admin status of port enabled.

B<swPortAdminStatus>

=item $c1900->c1900_p_type()

Gives Type of port, ie. "general-ethernet"

B<swPortMediaCapability>

=item $c1900->c1900_p_media()

Gives the media of the port , ie "fiber-sc"

B<swPortConnectorType>

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See documentation in SNMP::Info::Layer2 for details.

=cut
