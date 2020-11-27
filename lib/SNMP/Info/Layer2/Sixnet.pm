# SNMP::Info::Layer2::Sixnet
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

package SNMP::Info::Layer2::Sixnet;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer2;

@SNMP::Info::Layer2::Sixnet::ISA       = qw/SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::Sixnet::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %FUNCS, %MIBS, %MUNGE);

$VERSION = '3.71';

%MIBS = (%SNMP::Info::Layer2::MIBS, 'SIXNET-MIB' => 'sxid',);

%GLOBALS = (
  %SNMP::Info::Layer2::GLOBALS,
  'os_ver'     => 'firmwareRevision',
  's_model'    => 'sxid',
  'ps1_status' => 'p1status',
  'ps2_status' => 'p2status',
);

%FUNCS = (%SNMP::Info::Layer2::FUNCS,);

%MUNGE = (%SNMP::Info::Layer2::MUNGE,);


sub vendor {
  return 'sixnet';
}

sub os {
  return 'sixnet';
}

sub model {
  my $sixnet = shift;

  my $s_model = $sixnet->s_model();
  return $s_model if defined $s_model;

  my $id = $sixnet->id();
  return unless defined $id;

  my $model = SNMP::translateObj($id);
  return $model ? $model : $id;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer2::Sixnet - SNMP Interface to Sixnet industrial switches

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

    my $sixnet = new SNMP::Info(
              AutoSpecify => 1,
              Debug       => 1,
              DestHost    => 'myswitch',
              Community   => 'public',
              Version     => 2
            )

    or die "Can't connect to DestHost.\n";

    my $class = $sixnet->class();
    print " Using device sub class : $class\n";

=head1 DESCRIPTION

SNMP::Info::Layer2::Sixnet is a subclass of SNMP::Info that provides an
interface to Sixnet industrial switches.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

=over

=item F<SIXNET-MIB>

=back

=head2 Inherited MIBs

See L<SNMP::Info::Layer2/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $sixnet->vendor()

Returns 'sixnet'

=item $sixnet->os()

Returns 'sixnet'

=item $sixnet->os_ver()

Returns the software version returned by C<firmwareRevision>

=item $sixnet->model()

Returns model type. Returns C<sxid> if it exists, otherwise cross references
$sixnet->id() with the F<SIXNET-MIB>.

=item $sixnet->ps1_status()

(C<p1status>)

=item $sixnet->ps2_status()

(C<p2status>)

=back

=head2 Globals imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=cut
