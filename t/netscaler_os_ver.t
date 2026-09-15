use strict;
use warnings;
use Test::More;
use lib 'lib';

use SNMP::Info::Layer7::Netscaler;

{
    package TestNetscaler;
    our @ISA = ('SNMP::Info::Layer7::Netscaler');

    sub build_ver { return $_[0]->{build_ver}; }
}

my $ns = bless {}, 'TestNetscaler';

for my $case (
    ['NetScaler NS14.1: Build 72.61.nc, Date: Sep 2026', '14.1-72.61', 'release and build'],
    ['NetScaler NS9.3: Build 55.6.nc, Date: ', '9.3-55.6', 'older release and build'],
    ['NetScaler ns14.1: build 72.61.nc', '14.1-72.61', 'case-insensitive build format'],
    ['NetScaler NS14.1: Build 72.nc', '14.1-72', 'integer build'],
    ['NetScaler NS14.1: Date: Sep 2026', '14.1', 'release-only fallback'],
    ['Unrecognized version string', 'Unrecognized version string', 'unrecognized input unchanged'],
    [undef, '', 'missing version returns empty string'],
) {
    $ns->{build_ver} = $case->[0];
    is($ns->os_ver(), $case->[1], $case->[2]);
}

done_testing();
