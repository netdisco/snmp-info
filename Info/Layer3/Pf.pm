# SNMP::Info::Layer3::Pf
# $Id$
#
# Copyright (c) 2010 Max Baker
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
#     * Neither the name of Pf Networks, Inc. nor the
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

package SNMP::Info::Layer3::Pf;

use strict;
use Exporter;

use SNMP::Info::Layer3;
use SNMP::Info::LLDP;

@SNMP::Info::Layer3::Pf::ISA = qw/SNMP::Info::LLDP SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Pf::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '2.06';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::LLDP::MIBS,
    # Enterprise container where BEGEMOT-* lives
    'FOKUS-MIB' => 'fokus',
    # MIBs used included in Layer3 and above:
    # UDP-MIB
    # TCP-MIB
    # IF-MIB
    #
    # Stuff in these MIBs but not used for Netdisco yet for my test device:
    #
    #'BEGEMOT-SNMPD-MIB',
    #'BEGEMOT-PF-MIB',
    #'BEGEMOT-NETGRAPH-MIB',
    #'BEGEMOT-MIB2-MIB',
    #'BEGEMOT-HOSTRES-MIB',
    # HOST-RESOURCES-MIB
    # IP-FORWARD-MIB
    #
    # Nothing in these MIBs for my test device:
    #
    #'BEGEMOT-IP-MIB',
    #'BEGEMOT-MIB',
    #'BEGEMOT-BRIDGE-MIB',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::LLDP::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::LLDP::MUNGE,
);

sub vendor {
    return 'FreeBSD';
}

sub model {
    my $pf = shift;
    my $descr   = $pf->description() || '';
    my $model  = undef;
    $model = $1 if ( $descr =~ /FreeBSD\s+(\S+)/ );
    return $model if defined $model;
    return $pf->os_ver();
}

sub os {
    return 'Pf';
}

sub os_ver {
    my $pf = shift;
    my $id = $pf->id();

    my $os_ver = &SNMP::translateObj($id);
    return $id unless defined $os_ver;

    # From /usr/share/snmp/defs/tree.def on a Pf Machine
    # (2 begemotSnmpdDefs
    #   (1 begemotSnmpdAgent
    #     (1 begemotSnmpdAgentFreeBSD OID op_dummy)
    # We're leaving the 1.1 and trimming off up to the 2
    $os_ver =~ s/fokus.1.1.2.//;
    return $os_ver;
}

# Use LLDP
sub hasCDP {
    my $pf = shift;
    return $pf->hasLLDP();
}

sub c_ip {
    my $pf  = shift;
    my $partial = shift;
    return $pf->lldp_ip($partial);
}

sub c_if {
    my $pf  = shift;
    my $partial = shift;
    return $pf->lldp_if($partial);
}

sub c_port {
    my $pf  = shift;
    my $partial = shift;
    return $pf->lldp_port($partial);
}

sub c_id {
    my $pf  = shift;
    my $partial = shift;
    return $pf->lldp_id($partial);
}

sub c_platform {
    my $pf  = shift;
    my $partial = shift;
    return $pf->lldp_rem_sysdesc($partial);
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Pf - SNMP Interface to FreeBSD-Based Firewalls using Pf /Pf Sense

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS


 # Let SNMP::Info determine the correct subclass for you. 
 my $pf = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $pf->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Free-BSD PF-Based devices

=head1 LLDP Support

LLDP Support is included but untested in this Device Class.  It is reported
that the available CDP/LLDP modules for net-snmp don't work on FreeBSD (on
which pfSense is based) as they assume certain Linux specific Ethernet
structures.  This problem is apparently solved on PF based firewall appliances
by using the ladvd package, for which a port may be found here:
L<http://www.freshports.org/net/ladvd/>.  I'm not sure if this module ties into 
Net-SNMP or not.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::LLDP

=back

=head2 Required MIBs

=over

=item F<FOKUS-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::LLDP/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar values from SNMP

=over

=item $pf->vendor()

    Returns 'FreeBSD'

=item $pf->hasCDP()

    Returns whether LLDP is enabled.

=item $pf->model()

Grabs the os version from C<sysDescr>

=item $pf->os()

Returns 'Pf'

=item $pf->os_ver()

Tries to reference $pf->id() to one of the product MIBs listed above.
Will probably return a truncation of the default OID for pf-based systems 
C<enterprises.12325.1.1.2.1.1>.

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $pf->c_id()

Returns LLDP information.

=item $pf->c_if()

Returns LLDP information.

=item $pf->c_ip()

Returns LLDP information.

=item $pf->c_platform()

Returns LLDP information.

=item $pf->c_port()

Returns LLDP information.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"TABLE METHODS"> for details.

=cut
