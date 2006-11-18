# SNMP::Info::Layer3::Foundry - SNMP Interface to Foundry devices
# Max Baker
#
# Copyright (c) 2004,2005 Max Baker changes from version 0.8 and beyond.
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

package SNMP::Info::Layer3::Foundry;
# $Id$

use strict;

use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::FDP;

use vars qw/$VERSION $DEBUG %GLOBALS %FUNCS $INIT %MIBS %MUNGE/;

$VERSION = '1.04';

@SNMP::Info::Layer3::Foundry::ISA = qw/SNMP::Info::Layer3 SNMP::Info::FDP Exporter/;
@SNMP::Info::Layer3::Foundry::EXPORT_OK = qw//;

%MIBS = ( %SNMP::Info::Layer3::MIBS,
          %SNMP::Info::FDP::MIBS,
          'FOUNDRY-SN-ROOT-MIB' => 'foundry',
          'FOUNDRY-SN-AGENT-MIB' => 'snChasPwrSupplyDescription',
          # IP-FORWARD-MIB
          # ETHERLIKE-MIB
          # RFC1398-MIB
          # RMON-MIB
          # IF-MIB
        );

%GLOBALS = (
            %SNMP::Info::Layer3::GLOBALS,
            %SNMP::Info::FDP::GLOBALS,
            'mac'        => 'ifPhysAddress.1',
            'chassis'    => 'entPhysicalDescr.1',
            'serial1'    => 'snChasSerNum',
            'temp'       => 'snChasActualTemperature',
            'ps1_type'   => 'snChasPwrSupplyDescription.1',
            'ps1_status' => 'snChasPwrSupplyOperStatus.1',
            'fan'        => 'snChasFanOperStatus.1',
            #'serial'   => 'enterprises.1991.1.1.1.1.2.0',
            #'temp'     => 'enterprises.1991.1.1.1.1.18.0',
            #'ps1_type' => 'enterprises.1991.1.1.1.2.1.1.2.1',
            #'ps1_status' => 'enterprises.1991.1.1.1.2.1.1.3.1',
            #'fan'   => 'enterprises.1991.1.1.1.3.1.1.3.1'
           );

%FUNCS   = (
            %SNMP::Info::Layer3::FUNCS,
            %SNMP::Info::FDP::FUNCS,
            'i_name2'    => 'ifName',
            # FOUNDRY-MIB
            #   snSwPortInfoTable - Switch Port Information Group
            'sw_index'    => 'snSwPortIfIndex',
            'sw_duplex'   => 'snSwPortInfoChnMode',
            'sw_type'     => 'snSwPortInfoMediaType',
            'sw_speed'    => 'snSwPortInfoSpeed',
           );

%MUNGE = (
            # Inherit all the built in munging
            %SNMP::Info::Layer3::MUNGE,
            %SNMP::Info::FDP::MUNGE,
         );


# Method OverRides

sub bulkwalk_no { 1; }

# Add our i_aliases if they are set (manually)
sub i_name {
    my $foundry = shift;
    my $i_name = $foundry->i_name2();

    my $i_alias = $foundry->i_alias();

    foreach my $iid (keys %$i_name){
        my $alias = $i_alias->{$iid};
        next unless defined $alias;
        next unless length($alias);
        $i_name->{$iid} = $i_alias->{$iid};
    }

    return $i_name;
}

sub i_ignore {
    my $foundry = shift;
    
    my $interfaces = $foundry->interfaces();
    my $i_descr    = $foundry->i_descr();

    my %i_ignore;
    foreach my $if (keys %$interfaces) {
        # lo -> cisco aironet 350 loopback
        if ($interfaces->{$if} =~ /(tunnel|loopback|lo|lb|null)/i){
            $i_ignore{$if}++;
        }
    }
    return \%i_ignore;
}

sub i_duplex {
    my $foundry = shift;
    my $sw_index = $foundry->sw_index();
    my $sw_duplex= $foundry->sw_duplex();

    unless (defined $sw_index and defined $sw_duplex){
       return $foundry->SUPER::i_duplex(); 
    }
    
    my %i_duplex;
    foreach my $sw_port (keys %$sw_duplex){
        my $iid = $sw_index->{$sw_port};
        my $duplex = $sw_duplex->{$sw_port};
        next if $duplex =~ /none/i;
        $i_duplex{$iid} = 'half' if $duplex =~ /half/i;
        $i_duplex{$iid} = 'full' if $duplex =~ /full/i;
    }
    return \%i_duplex;
}

sub i_type {
    my $foundry = shift;
    my $sw_index = $foundry->sw_index();
    my $sw_type= $foundry->sw_type();

    unless (defined $sw_index and defined $sw_type){
       return $foundry->SUPER::i_type(); 
    }
    
    my %i_type;
    foreach my $sw_port (keys %$sw_type){
        my $iid = $sw_index->{$sw_port};
        my $type = $sw_type->{$sw_port};
        next unless defined $type;
        $i_type{$iid} = $type;
    }
    return \%i_type;
}

