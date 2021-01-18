# SNMP::Info::Layer3::Genua
#
# Copyright (c) 2018 Netdisco Developers
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

package SNMP::Info::Layer3::Genua;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Genua::ISA       = qw/SNMP::Info::Layer3/;
@SNMP::Info::Layer3::Genua::EXPORT_OK = qw//;

our ($VERSION, %FUNCS, %GLOBALS, %MIBS, %MUNGE);

$VERSION = '3.71';

%MIBS = (%SNMP::Info::Layer3::MIBS);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'genua_os'          => '.1.3.6.1.4.1.3717.2.3.1.0',
    'genua_osver_rel'   => '.1.3.6.1.4.1.3717.2.3.3.0',
    'genua_osver_patch' => '.1.3.6.1.4.1.3717.2.3.4.0',
    'genua_model'       => '.1.3.6.1.4.1.3717.2.3.5.0',
    'genua_serial'      => '.1.3.6.1.4.1.3717.2.3.6.0',
);

%FUNCS = (%SNMP::Info::Layer3::FUNCS);

%MUNGE = (%SNMP::Info::Layer3::MUNGE);

sub serial {
    my $genua = shift;

    return $genua->genua_serial();
}

sub os {
    my $genua = shift;

    return $genua->genua_os();
}

sub os_ver {
    my $genua = shift;

    my $genua_osver_rel   = $genua->genua_osver_rel();
    my $genua_osver_patch = $genua->genua_osver_patch();

    my $genua_osver;

    if ( defined $genua_osver_rel and defined $genua_osver_patch ) {
        return $genua_osver_rel . "_PL_" . $genua_osver_patch;
    }
    return $genua_osver;
}

sub model {
    my $genua = shift;

    my $genua_model = $genua->genua_model();

    if (defined $genua_model) {
      if ($genua_model =~ m/GeNUA.+(GS.+?)\s/i) {
        $genua_model = $1;
      }
      elsif ($genua_model =~ m/genua\s+(.+?)\s+/i) {
        $genua_model = $1;
      }
    } else {
      $genua_model = 'unknown';
    }
    return $genua_model;
}

sub vendor {
    return 'genua';
}

1;

__END__

=head1 NAME

SNMP::Info::Layer3::Genua - SNMP Interface to Genua security devices

=head1 AUTHOR

Netdisco Developers

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $genua = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myhub',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $genua->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to information obtainable from a Genua security device
through SNMP. See inherited classes' documentation for inherited methods.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Inherited MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=head2 Overrides

=over

=item $genua->vendor()

Returns 'genua'

=item $genua->os()

(C<infoSoftwareversion>)

=item $genua->os_ver()

(C<infoRelease>) and (C<infoPatchlevel>)

=item $genua->model()

(C<infoHardwareversion>)

=item $genua->serial()

(C<infoSerialnumber>)

=back

=head2 Globals imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

=head2 Table Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
