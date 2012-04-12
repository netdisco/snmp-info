# SNMP::Info::Layer3::Netscreen
# $Id$
#
# Copyright (c) 2008 Eric Miller
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

@SNMP::Info::Layer3::Netscreen::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Netscreen::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE/;

$VERSION = '2.06';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'NETSCREEN-SMI'           => 'netscreenSetting',
    'NETSCREEN-PRODUCTS-MIB'  => 'netscreenGeneric',
    'NETSCREEN-INTERFACE-MIB' => 'nsIfIndex',
    'NETSCREEN-SET-GEN-MIB'   => 'nsSetGenSwVer',
    'NETSCREEN-IP-ARP-MIB'    => 'nsIpArpAOD',
);

%GLOBALS = ( %SNMP::Info::Layer3::GLOBALS, 'os_version' => 'nsSetGenSwVer', );

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,

    ns_i_index => 'nsIfIndex',
    ns_i_name => 'nsIfName',
    ns_i_description => 'nsIfDescr',
    ns_i_mac => 'nsIfMAC',
    ns_i_up => 'nsIfStatus',
    ns_ip_table => 'nsIfIp',
    ns_ip_netmask => 'nsIfNetmask',

    at_index => 'nsIpArpIfIdx',
    at_paddr => 'nsIpArpMac',
    at_netaddr => 'nsIpArpIp',
    bp_index => 'nsIfInfo',
);

%MUNGE = ( %SNMP::Info::Layer3::MUNGE, );

sub layers {
    return '01001110';
}

