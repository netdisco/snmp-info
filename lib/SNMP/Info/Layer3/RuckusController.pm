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
$VERSION = '3.983000';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'RUCKUS-PRODUCTS-MIB'   => 'ruckusSCG200',
    'RUCKUS-SZ-SYSTEM-MIB'  => 'ruckusSZSystemStatsSerialNumber',
    'RUCKUS-SCG-SYSTEM-MIB' => 'ruckusSystemStatsSerialNumber',
    'RUCKUS-CTRL-MIB'       => 'ruckusCtrlSystemNodeModel',
);
%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,

    # RUCKUS-SZ-SYSTEM-MIB
    'ruckus_sz_serial' => 'ruckusSZSystemStatsSerialNumber',

    # RUCKUS-SCG-SYSTEM-MIB
    'ruckus_scg_serial' => 'ruckusSystemStatsSerialNumber',
);
%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,

    # RUCKUS-CTRL-MIB::ruckusCTRLSystemNodeTable, one row per cluster node
    'ruckus_node_model'   => 'ruckusCtrlSystemNodeModel',
    'ruckus_node_version' => 'ruckusCtrlSystemNodeVersion',
);
%MUNGE = ( %SNMP::Info::Layer3::MUNGE );

sub vendor { return 'ruckus'; }

# Some agents serve no sysServices; vSZ serves 78
sub layers {
    my $self = shift;
    return $self->SUPER::layers() || '01001110';
}

# A cluster serves a row per node, indexed by the node's serial as a
# length-prefixed string; some agents do not serve the serial column
sub _ruckus_node_iid {
    my $self = shift;

    my %iids = map { $_ => 1 } keys %{ $self->ruckus_node_model() || {} },
        keys %{ $self->ruckus_node_version() || {} };
    my $serial = $self->serial();
    if ( defined $serial ) {
        my ($iid) = grep { _ruckus_iid_string($_) eq $serial } keys %iids;
        return $iid if defined $iid;
    }
    my @iids = keys %iids;
    return $iids[0] if @iids == 1;
    return;
}

sub _ruckus_iid_string {
    my ( $length, @octets ) = split /\./, shift;
    return '' unless defined $length and @octets == $length;
    return join '', map {chr} @octets;
}

sub _ruckus_node_value {
    my ( $self, $column ) = @_;

    my $iid = $self->_ruckus_node_iid();
    return unless defined $iid;
    my $value = ( $self->$column() || {} )->{$iid};
    return $value if defined $value and $value =~ /\S/;
    return;
}

sub os_ver {
    my $self = shift;
    return $self->_ruckus_node_value('ruckus_node_version')
        || $self->SUPER::os_ver();
}

sub model {
    my $self = shift;
    my $node_model = $self->_ruckus_node_value('ruckus_node_model');
    return $node_model if defined $node_model;

    my $id = $self->id() || '';
    my $product = SNMP::translateObj($id) || '';
    return 'SCG200' if $product eq 'ruckusSCG200';
    return 'SZ100' if $product eq 'ruckusSZ100';
    return 'SZ50' if $product eq 'ruckusSZ50';
    return 'SCG' if $product eq 'ruckusWirelessSmartCellGatewayProducts';
    return 'SmartZone' if $product eq 'ruckusWirelessSmartZoneProducts';
    return $self->SUPER::model();
}

sub serial {
    my $self = shift;
    my $serial = $self->ruckus_sz_serial();
    $serial = $self->ruckus_scg_serial() unless defined $serial && $serial =~ /\S/;
    return $serial if defined $serial && $serial =~ /\S/;
    return $self->SUPER::serial();
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

=over

=item F<RUCKUS-PRODUCTS-MIB>

=item F<RUCKUS-SZ-SYSTEM-MIB>

=item F<RUCKUS-SCG-SYSTEM-MIB>

=item F<RUCKUS-CTRL-MIB>

=back

=head2 Inherited MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These methods return scalar values.

=over

=item $controller->ruckus_sz_serial()

Returns the SmartZone serial number (C<ruckusSZSystemStatsSerialNumber>,
F<RUCKUS-SZ-SYSTEM-MIB>).

=item $controller->ruckus_scg_serial()

Returns the SmartCell Gateway serial number
(C<ruckusSystemStatsSerialNumber>, F<RUCKUS-SCG-SYSTEM-MIB>).

=back

=head2 Overrides

=over

=item $controller->vendor()

Returns C<ruckus>.

=item $controller->os()

Returns C<ruckus smartzone/scg>.

=item $controller->layers()

Returns the served C<sysServices> layers, or C<01001110> (layers 2, 3, 4 and
7, as virtual SmartZone serves) where the agent serves none.

=item $controller->os_ver()

Returns this node's software version from C<ruckusCTRLSystemNodeTable>
(C<ruckusCtrlSystemNodeVersion>), falling back to the inherited method.

=item $controller->model()

Returns this node's model from C<ruckusCTRLSystemNodeTable>
(C<ruckusCtrlSystemNodeModel>), such as C<SZ104> or C<vSZ-E>.  Where the
table is not served, returns the model identified by its product sysObjectID. Known
models include C<SCG200>, C<SZ100>, and C<SZ50>; generic product branches
return C<SCG> or C<SmartZone>. Unrecognized IDs use the inherited model.

=item $controller->serial()

Returns the serial number from the SmartZone or SmartCell Gateway system MIB,
falling back to the inherited serial method.

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

=head2 Ruckus Controller Node Table (C<ruckusCTRLSystemNodeTable>)

The table holds one row per cluster node, indexed by the node's serial
number.  This node's row is the one whose index is C<serial()>, or the only
row.

=over

=item $controller->ruckus_node_model()

Returns reference to hash.  Key: node index, value: node model
(C<ruckusCtrlSystemNodeModel>).

=item $controller->ruckus_node_version()

Returns reference to hash.  Key: node index, value: node software version
(C<ruckusCtrlSystemNodeVersion>).

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head1 Data Munging Callback Subroutines

No data munging callbacks are defined.

=cut
