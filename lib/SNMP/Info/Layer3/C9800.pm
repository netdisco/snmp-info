# SNMP::Info::Layer3::C9800
#
# Copyright (c) 2026 The SNMP::Info Developers
# All rights reserved.

package SNMP::Info::Layer3::C9800;

use strict;
use warnings;
use Exporter;
use SNMP::Info::CiscoStats;
use SNMP::Info::CiscoVTP;
use SNMP::Info::Entity;
use SNMP::Info::EtherLike;
use SNMP::Info::LLDP;
use SNMP::Info::Layer2::Airespace;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

@SNMP::Info::Layer3::C9800::ISA = qw/
    SNMP::Info::Layer2::Airespace
    SNMP::Info::CiscoVTP
    SNMP::Info::CiscoStats
    SNMP::Info::LLDP
    SNMP::Info::EtherLike
    Exporter
/;

@SNMP::Info::Layer3::C9800::EXPORT_OK = qw//;

$VERSION = '3.984000';

%MIBS = (
    %SNMP::Info::Layer2::Airespace::MIBS,
    %SNMP::Info::CiscoVTP::MIBS,
    %SNMP::Info::CiscoStats::MIBS,
    %SNMP::Info::LLDP::MIBS,
    %SNMP::Info::EtherLike::MIBS,
    %SNMP::Info::Entity::MIBS,
    'CISCO-LWAPP-CDP-MIB' => 'clcCdpApCacheNeighInterface',
);

%GLOBALS = (
    %SNMP::Info::Layer2::Airespace::GLOBALS,
    %SNMP::Info::CiscoVTP::GLOBALS,
    %SNMP::Info::CiscoStats::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,
    %SNMP::Info::EtherLike::GLOBALS,
    'c9800_os_ver' => '.1.3.6.1.2.1.16.19.2.0',
    'serial1' =>
        '.1.3.6.1.4.1.9.3.6.3.0',    # OLD-CISCO-CHASSIS-MIB::chassisId.0
);

# CiscoVTP after Layer2::Airespace: v_name is vtpVlanName, the controller's
# VLANs, not Q-BRIDGE dot1qVlanStaticName, which the 9800 leaves empty
%FUNCS = (
    %SNMP::Info::Layer2::Airespace::FUNCS,
    %SNMP::Info::CiscoVTP::FUNCS,
    %SNMP::Info::CiscoStats::FUNCS,
    %SNMP::Info::LLDP::FUNCS,
    %SNMP::Info::EtherLike::FUNCS,
    # CISCO-LWAPP-AP-MIB::cLApRadioWlanInfoTable
    'c9800_radio_wlan_ssid'  => 'cLApRadioWlanSsid',
    'c9800_radio_wlan_bssid' => 'cLApRadioWlanBssid',
    'c9800_entity_descr'  => 'entPhysicalDescr',
    'c9800_entity_class'  => 'entPhysicalClass',
    'c9800_entity_name'   => 'entPhysicalName',
    'c9800_entity_model'  => 'entPhysicalModelName',
    'c9800_entity_type'   => 'entPhysicalVendorType',
    'c9800_entity_fwver'  => 'entPhysicalFirmwareRev',
    'c9800_entity_vendor' => 'entPhysicalMfgName',
    'c9800_entity_serial' => 'entPhysicalSerialNum',
    'c9800_entity_pos'    => 'entPhysicalParentRelPos',
    'c9800_entity_swver'  => 'entPhysicalSoftwareRev',
    'c9800_entity_parent' => 'entPhysicalContainedIn',
    'c9800_cdp_name'      => 'clcCdpApCacheNeighName',
    'c9800_cdp_address'   => 'clcCdpApCacheNeighAddress',
    'c9800_cdp_interface' => 'clcCdpApCacheNeighInterface',
    'c9800_ap_vlan'       => 'bsnAPGroupVlanName',
    'c9800_ap_ios_ver'    => 'bsnAPIOSVersion',
    'c9800_ap_oper'       => 'bsnAPOperationStatus',
    'c9800_ap_primary'    => 'bsnAPPrimaryMwarName',
    'c9800_ap_secondary'  => 'bsnAPSecondaryMwarName',
    # CISCO-LWAPP-AP-MIB::cLApTable
    'c9800_ap_site_tag'   => 'cLApSiteTagName',
    'c9800_ap_rf_tag'     => 'cLApRfTagName',
    'c9800_ap_policy_tag' => 'cLApPolicyTagName',
    'c9800_ap_tag_source' => 'cLApTagSource',
);