sub vendor {
    return 'netscreen';
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

# provides mapping from IF-MIB to nsIf interfaces - many to 1 (!)
# - on WLAN devices wireless0/0(|-[ag]) -> wireless0/0 !!
sub if_nsif_map {
    my $netscreen = shift;
    my $i_descr = $netscreen->SUPER::i_description;
    my $ns_descr = $netscreen->ns_i_description;
    my %if_nsif_map = ();
    my @ikeys = sort {$a <=> $b} keys %$i_descr;
    my @nskeys = sort {$a <=> $b} keys %$ns_descr;
    my $i = 0;
    my $n = 0;

    # assumes descriptions are in the same order from both walks
    while ($i < @ikeys && $n < @nskeys) {
        # find matching sub interfaces
        while ($i < @ikeys
                && substr($i_descr->{$ikeys[$i]}, 0, length $ns_descr->{$nskeys[$n]})
                    eq $ns_descr->{$nskeys[$n]}) {

            $if_nsif_map{$ikeys[$i]} = $nskeys[$n];
            $i++;
        }

        $n++;
        # skip non-matching interfaces (e.g. tunnel.N)
        while ($i < @ikeys
                && substr($i_descr->{$ikeys[$i]}, 0, length $ns_descr->{$nskeys[$n]})
                    ne $ns_descr->{$nskeys[$n]}
                && $n < @nskeys) {

            $if_nsif_map{$ikeys[$i]} = 0; # no matching interface
            $i++;
        }
    }

    return \%if_nsif_map;
}

sub nsif_if_map {
    my $netscreen = shift;
    my $native = shift || 0; # return only mappings for IF-MIB interfaces or all netscreen interfaces
    my $i_descr = $netscreen->SUPER::i_description;
    my $ns_descr = $netscreen->ns_i_description;
    my %nsif_if_map = ();
    my @ikeys = sort {$a <=> $b} keys %$i_descr;
    my @nskeys = sort {$a <=> $b} keys %$ns_descr;
    my $i = 0;
    my $n = 0;

    # assumes descriptions are in the same order from both walks
    while ($i < @ikeys && $n < @nskeys) {
        # find matching sub interfaces
        while ($n < @nskeys
                && substr($ns_descr->{$nskeys[$n]}, 0, length $i_descr->{$ikeys[$i]})
                    eq $i_descr->{$ikeys[$i]}) {

            $nsif_if_map{$nskeys[$n]} = $ikeys[$i]
                if !$native || $ns_descr->{$nskeys[$n]} eq $i_descr->{$ikeys[$i]};
            $n++;
        }

        $i++;
        # skip non-matching interfaces (e.g. tunnel.N)
        while ($n < @nskeys
                && substr($ns_descr->{$nskeys[$n]}, 0, length $i_descr->{$ikeys[$i]})
                    ne $i_descr->{$ikeys[$i]}
                && $i < @ikeys) {

            $nsif_if_map{$nskeys[$n]} = 0 unless $native; # no matching interface
            $n++;
        }
    }

    return \%nsif_if_map;
}

sub interfaces {
    my $netscreen = shift;
    return $netscreen->i_description;
}

sub i_index {
    my $netscreen = shift;
    return $netscreen->ns_i_index;
}

sub i_name {
    my $netscreen = shift;
    return $netscreen->ns_i_name;
}

sub i_description {
    my $netscreen = shift;
    return $netscreen->ns_i_description;
}

sub i_mac {
    my $netscreen = shift;
    my %i_mac = ();
    my $ns_mac = $netscreen->ns_i_mac;

    foreach my $iid (keys %$ns_mac) {
        $i_mac{$iid} = &SNMP::Info::munge_mac($ns_mac->{$iid});
    }

    return \%i_mac;
}

sub i_up {
    my $netscreen = shift;
    return $netscreen->ns_i_up;
}

sub i_up_admin {
    my $netscreen = shift;
    my $i_up = $netscreen->i_up;
    my $i_up_admin = $netscreen->SUPER::i_up_admin;
    my $ns_i_map = $netscreen->nsif_if_map;
    my %i_up_admin;

    foreach my $iid (keys %$ns_i_map) {
        $i_up_admin{$iid} = $i_up->{$iid} eq "up" && "up"
                            || $i_up_admin->{$ns_i_map->{$iid}}
                            || 0;
    }

    return \%i_up_admin;
}

sub i_type {
    my $netscreen = shift;
    my $i_type = $netscreen->SUPER::i_type;
    my $ns_i_map = $netscreen->nsif_if_map;
    my %i_type;

    foreach my $iid (keys %$ns_i_map) {
        $i_type{$iid} = $i_type->{$ns_i_map->{$iid}} || "tunnel"; 
    }

    return \%i_type;
}

sub i_ignore {
    return undef;
}

sub i_speed {
    my $netscreen = shift;
    my $i_speed = $netscreen->SUPER::i_speed;
    my $i_name = $netscreen->i_name;
    my $ns_i_map = $netscreen->nsif_if_map;
    my %i_speed;

    foreach my $iid (keys %$ns_i_map) {
        $i_speed{$iid} = $i_speed->{$ns_i_map->{$iid}}
                         || $i_name->{$iid} =~ /tunnel/ && "vpn"
                         || 0;
    }a

    return \%i_speed;
}

sub mac_map {
    my $netscreen = shift;
    my %mac_map = ();
    my $arp_mac = $netscreen->nsIpArpMac;

    foreach my $iid (keys %$arp_mac) {
        my $oid = join(".",(unpack ("C6",$arp_mac->{$iid})));
        $mac_map{$oid} = $iid;
    }
    return \%mac_map;
}

sub ip_index {
    my $netscreen = shift;
    my %ip_index = ();
    my $ns_ip = $netscreen->ns_ip_table;

    foreach my $iid (keys %$ns_ip) {
        $ip_index{$ns_ip->{$iid}} = $iid if $ns_ip->{$iid} ne "0.0.0.0";
    }

    return \%ip_index;
}

sub ip_table {
    my $netscreen = shift;
    my $ip_index = $netscreen->ip_index;
    my %ip_table = ();

    foreach my $iid (keys %$ip_index) {
        $ip_table{$iid} = $iid;
    }

    return \%ip_table;
}

sub ip_netmask {
    my $netscreen = shift;
    my $ip_index = $netscreen->ip_index;
    my $ns_netmask = $netscreen->ns_ip_netmask;
    my %ip_netmask = ();

    foreach my $iid (keys %$ip_index) {
        $ip_netmask{$iid} = $ns_netmask->{$ip_index->{$iid}};
    }

    return \%ip_netmask;
}

sub fw_index {
    my $netscreen = shift;
    my %fw_index = ();
    my $arp_mac = $netscreen->nsIpArpMac;

    foreach my $iid (keys %$arp_mac) {
        my $oid = join(".",(unpack ("C6",$arp_mac->{$iid})));
        $fw_index{$iid} = $oid;
    }

    return \%fw_index;
}

sub fw_mac {
    my $netscreen = shift;
    my %fw_mac = ();
    my $mac_map = $netscreen->mac_map;

    foreach my $oid (keys %$mac_map) {
        my $mac = join(":",(map {sprintf "%lx",$_} split(/\./,$oid)));
        $fw_mac{$oid} = $mac;
    }

    return \%fw_mac;
}

sub bp_index {
    my $netscreen = shift;
    my $if_info = $netscreen->nsIfInfo;
    my %bp_index = ();

    foreach my $iid (keys %$if_info) {
        $bp_index{$if_info->{$iid}} = $iid;
    }

    return \%bp_index;
}

sub fw_port {
    my $netscreen = shift;
    my %fw_port;
    my $fw_index = $netscreen->fw_index;
    my $arp_if = $netscreen->nsIpArpIfIdx;

    foreach my $iid (keys %$arp_if) {
        $fw_port{$fw_index->{$iid}} = $arp_if->{$iid}
            if defined $fw_index->{$iid};
    }

    return \%fw_port;
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
Netscreen device through SNMP. See inherited classes' documentation for 
inherited methods.

my $netscreen = new SNMP::Info::Layer3::Netscreen(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<NETSCREEN-SMI>

=item F<NETSCREEN-PRODUCTS-MIB>

=item F<NETSCREEN-INTERFACE-MIB>

=item F<NETSCREEN-SET-GEN-MIB>

=item Inherited Classes

See L<SNMP::Info::Layer3/"Required MIBs"> and its inherited classes.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $netscreen->vendor()

Returns 'netscreen'

=item $netscreen->os()

Returns C<'screenos'>

=item $netscreen->os_ver()

Extracts the OS version from the description string.

=item $netscreen->serial()

Returns serial number..

=back

=head2 Overrides

=over

=item $netscreen->layers()

Returns 01001100.  Device doesn't report layers properly, modified to reflect 
Layer3 functionality.

=back

=head2 Globals imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut

