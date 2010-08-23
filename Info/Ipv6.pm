# SNMP::Info::Ipv6
#
# Copyright (c) 2010 Jeroen van Ingen
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

package SNMP::Info::Ipv6;

use strict;
use Exporter;
use SNMP::Info;

@SNMP::Info::Ipv6::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::Ipv6::EXPORT_OK = qw//;

use vars qw/$VERSION %MIBS %FUNCS %GLOBALS %MUNGE $METHOD/;

use constant {
    IPMIB   => 1,
    CISCO   => 2,
    IPV6MIB => 3,
};

$VERSION = '2.01';



%MIBS = ( 
    'IP-MIB'            => 'ipv6InterfaceTableLastChange',
    'IPV6-MIB'          => 'ipv6IfTableLastChange',
    'CISCO-IETF-IP-MIB' => 'cInetNetToMediaNetAddress', 
);

%GLOBALS = ();

%FUNCS = ( 
    'ip_n2p_phys_addr'  => 'ipNetToPhysicalPhysAddress',    # IP-MIB
    'c_inet_phys_addr'  => 'cInetNetToMediaPhysAddress',    # CISCO-IETF-IP-MIB
    'i6_n2p_phys_addr'  => 'ipv6NetToMediaNetAddress',      # IPV6-MIB
    'ip_n2p_phys_type'  => 'ipNetToPhysicalType',       # IP-MIB
    'c_inet_phys_type'  => 'cInetNetToMediaType',       # CISCO-IETF-IP-MIB
    'i6_n2p_phys_type'  => 'ipv6NetToMediaType',        # IPV6-MIB
    'ip_n2p_phys_state' => 'ipNetToPhysicalState',      # IP-MIB
    'c_inet_phys_state' => 'cInetNetToMediaState',      # CISCO-IETF-IP-MIB
    'i6_n2p_phys_state' => 'ipv6NetToMediaState',       # IPV6-MIB
);

%MUNGE = (
    'ip_n2p_phys_addr'  => \&SNMP::Info::munge_mac,
    'c_inet_phys_addr'  => \&munge_physaddr,
    'i6_n2p_phys_addr'  => \&SNMP::Info::munge_mac,
);


sub ipv6_n2p_mac {
    my $info = shift;
    my $return;
    my $phys_addr = &test_methods( $info, {
        ip_n2p_phys_addr => IPMIB,
        c_inet_phys_addr => CISCO,
        i6_n2p_phys_addr => IPV6MIB,
    });
    return unless defined $phys_addr;
    foreach my $row (keys %$phys_addr) {
        if ($row =~ /^(\d+)\.(\d+)\.(\d+)\.([\d\.]+)$/) {
            my $ifindex = $1; my $addrtype = $2; my $addrsize = $3; my $v6addr = $4;
            if ($info::METHOD == IPV6MIB) { 
                # IPV6-MIB doesn't include the addrtype in the index; 
                # also, address syntax is Ipv6Address (fixed 16 bytes) and not InetAddress (length field followed by address bytes)
                $v6addr = join('.', $addrtype, $addrsize, $v6addr);
                $addrtype = 2;
            }
            if ($addrtype == 2) { # IPv6
                $return->{$row} = substr($phys_addr->{$row}, 0, 17);
            }
        }
    }
    printf("%s: data comes from %s.\n", &my_sub_name, $info->method_used() ) if $info->debug();
    return $return;
}

sub ipv6_n2p_addr {
    my $info = shift;
    my $return;
    my $net_addr = &test_methods( $info, {
        ip_n2p_phys_addr => IPMIB,
        c_inet_phys_addr => CISCO,
        i6_n2p_phys_addr => IPV6MIB,
    });
    return unless defined $net_addr;
    foreach my $row (keys %$net_addr) {
        if ($row =~ /^(\d+)\.(\d+)\.(\d+)\.([\d\.]+)$/) {
            my $ifindex = $1; my $addrtype = $2; my $addrsize = $3; my $v6addr = $4;
            if ($info::METHOD == IPV6MIB) { 
                # IPV6-MIB doesn't include the addrtype in the index; 
                # also, address syntax is Ipv6Address (fixed 16 bytes) and not InetAddress (length field followed by address bytes)
                $v6addr = join('.', $addrtype, $addrsize, $v6addr);
                $addrtype = 2;
            }
            if ($addrtype == 2) { # IPv6
                my $v6_packed = pack("C*", split(/\./, $v6addr));
                $v6addr = join(':', map { sprintf("%04x", $_) } unpack("n*", $v6_packed) );
                $return->{$row} = $v6addr;
            }
        }
    }
    printf("%s: data comes from %s.\n", &my_sub_name, $info->method_used() ) if $info->debug();
    return $return;
}

sub ipv6_n2p_if {
    my $info = shift;
    my $return;
    my $phys_addr = &test_methods( $info, {
        ip_n2p_phys_addr => IPMIB,
        c_inet_phys_addr => CISCO,
        i6_n2p_phys_addr => IPV6MIB,
    });
    return unless defined $phys_addr;
    foreach my $row (keys %$phys_addr) {
        if ($row =~ /^(\d+)\.(\d+)\.(\d+)\.([\d\.]+)$/) {
            my $ifindex = $1; my $addrtype = $2; my $addrsize = $3; my $v6addr = $4;
            if ($info::METHOD == IPV6MIB) { 
                # IPV6-MIB doesn't include the addrtype in the index; 
                # also, address syntax is Ipv6Address (fixed 16 bytes) and not InetAddress (length field followed by address bytes)
                $v6addr = join('.', $addrtype, $addrsize, $v6addr);
                $addrtype = 2;
            }
            if ($addrtype == 2) { # IPv6
                $return->{$row} = $ifindex;
            }
        }
    }
    printf("%s: data comes from %s.\n", &my_sub_name, $info->method_used() ) if $info->debug();
    return $return;
}

