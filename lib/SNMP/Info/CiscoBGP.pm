# SNMP::Info::CiscoBGP
#
# Copyright (c) 2022 Alexander Hartmaier
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

package SNMP::Info::CiscoBGP;

use strict;
use warnings;
use Exporter;
use SNMP::Info;

@SNMP::Info::CiscoBGP::ISA       = qw( SNMP::Info Exporter );
@SNMP::Info::CiscoBGP::EXPORT_OK = qw(
    parse_cisco_bgp_peer2_entry_index
);

our ($VERSION, %MIBS, %FUNCS, %GLOBALS, %MUNGE);

$VERSION = '3.975000';

%MIBS = ( 'CISCO-BGP4-MIB' => 'cbgpPeer2State', );

%GLOBALS = ();

%FUNCS = (
    # cbgpPeer2Table
    'cisco_bgp_peer2_state'               => 'cbgpPeer2State',
    'cisco_bgp_peer2_adminstatus'         => 'cbgpPeer2AdminStatus',
    'cisco_bgp_peer2_localaddr'           => 'cbgpPeer2LocalAddr',
    'cisco_bgp_peer2_localport'           => 'cbgpPeer2LocalPort',
    'cisco_bgp_peer2_localas'             => 'cbgpPeer2LocalAs',
    'cisco_bgp_peer2_localidentifier'     => 'cbgpPeer2LocalIdentifier',
    'cisco_bgp_peer2_remoteport'          => 'cbgpPeer2RemotePort',
    'cisco_bgp_peer2_remoteas'            => 'cbgpPeer2RemoteAs',
    'cisco_bgp_peer2_remoteidentifier'    => 'cbgpPeer2RemoteIdentifier',
    'cisco_bgp_peer2_inupdates'           => 'cbgpPeer2InUpdates',
    'cisco_bgp_peer2_outupdates'          => 'cbgpPeer2OutUpdates',
    'cisco_bgp_peer2_intotalmessages'     => 'cbgpPeer2InTotalMessages',
    'cisco_bgp_peer2_outtotalmessages'    => 'cbgpPeer2OutTotalMessages',
    'cisco_bgp_peer2_lasterror'           => 'cbgpPeer2LastError',
    'cisco_bgp_peer2_fsmestablishedtransitions'
                                    => 'cbgpPeer2FsmEstablishedTransitions',
    'cisco_bgp_peer2_fsmestablishedtime'  => 'cbgpPeer2FsmEstablishedTime',
    'cisco_bgp_peer2_connectretryinterval'=> 'cbgpPeer2ConnectRetryInterval',
    'cisco_bgp_peer2_holdtime'            => 'cbgpPeer2HoldTime',
    'cisco_bgp_peer2_keepalive'           => 'cbgpPeer2KeepAlive',
    'cisco_bgp_peer2_holdtimeconfigured'  => 'cbgpPeer2HoldTimeConfigured',
    'cisco_bgp_peer2_keepaliveconfigured' => 'cbgpPeer2KeepAliveConfigured',
    'cisco_bgp_peer2_minasoriginationinterval'
                                    => 'cbgpPeer2MinASOriginationInterval',
    'cisco_bgp_peer2_inupdatelapsedtime'  => 'cbgpPeer2InUpdateElapsedTime',
    'cisco_bgp_peer2_lasterrortxt'        => 'cbgpPeer2LastErrorTxt',
    'cisco_bgp_peer2_prevstate'           => 'cbgpPeer2PrevState',

    # cbgpPeer2AddrFamilyPrefixTable
    'cisco_bgp_peer2_acceptedprefixes'    => 'cbgpPeer2AcceptedPrefixes',
    'cisco_bgp_peer2_deniedprefixes'      => 'cbgpPeer2DeniedPrefixes',
    'cisco_bgp_peer2_prefixadminlimit'    => 'cbgpPeer2PrefixAdminLimit',
    'cisco_bgp_peer2_prefixthreshold'     => 'cbgpPeer2PrefixThreshold',
    'cisco_bgp_peer2_prefixclearthreshold'=> 'cbgpPeer2PrefixClearThreshold',
    'cisco_bgp_peer2_advertisedprefixes'  => 'cbgpPeer2AdvertisedPrefixes',
    'cisco_bgp_peer2_suppressedprefixes'  => 'cbgpPeer2SuppressedPrefixes',
    'cisco_bgp_peer2_withdrawnprefixes'   => 'cbgpPeer2WithdrawnPrefixes',
);

%MUNGE = (
    'cisco_bgp_peer2_localaddr'           => \&SNMP::Info::munge_inetaddress,
    'cisco_bgp_peer2_lasterror'           => \&SNMP::Info::munge_octet2hex,
);

sub parse_cisco_bgp_peer2_entry_index {
    my ($self, $index) = @_;
    my ($type, $addrlength, $ip) = split(/\./, $index, 3);
    # decode IPv6 remote address
    if ($addrlength == 16) {
        # copied from SNMP::Info::IPv6/ipv6_addr
        my @parts = split(/\./, $ip);
        $ip = sprintf("%x:%x:%x:%x:%x:%x:%x:%x",
            unpack('n8', pack('C*', @parts)));
    }
    return $type, $addrlength, $ip;
}

1;
__END__

