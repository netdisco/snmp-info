# SNMP::Info::EDP
#
# Copyright (c) 2012 Eric Miller
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


package SNMP::Info::EDP;

use strict;
use Exporter;
use SNMP::Info;

@SNMP::Info::LLDP::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::LLDP::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE/;

$VERSION = '3.18';

%MIBS = (
    'EXTREME-EDP-MIB'   => 'extremeEdpPortIfIndex',
);

%GLOBALS = (

);

%FUNCS = (
    # EXTREME-EDP-MIB::extremeEdpTable
    'edp_rem_sysname'  => 'extremeEdpNeighborName',
);

%MUNGE = (
    'edp_rem_sysname'   => \&SNMP::Info::munge_null,
);

sub hasEDP {
    my $edp = shift;

    my $edp_ip = $edp->extremeEdpNeighborVlanIpAddress() || {};

    return 1 if ( scalar( keys %$edp_ip ) );
    
    return;
}

# Since we need to get IP Addresses from the extremeEdpNeighborTable which has
# a different index (adds VLAN name) than the extremeEdpTable which holds
# the remote device details use the index from extremeEdpNeighborTable but skip
# indexes which have an address of 0.0.0.0.  Would like to include only one
# address since they should all originate from the same device, but we don't
# know if they would all be reachable from the network management application.
#
# We don't inplement partials since this is private index function
sub _edp_index {
    my $edp = shift;

    my $edp_ip  = $edp->extremeEdpNeighborVlanIpAddress() || {};
    
    my %edp_index;
    foreach my $key ( keys %$edp_ip ) {
        my $ip = $edp_ip->{$key};
        next if ($ip eq '0.0.0.0');
        next unless $ip;
        $edp_index{$key} = $key;
    }
    return \%edp_index;
}

sub edp_if {
    my $edp = shift;

    my $index = $edp->_edp_index() || {};

    my %edp_if;
    foreach my $key (keys %$index) {
        my $iid = $key;
        # ifIndex is first part of the iid
        $iid = $1 if $iid =~ /^(\d+)\./;
        $edp_if{$key} = $iid;
    }
 
  return \%edp_if;
}

sub edp_ip {
    my $edp = shift;

    my $index  = $edp->_edp_index() || {};
    my $edp_ip = $edp->extremeEdpNeighborVlanIpAddress() || {};

    my %edp_ip;
    foreach my $key ( keys %$index ) {
        my $ip = $edp_ip->{$key};
        # MIB says should only be IPv4
        next unless ($ip =~ /\d+(\.\d+){3}/);
        $edp_ip{$key} = $ip;
    }
    return \%edp_ip;
}

sub edp_port {
    my $edp = shift;

    my $index    = $edp->_edp_index() || {};
    my $edp_rport = $edp->extremeEdpNeighborPort() || {};
    my $edp_rslot = $edp->extremeEdpNeighborSlot() || {};

    my %edp_port;
    foreach my $key ( sort keys %$edp_rport ) {
        my $port = $edp_rport->{$key};
        my $slot = $edp_rslot->{$key} || 0;
        next unless $port;
        my $slotport = defined $slot ?  "$slot\/$port" : $port;

        foreach my $iid ( sort keys %$index ) {
            $edp_port{$iid} = $slotport if ($iid =~ /^$key/);
        }
    }
    return \%edp_port;
}

sub edp_id {
    my $edp = shift;

    my $index    = $edp->_edp_index() || {};
    my $edp_name = $edp->edp_rem_sysname() || {};

    my %edp_name;
    foreach my $key ( sort keys %$edp_name ) {
        my $name = $edp_name->{$key} || 0;
        next unless $name;

        foreach my $iid ( sort keys %$index ) {
            $edp_name{$iid} = $name if ($iid =~ /^$key/);
        }
    }
    return \%edp_name;
}

sub edp_ver {
    my $edp = shift;

    my $index   = $edp->_edp_index() || {};
    my $edp_ver = $edp->extremeEdpNeighborSoftwareVersion() || {};

    my %edp_ver;
    foreach my $key ( sort keys %$edp_ver ) {
        my $ver = $edp_ver->{$key} || 0;
        next unless $ver;

        foreach my $iid ( sort keys %$index ) {
            $edp_ver{$iid} = $ver if ($iid =~ /^$key/);
        }
    }
    return \%edp_ver;
}

1;
__END__

=head1 NAME

SNMP::Info::EDP - SNMP Interface to the Extreme Discovery Protocol (EDP)

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 my $edp = new SNMP::Info ( 
                             AutoSpecify => 1,
                             Debug       => 1,
                             DestHost    => 'router', 
                             Community   => 'public',
                             Version     => 2
                           );

 my $class = $edp->class();
 print " Using device sub class : $class\n";

 $haslldp   = $edp->hasLLDP() ? 'yes' : 'no';

 # Print out a map of device ports with LLDP neighbors:
 my $interfaces    = $edp->interfaces();
 my $edp_if       = $edp->edp_if();
 my $edp_ip       = $edp->edp_ip();
 my $edp_port     = $edp->edp_port();

 foreach my $edp_key (keys %$edp_ip){
    my $iid           = $edp_if->{$edp_key};
    my $port          = $interfaces->{$iid};
    my $neighbor      = $edp_ip->{$edp_key};
    my $neighbor_port = $edp_port->{$edp_key};
    print "Port : $port connected to $neighbor / $neighbor_port\n";
 }

=head1 DESCRIPTION

SNMP::Info::EDP is a subclass of SNMP::Info that provides an object oriented 
interface to EDP information through SNMP.

EDP is a Layer 2 protocol that allows a network device to advertise its
identity and capabilities on the local network providing topology information.

Create or use a device subclass that inherits this class.  Do not use
directly.

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item F<EXTREME-EDP-MIB>

=back

=head1 GLOBAL METHODS

These are methods that return scalar values from SNMP

=over

=item $edp->hasEDP()

Is EDP is active in this device?  

=back

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $edp->edp_id()

Returns the string value used to identify the chassis component associated
with the remote system.

(C<extremeEdpNeighborName>)

=item $edp->edp_if()

Returns the mapping to the SNMP Interface Table.

=item  $edp->edp_ip()

Returns remote IPv4 address.

=item $edp->edp_port()

Returns remote port ID

=item $edp->edp_ver()

Returns the operating system version of the remote system.

Nulls are removed before the value is returned. 

(C<extremeEdpNeighborSoftwareVersion>)

=back

=cut

