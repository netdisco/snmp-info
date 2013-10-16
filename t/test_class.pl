#!/usr/bin/perl
#
# test_class.pl
#
# Copyright (c) 2013 Eric Miller
# All rights reserved.
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
# LIABLE FOR # ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

use strict;
use warnings;
use Carp;
use Getopt::Long;
use Pod::Usage;
use SNMP::Info;

my $EMPTY = q{};

# Default Values
my $class  = $EMPTY;
my @dump   = ();
my $debug  = 0;
my $device = '';
my $comm   = '';
my $ver    = 2;
my $ignore = 0;
my $help   = 0;
my $nobulk = 0;
my $mibdirs;
my %dumped;

GetOptions(
    'c|class=s'  => \$class,
    'd|dev=s'    => \$device,
    's|comm=s'   => \$comm,
    'v|ver=i'    => \$ver,
    'i|ignore'   => \$ignore,
    'p|print=s'  => \@dump,
    'x|debug+'   => \$debug,
    'm|mibdir=s' => \$mibdirs,
    'n|nobulk'   => \$nobulk,
    'h|?|help'   => sub { pod2usage(1); },
);

unless ( $device and $comm ) {
    pod2usage(2);
}

if ( $ignore && !defined $mibdirs ) {
    print "mibdirs must be provided if ignoring snmp.conf \n\n";
    pod2usage(1);
}

local $ENV{'SNMPCONFPATH'} = $EMPTY     if $ignore;
local $ENV{'MIBDIRS'}      = "$mibdirs" if $ignore;

if ( defined $mibdirs ) {
    SNMP::addMibDirs($mibdirs);
}

$class = $class ? "SNMP::Info::$class" : 'SNMP::Info';

( my $mod = "$class.pm" )
    =~ s{::}{/}xg;    # SNMP::Info::Layer3 => SNMP/Info/Layer3.pm
if ( !eval { require $mod; 1; } ) {
    croak "Could not load $class. Error Message: $@\n";
}

my $class_ver = $class->VERSION();

print
    "Class $class ($class_ver) loaded from SNMP::Info $SNMP::Info::VERSION.\n";

if ( scalar @dump ) { print 'Dumping : ', join( q{,}, @dump ), "\n" }

my %args = ();
if ($nobulk) {
    $args{BulkWalk} = 0;
}

my $dev = $class->new(
    'AutoSpecify' => 0,
    'AutoVerBack' => 0,
    'Debug'       => $debug,
    'Version'     => $ver,
    'DestHost'    => $device,
    'Community'   => $comm,
    %args
) or die "\n";

print "Connected to $device.\n";
print 'Detected Class: ', $dev->device_type(), "\n";
print "Using    Class: $class (-c to change)\n";

my $layers = $dev->layers();
my $descr  = $dev->description();

if ( !defined $layers || !defined $descr ) {
    die
	"Are you sure you got the right community string and version?\nCan't fetch layers or description.\n";
}

print "\nFetching base info...\n\n";

my @base_fns = qw/vendor model os os_ver description contact location
    layers mac serial/;

foreach my $fn (@base_fns) {
    test_global( $dev, $fn );
}

print "\nFetching interface info...\n\n";

my @fns = qw/interfaces i_type i_ignore i_description i_mtu i_speed i_mac i_up
    i_up_admin i_name i_duplex i_duplex_admin i_stp_state
    i_vlan i_pvid i_lastchange/;

foreach my $fn (@fns) {
    test_fn( $dev, $fn );
}

print "\nFetching VLAN info...\n\n";

my @vlan = qw/v_index v_name/;

foreach my $fn (@vlan) {
    test_fn( $dev, $fn );
}

print "\nFetching topology info...\n\n";

my @topo = qw/c_if c_ip c_port c_id c_platform/;

foreach my $fn (@topo) {
    test_fn( $dev, $fn );
}

print "\nFetching module info...\n\n";

my @modules = qw/e_descr e_type e_parent e_name e_class e_pos e_hwver
    e_fwver e_swver e_model e_serial e_fru/;

foreach my $fn (@modules) {
    test_fn( $dev, $fn );
}

foreach my $fn (@dump) {
    if ( !$dumped{$fn} ) { test_fn( $dev, $fn ) }
}

#--------------------------------

sub test_global {
    my $info   = shift;
    my $method = shift;

    my $value = $info->$method();

    if ( !defined $value ) {
	printf "%-20s Does not exist.\n", $method;
	return 0;
    }
    $value =~ s/[[:cntrl:]]+/ /gx;
    if ( length $value > 60 ) {
	$value = substr $value, 0, 60;
	$value .= '...';
    }
    printf "%-20s %s \n", $method, $value;
    return 1;
}

sub test_fn {
    my $info   = shift;
    my $method = shift;

    my $results = $info->$method();

    # If accidentally called on a global, pass it along nicely.
    if ( defined $results && !ref $results ) {
	return test_global( $dev, $method );
    }
    if ( !defined $results && !scalar keys %{$results} ) {
	printf "%-20s Empty Results.\n", $method;
	return 0;
    }

    printf "%-20s %d rows.\n", $method, scalar keys %{$results};
    if ( grep {/^$method$/x} @dump ) {
	$dumped{$method} = 1;
	foreach my $iid ( keys %{$results} ) {
	    print "  $iid : ";
	    if ( ref( $results->{$iid} ) eq 'ARRAY' ) {
		print '[ ', join( ', ', @{ $results->{$iid} } ), ' ]';
	    }
	    else {
		print $results->{$iid};
	    }
	    print "\n";
	}
    }
    return 1;
}

__END__

=head1 NAME

test_class.pl - Test a device against an SNMP::Info class.

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

test_class.pl [options]

Options:

    -c|class    SNMP::Info class to use, Layer2::Catalyst    
    -d|dev      Device
    -s|comm     SNMP community
    -v|ver      SNMP version
    -p|print    Print values 
    -x|debug    Debugging flag
    -i|ignore   Ignore Net-SNMP configuration file
    -m|mibdir   Directory containing MIB Files
    -n|nobulk   Disable bulkwalk
    -h|?|help   Brief help message

=head1 OPTIONS

=over 8

=item B<-class>

Specific SNMP::Info class to use.  Defaults to SNMP::Info if no specific
class provided.

-class Layer2::Catalyst

=item B<-dev>

Device to test against.  No default and a mandatory option.

-dev 1.2.3.4

=item B<-comm>

SNMP community string.  No default and a mandatory option.

-comm public

=item B<-ver>

SNMP version. Default 2.

-ver 1

=item B<-print>

Print values of a class method rather than summarizing.  May be repeated
multiple times. 

-print i_description -print i_type

=item B<-debug>

Turns on SNMP::Info debug.

-debug

=item B<-ignore >

Ignore Net-SNMP configuration file snmp.conf.  If this used mibdirs must be
provided.

-ignore

=item B<-mibdir>

Directory containing MIB Files.  Multiple directories should be separated by a
colon ':'. 

-mibdir /usr/local/share/snmp/mibs/rfc:/usr/local/share/snmp/mibs/net-snmp

=item B<-nobulk >

Disable SNMP bulkwalk. Default bulkwalk is on and utilized with version 2.

-nobulk

=item B<-help>

Print help message and exits.

=back

=head1 DESCRIPTION

B<test_class.pl> will test a device against a specfied SNMP::Info class.
This allows debugging and testing of live devices to include validating
device support with existing classes.

=cut
