# SNMP::Info::Layer2::HP - SNMP Interface to HP ProCurve Switches
#
# Copyright (c) 2008-2009 Max Baker changes from version 0.8 and beyond.
#
# Copyright (c) 2002,2003 Regents of the University of California
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

package SNMP::Info::Layer2::HP;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::MAU;
use SNMP::Info::CDP;
use SNMP::Info::Aggregate 'agg_ports_ifstack';

@SNMP::Info::Layer2::HP::ISA = qw/
    SNMP::Info::Aggregate
    SNMP::Info::Layer3
    SNMP::Info::MAU
    SNMP::Info::CDP
    Exporter
/;
@SNMP::Info::Layer2::HP::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %PORTSTAT, %MODEL_MAP, %MUNGE);

$VERSION = '3.70';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::MAU::MIBS,
    %SNMP::Info::CDP::MIBS,
    %SNMP::Info::Aggregate::MIBS,
    'RFC1271-MIB'            => 'logDescription',
    'HP-ICF-OID'             => 'hpSwitch4000',
    'STATISTICS-MIB'         => 'hpSwitchCpuStat',
    'NETSWITCH-MIB'          => 'hpMsgBufFree',
    'CONFIG-MIB'             => 'hpSwitchConfig',
    'HP-ICF-CHASSIS'         => 'hpicfSensorObjectId',
    'HP-ICF-BRIDGE'          => 'hpicfBridgeRstpForceVersion',
    'HP-ICF-POE-MIB'         => 'hpicfPoePethPsePortCurrent',
    'SEMI-MIB'               => 'hpHttpMgSerialNumber',
    'HP-SWITCH-PL-MIB'       => 'hpSwitchProliant',
    'BLADETYPE4-NETWORK-MIB' => 'hpProLiant-GbE2c-InterconnectSwitch',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::MAU::GLOBALS,
    %SNMP::Info::CDP::GLOBALS,
    %SNMP::Info::Aggregate::GLOBALS,
    'serial1'      => 'entPhysicalSerialNum.1',
    'serial2'      => 'hpHttpMgSerialNumber.0',
    'hp_cpu'       => 'hpSwitchCpuStat.0',
    'hp_mem_total' => 'hpGlobalMemTotalBytes.1',
    'mem_free'     => 'hpGlobalMemFreeBytes.1',
    'mem_used'     => 'hpGlobalMemAllocBytes.1',
    'os_version'   => 'hpSwitchOsVersion.0',
    'os_version2'  => 'hpHttpMgVersion.0',
    'os_bin'       => 'hpSwitchRomVersion.0',
    'mac'          => 'hpSwitchBaseMACAddress.0',
    'rstp_ver'     => 'hpicfBridgeRstpForceVersion',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::MAU::FUNCS,
    %SNMP::Info::CDP::FUNCS,
    %SNMP::Info::Aggregate::FUNCS,
    'i_type2'   => 'ifType',

    # RFC1271
    'l_descr' => 'logDescription',

    # CONFIG-MIB::hpSwitchPortTable
    'hp_duplex'       => 'hpSwitchPortEtherMode',
    'hp_duplex_admin' => 'hpSwitchPortFastEtherMode',
    'vendor_i_type'   => 'hpSwitchPortType',

    # HP-ICF-CHASSIS
    'hp_s_oid'    => 'hpicfSensorObjectId',
    'hp_s_name'   => 'hpicfSensorDescr',
    'hp_s_status' => 'hpicfSensorStatus',

    # HP-ICF-POE-MIB
    'peth_port_power'   => 'hpicfPoePethPsePortPower',
);

%MUNGE = (
    # Inherit all the built in munging
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::MAU::MUNGE,
    %SNMP::Info::CDP::MUNGE,
    %SNMP::Info::Aggregate::MUNGE,
    'c_id'   => \&munge_hp_c_id,
);


