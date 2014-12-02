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

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

# NOTE : Top-most items gets precedence for @ISA
@SNMP::Info::Layer3::Nexus::ISA = qw/
	SNMP::Info::Layer3::CiscoSwitch
	Exporter
	/;

@SNMP::Info::Layer3::Nexus::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.22';

# NOTE: Order creates precedence
#       Example: v_name exists in Bridge.pm and CiscoVTP.pm
#       Bridge is called from Layer3 and CiscoStpExtensions
#       So we want CiscoVTP to come last to get the right one.
# The @ISA order should be reverse of these orders.

%MIBS = (
	%SNMP::Info::Layer3::CiscoSwitch::MIBS,
	'CISCO-ENTITY-VENDORTYPE-OID-MIB' => 'cevMIBObjects',
);

%GLOBALS = (
	%SNMP::Info::Layer3::CiscoSwitch::GLOBALS,
	'mac' => 'dot1dBaseBridgeAddress',
);

%FUNCS = ( %SNMP::Info::Layer3::CiscoSwitch::FUNCS, );

%MUNGE = ( %SNMP::Info::Layer3::CiscoSwitch::MUNGE, );

sub os {
	return 'nx-os';
}

sub os_ver {
	my $nexus = shift;
	my $descr = $nexus->description();

	return $1 if ( $descr =~ /\),\s+Version\s+(.+?),/ );
	return $descr;
}

sub serial {
	my $nexus = shift;

	my $e_parent = $nexus->e_parent();

	foreach my $iid ( keys %$e_parent ) {
		my $parent = $e_parent->{$iid};
		if ( $parent eq '0' ) {
			my $serial = $nexus->e_serial($iid);
			return $serial->{$iid};
		}
	}
	return;
}

# sysObjectID returns an IID to an entry in the CISCO-ENTITY-VENDORTYPE-OID-MIB.
# Look it up and return it.
sub model {
	my $nexus = shift;
	my $id    = $nexus->id();

	unless ( defined $id ) {
		print
			" SNMP::Info::Layer3::Nexus::model() - Device does not support sysObjectID\n"
			if $nexus->debug();
		return;
	}

	my $model = &SNMP::translateObj($id);

	return $id unless defined $model;

	$model =~ s/^cevChassis//i;
	return $model;
}

# Reported version 6.x of NX-OS doesn't use the IPv4 address as index
# override methods in ipAddrTable
sub ip_table {
	my $nexus         = shift;
	my $orig_ip_table = $nexus->orig_ip_table();

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
	my $orig_ip_table = $nexus->orig_ip_table();
	my $orig_ip_index = $nexus->orig_ip_index();

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
	my $orig_ip_table   = $nexus->orig_ip_table();
	my $orig_ip_netmask = $nexus->orig_ip_netmask();

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
	my $orig_ip_table     = $nexus->orig_ip_table();
	my $orig_ip_broadcast = $nexus->orig_ip_broadcast();

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

=back

=head2 Globals imported from SNMP::Info::Layer3::CiscoSwitch

See documentation in L<SNMP::Info::Layer3::CiscoSwitch/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3::CiscoSwitch

See documentation in L<SNMP::Info::Layer3::CiscoSwitch/"TABLE METHODS"> for
details.

=cut
