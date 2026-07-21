# SNMP::Info::Layer3::C9800
#
# Copyright (c) 2026 The SNMP::Info Developers
# All rights reserved.

package SNMP::Info::Layer3::C9800;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Entity;
use SNMP::Info::Layer2::Airespace;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

@SNMP::Info::Layer3::C9800::ISA = qw/
    SNMP::Info::Layer2::Airespace
    Exporter
/;

@SNMP::Info::Layer3::C9800::EXPORT_OK = qw//;

$VERSION = '3.975000';

%MIBS = (
    %SNMP::Info::Layer2::Airespace::MIBS,
    %SNMP::Info::Entity::MIBS,
);

%GLOBALS = (
    %SNMP::Info::Layer2::Airespace::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer2::Airespace::FUNCS,
    'c9800_entity_descr'  => 'entPhysicalDescr',
    'c9800_entity_serial' => 'entPhysicalSerialNum',
);

%MUNGE = ( %SNMP::Info::Layer2::Airespace::MUNGE, );

sub serial {
    my $c9800 = shift;
    my $descr   = $c9800->c9800_entity_descr()  || {};
    my $serials = $c9800->c9800_entity_serial() || {};

    my @chassis_serials = map { $serials->{$_} }
        grep {
               defined $descr->{$_}
            && $descr->{$_} =~ /chassis/i
            && defined $serials->{$_}
            && $serials->{$_} ne ''
        } sort { $a <=> $b } keys %{$descr};

    return unless @chassis_serials;
    return join ' ', @chassis_serials;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::C9800 - SNMP Interface to Cisco Catalyst 9800 Wireless Controllers

=head1 DESCRIPTION

Subclass for Cisco Catalyst 9800 Wireless Controllers using the Airespace
wireless controller MIBs for managed access points and clients.

=head1 INHERITED CLASSES

=over

=item SNMP::Info::Layer2::Airespace

=back

=head2 Overrides

=over

=item serial()

Finds all C<ENTITY-MIB::entPhysicalDescr> entries containing C<chassis> and
returns the concatenated C<entPhysicalSerialNum> values at the corresponding
indexes.

=back

=cut
