# SNMP::Info::RapidCity
# Eric Miller <eric@jeneric.org>
# $Id$
#
# Copyright (c) 2004 Max Baker
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#     * Neither the name of the University of California, Santa Cruz nor the 
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

package SNMP::Info::RapidCity;
$VERSION = 0.9;
use strict;

use Exporter;
use SNMP::Info;
use Carp;

@SNMP::Info::RapidCity::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::RapidCity::EXPORT_OK = qw//;

use vars qw/$VERSION $DEBUG %FUNCS %GLOBALS %MIBS %MUNGE $INIT/;
# Debug
$DEBUG=0;
$SNMP::debugging=$DEBUG;

# Five data structures required by SNMP::Info
$INIT = 0;

%MIBS    = (
            'RAPID-CITY' => 'rapidCity',
            );

%GLOBALS = (
            'serial'       => 'rcChasSerialNumber',
            'chassis'      => 'rcChasType',
            'slots'        => 'rcChasNumSlots',
            'tftp_host'    => 'rcTftpHost',
            'tftp_file'    => 'rcTftpFile',
            'tftp_action'  => 'rcTftpAction',
            'tftp_result'  => 'rcTftpResult',
            'rc_ch_rev'    => 'rcChasHardwareRevision',
            'rc_base_mac'  => 'rc2kChassisBaseMacAddr',
            'rc_virt_ip'   => 'rcSysVirtualIpAddr',
            );

