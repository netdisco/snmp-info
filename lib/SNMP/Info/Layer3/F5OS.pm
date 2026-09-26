package SNMP::Info::Layer3::F5OS;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::F5OS::ISA       =
    qw/SNMP::Info::Layer3 SNMP::Info::LLDP Exporter/;
@SNMP::Info::Layer3::F5OS::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %FUNCS, %MIBS, %MUNGE);

$VERSION = '3.977001';


# ------------------------------------------------------------------------
# MIB definitions
# ------------------------------------------------------------------------
#
# F5OS exposes only a subset of the networking information normally
# expected from a Layer3 device.
#
# In particular, the tested F5OS SNMP agents do not implement:
#
#   - IP-MIB address tables
#   - ipNetToMediaTable / ipNetToPhysicalTable
#   - IEEE8023-LAG-MIB aggregation membership
#   - standard VLAN-to-interface membership tables
#
# F5-OS-TENANT-MIB::tenantVlansTable does expose VLAN IDs assigned to
# tenants, but it does not provide the interface/LAG membership required
# by SNMP::Info's normal VLAN model. It is therefore intentionally not
# used here.
#
# F5-PLATFORM-STATS-MIB is used to construct ENTITY-MIB compatible
# inventory information for the chassis, power supplies and disks.
#

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::LLDP::MIBS,

    'F5-OS-SYSTEM-MIB'      => 'serialNumber',
    'F5-OS-LLDP-MIB'        => 'lldpSystemId',
    'F5-PLATFORM-STATS-MIB' => 'model',
);


%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,

    # Chassis serial number reported by F5OS.
    'f5_serial' => 'serialNumber',

    # F5OS does not expose the local chassis identifier through the
    # standard LLDP-MIB objects expected by SNMP::Info. Use the
    # vendor-specific F5-OS-LLDP-MIB::lldpSystemId instead.
    'serial1' => 'lldpSystemId',
);


%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,

    # F5-OS-LLDP-MIB::lldpNeighborsTable
    'f5_lldp_local_if'    => 'lldpLocalInterface',
    'f5_lldp_rem_port'    => 'lldpNeighborPortId',
    'f5_lldp_rem_chassis' => 'lldpNeighborChassisId',
    'f5_lldp_rem_pdesc'   => 'lldpNeighborPortDesc',
    'f5_lldp_rem_name'    => 'lldpNeighborSysName',
    'f5_lldp_rem_desc'    => 'lldpNeighborSysDesc',
    'f5_lldp_rem_cap'     => 'lldpNeighborSysCap',
    'f5_lldp_rem_ip'      => 'lldpNeighborMgmtAddr',
    'f5_lldp_rem_model'   => 'lldpNeighborF5ProductModel',

    # F5-PLATFORM-STATS-MIB::componentInfoTable
    'f5_component_serial' => 'serialNo',
    'f5_component_model'  => 'model',

    # F5-PLATFORM-STATS-MIB::psuStatsTable
    'f5_psu_name'         => 'psuName',
    'f5_psu_serial'       => 'psuSerialNo',
    'f5_psu_part'         => 'psuPartNo',

    # F5-PLATFORM-STATS-MIB::diskInfoTable
    'f5_disk_name'        => 'diskName',
    'f5_disk_model'       => 'diskModel',
    'f5_disk_vendor'      => 'diskVendor',
    'f5_disk_version'     => 'diskVersion',
    'f5_disk_serial'      => 'diskSerialNo',
    'f5_disk_size'        => 'diskSize',
    'f5_disk_type'        => 'diskType',
);


%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
);


# ------------------------------------------------------------------------
# Device information
# ------------------------------------------------------------------------

sub vendor {
    return 'f5';
}


sub os {
    return 'f5os';
}


sub model {
    my $f5 = shift;

    # componentInfoTable uses a DisplayString as its index. The platform
    # entry represents the chassis itself and contains the F5OS hardware
    # model (for example "r2600" or "r12900-DS").
    #
    # Do not simply return the first populated model from the table:
    # additional component types may gain model information in future
    # F5OS releases.
    my $models = $f5->f5_component_model() || {};

    foreach my $iid (keys %$models) {
        my ($name) = _f5_decode_string_indexes($iid);

        next unless defined $name && $name eq 'platform';

        my $model = $models->{$iid};
        return $model if defined $model && $model ne '';
    }

    # Fall back to the model derived from sysObjectID if the platform
    # component is unavailable.
    my $id = $f5->id();
    my $model = &SNMP::translateObj($id);

    return defined $model ? $model : $id;
}


sub os_ver {
    my $f5 = shift;

    my $version = $f5->f5os_version();

    return unless defined $version;

    # sysDescr may contain additional text after the semantic version.
    # Netdisco only needs the F5OS version itself.
    if ($version =~ /^(\d+\.\d+\.\d+)/) {
        return $1;
    }

    return $version;
}


