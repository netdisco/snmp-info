# SNMP::Info - Max Baker <max@warped.org>
#
# Copyright (c) 2002, Regents of the University of California
# All rights reserved.  
#
# See COPYRIGHT below 

package SNMP::Info;
$VERSION = 0.1;
use strict;

use Exporter;
use SNMP;
use Carp;

@SNMP::Info::ISA = qw/Exporter/;
@SNMP::Info::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD $INIT $DEBUG %SPEED_MAP/;

$DEBUG=0;

=head1 NAME

SNMP::Info - Perl5 Interface to Network devices through SNMP. 

=head1 VERSION

SNMP::Info - Version 0.1

=head1 AUTHOR

Max Baker (C<max@warped.org>)

SNMP::Info was created for the Netdisco application at UCSC

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2002, Regents of the University of California
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.
    * Neither the name of the University of California, Santa Cruz nor the 
      names of its contributors may be used to endorse or promote products 
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 SYNOPSIS

 # Connect with generic Info object
 
 my $info = new SNMP::Info( DestHost  => 'router' , 
                             Community => 'public' );
 
 $name = $info->name();
 
 # Try and find a more specific subclass of SNMP::Info
 my $object_class = $info->device_type();
 
 my $more_specific_device = new $object_class(
                                  'Desthost' => 'mydevice',
                                  'Community' => 'public');
 
 # Find out the Duplex status for the ports
 my $interfaces = $more_specific_device->interfaces();
 my $i_duplex   = $more_specific_device->i_duplex();
 
 foreach my $iid (keys %$interfaces){
 
    my $duplex = $i_duplex->{$iid};
 
    # Print out physical port name, not snmp iid
    my $port  = $interfaces->{$iid};
 
    print "$port : $duplex\n";
 
 }

=head1 REQUIREMENTS

=over

=item 1. Net-SNMP

To use this module, you must have Net-SNMP installed on your system.   

Net-SNMP can be found at http://net-snmp.sourceforge.net .  Version 5.0.2 or 
greater is recommended. 


The Perl module C<SNMP> is found inside the distribution.  Go to the F<perl/> directory
and install it from there, or run C<./configure --with-perl-modules> .

=item 2. MIBS

Each sub-module that you use will also require specific MIBs,
usually obtainable on the net.   See the list above for a quick
glance, and the documentation in each sub module for more information.

Make sure that your snmp.conf is updated to point to your MIB directory
and that the MIBs are world-readable.  

SNMP::Info requires RFC1213-MIB (and whatever supporting MIBs that
are referenced).  

A good starting point are the Version 2 MIBs from Cisco, found at

 ftp://ftp.cisco.com/pub/mibs/v2/v2.tar.gz

Run C<cd /usr/local/share/snmp/mibs && tar xvfz ~/v2.tar.gz > to install them.

Then run C<snmpconf> and setup that directory as default.  Move F<snmp.conf>
into F</usr/local/share/snmp> when you are done.

=back

=head1 DESCRIPTION 

SNMP::Info gives an object oriented interface to information obtained through
SNMP.  

This module is geared towards network devices.  Speciality sub-classes
exist for a number of vendors and products (see below).

=head2 Design Goals

=over

=item 1. Use of MIB variables and values instead of purely numeric OID

All values are retrieved via MIB Leaf node names.   

This means that SNMP::Info only asks SNMP::Session to look for ``sysName'' instead
of 1.3.6.1.2.1.1.5.

It also means that you need to download MIB files for each sub module
that you use.  

The other side effect to using MIBs is data results come back as meaningful
text, instead of integers.

Instead of looking up 1.3.6.1.2.1.2.2.1.3 and getting back C<23>

SNMP::Info will ask for C<RFC1213-MIB::ifType> and will get back C<ppp>. 

=item 2. SNMP::Info is easily extended to new devices

You can create a new sub class for a device by filling in Four hashes 
%GLOBALS, %MIBS, %FUNCS, and %MUNGE with the names of the SNMP attributes
that are specific to your device.   See the bottom of this document
for a sample Sub Class.

When you make a new sub class for a device, please be sure to send it
back to the developers at snmp@warped.org for inclusion in the next version.

=back

=head1 Sub Classes

=over

=item SNMP::Info::Bridge

=item SNMP::Info::CDP

