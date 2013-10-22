# SNMP::Info::Layer3::Altiga
# $Id$
#
# Copyright (c) 2008 Jeroen van Ingen Schenau
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

package SNMP::Info::Layer3::Altiga;

use strict;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Altiga::ISA = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Altiga::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE 
            $int_include_vpn $fake_idx $type_class/;

$VERSION = '3.08';

%MIBS = (
            %SNMP::Info::Layer3::MIBS,
            'ALTIGA-VERSION-STATS-MIB'  => 'alVersionString',
            'ALTIGA-SESSION-STATS-MIB'  => 'alActiveSessionCount',
            'ALTIGA-HARDWARE-STATS-MIB' => 'alHardwarePs1Type',  
    );

%GLOBALS = (
            %SNMP::Info::Layer3::GLOBALS,
            # From ALTIGA-VERSION-STATS-MIB
            'os_ver'          => 'alVersionString',
            # From ALTIGA-SESSION-STATS-MIB
            'vpn_act_sess'    => 'alActiveSessionCount',
            'vpn_total_sess'  => 'alTotalSessionCount',
            'vpn_max_sess'    => 'alMaxSessionCount',
            'vpn_l2l_sess'    => 'alActiveLanToLanSessionCount',
            'vpn_mgmt_sess'   => 'alActiveManagementSessionCount',
            'vpn_ras_sess'    => 'alActiveRemoteAccessSessionCount',
            # From ALTIGA-HARDWARE-STATS-MIB
            'ps1_type'        => 'alHardwarePs1Type',
            'ps1_3v_alarm'    => 'alHardwarePs1Voltage3vAlarm',
            'ps1_5v_alarm'    => 'alHardwarePs1Voltage5vAlarm',
            'ps2_type'        => 'alHardwarePs2Type',
            'ps2_3v_alarm'    => 'alHardwarePs2Voltage3vAlarm',
            'ps2_5v_alarm'    => 'alHardwarePs2Voltage5vAlarm',
            'fan1_alarm'      => 'alHardwareFan1RpmAlarm',
            'fan2_alarm'      => 'alHardwareFan2RpmAlarm',
            'fan3_alarm'      => 'alHardwareFan3RpmAlarm',
            
       );

%FUNCS = (
            %SNMP::Info::Layer3::FUNCS,
            'i_type2'           => 'ifType',
            'i_lastchange2'     => 'ifLastChange',
            'vpn_sess_status'   => 'alActiveSessionRowStatus',
            'vpn_sess_user'     => 'alActiveSessionUserName',
            'vpn_sess_peer_ip'  => 'alActiveSessionIpAddress',
            'vpn_sess_protocol' => 'alActiveSessionProtocol',
            'vpn_sess_encr'     => 'alActiveSessionEncrType',
            'vpn_sess_start'    => 'alActiveSessionStartTime',
            'vpn_sess_conntime' => 'alActiveSessionConnectTime',
            'vpn_sess_out_oct'  => 'alActiveSessionOctetsSent',
            'vpn_sess_in_oct'   => 'alActiveSessionOctetsRcvd',
            'vpn_sess_group'    => 'alActiveSessionGroupName',
            'vpn_sess_gid'      => 'alActiveSessionGroupId',
            'vpn_sess_rem_ip'   => 'alActiveSessionPublicIpAddress',
     );

%MUNGE = (
            %SNMP::Info::Layer3::MUNGE,
            'ps1_3v_alarm'    => \&munge_alarm,
            'ps1_5v_alarm'    =>  \&munge_alarm,
            'ps2_3v_alarm'    =>  \&munge_alarm,
            'ps2_5v_alarm'    =>  \&munge_alarm,
            'fan1_alarm'      =>  \&munge_alarm,
            'fan2_alarm'      =>  \&munge_alarm,
            'fan3_alarm'      =>  \&munge_alarm,

     );