# Model map, reverse sorted by common model name (sort -k2 -r)
# Potential sources for model information: http://www.hp.com/rnd/software/switches.htm or HP-ICF-OID MIB
%MODEL_MAP = (
    'J8131A' => 'WAP-420-WW',
    'J8130A' => 'WAP-420-NA',
    'J9833A' => 'PS1810-8G',
    'J9834A' => 'PS1810-24G',
    'J8133A' => 'AP520WL',
    'J8680A' => '9408sl',
    'J9091A' => '8212zl',
    'J9475A' => '8206zl',
    'J9265A' => '6600ml-24XG',
    'J9264A' => '6600ml-24G-4XG',
    'J9263A' => '6600ml-24G',
    'J9452A' => '6600-48G-4XG',
    'J9451A' => '6600-48G',
    'J8474A' => '6410cl-6XG',
    'J8433A' => '6400cl-6XG',
    'J8992A' => '6200yl-24G',
    'J4902A' => '6108',
    'J8698A' => '5412zl',
    'J9851A' => '5412R-zl2',
    'J8719A' => '5408yl',
    'J8697A' => '5406zl',
    'J9850A' => '5406R-zl2',
    'J8718A' => '5404yl',
    'J4819A' => '5308XL',
    'J4850A' => '5304XL',
    'J8773A' => '4208vl',
    'J8770A' => '4204vl',
    'J8772A' => '4202vl-72',
    'J9032A' => '4202vl-68G',
    'J9031A' => '4202vl-68',
    'J8771A' => '4202vl-48G',
    'J4865A' => '4108GL',
    'J4887A' => '4104GL',
    'JL074A' => '3810M-48G-PoE+',
    'JL072A' => '3810M-48G',
    'JL076A' => '3810M-40G-8SR-PoE+',
    'JL073A' => '3810M-24G-PoE+',
    'JL071A' => '3810M-24G',
    'JL075A' => '3810M-16SFP+',
    'J9588A' => '3800-48G-PoE+-4XG',
    'J9574A' => '3800-48G-PoE+-4SFP+',
    'J9586A' => '3800-48G-4XG',
    'J9576A' => '3800-48G-4SFP+',
    'J9584A' => '3800-24SFP-2SFP+',
    'J9587A' => '3800-24G-PoE+-2XG',
    'J9573A' => '3800-24G-PoE+-2SFP+',
    'J9585A' => '3800-24G-2XG',
    'J9575A' => '3800-24G-2SFP+',
    'J8693A' => '3500yl-48G-PWR',
    'J8692A' => '3500yl-24G-PWR',
    'J9473A' => '3500-48-PoE',
    'J9472A' => '3500-48',
    'J9471A' => '3500-24-PoE',
    'J9470A' => '3500-24',
    'J4906A' => '3400cl-48G',
    'J4905A' => '3400cl-24G',
    'J4815A' => '3324XL',
    'J4851A' => '3124',
    'JL322A' => '2930M-48G-PoE+',
    'JL321A' => '2930M-48G',
    'JL323A' => '2930M-40G-8SR-PoE+',
    'JL320A' => '2930M-24G-PoE+',
    'JL324A' => '2930M-24G-8SR-PoE+',
    'JL319A' => '2930M-24G',
    'JL258A' => '2930F-8G-PoE+-2SFP+',
    'JL558A' => '2930F-48G-PoE+-4SFP+-740W',
    'JL557A' => '2930F-48G-PoE+-4SFP-740W',
    'JL256A' => '2930F-48G-PoE+-4SFP+',
    'JL262A' => '2930F-48G-PoE+-4SFP',
    'JL254A' => '2930F-48G-4SFP+',
    'JL260A' => '2930F-48G-4SFP',
    'JL255A' => '2930F-24G-PoE+-4SFP+',
    'JL261A' => '2930F-24G-PoE+-4SFP',
    'JL253A' => '2930F-24G-4SFP+',
    'JL259A' => '2930F-24G-4SFP',
    'J9729A' => '2920-48G-PoE+',
    'J9729A' => '2920-48G-PoE+',
    'J9728A' => '2920-48G',
    'J9728A' => '2920-48G',
    'J9727A' => '2920-24G-PoE+',
    'J9727A' => '2920-24G-PoE+',
    'J9726A' => '2920-24G',
    'J9726A' => '2920-24G',
    'J9562A' => '2915-8G-PoE',
    'J9148A' => '2910al-48G-PoE+',
    'J9147A' => '2910al-48G',
    'J9146A' => '2910al-24G-PoE+',
    'J9145A' => '2910al-24G',
    'J9050A' => '2900-48G',
    'J9049A' => '2900-24G',
    'J4904A' => '2848',
    'J4903A' => '2824',
    'J9022A' => '2810-48G',
    'J9021A' => '2810-24G',
    'J8165A' => '2650-PWR',
    'J4899B' => '2650-CR',
    'J4899C' => '2650C',
    'J4899A' => '2650',
    'J8164A' => '2626-PWR',
    'J4900B' => '2626-CR',
    'J4900C' => '2626C',
    'J4900A' => '2626',
    'J9627A' => '2620-48-PoE+',
    'J9626A' => '2620-48',
    'J9624A' => '2620-24-PPoE+',
    'J9625A' => '2620-24-PoE+',
    'J9623A' => '2620-24',
    'J9565A' => '2615-8-PoE',
    'J9089A' => '2610-48-PWR',
    'J9088A' => '2610-48',
    'J9087A' => '2610-24-PWR',
    'J9086A' => '2610-24/12PWR',
    'J9085A' => '2610-24',
    'J8762A' => '2600-8-PWR',
    'JL357A' => '2540-48G-PoE+-4SFP+',
    'JL355A' => '2540-48G-4SFP+',
    'JL356A' => '2540-24G-PoE+-4SFP+',
    'JL354A' => '2540-24G-4SFP+',
    'JL070A' => '2530-8-PoE+ Internal PS',
    'J9780A' => '2530-8-PoE+',
    'J9774A' => '2530-8G-PoEP',
    'J9777A' => '2530-8G',
    'J9783A' => '2530-8',
    'J9778A' => '2530-48-PoE+',
    'J9853A' => '2530-48G-PoE+-2SFP+',
    'J9772A' => '2530-48G-PoE+',
    'J9855A' => '2530-48G-2SFP+',
    'J9775A' => '2530-48G',
    'J9781A' => '2530-48',
    'J9779A' => '2530-24-PoE+',
    'J9854A' => '2530-24G-PoE+-2SFP+',
    'J9773A' => '2530-24G-PoE+',
    'J9856A' => '2530-24G-2SFP+',
    'J9776A' => '2530-24G',
    'J9782A' => '2530-24',
    'J4813A' => '2524',
    'J9298A' => '2520G-8-PoE',
    'J9299A' => '2520G-24-PoE',
    'J9137A' => '2520-8-PoE',
    'J9138A' => '2520-24-PoE',
    'J4812A' => '2512',
    'J9280A' => '2510G-48',
    'J9279A' => '2510G-24',
    'J9020A' => '2510-48A',
    'J9019B' => '2510-24B',
    'J9019A' => '2510-24A',
    'J4818A' => '2324',
    'J4817A' => '2312',
    'J9449A' => '1810G-8',
    'J9450A' => '1810G-24',
    'J9802A' => '1810-8G',
    'J9803A' => '1810-24G',
    'J9029A' => '1800-8G',
    'J9028A' => '1800-24G',
);

