# SNMP::Info::Layer3::SONiC - SNMP interface to SONiC switches
#
# Copyright (c) 2026 by SNMP::Info Developers.
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
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Layer3::SONiC;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3::NetSNMP;

@SNMP::Info::Layer3::SONiC::ISA = qw/SNMP::Info::Layer3::NetSNMP Exporter/;
@SNMP::Info::Layer3::SONiC::EXPORT_OK = qw//;

our ( $VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE );

$VERSION = '3.985002';

%MIBS = ( %SNMP::Info::Layer3::NetSNMP::MIBS, );

%GLOBALS = (
    %SNMP::Info::Layer3::NetSNMP::GLOBALS,

    # LLDP-MIB lldpLocChassisIdSubtype and lldpLocChassisId, as community
    # builds serve them: without the .0 instance
    'sonic_loc_id_type' => '.1.0.8802.1.1.2.1.3.1',
    'sonic_loc_id_os'   => '.1.0.8802.1.1.2.1.3.2',
);

%FUNCS = ( %SNMP::Info::Layer3::NetSNMP::FUNCS, );

%MUNGE = ( %SNMP::Info::Layer3::NetSNMP::MUNGE, );

# HwSku names start with the hardware maker; Force10 and DellEMC are Dell's.
my %VENDOR_OF_SKU_PREFIX = (
    accton  => 'accton',
    dell    => 'dell',
    dellemc => 'dell',
    force10 => 'dell',
);

my $MAC_RE = qr/^(?:[0-9a-f]{2}:){5}[0-9a-f]{2}$/;

# sysServices is fixed at 72 (layers 4 and 7) in the SNMP container's
# snmpd.conf, whatever the switch does.
sub layers {
    my $sonic = shift;

    my $layers = $sonic->SUPER::layers() || '00000000';
    substr( $layers, 5, 2, '11' );
    return $layers;
}

sub vendor {
    my $sonic = shift;

    my $sku = $sonic->model() || '';
    if ( $sku =~ /^([A-Za-z0-9]+)-/ ) {
        my $vendor = $VENDOR_OF_SKU_PREFIX{ lc $1 };
        return $vendor if $vendor;
    }
    return 'sonic';
}

sub os { return 'sonic' }

sub os_ver {
    my $sonic = shift;

    my $descr = $sonic->description() || '';
    return $1 if $descr =~ /^"?SONiC Software Version:\s+SONiC\.([^\s"]+)/;
    return;
}

