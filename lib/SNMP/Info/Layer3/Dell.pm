# SNMP::Info::Layer3::Dell - SNMP Interface to Dell devices
# $Id$
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

package SNMP::Info::Layer3::Dell;

use strict;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::LLDP;

@SNMP::Info::Layer3::Dell::ISA       = qw/SNMP::Info::LLDP SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Dell::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %FUNCS %MIBS %MUNGE/;

$VERSION = '3.34';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::LLDP::MIBS,
    'RADLAN-Physicaldescription-MIB' => 'rlPhdStackReorder',
    'RADLAN-rlInterfaces'            => 'rlIfNumOfLoopbackPorts',
    'RADLAN-HWENVIROMENT'            => 'rlEnvPhysicalDescription',
    'Dell-Vendor-MIB'                => 'productIdentificationVersion',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,
    'os_ver'       => 'productIdentificationVersion',
    'dell_id_name' => 'productIdentificationDisplayName',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::LLDP::FUNCS,

    # RADLAN-rlInterfaces:swIfTable
    'dell_duplex_admin' => 'swIfDuplexAdminMode',
    'dell_duplex'       => 'swIfDuplexOperMode',
    'dell_tag_mode'     => 'swIfTaggedMode',
    'dell_i_type'       => 'swIfType',
    'dell_fc_admin'     => 'swIfFlowControlMode',
    'dell_speed_admin'  => 'swIfSpeedAdminMode',
    'dell_auto'         => 'swIfSpeedDuplexAutoNegotiation',
    'dell_fc'           => 'swIfOperFlowControlMode',

    # RADLAN-Physicaldescription-MIB:rlPhdUnitGenParamTable
    'dell_unit'      => 'rlPhdUnitGenParamStackUnit',
    'dell_sw_ver'    => 'rlPhdUnitGenParamSoftwareVersion',
    'dell_fw_ver'    => 'rlPhdUnitGenParamFirmwareVersion',
    'dell_hw_ver'    => 'rlPhdUnitGenParamHardwareVersion',
    'dell_serial_no' => 'rlPhdUnitGenParamSerialNum',
    'dell_asset_no'  => 'rlPhdUnitGenParamAssetTag',

    # RADLAN-COPY-MIB:rlCopyTable
    'dell_cp_idx'     => 'rlCopyIndex',
    'dell_cp_sloc'    => 'rlCopySourceLocation',
    'dell_cp_sip'     => 'rlCopySourceIpAddress',
    'dell_cp_sunit'   => 'rlCopySourceUnitNumber',
    'dell_cp_sfile'   => 'rlCopySourceFileName',
    'dell_cp_stype'   => 'rlCopySourceFileType',
    'dell_cp_dloc'    => 'rlCopyDestinationLocation',
    'dell_cp_dip'     => 'rlCopyDestinationIpAddress',
    'dell_cp_dunit'   => 'rlCopyDestinationUnitNumber',
    'dell_cp_dfile'   => 'rlCopyDestinationFileName',
    'dell_cp_dtype'   => 'rlCopyDestinationFileType',
    'dell_cp_state'   => 'rlCopyOperationState',
    'dell_cp_bkgnd'   => 'rlCopyInBackground',
    'dell_cp_rstatus' => 'rlCopyRowStatus',

    # RADLAN-HWENVIROMENT:rlEnvMonSupplyStatusTable
    'dell_pwr_src'   => 'rlEnvMonSupplySource',
    'dell_pwr_state' => 'rlEnvMonSupplyState',
    'dell_pwr_desc'  => 'rlEnvMonSupplyStatusDescr',

    # RADLAN-HWENVIROMENT:rlEnvMonFanStatusTable
    'dell_fan_state' => 'rlEnvMonFanState',
    'dell_fan_desc'  => 'rlEnvMonFanStatusDescr',
);

%MUNGE = ( %SNMP::Info::Layer3::MUNGE, %SNMP::Info::LLDP::MUNGE, );

# Method OverRides

sub model {
    my $dell = shift;

    my $name  = $dell->dell_id_name();
    my $descr = $dell->description();

    if ( defined $name and $name =~ m/(\d+)/ ) {
        return $1;
    }

    # Don't have a vendor MIB for D-Link
    else {
        return $descr;
    }
}

sub vendor {
    my $dell = shift;

    return $dell->_vendor();
}

sub os {
    my $dell = shift;

    return $dell->_vendor();
}

sub serial {
    my $dell = shift;

    my $numbers = $dell->dell_serial_no();

    foreach my $key ( keys %$numbers ) {
        my $serial = $numbers->{$key};
        return $serial if ( defined $serial and $serial !~ /^\s*$/ );
        next;
    }

    # Last resort
    return $dell->SUPER::serial();
}

# check all fans, and report overall status
sub fan {
    my $dell = shift;

    my $fan   = $dell->dell_fan_desc()  || {};
    my $state = $dell->dell_fan_state() || {};
    my @messages = ();

    foreach my $k (keys %$fan) {
        next if $state->{$k} and $state->{$k} eq 'normal';
        push @messages, "$fan->{$k}: $state->{$k}";
    }

    push @messages, ((scalar keys %$fan). " fans OK")
      if scalar @messages == 0;

    return (join ", ", @messages);
}

sub _ps_status {
    my ($dell, $unit) = @_;

    my $status = 'unknown';
    return $status if !defined $unit;

    my $desc  = $dell->dell_pwr_desc()  || {};
    my $state = $dell->dell_pwr_state() || {};

    foreach my $k (keys %$desc) {
        next unless $desc->{$k} and $desc->{$k} eq "ps1_unit$unit";
        return ($state->{$k} || $status);
    }

    return $status;
}

