# SNMP::Info::Layer3::H3C
#
# Copyright (c) 2018 Jeroen van Ingen
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

package SNMP::Info::Layer3::H3C;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::IEEE802dot3ad 'agg_ports_lag';

@SNMP::Info::Layer3::H3C::ISA = qw/
  SNMP::Info::IEEE802dot3ad
  SNMP::Info::Layer3
  Exporter
/;
@SNMP::Info::Layer3::H3C::EXPORT_OK = qw/
  agg_ports
/;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.983000';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::IEEE802dot3ad::MIBS,
    'HH3C-LswDEVM-MIB'     => 'hh3cDevMFanStatus',
    'HH3C-LswINF-MIB'      => 'hh3cSlotPortMax',
    'HH3C-LSW-DEV-ADM-MIB' => 'hh3cLswSysVersion',
    'HH3C-PRODUCT-ID-MIB'  => 'hh3c-s5500-28C-EI',
    'HH3C-ENTITY-VENDORTYPE-OID-MIB' => 'hh3cevtOther',
    'HH3C-LswMSTP-MIB'     => 'hh3cdot1sStpForceVersion',
    'HH3C-IP-ADDRESS-MIB'  => 'hh3cIpAddrSetMask',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'fan' => 'hh3cDevMFanStatus.1',
    'ps1_status' => 'hh3cDevMPowerStatus.1',
    'ps2_status' => 'hh3cDevMPowerStatus.2',

    # HH3C-LswMSTP-MIB
    'h3c_stp_version' => 'hh3cdot1sStpForceVersion',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::IEEE802dot3ad::FUNCS,
    i_duplex_admin => 'hh3cifEthernetDuplex',
    ad_port_attached_agg => 'dot3adAggPortAttachedAggID',

    # HH3C-LswMSTP-MIB::hh3cdot1sInstanceTable, indexed by instance
    'h3c_stp_i_id'     => 'hh3cdot1sInstanceID',
    'h3c_stp_i_bridge' => 'hh3cdot1sMstiBridgeID',
    'h3c_stp_i_root'   => 'hh3cdot1sMstiDesignedRoot',

    # HH3C-LswMSTP-MIB::hh3cdot1sPortTable, indexed <instance>.<bridge port>
    'h3c_stp_p_state'  => 'hh3cdot1sMstiState',
    'h3c_stp_p_bridge' => 'hh3cdot1sMstiDesignatedBridge',
    'h3c_stp_p_port'   => 'hh3cdot1sMstiDesignatedPort',

    # HH3C-LswMSTP-MIB::hh3cdot1sMstiVlanTable, indexed by VLAN id
    'h3c_stp_vlan_mst' => 'hh3cdot1sOperMstID',

    # HH3C-IP-ADDRESS-MIB::hh3cIpAddrSetTable, indexed
    # ifIndex.addrType.length.address
    'vrf_h3c_addr_mask' => 'hh3cIpAddrSetMask',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::IEEE802dot3ad::MUNGE,
    'h3c_stp_i_bridge' => \&SNMP::Info::munge_prio_mac,
    'h3c_stp_i_root'   => \&SNMP::Info::munge_prio_mac,
    'h3c_stp_p_bridge' => \&SNMP::Info::munge_prio_mac,
    'h3c_stp_p_port'   => \&SNMP::Info::munge_prio_port,
);

sub vendor {
    my $h3c = shift;
    my $mfg = $h3c->entPhysicalMfgName(1) || {};
    return $mfg->{1} || "h3c";
}

sub model {
    my $h3c = shift;
    my $id    = $h3c->id() || '';
    my $descr = $h3c->description() || '';

    my $entclass = $h3c->entPhysicalClass(2) || {};
    my $entity   = $entclass->{2} || '';
    my $entname  = $h3c->entPhysicalName(2)  || {};

    if ($descr =~ /^.*\n(.*)\n/) {
        return $1;
    } elsif ($entity =~ /^(3|chassis)$/) {
        return $entname->{2};
    } else {
        return &SNMP::translateObj($id) || $id;
    }
}

