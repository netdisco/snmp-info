package SNMP::Info::Layer3::Cambium;
#
# Copyright (c) 2026 Netdisco Contributors
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

use strict;
use warnings;

use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Cambium::ISA = qw/
    SNMP::Info::Layer3
    Exporter
/;
@SNMP::Info::Layer3::Cambium::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.975000';

# Cambium publishes the model mapping only in free-form DESCRIPTION text for
# cambiumHWInfo, not as machine-readable ASN.1 enums, so we keep a local lookup.
my %CAMBIUM_HW_SKU = (
    -1 => 'Not available',
    0 => '5 GHz Connectorized Radio with Sync',
    1 => '5 GHz Connectorized Radio',
    2 => '5 GHz Integrated Radio',
    3 => '2.4 GHz Connectorized Radio with Sync',
    4 => '2.4 GHz Connectorized Radio',
    5 => '2.4 GHz Integrated Radio',
    6 => '5 GHz Force 200 (ROW)',
    8 => '5 GHz Force 200 (FCC)',
    9 => '2.4 GHz Force 200',
    10 => 'ePMP 2000',
    11 => '5 GHz Force 180 (ROW)',
    12 => '5 GHz Force 180 (FCC)',
    13 => '5 GHz Force 190 Radio (ROW/ETSI)',
    14 => '5 GHz Force 190 Radio (FCC)',
    16 => '6 GHz Force 180 Radio',
    17 => '6 GHz Connectorized Radio with Sync',
    18 => '6 GHz Connectorized Radio',
    19 => '2.5 GHz Connectorized Radio with Sync',
    20 => '2.5 GHz Connectorized Radio',
    22 => '5 GHz Force 130 Radio',
    23 => '2.4 GHz Force 130 Radio',
    24 => '5 GHz Force 200L Radio',
    25 => '5 GHz Force 200L Radio V2',
    33 => '5 GHz PTP550 Integrated Radio',
    34 => '5 GHz PTP550 Connectorized Radio',
    35 => '5 GHz Force 300-25 Radio (FCC)',
    36 => '5 GHz Force 300-25 Radio (ROW/ETSI)',
    37 => 'ePMP3000 (FCC)',
    38 => '5 GHz Force 300-16 Radio (FCC)',
    39 => '5 GHz Force 300-16 Radio (ROW/ETSI)',
    40 => 'ePMP3000 (ROW/ETSI)',
    41 => '5 GHz PTP 550E Integrated Radio',
    42 => '5 GHz PTP 550E Connectorized Radio',
    43 => '5 GHz ePMP3000L (FCC)',
    44 => '5 GHz ePMP3000L (ROW/ETSI)',
    45 => '5 GHz Force 300 Connectorized Radio without GPS (FCC)',
    46 => '5 GHz Force 300 Connectorized Radio without GPS (ROW/ETSI)',
    47 => '5 GHz Force 300-13 Radio (FCC)',
    48 => '5 GHz Force 300-13 Radio (ROW/ETSI)',
    49 => '5 GHz Force 300-19 Radio (FCC)',
    50 => '5 GHz Force 300-19 Radio (ROW/ETSI)',
    51 => '5 GHz Force 300-19R IP67 Radio (ROW/ETSI)',
    52 => '5 GHz Force 300-19R IP67 Radio (FCC)',
    53 => '5 GHz ePMP Client MAXrP IP67 Radio (FCC)',
    54 => '5 GHz ePMP Client MAXrP IP67 Radio (ROW/ETSI)',
    55 => '5 GHz Force 300-25 Radio V2 (FCC)',
    58 => '5 GHz Force 300-25L Radio',
    59 => '5 GHz Force 300 CSML Connectorized Radio',
    60 => '5 GHz Force 300-25L Radio V2',
    61 => '5 GHz Force 300-13L Radio',
    62 => '5 GHz ePMP MP 3000',
    100 => '(0xe855) ePMP Elevate NSM5-XW',
    110 => '(0xe845) ePMP Elevate NSlocoM5-XW',
    111 => '(0xe8a2) ePMP Elevate NSlocoM2-XW',
    112 => '(0xe867) ePMP Elevate NSlocoM2-V2-XW',
    113 => '(0xe866) ePMP Elevate NSlocoM2-V3-XW',
    120 => '(0xe6b5) ePMP Elevate RM5-XW-V1',
    121 => '(0xe3b5) ePMP Elevate RM5-XW-V2',
    130 => '(0xe815) ePMP Elevate NBE-M5-16-XW',
    131 => '(0xe825) ePMP Elevate NBE-M5-19-XW',
    132 => '(0xe812) ePMP Elevate NBE-M2-13-XW',
    140 => 'ePMP Elevate SXTLITE5 BOARD',
    141 => 'ePMP Elevate INTELBRAS BOARD',
    142 => 'ePMP Elevate LHG5 BOARD',
    143 => 'ePMP Elevate Disc Lite BOARD',
    144 => 'ePMP Elevate 911L BOARD',
    145 => 'ePMP Elevate Sextant BOARD',
    150 => '(0xe3e5) ePMP Elevate PBE-M5-300-XW',
    151 => '(0xe4e5) ePMP Elevate PBE-M5-400-XW',
    152 => '(0xe885) ePMP Elevate PBE-M5-620-XW',
    153 => '(0xe2c2) ePMP Elevate PBE-M2-400-XW',
    154 => '(0xe6e5) ePMP Elevate PBE-M5-400-ISO-XW',
    155 => '(0xe5e5) ePMP Elevate PBE-M5-300-ISO-XW',
    156 => '(0xe7e5) ePMP Elevate PBE-M5-600-ISO-XW',
    160 => '(0xe835) ePMP Elevate AG-HP-5G-XW',
    161 => '(0xe832) ePMP Elevate AG-HP-2G-XW',
    162 => '(0xe865) ePMP Elevate LB-M5-23-XW',
    170 => '(0xe005) ePMP Elevate NSM5-XM-V1',
    171 => '(0xe805) ePMP Elevate NSM5-XM-V2',
    173 => '(0xe012) ePMP Elevate NS-M2-V1',
    176 => '(0xe002) ePMP Elevate NS-M2-V2',
    180 => '(0xe0a5) ePMP Elevate NSlocoM5-XM-V1',
    181 => '(0xe8a5) ePMP Elevate NSlocoM5-XM-V2',
    183 => '(0xe0a2) ePMP Elavate NSloco-M2',
    193 => '(0xe2b5) ePMP Elevate NB-5G22-XM',
    194 => '(0xe2e5) ePMP Elevate NB-5G25-XM',
    195 => '(0xe235) ePMP Elevate NB-XM',
    196 => '(0xe2b2) ePMP Elevate NB-M2-V1-XM',
    197 => '(0xe232) ePMP Elevate NB-M2-V2-XM',
    200 => 'ePMP Elevate INTELBRAS WOM-5A-MiMo BOARD',
    201 => 'ePMP Elevate INTELBRAS WOM-5A-23 BOARD',
    220 => '(0xe006) ePMP Elevate NS-M6',
    230 => '(0xe215) ePMP Elevate AG-M5-23-XM',
    231 => '(0xe245) ePMP Elevate AG-M5-28-XM',
    232 => '(0xe255) ePMP Elevate AG-HP-5G-XM',
    233 => '(0xe212) ePMP Elevate AG-M2-16-XM',
    234 => '(0xe242) ePMP Elevate AG-M2-20-XM',
    235 => '(0xe252) ePMP Elevate AG-M2-HP-XM',
    236 => '(0xe202) ePMP Elevate BM-M2-HP-XM',
    237 => '(0xe205) ePMP Elevate BM-M5-HP-XM',
    241 => '(0xe105) ePMP Elevate RM5-V1-XM',
    242 => '(0xe1b5) ePMP Elevate RM5-V2-XM',
    243 => '(0xe1c5) ePMP Elevate RM5-V3-XM',
    244 => '(9xe8b5) ePMP Elevate RM5-V4-XM',
    245 => '(0xe102) ePMP Elevate RM2-V1-XM',
    246 => '(0xe112) ePMP Elevate RM2-V2-XM',
    247 => '(0xe1b2) ePMP Elevate RM2-V3-XM',
    248 => '(0xe1c2) ePMP Elevate RM2-V4-XM',
    53264 => '6 GHz ePMP 4600 4x4 (ROW/FCC)',
    53280 => '5 GHz ePMP 4500 8x8 (ROW)',
    53281 => '5 GHz ePMP 4500C 8x8 (ROW)',
    53288 => '5 GHz ePMP 4500 8x8 (FCC)',
    53289 => '5 GHz ePMP 4500C 8x8 (FCC)',
    53296 => '6 GHz ePMP 4600L (ROW/FCC)',
    53344 => '5 GHz ePMP 4500L (ROW)',
    53352 => '5 GHz ePMP 4500L (FCC)',
    53376 => '5 GHz cnPilot Tiger',
    53504 => '5 GHz Force 425 (ROW)',
    53505 => '5 GHz Force 400C (ROW)',
    53512 => '5 GHz Force 425 (FCC)',
    53513 => '5 GHz Force 400C (FCC)',
    53520 => '6 GHz Force 4600C (ROW/FCC)',
    53536 => '5 GHz Force 4516 (ROW)',
    53537 => '5 GHz Force 4525 (ROW)',
    53538 => '5 GHz Force 4525L (ROW)',
    53544 => '5 GHz Force 4516 (FCC)',
    53545 => '5 GHz Force 4525 (FCC)',
    53552 => '6 GHz Force 4616 (ROW)',
    53553 => '6 GHz Force 4625 (ROW)',
    53560 => '6 GHz Force 4616 USB GPS Radio (FCC)',
    53561 => '6 GHz Force 4625 USB GPS Radio (FCC)',
);

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'CAMBIUM-PMP80211-MIB' => 'cambiumCurrentSWInfo',
    'CAMBIUM-MIB'          => 'cambiumAPName',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'cambium_os_ver'      => 'cambiumCurrentSWInfo',
    'cambium_hw_info'     => 'cambiumHWInfo',
    'cambium_esn'         => 'cambiumESN',
    'cambium_epmp_msn'    => 'cambiumEPMPMSN',
    'cambium_lan_mac'     => 'cambiumLANMACAddress',
    'cambium_device_name' => 'cambiumEffectiveDeviceName',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
);

