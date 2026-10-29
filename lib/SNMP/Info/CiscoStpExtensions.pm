# SNMP::Info::CiscoStpExtensions
#
# Copyright (c)2009 Carlos Vicente
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#     * Neither the name of the author nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::CiscoStpExtensions;

use strict;
use warnings;
use Exporter;
use SNMP::Info;
use SNMP::Info::Bridge;

our ($VERSION, $DEBUG, %MIBS, %FUNCS, %GLOBALS, %MUNGE, %PORTSTAT, $INIT);

$VERSION = '3.983000';

@SNMP::Info::CiscoStpExtensions::ISA = qw/SNMP::Info::Bridge SNMP::Info Exporter/;
@SNMP::Info::CiscoStpExtensions::EXPORT_OK = qw//;

%MIBS    = (
            %SNMP::Info::Bridge::MIBS,
            'CISCO-STP-EXTENSIONS-MIB' => 'stpxSpanningTreeType',
           );

%GLOBALS = (
            %SNMP::Info::Bridge::GLOBALS,
            'stpx_mst_config_digest' => 'stpxSMSTConfigDigest',
            'stpx_mst_region_name'   => 'stpxMSTRegionName',
            'stpx_mst_region_rev'    => 'stpxSMSTRegionRevision',
            'stpx_stp_type'          => 'stpxSpanningTreeType',
            'stpx_bpduguard_enable'  => 'stpxFastStartBpduGuardEnable',
            'stpx_bpdufilter_enable' => 'stpxFastStartBpduFilterEnable',
            'stpx_faststart_default' => 'stpxFastStartGlobalDefaultMode',
           );

%FUNCS   = (
            %SNMP::Info::Bridge::FUNCS,
            'stpx_rootguard_enabled'      => 'stpxRootGuardConfigEnabled',
            'stpx_loopguard_enabled'      => 'stpxLoopGuardConfigEnabled',
            'stpx_faststart_enabled'      => 'stpxFastStartPortEnable',
            'stpx_faststart_operational'  => 'stpxFastStartPortMode',
            'stpx_port_bpduguard_mode'    => 'stpxFastStartPortBpduGuardMode',
            'stpx_port_bpdufilter_mode'   => 'stpxFastStartPortBpduFilterMode',
            'stpx_smst_root'              => 'stpxSMSTInstanceCISTRegionalRoot',
            'stpx_smst_vlans_mapped_1k2k' => 'stpxSMSTInstanceVlansMapped1k2k',
            'stpx_smst_vlans_mapped_3k4k' => 'stpxSMSTInstanceVlansMapped3k4k',
            'stpx_pvst_vlan_enable'       => 'stpxPVSTVlanEnable',
            'stpx_faststart_oper'         => 'stpxFastStartOperMode',
            'stpx_rstp_port_role'         => 'stpxRSTPPortRoleValue',
           );

%MUNGE   = (
            %SNMP::Info::Bridge::MUNGE,
           'stpx_mst_config_digest'      => \&SNMP::Info::CiscoStpExtensions::oct2str,
           'stpx_rstp_port_role' => \&SNMP::Info::munge_stpx_port_role,
           );


# Report version of STP via standard method
sub stp_ver {
     my $self = shift;
     my $stp_ver = $self->SUPER::stp_ver();
     if ( !defined($stp_ver) || $stp_ver eq 'unknown' ){
         if ( defined $self->stpx_stp_type() ){
             $stp_ver = $self->stpx_stp_type();
         }
     }
     return $stp_ver;
}

sub mst_config_digest {
    my $self = shift;
    return $self->stpx_mst_config_digest;
}

sub mst_region_name {
    my $self = shift;
    return $self->stpx_mst_region_name;
}

sub mst_region_rev {
    my $self = shift;
    return $self->stpx_mst_region_rev;
}