%MUNGE = (
    %SNMP::Info::Layer2::Airespace::MUNGE,
    %SNMP::Info::CiscoVTP::MUNGE,
    %SNMP::Info::CiscoStats::MUNGE,
    %SNMP::Info::LLDP::MUNGE,
    %SNMP::Info::EtherLike::MUNGE,
    'c9800_radio_wlan_bssid' => \&SNMP::Info::munge_mac,
    'c9800_cdp_address' => \&SNMP::Info::munge_ip,
    'c9800_entity_type' => \&SNMP::Info::munge_e_type,
);

sub serial {
    my $c9800 = shift;
    my $descr   = $c9800->c9800_entity_descr()  || {};
    my $serials = $c9800->c9800_entity_serial() || {};

    my @chassis_serials = map { $serials->{$_} }
        grep {
               defined $descr->{$_}
            && $descr->{$_} =~ /chassis/i
            && defined $serials->{$_}
            && $serials->{$_} ne ''
        } sort { $a <=> $b } keys %{$descr};

    return unless @chassis_serials;
    return join ' ', @chassis_serials;
}

sub os_ver {
    my $c9800 = shift;
    my $os_ver = $c9800->c9800_os_ver();
    return $os_ver if defined $os_ver && $os_ver ne '';

    return SNMP::Info::CiscoStats::os_ver($c9800);
}

sub os {
    my $c9800 = shift;
    return SNMP::Info::CiscoStats::os($c9800);
}

# FlexConnect clients sit on VLANs the controller never defines, so the
# controller's VTP table misses them. Take those names from the client table,
# but never replace a name someone gave the VLAN: only a gap, or the default
# a switch invents ("VLAN0415").
sub v_name {
    my $c9800   = shift;
    my $partial = shift;

    my $v_name  = { %{ $c9800->SUPER::v_name($partial) || {} } };
    my $names   = $c9800->airespace_vlan_names() || {};
    my %key_for = map { ( ( split /\./ )[-1] => $_ ) } keys %$v_name;

    foreach my $vlan ( keys %$names ) {
        my $key = $key_for{$vlan} // $vlan;
        next if defined $partial and $partial ne $key;

        my $have = $v_name->{$key};
        next
            if defined $have
            and length $have
            and $have !~ /^VLAN\s?0*\Q$vlan\E$/i;

        $v_name->{$key} = $names->{$vlan};
    }

    return $v_name;
}

# VTP keys are domain.vlan, client-only VLANs are the bare VLAN ID
sub v_index {
    my $c9800   = shift;
    my $partial = shift;

    my $v_name  = $c9800->v_name($partial) || {};
    my %v_index = map { ( $_ => ( split /\./ )[-1] ) } keys %$v_name;
    return \%v_index;
}

sub i_vlan {
    my $c9800   = shift;
    my $partial = shift;

    return {
        %{ $c9800->SUPER::i_vlan($partial) || {} },
        %{ SNMP::Info::CiscoVTP::i_vlan( $c9800, $partial ) || {} },
    };
}

sub i_vlan_membership {
    my $c9800   = shift;
    my $partial = shift;

    return {
        %{ $c9800->SUPER::i_vlan_membership($partial) || {} },
        %{  SNMP::Info::CiscoVTP::i_vlan_membership( $c9800, $partial ) || {}
        },
    };
}

sub i_vlan_membership_untagged {
    my $c9800   = shift;
    my $partial = shift;

    return {
        %{ $c9800->SUPER::i_vlan_membership_untagged($partial) || {} },
        %{  SNMP::Info::CiscoVTP::i_vlan_membership_untagged( $c9800,
                $partial )
                || {}
        },
    };
}

# Bridge, reached through Layer2::Airespace, comes before CiscoVTP in method
# resolution, so these would otherwise use Q-BRIDGE-MIB, which the 9800 lacks
sub i_untagged {
    my $c9800 = shift;
    return SNMP::Info::CiscoVTP::i_untagged( $c9800, @_ );
}

sub set_i_pvid {
    my $c9800 = shift;
    return SNMP::Info::CiscoVTP::set_i_pvid( $c9800, @_ );
}

sub set_i_vlan {
    my $c9800 = shift;
    return SNMP::Info::CiscoVTP::set_i_vlan( $c9800, @_ );
}

sub set_i_untagged {
    my $c9800 = shift;
    return SNMP::Info::CiscoVTP::set_i_untagged( $c9800, @_ );
}

