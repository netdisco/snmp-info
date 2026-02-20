# SNMP::Info::Layer7::Stormshield
#
# Copyright (c) 2025 snmp-info Developers
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

package SNMP::Info::Layer7::Stormshield;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer7;
use Data::Dumper;

@SNMP::Info::Layer7::Stormshield::ISA       = qw/SNMP::Info::Layer7 Exporter/;
@SNMP::Info::Layer7::Stormshield::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.975000';

%MIBS = (
    %SNMP::Info::Layer7::MIBS,
    'STORMSHIELD-HA-MIB'     => 'snsFwSerial',
    'STORMSHIELD-IF-MIB'     => 'snsifUserName',
    'STORMSHIELD-PROPERTY-MIB' => 'snsSerialNumber',
);


# use qualified names to avoid leaf conflicts. There is PROPERTY, HA and some DEPRECATED mibs
# with identical symbols 

%GLOBALS = (
    %SNMP::Info::Layer7::GLOBALS,
    'propmib_serial'   => 'STORMSHIELD_PROPERTY_MIB__snsSerialNumber',
    'propmib_model'    => 'STORMSHIELD_PROPERTY_MIB__snsModel',
    'propmib_version'  => 'STORMSHIELD_PROPERTY_MIB__snsVersion',
    'propmib_systemname'  => 'STORMSHIELD_PROPERTY_MIB__snsSystemName',
);

%FUNCS = (
    %SNMP::Info::Layer7::FUNCS,
    # HA MIB
    'hamib_serial' => 'STORMSHIELD_HA_MIB__snsFwSerial',
    'hamib_model'  => 'STORMSHIELD_HA_MIB__snsModel', 
    'hamib_version' => 'STORMSHIELD_HA_MIB__snsVersion',
    'hamib_halicense' => 'STORMSHIELD_HA_MIB__snsHALicence',
    # can't use, MAX-ACCESS	not-accessible
    #'hamib_nodeindex' => 'STORMSHIELD_HA_MIB__snsNodeIndex',

    # use STORMSHIELD_IF_MIB
    # it uses different indexes than ifXEntry so we need to take care
    # of not mixing things up. 
    'ifmib_interfaces' => 'STORMSHIELD_IF_MIB__snsifDrvName',
    'i_name' => 'STORMSHIELD_IF_MIB__snsifName',
    'i_alias' => 'STORMSHIELD_IF_MIB__snsifName',
    'i_description' => 'STORMSHIELD_IF_MIB__snsifUserName',
    'i_type' => 'STORMSHIELD_IF_MIB__snsifType',
    'i_index' => 'STORMSHIELD_IF_MIB__snsifIndex',

    # regular interface tables
    '_mib2_i_description' => 'IF-MIB__ifDescr',

    );

%MUNGE = (
    %SNMP::Info::Layer7::MUNGE
    );

sub _ifindex_conversion {
  my $Stormshield = shift;

  # return a table that maps ifTable indexes to snsifTable indexes, so we can look up STORMSHIELD_IF_MIB data using standard IF-MIB indexes

  # .iso.org.dod.internet.private.enterprises.stormshield.stormshieldMIB.snsif.snsifTable.snsifEntry.snsifDrvName.1 = STRING: "tun0"
  # .iso.org.dod.internet.private.enterprises.stormshield.stormshieldMIB.snsif.snsifTable.snsifEntry.snsifDrvName.4 = STRING: "igc7"
  # .iso.org.dod.internet.private.enterprises.stormshield.stormshieldMIB.snsif.snsifTable.snsifEntry.snsifDrvName.5 = STRING: "igc6"

  # .iso.org.dod.internet.mgmt.mib-2.interfaces.ifTable.ifEntry.ifDescr.7 = STRING: "igc6"
  # .iso.org.dod.internet.mgmt.mib-2.interfaces.ifTable.ifEntry.ifDescr.8 = STRING: "igc7"
  # .iso.org.dod.internet.mgmt.mib-2.interfaces.ifTable.ifEntry.ifDescr.12 = STRING: "tun0"

  my $snsif = $Stormshield->ifmib_interfaces() || {};
  my $mib2if_desc = $Stormshield->_mib2_i_description() || {};
  my $mib2if = {reverse %$mib2if_desc};
  my $map_m2s = {};

  foreach my $si ( keys %$snsif ) {
    my $sv = $snsif->{$si};
    my $mib_index = $mib2if->{$sv};
    if (defined $mib_index) {
      $map_m2s->{$mib_index} = $si;
    }
  }

  # now for e.g. ifDescr.8 (igc7):
  # this will return $map_m2s->{8} = 4, the STORMSHIELD_IF_MIB index for igc7
  return $map_m2s;
}

