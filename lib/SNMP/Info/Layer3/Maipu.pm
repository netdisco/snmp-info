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

$VERSION = '3.985005';

%MIBS    = (%SNMP::Info::Layer3::MIBS);
%GLOBALS = (%SNMP::Info::Layer3::GLOBALS);
%FUNCS   = (
    %SNMP::Info::Layer3::FUNCS,

    # netdisco-mibs has no Maipu MIB, so these are read by numeric OID.
    # MAIPU-SYS-MIB::mpSysDeviceSerialNumber
    'mp_device_serial' => '.1.3.6.1.4.1.5651.3.600.14.1.1.2',

    # MAIPU-SYS-MIB::mpSysPowerType
    'mp_power_type' => '.1.3.6.1.4.1.5651.3.600.7.1.1.2',

    # MAIPU-SYS-MIB::mpSysPowerOnlineStatus
    'mp_power_online' => '.1.3.6.1.4.1.5651.3.600.7.1.1.8',

    # MAIPU-SYS-MIB::mpSysPowerAlarmStatus
    'mp_power_alarm' => '.1.3.6.1.4.1.5651.3.600.7.1.1.10',

    # MAIPU-SYS-MIB::mpSysFanCardOnlineStatus
    'mp_fan_online' => '.1.3.6.1.4.1.5651.3.600.8.1.1.7',

    # MAIPU-SYS-MIB::mpSysFanCardAlarmStatus
    'mp_fan_alarm' => '.1.3.6.1.4.1.5651.3.600.8.1.1.9',
);
%MUNGE = (%SNMP::Info::Layer3::MUNGE);

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
# entPhysicalModelName empty.
sub _chassis_model {
    my $maipu = shift;

    my $e_class = $maipu->e_class() || {};
    my $e_model = $maipu->e_model() || {};
    my $e_descr = $maipu->e_descr() || {};
    foreach my $index ( sort { $a <=> $b } keys %$e_class ) {
        next unless $e_class->{$index} eq 'chassis';
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

# Net-SNMP translates enumerations only for values served as INTEGER, and
# the agent serves entPhysicalClass as a Gauge32.
sub e_class {
    my $maipu   = shift;
    my $partial = shift;

    my $e_class = $maipu->SUPER::e_class($partial) || {};
    my $oid     = SNMP::translateObj( 'ENTITY-MIB::entPhysicalClass', 0, 1 )
        || '';
    my $enums
        = ref {} eq ref $SNMP::MIB{$oid}{'enums'}
        ? $SNMP::MIB{$oid}{'enums'}
        : {};
    my %labels = reverse %$enums;

    my %translated;
    foreach my $index ( keys %$e_class ) {
        my $class = $e_class->{$index};
        $translated{$index}
            = defined $class && exists $labels{$class}
            ? $labels{$class}
            : $class;
    }
    return \%translated;
}

sub serial {
    my $maipu = shift;

    my $serials = $maipu->mp_device_serial() || {};
    foreach my $index ( sort { $a <=> $b } keys %$serials ) {
        my $serial = $serials->{$index};
        return $serial if defined $serial and $serial =~ /\S/;
    }
    return $maipu->SUPER::serial();
}

my %POWER_CURRENT = ( 1 => 'AC', 2 => 'DC', 3 => 'AC', 4 => 'DC' );

# Status of the supply or fan at position $n, in index order.
sub _mp_status {
    my ( $online, $alarm, $index ) = @_;

    return 'offline' if ( $online->{$index} // 0 ) == 2;
    my $state = $alarm->{$index} // 0;
    return $state == 1 ? 'normal' : $state == 2 ? 'alarm' : undef;
}

sub _mp_power_index {
    my ( $maipu, $n ) = @_;

    my %indexes = map { %{ $maipu->$_() || {} } }
        qw/mp_power_type mp_power_online mp_power_alarm/;
    my @indexes = sort { $a <=> $b } keys %indexes;
    return $indexes[ $n - 1 ];
}

sub _mp_power_type {
    my ( $maipu, $n ) = @_;

    my $index = $maipu->_mp_power_index($n);
    return unless defined $index;
    my $types = $maipu->mp_power_type() || {};
    return $POWER_CURRENT{ $types->{$index} // '' };
}

sub _mp_power_status {
    my ( $maipu, $n ) = @_;

    my $index = $maipu->_mp_power_index($n);
    return unless defined $index;
    return _mp_status( $maipu->mp_power_online() || {},
        $maipu->mp_power_alarm() || {}, $index );
}

sub ps1_type   { return $_[0]->_mp_power_type(1); }
sub ps2_type   { return $_[0]->_mp_power_type(2); }
sub ps1_status { return $_[0]->_mp_power_status(1); }
sub ps2_status { return $_[0]->_mp_power_status(2); }

sub fan {
    my $maipu = shift;

    my $online  = $maipu->mp_fan_online() || {};
    my $alarm   = $maipu->mp_fan_alarm()  || {};
    my @indexes = sort { $a <=> $b } keys %{ { %$online, %$alarm } };
    return unless @indexes;

    my @faults;
    foreach my $position ( 1 .. @indexes ) {
        my $state = _mp_status( $online, $alarm, $indexes[ $position - 1 ] )
            // 'unknown';
        push @faults, "Fan $position: $state" unless $state eq 'normal';
    }
    return @faults ? join( ', ', @faults ) : 'normal';
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

None. Objects from F<MAIPU-SYS-MIB>, which netdisco-mibs does not carry,
are read by numeric OID.

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

=item $maipu->serial()

Returns the first non-empty C<mpSysDeviceSerialNumber> in device index
order, else the inherited value.

=item $maipu->ps1_type()

=item $maipu->ps2_type()

Returns C<AC> or C<DC> for the first or second power supply in index
order, from C<mpSysPowerType>.

=item $maipu->ps1_status()

=item $maipu->ps2_status()

Returns C<offline> when C<mpSysPowerOnlineStatus> says so, else
C<normal> or C<alarm> from C<mpSysPowerAlarmStatus>, for the first or
second power supply in index order.

=item $maipu->fan()

Returns C<normal> when every fan is online and normal. Otherwise lists
each other fan by position with its state, such as C<Fan 2: offline>.

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a
reference to a hash.

=head2 Maipu System Table (C<mpSysMIB>)

Read by numeric OID; values are the raw integers the MIB defines.

=over

=item $maipu->mp_device_serial()

C<mpSysDeviceSerialNumber>

=item $maipu->mp_power_type()

C<mpSysPowerType>

=item $maipu->mp_power_online()

C<mpSysPowerOnlineStatus>

=item $maipu->mp_power_alarm()

C<mpSysPowerAlarmStatus>

=item $maipu->mp_fan_online()

C<mpSysFanCardOnlineStatus>

=item $maipu->mp_fan_alarm()

C<mpSysFanCardAlarmStatus>

=back

=head2 Overrides

=over

=item $maipu->e_class()

Returns C<entPhysicalClass> with numbers translated to their
C<PhysicalClass> labels. The agent serves the column as a Gauge32, and
Net-SNMP translates enumerations only for values served as an INTEGER.

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
