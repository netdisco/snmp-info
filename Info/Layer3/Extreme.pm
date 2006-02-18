# SNMP::Info::Layer3::Extreme - SNMP Interface to Extreme devices
# Eric Miller
#
# Copyright (c) 2005 Eric Miller
#
# Copyright (c) 2002,2003 Regents of the University of California
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

package SNMP::Info::Layer3::Extreme;
# $Id$

use strict;

use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::MAU;

use vars qw/$VERSION $DEBUG %GLOBALS %FUNCS $INIT %MIBS %MUNGE/;

$VERSION = 1.0;

@SNMP::Info::Layer3::Extreme::ISA = qw/SNMP::Info::Layer3 SNMP::Info::MAU Exporter/;
@SNMP::Info::Layer3::Extreme::EXPORT_OK = qw//;

%MIBS = ( %SNMP::Info::Layer3::MIBS,
          %SNMP::Info::MAU::MIBS,
          'EXTREME-BASE-MIB'   => 'extremeAgent',
          'EXTREME-SYSTEM-MIB' => 'extremeSystem',
          'EXTREME-FDB-MIB'    => 'extremeSystem',
        );

%GLOBALS = (
            %SNMP::Info::Layer3::GLOBALS,
            %SNMP::Info::MAU::GLOBALS,
            'serial'     => 'extremeSystemID',
            'temp'       => 'extremeCurrentTemperature',
            'ps1_status' => 'extremePowerSupplyStatus.1',
            'fan'        => 'extremeFanOperational.1',
            'mac'        => 'dot1dBaseBridgeAddress',
           );

%FUNCS   = (
            %SNMP::Info::Layer3::FUNCS,
            %SNMP::Info::MAU::FUNCS,
            # EXTREME-FDB-MIB:extremeFdbMacFdbTable
            'fw_mac'     => 'extremeFdbMacFdbMacAddress',
            'fw_port'    => 'extremeFdbMacFdbPortIfIndex',
            'fw_status'  => 'extremeFdbMacFdbStatus',
           );

%MUNGE = (
            # Inherit all the built in munging
            %SNMP::Info::Layer3::MUNGE,
            %SNMP::Info::MAU::MUNGE,
         );

# Method OverRides

sub bulkwalk_no { 1; }

*SNMP::Info::Layer3::Extreme::i_duplex       = \&SNMP::Info::MAU::mau_i_duplex;
*SNMP::Info::Layer3::Extreme::i_duplex_admin = \&SNMP::Info::MAU::mau_i_duplex_admin;

sub model {
    my $extreme = shift;
    my $id = $extreme->id();
    
    unless (defined $id){
        print " SNMP::Info::Layer3::Extreme::model() - Device does not support sysObjectID\n" if $extreme->debug(); 
        return undef;
    }
    
    my $model = &SNMP::translateObj($id);

    return $id unless defined $model;

    return $model;
}

sub vendor {
    return 'extreme';
}

sub os {
    return 'extreme';
}

sub os_ver {
    my $extreme = shift;
    my $descr = $extreme->description();
    return undef unless defined $descr;

    if ($descr =~ m/Version ([\d.]*)/){
        return $1;
    }

    return undef;
}

# We're not using BRIDGE-MIB
sub bp_index {
    my $extreme = shift;
    my $if_index = $extreme->i_index();

    my %bp_index;
    foreach my $iid (keys %$if_index){
        $bp_index{$iid} = $iid;
    }
    return \%bp_index;
}

# Index values in the Q-BRIDGE-MIB are the same
# as in the BRIDGE-MIB and do not match ifIndex.
sub i_vlan {
    my $extreme = shift;
    my $qb_i_vlan = $extreme->qb_i_vlan();
    my $bp_index = $extreme->bp_index();

    my %i_vlan;
    foreach my $v_index (keys %$qb_i_vlan){
        my $vlan = $qb_i_vlan->{$v_index};
        my $iid  = $bp_index->{$v_index};

        unless (defined $iid) {
            print "  Port $v_index has no bp_index mapping. Skipping\n"
                if $DEBUG;
            next;
        }
        $i_vlan{$iid}=$vlan; 
    }
    return \%i_vlan;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Extreme - Perl5 Interface to Extreme Network Devices

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $extreme = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 1
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $extreme->class();

 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from an 
Extreme device through SNMP. 

For speed or debugging purposes you can call the subclass directly, but not after determining
a more specific class using the method above. 

my $extreme = new SNMP::Info::Layer3::Extreme(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::MAU

=back

=head2 Required MIBs

=over

=item EXTREME-BASE-MIB

=item EXTREME-SYSTEM-MIB

=item EXTREME-FDB-MIB

=item Inherited Classes' MIBs

See classes listed above for their required MIBs.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $extreme->bulkwalk_no

Return C<1>.  Bulkwalk is currently turned off for this class.

=item $extreme->model()

Returns model type.  Checks $extreme->id() against the EXTREME-BASE-MIB.

=item $extreme->vendor()

Returns extreme

=item $extreme->os()

Returns extreme

=item $extreme->serial()

Returns serial number

(B<extremeSystemID>)

=item $extreme->temp()

Returns system temperature

(B<extremeCurrentTemperature>)

=item $extreme->ps1_status()

Returns status of power supply 1

(B<extremePowerSupplyStatus.1>)

=item $extreme->fan()

Returns fan status

(B<extremeFanOperational.1>)

=item $extreme->mac()

Returns base mac

(B<dot1dBaseBridgeAddress>)

=back

=head2 Overrides

=over

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in SNMP::Info::Layer3 for details.

=head2 Globals imported from SNMP::Info::MAU

See documentation in SNMP::Info::MAU for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $extreme->fw_mac()

(B<extremeFdbMacFdbMacAddress>)

=item $extreme->fw_port()

(B<extremeFdbMacFdbPortIfIndex>)

=item $extreme->fw_status()

(B<extremeFdbMacFdbStatus>)

=item $extreme->i_vlan()

Returns a mapping between ifIndex and the VLAN.

=item $stack->bp_index()

Returns reference to hash of bridge port table entries map back to interface identifier (iid)

Returns (B<ifIndex>) for both key and value since we're using EXTREME-FDB-MIB
rather than BRIDGE-MIB.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in SNMP::Info::Layer3 for details.

=head2 Table Methods imported from SNMP::Info::MAU

See documentation in SNMP::Info::MAU for details.

=cut
