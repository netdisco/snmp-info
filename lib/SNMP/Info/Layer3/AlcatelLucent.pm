# SNMP::Info::Layer3::AlcatelLucent
#
# Copyright (c) 2008 Bill Fenner
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

package SNMP::Info::Layer3::AlcatelLucent;

use strict;
use warnings;

use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::MAU;
use SNMP::Info::AMAP;
# Use LLDP
# (or at least try.  The versions I've seen have two problems:
# 1. they report ifIndex values as 'local'; we don't support ifIndex
#    but *could*
# 2. They report 0.0.0.0 as the management address
# )
use SNMP::Info::LLDP;

@SNMP::Info::Layer3::AlcatelLucent::ISA = qw/SNMP::Info::AMAP SNMP::Info::LLDP
    SNMP::Info::MAU SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::AlcatelLucent::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.982000';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::MAU::MIBS,
    %SNMP::Info::LLDP::MIBS,
    %SNMP::Info::AMAP::MIBS,
    'ALCATEL-IND1-DEVICES'      => 'familyOmniSwitch7000',
    'ALCATEL-IND1-CHASSIS-MIB'  => 'chasEntPhysOperStatus',
    'ALCATEL-IND1-VLAN-MGR-MIB' => 'vpaType',
    'ALU-POWER-ETHERNET-MIB'    => 'pethPsePortDetectionStatus',
);

# Alcatel's AOS 6 copy of the POWER-ETHERNET-MIB lives in vendor space
# without renaming any objects, while AOS 8 implements the standard MIB.
# With both modules loaded a bare leaf name resolves to whichever loaded
# last, so every peth column is qualified with its MIB name.

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS, %SNMP::Info::MAU::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS, %SNMP::Info::AMAP::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS, %SNMP::Info::MAU::FUNCS,
    %SNMP::Info::LLDP::FUNCS, %SNMP::Info::AMAP::FUNCS,

    # POWER-ETHERNET-MIB (standard, AOS 8)
    'std_peth_port_admin'  => 'POWER_ETHERNET_MIB__pethPsePortAdminEnable',
    'std_peth_port_status' =>
        'POWER_ETHERNET_MIB__pethPsePortDetectionStatus',
    'std_peth_port_class' =>
        'POWER_ETHERNET_MIB__pethPsePortPowerClassifications',
    'std_peth_power_watts'  => 'POWER_ETHERNET_MIB__pethMainPsePower',
    'std_peth_power_status' => 'POWER_ETHERNET_MIB__pethMainPseOperStatus',
    'std_peth_power_consumption' =>
        'POWER_ETHERNET_MIB__pethMainPseConsumptionPower',
    'std_peth_power_threshold' =>
        'POWER_ETHERNET_MIB__pethMainPseUsageThreshold',

    # ALU-POWER-ETHERNET-MIB (vendor copy, AOS 6)
    'alu_peth_port_admin' => 'ALU_POWER_ETHERNET_MIB__pethPsePortAdminEnable',
    'alu_peth_port_status' =>
        'ALU_POWER_ETHERNET_MIB__pethPsePortDetectionStatus',
    'alu_peth_port_class' =>
        'ALU_POWER_ETHERNET_MIB__pethPsePortPowerClassifications',
    'alu_peth_power_watts'  => 'ALU_POWER_ETHERNET_MIB__pethMainPsePower',
    'alu_peth_power_status' =>
        'ALU_POWER_ETHERNET_MIB__pethMainPseOperStatus',
    'alu_peth_power_consumption' =>
        'ALU_POWER_ETHERNET_MIB__pethMainPseConsumptionPower',
    'alu_peth_power_threshold' =>
        'ALU_POWER_ETHERNET_MIB__pethMainPseUsageThreshold',

    # ALCATEL-IND1-VLAN-MGR-MIB::vpaTable
    'alu_vpa_type' => 'vpaType',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE, %SNMP::Info::MAU::MUNGE,
    %SNMP::Info::LLDP::MUNGE, %SNMP::Info::AMAP::MUNGE,
);

