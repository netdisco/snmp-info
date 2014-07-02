# SNMP::Info::MAU - Media Access Unit - RFC 2668
# $Id$
#
# Copyright (c) 2008 Max Baker changes from version 0.8 and beyond.
#
# Copyright (c) 2002,2003 Regents of the University of California
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

package SNMP::Info::MAU;

use strict;
use Exporter;
use SNMP::Info;

@SNMP::Info::MAU::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::MAU::EXPORT_OK = qw//;

use vars qw/$VERSION %MIBS %FUNCS %GLOBALS %MUNGE/;

$VERSION = '3.18';

%MIBS = ( 'MAU-MIB' => 'mauMod', 'IANA-MAU-MIB' => 'dot3MauType' );

%GLOBALS = ();

%FUNCS = (

    # Interface MAU Table
    'mau_index'      => 'ifMauIfIndex',
    'mau_link'       => 'ifMauType',
    'mau_status'     => 'ifMauStatus',
    'mau_up'         => 'ifMauMediaAvailable',
    'mau_type'       => 'ifMauTypeList',
    'mau_type_admin' => 'ifMauDefaultType',

    # Interface Auto-Negotiation Table
    'mau_auto'     => 'ifMauAutoNegSupported',
    'mau_autostat' => 'ifMauAutoNegAdminStatus',
    'mau_autosent' => 'ifMauAutoNegCapAdvertised',
    'mau_autorec'  => 'ifMauAutoNegCapReceived',
);

%MUNGE = (

    # Inherit all the built in munging
    %SNMP::Info::MUNGE,

    # Add ones for our class
    'mau_type'     => \&munge_int2bin,
    'mau_autosent' => \&munge_int2bin,
    'mau_autorec'  => \&munge_int2bin,
);

sub munge_int2bin {
    my $int = shift;
    return unless defined $int;
    return unpack( "B32", pack( "N", $int ) );
}

sub _isfullduplex {
    my $mau     = shift;
    my $mautype = shift;

    my @full_types = qw/11 13 16 18 20/;
    foreach my $type (@full_types) {
        return 1 if ( substr( $mautype, 32 - $type, 1 ) eq '1' );
    }
    return 0;
}

sub _ishalfduplex {
    my $mau     = shift;
    my $mautype = shift;

    my @half_types = qw/10 12 15 17 19/;
    foreach my $type (@half_types) {
        return 1 if ( substr( $mautype, 32 - $type, 1 ) eq '1' );
    }
    return 0;
}

my %_mau_i_speed_map = (
    '10'    => '10 Mbps',
    '100'   => '100 Mbps',
    '1000'  => '1.0 Gbps',
    '10Gig' => '10 Gbps',
);

sub mau_i_speed_admin {
    my $mau = shift;

    my $mau_index      = $mau->mau_index();
    my $mau_type_admin = $mau->mau_type_admin();

    my %i_speed_admin;
    foreach my $mau_port ( keys %$mau_type_admin ) {
        my $iid = $mau_index->{$mau_port};
        next unless defined $iid;

        my $type_adminoid = $mau_type_admin->{$mau_port};
        my $type_admin    = &SNMP::translateObj($type_adminoid);
        next unless defined $type_admin;

        if ( $type_adminoid eq '.0.0' ) {
            $i_speed_admin{$iid} = 'auto';
        }
        elsif ($type_admin =~ /^dot3MauType(.*)Base/
            && $_mau_i_speed_map{$1} )
        {
            $i_speed_admin{$iid} = $_mau_i_speed_map{$1};
        }
    }
    return \%i_speed_admin;
}