=item SNMP::Info::EtherLike

=item SNMP::Info::MAU

=item SNMP::Info::Layer1

=item SNMP::Info::Layer2 

=item SNMP::Info::Layer3

=item SNMP::Info::Layer1::Allied

=item SNMP::Info::Layer1::Asante

=item SNMP::Info::Layer2::Bay

=item SNMP::Info::Layer2::C1900

=item SNMP::Info::Layer2::C2900

=item SNMP::Info::Layer2::Catalyst

=item SNMP::Info::Layer2::HP

=item SNMP::Info::Layer3::Aironet

=item SNMP::Info::Layer3::Foundry

=back

=head2 Details

=over

=item * SNMP::Info::Bridge - BRIDGE-MIB - RFC1286 Support

Requires BRIDGE-MIB

=item * SNMP::Info::CDP - Cisco Discovery Protocol (CDP) Support. 

Provides Layer 2 Topology Information on Cisco and some HP Devices.

Requires CISCO-CDP-MIB

=item * SNMP::Info::EtherLike

Requires ETHERLIKE-MIB - RFC1398

=item * SNMP::Info::Layer1 - Generic Layer 1 Device Support

Requires Standard V1 and V2 MIBs

=item * SNMP::Info::Layer2 - Generic Layer 2 Device Support

Inherits:

 SNMP::Info::CDP
 SNMP::Info::Bridge

Required MIBs:

 CISCO-PRODUCTS-MIB - Gives model information for Cisco
 HP-ICF-OID         - Gives model information for HPs

=item * SNMP::Info::Layer3 - Generic Layer 3 and Layer 2/3 Device Support

Inherits:

 SNMP::Info::Bridge - For Layer 2/3 devices
 SNMP::Info::CDP
 SNMP::Info::EtherLike

Required MIBs:

 CISCO-PRODUCTS-MIB - Gives model information for Cisco
 HP-ICF-OID         - Gives model information for HPs
 ENTITY-MIB         - Gives some chassis information
 OSPF-MIB           - Gives router information

=item * SNMP::Info::MAU - RFC2668 - Media Access Unit (MAU) MAU-MIB

=item * SNMP::Info::Layer1::Allied - Allied TeleSys Hub Support

Requires ATI-MIB - Allied Devices MIB downloadable from 
http://www.allied-telesyn.com/allied/support/

=item * SNMP::Info::Layer1::Asante - Asante 1012 Hubs

Requires ASANTE-HUB1012-MIB - Download from http://www.mibdepot.com

=item * SNMP::Info::Layer2::Bay - Bay Networks BayStack Switch Support

Required MIBs:

 SYNOPTICS-ROOT-MIB  - Gives model information for Bay
 S5-ETH-MULTISEG-TOPOLOGY-MIB - Gives Layer 2 topology information for Bay

Other supporting MIBs needed, see SNMP::Info::Bay for more info

=item * SNMP::Info::Layer2::C1900 - Cisco 1900 and 1900c Device Support

Requires STAND-ALONE-ETHERNET-SWITCH-MIB (ESSWITCH-MIB)

=item * SNMP::Info::Layer2::C2900 - Cisco 2900 Series Device Support.

Requires CISCO-C2900-MIB

=item * SNMP::Info::Layer2::Catalyst - Cisco Catalyst WSC Series Switch Support

Requires MIBs:

 CISCO-STACK-MIB
 CISCO-VTP-MIB

=item * SNMP::Info::Layer2::HP - HP Procurve Switch Support

Inherits:

 SNMP::Info::MAU

Required MIBs:

 ENTITY-MIB
 RFC1271-MIB
 HP-ICF-OID

=item * SNMP::Info::Layer3::Aironet - Cisco Aironet Wireless Access Points (AP) Support

Required MIBs:

 AWCVX-MIB        - Aironet Specific MIB values
 IEEE802dot11-MIB - IEEE 802.11 Specific MIB (currently draft)

=item * SNMP::Info::Layer3::Foundry - Older Foundry Networks Devices Support

Inherits SNMP::Info::Bridge

Requires FOUNDRY-SN-ROOT-MIB - Foundry specific values. 
See SNMP::Info::Layer3::Foundry for more information.

=back

=head1 METHODS

    These are generic methods from RFC1213.  Some subset of these is 
