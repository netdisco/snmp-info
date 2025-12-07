# SNMP::Info::Layer2::TPLink
#
# Copyright (c) 2025 The Netdisco Developer Team
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

package SNMP::Info::Layer2::TPLink;

use strict;
use warnings;
use Exporter;
use Data::Dumper;
use SNMP::Info::Layer2;
use SNMP::Info::EtherLike;

@SNMP::Info::Layer2::TPLink::ISA = qw/
    SNMP::Info::EtherLike SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::TPLink::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.974000';

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
    %SNMP::Info::EtherLike::MIBS,
    # Ensure we can reference TP-Link system/product objects
    'TPLINK-SYSINFO-MIB' => 'tpSysInfoDescription',
    'TPLINK-MIB'         => 'tplinkProducts',
    'TPLINK-LLDP-MIB'    => 'tplinkLldpMIBObjects',
    'TPLINK-DOT1Q-VLAN-MIB' => 'tplinkDot1qVlanMIBObjects',
    'TPLINK-PORTCONFIG-MIB' => 'tpPortConfigTable',
    'TPLINK-SPANNING-TREE-MIB' => 'tplinkSpanningTreeMIBObjects',
    'TPLINK-L2BRIDGE-MIB' => 'tplinkl2BridgeMIBObjects',
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
    %SNMP::Info::EtherLike::GLOBALS,
    'tp_sysinfo_descr'    => 'tpSysInfoDescription',
    'tp_sysinfo_hostname' => 'tpSysInfoHostName',
    'tp_sysinfo_hwver'    => 'tpSysInfoHwVersion',
    'tp_sysinfo_swver'    => 'tpSysInfoSwVersion',
    'tp_sysinfo_mac'      => 'tpSysInfoMacAddr',
    # Spanning Tree globals from TP-Link private MIB
    'stp_ver'       => 'TPLINK-SPANNING-TREE-MIB::tpStpMode',
    'stp_time'      => 'TPLINK-SPANNING-TREE-MIB::tpStpLastTopologyChangeTime',
    'stp_root'      => 'TPLINK-SPANNING-TREE-MIB::tpStpCISTRoot',
    'stp_root_port' => 'TPLINK-SPANNING-TREE-MIB::tpStpRootPort',
    'stp_priority'  => 'TPLINK-SPANNING-TREE-MIB::tpStpCistPriority',
    'v_index'    => 'TPLINK-DOT1Q-VLAN-MIB::dot1qVlanId',
    'v_name' => 'TPLINK-DOT1Q-VLAN-MIB::dot1qVlanDescription',
    # 'i_description' => 'TPLINK-PORTCONFIG-MIB::tpPortConfigDescription',
    
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
    %SNMP::Info::EtherLike::FUNCS,
    # Ensure Ethernet/duplex index funcs are present for autoload
    'el_index'  => 'dot3StatsIndex',
    'el_duplex' => 'dot3StatsDuplexStatus',
    # TP-Link DOT1Q VLAN MIB helpers
    'tp_i_vlan_membership_untagged' => 'TPLINK-DOT1Q-VLAN-MIB::vlanPortPvid',
    # TP-Link port config (duplex/speed/etc)
    'i_duplex_admin' => 'TPLINK-PORTCONFIG-MIB::tpPortConfigDuplex',
    'i_speed_admin'  => 'TPLINK-PORTCONFIG-MIB::tpPortConfigSpeed',
    'tp_port_config_descr' => 'TPLINK-PORTCONFIG-MIB::tpPortConfigDescription',
    # TP-Link LLDP tables (map to SNMP::Info::LLDP expected names)
    'lldp_lport_id'   => 'TPLINK-LLDPINFO-MIB::lldpLocalPortId',
    'lldp_lport_desc' => 'TPLINK-LLDPINFO-MIB::lldpLocalPortDescr',
    'lldp_lman_addr'  => 'TPLINK-LLDPINFO-MIB::lldpLocalManageIpAddr',
    'lldp_rem_id_type'  => 'TPLINK-LLDPINFO-MIB::lldpNeighborChassisIdType',
    'lldp_rem_id'       => 'TPLINK-LLDPINFO-MIB::lldpNeighborChassisId',
    'lldp_rem_pid_type' => 'TPLINK-LLDPINFO-MIB::lldpNeighborPortIdType',
    'lldp_rem_pid'      => 'TPLINK-LLDPINFO-MIB::lldpNeighborPortId',
    'lldp_rem_desc'     => 'TPLINK-LLDPINFO-MIB::lldpNeighborPortDescr',
    'lldp_rem_sysname'  => 'TPLINK-LLDPINFO-MIB::lldpNeighborDeviceName',
    'lldp_rem_sysdesc'  => 'TPLINK-LLDPINFO-MIB::lldpNeighborDeviceDescr',
    'lldp_rem_sys_cap'  => 'TPLINK-LLDPINFO-MIB::lldpNeighborCapEnabled',
    'lldp_rem_cap_spt'  => 'TPLINK-LLDPINFO-MIB::lldpNeighborCapAvailable',
    'lldpLocalOperMau' => 'TPLINK-LLDPINFO-MIB::lldpLocalOperMau',
    # Raw TP-Link neighbor manage addr table (internal accessor)
    'tplink_lldp_rman'    => 'TPLINK-LLDPINFO-MIB::lldpNeighborManageIpAddr',
    # TP-Link dynamic MAC forwarding table
    'tpl2BridgeManageDynMac'  => 'TPLINK-L2BRIDGE-MIB::tpl2BridgeManageDynMac',
    'tpl2BridgeManageDynVlanId' => 'TPLINK-L2BRIDGE-MIB::tpl2BridgeManageDynVlanId',
    'tpl2BridgeManageDynPort' => 'TPLINK-L2BRIDGE-MIB::tpl2BridgeManageDynPort',
    # Map TP-Link STP per-port table fields into the Bridge expected names
    'stp_i_root'       => 'TPLINK-SPANNING-TREE-MIB::tpStpCISTRoot',
    'stp_i_time'       => 'TPLINK-SPANNING-TREE-MIB::tpStpLastTopologyChangeTime',
    'stp_i_root_port'  => 'TPLINK-SPANNING-TREE-MIB::tpStpRootPort',
    'stp_i_priority'   => 'TPLINK-SPANNING-TREE-MIB::tpStpCistPriority',
    # Per-port STP mapped keys (index by ifIndex)
    'stp_p_id'       => 'TPLINK-SPANNING-TREE-MIB::tpStpPortNumber',
    'stp_p_priority' => 'TPLINK-SPANNING-TREE-MIB::tpStpPortPriority',
    'stp_p_state'    => 'TPLINK-SPANNING-TREE-MIB::tpStpPortStatus',
    'stp_p_cost'     => 'TPLINK-SPANNING-TREE-MIB::tpStpPortInPathCost',
    'stp_p_role'     => 'TPLINK-SPANNING-TREE-MIB::tpStpPortRole',
    'is_edgeport_admin' => 'TPLINK-SPANNING-TREE-MIB::tpStpEdgePortStatus',
    'is_edgeport_oper'  => 'TPLINK-SPANNING-TREE-MIB::tpStpEdgePortStatus',
);