# use MAU-MIB for admin. duplex and admin. speed
*SNMP::Info::Layer3::AlcatelLucent::i_duplex_admin
    = \&SNMP::Info::MAU::mau_i_duplex_admin;
*SNMP::Info::Layer3::AlcatelLucent::i_speed_admin
    = \&SNMP::Info::MAU::mau_i_speed_admin;

sub model {
    my $alu   = shift;
    my $id    = $alu->id();
    my $model = &SNMP::translateObj($id);

    return $id unless defined $model;

    $model =~ s/^device//;

    return $model;
}

sub os {
    return 'AOS';
}

sub vendor {
    return 'alcatel-lucent';
}

sub os_ver {
   my $alu = shift;

   my $descr = $alu->description();
   if (defined ($descr)) {
     return $1 if $descr =~ m/\b(\d[\.\d]+R\d+) (?:GA|Service Release), /;
   }

   # No clue what this will try but hey
   return $alu->SUPER::os_ver();
}

# ps1_type, ps1_status, ps2_type, ps2_status:
# Find the list of power supplies in the ENTITY-MIB
# e_class = powerSupply
# e_descr = ps_type
# chasEntPhysOperStatus = ps_status
sub _power_supplies {
    my $alu = shift;

    my $e_class  = $alu->e_class();
    my @supplies = ();

    foreach my $key ( sort { int($a) cmp int($b) } keys %$e_class ) {
        if ( $e_class->{$key} eq 'powerSupply' ) {
            push( @supplies, int($key) );
        }
    }
    return @supplies;
}

sub _ps_type {
    my $alu   = shift;
    my $psnum = shift;
    my @ps    = $alu->_power_supplies();

    if ( $psnum > $#ps ) {
        return "none";
    }
    my $supply = $ps[$psnum];
    my $descr  = $alu->e_descr($supply);
    return $descr->{$supply};
}

sub _ps_status {
    my $alu   = shift;
    my $psnum = shift;
    my @ps    = $alu->_power_supplies();

    if ( $psnum > $#ps ) {
        return "not present";
    }
    my $supply = $ps[$psnum];
    my $status = $alu->chasEntPhysOperStatus($supply);
    return $status->{$supply};
}

sub ps1_type {
    my $alu = shift;
    return $alu->_ps_type(0);
}

sub ps2_type {
    my $alu = shift;
    return $alu->_ps_type(1);
}

sub ps1_status {
    my $alu = shift;
    return $alu->_ps_status(0);
}

sub ps2_status {
    my $alu = shift;
    return $alu->_ps_status(1);
}

# The interface description contains the software version, so
# to avoid losing historical information through a software upgrade
# we use interface name instead.
sub interfaces {
    my $alu     = shift;
    my $partial = shift;

    return $alu->orig_i_name($partial);
}

# Work around buggy bp_index in 6.3.1.871.R01 and 6.3.1.975.R01
sub bp_index {
    my $alu     = shift;
    my $partial = shift;

    my $bp_index = $alu->SUPER::bp_index($partial);

    #
    # This device sometimes reports an ifIndex and sometimes reports
    # dot1dBasePort for the dot1d port values - e.g.,
    # in 6.3.1.871.R01 both dot1dTpFdbPort and dot1qTpFdbPort report
    # the ifIndex; in 6.3.1.975.R01 dot1dTpFdbPort has been updated
    # to report the dot1dBasePort but dot1qTpFdbPort still returns an
    # ifIndex.  For this reason, we augment the dot1dBasePort
    # mapping with ifIndex->ifIndex mappings -- we can do this because
    # the ifIndex and dot1dBasePort spaces don't overlap, at least for
    # the ports we care about.
    my @keys = keys %$bp_index;
    foreach my $idx (@keys) {
        my $ifIndex = $bp_index->{$idx};
        $bp_index->{$ifIndex} = $ifIndex;
    }

    #
    # In addition, aggregates aren't reported at all in bp_index.
    # We grab them from i_index.
    my $i_index = $alu->i_index();
    foreach my $idx ( keys %$i_index ) {
        my $ifIndex = $i_index->{$idx};
        if ( int($ifIndex) > 40000001 ) {
            $bp_index->{$ifIndex} = $ifIndex;

            # dot1dTpFdbPort seems to use 4098, 4099, 4100 for
            # 40000001, 40000002, 40000003.  I guess this is
            # 4096 + 1 + aggregate number.
            my $tmp = sprintf( "%d", int($ifIndex) - 39995903 );
            $bp_index->{$tmp} = $ifIndex;
        }
    }
    return $bp_index;
}

