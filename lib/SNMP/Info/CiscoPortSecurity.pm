# SNMP::Info::CiscoPortSecurity
#
# Copyright (c) 2008 Eric Miller
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

package SNMP::Info::CiscoPortSecurity;

use strict;
use warnings;
use Exporter;
use SNMP::Info;

@SNMP::Info::CiscoPortSecurity::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::CiscoPortSecurity::EXPORT_OK = qw//;

our ($VERSION, %MIBS, %FUNCS, %GLOBALS, %MUNGE, %PAECAPABILITIES);

$VERSION = '3.70';

%MIBS = (
    'CISCO-PORT-SECURITY-MIB' => 'ciscoPortSecurityMIB',
    'CISCO-PAE-MIB'           => 'ciscoPaeMIB',
    'IEEE8021-PAE-MIB'        => 'dot1xAuthLastEapolFrameSource',
    'CISCO-ERR-DISABLE-MIB'   => 'ciscoErrDisableMIB',
);

%GLOBALS = (

    # CISCO-PORT-SECURITY-MIB
    'cps_clear'     => 'cpsGlobalClearSecureMacAddresses',
    'cps_notify'    => 'cpsGlobalSNMPNotifControl',
    'cps_rate'      => 'cpsGlobalSNMPNotifRate',
    'cps_enable'    => 'cpsGlobalPortSecurityEnable',
    'cps_mac_count' => 'cpsGlobalTotalSecureAddress',
    'cps_mac_max'   => 'cpsGlobalMaxSecureAddress',
);

%FUNCS = (

    # CISCO-PORT-SECURITY-MIB::cpsIfConfigTable
    'cps_i_limit_val'  => 'cpsIfInvalidSrcRateLimitValue',
    'cps_i_limit'      => 'cpsIfInvalidSrcRateLimitEnable',
    'cps_i_sticky'     => 'cpsIfStickyEnable',
    'cps_i_clear_type' => 'cpsIfClearSecureMacAddresses',
    'cps_i_shutdown'   => 'cpsIfShutdownTimeout',
    'cps_i_flood'      => 'cpsIfUnicastFloodingEnable',
    'cps_i_clear'      => 'cpsIfClearSecureAddresses',
    'cps_i_mac'        => 'cpsIfSecureLastMacAddress',
    'cps_i_count'      => 'cpsIfViolationCount',
    'cps_i_action'     => 'cpsIfViolationAction',
    'cps_i_mac_static' => 'cpsIfStaticMacAddrAgingEnable',
    'cps_i_mac_type'   => 'cpsIfSecureMacAddrAgingType',
    'cps_i_mac_age'    => 'cpsIfSecureMacAddrAgingTime',
    'cps_i_mac_count'  => 'cpsIfCurrentSecureMacAddrCount',
    'cps_i_mac_max'    => 'cpsIfMaxSecureMacAddr',
    'cps_i_status'     => 'cpsIfPortSecurityStatus',
    'cps_i_enable'     => 'cpsIfPortSecurityEnable',

    # CISCO-PORT-SECURITY-MIB::cpsIfVlanTable
    'cps_i_v_mac_count' => 'cpsIfVlanCurSecureMacAddrCount',
    'cps_i_v_mac_max'   => 'cpsIfVlanMaxSecureMacAddr',

    # CISCO-PORT-SECURITY-MIB::cpsIfVlanSecureMacAddrTable
    'cps_i_v_mac_status' => 'cpsIfVlanSecureMacAddrRowStatus',
    'cps_i_v_mac_age'    => 'cpsIfVlanSecureMacAddrRemainAge',
    'cps_i_v_mac_type'   => 'cpsIfVlanSecureMacAddrType',

    # CISCO-PORT-SECURITY-MIB::cpsSecureMacAddressTable
    'cps_m_status' => 'cpsSecureMacAddrRowStatus',
    'cps_m_age'    => 'cpsSecureMacAddrRemainingAge',
    'cps_m_type'   => 'cpsSecureMacAddrType',

    # IEEE8021-PAE-MIB::dot1xPaePortEntry
    'pae_i_capabilities'            => 'dot1xPaePortCapabilities',
    'pae_i_last_eapol_frame_source' => 'dot1xAuthLastEapolFrameSource',

    # CISCO-ERR-DISABLE-MIB::cErrDisableIfStatusEntry
    'cerr_i_cause' => 'cErrDisableIfStatusCause',
);

%MUNGE = (
    'cps_i_mac'                     => \&SNMP::Info::munge_mac,
    'pae_i_last_eapol_frame_source' => \&SNMP::Info::munge_mac,
    'pae_i_capabilities'            => \&munge_pae_capabilities,
);

%PAECAPABILITIES = (
    0 => 'dot1xPaePortAuthCapable',
    1 => 'dot1xPaePortSuppCapable',
);

sub munge_pae_capabilities {
    my $bits = shift;

    return unless defined $bits;
    my @vals
        = map( $PAECAPABILITIES{$_}, sprintf( "%x", unpack( 'b*', $bits ) ) );
    return join( ' ', @vals );
}

# Define a generic method to show the cause for a port to be err-disabled.
# Cisco indexes cErrDisableIfStatusCause by {ifindex,vlan}, but for a more
# generic method, using ifIndex only makes it easier to implement across
# device classes. Besides, several (most?) err-disable features will disable
# the whole interface anyway, and not just a vlan on the interface.
sub i_err_disable_cause {
    my $cps = shift;
    my $ret;
    my $causes = $cps->cerr_i_cause() || {};
    foreach my $interfacevlan (keys %$causes) {
        my ($iid, $vid) = split(/\./, $interfacevlan);
        $ret->{$iid} = $causes->{$interfacevlan};
    }
    return $ret;
}

1;
__END__

=head1 NAME

