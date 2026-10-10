#!/usr/bin/env perl
# pod-coverage.t - Test to check POD coverage of SNMP::Info

use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval {
    require Test::Pod::Coverage;
    Test::Pod::Coverage->VERSION($min_tpc);
    Test::Pod::Coverage->import;
    1;
} or plan skip_all =>
    "Test::Pod::Coverage $min_tpc required for testing POD coverage";

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval { require Pod::Coverage; Pod::Coverage->VERSION($min_pc); 1 }
    or plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage";

all_pod_coverage_ok();
