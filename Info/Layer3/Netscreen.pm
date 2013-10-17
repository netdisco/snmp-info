# SNMP::Info::Layer3::Netscreen
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

package SNMP::Info::Layer3::Netscreen;

use strict;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::IEEE802dot11;

@SNMP::Info::Layer3::Netscreen::ISA
    = qw/SNMP::Info::Layer3 SNMP::Info::IEEE802dot11 Exporter/;
@SNMP::Info::Layer3::Netscreen::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE/;

$VERSION = '3.07_001';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::IEEE802dot11::MIBS,
    'NETSCREEN-SMI'           => 'netscreenSetting',
    'NETSCREEN-PRODUCTS-MIB'  => 'netscreenGeneric',
    'NETSCREEN-INTERFACE-MIB' => 'nsIfIndex',
    'NETSCREEN-SET-GEN-MIB'   => 'nsSetGenSwVer',
    'NETSCREEN-IP-ARP-MIB'    => 'nsIpArpAOD',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::IEEE802dot11::GLOBALS,
    'os_version' => 'nsSetGenSwVer',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::IEEE802dot11::FUNCS,

    ns_i_index       => 'nsIfIndex',
    ns_i_name        => 'nsIfName',
    ns_i_description => 'nsIfDescr',
    ns_i_mac         => 'nsIfMAC',
    ns_i_up          => 'nsIfStatus',
    ns_ip_table      => 'nsIfIp',
    ns_ip_netmask    => 'nsIfNetmask',
    at_index         => 'nsIpArpIfIdx',
    at_paddr         => 'nsIpArpMac',
    at_netaddr       => 'nsIpArpIp',
    bp_index         => 'nsIfInfo',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::IEEE802dot11::MUNGE,
    'ns_i_mac' => \&SNMP::Info::munge_mac,
    'at_paddr' => \&SNMP::Info::munge_mac,
);

sub layers {
    return '01001110';
}

sub vendor {
    return 'juniper';
}

sub os {
    return 'screenos';
}