sub ipv6_n2p_type {
    my $info = shift;
    my $return;
    my $phys_type = &test_methods( $info, {
        ip_n2p_phys_type => IPMIB,
        c_inet_phys_type => CISCO,
        i6_n2p_phys_type => IPV6MIB,
    });
    return unless defined $phys_type;
    foreach my $row (keys %$phys_type) {
        if ($row =~ /^(\d+)\.(\d+)\.(\d+)\.([\d\.]+)$/) {
            my $ifindex = $1; my $addrtype = $2; my $addrsize = $3; my $v6addr = $4;
            if ($info::METHOD == IPV6MIB) { 
                # IPV6-MIB doesn't include the addrtype in the index; 
                # also, address syntax is Ipv6Address (fixed 16 bytes) and not InetAddress (length field followed by address bytes)
                $v6addr = join('.', $addrtype, $addrsize, $v6addr);
                $addrtype = 2;
            }
            if ($addrtype == 2) { # IPv6
                $return->{$row} = $phys_type->{$row};
            }
        }
    }
    printf("%s: data comes from %s.\n", &my_sub_name, $info->method_used() ) if $info->debug();
    return $return;
}

sub ipv6_n2p_state {
    my $info = shift;
    my $return;
    my $phys_state = &test_methods( $info, {
        ip_n2p_phys_state => IPMIB,
        c_inet_phys_state => CISCO,
        i6_n2p_phys_state => IPV6MIB,
    });
    return unless defined $phys_state;
    foreach my $row (keys %$phys_state) {
        if ($row =~ /^(\d+)\.(\d+)\.(\d+)\.([\d\.]+)$/) {
            my $ifindex = $1; my $addrtype = $2; my $addrsize = $3; my $v6addr = $4;
            if ($info::METHOD == IPV6MIB) { 
                # IPV6-MIB doesn't include the addrtype in the index; 
                # also, address syntax is Ipv6Address (fixed 16 bytes) and not InetAddress (length field followed by address bytes)
                $v6addr = join('.', $addrtype, $addrsize, $v6addr);
                $addrtype = 2;
            }
            if ($addrtype == 2) { # IPv6
                $return->{$row} = $phys_state->{$row};
            }
        }
    }
    printf("%s: data comes from %s.\n", &my_sub_name, $info->method_used() ) if $info->debug();
    return $return;
}



sub method_used {
    my $info = shift;
    my $return = 'none of the MIBs';
    if (defined $info::METHOD) {
        if ($info::METHOD eq IPMIB) {
            $return = 'IP-MIB';
        } elsif ($info::METHOD eq IPV6MIB) {
            $return = 'IPV6-MIB';
        } elsif ($info::METHOD eq CISCO) {
            $return = 'CISCO-IETF-IP-MIB';
        }
    }
    return $return;
}

sub test_methods {
    my $info = shift;
    my $test = shift;
    my $return = {};
    foreach my $method (sort {$test->{$a} <=> $test->{$b}} keys %$test) {
        $return = $info->$method || {};
        if (scalar keys %$return) {
            $info::METHOD = $test->{$method};
            last;
        }
    }
    return $return;
}

sub my_sub_name {
    my @callinfo = caller(1);
    return $callinfo[3];
}

=item munge_physaddr()

Takes an octet stream (HEX-STRING) and returns a colon separated ASCII hex
string.

=cut

sub munge_physaddr {
    my $addr = shift;
    return unless defined $addr;
    return unless length $addr;
    $addr = join( ':', map { sprintf "%02x", $_ } unpack( 'C*', $addr ) );
    return $addr;
}

1;

__END__

=head1 NAME

SNMP::Info::Ipv6 - SNMP Interface for mapping IPv6 addresses to MACs and interfaces, using information from 
F<IP-MIB>, F<IPV6-MIB> and/or F<CISCO-IETF-IP-MIB>.

=head1 AUTHOR

Jeroen van Ingen

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $info = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $info->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

The SNMP::Info::Ipv6 class implements functions to for mapping IPv6 addresses 
to MAC addresses, interfaces and more. It will use data from the IP-MIB, IPV6-MIB 
or the CISCO-IETF-IP-MIB, whichever is supported by the device.

This class is inherited by Info::Layer3 to provide IPv6 node tracking across  
device classes.

For debugging purposes you can call this class directly as you would
SNMP::Info

 my $info = new SNMP::Info::Ipv6 (...);

=head2 Inherited Classes

none.

=head2 Required MIBs

=over

=item F<IP-MIB>
=item F<IPV6-MIB>
=item F<CISCO-IETF-IP-MIB>

=back

=head1 GLOBALS

none.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2  Internet Address Translation table

=over

=item $info->c_inet_phys_address()

Maps an address of type C<cInetNetToMediaNetAddressType> on interface C<ifIndex> to a physical address.

=back

=cut
