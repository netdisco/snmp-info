# SNMP::Info::CiscoStack
# Max Baker <max@warped.org>
#
# Copyright (c) 2003 Max Baker
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
#     * Neither the name of the author nor the 
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

package SNMP::Info::CiscoStack;
$VERSION = 0.7;
# $Id$

use strict;

use Exporter;
use SNMP::Info;

use vars qw/$VERSION $DEBUG %MIBS %FUNCS %GLOBALS %MUNGE %PORTSTAT $INIT/;
@SNMP::Info::CiscoStack::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::CiscoStack::EXPORT_OK = qw//;

$DEBUG=0;
$SNMP::debugging=$DEBUG;

$INIT    = 0;
%MIBS    = (
            'CISCO-STACK-MIB'     => 'ciscoStackMIB',
           );

%GLOBALS = (
            'sysip'       => 'sysIpAddr',    
            'netmask'     => 'sysNetMask',    
            'broadcast'   => 'sysBroadcast',
            'serial1'     => 'chassisSerialNumber',    
            'serial2'     => 'chassisSerialNumberString',
            'model'       => 'chassisModel',    
            'ps1_type'    => 'chassisPs1Type',    
            'ps1_status'  => 'chassisPs1Status',    
            'ps2_type'    => 'chassisPs2Type',    
            'ps2_status'  => 'chassisPs2Status',    
            'slots'       => 'chassisNumSlots',    
            'fan'         => 'chassisFanStatus',
           );

%FUNCS   = (
            'i_type2'        => 'ifType',
            # CISCO-STACK-MIB::moduleEntry
            #   These are blades in a catalyst device
            'm_type'         => 'moduleType',
            'm_model'        => 'moduleModel',
            'm_serial'       => 'moduleSerialNumber',
            'm_status'       => 'moduleStatus',
            'm_name'         => 'moduleName',
            'm_ports'        => 'moduleNumPorts',
            'm_ports_status' => 'modulePortStatus',
            'm_hwver'        => 'moduleHwVersion',
            'm_fwver'        => 'moduleFwVersion',
            'm_swver'        => 'moduleSwVersion',
            # Router Blades :
            'm_ip'           => 'moduleIPAddress',
            'm_sub1'         => 'moduleSubType',
            'm_sub2'         => 'moduleSubType2',
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
           );