sub f5os_version {
    my $f5 = shift;

    my $descr = $f5->description();

    return unless defined $descr;

    # F5OS exposes the appliance services version through sysDescr rather
    # than through a dedicated scalar in the tested SNMP implementation.
    if ($descr =~ /Appliance services version\s+([^\s]+)/i) {
        return $1;
    }

    return;
}


sub serial {
    my $f5 = shift;

    # Use F5-OS-SYSTEM-MIB::serialNumber as the authoritative hardware
    # serial number. The separate serial1() value is sourced from
    # F5-OS-LLDP-MIB::lldpSystemId and is used by SNMP::Info as the local
    # LLDP chassis identifier.
    return $f5->f5_serial();
}


# ------------------------------------------------------------------------
# Interfaces
# ------------------------------------------------------------------------

sub interfaces {
    my $f5      = shift;
    my $partial = shift;

    my $i_index = $f5->i_index($partial) || {};
    my $i_name  = $f5->i_name($partial)  || {};

    my %if;

    foreach my $iid (keys %$i_index) {
        my $index = $i_index->{$iid};
        next unless defined $index;

        my $name = $i_name->{$iid};

        # F5OS provides useful interface names through ifName, including
        # physical port names and logical LAG names. Prefer these over the
        # numeric ifIndex value.
        if (defined $name && $name ne '') {
            $if{$iid} = $name;
        }
        else {
            $if{$iid} = $index;
        }
    }

    return \%if;
}


# ------------------------------------------------------------------------
# LLDP
# ------------------------------------------------------------------------

sub hasLLDP {
    my $f5 = shift;

    # F5OS provides LLDP neighbor information through its vendor-specific
    # F5-OS-LLDP-MIB rather than through the standard LLDP MIB tables used
    # by SNMP::Info.
    my $neighbors = $f5->f5_lldp_rem_chassis() || {};

    return 1 if scalar keys %$neighbors;
    return;
}


sub lldp_if {
    my $f5      = shift;
    my $partial = shift;

    my $local_if = $f5->f5_lldp_local_if($partial) || {};
    my $i_name   = $f5->i_name()                   || {};

    # F5-OS-LLDP-MIB identifies the local interface by its interface name.
    # SNMP::Info expects an ifIndex, so map the F5OS interface name back
    # to the corresponding IF-MIB index.
    my %name_to_iid = reverse %$i_name;
    my %lldp_if;

    foreach my $key (keys %$local_if) {
        my $name = $local_if->{$key};
        next unless defined $name;

        my $ifindex = $name_to_iid{$name};
        next unless defined $ifindex;

        $lldp_if{$key} = $ifindex;
    }

    return \%lldp_if;
}


sub lldp_port {
    my $f5      = shift;
    my $partial = shift;

    return $f5->f5_lldp_rem_port($partial) || {};
}


sub lldp_id {
    my $f5      = shift;
    my $partial = shift;

    return $f5->f5_lldp_rem_chassis($partial) || {};
}


sub lldp_ip {
    my $f5      = shift;
    my $partial = shift;

    return $f5->f5_lldp_rem_ip($partial) || {};
}


sub lldp_platform {
    my $f5      = shift;
    my $partial = shift;

    my $desc = $f5->f5_lldp_rem_desc($partial) || {};
    my %platform;

    foreach my $iid (keys %$desc) {
        next unless defined $desc->{$iid};

        # Keep the value within the size expected by Netdisco.
        $platform{$iid} = substr($desc->{$iid}, 0, 255);
    }

    return \%platform;
}


# ------------------------------------------------------------------------
# ENTITY inventory helpers
# ------------------------------------------------------------------------

sub _f5_decode_string_indexes {
    my $iid = shift;

    return unless defined $iid;

    # Several F5 platform tables use one or more variable-length strings
    # as their SNMP index. Net-SNMP exposes such indexes as:
    #
    #   <length>.<char>.<char>...
    #
    # For example:
    #
    #   8.112.108.97.116.102.111.114.109
    #
    # decodes to:
    #
    #   platform
    #
    # Some tables contain multiple consecutive string indexes, therefore
    # decode all strings present in the instance identifier.
    my @oid = split /\./, $iid;
    my @strings;

    while (@oid) {
        my $len = shift @oid;

        return unless defined $len && $len =~ /^\d+$/;
        return if @oid < $len;

        my @chars = splice @oid, 0, $len;
        push @strings, join '', map { chr($_) } @chars;
    }

    return @strings;
}


