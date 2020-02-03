# SNMP::Info::Layer3::Contivity
#
# Copyright (c) 2010 Eric Miller
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

package SNMP::Info::Layer3::Contivity;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Contivity::ISA
    = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Contivity::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %FUNCS, %MIBS, %MUNGE);

$VERSION = '3.70';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
);

%FUNCS = (
  %SNMP::Info::Layer3::FUNCS,
);

%MUNGE = (
  %SNMP::Info::Layer3::MUNGE,
);

sub layers {
    return '00000100';
}

sub vendor {
    return 'avaya';
}

sub model {
    my $contivity = shift;
    my $e_model = $contivity->e_model() || {};

    my $model = $e_model->{1} || undef;

    return $1 if ( defined $model and $model =~ /(CES\d+|NVR\d+)/i );
    return;
}

sub os {
    return 'contivity';
}

sub os_ver {
    my $contivity = shift;
    my $descr     = $contivity->description();
    return unless defined $descr;

    if ( $descr =~ m/V(\d+_\d+\.\d+)/i ) {
        return $1;
    }
    return;
}

sub mac {
    my $contivity = shift;
    my $i_mac     = $contivity->i_mac();

    # Return Interface MAC
    foreach my $entry ( sort keys %$i_mac ) {
        my $sn = $i_mac->{$entry};
        next unless $sn;
        return $sn;
    }
    return;
}

sub serial {
    my $contivity = shift;
    my $e_serial = $contivity->e_serial() || {};

    my $serial = $e_serial->{1} || undef;

    return $1 if ( defined $serial and $serial =~ /(\d+)/ );
    return;
}

sub interfaces {
    my $contivity = shift;
    my $partial   = shift;

    my $description = $contivity->i_description($partial) || {};

    my %interfaces = ();
    foreach my $iid ( keys %$description ) {
        my $desc = $description->{$iid};

        # Skip everything except Ethernet interfaces
        next unless ( defined $desc and $desc =~ /fe/i );

        $interfaces{$iid} = $desc;
    }
    return \%interfaces;
}

sub i_name {
    my $contivity = shift;
    my $partial   = shift;

    my $i_name2 = $contivity->orig_i_name($partial) || {};

    my %i_name;
    foreach my $iid ( keys %$i_name2 ) {
        my $name = $i_name2->{$iid};

        #Skip everything except Ethernet interfaces
        next unless ( defined $name and $name =~ /fe/i );

        $name = $1 if $name =~ /(fei\.\d+\.\d+)/;

        $i_name{$iid} = $name;
    }
    return \%i_name;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Contivity - SNMP Interface to Avaya/Nortel VPN Routers
(formerly Contivity Extranet Switches).

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $contivity = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $contivity->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for Avaya/Nortel VPN Routers (formerly Contivity
Extranet Switch).

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $contivity->vendor()

Returns 'avaya'

=item $contivity->model()

Returns the chassis name.

(C<entPhysicalModelName.1>)

=item $contivity->os()

Returns C<'contivity'>

=item $contivity->os_ver()

Returns the software version extracted from (C<sysDescr>).

=item $contivity->serial()

Returns the chassis serial number.

(C<entPhysicalSerialNum.1>)

=item $contivity->mac()

Returns the MAC address of the first Ethernet Interface.

=back

=head2 Overrides

=over

=item $contivity->layers()

Returns 00000100.  Contivity does not support bridge MIB, so override reported
layers.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $contivity->interfaces()

Returns reference to the map between IID and physical Port.  Skips loopback
and tunnel interfaces.

=item $contivity->i_name()

Interface Name field.  Skips loopback and tunnel interfaces.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
