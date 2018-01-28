#!/usr/bin/perl
# 00_local_versionsync.t - Private test to check that all modules are listed in Info.pm
# $Id$

use warnings;
use strict;
use File::Find;
use Test::More;

eval "use File::Slurp";
plan skip_all => "File::Slurp required for testing version sync"
    if $@;

plan qw(no_plan);

my %Items;
# Grab all the =item's from Info.pm
open (I,"lib/SNMP/Info.pm") or fail("Can't open Info.pm");
while (<I>) {
    next unless /^\s*=item\s*(\S+)/;
    $Items{$1}++;
}
close I;

#warn "items : ",join(', ',keys %Items),"\n";

# Check that each package is represented in Info.pm docs
find({wanted => \&check_version, no_chdir => 1}, 'lib');

sub check_version {
    # $_ is the full path to the file
    return unless (m{lib/}xms and m{\.pm \z}xms);

    my $content = read_file($_);

    # Make sure that this package is listed in Info.pm
    fail($_) unless $content =~ m/^\s*package\s+(\S+)\s*;/m;
    
    my $package = $1;

    return if $package eq 'SNMP::Info';

    fail($_) unless defined $Items{$package};

    pass($_);
}
