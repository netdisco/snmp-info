# SNMP::Info::Bridge
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

package SNMP::Info::Bridge;
$VERSION = 0.2;
# $Id$

use strict;

use Exporter;
use SNMP::Info;

use vars qw/$VERSION $DEBUG %MIBS %FUNCS %GLOBALS %MUNGE $INIT/;
@SNMP::Info::Bridge::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::Bridge::EXPORT_OK = qw//;

$DEBUG=0;
$SNMP::debugging=$DEBUG;

$INIT = 0;
%MIBS = ('BRIDGE-MIB' => 'dot1dBaseBridgeAddress');
%GLOBALS = (
            'b_mac'   => 'dot1dBaseBridgeAddress',
            'b_ports' => 'dot1dBaseNumPorts',
            'b_type'  => 'dot1dBaseType',
            # Spanning Tree Protocol
            'stp_ver' => 'dot1dStpProtocolSpecification',
            'stp_time' => 'dot1dStpTimeSinceTopologyChange',
            'stp_root' => 'dot1dStpDesignatedRoot',
           );

%FUNCS = (
          # Forwarding Table: Dot1dTpFdbEntry 
          'fw_mac'    => 'dot1dTpFdbAddress',
          'fw_port'   => 'dot1dTpFdbPort',
          'fw_status' => 'dot1dTpFdbStatus',
          # Bridge Port Table: Dot1dBasePortEntry
          'bp_index'  => 'dot1dBasePortIfIndex',
          'bp_port'   => 'dot1dBasePortCircuit ',
          # Bridge Static (Destination-Address Filtering) Database
          'bs_mac'     => 'dot1dStaticAddress',
          'bs_port'   => 'dot1dStaticReceivePort',
          'bs_to'     => 'dot1dStaticAllowedToGoTo',
          'bs_status' => 'dot1dStaticStatus',
          # Spanning Tree Protocol Table : dot1dStpPortTable
          'stp_p_id'       => 'dot1dStpPort',
          'stp_p_priority' => 'dot1dStpPortPriority',
          'stp_p_state'    => 'dot1dStpPortState',
          'stp_p_cost'     => 'dot1dStpPortPathCost',
          'stp_p_root'     => 'dot1dStpPortDesignatedRoot',
          'stp_p_bridge'   => 'dot1dStpPortDesignatedBridge',
          'stp_p_port'     => 'dot1dStpPortDesignatedPort',
          );

%MUNGE = (
          # Inherit all the built in munging
          %SNMP::Info::MUNGE,
          # Add ones for our class
          'fw_mac'       => \&SNMP::Info::munge_mac,
          'bs_mac'       => \&SNMP::Info::munge_mac,
          'stp_root'     => \&SNMP::Info::munge_mac,
          'stp_p_root'   => \&SNMP::Info::munge_mac,
          'stp_p_bridge' => \&SNMP::Info::munge_mac,
          'stp_p_port'   => \&SNMP::Info::munge_mac
         );


sub i_stp_state {
    my $bridge = shift;
    my $bp_index = $bridge->bp_index();
    my $stp_p_state = $bridge->stp_p_state();

    my %i_stp_state;

    foreach my $index (keys %$stp_p_state){
        my $state = $stp_p_state->{$index};
        my $iid   = $bp_index->{$index};
        next unless defined $iid;
        next unless defined $state;
        $i_stp_state{$iid}=$state;
    }

    return \%i_stp_state;
}

1;
__END__


=head1 NAME

SNMP::Info::Bridge - Perl5 Interface to BRIDGE-MIB 

=head1 DESCRIPTION

BRIDGE-MIB is used by most Layer 2 devices like Switches 

Inherits all methods from SNMP::Info

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 my $bridge = new SNMP::Info::Bridge(DestHost  => 'myswitch',
                               Community => 'public');
 my $mac = $bridge->mac(); 

=head1 CREATING AN OBJECT

=over

=item  new SNMP::Info::Bridge()

