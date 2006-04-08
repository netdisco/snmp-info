# SNMP::Info::Airespace
# Eric Miller
# $Id$
#
# Copyright (c) 2005 Eric Miller
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

package SNMP::Info::Airespace;
$VERSION = '1.01';
use strict;

use Exporter;
use SNMP::Info;

@SNMP::Info::Airespace::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::Airespace::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD $INIT $DEBUG/;

%MIBS    = (
            %SNMP::Info::MIBS,
            'AIRESPACE-WIRELESS-MIB'     => 'bsnAPName',
            'AIRESPACE-SWITCHING-MIB'    => 'agentInventorySerialNumber',
            );

%GLOBALS = (
            %SNMP::Info::GLOBALS,
            'serial'     => 'agentInventorySerialNumber',
            'os_ver'     => 'agentInventoryProductVersion',
            );

%FUNCS   = (
            %SNMP::Info::FUNCS,
            'i_index2'            => 'ifIndex',
            'i_name2'             => 'ifName',
            'i_description2'      => 'ifDescr',
            # AIRESPACE-WIRELESS-MIB::bsnAPTable
            'airespace_ap_mac'        => 'bsnAPDot3MacAddress',
            'airespace_ap_name'       => 'bsnAPName',
            'airespace_ap_ip'         => 'bsnApIpAddress',
            'airespace_ap_loc'        => 'bsnAPLocation',
            'airespace_ap_model'      => 'bsnAPModel',
            'airespace_ap_serial'     => 'bsnAPSerialNumber',
            # AIRESPACE-WIRELESS-MIB::bsnMobileStationTable
            'fw_port'                 => 'bsnMobileStationAPMacAddr',
            'fw_mac'                  => 'bsnMobileStationMacAddress',
            # AIRESPACE-SWITCHING-MIB::agentPortConfigTable
            'airespace_duplex_admin'  => 'agentPortPhysicalMode',
            'airespace_duplex'        => 'agentPortPhysicalStatus',
            );

%MUNGE   = (
          %SNMP::Info::MUNGE,
          # Add ones for our class
          'airespace_ap_mac'  => \&SNMP::Info::munge_mac,
          'fw_port'           => \&SNMP::Info::munge_mac,
            );

sub layers {
    return '00000011';
}

# Wirless switches do not support ifMIB requirements for get MAC
# and port status

sub i_index {
    my $airespace = shift;
    my $i_index   = $airespace->i_index2();
    my $ap_index  = $airespace->airespace_ap_mac();
    
    my %if_index;
    foreach my $iid (keys %$i_index){
        my $index = $i_index->{$iid};
        next unless defined $index;

        $if_index{$iid} = $index;
    }

    # Get Attached APs as Interfaces
    foreach my $ap_id (keys %$ap_index){
        my $ap_index = $ap_index->{$ap_id};
        next unless defined $ap_index;

        $if_index{$ap_id} = $ap_index;
    }
    return \%if_index;
}