sub mau_i_duplex {
    my $mau = shift;

    my $mau_index = $mau->mau_index();
    my $mau_link  = $mau->mau_link();

    my %i_duplex;
    foreach my $mau_port ( keys %$mau_link ) {
        my $iid = $mau_index->{$mau_port};
        next unless defined $iid;

        my $linkoid = $mau_link->{$mau_port};
        my $link    = &SNMP::translateObj($linkoid);
        next unless defined $link;

        my $duplex = undef;

        if ( $link =~ /fd$/i ) {
            $duplex = 'full';
        }
        elsif ( $link =~ /hd$/i ) {
            $duplex = 'half';
        }

        $i_duplex{$iid} = $duplex if defined $duplex;
    }
    return \%i_duplex;
}

sub mau_i_duplex_admin {
    my $mau     = shift;
    my $partial = shift;

    my $mau_index = $mau->mau_index() || {};

    if ($partial) {
        my %rev_mau_index = reverse %$mau_index;
        $partial = $rev_mau_index{$partial};
    }

    my $mau_autostat   = $mau->mau_autostat($partial)   || {};
    my $mau_type_admin = $mau->mau_type_admin($partial) || {};

    # Older HP4000's don't implement ifMauDefaultType, but we can
    # figure out from ifMauAutoNegCapAdvertised what we'd like.
    if ( !defined($mau_type_admin) ) {
        if ( defined($mau_index) ) {
            return mau_i_duplex_admin_old( $mau, $mau_index, $mau_autostat );
        }
        else {
            return;
        }
    }

    my %i_duplex_admin;
    foreach my $mau_port ( keys %$mau_type_admin ) {
        my $iid = $mau_index->{$mau_port};
        next unless defined $iid;

        my $autostat = $mau_autostat->{$mau_port};
        if ( defined $autostat and $autostat =~ /enabled/i ) {
            $i_duplex_admin{$iid} = 'auto';
            next;
        }

        my $type_adminoid = $mau_type_admin->{$mau_port};
        my $type_admin    = &SNMP::translateObj($type_adminoid);
        next unless defined $type_admin;

        my $duplex = undef;

        if ( $type_admin =~ /fd$/i ) {
            $duplex = 'full';
        }
        elsif ( $type_admin =~ /hd$/i ) {
            $duplex = 'half';
        }
        elsif ( $type_admin eq 'zeroDotZero' ) {
            $duplex = 'auto';
        }

        $i_duplex_admin{$iid} = $duplex if defined $duplex;
    }
    return \%i_duplex_admin;
}

sub mau_i_duplex_admin_old {
    my $mau          = shift;
    my $mau_index    = shift;
    my $mau_autostat = shift;

    my $interfaces   = $mau->interfaces();
    my $mau_autosent = $mau->mau_autosent();

    my %mau_reverse = reverse %$mau_index;

    my %i_duplex_admin;
    foreach my $iid ( keys %$interfaces ) {
        my $mau_idx = $mau_reverse{$iid};
        next unless defined $mau_idx;

        my $autostat = $mau_autostat->{$mau_idx};

        # HP25xx has this value
        if ( defined $autostat and $autostat =~ /enabled/i ) {
            $i_duplex_admin{$iid} = 'auto';
            next;
        }

        my $type = $mau_autosent->{$mau_idx};

        next unless defined $type;

        if ( $type == 0 ) {
            $i_duplex_admin{$iid} = 'none';
            next;
        }

        my $full = $mau->_isfullduplex($type);
        my $half = $mau->_ishalfduplex($type);

        if ( $full && !$half ) {
            $i_duplex_admin{$iid} = 'full';
        }
        elsif ($half) {
            $i_duplex_admin{$iid} = 'half';
        }
    }

    return \%i_duplex_admin;
}