probably available for any network device that speaks SNMP.

=head2 Constructor

=over

=item new()

Creates a new object and connects via SNMP::Session. 

Arguments given are passed to SNMP::Session and can be used to overide defaults.

=cut
sub new {
    my $class = shift;
    my %args = @_;
    my $new_obj = {};
    bless $new_obj,$class;
    
    $new_obj->{_class} = $class;

    # load references to all the subclass data structures
    {
        no strict 'refs';
        $new_obj->{_init}    = \${$class . '::INIT'};
        $new_obj->{_mibs}    = \%{$class . '::MIBS'};
        $new_obj->{_globals} = \%{$class . '::GLOBALS'};
        $new_obj->{_funcs}   = \%{$class . '::FUNCS'};
        $new_obj->{_munge}   = \%{$class . '::MUNGE'};
    }
    # SNMP version
    $new_obj->{_version} = $args{Version};
    $new_obj->{_community} = $args{Community};

    # Initialize mibs if not done
    my $init_ref = $new_obj->{_init};
    unless ( $$init_ref ) {
        $new_obj->init();
        $$init_ref=1;    
    }

    # These session defaults can be overwritten with @_
    my $sess = new SNMP::Session(
                    #'Version'  => 2,
                    'UseEnums' => 1,
                    %args
                    );
    
    unless (defined $sess){
        # How do i get error messages back from SNMP?
        #print $SNMP::ErrorStr;
        return undef;
    }

    $new_obj->{sess} = $sess;

    my $store = {};
    $new_obj->{store} = $store;

    return $new_obj;
}

=back

=head2 Data is Cached

A call to any of these methods will load the data once, and then
return cached versions of that data.  

Use load_METHOD() to reload from the device 

        $data = $cdp->c_ip();
        ...
        $cdp->load_c_ip();
        $newdata = $cdp->c_ip();

=head2 Scalar Methods

=over

=item $info->device_type()

Returns the SubClass name for this device.  C<SNMP::Info> is returned if no more
specific class is available.

First the device is checked for Layer 3 support and a specific subclass,
then Layer 2 support and subclasses are checked for.

This means that Layer 2 / 3  switches and routers will fall under the
SNMP::Info::Layer3 subclasses.

If the device still can be connected to via SNMP::Info, then 
SNMP::Info is returned.  

Algorithm for SubClass Detection:

        Layer3 Support                     -> SNMP::Info::Layer3
            Foundry                        -> SNMP::Info::Foundry
            Aironet                        -> SNMP::Info::Aironet
        Elsif Layer2 (no Layer3)           -> SNMP::Info::Layer2 
            Catalyst 1900                  -> SNMP::Info::Layer2::C1900
            Catalyst 2900XL (IOS)          -> SNMP::Info::Layer2::C2900
            Catalyst WS-C (2926,5xxx,6xxx) -> SNMP::Info::Layer2::Catalyst
            HP Procurve                    -> SNMP::Info::Layer2::HP
            Bay Networks                   -> SNMP::Info::Layer2::Bay
        Elsif Layer1 Support               -> SNMP::Info::Layer1
            Allied                         -> SNMP::Info::Layer1::Allied
            Asante                         -> SNMP::Info::Layer1::Asante
        Else                               -> SNMP::Info

