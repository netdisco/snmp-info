#!/usr/bin/env perl

use strict;
use warnings;

use lib 'xt/lib';
use Module::Find;

my @BAD_MODULES = qw(
  Test::SNMP::Info::MAU
  Test::SNMP::Info::Layer3::C4000
);

my @found = findallmod 'Test::SNMP::Info';
unshift @found, 'Test::SNMP::Info';

# pass a specific module to test,
# using e.g. "prove xt/21_run.t :: Test::SNMP::Info::MAU"
if (scalar @ARGV) { @found = @ARGV }

# cannot do this inline with findallmod
@found = sort { (scalar split m/::/, $a) <=> (scalar split m/::/, $b)
                    or
                $a cmp $b } @found;
                
# my $total = scalar @found - scalar @BAD_MODULES;
# this did not work because @found can be a subset (e.g. via ARGV), so subtracting
# all BAD modules (even those not in @found) makes the TAP plan incorrect.
# the below seems to work correctly for the hand-picked usage like
#  prove  xt/21_run.t ::  Test::SNMP::Info::Layer7::Stormshield
my $total = scalar grep {
  my $m = $_;
  ! grep { $_ eq $m } @BAD_MODULES
} @found;
my $count = 0;

# fake test plan
print "1..$total\n";

foreach my $module (@found) {
  if (grep m/^${module}$/, @BAD_MODULES) {
    # printf STDERR "!!> skipping: %s\n", $module;
    next;
  }

  my $preamble = <<'END_CODE_PREAMBLE';
    # this is to avoid annoying plan warnings with the way subtests are done
    {
      use Hook::LexWrap;
      use Test::Builder;
      no warnings 'redefine';
      wrap *Test::Builder::diag, pre => sub {
        $_[-1] = 1
          if $_[1] and $_[1] =~ m/Tests were run but no plan was declared/;
      };
    }
END_CODE_PREAMBLE

  my $code = <<"END_CODE";
    $module->builder->current_test($count);
    Test::More::subtest '$module' => sub { $module->runtests() };
END_CODE

  # printf STDERR "--> %d: %s\n", ($count + 1), $module;
  system (qw{perl -Ilib -Ixt/lib}, "-M$module", '-e', $preamble . $code);
  ++$count;
}
