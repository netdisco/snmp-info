# SNMP::Info::Layer3::RuckusController - SmartZone and SmartCell Gateway
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
#     * Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Layer3::RuckusController;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::RuckusController::ISA = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::RuckusController::EXPORT_OK = qw//;

our ( $VERSION, %FUNCS, %GLOBALS, %MIBS, %MUNGE );
$VERSION = '3.981001';

%MIBS = ( %SNMP::Info::Layer3::MIBS );
%GLOBALS = ( %SNMP::Info::Layer3::GLOBALS );
%FUNCS = ( %SNMP::Info::Layer3::FUNCS );
%MUNGE = ( %SNMP::Info::Layer3::MUNGE );

sub vendor { return 'ruckus'; }

sub model {
    my $self = shift;
    my $id = $self->id() || '';
    return 'SCG200' if $id =~ /\.25053\.3\.1\.10\.1(?:\.|$)/;
    return 'SZ100' if $id =~ /\.25053\.3\.1\.11\.1(?:\.|$)/;
    return 'SZ50' if $id =~ /\.25053\.3\.1\.11\.2(?:\.|$)/;
    return 'SCG' if $id =~ /\.25053\.3\.1\.10(?:\.|$)/;
    return 'SmartZone' if $id =~ /\.25053\.3\.1\.11(?:\.|$)/;
    return;
}

sub os { return 'ruckus smartzone/scg'; }

1;

__END__

=head1 NAME

SNMP::Info::Layer3::RuckusController - SNMP interface to Ruckus controllers

=head1 AUTHOR

SNMP::Info Developers

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $controller = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'mydevice',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $controller->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Identifies SmartZone-based and SmartCell Gateway controllers by their Ruckus
product sysObjectID branches and reports the product family or known model.
The SmartCell Gateway product branch remains in the Ruckus MIB and is used by
some SmartZone-based platforms.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

No additional MIBs are required. Product identification uses C<sysObjectID>.

=head2 Inherited MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These methods return scalar values.

=head2 Overrides

=over

=item $controller->vendor()

Returns C<ruckus>.

=item $controller->os()

Returns C<ruckus smartzone/scg>.

=item $controller->model()

Returns the controller model identified by its product sysObjectID. Known
models include C<SCG200>, C<SZ100>, and C<SZ50>; generic product branches
return C<SCG> or C<SmartZone>. Unrecognized IDs use the inherited model.

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

=head2 Table Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head1 Data Munging Callback Subroutines

No data munging callbacks are defined.

=cut
