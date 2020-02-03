# SNMP::Info::Layer3::Timetra
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

package SNMP::Info::Layer3::Timetra;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::Aggregate;

@SNMP::Info::Layer3::Timetra::ISA
    = qw/SNMP::Info::Aggregate SNMP::Info::Layer3
    Exporter/;
@SNMP::Info::Layer3::Timetra::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.70';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::Aggregate::MIBS,
    'TIMETRA-GLOBAL-MIB'  => 'timetraReg',
    'TIMETRA-LLDP-MIB'    => 'tmnxLldpAdminStatus',
    'TIMETRA-PORT-MIB'    => 'tmnxPortEtherDuplex',
    'TIMETRA-CHASSIS-MIB' => 'tmnxChassisFanOperStatus',
);

%GLOBALS = ( %SNMP::Info::Layer3::GLOBALS, );

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,

    # For some reason LLDP-MIB::lldpLocManAddrTable is populated
    # but LLDP-MIB::lldpRemTable is not and we need to use the
    # proprietary TIMETRA-LLDP-MIB Note: these tables are
    # indexed differently than LLDP-MIB
    # TIMETRA-LLDP-MIB::tmnxLldpRemTable
    'lldp_rem_id_type'  => 'tmnxLldpRemChassisIdSubtype',
    'lldp_rem_id'       => 'tmnxLldpRemChassisId',
    'lldp_rem_pid_type' => 'tmnxLldpRemPortIdSubtype',
    'lldp_rem_pid'      => 'tmnxLldpRemPortId',
    'lldp_rem_desc'     => 'tmnxLldpRemPortDesc',
    'lldp_rem_sysname'  => 'tmnxLldpRemSysName',
    'lldp_rem_sysdesc'  => 'tmnxLldpRemSysDesc',
    'lldp_rem_sys_cap'  => 'tmnxLldpRemSysCapEnabled',
    'lldp_rem_cap_spt'  => 'tmnxLldpRemSysCapSupported',

    # TIMETRA-LLDP-MIB::tmnxLldpRemManAddrTable
    'lldp_rman_addr' => 'tmnxLldpRemManAddrIfSubtype',

    # TIMETRA-PORT-MIB::tmnxPortEtherTable
    'tmnx_eth_speed_admin'  => 'tmnxPortEtherSpeed',
    'tmnx_eth_duplex'       => 'tmnxPortEtherOperDuplex',
    'tmnx_eth_duplex_admin' => 'tmnxPortEtherDuplex',
    'tmnx_eth_auto'         => 'tmnxPortEtherAutoNegotiate',

    # TIMETRA-CHASSIS-MIB::tmnxChassisFanTable
    'tmnx_fan_state' => 'tmnxChassisFanOperStatus',

    # TIMETRA-CHASSIS-MIB::tmnxChassisPowerSupplyTable
    'tmnx_ps1_state' => 'tmnxChassisPowerSupply1Status',
    'tmnx_ps2_state' => 'tmnxChassisPowerSupply2Status',

    # TIMETRA-CHASSIS-MIB::tmnxHwTable
    'e_descr'  => 'tmnxHwName',
    'e_parent' => 'tmnxHwContainedIn',
    'e_name'   => 'tmnxHwName',
    'e_class'  => 'tmnxHwClass',
    'e_pos'    => 'tmnxHwParentRelPos',
    'e_swver'  => 'tmnxHwSoftwareCodeVersion',
    'e_model'  => 'tmnxHwMfgBoardNumber',
    'e_serial' => 'tmnxHwSerialNumber',
    'e_fru'    => 'tmnxHwIsFRU',
    'e_fwver'  => 'tmnxHwFirmwareCodeVersion',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    'tmnx_fan_state' => \&SNMP::Info::Layer3::Timetra::munge_tmnx_state,
    'tmnx_ps1_state' => \&SNMP::Info::Layer3::Timetra::munge_tmnx_state,
    'tmnx_ps2_state' => \&SNMP::Info::Layer3::Timetra::munge_tmnx_state,
    'e_type'         => \&SNMP::Info::munge_e_type,
    'e_class'        => \&SNMP::Info::Layer3::Timetra::munge_tmnx_e_class,
    'e_swver'        => \&SNMP::Info::Layer3::Timetra::munge_tmnx_e_swver,
);