%MUNGE = (
    %SNMP::Info::Layer2::MUNGE,
    %SNMP::Info::EtherLike::MUNGE,
);

sub vendor {
    return 'TP-Link';
}

sub os {
    return 'tplink';
}

sub model {
    my $tp = shift;

    # Prefer TP-Link's own sysinfo MIB (TPLINK-SYSINFO-MIB)
    # Use textual description (tpSysInfoDescription) first which typically
    # contains product name and version.  If available, prefer a cleaned
    # combination of description and hardware version.
    my $tp_descr = $tp->tp_sysinfo_descr();
    my $tp_hw    = $tp->tp_sysinfo_hwver();
    if ( defined $tp_descr and $tp_descr !~ /^\s*$/ ) {
        my $model = $tp_descr;
        $model =~ s/\s+$//;
        # Append hardware version if present and not duplicate
        if ( defined $tp_hw and $tp_hw !~ /^\s*$/ and $model !~ /\Q$tp_hw\E/ ) {
            $model = "$tp_hw";
        }
        return $model;
    }

    # Fallback: prefer ENTITY-MIB model information when available
    my $e_model = $tp->e_model() || {};
    foreach my $iid ( sort keys %$e_model ) {
        my $m = $e_model->{$iid};
        return $m if defined $m and $m !~ /^\s*$/;
    }

    # Last resort: use sysDescr
    my $descr = $tp->description() || '';
    $descr =~ s/\s+$//;
    return $descr if $descr ne '';

    return;
}