sub os {
    my $h3c = shift;
    my $descr   = $h3c->description();

    return $1 if ( $descr =~ /(\S+)\s+Platform Software/ );
    return "H3C";
}

sub os_ver {
    my $h3c = shift;
    my $descr   = $h3c->description();
#    my $version = $h3c->hh3cLswSysVersion(); # Don't use, indicates base version only, no release details
    my $ver_release = $h3c->entPhysicalSoftwareRev(2) || {};
    my $os_ver  = undef;

    $os_ver = "$1 $2" if ( $descr =~ /Software Version ([^,]+),.*(Release\s\S+)/i );
    $os_ver = "$1" if ( $descr =~ /Product Version ([0-9.]+)/i );

    return $ver_release->{2} || $os_ver;
}

sub i_ignore {
    my $l3      = shift;
    my $partial = shift;

    my $interfaces = $l3->interfaces($partial) || {};

    my %i_ignore;
    foreach my $if ( keys %$interfaces ) {

        # lo0 etc
        if ( $interfaces->{$if} =~ /\blo\d*\b/i ) {
            $i_ignore{$if}++;
        }
    }
    return \%i_ignore;
}

# Some Comware firmware uses a different numbering scheme in the PortList.
# AttachedAggID is indexed directly by ifIndex, including unselected members.
sub _attached_agg_ports {
    my $h3c = shift;
    my $attached = $h3c->ad_port_attached_agg() || {};
    my $interfaces = $h3c->interfaces() || {};
    my %members;
    foreach my $member (keys %$attached) {
        my $aggregate = $attached->{$member};
        next unless defined $aggregate && $aggregate =~ /^\d+$/ && $aggregate > 0;
        next if $member eq $aggregate;
        next unless ($interfaces->{$member} || '') =~ /Ethernet/;
        next unless ($interfaces->{$aggregate} || '') =~ /^Bridge-Aggregation\d+$/;
        $members{$member} = $aggregate;
    }
    return \%members;
}

sub agg_ports {
    my $h3c = shift;
    my $members = $h3c->_attached_agg_ports();
    return $members if scalar keys %$members;
    return agg_ports_lag($h3c, @_);
}

sub i_stp_state {
    my ($h3c, $partial) = @_;

    # dot1dStpPortState there matches no VLAN's tree, so it would label a
    # port with the wrong tree's state
    return {} if $h3c->_h3c_comware7()
        and ( $h3c->_h3c_stp_protocol() || '' ) eq 'pvst';
    my %states = %{ $h3c->SUPER::i_stp_state($partial) || {} };
    my $members = $h3c->_attached_agg_ports();
    delete @states{keys %$members};
    return \%states;
}

# CH: overwrite and always return empty mapping for qb_fdb_index
# see https://github.com/netdisco/snmp-info/issues/218
# if no fdb->vlan mapping is available the fdb is assumed to be the vlan
# which is ok for h3c
# otherwise h3c will deliver a broken vlan mapping and nodes will jump
# other all vlans
sub qb_fdb_index {
    return {};
}

# The OS version is not in os_ver(), whose regex misses some Comware 7
# sysDescr strings
sub _h3c_comware7 {
    my $h3c = shift;
    return ( $h3c->description() || '' ) =~ /Software Version 7\./ ? 1 : 0;
}

# 0 when a named walk is known to be incomplete; an absent or empty column
# is complete
sub _h3c_stp_shape_ok {
    my ( $h3c, @methods ) = @_;

    foreach my $method (@methods) {
        my $status = $h3c->walk_status($method);
        return 0 if $status and !$status->{complete};
    }
    return 1;
}

