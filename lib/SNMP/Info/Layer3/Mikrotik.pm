# SNMP::Info::Layer3::Mikrotik
#
# Copyright (c) 2011 Jeroen van Ingen
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

package SNMP::Info::Layer3::Mikrotik;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Mikrotik::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Mikrotik::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.978002';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'HOST-RESOURCES-MIB'       => 'hrSystem',
    'MIKROTIK-MIB'             => 'mtxrLicVersion',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'hrSystemUptime' => 'hrSystemUptime',
    'os_level'       => 'mtxrLicLevel',
    'os_ver'         => 'mtxrLicVersion',
    'serial1'        => 'mtxrSystem.3.0',
    'firmware'       => 'mtxrSystem.4.0',
    'fan_type'       => 'mtxrHlActiveFan',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
);

sub vendor {
    return 'mikrotik';
}

sub serial {
    my $mikrotik = shift;
    return $mikrotik->serial1;
}

sub model {
    my $mikrotik = shift;
    my $descr = $mikrotik->description() || '';
    my $model = undef;
    $model = $1 if ( $descr =~ /^RouterOS\s+(\S+)$/i );
    $model = $1 if ( $descr =~ /^RouterOS\s+(RB .*)$/i );
    return $model;
}

sub os {
    return 'routeros';
}

sub board_temp {
    my $mikrotik = shift;
    my $temp = $mikrotik->mtxrHlTemperature;
    return $temp / 10.0;
}

sub cpu_temp {
    my $mikrotik = shift;
    my $temp = $mikrotik->mtxrHlProcessorTemperature;
    return $temp / 10.0;
}

# RouterOS returns MAC chassis IDs as text ("0C:00:1E:5A:27:00") rather than
# the six octets LLDP-MIB defines, which munge_mac() rejects.
sub _lldp_id_string {
    my ( $mikrotik, $id, $type ) = @_;

    return lc $id
        if $type =~ /mac/ and $id =~ /^(?:[0-9A-F]{2}:){5}[0-9A-F]{2}$/i;
    return $mikrotik->SUPER::_lldp_id_string( $id, $type );
}

# ifPhysAddress.1 is the loopback, all zeros. The chassis MAC is what LLDP
# neighbors report as c_id, so Netdisco can match them to this device.
sub mac {
    my $mikrotik = shift;

    my $chassis
        = $mikrotik->lldp_loc_id_type() ? $mikrotik->lldp_loc_id() : undef;
    return $chassis || $mikrotik->SUPER::mac();
}

# RouterOS advertises only addresses on the sending port or its bridge. A
# neighbor managed on a VLAN interface has no IPv4 address, so return
# 0.0.0.0, which Netdisco resolves by looking up c_id among known devices.
sub c_ip {
    my ( $mikrotik, $partial, $topo_cap ) = @_;

    my $c_ip = $mikrotik->SUPER::c_ip( $partial, $topo_cap ) || {};
    my $c_id = $mikrotik->c_id( $partial, $topo_cap )        || {};
    foreach my $iid ( keys %$c_id ) {
        $c_ip->{$iid} = '0.0.0.0' unless defined $c_ip->{$iid};
    }
    return $c_ip;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Mikrotik - SNMP Interface to Mikrotik devices

=head1 AUTHORS

Jeroen van Ingen
initial version based on SNMP::Info::Layer3::NetSNMP by Bradley Baetz and Bill Fenner

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $mikrotik = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $mikrotik->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Mikrotik devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<HOST-RESOURCES-MIB>

=item F<MIKROTIK-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $mikrotik->vendor()

Returns C<'mikrotik'>.

=item $mikrotik->os()

Returns C<'routeros'>.

=item $mikrotik->model()

Tries to extract the device model from C<sysDescr>.

=item $mikrotik->os_ver()

Returns the value of C<mtxrLicVersion>.

=item $mikrotik->os_level()

Returns the value of RouterOS level C<mtxrLicLevel>

=item $mikrotik->board_temp()

=item $mikrotik->cpu_temp()

Returns the appropriate temperature values

=item $mikrotik->serial()

Returns the device serial.

=item $mikrotik->firmware()

Returns the firmware version of hardware.

=item $mikrotik->mac()

Returns the LLDP chassis MAC (C<lldp_loc_id()>). C<ifPhysAddress.1> is the
loopback on RouterOS and reads as all zeros; it is used only when there is
no LLDP chassis ID.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $mikrotik->c_ip()

Returns C<0.0.0.0> for an LLDP neighbor that has a chassis ID but advertises
no IPv4 management address, so Netdisco can resolve it by C<c_id()>. RouterOS
advertises only addresses on the sending port or its bridge, not on VLAN
interfaces.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=cut