# Method Overrides

sub stp_ver {
    my $hp = shift;
    return $hp->rstp_ver() || $hp->SUPER::stp_ver();
}

sub cpu {
    my $hp = shift;
    return $hp->hp_cpu();
}

sub mem_total {
    my $hp = shift;
    return $hp->hp_mem_total();
}

sub os {
    return 'hp';
}

sub os_ver {
    my $hp         = shift;
    my $os_version = $hp->os_version() || $hp->os_version2();
    return $os_version if defined $os_version;

    # Some older ones don't have this value,so we cull it from the description
    my $descr = $hp->description();
    if ( $descr =~ m/revision ([A-Z]{1}\.\d{2}\.\d{2})/ ) {
        return $1;
    }
    return;
}

# Regular managed ProCurve switches have the serial num in entity mib,
# the web-managed models in the semi mib (hphttpmanageable).
sub serial {
    my $hp = shift;

    my $serial = $hp->serial1() || $hp->serial2() || undef;;

    return $serial;
}

# Lookup model number, and translate the part number to the common number
sub model {
    my $hp = shift;
    my $id = $hp->id();
    return unless defined $id;
    my $model = &SNMP::translateObj($id);
    return $id unless defined $model;

    $model =~ s/^(hp|aruba)switch//i;

    return defined $MODEL_MAP{$model} ? $MODEL_MAP{$model} : $model;
}

