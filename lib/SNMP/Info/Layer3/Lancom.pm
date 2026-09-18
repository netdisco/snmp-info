package SNMP::Info::Layer3::Lancom;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

our @ISA = qw(
    SNMP::Info::Layer3
    Exporter
);

our (
    $VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.977001';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,

    # LCOS Status > Hardware-Info
    'lancom_model'  => '.1.3.6.1.4.1.2356.11.1.47.6.0',
    'lancom_serial' => '.1.3.6.1.4.1.2356.11.1.47.7.0',
    'lancom_fw'     => '.1.3.6.1.4.1.2356.11.1.47.9.0',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
);


sub model {
    my $self = shift;
    return $self->lancom_model();
}

sub serial {
    my $self = shift;
    return $self->lancom_serial();
}

sub os {
    return 'LCOS';
}

sub os_ver {
    my $self = shift;

    my $version = $self->lancom_fw();
    return unless defined($version) && length($version);

    $version =~ s/\s*\/.*$//;
    $version =~ s/^\s+|\s+$//g;

    return $version;
}

1;
