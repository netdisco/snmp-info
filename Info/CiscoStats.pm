# SNMP::Info::CiscoStats
# Max Baker
#
# Changes since Version 0.7 Copyright (c) 2004 Max Baker 
# All rights reserved.  
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
$VERSION = 1.0;
# $Id$

use strict;

use Exporter;
use SNMP::Info;

use vars qw/$VERSION $DEBUG %MIBS %FUNCS %GLOBALS %MUNGE $INIT/;
@SNMP::Info::CiscoStats::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::CiscoStats::EXPORT_OK = qw//;

%MIBS    = (
            'SNMPv2-MIB'            => 'sysDescr',
            'CISCO-PROCESS-MIB'     => 'cpmCPUTotal5sec',
            'CISCO-MEMORY-POOL-MIB' => 'ciscoMemoryPoolUsed',
            'OLD-CISCO-SYSTEM-MIB'  => 'writeMem',
            'CISCO-PRODUCTS-MIB'    => 'sysName',
            'CISCO-STACK-MIB'       => 'wsc1900sysID',    # some older catalysts live here
            'CISCO-ENTITY-VENDORTYPE-OID-MIB' => 'cevChassis',
           );

%GLOBALS = (
            'description'  => 'sysDescr',
            # We will use the numeric OID's so that we don't require people
            # to install v1 MIBs, which can conflict.
            # OLD-CISCO-CPU-MIB:avgBusyPer
            'ios_cpu'      => '1.3.6.1.4.1.9.2.1.56.0',
            'ios_cpu_1min' => '1.3.6.1.4.1.9.2.1.57.0',
            'ios_cpu_5min' => '1.3.6.1.4.1.9.2.1.58.0',
            # CISCO-PROCESS-MIB
            'cat_cpu'      => 'cpmCPUTotal5sec.9',
            'cat_cpu_1min' => 'cpmCPUTotal1min.9',
            'cat_cpu_5min' => 'cpmCPUTotal5min.9',
            # CISCO-MEMORY-POOL-MIB
            'mem_free'     => 'ciscoMemoryPoolFree.1',
            'mem_used'     => 'ciscoMemoryPoolUsed.1',
            # OLD-CISCO-SYSTEM-MIB
            'write_mem'    => 'writeMem',
           );

%FUNCS   = (
           );

%MUNGE   = (
           );

sub os {
    my $l2 = shift;
    my $descr = $l2->description() || '';

    # order here matters - there are Catalysts that run IOS and have catalyst in their description field.
    return 'ios'      if ($descr =~ /IOS/);
    return 'catalyst' if ($descr =~ /catalyst/i);
    return undef;
}

sub os_ver {
    my $l2    = shift;
    my $os    = $l2->os();
    my $descr = $l2->description();
    
    # Older Catalysts
    if (defined $os and $os eq 'catalyst' and defined $descr and $descr =~ m/V(\d{1}\.\d{2}\.\d{2})/){
        return $1;
    }
    
    # Newer Catalysts and IOS devices
    if (defined $descr and $descr =~ m/Version (\d+\.\d+\([^)]+\)[^,\s]*)(,|\s)+/ ){
        return $1;
    } 
    return undef;
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

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $ciscostats = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $ciscostats->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

SNMP::Info::CiscoStats is a subclass of SNMP::Info that provides cpu, memory, os and
version information about Cisco Devices. 

Use or create in a subclass of SNMP::Info.  Do not use directly.

=head2 Inherited Classes

none.

=head2 Required MIBs

=over

=item CISCO-PRODUCTS-MIB

=item CISCO-PROCESS-MIB

=item CISCO-MEMORY-POOL-MIB

=item SNMPv2-MIB

=item OLD-CISCO-SYSTEM-MIB

=item CISCO-STACK-MIB

=item CISCO-ENTITY-VENDORTYPE-OID-MIB

=back

MIBs can be found at ftp://ftp.cisco.com/pub/mibs/v2/v2.tar.gz

=head1 GLOBALS

=over

=item $ciscostats->cpu()

Returns ios_cpu() or cat_cpu(), whichever is available.

=item $ciscostats->cpu_1min()

Returns ios_cpu_1min() or cat_cpu1min(), whichever is available.

=item $ciscostats->cpu_5min()

Returns ios_cpu_5min() or cat_cpu5min(), whichever is available.

=item $ciscostats->mem_total()

Returns mem_free() + mem_used()

=item $ciscostats->os()

Trys to parse if device is running IOS or CatOS from description()

=item $ciscostats->os_ver()

Trys to parse device operating system version from description()

=item $ciscostats->ios_cpu()

Current CPU usage in percents of device.

B<1.3.6.1.4.1.9.2.1.56.0> = 
B<OLD-CISCO-CPU-MIB:avgBusyPer>

=item $ciscostats->ios_cpu_1min()

Average CPU Usage in percents of device over last minute.

B<1.3.6.1.4.1.9.2.1.57.0>

=item $ciscostats->ios_cpu_5min()

Average CPU Usage in percents of device over last 5 minutes.

B<1.3.6.1.4.1.9.2.1.58.0>

=item $ciscostats->cat_cpu()

Current CPU usage in percents of device.

B<CISCO-PROCESS-MIB::cpmCPUTotal5sec.9>

=item $ciscostats->cat_cpu_1min()

Average CPU Usage in percents of device over last minute.

B<CISCO-PROCESS-MIB::cpmCPUTotal1min.9>

=item $ciscostats->cat_cpu_5min()

Average CPU Usage in percents of device over last 5 minutes.

B<CISCO-PROCESS-MIB::cpmCPUTotal5min.9>

=item $ciscostats->mem_free()

Main DRAM free in device.  In bytes.

B<CISCO-MEMORY-POOL-MIB::ciscoMemoryPoolFree.1>

=item $ciscostats->mem_used()

Main DRAM used in device.  In bytes.

B<CISCO-MEMORY-POOL-MIB::ciscoMemoryPoolUsed.1>

=back

=head1 TABLE METHODS

None.

=cut