sub vendor {
    return 'Cambium Networks';
}

sub os_ver {
    my $self = shift;
    return $self->cambium_os_ver();
}

sub os {
    return 'Cambium';
}

sub model {
    my $self = shift;
    my $hw = $self->cambium_hw_info();
    my $sku_model = undef;
    if ( defined $hw and $hw ne '' and $hw ne '-1' ) {
        $sku_model = $CAMBIUM_HW_SKU{$hw} || $hw;
    }

    my $sysoid_model = undef;
    my $id = $self->id();
    if ( defined $id and $id ne '' ) {
        my $translated = SNMP::translateObj($id);
        my $source = defined $translated ? $translated : $id;
        $source =~ s/^\.+//;
        my @parts = split /\./, $source;
        $sysoid_model = $parts[-1] if @parts;
        $sysoid_model = undef if (defined $sysoid_model and $sysoid_model =~ /^\d+$/);
    }

    if ( defined $sku_model and $sku_model ne '' ) {
        if ( defined $sysoid_model and $sysoid_model ne '' ) {
            return $sku_model
              if ( lc($sku_model) eq lc($sysoid_model) );
            return $sku_model . ' (' . $sysoid_model . ')';
        }
        return $sku_model;
    }

    return $sysoid_model if ( defined $sysoid_model and $sysoid_model ne '' );
    return $self->SUPER::model();
}

