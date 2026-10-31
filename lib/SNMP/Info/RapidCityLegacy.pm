# SNMP::Info::RapidCityLegacy
#
# Copyright (c) 2014 Eric Miller
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

package SNMP::Info::RapidCityLegacy;

use strict;
use warnings;
use Exporter;
use SNMP::Info;
use SNMP::Info::RapidCity ();

@SNMP::Info::RapidCityLegacy::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::RapidCityLegacy::EXPORT_OK = qw//;

our ($VERSION, %FUNCS, %GLOBALS, %MIBS, %MUNGE);

$VERSION = '3.984000';

%MIBS = ( 'RAPID-CITY' => 'rapidCity' );

%GLOBALS = (
    'rc_virt_ip'   => 'rcSysVirtualIpAddr',
    'rc_virt_mask' => 'rcSysVirtualNetMask',

    # From RAPID-CITY::rcMlt (IST)
    'rc_ist_status' => 'rcMltIstSessionStatus',
    'rc_ist_peer'   => 'rcMltIstPeerIp',
    'rc_ist_vlan'   => 'rcMltIstVlanId',
);

%FUNCS = (

    # From RAPID-CITY::rc2kCpuEthernetPortTable
    'rc_cpu_ifindex'      => 'rc2kCpuEthernetPortIfIndex',
    'rc_cpu_admin'        => 'rc2kCpuEthernetPortAdminStatus',
    'rc_cpu_oper'         => 'rc2kCpuEthernetPortOperStatus',
    'rc_cpu_ip'           => 'rc2kCpuEthernetPortAddr',
    'rc_cpu_mask'         => 'rc2kCpuEthernetPortMask',
    'rc_cpu_auto'         => 'rc2kCpuEthernetPortAutoNegotiate',
    'rc_cpu_duplex_admin' => 'rc2kCpuEthernetPortAdminDuplex',
    'rc_cpu_duplex'       => 'rc2kCpuEthernetPortOperDuplex',
    'rc_cpu_speed_admin'  => 'rc2kCpuEthernetPortAdminSpeed',
    'rc_cpu_speed_oper'   => 'rc2kCpuEthernetPortOperSpeed',
    'rc_cpu_mac'          => 'rc2kCpuEthernetPortMgmtMacAddr',

    # From RAPID-CITY::rcVlanPortTable
    'rc_i_vlan' => 'rcVlanPortVlanIds',

    # From RAPID-CITY::rcCardTable
    'rc_c_type'   => 'rcCardType',
    'rc_c_serial' => 'rcCardSerialNumber',
    'rc_c_rev'    => 'rcCardHardwareRevision',
    'rc_c_part'   => 'rcCardPartNumber',

    # From RAPID-CITY::rc2kCardTable
    'rc2k_c_btype'   => 'rc2kCardBackType',
    'rc2k_c_bdesc'   => 'rc2kCardBackDescription',
    'rc2k_c_bserial' => 'rc2kCardBackSerialNum',
    'rc2k_c_brev'    => 'rc2kCardBackHwVersion',
    'rc2k_c_bpart'   => 'rc2kCardBackPartNumber',
    'rc2k_c_bdate'   => 'rc2kCardBackDateCode',
    'rc2k_c_bdev'    => 'rc2kCardBackDeviations',

    # From RAPID-CITY::rc2kMdaCardTable
    'rc2k_mda_type'   => 'rc2kMdaCardType',
    'rc2k_mda_desc'   => 'rc2kMdaCardDescription',
    'rc2k_mda_serial' => 'rc2kMdaCardSerialNum',
    'rc2k_mda_rev'    => 'rc2kMdaCardHwVersion',
    'rc2k_mda_part'   => 'rc2kMdaCardPartNumber',
    'rc2k_mda_date'   => 'rc2kMdaCardDateCode',
    'rc2k_mda_dev'    => 'rc2kMdaCardDeviations',

    # From RAPID-CITY::rcBridgeSpbmMacTable
    'rc_spbm_fw_port'   => 'rcBridgeSpbmMacCPort',
    'rc_spbm_fw_status' => 'rcBridgeSpbmMacStatus',
    'rc_spbm_fw_vlan'   => 'rcBridgeSpbmMacCVlanId',
);

%MUNGE = ( 'rc_cpu_mac' => \&SNMP::Info::munge_mac );

# The core reads rcPortTable only; these add the CPU Ethernet rows of the
# 8600 Series.  The mixin's @ISA stops at SNMP::Info, so SUPER:: would not
# reach the core.
sub i_duplex {
    my $rapidcity = shift;
    my $partial   = shift;

    my $i_duplex = SNMP::Info::RapidCity::i_duplex( $rapidcity, $partial );
    my $rc_cpu_duplex = $rapidcity->rc_cpu_duplex($partial) || {};

    # Get CPU Ethernet Interfaces for 8600 Series
    foreach my $iid ( keys %$rc_cpu_duplex ) {
        my $c_duplex = $rc_cpu_duplex->{$iid};
        next unless defined $c_duplex;

        $i_duplex->{$iid} = $c_duplex;
    }

    return $i_duplex;
}

