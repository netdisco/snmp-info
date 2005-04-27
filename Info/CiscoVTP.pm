# SNMP::Info::CiscoVTP
# Max Baker
#
# Copyright (c) 2004 Max Baker changes from version 0.8 and beyond.
#
# Copyright (c) 2003 Regents of the University of California
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

package SNMP::Info::CiscoVTP;
$VERSION = 1.0;
# $Id$

use strict;

use Exporter;
use SNMP::Info;

use vars qw/$VERSION $DEBUG %MIBS %FUNCS %GLOBALS %MUNGE $INIT/;
@SNMP::Info::CiscoVTP::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::CiscoVTP::EXPORT_OK = qw//;

%MIBS    = (
            'CISCO-VTP-MIB'                       => 'vtpVlanName',
            'CISCO-VLAN-MEMBERSHIP-MIB'           => 'vmMembershipEntry',
            'CISCO-VLAN-IFTABLE-RELATIONSHIP-MIB' => 'cviRoutedVlanIfIndex',
           );

%GLOBALS = (
            'vtp_version'           => 'vtpVersion',
            'vtp_maxstore'          => 'vtpMaxVlanStorage',
            'vtp_notify'            => 'vtpNotificationsEnabled',
            'vtp_notify_create'     => 'vtpVlanCreatedNotifEnabled',
            'vtp_notify_delete'     => 'vtpVlanDeletedNotifEnabled',
           );

%FUNCS   = (
            # Management Domain Table
            'vtp_d_index'     => 'managementDomainIndex',
            'vtp_d_name'      => 'managementDomainName',
            'vtp_d_mode'      => 'managementDomainLocalMode',
            'vtp_d_rev'       => 'managementDomainConfigRevNumber',
            'vtp_d_updater'   => 'managementDomainLastUpdater',
            'vtp_d_last'      => 'managementDomainLastChange',
            'vtp_d_status'    => 'managementDomainRowStatus',
            'vtp_d_tftp'      => 'managementDomainTftpServer',
            'vtp_d_tftp_path' => 'managementDomainTftpPathname',
            'vtp_d_pruning'   => 'managementDomainPruningState',
            'vtp_d_ver'       => 'managementDomainVersionInUse',
            #  VLAN Table
            'v_index'    => 'vtpVlanIndex',
            'v_state'    => 'vtpVlanState',
            'v_type'     => 'vtpVlanType',
            'v_name'     => 'vtpVlanName',
            'v_mtu'      => 'vtpVlanMtu',
            'v_said'     => 'vtpVlanDot10Said',
            'v_ring'     => 'vtpVlanRingNumber',
            'v_bridge'   => 'vtpVlanBridgeNumber',
            'v_stp'      => 'vtpVlanStpType',
            'v_parent'   => 'vtpVlanParentVlan',
            'v_trans1'   => 'vtpVlanTranslationalVlan1',
            'v_trans2'   => 'vtpVlanTranslationalVlan2',
            'v_btype'    => 'vtpVlanBridgeType',
            'v_hop_are'  => 'vtpVlanAreHopCount',
            'v_hop_ste'  => 'vtpVlanSteHopCount',
            'v_crf'      => 'vtpVlanIsCRFBackup',
            'v_type_ext' => 'vtpVlanTypeExt',
            'v_if'       => 'vtpVlanIfIndex',

            # CISCO-VLAN-MEMBERSHIP-MIB
            # VmMembershipTable
            'i_vlan_type' => 'vmVlanType',
            'i_vlan2'     => 'vmVlan',
            'i_vlan_stat' => 'vmPortStatus',
            'i_vlan_1'    => 'vmVlans',
            'i_vlan_2'    => 'vmVlans2k',
            'i_vlan_3'    => 'vmVlans3k',
            'i_vlan_4'    => 'vmVlans4k',

            # CISCO-VLAN-IFTABLE-RELATIONSHIP-MIB
            'v_cvi_if'    => 'cviRoutedVlanIfIndex',

            # vlanTrunkPortTable

            # TODO Add these tables if someone wants them..
            # vtpEditControlTable
            # vtpVlanEditTable
            # vtpStatsTable
           );

%MUNGE   = (
           );


sub i_vlan {
    my $vtp = shift;

    # Check for CISCO-VLAN-MIB
    my $i_vlan = $vtp->i_vlan2();
    return $i_vlan if defined $i_vlan;

    # Check in CISCO-VLAN-IFTABLE-RELATION-MIB
    my $v_cvi_if = $vtp->v_cvi_if();
    return undef unless defined $v_cvi_if;

    # Translate vlan.physical_interface -> iid
    #       to iid -> vlan
    $i_vlan = {};
    foreach my $i (keys %$v_cvi_if){
        my ($vlan,$phys) = split(/\./,$i);
        my $iid = $v_cvi_if->{$i};

        $i_vlan->{$iid}=$vlan;
    }

    return $i_vlan;
}