%FUNCS  = (
            # From RAPID-CITY::rcPortTable
            'rc_index'          => 'rcPortIndex',
            'rc_duplex'         => 'rcPortOperDuplex',
            'rc_duplex_admin'   => 'rcPortAdminDuplex',
            'rc_speed_admin'    => 'rcPortAdminSpeed',
            'rc_auto'           => 'rcPortAutoNegotiate',
            'rc_alias'	    => 'rcPortName',
            # From RAPID-CITY::rc2kCpuEthernetPortTable
            'rc_cpu_ifindex'        => 'rc2kCpuEthernetPortIfIndex',
            'rc_cpu_admin'         => 'rc2kCpuEthernetPortAdminStatus',
            'rc_cpu_oper'          => 'rc2kCpuEthernetPortOperStatus',
            'rc_cpu_ip'            => 'rc2kCpuEthernetPortAddr',
            'rc_cpu_auto'          => 'rc2kCpuEthernetPortAutoNegotiate',
            'rc_cpu_duplex_admin'  => 'rc2kCpuEthernetPortAdminDuplex',
            'rc_cpu_duplex'        => 'rc2kCpuEthernetPortOperDuplex',
            'rc_cpu_speed_admin'   => 'rc2kCpuEthernetPortAdminSpeed',
            'rc_cpu_speed_oper'    => 'rc2kCpuEthernetPortOperSpeed',
            'rc_cpu_mac'           => 'rc2kCpuEthernetPortMgmtMacAddr',
            # From RAPID-CITY::rcVlanPortTable
            'rc_i_vlan_if'      => 'rcVlanPortIndex',
            'rc_i_vlan_num'     => 'rcVlanPortNumVlanIds',
            'rc_i_vlan'         => 'rcVlanPortVlanIds',
            'rc_i_vlan_type'    => 'rcVlanPortType',
            'rc_i_vlan_pvid'    => 'rcVlanPortDefaultVlanId',
            'rc_i_vlan_tag'     => 'rcVlanPortPerformTagging',
            # From RAPID-CITY::rcVlanTable
            'rc_vlan_id'      => 'rcVlanId',
            'rc_vlan_name'    => 'rcVlanName',
            'rc_vlan_color'   => 'rcVlanColor',
            'rc_vlan_if'      => 'rcVlanIfIndex',
            'rc_vlan_stg'     => 'rcVlanStgId',
            'rc_vlan_type'    => 'rcVlanType',
            'rc_vlan_members' => 'rcVlanPortMembers',
            'rc_vlan_mac'     => 'rcVlanMacAddress',
            # From RAPID-CITY::rcIpAddrTable
            'rc_ip_index'  => 'rcIpAdEntIfIndex',
            'rc_ip_addr'   => 'rcIpAdEntAddr',
            'rc_ip_type'   => 'rcIpAdEntIfType',
            # From RAPID-CITY::rcChasFanTable
            'rc_fan_op'     => 'rcChasFanOperStatus',
            # From RAPID-CITY::rcChasPowerSupplyTable
            'rc_ps_op'     => 'rcChasPowerSupplyOperStatus',
            # From RAPID-CITY::rcChasPowerSupplyDetailTable
            'rc_ps_type'     => 'rcChasPowerSupplyDetailType',
            'rc_ps_serial'   => 'rcChasPowerSupplyDetailSerialNumber',
            'rc_ps_rev'      => 'rcChasPowerSupplyDetailHardwareRevision',
            'rc_ps_part'     => 'rcChasPowerSupplyDetailPartNumber',
            'rc_ps_detail'     => 'rcChasPowerSupplyDetailDescription',
            # From RAPID-CITY::rcCardTable
            'rc_c_type'     => 'rcCardType',
            'rc_c_serial'   => 'rcCardSerialNumber',
            'rc_c_rev'      => 'rcCardHardwareRevision',
            'rc_c_part'     => 'rcCardPartNumber',
            # From RAPID-CITY::rc2kCardTable
            'rc2k_c_ftype'    => 'rc2kCardFrontType',
            'rc2k_c_fdesc'    => 'rc2kCardFrontDescription',
            'rc2k_c_fserial'  => 'rc2kCardFrontSerialNum',
            'rc2k_c_frev'     => 'rc2kCardFrontHwVersion',
            'rc2k_c_fpart'    => 'rc2kCardFrontPartNumber',
            'rc2k_c_fdate'    => 'rc2kCardFrontDateCode',
            'rc2k_c_fdev'     => 'rc2kCardFrontDeviations',
            'rc2k_c_btype'    => 'rc2kCardBackType',
            'rc2k_c_bdesc'    => 'rc2kCardBackDescription',
            'rc2k_c_bserial'  => 'rc2kCardBackSerialNum',
            'rc2k_c_brev'     => 'rc2kCardBackHwVersion',
            'rc2k_c_bpart'    => 'rc2kCardBackPartNumber',
            'rc2k_c_bdate'    => 'rc2kCardBackDateCode',
            'rc2k_c_bdev'     => 'rc2kCardBackDeviations',
            # From RAPID-CITY::rc2kMdaCardTable
            'rc2k_mda_type'    => 'rc2kMdaCardType',
            'rc2k_mda_desc'    => 'rc2kMdaCardDescription',
            'rc2k_mda_serial'  => 'rc2kMdaCardSerialNum',
            'rc2k_mda_rev'     => 'rc2kMdaCardHwVersion',
            'rc2k_mda_part'    => 'rc2kMdaCardPartNumber',
            'rc2k_mda_date'    => 'rc2kMdaCardDateCode',
            'rc2k_mda_dev'     => 'rc2kMdaCardDeviations',
            );

%MUNGE = (
            'rc_base_mac' => \&SNMP::Info::munge_mac,
            'rc_vlan_mac' => \&SNMP::Info::munge_mac,
            'rc_cpu_mac' => \&SNMP::Info::munge_mac,         
         );


sub i_duplex {
    my $rapidcity = shift;
    
    my $interfaces   = $rapidcity->interfaces();
    my $rc_index  = $rapidcity->rc_index();
    my $rc_duplex = $rapidcity->rc_duplex();
    my $rc_cpu_duplex = $rapidcity->rc_cpu_duplex();

    my %i_duplex;
    foreach my $if (keys %$interfaces){
        my $duplex = $rc_duplex->{$if};
        next unless defined $duplex; 
    
        $duplex = 'half' if $duplex =~ /half/i;
        $duplex = 'full' if $duplex =~ /full/i;
        $i_duplex{$if}=$duplex; 
    }
    
    # Get CPU Ethernet Interfaces for 8600 Series
    foreach my $iid (keys %$rc_cpu_duplex){
        my $c_duplex = $rc_cpu_duplex->{$iid};
        next unless defined $c_duplex;

       	$i_duplex{$iid} = $c_duplex;
    }

    return \%i_duplex;
}