sub interfaces {
    my $hp         = shift;
    my $interfaces = $hp->i_index();
    my $i_descr    = $hp->i_description();

    my %if;
    foreach my $iid ( keys %$interfaces ) {
        my $descr = $i_descr->{$iid};
        next unless defined $descr;
        $if{$iid} = $descr if ( defined $descr and length $descr );
    }

    return \%if

}

sub i_name {
    my $hp      = shift;
    my $i_alias = $hp->i_alias();
    my $e_name  = $hp->e_name();
    my $e_port  = $hp->e_port();

    my %i_name;

    foreach my $port ( keys %$e_name ) {
        my $iid = $e_port->{$port};
        next unless defined $iid;
        my $alias = $i_alias->{$iid};
        next unless defined $iid;
        $i_name{$iid} = $e_name->{$port};

        # Check for alias
        $i_name{$iid} = $alias if ( defined $alias and length($alias) );
    }

    return \%i_name;
}

sub i_duplex {
    my $hp = shift;

    return $hp->mau_i_duplex();
}

sub i_duplex_admin {
    my $hp      = shift;
    my $partial = shift;

    # Try HP MIB first
    my $hp_duplex = $hp->hp_duplex_admin($partial);
    if ( defined $hp_duplex and scalar( keys %$hp_duplex ) ) {

        my %i_duplex;
        foreach my $if ( keys %$hp_duplex ) {
            my $duplex = $hp_duplex->{$if};
            next unless defined $duplex;

            $duplex = 'half' if $duplex =~ /half/i;
            $duplex = 'full' if $duplex =~ /full/i;
            $duplex = 'auto' if $duplex =~ /auto/i;
            $i_duplex{$if} = $duplex;
        }
        return \%i_duplex;
    }
    else {
        return $hp->mau_i_duplex_admin();
    }
}

sub vendor {
    return 'hp';
}

sub log {
    my $hp = shift;

    my $log = $hp->l_descr();

    my $logstring = undef;

    foreach my $val ( values %$log ) {
        next if $val =~ /^Link\s+(Up|Down)/;
        $logstring .= "$val\n";
    }

    return $logstring;
}

sub slots {
    my $hp = shift;

    my $e_name = $hp->e_name();

    return unless defined $e_name;

    my $slots;
    foreach my $slot ( keys %$e_name ) {
        $slots++ if $e_name->{$slot} =~ /slot/i;
    }

    return $slots;
}

sub fan {
    my $hp = shift;
    return &_sensor( $hp, 'fan' );
}

sub ps1_status {
    my $hp = shift;
    return &_sensor( $hp, 'power', '^power supply 1' )
        || &_sensor( $hp, 'power', '^power supply sensor' );
}

sub ps2_status {
    my $hp = shift;
    return &_sensor( $hp, 'power', '^power supply 2' )
        || &_sensor( $hp, 'power', '^redundant' );
}

sub _sensor {
    my $hp          = shift;
    my $search_type = shift || 'fan';
    my $search_name = shift || '';
    my $hp_s_oid    = $hp->hp_s_oid();
    my $result;
    foreach my $sensor ( keys %$hp_s_oid ) {
        my $sensortype = &SNMP::translateObj( $hp_s_oid->{$sensor} );
        if ( $sensortype =~ /$search_type/i ) {
            my $sensorname   = $hp->hp_s_name()->{$sensor};
            my $sensorstatus = $hp->hp_s_status()->{$sensor};
            if ( $sensorname =~ /$search_name/i ) {
                $result = $sensorstatus;
            }
        }
    }
    return $result;
}