# The version is a read-write setting, so it names the protocol the device
# runs. Its enumeration has no PVST value, so under rstp the instance table
# shape is the only indicator: VLAN rows with no bridge or port-state column
sub _h3c_stp_protocol {
    my $h3c = shift;

    my $version = $h3c->h3c_stp_version();
    return unless defined $version;
    return 'stp'  if $version =~ /^(?:stp|0)$/;
    return 'mstp' if $version =~ /^(?:mstp|3)$/;
    return unless $version =~ /^(?:rstp|2)$/;

    # walk_status is set by the walk, so read the columns before checking it
    my $has_instances = %{ $h3c->h3c_stp_i_id() || {} };
    my $has_bridges   = %{ $h3c->h3c_stp_i_bridge() || {} };
    my $has_states    = %{ $h3c->h3c_stp_p_state() || {} };
    return unless $h3c->_h3c_stp_shape_ok(
        qw/h3c_stp_i_id h3c_stp_i_bridge h3c_stp_p_state/);
    return 'pvst' if $has_instances and !$has_bridges and !$has_states;
    return 'rstp';
}

sub hasSTP {
    my $h3c = shift;
    return ( $h3c->_h3c_stp_protocol() || '' ) eq 'stp' ? 1 : 0;
}

sub hasRSTP {
    my $h3c = shift;
    return ( $h3c->_h3c_stp_protocol() || '' ) eq 'rstp' ? 1 : 0;
}

sub hasMSTP {
    my $h3c = shift;
    return ( $h3c->_h3c_stp_protocol() || '' ) eq 'mstp' ? 1 : 0;
}

sub hasPVST {
    my $h3c = shift;
    return ( $h3c->_h3c_stp_protocol() || '' ) eq 'pvst' ? 1 : 0;
}

sub stp_protocols {
    my $h3c = shift;

    my $protocol = $h3c->_h3c_stp_protocol();
    return unless defined $protocol;
    return [$protocol];
}

sub stp_trees {
    my $h3c = shift;

    return unless $h3c->_stp_default_context_ok();
    return $h3c->{_stp_trees} if $h3c->{_stp_trees};

    my $protocol = $h3c->_h3c_stp_protocol() or return {};
    my $measured
        = ( $h3c->_h3c_comware7() and $protocol =~ /^(?:mstp|rstp|pvst)$/ )
        ? 1
        : 0;

    my $trees;
    if ( $protocol eq 'mstp' ) {
        $trees = $h3c->_h3c_mstp_trees($measured);
    }
    elsif ( $protocol eq 'pvst' ) {
        $trees = $h3c->_h3c_pvst_trees($measured);
    }
    else {
        my $record = $h3c->_stp_dot1d_tree();
        $trees
            = $record
            ? { 'cist.0' => { %$record, protocol => $protocol,
                measured => $measured } }
            : {};
    }
    $h3c->{_stp_trees} = $trees if keys %$trees;
    return $trees;
}

sub _h3c_pvst_trees {
    my ( $h3c, $measured ) = @_;

    my $instances = $h3c->h3c_stp_i_id() || {};
    my %trees;
    foreach my $vlan ( grep { $_ } keys %$instances ) {
        $trees{"vlan.$vlan"} = {
            type           => 'vlan',
            id             => $vlan,
            vlan           => $vlan,
            protocol       => 'pvst',
            measured       => $measured,
            ports_complete => 0,
            contexts       => [],
            bridge         => undef,
            root           => undef,
        };
    }
    return \%trees;
}

sub _h3c_tree_key {
    my $instance = shift;
    return $instance ? "msti.$instance" : 'cist.0';
}

sub _h3c_mstp_trees {
    my ( $h3c, $measured ) = @_;

    my $instances = $h3c->h3c_stp_i_id()     || {};
    my $bridges   = $h3c->h3c_stp_i_bridge() || {};
    my $roots     = $h3c->h3c_stp_i_root()   || {};
    my $states    = $h3c->h3c_stp_p_state()  || {};
    my $bp_index  = $h3c->bp_index()         || {};

    my %unmapped;
    foreach my $row ( keys %$states ) {
        my ( $instance, $port ) = split /\./, $row, 2;
        $unmapped{$instance} = 1 unless defined $bp_index->{$port};
    }

    my %trees;
    foreach my $instance ( keys %$instances ) {
        $trees{ _h3c_tree_key($instance) } = {
            type           => $instance ? 'msti' : 'cist',
            id             => $instance,
            protocol       => 'mstp',
            measured       => $measured,
            ports_complete => $unmapped{$instance} ? 0 : 1,
            contexts       => [ { kind => 'none' } ],
            bridge => scalar SNMP::Info::Bridge::_stp_decode_bridge_id(
                $bridges->{$instance} ),
            root => scalar SNMP::Info::Bridge::_stp_decode_bridge_id(
                $roots->{$instance} ),
        };
    }
    return \%trees;
}

