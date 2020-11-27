# SNMP::Info::Layer2::Nexans
#
# Copyright (c) 2018 Christoph Neuhaus
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

package SNMP::Info::Layer2::Nexans;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer2;

@SNMP::Info::Layer2::Nexans::ISA = qw/SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::Nexans::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %FUNCS, %MIBS, %MUNGE);

$VERSION = '3.71';

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
    'NEXANS-MIB'    => 'nexansANS',
    'NEXANS-BM-MIB' => 'infoDescr',
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
    'mac'   => 'adminAgentPhysAddress.0',
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
    'i_duplex'          => 'portLinkState', #NEXANS-BM-MIB
    'i_duplex_admin'    => 'portSpeedDuplexSetup', #NEXANS-BM-MIB
    'nexans_i_name'     => 'ifAlias',
);

%MUNGE = (
    %SNMP::Info::Layer2::MUNGE,
    'i_duplex'          => \&munge_i_duplex,
    'i_duplex_admin'    => \&munge_i_duplex_admin,
);

sub munge_i_duplex {
    my $duplex   = shift;
    return unless defined $duplex;
    $duplex = 'half' if $duplex =~/Hdx/;
    $duplex = 'full' if $duplex =~/Fdx/;
    return $duplex;
}

sub munge_i_duplex_admin {
    my $duplex_admin    = shift;
    return unless defined $duplex_admin;
    $duplex_admin = 'full' if $duplex_admin =~/Fdx/;
    $duplex_admin = 'half' if $duplex_admin =~/Hdx/;
    $duplex_admin = 'auto' if $duplex_admin =~/autoneg/;
    return $duplex_admin;
}

sub vendor {
    return 'nexans';
}

sub model {
    my $nexans  = shift;
    my $id      = $nexans->id() || '';
    my $model   = &SNMP::translateObj($id);
    return $id unless defined $model;
    return $model;
}

sub os {
    return 'nexanos';
}

sub os_ver {
    my $nexans  = shift;
    my $ver     = $nexans->infoMgmtFirmwareVersion() || '';
    return $ver;
}

sub serial {
    my $nexans = shift;
    return $nexans->infoSeriesNo();
}

sub i_name {
    my $nexans  = shift;
    my $return  = $nexans->nexans_i_name();
    # replace i_name where possible
    foreach my $iid ( keys %$return ) {
        next unless $return->{$iid} eq "";
        $return->{$iid} = $iid;
    }
    return \%$return;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer2::Nexans - SNMP Interface to Nexans network devices.

=head1 AUTHOR

Christoph Neuhaus

=head1 SYNOPSIS

# Let SNMP::Info determine the correct subclass for you.

    my $nexans = new SNMP::Info(
                            AutoSpecify => 1,
                            Debug       => 1,
                            DestHost    => 'myswitch',
                            Community   => 'public',
                            Version     => 2
                            )
    or die "Can't connect to DestHost.\n";

    my $class = $nexans->class();
    print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for Nexans network devices.

tested devices:

    fiberSwitch100BmPlus version 3.61
    gigaSwitch641DeskSfpTp version 3.68, 4.14W
    gigaSwitchV3d2SfpSfp version 3.68, 4.02, 4.02B, 4.10C, 4,14W

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

=over

=item F<NEXANS>

=item F<NEXANS-BM>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer2/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $nexans->vendor()

Returns 'nexans'

=item $nexans->model()

Returns the chassis model.

=item $nexans->os()

Returns 'nexanos'

=item $nexans->os_ver()

Returns the software version.

=item $nexans->serial()

Returns the chassis serial number.

(C<infoSeriesNo>)

=back

=head2 Globals imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $nexans->i_name()

Returns reference to map of IIDs to human-set port name.

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=head1 Data Munging Callback Subroutines

=over

=item munge_i_duplex()

Converts duplex returned by C<portLinkState> to either 'full' or 'half'.

=item munge_i_duplex_admin()

Converts duplex returned by C<portSpeedDuplexSetup> to either 'full', 'half',
or 'auto'.

=back

=cut
