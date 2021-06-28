# SNMP::Info::Layer3::Cumulus
#
# Copyright (c) 2018 Bill Fenner and Oliver Gorwits
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

package SNMP::Info::Layer3::Cumulus;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::IEEE802dot3ad 'agg_ports_lag';

@SNMP::Info::Layer3::Cumulus::ISA = qw/
  SNMP::Info::IEEE802dot3ad
  SNMP::Info::Layer3
  Exporter
/;
@SNMP::Info::Layer3::Cumulus::EXPORT_OK = qw/ agg_ports /;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.73';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::IEEE802dot3ad::MIBS,
    'UCD-SNMP-MIB'       => 'versionTag',
    'NET-SNMP-TC'        => 'netSnmpAliasDomain',
    'HOST-RESOURCES-MIB' => 'hrSystem',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'netsnmp_vers'   => 'versionTag',
    'hrSystemUptime' => 'hrSystemUptime',
    'chassis'    => 'entPhysicalDescr.1',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::IEEE802dot3ad::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::IEEE802dot3ad::MUNGE,
);

sub vendor { return 'cumulus networks' }

sub os { return 'cumulus' }

sub os_ver {
    my $netsnmp = shift;
    my $descr   = $netsnmp->description();

# STRING: "Cumulus Linux version 3.5.1 running on innotek GmbH VirtualBox"
    return $1 if ( defined ($descr) && $descr =~ /^Cumulus Linux.+(\d+\.\d+\.\d+)\s/ );
    return;
}

sub model {
    my $netsnmp = shift;
    my $chassis = $netsnmp->chassis();

# STRING: "Cumulus Networks  VX Chassis"
    if (defined ($chassis)) {
      return $1 if ($chassis =~ /^Cumulus Networks\s+(.+)/);
    }
    return $netsnmp->SUPER::model();
}

# sysUptime gives us the time since the SNMP daemon has restarted,
# so return the system uptime since that's probably what the user
# wants.  (Caution: this could cause trouble if using
# sysUptime-based discontinuity timers or other TimeStamp
# objects.
sub uptime {
    my $netsnmp = shift;
    my $uptime;

    $uptime = $netsnmp->hrSystemUptime();
    return $uptime if defined $uptime;

    return $netsnmp->SUPER::uptime();
}

# ifDescr is the same for all interfaces in a class, but the ifName is
# unique, so let's use that for port name.  If all else fails,
# concatenate ifDesc and ifIndex.
# (code from SNMP/Info/Layer2/Netgear.pm)
sub interfaces {
    my $netsnmp = shift;
    my $partial = shift;

    my $interfaces = $netsnmp->i_index($partial)       || {};
    my $i_descr    = $netsnmp->i_description($partial) || {};
    my $i_name     = $netsnmp->i_name($partial);
    my $i_isset    = ();
    # Replace the description with the ifName field, if set
    foreach my $iid ( keys %$i_name ) {
        my $name = $i_name->{$iid};
        next unless defined $name;
        if (defined $name and $name !~ /^\s*$/) {
            $interfaces->{$iid} = $name;
            $i_isset->{$iid} = 1;
        }
    }
    # Replace the Index with the ifDescr field, appended with index
    # number, to deal with devices with non-unique ifDescr.
    foreach my $iid ( keys %$i_descr ) {
        my $port = $i_descr->{$iid} . '-' . $iid;
        next unless defined $port;
        next if (defined $i_isset->{$iid} and $i_isset->{$iid} == 1);
        $interfaces->{$iid} = $port;
    }

    return $interfaces;
}

sub i_ignore {
    my $l3      = shift;
    my $partial = shift;

    my $interfaces = $l3->interfaces($partial) || {};

    my %i_ignore;
    foreach my $if ( keys %$interfaces ) {

        # vlan1@br0 or peerlink.4094@peerlink
        if ( $interfaces->{$if} =~ /@/i ) {
            $i_ignore{$if}++;
        }
    }
    return \%i_ignore;
}

sub agg_ports { return agg_ports_lag(@_) }

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Cumulus - SNMP Interface to Cumulus Networks Devices

=head1 AUTHORS

Oliver Gorwits - based on Layer3::NetSNMP implementation

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $cumulus = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $cumulus->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Cumulus Networks devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<UCD-SNMP-MIB>

=item F<NET-SNMP-TC>

=item F<HOST-RESOURCES-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

See L<SNMP::Info::IEEE802dot3ad> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $cumulus->vendor()

Returns 'cumulus networks'.

=item $cumulus->os()

Returns 'cumulus'.

=item $cumulus->os_ver()

Returns the software version extracted from C<sysDescr>.

=item $cumulus->uptime()

Returns the system uptime instead of the agent uptime.
NOTE: discontinuity timers and other Time Stamp based objects
are based on agent uptime, so use orig_uptime().

=item $l3->model()

Returns the chassis type.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Globals imported from SNMP::Info::IEEE802dot3ad

See documentation in L<SNMP::Info::IEEE802dot3ad> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $cumulus->interfaces()

Uses the i_name() field.

=item $cumulus->i_ignore()

Ignores interfaces with an "@" in them.

=item C<agg_ports>

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Table Methods imported from SNMP::Info::IEEE802dot3ad

See documentation in L<SNMP::Info::IEEE802dot3ad> for details.

=cut