SNMP::Info::CiscoPortSecurity - SNMP Interface to data from
F<CISCO-PORT-SECURITY-MIB>, F<CISCO-PAE-MIB> and F<CISCO-ERR-DISABLE-MIB>.

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $cps = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $cps->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

SNMP::Info::CiscoPortSecurity is a subclass of SNMP::Info that provides
an interface to the F<CISCO-PORT-SECURITY-MIB>, F<CISCO-PAE-MIB> and
F<CISCO-ERR-DISABLE-MIB>. These MIBs are used across the Catalyst
family under CatOS and IOS.

Use or create in a subclass of SNMP::Info.  Do not use directly.

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item F<CISCO-PORT-SECURITY-MIB>

=item F<CISCO-PAE-MIB>

=item F<IEEE8021-PAE-MIB>

=item F<CISCO-ERR-DISABLE-MIB>

=back

=head1 GLOBALS

These are methods that return scalar values from SNMP

=head2 F<CISCO-PORT-SECURITY-MIB> globals

=over

=item $cps->cps_clear()

(C<cpsGlobalClearSecureMacAddresses>)

=item $cps->cps_notify()

(C<cpsGlobalSNMPNotifControl>)

=item $cps->cps_rate()

(C<cpsGlobalSNMPNotifRate>)

=item $cps->cps_enable()

(C<cpsGlobalPortSecurityEnable>)

=item $cps->cps_mac_count()

(C<cpsGlobalTotalSecureAddress>)

=item $cps->cps_mac_max()

(C<cpsGlobalMaxSecureAddress>)

=back

=head1 TABLE METHODS

=head2 C<CISCO-PORT-SECURITY-MIB> - Interface Config Table

=over

=item $cps->cps_i_limit_val()

(C<cpsIfInvalidSrcRateLimitValue>)

=item $cps->cps_i_limit()

(C<cpsIfInvalidSrcRateLimitEnable>)

=item $cps->cps_i_sticky()

(C<cpsIfStickyEnable>)

=item $cps->cps_i_clear_type()

(C<cpsIfClearSecureMacAddresses>)

=item $cps->cps_i_shutdown()

(C<cpsIfShutdownTimeout>)

=item $cps->cps_i_flood()

(C<cpsIfUnicastFloodingEnable>)

=item $cps->cps_i_clear()

(C<cpsIfClearSecureAddresses>)

=item $cps->cps_i_mac()

(C<cpsIfSecureLastMacAddress>)

=item $cps->cps_i_count()

(C<cpsIfViolationCount>)

=item $cps->cps_i_action()

(C<cpsIfViolationAction>)

=item $cps->cps_i_mac_static()

(C<cpsIfStaticMacAddrAgingEnable>)

=item $cps->cps_i_mac_type()

(C<cpsIfSecureMacAddrAgingType>)

=item $cps->cps_i_mac_age()

(C<cpsIfSecureMacAddrAgingTime>)

=item $cps->cps_i_mac_count()

(C<cpsIfCurrentSecureMacAddrCount>)

=item $cps->cps_i_mac_max()

(C<cpsIfMaxSecureMacAddr>)

=item $cps->cps_i_status()

(C<cpsIfPortSecurityStatus>)

=item $cps->cps_i_enable()

(C<cpsIfPortSecurityEnable>)

=back

=head2 C<CISCO-PORT-SECURITY-MIB::cpsIfVlanTable>

=over

=item $cps->cps_i_v_mac_count()

(C<cpsIfVlanCurSecureMacAddrCount>)

=item $cps->cps_i_v_mac_max()

(C<cpsIfVlanMaxSecureMacAddr>)

=back

=head2 C<CISCO-PORT-SECURITY-MIB::cpsIfVlanSecureMacAddrTable>

=over

=item $cps->cps_i_v_mac_status()

(C<cpsIfVlanSecureMacAddrRowStatus>)

=item $cps->cps_i_v_mac_age()

(C<cpsIfVlanSecureMacAddrRemainAge>)

=item $cps->cps_i_v_mac_type()

(C<cpsIfVlanSecureMacAddrType>)

=back

=head2 C<CISCO-PORT-SECURITY-MIB::cpsSecureMacAddressTable>

=over

=item $cps->cps_m_status()

(C<cpsSecureMacAddrRowStatus>)

=item $cps->cps_m_age()

(C<cpsSecureMacAddrRemainingAge>)

=item $cps->cps_m_type()

(C<cpsSecureMacAddrType>)

=back

=head2 C<IEEE8021-PAE-MIB::dot1xPaePortEntry>

=over

=item $cps->pae_i_capabilities()

C<dot1xPaePortCapabilities>

Indicates the PAE functionality that this Port supports
and that may be managed through this MIB munged to return either
C<'dot1xPaePortAuthCapable'> or C<'dot1xPaePortSuppCapable'>.

=item $cps->pae_i_last_eapol_frame_source()

C<dot1xAuthLastEapolFrameSource>

The source MAC address carried in the most recently received EAPOL frame.

=back

=head2 C<CISCO-ERR-DISABLE-MIB::cErrDisableIfStatusEntry>

=over

=item $cps->cerr_i_cause()

C<cErrDisableIfStatusCause>

Indicates the feature/event that caused the {interface, vlan} (or the entire
interface) to be error-disabled.

=back

=head1 METHODS

=over

=item C<i_err_disable_cause>

Returns a HASH reference mapping ifIndex to err-disabled cause. The returned
data is sparse, so if the ifIndex is not present in the return value, the port
is not err-disabled.

=back

=head1 Data Munging Callback Subroutines

=over

=item $cps->munge_pae_capabilities()

Return either C<'dot1xPaePortAuthCapable'> or C<'dot1xPaePortSuppCapable'>
based upon bit value.

=back

=cut