sub munge_hp_c_id {
    my ($v) = @_;
    if ( length(unpack('H*', $v)) == 12 ){
	return join(':',map { sprintf "%02x", $_ } unpack('C*', $v));
    }if ( length(unpack('H*', $v)) == 10 ){
	# IP address (first octet is sign, I guess)
	my @octets = (map { sprintf "%02x",$_ } unpack('C*', $v))[1..4];
	return join '.', map { hex($_) } @octets;
    }else{
	return $v;
    }
}

# POWER-ETHERNET-MIB doesn't define a mapping of its
# "module"/"port" index to ifIndex.  Different vendors
# do this in different ways.
# HP switches use the ifIndex as port index, so we can
# ignore the module information and map the index directly
# onto an ifIndex.
sub peth_port_ifindex {
    my $peth    = shift;
    my $partial = shift;

    my $peth_port_status = $peth->peth_port_status($partial);
    my $peth_port_ifindex;

    foreach my $i ( keys %$peth_port_status ) {
        my ( $module, $port ) = split( /\./, $i );
        $peth_port_ifindex->{$i} = $port;
    }
    return $peth_port_ifindex;
}

sub set_i_vlan {
    my $hp = shift;
    my $rv;

    my $qb_i_vlan = $hp->qb_i_vlan_t();
    if (defined $qb_i_vlan and scalar(keys %$qb_i_vlan)){
        my $vlan = shift;
        my $iid = shift;

        my $qb_v_egress = $hp->qb_v_egress();
        if (defined $qb_v_egress and scalar($qb_v_egress->{$vlan})) {
            # store current untagged VLAN to remove it from the port list later
            my $old_untagged = $qb_i_vlan->{$iid};

            # set new untagged / native VLAN
            $rv = $hp->set_qb_i_vlan($vlan, $iid);

            # If change is successful, the old native VLAN will now be a tagged VLAN on the port. This is generally not what we want.
            # We'll have to remove this VLAN from the "egress list" on the port.
            if (defined $rv and $old_untagged != $vlan) {
                if (defined $old_untagged and defined $qb_v_egress and scalar($qb_v_egress->{$vlan})){

                    # First, get the egress list of the old native VLAN (arrayref structure)
                    my $egressports = $qb_v_egress->{$old_untagged};

                    # Since arrays are zero-based, we have to change the element at Index - 1
                    $egressports->[$iid-1] = "0";

                    # After changing, pack the array into a binary structure (expected by set_qb_v_egress) and set the new value on the device.
                    my $new_egresslist = pack("B*", join('', @$egressports));

                    $rv = $hp->set_qb_v_egress($new_egresslist, $old_untagged);
                }
            }
        } else {
            $hp->error_throw(sprintf("Requested VLAN %s doesn't seem to exist on device...", $vlan));
        }
    }
    return $rv;
}

sub set_i_vlan_tagged {
    my $hp = shift;
    my $rv;

    my $qb_i_vlan = $hp->qb_i_vlan_t();
    if (defined $qb_i_vlan and scalar(keys %$qb_i_vlan)){
        my $vlan = shift;
        my $iid = shift;

        my $qb_v_egress = $hp->qb_v_egress();
        if (defined $qb_v_egress and scalar($qb_v_egress->{$vlan})) {

            # First, get the egress list of the VLAN we want to add to the port.
            my $egressports = $qb_v_egress->{$vlan};

            # Since arrays are zero-based, we have to change the element at Index - 1
            $egressports->[$iid-1] = "1";

            # After changing, pack the array into a binary structure (expected by set_qb_v_egress) and set the new value on the device.
            my $new_egresslist = pack("B*", join('', @$egressports));
            $rv = $hp->set_qb_v_egress($new_egresslist, $vlan);
            return $rv;
        } else {
            $hp->error_throw(sprintf("Requested VLAN %s doesn't seem to exist on device...", $vlan));
        }
    }
    return;
}

sub agg_ports { return agg_ports_ifstack(@_) }

1;
__END__

=head1 NAME