sub stp_tree_ports {
    my ( $h3c, $tree_key ) = @_;

    my $tree = $h3c->_stp_tree_for_key($tree_key) or return;
    return {} if $tree->{protocol} eq 'pvst';
    my $rows
        = $tree->{protocol} eq 'mstp'
        ? $h3c->_h3c_mstp_port_rows($tree)
        : $h3c->_stp_dot1d_port_rows($tree);

    delete @{$rows}{ keys %{ $h3c->_attached_agg_ports() } };
    return $rows;
}

sub _h3c_mstp_port_rows {
    my ( $h3c, $tree ) = @_;

    my $states   = $h3c->h3c_stp_p_state()  || {};
    my $d_bridge = $h3c->h3c_stp_p_bridge() || {};
    my $d_port   = $h3c->h3c_stp_p_port()   || {};
    my $enable   = $h3c->stp_p_enable()     || {};
    my $bp_index = $h3c->bp_index()         || {};

    my %rows;
    foreach my $row ( keys %$states ) {
        my ( $instance, $port ) = split /\./, $row, 2;
        next unless $instance == $tree->{id};

        my $iid = $bp_index->{$port};
        next unless defined $iid;
        $rows{$iid} = {
            tree_type         => $tree->{type},
            tree_id           => $tree->{id},
            state             => $states->{$row},
            role              => undef,
            role_raw          => undef,
            enabled           =>
                scalar SNMP::Info::Bridge::_stp_enabled( $enable->{$port} ),
            designated_bridge =>
                scalar SNMP::Info::Bridge::_stp_decode_bridge_id(
                $d_bridge->{$row} ),
            designated_port =>
                scalar SNMP::Info::Bridge::_stp_decode_port_id(
                $d_port->{$row} ),
        };
    }
    return \%rows;
}

sub stp_trees_complete {
    my $h3c = shift;

    my $trees = $h3c->stp_trees() || {};
    return keys %$trees ? 1 : 0;
}

sub stp_vlan_map {
    my $h3c = shift;

    return unless ( $h3c->_h3c_stp_protocol() || '' ) eq 'mstp';
    my $instances = $h3c->h3c_stp_vlan_mst() || {};
    return unless keys %$instances;
    return {
        map { $_ => _h3c_tree_key( $instances->{$_} ) } keys %$instances
    };
}

# Comware 7 serves ipAddrTable for the default instance only, and no
# ipAddressTable. hh3cIpAddrSetTable lists every instance's IPv4 addresses
# by port, and IPV6-MIB ipv6AddrTable the IPv6 ones, link-locals included.
sub _vrf_vendor_address_rows {
    my ( $h3c, $name ) = @_;

    return {
        %{ $h3c->_vrf_ipv6_mib_address_rows($name) },
        %{ $h3c->_h3c_ipv4_address_rows($name) },
    };
}

