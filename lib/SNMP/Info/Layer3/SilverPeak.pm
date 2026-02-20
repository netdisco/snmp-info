# SNMP::Info::Layer3::SilverPeak
#
# Copyright (c) 2024 Netdisco Developers
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

package SNMP::Info::Layer3::SilverPeak;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::SilverPeak::ISA = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::SilverPeak::EXPORT_OK = qw//;

our ($VERSION, %MIBS, %FUNCS, %GLOBALS, %MUNGE);

$VERSION = '3.975000';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'SILVERPEAK-MGMT-MIB'    => 'spsSystemVersion',
    'SILVERPEAK-PRODUCTS-MIB' => 'silverpeakProductsMIB',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'os_ver'       => 'spsSystemVersion.0',
    'product_model'=> 'spsProductModel.0',
    'serial'       => 'spsSystemSerial.0',
    'uptime'       => 'spsSystemUptime.0',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
);

sub vendor {
    return 'silverpeak';
}

sub model {
    my $silverpeak = shift;
    my $model = $silverpeak->product_model();
    return $model if defined $model;
    return;
}

sub os {
    return 'silverpeak';
}

sub os_ver {
    my $silverpeak = shift;
    return $silverpeak->spsSystemVersion();
}

sub serial {
    my $silverpeak = shift;
    return $silverpeak->spsSystemSerial();
}

sub uptime {
    my $silverpeak = shift;
    return $silverpeak->spsSystemUptime();
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::SilverPeak - SNMP Interface to SilverPeak devices.

=head1 AUTHOR

Netdisco Developers

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $silverpeak = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $silverpeak->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for SilverPeak devices.


=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

F<SILVERPEAK-MGMT-MIB>

F<SILVERPEAK-PRODUCTS-MIB>

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $silverpeak->vendor()

Returns 'silverpeak'

=item $silverpeak->model()

Returns the chassis model.

(C<SILVERPEAK-PRODUCTS-MIB::model>)

=item $silverpeak->os()

Returns 'silverpeak'

=item $silverpeak->os_ver()

Returns the software version extracted from (C<spsSystemVersion>).

=item $silverpeak->serial()

Returns the chassis serial number.

(C<spsSystemSerial>)

=back

=head2 Overrides

=over

=item $silverpeak->uptime()

returns spsSystemUptime

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 AUTHOR

Written and contributed by Muris Boric. Many thanks!

=cut
