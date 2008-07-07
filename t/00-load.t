#!/usr/bin/perl
# 00-load.t - Test loading of SNMP::Info 
# $Id$

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
	use_ok( 'SNMP::Info' );
}

diag( "Testing SNMP::Info $SNMP::Info::VERSION, Perl $], $^X" );
