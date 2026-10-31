# SNMP::Info::Layer3::VOSS
#
# Copyright (c) 2026 The SNMP::Info Developers
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

package SNMP::Info::Layer3::VOSS;

use strict;
use warnings;
use Exporter;
use SNMP::Info::RapidCityVRF;
use SNMP::Info::RapidCity;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::VOSS::ISA
    = qw/SNMP::Info::RapidCityVRF SNMP::Info::RapidCity
    SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::VOSS::EXPORT_OK = qw//;

our ( $VERSION, %GLOBALS, %FUNCS, %MIBS, %MUNGE );

$VERSION = '3.984000';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::RapidCity::MIBS,
    %SNMP::Info::RapidCityVRF::MIBS,
    'EXTREME-BASE-MIB' => 'extremeAgent',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::RapidCity::GLOBALS,
    %SNMP::Info::RapidCityVRF::GLOBALS,
    'mac' => 'dot1dBaseBridgeAddress',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::RapidCity::FUNCS,
    %SNMP::Info::RapidCityVRF::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::RapidCity::MUNGE,
    %SNMP::Info::RapidCityVRF::MUNGE,
);

sub vendor {
    return 'extreme';
}

sub os {
    return 'voss';
}

# VOSS / Fabric Engine sysDescr is "<model> (<a.b.c.d>[_build])"
sub os_ver {
    my $voss  = shift;
    my $descr = $voss->description();
    return unless defined $descr;

    if ( $descr =~ m/^\S+\s+\((\d+(?:\.\d+){3})/ ) {
        return $1;
    }

    return;
}

# Returns the sysObjectID unchanged when EXTREME-BASE-MIB does not name it,
# as Layer3::Extreme did for these devices
sub model {
    my $voss = shift;
    my $id   = $voss->id();
    return unless defined $id;

    my $model = &SNMP::translateObj($id);

    return defined $model ? $model : $id;
}

# Not rcChasSerialNumber, which RapidCity::serial reads: the entity table,
# then Layer3's serial1 (OLD-CISCO-CHASSIS-MIB chassisId). Layer3::Extreme
# read extremeSystemID as serial1 instead; both are empty on every VOSS walk
# checked, so the answers match there
sub serial {
    my $voss = shift;

    return $voss->SNMP::Info::Layer3::serial(@_);
}

# ifName is a nice concise port name on Fabric Engine, but a router
# interface's ifName holds its IP address, so ifDescr names those
sub interfaces {
    my $voss          = shift;
    my $partial       = shift;
    my $i_name        = $voss->orig_i_name($partial);
    my $i_description = $voss->orig_i_description($partial);
    my $interfaces    = {};
    foreach my $idx ( keys %$i_name ) {
        if ( $i_name->{$idx} =~ /\([0-9.]+\)/ ) {
            $interfaces->{$idx} = $i_description->{$idx};
        }
        else {
            $interfaces->{$idx} = $i_name->{$idx};
        }
    }
    return $interfaces;
}

# Fabric Engine bridge port numbers are ifIndexes
sub bp_index {
    my $voss = shift;

    my $bindex = $voss->SUPER::bp_index();
    return $bindex if ( ref {} eq ref $bindex and keys %$bindex );

    my $if_index = $voss->i_index();

    my %bp_index;
    foreach my $iid ( keys %$if_index ) {
        $bp_index{$iid} = $iid;
    }
    return \%bp_index;
}

# Q-BRIDGE first, as Layer3::Extreme read it: some releases serve no
# rcVlanPortTable. RapidCity answers where Q-BRIDGE lists nothing.
sub i_vlan {
    my $voss = shift;

    return _rows_or_undef( $voss->SNMP::Info::Layer3::i_vlan(@_) )
        // _rows_or_undef( $voss->SUPER::i_vlan(@_) );
}

sub i_vlan_membership {
    my $voss = shift;

    return _rows_or_undef( $voss->SNMP::Info::Layer3::i_vlan_membership(@_) )
        // _rows_or_undef( $voss->SUPER::i_vlan_membership(@_) );
}

# RapidCity lists every port, with no value for one with no untagged VLAN
sub i_vlan_membership_untagged {
    my $voss = shift;

    return _rows_or_undef(
        $voss->SNMP::Info::Layer3::i_vlan_membership_untagged(@_) )
        // _rows_or_undef(
        _rows_with_values( $voss->SUPER::i_vlan_membership_untagged(@_) ) );
}

