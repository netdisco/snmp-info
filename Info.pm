# SNMP::Info
#
# Copyright (c) 2003-2012 Max Baker and SNMP::Info Developers
# All rights reserved.
#
# Portions Copyright (c) 2002-2003, Regents of the University of California
# All rights reserved.
#
# See COPYRIGHT at bottom

package SNMP::Info;

use warnings;
use strict;
use Exporter;
use SNMP;
use Carp;
use Math::BigInt;

@SNMP::Info::ISA       = qw/Exporter/;
@SNMP::Info::EXPORT_OK = qw//;

use vars
    qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD $INIT $DEBUG %SPEED_MAP
    $NOSUCH $BIGINT $REPEATERS/;

$VERSION = '3.09';

=head1 NAME

SNMP::Info - OO Interface to Network devices and MIBs through SNMP

=head1 VERSION

SNMP::Info - Version 3.09

=head1 AUTHOR

SNMP::Info is maintained by team of Open Source authors headed by Eric Miller,
Bill Fenner, Max Baker, Jeroen van Ingen and Oliver Gorwits.

Please visit L<http://sourceforge.net/projects/snmp-info/> for most up-to-date
list of developers.

SNMP::Info was originally created at UCSC for the Netdisco project L<http://netdisco.org>
by Max Baker.

=head1 DEVICES SUPPORTED

See L<http://netdisco.org/doc/DeviceMatrix.html> or L<DeviceMatrix.txt> for more details.

=head1 SYNOPSIS

 use SNMP::Info;

 my $info = new SNMP::Info( 
                            # Auto Discover more specific Device Class
                            AutoSpecify => 1,
                            Debug       => 1,
                            # The rest is passed to SNMP::Session
                            DestHost    => 'router',
                            Community   => 'public',
                            Version     => 2 
                          ) or die "Can't connect to device.\n";

 my $err = $info->error();
 die "SNMP Community or Version probably wrong connecting to device. $err\n" if defined $err;

 $name  = $info->name();
 $class = $info->class();
 print "SNMP::Info is using this device class : $class\n";

 # Find out the Duplex status for the ports
 my $interfaces = $info->interfaces();
 my $i_duplex   = $info->i_duplex();

 # Get CDP Neighbor info
 my $c_if       = $info->c_if();
 my $c_ip       = $info->c_ip();
 my $c_port     = $info->c_port();

 # Print out data per port
 foreach my $iid (keys %$interfaces){
    my $duplex = $i_duplex->{$iid};
    # Print out physical port name, not snmp iid
    my $port  = $interfaces->{$iid};

    print "$port: ";
    print "$duplex duplex" if defined $duplex;

    # The CDP Table has table entries different than the interface tables.
    # So we use c_if to get the map from cdp table to interface table.

    my %c_map = reverse %$c_if; 
    my $c_key = $c_map{$iid};
    unless (defined $c_key) {
         print "\n\n";
         next;
     }
    my $neighbor_ip   = $c_ip->{$c_key};
    my $neighbor_port = $c_port->{$c_key};

    print " connected to $neighbor_ip / $neighbor_port\n" if defined $neighbor_ip;
    print "\n";

 }

=head1 SUPPORT

Please direct all support, help, and bug requests to the snmp-info-users
Mailing List at <http://lists.sourceforge.net/lists/listinfo/snmp-info-users>.

=head1 DESCRIPTION 

SNMP::Info gives an object oriented interface to information obtained through
SNMP.

This module is geared towards network devices.  Subclasses exist for a number
of network devices and common MIBs. 

The idea behind this module is to give a common interface to data from network
devices, leaving the device-specific hacks behind the scenes in subclasses.

In the SYNOPSIS example we fetch the name of all the ports on the device and
the duplex setting for that port with two methods -- interfaces() and
i_duplex().

The information may be coming from any number of MIB files and is very vendor
specific.  SNMP::Info provides you a common method for all supported devices.

Adding support for your own device is easy, and takes little SNMP knowledge.

The module is not limited to network devices. Any MIB or device can be given
an objected oriented front-end by making a module that consists of a couple
hashes.  See EXTENDING SNMP::INFO.

=head1 REQUIREMENTS

=over

=item 1. Net-SNMP

To use this module, you must have Net-SNMP installed on your system.
More specifically you need the Perl modules that come with it.

DO NOT INSTALL SNMP:: or Net::SNMP from CPAN!

The SNMP module is matched to an install of net-snmp, and must be installed
from the net-snmp source tree.

The Perl module C<SNMP> is found inside the net-snmp distribution.  Go to the
F<perl/> directory of the distribution to install it, or run
C<./configure --with-perl-modules> from the top directory of the net-snmp
distribution.

Net-SNMP can be found at http://net-snmp.sourceforge.net

Version 5.3.2 or greater is recommended.

Versions 5.0.1, 5.0301 and 5.0203 have issues with bulkwalk and are not supported.

B<Redhat Users>: Some versions that come with certain versions of
Redhat/Fedora don't have the Perl library installed.  Uninstall the RPM and
install by hand.

=item 2. MIBS

SNMP::Info operates on textual descriptors found in MIBs.

If you are using SNMP::Info separate from Netdisco, 
download the Netdisco MIB package at L<http://sourceforge.net/project/showfiles.php?group_id=80033&package_id=135517>

Make sure that your snmp.conf is updated to point to your MIB directory
and that the MIBs are world-readable.

=back

=head1 DESIGN GOALS

=over

=item 1. Use of textual MIB leaf identifier and enumerated values 

=over

=item * All values are retrieved via MIB Leaf node names

For example SNMP::Info has an entry in its %GLOBALS hash for ``sysName''
instead of 1.3.6.1.2.1.1.5.

=item * Data returned is in the enumerated value form.

For Example instead of looking up 1.3.6.1.2.1.2.2.1.3 and getting back C<23>

SNMP::Info will ask for C<RFC1213-MIB::ifType> and will get back C<ppp>. 

=back

=item 2. SNMP::Info is easily extended to new devices

You can create a new subclass for a device by providing four hashes :
%GLOBALS, %MIBS, %FUNCS, and %MUNGE.  

Or you can override any existing methods from a parent class by making a short
subroutine. 

See the section EXTENDING SNMP::INFO for more details.

When you make a new subclass for a device, please be sure to send it back to
the developers (via Source Forge or the mailing list) for inclusion in the
next version.

=back

=head1 SUBCLASSES

These are the subclasses that implement MIBs and support devices:

Required MIBs not included in the install instructions above are noted here.

=head2 MIB Subclasses

These subclasses implement method to access one or more MIBs.  These are not 
used directly, but rather inherited from device subclasses.

For more info run C<perldoc> on any of the following module names.

=over

=item SNMP::Info::AdslLine

SNMP Interface to the ADSL-LINE-MIB for ADSL interfaces.

Requires the F<ADSL-LINE-MIB>, down loadable from Cisco.

See documentation in L<SNMP::Info::AdslLine> for details.

=item SNMP::Info::Airespace

F<AIRESPACE-WIRELESS-MIB> and F<AIRESPACE-SWITCHING-MIB>.  Inherited by
devices based on the Airespace wireless platform.

See documentation in L<SNMP::Info::Airespace> for details.

=item SNMP::Info::AMAP

F<ALCATEL-IND1-INTERSWITCH-PROTOCOL-MIB>.  Alcatel Mapping Adjacency
Protocol (AMAP) Support.

See documentation in L<SNMP::Info::AMAP> for details.

=item SNMP::Info::Bridge

F<BRIDGE-MIB> (RFC1286).  F<QBRIDGE-MIB>. Inherited by devices with Layer2
support.

See documentation in L<SNMP::Info::Bridge> for details.

=item SNMP::Info::CDP

F<CISCO-CDP-MIB>.  Cisco Discovery Protocol (CDP) Support.  Inherited by
Cisco, Enterasys, and HP devices.

See documentation in L<SNMP::Info::CDP> for details.

=item SNMP::Info::CiscoConfig

F<CISCO-CONFIG-COPY-MIB>, F<CISCO-FLASH-MIB>, and F<OLD-CISCO-SYS-MIB>.
These OIDs facilitate the writing of configuration files.

See documentation in L<SNMP::Info::CiscoConfig> for details.

=item SNMP::Info::CiscoImage

F<CISCO-IMAGE-MIB>. A collection of OIDs providing IOS image characteristics.

See documentation in L<SNMP::Info::CiscoImage> for details.

=item SNMP::Info::CiscoPortSecurity

F<CISCO-PORT-SECURITY-MIB> and F<CISCO-PAE-MIB>.

See documentation in L<SNMP::Info::CiscoPortSecurity> for details.

=item SNMP::Info::CiscoPower

F<CISCO-POWER-ETHERNET-EXT-MIB>.

See documentation in L<SNMP::Info::CiscoPower> for details.

=item SNMP::Info::CiscoQOS

F<CISCO-CLASS-BASED-QOS-MIB>. A collection of OIDs providing information about
a Cisco device's QOS config.

See documentation in L<SNMP::Info::CiscoQOS> for details.

=item SNMP::Info::CiscoRTT

F<CISCO-RTTMON-MIB>. A collection of OIDs providing information about a Cisco
device's RTT values.

See documentation in L<SNMP::Info::CiscoRTT> for details.

=item SNMP::Info::CiscoStack

F<CISCO-STACK-MIB>.

See documentation in L<SNMP::Info::CiscoStack> for details.

=item SNMP::Info::CiscoStpExtensions

F<CISCO-STP-EXTENSIONS-MIB>

See documentation in L<SNMP::Info::CiscoStpExtensions> for details.

=item SNMP::Info::CiscoStats

F<OLD-CISCO-CPU-MIB>, F<CISCO-PROCESS-MIB>, and F<CISCO-MEMORY-POOL-MIB>.
Provides common interfaces for memory, cpu, and os statistics for Cisco
devices.  

See documentation in L<SNMP::Info::CiscoStats> for details.

=item SNMP::Info::CiscoVTP

F<CISCO-VTP-MIB>, F<CISCO-VLAN-MEMBERSHIP-MIB>,
F<CISCO-VLAN-IFTABLE-RELATIONSHIP-MIB>

See documentation in L<SNMP::Info::CiscoVTP> for details.

=item SNMP::Info::EDP

Extreme Discovery Protocol.  F<EXTREME-EDP-MIB>

See documentation in L<SNMP::Info::EDP> for details.

=item SNMP::Info::Entity

F<ENTITY-MIB>.  Used for device info in Cisco and other vendors.

See documentation in L<SNMP::Info::Entity> for details.

=item SNMP::Info::EtherLike

F<EtherLike-MIB> (RFC1398) - Some Layer3 devices implement this MIB, as well
as some Aironet Layer 2 devices (non Cisco).

See documentation in L<SNMP::Info::EtherLike> for details.

=item SNMP::Info::FDP

Foundry (Brocade) Discovery Protocol.  F<FOUNDRY-SN-SWITCH-GROUP-MIB>

See documentation in L<SNMP::Info::FDP> for details.

=item SNMP::Info::IPv6

SNMP Interface for obtaining configured IPv6 addresses and mapping IPv6
addresses to MAC addresses and interfaces, using information from F<IP-MIB>,
F<IPV6-MIB> and/or F<CISCO-IETF-IP-MIB>.

See documentation in L<SNMP::Info::IPv6> for details.

=item SNMP::Info::IEEE802dot11

F<IEEE802dot11-MIB>.  A collection of OIDs providing information about
standards based 802.11 wireless devices.  

See documentation in L<SNMP::Info::IEEE802dot11> for details.

=item SNMP::Info::LLDP

F<LLDP-MIB>, F<LLDP-EXT-DOT1-MIB>, and F<LLDP-EXT-DOT3-MIB>.  Link Layer
Discovery Protocol (LLDP) Support.

See documentation in L<SNMP::Info::LLDP> for details.

=item SNMP::Info::MAU

F<MAU-MIB> (RFC2668).  Some Layer2 devices use this for extended Ethernet
(Media Access Unit) interface information.

See documentation in L<SNMP::Info::MAU> for details.

=item SNMP::Info::NortelStack

F<S5-AGENT-MIB>, F<S5-CHASSIS-MIB>.

See documentation in L<SNMP::Info::NortelStack> for details.

=item SNMP::Info::PowerEthernet

F<POWER-ETHERNET-MIB>

See documentation in L<SNMP::Info::PowerEthernet> for details.

=item SNMP::Info::RapidCity

F<RAPID-CITY>.  Inherited by Avaya switches for duplex and VLAN information.

See documentation in L<SNMP::Info::RapidCity> for details.

=item SNMP::Info::SONMP

SynOptics Network Management Protocol (SONMP) F<SYNOPTICS-ROOT-MIB>,
F<S5-ETH-MULTISEG-TOPOLOGY-MIB>.  Inherited by 
Avaya/Nortel/Bay/Synoptics switches and hubs.

See documentation in L<SNMP::Info::SONMP> for details.

=back

=head2 Device Subclasses

These subclasses inherit from one or more classes to provide a common
interface to data obtainable from network devices. 

All the required MIB files are included in the netdisco-mib package.
(See Above).

=over

=item SNMP::Info::Layer1

Generic Layer1 Device subclass.

See documentation in L<SNMP::Info::Layer1> for details.

=over 

=item SNMP::Info::Layer1::Allied

Subclass for Allied Telesis Repeaters / Hubs.  

Requires F<ATI-MIB>

See documentation in L<SNMP::Info::Layer1::Allied> for details.

=item SNMP::Info::Layer1::Asante

Subclass for Asante 1012 Hubs. 

Requires F<ASANTE-HUB1012-MIB>

See documentation in L<SNMP::Info::Layer1::Asante> for details.

=item SNMP::Info::Layer1::Bayhub

Subclass for Nortel/Bay hubs.  This includes System 5000, 100 series,
200 series, and probably more.

See documentation in L<SNMP::Info::Layer1::Bayhub> for details.

=item SNMP::Info::Layer1::Cyclades

Subclass for Cyclades terminal servers.

See documentation in L<SNMP::Info::Layer1::Cyclades> for details.

=item SNMP::Info::Layer1::S3000

Subclass for Bay/Synoptics hubs.  This includes System 3000, 281X, and
probably more.

See documentation in L<SNMP::Info::Layer1::S3000> for details.

=back

=item SNMP::Info::Layer2

Generic Layer2 Device subclass.

See documentation in L<SNMP::Info::Layer2> for details.

=over

=item SNMP::Info::Layer2::Airespace

Subclass for Cisco (Airespace) wireless controllers.

See documentation in L<SNMP::Info::Layer2::Airespace> for details.

=item SNMP::Info::Layer2::Aironet

Class for Cisco Aironet wireless devices that run IOS.  See also
Layer3::Aironet for Aironet devices that don't run IOS.

See documentation in L<SNMP::Info::Layer2::Aironet> for details.

=item SNMP::Info::Layer2::Allied

Allied Telesis switches.

See documentation in L<SNMP::Info::Layer2::Allied> for details.

=item SNMP::Info::Layer2::Baystack

Subclass for Avaya/Nortel/Bay Ethernet Switch/Baystack switches.  This
includes 303, 304, 350, 380, 410, 420, 425, 450, 460, 470 series,
2500 series, 4000 series, 5000 series, Business Ethernet Switch (BES),
Business Policy Switch (BPS), VSP 7000 series, and probably others.

See documentation in L<SNMP::Info::Layer2::Baystack> for details.

=item SNMP::Info::Layer2::Kentrox

Class for Kentrox DataSMART DSU/CSU. See L<SNMP::Info::Layer2::Kentrox> for details.

=item SNMP::Info::Layer2::C1900

Subclass for Cisco Catalyst 1900 and 1900c Devices running CatOS.

See documentation in L<SNMP::Info::Layer2::C1900> for details.

=item SNMP::Info::Layer2::C2900

Subclass for Cisco Catalyst 2900, 2950, 3500XL, and 3548 devices running IOS.

See documentation in L<SNMP::Info::Layer2::C2900> for details.

=item SNMP::Info::Layer2::Catalyst

Subclass for Cisco Catalyst switches running CatOS.  These switches usually
report a model number that starts with C<wsc>.   Note that this class
does not support everything that has the name Catalyst. 

See documentation in L<SNMP::Info::Layer2::Catalyst> for details.

=item SNMP::Info::Layer2::Centillion

Subclass for Nortel/Bay Centillion and 5000BH ATM switches.

See documentation in L<SNMP::Info::Layer2::Centillion> for details.

=item SNMP::Info::Layer2::Cisco

