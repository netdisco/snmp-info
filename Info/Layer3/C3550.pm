# SNMP::Info::Layer3::C3550
# Max Baker <max@warped.org>
#
# Copyright (c) 2003, Regents of the University of California
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

package SNMP::Info::Layer3::C3550;
$VERSION = 0.3;
# $Id$

use strict;

use Exporter;
use SNMP::Info::Layer3;

use vars qw/$VERSION $DEBUG %GLOBALS %MIBS %FUNCS %PORTSTAT %MUNGE $INIT/ ;
@SNMP::Info::Layer3::C3550::ISA = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::C3550::EXPORT_OK = qw//;

$DEBUG=0;

# See SNMP::Info for the details of these data structures and 
#       the interworkings.
$INIT = 0;

%MIBS = (
         %SNMP::Info::Layer3::MIBS,  
         'CISCO-STACK-MIB' => 'moduleType',
         'CISCO-VTP-MIB'   => 'vtpVlanIndex'
        );

%GLOBALS = (
            %SNMP::Info::Layer3::GLOBALS,
            'ports2'      => 'ifNumber',
            # these are in CISCO-STACK-MIB
            'serial'      => 'chassisSerialNumberString',    
            'ps1_type'    => 'chassisPs1Type',    
            'ps1_status'  => 'chassisPs1Status',    
            'ps2_type'    => 'chassisPs2Type',    
            'ps2_status'  => 'chassisPs2Status',    
            'fan'         => 'chassisFanStatus'
             );

%FUNCS = (
            %SNMP::Info::Layer3::FUNCS,
            'i_type2'        => 'ifType',
            # CISCO-STACK-MIB::portEntry 
            'p_name'    => 'portName',
            'p_type'    => 'portType',
            'p_status'  => 'portOperStatus',
            'p_status2' => 'portAdditionalStatus',
            'p_speed'   => 'portAdminSpeed',
            'p_duplex'  => 'portDuplex',
            'p_port'    => 'portIfIndex',
            # CISCO-STACK-MIB::PortCpbEntry
            'p_speed_admin'  => 'portCpbSpeed',
            'p_duplex_admin' => 'portCpbDuplex',
            # CISCO-VTP-MIB::VtpVlanEntry 
            'v_state'   => 'vtpVlanState',
            'v_type'    => 'vtpVlanType',
            'v_name'    => 'vtpVlanName',
            'v_mtu'     => 'vtpVlanMtu',
        );

%MUNGE = (
            # Inherit all the built in munging
            %SNMP::Info::Layer3::MUNGE,
            'm_ports_status' => \&munge_port_status,
            'p_duplex_admin' => \&SNMP::Info::munge_bits,
         );

%PORTSTAT = (1 => 'other',
             2 => 'ok',
             3 => 'minorFault',
             4 => 'majorFault');

# Changes binary byte describing each port into ascii, and returns
# an ascii list separated by spaces.
sub munge_port_status {
    my $status = shift;
    my @vals = map($PORTSTAT{$_},unpack('C*',$status));
    return join(' ',@vals);
}

# Overidden Methods

sub i_type {
    my $c3550 = shift;

    my $p_port = $c3550->p_port();
    my $p_type  = $c3550->p_type();

    # Get more generic port types from IF-MIB
    my $i_type  = $c3550->i_type2();

    # Now Override w/ port entries
    foreach my $port (keys %$p_type) {
        my $iid = $p_port->{$port};
        $i_type->{$iid} = $p_type->{$port};  
    }

    return $i_type;
}

sub i_duplex {
    my $c3550 = shift;

    my $p_port = $c3550->p_port();
    my $p_duplex  = $c3550->p_duplex();

    my %i_duplex;
    foreach my $port (keys %$p_duplex) {
        my $iid = $p_port->{$port};
        $i_duplex{$iid} = $p_duplex->{$port};
    }
    return \%i_duplex; 
}

sub i_duplex_admin {
    my $c3550 = shift;

    my $p_port          = $c3550->p_port();
    my $p_duplex_admin  = $c3550->p_duplex_admin();

    my %i_duplex_admin;
    foreach my $port (keys %$p_duplex_admin) {
        my $iid = $p_port->{$port};
        next unless defined $iid;
        my $duplex = $p_duplex_admin->{$port};
        next unless defined $duplex;

        my $string = 'other';
        # see CISCO-STACK-MIB for a description of the bits
        $string = 'half' if ($duplex =~ /001$/ or $duplex =~ /0100.$/);
        $string = 'full' if ($duplex =~ /010$/ or $duplex =~ /100.0$/);
        # we'll call it auto if both full and half are turned on, or if the
        #   specifically 'auto' flag bit is set.
        $string = 'auto' 
            if ($duplex =~ /1..$/ or $duplex =~ /110..$/ or $duplex =~ /..011$/);
       
        $i_duplex_admin{$iid} = $string;
    }
    return \%i_duplex_admin; 
}