sub set_add_i_vlan_tagged {
    my $c9800 = shift;
    return SNMP::Info::CiscoVTP::set_add_i_vlan_tagged( $c9800, @_ );
}

sub set_remove_i_vlan_tagged {
    my $c9800 = shift;
    return SNMP::Info::CiscoVTP::set_remove_i_vlan_tagged( $c9800, @_ );
}

sub _validate_vlan_param {
    my $c9800 = shift;
    return SNMP::Info::CiscoVTP::_validate_vlan_param( $c9800, @_ );
}

sub i_duplex {
    my $c9800   = shift;
    my $partial = shift;

    my %i_duplex  = %{ $c9800->SUPER::i_duplex($partial) || {} };
    my $el_index  = $c9800->el_index($partial)  || {};
    my $el_duplex = $c9800->el_duplex($partial) || {};

    foreach my $el_port ( keys %$el_duplex ) {
        my $iid    = $el_index->{$el_port};
        my $duplex = $el_duplex->{$el_port};
        next unless defined $iid and defined $duplex;
        next unless $duplex =~ /^(half|full)$/;

        $i_duplex{$iid} = $duplex;
    }

    return \%i_duplex;
}

# The 9800 leaves bsnDot11EssSsid empty; the radio WLAN table is keyed
# like the AP radio ports with the WLAN index appended
sub i_ssidlist {
    my $c9800   = shift;
    my $partial = shift;

    my $ssids      = $c9800->c9800_radio_wlan_ssid($partial) || {};
    my %i_ssidlist = map { ( $_ => $ssids->{$_} ) }
        grep { defined $ssids->{$_} and length $ssids->{$_} } keys %$ssids;
    return \%i_ssidlist;
}

sub i_ssidmac {
    my $c9800   = shift;
    my $partial = shift;

    return $c9800->c9800_radio_wlan_bssid($partial) || {};
}

sub i_ssidbcast {
    my $c9800   = shift;
    my $partial = shift;

    my $ssidlist  = $c9800->i_ssidlist($partial)  || {};
    my $ess_bcast = $c9800->airespace_ess_bcast() || {};
    my %bcmap     = qw/enable 1 disable 0/;

    my %i_ssidbcast;
    foreach my $iid ( keys %$ssidlist ) {

        # assumes bsnDot11EssIndex equals cLWlanIndex, as on 17.12 and 17.18
        my $wlan = ( split /\./, $iid )[-1];
        my $bc   = $ess_bcast->{$wlan};
        next unless defined $bc and exists $bcmap{$bc};

        $i_ssidbcast{$iid} = $bcmap{$bc};
    }
    return \%i_ssidbcast;
}

sub interfaces {
    my $c9800   = shift;
    my $partial = shift;

    my $interfaces   = $c9800->SUPER::interfaces($partial)  || {};
    my $indexes      = $c9800->i_index($partial)            || {};
    my $descriptions = $c9800->orig_i_description($partial) || {};

    foreach my $iid (keys %{$indexes}) {
        next unless defined $indexes->{$iid} && $indexes->{$iid} =~ /^\d+$/;
        next unless defined $descriptions->{$iid} && $descriptions->{$iid} ne '';

        $interfaces->{$iid} = $descriptions->{$iid};
    }

    return $interfaces;
}

sub _cdp_connections {
    my $c9800     = shift;
    my $names        = $c9800->c9800_cdp_name()               || {};
    my $addresses    = $c9800->c9800_cdp_address()            || {};
    my $interfaces   = $c9800->c9800_cdp_interface()          || {};

    my %neighbors;
    foreach my $cdp_iid ( sort keys %{$names} ) {
        my $ap_iid = $cdp_iid;
        next unless $ap_iid =~ s/\.\d+$//;

        my @parts = grep { defined && $_ ne '' }
            ($names->{$cdp_iid}, $interfaces->{$cdp_iid});
        push @parts, '(' . $addresses->{$cdp_iid} . ')'
            if defined $addresses->{$cdp_iid}
            && $addresses->{$cdp_iid} ne '';
        next unless @parts;

        push @{$neighbors{$ap_iid}}, join ' ', @parts;
    }

    my %connections;
    foreach my $ap_iid (keys %neighbors) {
        my %seen;
        $connections{$ap_iid} = join ', ',
            grep { !$seen{$_}++ } @{$neighbors{$ap_iid}};
    }
    return \%connections;
}

