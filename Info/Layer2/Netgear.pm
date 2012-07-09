# SNMP::Info::Layer2::Netgear
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

package SNMP::Info::Layer2::Netgear;

use strict;
use Exporter;
use SNMP::Info::Layer2;
use SNMP::Info::LLDP;

@SNMP::Info::Layer2::Netgear::ISA       = qw/SNMP::Info::LLDP SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::Netgear::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '2.07_001';

%MIBS = ( %SNMP::Info::Layer2::MIBS, %SNMP::Info::LLDP::MIBS, );

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS, %SNMP::Info::LLDP::GLOBALS,
    ng_serial => '.1.3.6.1.4.1.4526.10.1.1.1.4.0',
    ng_osver  => '.1.3.6.1.4.1.4526.10.1.1.1.13.0',
);

%FUNCS = ( %SNMP::Info::Layer2::FUNCS, %SNMP::Info::LLDP::FUNCS, );

%MUNGE = ( %SNMP::Info::Layer2::MUNGE, %SNMP::Info::LLDP::MUNGE, );

sub vendor {
    return 'netgear';
}

sub os {
    return 'netgear';
}

# Wish the OID-based method worked, but netgear scatters
# the sysObjectID values across all the device MIBs, and
# makes the device MIBs state secrets.
# They seem to set sysDescr to the model number, though,
# so we'll use that.
sub model {
    my $netgear = shift;
    return $netgear->description();
}

#
# This is model-dependent.  Some netgear brand devices don't implement
# the bridge MIB forwarding table, so we use the Q-BRIDGE-MIB forwarding
# table.  Fall back to the orig functions if the qb versions don't
# return anything.
sub fw_mac {
    my $netgear = shift;
    my $ret     = $netgear->qb_fw_mac();
    $ret = $netgear->orig_fw_mac() if ( !defined($ret) );
    return $ret;
}

sub fw_port {
    my $netgear = shift;
    my $ret     = $netgear->qb_fw_port();
    $ret = $netgear->orig_fw_port() if ( !defined($ret) );
    return $ret;
}

# these seem to work for GSM models but not GS
# https://sourceforge.net/tracker/?func=detail&aid=3085413&group_id=70362&atid=527529
sub os_ver {
    my $self = shift;
    return if $self->model and $self->model =~ m/GS\d/i;
    return $self->ng_osver();
}

sub serial {
    my $self = shift;
    return if $self->model and $self->model =~ m/GS\d/i;
    return $self->ng_serial();
}

#  Use LLDP

sub hasCDP {
    my $netgear = shift;
    return $netgear->hasLLDP();
}

sub c_ip {
    my $netgear = shift;
    my $partial  = shift;

    return $netgear->lldp_ip($partial);
}

sub c_if {
    my $netgear = shift;
    my $partial  = shift;

    return $netgear->lldp_if($partial);
}

sub c_port {
    my $netgear = shift;
    my $partial  = shift;

    return $netgear->lldp_port($partial);
}

sub c_id {
    my $netgear = shift;
    my $partial  = shift;

    return $netgear->lldp_id($partial);
}

sub c_platform {
    my $netgear = shift;
    my $partial  = shift;

    return $netgear->lldp_rem_sysdesc($partial);
}


1;

__END__

=head1 NAME

SNMP::Info::Layer2::Netgear - SNMP Interface to Netgear switches

=head1 AUTHOR

Bill Fenner and Zoltan Erszenyi, 
Hacked in LLDP support from Baystack.pm by 
 Nic Bernstein <nic@onlight.com>

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $netgear = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $netgear->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a 
Netgear device through SNMP. See inherited classes' documentation for 
inherited methods.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2
=item SNMP::Info::LLDP

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

MIBs listed in L<SNMP::Info::Layer2/"Required MIBs"> and its inherited
classes.

See L<SNMP::Info::LLDP/"Required MIBs"> for its MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=head2 Overrides

=over

=item $netgear->vendor()

Returns 'netgear'

=item $netgear->os()

Returns 'netgear' 

=item $netgear->model()

Returns description()

=item $netgear->os_ver()

Returns OS Version.

=item $netgear->serial()

Returns Serial Number.

=back

=head2 Global Methods imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of
a reference to a hash.

=head2 Overrides

=over

=item $netgear->fw_mac()

Returns reference to hash of forwarding table MAC Addresses.

Some devices don't implement the C<BRIDGE-MIB> forwarding table, so we use
the C<Q-BRIDGE-MIB> forwarding table.  Fall back to the C<BRIDGE-MIB> if
C<Q-BRIDGE-MIB> doesn't return anything.

=item $netgear->fw_port()

Returns reference to hash of forwarding table entries port interface
identifier (iid)

Some devices don't implement the C<BRIDGE-MIB> forwarding table, so we use
the C<Q-BRIDGE-MIB> forwarding table.  Fall back to the C<BRIDGE-MIB> if
C<Q-BRIDGE-MIB> doesn't return anything.

=back

=head2 Topology information

Based upon the software version devices may support Link Layer Discovery 
Protocol (LLDP).

=over

=item $netgear->hasCDP()

Returns true if the device is running LLDP.

=item $netgear->c_if()

Returns reference to hash.  Key: iid Value: local device port (interfaces)

=item $netgear->c_ip()

Returns reference to hash.  Key: iid Value: remote IPv4 address

If multiple entries exist with the same local port, c_if(), with the same IPv4
address, c_ip(), it may be a duplicate entry.

If multiple entries exist with the same local port, c_if(), with different
IPv4 addresses, c_ip(), there is either a non-LLDP device in between two or
more devices or multiple devices which are not directly connected.  

Use the data from the Layer2 Topology Table below to dig deeper.

=item $netgear->c_port()

Returns reference to hash. Key: iid Value: remote port (interfaces)

=item $netgear->c_id()

Returns reference to hash. Key: iid Value: string value used to identify the
chassis component associated with the remote system.

=item $netgear->c_platform()

Returns reference to hash.  Key: iid Value: Remote Device Type

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=cut