Generic Cisco subclass for layer2 devices that are not yet supported
in more specific subclasses.

See documentation in L<SNMP::Info::Layer2::Cisco> for details.

=item SNMP::Info::Layer2::CiscoSB

Subclass for Cisco's "Small Business" product line, acquired from 
Linksys.  This currently comprises the Sx300/500 line of switches.

See documentation in L<SNMP::Info::Layer2::CiscoSB> for details.

=item SNMP::Info::Layer2::HP

Subclass for more recent HP Procurve Switches

Requires F<HP-ICF-OID> and F<ENTITY-MIB> downloaded from HP.  

See documentation in L<SNMP::Info::Layer2::HP> for details.

=item SNMP::Info::Layer2::HP4000

Subclass for older HP Procurve Switches

Requires F<HP-ICF-OID> and F<ENTITY-MIB> downloaded from HP.  

See documentation in L<SNMP::Info::Layer2::HP4000> for details.

=item SNMP::Info::Layer2::HPVC

Subclass for HP Virtual Connect Switches

See documentation in L<SNMP::Info::Layer2::HPVC> for details.

=item SNMP::Info::Layer2::N2270

Subclass for Nortel 2270 wireless switches.

See documentation in L<SNMP::Info::Layer2::N2270> for details.

=item SNMP::Info::Layer2::NAP222x

Subclass for Nortel 222x series wireless access points.

See documentation in L<SNMP::Info::Layer2::NAP222x> for details.

=item SNMP::Info::Layer2::Netgear

Subclass for Netgear switches

See documentation in L<SNMP::Info::Layer2::Netgear> for details.

=item SNMP::Info::Layer2::NWSS2300

SNMP Interface to Avaya (Trapeze) Wireless Controllers

See documentation in L<SNMP::Info::Layer2::NWSS2300> for details.

=item SNMP::Info::Layer2::Orinoco

Subclass for Orinoco/Proxim wireless access points.

See documentation in L<SNMP::Info::Layer2::Orinoco> for details.

=item SNMP::Info::Layer2::Trapeze

SNMP Interface to Juniper (Trapeze) Wireless Controllers

See documentation in L<SNMP::Info::Layer2::Trapeze> for details.

=item SNMP::Info::Layer2::ZyXEL_DSLAM

Zyxel DSLAMs.  Need I say more?

See documentation in L<SNMP::Info::Layer2::ZyXEL_DSLAM> for details.

=back

=item SNMP::Info::Layer3

Generic Layer3 and Layer2+3 Device subclass.

See documentation in L<SNMP::Info::Layer3> for details.

=over

=item SNMP::Info::Layer3::Aironet

Subclass for Cisco Aironet wireless access points (AP) not running IOS. These
are usually older devices.

MIBs for these devices now included in v2.tar.gz available from ftp.cisco.com.

Note Layer2::Aironet 

See documentation in L<SNMP::Info::Layer3::Aironet> for details.

=item SNMP::Info::Layer3::AlcatelLucent

Alcatel-Lucent OmniSwitch Class.

See documentation in L<SNMP::Info::Layer3::AlcatelLucent> for details.

=item SNMP::Info::Layer3::AlteonAD

Subclass for Radware Alteon Series ADC switches and Nortel BladeCenter
Layer2-3 GbE Switch Modules.

See documentation in L<SNMP::Info::Layer3::AlteonAD> for details.

=item SNMP::Info::Layer3::Altiga

See documentation in L<SNMP::Info::Layer3::Altiga> for details.

=item SNMP::Info::Layer3::Arista

See documentation in L<SNMP::Info::Layer3::Arista> for details.

=item SNMP::Info::Layer3::Aruba

Subclass for Aruba wireless switches.

See documentation in L<SNMP::Info::Layer3::Aruba> for details.

=item SNMP::Info::Layer3::BayRS

Subclass for Avaya/Nortel/Bay Multiprotocol/BayRS routers.  This includes
BCN, BLN, ASN, ARN, AN, 2430, and 5430 routers.

See documentation in L<SNMP::Info::Layer3::BayRS> for details.

=item SNMP::Info::Layer3::BlueCoatSG

Subclass for Blue Coat SG series proxy devices.

See documentation in L<SNMP::Info::Layer3::BlueCoatSG> for details.

=item SNMP::Info::Layer3::C3550

Subclass for Cisco Catalyst 3550,3540,3560 2/3 switches running IOS.

See documentation in L<SNMP::Info::Layer3::C3550> for details.

=item SNMP::Info::Layer3::C4000

This class covers Catalyst 4000s and 4500s.

See documentation in L<SNMP::Info::Layer3::C4000> for details.

=item SNMP::Info::Layer3::C6500

This class covers Catalyst 6500s in native mode, hybrid mode.  Catalyst
3750's, 2970's and probably others.

See documentation in L<SNMP::Info::Layer3::C6500> for details.

=item SNMP::Info::Layer3::Cisco

This is a simple wrapper around Layer3 for IOS devices.  It adds on CiscoVTP.

See documentation in L<SNMP::Info::Layer3::Cisco> for details.

=item SNMP::Info::Layer3::CiscoASA

Subclass for Cisco Adaptive Security Appliances.

See documentation in L<SNMP::Info::Layer3::CiscoASA> for details.

=item SNMP::Info::Layer3::CiscoFWSM

Subclass for Cisco Firewall Services Modules.

See documentation in L<SNMP::Info::Layer3::CiscoFWSM> for details.

=item SNMP::Info::Layer3::Contivity

Subclass for Avaya/Nortel Contivity/VPN Routers.  

See documentation in L<SNMP::Info::Layer3::Contivity> for details.

=item SNMP::Info::Layer3::Dell

Subclass for Dell PowerConnect switches. D-Link, the IBM BladeCenter
Gigabit Ethernet Switch Module and some Linksys switches
also use this module based upon MIB support.

See documentation in L<SNMP::Info::Layer3::Dell> for details.

=item SNMP::Info::Layer3::Enterasys

Subclass for Enterasys devices.

See documentation in L<SNMP::Info::Layer3::Enterasys> for details.

=item SNMP::Info::Layer3::Extreme

Subclass for Extreme Networks switches.

See documentation in L<SNMP::Info::Layer3::Extreme> for details.

=item SNMP::Info::Layer3::F5

Subclass for F5 devices.

See documentation in L<SNMP::Info::Layer3::F5> for details.

=item SNMP::Info::Layer3::Force10

Subclass for Force10 devices.

See documentation in L<SNMP::Info::Layer3::Force10> for details.

=item SNMP::Info::Layer3::Foundry

Subclass for Brocade (Foundry) Network devices.

See documentation in L<SNMP::Info::Layer3::Foundry> for details.

=item SNMP::Info::Layer3::H3C

SNMP Interface to Layer 3 Devices, H3C & HP A-series.

See documentation in L<SNMP::Info::Layer3::H3C> for details.

=item SNMP::Info::Layer3::HP9300

Subclass for HP network devices which Foundry Networks was the
Original Equipment Manufacturer (OEM) such as the HP ProCurve 9300 and 6300 series.

See documentation in L<SNMP::Info::Layer3::HP9300> for details.

=item SNMP::Info::Layer3::IBMGbTor

SNMP Interface to IBM Rackswitch (formerly Blade Network Technologies)
network devices.

See documentation in L<SNMP::Info::Layer3::IBMGbTor> for details.

=item SNMP::Info::Layer3::Juniper

Subclass for Juniper devices

See documentation in L<SNMP::Info::Layer3::Juniper> for details.

=item SNMP::Info::Layer3::Lantronix

Subclass for Lantronix devices

See documentation in L<SNMP::Info::Layer3::Lantronix> for details.

=item SNMP::Info::Layer3::Microsoft

Subclass for Generic Microsoft Routers running Microsoft Windows OS.

See documentation in L<SNMP::Info::Layer3::Microsoft> for details.

=item SNMP::Info::Layer3::Mikrotik

Subclass for Mikrotik devices running RouterOS.

See documentation in L<SNMP::Info::Layer3::Mikrotik> for details.

=item SNMP::Info::Layer3::N1600

Subclass for Avaya/Nortel Ethernet Routing Switch 1600 series.

See documentation in L<SNMP::Info::Layer3::N1600> for details.

=item SNMP::Info::Layer3::NetSNMP

Subclass for host systems running Net-SNMP.

See documentation in L<SNMP::Info::Layer3::NetSNMP> for details.

=item SNMP::Info::Layer3::Netscreen

Subclass for Juniper NetScreen.

See documentation in L<SNMP::Info::Layer3::Netscreen> for details.

=item SNMP::Info::Layer3::Nexus

Subclass for Cisco Nexus devices running NX-OS

See documentation in L<SNMP::Info::Layer3::Nexus> for details.

=item SNMP::Info::Layer3::PacketFront

Subclass for PacketFront DRG series CPE.

See documentation in L<SNMP::Info::Layer3::PacketFront> for details.

=item SNMP::Info::Layer3::Passport

Subclass for Avaya/Nortel Ethernet Routing Switch/Passport 8000 series,
Accelar, and VSP 9000 series switches.

See documentation in L<SNMP::Info::Layer3::Passport> for details.

=item SNMP::Info::Layer3::Pf

Subclass for FreeBSD-Based Firewalls using Pf /Pf Sense

See documentation in L<SNMP::Info::Layer3::Pf> for details.

=item SNMP::Info::Layer3::Pica8

Subclass for Pica8 devices.

See documentation in L<SNMP::Info::Layer3::Pica8> for details.

=item SNMP::Info::Layer3::SonicWALL

Subclass for generic SonicWALL devices. See documentation in
L<SNMP::Info::Layer3::SonicWALL> for details.

=item SNMP::Info::Layer3::Steelhead

Subclass for  Riverbed Steelhead WAN optimization appliances. See
documentation in L<SNMP::Info::Layer3::Steelhead> for details.

=item SNMP::Info::Layer3::Sun

Subclass for Generic Sun Routers running SunOS.

See documentation in L<SNMP::Info::Layer3::Sun> for details.

=item SNMP::Info::Layer3::Tasman

Subclass for Avaya Secure Routers.

See documentation in L<SNMP::Info::Layer3::Tasman> for details.

=item SNMP::Info::Layer3::Timetra

Alcatel-Lucent SR Class.

See documentation in L<SNMP::Info::Layer3::Timetra> for details.

=back

=back

=over 4

=item SNMP::Info::Layer7

Generic Layer7 Devices.

See documentation in L<SNMP::Info::Layer7> for details.

=over 4

=item SNMP::Info::Layer7::APC

SNMP Interface to APC UPS devices

See documentation in L<SNMP::Info::Layer7::APC> for details.

=item SNMP::Info::Layer7::Netscaler

SNMP Interface to Citrix Netscaler appliances

See documentation in L<SNMP::Info::Layer7::Netscaler> for details.

=item SNMP::Info::Layer7::Neoteris

SNMP Interface to Juniper SSL VPN appliances

See documentation in L<SNMP::Info::Layer7::Neoteris> for details.

=back

=back

=head1 Thanks

Thanks for testing and coding help (in no particular order) to :
Alexander Barthel, Andy Ford, Alexander Hartmaier, Andrew Herrick, Alex
Kramarov, Bernhard Augenstein, Bradley Baetz, Brian Chow, Brian Wilson,
Carlos Vicente, Dana Watanabe, David Pinkoski, David Sieborger, Douglas
McKeown, Greg King, Ivan Auger, Jean-Philippe Luiggi, Jeroen van Ingen,
Justin Hunter, Kent Hamilton, Matthew Tuttle, Michael Robbert, Mike Hunter,
Nicolai Petri, Ralf Gross, Robert Kerr and people listed on the Netdisco
README!

=head1 USAGE

=head2 Constructor

=over

=item new()

Creates a new object and connects via SNMP::Session. 

 my $info = new SNMP::Info( 'Debug'             => 1,
                            'AutoSpecify'       => 1,
                            'BigInt'            => 1,
                            'BulkWalk'          => 1,
                            'BulkRepeaters'     => 20,
                            'IgnoreNetSNMPConf' => 1,
                            'LoopDetect'        => 1,
                            'DestHost'          => 'myrouter',
                            'Community'         => 'public',
                            'Version'           => 2,
                            'MibDirs'           => ['dir1','dir2','dir3'],
                          ) or die;

SNMP::Info Specific Arguments :

=over

=item AutoSpecify

Returns an object of a more specific device class

(default 0, which means "off")

=item BigInt

Return Math::BigInt objects for 64 bit counters.  Sets on a global scope,
not object.

(default 0, which means "off")

=item BulkWalk

Set to C<0> to turn off BULKWALK commands for SNMPv2 connections.

Note that BULKWALK is turned off for Net-SNMP versions 5.1.x because of a bug.

(default 1, which means "on")

=item BulkRepeaters

Set number of MaxRepeaters for BULKWALK operation.  See
C<perldoc SNMP> -> bulkwalk() for more info.

(default 20)

=item LoopDetect

Detects looping during getnext table column walks by comparing IIDs for each
instance.  A loop is detected if the same IID is seen more than once and the
walk is aborted.  Note:  This will not detect loops during a bulkwalk
operation, Net-SNMP's internal bulkwalk function must detect the loop. 

Set to C<0> to turn off loop detection.

(default 1, which means "on")

=item IgnoreNetSNMPConf

Net-SNMP version 5.0 and higher read configuration files, snmp.conf or
snmp.local.conf, from /etc/snmp, /usr/share/snmp, /usr/lib(64)/snmp, or
$HOME/.snmp and uses those settings to automatically parse MIB files, etc.

Set to C<1> "on" to ignore Net-SNMP configuration files by overriding the
C<SNMPCONFPATH> environmental variable during object initialization. Note:
MibDirs must be defined or Net-SNMP will not be able to load MIBs and
initialize the object.

(default 0, which means "off")

=item Debug

Prints Lots of debugging messages.
Pass 2 to print even more debugging messages.

(default 0, which means "off")

=item DebugSNMP

Set $SNMP::debugging level for Net-SNMP.

See F<SNMP> for more details.

=item MibDirs

Array ref to list of directories in which to look for MIBs.  Note this will
be in addition to the ones setup in snmp.conf at the system level.

(default use net-snmp settings only)

=item RetryNoSuch

When using SNMP Version 1, try reading values even if they come back as "no
such variable in this MIB".  Set to false if so desired.  This feature lets
you read SNMPv2 data from an SNMP version 1 connection, and should probably
be left on.

(default 1, which means "on")

=item Session

SNMP::Session object to use instead of connecting on own.

(default creates session automatically)

=item OTHER

All other arguments are passed to SNMP::Session.

See SNMP::Session for a list of other possible arguments.

=back

A Note about the wrong Community string or wrong SNMP Version:

If a connection is using the wrong community string or the wrong SNMP version,
the creation of the object will not fail.  The device still answers the call
on the SNMP port, but will not return information.  Check the error() method
after you create the device object to see if there was a problem in
connecting.

A note about SNMP Versions :

Some older devices don't support SNMP version 2, and will not return anything
when a connection under Version 2 is attempted.

Some newer devices will support Version 1, but will not return all the data
they might have if you had connected under Version 1 

When trying to get info from a new device, you may have to try version 2 and
then fallback to version 1.

=cut