=cut
sub device_type {
    my $info = shift;

    my $objtype = "SNMP::Info";

    my $layers = $info->layers();
    my $desc   = $info->description();

    # if we dont have sysServices, we dont have anything else either probably.
    return undef unless (defined $layers and length($layers));

    # Layer 3 Supported 
    #   (usually has layer2 as well, so we check for 3 first)
    if ($info->has_layer(3)) {
        $objtype = 'SNMP::Info::Layer3';

        # Device Type Overrides

        return $objtype unless (defined $desc and length($desc));

        $objtype = 'SNMP::Info::Layer3::Foundry' if $desc =~ /foundry/i ;
        $objtype = 'SNMP::Info::Layer3::Aironet' if ($desc =~ /cisco/i and $desc =~ /\D3[45]0\D/) ;

    # Layer 2 Supported
    } elsif ($info->has_layer(2)) {
        $objtype = 'SNMP::Info::Layer2'; 

        return $objtype unless (defined $desc and $desc !~ /^\s*$/);

        # Device Type Overrides
        
        #   Catalyst 1900 series override
        $objtype = 'SNMP::Info::Layer2::C1900' if ($desc =~ /catalyst/i and $desc =~ /\D19\d{2}/);

        #   Catalyst 2900 (IOS) series override
        $objtype = 'SNMP::Info::Layer2::C2900' if ($desc =~ /C2900XL/i );

        #   Catalyst WS-C series override (2926,5xxx,6xxx)
        $objtype = 'SNMP::Info::Layer2::Catalyst' if ($desc =~ /WS-C\d{4}/);

        #   HP ProCurve 
        $objtype = 'SNMP::Info::Layer2::HP' if ($desc =~ /procurve/i); 
    
        #  Bay Switch
        $objtype = 'SNMP::Info::Layer2::Bay' if ($desc =~ /bay/i);
    
    } elsif ($info->has_layer(1)) {
        $objtype = 'SNMP::Info::Layer1';
        #  Allied crap-o-hub
        $objtype = 'SNMP::Info::Layer1::Allied' if ($desc =~ /allied/i);
        $objtype = 'SNMP::Info::Layer1::Asante' if ($desc =~ /asante/i);
    }

    return $objtype; 
}

=item $info->has_layer(3)

Returns non-zero if the device has the supplied layer in the OSI Model

Returns C<undef> if the device doesn't support the layers() call.

=cut
sub has_layer {
    my $self = shift;
    my $check_for = shift;

    my $layers = $self->layers();
    return undef unless defined $layers;
    return undef unless length($layers);
    return substr($layers,8-$check_for, 1);
}

=item $info->uptime()

Uptime in hundreths of seconds since device became available.

(B<sysUpTime>)

=item $info->contact()

(B<sysContact>)

=item $info->name()

(B<sysName>)

=item $info->location() 

(B<sysLocation>)

=item $info->layers()

This returns a binary encoded string where each
digit represents a layer of the OSI model served
by the device.  

    eg: 01000010  means layers 2 (physical) and 7 (Application) 
                  are served.

Note:  This string is 8 digits long.  

(B<sysServices>)

=item $info->ports()

Number of interfaces available on this device.

(B<ifNumber>)

=back

=head2 Table Methods

Each of these methods returns a hash_reference to a hash keyed on the interface index in SNMP.

 Example : $cdp->c_ip() returns 
            { '304' => '123.123.231.12' }

=head3 Interfaces 

=over

=item $info->interfaces()

This methods is overriden in each subclass to provide a 
mapping between the Interface Table Index (iid) and the physical port name.

=item $info->if_ignore()

Returns a reference to a hash where key values that exist are 
interfaces to ignore.

Ignored interfaces are ones that are usually
not Physical ports or Virtual Lans (VLANs) such as the Loopback interface,
or the CPU interface. 

SNMP::Info and it's subclasses tries to provide data on Physical ports.

=cut
sub if_ignore {
    my %nothing;
    return \%nothing;
}

=item $info->i_index()

Defaults to $info->interfaces()

(B<ifIndex>)

=item $info->i_description() 

Returns reference to hash keyed by iid.  Values are the Textual Description
 of the interface (port).  Usually the physical / human-friendly name.

(B<ifDescr>)

=item $info->i_type()

Returns reference to hash keyed by iid. Values are the port type, such
as Vlan, 10baseT, Ethernet, Serial...

(B<ifType>)

=item $info->i_mtu()

Returns reference to hash keyed by iid.  Values are the MTU value for the
port.

(B<ifMtu>)

=item $info->i_speed()

Returns reference to hash keyed by iid.  Values are the speed of the link.

(B<ifSpeed>)

=item $info->i_mac() 

Returns reference to hash keyed by iid.  Values are the MAC address of the 
interface.  Note this is just the MAC of the port, not anything connected to it.

(B<ifPhysAddress>)

=item $info->i_up() 

Returns reference to hash keyed by iid.  Values are the Link Status of the 
interface.  Typical values are 'up' and 'down'.

(B<ifOperStatus>)

=item $info->i_up_admin()

Returns reference to hash keyed by iid.  Values are the administrative 
status of the port.  Typical values are 'enabled' and 'disabled'.

(B<ifAdminStatus>)

=item $info->i_name()

