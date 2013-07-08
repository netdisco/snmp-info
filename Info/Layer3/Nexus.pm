# SNMP::Info::Layer3::Nexus
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

package SNMP::Info::Layer3::Nexus;

use strict;
use Exporter;
use SNMP::Info::LLDP;
use SNMP::Info::CDP;
use SNMP::Info::CiscoImage;
use SNMP::Info::CiscoPortSecurity;
use SNMP::Info::CiscoConfig;
use SNMP::Info::CiscoPower;
use SNMP::Info::Layer3;
use SNMP::Info::CiscoStpExtensions;
use SNMP::Info::CiscoVTP;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

# NOTE : Top-most items gets precedence for @ISA
@SNMP::Info::Layer3::Nexus::ISA = qw/
    SNMP::Info::CiscoVTP 
    SNMP::Info::CiscoStpExtensions
    SNMP::Info::LLDP
    SNMP::Info::CDP 
    SNMP::Info::CiscoImage
    SNMP::Info::CiscoPortSecurity
    SNMP::Info::CiscoConfig
    SNMP::Info::CiscoPower
    SNMP::Info::Layer3
    Exporter
/;

@SNMP::Info::Layer3::Nexus::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.02';

# NOTE: Order creates precedence
#       Example: v_name exists in Bridge.pm and CiscoVTP.pm
#       Bridge is called from Layer3 and CiscoStpExtensions
#       So we want CiscoVTP to come last to get the right one.
# The @ISA order should be reverse of these orders.

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::CiscoPower::MIBS,
    %SNMP::Info::CiscoConfig::MIBS,
    %SNMP::Info::CiscoPortSecurity::MIBS,
    %SNMP::Info::CiscoImage::MIBS,
    %SNMP::Info::CDP::MIBS,
    %SNMP::Info::LLDP::MIBS,
    %SNMP::Info::CiscoStpExtensions::MIBS, 
    %SNMP::Info::CiscoVTP::MIBS,
    'CISCO-ENTITY-VENDORTYPE-OID-MIB' => 'cevMIBObjects',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::CiscoPower::GLOBALS,
    %SNMP::Info::CiscoConfig::GLOBALS,
    %SNMP::Info::CiscoPortSecurity::GLOBALS,
    %SNMP::Info::CiscoImage::GLOBALS,
    %SNMP::Info::CDP::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,
    %SNMP::Info::CiscoStpExtensions::GLOBALS,
    %SNMP::Info::CiscoVTP::GLOBALS,
    'mac' => 'dot1dBaseBridgeAddress',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::CiscoPower::FUNCS,
    %SNMP::Info::CiscoConfig::FUNCS,
    %SNMP::Info::CiscoPortSecurity::FUNCS,
    %SNMP::Info::CiscoImage::FUNCS,
    %SNMP::Info::CDP::FUNCS,
    %SNMP::Info::LLDP::FUNCS,
    %SNMP::Info::CiscoStpExtensions::FUNCS, 
    %SNMP::Info::CiscoVTP::FUNCS,    
);


%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::CiscoPower::MUNGE,
    %SNMP::Info::CiscoConfig::MUNGE,
    %SNMP::Info::CiscoPortSecurity::MUNGE,
    %SNMP::Info::CiscoImage::MUNGE,         
    %SNMP::Info::CDP::MUNGE,
    %SNMP::Info::LLDP::MUNGE,
    %SNMP::Info::CiscoStpExtensions::MUNGE, 
    %SNMP::Info::CiscoVTP::MUNGE,    
);

sub cisco_comm_indexing { return 1; }

sub vendor {
    return 'cisco';
}

sub os {
    return 'nx-os';
}

sub os_ver {
    my $nexus = shift; 
    my $descr = $nexus->description();
    
    return $1 if ( $descr =~ /\),\s+Version\s+(.+?),/ );
    return $descr;
}

sub serial {
    my $nexus = shift;

    my $e_class = $nexus->e_class();

    foreach my $iid ( keys %$e_class ) {
        my $class = $e_class->{$iid} || '';
        if ($class =~ /chassis/) {
	    my $serial = $nexus->e_serial($iid);
	    return $serial->{$iid};
	}
    }    
    return;
}

# sysObjectID returns an IID to an entry in the CISCO-ENTITY-VENDORTYPE-OID-MIB.
# Look it up and return it.
sub model {
    my $nexus = shift;
    my $id    = $nexus->id();

    unless ( defined $id ) {
        print
            " SNMP::Info::Layer3::Nexus::model() - Device does not support sysObjectID\n"
            if $nexus->debug();
        return;
    }

    my $model = &SNMP::translateObj($id);

    return $id unless defined $model;

    $model =~ s/^cevChassis//i;
    return $model;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Nexus - SNMP Interface to Cisco Nexus Switches running
NX-OS

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $nexus = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $nexus->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for Cisco Nexus Switches running NX-OS.  

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

 my $nexus = new SNMP::Info::Layer3::Nexus(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::CiscoVTP

=item SNMP::Info::CDP

=item SNMP::Info::CiscoImage

=item SNMP::Info::CiscoPortSecurity

=item SNMP::Info::CiscoConfig

=item SNMP::Info::CiscoPower

=item SNMP::Info::CiscoStpExtensions

=item SNMP::Info::LLDP

=back

=head2 Required MIBs

=over

=item F<CISCO-ENTITY-VENDORTYPE-OID-MIB>

=back

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoVTP/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CDP/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoImage/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoPortSecurity/"Required MIBs"> for its own MIB
requirements.

See L<SNMP::Info::CiscoConfig/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoPower/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoStpExtensions/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::LLDP/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return a scalar value from SNMP

=over

=item $nexus->vendor()

Returns 'cisco'

=item $nexus->os()

Returns C<'nx-os'>

=item $nexus->os_ver()

Returns operating system version extracted from C<sysDescr>.

=item $nexus->serial()

Returns the serial number of the chassis from F<ENTITY-MIB>.

=item $nexus->model()

Tries to reference $nexus->id() to F<CISCO-ENTITY-VENDORTYPE-OID-MIB>

Removes C<'cevChassis'> for readability.

=item $nexus->mac()

C<dot1dBaseBridgeAddress>

=item $nexus->cisco_comm_indexing()

Returns 1.  Use vlan indexing.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::CiscoVTP

See documentation in L<SNMP::Info::CiscoVTP/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CDP

See documentation in L<SNMP::Info::CDP/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoImage

See documentation in L<SNMP::Info::CiscoImage/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoPortSecurity

See documentation in L<SNMP::Info::CiscoPortSecurity/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoConfig

See documentation in L<SNMP::Info::CiscoConfig/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoPower

See documentation in L<SNMP::Info::CiscoPower/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoStpExtensions

See documentation in L<SNMP::Info::CiscoStpExtensions/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoVTP

See documentation in L<SNMP::Info::CiscoVTP/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CDP

See documentation in L<SNMP::Info::CDP/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoStats

See documentation in L<SNMP::Info::CiscoStats/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoImage

See documentation in L<SNMP::Info::CiscoImage/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoPortSecurity

See documentation in L<SNMP::Info::CiscoPortSecurity/"TABLE METHODS"> for
details.

=head2 Table Methods imported from SNMP::Info::CiscoConfig

See documentation in L<SNMP::Info::CiscoConfig/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoPower

See documentation in L<SNMP::Info::CiscoPower/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoStpExtensions

See documentation in L<SNMP::Info::CiscoStpExtensions/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"TABLE METHODS"> for details.

=cut
