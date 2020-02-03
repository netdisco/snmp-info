# SNMP::Info::Layer2::Atmedia
#
# Copyright (c) 2018 Netdisco Developers
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

package SNMP::Info::Layer2::Atmedia;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer2;

@SNMP::Info::Layer2::Atmedia::ISA       = qw/SNMP::Info::Layer2/;
@SNMP::Info::Layer2::Atmedia::EXPORT_OK = qw//;

our ($VERSION, %FUNCS, %GLOBALS, %MIBS, %MUNGE);

$VERSION = '3.70';

%MIBS = ( %SNMP::Info::Layer2::MIBS );

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
    'os_ver'          => '.1.3.6.1.4.1.13458.1.2.1.0',
    'atm_serial'      => '.1.3.6.1.4.1.13458.1.1.2.0',
    'atm_hardversion' => '.1.3.6.1.4.1.13458.1.3.1.0',
    'atm_model'       => '.1.3.6.1.4.1.13458.1.1.6.0',
);

%FUNCS = (%SNMP::Info::Layer2::FUNCS);

%MUNGE = (%SNMP::Info::Layer2::MUNGE);

sub serial {
    my $atmedia = shift;

    return $atmedia->atm_serial();
}

sub os {
    return 'Atmedia-OS';
}

sub model {
    my $atmedia = shift;

    my $atmedia_model = $atmedia->atm_model();
    if (defined $atmedia_model) {
      $atmedia_model =~ s/\<|\>//g;
      $atmedia_model =~ s/\//_/g;
      return $atmedia_model;
    }
    return;
}

sub vendor {
    return 'atmedia';
}

1;

__END__

=head1 NAME

SNMP::Info::Layer2::Atmedia - SNMP Interface to atmedia encryptors

=head1 AUTHOR

Netdisco Developers

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $atmedia = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myhub',
                          Community   => 'public',
                          Version     => 1
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $atmedia->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to information obtainable from a atmedia encryptor
through SNMP. See inherited classes' documentation for inherited methods.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=back

=head2 Inherited MIBs

See L<SNMP::Info::Layer2/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=head2 Overrides

=over

=item $atmedia->vendor()

Returns 'atmedia'

=item $atmedia->os()

Returns 'Atmedia-OS'

=item $atmedia->os_ver()

(C<acSoftVersion>)

=item $atmedia->model()

(C<acDescr>)

=item $atmedia->serial()

(C<acSerialNumber>)

=back

=head2 Globals imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head1 TABLE METHODS

=head2 Table Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=cut