sub _h3c_ipv4_address_rows {
    my ( $h3c, $name ) = @_;

    my $masks = $h3c->_vrf_column( 'vrf_h3c_addr_mask', $name );
    my %rows;
    foreach my $iid ( keys %$masks ) {
        my ( $ifindex, $type, $length, @octets ) = split /\./, $iid;
        next unless ( $type // q() ) eq '1' and $length == 4;
        next unless @octets == 4;
        my $ip = join q(.), @octets;
        $rows{"$ifindex.$ip"} = {
            ifindex    => $ifindex,
            ip         => $ip,
            prefix_len =>
                scalar SNMP::Info::VRF::_vrf_mask_length( $masks->{$iid} ),
            family => 'ipv4',
        };
    }
    return \%rows;
}

# Host link-locals are served as IPv6z in IP-MIB, which ipv6_n2p_addr
# does not return; IPV6-MIB ipv6NetToMediaTable has them unzoned
sub _vrf_nd_from_ipv6_mib { return 1; }

sub _vrf_subnets_from_routes { return 1; }

# Default tree is not the common tree: dot1dStp matches no VLAN's tree under
# PVST
sub _stp_default_is_common { return 0; }

1;
__END__

=head1 NAME

SNMP::Info::Layer3::H3C - SNMP Interface to L3 Devices, H3C & HP A-series

=head1 AUTHORS

Jeroen van Ingen

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $h3c = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $h3c->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for H3C & HP A-series devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::IEEE802dot3ad

=back

=head2 Required MIBs

=over

=item F<HH3C-LswDEVM-MIB>

=item F<HH3C-LswINF-MIB>

=item F<HH3C-LSW-DEV-ADM-MIB>

=item F<HH3C-PRODUCT-ID-MIB>

=item F<HH3C-ENTITY-VENDORTYPE-OID-MIB>

=item F<HH3C-LswMSTP-MIB>

=item F<HH3C-IP-ADDRESS-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::IEEE802dot3ad> for its own MIB requirements.

See L<SNMP::Info::Layer3> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $h3c->model()

Returns the model from C<sysObjectID> or C<entPhysicalClass>.

=item $h3c->vendor()

Returns value for C<entPhysicalMfgName.1>.

=item $h3c->os()

Returns the OS extracted from C<sysDescr>.

=item $h3c->os_ver()

Returns the software version. Either C<entPhysicalSoftwareRev.2> or extracted from
C<sysDescr>.

=item $h3c->qb_fdb_index()

overwritten to always return empty hash as implementation on 
h3c is broken.

=item $h3c->h3c_stp_version()

(C<hh3cdot1sStpForceVersion>)

=item $h3c->hasSTP()

Returns 1 when C<hh3cdot1sStpForceVersion> is C<stp(0)>, else 0.

=item $h3c->hasRSTP()

Returns 1 when C<hh3cdot1sStpForceVersion> is C<rstp(2)>, else 0.

=item $h3c->hasPVST()

Returns 1 when the tables show PVST (see L</"Spanning Tree Trees">), else 0.

=item $h3c->hasMSTP()

Returns 1 when C<hh3cdot1sStpForceVersion> is C<mstp(3)>, else 0.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Globals imported from SNMP::Info::IEEE802dot3ad

See documentation in L<SNMP::Info::IEEE802dot3ad> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $h3c->i_ignore()

Returns reference to hash.  Increments value of IID if port is to be ignored.

Ignores loopback

=item $h3c->i_stp_state()

Returns inherited STP states, omitting physical members of confirmed
Bridge-Aggregation interfaces. STP applies to the logical aggregate; an omitted
member state does not mean that the member or aggregate is forwarding.
The aggregate and non-member states are retained. No MSTP instance states
are combined into this single per-interface result.  Under MSTP the
inherited states are the CIST's.  Under PVST on Comware 7 returns an empty
hash, because C<dot1dStpPortState> there matches no VLAN's tree.

=item $h3c->ad_port_attached_agg()

Returns the raw member ifIndex to attached aggregate ifIndex mapping from
C<dot3adAggPortAttachedAggID>. Zero means no attached aggregate.

=item C<agg_ports>

Prefers validated C<dot3adAggPortAttachedAggID> mappings for Bridge-Aggregation
interfaces, falling back to the inherited port-list mapping when none are
available.

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.

=back

=head2 Table Methods

=over

=item $h3c->h3c_stp_i_id()

(C<hh3cdot1sInstanceID>)

=item $h3c->h3c_stp_i_bridge()

(C<hh3cdot1sMstiBridgeID>)

=item $h3c->h3c_stp_i_root()

(C<hh3cdot1sMstiDesignedRoot>)

=item $h3c->h3c_stp_p_state()

(C<hh3cdot1sMstiState>)

=item $h3c->h3c_stp_p_bridge()

(C<hh3cdot1sMstiDesignatedBridge>)

=item $h3c->h3c_stp_p_port()

(C<hh3cdot1sMstiDesignatedPort>)

=item $h3c->h3c_stp_vlan_mst()

(C<hh3cdot1sOperMstID>)

=item $h3c->vrf_h3c_addr_mask()

Returns reference to hash of the IPv4 address masks of every routing
instance, indexed by ifIndex, address type, length and address.
C<vrf_addresses()> reads it; see L</"VRF Instances">.

(C<hh3cIpAddrSetMask>)

=back

=head2 VRF Instances

See L<SNMP::Info::VRF/"VRF Instances"> for the readers. Comware 7 serves
no C<ipAddressTable>, and an C<ipAddrTable> holding the default instance
only. This class fills the gaps:

=over

=item *

C<vrf_addresses()> reads every instance's IPv4 addresses from
C<hh3cIpAddrSetTable>, and its IPv6 addresses, anycast ones included,
from F<IPV6-MIB> C<ipv6AddrTable>. Each instance then lists its own
addresses.

=item *

C<vrf_neighbors()> adds host link-local neighbors from F<IPV6-MIB>
C<ipv6NetToMediaTable>. Comware serves them in F<IP-MIB> only with a
zone, which C<ipv6_n2p_addr()> does not return.

=item *

C<vrf_subnets()> adds connected routes (see
L<SNMP::Info::VRF/"Collapsed Subnets">).

=back

=head2 Spanning Tree Trees

These override L<SNMP::Info::Bridge/"Spanning Tree Trees">; records are as
described there.  The protocol is the one C<hh3cdot1sStpForceVersion> names.
Under MSTP the CIST and each MSTI come from the C<HH3C-LswMSTP-MIB>
instance and port tables, keyed C<cist.0> and C<msti.E<lt>instanceE<gt>>;
their bridge IDs carry the instance number in the low 12 bits.  Under RSTP
and STP the one tree comes from C<BRIDGE-MIB>, whose values the instance
tables only copy.  The MIBs serve no port role, so C<role> and C<role_raw>
are undef.  Physical members of a Bridge-Aggregation interface are omitted,
as in C<i_stp_state()>.  C<measured> is 1 on Comware 7 under MSTP, RSTP
and PVST.  Under PVST, which C<hh3cdot1sStpForceVersion> does not name, the
protocol is C<pvst> when the force version is C<rstp>, the instance table
lists instances and neither C<hh3cdot1sMstiBridgeID> nor
C<hh3cdot1sMstiState> has rows.  Each VLAN in the instance table (not 0)
becomes a C<vlan.N> tree with no context, no bridge or root, and
C<ports_complete> 0, since no port data is served for it.  When one of
those three walks was incomplete the protocol is unknown and no trees are
reported.

=over

=item $h3c->stp_protocols()

Returns reference to an array holding the protocol, or nothing.

=item $h3c->stp_trees()

Returns reference to hash of tree records, or an empty hash when no force
version is served.  Without the force-version object PVST cannot be told from
RSTP or MSTP, and C<BRIDGE-MIB> states are wrong under PVST, so no
C<dot1dStp> tree is reported.

=item $h3c->stp_tree_ports($tree_key)

Returns reference to hash of the tree's port records keyed by ifIndex.

=item $h3c->stp_trees_complete()

Returns 1 when trees were read, 0 otherwise.  Under PVST every VLAN tree is
listed, so it is 1.

=item $h3c->stp_vlan_map()

Under MSTP returns reference to hash mapping VLAN id to tree key, from
C<hh3cdot1sOperMstID>.  Otherwise nothing; RSTP still serves the unused
region map.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Table Methods imported from SNMP::Info::IEEE802dot3ad

See documentation in L<SNMP::Info::IEEE802dot3ad> for details.

=cut