sub ps1_type { return 'internalRedundant' }
sub ps2_type { return 'internalRedundant' }

sub ps1_status { return (shift)->_ps_status(1) }
sub ps2_status { return (shift)->_ps_status(2) }

sub interfaces {
    my $dell    = shift;
    my $partial = shift;

    my $i_descr = $dell->i_description($partial) || {};
    my $i_name  = $dell->orig_i_name($partial)   || {};

    # Descriptions are all the same on some Dells, so use name instead if
    # available
    foreach my $iid ( keys %$i_name ) {
        my $name = $i_name->{$iid};
        next unless defined $name;
        $i_descr->{$iid} = $name;
    }

    return $i_descr;
}

sub i_duplex_admin {
    my $dell    = shift;
    my $partial = shift;

    my $interfaces  = $dell->interfaces($partial)        || {};
    my $dell_duplex = $dell->dell_duplex_admin($partial) || {};
    my $dell_auto   = $dell->dell_auto($partial)         || {};

    my %i_duplex_admin;
    foreach my $if ( keys %$interfaces ) {
        my $duplex = $dell_duplex->{$if};
        next unless defined $duplex;
        my $auto = $dell_auto->{$if} || 'false';

        $duplex = 'half' if ( $duplex =~ /half/i and $auto =~ /false/i );
        $duplex = 'full' if ( $duplex =~ /half/i and $auto =~ /false/i );
        $duplex = 'auto' if $auto =~ /true/i;
        $i_duplex_admin{$if} = $duplex;
    }
    return \%i_duplex_admin;
}

sub _vendor {
    my $dell = shift;

    my $id = $dell->id() || 'undef';
    my %oidmap = (
        2    => 'ibm',
        171  => 'dlink',
        674  => 'dell',
        3955 => 'linksys',
    );
    $id = $1 if ( defined($id) && $id =~ /^\.1\.3\.6\.1\.4\.1\.(\d+)/ );

    if ( defined($id) and exists( $oidmap{$id} ) ) {
        return $oidmap{$id};
    }
    else {
        return 'dlink';
    }
}

# dot1qTpFdbTable uses dot1qVlanIndex rather than dot1qFdbId as index,
# so pretend we don't have the mapping
sub qb_fdb_index {return}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Dell - SNMP Interface to Dell Power Connect Network
Devices

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $dell = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 1
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class = $dell->class();

 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from an 
Dell Power Connect device through SNMP.  D-Link and the IBM BladeCenter
Gigabit Ethernet Switch Module also use this module based upon MIB support. 

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

my $dell = new SNMP::Info::Layer3::Dell(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<Dell-Vendor-MIB>

=item F<RADLAN-Physicaldescription-MIB>

=item F<RADLAN-rlInterfaces>

=item F<RADLAN-HWENVIROMENT>

=item Inherited Classes' MIBs

See classes listed above for their required MIBs.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $dell->os_ver()

(C<productIdentificationVersion>)

=item $dell->dell_id_name()

(C<productIdentificationDisplayName>)

=item $dell->model()

Returns model type.  Returns numeric from
(C<productIdentificationDisplayName>) if available, otherwise if returns
description().

=item $dell->vendor()

Returns 'dell', 'dlink', or 'ibm' based upon the IANA enterprise number in
id().  Defaults to 'dlink'.

=item $dell->os()

Returns 'dell', 'dlink', or 'ibm' based upon the IANA enterprise number in
id().  Defaults to 'dlink'.

=item $dell->fan()

Return the status of all fans from the F<Dell-Vendor-MIB>

=item $dell->ps1_type()

Return the type of the first power supply from the F<Dell-Vendor-MIB>

=item $dell->ps2_type()

Return the type of the second power supply from the F<Dell-Vendor-MIB>

=item $dell->ps1_status()

Return the status of the first power supply from the F<Dell-Vendor-MIB>

=item $dell->ps2_status()

Return the status of the second power supply from the F<Dell-Vendor-MIB>

=back

=head2 Overrides

=over

=item $dell->serial()

Returns serial number. Returns (C<rlPhdUnitGenParamSerialNum>) if available,
otherwise uses the Layer3 serial method.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 RADLAN Interface Table (C<swIfTable>)

=over

=item $dell->dell_duplex_admin()

(C<swIfDuplexAdminMode>)

=item $dell->dell_duplex()

(C<swIfDuplexOperMode>)

=item $dell->dell_tag_mode()

(C<swIfTaggedMode>)

=item $dell->dell_i_type()

(C<swIfType>)

=item $dell->dell_fc_admin()

(C<swIfFlowControlMode>)

=item $dell->dell_speed_admin()

(C<swIfSpeedAdminMode>)

=item $dell->dell_auto()

(C<swIfSpeedDuplexAutoNegotiation>)

=item $dell->dell_fc()

(C<swIfOperFlowControlMode>)

=back

=head2 Overrides

=over

=item $dell->interfaces()

Returns the map between SNMP Interface Identifier (iid) and physical port
name.  Uses name if available instead of description since descriptions are 
sometimes not unique.

=item $dell->i_duplex_admin()

Returns reference to hash of iid to current link administrative duplex
setting.

=item $dell->qb_fdb_index()

Returns nothing to work around incorrect indexing of C<dot1qTpFdbTable>

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"TABLE METHODS"> for details.

=cut
