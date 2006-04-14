# SNMP::Info::Layer2::Baystack
# Eric Miller
# $Id$
#
# Copyright (c) 2004-6 Max Baker changes from version 0.8 and beyond.
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

package SNMP::Info::Layer2::Baystack;
$VERSION = '1.03';
use strict;

use Exporter;
use SNMP::Info;
use SNMP::Info::Bridge;
use SNMP::Info::SONMP;
use SNMP::Info::RapidCity;
use SNMP::Info::NortelStack;

@SNMP::Info::Layer2::Baystack::ISA = qw/SNMP::Info SNMP::Info::Bridge SNMP::Info::SONMP SNMP::Info::RapidCity SNMP::Info::NortelStack Exporter/;
@SNMP::Info::Layer2::Baystack::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD $INIT $DEBUG/;

%MIBS    = (
            %SNMP::Info::MIBS,
            %SNMP::Info::Bridge::MIBS,
            %SNMP::Info::SONMP::MIBS,
            %SNMP::Info::RapidCity::MIBS,
            %SNMP::Info::NortelStack::MIBS,
           );

%GLOBALS = ( 
            %SNMP::Info::GLOBALS,
            %SNMP::Info::Bridge::GLOBALS,
            %SNMP::Info::SONMP::GLOBALS,
            %SNMP::Info::RapidCity::GLOBALS,
            %SNMP::Info::NortelStack::GLOBALS,
           );

%FUNCS   = (
            %SNMP::Info::FUNCS,
            %SNMP::Info::Bridge::FUNCS,
            %SNMP::Info::SONMP::FUNCS,
            %SNMP::Info::RapidCity::FUNCS,
            %SNMP::Info::NortelStack::FUNCS,
            'i_name2'    => 'ifName',
            'i_mac2'      => 'ifPhysAddress',
            # From RFC1213-MIB
            'at_index'    => 'ipNetToMediaIfIndex',
            'at_paddr'    => 'ipNetToMediaPhysAddress',
            'at_netaddr'  => 'ipNetToMediaNetAddress',
            );

# 450's report full duplex as speed = 20mbps?!
$SNMP::Info::SPEED_MAP{20_000_000} = '10 Mbps';
$SNMP::Info::SPEED_MAP{200_000_000} = '100 Mbps';
$SNMP::Info::SPEED_MAP{2_000_000_000} = '1.0 Gbps';

%MUNGE   = (
            %SNMP::Info::MUNGE,
            %SNMP::Info::Bridge::MUNGE,
            %SNMP::Info::SONMP::MUNGE,
            %SNMP::Info::RapidCity::MUNGE,
            %SNMP::Info::NortelStack::MUNGE,
            'i_mac2' => \&SNMP::Info::munge_mac,
            'at_paddr' => \&SNMP::Info::munge_mac,
            );

sub os {
    my $baystack = shift;
    my $descr = $baystack->description();
    my $model = $baystack->model();

    if ((defined $model and $model =~ /(470|460|BPS|5510|5520|5530)/) and (defined $descr and $descr =~ m/SW:v[3-5]/i)) {
       return 'boss';
    }
    return 'baystack';
}

sub os_bin {
    my $baystack = shift;
    my $descr = $baystack->description();
    return undef unless defined $descr;

    # 303 / 304
    if ($descr =~ m/Rev: \d+\.(\d+\.\d+\.\d+)-\d+\.\d+\.\d+\.\d+/){
        return $1;
    }

    # 450
    if ($descr =~ m/FW:V(\d+\.\d+)/){
        return $1;
    }

    if ($descr =~ m/FW:(\d+\.\d+\.\d+\.\d+)/i){
        return $1;
    }
    return undef;
}

sub vendor {
    return 'nortel';
}

sub model {
    my $baystack = shift;
    my $id = $baystack->id();
    return undef unless defined $id;
    my $model = &SNMP::translateObj($id);
    return $id unless defined $model;

    my $descr = $baystack->description();

    return '303' if (defined $descr and $descr =~ /\D303\D/);
    return '304' if (defined $descr and $descr =~ /\D304\D/);
    return 'BPS' if ($model =~ /BPS2000/i);
    return $2 if ($model =~ /(ES|ERS|BayStack|EthernetRoutingSwitch|EthernetSwitch)(\d+)/);
    
    return $model;
}

sub i_ignore {
    my $baystack = shift;
    my $i_type = $baystack->i_type();

    my %i_ignore;
    foreach my $if (keys %$i_type){
        my $type = $i_type->{$if};
        next unless defined $type;
        $i_ignore{$if}++ if $type =~ /(54|loopback|propvirtual|cpu)/i;
    }
    return \%i_ignore;
}

sub interfaces {
    my $baystack = shift;
    my $i_index = $baystack->i_index();
    my $index_factor = $baystack->index_factor();
    my $slot_offset = $baystack->slot_offset();
    
    my %if;
    foreach my $iid (keys %$i_index){
        my $index = $i_index->{$iid};
        next unless defined $index;
        # Ignore cascade ports
        next if $index > 513;

        my $port = ($index % $index_factor);
        my $slot = (int($index / $index_factor)) + $slot_offset;

        my $slotport = "$slot.$port";
        $if{$iid} = $slotport;
    }
    return \%if;
}

