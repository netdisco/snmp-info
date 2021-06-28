# SNMP::Info::Layer1::Cyclades
#
# Copyright (c) 2018 Eric Miller
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

package SNMP::Info::Layer1::Cyclades;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer1;

@SNMP::Info::Layer1::Cyclades::ISA       = qw/SNMP::Info::Layer1 Exporter/;
@SNMP::Info::Layer1::Cyclades::EXPORT_OK = qw//;

our ($VERSION, %FUNCS, %GLOBALS, %MIBS, %MUNGE, $AUTOLOAD);

$VERSION = '3.73';

%MIBS = (
    %SNMP::Info::Layer1::MIBS,
    'CYCLADES-ACS-SYS-MIB'    => 'cyACSversion',
    'CYCLADES-ACS5K-SYS-MIB'  => 'cyACS5Kversion',
    'CYCLADES-ACS-CONF-MIB'   => 'cyACSConf',
    'CYCLADES-ACS5K-CONF-MIB' => 'cyACS5KConf',
    'CYCLADES-ACS-INFO-MIB'   => 'cyACSInfo',
    'CYCLADES-ACS5K-INFO-MIB' => 'cyACS5KInfo',
    'ACS-MIB'                 => 'acs6016',
    'ACS8000-MIB'             => 'acs8048',
);

%GLOBALS = (

    %SNMP::Info::Layer1::GLOBALS,

    # CYCLADES-ACS-SYS-MIB
    'cy_os_ver'     => 'cyACSversion',
    'cy_model'      => 'cyACSpname',
    'cy_serial'     => 'cyACSDevId',
    'cy_ps1_status' => 'cyACSPw1',
    'cy_ps2_status' => 'cyACSPw2',

    # CYCLADES-ACS-CONF-MIB
    'cy_root_ip' => 'CYCLADES_ACS_CONF_MIB__cyEthIPaddr',

    # CYCLADES-ACS5K-SYS-MIB
    'cy5k_os_ver'     => 'cyACS5Kversion',
    'cy5k_model'      => 'cyACS5Kpname',
    'cy5k_serial'     => 'cyACS5KDevId',
    'cy5k_ps1_status' => 'cyACS5KPw1',
    'cy5k_ps2_status' => 'cyACS5KPw2',

    # CYCLADES-ACS5K-CONF-MIB
    'cy5k_root_ip'   => 'CYCLADES_ACS5K_CONF_MIB__cyEthIPaddr',

    # ACS-MIB
    'acs_os_ver'     => 'ACS_MIB__acsFirmwareVersion',
    'acs_model'      => 'ACS_MIB__acsProductModel',
    'acs_serial'     => 'ACS_MIB__acsSerialNumber',
    'acs_ps1_status' => 'ACS_MIB__acsPowerSupplyStatePw1',
    'acs_ps2_status' => 'ACS_MIB__acsPowerSupplyStatePw2',

    # ACS8000-MIB
    'acs8k_os_ver'     => 'ACS8000_MIB__acsFirmwareVersion',
    'acs8k_model'      => 'ACS8000_MIB__acsProductModel',
    'acs8k_serial'     => 'ACS8000_MIB__acsSerialNumber',
    'acs8k_ps1_status' => 'ACS8000_MIB__acsPowerSupplyStatePw1',
    'acs8k_ps2_status' => 'ACS8000_MIB__acsPowerSupplyStatePw2',
);

