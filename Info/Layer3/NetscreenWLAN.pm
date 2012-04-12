package SNMP::Info::Layer3::NetscreenWLAN;

# Copyright (c) 2011 David Baldwin
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

use strict;
use Exporter;
use SNMP::Info::Layer3::Netscreen;
use SNMP::Info::IEEE802dot11;

@SNMP::Info::Layer3::NetscreenWLAN::ISA
    = qw/SNMP::Info::Layer3::Netscreen SNMP::Info::IEEE802dot11 Exporter/;
@SNMP::Info::Layer3::NetscreenWLAN::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE/;

$VERSION = '2.06';

%MIBS = (
    %SNMP::Info::Layer3::Netscreen::MIBS,
    %SNMP::Info::IEEE802dot11::MIBS,
);

%GLOBALS = ( %SNMP::Info::Layer3::Netscreen::GLOBALS, %SNMP::Info::IEEE802dot11::GLOBALS,  );

%FUNCS = ( %SNMP::Info::Layer3::Netscreen::FUNCS, %SNMP::Info::IEEE802dot11::FUNCS, );

%MUNGE = ( %SNMP::Info::Layer3::Netscreen::MUNGE, %SNMP::Info::IEEE802dot11::MUNGE, );

# need to remap from IF-MIB index to nsIf index
sub i_ssidlist {
    my $netscreen = shift;
    my $i_ssidlist = $netscreen->SUPER::i_ssidlist;
    my $ns_i_map = $netscreen->if_nsif_map;
    my %i_ssidlist;

    foreach my $iid (keys %$i_ssidlist) {
        $i_ssidlist{$ns_i_map->{$iid}} = $i_ssidlist->{$iid};
    }

    return \%i_ssidlist;
}

sub i_80211channel {
    my $netscreen = shift;
    my $i_80211channel = $netscreen->SUPER::i_80211channel;
    my $ns_i_map = $netscreen->if_nsif_map;
    my %i_80211channel;

    foreach my $iid (keys %$i_80211channel) {
        $i_80211channel{$ns_i_map->{$iid}} = $i_80211channel->{$iid};
    }

    return \%i_80211channel;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::NetscreenWLAN - Netscreen Devices with Wireless support

=head1 AUTHOR

David Baldwin

=head1 SYNOPSIS

    #Let SNMP::Info determine the correct subclass for you.

    my $netscreen = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 

    or die "Can't connect to DestHost.\n";

    my $class = $netscreen->class();
    print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a 
Netscreen device with wireless capability through SNMP. See inherited classes' documentation for 
inherited methods.

Allows access to SNMP::Info::IEEE802dot11 and 
SNMP::Info::Layer3::Netscreen methods. No additional functionality.

my $netscreen = new SNMP::Info::Layer3::NetscreenWLAN(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3::Netscreen

=item SNMP::Info::IEEE802dot11

=back

=head2 Required MIBs

=over

=item Inherited Classes

See inherited classes.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=head2 Overrides

=over

None

=back

=head2 Globals imported from SNMP::Info::Layer3::Netscreen

See L<SNMP::Info::Layer3::Netscreen/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::IEEE802dot11

See L<SNMP::Info::IEEE802dot11/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3::Netscreen

See L<SNMP::Info::Layer3::Netscreen/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::IEEE802dot11

See L<SNMP::Info::IEEE802dot11/"TABLE METHODS"> for details.

=cut