sub mau_set_i_speed_admin {
    my $mau          = shift;
    my $speed    = shift;
    my $iid = shift;

    my $rv;

    $speed = lc($speed);
    if ( !( $speed =~ /(10|100|1000|auto)/io and $iid =~ /\d+/o ) ) {
        return;
    }

    # map a speed value to an integer the switch understands based on duplex
    my %speeds;

    # 10 = dot3MauType10BaseTHD, 15 = dot3MauType100BaseTXHD
    # 29 = dot3MauType1000BaseTHD from IANA-MAU-MIB
    %{ $speeds{'HD'} } = qw/10 10 100 15 1000 29/;    # half duplex settings
         # 11 = dot3MauType10BaseTFD, 16 = dot3MauType100BaseTXFD
         # 30 = dot3MauType1000BaseTFD from IANA-MAU-MIB
    %{ $speeds{'FD'} } = qw/10 11 100 16 1000 30/;    # full duplex settings

    my $myhash    = $mau->mau_autostat;
    my $key       = $iid . '.1';
    my $i_autoneg = $myhash->{$key};

    my $myduplex;

    my $i_mau_def_type
        = &SNMP::translateObj( $mau->mau_type_admin($iid)->{ $iid . '.1' } );

    if ( $i_mau_def_type =~ /^dot3MauType.*Base.*(..)$/
        && ( $1 eq "HD" or $1 eq "FD" ) )
    {
        $myduplex = $1;
    }
    else {

        # this is not a valid speed known, assuming auto
        $myduplex = "auto";
    }

    if ( $speed eq "auto" && $i_autoneg eq "enabled" ) {
        return (1);
    }
    elsif ( $speed eq "auto" ) {
        $rv = $mau->set_mau_autostat( 'enabled', $iid . '.1' );
        return ($rv);
    }
    else {
        if ( $i_autoneg eq "enabled" ) {
            $mau->set_mau_autostat( 'disabled', $iid . '.1' );
        }
        $rv
            = $mau->set_mau_type_admin(
            '.1.3.6.1.2.1.26.4.' . $speeds{$myduplex}{$speed},
            $iid . '.1' );

        return ($rv);
    }
}

sub mau_set_i_duplex_admin {
    my $mau = shift;
    my $duplex = shift;
    my $iid = shift;

    my $rv;

    $duplex = lc($duplex);

    if ( !( $duplex =~ /(full|half|auto)/i and $iid =~ /\d+/ ) ) {
        return;
    }

 # map a textual duplex setting to an integer value the switch will understand
    my %duplexes;
    %{ $duplexes{'10'} }   = qw/full 11 half 10/;
    %{ $duplexes{'100'} }  = qw/full 16 half 15/;
    %{ $duplexes{'1000'} } = qw/full 30 half 29/;

    # current port values:
    my $myhash    = $mau->mau_autostat;
    my $key       = $iid . '.1';
    my $i_autoneg = $myhash->{$key};

    my $i_speed
        = &SNMP::translateObj( $mau->mau_type_admin($iid)->{ $iid . '.1' } );

    if ( $i_speed =~ /^dot3MauType(.*)Base/ && $_mau_i_speed_map{$1} ) {
        $i_speed = $1;
    }
    else {

        # this is not a valid speed setting, assuming auto
        $duplex = "auto";
    }

    if ( $duplex eq "auto" && $i_autoneg eq "enabled" ) {
        return (1);
    }
    elsif ( $duplex eq "auto" ) {
        $rv = $mau->set_mau_autostat( 'enabled', $iid . '.1' );
        return ($rv);
    }
    else {

        # Can't always do it here, if not...
        if ( $i_autoneg eq "enabled"
            && defined( $duplexes{$i_speed}{$duplex} ) )
        {
            $mau->set_mau_autostat( 'disabled', $iid . '.1' );
        }
        $rv
            = $mau->set_mau_type_admin(
            '.1.3.6.1.2.1.26.4.' . $duplexes{$i_speed}{$duplex},
            $iid . '.1' );
        return ($rv);
    }
}

#
# mau_set_i_speed_duplex_admin() accepts the following values for speed/duplex
#

# auto/auto (special case)
# 10/half
# 10/full
# 100/half
# 100/full
# 1000/half
# 1000/full