sub _rows_with_values {
    my $rows = shift;

    return unless ref {} eq ref $rows;
    return {
        map  { $_ => $rows->{$_} }
        grep { defined $rows->{$_} } keys %$rows
    };
}

sub _rows_or_undef {
    my $rows = shift;

    return $rows if ref {} eq ref $rows and keys %$rows;
    return;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer3::VOSS - SNMP Interface to Extreme VOSS / Fabric Engine
switches

=head1 AUTHOR

SNMP::Info Developers

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $voss = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $voss->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Extreme VOSS (Virtual Services Platform Operating System
Software) and Fabric Engine switches, including the VSP 4000, 7000 and 8000
series, the 5520 and the XA series.

This class is chosen for VOSS sysDescr values (C<model (a.b.c.d)>) under the
Extreme enterprise (1916). VOSS releases that report enterprise 2272 stay in
L<SNMP::Info::Layer3::Passport>, which names ports C<slot.port> for SONMP
matching. This class has no SONMP role.

Interface names, the model, the serial and the OS identity are the ones
L<SNMP::Info::Layer3::Extreme> reported for these devices before this class
existed, so a stored port history keeps matching.

=head2 Inherited Classes

=over

=item SNMP::Info::RapidCityVRF

=item SNMP::Info::RapidCity

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<EXTREME-BASE-MIB>

=back

=head2 Inherited MIBs

See L<SNMP::Info::RapidCityVRF/"Required MIBs"> for its MIB requirements.

See L<SNMP::Info::RapidCity/"Required MIBs"> for its MIB requirements.

See L<SNMP::Info::Layer3/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar values from SNMP

=over

=item $voss->vendor()

Returns C<extreme>.

=item $voss->os()

Returns C<voss>.

=item $voss->os_ver()

Returns the C<a.b.c.d> release from sysDescr, without any build suffix.

=item $voss->model()

Returns the name F<EXTREME-BASE-MIB> gives the sysObjectID, or the
sysObjectID itself when the MIB does not name it.

=item $voss->mac()

Returns the bridge MAC address.

(C<dot1dBaseBridgeAddress>)

=back

=head2 Overrides

=over

=item $voss->serial()

Returns the serial from the entity table or C<serial1>, as
L<SNMP::Info::Layer3> does. C<rcChasSerialNumber> is available as
C<rc_serial()>.

=back

=head2 Global Methods imported from SNMP::Info::RapidCityVRF

See L<SNMP::Info::RapidCityVRF/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::RapidCity

See L<SNMP::Info::RapidCity/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

=head2 Overrides

=over

=item $voss->interfaces()

Returns reference to the map between IID and physical Port.

Uses C<ifName>, for example C<1/1>. An interface whose C<ifName> holds an IP
address in brackets is named by C<ifDescr>.

=item $voss->bp_index()

Returns reference to hash of bridge port table entries map back to interface
identifier (iid)

Uses BRIDGE-MIB where it is served. Otherwise each ifIndex is its own bridge
port.

=item $voss->i_vlan()

Returns reference to hash of port to default VLAN from Q-BRIDGE, else from
C<rcVlanPortDefaultVlanId>. Undef when the device lists none.

=item $voss->i_vlan_membership()

Returns reference to hash of arrays: key = ifIndex, value = array of VLAN
IDs, from Q-BRIDGE, else from C<rcVlanPortMembers>. Undef when the device
lists none.

=item $voss->i_vlan_membership_untagged()

Returns reference to hash of arrays: key = ifIndex, value = array of VLAN
IDs the port sends untagged, from Q-BRIDGE, else from RAPID-CITY. A port with
none has no row. Undef when no port has any.

=back

=head2 Table Methods imported from SNMP::Info::RapidCityVRF

See L<SNMP::Info::RapidCityVRF/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::RapidCity

See L<SNMP::Info::RapidCity/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