sub os_ver {
    my $tp = shift;

    # Prefer TP-Link specific SW version
    my $sw = $tp->tp_sysinfo_swver();
    return $sw if defined $sw and $sw ne '';

    # Fallback to ENTITY-MIB derived OS/version
    my $e_ver = $tp->entity_derived_os_ver();
    return $e_ver if defined $e_ver and $e_ver ne '';

    # Last resort, take from sysDescr
    my $desc = $tp->description() || '';
    if ( $desc =~ /([\d]+(?:\.[\d]+)+)/ ) {
        return $1;
    }
    return;
}

sub serial {
    my $tp = shift;


    # Prefer TP-Link sometimes provides MAC as primary identifier; use as fallback
    my $mac = $tp->tp_sysinfo_mac();
    if ( defined $mac and $mac ne '' ) {
        $mac =~ s/:|-//g;
        $mac = uc $mac;
        return $mac;
    }

    # Fallback to Entity MIB derived serial
    my $eserial = $tp->entity_derived_serial();
    return $eserial if defined $eserial and $eserial ne '';

    return;
}

sub mac {
    my $tp = shift;

    # Prefer TP-Link MAC from sysinfo MIB
    my $mac = $tp->tp_sysinfo_mac();
    if ( defined $mac and $mac ne '' ) {
        $mac =~ s/-/:/g;
        $mac = uc $mac;
        return $mac;
    }

    # Fallback to primary MAC from EtherLike MIB
    return $tp->el_mac();
}

sub i_name {
    my $tp = shift;

    # Prefer TP-Link port description from port config MIB
    my $pc_desc = $tp->tp_port_config_descr() || {};
    my $ifdescr = $tp->SUPER::i_description() || {};
    my %out;
    foreach my $key ( keys %$ifdescr ) {
        if (defined $pc_desc->{$key} and $pc_desc->{$key} ne '') {
            $out{$key} = $pc_desc->{$key};
        } else {
            $out{$key} = $ifdescr->{$key};
        }
    }

    return \%out;
}

sub i_duplex {
    my $tp = shift;

    # Prefer TP-Link admin duplex setting if available
    my $mau = $tp->lldpLocalOperMau() || {};
    my %out;
    foreach my $key ( keys %$mau ) {
        if ( defined $mau->{$key} and $mau->{$key} =~ /speed\(\S+\)\/duplex\((full|half)\)/i ) {
            $out{$key} = $1;
        } else {
            $out{$key} = 'unknown';
        }
    }

    return \%out;
}
# VLAN methods. 
sub i_vlan_membership_untagged {
    my $tp  = shift;
    my $partial = shift;
    my $vlan_members_untagged = {};

    my $ports = $tp->tp_i_vlan_membership_untagged($partial);

    foreach my $key (keys %$ports) {
        push @{$vlan_members_untagged->{$key}}, $ports->{$key};
    }
    return $vlan_members_untagged;
}

# TP-Link devices do not implement these proprietary neighbor discovery
# protocols.  Provide explicit overrides to avoid mistaken detection
# and to keep has_topo() clean for TP-Link devices.
sub hasLLDP { return 1; }
sub hasCDP { return; }
sub hasFDP { return; }
sub hasSONMP { return; }
sub hasEDP { return; }
sub hasAMAP { return; }