Returns reference to hash keyed by iid.  Values are the Interface Name 
field.  Supported by a smaller subset of devices, this fields is often 
human set.

(B<ifName>)

=item $info->i_alias()

Returns reference to hash keyed by iid.  Values are a differnent version
of the Interface Description or Interface Name.  For certain devices this
is a more human friendly form of i_description() . For others it is a human
set field like i_name().

(B<ifAlias>)

=back

=head3 IP Address Table

Each entry in this table is an IP address in use on this device.  Usually 
this is implemented in Layer3 Devices.

=over

=item $info->ip_index()

Maps the IP Table to the IID

(B<ipAdEntIfIndex>)

=item $info->ip_table()

Maps the Table to the IP address

(B<ipAdEntAddr>)

=item $info->ip_netmask()

Gives netmask setting for IP table entry.

(B<ipAdEntNetMask>)

=item $info->ip_broadcast()

Gives broadcast address for IP table entry.

(B<ipAdEntBcastAddr>)

=back

=head2 Default %MUNGE

 ip     -> &munge_ip 

 mac    -> &munge_mac 

 i_mac  -> &munge_mac 

 layers -> &munge_dec2bin

=cut

=head1 CREATING SUBCLASSES

=head2 Data Structures Used in SNMP::Info and SubClasses

A class inheriting this class must implement these data
structures : 

=over

=item  $INIT

Used to flag if the MIBs have been loaded yet.

=cut
$INIT    = 0;

=item %GLOBALS

Contains a hash in the form ( method_name => SNMP iid name )
These are scalar values such as name,uptime, etc. 

When choosing the name for the methods, be aware that other new
Sub Modules might inherit this one to get it's features.  Try to
choose a prefix for methods that will give it's own name space inside
the SNMP::Info methods.

=cut
%GLOBALS = (
            # from SNMPv2-MIB
            'id'          => 'sysObjectID',
            'description' => 'sysDescr',
            'uptime'      => 'sysUpTime',
            'contact'     => 'sysContact',
            'name'        => 'sysName',
            'location'    => 'sysLocation',
            'layers'      => 'sysServices',
            'ports'       => 'ifNumber',
            );

=item %FUNCS

Contains a hash in the form ( method_name => SNMP iid)
These are table entries, such as the IfIndex

=cut
%FUNCS   = (
            'interfaces'    => 'ifIndex',
            # from SNMPv2-MIB
            'i_index'       => 'ifIndex',
            'i_description' => 'ifDescr',
            'i_type'        => 'ifType',
            'i_mtu'         => 'ifMtu',
            'i_speed'       => 'ifSpeed',
            'i_mac'         => 'ifPhysAddress',
            'i_up'          => 'ifOperStatus',
            'i_up_admin'    => 'ifAdminStatus',
            'i_name'        => 'ifName',
            'i_alias'       => 'ifAlias',
            # IP Address Table
            'ip_index'      => 'ipAdEntIfIndex',
            'ip_table'      => 'ipAdEntAddr',
            'ip_netmask'    => 'ipAdEntNetMask',
            'ip_broadcast'  => 'ipAdEntBcastAddr',
           );

=item %MIBS

A list of each mib needed.  

('MIB-NAME' => 'itemToTestForPresence')

The value for each entry should be a MIB object to check for to make sure 
that the MIB is present and has loaded correctly. 

$info->init() will throw an exception if a MIB does not load. 

=cut
%MIBS    = ('RFC1213-MIB' => 'sysName');

=item %MUNGE

A map between method calls (from %FUNCS or %GLOBALS) and sub routine methods.
The subroutine called will be passed the data as it gets it from SNMP and 
it should return that same data in a more human friendly format. 


=cut
%MUNGE   = ('ip'     => \&munge_ip,
            'mac'    => \&munge_mac,
            'i_mac'  => \&munge_mac,
            'layers' => \&munge_dec2bin,
            'i_speed'=> \&munge_speed
            );

=back

=head2 Sample Sub Class