sub i_speed {
    my $foundry = shift;
    my $sw_index = $foundry->sw_index();
    my $sw_speed= $foundry->sw_speed();

    unless (defined $sw_index and defined $sw_speed){
       return $foundry->SUPER::i_speed(); 
    }
    
    my %i_speed;
    foreach my $sw_port (keys %$sw_speed){
        my $iid = $sw_index->{$sw_port};
        my $speed = $sw_speed->{$sw_port};
        next unless defined $speed;
        $speed = 'auto'     if $speed =~ /auto/i;
        $speed = '10 Mbps'  if $speed =~ /s10m/i;
        $speed = '100 Mbps' if $speed =~ /s100m/i;
        $speed = '1.0 Gbps' if $speed =~ /s1g/i;
        $speed = '45 Mbps' if $speed =~ /s45M/i;
        $speed = '155 Mbps' if $speed =~ /s155M/i;
        $i_speed{$iid} = $speed;
    }
    return \%i_speed;
}

# $foundry->model() - looks for xxnnnn in the description
sub model {
    my $foundry = shift;
    my $id = $foundry->id();
    my $desc = $foundry->description();
    my $model = &SNMP::translateObj($id);

    $model = $1 if $desc =~ /\s+([a-z]{2}\d{4})\D/i;
    $model = $1 if $desc =~ /\b(FW[A-Z\d]+)/;

    $model =~ s/^sn//;

    return $model;
}

sub os {
    my $foundry = shift;
    my $descr = $foundry->description();
    if ($descr =~ m/IronWare/i) {
        return 'IronWare';
    }

    return 'foundry';
}
sub os_ver {
    my $foundry = shift;
    my $os_version = $foundry->os_version();
    return $os_version if defined $os_version;
    # Some older ones don't have this value,so we cull it from the description
    my $descr = $foundry->description();
    if ($descr =~ m/Version (\d\S*)/) {
        return $1;
    }
    return undef;
}


# $foundry->interfaces() - Map the Interfaces to their physical names
sub interfaces {
    my $foundry = shift;
    my $interfaces = $foundry->i_index();
    
    my $descriptions = $foundry->i_description();

    my %ifs = ();
    foreach my $iid (keys %$interfaces){
        $ifs{$iid} = $descriptions->{$iid}; 
    }
    
    return \%ifs;
}

sub vendor {
    return 'foundry';
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Foundry - Perl5 Interface to Foundry FastIron Network Devices

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $foundry = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 1
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $foundry->class();

 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

This module provides limited functionality from some L2+L3 and L3 Foundry devices.

Specifically designed for a FI4802. Works on a FWSX424.

For speed or debugging purposes you can call the subclass directly, but not after determining
a more specific class using the method above.  Turn off the AutoSpecify flag.

 my $foundry = new SNMP::Info::Layer3::Foundry(...);

=head2 Inherited Classes

=over

=item SNMP::Info


=back

=head2 Required MIBs

=over

=item FOUNDRY-SN-ROOT-MIB

=item Inherited Classes' MIBs

See classes listed above for their required MIBs.

=back

The Foundry MIBS can be downloaded from www.mibdepot.com and ??

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $foundry->model()

Returns model type.  Checks $foundry->id() against the 
FOUNDRY-SN-ROOT-MIB and then parses out xxNNNN

=item $foundry->vendor()

Returns 'foundry' :)

=item $foundry->mac()

Returns MAC Address of root port.

(B<ifPhysAddress.1>)

=item $foundry->chassis()

Returns Chassis type.

(B<entPhysicalDescr.1>)

=item $foundry->serial()

Returns serial number of device.

(B<snChasSerNum>)

=item $foundry->temp()

Returns the chassis temperature

(B<snChasActualTemperature>)

=item $foundry->ps1_type()

Returns the Description for the power supply

(B<snChasPwrSupplyDescription.1>)

=item $foundry->ps1_status()

Returns the status of the power supply.

(B<snChasPwrSupplyOperStatus.1>)

=item $foundry->fan()

Returns the status of the chassis fan.

(B<snChasFanOperStatus.1>)

=back

=head2 Globals imported from SNMP::Info

See documentation in L<SNMP::Info/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $foundry->interfaces()

Returns reference to hash of interface names to iids.

Uses B<ifDescr>.

=item $foundry->i_name()

Returns reference to hash of interface names.  
Trys for B<ifAlias> and Defaults to B<ifName>

=item $foundry->i_ignore()

Returns reference to hash of interfaces to be ignored.

Ignores interfaces with descriptions of  tunnel,loopback,null 

=item $foundry->i_duplex()

Returns reference to hash of interface link duplex status. 

Crosses $foundry->sw_duplex() with $foundry->sw_index()

=item $foundry->i_type()

Returns reference to hash of interface types.

Crosses $foundry->sw_type() with $foundry->sw_index()

=item $foundry->i_speed()

Returns reference to hash of interface speeds .

Crosses $foundry->sw_speeD() with $foundry->sw_index() and 
does a little munging.

=back

=head2 Foundry Switch Port Information Table (B<snSwPortIfTable>)

=over

=item $foundry->sw_index()

Returns reference to hash.  Maps Table to Interface IID. 

(B<snSwPortIfIndex>)

=item $foundry->sw_duplex()

Returns reference to hash.   Current duplex status for switch ports. 

(B<snSwPortInfoChnMode>)

=item $foundry->sw_type()

Returns reference to hash.  Current Port Type .

(B<snSwPortInfoMediaType>)

=item $foundry->sw_speed()

Returns reference to hash.  Current Port Speed. 

(B<snSwPortInfoSpeed>)

=back

=head2 Table Methods imported from SNMP::Info

See documentation in L<SNMP::Info/"TABLE METHODS"> for details.

=cut
