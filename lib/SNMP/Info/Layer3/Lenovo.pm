# SNMP::Info::Layer3::Lenovo
#
# Copyright (c) 2019 nick nauwelaerts
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

# TODO
# fallback to super::i_speed needed?
# lag members (no ez way to map master<->slaves)
# psu & fan info should be possible
# spanning tree info is avail too
# modules list could use more work

package SNMP::Info::Layer3::Lenovo;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::IEEE802dot3ad;

@SNMP::Info::Layer3::Lenovo::ISA = qw/
    SNMP::Info::Layer3
    SNMP::Info::IEEE802dot3ad
    Exporter
/;
@SNMP::Info::Layer3::Lenovo::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.73';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::IEEE802dot3ad::MIBS,
    'LENOVO-ENV-MIB'      => 'lenovoEnvMibPowerSupplyIndex',
    'LENOVO-PRODUCTS-MIB' => 'tor',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    # no way to get os version and other device details
    # ENTITY-MIB however can help out
    'os_ver'  => 'entPhysicalSoftwareRev.1',
    'mac'     => 'dot1dBaseBridgeAddress',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::IEEE802dot3ad::FUNCS,
    # perhaps we should honor what the device returns, but it's just
    # the opposite of what most other's do, so overwrite
    'i_name'        => 'ifDescr',
    'i_description' => 'ifName',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::IEEE802dot3ad::MUNGE,
);

# lenovo does not set ifSpeed to 4294967295 for highspeed links, instead
# it substracts 4294967296 from the value until the remainder fits, so
# 10gbit interfaces are presented as:
# 10000000000 - 4294967296 - 4294967296 = 1410065408
# so just always return if_speed_high
#
# forcing the use of ifhighspeed would be preferred but not possible atm
# so copy both functions from Info.pm & overwrite

# is there any way to just overwrite the whole function?
# (overwrite i_speed with i_speed_high). would be more elegant.
sub i_speed {
    my $cnos    = shift;
    my $partial = shift;

    return $cnos->orig_i_speed_high($partial);
}

# also need to overwrite i_speed_raw, netdisco uses this in some
# instances
sub i_speed_raw {
    my $info    = shift;
    my $partial = shift;

    # remove the speed formating
    my $munge_i_speed = delete $info->{munge}{i_speed};
    # also for highspeed interfaces e.g. TenGigabitEthernet
    my $munge_i_speed_high = delete $info->{munge}{i_speed_high};

    my $i_speed_raw = $info->orig_i_speed($partial);
#    my $i_speed_high = undef;

    # just overwrite if interface speed is over 2.5gbps
    foreach my $i ( keys %$i_speed_raw ) {
      my $i_speed_high = undef;

      $i_speed_high = $info->i_speed_high($partial);
      if (defined($i_speed_high) and ($i_speed_high->{$i} > 2500)) {
        $i_speed_raw->{$i} = ( $i_speed_high->{$i} * 1_000_000 );
      }
    }

    # restore the speed formating
    $info->{munge}{i_speed} = $munge_i_speed;
    $info->{munge}{i_speed_high} = $munge_i_speed_high;

    return $i_speed_raw;
}

sub vendor {
    return 'lenovo';
}

sub os {
    return 'cnos';
}

# work in progress, there seems to be no standardized way to map
# lag members to the master.
sub agg_ports_cnos {
  my $dev = shift;

  # TODO: implement partial
  my $ports  = $dev->ad_lag_ports();
  my $index  = $dev->bp_index() || {};

  return {} unless ref {} eq ref $ports and scalar keys %$ports;

  my $ret = {};
  foreach my $m ( keys %$ports ) {
print "m $m\n";
    my $idx = $m;
    my $portlist = $ports->{$m};
printf "p %d\n", scalar(@$portlist);

    next unless $portlist;

    # While dot3adAggTable is indexed by ifIndex, the portlist is indexed
    # with a dot1dBasePort, so we need to use dot1dBasePortIfIndex to map to
    # the ifIndex. If we don't have dot1dBasePortIfIndex assume
    # dot1dBasePort = ifIndex
    for ( my $i = 0; $i <= scalar(@$portlist); $i++ ) {
      my $ifindex = $i+1;
      if ( exists($index->{$i+1}) and defined($index->{$i+1}) ) {
        $ifindex = $index->{$i+1};
print "ifi $ifindex\n";
      }
      $ret->{$ifindex} = $idx if ( @$portlist[$i] );
    }
  }

  return $ret;
}

#sub agg_ports { return agg_ports_cnos(@_) }

1;

__END__

=head1 NAME

SNMP::Info::Layer3::Lenovo - SNMP Interface to Lenovo switches running CNOS.

=head1 AUTHORS

Nick Nauwelaerts

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 use SNMP::Info;
 my $cnos = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";
 my $class = $cnos->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Lenovo switches running CNOS.

=head2 Inherited Classes

=over

=item SNMP::Info::IEEE802dot3ad

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<LENOVO-ENV-MIB>

=item F<LENOVO-PRODUCTS-MIB>

=back

=head2 Inherited Classes' MIBs

See L<SNMP::Info::IEEE802dot3ad> for its own MIB requirements.

See L<SNMP::Info::Layer3> for its own MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP.

=over

=item $cnos->mac()

Returns base mac based on C<dot1dBaseBridgeAddress>.

=item $cnos->os_ver()

Returns the OS version extracted from C<entPhysicalSoftwareRev.1>.

=back

=head2 Overrides

=over

=item $cnos->vendor()

Returns 'lenovo'.

=item $cnos->os()

Returns 'cnos'.

=back

=head2 Globals imported from SNMP::Info::IEEE802dot3ad

See documentation in L<SNMP::Info::IEEE802dot3ad> for details.

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $cnos->agg_ports_cnos()

placeholder function, will return agg_ports mapping once implemented.

=back

=head2 Overrides

=over

=item $cnos->i_description()

Uses C<ifName> to match most other devices.

=item $cnos->i_name()

Uses C<ifDescr> to match most other devices.

=item $cnos->i_speed()

CNOS does not set C<ifSpeed> to 4294967295 for high speed links, return
C<orig_if_speed_high()> instead. SNMP::Info will handle this correctly.

=item $cnos->i_speed_raw()

If C<ifSpeedHigh> > 2500 we overwrite C<i_speed_raw()>, using the
formula: C<ifSpeedHigh> * 1_000_000.

=back

=head2 Table Methods imported from SNMP::Info::IEEE802dot3ad

See documentation in L<SNMP::Info::IEEE802dot3ad> for details.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=cut