sub new {
    my $proto     = shift;
    my $class     = ref($proto) || $proto;
    my %args      = @_;
    my %sess_args = %args;
    my $new_obj   = {};
    bless $new_obj, $class;

    $new_obj->{class} = $class;

    # load references to all the subclass data structures
    {
        no strict 'refs';    ## no critic (ProhibitNoStrict ProhibitProlongedStrictureOverride)
        $new_obj->{init}    = \${ $class . '::INIT' };
        $new_obj->{mibs}    = \%{ $class . '::MIBS' };
        $new_obj->{globals} = \%{ $class . '::GLOBALS' };
        $new_obj->{funcs}   = \%{ $class . '::FUNCS' };
        $new_obj->{munge}   = \%{ $class . '::MUNGE' };
    }

    # SNMP::Info specific args :
    if ( defined $args{Debug} ) {
        $new_obj->debug( $args{Debug} );
        delete $sess_args{Debug};
    }
    else {
        $new_obj->debug( defined $DEBUG ? $DEBUG : 0 );
    }

    if ( defined $args{DebugSNMP} ) {
        $SNMP::debugging = $args{DebugSNMP};
        delete $sess_args{DebugSNMP};
    }

    my $auto_specific = 0;
    if ( defined $args{AutoSpecify} ) {
        $auto_specific = $args{AutoSpecify} || 0;
        delete $sess_args{AutoSpecify};
    }

    if ( defined $args{BulkRepeaters} ) {
        $new_obj->{BulkRepeaters} = $args{BulkRepeaters};
        delete $sess_args{BulkRepeaters};
    }

    if ( defined $args{BulkWalk} ) {
        $new_obj->{BulkWalk} = $args{BulkWalk};
        delete $sess_args{BulkWalk};
    }

    if ( defined $args{LoopDetect} ) {
        $new_obj->{LoopDetect} = $args{LoopDetect};
        delete $sess_args{LoopDetect};
    }

    if ( defined $args{IgnoreNetSNMPConf} ) {
        $new_obj->{IgnoreNetSNMPConf} = $args{IgnoreNetSNMPConf} || 0;
        delete $sess_args{IgnoreNetSNMPConf};
    }

    my $sess = undef;
    if ( defined $args{Session} ) {
        $sess = $args{Session};
        delete $sess_args{Session};
    }
    if ( defined $args{BigInt} ) {
        $BIGINT = $args{BigInt};
        delete $sess_args{BigInt};
    }
    if ( defined $args{MibDirs} ) {
        $new_obj->{mibdirs} = $args{MibDirs};
        delete $sess_args{MibDirs};
    }

    $new_obj->{nosuch} = $args{RetryNoSuch} || $NOSUCH;

    # Initialize mibs if not done
    my $init_ref = $new_obj->{init};
    unless ( defined $$init_ref and $$init_ref ) {
        $new_obj->init();
        $$init_ref = 1;
    }

    # Connects to device unless open session is provided.
    $sess = new SNMP::Session(
        'UseEnums' => 1,
        %sess_args, 'RetryNoSuch' => $new_obj->{nosuch}
    ) unless defined $sess;

    # No session object created
    unless ( defined $sess ) {
        $new_obj->error_throw("SNMP::Info::new() Failed to Create Session. ");
        return;
    }

    # Session object created but SNMP connection failed.
    my $sess_err = $sess->{ErrorStr} || '';
    if ($sess_err) {
        $new_obj->error_throw(
            "SNMP::Info::new() Net-SNMP session creation failed. $sess_err");
        return;
    }

    # Table function store
    my $store = {};

    # Save Args for later
    $new_obj->{store}     = $store;
    $new_obj->{sess}      = $sess;
    $new_obj->{args}      = \%args;
    $new_obj->{snmp_ver}  = $args{Version} || 2;
    $new_obj->{snmp_comm} = $args{Community} || 'public';
    $new_obj->{snmp_user} = $args{SecName} || 'initial';

    return $auto_specific ? $new_obj->specify() : $new_obj;
}

=item update()

Replace the existing session with a new one with updated values,
without re-identifying the device.  The only supported changes are
to Community or Context.

Clears the object cache.

This is useful, e.g., when a device supports multiple contexts
(via changes to the Community string, or via the SNMPv3 Context
parameter), but a context that you want to access does not support
the objects (e.g., C<sysObjectID>, C<sysDescr>) that we use to identify
the device.

=cut

sub update {
    my $obj         = shift;
    my %update_args = @_;
    my %sess_args   = ( %{ $obj->{args} }, %update_args );

    # silently only update "the right" args
    delete $sess_args{Debug};
    delete $sess_args{DebugSNMP};
    delete $sess_args{AutoSpecify};
    delete $sess_args{BulkRepeaters};
    delete $sess_args{BulkWalk};
    delete $sess_args{LoopDetect};
    delete $sess_args{IgnoreNetSNMPConf};
    delete $sess_args{BigInt};
    delete $sess_args{MibDirs};

    my $sess = new SNMP::Session(
        'UseEnums' => 1,
        %sess_args, 'RetryNoSuch' => $obj->{nosuch}
    );
    unless ( defined $sess ) {
        $obj->error_throw(
            "SNMP::Info::update() Failed to Create new Session. ");
        return;
    }

    # Session object created but SNMP connection failed.
    my $sess_err = $sess->{ErrorStr} || '';
    if ($sess_err) {
        $obj->error_throw(
            "SNMP::Info::update() Net-SNMP session creation failed. $sess_err"
        );
        return;
    }
    $obj->clear_cache();
    return $obj->session($sess);
}

=back

=head2 Data is Cached

Methods and subroutines requesting data from a device will only load the data
once, and then return cached versions of that data. 

Run $info->load_METHOD() where method is something like 'i_name' to reload
data from a method.

Run $info->clear_cache() to clear the cache to allow reload of both globals
and table methods.

=head2 Object Scalar Methods

These are for package related data, not directly supplied
from SNMP.

=over

=item $info->clear_cache()

Clears the cached data.  This includes GLOBALS data and TABLE METHOD data.

=cut

sub clear_cache {
    my $self = shift;

    print "SNMP::Info::clear_cache() - Cache Cleared.\n" if $self->debug();

    # Clear cached global values and table method flag for being cached
    foreach my $key ( keys %$self ) {
        next unless defined $key;
        next unless $key =~ /^_/;
        delete $self->{$key};
    }

    # Clear store for tables
    return $self->store( {} );

}

=item $info->debug(1)

Returns current debug status, and optionally toggles debugging info for this
object.

=cut

sub debug {
    my $self  = shift;
    my $debug = shift;

    if ( defined $debug ) {
        $self->{debug} = $debug;
    }

    return $self->{debug};
}

=item $info->bulkwalk([1|0])

Returns if bulkwalk is currently turned on for this object.

Optionally sets the bulkwalk parameter.

=cut

sub bulkwalk {
    my $self = shift;
    my $bw   = shift;

    if ( defined $bw ) {
        $self->{BulkWalk} = $bw;
    }
    return $self->{BulkWalk};
}

=item $info->loopdetect([1|0])

Returns if loopdetect is currently turned on for this object.

Optionally sets the loopdetect parameter.

=cut

sub loopdetect {
    my $self = shift;
    my $ld   = shift;

    if ( defined $ld ) {
        $self->{LoopDetect} = $ld;
    }
    return $self->{LoopDetect};
}

=item $info->device_type()

Returns the Subclass name for this device.  C<SNMP::Info> is returned if no
more specific class is available.

First the device is checked for Layer 3 support and a specific subclass,
then Layer 2 support and subclasses are checked.

This means that Layer 2 / 3  switches and routers will fall under the
SNMP::Info::Layer3 subclasses.

If the device still can be connected to via SNMP::Info, then 
SNMP::Info is returned.  

See L<http://netdisco.org/doc/DeviceMatrix.html> or L<DeviceMatrix.txt> for more details
about device support, or view C<device_type()> in F<Info.pm>.

=cut

sub device_type {
    my $info = shift;

    my $objtype = "SNMP::Info";

    my $layers = $info->layers() || '00000000';

    my $desc = $info->description() || 'undef';
    $desc =~ s/[\r\n\l]+/ /g;

    # Some devices don't implement sysServices, but do return a description. 
    # In that case, log a warning and continue.
    if ( $layers eq '00000000' ) {
        if ($desc ne 'undef') {
            carp("Device doesn't implement sysServices but did return sysDescr. Might give unexpected results.\n") if $info->debug();
        } else {
            # No sysServices, no sysDescr 
            return;
        }
    }

    my $id = $info->id() || 'undef';
    my $soid = $id;

    # Hash for generic fallback to a device class if unable to determine using
    # the sysDescr regex.
    my %l3sysoidmap = (
        9    => 'SNMP::Info::Layer3::Cisco',
        11   => 'SNMP::Info::Layer2::HP',
        18   => 'SNMP::Info::Layer3::BayRS',
        42   => 'SNMP::Info::Layer3::Sun',
        45   => 'SNMP::Info::Layer2::Baystack',
        171  => 'SNMP::Info::Layer3::Dell',
        244  => 'SNMP::Info::Layer3::Lantronix',
        311  => 'SNMP::Info::Layer3::Microsoft',
        674  => 'SNMP::Info::Layer3::Dell',
        1872 => 'SNMP::Info::Layer3::AlteonAD',
        1916 => 'SNMP::Info::Layer3::Extreme',
        1991 => 'SNMP::Info::Layer3::Foundry',
        2021 => 'SNMP::Info::Layer3::NetSNMP',
        2272 => 'SNMP::Info::Layer3::Passport',
        2636 => 'SNMP::Info::Layer3::Juniper',
        2925 => 'SNMP::Info::Layer1::Cyclades',
        3076 => 'SNMP::Info::Layer3::Altiga',
        3224 => 'SNMP::Info::Layer3::Netscreen',
        3375 => 'SNMP::Info::Layer3::F5',
        3417 => 'SNMP::Info::Layer3::BlueCoatSG',
        4526 => 'SNMP::Info::Layer2::Netgear',
        5624 => 'SNMP::Info::Layer3::Enterasys',
        6027 => 'SNMP::Info::Layer3::Force10',
        6486 => 'SNMP::Info::Layer3::AlcatelLucent',
        6527 => 'SNMP::Info::Layer3::Timetra',
        8072 => 'SNMP::Info::Layer3::NetSNMP',
        9303 => 'SNMP::Info::Layer3::PacketFront',
        12325 => 'SNMP::Info::Layer3::Pf',
        14525 => 'SNMP::Info::Layer2::Trapeze',
        14988 => 'SNMP::Info::Layer3::Mikrotik',
        17163 => 'SNMP::Info::Layer3::Steelhead',
        25506 => 'SNMP::Info::Layer3::H3C',
        26543 => 'SNMP::Info::Layer3::IBMGbTor',
        30065 => 'SNMP::Info::Layer3::Arista',
        35098 => 'SNMP::Info::Layer3::Pica8',
    );

    my %l2sysoidmap = (
        9     => 'SNMP::Info::Layer2::Cisco',
        11    => 'SNMP::Info::Layer2::HP',
        45    => 'SNMP::Info::Layer2::Baystack',
        171   => 'SNMP::Info::Layer3::Dell',
        207   => 'SNMP::Info::Layer2::Allied',
        674   => 'SNMP::Info::Layer3::Dell',
        1872  => 'SNMP::Info::Layer3::AlteonAD',
        1916  => 'SNMP::Info::Layer3::Extreme',
        1991  => 'SNMP::Info::Layer3::Foundry',
        2272  => 'SNMP::Info::Layer3::Passport',
        2925  => 'SNMP::Info::Layer1::Cyclades',
        3224  => 'SNMP::Info::Layer3::Netscreen',
        3375  => 'SNMP::Info::Layer3::F5',
        4526  => 'SNMP::Info::Layer2::Netgear',
        5624  => 'SNMP::Info::Layer3::Enterasys',
        6486  => 'SNMP::Info::Layer3::AlcatelLucent',
        11898 => 'SNMP::Info::Layer2::Orinoco',
        14179 => 'SNMP::Info::Layer2::Airespace',
        14525 => 'SNMP::Info::Layer2::Trapeze',
        14823 => 'SNMP::Info::Layer3::Aruba',
        17163 => 'SNMP::Info::Layer3::Steelhead',
        26543 => 'SNMP::Info::Layer3::IBMGbTor',
    );

    my %l7sysoidmap = (
        318   => 'SNMP::Info::Layer7::APC',
        5951  => 'SNMP::Info::Layer7::Netscaler',
        14525 => 'SNMP::Info::Layer2::Trapeze',
        12532 => 'SNMP::Info::Layer7::Neoteris',
    );

    # Get just the enterprise number for generic mapping
    $id = $1 if ( defined($id) && $id =~ /^\.1\.3\.6\.1\.4\.1\.(\d+)/ );

    if ($info->debug()) {
        print "SNMP::Info $VERSION\n";
        print "SNMP::Info::device_type() layers:$layers id:$id sysDescr:\"$desc\"\n";
    }

    # Layer 3 Supported
    #   (usually has layer2 as well, so we check for 3 first)
    if ( $info->has_layer(3) ) {
        $objtype = 'SNMP::Info::Layer3';

        # Device Type Overrides

        return $objtype unless ( defined $desc and length($desc) );

        $objtype = 'SNMP::Info::Layer3::C3550' if $desc =~ /(C3550|C3560)/;
        $objtype = 'SNMP::Info::Layer3::C4000' if $desc =~ /Catalyst 4[05]00/;
        $objtype = 'SNMP::Info::Layer3::Foundry' if $desc =~ /foundry/i;

        # Aironet - older non-IOS
        $objtype = 'SNMP::Info::Layer3::Aironet'
            if ($desc =~ /Cisco/
            and $desc =~ /\D(CAP340|AP340|CAP350|350|1200)\D/ );
        $objtype = 'SNMP::Info::Layer3::Aironet'
            if ( $desc =~ /Aironet/ and $desc =~ /\D(AP4800)\D/ );

        # Cat6k with older SUPs (hybrid CatOS/IOS?)
        $objtype = 'SNMP::Info::Layer3::C6500' if $desc =~ /(c6sup2|c6sup1)/;

        # Cat6k with Sup720, Sup720 or Sup2T (and Sup2 running native IOS?)
        $objtype = 'SNMP::Info::Layer3::C6500'
            if $desc =~ /(s72033_rp|s3223_rp|s32p3_rp|s222_rp|s2t54)/;

        # Next one untested. Reported working by DA
        $objtype = 'SNMP::Info::Layer3::C6500'
            if ( $desc =~ /cisco/i and $desc =~ /3750/ );

        # IOS 15.x on Catalyst 3850
        $objtype = 'SNMP::Info::Layer3::C6500'
            if ( $desc =~ /cisco/i and $desc =~ /CAT3K/ );

        #   Cisco 2970
        $objtype = 'SNMP::Info::Layer3::C6500'
            if ( $desc =~ /(C2970|C2960)/ );

        #   Cisco 3400 w/ Layer3 capable image
        $objtype = 'SNMP::Info::Layer3::C3550'
            if ( $desc =~ /(ME340x)/ );

        # Various Cisco blade switches, CBS30x0 and CBS31x0 models
        $objtype = 'SNMP::Info::Layer3::C6500'
            if ( $desc =~ /cisco/i and $desc =~ /CBS3[0-9A-Za-z]{3}/ );

        # Cisco Nexus running NX-OS
        $objtype = 'SNMP::Info::Layer3::Nexus'
            if ( $desc =~ /^Cisco\s+NX-OS/ );

        # HP, older ProCurve models (1600, 2400, 2424m, 4000, 8000)
        $objtype = 'SNMP::Info::Layer2::HP4000'
            if $desc =~ /\b(J4093A|J4110A|J4120A|J4121A|J4122A|J4122B)\b/;

        # HP, Foundry OEM
        $objtype = 'SNMP::Info::Layer3::HP9300'
            if $desc =~ /\b(J4874A|J4138A|J4139A|J4840A|J4841A)\b/;

        # Nortel ERS (Passport) 1600 Series < version 2.1
        $objtype = 'SNMP::Info::Layer3::N1600'
            if $desc =~ /(Passport|Ethernet\s+Routing\s+Switch)-16/i;

        #  ERS - BayStack Numbered
        $objtype = 'SNMP::Info::Layer2::Baystack'
            if ( $desc
            =~ /^(BayStack|Ethernet\s+Routing\s+Switch)\s[2345](\d){2,3}/i );

        # Nortel Contivity
        $objtype = 'SNMP::Info::Layer3::Contivity' if $desc =~ /(\bCES\b|\bNVR\sV\d)/;

        # SonicWALL
        $objtype = 'SNMP::Info::Layer3::SonicWALL' if $desc =~ /SonicWALL/i;

        # Allied Telesis Layer2 managed switches. They report they have L3 support
        $objtype = 'SNMP::Info::Layer2::Allied'
            if ( $desc =~ /Allied.*AT-80\d{2}\S*/i );

        # Cisco ASA, newer versions which report layer 3 functionality
        # version >= 8.2 are known to do this
        $objtype = 'SNMP::Info::Layer3::CiscoASA'
            if ( $desc =~ /Cisco Adaptive Security Appliance/i );

        # Cisco FWSM
        $objtype = 'SNMP::Info::Layer3::CiscoFWSM'
            if ( $desc =~ /Cisco Firewall Services Module/i );
        
        # Avaya Secure Router
        $objtype = 'SNMP::Info::Layer3::Tasman'
            if ( $desc =~ /^(avaya|nortel)\s+(SR|secure\srouter)\s+\d{4}/i );

        # HP Virtual Connect blade switches
        $objtype = 'SNMP::Info::Layer2::HPVC'
            if ( $desc =~ /HP\sVC\s/ );

        # Aironet - IOS
        # Starting with IOS 15, Aironet reports sysServices 6, even though
        # it still is the same layer2 access point.
        $objtype = 'SNMP::Info::Layer2::Aironet'
            if ($desc =~ /\b(C1100|C1130|C1140|AP1200|C350|C1200|C1240|C1250)\b/
            and $desc =~ /\bIOS\b/ );

        # Generic device classification based upon sysObjectID
        if (    ( $objtype eq 'SNMP::Info::Layer3' )
            and ( defined($id) )
            and ( exists( $l3sysoidmap{$id} ) ) )
        {
            $objtype = $l3sysoidmap{$id};
        }

        # Layer 2 Supported
    }
    elsif ( $info->has_layer(2) ) {
        $objtype = 'SNMP::Info::Layer2';

        return $objtype unless ( defined $desc and $desc !~ /^\s*$/ );

        # Device Type Overrides

        #   Catalyst 1900 series override
        $objtype = 'SNMP::Info::Layer2::C1900'
            if ( $desc =~ /catalyst/i and $desc =~ /\D19\d{2}/ );

        #   Catalyst 2900 and 3500XL (IOS) series override
        $objtype = 'SNMP::Info::Layer2::C2900'
            if ( $desc =~ /(C2900XL|C2950|C3500XL|C2940|CGESM|CIGESM)/i );

        #   Catalyst WS-C series override 2926,4k,5k,6k in Hybrid
        $objtype = 'SNMP::Info::Layer2::Catalyst' if ( $desc =~ /WS-C\d{4}/ );

        #   Catalyst 3550 / 3548 Layer2 only switches
        #   Cisco 3400 w/ MetroBase Image
        $objtype = 'SNMP::Info::Layer3::C3550'
            if ( $desc =~ /(C3550|ME340x)/ );

        # Cisco blade switches, CBS30x0 and CBS31x0 models with L2 only
        $objtype = 'SNMP::Info::Layer3::C6500'
            if ( $desc =~ /cisco/i and $desc =~ /CBS3[0-9A-Za-z]{3}/ );

        #   Cisco 2970
        $objtype = 'SNMP::Info::Layer3::C6500'
            if ( $desc =~ /(C2970|C2960)/ );

        #   Cisco Small Business (300 500) series override
        #   This is for enterprises(1).cisco(9).otherEnterprises(6).ciscosb(1)
        $objtype = 'SNMP::Info::Layer2::CiscoSB'
            if ( $soid =~ /^\.1\.3\.6\.1\.4\.1\.9\.6\.1/ );
        
        # HP, older ProCurve models (1600, 2400, 2424m, 4000, 8000)
        $objtype = 'SNMP::Info::Layer2::HP4000'
            if $desc =~ /\b(J4093A|J4110A|J4120A|J4121A|J4122A|J4122B)\b/;

        # HP, Foundry OEM
        $objtype = 'SNMP::Info::Layer3::HP9300'
            if $desc =~ /\b(J4874A|J4138A|J4139A|J4840A|J4841A)\b/;

        # IBM BladeCenter 4-Port GB Ethernet Switch Module
        $objtype = 'SNMP::Info::Layer3::Dell'
            if ( $desc =~ /^IBM Gigabit Ethernet Switch Module$/ );

        # Linksys 2024/2048
        $objtype = 'SNMP::Info::Layer3::Dell'
            if (
            $desc =~ /^(24|48)-Port 10\/100\/1000 Gigabit Switch (with |w\/)WebView$/ );

        #  Centillion ATM
        $objtype = 'SNMP::Info::Layer2::Centillion' if ( $desc =~ /MCP/ );

        #  BPS
        $objtype = 'SNMP::Info::Layer2::Baystack'
            if ( $desc =~ /Business\sPolicy\sSwitch/i );

        #  BayStack Numbered
        $objtype = 'SNMP::Info::Layer2::Baystack'
            if ( $desc
            =~ /^(BayStack|Ethernet\s+(Routing\s+)??Switch)\s[2345](\d){2,3}/i
            );

        # Kentrox DataSMART DSU/CSU
        $objtype = 'SNMP::Info::Layer2::Kentrox'
            if ( $desc =~ /^DataSMART/i );

        #  Nortel Business Ethernet Switch
        $objtype = 'SNMP::Info::Layer2::Baystack'
            if ( $desc =~ /^Business Ethernet Switch\s[12]\d\d/i );

        #  Nortel AP 222X
        $objtype = 'SNMP::Info::Layer2::NAP222x'
            if ( $desc =~ /Access\s+Point\s+222/ );

        #  Orinoco
        $objtype = 'SNMP::Info::Layer2::Orinoco'
            if ( $desc =~ /(AP-\d{3}|WavePOINT)/ );

        #  Aironet - IOS
        $objtype = 'SNMP::Info::Layer2::Aironet'
            if ($desc =~ /\b(C1100|C1130|C1140|AP1200|C350|C1200|C1240|C1250)\b/
            and $desc =~ /\bIOS\b/ );

        # Aironet - non IOS
        $objtype = 'SNMP::Info::Layer3::Aironet'
            if ( $desc =~ /Cisco/ and $desc =~ /\D(BR500)\D/ );

        # Airespace (WLC) Module
        $objtype = 'SNMP::Info::Layer2::Airespace'
            if ( $desc =~ /Cisco Controller/ );

        #Nortel 2270
        $objtype = 'SNMP::Info::Layer2::N2270'
            if (
            $desc =~ /Nortel\s+(Networks\s+)??WLAN\s+-\s+Security\s+Switch/ );

        # HP Virtual Connect blade switches
        $objtype = 'SNMP::Info::Layer2::HPVC'
            if ( $desc =~ /HP\sVC\s/ );

        # Generic device classification based upon sysObjectID
        if (    ( $objtype eq 'SNMP::Info::Layer2' )
            and ( defined($id) )
            and ( exists( $l2sysoidmap{$id} ) ) )
        {
            $objtype = $l2sysoidmap{$id};
        }

    }
    elsif ( $info->has_layer(1) ) {
        $objtype = 'SNMP::Info::Layer1';

        #  Allied crap-o-hub
        $objtype = 'SNMP::Info::Layer1::Allied' if ( $desc =~ /allied/i );
        $objtype = 'SNMP::Info::Layer1::Asante' if ( $desc =~ /asante/i );

        #  Bay Hub
        $objtype = 'SNMP::Info::Layer1::Bayhub'
            if ( $desc =~ /\bNMM.*Agent/ );
        $objtype = 'SNMP::Info::Layer1::Bayhub'
            if ( $desc =~ /\bBay\s*Stack.*Hub/i );

        #  Synoptics Hub
        #  This will override Bay Hub only for specific devices supported by this class
        $objtype = 'SNMP::Info::Layer1::S3000'
            if ( $desc =~ /\bNMM\s+(281|3000|3030)/i );

        # These devices don't claim to have Layer1-3 but we like em anyways.
    }
    else {
        $objtype = 'SNMP::Info::Layer2::ZyXEL_DSLAM'
            if ( $desc =~ /8-port .DSL Module\(Annex .\)/i );

        # Aruba wireless switches
        $objtype = 'SNMP::Info::Layer3::Aruba'
            if ( $desc =~ /(ArubaOS|AirOS)/ );

        # Alcatel-Lucent branded Aruba
        $objtype = 'SNMP::Info::Layer3::Aruba'
            if ( $desc =~ /^AOS-W/ );

        # Cisco PIX
        $objtype = 'SNMP::Info::Layer3::Cisco'
            if ( $desc =~ /Cisco PIX Security Appliance/i );

        # Cisco ASA, older version which doesn't report layer 3 functionality
        $objtype = 'SNMP::Info::Layer3::CiscoASA'
            if ( $desc =~ /Cisco Adaptive Security Appliance/i );

        # HP Virtual Connect blade switches
        $objtype = 'SNMP::Info::Layer2::HPVC'
            if ( $desc =~ /HP\sVC\s/ );

        # Nortel (Trapeze) WSS 2300 Series
        $objtype = 'SNMP::Info::Layer2::NWSS2300'    
            if ( $desc =~ /\bWireless\sSecurity\sSwitch\s23[568][012]\b/);

        # Generic device classification based upon sysObjectID
        if ( defined($id) and $objtype eq 'SNMP::Info') {
            if ( defined $l3sysoidmap{$id} ) {
                $objtype = $l3sysoidmap{$id};
            } elsif ( defined $l2sysoidmap{$id}) {
                $objtype = $l2sysoidmap{$id};
            } elsif ( defined $l7sysoidmap{$id}) {
                $objtype = $l7sysoidmap{$id};
            } elsif ($info->has_layer(7)) {
                $objtype = 'SNMP::Info::Layer7'
            }
        }
    }

    return $objtype;
}

