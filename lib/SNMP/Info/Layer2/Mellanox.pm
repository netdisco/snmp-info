# SNMP::Info::Layer2::Mellanox
#
# Copyright (c) 2026 Hannes Eberhardt
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

package SNMP::Info::Layer2::Mellanox;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer2;

@SNMP::Info::Layer2::Mellanox::ISA = qw/
    SNMP::Info::Layer2
    Exporter
/;
@SNMP::Info::Layer2::Mellanox::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.975000';

%MIBS = ( %SNMP::Info::Layer2::MIBS, );

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
    'mac' => 'dot1dBaseBridgeAddress',
);

%FUNCS = ( %SNMP::Info::Layer2::FUNCS, );

%MUNGE = (
    %SNMP::Info::Layer2::MUNGE,
    'mac' => \&SNMP::Info::munge_mac,
);

sub bulkwalk_no { return 1; }

sub layers { return '01001010'; }

sub vendor { return 'Mellanox'; }

sub os { return 'Onyx'; }

sub os_ver {
    my $dev   = shift;
    my $descr = $dev->description();
    return unless defined $descr;
    return $1 if $descr =~ /SWv([\d.]+)/;
    return;
}

sub model {
    my $dev   = shift;
    my $descr = $dev->description();
    return $1 if defined $descr && $descr =~ /^Onyx,\s*([^,]+),/;
    return $dev->SUPER::model();
}

sub interfaces {
    my $dev     = shift;
    my $partial = shift;

    my $i_name = $dev->i_name($partial) || {};

    my %if;
    foreach my $iid ( keys %$i_name ) {
        my $name = $i_name->{$iid};
        next unless defined $name and $name !~ /^\s*$/;
        $if{$iid} = $name;
    }
    return \%if;
}

sub i_description {
    my $dev     = shift;
    my $partial = shift;

    my $i_name  = $dev->i_name($partial)  || {};
    my $i_alias = $dev->i_alias($partial) || {};

    my %descr;

    # start with ifName as fallback
    foreach my $iid ( keys %$i_name ) {
        my $name = $i_name->{$iid};
        next unless defined $name and $name !~ /^\s*$/;
        $descr{$iid} = $name;
    }

    # override with ifAlias where operator has set a description
    foreach my $iid ( keys %$i_alias ) {
        my $alias = $i_alias->{$iid};
        next unless defined $alias and $alias !~ /^\s*$/;
        $descr{$iid} = $alias;
    }

    return \%descr;
}

sub lldp_id {
    my $dev     = shift;
    my $partial = shift;

    my $id_type = $dev->lldp_rem_id_type($partial) || {};
    my $id_raw  = $dev->lldp_rem_id($partial)      || {};

    my %id;
    foreach my $key ( keys %$id_raw ) {
        my $type = $id_type->{$key};
        my $raw  = $id_raw->{$key};
        next unless defined $raw;

        if ( defined $type and $type eq 'macAddress' ) {
            # Onyx encodes the MAC as an ASCII string in the bytes,
            # e.g. hex 31633a33343a... decodes to ASCII "1c:34:da:39:f9:80"
            my $ascii = pack( 'H*', unpack( 'H*', $raw ) );
            if ( $ascii =~ /^([0-9a-f]{2}:){5}[0-9a-f]{2}$/i ) {
                $id{$key} = lc $ascii;
            }
            else {
                # genuine 6-byte binary MAC
                $id{$key} = join ':', map { sprintf "%02x", $_ }
                                      unpack( 'C*', $raw );
            }
        }
        elsif ( defined $type and $type eq 'networkAddress' ) {
            # first byte is address family (1 = IPv4), skip it
            my @bytes = unpack( 'C*', $raw );
            if ( $bytes[0] == 1 and scalar @bytes == 5 ) {
                $id{$key} = join '.', @bytes[1..4];
            }
            else {
                $id{$key} = unpack 'H*', $raw;
            }
        }
        else {
            # ifName, local string etc -- decode ASCII bytes
            $id{$key} = pack( 'H*', unpack( 'H*', $raw ) );
        }
    }
    return \%id;
}