sub _map_table {
  # get STORMSHIELD_IF_MIB data and map it to standard IF-MIB indexes
  my ($Stormshield, $snsif_method) = @_;
  my $map_m2s = $Stormshield->_ifindex_conversion();
  
  # Map method names to their SNMP attribute names
  my %method_to_attr = (
    'i_name' => 'snsifName',
    'i_alias' => 'snsifName', 
    'i_description' => 'snsifUserName',
    'i_type' => 'snsifType',
    'i_index' => 'snsifIndex',
  );
  
  my $attr_name = $method_to_attr{$snsif_method};
  
  # Get the raw SNMP data by calling the attribute method directly
  my $snsif_data = {};
  if ($attr_name && $Stormshield->can($attr_name)) {
    $snsif_data = $Stormshield->$attr_name() || {};
  }
  
  my $out = {};

  foreach my $mib_index ( keys %$map_m2s ) {
    my $snsif_index = $map_m2s->{$mib_index};
    $out->{$mib_index} = $snsif_data->{$snsif_index};
  }
  return $out;
}


sub vendor {
    return 'stormshield';
}

sub os {
    return 'SNS';
}

sub name {
    my $Stormshield = shift;
    return $Stormshield->propmib_systemname() || $Stormshield->SUPER::name();
}

sub serial {

  my $Stormshield = shift;
  return $Stormshield->propmib_serial() // '';
}


sub model {
  my $Stormshield = shift;
  return $Stormshield->propmib_model() // '';
}


sub os_ver {
  my $Stormshield = shift;
  return $Stormshield->propmib_version() // '';
}


sub e_index {

  my $Stormshield = shift;
  my $hamib_serials = $Stormshield->hamib_serial() || ();
  my %e_index;
  foreach my $iid (keys %$hamib_serials) {
    $e_index{$iid} = $iid;
  }

  return \%e_index;
}

sub e_class {

  my $Stormshield = shift;
  my $hamib_serials = $Stormshield->hamib_serial() || ();
  my %e_index;
  foreach my $iid (keys %$hamib_serials) {
    $e_index{$iid} = "chassis";
  }

  return \%e_index;
}

sub e_name {

  my $Stormshield = shift;
  my $hamib_serials = $Stormshield->hamib_serial() || ();
  my %e_index;
  foreach my $iid (keys %$hamib_serials) {
    $e_index{$iid} = "chassis." . $iid;
  }

  return \%e_index;
}

sub e_vendor {

  my $Stormshield = shift;
  my $hamib_serials = $Stormshield->hamib_serial() || ();
  my %e_index;
  foreach my $iid (keys %$hamib_serials) {
    $e_index{$iid} = $Stormshield->vendor();
  }

  return \%e_index;
}

sub e_descr {

  my $Stormshield = shift;
  my $hamib_models = $Stormshield->hamib_model() || ();
  my $hamib_halicense = $Stormshield->hamib_halicense() || ();
  my $hamib_serials = $Stormshield->hamib_serial() || ();
  my $hamib_version = $Stormshield->hamib_version() || ();
  my %e_index;
  foreach my $iid (keys %$hamib_models) {
    $e_index{$iid} = $hamib_models->{$iid} . " " . $hamib_halicense->{$iid} . " " . $hamib_serials->{$iid} . " " . $hamib_version->{$iid};
  }

  return \%e_index;
}

sub e_model {

  my $Stormshield = shift;
  my $hamib_models = $Stormshield->hamib_model() || ();
  my %e_index;
  foreach my $iid (keys %$hamib_models) {
    $e_index{$iid} = $hamib_models->{$iid};
  }

  return \%e_index;
}

sub e_swver {

  my $Stormshield = shift;
  my $hamib_version = $Stormshield->hamib_version() || ();
  my %e_index;
  foreach my $iid (keys %$hamib_version) {
    $e_index{$iid} = $hamib_version->{$iid};
  }

  return \%e_index;
}


sub e_serial {

  my $Stormshield = shift;
  my $hamib_serials = $Stormshield->hamib_serial() || ();
  my %e_index;
  foreach my $iid (keys %$hamib_serials) {
    $e_index{$iid} = $hamib_serials->{$iid};
  }

  return \%e_index;
}

# Interface methods - all grouped together
sub interfaces {
  # return standard IF-MIB interface names keyed by standard IF-MIB indexes
  my $Stormshield = shift;
  return $Stormshield->_mib2_i_description();
}


# STORMSHIELD_IF_MIB specific methods that map to standard IF-MIB indexes
sub i_name {
  my $Stormshield = shift;
  return $Stormshield->_map_table('i_name');
}

sub i_alias {
  my $Stormshield = shift;
  return $Stormshield->_map_table('i_alias');
}

sub i_description {
  my $Stormshield = shift;
  return $Stormshield->_map_table('i_description');
}

sub i_type {
  my $Stormshield = shift;
  return $Stormshield->_map_table('i_type');
}

sub i_index {
  my $Stormshield = shift;
  return $Stormshield->_map_table('i_index');
}

1;

__END__

=head1 NAME

SNMP::Info::Layer7::Stormshield - SNMP Interface to Stormshield Network Security appliances

=head1 AUTHORS

Rob Woodward

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $Stormshield = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myfirewall',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $Stormshield->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Stormshield Network Security (SNS) appliances

The module supports both High Availability (HA) and non-HA Stormshield
appliances.

- Scalar globals such as serial number, model and OS version are retrieved
  from C<STORMSHIELD-PROPERTY-MIB>.