=item $info->error(no_clear)

Returns Error message if there is an error, or undef if there is not.

Reading the error will clear the error unless you set the no_clear flag.

=cut

sub error {
    my $self     = shift;
    my $no_clear = shift;
    my $err      = $self->{error};

    $self->{error} = undef unless defined $no_clear and $no_clear;
    return $err;
}

=item $info->has_layer(3)

Returns non-zero if the device has the supplied layer in the OSI Model

Returns if the device doesn't support the layers() call.

=cut

sub has_layer {
    my $self      = shift;
    my $check_for = shift;

    my $layers = $self->layers();
    return unless defined $layers;
    return unless length($layers);
    return substr( $layers, 8 - $check_for, 1 );
}

=item $info->snmp_comm()

Returns SNMP Community string used in connection.

=cut

sub snmp_comm {
    my $self = shift;
    if ( $self->{snmp_ver} == 3 ) {
        return $self->{snmp_user};
    }
    else {
        return $self->{snmp_comm};
    }
}

=item $info->snmp_ver()

Returns SNMP Version used for this connection

=cut

sub snmp_ver {
    my $self = shift;
    return $self->{snmp_ver};
}

=item $info->specify()

Returns an object of a more-specific subclass.  

 my $info = new SNMP::Info(...);
 # Returns more specific object type
 $info = $info->specific();

Usually this method is called internally from new(AutoSpecify => 1)

See device_type() entry for how a subclass is chosen.

=cut

sub specify {
    my $self = shift;

    my $device_type = $self->device_type();
    unless ( defined $device_type ) {
        $self->error_throw(
            "SNMP::Info::specify() - Could not get info from device");
        return;
    }
    return $self if $device_type eq 'SNMP::Info';

    # Load Subclass
    # By evaling a string the contents of device_type now becomes a bareword.
    eval "require $device_type;";    ## no critic
    if ($@) {
        croak "SNMP::Info::specify() Loading $device_type Failed. $@\n";
    }

    my $args    = $self->args();
    my $session = $self->session();
    my $sub_obj = $device_type->new(
        %$args,
        'Session'     => $session,
        'AutoSpecify' => 0
    );

    unless ( defined $sub_obj ) {
        $self->error_throw(
            "SNMP::Info::specify() - Could not connect with new class ($device_type)"
        );
        return $self;
    }

    $self->debug()
        and print "SNMP::Info::specify() - Changed Class to $device_type.\n";
    return $sub_obj;
}

=item $info->cisco_comm_indexing()

Returns 0.  Is an overridable method used for vlan indexing for
snmp calls on certain Cisco devices. 

See L<ftp://ftp.cisco.com/pub/mibs/supportlists/wsc5000/wsc5000-communityIndexing.html>

=cut

sub cisco_comm_indexing {
    return 0;
}

=back

=head2 Globals (Scalar Methods)

These are methods to return scalar data from RFC1213.  

Some subset of these is probably available for any network device that speaks
SNMP.

=over

=item $info->uptime()

Uptime in hundredths of seconds since device became available.

(C<sysUpTime>)

=item $info->contact()

(C<sysContact>)

=item $info->name()

(C<sysName>)

=item $info->location() 

(C<sysLocation>)

=item $info->layers()

This returns a binary encoded string where each
digit represents a layer of the OSI model served
by the device.  

    eg: 01000010  means layers 2 (physical) and 7 (Application) 
                  are served.

Note:  This string is 8 digits long.  

See $info->has_layer()

(C<sysServices>)

=item $info->ports()

Number of interfaces available on this device.

Not too useful as the number of SNMP interfaces usually does not 
correspond with the number of physical ports

(C<ifNumber>)

=item $info->ipforwarding()

The indication of whether the entity is acting as an IP gateway

Returns either forwarding or not-forwarding

(C<ipForwarding>)

=back

=head2 Table Methods

Each of these methods returns a hash_reference to a hash keyed on the
interface index in SNMP.

Example : $info->interfaces() might return  

    { '1.12' => 'FastEthernet/0',
      '2.15' => 'FastEthernet/1',
      '9.99' => 'FastEthernet/2'
    }

The key is what you would see if you were to do an snmpwalk, and in some cases
changes between reboots of the network device.

=head2 Partial Table Fetches

If you want to get only a part of an SNMP table or a single instance from the
table and you know the IID for the part of the table that you want, you can
specify it in the call:

    $local_routes = $info->ipr_route('192.168.0');

This will only fetch entries in the table that start with C<192.168.0>, which
in this case are routes on the local network. 

Remember that you must supply the partial IID (a numeric OID).

Partial table results are not cached.

=head2 Interface Information

=over

=item $info->interfaces()

This methods is overridden in each subclass to provide a 
mapping between the Interface Table Index (iid) and the physical port name.

=item $info->if_ignore()

Returns a reference to a hash where key values that exist are 
interfaces to ignore.

Ignored interfaces are ones that are usually not physical ports or Virtual
Lans (VLANs) such as the Loopback interface, or the CPU interface. 

=cut

sub if_ignore {
    my %nothing;
    return \%nothing;
}

=item $info->bulkwalk_no()

Returns 0.  Is an overridable method used for turn off bulkwalk for the
device class. 

=cut

sub bulkwalk_no {
    return 0;
}

=item $info->i_index()

Default SNMP IID to Interface index.

(C<ifIndex>)

=item $info->i_description() 

Description of the interface. Usually a little longer single word name that is
both human and machine friendly.  Not always.

(C<ifDescr>)

=item $info->i_type()

Interface type, such as Vlan, Ethernet, Serial

(C<ifType>)

=item $info->i_mtu()

INTEGER. Interface MTU value.

(C<ifMtu>)

=item $info->i_speed()

Speed of the link, human format.  See munge_speed() later in document for
details.

(C<ifSpeed>, C<ifHighSpeed> if necessary)

=cut

sub i_speed {
    my $info    = shift;
    my $partial = shift;

    my $i_speed = $info->orig_i_speed($partial);

    my $i_speed_high = undef;
    foreach my $i ( keys %$i_speed ) {
        if ( $i_speed->{$i} eq "4294967295" ) {
            $i_speed_high = $info->i_speed_high($partial)
                unless defined($i_speed_high);
            $i_speed->{$i} = $i_speed_high->{$i} if ( $i_speed_high->{$i} );
        }
    }
    return $i_speed;
}

=item $info->i_speed_raw()

Speed of the link in bits per second without munging.
If i_speed_high is available it will be used and multiplied by 1_000_000.

(C<ifSpeed>, C<ifHighSpeed> if necessary)

=cut

sub i_speed_raw {
    my $info    = shift;
    my $partial = shift;

    # remove the speed formating
    my $munge_i_speed = delete $info->{munge}{i_speed};
    # also for highspeed interfaces e.g. TenGigabitEthernet
    my $munge_i_speed_high = delete $info->{munge}{i_speed_high};

    my $i_speed_raw = $info->orig_i_speed($partial);

    my $i_speed_high = undef;
    foreach my $i ( keys %$i_speed_raw ) {
        if ( $i_speed_raw->{$i} eq "4294967295" ) {
            $i_speed_high = $info->i_speed_high($partial)
                unless defined($i_speed_high);
            $i_speed_raw->{$i} = ( $i_speed_high->{$i} * 1_000_000 )
                if ( $i_speed_high->{$i} );
        }
    }

    # restore the speed formating
    $info->{munge}{i_speed} = $munge_i_speed;
    $info->{munge}{i_speed_high} = $munge_i_speed_high;

    return $i_speed_raw;
}

=item $info->i_speed_high()

Speed of a high-speed link, human format.  See munge_highspeed() later in
document for details.  You should not need to call this directly, as
i_speed() will call it if it needs to.

(C<ifHighSpeed>)

=item $info->i_mac() 

MAC address of the interface.  Note this is just the MAC of the port, not
anything connected to it.

(C<ifPhysAddress>)

=item $info->i_up() 

Link Status of the interface.  Typical values are 'up' and 'down'.

(C<ifOperStatus>)

=item $info->i_up_admin()

Administrative status of the port.  Typical values are 'enabled' and 'disabled'.

