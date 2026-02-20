# SNMP::Info::PortAccessEntity
#
# Copyright (c) 2022 Christian Ramseyer
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

package SNMP::Info::PortAccessEntity;

use strict;
use warnings;
use Exporter;
use SNMP::Info;
use Regexp::Common qw /net/;

@SNMP::Info::PortAccessEntity::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::PortAccessEntity::EXPORT_OK = qw//;

our ($VERSION, %MIBS, %FUNCS, %GLOBALS, %MUNGE);

$VERSION = '3.975000';

%MIBS = ( 'IEEE8021-PAE-MIB' => 'dot1xPaeSystemAuthControl' );

%GLOBALS = (
    # dot1xPaeSystem
    'pae_control'  => 'dot1xPaeSystemAuthControl',
);

%FUNCS = (
    # dot1xAuthConfigEntry
    'pae_authconfig_state'         => 'dot1xAuthPaeState', # disconnected|authenticated
    'pae_authconfig_port_status'   => 'dot1xAuthAuthControlledPortStatus', #(un)authorized

    # dot1xAuthSessionStatsTable
    'pae_authsess_user'  => 'dot1xAuthSessionUserName',
);

%MUNGE = ();

# try to figure out whether the method is mac address bypass (mab) or dot1x. At least on Cisco,
# having a MAC address as the "UserName" seems to point at mab.
sub pae_authsess_mab {
    my $this    = shift;

    my $u = $this->pae_authsess_user();

    my $mab = {};
    foreach my $i ( keys %$u ) {
	    if ($u->{$i} =~ /$RE{net}{MAC}{hex}{-sep=>'[-:]'}/ ) {
	        $mab->{$i} = "mab" ;
	    }
    }
    return $mab;
}


1;

__END__

=head1 NAME

SNMP::Info::PortAccessEntity - SNMP Interface to data stored in
F<IEEE8021-PAE-MIB>.

=head1 AUTHOR

Christian Ramseyer

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $pae = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $pae->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

F<IEEE8021-PAE-MIB> is used to describe Port Access Entities, aka NAC/dot1x features.

Create or use a device subclass that inherit this class.  Do not use directly.

For debugging purposes you can call this class directly as you would
SNMP::Info

 my $pae = new SNMP::Info::PortAccessEntity (...);

=head2 Inherited Classes

none.

=head2 Required MIBs

=over

=item F<IEEE8021-PAE-MIB>

=back

=head1 GLOBALS

=over

=item $pae->pae_control()

The administrative enable/disable state for Port Access Control in a System.
Possible values are enabled and disabled.

C<dot1xPaeSystemAuthControl>

=back

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $pae->pae_authconfig_state()

Authentication state: is the port authenticated, disconnected, etc. 

C<dot1xAuthPaeState>

=item $pae->pae_authconfig_port_status()

Controlled Port status parameter for the Port: can only be authorized or unauthorized

C<dot1xAuthAuthControlledPortStatus>

=item $pae->pae_authsess_user()

The User-Name representing the identity of the Supplicant PAE. This can be a pretty
arbitrary string besides an actual username, e.g. a MAC address for MAB or a hostname
for dot1x.

C<dot1xAuthSessionUserName>

=item $pae->pae_authsess_mab()

Helper method, guess if this a mac address bypass port: contains the string "mab" for indexes where the 
pae_authsess_user looks like a MAC address.

=back

=cut