Let's make a sample Layer 2 Device subclass :

 # SNMP::Info::Layer2::Sample

 package SNMP::Info::Layer2::Sample;

 $VERSION = 0.1;

 use strict;

 use Exporter;
 use SNMP::Info::Layer2;

 @SNMP::Info::Layer2::Sample::ISA = qw/SNMP::Info::Layer2 Exporter/;
 @SNMP::Info::Layer2::Sample::EXPORT_OK = qw//;

 use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD $INIT $DEBUG/;

 %MIBS    = (%SNMP::Info::Layer2::MIBS,
             'SUPER-DOOPER-MIB'  => 'supermibobject'
            );

 %GLOBALS = (%SNMP::Info::Layer2::GLOBALS,
             'name'              => 'supermib_supername',
             'favorite_color'    => 'supermib_fav_color_object',
             'favorite_movie'    => 'supermib_fav_movie_val'
             );

 %FUNCS   = (%SNMP::Info::Layer2::FUNCS,
             # Super Dooper MIB - Super Hero Table
             'super_hero_index'  => 'SuperHeroIfIndex',
             'super_hero_name'   => 'SuperHeroIfName',
             'super_hero_powers' => 'SuperHeroIfPowers'
            );


 %MUNGE   = (%SNMP::Info::Layer2::MUNGE,
             'super_hero_powers' => \&munge_powers
            );

 # OverRide uptime() method from %SNMP::Info::GLOBALS
 sub uptime {
     my $sample = shift;

     my $name   = $sample->name();

     # this is silly but you get the idea
     return '600' if defined $name ; 
 }

 # Create our own munge function
 sub munge_powers {
     my $power = shift;

     # Take the returned obscure value and return something useful.
     return 'Fire' if $power =~ /reallyhot/i;
     return 'Ice'  if $power =~ /reallycold/i;
     
     # Else 
     return $power;
 }

 # Add Copious Documentation here!!!


Be sure and send the debugged version to snmp@warped.org to be 
included in the next version of SNMP::Info.

=head2 Data Munging Callback Subs

=over

=item munge_speed()

Makes human friendly speed ratings using %SPEED_MAP

 %SPEED_MAP = (
                '64000'      => '64 kbps',
                '1500000'    => '1.5 Mbps',
                '1544000'    => 'T1',
                '2000000'    => '2.0 Mbps',
                '2048000'    => '2.048 Mbps',
                '4000000'    => '4.0 Mbps',
                '10000000'   => '10 Mbps',
                '11000000'   => '11 Mbps',
                '20000000'   => '20 Mbps',
                '16000000'   => '16 Mbps',
                '45000000'   => 'DS3',
                '45045000'   => 'DS3',
                '64000000'   => '64 Mbps',
                '100000000'  => '100 Mbps',
                '149760000'  => 'OC-1'
                '155000000'  => 'OC-1'
                '400000000'  => '400 Mbps',
                '622000000'  => 'OC-12',
                '599040000'  => 'OC-12', 
                '1000000000' => '1.0 Gbps',
             );

=cut
%SPEED_MAP = (
                '64000'      => '64 kbps',
                '1500000'    => '1.5 Mbps',
                '1544000'    => 'T1',
                '2000000'    => '2.0 Mbps',
                '2048000'    => '2.048 Mbps',
                '4000000'    => '4.0 Mbps',
                '10000000'   => '10 Mbps',
                '11000000'   => '11 Mbps',
                '20000000'   => '20 Mbps',
                '16000000'   => '16 Mbps',
                '45000000'   => '45 Mbps',
                '45045000'   => 'DS3',
                '64000000'   => '64 Mbps',
                '100000000'  => '100 Mbps',
                '149760000'  => 'OC-1',
                '155000000'  => 'OC-1',
                '400000000'  => '400 Mbps',
                '622000000'  => 'OC-12',
                '599040000'  => 'OC-12', 
                '1000000000' => '1.0 Gbps',
             );

sub munge_speed {
    my $speed = shift;
    return defined $SPEED_MAP{$speed} ? $SPEED_MAP{$speed} : $speed;
}

=item munge_ip() 

Takes a binary IP and makes it dotted ASCII

=cut
sub munge_ip {
    my $ip = shift;
    return join('.',unpack('C4',$ip));
}

=item munge_mac()

Takes an octet stream and returns a colon separated ASCII hex string.

=cut
sub munge_mac {
    my $mac = shift;
    return undef unless defined $mac;
    return undef unless length $mac;
    return join(':',map { sprintf "%02x",$_ } unpack('C*',$mac));
}

=item munge_octet2hex()

Takes a binary octet stream and returns an ASCII hex string