(C<ifAdminStatus>)

=item $info->i_lastchange()

The value of C<sysUpTime> when this port last changed states (up,down).

(C<ifLastChange>)

=item $info->i_name()

Interface Name field.  Supported by a smaller subset of devices, this fields
is often human set.

(C<ifName>)

=item $info->i_alias()

Interface Name field.  For certain devices this is a more human friendly form
of i_description().  For others it is a human set field like i_name().

(C<ifAlias>)

=back

=head2 Interface Statistics

=over

=item $info->i_octet_in(), $info->i_octets_out(),
$info->i_octet_in64(), $info->i_octets_out64()

Bandwidth.

Number of octets sent/received on the interface including framing characters.

64 bit version may not exist on all devices. 

NOTE: To manipulate 64 bit counters you need to use Math::BigInt, since the
values are too large for a normal Perl scalar.   Set the global
$SNMP::Info::BIGINT to 1 , or pass the BigInt value to new() if you want
SNMP::Info to do it for you.


(C<ifInOctets>) (C<ifOutOctets>)
(C<ifHCInOctets>) (C<ifHCOutOctets>)

=item $info->i_errors_in(), $info->i_errors_out()

Number of packets that contained an error preventing delivery.  See C<IF-MIB>
for more info.

(C<ifInErrors>) (C<ifOutErrors>)

=item $info->i_pkts_ucast_in(), $info->i_pkts_ucast_out(),
$info->i_pkts_ucast_in64(), $info->i_pkts_ucast_out64()

Number of packets not sent to a multicast or broadcast address.

64 bit version may not exist on all devices. 

(C<ifInUcastPkts>) (C<ifOutUcastPkts>)
(C<ifHCInUcastPkts>) (C<ifHCOutUcastPkts>)

=item $info->i_pkts_nucast_in(), $info->i_pkts_nucast_out(),

Number of packets sent to a multicast or broadcast address.

These methods are deprecated by i_pkts_multi_in() and i_pkts_bcast_in()
according to C<IF-MIB>.  Actual device usage may vary.

(C<ifInNUcastPkts>) (C<ifOutNUcastPkts>)

=item $info->i_pkts_multi_in() $info->i_pkts_multi_out(),
$info->i_pkts_multi_in64(), $info->i_pkts_multi_out64()

Number of packets sent to a multicast address.

64 bit version may not exist on all devices. 

(C<ifInMulticastPkts>) (C<ifOutMulticastPkts>)
(C<ifHCInMulticastPkts>) (C<ifHCOutMulticastPkts>)

=item $info->i_pkts_bcast_in() $info->i_pkts_bcast_out(),
$info->i_pkts_bcast_in64() $info->i_pkts_bcast_out64()

Number of packets sent to a broadcast address on an interface.

64 bit version may not exist on all devices. 

(C<ifInBroadcastPkts>) (C<ifOutBroadcastPkts>)
(C<ifHCInBroadcastPkts>) (C<ifHCOutBroadcastPkts>)

=item $info->i_discards_in() $info->i_discards_out()

"The number of inbound packets which were chosen to be discarded even though
no errors had been detected to prevent their being deliverable to a
higher-layer protocol.  One possible reason for discarding such a packet could
be to free up buffer space."  (C<IF-MIB>)

(C<ifInDiscards>) (C<ifOutDiscards>)

=item $info->i_bad_proto_in()

"For packet-oriented interfaces, the number of packets received via the
interface which were discarded because of an unknown or unsupported protocol.
For character-oriented or fixed-length interfaces that support protocol
multiplexing the number of transmission units received via the interface which
were discarded because of an unknown or unsupported protocol.  For any
interface that does not support protocol multiplexing, this counter will always
be 0."

(C<ifInUnknownProtos>)

=item $info->i_qlen_out()

"The length of the output packet queue (in packets)."

(C<ifOutQLen>)

=item $info->i_specific()

See C<IF-MIB> for full description

(C<ifSpecific>)

=back

=head2 IP Address Table

Each entry in this table is an IP address in use on this device.  Usually 
this is implemented in Layer3 Devices.

=over

=item $info->ip_index()

Maps the IP Table to the IID

(C<ipAdEntIfIndex>)

=item $info->ip_table()

Maps the Table to the IP address

(C<ipAdEntAddr>)

=item $info->ip_netmask()

Gives netmask setting for IP table entry.

(C<ipAdEntNetMask>)

=item $info->ip_broadcast()

Gives broadcast address for IP table entry.

(C<ipAdEntBcastAddr>)

=back

=head2 IP Routing Table

=over

=item $info->ipr_route()

The route in question.  A value of 0.0.0.0 is the default gateway route.

(C<ipRouteDest>)

=item $info->ipr_if()

The interface (IID) that the route is on.  Use interfaces() to map.

(C<ipRouteIfIndex>)

=item $info->ipr_1()

Primary routing metric for this route. 

(C<ipRouteMetric1>)

=item $info->ipr_2()

If metrics are not used, they should be set to -1

(C<ipRouteMetric2>)

=item $info->ipr_3()

(C<ipRouteMetric3>)

=item $info->ipr_4()

(C<ipRouteMetric4>)

=item $info->ipr_5()

(C<ipRouteMetric5>)

=item $info->ipr_dest()

From RFC1213:

  "The IP address of the next hop of this route.
  (In the case of a route bound to an interface
  which is realized via a broadcast media, the value
  of this field is the agent's IP address on that
  interface.)"

(C<ipRouteNextHop>)

=item $info->ipr_type()

From RFC1213:

    other(1),        -- none of the following
    invalid(2),      -- an invalidated route
                     -- route to directly
    direct(3),       -- connected (sub-)network
                     -- route to a non-local
    indirect(4)      -- host/network/sub-network


      "The type of route.  Note that the values
      direct(3) and indirect(4) refer to the notion of
      direct and indirect routing in the IP
      architecture.

      Setting this object to the value invalid(2) has
      the effect of invalidating the corresponding entry
      in the ipRouteTable object.  That is, it
      effectively disassociates the destination
      identified with said entry from the route
      identified with said entry.  It is an
      implementation-specific matter as to whether the
      agent removes an invalidated entry from the table.
      Accordingly, management stations must be prepared
      to receive tabular information from agents that
      corresponds to entries not currently in use.
      Proper interpretation of such entries requires
      examination of the relevant ipRouteType object."

(C<ipRouteType>)

=item $info->ipr_proto()

From RFC1213:

    other(1),       -- none of the following
                    -- non-protocol information,
                    -- e.g., manually configured
    local(2),       -- entries
                    -- set via a network
    netmgmt(3),     -- management protocol
                    -- obtained via ICMP,
    icmp(4),        -- e.g., Redirect
                    -- the remaining values are
                    -- all gateway routing
                    -- protocols
    egp(5),
    ggp(6),
    hello(7),
    rip(8),
    is-is(9),
    es-is(10),
    ciscoIgrp(11),
    bbnSpfIgp(12),
    ospf(13),
    bgp(14)

(C<ipRouteProto>)

=item $info->ipr_age()

Seconds since route was last updated or validated.

(C<ipRouteAge>)

=item $info->ipr_mask()

Subnet Mask of route. 0.0.0.0 for default gateway.

(C<ipRouteMask>)

=item $info->ipr_info()

Reference to MIB definition specific to routing protocol.

(C<ipRouteInfo>)

=back

=head2 Topology Information

Based upon the manufacturer and software version devices may support some 
combination of Layer 2 topology protocol information.  SNMP::Info
supports querying Link Layer Discovery Protocol (LLDP), Cisco Discovery
Protocol (CDP), SynOptics/Bay/Nortel/Avaya Network Management Protocol
(SONMP), Foundry/Brocade Discovery Protocol (FDP), Extreme Discovery
Protocol (EDP), and Alcatel Mapping Adjacency Protocol (AMAP). 

For protocol specific information and implementation:

=over

=item LLDP: See L<SNMP::Info::LLDP> for details.

=item CDP: See L<SNMP::Info::CDP> for details.

=item SONMP: See L<SNMP::Info::SONMP> for details.

=item FDP: See L<SNMP::Info::FDP> for details.

=item EDP: See L<SNMP::Info::EDP> for details.

=item AMAP: See L<SNMP::Info::AMAP> for details.

=back

=head3 Topology Capabilities

=over

=item $info->has_topo()

Reports Layer 2 topology protocols which are supported and running on
a device.

Returns either a reference to an array of protocols, possible values
being: C<lldp>, C<cdp>, C<sonmp>, C<fdp>, C<edp>, C<amap> or C<undef> if
no protocols are supported or running.

=back

=cut

sub has_topo {
    my $self = shift;

    my @topo_cap;
    push( @topo_cap, 'lldp' )
        if ( $self->can('hasLLDP') && $self->hasLLDP() );
    push( @topo_cap, 'cdp' ) if $self->can('hasCDP') && $self->hasCDP();
    push( @topo_cap, 'sonmp' )
        if $self->can('hasSONMP') && $self->hasSONMP();
    push( @topo_cap, 'fdp' ) if $self->can('hasFDP') && $self->hasFDP();
    push( @topo_cap, 'edp' ) if $self->can('hasEDP') && $self->hasEDP();
    push( @topo_cap, 'amap' ) if $self->can('hasAMAP') && $self->hasAMAP();

    if (@topo_cap) {
        return \@topo_cap;
    }
    else {
        return;
    }
}

sub _get_topo_data {
    my $self     = shift;
    my $partial  = shift;
    my $topo_cap = shift;
    my $method   = shift;

    return unless $method =~ /(ip|if|port|id|platform|cap)/;

    my %t_data;
    foreach my $proto (@$topo_cap) {
        next unless $proto =~ /(lldp|cdp|sonmp|fdp|edp|amap)/;
        my $method_name = "$proto" . "_$method";
        my $cdp = $self->$method_name($partial) || {};

        foreach my $iid ( keys %$cdp ) {
            my $ip = $cdp->{$iid};
            next unless defined $ip;

            $t_data{$iid} = $ip;
        }
    }
    return \%t_data; 
}

=head3 Common Topology Table Information

The common topology table methods below will query the
device for information from the specified topology protocols and return a
single hash combining all information. As a result, there may be identical
topology information returned from the two protocols causing duplicate
entries.  It is the calling program's responsibility to identify any
duplicate entries and remove duplicates if necessary.  If it is necessary
to understand which protocol provided the information, utilize the protocol
specific methods directly rather than the generic methods.

The methods support partial table fetches by providing a partial as the
first argument.

If a reference to an array is provided as the second argument, those
protocols will be queried for information.  The supported array values are:
C<lldp>, C<cdp>, C<sonmp>, C<fdp>, C<edp>, C<amap>.

If nothing is passed in as the second argument, the methods will call
has_topo() to determine supported and running topology protocols on the
device. 

=over

=item $info->c_ip(partial, topology_protocol_arrayref)

Returns reference to hash.  Key: iid, Value: remote IPv4 address

If multiple entries exist with the same local port, c_if(), with the
same IPv4 address, c_ip(), it may be a duplicate entry.

If multiple entries exist with the same local port, c_if(), with different
IPv4 addresses, c_ip(), there is either a device in between two or
more devices utilizing a different topology protocol or multiple devices
which are not directly connected.  

Use the protocol specific methods to dig deeper.

=cut

sub c_ip {
    my $self     = shift;
    my $partial  = shift;
    my $topo_cap = shift;

    # Default to old behavior if not called with topo_cap
    if ( !$topo_cap ) {
        my $topo_test = $self->has_topo();
        if ($topo_test) {
            $topo_cap = $topo_test;
        }
        else {
            return;
        }
    }
    return _get_topo_data ($self, $partial, $topo_cap, 'ip');
}

=item $info->c_if(partial, topology_protocol_arrayref)

Returns reference to hash.  Key: iid, Value: local device port (interfaces)

=cut

sub c_if {
    my $self     = shift;
    my $partial  = shift;
    my $topo_cap = shift;

    # Default to old behavior if not called with topo_cap
    if ( !$topo_cap ) {
        my $topo_test = $self->has_topo();
        if ($topo_test) {
            $topo_cap = $topo_test;
        }
        else {
            return;
        }
    }
    return _get_topo_data ($self, $partial, $topo_cap, 'if');
}

=item $info->c_port(partial, topology_protocol_arrayref)

Returns reference to hash. Key: iid, Value: remote port (interfaces)

=cut

sub c_port {
    my $self     = shift;
    my $partial  = shift;
    my $topo_cap = shift;

    # Default to old behavior if not called with topo_cap
    if ( !$topo_cap ) {
        my $topo_test = $self->has_topo();
        if ($topo_test) {
            $topo_cap = $topo_test;
        }
        else {
            return;
        }
    }
    return _get_topo_data ($self, $partial, $topo_cap, 'port');
}

=item $info->c_id(partial, topology_protocol_arrayref)

Returns reference to hash. Key: iid, Value: string value used to identify the
chassis component associated with the remote system.

Note: SONMP does not return this information.

=cut

sub c_id {
    my $self     = shift;
    my $partial  = shift;
    my $topo_cap = shift;

    # Default to old behavior if not called with topo_cap
    if ( !$topo_cap ) {
        my $topo_test = $self->has_topo();
        if ($topo_test) {
            $topo_cap = $topo_test;
        }
        else {
            return;
        }
    }
    return _get_topo_data ($self, $partial, $topo_cap, 'id');
}

=item $info->c_platform(partial, topology_protocol_arrayref)

Returns reference to hash.  Key: iid, Value: Remote Device Type

Note:  EDP does not provide this information.  LLDP uses (C<lldpRemSysDesc>)
or C<lldp_rem_sysname> as the closest match.

=cut

sub c_platform {
    my $self     = shift;
    my $partial  = shift;
    my $topo_cap = shift;

    # Default to old behavior if not called with topo_cap
    if ( !$topo_cap ) {
        my $topo_test = $self->has_topo();
        if ($topo_test) {
            $topo_cap = $topo_test;
        }
        else {
            return;
        }
    }
    return _get_topo_data ($self, $partial, $topo_cap, 'platform');
}

=item $info->c_cap(partial, topology_protocol_arrayref)

Returns reference to hash of arrays.  Key: iid, Value: Array of capabilities 
supported by the device.  See the specific protocol class for string values
which could be elements within the array. 

Note:  Only CDP and LLDP support this method.

=cut

sub c_cap {
    my $self     = shift;
    my $partial  = shift;
    my $topo_cap = shift;

    # Default to old behavior if not called with topo_cap
    if ( !$topo_cap ) {
        my $topo_test = $self->has_topo();
        if ($topo_test) {
            $topo_cap = $topo_test;
        }
        else {
            return;
        }
    }
    return _get_topo_data ($self, $partial, $topo_cap, 'cap');
}

=back

=head1 SETTING DATA VIA SNMP

This section explains how to use SNMP::Info to do SNMP Set operations.

=over

=item $info->set_METHOD($value)

Sets the global METHOD to value.  Assumes that iid is .0

Returns if failed, or the return value from SNMP::Session::set() (snmp_errno)

 $info->set_location("Here!");

=item $info->set_METHOD($value,$iid)

Table Methods. Set iid of method to value. 

Returns if failed, or the return value from SNMP::Session::set() (snmp_errno)

 # Disable a port administratively
 my %if_map = reverse %{$info->interfaces()}
 $info->set_i_up_admin('down', $if_map{'FastEthernet0/0'}) 
    or die "Couldn't disable the port. ",$info->error(1);

=back

NOTE: You must be connected to your device with a C<ReadWrite> community
string in order for set operations to work.

NOTE: This will only set data listed in %FUNCS and %GLOBALS.  For data
acquired from overridden methods (subroutines) specific set_METHOD()
subroutines will need to be added if they haven't been already.

=head1 Quiet Mode

SNMP::Info will not chirp anything to STDOUT unless there is a serious error
(in which case it will probably die).

To get lots of debug info, set the Debug flag when calling new() or
call $info->debug(1);

When calling a method check the return value.  If the return value is undef
then check $info->error()

Beware, calling $info->error() clears the error.

 my $name = $info->name() or die "Couldn't get sysName!" . $name->error();

=head1 EXTENDING SNMP::INFO

To support a new class (vendor or platform) of device, add a Perl package with
the data structures and methods listed below.

If this seems a little scary, then the SNMP::Info developers are usually happy
to accept the SNMP data from your device and make an attempt at the class
themselves. Usually a "beta" release will go to CPAN for you to verify the
implementation.

=head2 Gathering MIB data for SNMP::Info Developers