# Transform TP-Link neighbor management address table into the
# lldpRemManAddrTable-style index expected by SNMP::Info::LLDP.
sub lldp_rman_addr {
    my $tp      = shift;
    my $partial = shift;

    # Get the raw TP-Link neighbor manage IP table (indexed by ifIndex,neighborId)
    my $raw = $tp->tplink_lldp_rman($partial) || {};
    my %out;

    # To ensure keys line up with other LLDP tables (e.g. lldpRemPortId),
    # find the corresponding remote-entry key from the standard LLDP accessors
    # and append protocol/length/octets to that key.
    my $pid_map = $tp->lldp_rem_pid($partial) || {};
    my @pid_keys = keys %$pid_map;

    foreach my $key ( keys %$raw ) {
        my $addr = $raw->{$key};
        next unless defined $addr and $addr ne '';

        # Split raw key into numeric components (e.g. ifIndex.remIndex[.sub])
        my @raw_parts = split /\./, $key;

        # Determine protocol and octets
        my $proto;
        my @octets;
        if ( $addr =~ /:/ ) {
            # IPv6
            $proto = 2;
            eval {
                require Socket;
                my $packed = eval { Socket::inet_pton( Socket::AF_INET6(), $addr ) };
                if ( defined $packed ) {
                    @octets = unpack( 'C*', $packed );
                }
            };
            next unless @octets;
        }
        else {
            # IPv4
            $proto  = 1;
            @octets = split( /\./, $addr );
            next unless @octets == 4;
        }

        my $len = scalar @octets;

        # Try several strategies to find a matching pid_key so the compound
        # index we produce lines up with other LLDP tables (lldpRemPortId etc.).
        my $matched_pid_key;
        PID_KEY: foreach my $pkey (@pid_keys) {
            my @p_parts = split /\./, $pkey;

            # 1) Exact suffix match: pid key ends with the raw key components
            for my $n ( reverse 1 .. scalar @raw_parts ) {
                my $raw_suffix = join('.', @raw_parts[0..$n-1]);
                my $p_suffix = join('.', @p_parts[-$n..-1]);
                if ( defined $p_suffix && $p_suffix eq $raw_suffix ) {
                    $matched_pid_key = $pkey;
                    last PID_KEY;
                }
            }

            # 2) Match local port number: many LLDP pid keys have local port
            # as the second component (timeMark.localPort.remIndex). If the
            # raw key's first component equals that localPort, accept it.
            if ( defined $p_parts[1] && defined $raw_parts[0] && $p_parts[1] eq $raw_parts[0] ) {
                $matched_pid_key = $pkey;
                last PID_KEY;
            }
        }

        # If not found, fall back to using the raw key as prefix so callers
        # may still find the entry if they index with raw-style keys.
        my $base_key = $matched_pid_key || join( '.', @raw_parts );

        # Ensure base_key has at least 3 components so _lldp_addr_index in
        # SNMP::Info::LLDP parses proto/length/octets correctly. Some
        # TP-Link devices use two-component indexes (localPort.remIndex).
        # Prepend a zero timeMark to make it a 3-component index.
        my @bk_parts = split( /\./, $base_key );
        while ( scalar @bk_parts < 3 ) {
            unshift @bk_parts, 0;
        }
        $base_key = join( '.', @bk_parts );

        my $newkey = join( '.', $base_key, $proto, $len, @octets );
        $out{$newkey} = $addr;

        # Also provide a fallback without trying to align to pid keys in case
        # some consumers index differently (helps compatibility).
        my $raw_fallback = join( '.', @raw_parts, $proto, $len, @octets );
        $out{$raw_fallback} = $addr;

        # Debug logging removed — provider now exposes vendor values without
        # emitting runtime warnings. Enable external debugging when needed
        # by instrumenting the test harness rather than the provider.
    }

    return \%out;
}

# TP-Link specific override to map LLDP remote pid entries to local ifIndex.
# TP-Link uses short port id strings like "1/0/25" in lldpNeighborPortId,
# while `interfaces()` contains values like "gigabitEthernet 1/0/25".
# Match by substring to produce the pid -> local ifIndex mapping expected
# by SNMP::Info::LLDP::lldp_if().
sub lldp_if {
    my $tp      = shift;
    my $partial = shift;

    my $pid_map    = $tp->lldp_rem_pid($partial) || {};
    my $interfaces = $tp->interfaces()    || {};

    my %lldp_if;
    foreach my $key ( keys %$pid_map ) {
        my $pval = $pid_map->{$key};
        next unless defined $pval and $pval ne '';

        # Try to find an ifIndex whose ifDescr contains the pid string
        my $found;
        foreach my $iid ( keys %$interfaces ) {
            my $descr = $interfaces->{$iid} || '';
            if ( $descr =~ /\Q$pval\E/ ) {
                $found = $iid;
                last;
            }
        }

        # If not found, fall back to existing generic behavior: try
        # cross-referencing via lldpLocalPortDescr (if available).
        if ( !defined $found ) {
            my $lport_desc = $tp->lldp_lport_desc() || {};
            # lldpLocalPortDescr keys are often simple indices; try to find
            # a local port whose description contains the pid string and map
            # it back to an ifIndex by matching description -> ifIndex.
            foreach my $iid ( keys %$interfaces ) {
                my $descr = $interfaces->{$iid} || '';
                if ( $descr && exists $lport_desc->{$iid} && $lport_desc->{$iid} =~ /\Q$pval\E/ ) {
                    $found = $iid;
                    last;
                }
            }
        }

        if ( defined $found ) {
            # Expose both the raw key and the 3-component index form so
            # callers using either format can find the mapping.
            $lldp_if{$key}       = $found unless exists $lldp_if{$key};
            $lldp_if{"0.$key"} = $found unless exists $lldp_if{"0.$key"};
        }
    }

    return \%lldp_if;
}

