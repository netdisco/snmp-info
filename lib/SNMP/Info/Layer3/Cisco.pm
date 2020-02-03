# SNMP::Info::Layer3::Cisco
#
# Copyright (c) 2008 Max Baker
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

package SNMP::Info::Layer3::Cisco;

use strict;
use warnings;
use Exporter;
use SNMP::Info::CiscoVTP;
use SNMP::Info::CDP;
use SNMP::Info::CiscoStats;
use SNMP::Info::CiscoRTT;
use SNMP::Info::CiscoQOS;
use SNMP::Info::CiscoConfig;
use SNMP::Info::CiscoPower;
use SNMP::Info::CiscoStpExtensions;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Cisco::ISA = qw/SNMP::Info::CiscoVTP
    SNMP::Info::CDP
    SNMP::Info::CiscoStats SNMP::Info::CiscoRTT
    SNMP::Info::CiscoQOS SNMP::Info::CiscoConfig
    SNMP::Info::CiscoPower SNMP::Info::CiscoStpExtensions
    SNMP::Info::Layer3
    Exporter/;
@SNMP::Info::Layer3::Cisco::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.70';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::CiscoStpExtensions::MIBS,
    %SNMP::Info::CiscoPower::MIBS,
    %SNMP::Info::CiscoConfig::MIBS,
    %SNMP::Info::CiscoQOS::MIBS,
    %SNMP::Info::CiscoRTT::MIBS,
    %SNMP::Info::CiscoStats::MIBS,
    %SNMP::Info::CDP::MIBS,
    %SNMP::Info::CiscoVTP::MIBS,
    'CISCO-EIGRP-MIB' => 'cEigrpAsRouterId',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::CiscoStpExtensions::GLOBALS,
    %SNMP::Info::CiscoPower::GLOBALS,
    %SNMP::Info::CiscoConfig::GLOBALS,
    %SNMP::Info::CiscoQOS::GLOBALS,
    %SNMP::Info::CiscoRTT::GLOBALS,
    %SNMP::Info::CiscoStats::GLOBALS,
    %SNMP::Info::CDP::GLOBALS,
    %SNMP::Info::CiscoVTP::GLOBALS,
    'eigrp_id' => 'cEigrpAsRouterId',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::CiscoStpExtensions::FUNCS,
    %SNMP::Info::CiscoPower::FUNCS,
    %SNMP::Info::CiscoConfig::FUNCS,
    %SNMP::Info::CiscoQOS::FUNCS,
    %SNMP::Info::CiscoRTT::FUNCS,
    %SNMP::Info::CiscoStats::FUNCS,
    %SNMP::Info::CDP::FUNCS,
    %SNMP::Info::CiscoVTP::FUNCS,

    # CISCO-EIGRP-MIB::cEigrpPeerTable
    'c_eigrp_peer_types' => 'cEigrpPeerAddrType',
    'c_eigrp_peers'      => 'cEigrpPeerAddr',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,     %SNMP::Info::CiscoStpExtensions::MUNGE,
    %SNMP::Info::CiscoPower::MUNGE, %SNMP::Info::CiscoConfig::MUNGE,
    %SNMP::Info::CiscoQOS::MUNGE,   %SNMP::Info::CiscoRTT::MUNGE,
    %SNMP::Info::CiscoStats::MUNGE, %SNMP::Info::CDP::MUNGE,
    %SNMP::Info::CiscoVTP::MUNGE,
);

sub i_vlan {
    my $cisco   = shift;
    my $partial = shift;

    my $i_type  = $cisco->i_type($partial);
    my $i_descr = $cisco->i_description($partial);
    my $i_vlan  = $cisco->SUPER::i_vlan($partial);

    foreach my $idx ( keys %$i_descr ) {
        next unless $i_type->{$idx};
        if (   $i_type->{$idx} eq 'l2vlan'
            || $i_type->{$idx} eq '135' && !defined $i_vlan->{$idx} )
        {
            # Not sure where this regex came from, anchored at end?
            if ( $i_descr->{$idx} =~ /\.(\d+)$/ ) {
                $i_vlan->{$idx} = $1;
            }

            # This matches 101 in 'Ethernet0.101-802.1Q vLAN subif'
            elsif ( $i_descr->{$idx} =~ /\.(\d+)-/ ) {
                $i_vlan->{$idx} = $1;
            }
        }
    }
    return $i_vlan;
}

