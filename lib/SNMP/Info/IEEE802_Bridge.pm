# SNMP::Info::IEEE802_Bridge
#
# Changes since Version 0.7 Copyright (c) 2004 Max Baker
# All rights reserved.
#
# Copyright (c) 2002,2003 Regents of the University of California
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

package SNMP::Info::IEEE802_Bridge;

use strict;
use warnings;
use Exporter;
use SNMP::Info;

@SNMP::Info::IEEE802_Bridge::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::IEEE802_Bridge::EXPORT_OK = qw//;

our ($VERSION, $DEBUG, %MIBS, %FUNCS, %GLOBALS, %MUNGE, $INIT);

$VERSION = '3.73';

%MIBS = (
    'IEEE8021-Q-BRIDGE-MIB' => 'ieee8021QBridgeVlanCurrentEgressPorts',
);

%GLOBALS = (
);

%FUNCS = (
    'iqb_i_vlan'        => 'ieee8021QBridgePvid',
    'iqb_i_vlan_type'   => 'ieee8021QBridgePortAcceptableFrameTypes',
    'iqb_i_vlan_in_flt' => 'ieee8021QBridgePortIngressFiltering',

    'iqb_cv_egress'   => 'ieee8021QBridgeVlanCurrentEgressPorts',
    'iqb_cv_untagged' => 'ieee8021QBridgeVlanCurrentUntaggedPorts',
    'iqb_cv_stat'     => 'ieee8021QBridgeVlanStatus',

    'iqb_v_name'        => 'ieee8021QBridgeVlanStaticName',
    'iqb_v_egress'      => 'ieee8021QBridgeVlanStaticEgressPorts',
    'iqb_v_fbdn_egress' => 'ieee8021QBridgeVlanForbiddenEgressPorts',
    'iqb_v_untagged'    => 'ieee8021QBridgeVlanStaticUntaggedPorts',
    'iqb_v_stat'        => 'ieee8021QBridgeVlanStaticRowStatus',

);

%MUNGE = (

    # Inherit all the built in munging
    %SNMP::Info::MUNGE,

    # Add ones for our class
    'iqb_cv_egress'     => \&SNMP::Info::munge_port_list,
    'iqb_cv_untagged'   => \&SNMP::Info::munge_port_list,
    'iqb_v_egress'      => \&SNMP::Info::munge_port_list,
    'iqb_v_fbdn_egress' => \&SNMP::Info::munge_port_list,
    'iqb_v_untagged'    => \&SNMP::Info::munge_port_list,

);

1;

__END__


=head1 NAME

SNMP::Info::IEEE802_Bridge - SNMP Interface to SNMP data available through the
F<IEEE8021-Q-BRIDGE-MIB>

=head1 AUTHOR

Jeroen van Ingen

=head1 SYNOPSIS

FIXME update with better example
 my $bridge = new SNMP::Info (
                             AutoSpecify => 1,
                             Debug       => 1,
                             DestHost    => 'switch',
                             Community   => 'public',
                             Version     => 2
                             );

 my $class = $bridge->class();
 print " Using device sub class : $class\n";

 # Grab Forwarding Tables
 my $interfaces = $bridge->interfaces();
 my $fw_mac     = $bridge->fw_mac();
 my $fw_port    = $bridge->fw_port();
 my $bp_index   = $bridge->bp_index();

 foreach my $fw_index (keys %$fw_mac){
    my $mac   = $fw_mac->{$fw_index};
    my $bp_id = $fw_port->{$fw_index};
    my $iid   = $bp_index->{$bp_id};
    my $port  = $interfaces->{$iid};

    print "Port:$port forwarding to $mac\n";
 }

=head1 DESCRIPTION

F<IEEE8021-Q-BRIDGE-MIB> is used by some newer switches / Layer 2 devices.
It is derived from the IETF Q-BRIDGE-MIB (RFC 4363), extending it with the
concept of multiple VLAN-aware bridges (PBB).

Create or use a subclass of SNMP::Info that inherits this class.  Do not use
directly.

For debugging you can call new() directly as you would in SNMP::Info

 my $bridge = new SNMP::Info::IEEE802_Bridge(...);

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item F<IEEE8021-Q-BRIDGE-MIB>

=back

=head1 GLOBALS

These are methods that return scalar values from SNMP

=over

=back

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Per-port VLAN configuration in the device (C<ieee8021QBridgePortVlanTable>)

=over

=item $bridge->iqb_i_vlan()

(C<ieee8021QBridgePvid>)

=item $bridge->iqb_i_vlan_type()

(C<ieee8021QBridgePortAcceptableFrameTypes>)

=item $bridge->iqb_i_vlan_in_flt()

(C<ieee8021QBridgePortIngressFiltering>)

=back

=head2 VLAN Current Table (C<ieee8021QBridgeVlanCurrentTable>)

=over

=item $bridge->iqb_cv_egress()

(C<ieee8021QBridgeVlanCurrentEgressPorts>)

=item $bridge->iqb_cv_untagged()

(C<ieee8021QBridgeVlanCurrentUntaggedPorts>)

=item $bridge->iqb_cv_stat()

(C<ieee8021QBridgeVlanStatus>)

=back

=head2 VLAN Static Table (C<ieee8021QBridgeVlanStaticTable>)

=over

=item $bridge->iqb_v_name()

(C<ieee8021QBridgeVlanStaticName>)

=item $bridge->iqb_v_egress()

(C<ieee8021QBridgeVlanStaticEgressPorts>)

=item $bridge->iqb_v_fbdn_egress()

(C<ieee8021QBridgeVlanForbiddenEgressPorts>)

=item $bridge->iqb_v_untagged()

(C<ieee8021QBridgeVlanStaticUntaggedPorts>)

=item $bridge->iqb_v_stat()

C<active> !

(C<ieee8021QBridgeVlanStaticRowStatus>)

=back

=cut
