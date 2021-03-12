# SNMP::Info::Layer2::Adtran - SNMP Interface to Adtran Devices
#
# Copyright (c) 2019 by The Netdisco Developer Team.
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

package SNMP::Info::Layer2::Adtran;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer2;
use SNMP::Info::Layer3;

@SNMP::Info::Layer2::Adtran::ISA       = qw/SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::Adtran::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.71';

# This will be filled in with the device's index into the EntPhysicalEntry
# table by the serial() function.
our $index = undef;

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
    %SNMP::Info::Layer3::MIBS,
#    'ADTRAN-GENEVC-MIB'     => 'adGenEVCMIB',
#    'ADTRAN-GENMEF-MIB'     => 'adGenMEFMIB',
#    'ADTRAN-GENPORT-MIB'    => 'adGenPort',
    'ADTRAN-MIB'            => 'adtran',
    'ADTRAN-AOSUNIT'     => 'adGenAOSUnitMib',
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
    %SNMP::Info::Layer3::GLOBALS,
    'serial'    => 'adProdSerialNumber',
    'ad_mgmtevcvid' => 'adGenEVCSysMgmtEVCSTagVID',
);

%FUNCS = ( %SNMP::Info::Layer2::FUNCS,
           %SNMP::Info::Layer3::FUNCS,
           'ad_evcstag' => 'adGenEVCLookupName',
           'ad_menport' => 'adGenMenPortRowStatus',
           'ad_evcnamevid' => 'adGenEVCSTagVID',
           'ad_mgmtevcports' => 'adGenSysMgmtEVCInterfaceConnectionType',
           'ad_evcmapuniport' => 'adGenMEFMapUNIPort',
           'ad_evcmapevc' => 'adGenMEFMapAssociatedEVCAlias',
           'ad_genportcustuse' => 'adGenPortCustomerUse',
);

%MUNGE = ( %SNMP::Info::Layer2::MUNGE, %SNMP::Info::Layer3::MUNGE );

sub vendor {
    return 'adtran';
}
sub os {
    return 'aos';
}

sub layers {
    my $adtran = shift;

    my $layers = $adtran->SUPER::layers();
    # Some netvantas don't report L2 properly
    my $macs   = $adtran->fw_mac();

    if (keys %$macs) {
        my $l = substr $layers, 6, 1, "1";
    }

    return $layers;
}

sub os_ver {
    my $adtran = shift;
    my $ver = $adtran->adProdSwVersion() || undef;
    return $ver if (defined $ver);
    my $aos_ver = $adtran->adAOSDeviceVersion();
    return $aos_ver;
}
sub model {
    my $adtran = shift;
    my $id = $adtran->id();
    my $mod = $adtran->adProdName() || undef;
    return $mod if (defined $mod);
    my $model = $adtran->adAOSDeviceProductName() || undef;
    return $model;
}
sub serial {
    my $adtran = shift;
    my $e_serial = $adtran->e_serial() || {};
    my $serial2 = $e_serial->{1} || undef;
    return $serial2 if ( defined $serial2 );
    return $adtran->orig_serial();
}

sub i_name {
    my $adtran = shift;
    my $partial = shift;
    my $i_name = $adtran->SUPER::i_alias() || undef;
    return $i_name if (defined $i_name);
    $i_name = {};
    my $adname = $adtran->ad_genportcustuse() || undef;
    if (defined $adname) {
        foreach my $port (keys %$adname) {
            my @splitout = split(/\./,$port);
            $i_name->{$splitout[1]} = $adname->{$port};
        }
    }
    return $i_name;
}
sub i_vlan {
    my $adtran = shift;
    my $partial = shift;
    my $uniports = $adtran->ad_evcmapuniport() || undef;
    my $evcmaps = $adtran->ad_evcmapevc() || undef;
    my $v_names = $adtran->ad_evcnamevid() || undef;
    if (defined $uniports) {
        my $vlans = {};
        foreach my $oid (keys %$v_names) {
            my $name = pack("C*", split(/\./,$oid));
            $vlans->{$name} = $v_names->{$oid};
        }
        my $i_vlan = {};
        foreach my $evcmap (keys %$evcmaps) {
            $i_vlan->{$uniports->{$evcmap}} = $vlans->{$evcmaps->{$evcmap}};
        }
        return $i_vlan;
    }
    return {};

}

sub i_vlan_membership {
    my $adtran  = shift;
    my $partial = shift;
    my $i_vlan = $adtran->ad_menport();
    if (defined $i_vlan) {
        my $vlans = {};
        my $v_name = $adtran->v_name();
        foreach my $vid (keys %$v_name) {
            $vlans->{$v_name->{$vid}} = $vid;
        }
        my $if_vlans = {};
        foreach my $entry (keys %$i_vlan) {
            my @splitout = split(/(\.0)+\./,$entry);
            my $name = pack("C*", split(/\./,$splitout[0]));
            push @{$if_vlans->{$splitout[2]}}, $vlans->{$name};
        }
        my $mgmtevcports = $adtran->ad_mgmtevcports();
        my $mgmtevcid = $adtran->ad_mgmtevcvid();
        foreach my $port (keys %$mgmtevcports) {
           push @{$if_vlans->{$port}}, $mgmtevcid;
        }
        return $if_vlans;
    }
    return {};
}

sub v_name {
    my $adtran = shift;
    my $partial = shift;
    my $v_index = $adtran->ad_evcstag();
    return {} unless defined $v_index;
    $v_index->{$adtran->ad_mgmtevcvid()} = 'system-management-evc';
    return $v_index;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::Adtran - SNMP Interface to Adtran Devices

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $adtran = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $adtran->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for adtran Devices running JUNOS

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=item SNMP::Info::Layer3

=back

=head2 Inherited Classes' MIBs

See L<SNMP::Info::Layer2/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $adtran->vendor()

Returns 'adtran'

=item $adtran->os()

Returns 'aos'

=item $adtran->layers()

Ensures that layer two is reported, at least.

=item $adtran->os_ver()

Returns the software version extracted first from C<adProdSwVersion> or
C<adAOSDeviceVersion>.

=item $adtran->model()

Returns the model extracted first from C<adProdName> or
C<adAOSDeviceProductName>.

=item $adtran->serial()

Returns serial number.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $adtran->v_name()

VLAN names table.

=item $adtran->i_name()

Interface names table.

=item $adtran->i_vlan()

Returns a mapping between C<ifIndex> and the PVID or default VLAN.

=item $adtran->i_vlan_membership()

Returns reference to hash of arrays: key = C<ifIndex>, value = array of VLAN
IDs.  These are the VLANs which are members of the egress list for the port.

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