sub i_duplex_admin {
    my $rapidcity = shift;
    my $partial   = shift;

    my $i_duplex_admin
        = SNMP::Info::RapidCity::i_duplex_admin( $rapidcity, $partial );
    my $rc_cpu_auto         = $rapidcity->rc_cpu_auto($partial)         || {};
    my $rc_cpu_duplex_admin = $rapidcity->rc_cpu_duplex_admin($partial) || {};

    # Get CPU Ethernet Interfaces for 8600 Series
    foreach my $iid ( keys %$rc_cpu_duplex_admin ) {
        my $c_duplex = $rc_cpu_duplex_admin->{$iid};
        next unless defined $c_duplex;
        my $c_auto = $rc_cpu_auto->{$iid};

        my $string = 'other';
        $string = 'half' if ( $c_duplex =~ /half/i and $c_auto =~ /false/i );
        $string = 'full' if ( $c_duplex =~ /full/i and $c_auto =~ /false/i );
        $string = 'auto' if $c_auto =~ /true/i;

        $i_duplex_admin->{$iid} = $string;
    }

    return $i_duplex_admin;
}

# Adds the IST of the 8600 and ERS families to the core's virtual IST
sub _rc_peer_link_flavors {
    return (
        vist => [ 'rc_vist', 'rcVirtualIst' ],
        ist  => [ 'rc_ist',  'rcMltIst' ],
    );
}

# break up the rcBridgeSpbmMacEntry INDEX into ISID and MAC Address.
sub _spbm_fdbtable_index {
    my $idx    = shift;
    my @values = split( /\./, $idx );
    my $isid = shift(@values);
    return ( $isid, join( ':', map { sprintf "%02x", $_ } @values ) );
}

sub rc_spbm_fw_mac {
    my $rapidcity  = shift;
    my $partial = shift;

    my $spbm_fw_ports = $rapidcity->rc_spbm_fw_port($partial);
    my $spbm_fw_mac  = {};
    foreach my $idx ( keys %$spbm_fw_ports ) {
        my ( $isid, $mac ) = _spbm_fdbtable_index($idx);
        $spbm_fw_mac->{$idx} = $mac;
    }
    return $spbm_fw_mac;
}

sub rc_spbm_fw_isid {
    my $rapidcity  = shift;
    my $partial = shift;

    my $spbm_fw_ports = $rapidcity->rc_spbm_fw_port($partial);
    my $spbm_fw_isid  = {};
    foreach my $idx ( keys %$spbm_fw_ports ) {
        my ( $isid, $mac ) = _spbm_fdbtable_index($idx);
        $spbm_fw_isid->{$idx} = $isid;
    }
    return $spbm_fw_isid;
}

1;

__END__

=head1 NAME

SNMP::Info::RapidCityLegacy - SNMP Interface to the RAPID-CITY MIB tables of
the Avaya/Nortel 8600 and ERS families

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $rapidcity = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $rapidcity->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

SNMP::Info::RapidCityLegacy is a subclass of SNMP::Info that provides the
C<RAPID-CITY> MIB entries used by the Passport 8600 era and the Ethernet
Routing Switch and BayStack families: the CPU Ethernet port, card and MDA
tables, the IST, the virtual IP address and the SPBM forwarding table.

Use or create in a subclass of SNMP::Info.  Do not use directly.  List it
ahead of L<SNMP::Info::RapidCity> in C<@ISA>, so its C<i_duplex()> and
C<i_duplex_admin()> add the CPU Ethernet rows to the ones the core returns,
and list the hashes in the opposite order.

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item F<RAPID-CITY>

=back

=head1 GLOBALS

These are methods that return scalar values from SNMP

=over

=item  $rapidcity->rc_virt_ip()

(C<rcSysVirtualIpAddr>)

=item  $rapidcity->rc_virt_mask()

(C<rcSysVirtualNetMask>)

=item $rapidcity->rc_ist_status()

(C<rcMltIstSessionStatus>)

=item $rapidcity->rc_ist_peer()

(C<rcMltIstPeerIp>)

=item $rapidcity->rc_ist_vlan()

(C<rcMltIstVlanId>)

=back

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $rapidcity->mlag_domains()

Adds the C<ist> domain kind to the core's C<mlag_domains()>, from
C<rcMltIstPeerIp> (C<peer>), C<rcMltIstVlanId> (C<vlan>) and
C<rcMltIstSessionStatus> (C<status>), with the same C<system_mac> as the
virtual IST.  A split MLT pairs with C<ist> in C<lag_groups()> when no virtual
IST is served.

=item $rapidcity->i_duplex()

Returns reference to map of IIDs to current link duplex, with the CPU
Ethernet ports added to the C<rcPortTable> rows of
L<SNMP::Info::RapidCity/"i_duplex()">.

