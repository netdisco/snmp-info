# SNMP::Info::Layer3::Onyx
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

package SNMP::Info::Layer3::Onyx;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::PortAccessEntity;

@SNMP::Info::Layer3::Onyx::ISA = qw/
    SNMP::Info::Layer3
    SNMP::Info::PortAccessEntity
    Exporter
/;
@SNMP::Info::Layer3::Onyx::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.985002';

%MIBS = (
    %SNMP::Info::PortAccessEntity::MIBS,
    %SNMP::Info::Layer3::MIBS,
);

%GLOBALS = (
    %SNMP::Info::PortAccessEntity::GLOBALS,
    %SNMP::Info::Layer3::GLOBALS,
    'mac' => 'dot1dBaseBridgeAddress',
);

%FUNCS = (
    %SNMP::Info::PortAccessEntity::FUNCS,
    %SNMP::Info::Layer3::FUNCS,
);

%MUNGE = (
    %SNMP::Info::PortAccessEntity::MUNGE,
    %SNMP::Info::Layer3::MUNGE,
    'mac' => \&SNMP::Info::munge_mac,
);

# Onyx serves sysServices 72 (layers 4 and 7) despite its bridge and IP
# tables. Include layers 2 and 3 so callers collect forwarding and ARP data.
sub layers {
    my $dev = shift;

    my $layers = $dev->SUPER::layers() || '00000000';
    substr( $layers, 5, 2, '11' );
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

# Onyx returns MAC chassis IDs as text rather than the six octets LLDP-MIB
# defines. Keep the common decoder for binary MACs and other ID types.
sub _lldp_id_string {
    my ( $dev, $id, $type ) = @_;

    return lc $id
        if defined $id and defined $type and $type eq 'macAddress'
        and $id =~ /^(?:[0-9a-f]{2}:){5}[0-9a-f]{2}$/i;
    return $dev->SUPER::_lldp_id_string( $id, $type );
}

# lldpRemLocalPortNum is a bridge port number. A port with no bridge port
# row (a LAG member) is found by its lldpLocPortId, which Onyx sets to the
# ifName; a neighbor matching neither is left out rather than guessed
sub lldp_if {
    my $dev     = shift;
    my $partial = shift;

    return $dev->SUPER::lldp_if($partial)
        if ( $dev->_lldp_source() || '' ) eq 'v2';

    my $id_type  = $dev->_lldp_rem( 'lldp_rem_id_type', $partial );
    my $bp_index = $dev->bp_index()                 || {};
    my $lport_id = $dev->lldp_lport_id()            || {};
    my %by_name  = reverse %{ $dev->orig_i_name() || {} };

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
    my ( $dev, $partial, $topo_cap ) = @_;

    $topo_cap ||= $dev->has_topo() || [];
    my $c_ip = $dev->SUPER::c_ip( $partial, $topo_cap ) || {};
    return $c_ip unless grep { $_ eq 'lldp' } @$topo_cap;

    my $id_type = $dev->_lldp_rem( 'lldp_rem_id_type', $partial );

    foreach my $key ( keys %$id_type ) {
        $c_ip->{$key} = '0.0.0.0' unless defined $c_ip->{$key};
    }

    return $c_ip;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer3::Onyx - SNMP Interface to Mellanox/NVIDIA Switches
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
Mellanox / NVIDIA switch running Onyx via SNMP. It is chosen for devices
whose C<sysDescr> starts with C<Onyx,> and whose C<sysObjectID> is under
C<.1.3.6.1.4.1.33049.1.1.1>.

Onyx returns MAC chassis IDs as ASCII text. The inherited LLDP methods
accept these as well as binary MAC addresses and select LLDP-MIB or
LLDP-V2-MIB as provided by the device.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::PortAccessEntity

=back

=head2 Required MIBs

None beyond those of the inherited classes.

=head2 Inherited MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> and
L<SNMP::Info::PortAccessEntity/"Required MIBs"> for their MIB requirements.

=head1 GLOBALS

These methods return scalar values from SNMP.

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

Returns the inherited layers with layers 2 and 3 added, or C<00000110>
when C<sysServices> is unavailable. Onyx serves C<sysServices> 72 (layers
4 and 7), which omits its bridge and IP capabilities. The layer 3 bit
allows callers to collect ARP and IPv6 neighbor data even when IP
forwarding is disabled.

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::PortAccessEntity

See L<SNMP::Info::PortAccessEntity/"GLOBALS"> for details.

=head1 TABLE METHODS

=head2 Overrides

=over

=item $dev->lldp_if()

Returns reference to hash. Key: iid, Value: local ifIndex. Onyx's
C<lldpRemLocalPortNum> is a bridge port number, mapped through
C<bp_index()>. A port with no bridge port row is matched by its
C<lldpLocPortId> to C<ifName>; a neighbor matching neither is left out.
For LLDP-V2-MIB, uses the inherited mapping, whose local port number is
already an ifIndex.

=item $dev->c_ip()

Returns reference to hash. Key: iid, Value: remote IPv4 address from
C<lldp_ip()>, or 0.0.0.0 for a neighbor that advertises no management
address, so it can still be found by its C<c_id()>. Honors the optional
topology protocol list; the placeholder is added only when LLDP is selected.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"TABLE METHODS"> for details, including the
standard ARP and IPv6 neighbor tables.

=head2 Table Methods imported from SNMP::Info::PortAccessEntity

See L<SNMP::Info::PortAccessEntity/"TABLE METHODS"> for details.

=cut