%FUNCS = (
    %SNMP::Info::Layer1::FUNCS,

    # CYCLADES-ACS-INFO-MIB::cyInfoSerialTable
    'cy_port_tty'   => 'CYCLADES_ACS_INFO_MIB__cyISPortTty',
    'cy_port_name'  => 'CYCLADES_ACS_INFO_MIB__cyISPortName',
    'cy_port_speed' => 'CYCLADES_ACS_INFO_MIB__cyISPortSpeed',
    'cy_port_cd'    => 'CYCLADES_ACS_INFO_MIB__cyISPortSigCD',

    # CYCLADES-ACS-CONF-MIB::cySerialPortTable
    'cy_port_socket' => 'CYCLADES_ACS_CONF_MIB__cySPortSocketPort',

    # CYCLADES-ACS5K-INFO-MIB::cyInfoSerialTable
    'cy5k_port_tty'   => 'CYCLADES_ACS5K_INFO_MIB__cyISPortTty',
    'cy5k_port_name'  => 'CYCLADES_ACS5K_INFO_MIB__cyISPortName',
    'cy5k_port_speed' => 'CYCLADES_ACS5K_INFO_MIB__cyISPortSpeed',
    'cy5k_port_cd'    => 'CYCLADES_ACS5K_INFO_MIB__cyISPortSigCD',

    # CYCLADES-ACS5K-CONF-MIB::cySerialPortTable
    'cy5k_port_socket' => 'CYCLADES_ACS5K_CONF_MIB__cySPortSocketPort',

    # ACS-MIB::acsSerialPortTable
    'acs_port_tty'   => 'ACS_MIB__acsSerialPortTableDeviceName',
    'acs_port_name'  => 'ACS_MIB__acsSerialPortTableName',
    'acs_port_speed' => 'ACS_MIB__acsSerialPortTableComSpeed',
    'acs_port_cd'    => 'ACS_MIB__acsSerialPortTableSignalStateDCD',

    # Equivalent to cySPortSocketPort doesn't exist in ACS-MIB
    # Use 'acsSerialPortTableDeviceName' as an equivalent, it just needs
    # to be unique so that we can differentiate between the index in the
    # acsSerialPortTable from ifIndex which are both integers
    # ACS-MIB::acsSerialPortTableEntry
    'acs_port_socket' => 'ACS_MIB__acsSerialPortTableDeviceName',

    # ACS8000-MIB::acsSerialPortTable
    'acs8k_port_tty'   => 'ACS8000_MIB__acsSerialPortTableDeviceName',
    'acs8k_port_name'  => 'ACS8000_MIB__acsSerialPortTableName',
    'acs8k_port_speed' => 'ACS8000_MIB__acsSerialPortTableComSpeed',
    'acs8k_port_cd'    => 'ACS8000_MIB__acsSerialPortTableSignalStateDCD',

    # Equivalent to cySPortSocketPort doesn't exist in ACS-MIB
    # Use 'acsSerialPortTableDeviceName' as an equivalent, it just needs
    # to be unique so that we can differentiate between the index in the
    # acsSerialPortTable from ifIndex which are both integers
    # ACS8000-MIB::acsSerialPortTableEntry
    'acs8k_port_socket' => 'ACS8000_MIB__acsSerialPortTableDeviceName',
);

%MUNGE = ( %SNMP::Info::Layer1::MUNGE, );

# These devices don't have a FDB and we probably don't want to poll for ARP
# cache so turn off reported L2/L3.
sub layers {
    return '01000001';
}

sub os {
    return 'avocent';
}

# Use "short circuit" to return the first MIB instance that returns data to
# reduce network communications
# We'll try newest (acs*) first assuming those are most likely deployed
sub os_ver {
    my $cyclades = shift;

    return
           $cyclades->acs_os_ver()
        || $cyclades->acs8k_os_ver()
        || $cyclades->cy5k_os_ver()
        || $cyclades->cy_os_ver()
        || undef;
}

sub vendor {
    return 'vertiv';
}

sub model {
    my $cyclades = shift;

    my $model
        = $cyclades->acs_model()
        || $cyclades->acs8k_model()
        || $cyclades->cy5k_model()
        || $cyclades->cy_model()
        || undef;

    return lc($model) if ( defined $model );

    my $id   = $cyclades->id();
    my $prod = SNMP::translateObj($id);

    return $prod || $id;
}

sub serial {
    my $cyclades = shift;

    return
           $cyclades->acs_serial()
        || $cyclades->acs8k_serial()
        || $cyclades->cy5k_serial()
        || $cyclades->cy_serial()
        || undef;
}

sub root_ip {
    my $cyclades = shift;

    return
           $cyclades->cy5k_root_ip()
        || $cyclades->cy_root_ip()
        || undef;
}

sub ps1_status {
    my $cyclades = shift;

    return
           $cyclades->acs_ps1_status()
        || $cyclades->acs8k_ps1_status()
        || $cyclades->cy5k_ps1_status()
        || $cyclades->cy_ps1_status()
        || undef;
}

sub ps2_status {
    my $cyclades = shift;

    return
           $cyclades->acs_ps2_status()
        || $cyclades->acs8k_ps2_status()
        || $cyclades->cy5k_ps2_status()
        || $cyclades->cy_ps2_status()
        || undef;
}

# Extend interface methods to include serial ports
#
# Partials don't really help in this class, but implemented
# for consistency

sub i_index {
    my $cyclades = shift;
    my $partial  = shift;

    my $orig_index = $cyclades->orig_i_index($partial) || {};
    my $cy_index
        = $cyclades->acs_port_socket()
        || $cyclades->acs8k_port_socket()
        || $cyclades->cy5k_port_socket()
        || $cyclades->cy_port_socket()
        || {};

    my %i_index;
    foreach my $iid ( keys %$orig_index ) {
        my $index = $orig_index->{$iid};
        next unless defined $index;

        $i_index{$iid} = $index;
    }

    # Use alternative labeling system for the serial port, listening socket
    # to avoid conflicts with ifIndex.
    foreach my $iid ( keys %$cy_index ) {
        my $index = $cy_index->{$iid};
        next unless defined $index;
        next if ( defined $partial and $index !~ /^$partial$/ );

        $i_index{$index} = $index;
    }

    return \%i_index;
}

