#!/usr/bin/perl -w
#
# test_class.pl
#
#   Test a device class in SNMP::Info against a device.
#
# Max Baker <max@warped.org>
#
# $Id$
#

use lib '/usr/local/netdisco';
use SNMP::Info;
use Getopt::Long;
use strict;
use vars qw/$Class $Dev $Comm $Ver/;

# Default Values
$Class = '';
$Dev   = '';
$Comm  = '';
$Ver   = 2;

GetOptions ('c|class=s' => \$Class,
            'd|dev=s'   => \$Dev,
            's|comm=s'  => \$Comm,
            'v|ver=i'   => \$Ver,
            'h|help'    => \&usage,
           );


&usage unless ($Dev and $Comm);

$Class = $Class ? "SNMP::Info::$Class" : 'SNMP::Info';
eval "require $Class;";
if ($@) {
    die "Can't load Class specified : $Class.\n\n$@\n";
}

print "Class $Class loaded.\n";

my $dev = new $Class( 'AutoSpecify' => 0,
                      'AutoVerBack' => 0,
                      'Version'     => $Ver,
                      'Debug'       => 0,
                      'DestHost'    => $Dev,
                      'Community'   => $Comm
                    ) or die "\n"; 

print "Connected to $Dev.\n";
    
my $layers = $dev->layers();

unless (defined $layers){
    warn "Are you sure you got the right community string and version?\nCan't fetch layers.\n";
}

print "Fetching global info...\n\n";

my @globals = qw/description uptime contact name location layers ports mac serial
                ps1_type ps2_type ps1_status ps2_status fan slots vendor os os_ver/;

foreach my $global (@globals){
    test_global($dev,$global);
}

print "\nFetching interface info...\n\n";

my @fns = qw/interfaces i_type i_ignore i_description i_mtu i_speed i_mac i_up
             i_up_admin i_name i_duplex i_duplex_admin i_stp_state/;

foreach my $fn (@fns){
    test_fn($dev,$fn);
}

#--------------------------------
sub test_global {
    my $dev    = shift;
    my $method = shift;

    my $value;
    eval {
        $value = $dev->$method();
    };
    
    if ($@){
        my $err = $@;
        $err =~ s/\n/ /g;
        printf "%-20s Blew up. $err\n",$method;
        return 0;
    }
    
    unless (defined $value){
        printf "%-20s Does not exist.\n",$method;
        return 0;
    }
    $value =~ s/\n/ /g;
    if (length $value > 60) {
        $value = substr($value,0,60);
        $value .= '...';
    }
    printf "%-20s %s \n",$method,$value;
    return 1;
}

sub test_fn {
    my $dev = shift;    
    my $method = shift;

    my $results;

    eval {
        $results = $dev->$method();
    };

    if ($@){
        my $err = $@;
        $err =~ s/\n/ /g;
        printf "%-20s Blew up. $err\n",$method;
        return 0;
    }

    unless (defined $results and scalar keys %$results) {
        printf "%-20s Empty Results.\n",$method;
        return 0;
    }

    printf "%-20s %d rows.\n",$method, scalar(keys %$results);
    return 1;
}

sub usage {
    print << "end_usage";

test_class - Test a device against an SNMP::Info class
    -c  --class Layer2::Catalyst
    -d  --dev   myswitch
    -s  --comm  public
    -v  --ver   2

end_usage
    exit;
}
