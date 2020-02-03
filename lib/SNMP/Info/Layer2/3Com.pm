# SNMP::Info::Layer2::3Com - SNMP Interface to 3Com Devices
#
# Copyright (c) 2019 by The Netdisco Developer Team.
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

package SNMP::Info::Layer2::3Com;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer2;
use SNMP::Info::CDP;

@SNMP::Info::Layer2::3Com::ISA       = qw/SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::3Com::EXPORT_OK = qw//;

our ($VERSION, %FUNCS, %GLOBALS, %MIBS, %MUNGE, $AUTOLOAD);

$VERSION = '3.70';

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
    'A3Com-products-MIB' => 'wlanAP7760',
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer2::MUNGE,
);

sub os {
    return '3Com';
}

sub serial {
    my $dev  = shift;
    my $e_serial = $dev->e_serial();

    # Find entity table entry for this unit
    foreach my $e ( sort keys %$e_serial ) {
        if (defined $e_serial->{$e} and $e_serial->{$e} !~ /^\s*$/) {
            return $e_serial->{$e};
        }
    }
    return;
}

sub os_ver {

    my $dev = shift;
    my $e_swver  = $dev->e_swver();
    # Find entity table entry for this unit
    foreach my $e ( sort keys %$e_swver ) {
        if (defined $e_swver->{$e} and $e_swver->{$e} !~ /^\s*$/) {
            return $e_swver->{$e};
        }
    }
    return;
}

sub vendor {
    return '3com';
}

sub model {
    my $dsmodel = shift;
    my $descr = $dsmodel->description();

    if (defined ($descr)) {
      if ($descr =~ /^([\S ]+) Software.*/) {
        return $1;
      } else {
        return $descr;
      }
    }
    return;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::3Com - SNMP Interface to L2 3Com Switches

=head1 AUTHOR

Max Kosmach

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $router = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $router->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for 3Com L2 devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

=over

=item F<A3Com-products-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer2/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=head2 Overrides

=over

=item $device->vendor()

Returns '3com'

=item $device->os()

Returns '3Com'

=item $device->os_ver()

Return os version

=item $device->model()

Returns device model extracted from description

=item $device->serial()

Returns serial number

=back

=head2 Globals imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=cut

