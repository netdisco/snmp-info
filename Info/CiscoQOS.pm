# SNMP::Info::CiscoQOS
# Alexander Hartmaier <alexander.hartmaier@t-systems.at>
# $Id$
#
# Copyright (c) 2005 Alexander Hartmaier
#
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

package SNMP::Info::CiscoQOS;
$VERSION = 1.0;
use strict;

use Exporter;
use SNMP::Info;

@SNMP::Info::CiscoQOS::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::CiscoQOS::EXPORT_OK = qw//;

use vars qw/$VERSION $DEBUG %MIBS %FUNCS %GLOBALS %MUNGE $INIT/;

%MIBS    = (
            'CISCO-CLASS-BASED-QOS-MIB'      => 'cbQosIfIndex',
           );

%GLOBALS = (
           );

%FUNCS   = (
            # CISCO-CLASS-BASED-QOS-MIB
            'qos_i_index'             => 'cbQosIfIndex',
            'qos_i_type'              => 'cbQosIfType',
            'qos_pol_direction'       => 'cbQosPolicyDirection',
            'qos_obj_index'           => 'cbQosConfigIndex',
            'qos_obj_type'            => 'cbQosObjectsType',
            'qos_obj_parent'          => 'cbQosParentObjectsIndex',
            'qos_cm_name'             => 'cbQosCMName',
            'qos_cm_desc'             => 'cbQosCMDesc',
            'qos_cm_info'             => 'cbQosCMInfo',
            'qos_octet_pre'           => 'cbQosCMPrePolicyByte',
            'qos_octet_post'          => 'cbQosCMPostPolicyByte',
           );

%MUNGE   = (
           );

1;
__END__

=head1 NAME

SNMP::Info::CiscoQOS - Perl5 Interface to Cisco's Quality of Service MIBs

=head1 AUTHOR

Alexander Hartmaier (C<alexander.hartmaier@t-systems.at>)

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $qos = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $qos->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

SNMP::Info::CiscoQOS is a subclass of SNMP::Info that provides 
information about a cisco device's QoS config.

Use or create in a subclass of SNMP::Info.  Do not use directly.

=head2 Inherited Classes

none.

=head2 Required MIBs

=over

=item CISCO-CLASS-BASED-QOS-MIB

=back

MIBs can be found at ftp://ftp.cisco.com/pub/mibs/v2/v2.tar.gz

=head1 GLOBALS

=over

none

=back

=head1 TABLE METHODS

=head2 ServicePolicy Table

This table is from CISCO-CLASS-BASED-QOS-MIB::cbQosServicePolicyTable

This table describes the interfaces/media types and the policymap that are attached to it.

=over

=item $qos->qos_i_index()

(B<cbQosIfIndex>)

=item $qos->qos_i_type()

(B<cbQosIfType>)

=head2 ClassMap configuration Table

This table is from CISCO-CLASS-BASED-QOS-MIB::cbQosCMCfgTable

=over

=back

=cut
