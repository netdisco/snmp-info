#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 1.302083;

use SNMP::Info;
use Path::Class 'dir';

# needed when running with Alien::SNMP::MAXTC
%SNMP::Info::MIBS = ('RFC1213-MIB' => 'sysName');

my $info = SNMP::Info->new(
  AutoSpecify => 1,
  Debug       => 1,
  DestHost    => 'demo.snmplabs.com',
  Community   => 'public',
  Version     => 2,
  MibDirs     => [ _build_mibdirs() ],
  IgnoreNetSNMPConf => 1,
#  Debug       => 1,
#  DebugSNMP   => 1,
);

ok($info, 'SNMP::Info instantiated');
ok((!defined $info->error()), 'No error on initial connection');

like($info->name(),  qr/\w+/, 'name is "new system name"');
is($info->class(), 'SNMP::Info::Layer3::NetSNMP', 'class is Layer3::NetSNMP');

done_testing;

sub _build_mibdirs {
  my $home = dir($ENV{HOME}, 'netdisco-mibs');
  return map { dir($home, $_)->stringify } @{ _get_mibdirs_content($home) };
}

sub _get_mibdirs_content {
  my $home = shift;
  my @list = map {s|$home/||; $_} grep {m/[a-z0-9]/} grep {-d} glob("$home/*");
  return \@list;
}
