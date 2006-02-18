# SNMP::Info::Layer2::Aruba
# Eric Miller
# $Id$
#
# Copyright (c) 2005 Eric Miller
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

package SNMP::Info::Layer2::Aruba;
$VERSION = 1.0;
use strict;

use Exporter;
use SNMP::Info;
use SNMP::Info::Bridge;

@SNMP::Info::Layer2::Aruba::ISA = qw/SNMP::Info SNMP::Info::Bridge Exporter/;
@SNMP::Info::Layer2::Aruba::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD $INIT $DEBUG/;

%MIBS    = (
            %SNMP::Info::MIBS,
            %SNMP::Info::Bridge::MIBS,            
            'WLSX-SWITCH-MIB'  => 'wlsxHostname',
            );

%GLOBALS = (
            %SNMP::Info::GLOBALS,
            %SNMP::Info::Bridge::GLOBALS,
            );

%FUNCS   = (
            %SNMP::Info::FUNCS,
            %SNMP::Info::Bridge::FUNCS,
            'i_index2'            => 'ifIndex',
            'i_name2'             => 'ifName',
            # WLSX-SWITCH-MIB::wlsxSwitchAccessPointTable
            # Table index leafs do not return information
            # therefore unable to use apESSID.  We extract
            # the information from the IID instead.
            #'aruba_ap_essid'      => 'apESSID',
            'aruba_ap_name'       => 'apLocation',
            'aruba_ap_ip'         => 'apIpAddress',
            # WLSX-SWITCH-MIB::wlsxSwitchStationMgmtTable
            # Table index leafs do not return information
            # therefore unable to use staAccessPointBSSID
            # or staPhyAddress.  We extract the information from
            # the IID instead.
            #'fw_port'             => 'staAccessPointBSSID',
            #'fw_mac'              => 'staPhyAddress',
            'fw_user'             => 'staUserName',
            );

%MUNGE   = (
          %SNMP::Info::MUNGE,
          %SNMP::Info::Bridge::MUNGE,
            );

sub layers {
    return '00000011';
}

sub os {
    return 'airos';
}

sub vendor {
    return 'aruba';
}

sub os_ver {
    my $aruba = shift;
    my $descr = $aruba->description();
    return undef unless defined $descr;

    if ($descr =~ m/Version\s+(\d+\.\d+\.\d+\.\d+)/){
        return $1;
    }

    return undef;
}

sub model {
    my $aruba = shift;
    my $id = $aruba->id();
    return undef unless defined $id;
    my $model = &SNMP::translateObj($id);
    return $id unless defined $model;

    return $model;
}

# Thin APs do not support ifMIB requirement

sub i_index {
    my $aruba = shift;
    my $i_index   = $aruba->i_index2();
    my $ap_index  = $aruba->aruba_ap_name();
    
    my %if_index;
    foreach my $iid (keys %$i_index){
        my $index = $i_index->{$iid};
        next unless defined $index;

        $if_index{$iid} = $index;
    }

    # Get Attached APs as Interfaces
    foreach my $ap_id (keys %$ap_index){
        # Convert the 0.254.123.456 index entry to a MAC address.
        my $mac = join(':',map {sprintf("%02x",$_)} split(/\./,$ap_id));

        $if_index{$ap_id} = $mac;
    }
    return \%if_index;
}