- Since ENTITY-MIB is not available on the device, a set of C<e_*> methods is
  provided based on C<STORMSHIELD-HA-MIB> tables to approximate ENTITY-like
  information for HA nodes.

=head2 High Availability (HA) Devices (HA-derived e_* methods)

For HA devices, the module uses the C<STORMSHIELD-HA-MIB> to build
ENTITY-like methods:

=over

=item Serial Number table: C<snsFwSerial> (.1.3.6.1.4.1.11256.1.11.7.1.2)

=item Model table: C<snsModel> (.1.3.6.1.4.1.11256.1.11.7.1.4)

=item Version table: C<snsVersion> (.1.3.6.1.4.1.11256.1.11.7.1.5)

=item HA license table: C<snsHALicence> (.1.3.6.1.4.1.11256.1.11.7.1.6)

=back

Note: While C<snsNodeIndex> exists in the HA MIB, it is C<MAX-ACCESS
not-accessible> and cannot be fetched directly; the C<e_index> method uses the
row indices of the HA tables (e.g., C<snsFwSerial>) as identity mapping.

Example SNMP walk for model:
 snmpwalk -v2c -On .1.3.6.1.4.1.11256.1.11.7.1.4
 .1.3.6.1.4.1.11256.1.11.7.1.4.0 = STRING: "SN-S-Series-220"
 .1.3.6.1.4.1.11256.1.11.7.1.4.1 = STRING: "SN-S-Series-220"

=head2 Non-HA Devices (Property MIB globals)

The module uses the C<STORMSHIELD-PROPERTY-MIB> for single nodes or the primary cluster node:

=over

=item Serial Number: C<snsSerialNumber> (.1.3.6.1.4.1.11256.1.18.3)

=item Model: C<snsModel> (.1.3.6.1.4.1.11256.1.18.1)

=item Version: C<snsVersion> (.1.3.6.1.4.1.11256.1.18.2)

=back

Example SNMP walk for model:
 snmpwalk -v2c -On .1.3.6.1.4.1.11256.1.18
 .1.3.6.1.4.1.11256.1.18.1.0 = STRING: "SN-S-Series-220"

=head2 Inherited Classes

=over

=item SNMP::Info::Layer7

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer7> for its own MIB requirements.

=item STORMSHIELD-HA-MIB

Required for High Availability (HA) Stormshield appliances.

=item STORMSHIELD-PROPERTY-MIB

Required for both single nodes and clusters.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $Stormshield->vendor()

Returns 'stormshield'.

=item $Stormshield->name()

Returns snsProductProperty.snsSystemName if available, regular sysName otherwise

=item $Stormshield->os()

Returns 'SNS'.

=item $Stormshield->os_ver()

Release extracted from C<STORMSHIELD-PROPERTY-MIB>.

=item $Stormshield->model()

Model extracted from C<STORMSHIELD-PROPERTY-MIB>.

=item $Stormshield->serial()

Returns serial number extracted from C<STORMSHIELD-PROPERTY-MIB>.

=back

=head2 Globals imported from SNMP::Info::Layer7

See documentation in L<SNMP::Info::Layer7> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $Stormshield->e_index()

Returns an identity mapping of HA node row indices inferred from
C<STORMSHIELD-HA-MIB> tables; key = iid, value = iid.

=item $Stormshield->e_class()

Returns reference to hash: key = iid, value = 'chassis'.

=item $Stormshield->e_name()

Returns reference to hash: key = iid, value = 'chassis.<iid>'.

=item $Stormshield->e_vendor()

Returns reference to hash: key = iid, value = 'stormshield'.

=item $Stormshield->e_descr()

Returns reference to hash: key = iid, value = '<model> <licence> <serial> <version>'
assembled from HA tables: C<snsModel>, C<snsHALicence>, C<snsFwSerial>, and
C<snsVersion>.

=item $Stormshield->e_model()

Returns reference to hash: key = iid, value = model (from C<snsModel>).

=item $Stormshield->e_swver()

Returns reference to hash: key = iid, value = software version (from
C<snsVersion>).

=item $Stormshield->e_serial()

Returns reference to hash: key = iid, value = serial (from C<snsFwSerial>).

=item $Stormshield->interfaces()

Override interface details with STORMSHIELD_IF_MIB

=back

=head2 Overrides

=over

=item $Stormshield->i_name()

Returns reference to hash: key = ifIndex, value = interface name from STORMSHIELD_IF_MIB.

=item $Stormshield->i_alias()

Returns reference to hash: key = ifIndex, value = interface alias from STORMSHIELD_IF_MIB.

=item $Stormshield->i_description()

Returns reference to hash: key = ifIndex, value = interface description from STORMSHIELD_IF_MIB.

=item $Stormshield->i_type()

Returns reference to hash: key = ifIndex, value = interface type from STORMSHIELD_IF_MIB.

=item $Stormshield->i_index()

Returns reference to hash: key = ifIndex, value = interface index from STORMSHIELD_IF_MIB.

=back

=head2 Table Methods imported from SNMP::Info::Layer7

See documentation in L<SNMP::Info::Layer7> for details.

=cut