# Variable to modify behaviour of "interfaces" subroutine.
# * When set to 0, "interfaces" returns only fixed interfaces from the IF-MIB,
# * When set to 1, "interfaces" returns fixed interfaces from IF-MIB and LAN-to-LAN tunnels from ALTIGA-SESSION-MIB
# TODO: This should be an instance method, not a class global
$int_include_vpn = 1;

# Variable to prepended to each tunnel index when tunnel is added to %interfaces, to avoid overwriting "real" ifIndex entries
$fake_idx = 3076;

# Variable to classify session types into categories: 0 - unclassified, 1 - LAN-to-LAN or fixed, 2 - RAS or dynamic, 3 - administrative
$type_class = {
    'pptp'                  => 2,
    'l2tp'                  => 2,
    'ipsec'                 => 2,
    'http'                  => 3,
    'ftp'                   => 3,
    'telnet'                => 3,
    'snmp'                  => 3,
    'tftp'                  => 3,
    'console'               => 3,
    'debugTelnet'           => 3,
    'debugConsole'          => 3,
    'other'                 => 3,
    'ike'                   => 0,
    'l2tpOverIpSec'         => 2,
    'ipsecLanToLan'         => 1,
    'ipsecOverUdp'          => 2,
    'ssh'                   => 3,
    'vcaLanToLan'           => 1,
    'ipsecOverTcp'          => 2,
    'pppoe'                 => 2,
    'ipsecOverNatT'         => 2,
    'ipsecLan2LanOverNatT'  => 1,
    'l2tpOverIpsecOverNatT' => 2,
    'userHttps'             => 2,
    'pop3s'                 => 2,
    'imap4s'                => 2,
    'smtps'                 => 2,
    'httpsTunnel'           => 2,
};

sub vendor {
    return 'altiga';
}

sub os {
    return 'altiga';
}

# $altiga->interfaces() - Map the Interfaces to their physical names
# Add interface number to interface name to prevent duplicate ifDescr
# Included statically configured VPN tunnels if ($int_include_vpn)
sub interfaces {
    my $altiga = shift;
    my $partial = shift;

    my $interfaces = $altiga->i_index($partial);
    my $descriptions = $altiga->i_description($partial);

    my %int_rev = ();
    my %interfaces = ();
    foreach my $iid (sort {$a cmp $b} keys %$interfaces) {
        my $desc = $descriptions->{$iid};
        next unless defined $desc;
        if (!exists $int_rev{$desc}) {
            $interfaces{$iid} = $desc;
            $int_rev{$desc} = $iid;
        } else {
            my $done = 0;
            my $unique_desc;
            my $cnt = 1;
            until ($done) {
                $cnt++;
                $unique_desc = sprintf("%s (%d)", $desc, $cnt);
                if (!exists $int_rev{$unique_desc}) {
                    $done++;
                }
            }
            $int_rev{$unique_desc} = $iid;
            $interfaces{$iid} = $unique_desc;
            $interfaces{ $int_rev{$desc} } = sprintf("%s (%d)", $desc, 1);
        }
    }
    if ($int_include_vpn) {
        my $tun_type = $altiga->vpn_sess_protocol();
        my $peer = $altiga->vpn_sess_peer_ip();
        my $remote = $altiga->vpn_sess_rem_ip(); 
        my $group = $altiga->vpn_sess_gid();
        foreach my $tunnel (keys %$tun_type) {
            if ($type_class->{$tun_type->{$tunnel}} eq 1) {
                $interfaces{"$fake_idx.$tunnel"} = sprintf("%s VPN to %s", uc($tun_type->{$tunnel}), $remote->{$tunnel});
            }
        }
    }
            
    return \%interfaces;
}

sub i_type {
    my $altiga = shift;
    my $partial = shift;
    my $types = $altiga->i_type2();
    if ($int_include_vpn) {
        my $tun_type = $altiga->vpn_sess_protocol();
        foreach my $tunnel (keys %$tun_type) {
            $types->{"$fake_idx.$tunnel"} = $tun_type->{$tunnel};
        }
    }
    return $types;
}