=cut
sub munge_octet2hex {
    my $oct = shift;
    return join('',map {sprintf "%x",$_} unpack('C*',$oct));
}

=item munge_dec2bin()

Takes a binary char and returns its ASCII binary representation

=cut
sub munge_dec2bin {
    my $num = shift;
    return undef unless defined $num;
    #return undef unless length($num);
    $num = unpack("B32",pack("N",$num));

    # return last 8 characters only
    $num =~ s/.*(.{8})$/$1/;
    return $num
}

=item munge_bits

Takes a SNMP2 'BITS' field and returns the ASCII bit string

=cut
sub munge_bits {
    my $bits = shift;
    return undef unless defined $bits;

    return unpack("b*",$bits);
}

=back

=head2 Internaly Used Functions

=over

=item $info->init()

Used internally.  Loads all entries in %MIBS.

=cut
sub init {
    my $self = shift;

    my $ver = $self->{_version};

    if (defined $ver and $ver == 1){
        # do nothing
    }
    &SNMP::initMib;
    
    my $version = $SNMP::VERSION;
    my ($major,$minor,$rev) = split('\.',$version);

    if ($major < 5){
        # Seems to work under 4.2.0
    } elsif ($major == 5 and $minor == 0 and $rev < 2){
        carp("SNMP 5.0.1 seems to be rather buggy. Upgrade.\n");
        # This is a bug in net-snmp 5.0.1 perl module
        # see http://groups.google.com/groups?th=47aed6bf7be6a0f5
        &SNMP::init_snmp("perl");
    }
    
    my $mibs = $self->mibs();
    
    foreach my $mib (keys %$mibs){
        &SNMP::loadModules("$mib");

        unless (defined $SNMP::MIB{$mibs->{$mib}}){
            croak "The $mib did not load. See README for $self->{_class}\n";
        }    
    }

}

=item $info->debug(1)

Turns on debugging info for this class and SNMP

=cut
sub debug {
    my $self = shift;
    my $debug = shift;

    $DEBUG=$debug;
    $SNMP::debugging=$debug;

}

=item $info->class() 

Returns the class name of the object.

=cut
sub class {
    my $self=shift;
    return $self->{_class};
}

=item $info->funcs()  

Returns a reference to the %FUNCS hash.

=cut
sub funcs {
    my $self=shift;
    return $self->{_funcs};
}

=item $info->mibs() 

Returns a reference to the %MIBS hash.

=cut
sub mibs {
    my $self=shift;
    return $self->{_mibs};
}

=item $info->globals()  

Returns a reference to the %GLOBALS hash.

=cut
sub globals {
    my $self=shift;
    return $self->{_globals};

}

=item $info->munge()   

Returns a reference ot the %MUNGE hash.

=cut
sub munge {
    my $self=shift;
    return $self->{_munge};
}

=item $info->session()  

Gets or Sets the SNMP::Session object.

=cut
sub session {
    my $self = shift;
    $self->{sess} = $_[0] if @_;
    return $self->{sess};
}

=back

=head3 Functions for SNMP Scalars (%GLOBALS)

=over

=item $info->_global()

Used internally by AUTOLOAD to load dynmaic methods from %GLOBALS. 

Example: $info->name() calls autoload which calls $info->_global('name').

=cut
sub _global{
    my $self = shift;
    my $attr = shift;
    my $sess = $self->{sess};
    return undef unless defined $sess;
    
    my $globals = $self->globals(); 

    my $oid = $globals->{$attr};

    # Tag on .0 unless the leaf ends in .number
    unless ($oid =~ /\.\d+$/) {
        $oid .= ".0";
    }

    $DEBUG and print "SNMP::Info::_global $attr : $oid\n";
    my $val = $sess->get($oid); 

    # Get the callback hash for data munging
    my $munge = $self->munge();

    # Data Munging
    if (defined $munge->{$attr}){
        my $subref = $munge->{$attr};
        $val = &$subref($val);
    } 

    return $val;
}

=back

=head3 Functions for SNMP Tables (%FUNCS)

=over

=item $info->load_all()

Runs $info->load_METHOD() for each entry in %FUNCS.

Returns { iid => values_hash } where value_hash is in the format:
    { attribute => value }  