sub i_mac { 
    my $baystack = shift;
    my $i_mac = $baystack->i_mac2();

    my %i_mac;
    # Baystack 303's with a hw rev < 2.11.4.5 report the mac as all zeros
    foreach my $iid (keys %$i_mac){
        my $mac = $i_mac->{$iid};
        next unless defined $mac;
        next if $mac eq '00:00:00:00:00:00';
        $i_mac{$iid}=$mac;
    }
    return \%i_mac;
}

sub i_name {
    my $baystack = shift;
    my $i_index = $baystack->i_index();
    my $i_alias = $baystack->i_alias();
    my $i_name2  = $baystack->i_name2();

    my %i_name;
    foreach my $iid (keys %$i_name2){
        my $name = $i_name2->{$iid};
        my $alias = $i_alias->{$iid};
        $i_name{$iid} = (defined $alias and $alias !~ /^\s*$/) ?
                        $alias : 
                        $name;
    }

    return \%i_name;
}

sub index_factor {
    my $baystack   = shift;
    my $model   = $baystack->model();
    my $os      = $baystack->os();
    my $op_mode = $baystack->ns_op_mode();
    
    $op_mode = 'pure' unless defined $op_mode;

    my $index_factor = 32;
    $index_factor = 64 if ((defined $model and $model =~ /(470)/) or ($os eq 'boss') and ($op_mode eq 'pure'));
    
    return $index_factor;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::Baystack - SNMP Interface to Nortel Ethernet (Baystack) Switches

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $baystack = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
  or die "Can't connect to DestHost.\n";

 my $class = $baystack->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a Nortel 
Ethernet Switch (Baystack) through SNMP. 

For speed or debugging purposes you can call the subclass directly, but not after determining
a more specific class using the method above. 

my $baystack = new SNMP::Info::Layer2::Baystack(...);

=head2 Inherited Classes

=over

=item SNMP::Info

=item SNMP::Info::Bridge

=item SNMP::Info::NortelStack

=item SNMP::Info::SONMP

=item SNMP::Info::RapidCity

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See SNMP::Info for its own MIB requirements.

See SNMP::Info::Bridge for its own MIB requirements.

See SNMP::Info::NortelStack for its own MIB requirements.

See SNMP::Info::SONMP for its own MIB requirements.

See SNMP::Info::RapidCity for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $baystack->vendor()

Returns 'nortel'

=item $baystack->model()

Cross references $baystack->id() to the SYNOPTICS-MIB and returns
the results.  303s and 304s have the same ID, so we have a hack
to return depending on which it is.

Returns BPS for Business Policy Switch

For BayStack, EthernetRoutingSwitch, or EthernetSwitch extracts and returns
the switch numeric designation.

=item $baystack->os()

Returns 'baystack' or 'boss' depending on software version.

=item $baystack->os_bin()

Returns the firmware version extracted from B<sysDescr>.

=back

=head2 Overrides

=over

=item  $baystack->index_factor()

Required by SNMP::Info::SONMP.  Number representing the number of ports
reserved per slot within the device MIB.

Index factor on the Baystack switches are determined by the formula: Index
Factor = 64 if (model = 470 or (os eq 'boss' and operating in pure mode))
or else Index factor = 32.

Returns either 32 or 64 based upon the formula.

=back

=head2 Globals imported from SNMP::Info

See documentation in SNMP::Info for details.

=head2 Globals imported from SNMP::Info::Bridge

See documentation in SNMP::Info::Bridge for details.

=head2 Globals imported from SNMP::Info::NortelStack

See documentation in SNMP::Info::NortelStack for details.

=head2 Global Methods imported from SNMP::Info::SONMP

See documentation in SNMP::Info::SONMP for details.

=head2 Global Methods imported from SNMP::Info::RapidCity

See documentation in SNMP::Info::RapidCity for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $baystack->interfaces()

Returns reference to the map between IID and physical Port.

  Slot and port numbers on the Baystack switches are determined by the formula:
  
  port = (Interface index % Index factor)
  slot = (int(Interface index / Index factor)) + Slot offset
 
  The physical port name is returned as slot.port.

=item $baystack->i_ignore()

Returns reference to hash of IIDs to ignore.

=item $baystack->i_mac()

Returns the B<ifPhysAddress> table entries. 

Removes all entries matching '00:00:00:00:00:00' -- Certain 
revisions of Baystack firmware report all zeros for each port mac.

=item $baystack->i_name()

Crosses ifName with ifAlias and returns the human set port name if exists.

=back

=head2 RFC1213 Arp Cache Table (B<ipNetToMediaTable>)

=over

=item $baystack->at_index()

Returns reference to hash.  Maps ARP table entries to Interface IIDs 

(B<ipNetToMediaIfIndex>)

=item $baystack->at_paddr()

Returns reference to hash.  Maps ARP table entries to MAC addresses. 

(B<ipNetToMediaPhysAddress>)

=item $baystack->at_netaddr()

Returns reference to hash.  Maps ARP table entries to IPs 

(B<ipNetToMediaNetAddress>)

=back

=head2 Table Methods imported from SNMP::Info

See documentation in SNMP::Info for details.

=head2 Table Methods imported from SNMP::Info::Bridge

See documentation in SNMP::Info::Bridge for details.

=head2 Table Methods imported from SNMP::Info::NortelStack

See documentation in SNMP::Info::NortelStack for details.

=head2 Table Methods imported from SNMP::Info::SONMP

See documentation in SNMP::Info::SONMP for details.

=head2 Table Methods imported from SNMP::Info::RapidCity

See documentation in SNMP::Info::RapidCity for details.

=cut