sub vendor {
    return 'cisco';
}

sub model {
    my $c3550 = shift;
    my $id = $c3550->id();
    my $model = &SNMP::translateObj($id);
    $model =~ s/^catalyst//;
    $model =~ s/(24|48)$//;

    return $model;
}

# Ports is encoded into the model number
sub ports {
    my $c3550 = shift;

    my $ports2 = $c3550->ports2();    

    my $id = $c3550->id();
    my $model = &SNMP::translateObj($id);
    if ($model =~ /(24|48)$/) {
        return $1;
    }
    return $ports2;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::C3550 - Perl5 Interface to Cisco Catalyst 3550 Layer 2/3 Switches running IOS

=head1 DESCRIPTION

Abstraction subclass for Cisco Catalyst 3550 Layer 2/3 Switches.  These devices run
IOS but have some of the same charactersitics as the Catalyst WS-C family (5xxx,6xxx). 
For example, forwarding tables are held in VLANs, and extened interface information
is gleened from CISCO-SWITCH-MIB.

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 my $c3550 = new SNMP::Info::Layer3::C3550(DestHost  => 'router' , 
                              Community => 'public' ); 


See L<SNMP::Info> and L<SNMP::Info::Layer3> for all the inherited methods.

=head1 CREATING AN OBJECT

=over

=item  new SNMP::Info::Layer3::C3550()

Arguments passed to new() are passed on to SNMP::Session::new()
    

    my $c3550 = new SNMP::Info::Layer3::C3550(
        DestHost => $host,
        Community => 'public',
        Version => 3,...
        ) 
    die "Couldn't connect.\n" unless defined $c3550;

=back

=head1 GLOBAL Values

=over

=item $c3550->serial()
(B<chassisSerialNumberString>)

=item $c3550->model()
(B<chassisModel>)

=item $c3550->ps1_type()
(B<chassisPs1Type>)

=item $c3550->ps2_type()
(B<chassisPs2Type>)

=item $c3550->ps1_status()
(B<chassisPs1Status>)

=item $c3550->ps2_status()
(B<chassisPs2Status>)

=item $c3550->slots()
(B<chassisNumSlots>)

=item $c3550->fan()
(B<chassisFanStatus>)

=item $c3550->vendor()

    Returns 'cisco'

=back

=head1 TABLE ENTRIES

=head2 Overrides

=over

=item $c3550->i_type()

    Crosses p_port() with p_type() and returns the results. 

    Overrides with ifType if p_type() isn't available.

=item $c3550->i_name()

    Crosses p_name with p_port and returns results.

=item $c3550->i_duplex()

    Crosses p_duplex with p_port and returns results.

=item $c3550->i_duplex_admin()

    Crosses p_duplex_admin with p_port.

    Munges bit_string returned from p_duplex_admin to get duplex settings.

=back

=head2 Port Entry Table (CISCO-STACK-MIB::portTable)

=over

=item $c3550->p_name()
(B<portName>)

=item $c3550->p_type()
(B<portType>)

=item $c3550->p_status()
(B<portOperStatus>)

=item $c3550->p_status2()
(B<portAdditionalStatus>)

=item $c3550->p_speed()
(B<portAdminSpeed>)

=item $c3550->p_duplex()
(B<portDuplex>)

=item $c3550->p_port()
(B<portIfIndex>)

=back

=head2 Port Capability Table (CISCO-STACK-MIB::portCpbTable)

=over

=item $c3550->p_speed_admin()
(B<portCpbSpeed>)

=item $c3550->p_duplex_admin()
(B<portCpbDuplex>)

=back

=head2 VLAN Entry Table

See ftp://ftp.cisco.com/pub/mibs/supportlists/wsc5000/wsc5000-communityIndexing.html
for a good treaty of how to connect to the VLANs


=over

=item $c3550->v_state()
(B<vtpVlanState>)

=item $c3550->v_type()
(B<vtpVlanType>)

=item $c3550->v_name()
(B<vtpVlanName>)

=item $c3550->v_mtu()
(B<vtpVlanMtu>)

=back

=cut