sub model {
    my $timetra = shift;
    my $id      = $timetra->id();
    my $model   = SNMP::translateObj($id);
    my $descr   = $timetra->description();

    my $str;

    if ( defined ($descr) && $descr =~ /\s+(7\d{3})/ ) {
        $str = $1;
    }

    if ( defined $model && $model =~ /^tmnxModel/ ) {
        $model =~ s/^tmnxModel//;
        $model =~ s/Reg$//;
        $str .= $str ? " " : "";
        $str .= $model;
    }

    return $str || $id;
}

sub os {
    return 'TiMOS';
}

sub vendor {
    return 'nokia';
}

sub os_ver {
    my $timetra = shift;

    my $descr = $timetra->description();
    if ( defined ($descr) && $descr =~ m/^TiMOS-(\S+)/x ) {
        return $1;
    }
    return;
}

# The interface description contains the SFP type, so
# to avoid losing historical information through a configuration change
# we use interface name instead.
sub interfaces {
    my $alu     = shift;
    my $partial = shift;

    return $alu->orig_i_name($partial);
}

# The TIMETRA-LLDP-MIB::tmnxLldpRemTable unambiguously states it uses ifIndex
# Trying to cross reference to ifDescr or ifAlias would cause unpredictable
# results based upon how the device names ports.
sub lldp_if {
    my $alu     = shift;
    my $partial = shift;

    my $addr = $alu->lldp_rem_pid($partial) || {};

    my %lldp_if;
    foreach my $key ( keys %$addr ) {
        my @aOID = split( '\.', $key );
        my $port = $aOID[1];
        next unless $port;

        $lldp_if{$key} = $port;
    }
    return \%lldp_if;
}

# The proprietary TIMETRA-LLDP-MIB tables are indexed differently than LLDP-MIB
# We overwrite the private function so that the we don't have to replicate
# the code in SNMP::Info::LLDP that uses it.

sub _lldp_addr_index {
    my $alu = shift;
    my $idx = shift;

    my @oids = split( /\./, $idx );

    # Index has extra field compared to LLDP-MIB
    my $index = join( '.', splice( @oids, 0, 4 ) );
    my $proto = shift(@oids);
    shift(@oids) if scalar @oids > 4;    # $length

    # IPv4
    if ( $proto == 1 ) {
        return ( $index, $proto, join( '.', @oids ) );
    }

    # IPv6
    elsif ( $proto == 2 ) {
        return ( $index, $proto,
            join( ':', unpack( '(H4)*', pack( 'C*', @oids ) ) ) );
    }

    # MAC
    elsif ( $proto == 6 ) {
        return ( $index, $proto,
            join( ':', map { sprintf "%02x", $_ } @oids ) );
    }

    # TODO - Other protocols may be used as well; implement when needed?
    else {
        return;
    }
};

sub i_duplex {
    my $alu     = shift;
    my $partial = shift;

    my $hw_duplex = $alu->tmnx_eth_duplex($partial) || {};

    my %i_duplex;
    if ( ref {} eq ref $hw_duplex and scalar keys %$hw_duplex ) {
        foreach my $if ( keys %$hw_duplex ) {
            my $duplex = $hw_duplex->{$if};
            next unless defined $duplex;
            next if $duplex eq 'notApplicable';
            my ( $slot, $ifindex ) = split( /\./, $if );

            $duplex = 'half'
                if ( $duplex =~ /half/i );
            $duplex = 'full'
                if ( $duplex =~ /full/i );

            $i_duplex{$ifindex} = $duplex;
        }
        return \%i_duplex;
    }
    return $alu->SUPER::i_duplex($partial);
}