sub _ap_detail_strings {
    my $c9800 = shift;
    my $ips         = $c9800->airespace_ap_ip()  || {};
    my $dot3_macs   = $c9800->airespace_ap_mac() || {};
    my $ether_macs  = $c9800->airespace_ap_ethermac() || {};
    my $connections = $c9800->_cdp_connections();

    my %details;
    foreach my $iid (
        keys %{$ips}, keys %{$dot3_macs}, keys %{$ether_macs},
        keys %{$connections}
        ) {
        my @parts;
        push @parts, "IP $ips->{$iid}" if $ips->{$iid};
        push @parts, "Dot3 MAC $dot3_macs->{$iid}" if $dot3_macs->{$iid};
        push @parts, "Ethernet MAC $ether_macs->{$iid}"
            if $ether_macs->{$iid};
        push @parts, "Connected via $connections->{$iid}"
            if $connections->{$iid};
        $details{$iid} = join '; ', @parts if @parts;
    }
    return \%details;
}

# Tags are an AP-level setting, so they only go on the AP module and not on
# every radio port of that AP.
sub _ap_tag_strings {
    my $c9800 = shift;
    my $policy = $c9800->c9800_ap_policy_tag() || {};
    my $site   = $c9800->c9800_ap_site_tag()   || {};
    my $rf     = $c9800->c9800_ap_rf_tag()     || {};

    my %tags;
    foreach my $iid (keys %{$policy}, keys %{$site}, keys %{$rf}) {
        my @parts;
        push @parts, "Policy tag $policy->{$iid}" if $policy->{$iid};
        push @parts, "Site tag $site->{$iid}"     if $site->{$iid};
        push @parts, "RF tag $rf->{$iid}"         if $rf->{$iid};
        $tags{$iid} = join '; ', @parts if @parts;
    }
    return \%tags;
}

