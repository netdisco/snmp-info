# SNMP::Info::Layer3::Juniper
# $Id$
#
# Copyright (c) 2008 Bill Fenner
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

package SNMP::Info::Layer3::Juniper;

use strict;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::LLDP;

@SNMP::Info::Layer3::Juniper::ISA       = qw/SNMP::Info::Layer3 SNMP::Info::LLDP  Exporter/;
@SNMP::Info::Layer3::Juniper::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '2.06';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::LLDP::MIBS,
    'JUNIPER-CHASSIS-DEFINES-MIB' => 'jnxChassisDefines',
    'JUNIPER-MIB'                 => 'jnxBoxAnatomy',
);

%GLOBALS = ( %SNMP::Info::Layer3::GLOBALS, 
	     %SNMP::Info::LLDP::GLOBALS,
	     'serial' => 'jnxBoxSerialNo.0', );

%FUNCS = ( %SNMP::Info::Layer3::FUNCS, 
	   %SNMP::Info::LLDP::FUNCS,
);

%MUNGE = ( %SNMP::Info::Layer3::MUNGE, 
	   %SNMP::Info::LLDP::MUNGE,
);

sub vendor {
    return 'juniper';
}

sub os {
    return 'junos';
}

sub os_ver {
    my $juniper = shift;
    my $descr   = $juniper->description();
    return unless defined $descr;

    if ( $descr =~ m/kernel JUNOS (\S+)/ ) {
        return $1;
    }
    return;
}

sub model {
    my $l3 = shift;
    my $id = $l3->id();

    unless ( defined $id ) {
        print
            " SNMP::Info::Layer3::Juniper::model() - Device does not support sysObjectID\n"
            if $l3->debug();
        return;
    }

    my $model = &SNMP::translateObj($id);

    return $id unless defined $model;

    $model =~ s/^jnxProductName//i;
    return $model;
}

# Override the fancy Layer3.pm serial function
sub serial {
    my $juniper = shift;
    return $juniper->orig_serial();
}

sub i_vlan {
    my ($juniper) = shift;
    my ($partial) = shift;

    my ($i_type)  = $juniper->i_type($partial);
    my ($i_descr) = $juniper->i_description($partial);
    my %i_vlan;

    foreach my $idx ( keys %$i_descr ) {
        if ( $i_type->{$idx} eq 'l2vlan' || $i_type->{$idx} eq 135 ) {
            if ( $i_descr->{$idx} =~ /\.(\d+)$/ ) {
                $i_vlan{$idx} = $1;
            }
        }
    }
    return \%i_vlan;
}

# Use Q-BRIDGE-MIB for bridge forwarding tables
sub fw_mac {
    my $juniper  = shift;
    my $partial = shift;

    return $juniper->qb_fw_mac($partial);
}

sub fw_port {
    my $juniper  = shift;
    my $partial = shift;

    return $juniper->qb_fw_port($partial);
}

# Use LLDP

sub hasCDP {
    my $juniper = shift;

    return $juniper->hasLLDP();
}

sub c_ip {
    my $juniper  = shift;
    my $partial = shift;

    return $juniper->lldp_ip($partial);
}

sub c_if {
    my $juniper  = shift;
    my $partial = shift;

    return $juniper->lldp_if($partial);
}

sub c_port {
    my $juniper  = shift;
    my $partial = shift;

    return $juniper->lldp_port($partial);
}

sub c_id {
    my $juniper  = shift;
    my $partial = shift;

    return $juniper->lldp_id($partial);
}

sub c_platform {
    my $juniper  = shift;
    my $partial = shift;

    return $juniper->lldp_rem_sysdesc($partial);
}


1;
__END__

=head1 NAME

SNMP::Info::Layer3::Juniper - SNMP Interface to L3 Juniper Devices

=head1 AUTHOR

Bill Fenner

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $juniper = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $juniper->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Generic Juniper Routers running JUNOS

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::LLDP

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::LLDP/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $juniper->vendor()

Returns C<'juniper'>

=item $juniper->os()

Returns C<'junos'>

=item $juniper->os_ver()

Returns the software version extracted from C<sysDescr>.

=item $juniper->model()

Returns the model from C<sysObjectID>, with C<jnxProductNameremoved> from the
beginning.

=item $juniper->serial()

Returns serial number

(C<jnxBoxSerialNo.0>)

=item $juniper->hasCDP()

    Returns whether LLDP is enabled.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $juniper->i_vlan()

Returns the list of interfaces whose C<ifType> is l2vlan(135), and
the VLAN ID extracted from the interface description.

=item $juniper->c_id()

Returns LLDP information.

=item $juniper->c_if()

Returns LLDP information.

=item $juniper->c_ip()

Returns LLDP information.

=item $juniper->c_platform()

Returns LLDP information.

=item $juniper->c_port()

Returns LLDP information.

=back

=head2 Forwarding Table (C<dot1dTpFdbEntry>)

=over 

=item $juniper->fw_mac()

Returns reference to hash of forwarding table MAC Addresses

(C<dot1dTpFdbAddress>)

=item $juniper->fw_port()

Returns reference to hash of forwarding table entries port interface
identifier (iid)

(C<dot1dTpFdbPort>)

=back 

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"TABLE METHODS"> for details.

=cut