sub i_duplex_admin {
    my $alu     = shift;
    my $partial = shift;

    my $hw_duplex_admin = $alu->tmnx_eth_duplex_admin($partial) || {};
    my $hw_auto         = $alu->tmnx_eth_auto($partial)         || {};

    my %i_duplex_admin;
    foreach my $if ( keys %$hw_duplex_admin ) {
        my $duplex = $hw_duplex_admin->{$if};
        next unless defined $duplex;
        next if $duplex eq 'notApplicable';
        my $auto = $hw_auto->{$if} || 'false';
        my ( $slot, $ifindex ) = split( /\./, $if );

        my $string = 'other';
        $string = 'half'
            if ( $duplex =~ /half/i and $auto =~ /false/i );
        $string = 'full'
            if ( $duplex =~ /full/i and $auto =~ /false/i );
        $string = 'auto' if $auto =~ /true/i;

        $i_duplex_admin{$ifindex} = $string;
    }
    return \%i_duplex_admin;
}

sub agg_ports {
    my $alu = shift;

    return $alu->agg_ports_ifstack();
}

sub fan {
    my $alu = shift;

    my $state = $alu->tmnx_fan_state() || {};

    if ( scalar keys %$state ) {
        my @messages = ();

        foreach my $k ( keys %$state ) {
            next if $state->{$k} and $state->{$k} eq 'Ok';
            my ( $chassis, $fan ) = split( /\./, $k );
            push @messages, "Fan $fan, Chassis $chassis: $state->{$k}";
        }

        push @messages, ( ( scalar keys %$state ) . " fans OK" )
            if scalar @messages == 0;

        return ( join ", ", @messages );
    }
    return;
}

sub ps1_status {
    my $alu = shift;

    my $pwr_state = $alu->tmnx_ps1_state() || {};

    my $ret = "";
    my $s   = "";
    foreach my $i ( sort keys %$pwr_state ) {
        my ( $chassis, $num ) = split( /\./, $i );
        $ret
            .= $s
            . "Chassis "
            . $chassis . " PS "
            . $num . ": "
            . $pwr_state->{$i};
        $s = ", ";
    }
    return if ( $s eq "" );
    return $ret;
}

sub ps2_status {
    my $alu = shift;

    my $pwr_state = $alu->tmnx_ps2_state() || {};

    my $ret = "";
    my $s   = "";
    foreach my $i ( sort keys %$pwr_state ) {
        my ( $chassis, $num ) = split( /\./, $i );
        $ret
            .= $s
            . "Chassis "
            . $chassis . " PS "
            . $num . ": "
            . $pwr_state->{$i};
        $s = ", ";
    }
    return if ( $s eq "" );
    return $ret;
}

sub e_index {
    my $alu  = shift;
    my $partial = shift;

    # Use MIB leaf to force load here
    my $e_descr = $alu->tmnxHwID($partial);

    return unless ( ref {} eq ref $e_descr and scalar keys %$e_descr );

    my %e_index;

    foreach my $iid ( keys %$e_descr ) {
        $e_index{$iid} = $iid;
    }
    return \%e_index;
}

sub munge_tmnx_state {
    my $state = shift;

    $state =~ s/deviceState//;
    $state =~ s/device//;
    return $state;
}

sub munge_tmnx_e_class {
    my $class = shift;

    if ($class eq 'physChassis') {
        $class = 'chassis';
    }
    elsif ($class =~ /Module/i) {
        $class = 'module';
    }
    return $class;
}