sub _debug_ap_details {
    my $c9800 = shift;
    return unless $c9800->debug();
    return if $c9800->{_c9800_ap_details_logged}++;

    my $names      = $c9800->airespace_ap_name()      || {};
    my $ips        = $c9800->airespace_ap_ip()        || {};
    my $serials    = $c9800->airespace_ap_serial()    || {};
    my $models     = $c9800->airespace_ap_model()     || {};
    my $vlans      = $c9800->c9800_ap_vlan()          || {};
    my $versions   = $c9800->c9800_ap_ios_ver()       || {};
    my $dot3_macs  = $c9800->airespace_ap_mac()       || {};
    my $ether_macs = $c9800->airespace_ap_ethermac()  || {};
    my $locations  = $c9800->airespace_ap_loc()       || {};
    my $admin      = $c9800->airespace_ap_status()    || {};
    my $oper       = $c9800->c9800_ap_oper()          || {};
    my $primary    = $c9800->c9800_ap_primary()       || {};
    my $secondary  = $c9800->c9800_ap_secondary()     || {};
    my $policy_tag = $c9800->c9800_ap_policy_tag()    || {};
    my $site_tag   = $c9800->c9800_ap_site_tag()      || {};
    my $rf_tag     = $c9800->c9800_ap_rf_tag()        || {};
    my $tag_source = $c9800->c9800_ap_tag_source()    || {};

    foreach my $iid (sort keys %{$names}) {
        my @values = (
            "name="      . ($names->{$iid}      // ''),
            "ip="        . ($ips->{$iid}        // ''),
            "serial="    . ($serials->{$iid}    // ''),
            "model="     . ($models->{$iid}     // ''),
            "vlan="      . ($vlans->{$iid}      // ''),
            "version="   . ($versions->{$iid}   // ''),
            "dot3_mac="  . ($dot3_macs->{$iid}  // ''),
            "ether_mac=" . ($ether_macs->{$iid} // ''),
            "location="  . ($locations->{$iid}  // ''),
            "admin="     . ($admin->{$iid}      // ''),
            "oper="      . ($oper->{$iid}       // ''),
            "primary="   . ($primary->{$iid}    // ''),
            "secondary=" . ($secondary->{$iid}  // ''),
            "policy_tag=" . ($policy_tag->{$iid} // ''),
            "site_tag="   . ($site_tag->{$iid}   // ''),
            "rf_tag="     . ($rf_tag->{$iid}     // ''),
            "tag_source=" . ($tag_source->{$iid} // ''),
        );
        print " SNMP::Info::Layer3::C9800 AP $iid "
            . join(' ', @values) . "\n";
    }
}

sub i_description {
    my $c9800  = shift;
    my $partial = shift;

    my $descriptions = $c9800->SUPER::i_description($partial) || {};
    my $indexes      = $c9800->i_index($partial)              || {};
    my $details      = $c9800->_ap_detail_strings();
    $c9800->_debug_ap_details();

    foreach my $iid (keys %{$indexes}) {
        my $ap_iid = $iid;
        next unless $ap_iid =~ s/\.\d+$//;

        next unless $details->{$ap_iid};

        my $prefix = $descriptions->{$iid};
        $descriptions->{$iid} = defined $prefix && $prefix ne ''
            ? "$prefix; $details->{$ap_iid}"
            : $details->{$ap_iid};
    }

    return $descriptions;
}

sub _merged_entity_table {
    my ($c9800, $entity_method, $ap_method) = @_;

    my $entities = $c9800->$entity_method() || {};
    my $ap_sub = SNMP::Info::Airespace->can($ap_method);
    my $aps = $ap_sub->($c9800) || {};
    my $ap_indexes = SNMP::Info::Airespace::e_index($c9800) || {};

    my %ap_entities = map { $_ => $aps->{$_} }
        grep { $_ ne 1 && exists $aps->{$_} } keys %{$ap_indexes};
    return {%{$entities}, %ap_entities};
}

sub e_index {
    my $c9800 = shift;

    my $descriptions = $c9800->c9800_entity_descr() || {};
    my $aps = SNMP::Info::Airespace::e_index($c9800) || {};
    my %indexes = map { $_ => $_ } keys %{$descriptions};

    delete $aps->{1};
    return {%indexes, %{$aps}};
}

sub e_class {
    return shift->_merged_entity_table('c9800_entity_class', 'e_class');
}

sub e_name {
    return shift->_merged_entity_table('c9800_entity_name', 'e_name');
}

sub e_descr {
    my $c9800 = shift;
    my $descriptions = $c9800->_merged_entity_table(
        'c9800_entity_descr', 'e_descr');
    my $details      = $c9800->_ap_detail_strings();
    my $tags         = $c9800->_ap_tag_strings();
    $c9800->_debug_ap_details();

    foreach my $iid (keys %{$descriptions}) {
        $descriptions->{$iid} .= "; $details->{$iid}" if $details->{$iid};
        $descriptions->{$iid} .= "; $tags->{$iid}"    if $tags->{$iid};
    }
    return $descriptions;
}

sub e_model {
    return shift->_merged_entity_table('c9800_entity_model', 'e_model');
}

sub e_type {
    return shift->_merged_entity_table('c9800_entity_type', 'e_type');
}

sub e_fwver {
    return shift->_merged_entity_table('c9800_entity_fwver', 'e_fwver');
}

sub e_vendor {
    return shift->_merged_entity_table('c9800_entity_vendor', 'e_vendor');
}

sub e_serial {
    return shift->_merged_entity_table('c9800_entity_serial', 'e_serial');
}

sub e_pos {
    return shift->_merged_entity_table('c9800_entity_pos', 'e_pos');
}

sub e_swver {
    return shift->_merged_entity_table('c9800_entity_swver', 'e_swver');
}

sub e_parent {
    return shift->_merged_entity_table('c9800_entity_parent', 'e_parent');
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::C9800 - SNMP Interface to Cisco Catalyst 9800 Wireless Controllers

=head1 DESCRIPTION

Subclass for Cisco Catalyst 9800 Wireless Controllers using the Airespace
wireless controller MIBs for managed access points and clients, and the
Cisco IOS-XE MIBs for the controller's own ports, VLANs and LLDP neighbors.

=head1 INHERITED CLASSES

=over

=item SNMP::Info::Layer2::Airespace

=item SNMP::Info::CiscoVTP

=item SNMP::Info::CiscoStats

=item SNMP::Info::LLDP

=item SNMP::Info::EtherLike

=back

=head2 Overrides

=over

=item serial()

Finds all C<ENTITY-MIB::entPhysicalDescr> entries containing C<chassis> and
returns the concatenated C<entPhysicalSerialNum> values at the corresponding
indexes.

=item os_ver()

Returns the IOS-XE version from C<.1.3.6.1.2.1.16.19.2.0>, falling back to
the standard Cisco sysDescr parsing.

=item os()

Returns C<ios-xe>, from the sysDescr parsing in L<SNMP::Info::CiscoStats>.

=item serial1()

Chassis serial number (C<OLD-CISCO-CHASSIS-MIB::chassisId.0>), as for other
Cisco IOS-XE devices.

=item v_name()

Returns the controller's VLAN names from C<CISCO-VTP-MIB::vtpVlanName>, keyed
by management domain and VLAN.  Adds the VLANs that wireless clients are on,
keyed by VLAN ID, using the interface name each client reports in
C<AIRESPACE-WIRELESS-MIB::bsnMobileStationInterface>.  FlexConnect APs switch
clients onto VLANs the controller does not define, so these are often the
only names for them.  A name already given to the VLAN is kept, unless it is
only the default C<VLANnnnn> name.

=item v_index()

Returns reference to hash.  Key: v_name() index, Value: VLAN ID.

=item i_vlan()

=item i_vlan_membership()

=item i_vlan_membership_untagged()

Native VLAN and VLAN membership of the controller's own ports from
L<SNMP::Info::CiscoVTP>, merged with the Airespace interface VLANs.

=item i_untagged()

=item set_i_pvid()

=item set_i_vlan()

=item set_i_untagged()

=item set_add_i_vlan_tagged()

=item set_remove_i_vlan_tagged()

The L<SNMP::Info::CiscoVTP> methods.  L<SNMP::Info::Bridge> comes first in
method resolution and would use F<Q-BRIDGE-MIB>, which the 9800 does not
implement.

=item i_duplex()

Duplex of the controller's own ports from
C<EtherLike-MIB::dot3StatsDuplexStatus>, merged with the Airespace port
duplex.

=item i_ssidlist()

Returns reference to hash.  SSID of each WLAN on each AP radio, from
c9800_radio_wlan_ssid().  The key is the AP radio interface iid followed by
the WLAN index.

=item i_ssidmac()

Returns reference to hash.  BSSID of each WLAN on each AP radio, from
c9800_radio_wlan_bssid(), keyed like i_ssidlist().

=item i_ssidbcast()

Returns reference to hash.  Whether each WLAN on each AP radio broadcasts its
SSID, from C<AIRESPACE-WIRELESS-MIB::bsnDot11EssBroadcastSsid> of its WLAN,
keyed like i_ssidlist().  The WLAN index is used as the
C<bsnDot11EssIndex>, as the 9800 numbers both the same.  WLANs without a
broadcast setting are omitted.

=item interfaces()

Uses the IF-MIB description for regular IOS-XE interfaces while retaining the
synthetic Airespace identifiers for AP and virtual interfaces.

=item i_description()

Adds the branch switch name, management address, and interface learned from
C<CISCO-LWAPP-CDP-MIB> to each matching AP pseudo-port description.

=item e_descr()

Adds the same branch connection information to each matching AP module
description, followed by the AP's policy, site and RF tag names.  The tags
are only added here and not to the AP radio port descriptions, because they
are set per AP rather than per radio.

=item e_index()

=item e_class()

=item e_name()

=item e_model()

=item e_type()

=item e_fwver()

=item e_vendor()

=item e_serial()

=item e_pos()

=item e_swver()

=item e_parent()

Merges the regular IOS-XE ENTITY-MIB inventory with the synthetic managed AP
inventory.  Physical chassis and module entries remain authoritative, and AP
entries are appended at their Airespace pseudo-indexes.

=back

=head2 AP Tag Table (C<CISCO-LWAPP-AP-MIB::cLApTable>)

Each AP has exactly one tag of each kind.  These tables are indexed by the AP
MAC address, like the Airespace AP tables.

=over

=item $c9800->c9800_ap_policy_tag()

(C<cLApPolicyTagName>)

=item $c9800->c9800_ap_site_tag()

(C<cLApSiteTagName>)

=item $c9800->c9800_ap_rf_tag()

(C<cLApRfTagName>)

=item $c9800->c9800_ap_tag_source()

How the tags were assigned: none, static, filterengine, pnpserver, default
or location.

(C<cLApTagSource>)

=back

=head2 Radio WLAN Table (C<CISCO-LWAPP-AP-MIB::cLApRadioWlanInfoTable>)

These tables are indexed by the AP radio MAC address, the radio slot and the
WLAN index.

=over

=item $c9800->c9800_radio_wlan_ssid()

(C<cLApRadioWlanSsid>)

=item $c9800->c9800_radio_wlan_bssid()

(C<cLApRadioWlanBssid>)

=back

=cut
