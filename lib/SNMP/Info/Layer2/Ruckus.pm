package SNMP::Info::Layer2::Ruckus;

use strict;
use warnings;
use SNMP::Info::Layer2;

our ($VERSION, %GLOBALS);
$VERSION = '3.979000';
@SNMP::Info::Layer2::Ruckus::ISA = qw(SNMP::Info::Layer2);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
    'ruckus_model'  => '.1.3.6.1.4.1.25053.1.1.2.1.1.1.1.0',
    'ruckus_serial' => '.1.3.6.1.4.1.25053.1.1.2.1.1.1.2.0',
    'ruckus_os_ver' => '.1.3.6.1.4.1.25053.1.1.3.1.1.1.1.1.3.1',
);

sub model {
    my $self = shift;
    return $self->ruckus_model() || $self->SUPER::model();
}

sub vendor { return 'ruckus'; }
sub os { return 'ruckus'; }
sub os_ver {
    my $self = shift;
    return $self->ruckus_os_ver();
}
sub serial {
    my $self = shift;
    my $serial = $self->ruckus_serial();
    return $serial if defined $serial and $serial !~ /^\s*$/;
    return $self->SUPER::serial();
}

1;

__END__

=head1 NAME

SNMP::Info::Layer2::Ruckus - SNMP interface to Ruckus access points

=head1 DESCRIPTION

Provides model, serial number, and software version information for Ruckus
access points registered below the Ruckus wireless product OID branches.

=cut
