# SNMP::Info::Layer3::PacketFront
#
# Copyright (c) 2011 Jeroen van Ingen
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

package SNMP::Info::Layer3::PacketFront;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::PacketFront::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::PacketFront::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.70';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'UCD-SNMP-MIB'             => 'versionTag',
    'NET-SNMP-TC'              => 'netSnmpAliasDomain',
    'HOST-RESOURCES-MIB'       => 'hrSystem',
    'PACKETFRONT-PRODUCTS-MIB' => 'drg100',
    'PACKETFRONT-DRG-MIB'      => 'productName',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'snmpd_vers'     => 'versionTag',
    'hrSystemUptime' => 'hrSystemUptime',
);

%FUNCS = ( %SNMP::Info::Layer3::FUNCS, );

%MUNGE = ( %SNMP::Info::Layer3::MUNGE, );

sub vendor {
    return 'packetfront';
}

sub os {
    # Only DRGOS for now (not tested with other product lines than DRG series)
    my $pfront = shift;
    my $descr   = $pfront->description();
    if ( $descr =~ /drgos/i ) {
        return 'drgos';
    } else {
        return;
    }
}

sub os_ver {
    my $pfront = shift;
    my $descr   = $pfront->description();
    my $os_ver  = undef;

    if ( $descr =~ /Version:\sdrgos-(\w+)-([\w\-\.]+)/ ) {
        $os_ver = $2;
    }
    return $os_ver;
}

sub serial {
    my $pfront = shift;
    return $pfront->productSerialNo();
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

sub layers {
    my $pfront = shift;

    my $layers = $pfront->SUPER::layers();
    # Some models or software versions don't report L2 properly
    # so add L2 capability to the output if the device has bridge ports.
    my $bports = $pfront->b_ports();

    if ($bports) {
        my $l = substr $layers, 6, 1, "1";
    }

    return $layers;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::PacketFront - SNMP Interface to PacketFront devices

=head1 AUTHORS

Jeroen van Ingen
initial version based on SNMP::Info::Layer3::NetSNMP by Bradley Baetz and Bill Fenner

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $pfront = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $pfront->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for PacketFront devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<UCD-SNMP-MIB>

=item F<NET-SNMP-TC>

=item F<HOST-RESOURCES-MIB>

=item F<PACKETFRONT-PRODUCTS-MIB>

=item F<PACKETFRONT-DRG-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $pfront->vendor()

Returns C<'packetfront'>.

=item $pfront->os()

Returns the OS extracted from C<sysDescr>.

=item $pfront->os_ver()

Returns the software version extracted from C<sysDescr>.

=item $pfront->serial()

Returns the value of C<productSerialNo>.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $pfront->i_ignore()

Returns reference to hash.  Increments value of IID if port is to be ignored.

Ignores loopback

=item $pfront->layers()

L2 capability isn't always reported correctly by the device itself; what the
device reports is augmented with L2 capability if the device has bridge ports.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.


=cut
