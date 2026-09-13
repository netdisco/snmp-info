# SNMP::Info::Layer3::Sophos
#
# Copyright (c) 2026 The SNMP::Info Developers
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

package SNMP::Info::Layer3::Sophos;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Sophos::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Sophos::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.977001';

%MIBS = (%SNMP::Info::Layer3::MIBS);

# Numeric OIDs from the sfosXGDeviceInfo group of SFOS-FIREWALL-MIB, so that
# the class still works where the vendor MIB is not installed.
%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'os_ver'     => '.1.3.6.1.4.1.2604.5.1.1.3.0',    # sfosDeviceFWVersion
    'serial1'    => '.1.3.6.1.4.1.2604.5.1.1.4.0',    # sfosDeviceAppKey
    'sfos_model' => '.1.3.6.1.4.1.2604.5.1.1.2.0',    # sfosDeviceType
);

%FUNCS = (%SNMP::Info::Layer3::FUNCS);

%MUNGE = (%SNMP::Info::Layer3::MUNGE);

sub vendor {
    return 'sophos';
}

sub os {
    return 'sfos';
}

sub model {
    my $sophos = shift;

    # sysObjectID is the MIB module node on SFOS, the same value on every
    # model, so the inherited translation of it is of no use here.
    my $model = $sophos->sfos_model();
    return $model if defined $model and $model =~ /\S/;

    # %l3sysoidmap keys on the bare enterprise number, so older Astaro and
    # UTM appliances under other 2604 subtrees reach this class as well.
    # They do not serve sfosDeviceType, and returning nothing there would be
    # a regression against the inherited method, which at least hands back
    # the raw sysObjectID.
    return $sophos->SUPER::model();
}

sub layers {
    return '01001100';
}

1;

__END__

=head1 NAME

SNMP::Info::Layer3::Sophos - SNMP Interface to Sophos SFOS firewalls

=head1 AUTHOR

SNMP::Info Developers

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $sophos = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $sophos->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Sophos firewalls running SFOS.

SFOS does not implement C<sysServices>, so the device is classified by the
enterprise number of its C<sysObjectID> and this class reports its own
layers. The ARP cache is served through the standard C<ipNetToMediaTable>
and is inherited from L<SNMP::Info::Layer3>.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Inherited MIBs

The device information is read through numeric OIDs, so that the class does
not require F<SFOS-FIREWALL-MIB> to be installed.

See L<SNMP::Info::Layer3/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $sophos->vendor()

Returns C<'sophos'>.

=item $sophos->os()

Returns C<'sfos'>.

=item $sophos->model()

Returns the value of C<sfosDeviceType.0>, for example C<'XGS118_XN01_SFOS'>.

=item $sophos->os_ver()

Returns the value of C<sfosDeviceFWVersion.0>, including the maintenance
release and build, for example C<'22.0.1 MR-1-Build490'>.

=item $sophos->serial()

Returns the value of C<sfosDeviceAppKey.0>, the appliance key.

=back

=head2 Overrides

=over

=item $sophos->layers()

Returns 01001100. SFOS doesn't report layers, modified to reflect
Layer 3,4,7 functionality.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