%MUNGE   = (
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

sub i_type {
    my $stack = shift;

    my $p_port = $stack->p_port();
    my $p_type  = $stack->p_type();

    # Get more generic port types from IF-MIB
    my $i_type  = $stack->i_type2();

    # Now Override w/ port entries
    foreach my $port (keys %$p_type) {
        my $iid = $p_port->{$port};
        $i_type->{$iid} = $p_type->{$port};  
    }

    return $i_type;
}

# p_* functions are indexed to physical port.  let's index these
#   to snmp iid
sub i_name {
    my $stack = shift;

    my $p_port = $stack->p_port();
    my $p_name  = $stack->p_name();

    my %i_name;
    foreach my $port (keys %$p_name) {
        my $iid = $p_port->{$port};
        next unless defined $iid;
        $i_name{$iid} = $p_name->{$port};
    }
    return \%i_name; 
}

sub i_duplex {
    my $stack = shift;

    my $p_port = $stack->p_port();
    my $p_duplex  = $stack->p_duplex();

    my %i_duplex;
    foreach my $port (keys %$p_duplex) {
        my $iid = $p_port->{$port};
        $i_duplex{$iid} = $p_duplex->{$port};
    }
    return \%i_duplex; 
}

sub i_duplex_admin {
    my $stack = shift;

    my $p_port          = $stack->p_port();
    my $p_duplex_admin  = $stack->p_duplex_admin();

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

# $stack->interfaces() - Maps the ifIndex table to a physical port
sub interfaces {
    my $self = shift;
    my $interfaces = $self->i_index();
    my $portnames  = $self->p_port();
    my %portmap = reverse %$portnames;

    my %interfaces = ();
    foreach my $iid (keys %$interfaces) {
        my $if = $interfaces->{$iid};
        $interfaces{$if} = $portmap{$iid};
    }

    return \%interfaces;
}

1;
__END__

=head1 NAME

SNMP::Info::CiscoStack - Perl5 Interface to CPU and Memory stats for Cisco Devices

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $ciscostats = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $ciscostats->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

SNMP::Info::CiscoStack is a subclass of SNMP::Info that provides
an interface to the C<CISCO-STACK-MIB>.  This MIB is used across
the Catalyst family under CatOS and IOS.

Use or create in a subclass of SNMP::Info.  Do not use directly.

=head2 Inherited Classes

none.

=head2 Required MIBs

=over

=item CISCO-STACK-MIB

=back

MIBs can be found at ftp://ftp.cisco.com/pub/mibs/v2/v2.tar.gz

=head1 GLOBALS

=over

=item $stack->broadcast()

(B<sysBroadcast>)

=item $stack->fan()

(B<chassisFanStatus>)

=item $stack->model()

(B<chassisModel>)

=item $stack->netmask()

(B<sysNetMask>)

=item $stack->ps1_type()

(B<chassisPs1Type>)

=item $stack->ps2_type()

(B<chassisPs2Type>)

=item $stack->ps1_status()

(B<chassisPs1Status>)

=item $stack->ps2_status()

(B<chassisPs2Status>)

=item $stack->serial()

(B<chassisSerialNumberString>) or (B<chassisSerialNumber>)

=item $stack->slots()

(B<chassisNumSlots>)

=back

=head1 TABLE METHODS

=head2 Interface Tables

=over

=item $stack->interfaces()

Crosses p_port() with i_index() to get physical names.

=item $stack->i_physical()

Returns a map to IID for ports that are physical ports, not vlans, etc.

=item $stack->i_type()

Crosses p_port() with p_type() and returns the results. 

Overrides with ifType if p_type() isn't available.

=item $stack->i_name()

Crosses p_name with p_port and returns results.

=item $stack->i_duplex()

Crosses p_duplex with p_port and returns results.

=item $stack->i_duplex_admin()

Crosses p_duplex_admin with p_port.

Munges bit_string returned from p_duplex_admin to get duplex settings.

=back

=head2 Module table

This table holds configuration information for each of the blades installed in
the Catalyst device.

=over

=item $stack->m_type()

(B<moduleType>)

=item $stack->m_model()

(B<moduleModel>)

=item $stack->m_serial()

(B<moduleSerialNumber>)

=item $stack->m_status()

(B<moduleStatus>)

=item $stack->m_name()

(B<moduleName>)

=item $stack->m_ports()

(B<moduleNumPorts>)

=item $stack->m_ports_status()

Returns a list of space separated status strings for the ports.

To see the status of port 4 :

    @ports_status = split(' ', $stack->m_ports_status() );
    $port4 = $ports_status[3];

(B<modulePortStatus>)

=item $stack->m_ports_hwver()

(B<moduleHwVersion>)

=item $stack->m_ports_fwver()

(B<moduleFwVersion>)

=item $stack->m_ports_swver()

(B<moduleSwVersion>)

=item $stack->m_ports_ip()

(B<moduleIPAddress>)

=item $stack->m_ports_sub1()

(B<moduleSubType>)

=item $stack->m_ports_sub2()

(B<moduleSubType2>)

=back

=head2 Modules - Router Blades

=over

=item $stack->m_ip()

(B<moduleIPAddress>)

=item $stack->m_sub1()

(B<moduleSubType>)

=item $stack->m_sub2()

(B<moduleSubType2>)

=back

=head2 Port Entry Table (CISCO-STACK-MIB::portTable)

=over

=item $stack->p_name()

(B<portName>)

=item $stack->p_type()

(B<portType>)

=item $stack->p_status()

(B<portOperStatus>)

=item $stack->p_status2()

(B<portAdditionalStatus>)

=item $stack->p_speed()

(B<portAdminSpeed>)

=item $stack->p_duplex()

(B<portDuplex>)

=item $stack->p_port()

(B<portIfIndex>)

=back

=head2 Port Capability Table (CISCO-STACK-MIB::portCpbTable)

=over

=item $stack->p_speed_admin()

(B<portCpbSpeed>)

=item $stack->p_duplex_admin()

(B<portCpbDuplex>)

=back

=cut