sub mst_vlan2instance {
    my $self = shift;

    # Get MST vlan-to-instance mapping
    my $m1k2k = $self->stpx_smst_vlans_mapped_1k2k;
    my $m3k4k = $self->stpx_smst_vlans_mapped_3k4k;

    # Get list of VLANs
    my $vlan_membership = $self->i_vlan_membership;
    my @vlans;
    foreach my $iid ( keys %$vlan_membership ){
        if ( my $vm = $vlan_membership->{$iid} ){
            foreach my $vid ( @$vm ){
                push @vlans, $vid;
            }
        }
    }
    my %res;
    foreach my $vlan ( @vlans ){
        if ( $vlan < 2048 ){
            foreach my $inst ( keys %$m1k2k ){
                my $list = $m1k2k->{$inst};
                my $vlanlist = [split(//, unpack("B*", $list))];
                if ( @$vlanlist[$vlan] ){
                    $res{$vlan} = $inst;
                    last;
                }
            }
        }else{
            foreach my $inst ( keys %$m3k4k ){
                my $list = $m3k4k->{$inst};
                my $vlanlist = [split(//, unpack("B*", $list))];
                if ( @$vlanlist[$vlan-2048] ){
                    $res{$vlan} = $inst;
                    last;
                }
            }
        }
    }
    return \%res;
}

sub i_rootguard_enabled {
    my $self    = shift;
    my $partial = shift;

    my $rg_enabled = $self->stpx_rootguard_enabled();
    my $bp_index   = $self->bp_index($partial);

    my %res;
    foreach my $index ( keys %$rg_enabled ){
        my $enabled = $rg_enabled->{$index};
        my $iid     = $bp_index->{$index};
        next unless defined $iid;
        next unless defined $enabled;
        $res{$iid} = $enabled;
    }
    return \%res;
}

sub i_loopguard_enabled {
    my $self    = shift;
    my $partial = shift;

    my $lg_enabled = $self->stpx_loopguard_enabled();
    my $bp_index   = $self->bp_index($partial);

    my %res;
    foreach my $index ( keys %$lg_enabled ){
        my $enabled = $lg_enabled->{$index};
        my $iid     = $bp_index->{$index};
        next unless defined $iid;
        next unless defined $enabled;
        $res{$iid} = $enabled;
    }
    return \%res;
}

sub i_bpduguard_enabled {
    my $self    = shift;
    my $partial = shift;

    my $bpdugm_default = $self->stpx_bpduguard_enable();
    my $bp_index       = $self->bp_index($partial);
    my $bpdugm         = $self->stpx_port_bpduguard_mode();

    my %res;
    foreach my $index ( keys %$bpdugm ){
        my $mode = $bpdugm->{$index};
        my $iid  = $bp_index->{$index};
        next unless defined $iid;
        next unless defined $mode;
        if ( $mode eq 'default' ){
            $res{$iid} =  $bpdugm_default;
        }else{
            $res{$iid} = $mode;
        }
    }
    return \%res;
}

sub i_bpdufilter_enabled {
    my $self    = shift;
    my $partial = shift;

    my $bpdufm_default = $self->stpx_bpdufilter_enable();
    my $bp_index       = $self->bp_index($partial);
    my $bpdufm         = $self->stpx_port_bpdufilter_mode();

    my %res;
    foreach my $index ( keys %$bpdufm ){
        my $mode = $bpdufm->{$index};
        my $iid  = $bp_index->{$index};
        next unless defined $iid;
        next unless defined $mode;
        if ( $mode eq 'default' ){
            $res{$iid} =  $bpdufm_default;
        }else{
            $res{$iid} = $mode;
        }
    }
    return \%res;
}

sub i_faststart_enabled {
    my $self    = shift;
    my $partial = shift;

    my $faststart_default = $self->stpx_faststart_default();
    my $bp_index          = $self->bp_index($partial);
    my $faststart         = $self->stpx_faststart_enabled();
    my $faststart_oper    = $self->stpx_faststart_operational();

    my %res;
    # stpxFastStartPortEnable is deprecated in favour of stpxFastStartPortMode
    # see https://github.com/netdisco/netdisco/issues/12
    foreach my $index ( keys %$faststart, keys %$faststart_oper ){
        my $mode = $faststart_oper->{$index} || $faststart->{$index};
        my $iid  = $bp_index->{$index};
        next unless defined $iid;
        next unless defined $mode;
        if ( $mode eq 'default' ){
            $res{$iid} =  $faststart_default;
        }else{
            $res{$iid} = $mode;
        }
        $res{$iid} = 'enable'  if $res{$iid} eq 'true';
        $res{$iid} = 'disable' if $res{$iid} eq 'false';
        $res{$iid} = 1 if $res{$iid} =~ m/enable/i; # enableForTrunk
        $res{$iid} = 0 if $res{$iid} eq 'disable';
    }
    return \%res;
}

sub i_edgeport_admin {
    my $self    = shift;
    my $partial = shift;

    my $faststart = $self->i_faststart_enabled($partial);

    my %res;
    foreach my $iid ( keys %$faststart ){
        my $mode = $faststart->{$iid};
        next unless defined $mode;
        $res{$iid} = 1 if $mode eq '1';
        $res{$iid} = 0 if $mode eq '0' or $mode eq 'network';
    }
    return \%res;
}

sub i_edgeport_oper {
    my $self    = shift;
    my $partial = shift;

    my $instance_of = $self->_stpx_edge_instance($partial) or return {};
    my $bp_index    = $self->bp_index() || {};
    my $oper        = $self->stpx_faststart_oper() || {};

    my %res;
    foreach my $bridge_port ( keys %$bp_index ) {
        my $iid = $bp_index->{$bridge_port};
        next unless defined $instance_of->{$iid};
        my $mode = $oper->{ $instance_of->{$iid} . ".$bridge_port" };
        next unless defined $mode;
        $res{$iid} = 1 if $mode eq 'enabled' or $mode eq '1';
        $res{$iid} = 0 if $mode eq 'disabled' or $mode eq 'network'
            or $mode eq '2' or $mode eq '3';
    }
    return \%res;
}

# ifIndex => tree instance whose FastStart oper rows describe that port
sub _stpx_edge_instance {
    my $self    = shift;
    my $partial = shift;

    my $protocol = $self->_stpx_protocol() || '';
    if ( $protocol eq 'pvst' or $protocol eq 'rapid-pvst' ) {
        return $self->i_vlan($partial);
    }
    return unless $protocol eq 'mstp';

    my $bp_index = $self->bp_index() || {};
    return { map { $_ => 0 } values %$bp_index };
}

sub oct2str {
    my ($v) = @_;
    return sprintf('%s', unpack('H*', $v));
}

# stpxSpanningTreeType; mistp and mistpPvstPlus have no tree record form
my %stpx_protocol = (
    'pvstPlus'      => 'pvst',
    1               => 'pvst',
    'rapidPvstPlus' => 'rapid-pvst',
    5               => 'rapid-pvst',
    'mst'           => 'mstp',
    4               => 'mstp',
);

sub _stpx_protocol {
    my $stpx = shift;

    my $type = $stpx->stpx_stp_type();
    return unless defined $type;
    return $stpx_protocol{$type};
}

sub hasPVST {
    my $stpx = shift;
    return ( $stpx->_stpx_protocol() || '' ) eq 'pvst' ? 1 : 0;
}

sub hasRapidPVST {
    my $stpx = shift;
    return ( $stpx->_stpx_protocol() || '' ) eq 'rapid-pvst' ? 1 : 0;
}

sub hasMSTP {
    my $stpx = shift;
    return ( $stpx->_stpx_protocol() || '' ) eq 'mstp' ? 1 : 0;
}

sub stp_protocols {
    my $stpx = shift;

    my $protocol = $stpx->_stpx_protocol();
    return unless defined $protocol;
    return [$protocol];
}

# Called by SNMP::Info::context_kinds, which a mixin cannot override
sub _context_kinds {
    my ( $stpx, $feature ) = @_;

    return ['vlan'] if $feature eq 'stp';
    return;
}

# Called by SNMP::Info::snmp_context, which a mixin cannot override
sub _snmp_context {
    my ( $stpx, $kind, $id ) = @_;

    return unless defined $kind and $kind eq 'vlan' and defined $id;
    return { kind => 'vlan', id => $id, v2c => "%s\@$id", v3 => "vlan-$id" };
}

# MSTI => [VLANs]: 1k2k bit N is VLAN N, 3k4k bit N is VLAN 2048 + N. The
# agent may serve fewer than 256 octets; the missing ones are zero.
sub _stpx_mst_vlans {
    my $stpx = shift;

    my $low  = $stpx->stpx_smst_vlans_mapped_1k2k() || {};
    my $high = $stpx->stpx_smst_vlans_mapped_3k4k() || {};

    my %vlans;
    foreach my $inst ( keys %{ { %$low, %$high } } ) {
        my $bits = join '',
            map { substr( unpack( 'B*', $_ // '' ) . '0' x 2048, 0, 2048 ) }
            $low->{$inst}, $high->{$inst};
        $vlans{$inst}
            = [ grep { substr( $bits, $_, 1 ) } 1 .. 4094 ];
    }
    return \%vlans;
}

# VLANs running a tree: a per-port row names them; stpxPVSTVlanEnable also
# enables the VTP defaults 1002 to 1005, which run none
sub _stpx_pvst_vlans {
    my $stpx = shift;

    my %vlans;
    foreach my $table (qw/stpx_faststart_oper stpx_rstp_port_role/) {
        my $rows = $stpx->$table() || {};
        $vlans{ ( split /\./, $_ )[0] } = 1 foreach keys %$rows;
    }
    return [ sort { $a <=> $b } keys %vlans ] if keys %vlans;

    my $enabled = $stpx->stpx_pvst_vlan_enable() || {};
    my $types   = $stpx->can('v_type') ? ( $stpx->v_type() || {} ) : {};
    my %type = map { ( split /\./, $_ )[-1] => $types->{$_} } keys %$types;
    return [
        sort { $a <=> $b }
            grep {
            ( $enabled->{$_} || '' ) =~ /^(?:enabled|1)$/
                and ( !%type or ( $type{$_} || '' ) =~ /^(?:ethernet|1)$/ )
            } keys %$enabled
    ];
}

sub _stpx_measured {
    my ( $stpx, $protocol ) = @_;

    my $os = $stpx->can('os') ? ( $stpx->os() || '' ) : '';
    return 1 if $os eq 'ios' or $os eq 'ios-xe';
    return 1 if $os eq 'nx-os' and $protocol ne 'pvst';
    return 0;
}

# VLAN 1's tree is the default context's
sub _stpx_vlan_contexts {
    my ( $stpx, $vlan ) = @_;

    return [ { kind => 'none' } ] if $vlan == 1;
    my $context = $stpx->snmp_context( 'vlan', $vlan );
    return $context ? [$context] : [];
}

sub _stpx_pvst_trees {
    my ( $stpx, $protocol ) = @_;

    my $measured = $stpx->_stpx_measured($protocol);
    my %trees;
    foreach my $vlan ( @{ $stpx->_stpx_pvst_vlans() } ) {
        $trees{"vlan.$vlan"} = {
            type           => 'vlan',
            id             => $vlan,
            vlan           => $vlan,
            protocol       => $protocol,
            measured       => $measured,
            ports_complete => 1,
            contexts       => $stpx->_stpx_vlan_contexts($vlan),
            bridge         => undef,
            root           => $vlan == 1
            ? scalar SNMP::Info::Bridge::_stp_decode_bridge_id(
                $stpx->stp_root() )
            : undef,
        };
    }
    return \%trees;
}

# The CIST's trunk ports have no row in any IOS context. NX-OS serves them in
# mst-0, but whether mst-0 maps bridge ports to ifIndex is unmeasured, so the
# CIST is never claimed complete
sub _stpx_mst_trees {
    my $stpx = shift;

    my $measured = $stpx->_stpx_measured('mstp');
    my $mapped   = $stpx->_stpx_mst_vlans();
    my %listed   = map { $_ => 1 } values %{ $stpx->v_index() || {} };

    my %trees;
    foreach my $inst ( keys %$mapped ) {
        my $own = $stpx->snmp_context( 'mst', $inst );
        my $tree = {
            type           => $inst ? 'msti' : 'cist',
            id             => $inst,
            protocol       => 'mstp',
            measured       => $measured,
            ports_complete => 1,
            bridge         => undef,
            root           => undef,
        };
        if ($inst) {
            my @vlans
                = grep { !%listed or $listed{$_} } @{ $mapped->{$inst} };
            $tree->{contexts} = [ ( $own ? $own : () ),
                map { @{ $stpx->_stpx_vlan_contexts($_) } } @vlans ];
        }
        else {
            $tree->{contexts}       = [ $own || { kind => 'none' } ];
            $tree->{ports_complete} = 0;
            $tree->{root} = SNMP::Info::Bridge::_stp_decode_bridge_id(
                $stpx->stp_root() );
        }
        $trees{ $inst ? "msti.$inst" : 'cist.0' } = $tree;
    }
    return \%trees;
}

sub stp_trees {
    my $stpx = shift;

    return unless $stpx->_stp_default_context_ok();
    return $stpx->{_stp_trees} if $stpx->{_stp_trees};

    my $protocol = $stpx->_stpx_protocol();
    return {} unless defined $protocol;

    my $trees
        = $protocol eq 'mstp'
        ? $stpx->_stpx_mst_trees()
        : $stpx->_stpx_pvst_trees($protocol);
    return {} unless keys %$trees;
    $stpx->{_stp_trees} = $trees;
    return $trees;
}

sub stp_trees_complete {
    my $stpx = shift;

    my $trees = $stpx->stp_trees() || {};
    my @listing = ( $stpx->_stpx_protocol() || '' ) eq 'mstp'
        ? qw/stpx_smst_vlans_mapped_1k2k stpx_smst_vlans_mapped_3k4k/
        : qw/stpx_faststart_oper stpx_rstp_port_role stpx_pvst_vlan_enable/;
    return 0 if $stpx->_stp_walk_incomplete(@listing);
    return keys %$trees ? 1 : 0;
}

sub stp_vlan_map {
    my $stpx = shift;

    return unless ( $stpx->_stpx_protocol() || '' ) eq 'mstp';
    my $mapped = $stpx->_stpx_mst_vlans();

    my %map;
    foreach my $inst ( keys %$mapped ) {
        $map{$_} = $inst ? "msti.$inst" : 'cist.0'
            foreach @{ $mapped->{$inst} };
    }
    return unless keys %map;
    return \%map;
}

# In the default context the key must be a tree read there; in a tree's own
# context the list cannot be read, so rows are labeled from the key alone
sub _stpx_tree_key_ok {
    my ( $stpx, $key ) = @_;

    return 1 if length $stpx->_walk_context();
    my $tree = ( $stpx->stp_trees() || {} )->{$key};
    unless ($tree) {
        $stpx->error_throw( "SNMP::Info::CiscoStpExtensions::stp_tree_ports()"
                . " has no tree '$key'. Pass a key from stp_trees(), read in"
                . " the default context.\n" );
        return 0;
    }
    return 1 if grep { $_->{kind} eq 'none' } @{ $tree->{contexts} };

    my $names = join( ', ',
        map { "v2c '" . ( $_->{v2c} // 'none' ) . "', v3 '"
                . ( $_->{v3} // 'none' ) . "'" } @{ $tree->{contexts} } );
    $stpx->error_throw( "SNMP::Info::CiscoStpExtensions::stp_tree_ports():"
            . " tree '$key' is served in its own context ($names): switch to"
            . " one with update() and call stp_tree_ports('$key') there.\n" );
    return 0;
}

sub stp_tree_ports {
    my $stpx = shift;
    my $key  = shift;

    my ( $type, $id ) = ( $key // '' ) =~ /^(vlan|cist|msti)\.(\d+)$/;
    unless ( defined $type ) {
        my $shown = $key // 'undef';
        $stpx->error_throw( "SNMP::Info::CiscoStpExtensions::stp_tree_ports()"
                . " takes a tree key from stp_trees(), of the form vlan.N,"
                . " cist.0 or msti.N; got '$shown'.\n" );
        return;
    }
    return unless $stpx->_stpx_tree_key_ok($key);

    my $rows = $stpx->_stp_dot1d_port_rows( { type => $type, id => $id } );
    my $roles     = $stpx->stpx_rstp_port_role()     || {};
    my $raw_roles = $stpx->stpx_rstp_port_role_raw() || {};
    my $bp_index  = $stpx->bp_index()                || {};
    foreach my $idx ( keys %$roles ) {
        my ( $inst, $port ) = split /\./, $idx;
        next unless $inst == $id;
        my $iid = $bp_index->{$port};
        next unless defined $iid;
        $rows->{$iid} ||= {
            tree_type         => $type,
            tree_id           => $id,
            state             => undef,
            role              => undef,
            role_raw          => undef,
            enabled           => undef,
            designated_bridge => undef,
            designated_port   => undef,
        };
        $rows->{$iid}{role}     = $roles->{$idx};
        $rows->{$iid}{role_raw} = $raw_roles->{$idx};
    }
    return $rows;
}

# Default tree is not the common tree: VLAN 1's tree under PVST+, VLAN 1's
# ports under MST
sub _stp_default_is_common { return 0; }

1;
__END__

=head1 NAME

SNMP::Info::CiscoStpExtensions - SNMP Interface to C<CISCO-STP-EXTENSIONS-MIB>

=head1 AUTHOR

Carlos Vicente

=head1 SYNOPSIS

   my $stpx = new SNMP::Info(
                         AutoSpecify => 1,
                         Debug       => 1,
                         DestHost    => 'myswitch',
                         Community   => 'public',
                         Version     => 2
                       )

   or die "Can't connect to DestHost.\n";

   my $class = $stpx->class();
   print " Using device sub class : $class\n";

=head1 DESCRIPTION

Create or use a subclass of SNMP::Info that inherits this class.  Do not use
directly.

For debugging you can call new() directly as you would in SNMP::Info

 my $stpx = new SNMP::Info::CiscoStpExtensions(...);

In the default context, C<i_stp_state()> reports VLAN 1's tree under PVST+
and Rapid-PVST+, with rows for VLAN 1's member ports only.  Under MST the
C<BRIDGE-MIB> globals are the CIST's and the port rows are again VLAN 1's
member ports.

=head2 Inherited Classes

=over

=item SNMP::Info

=item SNMP::Info::Bridge

=back

=head2 Required MIBs

=over

=item F<CISCO-STP-EXTENSIONS-MIB>

=back

=head1 GLOBALS

These are methods that return scalar values from SNMP

=over

=item $stpx->stp_ver()

Returns the particular STP version running on this device.
Meant to override SNMP::Info::Brigde::stp_ver()

Values: C<pvstPlus>, C<mistp>, C<mistpPvstPlus>, C<mst>, C<rapidPvstPlus>

(C<stpxSpanningTreeType>)

=item $stpx->hasPVST()

Returns 1 when C<stpxSpanningTreeType> is C<pvstPlus>.

=item $stpx->hasRapidPVST()

Returns 1 when C<stpxSpanningTreeType> is C<rapidPvstPlus>.

=item $stpx->hasMSTP()

Returns 1 when C<stpxSpanningTreeType> is C<mst>.  The MST region and its
instances are served under every mode, so they are not the test.

=item $stpx->context_kinds($feature)

See C<context_kinds()> in L<SNMP::Info>.  Returns C<['vlan']> for
C<stp>: each VLAN's tree is served in that VLAN's context.

=item $stpx->snmp_context($kind, $id)

See C<snmp_context()> in L<SNMP::Info>.  A C<vlan> context is reached as
the community suffix C<@N> under SNMPv2c and the context C<vlan-N> under
SNMPv3.  No C<mst> context is served.

=back

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $stpx->mst_config_digest()

Returns the Multiple Spanning Tree (MST) configuration digest

(C<stpxSMSTConfigDigest>)

=item $stpx->mst_region_name()

Returns the Multiple Spanning Tree (MST) region name

(C<stpxMSTRegionName>)

=item $stpx->mst_region_rev()

Returns the Multiple Spanning Tree (MST) region name

(C<stpxSMSTRegionRevision>)

=item $stpx->mst_vlan2instance()

Returns the mapping of vlan to MST instance in the form of a hash reference
with key = VLAN id, value = STP instance

=item $stpx->i_rootguard_enabled()

Returns 1 or 0 depending on whether C<RootGuard> is enabled on a given port.
Format is a hash reference with key = C<ifIndex>, value = [1|0]

(C<stpxRootGuardConfigEnabled>)

=item $stpx->i_loopguard_enabled()

Returns 1 or 0 depending on whether C<LoopGuard> is enabled on a given port.
Format is a hash reference with key = C<ifIndex>, value = [1|0]

(C<stpxLoopGuardConfigEnabled>)

=item $stpx->i_bpduguard_enabled()

Returns 1 or 0 depending on whether C<BpduGuard> is enabled on a given port.
Format is a hash reference with key = C<ifIndex>, value = [1|0]

(C<stpxFastStartPortBpduGuardMode>)

=item $stpx->i_bpdufilter_enabled()

Returns 1 or 0 depending on whether C<BpduFilter> is enabled on a given port.
Format is a hash reference with key = C<ifIndex>, value = [1|0]

(C<stpxFastStartBpduFilterEnable>)

=item $stpx->i_faststart_enabled()

Returns 1 or 0 depending on whether FastStart (aka PortFast) is enabled on a
given port.  Format is a hash reference with key = C<ifIndex>, value = [1|0]

(C<stpxFastStartPortEnable> and C<stpxFastStartPortMode>)

Legacy; see C<i_edgeport_admin()>.

=item $stpx->i_edgeport_admin()

Returns 1 or 0 depending on whether the port is configured as an edge port
(FastStart, aka PortFast).  A port in C<network> mode returns 0, and a port
with no configured value is absent.  Cisco can only report ports that
appear in the bridge table (C<bp_index()>) of the context being polled.
On IOS under PVST+ the default context lists only VLAN 1 ports and
trunks; ports in other VLANs need the per-VLAN context.  Format is a hash
reference with key = C<ifIndex>, value = [1|0]

(C<stpxFastStartPortEnable> and C<stpxFastStartPortMode>)

=item $stpx->i_edgeport_oper()

Returns 1 or 0 depending on whether the port is operating as an edge port
(FastStart, aka PortFast).  Under PVST+ and Rapid-PVST+ the value is read
from the tree of the port's native VLAN (the access VLAN on an access port,
from C<i_vlan()>); a trunk whose native VLAN has no row, or a port with no
C<i_vlan()> entry, is absent.  Under MST the value is read from instance 0.
A port in C<network> mode returns 0.  Under any other protocol the result is
empty.  Cisco can only report ports that appear in the bridge table
(C<bp_index()>) of the context being polled.  On IOS under PVST+ the
default context lists only VLAN 1 ports and trunks; ports in other VLANs
need the per-VLAN context.  Format is a hash reference with
key = C<ifIndex>, value = [1|0]

(C<stpxFastStartOperMode>)

=back

=head2 Spanning Tree Trees

These override L<SNMP::Info::Bridge/"Spanning Tree Trees">, where the
records are described.  The tree list, the protocol, the port roles and
the MST VLAN map are served in the default context.  Each tree's port
states and designated bridges and ports are served in F<BRIDGE-MIB> in
the tree's own context; to switch, see L<SNMP::Info/"SNMP Contexts">.

The tree records:

=over

=item Keys

C<vlan.N> for each VLAN under PVST+ and Rapid-PVST+.  C<cist.0> and
C<msti.N> under MST.

=item C<vlan>

The VLAN id, on C<vlan.N> trees.

=item C<protocol>

C<pvst>, C<rapid-pvst> or C<mstp>, from C<stpxSpanningTreeType>.

=item C<measured>

1 on IOS and IOS XE, and on NX-OS except under PVST+.  0 otherwise.

=item C<ports_complete>

0 for C<cist.0>, on every platform: IOS serves the CIST's trunk ports
in no context.  1 for every other tree.

=item C<contexts>

=over

=item *

C<vlan.1>: the default context.

=item *

Another C<vlan.N>: VLAN N's context.

=item *

C<msti.N>: first the instance's own C<mst> context, where
C<snmp_context('mst', N)> gives one (L<SNMP::Info::Layer3::Nexus>).
Then the context of each VLAN mapped to the instance, VLAN 1 as the
default context.  Where C<v_index()> lists VLANs, only those are used.

=item *

C<cist.0>: the instance's own C<mst> context where there is one, else
the default context.

=back

=item C<bridge>

Undef: IOS serves a placeholder C<dot1dBaseBridgeAddress>, not the bridge
address.

=item C<root>

Only on C<vlan.1> and C<cist.0>, from C<dot1dStpDesignatedRoot> in the
default context.  Undef on other trees: read C<stp_root()> in the tree's
context.

=back

The port records:

=over

=item C<state>, C<enabled>, C<designated_bridge>, C<designated_port>

From F<BRIDGE-MIB> in the context being read.

=item C<role>, C<role_raw>

From C<stpxRSTPPortRoleValue> where the context serves it, normalized by
C<munge_stpx_port_role()>.  PVST+ serves no role, and some IOS images
serve none in a VLAN context.

=back

=over

=item $stpx->stp_protocols()

Returns reference to an array holding C<pvst>, C<rapid-pvst> or C<mstp>
from C<stpxSpanningTreeType>, or nothing (including under MISTP).

=item $stpx->stp_trees()

Returns reference to hash of tree records: one per VLAN that runs
spanning tree under PVST+ and Rapid-PVST+, one per MST instance under
MST.

(C<stpxFastStartOperModeTable>, C<stpxRSTPPortRoleTable> and, where
neither serves a row, C<stpxPVSTVlanEnable> with C<vtpVlanType>;
C<stpxSMSTInstanceTable> under MST)

=item $stpx->stp_trees_complete()

Returns 1 or 0, as L<SNMP::Info::Bridge/"Spanning Tree Trees">
describes.  0 when no tree is listed, as when the device names no
protocol this class reads, and when a walk of the tables that list the
trees was incomplete.

=item $stpx->stp_vlan_map()

Returns reference to hash mapping each VLAN 1 to 4094 to its tree key under
MST, from (C<stpxSMSTInstanceVlansMapped1k2k>) and
(C<stpxSMSTInstanceVlansMapped3k4k>), as served; nothing under PVST+ and
Rapid-PVST+, where each VLAN is its own tree.

=item $stpx->stp_tree_ports($tree_key)

Returns reference to hash of port records keyed by ifIndex, read in the
session's current context.  Rows are labeled from C<$tree_key>, never
from the context.

=over

=item *

In the default context, pass a tree whose C<contexts> include the
default context.  For any other tree it returns nothing, with
C<error()> naming the tree's contexts.

=item *

In another context, it cannot check the key against the tree list.
Pass a tree whose C<contexts> list this context: rows read in any other
context describe another tree.

=back

=item $stpx->stpx_pvst_vlan_enable()

(C<stpxPVSTVlanEnable>)

=item $stpx->stpx_faststart_oper()

(C<stpxFastStartOperMode>)

=item $stpx->stpx_rstp_port_role()

(C<stpxRSTPPortRoleValue>)

=back

=head1 MUNGES

=over

=item oct2str()

Unpacks H* into a string

=back

=cut
