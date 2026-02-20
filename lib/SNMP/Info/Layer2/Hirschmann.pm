# SNMP::Info::Layer2::Hirschmann - SNMP Interface to Hirschmann Devices
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

package SNMP::Info::Layer2::Hirschmann;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer2;
use SNMP::Info::CDP;

@SNMP::Info::Layer2::Hirschmann::ISA       = qw/SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::Hirschmann::EXPORT_OK = qw//;

our ($VERSION, %FUNCS, %GLOBALS, %MIBS, %MUNGE, $AUTOLOAD);

$VERSION = '3.975000';

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
    'HMPRIV-MGMT-SNMP-MIB' => 'hirschmann',
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
    'h_serial_number' => 'hmSysGroupTable.hmSysGroupEntry.hmSysGroupSerialNum.1',
    'os_version'      => 'hmSysVersion.0',
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer2::MUNGE,
);

sub os {
    return 'hirschmann';
}

sub serial {
    my $hirschmann = shift;
    my $model = $hirschmann->model();
    my $id = $hirschmann->id();
    my $serial;

    return $hirschmann->h_serial_number() if ( $hirschmann->h_serial_number() );

}

sub os_ver {
    my $hirschmann = shift;
    my $model = $hirschmann->model();
    my $id = $hirschmann->id();

    my $os_version = $hirschmann->os_version();
    if ( $os_version =~ m/(SW:\sL2.-\d{1,2}\.\d\.\d{2})/ ) {
        return $1;
    }

    return $id unless defined $os_version;

    return $os_version;
}

sub vendor {
    return 'hirschmann';
}

sub model {
    my $hmodel = shift;
    my $id    = $hmodel->id();

    my $model = &SNMP::translateObj($id) || $id;

    # model return by snmp is rs30 also if its a rs40
    if (defined $model && $model !~ /rs30/) {
        return uc $model;
    } else {
        return 'RS40-30';
    }

    return;
}

sub mac {
    my $hirschmann = shift;
    my $i_descr    = $hirschmann->i_description();
    my $i_mac      = $hirschmann->i_mac();

    # Return Interface MAC addresse of the switch (on the CPU pseudo interface)
    foreach my $entry ( sort keys %$i_descr ) {
        my $descr = $i_descr->{$entry};
        if ($descr =~ m/(^CPU.)/) {
            my $sn = $i_mac->{$entry};
#           next unless $sn;
            return $sn;
        }
    }
    return;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::Hirschmann - SNMP Interface to L2 Hirschmann Switches

=head1 AUTHOR

Christophe COMTE

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

Subclass for Hirschmann L2 devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=item SNMP::Info::CDP

=back

=head2 Required MIBs

=over

=item F<HMPRIV-MGMT-SNMP-MIB>

=item Inherited Classes

MIBs required by the inherited classes listed above.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=head2 Overrides

=over

=item $device->vendor()

Returns 'hirschmann'

=item $device->os()

Returns 'hirschmann'

=item $device->os_ver()

Return os version

=item $device->mac()

Return Interface MAC addresse of the switch (on the CPU pseudo interface).

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

