# SNMP::Info::Layer2::Catalyst
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

package SNMP::Info::Layer2::Catalyst;
$VERSION = 0.6;
# $Id$

use strict;

use Exporter;
use SNMP::Info::Layer2;

use vars qw/$VERSION $DEBUG %GLOBALS %MIBS %FUNCS %PORTSTAT %MUNGE $INIT/ ;
@SNMP::Info::Layer2::Catalyst::ISA = qw/SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::Catalyst::EXPORT_OK = qw//;

$DEBUG=0;

# See SNMP::Info for the details of these data structures and 
#       the interworkings.
$INIT = 0;

%MIBS =    ( %SNMP::Info::Layer2::MIBS, 
             'CISCO-STACK-MIB' => 'moduleType',
             'CISCO-VTP-MIB'   => 'vtpVlanIndex'
           );

%GLOBALS = (
            %SNMP::Info::Layer2::GLOBALS,
            # these are in CISCO-STACK-MIB
            'sysip'       => 'sysIpAddr',    
            'netmask'     => 'sysNetMask',    
            'broadcast'   => 'sysBroadcast',
            'serial'      => 'chassisSerialNumber',    
            'model'       => 'chassisModel',    
            'ps1_type'    => 'chassisPs1Type',    
            'ps1_status'  => 'chassisPs1Status',    
            'ps2_type'    => 'chassisPs2Type',    
            'ps2_status'  => 'chassisPs2Status',    
            'slots'       => 'chassisNumSlots',    
            'fan'         => 'chassisFanStatus',
           );

%FUNCS =   (
            %SNMP::Info::Layer2::FUNCS,
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
            # CISCO-VTP-MIB::VtpVlanEntry 
            'v_state'   => 'vtpVlanState',
            'v_type'    => 'vtpVlanType',
            'v_name'    => 'vtpVlanName',
            'v_mtu'     => 'vtpVlanMtu',
           );