sub os_ver {
    my $netscreen = shift;

    my $descr = $netscreen->description();
    if ( $descr =~ m/version (\d\S*) \(SN: / ) {
        return $1;
    }
    return;
}

sub serial {
    my $netscreen = shift;

    my $e_serial = $netscreen->e_serial() || {};

    my $serial = $e_serial->{1} || undef;

    return $1 if ( defined $serial and $serial =~ /(\d+)/ );
    my $descr = $netscreen->description();
    if ( $descr =~ m/version .*\(SN: (\d\S*),/ ) {
        return $1;
    }
    return;
}

sub model {
    my $netscreen = shift;

    my $id = $netscreen->id();

    unless ( defined $id ) {
        print
            " SNMP::Info::Layer3::model() - Device does not support sysObjectID\n"
            if $netscreen->debug();
        return;
    }

    my $model = &SNMP::translateObj($id);

    return $id unless defined $model;

    $model =~ s/^netscreen//i;
    return $model;
}

# provides mapping from IF-MIB to nsIf interfaces - many to 1 (!)
# - on WLAN devices wireless0/0(|-[ag]) -> wireless0/0 !!
sub _if_nsif_map {
    my $netscreen   = shift;
    my $i_descr     = $netscreen->SUPER::i_description;
    my $ns_descr    = $netscreen->i_description;
    my %if_nsif_map = ();
    my @ikeys       = sort { $a <=> $b } keys %$i_descr;
    my @nskeys      = sort { $a <=> $b } keys %$ns_descr;
    my $i           = 0;
    my $n           = 0;

    # assumes descriptions are in the same order from both walks
    while ( $i < @ikeys && $n < @nskeys ) {

        # find matching sub interfaces
        while (
            $i < @ikeys
            && substr(
                $i_descr->{ $ikeys[$i] },
                0,
                length $ns_descr->{ $nskeys[$n] }
            ) eq $ns_descr->{ $nskeys[$n] }
            )
        {

            $if_nsif_map{ $ikeys[$i] } = $nskeys[$n];
            $i++;
        }

        $n++;

        # skip non-matching interfaces (e.g. tunnel.N)
        while (
            $i < @ikeys
            && substr(
                $i_descr->{ $ikeys[$i] },
                0,
                length $ns_descr->{ $nskeys[$n] }
            ) ne $ns_descr->{ $nskeys[$n] }
            && $n < @nskeys
            )
        {

            $if_nsif_map{ $ikeys[$i] } = 0;    # no matching interface
            $i++;
        }
    }

    return \%if_nsif_map;
}

# Provides mapping from nsIf interfaces to IF-MIB interfaces - many to 1
# Example, tunnel.# interfaces are not present in IF-MIB.  There exist no
# mapping of index IID's between the tables so create mapping based on names
sub _nsif_if_map {
    my $netscreen = shift;

    my $i_descr      = $netscreen->SUPER::i_description;
    my $ns_descr     = $netscreen->i_description;
    my %rev_i_descr  = reverse %$i_descr;
    my %rev_ns_descr = reverse %$ns_descr;

    my %nsif_if_map = ();
    foreach my $value ( values %$ns_descr ) {
        if ( exists $rev_i_descr{$value} ) {
            $nsif_if_map{ $rev_ns_descr{$value} } = $rev_i_descr{$value};
        }
        else {
            $nsif_if_map{ $rev_ns_descr{$value} } = 0;
        }
    }
    return \%nsif_if_map;
}

sub interfaces {
    my $netscreen = shift;
    return $netscreen->i_description();
}

sub i_index {
    my $netscreen = shift;
    return $netscreen->ns_i_index();
}

sub i_name {
    my $netscreen = shift;
    return $netscreen->ns_i_name();
}

sub i_description {
    my $netscreen = shift;

    # Versions prior to 5.4 do not support nsIfDescr but do have nsIfName
    return $netscreen->ns_i_description() || $netscreen->ns_i_name();
}

sub i_mac {
    my $netscreen = shift;

    my $ns_mac   = $netscreen->ns_i_mac()     || {};
    my $if_i_mac = $netscreen->SUPER::i_mac() || {};
    my $ns_i_map = $netscreen->_nsif_if_map();

    my %i_mac = ();
    foreach my $iid ( keys %$ns_i_map ) {
        $i_mac{$iid} = $ns_mac->{$iid} || $if_i_mac->{ $ns_i_map->{$iid} };
    }

    return \%i_mac;
}

sub i_lastchange {
    my $netscreen = shift;

    my $if_i_lastchange = $netscreen->SUPER::i_lastchange() || {};
    my $ns_i_map = $netscreen->_nsif_if_map();
    my %i_lastchange;

    foreach my $iid ( keys %$ns_i_map ) {
        $i_lastchange{$iid} = $if_i_lastchange->{ $ns_i_map->{$iid} };
    }
    return \%i_lastchange;
}

sub i_up {
    my $netscreen = shift;
    return $netscreen->ns_i_up();
}

sub i_up_admin {
    my $netscreen  = shift;
    my $i_up       = $netscreen->i_up();
    my $i_up_admin = $netscreen->SUPER::i_up_admin();
    my $ns_i_map   = $netscreen->_nsif_if_map();
    my %i_up_admin;

    foreach my $iid ( keys %$ns_i_map ) {
        $i_up_admin{$iid} 
            = $i_up->{$iid} eq "up" && "up"
            || $i_up_admin->{ $ns_i_map->{$iid} }
            || 0;
    }
    return \%i_up_admin;
}

sub i_type {
    my $netscreen = shift;

    my $if_i_type = $netscreen->SUPER::i_type() || {};
    my $ns_i_map = $netscreen->_nsif_if_map();
    my %i_type;

    foreach my $iid ( keys %$ns_i_map ) {
        $i_type{$iid} = $if_i_type->{ $ns_i_map->{$iid} } || "tunnel";
    }
    return \%i_type;
}

sub i_mtu {
    my $netscreen = shift;

    my $i_type = $netscreen->SUPER::i_mtu() || {};
    my $ns_i_map = $netscreen->_nsif_if_map();
    my %i_mtu;

    foreach my $iid ( keys %$ns_i_map ) {
        $i_mtu{$iid} = $i_type->{ $ns_i_map->{$iid} };
    }
    return \%i_mtu;
}

sub i_ignore {
    return;
}

sub i_speed {
    my $netscreen = shift;

    my $i_speed  = $netscreen->SUPER::i_speed();
    my $i_name   = $netscreen->i_name();
    my $ns_i_map = $netscreen->_nsif_if_map;
    my %i_speed;

    foreach my $iid ( keys %$ns_i_map ) {
        $i_speed{$iid} 
            = $i_speed->{ $ns_i_map->{$iid} }
            || $i_name->{$iid} =~ /tunnel/ && "vpn"
            || 0;
    }
    return \%i_speed;
}

sub _mac_map {
    my $netscreen = shift;

    my $arp_mac = $netscreen->nsIpArpMac() || {};

    my %mac_map = ();
    foreach my $iid ( keys %$arp_mac ) {
        my $oid = join( ".", ( unpack( "C6", $arp_mac->{$iid} ) ) );
        $mac_map{$oid} = $iid;
    }
    return \%mac_map;
}

sub ip_index {
    my $netscreen = shift;

    my $ns_ip = $netscreen->ns_ip_table() || {};

    my %ip_index = ();
    foreach my $iid ( keys %$ns_ip ) {
        $ip_index{ $ns_ip->{$iid} } = $iid if $ns_ip->{$iid} ne "0.0.0.0";
    }
    return \%ip_index;
}

sub ip_table {
    my $netscreen = shift;

    my $ip_index = $netscreen->ip_index() || {};

    my %ip_table = ();
    foreach my $iid ( keys %$ip_index ) {
        $ip_table{$iid} = $iid;
    }
    return \%ip_table;
}

sub ip_netmask {
    my $netscreen = shift;

    my $ip_index = $netscreen->ip_index() || {};
    my $ns_netmask = $netscreen->ns_ip_netmask();

    my %ip_netmask = ();
    foreach my $iid ( keys %$ip_index ) {
        $ip_netmask{$iid} = $ns_netmask->{ $ip_index->{$iid} };
    }
    return \%ip_netmask;
}

sub fw_index {
    my $netscreen = shift;
    my %fw_index  = ();
    my $arp_mac   = $netscreen->nsIpArpMac() || {};

    foreach my $iid ( keys %$arp_mac ) {
        my $oid = join( ".", ( unpack( "C6", $arp_mac->{$iid} ) ) );
        $fw_index{$iid} = $oid;
    }
    return \%fw_index;
}

sub fw_mac {
    my $netscreen = shift;

    my $mac_map = $netscreen->_mac_map() || {};

    my %fw_mac = ();
    foreach my $oid ( keys %$mac_map ) {
        my $mac
            = join( ":", ( map { sprintf "%lx", $_ } split( /\./, $oid ) ) );
        $fw_mac{$oid} = $mac;
    }
    return \%fw_mac;
}

sub bp_index {
    my $netscreen = shift;

    my $if_info = $netscreen->nsIfInfo() || {};

    my %bp_index = ();
    foreach my $iid ( keys %$if_info ) {
        $bp_index{ $if_info->{$iid} } = $iid;
    }
    return \%bp_index;
}

sub fw_port {
    my $netscreen = shift;

    my $fw_index = $netscreen->fw_index();
    my $arp_if = $netscreen->nsIpArpIfIdx() || {};

    my %fw_port;
    foreach my $iid ( keys %$arp_if ) {
        $fw_port{ $fw_index->{$iid} } = $arp_if->{$iid}
            if defined $fw_index->{$iid};
    }
    return \%fw_port;
}

# need to remap from IF-MIB index to nsIf index
sub i_ssidlist {
    my $netscreen = shift;

    my $i_ssidlist = $netscreen->SUPER::i_ssidlist() || {};
    my $ns_i_map = $netscreen->_if_nsif_map();

    my %i_ssidlist;
    foreach my $iid ( keys %$i_ssidlist ) {
        $i_ssidlist{ $ns_i_map->{$iid} } = $i_ssidlist->{$iid};
    }
    return \%i_ssidlist;
}

sub i_80211channel {
    my $netscreen = shift;

    my $i_80211channel = $netscreen->SUPER::i_80211channel() || {};
    my $ns_i_map = $netscreen->_if_nsif_map();

    my %i_80211channel;
    foreach my $iid ( keys %$i_80211channel ) {
        $i_80211channel{ $ns_i_map->{$iid} } = $i_80211channel->{$iid};
    }
    return \%i_80211channel;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer3::Netscreen - SNMP Interface to Juniper Netscreen Devices

=head1 AUTHOR

Kent Hamilton

=head1 SYNOPSIS

    #Let SNMP::Info determine the correct subclass for you.

    my $netscreen = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 

    or die "Can't connect to DestHost.\n";

    my $class = $netscreen->class();
    print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a 
Juniper Netscreen devices through SNMP.

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

my $netscreen = new SNMP::Info::Layer3::Netscreen(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::IEEE802dot11

=back

=head2 Required MIBs

=over

=item F<NETSCREEN-SMI>

=item F<NETSCREEN-PRODUCTS-MIB>

=item F<NETSCREEN-INTERFACE-MIB>

=item F<NETSCREEN-SET-GEN-MIB>

=item F<NETSCREEN-IP-ARP-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its MIB requirements.

See L<SNMP::Info::IEEE802dot11/"Required MIBs"> for its MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $netscreen->model()

Tries to reference $netscreen->id() to F<NETSCREEN-PRODUCTS-MIB>

=item $netscreen->vendor()

Returns C<'juniper'>

=item $netscreen->os()

Returns C<'screenos'>

=item $netscreen->os_ver()

Extracts the OS version from the description string.

=item $netscreen->serial()

Returns serial number.

=back

=head2 Overrides

=over

=item $netscreen->layers()

Returns 01001110.  Device doesn't report layers properly, modified to reflect 
Layer 2 and 3 functionality.

=back

=head2 Globals imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::IEEE802dot11

See L<SNMP::Info::IEEE802dot11/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=head3 Interface Information

=over

=item $netscreen->interfaces()

Creates a map between the interface identifier (iid) and the physical port
name.

Defaults to C<insIfDescr> if available, uses C<nsIfName> if not.

=item $netscreen->i_description() 

Description of the interface. Uses C<insIfDescr> if available, C<nsIfName>
if not.

=item $netscreen->i_ignore()

Returns without defining any interfaces to ignore.

=item $netscreen->i_index()

Default SNMP IID to Interface index.

(C<nsIfIndex>)

=item $netscreen->i_lastchange()

The value of C<sysUpTime> when this port last changed states (up,down), 
maps from C<ifIndex> to C<nsIfIndex>.

(C<ifLastChange>)

=item $netscreen->i_mac() 

MAC address of the interface.  Note this is just the MAC of the port, not
anything connected to it.  Uses C<nsIfMAC> if available, C<ifPhysAddress>
if not.

=item $netscreen->i_mtu()

INTEGER. Interface MTU value, maps from C<ifIndex> to C<nsIfIndex>.

(C<ifMtu>)

=item $netscreen->i_name()

Interface Name field.

(C<nsIfName>)

=item $netscreen->i_speed()

Speed of the link, maps from C<ifIndex> to C<nsIfIndex>.

=item $netscreen->i_type()

Interface type.  Maps from C<ifIndex> to C<nsIfIndex>.

(C<ifType>)

=item $netscreen->i_up() 

Link Status of the interface.  Typical values are 'up' and 'down'.

(C<nsIfStatus>)

=item $netscreen->i_up_admin()

Administrative status of the port.  Checks both C<ifAdminStatus> and
C<nsIfStatus>.

=back

=head3 IP Address Table

Each entry in this table is an IP address in use on this device.

=over

=item $netscreen->ip_index()

Maps the IP Table to the IID

=item $netscreen->ip_table()

Maps the Table to the IP address

(C<nsIfIp>)

=item $netscreen->ip_netmask()

Gives netmask setting for IP table entry.

(C<nsIfNetmask>)

=back

=head3 Forwarding Table

Uses C<nsIpArpTable> to emulate the forwarding table.

=over 

=item $netscreen->fw_index()

Maps the Forwarding Table to the IID

=item $netscreen->fw_mac()

Returns reference to hash of forwarding table MAC Addresses.

=item $netscreen->fw_port()

Returns reference to hash of forwarding table entries port interface
identifier (IID).

=item $netscreen->bp_index()

Returns reference to hash of bridge port table entries map back to interface
identifier (IID).

=back

=head3 Wireless Information

=over 

=item $dot11->i_ssidlist()

Returns reference to hash.  SSID's recognized by the radio interface.
Remaps from C<ifIndex> to C<nsIfIndex>.

(C<dot11DesiredSSID>)

=item $dot11->i_80211channel()

Returns reference to hash.  Current operating frequency channel of the radio
interface.  Remaps from C<ifIndex> to C<nsIfIndex>.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::IEEE802dot11

See L<SNMP::Info::IEEE802dot11/"TABLE METHODS"> for details.

=cut