sub interfaces {
    my $airespace  = shift;
    my $i_index    = $airespace->i_index();
    my $ap_index   = $airespace->airespace_ap_mac();
    
    my %if;
    foreach my $iid (keys %$i_index){
        my $index = $i_index->{$iid};
        next unless defined $index;

        if ($index =~ /^\d+$/ ) {
          $if{$index} = "1.$index";
        }

        elsif ($index =~ /(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/) {
          my $ap = $ap_index->{$iid};
          next unless defined $ap;
          $if{$index} = $ap;
        }           

        else {
            next;
        }
    }
    return \%if;
}

sub i_name {
    my $airespace  = shift;
    my $i_index    = $airespace->i_index();
    my $i_name2    = $airespace->i_name2();
    my $ap_name    = $airespace->airespace_ap_name();
    
    my %i_name;
    foreach my $iid (keys %$i_index){
        my $index = $i_index->{$iid};
        next unless defined $index;

        if ($index =~ /^\d+$/ ) {
          my $name = $i_name2->{$iid};
          next unless defined $name;
          $i_name{$index} = $name;
        }

        elsif ($index =~ /(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/) {
          my $name = $ap_name->{$iid};
          next unless defined $name;
          $i_name{$index} = $name;
        }           
        else {
            next;
        }
    }
  return \%i_name;
}

sub i_description {
    my $airespace = shift;
    my $i_index  = $airespace->i_index();
    my $i_descr  = $airespace->i_description2();
    my $ap_loc   = $airespace->airespace_ap_loc();


    my %descr;
    foreach my $iid (keys %$i_index){
        my $index = $i_index->{$iid};
        next unless defined $index;

        if ($index =~ /^\d+$/ ) {
          my $descr = $i_descr->{$iid};
          next unless defined $descr;
          $descr{$index} = $descr;
        }

        elsif ($index =~ /(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/) {
          my $name = $ap_loc->{$iid};
          next unless defined $name;
          $descr{$index} = $name;
        }           
        else {
          next;
        }
    }
    return \%descr;
}

sub i_duplex {
    my $airespace = shift;
    
    my $interfaces  = $airespace->interfaces();
    my $ap_duplex   = $airespace->airespace_duplex();

    my %i_duplex;
    foreach my $if (keys %$interfaces){
        my $duplex = $ap_duplex->{$if};
        next unless defined $duplex; 
    
        $duplex = 'half' if $duplex =~ /half/i;
        $duplex = 'full' if $duplex =~ /full/i;
        $duplex = 'auto' if $duplex =~ /auto/i;
        $i_duplex{$if}=$duplex; 
    }
    return \%i_duplex;
}

sub i_duplex_admin {
    my $airespace = shift;
    
    my $interfaces       = $airespace->interfaces();
    my $ap_duplex_admin  = $airespace->airespace_duplex_admin();

    my %i_duplex_admin;
    foreach my $if (keys %$interfaces){
        my $duplex = $ap_duplex_admin->{$if};
        next unless defined $duplex; 
    
        $duplex = 'half' if $duplex =~ /half/i;
        $duplex = 'full' if $duplex =~ /full/i;
        $duplex = 'auto' if $duplex =~ /auto/i;
        $i_duplex_admin{$if}=$duplex; 
    }
    return \%i_duplex_admin;
}

  
# Wireless switches do not support the standard Bridge MIB
sub bp_index {
    my $airespace = shift;
    my $i_index   = $airespace->i_index2();
    my $ap_index  = $airespace->airespace_ap_mac();
    
    my %bp_index;
    foreach my $iid (keys %$i_index){
        my $index = $i_index->{$iid};
        next unless defined $index;

        $bp_index{$iid} = $index;
    }

    # Get Attached APs as Interfaces
    foreach my $ap_id (keys %$ap_index){
        my $ap_index = $ap_index->{$ap_id};
        next unless defined $ap_index;

        $bp_index{$ap_index} = $ap_index;
    }
    return \%bp_index;
}

1;
__END__

=head1 NAME

SNMP::Info::Airespace - SNMP Interface to Airespace wireless switches

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

    my $airespace = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 

    or die "Can't connect to DestHost.\n";

    my $class = $airespace->class();
    print " Using device sub class : $class\n";

=head1 DESCRIPTION

SNMP::Info::Airespace is a subclass of SNMP::Info that provides an interface
to C<AIRESPACE-WIRELESS-MIB> and C<AIRESPACE-SWITCHING-MIB>.  These MIBs are
used in Airespace wireless switches, as well as, products from Cisco, Nortel,
and Alcatel which are based upon the Airespace platform.

The Airespace platform utilizes intelligent wireless switches which control
thin access points.  The thin access points themselves are unable to be polled
for end station information.

This class emulates bridge functionality for the wireless switch. This enables
end station MAC addresses collection and correlation to the thin access point
the end station is using for communication.

Normally you use or create a subclass of SNMP::Info that inherits this one.  Do not use directly.

For debugging purposes call the class directly as you would SNMP::Info

 my $airespace = new SNMP::Info::Airespace(...);

=head2 Inherited Classes

=over

=item SNMP::Info

=back

=head2 Required MIBs

=over

=item AIRESPACE-WIRELESS-MIB

=item AIRESPACE-SWITCHING-MIB

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $airespace->serial()

(B<agentInventorySerialNumber>)

=item $airespace->os_ver()

(B<agentInventoryProductVersion>)

=back

=head2 Overrides

=over

=item $airespace->layers()

Returns 00000011.  Class emulates Layer 2 functionality for Thin APs through
proprietary MIBs.

=back

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $airespace->i_index()

Returns reference to map of IIDs to Interface index. 

Extends ifIndex to support thin APs as device interfaces.

=item $airespace->interfaces()

Returns reference to map of IIDs to ports.  Thin APs are implemented as device 
interfaces.  The thin AP MAC address is used as the port identifier.

=item $airespace->i_name()

Interface name.  Returns (B<ifName>) for Ethernet interfaces and (B<bsnAPName>)
for thin AP interfaces.

=item $airespace->i_description()

Description of the interface.  Returns (B<ifDescr>) for Ethernet interfaces and 
(B<bsnAPLocation>) for thin AP interfaces.

=item $airespace->i_duplex()

Returns reference to map of IIDs to current link duplex.  Ethernet interfaces only.

=item $airespace->i_duplex_admin()

Returns reference to hash of IIDs to admin duplex setting.  Ethernet interfaces
only.

=item $airespace->bp_index()

Simulates bridge MIB by returning reference to a hash containing the index for
both the keys and values.

=item $airespace->fw_port()

(B<bsnMobileStationAPMacAddr>)

=item $airespace->fw_mac()

(B<bsnMobileStationMacAddress>)

=back

=head2 AIRESPACE AP Table  (B<bsnAPTable>)

=over

=item $airespace->airespace_ap_mac()

(B<bsnAPDot3MacAddress>)

=item $airespace->airespace_ap_name()

(B<bsnAPName>)

=item $airespace->airespace_ap_ip()

(B<bsnApIpAddress>)

=item $airespace->airespace_ap_loc()

(B<bsnAPLocation>)

=item $airespace->airespace_ap_model()

(B<bsnAPModel>)

=item $airespace->airespace_ap_serial()

(B<bsnAPSerialNumber>)

=back

=head2 AIRESPACE Agent Port Config Table (B<agentPortConfigTable>)

=over

=item $airespace->airespace_duplex_admin()

(B<agentPortPhysicalMode>)

=item $airespace->airespace_duplex()

(B<agentPortPhysicalStatus>)

=cut