=cut
sub load_all {
    my $self = shift;
    my $sess = $self->{sess};
    return undef unless defined $sess;

    my $funcs = $self->funcs();
    
    foreach my $attrib (keys %$funcs) {
      $attrib = "load_$attrib";
      $self->$attrib(); 
    }

    $self->{_all}++;

    return $self->{store} if defined wantarray;
}

=item $info->all()

Runs $info->load_all() once then returns the cached data.  

Use $info->load_all() to reload the data.

=cut
sub all {
    my $self = shift;
    my $sess = $self->{sess};
    return undef unless defined $sess;

    $self->load_all() unless defined $self->{_all};

    return $self->{store};    
}


=item $info->_load_attr()

Used internally by AUTOLOAD to fetch data called from methods listed in %FUNCS.

Called from $info->load_METHOD();

=cut
sub _load_attr {
    my $self = shift;
    my ($attr,$leaf) = @_;

    my $sess = $self->{sess};
    my $store = $self->{store};
    return undef unless defined $sess;

    # Get the callback hash for data munging
    my $munge = $self->munge();

    $DEBUG and print "SNMP::Info::_load_attr $attr : $leaf\n";

    my $var = new SNMP::Varbind([$leaf]);
    while (! $sess->{ErrorNum} ){
        $sess->getnext($var);
        last if $var->[0] ne $leaf;

        my $iid = $var->[1];
        my $val = $var->[2];

        unless (defined $iid){
            $DEBUG and print "SNMP::Info::_load_attr: $attr not here\n";
            next;
        }

        # Data Munging
        #   Checks for an entry in %munge and runs the subroutine
        if (defined $munge->{$attr}){
            my $subref = $munge->{$attr};
            $val = &$subref($val);
        } 

        $store->{$iid}->{$attr}=$val;
    } 

    # mark data as loaded
    $self->{"_${attr}"}++;

}

=item $info->_show_attr()

Used internaly by AUTOLOAD to return data called by methods listed in %FUNCS.

Called like $info->METHOD().

The first time ran, it will call $info->load_METHOD().  
Every time after it will return cached data.

=cut
sub _show_attr {
    my $self = shift;
    my $attr = shift;

    my $store = $self->{store};
    return undef unless (scalar keys %$store);
    
    my %ret_hash;

    foreach my $iid (keys %$store){
        next unless (defined $store->{$iid}->{$attr});
        
        my $val = $store->{$iid}->{$attr};

        $ret_hash{$iid}= $val;
    }
    
    return \%ret_hash;
}

=back

=head2 AUTOLOAD

Each entry in either %FUNCS or %GLOBALS is used by AUTOLOAD() to create dynamic methods.

First Autoload sees if the method name is listed in either of the two hashes.

If the method exists in globals, it runs $info->_global(method).

Next it will check %FUNCS, run $info->_load_attr(method) if needed
and return $info->_show_attr(method).

Override any dynamic method listed in one of these hashes by creating a sub with 
the same name.

Example : 
 Override $info->name() by creating `` sub name {}'' in your Module.

=cut
sub AUTOLOAD {
    my $sub_name = $AUTOLOAD;

    return if $sub_name =~ /DESTROY$/;

    # package is the first part
    (my $package = $sub_name) =~ s/[^:]*$//;
    # Sub name is the last part
    $sub_name =~ s/.*://;   

    my $attr = $sub_name;
    $attr =~ s/^load_//;

    
    # Let's use the %GLOBALS and %FUNCS from the class that 
    #   inherited us.
    no strict 'refs';
    my %funcs = %{$package.'FUNCS'};
    my %globals = %{$package.'GLOBALS'};

    return unless( defined $funcs{$attr} or
                   defined $globals{$attr} );
    
    my $self = shift;


    # First check %GLOBALS and return _scalar(global)
    if (defined $globals{$attr}) {
        return $self->_global( $attr );
    }

    # Next see if we're load_ ing.
    if ($sub_name =~ /^load_/){
        $self->_load_attr( $attr,$funcs{$attr} );
        return $self->_show_attr( $attr ) if defined wantarray;
    
    # Otherwise we must be listed in %FUNCS 
    } else {

        # Load data if not already cached
        $self->_load_attr( $attr, $funcs{$attr} )
            unless defined $self->{"_${attr}"};

        return $self->_show_attr($attr);
    }
}

1;
