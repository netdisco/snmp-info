# SNMP::Info::Layer3::Nexus
#
# Copyright (c) 2014 Eric Miller
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

package SNMP::Info::Layer3::Nexus;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3::CiscoSwitch;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

# NOTE : Top-most items gets precedence for @ISA
@SNMP::Info::Layer3::Nexus::ISA = qw/
	SNMP::Info::Layer3::CiscoSwitch
	Exporter
/;

@SNMP::Info::Layer3::Nexus::EXPORT_OK = qw//;

$VERSION = '3.983000';

# NOTE: Order creates precedence
#       Example: v_name exists in Bridge.pm and CiscoVTP.pm
#       Bridge is called from Layer3 and CiscoStpExtensions
#       So we want CiscoVTP to come last to get the right one.
# The @ISA order should be reverse of these orders.

%MIBS = (
    %SNMP::Info::Layer3::CiscoSwitch::MIBS,
    'CISCO-ENTITY-VENDORTYPE-OID-MIB'   => 'cevMIBObjects',
    'CISCO-CONTEXT-MAPPING-MIB'         => 'cContextMappingMIBObjects',
    'SNMP-COMMUNITY-MIB'                => 'snmpCommunityName',
    'CISCO-VPC-MIB'                     => 'cVpcRoleStatus',
);

%GLOBALS = (
    %SNMP::Info::Layer3::CiscoSwitch::GLOBALS,
    'mac' => 'dot1dBaseBridgeAddress',
);

%FUNCS = (
    %SNMP::Info::Layer3::CiscoSwitch::FUNCS,
    'vrf_name'         => 'cContextMappingVrfName',
    'vrf_comm_name'    => 'snmpCommunityName',
    'vrf_comm_context' => 'snmpCommunityContextName',

    # CISCO-VPC-MIB::cVpcRoleTable
    'vpc_role'       => 'cVpcRoleStatus',
    'vpc_system_mac' => 'cVpcSystemOperMacAddress',
    # CISCO-VPC-MIB::cVpcPeerKeepAliveConfigTable
    'vpc_keepalive_peer' => 'cVpcPeerKeepAliveDestAddr',
    # CISCO-VPC-MIB::cVpcPeerKeepAliveTable
    'vpc_keepalive_stat' => 'cVpcPeerKeepAliveStatus',
    # CISCO-VPC-MIB::cVpcStatusPeerLinkTable
    'vpc_peer_link' => 'cVpcStatusPeerLinkIfIndex',
    # CISCO-VPC-MIB::cVpcStatusHostLinkTable
    'vpc_host_link_if'   => 'cVpcStatusHostLinkIfIndex',
    'vpc_host_link_stat' => 'cVpcStatusHostLinkStatus',
);

%MUNGE = (
    %SNMP::Info::Layer3::CiscoSwitch::MUNGE,
    'vpc_system_mac'     => \&SNMP::Info::munge_mac,
    'vpc_keepalive_peer' => \&SNMP::Info::munge_inetaddress,
);

sub os {
	return 'nx-os';
}

sub os_ver {
	my $nexus = shift;
	my $descr = $nexus->description();

	return $1 if ( $descr =~ /\),\s+Version\s+(.+?),/ );
	return $descr;
}

sub _lag_vendor_walked {
	return qw/vpc_role vpc_system_mac vpc_keepalive_peer vpc_keepalive_stat
		vpc_peer_link vpc_host_link_if vpc_host_link_stat/;
}

# Every vPC domain has a cVpcRoleTable row, indexed by the domain id
sub _lag_vendor_domains {
	my $nexus = shift;

	my %columns = (
		role       => [ vpc_role           => 'cVpcRoleStatus' ],
		system_mac => [ vpc_system_mac     => 'cVpcSystemOperMacAddress' ],
		peer       => [ vpc_keepalive_peer => 'cVpcPeerKeepAliveDestAddr' ],
		status     => [ vpc_keepalive_stat => 'cVpcPeerKeepAliveStatus' ],
		peer_link  => [ vpc_peer_link      => 'cVpcStatusPeerLinkIfIndex' ],
	);
	my $domains = {};
	foreach my $domain_id ( keys %{ $nexus->vpc_role() || {} } ) {
		my $domain = { kind => 'vpc', sources => {} };
		foreach my $field ( keys %columns ) {
			my ( $method, $leaf ) = @{ $columns{$field} };
			my $value = ( $nexus->$method() || {} )->{$domain_id};
			next if !defined $value or $value eq '';
			next if $field eq 'peer_link' and !$value;
			$domain->{$field} = $value;
			$domain->{sources}{$field} = 'CISCO-VPC-MIB::' . $leaf;
		}
		$domains->{$domain_id} = $domain;
	}
	return $domains;
}

