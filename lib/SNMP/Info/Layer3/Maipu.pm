# SNMP::Info::Layer3::Maipu - SNMP interface to Maipu switches
#
# Copyright (c) 2026 by SNMP::Info Developers.
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
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Layer3::Maipu;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Maipu::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Maipu::EXPORT_OK = qw//;

our ( $VERSION, %FUNCS, %GLOBALS, %MIBS, %MUNGE );

$VERSION = '3.985004';

%MIBS    = (%SNMP::Info::Layer3::MIBS);
%GLOBALS = (%SNMP::Info::Layer3::GLOBALS);
%FUNCS   = (%SNMP::Info::Layer3::FUNCS);
%MUNGE   = (%SNMP::Info::Layer3::MUNGE);

sub vendor { return 'maipu'; }

sub os { return 'mypower'; }

sub os_ver {
    my $maipu = shift;
    my $descr = $maipu->description() // '';

    return $1 if $descr =~ /\bversion\s+(\d+(?:\.\d+)+)/i;
    return $maipu->SUPER::os_ver();
}

sub model {
    my $maipu = shift;

    my $chassis_model = $maipu->_chassis_model();
    return $chassis_model if defined $chassis_model;

    my $descr = $maipu->description() // '';
    return $1 if $descr =~ /\bMyPower\s+([A-Z][\w-]*\d[\w-]*)\s+version\b/i;
    return $maipu->SUPER::model();
}

# The S3230 names its model in the chassis entPhysicalDescr and leaves
# entPhysicalModelName empty.  It serves entPhysicalClass as a Gauge32,
# which the enumeration does not translate, so chassis arrives as 3.
sub _chassis_model {
    my $maipu = shift;

    my $e_class = $maipu->e_class() || {};
    my $e_model = $maipu->e_model() || {};
    my $e_descr = $maipu->e_descr() || {};
    foreach my $index ( sort { $a <=> $b } keys %$e_class ) {
        next unless $e_class->{$index} =~ /^(?:chassis|3)$/;
        foreach my $model ( $e_model->{$index}, $e_descr->{$index} ) {
            return $model if defined $model and $model =~ /\S/;
        }
    }
    return;
}

# The S3230 serves sysServices 4, so add layer 2 when it has bridge ports.
sub layers {
    my $maipu = shift;

    my $layers = $maipu->SUPER::layers() || '00000100';
    substr( $layers, 6, 1, '1' ) if $maipu->b_ports();
    return $layers;
}

# The agent indexes dot1qTpFdbTable as FDB ID, a length octet 6, then the
# MAC, as if the MacAddress were a variable-length string.
sub qb_fw_mac {
    my $maipu   = shift;
    my $partial = shift;

    my $qb_fw_port = $maipu->qb_fw_port($partial) || {};
    my %qb_fw_mac;
    foreach my $idx ( keys %$qb_fw_port ) {
        my ( $fdb_id, @octets ) = split /\./, $idx;
        shift @octets if @octets == 7 and $octets[0] == 6;
        next unless @octets == 6;
        $qb_fw_mac{$idx} = join ':', map { sprintf '%02x', $_ } @octets;
    }
    return \%qb_fw_mac;
}

# Forwarding entries learned on a link aggregation name its ifIndex as the
# bridge port, which dot1dBasePortTable leaves out.
sub bp_index {
    my $maipu   = shift;
    my $partial = shift;

    my $bp_index   = $maipu->SUPER::bp_index($partial) || {};
    my $interfaces = $maipu->interfaces()              || {};
    my %mapped     = map { $_ => 1 } values %$bp_index;
    my @iids       = defined $partial ? ($partial) : keys %$interfaces;
    foreach my $iid (@iids) {
        next unless exists $interfaces->{$iid};
        next if exists $bp_index->{$iid} or $mapped{$iid};
        $bp_index->{$iid} = $iid;
    }
    return $bp_index;
}

# The agent serves no dot3adAggPortListPorts, so members come from the
# aggregator each port is attached to.
sub agg_ports {
    my $maipu = shift;

    my $attached   = $maipu->lag_port_attached() || {};
    my $interfaces = $maipu->interfaces()        || {};
    my %members;
    foreach my $member ( keys %$attached ) {
        my $aggregate = $attached->{$member};
        next unless defined $aggregate and $aggregate =~ /^\d+$/;
        next if $aggregate == 0 or $member eq $aggregate;
        next unless exists $interfaces->{$aggregate};
        $members{$member} = $aggregate;
    }
    return \%members if scalar keys %members;
    return SNMP::Info::IEEE802dot3ad::agg_ports_lag( $maipu, @_ );
}

sub _agg_ports_walked {
    return qw/lag_port_attached ad_lag_ports bp_index/;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Maipu - SNMP Interface to Maipu switches

=head1 AUTHOR

SNMP::Info Developers

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $maipu = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $maipu->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Maipu switches running MyPower, registered under the Maipu
C<mpSwitch> branch (C<.1.3.6.1.4.1.5651.1.102>). Reads the model from the
chassis entity or C<sysDescr> and the version from C<sysDescr>, reports
layer 2 for a switch that serves layer 3 only in C<sysServices>, maps link
aggregation members, and reads forwarding table entries the agent indexes
and maps in non-standard ways.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

None.

=head2 Inherited MIBs

=over

=item See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=head2 Overrides

=over

=item $maipu->vendor()

Returns C<'maipu'>.

=item $maipu->os()

Returns C<'mypower'>.

=item $maipu->os_ver()

Returns the version that follows the word C<version> in C<sysDescr>, else
the inherited value.

=item $maipu->model()

Returns the chassis C<entPhysicalModelName>, else the chassis
C<entPhysicalDescr>, such as C<S3230-54TXF(V1)>. Without either, returns
the model that precedes the word C<version> in C<sysDescr>, such as
C<S3230>, else the inherited value.

=item $maipu->layers()

Returns the served C<sysServices> layers, or layer 3 where none are
served, with layer 2 added when the device has bridge ports
(C<dot1dBaseNumPorts>).

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a
reference to a hash.

=head2 Overrides

=over

=item $maipu->qb_fw_mac()

Returns reference to hash of forwarding table MAC addresses, decoded from
the C<dot1qTpFdbTable> index. The agent puts a length octet before the
MAC in the index; it is dropped. A standard index is decoded as well.

=item $maipu->bp_index()

Returns reference to hash of bridge port to interface index
(C<dot1dBasePortIfIndex>), with each interface the table leaves out mapped
to itself. Forwarding entries learned on a link aggregation name its
ifIndex as the bridge port.

=item $maipu->agg_ports()

Returns a HASH reference mapping each link aggregation member's ifIndex
to the aggregation's ifIndex, from C<dot3adAggPortAttachedAggID>. The
agent serves no C<dot3adAggPortListPorts>. Falls back to
L<SNMP::Info::IEEE802dot3ad/agg_ports_lag()> when no port names an
attached aggregation.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