sub set_i_vlan {
    my $vtp = shift;

    # Check for CISCO-VLAN-MIB
    my $i_vlan = $vtp->i_vlan2();
    if (defined $i_vlan) {
        return $vtp->set_i_vlan2(@_);
    }
    # only support the first case for now.
    return undef;
}

1;
__END__

=head1 NAME

SNMP::Info::CiscoVTP - Perl5 Interface to Cisco's VLAN Management MIBs

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $vtp = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $vtp->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

SNMP::Info::CiscoVTP is a subclass of SNMP::Info that provides 
information about a cisco device's VLAN and VTP Domain memebership.

Use or create in a subclass of SNMP::Info.  Do not use directly.

=head2 Inherited Classes

none.

=head2 Required MIBs

=over

=item CISCO-VTP-MIB

=item CISCO-VLAN-MEMBERSHIP-MIB

=item CISCO-VLAN-IFTABLE-RELATIONSHIP-MIB

=back

MIBs can be found at ftp://ftp.cisco.com/pub/mibs/v2/v2.tar.gz

=head1 GLOBALS

=over

=item $vtp->vtp_version()

C<vtpVersion>

=item $vtp->vtp_maxstore()

C<vtpMaxVlanStorage>

=item $vtp->vtp_notify()

C<vtpNotificationsEnabled>

=item $vtp->vtp_notify_create()

C<vtpVlanCreatedNotifEnabled>

=item $vtp->vtp_notify_delete()

C<vtpVlanDeletedNotifEnabled>

=back

=head1 TABLE METHODS

You device will only implement a subset of these methods.

=head2 VLAN Table

See ftp://ftp.cisco.com/pub/mibs/supportlists/wsc5000/wsc5000-communityIndexing.html
for a good treaty of how to connect to the VLANs

This table is from CISCO-VTP-MIB::vtpVlanTable

=over

=item $vtp->v_index()

C<vtpVlanIndex>

=item $vtp->v_state()

C<vtpVlanState>

=item $vtp->v_type()

C<vtpVlanType>

=item $vtp->v_name()

C<vtpVlanName>

=item $vtp->v_mtu()

C<vtpVlanMtu>

=item $vtp->v_said()

C<vtpVlanDot10Said>

=item $vtp->v_ring()

C<vtpVlanRingNumber>

=item $vtp->v_bridge()

C<vtpVlanBridgeNumber>

=item $vtp->v_stp()

C<vtpVlanStpType>

=item $vtp->v_parent()

C<vtpVlanParentVlan>

=item $vtp->v_trans1()

C<vtpVlanTranslationalVlan1>

=item $vtp->v_trans2()

C<vtpVlanTranslationalVlan2>

=item $vtp->v_btype()

C<vtpVlanBridgeType>

=item $vtp->v_hop_are()

C<vtpVlanAreHopCount>

=item $vtp->v_hop_ste()

C<vtpVlanSteHopCount>

=item $vtp->v_crf()

C<vtpVlanIsCRFBackup>

=item $vtp->v_type_ext()

C<vtpVlanTypeExt>

=item $vtp->v_if()

C<vtpVlanIfIndex>

=back

=head2 VLAN Interface Table

This table is from CISCO-VLAN-MEMBERSHIP-MIB::VmMembershipTable

=over

=item $vtp->i_vlan_type()

Static, Dynamic, or multiVlan.  

C<vmVlanType>

=item $vtp->i_vlan()

The VLAN that a port is assigned to.

0 for no VLAN assigned. 

C<vmVlan>

=item $vtp->i_vlan_stat()

Inactive, active, shutdown.

C<vmPortStatus>

=item $vtp->i_vlan_1()

Each bit represents a VLAN.  This is 0 through 1023

C<vmVlans>

=item $vtp->i_vlan_2()

Each bit represents a VLAN.  This is 1024 through 2047

C<vmVlans2k>

=item $vtp->i_vlan_3()

Each bit represents a VLAN.  This is 2048 through 3071

C<vmVlans3k>

=item $vtp->i_vlan_4()

Each bit represents a VLAN.  This is 3072 through 4095

C<vmVlans4k>

=back

=head2 Managment Domain Table

=over

=item $vtp->vtp_d_index()

C<managementDomainIndex>

=item $vtp->vtp_d_name()

C<managementDomainName>

=item $vtp->vtp_d_mode()

C<managementDomainLocalMode>

=item $vtp->vtp_d_rev()

C<managementDomainConfigRevNumber>

=item $vtp->vtp_d_updater()

C<managementDomainLastUpdater>

=item $vtp->vtp_d_last()

C<managementDomainLastChange>

=item $vtp->vtp_d_status()

C<managementDomainRowStatus>

=item $vtp->vtp_d_tftp()

C<managementDomainTftpServer>

=item $vtp->vtp_d_tftp_path()

C<managementDomainTftpPathname>

=item $vtp->vtp_d_pruning()

C<managementDomainPruningState>

=item $vtp->vtp_d_ver()

C<managementDomainVersionInUse>

=back

=cut
