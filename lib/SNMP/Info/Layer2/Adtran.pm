package SNMP::Info::Layer2::Adtran;

use strict;
use Exporter;
use SNMP::Info::LLDP;
use SNMP::Info::Layer2;
use SNMP::Info::Layer3;

@SNMP::Info::Layer2::Adtran::ISA       = qw/SNMP::Info::LLDP SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::Adtran::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.34';

# This will be filled in with the device's index into the EntPhysicalEntry
# table by the serial() function.
our $index = undef;

%MIBS = ( 
    %SNMP::Info::Layer2::MIBS,
    %SNMP::Info::Layer3::MIBS,
    'ADTRAN-GENEVC-MIB'     => 'adGenEVCMIB',
    'ADTRAN-GENMEF-MIB'     => 'adGenMEFMIB',
    'ADTRAN-GENPORT-MIB'    => 'adGenPort',
    'ADTRAN-MIB'            => 'adtran',
    'ADTRAN-AOSUNIT'     => 'adGenAOSUnitMib',
 );

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS, 
    %SNMP::Info::Layer3::GLOBALS, 
    %SNMP::Info::LLDP::GLOBALS,
    'serial'    => 'adProdSerialNumber',
    'ad_mgmtevcvid' => 'adGenEVCSysMgmtEVCSTagVID',
);

%FUNCS = ( %SNMP::Info::Layer2::FUNCS,
           %SNMP::Info::Layer3::FUNCS,
           %SNMP::Info::LLDP::FUNCS, 
           'ad_evcstag' => 'adGenEVCLookupName',
           'ad_menport' => 'adGenMenPortRowStatus',
           'ad_evcnamevid' => 'adGenEVCSTagVID',
           'ad_mgmtevcports' => 'adGenSysMgmtEVCInterfaceConnectionType',
           'ad_evcmapuniport' => 'adGenMEFMapUNIPort',
           'ad_evcmapevc' => 'adGenMEFMapAssociatedEVCAlias',
           'ad_genportcustuse' => 'adGenPortCustomerUse',
);

%MUNGE = ( %SNMP::Info::Layer2::MUNGE, %SNMP::Info::LLDP::MUNGE, %SNMP::Info::Layer3::MUNGE );

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
            my @split = split(/\./,$port);
            $i_name->{@split[1]} = $adname->{$port};
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
            my @split = split(/(\.0)+\./,$entry);
            my $name = pack("C*", split(/\./,@split[0]));
            push @{$if_vlans->{@split[2]}}, $vlans->{$name};
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
