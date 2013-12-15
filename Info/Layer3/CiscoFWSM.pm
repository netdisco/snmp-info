# SNMP::Info::Layer3::CiscoFWSM
# $Id$
#
# Copyright (c) 2010 Brian De Wolf
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

package SNMP::Info::Layer3::CiscoFWSM;

use strict;
use Exporter;
use SNMP::Info::Layer3::Cisco;

@SNMP::Info::Layer3::CiscoFWSM::ISA = qw/SNMP::Info::Layer3::Cisco
    Exporter/;
@SNMP::Info::Layer3::CiscoFWSM::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.09';

%MIBS = (
    %SNMP::Info::Layer3::Cisco::MIBS,
);

%GLOBALS = (
    %SNMP::Info::Layer3::Cisco::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer3::Cisco::FUNCS,

);

%MUNGE = (
    %SNMP::Info::Layer3::Cisco::MUNGE,
);


# For FWSMs, the ipNetToPhysicalPhysAddress table appears to be of the form:
# $ifindex.$inetaddresstype.$proto.$ip_address -> $mac_address
#
# Using the output of ipNetToPhysicalPhysAddress, we can emulate the other
# functions.
#
# This doesn't really line up to what at_* return, so we munge it

sub at_paddr {
    my ($fwsm)    = shift;
    my ($partial)  = shift;

    my $paddrs = $fwsm->n2p_paddr($partial);
    my $n_paddrs = {};
    
    foreach my $key (keys %$paddrs) {
        my $paddr = $paddrs->{$key};
        my @parts = split /\./, $key;
	my ($ifindex, $addrtype, $proto) = splice @parts, 0, 3;
	my $ip = join ".", @parts;

	next if($proto != 4); # at_paddr doesn't support non-IPv4

        $n_paddrs->{"$ifindex.$ip"} = $paddr;
    }
    return $n_paddrs;
}

sub at_netaddr {
    my ($fwsm)    = shift;
    my ($partial)  = shift;

    my $paddrs = $fwsm->n2p_paddr($partial);

    my $netaddrs = {};
    
    foreach my $key (keys %$paddrs) {
        my $paddr = $paddrs->{$key};
        my @parts = split /\./, $key;
	my ($ifindex, $addrtype, $proto) = splice @parts, 0, 3;
	my $ip = join ".", @parts;

	next if($proto != 4); # at_netaddr doesn't support non-IPv4

        $netaddrs->{"$ifindex.$ip"} = $ip;
    }
    return $netaddrs;
}

sub at_ifaddr {
    my ($fwsm)    = shift;
    my ($partial)  = shift;

    my $paddrs = $fwsm->n2p_paddr($partial);

    my $ifaddrs = {};
    
    foreach my $key (keys %$paddrs) {
        my $paddr = $paddrs->{$key};
        my @parts = split /\./, $key;
	my ($ifindex, $addrtype, $proto) = splice @parts, 0, 3;
	my $ip = join ".", @parts;

	next if($proto != 4); # at_ifaddr doesn't support non-IPv4

        $ifaddrs->{"$ifindex.$ip"} = $ip;
    }
    return $ifaddrs;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::CiscoFWSM - SNMP Interface to Firewall Services Modules for
features not covered elsewhere.

=head1 AUTHOR

Brian De Wolf

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $fwsm = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $fwsm->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Cisco Firewall Services Modules

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3::Cisco

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3::Cisco/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

=head2 Global Methods imported from SNMP::Info::Layer3::Cisco

See documentation in L<SNMP::Info::Layer3::Cisco/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=back

=head2 Overrides

=over

=item $fwsm->at_paddr()

This function derives the at_paddr information from the n2p_paddr() table as
the MIB to provide that information isn't supported on FWSM.

=item $fwsm->at_netaddr()

This function derives the at_netaddr information from the n2p_paddr() table as
the MIB to provide that information isn't supported on FWSM.

=item $fwsm->at_ifaddr()

This function derives the at_ifaddr information from the n2p_paddr() table as
the MIB to provide that information isn't supported on FWSM.

=back

=head2 Table Methods imported from SNMP::Info::Layer3::Cisco

See documentation in L<SNMP::Info::Layer3::Cisco/"TABLE METHODS"> for details.

=cut
