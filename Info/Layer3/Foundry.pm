# SNMP::Info::Layer3::Foundry - SNMP Interface to Foundry devices
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

package SNMP::Info::Layer3::Foundry;

use strict;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::FDP;
use SNMP::Info::LLDP;

@SNMP::Info::Layer3::Foundry::ISA = qw/SNMP::Info::FDP SNMP::Info::LLDP
    SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Foundry::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %FUNCS %MIBS %MUNGE/;

$VERSION = '3.00_003';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::LLDP::MIBS,
    %SNMP::Info::FDP::MIBS,
    'FOUNDRY-SN-ROOT-MIB'         => 'foundry',
    'FOUNDRY-SN-AGENT-MIB'        => 'snChasPwrSupplyDescription',
    'FOUNDRY-SN-SWITCH-GROUP-MIB' => 'snSwGroupOperMode',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,
    %SNMP::Info::FDP::GLOBALS,
    'mac'        => 'ifPhysAddress.1',
    'chassis'    => 'entPhysicalDescr.1',
    'temp'       => 'snChasActualTemperature',
    'ps1_type'   => 'snChasPwrSupplyDescription.1',
    'ps1_status' => 'snChasPwrSupplyOperStatus.1',
    'fan'        => 'snChasFanOperStatus.1',
    'img_ver'    => 'snAgImgVer',
    'ch_serial'  => 'snChasSerNum',

);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::LLDP::FUNCS,
    %SNMP::Info::FDP::FUNCS,

    # FOUNDRY-SN-SWITCH-GROUP-MIB
    # snSwPortInfoTable - Switch Port Information Group
    'sw_index'  => 'snSwPortIfIndex',
    'sw_duplex' => 'snSwPortInfoChnMode',
    'sw_type'   => 'snSwPortInfoMediaType',
    'sw_speed'  => 'snSwPortInfoSpeed',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE, %SNMP::Info::LLDP::MUNGE,
    %SNMP::Info::FDP::MUNGE,
);

sub i_ignore {
    my $foundry = shift;
    my $partial = shift;

    my $interfaces = $foundry->interfaces($partial) || {};

    my %i_ignore;
    foreach my $if ( keys %$interfaces ) {
        if ( $interfaces->{$if} =~ /(tunnel|loopback|\blo\b|lb|null)/i ) {
            $i_ignore{$if}++;
        }
    }
    return \%i_ignore;
}

sub i_duplex {
    my $foundry = shift;
    my $partial = shift;

    my $sw_index  = $foundry->sw_index($partial);
    my $sw_duplex = $foundry->sw_duplex($partial);

    unless ( defined $sw_index and defined $sw_duplex ) {
        return $foundry->SUPER::i_duplex();
    }

    my %i_duplex;
    foreach my $sw_port ( keys %$sw_duplex ) {
        my $iid    = $sw_index->{$sw_port};
        my $duplex = $sw_duplex->{$sw_port};
        next if $duplex =~ /none/i;
        $i_duplex{$iid} = 'half' if $duplex =~ /half/i;
        $i_duplex{$iid} = 'full' if $duplex =~ /full/i;
    }
    return \%i_duplex;
}

sub model {
    my $foundry = shift;
    my $id      = $foundry->id();
    my $model   = &SNMP::translateObj($id);

    # EdgeIron
    if ( $id =~ /\.1991\.1\.[45]\./ ) {

        my $e_name = $foundry->e_name();

        # Find entity table entry for "unit.1"
        my $unit_iid = undef;
        foreach my $e ( keys %$e_name ) {
            my $name = $e_name->{$e} || '';
            $unit_iid = $e if $name eq 'unit.1';
        }

        # Find Model Name
        my $e_model = $foundry->e_model();
        if ( defined $e_model->{$unit_iid} ) {
            return $e_model->{$unit_iid};
        }
    }

    return $id unless defined $model;

    $model =~ s/^sn//;

    return $model;
}

sub os {
    return 'brocade';
}

sub vendor {
    return 'brocade';
}

sub os_ver {
    my $foundry = shift;

    return $foundry->img_ver() if ( defined $foundry->img_ver() );

    # Some older ones don't have this value,so we cull it from the description
    my $descr = $foundry->description();
    if ( $descr =~ m/Version (\d\S*)/ ) {
        return $1;
    }

    # EdgeIron
    my $e_name = $foundry->e_name();

    # find entity table entry for "stackmanaget.1"
    my $unit_iid = undef;
    foreach my $e ( keys %$e_name ) {
        my $name = $e_name->{$e} || '';
        $unit_iid = $e if $name eq 'stackmanaget.1';
    }

    if ( defined $unit_iid ) {

        # Find Model Name
        my $e_fwver = $foundry->e_fwver();
        if ( defined $e_fwver->{$unit_iid} ) {
            return $e_fwver->{$unit_iid};
        }
    }

    # See if we report from Flash if wouldn't report from running above
    return $foundry->snAgFlashImgVer() if ( defined $foundry->snAgFlashImgVer() );
    
    # Last resort
    return $foundry->SUPER::os_ver();

}

