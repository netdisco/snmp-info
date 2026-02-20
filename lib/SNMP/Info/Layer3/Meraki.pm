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

$VERSION = '3.975000';

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

=back

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=cut