sub i_duplex_admin {
    my $rapidcity = shift;

    my $interfaces  = $rapidcity->interfaces();
    my $rc_index = $rapidcity->rc_index();
    my $rc_duplex_admin = $rapidcity->rc_duplex_admin();
    my $rc_auto = $rapidcity->rc_auto();
    my $rc_cpu_auto = $rapidcity->rc_cpu_auto();
    my $rc_cpu_duplex_admin = $rapidcity->rc_cpu_duplex_admin();
 
    my %i_duplex_admin;
    foreach my $if (keys %$interfaces){
        my $duplex = $rc_duplex_admin->{$if};
        next unless defined $duplex;
        my $auto = $rc_auto->{$if}||'false';
        
	my $string = 'other';
        $string = 'half' if ($duplex =~ /half/i and $auto =~ /false/i);
        $string = 'full' if ($duplex =~ /full/i and $auto =~ /false/i);
        $string = 'auto' if $auto =~ /true/i;    

        $i_duplex_admin{$if}=$string; 
    }
    
    # Get CPU Ethernet Interfaces for 8600 Series
    foreach my $iid (keys %$rc_cpu_duplex_admin){
        my $c_duplex = $rc_cpu_duplex_admin->{$iid};
        next unless defined $c_duplex;
        my $c_auto = $rc_cpu_auto->{$iid};

	my $string = 'other';
        $string = 'half' if ($c_duplex =~ /half/i and $c_auto =~ /false/i);
        $string = 'full' if ($c_duplex =~ /full/i and $c_auto =~ /false/i);
        $string = 'auto' if $c_auto =~ /true/i;    

       	$i_duplex_admin{$iid} = $string;
    }
    
    return \%i_duplex_admin;
}