sub interfaces {
    my $aruba  = shift;
    my $i_index    = $aruba->i_index();
    my $i_descr    = $aruba->i_description();

    my %if;
    foreach my $iid (keys %$i_index){
        my $index = $i_index->{$iid};
        next unless defined $index;

        if ($index =~ /^\d+$/ ) {
        # Replace the Index with the ifDescr field.
          my $port = $i_descr->{$iid};
          next unless defined $port;
          $if{$iid} = $port;
        }

        elsif ($index =~ /(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/) {
          $if{$index} = $index;
        }           

        else {
            next;
        }
    }
    return \%if;
}

sub i_name {
    my $aruba  = shift;
    my $i_index    = $aruba->i_index();
    my $i_name2    = $aruba->i_name2();
    my $ap_name    = $aruba->aruba_ap_name();
    
    my %i_name;
    foreach my $iid (keys %$i_index){
        my $index = $i_index->{$iid};
        next unless defined $index;

        if ($index =~ /^\d+$/ ) {
          my $name = $i_name2->{$iid};
          next unless defined $name;
          $i_name{$index} = $name;
        }

        elsif ($index =~ /(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/) {
          my $name = $ap_name->{$iid};
          next unless defined $name;
          $i_name{$index} = $name;
        }           
        else {
            next;
        }
    }
  return \%i_name;
}
  
# Wireless switches do not support the standard Bridge MIB
sub bp_index {
    my $aruba = shift;
    my $i_index   = $aruba->i_index2();
    my $ap_index  = $aruba->aruba_ap_name();
    
    my %bp_index;
    foreach my $iid (keys %$i_index){
        my $index = $i_index->{$iid};
        next unless defined $index;

        $bp_index{$iid} = $index;
    }

    # Get Attached APs as Interfaces
    foreach my $ap_id (keys %$ap_index){
        # Convert the 0.254.123.456 index entry to a MAC address.
        my $mac = join(':',map {sprintf("%02x",$_)} split(/\./,$ap_id));

        $bp_index{$mac} = $mac;
    }
    return \%bp_index;
}

sub fw_port {
    my $aruba = shift;
    my $fw_idx = $aruba->fw_user();

    my %fw_port;
    foreach my $iid (keys %$fw_idx){
      if ($iid =~ /(\d+\.\d+\.\d+\.\d+\.\d+\.\d+).(\d+\.\d+\.\d+\.\d+\.\d+\.\d+)/) {
        my $port = join(':',map {sprintf("%02x",$_)} split(/\./,$2));
        $fw_port{$iid} = $port;
      }
      else {
        next;
      }
    }
    return \%fw_port;
}

sub fw_mac {
    my $aruba = shift;
    my $fw_idx = $aruba->fw_user();

    my %fw_mac;
    foreach my $iid (keys %$fw_idx){
      if ($iid =~ /(\d+\.\d+\.\d+\.\d+\.\d+\.\d+).(\d+\.\d+\.\d+\.\d+\.\d+\.\d+)/) {
        my $mac = join(':',map {sprintf("%02x",$_)} split(/\./,$1));
        $fw_mac{$iid} = $mac;
      }
      else {
        next;
      }
    }
    return \%fw_mac;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer2::Aruba - SNMP Interface to Aruba wireless switches

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

    my $aruba = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 

    or die "Can't connect to DestHost.\n";

    my $class = $aruba->class();
    print " Using device sub class : $class\n";

=head1 DESCRIPTION

SNMP::Info::Layer2::Aruba is a subclass of SNMP::Info that provides an interface
to Aruba wireless switches.  The Aruba platform utilizes intelligent wireless
switches which control thin access points.  The thin access points themselves
are unable to be polled for end station information.

This class emulates bridge functionality for the wireless switch. This enables
end station MAC addresses collection and correlation to the thin access point
the end station is using for communication.

For speed or debugging purposes you can call the subclass directly, but not after
determining a more specific class using the method above. 

 my $aruba = new SNMP::Info::Layer2::Aruba(...);

=head2 Inherited Classes

=over

=item SNMP::Info

=item SNMP::Info::Bridge

=back

=head2 Required MIBs

=over

=item WLSX-SWITCH-MIB

=item Inherited Classes' MIBs

See SNMP::Info for its own MIB requirements.

See SNMP::Info::Bridge for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $aruba->model()

Returns model type.  Cross references $aruba->id() with product IDs in the 
Aruba MIB.

=item $aruba->vendor()

Returns 'aruba'

=item $aruba->os()

Returns 'airos'

=item $aruba->os_ver()

Returns the software version extracted from B<sysDescr>

=back

=head2 Overrides

=over

=item $aruba->layers()

Returns 00000011.  Class emulates Layer 2 functionality for Thin APs through
proprietary MIBs.

=back

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $aruba->i_index()

Returns reference to map of IIDs to Interface index. 

Extends ifIndex to support thin APs as device interfaces.

=item $aruba->interfaces()

Returns reference to map of IIDs to ports.  Thin APs are implemented as device 
interfaces.  The thin AP MAC address is used as the port identifier.

=item $aruba->i_name()

Interface name.  Returns (B<ifName>) for Ethernet interfaces and (B<apLocation>)
for thin AP interfaces.

=item $aruba->bp_index()

Simulates bridge MIB by returning reference to a hash containing the index for
both the keys and values.

=item $aruba->fw_port()

(B<staAccessPointBSSID>) as extracted from the IID.

=item $aruba->fw_mac()

(B<staPhyAddress>) as extracted from the IID.

=back

=head2 Aruba Switch AP Table  (B<wlsxSwitchAccessPointTable>)

=over

=item $aruba->aruba_ap_name()

(B<apLocation>)

=item $aruba->aruba_ap_ip()

(B<apIpAddress>)

=back

=head2 Aruba Switch Station Management Table (B<wlsxSwitchStationMgmtTable>)

=over

=item $aruba->fw_user()

(B<staUserName>)

=cut