sub model {
    my $sonic = shift;

    my $descr = $sonic->description() || '';
    return $1 if $descr =~ /\s-\sHwSku:\s+([^\s"]+)/;
    return $sonic->SUPER::model();
}

# Layer3::NetSNMP returns no serial for a generic Linux host; a switch
# serves its chassis serial in ENTITY-MIB.
sub serial {
    my $sonic = shift;
    return $sonic->SNMP::Info::Layer3::serial();
}

# The ifIndex column holds the row's index minus one, so key each
# interface by its row instead.
sub i_index {
    my $sonic   = shift;
    my $partial = shift;

    my $i_descr = $sonic->i_description($partial) || {};
    return { map { $_ => $_ } keys %$i_descr };
}

# Community builds serve no dot1dBasePortTable, and dot1qTpFdbPort holds
# an ifIndex there, so each interface is its own bridge port.
sub bp_index {
    my $sonic = shift;

    my $bp_index = $sonic->SUPER::bp_index();
    return $bp_index if ref {} eq ref $bp_index and scalar keys %$bp_index;

    my $i_index = $sonic->i_index() || {};
    return { map { $_ => $_ } keys %$i_index };
}

# dot1qTpFdbPort holds an ifIndex, not a bridge port, even where
# dot1dBasePortTable numbers the bridge ports from 0.
sub fw_port {
    my $sonic = shift;

    my $qb_fw_port      = $sonic->qb_fw_port() || {};
    my %port_of_ifindex = reverse %{ $sonic->bp_index() || {} };

    my %fw_port;
    foreach my $idx ( keys %$qb_fw_port ) {
        my $port = $port_of_ifindex{ $qb_fw_port->{$idx} };
        next unless defined $port;
        $fw_port{$idx} = $port;
    }
    return \%fw_port;
}

# ipNetToMediaTable serves only its PhysAddress column, and
# ipNetToPhysicalTable keys the same neighbors by another ifIndex, so the
# address comes from the index of each at_paddr row.
sub at_netaddr {
    my $sonic   = shift;
    my $partial = shift;

    my $at_paddr = $sonic->at_paddr($partial) || {};

    my %at_netaddr;
    foreach my $idx ( keys %$at_paddr ) {
        next unless $idx =~ /\.(\d+\.\d+\.\d+\.\d+)$/;
        $at_netaddr{$idx} = $1;
    }
    return \%at_netaddr;
}

# Neighbors identify the switch by its LLDP chassis ID.
sub mac {
    my $sonic = shift;

    my $type = $sonic->lldp_loc_id_type() // '';
    my $id   = $sonic->lldp_loc_id();
    return $id if $type =~ /mac/ and defined $id and $id =~ $MAC_RE;
    return $sonic->SUPER::mac();
}

# Community builds serve the LLDP local scalars without their .0 instance.
sub lldp_loc_id_type {
    my $sonic = shift;
    return $sonic->orig_lldp_loc_id_type() // $sonic->sonic_loc_id_type();
}

sub lldp_loc_id_os {
    my $sonic = shift;
    return $sonic->orig_lldp_loc_id_os() // $sonic->sonic_loc_id_os();
}

# The agent can serve lldpRemManAddrTable under a later time mark than
# lldpRemTable, so the two share no key. The local port and remote index
# identify the neighbor; where two time marks give the same neighbor, the
# later row is kept.
sub _lldp_rem {
    my ( $sonic, $method, $partial ) = @_;

    my $rows = $sonic->SUPER::_lldp_rem( $method, $partial );
    my @keys
        = sort { _lldp_time_mark($a) <=> _lldp_time_mark($b) } keys %$rows;

    my %rows;
    foreach my $key (@keys) {
        next unless $key =~ /^\d+\.(\d+(?:\.\d+)*)$/;
        $rows{"0.$1"} = $rows->{$key};
    }
    return \%rows;
}

sub _lldp_time_mark {
    my $key = shift;

    return $key =~ /^(\d+)\./ ? $1 : 0;
}

# Enterprise SONiC 4.4 serves dot1qPvid as 0 on most ports, including ports
# learning addresses in a VLAN, so 0 is read as unknown.
sub i_vlan {
    my $sonic   = shift;
    my $partial = shift;

    my $i_vlan = $sonic->SUPER::i_vlan($partial) || {};
    return {
        map  { $_ => $i_vlan->{$_} }
        grep { $i_vlan->{$_} } keys %$i_vlan
    };
}

sub i_untagged { goto &i_vlan }

# Enterprise SONiC 4.4 serves the VLAN port lists as text ("ff ff f8 80
# 00"), and they put ports untagged in several VLANs at once, so they are
# not read. Community builds serve no VLAN tables.
sub i_vlan_membership          { return {} }
sub i_vlan_membership_untagged { return {} }

1;
__END__

=head1 NAME

SNMP::Info::Layer3::SONiC - SNMP Interface to SONiC switches

=head1 AUTHOR

SNMP::Info Developers

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $sonic = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $sonic->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for switches running SONiC, both the community builds and the
enterprise distributions from Dell and Broadcom. They are recognized by
their C<sysDescr>, since their C<sysObjectID> may be Net-SNMP's, Dell's or
Broadcom's.

The SNMP agent serves no C<ifStackTable> and no F<IEEE8023-LAG-MIB>, so
link aggregation members are not reported.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3::NetSNMP

=back

=head2 Required MIBs

None.

=head2 Inherited MIBs

See L<SNMP::Info::Layer3::NetSNMP/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=head2 Overrides

=over

=item $sonic->layers()

Returns C<sysServices> with layers 2 and 3 added. The agent reports a
fixed C<sysServices> of 72 (layers 4 and 7) whatever the switch does.

=item $sonic->vendor()

Returns the hardware maker named at the start of the hardware SKU, such as
'dell' for C<DellEMC-S5248f-P-25G-DPB> or C<Force10-S6000>, or 'accton' for
C<Accton-AS7726-32X>. Returns 'sonic' for a SKU it does not recognize.

=item $sonic->os()

Returns 'sonic'.

=item $sonic->os_ver()

Returns the software version from C<sysDescr>, the text after C<SONiC.>,
such as C<4.4.1-Enterprise_Base>.

=item $sonic->model()

Returns the hardware SKU from C<sysDescr> (C<HwSku>).

=item $sonic->serial()

Returns the chassis serial number from F<ENTITY-MIB>.

=item $sonic->mac()

Returns the LLDP chassis ID when it is a MAC address, which is how the
switch's neighbors identify it. Otherwise returns the inherited C<mac()>.

(C<lldpLocChassisId>)

=item $sonic->sonic_loc_id_type()

The LLDP chassis ID subtype, read without the C<.0> instance that community
builds leave off.

(C<lldpLocChassisIdSubtype>)

=item $sonic->sonic_loc_id_os()

The LLDP chassis ID, read without the C<.0> instance.

(C<lldpLocChassisId>)

=item $sonic->lldp_loc_id_type()

Returns C<lldpLocChassisIdSubtype>, or C<sonic_loc_id_type()> when the agent
serves no C<.0> instance.

=item $sonic->lldp_loc_id_os()

Returns C<lldpLocChassisId>, or C<sonic_loc_id_os()> when the agent serves
no C<.0> instance.

=back

=head2 Global Methods imported from SNMP::Info::Layer3::NetSNMP

See documentation in L<SNMP::Info::Layer3::NetSNMP> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

The keys of every LLDP neighbor method begin with C<0> in place of the time
mark, since the agent can serve C<lldpRemManAddrTable> under a later time
mark than C<lldpRemTable>.

=over

=item $sonic->i_index()

Returns reference to hash. Maps each interface's row index to itself. The
agent serves C<ifIndex> values one less than the row index.

=item $sonic->bp_index()

Returns reference to hash. Returns C<dot1dBasePortIfIndex> when the agent
serves it. Otherwise maps each interface to itself, since C<dot1qTpFdbPort>
then holds an ifIndex.

=item $sonic->fw_port()

Returns reference to hash. Returns the bridge port of each forwarding entry,
mapped back from the ifIndex that C<dot1qTpFdbPort> holds through
C<bp_index()>. Entries whose interface has no bridge port are left out.

=item $sonic->at_netaddr()

Returns reference to hash. The IPv4 address of each C<at_paddr()> row, taken
from its index. C<ipNetToMediaTable> serves only its C<PhysAddress> column.

=item $sonic->i_vlan()

Returns reference to hash of the port VLAN ID, keyed by ifIndex, as the
inherited method does, leaving out ports whose C<dot1qPvid> is 0.
Enterprise SONiC 4.4 serves 0 on most ports, including ports learning
addresses in a VLAN.

=item $sonic->i_untagged()

Same as C<i_vlan()>.

=item $sonic->i_vlan_membership()

Returns reference to an empty hash. Enterprise SONiC 4.4 serves the
Q-BRIDGE VLAN port lists as text that does not decode to the VLAN
membership, and the community agent serves none.

=item $sonic->i_vlan_membership_untagged()

Returns reference to an empty hash, for the reason given under
C<i_vlan_membership()>.

=back

=head2 Table Methods imported from SNMP::Info::Layer3::NetSNMP

See documentation in L<SNMP::Info::Layer3::NetSNMP> for details.

=cut