sub mau_set_i_speed_duplex_admin {
    my $mau = shift;
    my $speed = shift;
    my $duplex = shift;
    my $iid = shift;

    my $rv;

    $speed  = lc($speed);
    $duplex = lc($duplex);

    if (   ( $speed !~ m/auto|10|100|1000/io )
        or ( $duplex !~ m/full|half|auto/io )
        or ( $iid !~ /\d+/ ) )
    {
        return ("bad arguments");
    }

    # map input speed and duplex paramters to 'mau_type_admin' settings
    # From IANA-MAU-MIB
    # 11 = dot3MauType10BaseTFD, 10 = dot3MauType10BaseTHD,
    # 16 = dot3MauType100BaseTXFD, 15 = dot3MauType100BaseTXHD
    # 30 = dot3MauType1000BaseTFD, 29 = dot3MauType1000BaseTHD
    my %params;
    %{ $params{'10'} }   = qw/full 11 half 10/;
    %{ $params{'100'} }  = qw/full 16 half 15/;
    %{ $params{'1000'} } = qw/full 30 half 29/;

    # if given "auto/auto", set 'mau_autostat' to "enable" and exit

    if ( ( $speed eq "auto" ) or ( $duplex eq "auto" ) ) {
        $rv = $mau->set_mau_autostat( 'enabled', $iid . '.1' );
        return ($rv);
    }

    $rv
        = $mau->set_mau_type_admin(
        '.1.3.6.1.2.1.26.4.' . $params{$speed}{$duplex},
        $iid . '.1' );
    $rv = $mau->set_mau_autostat( 'disabled', $iid . '.1' );
    return ($rv);
}

1;
__END__


=head1 NAME

SNMP::Info::MAU - SNMP Interface to Medium Access Unit (MAU) MIB (RFC 2668)
via SNMP

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 my $mau = new SNMP::Info ( 
                             AutoSpecify => 1,
                             Debug       => 1,
                             DestHost    => 'hpswitch', 
                             Community   => 'public',
                             Version     => 2
                           );
 
 my $class = $mau->class();
 print " Using device sub class : $class\n";

=head1 DESCRIPTION

SNMP::Info::MAU is a subclass of SNMP::Info that supplies access to the
F<MAU-MIB> (RFC 2668). This MIB is sometimes implemented on Layer 2 network
devices like HP Switches.  MAU = Media Access Unit.

The MAU table contains link and duplex info for the port itself and the device
connected to that port.

Normally you use or create a subclass of SNMP::Info that inherits this one.
Do not use directly.

For debugging purposes call the class directly as you would SNMP::Info

 my $mau = new SNMP::Info::MAU(...);

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item F<MAU-MIB>

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item None

=back

=head1 TABLE METHODS

These are methods that return tables of information in the form
of a reference to a hash.

=over

=item $mau->mau_i_duplex()

Parses mau_index and mau_link to return the duplex information for
interfaces.

=item $mau->mau_i_duplex_admin()

Parses C<mac_index>,C<mau_autostat>,C<mau_type_admin> in
order to find the admin duplex setting for all the interfaces.

Returns either (auto,full,half).

=item $mau->mau_i_duplex_admin_old()

Called by mau_i_duplex_admin() if C<mau_type_admin> is empty.
Parses C<mau_index>,C<mau_autostat>,C<mau_autosent> in
order to find the admin duplex setting for all the interfaces.

Returns either (auto,none,full,half).

=item $mau->mau_i_speed_admin()

Returns admin speed setting for all the interfaces.

=back

=head2 MAU Interface Table Methods

=over

=item $mau->mau_index() -  Returns a list of interfaces
and their index in the MAU IF Table.

(C<ifMauIfIndex>)

=item $mau->mau_link() - Returns the type of Media Access used.  

    This is essentially the type of link in use.  
    eg. dot3MauType100BaseTXFD - 100BaseT at Full Duplex

(C<ifMauType>)