sub interfaces {
    my $cyclades = shift;
    my $partial  = shift;

    my $i_descr = $cyclades->orig_i_description($partial) || {};
    my $cy_index
        = $cyclades->acs_port_socket()
        || $cyclades->acs8k_port_socket()
        || $cyclades->cy5k_port_socket()
        || $cyclades->cy_port_socket()
        || {};
    my $cy_p_tty
        = $cyclades->acs_port_tty()
        || $cyclades->acs8k_port_tty()
        || $cyclades->cy5k_port_tty()
        || $cyclades->cy_port_tty()
        || {};

    my %if;
    foreach my $iid ( keys %$i_descr ) {
        my $descr = $i_descr->{$iid};
        next unless defined $descr;

        $if{$iid} = $descr;
    }

    foreach my $iid ( keys %$cy_p_tty ) {
        my $index = $cy_index->{$iid};
        next unless defined $index;
        next if ( defined $partial and $index !~ /^$partial$/ );
        my $name = $cy_p_tty->{$iid};
        next unless defined $name;

        $if{$index} = $name;
    }

    return \%if;
}

sub i_speed {
    my $cyclades = shift;
    my $partial  = shift;

    my $i_speed    = $cyclades->orig_i_speed($partial) || {};
    my $cy_index
        = $cyclades->acs_port_socket()
        || $cyclades->acs8k_port_socket()
        || $cyclades->cy5k_port_socket()
        || $cyclades->cy_port_socket()
        || {};
    my $cy_p_speed
        = $cyclades->acs_port_speed()
        || $cyclades->acs8k_port_speed()
        || $cyclades->cy5k_port_speed()
        || $cyclades->cy_port_speed()
        || {};

    my %i_speed;
    foreach my $iid ( keys %$i_speed ) {
        my $speed = $i_speed->{$iid};
        next unless defined $speed;

        $i_speed{$iid} = $speed;
    }

    foreach my $iid ( keys %$cy_p_speed ) {
        my $index = $cy_index->{$iid};
        next unless defined $index;
        next if ( defined $partial and $index !~ /^$partial$/ );
        my $speed = $cy_p_speed->{$iid};
        next unless defined $speed;

        $i_speed{$index} = $speed;
    }

    return \%i_speed;
}

sub i_up {
    my $cyclades = shift;
    my $partial  = shift;

    my $i_up     = $cyclades->orig_i_up($partial) || {};
    my $cy_index
        = $cyclades->acs_port_socket()
        || $cyclades->acs8k_port_socket()
        || $cyclades->cy5k_port_socket()
        || $cyclades->cy_port_socket()
        || {};
    my $cy_p_up
        = $cyclades->acs_port_cd()
        || $cyclades->acs8k_port_cd()
        || $cyclades->cy5k_port_cd()
        || $cyclades->cy_port_cd()
        || {};

    my %i_up;
    foreach my $iid ( keys %$i_up ) {
        my $up = $i_up->{$iid};
        next unless defined $up;

        $i_up{$iid} = $up;
    }

    foreach my $iid ( keys %$cy_p_up ) {
        my $index = $cy_index->{$iid};
        next unless defined $index;
        next if ( defined $partial and $index !~ /^$partial$/ );
        my $up = $cy_p_up->{$iid};
        next unless defined $up;

        $i_up{$index} = $up;
    }

    return \%i_up;
}

sub i_description {
    my $cyclades = shift;
    my $partial  = shift;

    my $i_desc    = $cyclades->orig_i_description($partial) || {};
    my $cy_index
        = $cyclades->acs_port_socket()
        || $cyclades->acs8k_port_socket()
        || $cyclades->cy5k_port_socket()
        || $cyclades->cy_port_socket()
        || {};
    my $cy_p_desc
        = $cyclades->acs_port_name()
        || $cyclades->acs8k_port_name()
        || $cyclades->cy5k_port_name()
        || $cyclades->cy_port_name()
        || {};

    my %descr;
    foreach my $iid ( keys %$i_desc ) {
        my $desc = $i_desc->{$iid};
        next unless defined $desc;

        $descr{$iid} = $desc;
    }

    foreach my $iid ( keys %$cy_p_desc ) {
        my $index = $cy_index->{$iid};
        next unless defined $index;
        next if ( defined $partial and $index !~ /^$partial$/ );
        my $desc = $cy_p_desc->{$iid};
        next unless defined $desc;

        $descr{$index} = $desc;
    }

    return \%descr;
}

