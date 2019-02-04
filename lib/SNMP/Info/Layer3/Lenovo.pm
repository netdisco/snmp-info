# SNMP::Info::Layer3::Lenovo
#
# Copyright (c) 2019 nick nauwelaerts
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

# TODO
# ignore 127.0.0.1 interface (could be snmpsim that's adding this however)
# fix port speed
#  -> either overwrite snmp::info to use highspeed
#  -> or add more keys to munge in this module
# lag members
# psu & fan info should be possible
# spanning tree info is avail too
# no ifalias, overwrite default port name in netdisco

package SNMP::Info::Layer3::Lenovo;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::LLDP;
use SNMP::Info::IEEE802dot3ad;

@SNMP::Info::Layer3::Lenovo::ISA = qw/
    SNMP::Info::LLDP
    SNMP::Info::Layer3
    SNMP::Info::IEEE802dot3ad
    Exporter
/;
@SNMP::Info::Layer3::Lenovo::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.64';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::LLDP::MIBS,
    %SNMP::Info::IEEE802dot3ad::MIBS,
    'LENOVO-ENV-MIB'      => 'lenovoEnvMibPowerSupplyIndex',
    'LENOVO-PRODUCTS-MIB' => 'lenovoProducts',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,
    %SNMP::Info::IEEE802dot3ad::GLOBALS,
    # no way to get os version and other device details
    # ENTITY-MIB however can help out
    'os_ver'  => 'entPhysicalSoftwareRev.1',
    'mac'     => 'dot1dBaseBridgeAddress',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::LLDP::FUNCS,
    %SNMP::Info::IEEE802dot3ad::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::LLDP::MUNGE,
    %SNMP::Info::IEEE802dot3ad::MUNGE,
);

# copied from snmp::info.pm to only use highspeed,
# needs to either become more elegant of find a way to
# force highspeed in snmp::info.pm
sub i_speed {
    my $info    = shift;
    my $partial = shift;

    my $i_speed = $info->orig_i_speed($partial);

    my $i_speed_high = undef;
    foreach my $i ( keys %$i_speed ) {
            $i_speed_high = $info->i_speed_high($partial)
                unless defined($i_speed_high);
            $i_speed->{$i} = $i_speed_high->{$i} if ( $i_speed_high->{$i} );
    }
    return $i_speed;
}

sub vendor {
    return 'lenovo';
}

sub os {
    return 'cnos';
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Lenovo - SNMP Interface to Lenovo switches running CNOS.

=head1 AUTHORS

Nick Nauwelaerts

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $cnos = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to $DestHost.\n";

 my $class      = $cnos->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Lenovo switches running CNOS.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::LLDP

=back

=head2 Required MIBs

=over

=item F<LENOVO-ENV-MIB>

=item F<LENOVO-PRODUCTS-MIB>

=back

=head2 Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

See L<SNMP::Info::LLDP> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP.

=over

=item $cnos->mac()

Returns base mac based on C<dot1dBaseBridgeAddress>.

=item $cnos->os_ver()

Returns the OS version extracted from C<entPhysicalSoftwareRev.1>.

=back

=head2 Overrides

=over

=item $cnos->vendor()

Returns 'lenovo'.

=item $cnos->os()

Returns 'cnos'.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Globals imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP> for details.

=cut
