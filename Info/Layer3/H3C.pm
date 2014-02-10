# SNMP::Info::Layer3::H3C
#
# Copyright (c) 2012 Jeroen van Ingen
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

package SNMP::Info::Layer3::H3C;

use strict;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::LLDP;

@SNMP::Info::Layer3::H3C::ISA       = qw/SNMP::Info::LLDP SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::H3C::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.12';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::LLDP::MIBS,
    'HH3C-LswDEVM-MIB'     => 'hh3cDevMFanStatus',
    'HH3C-LswINF-MIB'      => 'hh3cSlotPortMax',
    'HH3C-LSW-DEV-ADM-MIB' => 'hh3cLswSysVersion',
    'HH3C-PRODUCT-ID-MIB'  => 'hh3c-s5500-28C-EI',
    'HH3C-ENTITY-VENDORTYPE-OID-MIB' => 'hh3cevtOther',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,
    'fan' => 'hh3cDevMFanStatus.1',
    'ps1_status' => 'hh3cDevMPowerStatus.1',
    'ps2_status' => 'hh3cDevMPowerStatus.2',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::LLDP::FUNCS,
    i_duplex_admin => 'hh3cifEthernetDuplex',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::LLDP::MUNGE,
);

sub vendor {
    my $h3c = shift;
    my $mfg = $h3c->entPhysicalMfgName(1) || {};
    return $mfg->{1};
}

sub os {
    my $h3c = shift;
    my $descr   = $h3c->description();

    return $1 if ( $descr =~ /(\S+)\s+Platform Software/ );
    return;
}

sub os_ver {
    my $h3c = shift;
    my $descr   = $h3c->description();
#    my $version = $h3c->hh3cLswSysVersion(); # Don't use, indicates base version only, no release details
    my $ver_release = $h3c->entPhysicalSoftwareRev(2) || {};
    my $os_ver  = undef;

    $os_ver = "$1 $2" if ( $descr =~ /Software Version ([^,]+),.*(Release\s\S+)/i );

    return $ver_release->{2} || $os_ver;
}

sub i_ignore {
    my $l3      = shift;
    my $partial = shift;

    my $interfaces = $l3->interfaces($partial) || {};

    my %i_ignore;
    foreach my $if ( keys %$interfaces ) {

        # lo0 etc
        if ( $interfaces->{$if} =~ /\blo\d*\b/i ) {
            $i_ignore{$if}++;
        }
    }
    return \%i_ignore;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::H3C - SNMP Interface to L3 Devices, H3C & HP A-series

=head1 AUTHORS

Jeroen van Ingen

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $h3c = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $h3c->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for H3C & HP A-series devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::LLDP

=back

=head2 Required MIBs

=over

=item F<HH3C-LswDEVM-MIB>

=item F<HH3C-LswINF-MIB>

=item F<HH3C-LSW-DEV-ADM-MIB>

=item F<HH3C-PRODUCT-ID-MIB>

=item F<HH3C-ENTITY-VENDORTYPE-OID-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

See L<SNMP::Info::LLDP> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $h3c->vendor()

Returns value for C<entPhysicalMfgName.1>.

=item $h3c->os()

Returns the OS extracted from C<sysDescr>.

=item $h3c->os_ver()

Returns the software version. Either C<entPhysicalSoftwareRev.2> or extracted from 
C<sysDescr>.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Globals imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $h3c->i_ignore()

Returns reference to hash.  Increments value of IID if port is to be ignored.

Ignores loopback

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP> for details.

=cut
