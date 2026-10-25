#!/usr/bin/env perl
# 00_local_versionsync.t - Private test to check that all modules are listed in Info.pm

use warnings;
use strict;
use File::Find;
use Test::More;

eval { require File::Slurp; File::Slurp->import('read_file'); 1 }
    or plan skip_all => "File::Slurp required for testing version sync";

plan qw(no_plan);

my %Items;
# Grab all the =item's from Info.pm
open( my $info_fh, '<', 'lib/SNMP/Info.pm' ) or fail("Can't open Info.pm");
while (<$info_fh>) {
    next unless /^\s*=item\s*(\S+)/;
    $Items{$1}++;
}
close $info_fh;

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

    if (!defined $Items{$package}) {
        print STDERR sprintf "package missing from Info.pm: %s\n", ($package || '?');
        fail($_);
    }

    pass($_);
}