=item $rapidcity->i_duplex_admin()

Returns reference to hash of IIDs to admin duplex setting, with the CPU
Ethernet ports added to the C<rcPortTable> rows of
L<SNMP::Info::RapidCity/"i_duplex_admin()">.

=back

=head2 RAPID-CITY CPU Ethernet Port Table (C<rc2kCpuEthernetPortTable>)

=over

=item $rapidcity->rc_cpu_ifindex()

(C<rc2kCpuEthernetPortIfIndex>)

=item $rapidcity->rc_cpu_admin()

(C<rc2kCpuEthernetPortAdminStatus>)

=item $rapidcity->rc_cpu_oper()

(C<rc2kCpuEthernetPortOperStatus>)

=item $rapidcity->rc_cpu_ip()

(C<rc2kCpuEthernetPortAddr>)

=item $rapidcity->rc_cpu_mask()

(C<rc2kCpuEthernetPortMask>)

=item $rapidcity->rc_cpu_auto()

(C<rc2kCpuEthernetPortAutoNegotiate>)

=item $rapidcity->rc_cpu_duplex_admin()

(C<rc2kCpuEthernetPortAdminDuplex>)

=item $rapidcity->rc_cpu_duplex()

(C<rc2kCpuEthernetPortOperDuplex>)

=item $rapidcity->rc_cpu_speed_admin()

(C<rc2kCpuEthernetPortAdminSpeed>)

=item $rapidcity->rc_cpu_speed_oper()

(C<rc2kCpuEthernetPortOperSpeed>)

=item $rapidcity->rc_cpu_mac()

(C<rc2kCpuEthernetPortMgmtMacAddr>)

=back

=head2 RAPID-CITY VLAN Port Table (C<rcVlanPortTable>)

=over

=item $rapidcity->rc_i_vlan()

(C<rcVlanPortVlanIds>)

=back

=head2 RAPID-CITY Card Table (C<rcCardTable>)

=over

=item $rapidcity->rc_c_type()

(C<rcCardType>)

=item $rapidcity->rc_c_serial()

(C<rcCardSerialNumber>)

=item $rapidcity->rc_c_rev()

(C<rcCardHardwareRevision>)

=item $rapidcity->rc_c_part()

(C<rcCardPartNumber>)

=back

=head2 RAPID-CITY 2k Card Table (C<rc2kCardTable>)

=over

=item $rapidcity->rc2k_c_btype()

(C<rc2kCardBackType>)

=item $rapidcity->rc2k_c_bdesc()

(C<rc2kCardBackDescription>)

=item $rapidcity->rc2k_c_bserial()

(C<rc2kCardBackSerialNum>)

=item $rapidcity->rc2k_c_brev()

(C<rc2kCardBackHwVersion>)

=item $rapidcity->rc2k_c_bpart()

(C<rc2kCardBackPartNumber>)

=item $rapidcity->rc2k_c_bdate()

(C<rc2kCardBackDateCode>)

=item $rapidcity->rc2k_c_bdev()

(C<rc2kCardBackDeviations>)

=back

=head2 RAPID-CITY MDA Card Table (C<rc2kMdaCardTable>)

=over

=item $rapidcity->rc2k_mda_type()

(C<rc2kMdaCardType>)

=item $rapidcity->rc2k_mda_desc()

(C<rc2kMdaCardDescription>)

=item $rapidcity->rc2k_mda_serial()

(C<rc2kMdaCardSerialNum>)

=item $rapidcity->rc2k_mda_rev()

(C<rc2kMdaCardHwVersion>)

=item $rapidcity->rc2k_mda_part()

(C<rc2kMdaCardPartNumber>)

=item $rapidcity->rc2k_mda_date()

(C<rc2kMdaCardDateCode>)

=item $rapidcity->rc2k_mda_dev()

(C<rc2kMdaCardDeviations>)

=back

=head2 RAPID-CITY Bridge SPBM MAC Table (C<rcBridgeSpbmMacTable>)

=over

=item $rapidcity->rc_spbm_fw_mac()

Returns reference to hash of forwarding table MAC Addresses

(C<rcBridgeSpbmMacAddr>)

=item $rapidcity->rc_spbm_fw_port()

Returns reference to hash of forwarding table entries port interface
identifier (iid)

(C<rcBridgeSpbmMacCPort>)

=item $rapidcity->rc_spbm_fw_status()

Returns reference to hash of forwarding table entries status

(C<rcBridgeSpbmMacStatus>)

=item $rapidcity->rc_spbm_fw_vlan()

Returns reference to hash of forwarding table entries Customer VLAN ID

(C<rcBridgeSpbmMacCVlanId>)

=item $rapidcity->rc_spbm_fw_isid()

Returns reference to hash of forwarding table entries ISID

(C<rcBridgeSpbmMacIsid>)

=back

=cut