sub lldp_if {
    my $dev     = shift;
    my $partial = shift;

    my $id_type  = $dev->lldp_rem_id_type($partial) || {};
    my $bp_index = $dev->bp_index()                 || {};

    my %if;
    foreach my $key ( keys %$id_type ) {
        my ( $time, $lport, $remote ) = split /\./, $key;
        next unless defined $lport;

        my $ifindex = exists $bp_index->{$lport}
                    ? $bp_index->{$lport}
                    : $lport;

        $if{$key} = $ifindex;
    }
    return \%if;
}

sub c_ip {
    my $dev     = shift;
    my $partial = shift;

    my $lldp_ip = $dev->lldp_ip($partial)         || {};
    my $id_type = $dev->lldp_rem_id_type($partial) || {};

    my %c_ip = %$lldp_ip;

    foreach my $key ( keys %$id_type ) {
        if ( !exists $c_ip{$key} or !defined $c_ip{$key} ) {
            $c_ip{$key} = '0.0.0.0';
        }
    }

    return \%c_ip;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer2::Mellanox - SNMP Interface to Mellanox/NVIDIA Switches
running Onyx

=head1 AUTHOR

Hannes Eberhardt

=head1 SYNOPSIS

    # Let SNMP::Info determine the correct subclass for you.
    my $dev = new SNMP::Info(
                            AutoSpecify => 1,
                            Debug       => 1,
                            DestHost    => 'myswitch',
                            Community   => 'public',
                            Version     => 2
                          )
        or die "Can't connect to DestHost.\n";

    my $class = $dev->class();
    print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a
Mellanox/NVIDIA switch running Onyx via SNMP.

The main Onyx-specific quirks this module works around are:

=over

=item * sysServices reports 72 (Linux net-snmp default) rather than
advertising Layer 2 capability, so layers() is hardcoded.

=item * Chassis IDs in lldpRemChassisId are sent as ASCII MAC strings
encoded as bytes rather than raw binary bytes.

=item * LLDP local port numbers are bridge port numbers that must be
translated via dot1dBasePortIfIndex (bp_index) to get ifIndex.

=item * Neighbors with no LLDP management address need a 0.0.0.0
sentinel in c_ip() so Netdisco falls through to MAC-based resolution.

=item * Real port names are in ifName, not ifDescr. Operator
descriptions are in ifAlias.

=back

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

All MIBs required by L<SNMP::Info::Layer2> and its inherited classes.

=head1 GLOBALS

=over

=item $dev->layers()

Returns '01001010'. Hardcoded because Onyx reports the Linux net-snmp
default (72 / 01001000) which does not advertise Layer 2 capability.

=item $dev->vendor()

Returns 'Mellanox'.

=item $dev->os()

Returns 'Onyx'.

=item $dev->os_ver()

Parses the OS version from C<sysDescr>, e.g. "3.10.4100" from
"Onyx,MSN2410,SWv3.10.4100".

=item $dev->model()

Parses the model from C<sysDescr>, e.g. "MSN2410".

=item $dev->mac()

Returns the base bridge MAC address from C<dot1dBaseBridgeAddress>.

=back

=head1 TABLE METHODS

=over

=item $dev->interfaces()

Returns ifIndex -> ifName mapping. Uses ifName as the stable port
identifier (key in Netdisco's device_port table).

=item $dev->i_description()

Returns ifIndex -> description mapping. Prefers ifAlias (operator-set
description) over ifName so Netdisco displays meaningful port labels.

=item $dev->lldp_id()

Overrides the default to handle Onyx's chassis ID encoding: MAC
addresses are sent as ASCII strings in the byte field rather than as
raw 6-byte binary values.

=item $dev->lldp_if()

Translates LLDP local port numbers (bridge port numbers embedded in
the LLDP table key) to ifIndex via C<bp_index()>.

=item $dev->c_ip()

Delegates to C<lldp_ip()> and inserts 0.0.0.0 for entries with no
management IP so Netdisco falls through to MAC-based resolution.

=back

=cut