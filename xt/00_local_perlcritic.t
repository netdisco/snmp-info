#!/usr/bin/env perl
# 00_local_perlcritic.t - Test file for PBP compliance for SNMP::Info

use strict;
use warnings;
use Test::More;

eval {
    require Test::Perl::Critic;
    Test::Perl::Critic->import( -severity => 5 );
    1;
} or plan skip_all => "Test::Perl::Critic required for testing PBP compliance";

Test::Perl::Critic::all_critic_ok();
