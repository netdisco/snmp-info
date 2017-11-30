# SNMP::Info::Layer2::Ubiquiti
# $Id$
#

package SNMP::Info::Layer2::Ubiquiti;

use strict;
use Exporter;
use SNMP::Info::IEEE802dot11;
use SNMP::Info::Layer2;
use SNMP::Info::Layer3;




@SNMP::Info::Layer2::Ubiquiti::ISA
    = qw/SNMP::Info::IEEE802dot11 SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::Ubiquiti::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE/;

$VERSION = '3.38';

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
    my $ubnt = shift;

    my $names = $ubnt->dot11_prod_name();

    foreach my $iid ( keys %$names ) {
        my $prod = $names->{$iid};
        next unless defined $prod;
        # Product names that match AirOS products
                if((lc $prod) =~ /station/ or (lc $prod) =~ /beam/ or (lc $prod) =~ /grid/){
                        return 'AirOS';
                # Product names that match UAP
                }elsif((lc $prod) =~ /uap/){
                        return 'UniFi';
                }else{
                    # Continue below to find OS name
                }
    }

    ## EdgeMAX OS name is first field split by space
    my $ver = $ubnt->description() || '';

    my @myver = split(/ /, $ver);

    return $myver[0];
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
    my $ver = $dot11->description() || '';
    if($ver =~ /,/){
        ## EdgeSwitch OS version is second field split by comma
        my @myver = split(/, /, $ver);

        return $myver[1];
    }

    ## EdgeRouter OS version is second field split by space
    my @myver = split(/ /, $ver);

    return $myver[1];
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
    
    my $ver = $dot11->description() || '';
    
    ## Pull Model from beginning of description, separated by comma (EdgeSwitch)
    if($ver =~ /,/){    
        my @myver = split(/, /, $ver);
        return $myver[0];
    }

    ## Pull Model from the end of description, separated by space (EdgeRouter)
    ## only works if SNMP configuration is adjusted according to this post-config.d script:
=begin comment
place the following into a file with executable writes in the "/config/scripts/post-config.d" directory
#!/bin/bash

# updating snmp description to include system model
sed 's/print "sysDescr Edge.*/print "sysDescr EdgeOS \$version " . \`\/usr\/sbin\/ubnt-hal show-version | grep "^HW S\/N" | sed "s\/.* \/\/g" | tr -d "\\n"\` . " " . \`\/usr\/sbin\/ubnt-hal getBoardName\` . "\\n";/' /opt/vyatta/sbin/vyatta-snmp.pl -i
=end comment

=cut

    my @myver = split(/ /, $ver);
    return join(' ', @myver[3..8]);
}


sub serial {
    my $ubnt = shift;

    my $serial = uc $ubnt->mac();
    if($serial){
        $serial =~ s/://g;
        return $serial;
    }
    return ;
}

sub mac {
    my $ubnt = shift;
    my $ifDescs = $ubnt->ifDescr;

    foreach my $iid ( keys %$ifDescs ) {
        my $ifDesc = $ifDescs->{$iid};
        next unless defined $ifDesc;
        ## CPU Interface will have the primary MAC for EdgeSwitch
        ## eth0 will have primary MAC for linux-based UBNT devices
        if($ifDesc =~ /CPU/ or $ifDesc eq 'eth0'){
            my $mac = $ubnt->ifPhysAddress->{$iid};

            $mac = lc join( ':', map { sprintf "%02x", $_ } unpack( 'C*', $mac ) );
            
            return $mac if $mac =~ /^([0-9A-F][0-9A-F]:){5}[0-9A-F][0-9A-F]$/i;
            
        }
    }
    
    # MAC malformed or missing
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