sub _lag_vendor_groups {
	my ( $nexus, $groups ) = @_;

	$nexus->_vpc_mark_peer_links($groups);
	$nexus->_vpc_add_host_links($groups);
	return;
}

# A channel the device reports only through the vPC tables still gets a record
sub _vpc_group_record {
	my ( $groups, $ifindex ) = @_;

	return $groups->{$ifindex}
		||= SNMP::Info::IEEE802dot3ad::_lag_new_record();
}

sub _vpc_mark_peer_links {
	my ( $nexus, $groups ) = @_;

	my $peer_links = $nexus->vpc_peer_link() || {};
	foreach my $ifindex ( values %$peer_links ) {
		next unless $ifindex;
		my $record = _vpc_group_record( $groups, $ifindex );
		$record->{peer_link} = 1;
		$record->{sources}{peer_link}
			= 'CISCO-VPC-MIB::cVpcStatusPeerLinkIfIndex';
	}
	return;
}

# The host link table is indexed domain.vpcId
sub _vpc_add_host_links {
	my ( $nexus, $groups ) = @_;

	my $channels = $nexus->vpc_host_link_if()   || {};
	my $states   = $nexus->vpc_host_link_stat() || {};
	foreach my $iid ( keys %$channels ) {
		next unless $channels->{$iid};
		my ( $domain_id, $vpc_id ) = split /\./, $iid;
		my $record = _vpc_group_record( $groups, $channels->{$iid} );
		$record->{mc} = {
			kind   => 'vpc',
			group  => $vpc_id,
			domain => $domain_id,
			state  => $states->{$iid},
		};
		$record->{sources}{mc} = 'CISCO-VPC-MIB::cVpcStatusHostLinkIfIndex';
	}
	return;
}

sub _context_kinds {
	my ( $nexus, $feature ) = @_;

	return [ 'vlan', 'mst' ] if $feature eq 'stp';
	return ['vrf'] if $feature eq 'vrf';
	return;
}