# AOS 8 (and some AOS 6 releases) leave dot1qPvid empty, so fall back to
# the configured default VLAN in vpaTable, indexed by vlan.ifIndex.  A port
# listed as default in more than one VLAN is ambiguous and left out.
sub i_vlan {
    my $alu     = shift;
    my $partial = shift;

    my $i_vlan = $alu->SUPER::i_vlan($partial);
    return $i_vlan if ref $i_vlan eq 'HASH' and scalar keys %$i_vlan;

    my $vpa_type = $alu->alu_vpa_type();
    unless ( ref $vpa_type eq 'HASH' and scalar keys %$vpa_type ) {
        $vpa_type = $alu->alu8_vpa_type();
    }
    return {} unless ref $vpa_type eq 'HASH';

    my %defaults;
    foreach my $iid ( keys %$vpa_type ) {
        my $type = $vpa_type->{$iid};
        next unless defined $type and $type =~ m/^(?:cfgDefault|1)$/;
        my ( $vlan, $ifindex ) = split( m/\./, $iid );
        next if defined $partial and $ifindex ne $partial;
        push @{ $defaults{$ifindex} }, $vlan;
    }

    my $default_vlan = {};
    foreach my $ifindex ( keys %defaults ) {
        my @vlans = @{ $defaults{$ifindex} };
        $default_vlan->{$ifindex} = $vlans[0] if scalar @vlans == 1;
    }
    return $default_vlan;
}

# AOS 8 serves vpaType under .6486.801, but netdisco-mibs only defines the
# AOS 6 tree under .6486.800.  With no MIB node there net-snmp returns the
# whole instance OID as the tag and an empty iid, which AUTOLOAD's table
# walk cannot follow, so walk the numeric column here.
sub alu8_vpa_type {
    my $alu = shift;

    return $alu->{store}{alu8_vpa_type} if $alu->{'_alu8_vpa_type'};
    return if $alu->{Offline};
    my $sess = $alu->session() or return;

    my $base = '.1.3.6.1.4.1.6486.801.1.2.1.3.1.1.2.1.1.3';
    my ( $vpa_type, $failure ) = _alu8_vpa_walk( $sess, $base );
    my ( $reason, $errornum, $error ) = @{$failure};

    my $rows = scalar keys %{$vpa_type};
    $alu->_walk_outcome(
        {   method    => 'alu8_vpa_type',
            leaf      => $base,
            partial   => undef,
            complete  => ( SNMP::Info::_walk_incomplete($reason) ? 0 : 1 ),
            reason    => $reason,
            error     => $error,
            errornum  => $errornum,
            walk      => 'getnext',
            repeaters => undef,
            rows      => $rows,
            recovery  => [],
        }
    );

    if ( SNMP::Info::_walk_incomplete($reason) ) {
        $alu->error_throw( "SNMP::Info::Layer3::AlcatelLucent: "
                . "alu8_vpa_type incomplete: $reason after $rows rows. "
                . ( $error || '' ) );
        return if $alu->incomplete_walk() eq 'undef';
    }
    $alu->_cache( 'alu8_vpa_type', $vpa_type );
    return $vpa_type;
}