sub mac {
    my $self = shift;
    return $self->cambium_lan_mac() || $self->SUPER::mac();
}

sub name {
    my $self = shift;
    return $self->cambium_device_name() || $self->SUPER::name();
}

sub serial {
    my $self = shift;
    my $epmp = $self->cambium_epmp_msn();
    my $esn  = $self->cambium_esn();
    my @parts = grep { defined $_ && $_ ne '' } ($epmp, $esn);
    if (@parts) {
        return join(' ', @parts);
    } else {
        return $self->SUPER::serial();
    }
}

1;

__END__

=head1 NAME

SNMP::Info::Layer3::Cambium - SNMP Interface to Cambium devices

=head1 AUTHORS

Christian Ramseyer and Netdisco Contributors

=head1 SYNOPSIS

    # Let SNMP::Info determine the correct subclass for you.
    my $self = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

    my $class      = $self->class();
    print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Cambium devices (ePMP/cnPilot).

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<CAMBIUM-PMP80211-MIB>

=item F<CAMBIUM-MIB>

=back

=head2 Inherited MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP.

=over

=item $self->os()

Returns 'Cambium'.

=item $self->os_ver()

Returns the value from C<cambiumCurrentSWInfo>.

=item $self->vendor()

Returns 'Cambium Networks'.

=item $self->model()

Returns the value from C<cambiumHWInfo> if present; otherwise falls back to the
resolved C<sysObjectID>. Known SKU values are returned as human-readable model
strings. If available, the terminal symbolic token from C<sysObjectID> is
appended (for example C<ePMPxorn19rip67row>).

=item $self->mac()

Returns C<cambiumLANMACAddress> if present, otherwise falls back to the default
Layer3 MAC.

=item $self->name()

Returns C<cambiumEffectiveDeviceName> if present, otherwise falls back to the
default Layer3 name.

=item $self->serial()

Returns a string composed of C<cambiumEPMPMSN> and C<cambiumESN> separated by a
space when both are present. If only one of these is available, returns that
value. If neither is present, falls back to the default Layer3 serial.

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