sub munge_tmnx_e_swver {
    my $swver = shift;

    if ( $swver =~ m/^TiMOS-(\S+)/x ) {
        return $1;
    }
    return $swver;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Timetra - SNMP Interface to Alcatel-Lucent SR

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

Subclass for Alcatel-Lucent Service Routers

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<TIMETRA-GLOBAL-MIB>

=item F<TIMETRA-LLDP-MIB>

=item F<TIMETRA-PORT-MIB>

=item F<TIMETRA-CHASSIS-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $alu->vendor()

Returns 'nokia'

=item $alu->os()

Returns 'TiMOS'

=item $alu->os_ver()

Grabs the version string from C<sysDescr>.

=item $alu->model()

Tries to combine series and model extracted from $alu->id() to one of the
product MIBs.

Removes 'tmnxModel' from the name for readability.

=item $alu->fan()

Return the status of all fans from the F<TIMETRA-CHASSIS-MIB>. Returns
a string indicating the number of fans 'OK' or identification of any fan without
a 'Ok' operating status.

=item $alu->ps1_status()

Return the status of the first power supply in each chassis from
the F<TIMETRA-CHASSIS-MIB>.

=item $alu->ps2_status()

Return the status of the second power supply in each chassis from
the F<TIMETRA-CHASSIS-MIB>.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $alu->i_duplex()

Returns reference to map of IIDs to current link duplex.

=item $alu->i_duplex_admin()

Returns reference to hash of IIDs to admin duplex setting.

=item $alu->agg_ports()

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.

=back

=head2 Overrides

=over

=item $alu->interfaces()

Returns C<ifName>, since the default Layer3 C<ifDescr> varies based
upon the transceiver inserted.

=item $alu->lldp_if()

Returns the mapping to the SNMP Interface Table. Utilizes (C<ifIndex>)
from the (C<tmnxLldpRemEntry >) index.

=back

=head2 LLDP Remote Table (C<lldpRemTable>) uses (C<TIMETRA-LLDP-MIB::tmnxLldpRemTable>)

=over

=item $alu->lldp_rem_id_type()

(C<tmnxLldpRemChassisIdSubtype>)

=item $alu->lldp_rem_id()

(C<tmnxLldpRemChassisId>)

=item $alu->lldp_rem_pid_type()

(C<tmnxLldpRemPortIdSubtype>)

=item $alu->lldp_rem_pid()

(C<tmnxLldpRemPortId>)

=item $alu->lldp_rem_desc()

(C<tmnxLldpRemPortDesc>)

=item $alu->lldp_rem_sysname()

(C<tmnxLldpRemSysName>)

=item $alu->lldp_rem_sysdesc()

(C<tmnxLldpRemSysDesc>)

=item  $alu->lldp_rem_sys_cap()

(C<tmnxLldpRemSysCapEnabled>)

=back

=head2 Entity Table

=over

=item $alu->e_index()

(C<tmnxHwIndex>)

=item $alu->e_class()

Chassis, Module, Fan, Power Supply ...

(C<tmnxHwClass>)

=item $alu->e_descr()

Human Friendly

(C<tmnxHwName>)

=item $alu->e_fwver()

(C<tmnxHwFirmwareCodeVersion>)

=item $alu->e_fru()

BOOLEAN. Is a Field Replaceable unit?

(C<tmnxHwIsFRU>)

=item $alu->e_model()

Model Name of Entity.

(C<tmnxHwMfgBoardNumber>)

=item $alu->e_name()

More computer friendly name of entity.

(C<tmnxHwName>)

=item $alu->e_parent()

0 if root.

(C<tmnxHwContainedIn>)

=item $alu->e_pos()

The relative position among all entities sharing the same parent.

(C<tmnxHwParentRelPos>)

=item $alu->e_serial()

(C<tmnxHwSerialNumber>)

=item $alu->e_swver()

(C<tmnxHwSoftwareCodeVersion>)

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head1 Data Munging Callback Subroutines

=over

=item $alu->munge_tmnx_state()

Removes 'deviceState' or 'device' from C<TmnxDeviceState> strings.

=item $alu->munge_tmnx_e_class()

Attempts to normalize C<tmnxHwClass> to an C<IANAPhysicalClass>.

=item $alu->munge_tmnx_e_swver()

Extracts the software version from C<tmnxHwSoftwareCodeVersion> string.

=back

=cut