sub i_lastchange {
    my $altiga = shift;
    my $partial = shift;

    # TODO: This is what munges are for.
    my $lastchange = $altiga->i_lastchange2();
    if ($int_include_vpn) {
        my $tun_start = $altiga->vpn_sess_start();
        foreach my $tunnel (keys %$tun_start) {
            $lastchange->{"$fake_idx.$tunnel"} = $tun_start->{$tunnel};
        }
    }
    return $lastchange;
}

sub ps1_status {
    my $altiga = shift;
    my $alarm_3v = $altiga->ps1_3v_alarm() || "";
    my $alarm_5v = $altiga->ps1_5v_alarm() || "";
    return sprintf("3V: %s, 5V: %s", $alarm_3v, $alarm_5v);
}

sub ps2_status {
    my $altiga = shift;
    my $alarm_3v = $altiga->ps2_3v_alarm() || "";
    my $alarm_5v = $altiga->ps2_5v_alarm() || "";
    return sprintf("3V: %s, 5V: %s", $alarm_3v, $alarm_5v);
}

sub fan {
    my $altiga = shift;
    my $alarm_fan1 = $altiga->fan1_alarm() || "";
    my $alarm_fan2 = $altiga->fan2_alarm() || "";
    my $alarm_fan3 = $altiga->fan3_alarm() || "";
    return sprintf("Fan 1: %s, Fan 2: %s, Fan 3: %s", $alarm_fan1, $alarm_fan2, $alarm_fan3);
}

sub munge_alarm {
    my $alarm = shift;
    if ($alarm eq 'false') {
        return 'OK';
    } elsif ($alarm eq 'true') {
        return 'FAIL';
    } else {
        return "(n/a)";
    }
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Altiga - SNMP Interface to Cisco (formerly Altiga) VPN concentrators

=head1 AUTHOR

Jeroen van Ingen Schenau

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $altiga = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'my_vpn_host',
                          Community   => 'public',
                          Version     => 1
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $altiga->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Cisco (formerly Altiga) VPN concentrators

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=back

=head1 Class Variables (options)

=over

=item $SNMP::Info::Layer3::Altiga::int_include_vpn

Variable to modify behavior of "interfaces" subroutine.

  * When set to 0, "interfaces" returns only fixed interfaces from the IF-MIB,
  * When set to 1, "interfaces" returns fixed interfaces from IF-MIB and
    LAN-to-LAN tunnels from ALTIGA-SESSION-MIB (default)

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $altiga->vendor()

Returns 'altiga'

=item $altiga->os()

Returns 'altiga'

=item $altiga->os_ver()

Tries to determine OS version from the C<sysDescr.0> field. Returns version or C<sysDescr.0>

=item $altiga->fan()

Combines results from C<fan1_alarm>, C<fan2_alarm>, and C<fam3_alarm> methods.

=item $altiga->ps1_status()

Combines C<ps1_3v_alarm> and C<ps1_5v_alarm> methods.

=item $altiga->ps2_status()

Combines C<ps2_3v_alarm> and C<ps2_5v_alarm> methods.

=back

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $altiga->interfaces()

This method overrides the interfaces() method inherited from SNMP::Info.
It provides a mapping between the Interface Table Index (iid) and the physical 
port name, adding a port number to the port name to prevent duplicate names.

=item $altiga->i_lastchange()

Filters out the results depending on the value of $SNMP::Info::Layer3::Altiga::int_include_vpn

=item $altiga->i_type()

Filters out the results depending on the value of $SNMP::Info::Layer3::Altiga::int_include_vpn

=back

=head1 MUNGES

=over

=item munge_alarm()

Changes C<true> and C<false> to C<FAIL>, C<OK>, and C<(n/a)>.

=back

=cut