sub _f5_entities {
    my $f5 = shift;

    # F5OS does not expose the platform inventory through ENTITY-MIB.
    # Build the SNMP::Info entity view from F5-PLATFORM-STATS-MIB instead.
    #
    # Only inventory information explicitly supplied by F5OS is mapped.
    # Operational health is intentionally not inferred from measurements
    # such as PSU voltage/current, temperatures or fan RPM values.

    my $component_serial = $f5->f5_component_serial() || {};
    my $component_model  = $f5->f5_component_model()  || {};

    my $psu_name   = $f5->f5_psu_name()   || {};
    my $psu_serial = $f5->f5_psu_serial() || {};
    my $psu_part   = $f5->f5_psu_part()   || {};

    my $disk_name    = $f5->f5_disk_name()    || {};
    my $disk_model   = $f5->f5_disk_model()   || {};
    my $disk_vendor  = $f5->f5_disk_vendor()  || {};
    my $disk_version = $f5->f5_disk_version() || {};
    my $disk_serial  = $f5->f5_disk_serial()  || {};
    my $disk_size    = $f5->f5_disk_size()    || {};
    my $disk_type    = $f5->f5_disk_type()    || {};

    my %entities;


    # ------------------------------------------------------------------
    # Chassis
    # ------------------------------------------------------------------
    #
    # componentInfoTable contains a component named "platform". Treat
    # this entry as the root chassis entity.
    #

    foreach my $iid (sort keys %$component_serial) {
        my ($name) = _f5_decode_string_indexes($iid);
        next unless defined $name;
        next unless $name eq 'platform';

        $entities{1} = {
            class  => 'chassis',
            name   => $name,
            model  => $component_model->{$iid},
            serial => $component_serial->{$iid},
            vendor => 'F5',
            parent => 0,
            pos    => -1,
        };

        last;
    }


    # ------------------------------------------------------------------
    # Other platform components
    # ------------------------------------------------------------------
    #
    # componentInfoTable also contains components such as the LCD module.
    # PSU entries are deliberately skipped here because psuStatsTable
    # contains richer PSU inventory data and would otherwise result in
    # duplicate entities.
    #

    my $component_index = 1001;

    foreach my $iid (sort keys %$component_serial) {
        my ($name) = _f5_decode_string_indexes($iid);

        next unless defined $name;
        next if $name eq 'platform';
        next if $name =~ /^psu-\d+$/;

        $entities{$component_index++} = {
            class  => 'module',
            name   => $name,
            model  => $component_model->{$iid},
            serial => $component_serial->{$iid},
            parent => 1,
        };
    }


    # ------------------------------------------------------------------
    # Power supplies
    # ------------------------------------------------------------------
    #
    # psuStatsTable provides PSU name, serial number and part number.
    # The part number is exposed as the entity model.
    #
    # The table also contains electrical and thermal measurements, but
    # F5OS does not expose a reliable operational status. Do not derive
    # e_status from those measurements.
    #

    my $psu_index = 2001;

    foreach my $iid (
        sort {
            ($psu_name->{$a} || '') cmp ($psu_name->{$b} || '')
        } keys %$psu_name
      )
    {
        my $name = $psu_name->{$iid};
        next unless defined $name;

        $entities{$psu_index++} = {
            class  => 'powerSupply',
            name   => $name,
            model  => $psu_part->{$iid},
            serial => $psu_serial->{$iid},
            parent => 1,
        };
    }


    # ------------------------------------------------------------------
    # Disks
    # ------------------------------------------------------------------
    #
    # diskInfoTable contains useful inventory information for each local
    # disk. SNMP::Info has no dedicated disk entity class, so expose the
    # disks as modules below the chassis.
    #

    my $disk_index = 3001;

    foreach my $iid (
        sort {
            ($disk_name->{$a} || '') cmp ($disk_name->{$b} || '')
        } keys %$disk_name
      )
    {
        my $name = $disk_name->{$iid};
        next unless defined $name;

        my @descr;

        push @descr, $disk_type->{$iid}
          if defined $disk_type->{$iid} && length $disk_type->{$iid};

        push @descr, $disk_size->{$iid}
          if defined $disk_size->{$iid} && length $disk_size->{$iid};

        my %entity = (
            class  => 'module',
            name   => $name,
            model  => $disk_model->{$iid},
            serial => $disk_serial->{$iid},
            vendor => $disk_vendor->{$iid},
            fwver  => $disk_version->{$iid},
            parent => 1,
        );

        # Only add a description when F5-OS provides usable disk metadata.
        # This avoids exposing an empty entity description when neither disk
        # type nor disk size is available.
        $entity{descr} = join(', ', @descr) if @descr;

        $entities{$disk_index++} = \%entity;

    }


    # Assign stable relative positions to all entities directly contained
    # in the chassis. The synthetic entity indexes themselves are grouped
    # by component type:
    #
    #   1       chassis
    #   1001+   generic platform components
    #   2001+   power supplies
    #   3001+   disks
    #
    # These indexes do not originate from ENTITY-MIB; they provide a
    # deterministic entity hierarchy for Netdisco.
    my $pos = 0;

    foreach my $iid (
        sort { $a <=> $b }
        grep { $_ != 1 } keys %entities
      )
    {
        $entities{$iid}->{pos} = ++$pos;
    }

    return \%entities;
}


