# SNMP::Info::Bridge
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

package SNMP::Info::Bridge;
$VERSION = 0.1;

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
            'b_type'  => 'dot1dBaseType'
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
          );

%MUNGE = (
          # Inherit all the built in munging
          %SNMP::Info::MUNGE,
          # Add ones for our class
          'fw_mac' => \&SNMP::Info::munge_mac,
          'bs_mac' => \&SNMP::Info::munge_mac,
         );

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
=cut
