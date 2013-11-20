#!/usr/bin/perl
#
# test_class_mocked.pl
#
# Copyright (c) 2012 Eric Miller
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
use FindBin;
use lib "$FindBin::Bin/../../..";
use File::Slurp qw(slurp);
use Getopt::Long;
use Pod::Usage;
use SNMP::Info;
use Test::MockObject::Extends;

my $EMPTY = q{};

# Default Values
my $class = $EMPTY;
my @dump  = ();
my $debug = 0;
my $mibdirs;
my $ignore = 0;
my $help   = 0;
my $file;
my %dumped;

GetOptions(
    'c|class=s'  => \$class,
    'i|ignore'   => \$ignore,
    'p|print=s'  => \@dump,
    'x|debug+'   => \$debug,
    'm|mibdir=s' => \$mibdirs,
    'file=s'     => \$file,
    'h|?|help'   => sub { pod2usage(1); },
);

if ( !$file ) {
    pod2usage(1);
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
    =~ s{::}{/}g;    # SNMP::Info::Layer3 => SNMP/Info/Layer3.pm
if ( !eval { require $mod; 1; } ) {
    croak "Could not load $class. Error Message: $@\n";
}

my $class_ver = $class->VERSION();

print
    "Class $class ($class_ver) loaded from SNMP::Info $SNMP::Info::VERSION.\n";

if ( scalar @dump ) { print 'Dumping : ', join( q{,}, @dump ), "\n" }

my $mocked = create_mock_session();

my $dev = $class->new(
    'AutoSpecify' => 0,
    'BulkWalk'    => 0,
    'Debug'       => $debug,
    'Session'     => $mocked,
) or die "\n";

print 'Detected Class: ', $dev->device_type(), "\n";
print "Using    Class: $class (-c to change)\n";

my $layers = $dev->layers();
my $descr  = $dev->description();

if ( !defined $layers || !defined $descr ) {
    die "Are you sure you specified a file created with make_snmpdata.pl ?\n";
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

sub load_snmpdata {
    my $data_file = shift;

    my @lines = slurp($data_file);

    my $snmp_data = {};
    foreach my $line (@lines) {
	next if !$line;
	next if ( $line =~ /^#/ );
	if ( $line =~ /^(\S+::\w+)[.]?(\S+)*\s=\s(.*)$/ ) {
	    my ( $leaf, $iid, $val ) = ( $1, $2, $3 );
	    next if !$leaf;
	    $iid ||= 0;
	    $val =~ s/\"//g;
	    $snmp_data->{$leaf}->{$iid} = $val;
	}
    }
    return $snmp_data;
}

sub create_mock_session {

    my $snmp_data = load_snmpdata($file);

    my $session = SNMP::Session->new(
	UseEnums    => 1,
	RetryNoSuch => 1,
	Data        => $snmp_data,
	DestHost    => '127.0.0.1',
	Community   => 'public',
	Version     => 2,
    );

    my $mock_session = Test::MockObject::Extends->new($session);

    mock_get($mock_session);
    mock_getnext($mock_session);

    return $mock_session;
}

sub mock_get {
    my $mock_session = shift;

    $mock_session->mock(
	'get',
	sub {
	    my $self = shift;
	    my $vars = shift;
	    my ( $leaf, $iid, $oid, $oid_name );
	    my $c_data = $self->{Data};

	    # From SNMP::Info get will only be passed either an OID or
	    # SNMP::Varbind with a fully qualified leaf and potentially
	    # a partial
	    if ( ref($vars) =~ /SNMP::Varbind/ ) {
		( $leaf, $iid ) = @{$vars};
	    }
	    else {
		$oid = $vars;
		$oid_name = SNMP::translateObj( $oid, 0, 1 ) || $EMPTY;
		( $leaf, $iid ) = $oid_name =~ /^(\S+::\w+)[.]?(\S+)*$/;
	    }

	    $iid ||= 0;
	    my $new_iid = $iid;
	    my $val     = $EMPTY;
	    my $data    = $c_data->{$leaf} || {};
	    my $count   = scalar keys %{$data} || 0;
	    if ( $count > 1 ) {
		my $found = 0;
		foreach my $d_iid ( sort keys %{$data} ) {
		    if ( $d_iid eq $iid ) {
			$val   = $data->{$d_iid};
			$found = 1;
			next;
		    }
		    elsif ( $found == 1 ) {
			$new_iid = $d_iid;
			last;
		    }
		}
		if ( $found && ( $new_iid eq $iid ) ) {
		    $leaf = 'unknown';
		}
	    }
	    else {
		$val  = $data->{$iid};
		$leaf = 'unknown';
	    }

	    if ( ref $vars =~ /SNMP::Varbind/ ) {
		$vars->[0] = $leaf;
		$vars->[1] = $new_iid;
		$vars->[2] = $val;
	    }
	    return ( wantarray() ? $vars : $val );
	}
    );
    return;
}

sub mock_getnext {
    my $mock_session = shift;

    $mock_session->mock(
	'getnext',
	sub {
	    my $self = shift;
	    my $vars = shift;
	    my ( $leaf, $iid, $oid, $oid_name );
	    my $c_data = $self->{Data};

	    # From SNMP::Info getnext will only be passed a SNMP::Varbind
	    # with a fully qualified leaf and potentially a partial
	    ( $leaf, $iid ) = @{$vars};

	    unless (defined $iid) {
		$iid = -1;
	    }
	    my $new_iid = $iid;
	    my $val     = $EMPTY;
	    my $data    = $c_data->{$leaf};
	    my $count   = scalar keys %{$data} || 0;
	    if ( $count ) {
		my $found = 0;
		foreach my $d_iid ( sort keys %{$data} ) {
		    if ( $d_iid gt $iid && !$found ) {
			$val     = $data->{$d_iid};
			$new_iid = $d_iid;
			$found   = 1;
			next;
		    }
		    elsif ( $found == 1 ) {
			last;
		    }
		}
		if ( $found && ( $new_iid eq $iid ) ) {
		    $leaf = 'unknown';
		}
	    }
	    else {
		$val  = $data->{$iid};
		$leaf = 'unknown';
	    }

	    $vars->[0] = $leaf;
	    $vars->[1] = $new_iid;
	    $vars->[2] = $val;
	    return ( wantarray() ? $vars : $val );
	}
    );
    return;
}

sub test_global {
    my $device = shift;
    my $method = shift;

    my $value = $device->$method();

    if ( !defined $value ) {
	printf "%-20s Does not exist.\n", $method;
	return 0;
    }
    $value =~ s/[[:cntrl:]]+/ /g;
    if ( length $value > 60 ) {
	$value = substr $value, 0, 60;
	$value .= '...';
    }
    printf "%-20s %s \n", $method, $value;
    return 1;
}

sub test_fn {
    my $device = shift;
    my $method = shift;

    my $results = $device->$method();

    # If accidentally called on a global, pass it along nicely.
    if ( defined $results && !ref $results ) {
	return test_global( $dev, $method );
    }
    if ( !defined $results && !scalar keys %{$results} ) {
	printf "%-20s Empty Results.\n", $method;
	return 0;
    }

    printf "%-20s %d rows.\n", $method, scalar keys %{$results};
    if ( grep {/^$method$/} @dump ) {
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

test_class_mocked.pl - Test a device against an SNMP::Info class using
output from make_snmpdata.pl stored in a text file.

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

test_class_mocked.pl [options]

Options:

    -class    SNMP::Info class to use, Layer2::Catalyst    
    -file     File containing data gathered using make_snmpdata.pl
    -print    Print values 
    -debug    Debugging flag
    -ignore   Ignore Net-SNMP configuration file
    -mibdir   Directory containing MIB Files
    -help     Brief help message

=head1 OPTIONS

=over 8

=item B<-class>

Specific SNMP::Info class to use.  Defaults to SNMP::Info if no specific
class provided.

-class Layer2::Catalyst

=item B<-file>

File containing data gathered using make_snmpdata.pl.  No default and a
mandatory option.

-file /data/mydevice.txt

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

=item B<-help>

Print help message and exits.

=back

=head1 DESCRIPTION

B<test_class_mocked.pl> will test a device against an SNMP::Info class using
snmpwalk output from the utility B<make_snmpdata.pl> stored in a text file.
This allows debugging and testing without requiring network access to the
device being tested.

=cut