# Provide a TP-Link specific lldp_ip mapping directly from the vendor
# lldpNeighborManageIpAddr table.  Some TP-Link implementations return
# this column as OCTET/STRING which can confuse generic parsers; expose
# the usable IPv4 addresses directly keyed by the same pid keys Netdisco
# expects (both raw and 3-component forms).
sub lldp_ip {
    my $tp      = shift;
    my $partial = shift;

    # Expose the vendor-provided manage IP values as-is. Do not synthesize
    # or validate values here; callers (Netdisco) expect the provider to
    # reflect what the device reports.
    my $raw = $tp->tplink_lldp_rman($partial) || {};
    my %ips;
    foreach my $key ( keys %$raw ) {
        my $addr = $raw->{$key};
        next unless defined $addr and $addr ne '';
        $ips{$key} = $addr;
        $ips{"0.$key"} = $addr;
    }
    return \%ips;
}

# (No synthetic fallback functions - provider exposes vendor values as-is.)

# Provide a TP-Link specific lldp_port mapping using the vendor
# lldpNeighborPortId/Descr fields so remote port strings are exposed
# keyed the same way as lldp_ip above.
sub lldp_port {
    my $tp      = shift;
    my $partial = shift;

    my $pid   = $tp->lldp_rem_pid($partial)      || {};
    my $pdesc = $tp->lldp_rem_desc($partial)     || {};
    my %ports;

    foreach my $key ( keys %$pid ) {
        my $port = $pdesc->{$key} || $pid->{$key} || '';
        next unless $port;
        $ports{$key} = $port;
        $ports{"0.$key"} = $port;
    }
    return \%ports;
}

# Build Q-BRIDGE style forwarding table (dot1qTpFdbPort) from
# TP-Link's tpl2BridgeManageDynAddrCtrlTable when the standard
# Q-BRIDGE entries are not available. Keys are returned in the
# form: "<vlan>.<mac-octet-1>.<mac-octet-2>..." which mirrors
# dot1qTpFdbEntry indexing so SNMP::Info::Bridge helpers can
# parse MAC and VLAN from the index.
sub qb_fw_port {
    my $tp      = shift;
    my $partial = shift;

    # Prefer existing Q-BRIDGE data if present
    my $super = $tp->SUPER::qb_fw_port($partial) || {};
    return $super if (ref {} eq ref $super and scalar keys %$super);

    # Vendor dynamic MAC table
    my $dyn_port = $tp->tpl2BridgeManageDynPort($partial) || {};
    my %out;

    # interfaces mapping for port string -> ifIndex resolution
    my $interfaces = $tp->interfaces() || {};

    foreach my $key ( keys %$dyn_port ) {
        my $pval = $dyn_port->{$key};
        next unless defined $pval and $pval ne '';

        # Index in the MIB is: tpl2BridgeManageDynMac . tpl2BridgeManageDynVlanId
        my @parts = split /\./, $key;
        next unless @parts >= 2;
        my $vlan = pop @parts;    # last component is VLAN id
        my @mac_octets = @parts; # remaining are MAC octets (decimal)

        # Build qb-style index: vlan.<mac-octets>
        my $qb_idx = join('.', $vlan, @mac_octets);

        # Resolve vendor port value to an ifIndex when possible.
        my $ifindex;
        my $bp_index = $tp->bp_index() || {};

        # Normalize port value and try several resolution strategies in order
        # 1) If the value contains a textual port like '1/0/28', extract the
        #    trailing numeric and try to match interface descriptions (fast).
        # 2) If the value is numeric (e.g. '28'), try to match '/28' in
        #    interface descriptions (handles many TP-Link formats).
        # 3) Try direct bp_index lookup if the vendor returns bridge-port
        #    numeric identifiers (rare on some firmwares).
        my $portnum;
        if ( $pval =~ /(?:\D|^)(\d+)\$/ ) {
            $portnum = $1;
        }

        if ( defined $portnum ) {
            # Prefer matching by interface description containing '/<portnum>' or ' <portnum>' patterns
            foreach my $iid ( keys %$interfaces ) {
                my $descr = $interfaces->{$iid} || '';
                if ( $descr =~ /\/$portnum(?:\b|\s|:)/ || $descr =~ /\b$portnum(?:\b|\s|:)/ ) {
                    $ifindex = $iid;
                    last;
                }
            }
        }

        # If not found yet and pval is purely numeric, try bp_index mapping
        if ( !defined $ifindex && $pval =~ /^\d+$/ ) {
            if ( exists $bp_index->{$pval} ) {
                $ifindex = $bp_index->{$pval};
            }
        }

        # Final fallback: if pval is textual (eg '1/0/28'), try substring match
        if ( !defined $ifindex ) {
            foreach my $iid ( keys %$interfaces ) {
                my $descr = $interfaces->{$iid} || '';
                if ( $descr =~ /\Q$pval\E/ ) {
                    $ifindex = $iid;
                    last;
                }
            }
        }

        # If we couldn't resolve to an ifIndex, still expose the raw port
        # string so callers can inspect it; Netdisco will prefer numeric
        # ifIndex values but having the raw value is useful for diagnostics.
        $out{$qb_idx} = defined $ifindex ? $ifindex : $pval;
    }

    return \%out;
}