=head1 NAME

SNMP::Info::CiscoBGP - SNMP Interface to Cisco's BGP MIBs

=head1 AUTHOR

Alexander Hartmaier

=head1 SYNOPSIS

# Let SNMP::Info determine the correct subclass for you.
my $device = SNMP::Info->(
    AutoSpecify => 1,
    Debug       => 1,
    DestHost    => 'myswitch',
    Community   => 'public',
    Version     => 2
) or die "Can't connect to DestHost.\n";

my $remoteas_for_index = $device->cisco_bgp_peer2_remoteas;

for my $index (keys $remoteas_for_index->%*) {
    my ($type, $addrlength, $ip) =
        $device->parse_cisco_bgp_peer2_entry_index($index);
    printf('remote: %-39s  type: %-4s  remote AS: %5d',
        $ip, $type, $remoteas_for_index->{$index});
}

=head1 DESCRIPTION

SNMP::Info::CiscoBGP is a subclass of SNMP::Info that provides
information about a cisco device's BGP configuration and state.

Use or create in a subclass of SNMP::Info.  Do not use directly.

=head2 Inherited Classes

none.

=head2 Required MIBs

=over

=item F<CISCO-BGP4-MIB>

=back

=head1 GLOBALS

=over

None

=back

=head1 TABLE METHODS

=head2 Cisco BGP Peer 2 Table (cbgpPeer2Table)

This table contains, one entry per BGP peer, information about the connections
with BGP peers.

=over

=item cisco_bgp_peer2_state (cbgpPeer2State)

=item cisco_bgp_peer2_adminstatus (cbgpPeer2AdminStatus)

=item cisco_bgp_peer2_localaddr (cbgpPeer2LocalAddr)

=item cisco_bgp_peer2_localport (cbgpPeer2LocalPort)

=item cisco_bgp_peer2_localas (cbgpPeer2LocalAs)

=item cisco_bgp_peer2_localidentifier (cbgpPeer2LocalIdentifier)

=item cisco_bgp_peer2_remoteport (cbgpPeer2RemotePort)

=item cisco_bgp_peer2_remoteas (cbgpPeer2RemoteAs)

=item cisco_bgp_peer2_remoteidentifier (cbgpPeer2RemoteIdentifier)

=item cisco_bgp_peer2_inupdates (cbgpPeer2InUpdates)

=item cisco_bgp_peer2_outupdates (cbgpPeer2OutUpdates)

=item cisco_bgp_peer2_intotalmessages (cbgpPeer2InTotalMessages)

=item cisco_bgp_peer2_outtotalmessages (cbgpPeer2OutTotalMessages)

=item cisco_bgp_peer2_lasterror (cbgpPeer2LastError)

=item cisco_bgp_peer2_fsmestablishedtransitions (cbgpPeer2FsmEstablishedTransitions)

=item cisco_bgp_peer2_fsmestablishedtime (cbgpPeer2FsmEstablishedTime)

=item cisco_bgp_peer2_connectretryinterval (cbgpPeer2ConnectRetryInterval)

=item cisco_bgp_peer2_holdtime (cbgpPeer2HoldTime)

=item cisco_bgp_peer2_keepalive (cbgpPeer2KeepAlive)

=item cisco_bgp_peer2_holdtimeconfigured (cbgpPeer2HoldTimeConfigured)

=item cisco_bgp_peer2_keepaliveconfigured (cbgpPeer2KeepAliveConfigured)

=item cisco_bgp_peer2_minasoriginationinterval (cbgpPeer2MinASOriginationInterval)

=item cisco_bgp_peer2_inupdatelapsedtime (cbgpPeer2InUpdateElapsedTime)

=item cisco_bgp_peer2_lasterrortxt (cbgpPeer2LastErrorTxt)

=item cisco_bgp_peer2_prevstate (cbgpPeer2PrevState)

=back

=head2 Cisco BGP Peer 2 Address Family Prefix Table (cbgpPeer2AddrFamilyPrefixTable)

This table contains prefix related information related to address families
supported by a peer.

=over

=item cisco_bgp_peer2_acceptedprefixes (cbgpPeer2AcceptedPrefixes)

=item cisco_bgp_peer2_deniedprefixes (cbgpPeer2DeniedPrefixes)

=item cisco_bgp_peer2_prefixadminlimit (cbgpPeer2PrefixAdminLimit)

=item cisco_bgp_peer2_prefixthreshold (cbgpPeer2PrefixThreshold)

=item cisco_bgp_peer2_prefixclearthreshold (cbgpPeer2PrefixClearThreshold)

=item cisco_bgp_peer2_advertisedprefixes (cbgpPeer2AdvertisedPrefixes)

=item cisco_bgp_peer2_suppressedprefixes (cbgpPeer2SuppressedPrefixes)

=item cisco_bgp_peer2_withdrawnprefixes (cbgpPeer2WithdrawnPrefixes)

=back

=head2 METHODS

=over

=item parse_cisco_bgp_peer2_entry_index

Takes a cbgpPeer2Entry index as returned by all methods of the Cisco BGP Peer
2 Table methods.

Returns a list of type (numeric, cbgpPeer2Type), address length (in bytes:
4 for IPv4, 16 for IPv6) and the remote IP address as string.

=back

=cut
