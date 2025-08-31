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

$VERSION = '3.972002';

%MIBS = (
    %SNMP::Info::Layer7::MIBS,
    'STORMSHIELD-HA-MIB'     => 'snsFwSerial',
    'STORMSHIELD-PROPERTY-MIB' => 'snsSerialNumber',
);


# use qualified names to avoid leaf conflicts. There is PROPERTY, HA and some DEPRECATED mibs
# with identical symbols 

%GLOBALS = (
    %SNMP::Info::Layer7::GLOBALS,
    'propmib_serial'   => 'STORMSHIELD_PROPERTY_MIB__snsSerialNumber',
    'propmib_model'    => 'STORMSHIELD_PROPERTY_MIB__snsModel',
    'propmib_version'  => 'STORMSHIELD_PROPERTY_MIB__snsVersion',
);

%FUNCS = (
    %SNMP::Info::Layer7::FUNCS,
    # HA MIB
    'hamib_serial' => 'STORMSHIELD_HA_MIB__snsFwSerial',
    'hamib_model'  => 'STORMSHIELD_HA_MIB__snsModel', 
    'hamib_version' => 'STORMSHIELD_HA_MIB__snsVersion',
    );

%MUNGE = (
    %SNMP::Info::Layer7::MUNGE,
    );

sub vendor {
    return 'stormshield';
}

sub os {
    return 'SNS';
}

sub serial {

  my $Stormshield = shift;
  my $hamib_serial = $Stormshield->hamib_serial();
  my $propmib_serial = $Stormshield->propmib_serial();

  # Collect serials preserving HA MIB order
  my %unique_serials;
  my @serials;
  my %seen;
  
  if (ref($hamib_serial) eq 'HASH') {
    foreach my $key (sort keys %$hamib_serial) {
      my $value = $hamib_serial->{$key};
      push @serials, $value unless $seen{$value}++;
    }
  } else {
    push @serials, $hamib_serial unless $seen{$hamib_serial}++;
  }
  
  # Add Property MIB serials (avoiding duplicates)
  if (ref($propmib_serial) eq 'HASH') {
    foreach my $value (values %$propmib_serial) {
      push @serials, $value unless $seen{$value}++;
    }
  } else {
    push @serials, $propmib_serial unless $seen{$propmib_serial}++;
  }

  my $serial = join(' ', grep { defined && length } @serials);
  return $serial;
}



sub model {

  my $Stormshield = shift;
  my $hamib_model = $Stormshield->hamib_model();
  my $propmib_model = $Stormshield->propmib_model();

  my @models;
  my %seen;
  
  # Collect unique models preserving HA MIB order
  if (ref($hamib_model) eq 'HASH') {
    foreach my $key (sort keys %$hamib_model) {
      my $value = $hamib_model->{$key};
      push @models, $value unless $seen{$value}++;
    }
  } else {
    push @models, $hamib_model unless $seen{$hamib_model}++;
  }
  
  # Add Property MIB model
  if (ref($propmib_model) eq 'HASH') {
    foreach my $value (values %$propmib_model) {
      push @models, $value unless $seen{$value}++;
    }
  } else {
    push @models, $propmib_model unless $seen{$propmib_model}++;
  }
  
  my $model = join(' ', grep { defined && length } @models);
  return $model;
}

sub os_ver {

  my $Stormshield = shift;
  my $hamib_version = $Stormshield->hamib_version();
  my $propmib_version = $Stormshield->propmib_version();

  my @versions;
  my %seen;
  
  # Collect unique versions preserving HA MIB order
  if (ref($hamib_version) eq 'HASH') {
    foreach my $key (sort keys %$hamib_version) {
      my $value = $hamib_version->{$key};
      push @versions, $value unless $seen{$value}++;
    }
  } else {
    push @versions, $hamib_version unless $seen{$hamib_version}++;
  }
  
  # Add Property MIB version
  if (ref($propmib_version) eq 'HASH') {
    foreach my $value (values %$propmib_version) {
      push @versions, $value unless $seen{$value}++;
    }
  } else {
    push @versions, $propmib_version unless $seen{$propmib_version}++;
  }
  
  my $os_ver = join(' ', grep { defined && length } @versions);
  return $os_ver;
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

The module supports both High Availability (HA) and non-HA Stormshield appliances. The information retrieved can be different based on whether the device is a HA or non-HA device.

=head2 High Availability (HA) Devices

For HA devices, the module uses the STORMSHIELD-HA-MIB:

=over

=item Serial Number: C<snsFwSerial> (.1.3.6.1.4.1.11256.1.11.7.1.2)

=item Model: C<snsModel> (.1.3.6.1.4.1.11256.1.11.7.1.4)

=item Version: C<snsVersion> (.1.3.6.1.4.1.11256.1.11.7.1.5)

=back

Example SNMP walk for model:
 snmpwalk -v2c -On .1.3.6.1.4.1.11256.1.11.7.1.4
 .1.3.6.1.4.1.11256.1.11.7.1.4.0 = STRING: "SN-S-Series-220"
 .1.3.6.1.4.1.11256.1.11.7.1.4.1 = STRING: "SN-S-Series-220"

=head2 Non-HA Devices

For non-HA devices, the module uses the STORMSHIELD-PROPERTY-MIB:

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

Required for non-HA Stormshield appliances.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $Stormshield->vendor()

Returns 'stormshield'.

=item $Stormshield->os()

Returns 'SNS'.

=item $Stormshield->os_ver()

Release extracted from Stormshield MIBs (HA or Property MIB).

=item $Stormshield->model()

Model extracted from Stormshield MIBs (HA or Property MIB).

=item $Stormshield->serial()

Returns serial number extracted from Stormshield MIBs (HA or Property MIB).

=back

=head2 Globals imported from SNMP::Info::Layer7

See documentation in L<SNMP::Info::Layer7> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer7

See documentation in L<SNMP::Info::Layer7> for details.

=cut
