# SNMP::Info::CiscoStats
# Max Baker <max@warped.org>
#
# Copyright (c) 2003 Regents of the University of California
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#     * Neither the name of the University of California, Santa Cruz nor the 
#       names of its contributors may be used to endorse or promote products 
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::CiscoStats;
$VERSION = 0.4;
# $Id$

use strict;

use Exporter;
use SNMP::Info;

use vars qw/$VERSION $DEBUG %MIBS %FUNCS %GLOBALS %MUNGE $INIT/;
@SNMP::Info::CiscoStats::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::CiscoStats::EXPORT_OK = qw//;

$DEBUG=0;
$SNMP::debugging=$DEBUG;

$INIT    = 0;
%MIBS    = (
            'CISCO-PROCESS-MIB'     => 'cpmCPUTotal5sec',
            'CISCO-MEMORY-POOL-MIB' => 'ciscoMemoryPoolUsed' 
           );

%GLOBALS = (
            # OLD-CISCO-CPU-MIB:avgBusyPer
            'ios_cpu'      => '1.3.6.1.4.1.9.2.1.56.0',
            'ios_cpu_1min' => '1.3.6.1.4.1.9.2.1.57.0',
            'ios_cpu_5min' => '1.3.6.1.4.1.9.2.1.58.0',
            'cat_cpu'      => 'cpmCPUTotal5sec.9',
            'cat_cpu_1min' => 'cpmCPUTotal1min.9',
            'cat_cpu_5min' => 'cpmCPUTotal5min.9',
            # CISCO-MEMORY-POOL-MIB
            'mem_free'     => 'ciscoMemoryPoolFree.1',
            'mem_used'     => 'ciscoMemoryPoolUsed.1',
           );

%FUNCS   = (
           );

%MUNGE   = (
          # Inherit all the built in munging
          %SNMP::Info::MUNGE,
          # Add ones for our class
           );

sub os {
    my $l2 = shift;
    my $descr = $l2->description();

    return 'catalyst' if ($descr =~ /catalyst/i);
    return 'ios'      if ($descr =~ /IOS/);
}

sub os_ver {
    my $l2    = shift;
    my $os    = $l2->os();
    my $descr = $l2->description();
    
    # Older Catalysts
    if ($os eq 'catalyst' and $descr =~ m/V(\d{1}\.\d{2}\.\d{2})/){
        return $1;
    }

    # Newer Catalysts and IOS devices
    if ($descr =~ m/Version (\d+\.\d+\([^)]+\))/ ){
        return $1;
    } 
}

sub cpu {
    my $self = shift;
    my $ios_cpu = $self->ios_cpu();
    return $ios_cpu if defined $ios_cpu;
    my $cat_cpu = $self->cat_cpu();
    return $cat_cpu;
}

sub cpu_1min {
    my $self = shift;
    my $ios_cpu_1min = $self->ios_cpu_1min();
    return $ios_cpu_1min if defined $ios_cpu_1min;
    my $cat_cpu_1min = $self->cat_cpu_1min();
    return $cat_cpu_1min;
}

sub cpu_5min {
    my $self = shift;
    my $ios_cpu_5min = $self->ios_cpu_5min();
    return $ios_cpu_5min if defined $ios_cpu_5min;
    my $cat_cpu_5min = $self->cat_cpu_5min();
    return $cat_cpu_5min;
}

sub mem_total {
    my $self = shift;
    my $mem_free = $self->mem_free();
    my $mem_used = $self->mem_used();
    return undef unless defined $mem_free and defined $mem_used;
    return $mem_free + $mem_used;
}

1;
__END__

=head1 NAME

SNMP::Info::CiscoStats - Perl5 Interface to CPU and Memory stats for Cisco Devices

=head1 DESCRIPTION

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

To be used internally from device sub classes.  See SNMP::Info.

=head1 METHODS

=head2 GLOBAL METHODS

=head2 TABLE METHODS

=cut