%MUNGE =   (
            %SNMP::Info::Layer2::MUNGE,
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

# i_physical sets a hash entry as true if the iid is a physical port
sub i_physical {
    my $cat = shift;

    my $p_port = $cat->p_port();

    my %i_physical;
    foreach my $port (keys %$p_port) {
        my $iid = $p_port->{$port};
        $i_physical{$iid} = 1;  
    }
    return \%i_physical;
}

sub i_type {
    my $cat = shift;

    my $p_port = $cat->p_port();
    my $p_type  = $cat->p_type();

    # Get more generic port types from IF-MIB
    my $i_type  = $cat->i_type2();

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
    my $cat = shift;

    my $p_port = $cat->p_port();
    my $p_name  = $cat->p_name();

    my %i_name;
    foreach my $port (keys %$p_name) {
        my $iid = $p_port->{$port};
        next unless defined $iid;
        $i_name{$iid} = $p_name->{$port};
    }
    return \%i_name; 
}

sub i_duplex {
    my $cat = shift;

    my $p_port = $cat->p_port();
    my $p_duplex  = $cat->p_duplex();

    my %i_duplex;
    foreach my $port (keys %$p_duplex) {
        my $iid = $p_port->{$port};
        $i_duplex{$iid} = $p_duplex->{$port};
    }
    return \%i_duplex; 
}

sub i_duplex_admin {
    my $cat = shift;

    my $p_port          = $cat->p_port();
    my $p_duplex_admin  = $cat->p_duplex_admin();

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

# $cat->interfaces() - Maps the ifIndex table to a physical port
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

sub vendor {
    return 'cisco';
}

sub os {
    return 'catalyst';
}

sub os_ver {
    my $cat = shift;
    my $os_ver = $cat->SUPER::os_ver();
    return $os_ver if defined $os_ver;

    my $m_swver = $cat->m_swver();
    return undef unless defined $m_swver;

    # assume .1 entry is the chassis and the sw version we want.
    return $m_swver->{1} if defined $m_swver->{1};
    return undef;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::Catalyst - Perl5 Interface to Cisco devices running Catalyst OS 

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $cat = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $cat->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

SNMP::Info subclass to provide information for Cisco Catalyst switches running CatOS.

This subclass is not for all devices that have the name Catalyst.  Note that some Catalyst
switches run IOS, like the 2900 and 3550 families.  Cisco Catalyst 1900 switches use their
own MIB and have a separate subclass.  Use the method above to have SNMP::Info determine the
appropriate subclass before using this class directly.

Note:  Some older Catalyst switches will only talk SNMP version 1.  Some newer ones will not
return all their data if connected via Version 1.

For speed or debugging purposes you can call the subclass directly, but not after determining
a more specific class using the method above. 

 my $cat = new SNMP::Info::Layer2::Catalyst(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

=over

=item CISCO-STACK-MIB

=item CISCO-VTP-MIB

=item Inherited Classes' MIBs

See SNMP::Info::Layer2 for its own MIB requirements.

=back

These MIBs are found in the standard v2 MIBs from Cisco.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $cat->broadcast()

(B<sysBroadcast>)

=item $cat->fan()

(B<chassisFanStatus>)

=item $cat->model()

(B<chassisModel>)

=item $cat->netmask()

(B<sysNetMask>)

=item $cat->os()

Returns 'catalyst'

=item $cat->os_ver()

Tries to use the value from SNMP::Info::CiscoStats->os_ver() and if it fails 
it grabs $cat->m_swver()->{1} and uses that.

=item $cat->ps1_type()

(B<chassisPs1Type>)

=item $cat->ps2_type()

(B<chassisPs2Type>)

=item $cat->ps1_status()

(B<chassisPs1Status>)

=item $cat->ps2_status()

(B<chassisPs2Status>)

=item $cat->serial()

(B<chassisSerialNumberString>)

=item $cat->slots()

(B<chassisNumSlots>)

=item $cat->vendor()

Returns 'cisco'

=back

=head2 Globals imported from SNMP::Info::Layer2

See documentation in SNMP::Info::Layer2 for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $cat->interfaces()

Crosses p_port() with i_index() to get physical names.

=item $cat->i_physical()

Returns a map to IID for ports that are physical ports, not vlans, etc.

=item $cat->i_type()

Crosses p_port() with p_type() and returns the results. 

Overrides with ifType if p_type() isn't available.

=item $cat->i_name()

Crosses p_name with p_port and returns results.

=item $cat->i_duplex()

Crosses p_duplex with p_port and returns results.

=item $cat->i_duplex_admin()

Crosses p_duplex_admin with p_port.

Munges bit_string returned from p_duplex_admin to get duplex settings.

=back

=head2 Module table

This table holds configuration information for each of the blades installed in
the Catalyst device.

=over

=item $cat->m_type()

(B<moduleType>)

=item $cat->m_model()

(B<moduleModel>)

=item $cat->m_serial()

(B<moduleSerialNumber>)

=item $cat->m_status()

(B<moduleStatus>)

=item $cat->m_name()

(B<moduleName>)

=item $cat->m_ports()

(B<moduleNumPorts>)

=item $cat->m_ports_status()

Returns a list of space separated status strings for the ports.

To see the status of port 4 :

    @ports_status = split(' ', $cat->m_ports_status() );
    $port4 = $ports_status[3];

(B<modulePortStatus>)

=item $cat->m_ports_hwver()

(B<moduleHwVersion>)

=item $cat->m_ports_fwver()

(B<moduleFwVersion>)

=item $cat->m_ports_swver()

(B<moduleSwVersion>)

=item $cat->m_ports_ip()

(B<moduleIPAddress>)

=item $cat->m_ports_sub1()

(B<moduleSubType>)

=item $cat->m_ports_sub2()

(B<moduleSubType2>)

=back

=head2 Modules - Router Blades

=over

=item $cat->m_ip()

(B<moduleIPAddress>)

=item $cat->m_sub1()

(B<moduleSubType>)

=item $cat->m_sub2()

(B<moduleSubType2>)

=back

=head2 Port Entry Table (CISCO-STACK-MIB::portTable)

=over

=item $cat->p_name()

(B<portName>)

=item $cat->p_type()

(B<portType>)

=item $cat->p_status()

(B<portOperStatus>)

=item $cat->p_status2()

(B<portAdditionalStatus>)

=item $cat->p_speed()

(B<portAdminSpeed>)

=item $cat->p_duplex()

(B<portDuplex>)

=item $cat->p_port()

(B<portIfIndex>)

=back

=head2 Port Capability Table (CISCO-STACK-MIB::portCpbTable)

=over

=item $cat->p_speed_admin()

(B<portCpbSpeed>)

=item $cat->p_duplex_admin()

(B<portCpbDuplex>)

=back

=head2 VLAN Entry Table

See ftp://ftp.cisco.com/pub/mibs/supportlists/wsc5000/wsc5000-communityIndexing.html
for a good treaty of how to connect to the VLANs

=over

=item $cat->v_state()

(B<vtpVlanState>)

=item $cat->v_type()

(B<vtpVlanType>)

=item $cat->v_name()

(B<vtpVlanName>)

=item $cat->v_mtu()

(B<vtpVlanMtu>)

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See documentation in SNMP::Info::Layer2 for details.

=cut
