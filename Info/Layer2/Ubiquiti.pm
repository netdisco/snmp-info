# SNMP::Info::Layer2::Ubiquiti
# $Id$
#

package SNMP::Info::Layer2::Ubiquiti;

use strict;
use Exporter;
use SNMP::Info::IEEE802dot11;
use SNMP::Info::Layer2;

@SNMP::Info::Layer2::Ubiquiti::ISA
    = qw/SNMP::Info::IEEE802dot11 SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::Ubiquiti::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE/;

$VERSION = '3.22';

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
    %SNMP::Info::IEEE802dot11::MIBS,

);

%GLOBALS
    = ( %SNMP::Info::Layer2::GLOBALS, %SNMP::Info::IEEE802dot11::GLOBALS, );

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
    %SNMP::Info::IEEE802dot11::FUNCS,

);

%MUNGE = ( %SNMP::Info::Layer2::MUNGE, %SNMP::Info::IEEE802dot11::MUNGE, );

sub os {
    return 'Ubiquiti';
}

sub os_ver {
    my $dot11 = shift;

    my $versions = $dot11->dot11_prod_ver();

    foreach my $iid ( keys %$versions ) {
        my $ver = $versions->{$iid};
        next unless defined $ver;
	return $ver;
        if ( $ver =~ /([\d\.]+)/ ) {
            return $1;
        }
    }

    return;
}

sub vendor {
    return 'Ubiquiti Networks, Inc.';
}

sub model {
    my $dot11 = shift;

    my $names = $dot11->dot11_prod_name();

    foreach my $iid ( keys %$names ) {
        my $prod = $names->{$iid};
        next unless defined $prod;
        return $prod;
    }
    return;
}


1;
__END__

=head1 NAME

SNMP::Info::Layer2::Ubiquiti - SNMP Interface to Ubiquiti Access Points

=head1 AUTHOR

Max Kosmach

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $ubnt = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class = $ubnt->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from
Ubiquiti Access Point through SNMP.

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

 my $ubnt = new SNMP::Info::Layer2::Ubiquiti(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=item SNMP::Info::IEEE802dot11

=back

=head2 Required MIBs

None.

=head2 Inherited MIBs

See L<SNMP::Info::Layer2/"Required MIBs"> for its MIB requirements.

See L<SNMP::Info::IEEE802dot11/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $ubnt->vendor()

Returns 'Ubiquiti Networks, Inc.'

=item $ubnt->model()

Returns the model extracted from C<dot11manufacturerProductName>.

=item $ubnt->os()

Returns 'Ubiquiti'

=item $ubnt->os_ver()

Returns the software version extracted from C<dot11manufacturerProductVersion>.

=back

=head2 Global Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::IEEE802dot11

See L<SNMP::Info::IEEE802dot11/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::IEEE802dot11

See L<SNMP::Info::IEEE802dot11/"TABLE METHODS"> for details.

=cut