sub _f5_entity_field {
    my ($f5, $field) = @_;

    my $entities = $f5->_f5_entities();
    my %result;

    foreach my $iid (keys %$entities) {
        my $value = $entities->{$iid}{$field};
        next unless defined $value;

        $result{$iid} = $value;
    }

    return \%result;
}


# ------------------------------------------------------------------------
# ENTITY-MIB compatible SNMP::Info methods
# ------------------------------------------------------------------------

sub e_index {
    my $f5 = shift;

    my $entities = $f5->_f5_entities();

    return { map { $_ => $_ } keys %$entities };
}


sub e_class {
    return shift->_f5_entity_field('class');
}


sub e_name {
    return shift->_f5_entity_field('name');
}


sub e_descr {
    return shift->_f5_entity_field('descr');
}


sub e_model {
    return shift->_f5_entity_field('model');
}


sub e_serial {
    return shift->_f5_entity_field('serial');
}


sub e_vendor {
    return shift->_f5_entity_field('vendor');
}


sub e_fwver {
    return shift->_f5_entity_field('fwver');
}


sub e_parent {
    return shift->_f5_entity_field('parent');
}


sub e_pos {
    return shift->_f5_entity_field('pos');
}


1;


=head1 NAME

SNMP::Info::Layer3::F5OS - SNMP Interface to F5OS network devices.

=head1 AUTHOR

Daniel Tuecks (dt@dtconnect.de)

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $f5os = new SNMP::Info(
                            AutoSpecify => 1,
                            Debug       => 1,
                            DestHost    => 'mydevice',
                            Community   => 'public',
                            Version     => 2
                          )
    or die "Can't connect to DestHost.\n";

 my $class = $f5os->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for F5 devices running F5OS.

This class provides F5OS-specific system information and builds an
ENTITY-MIB compatible hardware inventory from the F5OS platform statistics
MIBs.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<F5-OS-SYSTEM-MIB>

=item F<F5-OS-LLDP-MIB>

=item F<F5-PLATFORM-STATS-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar values from SNMP.

=over

=item $f5os->vendor()

Returns C<f5>.

=item $f5os->os()

Returns C<f5os>.

=item $f5os->os_ver()

Returns the F5OS software version.

=item $f5os->model()

Returns the platform model reported by the F5 platform component
information.

=item $f5os->serial()

Returns the system serial number reported by F<F5-OS-SYSTEM-MIB>.

=item $f5os->f5os_version()

Extracts and returns the F5OS software version from C<sysDescr>.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a
reference to a hash.

=head2 Overrides

=over

=item $f5os->interfaces()

Returns a mapping between C<ifIndex> and interface names.

F5OS interface names are taken from C<ifName>.  If no interface name is
available, the C<ifIndex> is used as a fallback.

=item $f5os->hasLLDP()

Returns true when LLDP neighbor information is available from the
F5OS LLDP MIB.

=item $f5os->lldp_if()

Returns a mapping between LLDP remote entries and the local C<ifIndex>.

F5OS reports the local interface as an interface name.  This method maps
the interface name to the corresponding C<ifIndex>.

=item $f5os->lldp_id()

Returns the remote LLDP chassis identifiers.

=item $f5os->lldp_ip()

Returns the remote LLDP management addresses.

=item $f5os->lldp_port()

Returns the remote LLDP port identifiers.

=item $f5os->lldp_platform()

Returns the remote LLDP system descriptions as platform information.

=back

=head2 Entity Information

The F5OS platform statistics MIBs expose hardware inventory information
using several platform-specific tables rather than ENTITY-MIB.  The
following methods normalize this information into the standard SNMP::Info
entity interface.

=over

=item $f5os->e_index()

Returns the generated entity indexes.

=item $f5os->e_class()

Returns the entity classes.

=item $f5os->e_name()

Returns the entity names.

=item $f5os->e_descr()

Returns the entity descriptions where descriptive information is available.

=item $f5os->e_model()

Returns the entity model or part information.

=item $f5os->e_serial()

Returns the entity serial numbers.

=item $f5os->e_vendor()

Returns the entity vendors where available.

=item $f5os->e_fwver()

Returns firmware versions for entities where available.

=item $f5os->e_parent()

Returns the generated entity containment hierarchy.

=item $f5os->e_pos()

Returns the generated relative positions of entities.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut

# vim: expandtab tabstop=4 shiftwidth=4