=item $mau->mau_status() - Returns the admin link condition as 

    1 - other
    2 - unknown
    3 - operational
    4 - standby
    5 - shutdown
    6 - reset

Use 5 and !5 to see if the link is up or down on the admin side.

(C<ifMauStatus>)

=item $mau->mau_up() -  Returns the current link condition

 (C<ifMauMediaAvailable>)

=item $mau->mau_type() - Returns a 32bit string reporting the capabilities
of the port from a MAU POV. 

  Directly from F<MAU-MIB> : 
          Bit   Capability
            0      other or unknown
            1      AUI
            2      10BASE-5
            3      FOIRL
            4      10BASE-2
            5      10BASE-T duplex mode unknown
            6      10BASE-FP
            7      10BASE-FB
            8      10BASE-FL duplex mode unknown
            9      10BROAD36
           10      10BASE-T  half duplex mode
           11      10BASE-T  full duplex mode
           12      10BASE-FL half duplex mode
           13      10BASE-FL full duplex mode
           14      100BASE-T4
           15      100BASE-TX half duplex mode
           16      100BASE-TX full duplex mode
           17      100BASE-FX half duplex mode
           18      100BASE-FX full duplex mode
           19      100BASE-T2 half duplex mode
           20      100BASE-T2 full duplex mode

(C<ifMauTypeList>)

=item $mau->mau_type_admin()

(C<ifMauDefaultType>)

=item $mau->mau_auto() - Indicates whether or not auto-negotiation is
supported.

(C<ifMauAutoNegSupported>)

=item $mau->mau_autostat() - Returns status of auto-negotiation mode for
ports.

(C<ifMauAutoNegAdminStatus>)

=item $mau->mau_autosent() - Returns a 32 bit bit-string representing the
capabilities we are broadcasting on that port 

    Uses the same decoder as $mau->mau_type().

(C<ifMauAutoNegCapAdvertised>)

=item $mau->mau_autorec() - Returns a 32 bit bit-string representing the 
capabilities of the device on the other end. 

    Uses the same decoder as $mau->mau_type().

(C<ifMauAutoNegCapReceived>)

=back

=head1 SET METHODS

These are methods that provide SNMP set functionality for overridden methods
or provide a simpler interface to complex set operations.  See
L<SNMP::Info/"SETTING DATA VIA SNMP"> for general information on set
operations.

=over 

=item $mau->mau_set_i_speed_admin(speed, ifIndex)

Sets port speed, must be supplied with speed and port C<ifIndex>.

Note that this method has some limitations since there is no way
to reliably set the port speed independently of the port duplex
setting on certain devices, notably the Cisco Cat4k series.

Speed choices are '10', '100', '1000', 'auto'.

=item $mau->mau_set_i_duplex_admin(duplex, ifIndex)

Sets port duplex, must be supplied with duplex and port C<ifIndex>.

Note that this method has some limitations since there is no way
to reliably set the port duplex independently of the port speed
setting on certain devices, notably the Cisco Cat4k series.

Duplex choices are 'auto', 'half', 'full'.

=item $mau->mau_set_i_speed_duplex_admin(speed, duplex, ifIndex)

Sets port speed and duplex settings, must be supplied with speed,
duplex and port C<ifIndex>.

Accepts the following values for speed and duplex:

        Speed/Duplex
        ------------
        auto/auto (this is a special case)
        10/half
        10/full
        100/half
        100/full
        1000/half
        1000/full

=back

=head1 Utility Functions

=over 

=item munge_int2bin() - Unpacks an integer into a 32bit bit string.

=item $mau->_isfullduplex(bitstring)

    Boolean. Checks to see if any of the full_duplex types from mau_type()
    are     high.  Currently bits 11,13,16,18,20.

=item $mau->_ishalfduplex(bitstring)

    Boolean.  Checks to see if any of the half_duplex types from mau_type()
    are high.  Currently bits 10,12,15,17,19.

=back

=cut