# Walks the numeric column. Returns the rows and a [reason, errornum, error]
# triple that is empty when the walk ended cleanly.
sub _alu8_vpa_walk {
    my ( $sess, $base ) = @_;

    my $next_oid = $base;
    my $vpa_type = {};
    my %seen;
    while (1) {

        # The returned tag cannot be resent, so ask again by number.
        my $var = SNMP::Varbind->new( [$next_oid] );
        $sess->getnext($var);
        if ( $sess->{ErrorNum} ) {
            return ( $vpa_type, [] ) if SNMP::Info::_nosuch_end($sess);
            return ( $vpa_type, [ SNMP::Info::_walk_failure($sess) ] );
        }
        last if !defined $var->[0];
        my $name = $var->[0];
        $name .= ".$var->[1]" if defined $var->[1] and length $var->[1];
        my $oid = $name =~ m/^[.]\d/
            ? $name
            : SNMP::translateObj($name) // $name;

        # endOfMibView repeats the last OID, so test it before the loop check
        last if defined $var->[2] and $var->[2] eq 'ENDOFMIBVIEW';
        if ( $seen{$oid}++ ) {
            return ( $vpa_type,
                [ 'loop', 0, "Looping on: alu8_vpa_type oid:$oid." ] );
        }
        last unless $oid =~ m/^\Q$base\E\.(\d+\.\d+)$/;
        $vpa_type->{$1} = $var->[2];
        $next_oid = $oid;
    }
    return ( $vpa_type, [] );
}

# One PoE source per device: the standard MIB when its port table has
# rows, otherwise the AOS 6 vendor copy.
sub _peth_table {
    my $alu     = shift;
    my $method  = shift;
    my $partial = shift;

    my $std_status = $alu->std_peth_port_status();
    my $source
        = ( ref $std_status eq 'HASH' and scalar keys %$std_status )
        ? 'std'
        : 'alu';
    my $leaf_method = "${source}_$method";
    my $table       = $alu->$leaf_method($partial);
    return $table;
}

sub peth_port_admin {
    my ( $alu, $partial ) = @_;
    return $alu->_peth_table( 'peth_port_admin', $partial );
}

sub peth_port_status {
    my ( $alu, $partial ) = @_;
    return $alu->_peth_table( 'peth_port_status', $partial );
}

sub peth_port_class {
    my ( $alu, $partial ) = @_;
    return $alu->_peth_table( 'peth_port_class', $partial );
}

sub peth_power_watts {
    my ( $alu, $partial ) = @_;
    return $alu->_peth_table( 'peth_power_watts', $partial );
}

sub peth_power_status {
    my ( $alu, $partial ) = @_;
    return $alu->_peth_table( 'peth_power_status', $partial );
}

sub peth_power_consumption {
    my ( $alu, $partial ) = @_;
    return $alu->_peth_table( 'peth_power_consumption', $partial );
}

sub peth_power_threshold {
    my ( $alu, $partial ) = @_;
    return $alu->_peth_table( 'peth_power_threshold', $partial );
}

