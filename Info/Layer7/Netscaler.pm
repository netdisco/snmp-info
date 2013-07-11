# SNMP::Info::Layer7::Netscaler
#
# Copyright (c) 2012 Eric Miller
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the University of California, Santa Cruz nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR # ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Layer7::Netscaler;

use strict;
use Exporter;
use SNMP::Info::Layer7;

@SNMP::Info::Layer7::Netscaler::ISA       = qw/SNMP::Info::Layer7 Exporter/;
@SNMP::Info::Layer7::Netscaler::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.03';

%MIBS = (
    %SNMP::Info::Layer7::MIBS,
    'NS-ROOT-MIB' => 'sysBuildVersion',
);

%GLOBALS = (
    %SNMP::Info::Layer7::GLOBALS,
    'build_ver'   => 'sysBuildVersion',
    'sys_hw_desc' => 'sysHardwareVersionDesc',
    'cpu'         => 'resCpuUsage',
);

%FUNCS = (
    %SNMP::Info::Layer7::FUNCS,
    # IP Address Table - NS-ROOT-MIB::nsIpAddrTable
    'ip_index'    => 'ipAddr',
    'ip_netmask'  => 'ipNetmask',
    # TODO VLAN - NS-ROOT-MIB::vlanTable
    'ns_vid'      =>'vlanId',
    'ns_vlan_mem' => 'vlanMemberInterfaces',
    'ns_vtag_int' => 'vlanTaggedInterfaces',
    );

%MUNGE = ( %SNMP::Info::Layer7::MUNGE, );

sub vendor {
    return 'citrix';
}

sub os {
    return 'netscaler';
}

sub serial {
    return '';
}

sub model {
    my $ns    = shift;
    my $desc  = $ns->sys_hw_desc() || '';
   
    $desc =~ s/^.+\bNS//i;

    return $desc;
}

sub os_ver {
    my $ns    = shift;
    my $ver  = $ns->build_ver() || '';
    
    if ($ver =~ /^.+\bNS(\d+\.\d+)/) {
        $ver = $1;
    }
    return $ver;
}


1;
__END__

=head1 NAME

SNMP::Info::Layer7::Netscaler - SNMP Interface to Citrix Netscaler appliances

=head1 AUTHORS

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $ns = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $ns->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Citrix Netscaler appliances

=head2 Inherited Classes

=over

=item SNMP::Info::Layer7

=back

=head2 Required MIBs

=over

=item F<NS-ROOT-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer7> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $ns->vendor()

Returns 'citrix'.

=item $ns->os()

Returns 'netscaler'.

=item $ns->os_ver()

Release extracted from C<sysBuildVersion>.

=item $ns->model()

Model extracted from C<sysHardwareVersionDesc>.

=item $ns->cpu()

C<resCpuUsage>

=item $ns->build_ver()

C<sysBuildVersion>

=item $ns->sys_hw_desc()

C<sysHardwareVersionDesc>

=item $ns->serial()

Returns ''.

=back

=head2 Globals imported from SNMP::Info::Layer7

See documentation in L<SNMP::Info::Layer7> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $ns->ip_index()

C<ipAddr>

=item $ns->ip_netmask()

C<ipNetmask>

=back

=head2 Table Methods imported from SNMP::Info::Layer7

See documentation in L<SNMP::Info::Layer7> for details.

=cut
