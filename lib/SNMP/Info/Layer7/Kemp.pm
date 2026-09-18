# SNMP::Info::Layer7::Kemp
#
# Copyright (c) 2026 df-an and the SNMP::Info Developers
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

package SNMP::Info::Layer7::Kemp;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer7;

our @ISA = qw/SNMP::Info::Layer7 Exporter/;
our @EXPORT_OK = qw//;
our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.977001';

%MIBS = (
    %SNMP::Info::Layer7::MIBS,
    'B100-MIB' => 'patchVersion',
    'SNMP-FRAMEWORK-MIB' => 'snmpEngineID',
);

%GLOBALS = (
    %SNMP::Info::Layer7::GLOBALS,
    'os_ver' => 'B100-MIB::patchVersion',
    'kemp_engine_id' => 'SNMP-FRAMEWORK-MIB::snmpEngineID',
);

%FUNCS = (
    %SNMP::Info::Layer7::FUNCS,
    'kemp_vs_ip' => 'B100-MIB::vSIp',
    'kemp_vs_addrtype' => 'B100-MIB::vSAddrtype',
);

%MUNGE = (
    %SNMP::Info::Layer7::MUNGE,
    'kemp_vs_ip' => \&SNMP::Info::munge_inetaddress,
);

sub vendor { return 'kemp'; }
sub model  { return 'LoadMaster'; }
sub os     { return 'LMOS'; }

sub serial {
    my $kemp = shift;
    my $raw = $kemp->kemp_engine_id();
    return unless defined $raw and length $raw;

    return 'SNMP-ENGINEID-' . uc(unpack('H*', $raw));
}

# The legacy ip_* methods enumerate IPv4 only. Service indices are not
# ifIndex values, and the vendor MIB supplies neither interfaces nor masks.
sub _vip_addresses {
    my $kemp = shift;
    my $ips = $kemp->kemp_vs_ip() || {};
    my $types = $kemp->kemp_vs_addrtype() || {};
    my %vips;
    foreach my $iid (keys %$ips) {
        my $type = $types->{$iid};
        next unless defined $type and ($type eq 'ipv4' or $type eq '1');
        my $ip = $ips->{$iid};
        next unless defined $ip and $ip =~ /^(\d{1,3}\.){3}\d{1,3}$/;
        next if grep { $_ > 255 } split /\./, $ip;
        next if $ip eq '0.0.0.0' or $ip eq '255.255.255.255';
        $vips{$ip} = 1;
    }
    return \%vips;
}

sub ip_table {
    my $kemp = shift;
    my %ips = %{ $kemp->SUPER::ip_table() || {} };
    foreach my $ip (keys %{ $kemp->_vip_addresses() }) {
        $ips{$ip} = $ip unless exists $ips{$ip};
    }
    return \%ips;
}

sub ip_index {
    my $kemp = shift;
    my %indices = %{ $kemp->SUPER::ip_index() || {} };
    foreach my $ip (keys %{ $kemp->_vip_addresses() }) {
        $indices{$ip} = 0 unless exists $indices{$ip};
    }
    return \%indices;
}

sub ip_netmask {
    my $kemp = shift;
    my %masks = %{ $kemp->SUPER::ip_netmask() || {} };
    foreach my $ip (keys %{ $kemp->_vip_addresses() }) {
        $masks{$ip} = '255.255.255.255' unless exists $masks{$ip};
    }
    return \%masks;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer7::Kemp - SNMP Interface to Kemp LoadMaster appliances

=head1 AUTHORS

df-an and the SNMP::Info Developers

=head1 SYNOPSIS

 my $kemp = SNMP::Info->new(
     AutoSpecify => 1,
     DestHost    => 'loadmaster',
     Community   => 'public',
     Version     => 2,
 );
 my $version = $kemp->os_ver();
 my $ips = $kemp->ip_table();

=head1 DESCRIPTION

Support for Kemp (Progress) LoadMaster appliances, identified by enterprise
12196 even when the system description only identifies Linux.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer7

=back

=head2 Required MIBs

=over

=item F<B100-MIB>

Available with its F<ONE4NET-MIB> dependency in the C<one4net> directory of
netdisco-mibs.

=item F<SNMP-FRAMEWORK-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer7> for its own MIB requirements.

=back

=head1 GLOBALS

=over

=item $kemp->vendor()

Returns C<kemp>.

=item $kemp->model()

Returns C<LoadMaster>.

=item $kemp->os()

Returns C<LMOS>.

=item $kemp->os_ver()

Returns the installed firmware version (C<B100-MIB::patchVersion>).

=item $kemp->kemp_engine_id()

Returns the raw C<snmpEngineID> octets.

=item $kemp->serial()

Returns C<SNMP-ENGINEID-> followed by the hexadecimal SNMP engine ID, or
undef if unavailable. This is a surrogate identifier, not a hardware serial
number. LoadMaster does not expose its hardware serial number via SNMP;
the engine ID can change if reconfigured.

=back

=head1 TABLE METHODS

=over

=item $kemp->kemp_vs_ip()

Virtual service addresses keyed by service index (C<B100-MIB::vSIp>).
Binary IPv4 and IPv6 addresses are converted to printable addresses.

=item $kemp->kemp_vs_addrtype()

Virtual service address types (C<B100-MIB::vSAddrtype>).

=item $kemp->ip_table()

Adds virtual service IPv4 addresses to the inherited IP address table.
Repeated addresses shared by multiple services are returned only once.
Unspecified addresses and IPv6 services are excluded from these IPv4 methods.

=item $kemp->ip_index()

Preserves standard IP interface mappings and adds virtual service addresses
with interface index 0 (unknown). A service index is not an interface index.

=item $kemp->ip_netmask()

Preserves standard IP netmasks and adds virtual service addresses with host
masks (255.255.255.255), since the virtual service MIB supplies no netmask.

=back

=head2 Methods imported from SNMP::Info::Layer7

See L<SNMP::Info::Layer7> for details.

=cut