# Power-Ethernet ifIndex mapping.  I've only seen this from a
# fixed-config single-module system, so this is only a plausible
# guess as to the mapping on a stack or modular system.
sub peth_port_ifindex {
    my $alu     = shift;
    my $partial = shift;

    my $peth_port_status  = $alu->peth_port_status($partial);
    my $peth_port_ifindex = {};

    foreach my $key ( keys %$peth_port_status ) {
        my @oid = split( m/\./, $key );
        $peth_port_ifindex->{$key} = int( $oid[0] ) * 1000 + int( $oid[1] );
    }
    return $peth_port_ifindex;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::AlcatelLucent - SNMP Interface to Alcatel-Lucent OmniSwitch

=head1 AUTHOR

Bill Fenner

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $alu = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $alu->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Alcatel-Lucent OmniSwitch devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::MAU

=item SNMP::Info::LLDP

=back

=head2 Required MIBs

=over

=item F<ALCATEL-IND1-DEVICES>

=item F<ALCATEL-IND1-CHASSIS-MIB>

=item F<ALCATEL-IND1-VLAN-MGR-MIB>

=item F<ALU-POWER-ETHERNET-MIB>

Note that Alcatel-Lucent distributes their own proprietary version of the
F<POWER-ETHERNET-MIB>, but the MIB module name that they distribute is
simply F<POWER-ETHERNET-MIB>.  This module must be hand-edited to change the
module name to F<ALU-POWER-ETHERNET-MIB> so that it can be used simultaneously
with the standard F<POWER-ETHERNET-MIB>.  AOS 6 populates this vendor
copy; AOS 8 populates the standard F<POWER-ETHERNET-MIB> instead.

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::MAU/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::LLDP/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $alu->vendor()

Returns 'alcatel-lucent'

=item $alu->model()

Tries to reference $alu->id() to one of the product MIBs listed above

Removes 'device' from the name for readability.

=item $alu->os()

Returns 'AOS'

=item $alu->os_ver()

Grabs the os version from C<sysDescr>

=item $alu->ps1_type()

Return the type of the first power supply from the F<ENTITY-MIB>

=item $alu->ps2_type()

Return the type of the second power supply from the F<ENTITY-MIB>

=item $alu->ps1_status()

Return the status of the first power supply from the F<ALCATEL-IND1-CHASSIS-MIB>

=item $alu->ps2_status()

Return the status of the second power supply from the F<ALCATEL-IND1-CHASSIS-MIB>

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $alu->interfaces()

Returns interface name from C<ifName>, since the default return value
of C<ifDescr> includes the OS version.

=item $alu->bp_index()

Work around various bugs in the F<BRIDGE-MIB> and
F<Q-BRIDGE-MIB> implementations, by returning both
C<ifIndex> and C<dot1dBasePort> mappings to C<ifIndex> values.

=item $alu->i_duplex_admin()

Returns info from F<MAU-MIB>

=item $alu->i_speed_admin()

Returns info from F<MAU-MIB>

=item $alu->i_vlan()

Returns the default VLAN of each port from C<dot1qPvid>.  When that is
empty, as on AOS 8, returns the VLAN of C<vpaTable> rows whose C<vpaType>
is C<cfgDefault>, keyed by C<vpaIfIndex>.  A port that is C<cfgDefault>
in more than one VLAN is omitted.

=item $alu->alu8_vpa_type()

Returns C<vpaType> from the AOS 8 copy of C<vpaTable>
(C<.1.3.6.1.4.1.6486.801.1.2.1.3.1.1.2.1.1.3>), keyed by
C<vpaVlanNumber.vpaIfIndex>.  The table is walked by number because
F<ALCATEL-IND1-VLAN-MGR-MIB> only defines the AOS 6 location.  The walk is
recorded in C<walk_status>.  C<LoopDetect> is not consulted: this walk always
stops on a repeated OID.

=item $alu->peth_port_ifindex()

Returns the C<ifIndex> value for power-ethernet ports
using the OmniSwitch algorithm.

=item $alu->peth_port_admin()

=item $alu->peth_port_status()

=item $alu->peth_port_class()

=item $alu->peth_power_watts()

=item $alu->peth_power_status()

=item $alu->peth_power_consumption()

=item $alu->peth_power_threshold()

Return the standard F<POWER-ETHERNET-MIB> column when its
C<pethPsePortDetectionStatus> has rows (AOS 8), otherwise the same column
from F<ALU-POWER-ETHERNET-MIB> (AOS 6).  Rows from the two MIBs are never
mixed for one device.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"TABLE METHODS"> for details.

=cut
