# SNMP::Info::Layer2::C2900
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

package SNMP::Info::Layer2::C2900;
$VERSION = 0.1;
use strict;

use Exporter;
use SNMP::Info::Layer2;

@SNMP::Info::Layer2::C2900::ISA = qw/SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::C2900::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD $INIT $DEBUG/;

# Set for No CDP
%GLOBALS = (
            %SNMP::Info::Layer2::GLOBALS
            );

%FUNCS   = (%SNMP::Info::Layer2::FUNCS,
            # C2900PortEntry
            'c2900_p_index' => 'c2900PortIfIndex',
            'c2900_p_duplex'   => 'c2900PortDuplexStatus',
            'c2900_p_duplex_admin'   => 'c2900PortDuplexState',
            'c2900_p_speed_admin'   => 'c2900PortAdminSpeed',
            );

%MIBS    = (
            %SNMP::Info::Layer2::MIBS,
            'CISCO-C2900-MIB' =>  'ciscoC2900MIB'
            );

%MUNGE   = (%SNMP::Info::Layer2::MUNGE,
            );

sub vendor {
    return 'cisco';
}

sub i_duplex {
    my $c2900 = shift;
    
    my $interfaces     = $c2900->interfaces();
    my $c2900_p_index  = $c2900->c2900_p_index();
    my $c2900_p_duplex = $c2900->c2900_p_duplex();
 

    my %reverse_2900 = reverse %$c2900_p_index;

    my %i_duplex;
    foreach my $if (keys %$interfaces){
        my $port_2900 = $reverse_2900{$if};
        next unless defined $port_2900;
        my $duplex = $c2900_p_duplex->{$port_2900};
        next unless defined $duplex; 
    
        $duplex = 'half' if $duplex =~ /half/i;
        $duplex = 'full' if $duplex =~ /full/i;
        $i_duplex{$if}=$duplex; 
    }
    return \%i_duplex;
}

sub i_duplex_admin {
    my $c2900 = shift;
    
    my $interfaces     = $c2900->interfaces();
    my $c2900_p_index  = $c2900->c2900_p_index();
    my $c2900_p_admin = $c2900->c2900_p_duplex_admin();
 

    my %reverse_2900 = reverse %$c2900_p_index;

    my %i_duplex_admin;
    foreach my $if (keys %$interfaces){
        my $port_2900 = $reverse_2900{$if};
        next unless defined $port_2900;
        my $duplex = $c2900_p_admin->{$port_2900};
        next unless defined $duplex; 
    
        $duplex = 'half' if $duplex =~ /half/i;
        $duplex = 'full' if $duplex =~ /full/i;
        $duplex = 'auto' if $duplex =~ /auto/i;
        $i_duplex_admin{$if}=$duplex; 
    }
    return \%i_duplex_admin;
}

# Use i_descritption for port key, cuz i_name can be manually entered.
sub interfaces {
    my $c2900 = shift;
    my $interfaces = $c2900->i_index();
    my $i_descr    = $c2900->i_description(); 

    my %if;
    foreach my $iid (keys %$interfaces){
        my $port = $i_descr->{$iid};
        next unless defined $port;

        $port =~ s/\./\//g if( $port =~ /\d+\.\d+$/);
        $port =~ s/[^\d\/,()\w]+//gi;
    
        $if{$iid} = $port;
    }

    return \%if
}

__END__

=head1 NAME

SNMP::Info::Layer2::C2900 - SNMP Interface to Cisco Catalyst 2900 Network Switches

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a 
C2900 device through SNMP. 

MIBS:  CISCO-C2900-MIB

Inherits all SNMP::Info::Layer2 methods.

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 my $c2900 = new SNMP::Info::Layer2::C2900(DestHost  => 'mycat2900' , 
                              Community => 'public' ); 

=head1 CREATING AN OBJECT

=over

=item  new SNMP::Info::Layer2::C2900()

Arguments passed to new() are passed on to SNMP::Session::new()
    

    my $c2900 = new SNMP::Info::Layer2::C2900(
        DestHost => $host,
        Community => 'public',
        Version => 3,...
        ) 
    die "Couldn't connect.\n" unless defined $c2900;

=item  $c2900->session()

Sets or returns the SNMP::Session object

    # Get
    my $sess = $c2900->session();

    # Set
    my $newsession = new SNMP::Session(...);
    $c2900->session($newsession);

=back

=head1 GLOBALS

=over

=item $c2900->vendor()

    Returns 'cisco' :)

=back

=head1 TABLE ENTRIES

=head2 Overrides

=over

=item $c2900->interfaces()

    Returns reference to the map between IID and physical Port.

    On the 2900 devices i_name isn't reliable, so we override to just the description.

    Next all dots are changed for forward slashes so that the physical port name 
    is the same as the broadcasted CDP port name. 
        (Ethernet0.1 -> Ethernet0/1)

    Also, any weird characters are removed, as I saw a few pop up.

=item $c2900->i_duplex()

    Returns reference to map of IIDs to current link duplex

    Crosses $c2900->c2900_p_index() with $c2900->c2900_p_duplex;

=item $c2900->i_duplex_admin()

    Returns reference to hash of IIDs to admin duplex setting
    
    Crosses $c2900->c2900_p_index() with $c2900->c2900_p_duplex_admin;
    

=back

=head2 C2900-MIB Port Entry Table 

=over

=item $c2900->c2900_p_index()

    Maps the Switch Port Table to the IID

    B<c2900PortIfIndex>

=item $c2900->c2900_p_duplex()

    Gives Port Duplex Info

    B<c2900PortDuplexStatus>

=item $c2900->c2900_p_duplex_admin()

    Gives admin setting for Duplex Info

    B<c2900PortDuplexState>


=item $c2900->c2900_p_speed_admin()

    Gives Admin speed of port 

    B<c2900PortAdminSpeed>

=back

=cut