SNMP::Info::Layer2::HP - SNMP Interface to HP Procurve Switches

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $hp = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $hp->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a
HP ProCurve Switch via SNMP.

Note:  Some HP Switches will connect via SNMP version 1, but a lot of config
data will not be available.  Make sure you try and connect with Version 2
first, and then fail back to version 1.

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above.

 my $hp = new SNMP::Info::Layer2::HP(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=item SNMP::Info::MAU

=back

=head2 Required MIBs

=over

=item F<RFC1271-MIB>

Included in V2 mibs from Cisco

=item F<HP-ICF-OID>

(this MIB new with SNMP::Info 0.8)

=item F<STATISTICS-MIB>

=item F<NETSWITCH-MIB>

=item F<CONFIG-MIB>

=item F<HP-ICF-BRIDGE>

=item F<HP-ICF-POE-MIB>

=item F<HP-ICF-CHASSIS>

=item F<SEMI-MIB>

=item F<HP-SWITCH-PL-MIB>

=item F<BLADETYPE4-NETWORK-MIB>

=back

The last four MIBs listed are from HP and can be found at
L<http://www.hp.com/rnd/software> or
L<http://www.hp.com/rnd/software/MIBs.htm>

=head1 Change Log

Version 0.4 - Removed F<ENTITY-MIB> e_*() methods to separate sub-class -
SNMP::Info::Entity

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $hp->cpu()

Returns CPU Utilization in percentage.

=item $hp->log()

Returns all the log entries from the switch's log that are not Link up or
down messages.

=item $hp->mem_free()

Returns bytes of free memory

=item $hp->mem_total()

Return bytes of total memory

=item $hp->mem_used()

Returns bytes of used memory

=item $hp->model()

Returns the model number of the HP Switch.  Will translate between the HP Part
number and the common model number with this map :

 %MODEL_MAP = (
    'J8131A' => 'WAP-420-WW',
    'J8130A' => 'WAP-420-NA',
    'J8133A' => 'AP520WL',
    'J8680A' => '9408sl',
    'J9091A' => '8212zl',
    'J9475A' => '8206zl',
    'J9265A' => '6600ml-24XG',
    'J9264A' => '6600ml-24G-4XG',
    'J9263A' => '6600ml-24G',
    'J9452A' => '6600-48G-4XG',
    'J9451A' => '6600-48G',
    'J8474A' => '6410cl-6XG',
    'J8433A' => '6400cl-6XG',
    'J8992A' => '6200yl-24G',
    'J4902A' => '6108',
    'J8698A' => '5412zl',
    'J8719A' => '5408yl',
    'J8697A' => '5406zl',
    'J8718A' => '5404yl',
    'J4819A' => '5308XL',
    'J4850A' => '5304XL',
    'J8773A' => '4208vl',
    'J8770A' => '4204vl',
    'J8772A' => '4202vl-72',
    'J9032A' => '4202vl-68G',
    'J9031A' => '4202vl-68',
    'J8771A' => '4202vl-48G',
    'J4865A' => '4108GL',
    'J4887A' => '4104GL',
    'J9588A' => '3800-48G-PoE+-4XG',
    'J9574A' => '3800-48G-PoE+-4SFP+',
    'J9586A' => '3800-48G-4XG',
    'J9576A' => '3800-48G-4SFP+',
    'J9584A' => '3800-24SFP-2SFP+',
    'J9587A' => '3800-24G-PoE+-2XG',
    'J9573A' => '3800-24G-PoE+-2SFP+',
    'J9585A' => '3800-24G-2XG',
    'J9575A' => '3800-24G-2SFP+',
    'J8693A' => '3500yl-48G-PWR',
    'J8692A' => '3500yl-24G-PWR',
    'J9473A' => '3500-48-PoE',
    'J9472A' => '3500-48',
    'J9471A' => '3500-24-PoE',
    'J9470A' => '3500-24',
    'J4906A' => '3400cl-48G',
    'J4905A' => '3400cl-24G',
    'J4815A' => '3324XL',
    'J4851A' => '3124',
    'J9562A' => '2915-8G-PoE',
    'J9148A' => '2910al-48G-PoE+',
    'J9147A' => '2910al-48G',
    'J9146A' => '2910al-24G-PoE+',
    'J9145A' => '2910al-24G',
    'J9050A' => '2900-48G',
    'J9049A' => '2900-24G',
    'J4904A' => '2848',
    'J4903A' => '2824',
    'J9022A' => '2810-48G',
    'J9021A' => '2810-24G',
    'J8165A' => '2650-PWR',
    'J4899B' => '2650-CR',
    'J4899C' => '2650C',
    'J4899A' => '2650',
    'J8164A' => '2626-PWR',
    'J4900B' => '2626-CR',
    'J4900C' => '2626C',
    'J4900A' => '2626',
    'J9627A' => '2620-48-PoE+',
    'J9626A' => '2620-48',
    'J9624A' => '2620-24-PPoE+',
    'J9625A' => '2620-24-PoE+',
    'J9623A' => '2620-24',
    'J9565A' => '2615-8-PoE',
    'J9089A' => '2610-48-PWR',
    'J9088A' => '2610-48',
    'J9087A' => '2610-24-PWR',
    'J9086A' => '2610-24/12PWR',
    'J9085A' => '2610-24',
    'J8762A' => '2600-8-PWR',
    'J4813A' => '2524',
    'J9298A' => '2520G-8-PoE',
    'J9299A' => '2520G-24-PoE',
    'J9137A' => '2520-8-PoE',
    'J9138A' => '2520-24-PoE',
    'J4812A' => '2512',
    'J9280A' => '2510G-48',
    'J9279A' => '2510G-24',
    'J9020A' => '2510-48A',
    'J9019B' => '2510-24B',
    'J9019A' => '2510-24A',
    'J4818A' => '2324',
    'J4817A' => '2312',
    'J9449A' => '1810G-8',
    'J9450A' => '1810G-24',
    'J9029A' => '1800-8G',
    'J9028A' => '1800-24G',
 );

=item $hp->os()

Returns hp

=item $hp->os_bin()

C<hpSwitchRomVersion.0>

=item $hp->os_ver()

Tries to use os_version() and if that fails will try and cull the version from
the description field.

=item $hp->os_version()

C<hpSwitchOsVersion.0>

=item $hp->serial()

Returns serial number if available through SNMP

=item $hp->slots()

Returns number of entries in $hp->e_name that have 'slot' in them.

=item $hp->vendor()

hp

=item $hp->fan()

Returns fan status

=item $hp->ps1_status()

Power supply 1 status

=item $hp->ps2_status()

Power supply 2 status

=item $hp->peth_port_power()

Power supplied by PoE ports, in milliwatts
(C<hpicfPoePethPsePortPower>)

=item $hp->stp_ver()

Returns what version of STP the device is running.
(C<hpicfBridgeRstpForceVersion> with fallback to inherited stp_ver())

=back

=head2 Globals imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over 4

=item $hp->interfaces()

Uses $hp->i_description()

=item $hp->i_duplex()

Returns reference to map of IIDs to current link duplex.

=item $hp->i_duplex_admin()

Returns reference to hash of IIDs to admin duplex setting.

=item $hp->vendor_i_type()

Returns reference to hash of IIDs to HP specific port type
(C<hpSwitchPortType>).

=item $hp->i_name()

Crosses i_name() with $hp->e_name() using $hp->e_port() and i_alias()

=item $hp->peth_port_ifindex()

Returns reference to hash of power Ethernet port table entries map back to
interface index (c<ifIndex>)

=item C<agg_ports>

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"TABLE METHODS"> for details.

=head1 MUNGES

=over

=item munge_hp_c_id()

Munge for c_id which handles CDP and LLDP.

=back

=head1 SET METHODS

These are methods that provide SNMP set functionality for overridden methods
or provide a simpler interface to complex set operations.  See
L<SNMP::Info/"SETTING DATA VIA SNMP"> for general information on set
operations.

=over

=item set_i_vlan()

=item set_i_vlan_tagged()

=back

=cut
