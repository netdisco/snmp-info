#!/usr/bin/env perl
# 00_local_versionsync.t - Private test to check all version numbers match

use warnings;
use strict;
use File::Find;
use Test::More;

eval "use File::Slurp";
plan skip_all => "File::Slurp required for testing version sync"
    if $@;

plan qw(no_plan);

my $last_version = undef;
find({wanted => \&check_version, no_chdir => 1}, 'lib');
if (! defined $last_version) {
    fail('Failed to find any files with $VERSION');
}

sub check_version {
    # $_ is the full path to the file
    return if (! m{contrib/util/}xms && ! m{\.pm \z}xms);

    my $content = read_file($_);

    # only look at perl scripts, not sh scripts
    return if (m{contrib/util/}xms && $content !~ m/\A \#![^\r\n]+?perl/xms);

    my @version_lines = $content =~ m/ ( [^\n]* \$VERSION\s= [^\n]* ) /gxms;
    if (@version_lines == 0) {
       fail($_);
    }
    for my $line (@version_lines) {
        if (!defined $last_version) {
            $last_version = shift @version_lines;
            pass($_);
        }
        else {
            is($line, $last_version, $_);
        }
    }
}