sub cisco_comm_indexing {
    my $cisco = shift;

    # If we get a VTP version, it's *extremely* likely that the device needs
    # community based indexing
    my $vtp = $cisco->vtp_version() || '0';
    return $vtp ? 1 : 0;
}

sub eigrp_peers {
    my $cisco = shift;

    my $peers = $cisco->c_eigrp_peers()      || {};
    my $types = $cisco->c_eigrp_peer_types() || {};

    my %eigrp_peers;
    foreach my $idx ( keys %$peers ) {
        my $type = $types->{$idx};
        next unless $type;
        my $peer = $peers->{$idx};
        next unless $peer;

        my $ip = NetAddr::IP::Lite->new($peer);

        if ($ip) {
            $eigrp_peers{$idx} = $ip->addr;
        }
        elsif ( $type eq 'ipv4' ) {
            $eigrp_peers{$idx} = SNMP::Info::munge_ip($peer);
        }
        next;
    }
    return \%eigrp_peers;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Cisco - SNMP Interface to L3 and L2+L3 IOS Cisco Device
that are not covered in other classes and the base L3 Cisco class for other
device specific L3 Cisco classes.


=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $cisco = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $cisco->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Generic Cisco Routers running IOS and the base L3 Cisco class
for other device specific L3 Cisco classes.

=head2 Inherited Classes

=over

=item SNMP::Info::CiscoVTP

=item SNMP::Info::CDP

=item SNMP::Info::CiscoStats

=item SNMP::Info::CiscoRTT

=item SNMP::Info::CiscoQOS

=item SNMP::Info::CiscoConfig

=item SNMP::Info::Power

=item SNMP::Info::CiscoStpExtensions

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<CISCO-EIGRP-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::CiscoVTP/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CDP/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoStats/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoRTT/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoQOS/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoConfig/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoPower/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoStpExtensions/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $cisco->eigrp_id()

(C<cEigrpAsRouterId>)

=item $switch->cisco_comm_indexing()

Returns 1 when the device is likely to need vlan indexing.
Determined by checking C<vtpVersion>.

=back

=head2 Global Methods imported from SNMP::Info::CiscoVTP

See documentation in L<SNMP::Info::CiscoVTP/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CDP

See documentation in L<SNMP::Info::CDP/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoStats

See documentation in L<SNMP::Info::CiscoStats/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoRTT

See documentation in L<SNMP::Info::CiscoRTT/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoQOS

See documentation in L<SNMP::Info::CiscoQOS/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoConfig

See documentation in L<SNMP::Info::CiscoConfig/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoPower

See documentation in L<SNMP::Info::CiscoPower/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoStpExtensions

See documentation in L<SNMP::Info::CiscoStpExtensions/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $cisco->eigrp_peers()

Returns EIGRP peer IP addresses

(C<cEigrpPeerAddr>)

=item $cisco->i_vlan()

Returns a mapping between C<ifIndex> and the PVID or default VLAN.

=back

=head2 Table Methods imported from SNMP::Info::CiscoVTP

See documentation in L<SNMP::Info::CiscoVTP/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CDP

See documentation in L<SNMP::Info::CDP/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoStats

See documentation in L<SNMP::Info::CiscoStats/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoRTT

See documentation in L<SNMP::Info::CiscoRTT/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoQOS

See documentation in L<SNMP::Info::CiscoQOS/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoConfig

See documentation in L<SNMP::Info::CiscoConfig/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoPower

See documentation in L<SNMP::Info::CiscoPower/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoStpExtensions

See documentation in L<SNMP::Info::CiscoStpExtensions/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