sub i_name {
    my $cyclades = shift;
    my $partial  = shift;

    my $i_name    = $cyclades->orig_i_name($partial) || {};
    my $cy_index
        = $cyclades->acs_port_socket()
        || $cyclades->acs8k_port_socket()
        || $cyclades->cy5k_port_socket()
        || $cyclades->cy_port_socket()
        || {};
    my $cy_p_desc
        = $cyclades->acs_port_name()
        || $cyclades->acs8k_port_name()
        || $cyclades->cy5k_port_name()
        || $cyclades->cy_port_name()
        || {};

    my %i_name;
    foreach my $iid ( keys %$i_name ) {
        my $name = $i_name->{$iid};
        next unless defined $name;

        $i_name{$iid} = $name;
    }

    foreach my $iid ( keys %$cy_p_desc ) {
        my $index = $cy_index->{$iid};
        next unless defined $index;
        next if ( defined $partial and $index !~ /^$partial$/ );
        my $name = $cy_p_desc->{$iid};
        next unless defined $name;

        $i_name{$index} = $name;
    }

    return \%i_name;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer1::Cyclades - SNMP Interface to Cyclades/Avocent terminal
servers

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

    #Let SNMP::Info determine the correct subclass for you.

    my $cyclades = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        )

    or die "Can't connect to DestHost.\n";

    my $class = $cyclades->class();
    print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a
Cyclades/Avocent device through SNMP.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer1

=back

=head2 Required MIBs

=over

=item F<ACS-MIB>

=item F<ACS6000-MIB>

=item F<CYCLADES-ACS-SYS-MIB>

=item F<CYCLADES-ACS-CONF-MIB>

=item F<CYCLADES-ACS-INFO-MIB>

=item F<CYCLADES-ACS5K-SYS-MIB>

=item F<CYCLADES-ACS5K-CONF-MIB>

=item F<CYCLADES-ACS5K-INFO-MIB>

=back

=head2 Inherited MIBs

See L<SNMP::Info::Layer1/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $cyclades->os_ver()

(C<acsFirmwareVersion>), (C<cyACS5Kversion>), or (C<cyACSversion>)

=item $cyclades->serial()

(C<acsSerialNumber>), (C<cyACS5KDevId>), or (C<cyACSDevId>)

=item $cyclades->root_ip()

(C<cyEthIPaddr>)

=item $cyclades->ps1_status()

(C<acsPowerSupplyStatePw1>), (C<cyACS5KPw1>), or (C<cyACSPw1>)

=item $cyclades->ps2_status()

(C<acsPowerSupplyStatePw2>), (C<cyACS5KPw2>), or (C<cyACSPw2>)

=back

=head2 Overrides

=over

=item $cyclades->layers()

Returns 01000001.  These devices don't have a FDB and we probably don't want
to poll for an ARP cache so turn off reported Layer 2 and Layer 3.

=item $cyclades->vendor()

Returns 'vertiv'

=item $cyclades->os()

Returns 'avocent'

=item $cyclades->model()

Returns lower case (C<cyACSpname>) or (C<acsProductModel>) if it exists
otherwise tries to reference $cyclades->id() to one of the MIBs listed above

=back

=head2 Globals imported from SNMP::Info::Layer1

See L<SNMP::Info::Layer1/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $cyclades->i_index()

Returns reference to map of IIDs to Interface index.

Extended to include serial ports.  Serial ports are indexed with the
alternative labeling system for the serial port, either the listening socket
port C<cySPortSocketPort> or C<acsSerialPortTableDeviceName> name to avoid
conflicts with C<ifIndex>.

=item $cyclades->interfaces()

Returns reference to map of IIDs to physical ports.  Extended to include
serial ports, C<acsSerialPortTableDeviceName> or C<cyISPortTty>.

=item $cyclades->i_speed()

Returns interface speed.  Extended to include serial ports,
C<acsSerialPortTableComSpeed> or C<cyISPortSpeed>.

=item $cyclades->i_up()

Returns link status for each port.  Extended to include serial ports,
C<acsSerialPortTableSignalStateDCD> or C<cyISPortSigCD>.

=item $cyclades->i_description()

Returns description of each port.  Extended to include serial ports,
C<acsSerialPortTableName> or C<cyISPortName>.

=item $cyclades->i_name()

Returns name of each port.  Extended to include serial ports,
C<acsSerialPortTableName> or C<cyISPortName>.

=back

=head2 Table Methods imported from SNMP::Info::Layer1

See L<SNMP::Info::Layer1/"TABLE METHODS"> for details.

=cut
