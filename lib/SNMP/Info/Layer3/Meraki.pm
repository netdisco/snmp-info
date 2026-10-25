# SNMP::Info::Layer3::Meraki
#
# Copyright (c) 2024 SNMP::Info Developers
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

# I whipped this up from the suggestions in the included link and other pm files.
# https://sourceforge.net/p/netdisco/mailman/message/37257000/
# - custom addition 4/25/24

package SNMP::Info::Layer3::Meraki;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Meraki::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Meraki::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.982000';

%MIBS = (
    %SNMP::Info::Layer2::MIBS, %SNMP::Info::Layer3::MIBS,
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS, %SNMP::Info::Layer3::GLOBALS,
);

%FUNCS = ( %SNMP::Info::Layer2::FUNCS, %SNMP::Info::Layer3::FUNCS, );

%MUNGE = ( %SNMP::Info::Layer2::MUNGE, %SNMP::Info::Layer3::MUNGE, );

sub layers {
    return '00000110';
}

sub vendor {
    return 'cisco meraki';
}

# Keep a fallback for devices whose sysDescr is unavailable or differs
# from the usual form. These are Meraki product OID assignments from the
# MERAKI-CLOUD-CONTROLLER-MIB product tree.
my %MERAKI_PRODUCT_MODELS = (
    1   => 'MINI',
    2   => 'ID2',
    3   => 'WPG',
    4   => 'OD1',
    5   => 'OD2',
    6   => 'OD3',
    7   => 'MO1',
    8   => 'SOL',
    9   => 'LR1',
    10  => 'MR11',
    11  => 'MR12',
    12  => 'MR14',
    13  => 'MR16',
    14  => 'MR24',
    15  => 'MR62',
    16  => 'MR66',
    17  => 'MR34',
    18  => 'MR18',
    19  => 'MR26',
    20  => 'MR32',
    21  => 'MR72',
    22  => 'MR42',
    23  => 'MR52',
    24  => 'MR53',
    25  => 'MR84',
    26  => 'MR30H',
    27  => 'MR33',
    28  => 'MR74',
    29  => 'MR70',
    30  => 'MR45',
    31  => 'MR55',
    32  => 'MR42E',
    33  => 'MR53E',
    34  => 'MR20',
    35  => 'GR10',
    36  => 'GR60',
    37  => 'MR36',
    38  => 'MR46',
    39  => 'MR46E',
    40  => 'MR56',
    41  => 'MR76',
    42  => 'MR86',
    43  => 'MR44',
    44  => 'MR36H',
    45  => 'MR28',
    46  => 'GR12',
    47  => 'GR62',
    48  => 'MR78',
    49  => 'MR57',
    50  => 'CW9162I',
    51  => 'CW9164I',
    52  => 'CW9166D1',
    53  => 'CW9166I',
    54  => 'CW9163E',
    55  => 'CW9176I',
    56  => 'CW9176D1',
    57  => 'CW9178I',
    58  => 'CW9172I',
    59  => 'CW9171I',
    60  => 'CW9172H',
    61  => 'CW9174E',
    62  => 'CW9174I',
    63  => 'CW9179F',
    100 => 'Z1',

    # In older Dashboard copies of the MIB only
    101 => 'MX70',
    102 => 'MX80',
    103 => 'MX90',
    104 => 'MX400',
    105 => 'MX600',
    106 => 'MX100',
    107 => 'MX64',
    108 => 'MX64W',
    109 => 'MX84',
    110 => 'MX65',
    111 => 'MX65W',
    112 => 'MX250',
    113 => 'MX450',
    114 => 'MX650',
    116 => 'Z3',
    117 => 'GX20',
    118 => 'MX67',
    119 => 'MX67W',
    120 => 'MX67C',
    121 => 'MX68',
    122 => 'MX68W',
    123 => 'MX68CW',
    124 => 'Z3C',
    125 => 'MX85',
    126 => 'MX75',
    127 => 'MX95',
    128 => 'MX105',
    129 => 'GX50',
    130 => 'Z4',
    132 => 'C8455-G2',
    200 => 'Meraki VM10',
    300 => 'MS22',
    301 => 'MS22P',
    302 => 'MS42',
    303 => 'MS42P',
    304 => 'MS220-8',
    305 => 'MS220-8P',
    306 => 'MS220-24',
    307 => 'MS220-24P',
    308 => 'MS220-48',
    309 => 'MS220-48LP',
    310 => 'MS220-48FP',
    311 => 'MS320-24',
    312 => 'MS320-24P',
    313 => 'MS320-48',
    314 => 'MS320-48LP',
    315 => 'MS320-48FP',
    316 => 'MS420-24',
    317 => 'MS420-48',
    318 => 'MS350-24',
    319 => 'MS350-24P',
    320 => 'MS350-48',
    321 => 'MS350-48LP',
    322 => 'MS350-48FP',
    323 => 'MS410-16',
    324 => 'MS410-32',
    325 => 'MS425-16',
    326 => 'MS425-32',
    327 => 'MS350-24X',
    328 => 'MS225-24',
    329 => 'MS225-24P',
    330 => 'MS225-48',
    331 => 'MS225-48LP',
    332 => 'MS225-48FP',
    333 => 'MS250-24',
    334 => 'MS250-24P',
    335 => 'MS250-48',
    336 => 'MS250-48LP',
    337 => 'MS250-48FP',
    338 => 'MS120-8',
    339 => 'MS120-8LP',
    340 => 'MS120-8FP',
    341 => 'MS120-24',
    342 => 'MS120-24P',
    343 => 'MS120-48',
    344 => 'MS120-48LP',
    345 => 'MS210-24',
    346 => 'MS210-24P',
    347 => 'MS210-48',
    348 => 'MS210-48LP',
    349 => 'MS210-48FP',
    356 => 'MS120-48FP',
    357 => 'MS355-24X',
    358 => 'MS355-24X2',
    359 => 'MS355-48X',
    360 => 'MS355-48X2',
    361 => 'MS450-12',
    362 => 'MS390-24',
    363 => 'MS390-24P',
    364 => 'MS390-24U',
    365 => 'MS390-24UX',
    366 => 'MS390-48',
    367 => 'MS390-48P',
    368 => 'MS390-48U',
    369 => 'MS390-48UX',
    370 => 'MS390-48UX2',
    371 => 'MS125-24',
    372 => 'MS125-24P',
    373 => 'MS125-48',
    374 => 'MS125-48LP',
    375 => 'MS125-48FP',

    # Cloud-managed Catalyst, not in the MIB; identified from Dashboard
    388 => 'C9300',
    395 => 'MS130-8',
    396 => 'MS130-8P',
    397 => 'MS130-8X',
    398 => 'MS130-12X',
    399 => 'MS130-24',
    400 => 'MS130-24P',
    401 => 'MS130-24X',
    402 => 'MS130-48',
    403 => 'MS130-48P',
    404 => 'MS130-48X',
    405 => 'MS130R-8P',
    443 => 'MS150-48MP-4X',
    444 => 'MS150-24T-4G',
    445 => 'MS150-24P-4G',
    446 => 'MS150-24T-4X',
    447 => 'MS150-24P-4X',
    448 => 'MS150-24MP-4X',
    449 => 'MS150-48T-4G',
    450 => 'MS150-48LP-4G',
    451 => 'MS150-48FP-4G',
    452 => 'MS150-48T-4X',
    453 => 'MS150-48LP-4X',
    454 => 'MS150-48FP-4X',
    483 => 'MS130-8P-I',
);