sub i_vlan {
    my $rapidcity = shift;

    my $rc_vlans  = $rapidcity->rc_i_vlan();
    my $rc_vlan_id  = $rapidcity->rc_vlan_id();
    my $rc_vlan_if  = $rapidcity->rc_vlan_if();
    
    my %i_vlan;
        foreach my $if (keys %$rc_vlans){
            my $rc_vlanid = $rc_vlans->{$if};
            next unless defined $rc_vlanid;
            my @vlanids = map { sprintf "%02x",$_ } unpack('C*',$rc_vlanid);

            my @vlans = ();

            while($#vlanids > 0) {
                my $h = join('', splice(@vlanids,0,2));
                push(@vlans, hex($h));
            }
        my $vlans = join (',', @vlans);
        $i_vlan{$if}=$vlans; 
    }
        foreach my $if (keys %$rc_vlan_if){
            my $vlan_if = $rc_vlan_if->{$if};
            next unless defined $vlan_if;
            my $vlan = $rc_vlan_id->{$if};

        $i_vlan{$vlan_if}=$vlan; 
    }
    return \%i_vlan;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer2::RapidCity - SNMP Interface to Nortel Networks' RapidCity MIB

=head1 AUTHOR

Eric Miller (C<eric@jeneric.org>)

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $rapidcity = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $rapidcity->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

SNMP::Info::RapidCity is a subclass of SNMP::Info that provides an interface
to the C<RAPID-CITY> MIB.  This MIB is used across the Nortel Networks' Passport
LAN, as well as, the BayStack and Acclear families.

Use or create in a subclass of SNMP::Info.  Do not use directly.

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item RAPID-CITY

=back

MIBs can be found on the CD that came with your product.

Or, they can be downloaded directly from Nortel Networks regardless of support
contract status.

Go to http://www.nortelnetworks.com Techninal Support, Browse Technical Support,
Select by product, Java Device Manager, Software.  Download the latest version.
After installation, all mibs are located under the install directory under mibs
and the repspective product line.

Note:  Required version of RAPID-CITY, rapid_city.mib, must be from the Passport
8600 version 3.3 or higher (located in JDM\mibs\passport8k\).

=head1 GLOBAL METHODS

These are methods that return scalar values from SNMP

=over

=item  $rapidcity->chassis_base_mac()

(B<rc2kChassisBaseMacAddr>)

=item  $rapidcity->ch_serial()

(B<rcChasSerialNumber>)

=item  $rapidcity->rc_ch_rev()

(B<rcChasHardwareRevision>)

=item  $rapidcity->chassis()

(B<rcChasType>)

=item  $rapidcity->slots()

(B<rcChasNumSlots>)

=item  $rapidcity->rc_virt_ip()

(B<rcSysVirtualIpAddr>)

=item  $rapidcity->tftp_host()

(B<rcTftpHost>)

=item  $rapidcity->tftp_file()

(B<rcTftpFile>)

=item  $rapidcity->tftp_action()

(B<rcTftpAction>)

=item  $rapidcity->tftp_result()

(B<rcTftpResult>)

=back

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $rapidcity->i_duplex()

Returns reference to map of IIDs to current link duplex.

=item $rapidcity->i_duplex_admin()

Returns reference to hash of IIDs to admin duplex setting.

=item $rapidcity->i_vlan()

Returns a mapping between ifIndex and the VLAN.

=back

=head2 RAPID-CITY Port Table (B<rcPortTable>)

=over

=item $rapidcity->rc_index()

(B<rcPortIndex>)

=item $rapidcity->rc_duplex()

(B<rcPortOperDuplex>)

=item $rapidcity->rc_duplex_admin()

(B<rcPortAdminDuplex>)

=item $rapidcity->rc_speed_admin()

(B<rcPortAdminSpeed>)

=item $rapidcity->rc_auto()

(B<rcPortAutoNegotiate>)

=item $rapidcity->rc_alias()

(B<rcPortName>)

=back

=head2 RAPID-CITY CPU Ethernet Port Table (B<rc2kCpuEthernetPortTable>)

=over

=item $rapidcity->rc_cpu_ifindex()

(B<rc2kCpuEthernetPortIfIndex>)

=item $rapidcity->rc_cpu_admin()

(B<rc2kCpuEthernetPortAdminStatus>)

=item $rapidcity->rc_cpu_oper()

(B<rc2kCpuEthernetPortOperStatus>)

=item $rapidcity->rc_cpu_ip()

(B<rc2kCpuEthernetPortAddr>)

=item $rapidcity->rc_cpu_auto()

(B<rc2kCpuEthernetPortAutoNegotiate>)

=item $rapidcity->rc_cpu_duplex_admin()

(B<rc2kCpuEthernetPortAdminDuplex>)

=item $rapidcity->rc_cpu_duplex()

(B<rc2kCpuEthernetPortOperDuplex>)

=item $rapidcity->rc_cpu_speed_admin()

(B<rc2kCpuEthernetPortAdminSpeed>)

=item $rapidcity->rc_cpu_speed_oper()

(B<rc2kCpuEthernetPortOperSpeed>)

=item $rapidcity->rc_cpu_mac()

(B<rc2kCpuEthernetPortMgmtMacAddr>)

=back

=head2 RAPID-CITY VLAN Port Table (B<rcVlanPortTable>)

=over

=item $rapidcity->rc_i_vlan_if()

(B<rcVlanPortIndex>)

=item $rapidcity->rc_i_vlan_num()

(B<rcVlanPortNumVlanIds>)

=item $rapidcity->rc_i_vlan()

(B<rcVlanPortVlanIds>)

=item $rapidcity->rc_i_vlan_type()

(B<rcVlanPortType>)

=item $rapidcity->rc_i_vlan_pvid()

(B<rcVlanPortDefaultVlanId>)

=item $rapidcity->rc_i_vlan_tag()

(B<rcVlanPortPerformTagging>)

=back

=head2 RAPID-CITY VLAN Table (B<rcVlanTable>)

=over

=item $rapidcity->rc_vlan_id()

(B<rcVlanId>)

=item $rapidcity->rc_vlan_name()

(B<rcVlanName>)

=item $rapidcity->rc_vlan_color()

(B<rcVlanColor>)

=item $rapidcity->rc_vlan_if()

(B<rcVlanIfIndex>)

=item $rapidcity->rc_vlan_stg()

(B<rcVlanStgId>)

=item $rapidcity->rc_vlan_type()

(B<rcVlanType>)

=item $rapidcity->rc_vlan_members()

(B<rcVlanPortMembers>)

=item $rapidcity->rc_vlan_mac()

(B<rcVlanMacAddress>)

=back

=head2 RAPID-CITY IP Address Table (B<rcIpAddrTable>)

=over

=item $rapidcity->rc_ip_index()

(B<rcIpAdEntIfIndex>)

=item $rapidcity->rc_ip_addr()

(B<rcIpAdEntAddr>)

=item $rapidcity->rc_ip_type()

(B<rcIpAdEntIfType>)

=back

=head2 RAPID-CITY Chassis Fan Table (B<rcChasFanTable>)

=over

=item $rapidcity->rc_fan_op()

(B<rcChasFanOperStatus>)

=back

=head2 RAPID-CITY Power Supply Table (B<rcChasPowerSupplyTable>)

=over

=item $rapidcity->rc_ps_op()

(B<rcChasPowerSupplyOperStatus>)

=back

=head2 RAPID-CITY Power Supply Detail Table (B<rcChasPowerSupplyDetailTable>)

=over

=item $rapidcity->rc_ps_type()

(B<rcChasPowerSupplyDetailType>)

=item $rapidcity->rc_ps_serial()

(B<rcChasPowerSupplyDetailSerialNumber>)

=item $rapidcity->rc_ps_rev()

(B<rcChasPowerSupplyDetailHardwareRevision>)

=item $rapidcity->rc_ps_part()

(B<rcChasPowerSupplyDetailPartNumber>)

=item $rapidcity->rc_ps_detail()

(B<rcChasPowerSupplyDetailDescription>)

=back

=head2 RAPID-CITY Card Table (B<rcCardTable>)

=over

=item $rapidcity->rc_c_type()

(B<rcCardType>)

=item $rapidcity->rc_c_serial()

(B<rcCardSerialNumber>)

=item $rapidcity->rc_c_rev()

(B<rcCardHardwareRevision>)

=item $rapidcity->rc_c_part()

(B<rcCardPartNumber>)

=back

=head2 RAPID-CITY 2k Card Table (B<rc2kCardTable>)

=over

=item $rapidcity->rc2k_c_ftype()

(B<rc2kCardFrontType>)

=item $rapidcity->rc2k_c_fdesc()

(B<rc2kCardFrontDescription>)

=item $rapidcity->rc2k_c_fserial()

(B<rc2kCardFrontSerialNum>)

=item $rapidcity->rc2k_c_frev()

(B<rc2kCardFrontHwVersion>)

=item $rapidcity->rc2k_c_fpart()

(B<rc2kCardFrontPartNumber>)

=item $rapidcity->rc2k_c_fdate()

(B<rc2kCardFrontDateCode>)

=item $rapidcity->rc2k_c_fdev()

(B<rc2kCardFrontDeviations>)

=item $rapidcity->rc2k_c_btype()

(B<rc2kCardBackType>)

=item $rapidcity->rc2k_c_bdesc()

(B<rc2kCardBackDescription>)

=item $rapidcity->rc2k_c_bserial()

(B<rc2kCardBackSerialNum>)

=item $rapidcity->rc2k_c_brev()

(B<rc2kCardBackHwVersion>)

=item $rapidcity->rc2k_c_bpart()

(B<rc2kCardBackPartNumber>)

=item $rapidcity->rc2k_c_bdate()

(B<rc2kCardBackDateCode>)

=item $rapidcity->rc2k_c_bdev()

(B<rc2kCardBackDeviations>)

=back

=head2 RAPID-CITY MDA Card Table (B<rc2kMdaCardTable>)

=over

=item $rapidcity->rc2k_mda_type()

(B<rc2kMdaCardType>)

=item $rapidcity->rc2k_mda_desc()

(B<rc2kMdaCardDescription>)

=item $rapidcity->rc2k_mda_serial()

(B<rc2kMdaCardSerialNum>)

=item $rapidcity->rc2k_mda_rev()

(B<rc2kMdaCardHwVersion>)

=item $rapidcity->rc2k_mda_part()

(B<rc2kMdaCardPartNumber>)

=item $rapidcity->rc2k_mda_date()

(B<rc2kMdaCardDateCode>)

=item $rapidcity->rc2k_mda_dev()

(B<rc2kMdaCardDeviations>)

=cut
