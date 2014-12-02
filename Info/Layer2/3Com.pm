package SNMP::Info::Layer2::3Com;

use strict;
use Exporter;
use SNMP::Info::Layer2;
use SNMP::Info::LLDP;
use SNMP::Info::CDP;

@SNMP::Info::Layer2::3Com::ISA       = qw/SNMP::Info::LLDP SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::3Com::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD/;

$VERSION = '3.22';

%MIBS = (
    %SNMP::Info::LLDP::MIBS,
    %SNMP::Info::Layer2::MIBS,
    'A3Com-products-MIB' => 'wlanAP7760',
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
    %SNMP::Info::LLDP::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer2::MUNGE,
    %SNMP::Info::LLDP::MUNGE,
);


sub os {
    return '3Com';
}

sub serial {
    my $dev  = shift;
    my $e_serial = $dev->e_serial();

    # Find entity table entry for this unit
    foreach my $e ( sort keys %$e_serial ) {
        if (defined $e_serial->{$e} and $e_serial->{$e} !~ /^\s*$/) {
            return $e_serial->{$e};
        }
    }
}

sub os_ver {

    my $dev = shift;
    my $e_swver  = $dev->e_swver();
    # Find entity table entry for this unit
    foreach my $e ( sort keys %$e_swver ) {
        if (defined $e_swver->{$e} and $e_swver->{$e} !~ /^\s*$/) {
            return $e_swver->{$e};
        }
    }
}

sub vendor {
    return '3Com';
}

sub model {

    my $dsmodel = shift;
    my $descr = $dsmodel->description();
    if ( $descr =~ /^([\S ]+) Software.*/){
        return $1;
    }
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::3Com - SNMP Interface to L2 3Com Switches

=head1 AUTHOR

Max Kosmach

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $router = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 1
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $router->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for 3Com L2 devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

=over

=item F<A3Com-products-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer2/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=head2 Overrides

=over

=item $device->vendor()

Returns '3Com'

=item $device->os()

Returns '3Com'

=item $device->os_ver()

Return os version

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

