# SNMP::Info::Layer2::Ubiquiti
# $Id$
#

package SNMP::Info::Layer2::Ubiquiti;

use strict;
use Exporter;
use SNMP::Info::IEEE802dot11;
use SNMP::Info::Layer2;
use SNMP::Info::Layer3;  # only used in sub mac()



@SNMP::Info::Layer2::Ubiquiti::ISA
    = qw/SNMP::Info::IEEE802dot11 SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::Ubiquiti::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE/;

$VERSION = '3.49';

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

    ## EdgeMAX OS (EdgeSwitch and EdgeRouter) name is first field split by space
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
        ## Not sure what this function does, it seems to be extraneous being in the same code block after a return statement?
        if ( $ver =~ /([\d\.]+)/ ) {
            return $1;
        }
    }
    my $ver = $dot11->description() || '';
    if($ver =~ /^edgeswitch/){
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
    my $ubnt = shift;

    my $names = $ubnt->dot11_prod_name();

    foreach my $iid ( keys %$names ) {
        my $prod = $names->{$iid};
        next unless defined $prod;
        return $prod;
    }
    
    my $desc = $ubnt->description() || '';
    
    ## Pull Model from beginning of description, separated by comma (EdgeSwitch)
    if((lc $desc) =~ /^edgeswitch/){    
        my @mydesc = split(/, /, $desc);
        return $mydesc[0];
    }

    if(!((lc $desc) =~ /edgeos/)){
        # Not sure what type of device this is to get Model
        # Wireless devices report dot11_prod_name
        # EdgeSwitch includes mode directly and edgeos logic is in else statement
        return ;
    }else{
        ## do some logic to determine ER model based on tech specs from ubnt:
        ## https://help.ubnt.com/hc/en-us/articles/219652227--EdgeRouter-Which-EdgeRouter-Should-I-Use-#tech%20specs
        ## Would be nice if UBNT simply adds the model string to their SNMP daemon directly
        my $ethCount = 0;
        my $switchCount = 0;
        #my $sfpCount = 0;
        #my $poeCount = 0;  
        my $memTotalReal = $ubnt->memTotalReal;   
        my $cpuLoad = $ubnt->hrProcessorLoad;
        my $cpuCount = 0;
        ## My perl is lacking. Not sure if there's a more efficient way to find the cpu count
        foreach my $iid ( keys %$cpuLoad ) {
            $cpuCount++;
        }
        
        my $ifDescs = $ubnt->ifDescr;
        foreach my $iid ( keys %$ifDescs ) {
            my $ifDesc = $ifDescs->{$iid};
            next unless defined $ifDesc;

            if((lc $ifDesc) =~ /^eth\d+$/){ # exclude vlan interfaces. Ex: eth1.5
                $ethCount++;
            }elsif((lc $ifDesc) =~ /^switch/){
                $switchCount++;
            }
        }

        ## If people have other models to further fine-tune this logic that would be great. 
        if($ethCount eq 9){
            ## Should be ER Infinity
            return "EdgeRouter Infinity"
        }if($ethCount eq 8){
            ## Could be ER-8 Pro, ER-8, or EP-R8
            return "EdgeRouter 8-Port"
        }elsif($ethCount eq 5 and $cpuCount eq 4){
            ## Could be ER-X or ER-X-SFP
            return "EdgeRouter X 5-Port"
        }elsif($ethCount eq 5){
            return "EdgeRouter PoE 5-Port"
        }elsif($ethCount eq 3 and $cpuCount eq 2){
            return "EdgeRouter LITE 3-Port"
        }else{
            ## failback string
            return "EdgeRouter eth-$ethCount switch-$switchCount mem-$memTotalReal cpuNum-$cpuCount";
        }
        
    }
}

## simply take the MAC and clean it up
sub serial {
    my $ubnt = shift;

    my $serial = $ubnt->mac();
    if($serial){
        $serial =~ s/://g;
        return uc $serial;
    }
    return ;
}

## UBNT doesn't put the primary-mac interface at index 1
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

            # syntax stolen from sub munge_mac in SNMP::Info
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

Returns the model extracted from C<dot11manufacturerProductName>, with failback to some complex logic for EdgeMax devices

=item $ubnt->serial()

Serial Number.

=item $ubnt->mac()

Bridge MAC address.

=item $ubnt->os()

Returns 'Ubiquiti Networks, Inc.'

=item $ubnt->os_ver()

Returns the software version extracted from C<dot11manufacturerProductVersion>, with failback to description splitting for EdgeMax devices

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