sub serial {
    my $foundry = shift;

    # Return chassis serial number if available
    return $foundry->ch_serial() if ( $foundry->ch_serial() );

    # If no chassis serial use first module serial
    my $mod_serials = $foundry->snAgentConfigModuleSerialNumber() || {};

    foreach my $mod ( sort keys %$mod_serials ) {
        my $serial = $mod_serials->{$mod} || '';
        next unless defined $serial;
        return $serial;
    }

    # EdgeIron
    my $e_name = $foundry->e_name();

    # find entity table entry for "unit.1"
    my $unit_iid = undef;
    foreach my $e ( keys %$e_name ) {
        my $name = $e_name->{$e} || '';
        $unit_iid = $e if $name eq 'unit.1';
    }

    if ( defined $unit_iid ) {

        # Look up serial of found entry.
        my $e_serial = $foundry->e_serial();
        return $e_serial->{$unit_iid} if defined $e_serial->{$unit_iid};
    }

    # Last resort
    return $foundry->SUPER::serial();
}

sub interfaces {
    my $foundry = shift;
    my $partial = shift;

    my $i_descr = $foundry->i_description($partial) || {};
    my $i_name  = $foundry->i_name($partial)        || {};

    # Use ifName for EdgeIrons else use ifDescr
    foreach my $iid ( keys %$i_name ) {
        my $name = $i_name->{$iid};
        next unless defined $name;
        $i_descr->{$iid} = $name
            if $name =~ /^port\d+/i;
    }

    return $i_descr;
}

# Reported hangs on a EdgeIron 24G
sub stp_p_state {
    my $foundry = shift;
    my $partial = shift;

    my $descr = $foundry->description();
    if ( $descr =~ m/\bEdgeIron 24G\b/ ) {
        return;
    }

    return $foundry->SUPER::stp_p_state($partial) || {};

}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Foundry - SNMP Interface to Brocade (Foundry) Network
Devices

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $foundry = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 1
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class = $foundry->class();

 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for Brocade (Foundry) Networks devices.

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above.

 my $foundry = new SNMP::Info::Layer3::Foundry(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3;

=item SNMP::Info::FDP;

=item SNMP::Info::LLDP;

=back

=head2 Required MIBs

=over

=item F<FOUNDRY-SN-ROOT-MIB>

=item F<FOUNDRY-SN-AGENT-MIB>

=item F<FOUNDRY-SN-SWITCH-GROUP-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::FDP/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::LLDP/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $foundry->model()

Returns model type.  Checks $foundry->id() against the F<FOUNDRY-SN-ROOT-MIB>
and removes 'C<sn>'.  EdgeIron models determined through F<ENTITY-MIB>.  

=item $foundry->vendor()

Returns 'brocade'

=item $foundry->os()

Returns 'brocade'

=item $foundry->os_ver()

Returns the software version

=item $foundry->mac()

Returns MAC Address of root port.

(C<ifPhysAddress.1>)

=item $foundry->chassis()

Returns Chassis type.

(C<entPhysicalDescr.1>)

=item $foundry->serial()

Returns serial number of device.

=item $foundry->temp()

Returns the chassis temperature

(C<snChasActualTemperature>)

=item $foundry->ps1_type()

Returns the Description for the power supply

(C<snChasPwrSupplyDescription.1>)

=item $foundry->ps1_status()

Returns the status of the power supply.

(C<snChasPwrSupplyOperStatus.1>)

=item $foundry->fan()

Returns the status of the chassis fan.

(C<snChasFanOperStatus.1>)

=item $foundry->img_ver()

Returns device image version.

(C<snAgImgVer.0>)

=item $foundry->ch_serial()

Returns chassis serial number.

(C<snChasSerNum.0>)

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::FDP

See documentation in L<SNMP::Info::FDP/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $foundry->interfaces()

Returns reference to hash of interface names to iids.

=item $foundry->i_ignore()

Returns reference to hash of interfaces to be ignored.

Ignores interfaces with descriptions of  tunnel,loopback,null 

=item $foundry->i_duplex()

Returns reference to hash of interface link duplex status. 

Crosses $foundry->sw_duplex() with $foundry->sw_index()

=item $foundry->stp_p_state()

"The port's current state as defined by application of the Spanning Tree
Protocol.

Skipped if device is an EdgeIron 24G due to reports of hangs.

(C<dot1dStpPortState>)

=back

=head2 Foundry Switch Port Information Table (C<snSwPortIfTable>)

=over

=item $foundry->sw_index()

Returns reference to hash.  Maps Table to Interface IID. 

(C<snSwPortIfIndex>)

=item $foundry->sw_duplex()

Returns reference to hash.   Current duplex status for switch ports. 

(C<snSwPortInfoChnMode>)

=item $foundry->sw_type()

Returns reference to hash.  Current Port Type .

(C<snSwPortInfoMediaType>)

=item $foundry->sw_speed()

Returns reference to hash.  Current Port Speed. 

(C<snSwPortInfoSpeed>)

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::FDP

See documentation in L<SNMP::Info::FDP/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"TABLE METHODS"> for details.

=cut
