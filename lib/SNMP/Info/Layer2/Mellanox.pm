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

$VERSION = '3.984000';

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

# Onyx serves sysServices 72 (layers 4 and 7) although it bridges, so add
# layer 2 or the calling application skips the forwarding table
sub layers {
    my $dev = shift;

    my $layers = $dev->SUPER::layers() || '00000000';
    substr( $layers, 6, 1, '1' );
    return $layers;
}

sub vendor { return 'mellanox'; }

sub os { return 'onyx'; }

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

# lldpRemLocalPortNum is a bridge port number. A port with no bridge port
# row (a LAG member) is found by its lldpLocPortId, which Onyx sets to the
# ifName; a neighbor matching neither is left out rather than guessed
sub lldp_if {
    my $dev     = shift;
    my $partial = shift;

    my $id_type  = $dev->lldp_rem_id_type($partial) || {};
    my $bp_index = $dev->bp_index()                 || {};
    my $lport_id = $dev->lldp_lport_id()            || {};
    my %by_name  = reverse %{ $dev->i_name() || {} };

    my %if;
    foreach my $key ( keys %$id_type ) {
        my ( $time, $lport, $remote ) = split /\./, $key;
        next unless defined $lport;

        my $name    = $lport_id->{$lport};
        my $ifindex = $bp_index->{$lport}
            // ( defined $name ? $by_name{$name} : undef );
        next unless defined $ifindex;

        $if{$key} = $ifindex;
    }
    return \%if;
}

# A neighbor with no management address gets 0.0.0.0, which the calling
# application looks up by c_id; an entry with no c_ip is dropped
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
Mellanox / NVIDIA switch running Onyx via SNMP. It is chosen for
C<sysObjectID>s under the Onyx switch branch, C<.1.3.6.1.4.1.33049.1.1.1>.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

None beyond those of the inherited class.

=head2 Inherited MIBs

See L<SNMP::Info::Layer2/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP.

=over

=item $dev->vendor()

Returns 'mellanox'.

=item $dev->os()

Returns 'onyx'.

=item $dev->os_ver()

Returns the OS version from C<sysDescr>, such as "3.10.4100" from
"Onyx,MSN2410,SWv3.10.4100".

=item $dev->model()

Returns the model from C<sysDescr>, such as "MSN2410", or the inherited
model when C<sysDescr> does not name one.

=item $dev->mac()

Returns the bridge MAC address.

(C<dot1dBaseBridgeAddress>)

=back

=head2 Overrides

=over

=item $dev->layers()

Returns the inherited layers with layer 2 added. Onyx serves
C<sysServices> 72 (layers 4 and 7), which does not include layer 2.

=back

=head2 Global Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head1 TABLE METHODS

=head2 Overrides

=over

=item $dev->lldp_id()

Returns reference to hash. Key: iid, Value: remote chassis ID. Onyx sends
a MAC address chassis ID as its ASCII text rather than six octets; both
forms are returned as a colon-separated MAC address.

(C<lldpRemChassisId>)

=item $dev->lldp_if()

Returns reference to hash. Key: iid, Value: local ifIndex. Onyx's
C<lldpRemLocalPortNum> is a bridge port number, mapped through
C<bp_index()>. A port with no bridge port row is matched by its
C<lldpLocPortId> to C<ifName>; a neighbor matching neither is left out.

=item $dev->c_ip()

Returns reference to hash. Key: iid, Value: remote IPv4 address from
C<lldp_ip()>, or 0.0.0.0 for a neighbor that advertises no management
address, so it can still be found by its C<c_id()>.

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=cut