sub model {
    my $meraki = shift;
    my $descr = $meraki->description() || '';

    # Meraki sysDescr values begin with the product model, for example:
    # "Meraki MS120-8FP Cloud Managed PoE Switch".
    # Some APs prefix it with "=", as in "=Meraki MR28 Cloud Managed AP".
    if ( $descr =~ /^=?Meraki\s+(\S+)/i ) {
        my $product = $1;
        return $product
            unless $product =~ /^(?:cloud|managed|network|networks|security
                |wireless|access|switch|router)\b/ix;
    }

    # Otherwise map a registered Meraki sysObjectID suffix.
    my $id = $meraki->id() || '';
    if (    $id =~ /(?:^|\.)29671\.2\.(\d+)$/
        and exists $MERAKI_PRODUCT_MODELS{$1} )
    {
        return $MERAKI_PRODUCT_MODELS{$1};
    }

    return $meraki->SUPER::model();
}

sub serial1 {
    my $meraki = shift;
    my $serial = $meraki->entity_derived_serial();
    return $serial if defined $serial and $serial !~ /^\s*$/;
    return;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Meraki- SNMP Interface to L3 Devices, Meraki

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $meraki = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $meraki->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Meraki devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=head2 Overrides

=over

=item $meraki->layers()

Returns 00000110.

=item $meraki->vendor()

Returns C<'cisco meraki'>.

=item $meraki->model()

Returns the model token from C<sysDescr>, with a fallback mapping for
Meraki product sysObjectIDs listed in F<MERAKI-CLOUD-CONTROLLER-MIB>. For an
unmapped sysObjectID, returns the inherited L<SNMP::Info::Layer3> model.

=item $meraki->serial1()

Returns the ENTITY-MIB-derived serial when available, allowing consumers that
use C<serial1> as a chassis identifier to use the same serial already exposed
by the inherited C<serial> method.

=back

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=cut