# NX-OS refuses a community map for VLAN and MST contexts: SNMPv3 only.
# An MST context exists only under MST, so it is offered only where
# cContextMappingTable lists it (index: the length-prefixed context name).
sub _snmp_context {
	my ( $nexus, $kind, $id ) = @_;

	return unless defined $kind and defined $id;
	return { kind => 'vlan', id => $id, v2c => undef, v3 => "vlan-$id" }
		if $kind eq 'vlan';
	return $nexus->_vrf_snmp_context($id) if $kind eq 'vrf';
	return unless $kind eq 'mst';

	my $name   = "mst-$id";
	my $mapped = $nexus->vrf_name() || {};
	my $index  = join( '.', length $name, map {ord} split //, $name );
	return unless exists $mapped->{$index};
	return { kind => 'mst', id => $id, v2c => undef, v3 => $name };
}

# Each distinct non-empty VRF name cContextMappingTable maps. An empty
# value is a VLAN or MST context, never a VRF; any row lists default.
sub _vrf_vendor_instances {
	my $nexus = shift;

	my $mapped = $nexus->vrf_name() || {};
	my %instances;
	foreach my $name ( grep { defined && length } values %$mapped ) {
		next if $name eq 'default';
		my $record = SNMP::Info::VRF::_vrf_record( $name, 'vrf', 'device' );
		$record->{sources}{list} = 'CISCO-CONTEXT-MAPPING-MIB';
		$instances{$name} = $record;
	}
	$nexus->_vrf_list_default( \%instances, 'CISCO-CONTEXT-MAPPING-MIB' )
		if %$mapped;
	return \%instances;
}

sub _vrf_vendor_list_methods { return ('vrf_name'); }

# Layer3::Cisco reads CISCO-VRF-MIB membership; Nexus lists from the
# context map, which holds no ports
sub _vrf_vendor_membership { return {}; }

# Each VRF context serves only its own address rows, but ifTable and the
# IPv6 neighbors of other VRFs' ports too
sub _vrf_context_filters { return 1; }

# The context cContextMappingTable maps to the VRF: the one named like the
# VRF, else the lowest sorted name; with none mapped, the VRF name, unless
# that name is a context mapped to another VRF. The default VRF is the
# default context, and an unnamed one is not a VRF.
sub _vrf_snmp_context {
	my ( $nexus, $name ) = @_;

	return if !defined $name or $name eq q() or $name eq 'default';
	my $mapped = $nexus->vrf_name() || {};
	my ( %contexts, %of_other_vrf );
	foreach my $index ( keys %$mapped ) {
		next unless defined $mapped->{$index} and length $mapped->{$index};
		my ( $length, @octets ) = split /\./, $index;
		next unless $length == @octets;
		my $context = join q(), map {chr} @octets;
		my $owner = $mapped->{$index} eq $name ? \%contexts : \%of_other_vrf;
		$owner->{$context} = 1;
	}
	return if !%contexts and $of_other_vrf{$name};
	my ($context) = exists $contexts{$name} ? $name : sort keys %contexts;
	return {
		kind => 'vrf',
		id   => $name,
		v2c  => undef,
		v3   => defined $context ? $context : $name,
	};
}

# The context the session's own SNMP-COMMUNITY-MIB row maps its community
# to. NX-OS serves snmpCommunityName only on the row of the community the
# session uses, and the context name on every row. '' is the default
# context. Undef when the session is SNMPv3 (its Context decides), the
# table is not served, or no row carries the session's community.
sub _vrf_community_context {
	my $nexus = shift;

	my $session   = $nexus->session() || {};
	my $community = $session->{Community};
	my $version   = $session->{Version};
	return if defined $version and $version eq '3';
	return unless defined $community and length $community;

	my $names = $nexus->vrf_comm_name() || {};
	foreach my $index ( sort keys %$names ) {
		next unless defined $names->{$index};
		next unless $names->{$index} eq $community;
		return ( $nexus->vrf_comm_context() || {} )->{$index};
	}
	return;
}

sub _get_snmpid_chassis {
	my $self = shift;
	my $funcname = (caller(0))[3]; # Name of this sub, including package, used for debug logging

	my $snmpid_chassis;
	my $position;

	my $entity_entry = $self->e_class;
	for ( keys %$entity_entry ) {
		# filter by class (chassis is 3, but with proper MIBs loaded we should get the translated textual value)
		if ( ($entity_entry->{$_} eq 'chassis') or ($entity_entry->{$_} eq '3') ) {
		printf("%s - chassis with id %s found, position %s\n", $funcname, $_, $self->e_pos->{$_}) if $self->debug();

			# and if it's the topmost one
			if ( !defined $position || $self->e_pos->{$_} < $position ) {
				$snmpid_chassis = $_;
				$position = $self->e_pos->{$_};
			}
		}
	}
	if ( defined $snmpid_chassis && defined $position ) {
		printf(" %s - chassis with id %s, position %s selected\n", $funcname, $snmpid_chassis, $position) if $self->debug();
	} else {
		printf(" %s - no chassis found\n", $funcname) if $self->debug();
	}

	return $snmpid_chassis;
}

sub serial {
	my $nexus = shift;
        my $snmpid_chassis = $nexus->_get_snmpid_chassis;
        return $nexus->e_serial($snmpid_chassis)->{$snmpid_chassis} if defined $snmpid_chassis;
	return;
}

# sysObjectID returns an IID to an entry in the CISCO-ENTITY-VENDORTYPE-OID-MIB.
# Look it up and return it.
sub model {
	my $nexus = shift;
	my $id    = $nexus->id();

	unless ( defined $id ) {
		print " SNMP::Info::Layer3::Nexus::model() - Device does not support sysObjectID\n" if $nexus->debug();
		return;
	}

	my $model = &SNMP::translateObj($id);

	return $id unless defined $model;

	$model =~ s/^cevChassis//i;
	return $model;
}

# nx-os 6 seems to swap the data of lldpLocPortDesc with that of
# lldpLocPortId, so remap it to make the main lldp module happy.
# nx-os 7 behaves as expected.
sub lldp_lport_desc {
    my $nexus         = shift;
    my $osver         = $nexus->os_ver();

    if (defined ($osver)) {
        if ($osver =~ /^6.*/) {
            return $nexus->SUPER::lldp_lport_id();
        }
    }
    return $nexus->SUPER::lldp_lport_desc();
}

# Reported version 6.x of NX-OS doesn't use the IPv4 address as index
# override methods in ipAddrTable
sub ip_table {
	my $nexus         = shift;
	my $orig_ip_table = $nexus->SUPER::ip_table();

	my %ip_table;
	foreach my $iid ( keys %$orig_ip_table ) {
		my $ip = $orig_ip_table->{$iid};
		next unless defined $ip;

		$ip_table{$ip} = $ip;
	}

	my $local_addrs = $nexus->_local_addr();
	foreach my $addr (keys %$local_addrs) {
		$ip_table{$addr} = $addr unless exists $ip_table{$addr};
	}

	return \%ip_table;
}

sub ip_index {
	my $nexus         = shift;
	my $orig_ip_table = $nexus->SUPER::ip_table();
	my $orig_ip_index = $nexus->SUPER::ip_index();

	my %ip_index;
	foreach my $iid ( keys %$orig_ip_table ) {
		my $ip    = $orig_ip_table->{$iid};
		my $index = $orig_ip_index->{$iid};

		next unless ( defined $ip && defined $index );

		$ip_index{$ip} = $index;
	}

	my $local_addrs = $nexus->_local_addr();
	foreach my $addr (keys %$local_addrs) {
		$ip_index{$addr} = 0 unless exists $ip_index{$addr};
	}

	return \%ip_index;
}

sub ip_netmask {
	my $nexus           = shift;
	my $orig_ip_table   = $nexus->SUPER::ip_table();
	my $orig_ip_netmask = $nexus->SUPER::ip_netmask();

	my %ip_netmask;
	foreach my $iid ( keys %$orig_ip_table ) {
		my $ip      = $orig_ip_table->{$iid};
		my $netmask = $orig_ip_netmask->{$iid};

		next unless ( defined $ip && defined $netmask );

		$ip_netmask{$ip} = $netmask;
	}

	my $local_addrs = $nexus->_local_addr();
	foreach my $addr (keys %$local_addrs) {
		$ip_netmask{$addr} = $local_addrs->{$addr} unless exists $ip_netmask{$addr};
	}

	return \%ip_netmask;
}

sub ip_broadcast {
	my $nexus             = shift;
	my $orig_ip_table     = $nexus->SUPER::ip_table();
	my $orig_ip_broadcast = $nexus->SUPER::ip_broadcast();

	my %ip_broadcast;
	foreach my $iid ( keys %$orig_ip_table ) {
		my $ip        = $orig_ip_table->{$iid};
		my $broadcast = $orig_ip_broadcast->{$iid};

		next unless ( defined $ip && defined $broadcast );

		$ip_broadcast{$ip} = $broadcast;
	}

	my $local_addrs = $nexus->_local_addr();
	foreach my $addr (keys %$local_addrs) {
		$ip_broadcast{$addr} = $addr unless exists $ip_broadcast{$addr};
	}

	return \%ip_broadcast;
}

sub _local_addr {
	my $nexus = shift;
	my $listen_addr = $nexus->udpLocalAddress() || {};
	my %local_addr;
	foreach my $sock (keys %$listen_addr) {
		my $addr = $listen_addr->{$sock};
		next if ($addr =~ /^127\./); # localhost
		next if ($addr eq '0.0.0.0'); # "any"
		next if ($addr =~ /^(\d+)\./ and $1 ge 224); # Class D or E space: Multicast or Experimental
		$local_addr{$addr} = '255.255.255.255'; # Fictional netmask
	}
	return \%local_addr;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Nexus - SNMP Interface to Cisco Nexus Switches running
NX-OS

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $nexus = new SNMP::Info(
						AutoSpecify => 1,
						Debug       => 1,
						# These arguments are passed directly to SNMP::Session
						DestHost    => 'myswitch',
						Community   => 'public',
						Version     => 2
						)
	or die "Can't connect to DestHost.\n";

 my $class      = $nexus->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for Cisco Nexus Switches running NX-OS.

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above.

 my $nexus = new SNMP::Info::Layer3::Nexus(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3::CiscoSwitch

=back

=head2 Required MIBs

=over

=item F<CISCO-ENTITY-VENDORTYPE-OID-MIB>

=item F<CISCO-CONTEXT-MAPPING-MIB>

=item F<SNMP-COMMUNITY-MIB>

=item F<CISCO-VPC-MIB>

=back

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3::CiscoSwitch/"Required MIBs"> for its own MIB
requirements.

=back

=head1 GLOBALS

These are methods that return a scalar value from SNMP

=over

=item $nexus->os()

Returns C<'nx-os'>

=item $nexus->os_ver()

Returns operating system version extracted from C<sysDescr>.

=item $nexus->serial()

Returns the serial number of the chassis from F<ENTITY-MIB>.

=item $nexus->model()

Tries to reference $nexus->id() to F<CISCO-ENTITY-VENDORTYPE-OID-MIB>

Removes C<'cevChassis'> for readability.

=item $nexus->mac()

C<dot1dBaseBridgeAddress>

=item $nexus->context_kinds($feature)

See C<context_kinds()> in L<SNMP::Info>.  Returns C<['vlan', 'mst']> for
C<stp>, and C<['vlan']> for C<fdb>, and C<['vrf']> for C<vrf>.

=item $nexus->snmp_context($kind, $id)

See C<snmp_context()> in L<SNMP::Info>.  NX-OS serves VLAN and MST
contexts over SNMPv3 only, so C<v2c> is undef for both kinds:

=over

=item C<vlan>

The context C<vlan-N> for VLAN N.

=item C<mst>

The context C<mst-N> for MST instance N, only where
C<cContextMappingTable> lists it, which it does only under MST.
C<mst-0> serves the CIST's C<dot1dStpPortTable>, which the default
context does not.  C<cist.0> still has C<ports_complete> 0
(L<SNMP::Info::CiscoStpExtensions/"Spanning Tree Trees">).

=back

For C<vrf>, C<$id> is a name from C<vrf_instances()> and the answer is
C<{ kind =E<gt> 'vrf', id =E<gt> $name, v2c =E<gt> undef,
v3 =E<gt> $context }>.  C<$context> is a context C<cContextMappingTable>
maps to the VRF, chosen in this order:

=over

=item *

the context named like the VRF, if it is mapped to the VRF;

=item *

else the lowest sorted name among the contexts mapped to the VRF;

=item *

else the VRF name itself.

=back

Nothing is returned for:

=over

=item *

the default VRF and an empty name, which have no context;

=item *

a VRF with no mapped context whose name is a context mapped to another
VRF.  Its C<contexts> in C<vrf_instances()> is then empty.

=back

C<v2c> is undef: NX-OS reaches a VRF over SNMPv2c only through a site's
community map (C<snmp-server mib community-map>), whose community the
class cannot derive.  A session on such a community reads as the context
its own C<snmpCommunityTable> row names (see C<vrf_comm_name()>).  The
readers accept it where that is the context C<snmp_context('vrf', $name)>
gives.  Where the row is not served, the session reads as the default
context; read VRF contexts over SNMPv3.

VRF reads use context mode (see L<SNMP::Info::VRF/"Reading Instances">).
Each VRF context serves only that VRF's address rows, but C<ifTable> is
not scoped, and the default context serves the IPv6 neighbors of every
VRF's ports.  The readers therefore keep only the rows on ports holding
an address in the current context.

C<cContextMappingTable> lists the VRFs.  Any row it serves lists
C<default>, so a device that maps only VLAN or MST contexts reports
C<vrf_instances_complete()> 1, none configured (see
L<SNMP::Info::VRF/"Completeness">).

=back

=head2 Overrides

=head3 IP Address Table

Each entry in this table is an IP address in use on this device.  Some
versions do not index the table with the IPv4 address in accordance with
the MIB definition, these overrides correct that behavior.

Also, the table is augmented with IP addresses in use by UDP sockets on the
device, as determined by checking F<RFC1213-MIB::udpLocalAddress>. Valid
addresses from this table (any IPv4 that is not localhost, 0.0.0.0, Class D
(multicast) or Class E (experimental) are added as a /32 on interface ID 0.
This is a workaround to determine possible VPC Keepalive IP addresses on the
device, which are probably advertised by CDP/LLDP to neighbors.

=over

=item $nexus->ip_index()

Maps the IP Table to the IID

(C<ipAdEntIfIndex>)

=item $nexus->ip_table()

Maps the Table to the IP address

(C<ipAdEntAddr>)

=item $nexus->ip_netmask()

Gives netmask setting for IP table entry.

(C<ipAdEntNetMask>)

=item $nexus->ip_broadcast()

Gives broadcast address for IP table entry.

(C<ipAdEntBcastAddr>)

=item $nexus->lldp_lport_desc()

On nx-os 6 only this will return data from C<lldpLocPortId> instead of
the expected C<lldpLocPortDesc>. For all other nx-os versions uses the
function from L<SNMP::Info::LLDP>.

=back

=head2 Globals imported from SNMP::Info::Layer3::CiscoSwitch

See documentation in L<SNMP::Info::Layer3::CiscoSwitch/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 SNMP Community Table (C<snmpCommunityTable>)

=over

=item $nexus->vrf_comm_name()

Returns reference to hash of community strings, keyed by the
length-prefixed C<snmpCommunityIndex>.  NX-OS serves the community only
on the row the session itself uses, and an empty string on every other
row.

(C<snmpCommunityName>)

=item $nexus->vrf_comm_context()

Returns reference to hash of the SNMP context each community row maps
to, keyed as C<vrf_comm_name()>: empty for the default context, a context
name for a community set by C<snmp-server mib community-map>.

(C<snmpCommunityContextName>)

=back

=head2 Link Aggregation

=over

=item $nexus->lag_groups()

As described in L<SNMP::Info::IEEE802dot3ad/"METHODS">, with:

=over

=item *

C<mc> on the channel named by each vPC host link
(C<cVpcStatusHostLinkIfIndex>): C<kind> C<vpc>, C<group> the vPC id,
C<domain> the vPC domain id, and C<state> the host link status
(C<cVpcStatusHostLinkStatus>).

=item *

C<peer_link> on the channel named by C<cVpcStatusPeerLinkIfIndex>.

=item *

A static channel has no F<IEEE8023-LAG-MIB> row: C<lacp> is 0 and the
actor and partner fields are undef.

=back

=item $nexus->mlag_domains()

As described in L<SNMP::Info::IEEE802dot3ad/"METHODS">, keyed by vPC
domain id (C<cVpcRoleTable>), with C<kind> C<vpc> and these fields:

=over

=item *

C<system_mac>: C<cVpcSystemOperMacAddress>.

=item *

C<role>: C<cVpcRoleStatus>.

=item *

C<peer>: the peer keepalive destination, C<cVpcPeerKeepAliveDestAddr>.

=item *

C<peer_link>: C<cVpcStatusPeerLinkIfIndex>.

=item *

C<status>: the peer keepalive status, C<cVpcPeerKeepAliveStatus>.

=back

=back

=head2 vPC Tables (F<CISCO-VPC-MIB>)

=over

=item $nexus->vpc_role()

(C<cVpcRoleStatus>)

=item $nexus->vpc_system_mac()

(C<cVpcSystemOperMacAddress>)

=item $nexus->vpc_keepalive_peer()

(C<cVpcPeerKeepAliveDestAddr>)

=item $nexus->vpc_keepalive_stat()

(C<cVpcPeerKeepAliveStatus>)

=item $nexus->vpc_peer_link()

(C<cVpcStatusPeerLinkIfIndex>)

=item $nexus->vpc_host_link_if()

(C<cVpcStatusHostLinkIfIndex>)

=item $nexus->vpc_host_link_stat()

(C<cVpcStatusHostLinkStatus>)

=back

=head2 Table Methods imported from SNMP::Info::Layer3::CiscoSwitch

See documentation in L<SNMP::Info::Layer3::CiscoSwitch/"TABLE METHODS"> for
details.

=cut