The preference is to open a feature request in the SourceForge project.  This
allows all developers to have visibility into the request.  Please include
pointers to the applicable platform MIBs.  For development we will need an
C<snmpwalk> of the device.  There is a tool now included in the SNMP::Info
distribution to help with this task, although you'll most likely need to
download the distribution from CPAN as it's included in the "C<t/util>"
directory.

The utility is named C<make_snmpdata.pl>. Run it with a command line like:

 ./make_snmpdata.pl -c community -i -d device_ip \
  -m /home/netdisco-mibs/rfc:/home/netdisco-mibs/net-snmp:/home/netdisco-mibs/dir3 \
  SNMPv2-MIB IF-MIB EtherLike-MIB BRIDGE-MIB Q-BRIDGE-MIB ENTITY-MIB \
  POWER-ETHERNET-MIB IPV6-MIB LLDP-MIB DEVICE-SPECIFIC-MIB-NAME(s) > output.txt

This will print to the file every MIB entry with data in a format that the
developers can use to emulate read operations without needing access to the
device.  Preference would be to mask any sensitive data in the output, zip the
file, and upload as an attachment to the Sourceforge tracker.  However, if you
do not feel comfortable  uploading the output to the tracker you could e-mail
it to the developer that has claimed the ticket.

=head2 Data Structures required in new Subclass

A class inheriting this class must implement these data structures : 

=over

=item  $INIT

Used to flag if the MIBs have been loaded yet.

=cut

$INIT = 0;

=item %GLOBALS

Contains a hash in the form ( method_name => SNMP MIB leaf name )
These are scalar values such as name, uptime, etc. 

To resolve MIB leaf name conflicts between private MIBs, you may prefix the
leaf name with the MIB replacing each - (dash) and : (colon) with
an _ (underscore).  For example, ALTEON_TIGON_SWITCH_MIB__agSoftwareVersion
would be used as the hash value instead of the net-snmp notation
ALTEON-TIGON-SWITCH-MIB::agSoftwareVersion.

When choosing the name for the methods, be aware that other new
Sub Modules might inherit this one to get it's features.  Try to
choose a prefix for methods that will give it's own name space inside
the SNMP::Info methods.

=cut

%GLOBALS = (

    # from SNMPv2-MIB
    'id'           => 'sysObjectID',
    'description'  => 'sysDescr',
    'uptime'       => 'sysUpTime',
    'contact'      => 'sysContact',
    'name'         => 'sysName',
    'location'     => 'sysLocation',
    'layers'       => 'sysServices',
    'ports'        => 'ifNumber',
    'ipforwarding' => 'ipForwarding',
);

=item %FUNCS

Contains a hash in the form ( method_name => SNMP MIB leaf name)
These are table entries, such as the C<ifIndex>

To resolve MIB leaf name conflicts between private MIBs, you may prefix the
leaf name with the MIB replacing each - (dash) and : (colon) with
an _ (underscore).  For example, ALTEON_TS_PHYSICAL_MIB__agPortCurCfgPortName
would be used as the hash value instead of the net-snmp notation
ALTEON-TS-PHYSICAL-MIB::agPortCurCfgPortName.

=cut

%FUNCS = (
    'interfaces' => 'ifIndex',
    'i_name'     => 'ifName',

    # IF-MIB::IfEntry
    'i_index'           => 'ifIndex',
    'i_description'     => 'ifDescr',
    'i_type'            => 'ifType',
    'i_mtu'             => 'ifMtu',
    'i_speed'           => 'ifSpeed',
    'i_mac'             => 'ifPhysAddress',
    'i_up_admin'        => 'ifAdminStatus',
    'i_up'              => 'ifOperStatus',
    'i_lastchange'      => 'ifLastChange',
    'i_octet_in'        => 'ifInOctets',
    'i_pkts_ucast_in'   => 'ifInUcastPkts',
    'i_pkts_nucast_in'  => 'ifInNUcastPkts',
    'i_discards_in'     => 'ifInDiscards',
    'i_errors_in'       => 'ifInErrors',
    'i_bad_proto_in'    => 'ifInUnknownProtos',
    'i_octet_out'       => 'ifOutOctets',
    'i_pkts_ucast_out'  => 'ifOutUcastPkts',
    'i_pkts_nucast_out' => 'ifOutNUcastPkts',
    'i_discards_out'    => 'ifOutDiscards',
    'i_errors_out'      => 'ifOutErrors',
    'i_qlen_out'        => 'ifOutQLen',
    'i_specific'        => 'ifSpecific',

    # IF-MIB::IfStackTable
    'i_stack_status'    => 'ifStackStatus',

    # IP Address Table
    'ip_index'     => 'ipAdEntIfIndex',
    'ip_table'     => 'ipAdEntAddr',
    'ip_netmask'   => 'ipAdEntNetMask',
    'ip_broadcast' => 'ipAdEntBcastAddr',

    # ifXTable - Extension Table
    'i_speed_high'       => 'ifHighSpeed',
    'i_pkts_multi_in'    => 'ifInMulticastPkts',
    'i_pkts_multi_out'   => 'ifOutMulticastPkts',
    'i_pkts_bcast_in'    => 'ifInBroadcastPkts',
    'i_pkts_bcast_out'   => 'ifOutBroadcastPkts',
    'i_octet_in64'       => 'ifHCInOctets',
    'i_octet_out64'      => 'ifHCOutOctets',
    'i_pkts_ucast_in64'  => 'ifHCInUcastPkts',
    'i_pkts_ucast_out64' => 'ifHCOutUcastPkts',
    'i_pkts_multi_in64'  => 'ifHCInMulticastPkts',
    'i_pkts_multi_out64' => 'ifHCOutMulticastPkts',
    'i_pkts_bcast_in64'  => 'ifHCInBroadcastPkts',
    'i_pkts_bcast_out64' => 'ifHCOutBroadcastPkts',
    'i_alias'            => 'ifAlias',

    # IP Routing Table
    'ipr_route' => 'ipRouteDest',
    'ipr_if'    => 'ipRouteIfIndex',
    'ipr_1'     => 'ipRouteMetric1',
    'ipr_2'     => 'ipRouteMetric2',
    'ipr_3'     => 'ipRouteMetric3',
    'ipr_4'     => 'ipRouteMetric4',
    'ipr_5'     => 'ipRouteMetric5',
    'ipr_dest'  => 'ipRouteNextHop',
    'ipr_type'  => 'ipRouteType',
    'ipr_proto' => 'ipRouteProto',
    'ipr_age'   => 'ipRouteAge',
    'ipr_mask'  => 'ipRouteMask',
    'ipr_info'  => 'ipRouteInfo',
);

=item %MIBS

A list of each mib needed.  

    ('MIB-NAME' => 'itemToTestForPresence')

The value for each entry should be a MIB object to check for to make sure 
that the MIB is present and has loaded correctly. 

$info->init() will throw an exception if a MIB does not load. 

=cut

%MIBS = (

    # The "main" MIBs are automagically loaded in Net-SNMP now.
);

=item %MUNGE

A map between method calls (from %FUNCS or %GLOBALS) and subroutine methods.
The subroutine called will be passed the data as it gets it from SNMP and 
it should return that same data in a more human friendly format. 

Sample %MUNGE:

 (my_ip     => \&munge_ip,
  my_mac    => \&munge_mac,
  my_layers => \&munge_dec2bin
 )

=cut

%MUNGE = (
    'ip'                 => \&munge_ip,
    'mac'                => \&munge_mac,
    'i_mac'              => \&munge_mac,
    'layers'             => \&munge_dec2bin,
    'i_speed'            => \&munge_speed,
    'i_speed_high'       => \&munge_highspeed,
    'i_octet_in64'       => \&munge_counter64,
    'i_octet_out64'      => \&munge_counter64,
    'i_pkts_ucast_in64'  => \&munge_counter64,
    'i_pkts_ucast_out64' => \&munge_counter64,
    'i_pkts_mutli_in64'  => \&munge_counter64,
    'i_pkts_multi_out64' => \&munge_counter64,
    'i_pkts_bcast_in64'  => \&munge_counter64,
    'i_pkts_bcast_out64' => \&munge_counter64,
    'i_up'               => \&munge_i_up,
);

=back

=head2 Sample Subclass

Let's make a sample Layer 2 Device subclass.  This class
will inherit the Cisco Vlan module as an example.