Arguments passed to new() are passed on to SNMP::Session::new()
    

    my $bridge = new SNMP::Info::Bridge(
        DestHost => $host,
        Community => 'public',
        Version => 3,...
        ) 
    die "Couldn't connect.\n" unless defined $bridge;

=item  $bridge->session()

Sets or returns the SNMP::Session object

    # Get
    my $sess = $bridge->session();

    # Set
    my $newsession = new SNMP::Session(...);
    $bridge->session($newsession);

=back

=head1 Bridge Global Configuration Values

=over

=item $bridge->b_mac()

Returns the MAC Address of the root bridge port

(B<dot1dBaseBridgeAddress>)

=item $bridge->b_ports()

Returns the number of ports in device

(B<dot1dBaseNumPorts>)

=item $bridge->b_type()

Returns the type? of the device

(B<dot1dBaseType>)

=item $bridge->stp_ver()

Returns what version of STP the device is running.  Either decLb100 or ieee8021d.

(B<dot1dStpProtocolSpecification>)

=item $bridge->stp_time()

Returns time since last topology change detected. (100ths/second)

(B<dot1dStpTimeSinceTopologyChange>)

=item $bridge->stp_root()

Returns root of STP.

(B<dot1dStpDesignatedRoot>)

=back

=head1 TABLE ENTRIES

=head2 Forwarding Table (dot1dTpFdbEntry)

=over 

=item $bridge->fw_mac()

Returns reference to hash of forwarding table MAC Addresses

(B<dot1dTpFdbAddress>)

=item $bridge->fw_port()

Returns reference to hash of forwarding table entries port interface identifier (iid)

(B<dot1dTpFdbPort>)

=item $bridge->fw_status()

Returns reference to hash of forwading table entries status

(B<dot2dTpFdbStatus>)

=back

=head2 Bridge Port Table (dot1dBasePortEntry)

=over

=item $bridge->bp_index()

Returns reference to hash of bridge port table entries map back to interface identifier (iid)

(B<dot1dBasePortIfIndex>)

=item $bridge->bp_port()

Returns reference to hash of bridge port table entries physical port name.

(B<dot1dBasePortCircuit>)

=back

=head2 Spanning Tree Protocol Table (dot1dStpPortTable)

Descriptions are lifted straight from F<BRIDGE-MIB.my>

=over

=item $bridge->stp_p_id()

"The port number of the port for which this entry contains Spanning Tree Protocol management
information."

(B<dot1dStpPort>)

=item $bridge->stp_p_priority()

"The value of the priority field which is contained in the first (in network byte order)
octet of the (2 octet long) Port ID.  The other octet of the Port ID is given by the value of
dot1dStpPort."

(B<dot1dStpPortPriority>)

=item $bridge->stp_p_state()

"The port's current state as defined by application of the Spanning Tree Protocol.  This
state controls what action a port takes on reception of a frame.  If the bridge has detected
a port that is malfunctioning it will place that port into the broken(6) state.  For ports which
are disabled (see dot1dStpPortEnable), this object will have a value of disabled(1)."

 disabled(1)
 blocking(2)
 listening(3)
 learning(4)
 forwarding(5)
 broken(6)

(B<dot1dStpPortState>)

=item $bridge->stp_p_cost()

"The contribution of this port to the path cost of paths towards the spanning tree root which include
this port.  802.1D-1990 recommends that the default value of this parameter be in inverse
proportion to the speed of the attached LAN."

(B<dot1dStpPortPathCost>)

=item $bridge->stp_p_root()

"The unique Bridge Identifier of the Bridge recorded as the Root in the Configuration BPDUs
transmitted by the Designated Bridge for the segment to which the port is attached."

(B<dot1dStpPortDesignatedRoot>)

=item $bridge->stp_p_bridge()

"The Bridge Identifier of the bridge which this port considers to be the Designated Bridge for
this port's segment."

(B<dot1dStpPortDesignatedBridge>)

=item $bridge->stp_p_port()

(B<dot1dStpPortDesignatedPort>)

"The Port Identifier of the port on the Designated Bridge for this port's segment."

=back

=cut
