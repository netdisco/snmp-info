# SNMP::Info::Layer3::C9800
#
# Copyright (c) 2026 The SNMP::Info Developers
# All rights reserved.

package SNMP::Info::Layer3::C9800;

use strict;
use warnings;
use Exporter;
use SNMP::Info::CiscoStats;
use SNMP::Info::Entity;
use SNMP::Info::Layer2::Airespace;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

@SNMP::Info::Layer3::C9800::ISA = qw/
    SNMP::Info::Layer2::Airespace
    Exporter
/;

@SNMP::Info::Layer3::C9800::EXPORT_OK = qw//;

$VERSION = '3.977000';

%MIBS = (
    %SNMP::Info::Layer2::Airespace::MIBS,
    %SNMP::Info::Entity::MIBS,
    'CISCO-LWAPP-CDP-MIB' => 'clcCdpApCacheNeighInterface',
);

%GLOBALS = (
    %SNMP::Info::Layer2::Airespace::GLOBALS,
    'c9800_os_ver' => '.1.3.6.1.2.1.16.19.2.0',
);

%FUNCS = (
    %SNMP::Info::Layer2::Airespace::FUNCS,
    'c9800_entity_descr'  => 'entPhysicalDescr',
    'c9800_entity_serial' => 'entPhysicalSerialNum',
    'c9800_cdp_name'      => 'clcCdpApCacheNeighName',
    'c9800_cdp_address'   => 'clcCdpApCacheNeighAddress',
    'c9800_cdp_interface' => 'clcCdpApCacheNeighInterface',
    'c9800_ap_vlan'       => 'bsnAPGroupVlanName',
    'c9800_ap_ios_ver'    => 'bsnAPIOSVersion',
    'c9800_ap_oper'       => 'bsnAPOperationStatus',
    'c9800_ap_primary'    => 'bsnAPPrimaryMwarName',
    'c9800_ap_secondary'  => 'bsnAPSecondaryMwarName',
);

%MUNGE = (
    %SNMP::Info::Layer2::Airespace::MUNGE,
    'c9800_cdp_address' => \&SNMP::Info::munge_ip,
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

sub e_descr {
    my $c9800      = shift;
    my $descriptions = $c9800->SUPER::e_descr() || {};
    my $details      = $c9800->_ap_detail_strings();
    $c9800->_debug_ap_details();

    foreach my $iid (keys %{$descriptions}) {
        $descriptions->{$iid} .= "; $details->{$iid}" if $details->{$iid};
    }
    return $descriptions;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::C9800 - SNMP Interface to Cisco Catalyst 9800 Wireless Controllers

=head1 DESCRIPTION

Subclass for Cisco Catalyst 9800 Wireless Controllers using the Airespace
wireless controller MIBs for managed access points and clients.

=head1 INHERITED CLASSES

=over

=item SNMP::Info::Layer2::Airespace

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

=item i_description()

Adds the branch switch name, management address, and interface learned from
C<CISCO-LWAPP-CDP-MIB> to each matching AP pseudo-port description.

=item e_descr()

Adds the same branch connection information to each matching AP module
description.

=back

=cut