----------------------- snip --------------------------------

 # SNMP::Info::Layer2::Sample

 package SNMP::Info::Layer2::Sample;

 $VERSION = 0.1;

 use strict;

 use Exporter;
 use SNMP::Info::Layer2;
 use SNMP::Info::CiscoVTP;

 @SNMP::Info::Layer2::Sample::ISA = qw/SNMP::Info::Layer2
                                       SNMP::Info::CiscoVTP Exporter/;
 @SNMP::Info::Layer2::Sample::EXPORT_OK = qw//;

 use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD $INIT $DEBUG/;

 %MIBS    = (%SNMP::Info::Layer2::MIBS,
             %SNMP::Info::CiscoVTP::MIBS,
             'SUPER-DOOPER-MIB'  => 'supermibobject'
            );

 %GLOBALS = (%SNMP::Info::Layer2::GLOBALS,
             %SNMP::Info::CiscoVTP::GLOBALS,
             'name'              => 'supermib_supername',
             'favorite_color'    => 'supermib_fav_color_object',
             'favorite_movie'    => 'supermib_fav_movie_val'
             );

 %FUNCS   = (%SNMP::Info::Layer2::FUNCS,
             %SNMP::Info::CiscoVTP::FUNCS,
             # Super Dooper MIB - Super Hero Table
             'super_hero_index'  => 'SuperHeroIfIndex',
             'super_hero_name'   => 'SuperHeroIfName',
             'super_hero_powers' => 'SuperHeroIfPowers'
            );


 %MUNGE   = (%SNMP::Info::Layer2::MUNGE,
             %SNMP::Info::CiscoVTP::MUNGE,
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

 # Copious Documentation here!!!
 =head1 NAME
 =head1 AUTHOR
 =head1 SYNOPSIS
 =head1 DESCRIPTION
 =head2 Inherited Classes
 =head2 Required MIBs
 =head1 GLOBALS
 =head2 Overrides
 =head1 TABLE METHODS
 =head2 Overrides
 =cut

 1; # don't forget this line
----------------------- snip --------------------------------

Be sure and send the debugged version to snmp-info-users@lists.sourceforge.net to be 
included in the next version of SNMP::Info.

=head1 SNMP::INFO INTERNALS

=head2 Object Namespace

Internal data is stored with bareword keys. For example $info->{debug}

SNMP Data is stored or marked cached with keys starting with an underscore. 
For example $info->{_name} is the cache for $info->name().

Cached Table data is stored in $info->store() and marked cached per above.

=head2 Package Globals

These set the default value for an object upon creation.

=over

=item $DEBUG

Default 0.  Sends copious debug info to stdout.  This global sets the object's
debug status in new() unless 'Debug' argument passed in new().  Change
objects' debug status with $info->debug().

=cut

$DEBUG = 0;

=item $BIGINT

Default 0.   Set to true to have 64 bit counters return Math::BigInt objects
instead of scalar string values.  See note under Interface Statistics about
64 bit values.

=cut

$BIGINT = 0;

=item $NOSUCH

Default 1.  Set to false to disable RetryNoSuch option for SNMP::Session.  Or
see method in new() to do it on an object scope.

=cut

$NOSUCH = 1;

=item $REPEATERS

Default 20.  MaxRepeaters for BULKWALK operations.  See C<perldoc SNMP> for
more info.  Can change by passing L<BulkRepeaters> option in new()

=cut

$REPEATERS = 20;

=back

=head2 Data Munging Callback Subroutines

=over

=item munge_speed()

Makes human friendly speed ratings using %SPEED_MAP

 %SPEED_MAP = (
                '56000'      => '56 kbps',
                '64000'      => '64 kbps',
                '115000'     => '115 kpbs',
                '1500000'    => '1.5 Mbps',
                '1536000'    => 'T1',      
                '1544000'    => 'T1',
                '2000000'    => '2.0 Mbps',
                '2048000'    => '2.048 Mbps',
                '3072000'    => 'Dual T1',
                '3088000'    => 'Dual T1',   
                '4000000'    => '4.0 Mbps',
                '10000000'   => '10 Mbps',
                '11000000'   => '11 Mbps',
                '20000000'   => '20 Mbps',
                '16000000'   => '16 Mbps',
                '16777216'   => '16 Mbps',
                '44210000'   => 'T3',
                '44736000'   => 'T3',
                '45000000'   => '45 Mbps',
                '45045000'   => 'DS3',
                '46359642'   => 'DS3',
                '51850000'   => 'OC-1',
                '54000000'   => '54 Mbps',
                '64000000'   => '64 Mbps',
                '100000000'  => '100 Mbps',
                '149760000'  => 'ATM on OC-3',
                '155000000'  => 'OC-3',
                '155519000'  => 'OC-3',
                '155520000'  => 'OC-3',
                '400000000'  => '400 Mbps',
                '599040000'  => 'ATM on OC-12', 
                '622000000'  => 'OC-12',
                '622080000'  => 'OC-12',
                '1000000000' => '1.0 Gbps',
                '2488000000' => 'OC-48',
             )

Note: high speed interfaces (usually 1 Gbps or faster) have their link 
speed in C<ifHighSpeed>. i_speed() automatically determines whether to use 
C<ifSpeed> or C<ifHighSpeed>; if the latter is used, the value is munged by 
munge_highspeed(). SNMP::Info can return speeds up to terabit levels this way.

=cut

%SPEED_MAP = (
    '56000'      => '56 kbps',
    '64000'      => '64 kbps',
    '115000'     => '115 kpbs',
    '1500000'    => '1.5 Mbps',
    '1536000'    => 'T1',
    '1544000'    => 'T1',
    '2000000'    => '2.0 Mbps',
    '2048000'    => '2.048 Mbps',
    '3072000'    => 'Dual T1',
    '3088000'    => 'Dual T1',
    '4000000'    => '4.0 Mbps',
    '10000000'   => '10 Mbps',
    '11000000'   => '11 Mbps',
    '20000000'   => '20 Mbps',
    '16000000'   => '16 Mbps',
    '16777216'   => '16 Mbps',
    '44210000'   => 'T3',
    '44736000'   => 'T3',
    '45000000'   => '45 Mbps',
    '45045000'   => 'DS3',
    '46359642'   => 'DS3',
    '51850000'   => 'OC-1',
    '54000000'   => '54 Mbps',
    '64000000'   => '64 Mbps',
    '100000000'  => '100 Mbps',
    '149760000'  => 'ATM on OC-3',
    '155000000'  => 'OC-3',
    '155519000'  => 'OC-3',
    '155520000'  => 'OC-3',
    '400000000'  => '400 Mbps',
    '599040000'  => 'ATM on OC-12',
    '622000000'  => 'OC-12',
    '622080000'  => 'OC-12',
    '1000000000' => '1.0 Gbps',
    '2488000000' => 'OC-48',
);

sub munge_speed {
    my $speed = shift;
    my $map   = $SPEED_MAP{$speed};

    #print "  $speed -> $map  " if (defined $map);
    return $map || $speed;
}

=item munge_highspeed()

Makes human friendly speed ratings for C<ifHighSpeed>

=cut

sub munge_highspeed {
    my $speed = shift;
    my $fmt   = "%d Mbps";

    if ( $speed > 9999999 ) {
        $fmt = "%d Tbps";
        $speed /= 1000000;
    }
    elsif ( $speed > 999999 ) {
        $fmt = "%.1f Tbps";
        $speed /= 1000000.0;
    }
    elsif ( $speed > 9999 ) {
        $fmt = "%d Gbps";
        $speed /= 1000;
    }
    elsif ( $speed > 999 ) {
        $fmt = "%.1f Gbps";
        $speed /= 1000.0;
    }
    return sprintf( $fmt, $speed );
}

=item munge_ip() 

Takes a binary IP and makes it dotted ASCII

=cut

sub munge_ip {
    my $ip = shift;
    return join( '.', unpack( 'C4', $ip ) );
}

=item munge_mac()

Takes an octet stream (HEX-STRING) and returns a colon separated ASCII hex
string.

=cut

sub munge_mac {
    my $mac = shift;
    return unless defined $mac;
    return unless length $mac;
    $mac = join( ':', map { sprintf "%02x", $_ } unpack( 'C*', $mac ) );
    return $mac if $mac =~ /^([0-9A-F][0-9A-F]:){5}[0-9A-F][0-9A-F]$/i;
    return;
}

=item munge_prio_mac()

Takes an 8-byte octet stream (HEX-STRING) and returns a colon separated ASCII
hex string.

=cut

sub munge_prio_mac {
    my $mac = shift;
    return unless defined $mac;
    return unless length $mac;
    $mac = join( ':', map { sprintf "%02x", $_ } unpack( 'C*', $mac ) );
    return $mac if $mac =~ /^([0-9A-F][0-9A-F]:){7}[0-9A-F][0-9A-F]$/i;
    return;
}

=item munge_octet2hex()

Takes a binary octet stream and returns an ASCII hex string

=cut

sub munge_octet2hex {
    my $oct = shift;
    return join( '', map { sprintf "%x", $_ } unpack( 'C*', $oct ) );
}

=item munge_dec2bin()

Takes a binary char and returns its ASCII binary representation

=cut

sub munge_dec2bin {
    my $num = shift;
    return unless defined $num;

    #return unless length($num);
    $num = unpack( "B32", pack( "N", $num ) );

    # return last 8 characters only
    $num =~ s/.*(.{8})$/$1/;
    return $num;
}

=item munge_bits

Takes a SNMP2 'BITS' field and returns the ASCII bit string

=cut

sub munge_bits {
    my $bits = shift;
    return unless defined $bits;

    return unpack( "B*", $bits );
}

=item munge_counter64

If $BIGINT is set to true, then a Math::BigInt object is returned.
See Math::BigInt for details.

=cut

sub munge_counter64 {
    my $counter = shift;
    return          unless defined $counter;
    return $counter unless $BIGINT;
    my $bigint = Math::BigInt->new($counter);
    return $bigint;
}

=item munge_i_up

Net-SNMP tends to load C<RFC1213-MIB> first, and so ignores the
updated enumeration for C<ifOperStatus> in C<IF-MIB>.  This munge
handles the "newer" definitions for the enumeration in IF-MIB.

TODO: Get the precedence of MIBs and overriding of MIB data in Net-SNMP
figured out.  Heirarchy/precendence of MIBS in SNMP::Info.

=cut

sub munge_i_up {
    my $i_up = shift;
    return unless defined $i_up;

    my %ifOperStatusMap = ( '4' => 'unknown',
                            '5' => 'dormant',
                            '6' => 'notPresent',
                            '7' => 'lowerLayerDown' );
    return $ifOperStatusMap{$i_up} || $i_up;
}

=item munge_port_list

Takes an octet string representing a set of ports and returns a reference
to an array of binary values each array element representing a port. 

If the element has a value of '1', then that port is included in the set of
ports; the port is not included if it has a value of '0'.

=cut

sub munge_port_list {
    my $oct = shift;
    return unless defined $oct;

    my $list = [ split( //, unpack( "B*", $oct ) ) ];

    return $list;
}

=item munge_null()

Removes control characters from a string

=cut

# munge_null() - removes nulls (\0) and other control characters
sub munge_null {
    my $text = shift || return;

    $text =~ s/[[:cntrl:]]//g;
    return $text;
}

=item munge_e_type()

Takes an OID and return the object name if the right MIB is loaded.

=cut

sub munge_e_type {
    my $oid = shift;

    my $name = &SNMP::translateObj($oid);
    return $name if defined($name);
    return $oid;
}

=back

=head2 Internally Used Functions

=over

=item $info->init()

Used internally.  Loads all entries in %MIBS.

=cut

sub init {
    my $self = shift;

    # Get MibDirs if provided
    my $mibdirs = $self->{mibdirs} || [];
    
    # SNMP::initMib and SNMP::addMibDirs both look for some initial MIBs
    # so if we are not using Net-SNMP configuration files we need to
    # specify where the MIBs are before those calls.

    # Ignore snmp.conf and snmp.local.conf files if IgnoreNetSNMPConf
    # specified
    local $ENV{'SNMPCONFPATH'} = '' if $self->{IgnoreNetSNMPConf};
    # We need to provide MIBDIRS if we are not getting them from a
    # configuration file
    my $mibdir = join (':', @$mibdirs);
    local $ENV{'MIBDIRS'} = "$mibdir" if $self->{IgnoreNetSNMPConf};

    SNMP::initMib;

    my $version = $SNMP::VERSION;
    my ( $major, $minor, $rev ) = split( '\.', $version );

    if ( $major < 5 ) {

        # Seems to work under 4.2.0
    }
    elsif ( $major == 5 and $minor == 0 and $rev < 2 ) {
        carp("Net-SNMP 5.0.1 seems to be rather buggy. Upgrade.\n");

        # This is a bug in net-snmp 5.0.1 perl module
        # see http://groups.google.com/groups?th=47aed6bf7be6a0f5
        SNMP::init_snmp("perl");
    }

    foreach my $d (@$mibdirs) {
        next unless -d $d;
        print "SNMP::Info::init() - Adding new mibdir:$d\n" if $self->debug();
        SNMP::addMibDirs($d);
    }

    my $mibs = $self->mibs();

    foreach my $mib ( keys %$mibs ) {

        #print "SNMP::Info::init() - Loading mib:$mib\n" if $self->debug();
        SNMP::loadModules("$mib");

        unless ( defined $SNMP::MIB{ $mibs->{$mib} } ) {
            croak "The $mib did not load. See README for $self->{class}\n";
        }
    }
    return;
}

=item $info->args()

Returns a reference to the argument hash supplied to SNMP::Session

=cut

sub args {
    my $self = shift;
    return $self->{args};
}

=item $info->class()

Returns the class name of the object.

=cut

sub class {
    my $self = shift;
    return $self->{class};
}

=item $info->error_throw(error message)

Stores the error message for use by $info->error()

If $info->debug() is true, then the error message is carped too.

=cut

sub error_throw {
    my $self  = shift;
    my $error = shift;

    return unless defined $error;
    $self->{error} = $error;

    if ( $self->debug() ) {
        $error =~ s/\n+$//;
        carp($error);
    }
    return;
}

=item $info->funcs()

Returns a reference to the %FUNCS hash.

=cut

sub funcs {
    my $self = shift;
    return $self->{funcs};
}

=item $info->globals()

Returns a reference to the %GLOBALS hash.

=cut

sub globals {
    my $self = shift;
    return $self->{globals};
}

=item $info->mibs()

Returns a reference to the %MIBS hash.

=cut

sub mibs {
    my $self = shift;
    return $self->{mibs};
}

=item $info->munge()

Returns a reference of the %MUNGE hash.

=cut

sub munge {
    my $self = shift;
    return $self->{munge};
}

=item $info->nosuch()

Returns NoSuch value set or not in new()

=cut

sub nosuch {
    my $self = shift;
    return $self->{nosuch};
}

=item $info->session()

Gets or Sets the SNMP::Session object.

=cut

sub session {
    my $self = shift;
    $self->{sess} = $_[0] if @_;
    return $self->{sess};
}

=item $info->store(new_store)

Returns or sets hash store for Table functions.

Store is a hash reference in this format :

$info->store = { attribute => { iid => value , iid2 => value2, ... } };

=cut

sub store {
    my $self = shift;
    $self->{store} = $_[0] if @_;
    return $self->{store};
}

=item $info->_global()

Used internally by AUTOLOAD to create dynamic methods from %GLOBALS or a
single instance MIB Leaf node name from a loaded MIB.

Example: $info->name() on the first call dispatches to AUTOLOAD() which
calls $info->_global('name') creating the method name().

These methods return data as a scalar.

=cut

sub _global {
    my $method = shift;
    my $oid    = shift;

    return sub {
        my $self = shift;

        my $sess = $self->session();
        return unless defined $sess;

        my $load = $method =~ /^load/;
        my $raw  = $method =~ /raw$/;

        my $attr = $method;
        $attr =~ s/^(load|orig)_//;
        $attr =~ s/_raw$//;

        # Return cached data unless loading
        # We now store in raw format so munge before returning
        # unless expecting raw data
        if ( defined $self->{"_$attr"} && !$load ) {
            my $val = $self->{"_$attr"};

            if ( !$raw ) {
                return $self->_munge($attr, $val);
            } else{
                return $val;
            } 
        }

        if ( $self->debug() ) {
            # Let's get the MIB Module and leaf name along with the OID
            my $qual_leaf = SNMP::translateObj($oid,0,1) || '';
            print "SNMP::Info::_global $method : $qual_leaf : $oid\n";
        }
        my $val = $sess->get($oid);

        # Mark as gotten. Even if it fails below, we don't want to keep failing.
        $self->{"_$attr"} = undef;

        if ( $sess->{ErrorStr} ) {
            $self->error_throw(
                "SNMP::Info::_global($method) $sess->{ErrorStr}");
            return;
        }

        if ( defined $val and $val eq 'NOSUCHOBJECT' ) {
            $self->error_throw("SNMP::Info::_global($method) NOSUCHOBJECT");
            return;
        }

        if ( defined $val and $val eq 'NOSUCHINSTANCE' ) {
            $self->error_throw("SNMP::Info::_global($method) NOSUCHINSTANCE");
            return;
        }

        # Save Cached Value
        $self->_cache($attr, $val);

        # Data Munging
        if ( !$raw ) {
            $val = $self->_munge($attr, $val);
        }

        return $val;
    }
}

=item $info->_set(attr,val,iid,type)

Used internally by set_multi() to run an SNMP set command.  When run
clears attr cache.

Attr can be passed as either a scalar or a reference to an array or array
of arrays when used with set_multi().

Example:  $info->set_name('dog',3) uses autoload to resolve to
$info->_set('name','dog',3);

=cut

sub _set {
    my ( $self, $attr, $val, $iid, $type ) = @_;
    my $varbind_list_ref;

    if ( !ref($attr) ) {
        $varbind_list_ref = [ [ $attr, $iid, $val, $type ] ];
    }
    elsif ( ref($attr) =~ /ARRAY/ ) {
        $varbind_list_ref = [$attr];
        $varbind_list_ref = $attr if ref( $$attr[0] ) =~ /ARRAY/;
    }
    else {
        $self->error_throw(
            "SNMP::Info::_set($attr,$val) - Failed. Invalid argument for attr."
        );
    }

    my $sess = $self->session();
    return unless defined $sess;

    my $funcs   = $self->funcs();
    my $globals = $self->globals();

    foreach my $var_list (@$varbind_list_ref) {
        my $list_attr = $var_list->[0];
        my $list_iid  = $var_list->[1];
        my $list_val  = $var_list->[2];

        # Get rid of non-printable chars in $list_val for debug statements
        $list_val =~ s/\W//;

        # Instance is 0 for scalars without a supplied instance
        $var_list->[1] = $list_iid = defined $list_iid ? $list_iid : '0';

        # Check if this method is from a sub or from the tables.
        if ( $self->can($list_attr) ) {
            $self->error_throw(
                "SNMP::Info::_set($list_attr,$list_val) - Failed. $list_attr is generated in a sub(). set_$list_attr sub required."
            );

            # if sub set_attr() existed, we wouldn't have gotten this far.
            return;
        }

        # Lookup oid
        my $oid = undef;
        $oid = $list_attr             if SNMP::translateObj($list_attr);
        $oid = $globals->{$list_attr} if defined $globals->{$list_attr};
        $oid = $funcs->{$list_attr}   if defined $funcs->{$list_attr};

        unless ( defined $oid ) {
            $self->error_throw(
                "SNMP::Info::_set($list_attr,$list_val) - Failed to find $list_attr in \%GLOBALS or \%FUNCS or loaded MIB."
            );
            return;
        }

        # Check for fully qualified attr
        if ( $oid =~ /__/ ) {
            $oid =~ s/__/::/;
            $oid =~ s/_/-/g;
        }

        $var_list->[0] = $oid;

        $self->debug()
            and print
            "SNMP::Info::_set $list_attr.$list_iid ($oid.$list_iid) = $list_val\n";
        delete $self->{"_$list_attr"};
    }

    my $rv = $sess->set($varbind_list_ref);

    if ( $sess->{ErrorStr} ) {
        $self->error_throw("SNMP::Info::_set $sess->{ErrorStr}");
        return;
    }

    return $rv;
}

=item $info->_make_setter(val,iid)

Used internally by AUTOLOAD to create dynamic methods from either %GLOBALS,
%FUNCS, or a valid mib leaf from a loaded MIB which runs an SNMP set command.  
When run clears the attribute cache.

Example:  $info->set_name('dog',3) dispatches to autoload to resolve to
$info->_set('name','dog',3) and _make_setter creates the set_name() method.

=cut

sub _make_setter {
    my $method = shift;
    my $oid    = shift;

    return sub {
        my $self = shift;
        my $val  = shift;
        my $iid  = shift;

        my $set_oid = $oid;
        my $globals = $self->globals();
        my $attr = $method;
        $attr =~ s/^set_//;
        
        # The only thing which may give us the iid in $oid should be
        # a %GLOBALS entry appended with a number.  In that case strip it
        # from the OID and use it as $iid
        if ( defined $globals->{$attr} && $globals->{$attr} =~ /(\.\d+$)/ ) {
            $iid = $1;
            $set_oid =~ s/$iid//;
        }

        # If we don't have $iid now we should be a %GLOBALS entry or single
        # instance MIB leaf so default to zero
        $iid = defined $iid ? $iid : '.0';

        # prepend dot if necessary to $iid
        $iid = ".$iid" unless $iid =~ /^\./;

        my $sess = $self->session();
        return unless defined $sess;

        $set_oid .= "$iid";

        $self->debug()
            and print "SNMP::Info::_set $method$iid ($set_oid) = $val\n";
        delete $self->{"_$attr"};

        my $rv = $sess->set( $set_oid, $val );

        if ( $sess->{ErrorStr} ) {
            $self->error_throw("SNMP::Info::_set $sess->{ErrorStr}");
            return;
        }
        return $rv;
    }
}

=item $info->set_multi(arrayref)

Used to run an SNMP set command on several new values in the one request.
Returns the result of $info->_set(method).

Pass either a reference to a 4 element array [<obj>, <iid>, <val>, <type>] or
a reference to an array of 4 element arrays to specify multiple values.

    <obj> - One of the following forms:
        1) leaf identifier (e.g., C<'sysContact'>)
        2) An entry in either %FUNCS, %GLOBALS (e.g., 'contact')
    <iid> - The dotted-decimal, instance identifier. For scalar MIB objects
             use '0'
    <val>  - The SNMP data value being set (e.g., 'netdisco')
    <type> - Optional as the MIB should be loaded.

If one of the set assignments is invalid, then the request will be rejected
without applying any of the new values - regardless of the order they appear
in the list.

Example:
    my $vlan_set = [
        ['qb_v_untagged',"$old_vlan_id","$old_untagged_portlist"],
        ['qb_v_egress',"$new_vlan_id","$new_egress_portlist"],
        ['qb_v_egress',"$old_vlan_id","$old_egress_portlist"],
        ['qb_v_untagged',"$new_vlan_id","$new_untagged_portlist"],
        ['qb_i_vlan',"$port","$new_vlan_id"],
    ];

    $info->set_multi($vlan_set);

=cut

sub set_multi {
    my $self = shift;

    return $self->_set(@_);
}

=item $info->load_all()

Debugging routine.  This does not include any overridden method or method
implemented by subroutine.

Runs $info->load_METHOD() for each entry in $info->funcs();

Returns $info->store() -- See store() entry.

Note return value has changed since version 0.3

=cut

sub load_all {
    my $self = shift;
    my $sess = $self->session();
    return unless defined $sess;

    my $funcs = $self->funcs();

    foreach my $attrib ( keys %$funcs ) {
        $attrib = "load_$attrib";
        $self->$attrib();
    }

    $self->{_all}++;

    return unless defined wantarray;

    return $self->store();
}

=item $info->all()

Runs $info->load_all() once then returns $info->store();

Use $info->load_all() to reload the data.

Note return value has changed since version 0.3

=cut

sub all {
    my $self = shift;
    my $sess = $self->session();
    return unless defined $sess;

    $self->load_all() unless defined $self->{_all};

    return $self->store();
}

=item $info->_load_attr()

Used internally by AUTOLOAD to create dynamic methods from %FUNCS 
or a MIB Leaf node name contained within a table of a loaded MIB.

Supports partial table fetches and single instance table fetches.
See L<SNMP::Info/"Partial Table Fetches">.

These methods return data as a reference to a hash.

=cut

sub _load_attr {
    my $method = shift;
    my $oid    = shift;

    return sub {
        my $self    = shift;
        my $partial = shift;

        my $sess = $self->session();
        return unless defined $sess;

        my $ver    = $self->snmp_ver();
        my $nosuch = $self->nosuch();
        my $store  = $self->store();

        my $load = $method =~ /^load/;
        my $raw  = $method =~ /raw$/;

        my $attr = $method;
        $attr =~ s/^(load|orig)_//;
        $attr =~ s/_raw$//;

        # Return cached data unless loading or partial
        # We now store in raw format so munge before returning
        # unless expecting raw data
        return $self->_show_attr($attr, $raw)
            if ( defined $self->{"_${attr}"}
            && !$load
            && !defined $partial );

        # We want the qualified leaf name so that we can
        # specify the Module (MIB) in the case of private leaf naming
        # conflicts.  Example: ALTEON-TIGON-SWITCH-MIB::agSoftwareVersion
        # and ALTEON-CHEETAH-SWITCH-MIB::agSoftwareVersion
        # Third argument to translateObj specifies the Module prefix
        
        my $qual_leaf = SNMP::translateObj($oid,0,1) || '';
        
        # We still want just the leaf since a SNMP get in the case of a
        # partial fetch may strip the Module portion upon return.  We need
        # the match to make sure we didn't leave the table during getnext
        # requests
        
        my ($leaf) = $qual_leaf =~ /::(\w+)$/;

        $self->debug()
            and print "SNMP::Info::_load_attr $method : $qual_leaf",
            defined $partial ? "($partial)" : '', " : $oid" ,
            defined $partial ? ".$partial" : '', "\n";

        my $var = new SNMP::Varbind( [$qual_leaf, $partial] );

        # So devices speaking SNMP v.1 are not supposed to give out
        # data from SNMP2, but most do.  Net-SNMP, being very precise
        # will tell you that the SNMP OID doesn't exist for the device.
        # They have a flag RetryNoSuch that is used for get() operations,
        # but not for getnext().  We set this flag normally, and if we're
        # using V1, let's try and fetch the data even if we get one of those.

        my $localstore = undef;
        my $errornum   = 0;
        my %seen       = ();

        my $vars = [];
        my $bulkwalk_no
            = $self->can('bulkwalk_no') ? $self->bulkwalk_no() : 0;
        my $bulkwalk_on = defined $self->{BulkWalk} ? $self->{BulkWalk} : 1;
        my $can_bulkwalk = $bulkwalk_on && !$bulkwalk_no;
        my $repeaters = $self->{BulkRepeaters} || $REPEATERS;
        my $bulkwalk = $can_bulkwalk && $ver != 1;
        my $loopdetect
            = defined $self->{LoopDetect} ? $self->{LoopDetect} : 1;

        if ( defined $partial ) {

            # Try a GET, in case the partial is a leaf OID.
            # Would like to only do this if we know the OID is
            # long enough; implementing that would require a
            # lot of MIB mucking.
            my $try = $sess->get($var);
            $errornum = $sess->{ErrorNum};
            if ( defined($try) && $errornum == 0 && $try !~ /^NOSUCH/ ) {
                $var->[2] = $try;
                $vars     = [$var];
                $bulkwalk = 1;        # fake a bulkwalk return
            }

            # We want to execute the while loop below for the getnext request.
            if (    $ver == 1
                and $sess->{ErrorNum}
                and $sess->{ErrorStr} =~ /nosuch/i )
            {
                $errornum = 0;
            }
        }

        # Use BULKWALK if we can because its faster
        if ( $bulkwalk && @$vars == 0 ) {
            ($vars) = $sess->bulkwalk( 0, $repeaters, $var );
            if ( $sess->{ErrorNum} ) {
                $self->error_throw(
                    "SNMP::Info::_load_atrr: BULKWALK " . $sess->{ErrorStr},
                    "\n" );
                return;
            }
        }

        while ( !$errornum ) {
            if ($bulkwalk) {
                $var = shift @$vars or last;
            }
            else {

                # GETNEXT instead of BULKWALK
                $sess->getnext($var);
                $errornum = $sess->{ErrorNum};
            }

            if ( $self->debug() > 1 ) {
                use Data::Dumper;
                print "SNMP::Info::_load_attr $method : leaf = $oid , var = ",
                    Dumper($var);
            }

            # Check if we've left the requested subtree
            last if $var->[0] !~ /$leaf$/;
            my $iid = $var->[1];
            my $val = $var->[2];

            unless ( defined $iid ) {
                $self->error_throw(
                    "SNMP::Info::_load_attr: $method not here");
                next;
            }

            # Check to make sure we are still in partial land
            if (    defined $partial
                and $iid !~ /^$partial$/
                and $iid !~ /^$partial\./ )
            {
                $self->debug()
                    and print "$iid makes us leave partial land.\n";
                last;
            }

           # Check if last element, V2 devices may report ENDOFMIBVIEW even if
           # instance or object doesn't exist.
            if ( $val eq 'ENDOFMIBVIEW' ) {
                last;
            }

            # Similarly for SNMPv1 - noSuchName return results in both $iid
            # and $val being empty strings.
            if ( $val eq '' and $iid eq '' ) {
                last;
            }

         # Another check for SNMPv1 - noSuchName return may results in an $iid
         # we've already seen and $val an empty string.  If we don't catch
         # this here we erronously report a loop below.
            if ( defined $seen{$iid} and $seen{$iid} and $val eq '' ) {
                last;
            }

            if ($loopdetect) {

                # Check to see if we've already seen this IID (looping)
                if ( defined $seen{$iid} and $seen{$iid} ) {
                    $self->error_throw("Looping on: $method iid:$iid. ");
                    last;
                }
                else {
                    $seen{$iid}++;
                }
            }

            if ( $val eq 'NOSUCHOBJECT' ) {
                $self->error_throw(
                    "SNMP::Info::_load_attr: $method :  NOSUCHOBJECT");
                next;
            }
            if ( $val eq 'NOSUCHINSTANCE' ) {
                $self->error_throw(
                    "SNMP::Info::_load_attr: $method :  NOSUCHINSTANCE");
                next;
            }

            $localstore->{$iid} = $val;

        }

        # Cache data if we are not getting partial data:
        if ( !defined $partial ) {
            $self->_cache($attr, $localstore);
        }

        # Data Munging
        if ( !$raw ) {
            $localstore = $self->_munge($attr, $localstore);
        }

        return $localstore;
    }
}

=item $info->_show_attr()

Used internally by AUTOLOAD to return data called by methods listed in %FUNCS.

=cut

sub _show_attr {
    my $self = shift;
    my $attr = shift;
    my $raw  = shift;

    my $store = $self->store();

    if ( !$raw ) {
        my $localstore = $store->{$attr};
        return $self->_munge($attr, $localstore);
    }
    else {
        return $store->{$attr};
    }
}

=item $info->snmp_connect_ip(ip) 

Returns true or false based upon snmp connectivity to an IP.

=cut

sub snmp_connect_ip {
    my $self = shift;
    my $ip   = shift;
    my $ver  = $self->snmp_ver();
    my $comm = $self->snmp_comm();

    return if ( $ip eq '0.0.0.0' ) or ( $ip =~ /^127\./ );

    # Create session object
    my $snmp_test = new SNMP::Session(
        'DestHost'  => $ip,
        'Community' => $comm,
        'Version'   => $ver
    );

    # No session object created
    unless ( defined $snmp_test ) {
        return;
    }

    # Session object created but SNMP connection failed.
    my $sess_err = $snmp_test->{ErrorStr} || '';
    if ($sess_err) {
        return;
    }

    # Try to get some data from IP
    my $layers = $snmp_test->get('sysServices.0');

    $sess_err = $snmp_test->{ErrorStr} || '';
    if ($sess_err) {
        return;
    }

    return 1;

}

=item modify_port_list(portlist,offset,replacement)

Replaces the specified bit in a port_list array and
returns the packed bitmask 

=cut

sub modify_port_list {
    my ( $self, $portlist, $offset, $replacement ) = @_;

    print "Original port list: @$portlist \n" if $self->debug();
    @$portlist[$offset] = $replacement;

    # Some devices do not populate the portlist with all possible ports.
    # If we have lengthened the list fill all undefined elements with zero.
    foreach my $item (@$portlist) {
        $item = '0' unless ( defined($item) );
    }
    print "Modified port list: @$portlist \n" if $self->debug();

    return pack( "B*", join( '', @$portlist ) );
}

=item $info->_cache(attr, data)

Cache retrieved data so that if it's asked for again, we use the cache instead
of going back to Net-SNMP. Data is cached inside the blessed hashref C<$self>.

Accepts the leaf and value (scalar, or hashref for a table). Does not return
anything useful.

=cut

sub _cache {
    my $self = shift;
    my ($attr, $data) = @_;
    my $store = $self->store();

    if (ref {} eq ref $data) {
        $self->{"_${attr}"}++;
        $store->{$attr} = $data;
    }
    else {
        $self->{"_$attr"} = $data;
    }
}

=item $info->_munge(attr, data)

Raw data returned from Net-SNMP might not be formatted correctly or might have
platform-specific bugs or mistakes. The MUNGE feature of SNMP::Info allows for
fixups to take place.

Accepts the leaf and value (scalar, or hashref for a table) and returns the raw
or the munged data, as appropriate. That is, you do not need to know whether
MUNGE is installed, and it's safe to call this method regardless.

=cut

sub _munge {
    my $self = shift;
    my ($attr, $data) = @_;
    my $munge = $self->munge();

    return $data unless defined $munge->{$attr};

    if (ref {} eq ref $data) {
        my $subref = $munge->{$attr};
        my %munged;
        foreach my $key ( keys %$data ) {
            my $value = $data->{$key};
            next unless $value;
            $munged{$key} = $subref->($value);
        }
        return \%munged;
    }
    else {
        return unless $data;
        my $subref = $munge->{$attr};
        return $subref->($data);
    }
}

=item _validate_autoload_method(method)

Used internally by AUTOLOAD to validate that a dynamic method should be
created.  Returns the OID of the MIB leaf node the method will get or set.

=over 

=item 1. Returns unless method is listed in %FUNCS, %GLOBALS, or is MIB Leaf
node name in a loaded MIB for given class.

=item 2. Translates the MIB Leaf node name to an OID.

=item 3. Checks to see if the method access type is allowed for the resolved
OID.  Write access for set_ methods, read access for others.

=back

=cut

sub _validate_autoload_method {
    my $self   = shift;
    my $method = shift;

    my $setter = $method =~ /^set/;
    my $attr = $method;
    $attr =~ s/^(load|set|orig)_//;
    $attr =~ s/_raw$//;

    my $globals = $self->globals();
    my $funcs   = $self->funcs();

    my $leaf_name = $globals->{$attr} || $funcs->{$attr} || $attr;

    # Check for fully qualified name
    if ( $leaf_name =~ /__/ ) {
        $leaf_name =~ s/__/::/;
        $leaf_name =~ s/_/-/g;
    }

    # Translate MIB leaf node name to OID
    my $oid = SNMP::translateObj($leaf_name);

    if ( $leaf_name =~ /^[.]?\d[\.\d]+$/ ) {
        $oid = $leaf_name;
    }

    unless ( defined $oid ) {
        print
            "SNMP::Info::_validate_autoload_method($leaf_name) Unable to resolve method.\n"
            if $self->debug();
        return;
    }

    # Validate that we have proper access for the operation
    my $access = $SNMP::MIB{$oid}{'access'} || '';

    # If we were given a fully qualified OID because we don't have the MIB
    # file, it will translate above but we won't be able to check access so
    # skip the check and return
    if ($access) {
        unless ( ( $method =~ /^set/ && $access =~ /Write|Create/ )
            || $access =~ /Read|Create/ )
        {
            print
                "SNMP::Info::_validate_autoload_method($attr : $oid) Not accessable for requested operation.\n"
                if $self->debug();
            return;
        }
    }

    # If the parent of the leaf has indexes it is contained within a table
    my $indexes    = $SNMP::MIB{$oid}{'parent'}{'indexes'};
    my $table_leaf = 0;

    if ( !$globals->{$attr}
        && ( defined $indexes && scalar( @{$indexes} ) > 0 ) )
    {
        $table_leaf = 1;
    }

    # Tag on .0 for %GLOBALS and single instance MIB leafs unless
    # the leaf ends in a digit or we are going to use for a set operation
    if ( $table_leaf == 0 && ( $globals->{$attr} || $leaf_name ne $oid ) ) {

        unless ( $leaf_name =~ /\d$/ || $setter ) {
            $oid .= ".0";
        }
    }

    my $return = [ $oid, $table_leaf ];
    return $return;
}

=item $info->can()

Overrides UNIVERSAL::can() so that objects will correctly report their
capabilities to include dynamic methods generated at run time via AUTOLOAD.

Calls parent can() first to see if method exists, if not validates that a
method should be created then dispatches to the appropriate internal method
for creation.  The newly created method is inserted into the symbol table
returning to AUTOLOAD only for the initial method call.

Returns undef if the method does not exist and can not be created.

=cut

sub can {
    my $self   = shift;
    my $method = shift;

    # use results of parent can()
    return $self->SUPER::can($method) if $self->SUPER::can($method);

    my $validated = $self->_validate_autoload_method($method);
    return unless $validated;

    my ($oid, $table) = @$validated;

    # _validate_autoload_method validates, so we need to check for
    # set_ , funcs, table leafs, and everything else goes to _global
    my $funcs = $self->funcs();

    # We need to resolve funcs with a prefix or suffix
    my $f_method = $method;
    $f_method =~ s/^(load|orig)_//;
    $f_method =~ s/_raw$//;

    no strict 'refs';    ## no critic (ProhibitNoStrict )

    # Check for set_ ing.
    if ( $method =~ /^set_/ ) {
        return *{$AUTOLOAD} = _make_setter( $method, $oid, @_ );
    }
    elsif ( defined $funcs->{$f_method} || $table ) {
        return *{$AUTOLOAD} = _load_attr( $method, $oid, @_ );
    }
    else {
        return *{$AUTOLOAD} = _global( $method, $oid );
    }
}

=back

=head2 AUTOLOAD

Each entry in either %FUNCS, %GLOBALS, or MIB Leaf node names present in
loaded MIBs are used by AUTOLOAD() to create dynamic methods.  Generated
methods are inserted into the symbol table so that subsequent calls can avoid
AUTOLOAD() and dispatch directly.

=over 

=item 1. Returns unless method is listed in %FUNCS, %GLOBALS, or is a MIB
Leaf node name in a loaded MIB for given class.

=item 2. If the method exists in %GLOBALS or is a single instance MIB Leaf
node name from a loaded MIB, _global() generates the method. 

=item 3. If a set_ prefix is present _make_setter() generates the method.

=item 4. If the method exists in %FUNCS or is a MIB Leaf node name contained
within a table from a loaded MIB, _load_attr() generates the method.

=item 5. A load_ prefix forces reloading of data and does not use cached data.

=item 6. A _raw suffix returns data ignoring any munge routines.

=back

Override any dynamic method listed in %GLOBALS, %FUNCS, or MIB Leaf node
name a by creating a subroutine with the same name.

For example to override $info->name() create `` sub name {...}'' in your
subclass.

=cut

sub AUTOLOAD {
    my $self = shift;
    my ($sub_name) = $AUTOLOAD =~ /::(\w+)$/;

    return if $sub_name =~ /DESTROY$/;

    # Typos in function calls in SNMP::Info subclasses turn into
    # AUTOLOAD requests for non-methods.  While this is deprecated,
    # we'll still get called, so report a less confusing error.
    if ( ref($self) !~ /^SNMP::Info/ ) {

        # croak reports one level too high.  die reports here.
        # I would really like to get the place that's likely to
        # have the typo, but perl doesn't want me to.
        croak(
            "SNMP::Info::AUTOLOAD($AUTOLOAD) called with no class (probably typo of function call to $sub_name)"
        );
    }

    # This enables us to use SUPER:: for AUTOLOAD methods as well
    # as the true OO methods.  Method needs to be renamed to prevent
    # namespace collision when we insert into the symbol table later.
    if ( $AUTOLOAD =~ /SUPER::$sub_name$/ ) {
        $AUTOLOAD =~ s/SUPER::$sub_name/orig_$sub_name/;
        $sub_name = "orig_$sub_name";
    }

    return unless my $meth_ref = $self->can($sub_name, @_);
    return $self->$meth_ref(@_);

}

1;

=head1 COPYRIGHT AND LICENSE

Changes from SNMP::Info Version 0.7 and on are:
Copyright (c) 2003-2010 Max Baker and SNMP::Info Developers
All rights reserved.

Original Code is:
Copyright (c) 2002-2003, Regents of the University of California
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the University of California, Santa Cruz nor the 
      names of its contributors may be used to endorse or promote products 
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