# Override fw_port to ensure values are actual ifIndex where possible.
# Some TP-Link devices return small bridge-port numbers (e.g. '28') which
# Netdisco then looks up via bp_index(). On these devices bp_index() itself
# uses high ifIndex-like keys, so we prefer resolving port identifiers to
# the real ifIndex by matching interface descriptions or consulting
# vendor tables. This keeps macsuck from skipping MACs with "no bp_index".
sub fw_port {
    my $tp      = shift;
    my $partial = shift;

    # Get standard BRIDGE-MIB fw_port (dot1dTpFdbPort) from superclass
    my $fw = $tp->SUPER::fw_port($partial) || {};

    # If Q-BRIDGE data is available and BRIDGE empty, prefer that
    unless ( keys %$fw ) {
        my $qb = $tp->qb_fw_port($partial) || {};
        $fw = $qb if keys %$qb;
    }

    my $interfaces = $tp->interfaces() || {};
    my $bp_index   = $tp->bp_index()    || {};

    my %out;
    foreach my $idx ( keys %$fw ) {
        my $portval = $fw->{$idx};
        next unless defined $portval and $portval ne '';

        my $ifindex;

        # If the port value looks like a numeric ID (bridge-port or ifIndex)
        if ( $portval =~ /^\d+$/ ) {
            # If it's already an ifIndex, accept it
            if ( exists $interfaces->{$portval} ) {
                $ifindex = $portval;
            }
            else {
                # Try to find an interface whose description contains this
                # numeric port (e.g. '/28' or ' 28'). This handles '1/0/28'
                foreach my $iid ( keys %$interfaces ) {
                    my $descr = $interfaces->{$iid} || '';
                    if ( $descr =~ /\/$portval(?:\b|\s|:)/ || $descr =~ /\b$portval(?:\b|\s|:)/ ) {
                        $ifindex = $iid;
                        last;
                    }
                }
            }

            # If still not found, check if bp_index maps this bridge-port
            if ( !defined $ifindex && exists $bp_index->{$portval} ) {
                $ifindex = $bp_index->{$portval};
            }
        }
        else {
            # Textual port (like '1/0/28' or 'GigabitEthernet1/0/28')
            # Try exact substring match against interface descriptions
            foreach my $iid ( keys %$interfaces ) {
                my $descr = $interfaces->{$iid} || '';
                if ( $descr =~ /\Q$portval\E/ ) {
                    $ifindex = $iid;
                    last;
                }
            }
        }

        # Final fallback: keep original value so callers can inspect it
        $out{$idx} = defined $ifindex ? $ifindex : $portval;
    }

    return \%out;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::TPLink - SNMP Interface to TP-Link Layer2 devices

=head1 SYNOPSIS

 my $tp = new SNMP::Info(
                      AutoSpecify => 1,
                      Debug       => 1,
                      DestHost    => 'tplink-switch',
                      Community   => 'public',
                      Version     => 2
                    )
    or die "Can't connect to DestHost.\n";

=head1 DESCRIPTION

Subclass for TP-Link Layer2 devices. Inherits from L<SNMP::Info::Layer2>
and exposes TP-Link specific globals when available.

=head1 AUTHOR

Netdisco Developer Team

=cut
