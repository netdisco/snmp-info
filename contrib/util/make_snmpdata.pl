#!/usr/bin/perl
#
# make_snmpdata.pl
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
use Getopt::Long;
use Pod::Usage;
use SNMP;

local $| = 1;

my $mibdirs = ['/usr/local/share/snmp/mibs'];
my $comm    = 'public';
my $ver     = '2c';
my $dev;
my $ignore = 0;
my $help   = 0;

GetOptions(
    'community=s' => \$comm,
    'device=s'    => \$dev,
    'ignore'      => \$ignore,
    'mibdir=s'   => \$mibdirs,
    'version'     => \$ver,
    'help|?'      => sub { pod2usage(2); },
) or pod2usage(2);

unless ( defined $dev && $ver =~ /[1|2c]/ ) {
    pod2usage(1);
}

local $ENV{'SNMPCONFPATH'} = ''        if $ignore;
local $ENV{'MIBDIRS'}      = "$mibdirs" if $ignore;

SNMP::addMibDirs($mibdirs);

# Connect to Device
my $sess = SNMP::Session->new(
    'UseEnums'       => 1,
    'RetryNoSuch'    => 1,
    'DestHost'       => $dev,
    'Community'      => $comm,
    'Version'        => $ver,
    'UseSprintValue' => 1
);

my $sysdescr = $sess->get('sysDescr.0');
unless ( defined $sysdescr ) {
    die "Couldn't connect to $dev via snmp.\n";
}

SNMP::loadModules(@ARGV);

# Create a hash of MIB Modules for which we want results 
my %mib_hash = map {$_ => 1} @ARGV;
# Add the common MIB Modules we always want
my @common_mibs = ('SNMPv2-MIB', 'IF-MIB');
foreach my $mib (@common_mibs) {
    $mib_hash{$mib} = 1;
}

foreach my $key ( sort( keys %SNMP::MIB ) ) {
    my $module = $SNMP::MIB{$key}{moduleID} || '';
    # IMPORTS pulls in many modules we don't want to walk
    # Only walk those we've specified
    next unless (defined $mib_hash{$module});
    my $access = $SNMP::MIB{$key}{'access'} || '';
    next unless ( $access =~ /Read|Create/x );

    my $label = SNMP::translateObj( $key, 0, 1 ) || '';
    snmpwalk($label);
}

sub snmpwalk {
    return unless defined $sess;
    my $label    = shift;
    my $var      = SNMP::Varbind->new( [$label] );
    my $e        = 0;
    my $last_iid = '';
    my %seen     = ();
    while ( !$e ) {
        $sess->getnext($var);
        $e = $sess->{ErrorNum};

        return if $var->[0] ne $label;
        my $iid = $var->[1];
        my $val = $var->[2];
        return unless defined $iid;

        # Check to see if we've already seen this IID (looping)
        if ( defined $seen{$iid} and $seen{$iid} ) {
            warn "Looping on $label iid:$iid.  Skipped.\n";
            return;
        }
        else { $seen{$iid}++; }

        # why is it looping?
        return if $last_iid eq $iid;
        $last_iid = $iid;

        my $line = "$label.$iid = $val";
        print "$line\n";
    }
    return;
}

__END__

=head1 NAME

make_snmpdata.pl - Tool to get SNMP data for the SNMP::Info testing framework

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

make_snmpdata.pl [options] MIB-MODULE-1 MIB-MODULE-2

Options:

    -community SNMP Community
    -device    IP Address to query
    -ignore    Ignore Net-SNMP configuration file
    -mibdir    Directory containing MIB Files
    -version   SNMP version to use
    -help      Brief help message

=head1 OPTIONS

=over 8

=item B<-community>

SNMP Community, either 1 or 2c.  Defaults to version 2c

-community 2c

=item B<-device>

IP Address to query for the SNMP data.  No default and a mandatory option.

-device 127.0.0.1

=item B<-ignore >

Ignore Net-SNMP configuration file snmp.conf.  If this used mibdirs must be
provided

-ignore

=item B<-mibdir>

Directory containing MIB Files.  Mutiple directories should be separated by a
colon ':'.  Defaults to /usr/local/share/snmp/mibs.

-mibdir /usr/local/share/snmp/mibs/rfc:/usr/local/share/snmp/mibs/net-snmp

=item B<-version>

SNMP version to use.  Only version 1 and 2c are supported.  Defaults to 2c

-version 2c

=item B<-help>

Print help message and exits.

=back

=head1 DESCRIPTION

B<make_snmpdata.pl> will gather SNMP data by walking specified MIB files and
output the data to a file which can be used by the SNMP::Info testing
framework.

=cut
