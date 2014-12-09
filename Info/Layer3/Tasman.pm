# SNMP::Info::Layer3::Tasman
#
# Copyright (c) 2012 Eric Miller
# All Rights Reserved
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

package SNMP::Info::Layer3::Tasman;

use strict;
use warnings;
use Exporter;

use SNMP::Info::Layer3;
use SNMP::Info::MAU;

@SNMP::Info::Layer3::Tasman::ISA = qw/SNMP::Info::MAU
    SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Tasman::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.23';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::MAU::MIBS,
    'NT-ENTERPRISE-DATA-MIB' => 'ntEnterpriseRouters',
    'SYSTEM-MIB'             => 'nnsysVersion',
    'CHASSIS-MIB'            => 'nnchassisModel',
    'ENVIRONMENT-MIB'        => 'nnenvPwrsupStatus',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::MAU::GLOBALS,
    'ps1_type'      => 'nnenvPwrsupType.1',
    'ps1_status'    => 'nnenvPwrsupStatus.1',
    'ps2_type'      => 'nnenvPwrsupType.2',
    'ps2_status'    => 'nnenvPwrsupStatus.2',
    'nn_sys_ver'    => 'nnsysVersion',
    'nn_ch_model'   => 'nnchassisModel',
    'nn_ch_op_stat' => 'nnchassisOperStatus',
    'nn_ch_serial'  => 'nnchassisSerialNumber',
);

%FUNCS = ( %SNMP::Info::Layer3::FUNCS, %SNMP::Info::MAU::FUNCS, );

%MUNGE = ( %SNMP::Info::Layer3::MUNGE, %SNMP::Info::MAU::MUNGE, );

# use MAU-MIB for admin. duplex and admin. speed
*SNMP::Info::Layer3::Tasman::i_duplex_admin
    = \&SNMP::Info::MAU::mau_i_duplex_admin;
*SNMP::Info::Layer3::Tasman::i_speed_admin
    = \&SNMP::Info::MAU::mau_i_speed_admin;

my $module_map = {
    ADSL_ANX_A => '1-port ADSL2+ Annex A',
    ADSL_ANX_B => '1-port ADSL2+ Annex B',
    BRI_2ST    => '2-port ST-interface ISDN BRI for both TDM and Packet',
    FXO_2M     => 'Voice Interface card - 2 port FXO',
    FXO_4M     => 'Voice Interface card - 4 port FXO',
    FXS_2M     => 'Voice Interface card - 2 port FXS',
    FXS_4M     => 'Voice Interface card - 4 port FXS',
    HSSI_1     => '1-port High Speed Serial',
    LMF_24     => '24-port 10/100 Fast Ethernet Layer2/3 switch',
    LMG_10 =>
        '10-port non-blocking 10/100/1000 Gigabit Ethernet Layer2/3 switch',
    LMG_44   => '44-port 10/100/1000 Gigabit Ethernet Layer 2/3 switch',
    LMP_24   => '24-port 10/100 fast Ethernet Layer2/3 PoE switch',
    PVIM_A   => 'Packetized Voice Module (PVIM)',
    SCIM_A   => 'Ipsec VPN Encryption Module',
    SERV_MOD => 'Secure Router 4134 Server Module',
    VCM_A =>
        'Medium Carrier module supports up to 4 FXO or FXS Small Modules',
    VOIP_A  => 'Packetized Voice Module (PVM)',
    VPN_A   => 'High Performance IPsec VPN Encryption Module',
    WDS3_1C => '1-port Clear Channel DS3',
    WT3_1C  => '1-port Channelized T3',
    DS3_1C  => '1-port Channelized T3',
    WTE_1   => '1-port T1/E1 w DS0 and DS1 support for both TDM and Packet',
    WTE_2S  => '2-port Sync and Async Serial',
    WTE_8   => '8-port T1/E1'
};

sub vendor {
    return 'avaya';
}

sub os {
    return 'tasman';
}

sub os_ver {
    my $tasman  = shift;
    my $version = $tasman->nn_sys_ver() || "";
    my $descr   = $tasman->description() || "";

    # Newer versions
    return $1 if ( $version =~ /^SW:\s+(.+?)\s+/ );

    # Older versions
    return $1 if ( $descr =~ /Software Version\s+=\s+[r]*(.+),/ );

    # Can't find
    return;
}

sub model {
    my $tasman = shift;

    my $id       = $tasman->id();
    my $ch_model = $tasman->nn_ch_model();

    return $ch_model if $ch_model;

    my $model = &SNMP::translateObj($id);
    return $id unless defined $model;

    $model =~ s/^ntSecureRouter/SR/;
    return $model;
}

sub serial {
    my $tasman = shift;

    # Newer versions of the software redefined the MIB in a non-backwards
    # compatible manner.  Try the old OID first.
    my $serial = $tasman->nn_ch_op_stat();

    # Newer versions populate status, serial should contain some letters
    # while a status is an integer
    return $serial if ( $serial !~ /^\D+$/ );

    # Unfortunately newer versions don't seem to populate the newer OID.
    # so check modules for a chassis
    my $e_parent = $tasman->e_parent();

    foreach my $iid ( keys %$e_parent ) {
        my $parent = $e_parent->{$iid};
        if ( $parent eq '0' ) {
            my $ser = $tasman->e_serial($iid);
            return $ser->{$iid};
        }
    }

    # If everything else failed just return what is supposed to hold the
    # serial although it probably doesn't
    return $tasman->nn_ch_serial();
}

# Slots 1–4 are Small Module slots. Slots 5–7 are Medium Module slots.
# A Large Module spans slots 6 and 7. It will be identified as slot 6.

sub e_index {
    my $tasman = shift;

    my $index = $tasman->nnchassisInfoSlotSubSlotString() || {};

    # In some cases the modules are duplicated, remove duplicates
    my %seen;
    my %e_index;
    foreach my $key ( keys %$index ) {
        my $string = $index->{$key};
        $string =~ s/\D//;
        unless ( $seen{$string} ) {
            $seen{$string}++;
            $e_index{$key} = $string + 1;
        }
    }

    return \%e_index;
}

sub e_class {
    my $tasman = shift;

    my $e_index = $tasman->e_index() || {};

    my %e_class;
    foreach my $iid ( keys %$e_index ) {

        my $index = $e_index->{$iid};

        if ( $index == 1 ) {
            $e_class{$iid} = 'chassis';
        }
        else {
            $e_class{$iid} = 'module';
        }
    }
    return \%e_class;
}

sub e_descr {
    my $tasman = shift;

    my $e_index = $tasman->e_index()             || {};
    my $types   = $tasman->nnchassisInfoCardType || {};

    my %e_descr;
    foreach my $iid ( keys %$e_index ) {
        my $type = $types->{$iid};
        next unless $type;

        if ( $type =~ /^MPU/ ) {
            $e_descr{$iid} = $tasman->model();
        }
        elsif ( defined $module_map->{$type} ) {
            $e_descr{$iid} = $module_map->{$type};
        }
        else {
            next;
        }
    }
    return \%e_descr;
}

sub e_serial {
    my $tasman = shift;

    my $e_index = $tasman->e_index() || {};
    my $serials = $tasman->nnchassisInfoSerialNumber() || {};

    my %e_serial;
    foreach my $iid ( keys %$e_index ) {
        $e_serial{$iid} = $serials->{$iid} || '';
    }
    return \%e_serial;
}

sub e_fru {
    my $tasman = shift;

    my $e_index = $tasman->e_index() || {};

    my %e_fru;
    foreach my $iid ( keys %$e_index ) {
        $e_fru{$iid} = "true";
    }
    return \%e_fru;
}

sub e_type {
    my $tasman = shift;

    my $e_index = $tasman->e_index()             || {};
    my $types   = $tasman->nnchassisInfoCardType || {};

    my %e_type;
    foreach my $iid ( keys %$e_index ) {
        $e_type{$iid} = $types->{$iid} || '';
    }

    return \%e_type;
}

sub e_vendor {
    my $tasman = shift;

    my $e_idx = $tasman->e_index() || {};

    my %e_vendor;
    foreach my $iid ( keys %$e_idx ) {
        $e_vendor{$iid} = 'avaya';
    }
    return \%e_vendor;
}

sub e_pos {
    my $tasman = shift;

    return $tasman->e_index();
}

sub e_parent {
    my $tasman = shift;

    my $e_idx     = $tasman->e_index() || {};
    my $e_classes = $tasman->e_class() || {};

    my $cha_idx = 0;
    foreach my $i ( keys %$e_classes ) {
        my $class = $e_classes->{$i};
        my $pos   = $e_idx->{$i};
        if ( $class && $class eq 'chassis' ) {
            $cha_idx = $pos;
        }
    }

    my %e_parent;
    foreach my $iid ( keys %$e_idx ) {
        my $idx = $e_idx->{$iid};

        if ( $idx == 1 ) {
            $e_parent{$iid} = 0;
        }
        elsif ( $idx =~ /^(\d)\d$/ ) {
            $e_parent{$iid} = $1;
        }
        else {
            $e_parent{$iid} = $cha_idx;
        }
    }
    return \%e_parent;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Tasman - SNMP Interface to Avaya Secure Routers

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $tasman = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $tasman->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Avaya Secure Routers

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::MAU

=back

=head2 Required MIBs

=over

=item F<NT-ENTERPRISE-DATA-MIB>

=item F<SYSTEM-MIB>

=item F<CHASSIS-MIB>

=item F<ENVIRONMENT-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::MAU/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar values from SNMP

=over

=item $tasman->vendor()

Returns C<'avaya'>

=item $tasman->model()

Tries to get the model from C<nnchassisModel> and if not available 
cross references $tasman->id() to F<NT-ENTERPRISE-DATA-MIB>.

Substitutes 'SR' for C<'ntSecureRouter'> in the name for readability.

=item $tasman->os()

Returns C<'tasman'>

=item $tasman->os_ver()

Grabs the os version from C<nnsysVersion>

=item $tasman->ps1_type()

(C<nnenvPwrsupType.1>)

=item $tasman->ps1_status()

(C<nnenvPwrsupStatus.1>)

=item $tasman->ps2_type()

(C<nnenvPwrsupType.2>)

=item $tasman->ps2_status()

(C<nnenvPwrsupStatus.2>)

=item $tasman->nn_sys_ver()

(C<nnsysVersion.0>)

=item $tasman->nn_ch_model()

(C<nnchassisModel.0>)

=item $tasman->nn_ch_op_stat()

(C<nnchassisOperStatus.0>)

=item $tasman->nn_ch_serial()

(C<nnchassisSerialNumber.0>)

=item $tasman->serial()

Tries both (C<nnchassisOperStatus>) and (C<nnchassisSerialNumber>) as oid
was redefined between versions.

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over 4

=item $tasman->i_duplex_admin()

Returns reference to hash of iid to administrative duplex setting.

First checks for fixed gigabit ports which are always full duplex. Next checks
the port administrative speed (C<portAdminSpeed>) which if set to
autonegotiate then the duplex will also autonegotiate, otherwise it uses the
reported port duplex (C<portDuplex>).

=item $tasman->i_speed_admin()

Returns reference to hash of iid to administrative speed setting.

C<portAdminSpeed>

=back

=head2 Pseudo F<ENTITY-MIB> information

These methods emulate F<ENTITY-MIB> Physical Table methods using
F<CHASSIS-MIB>. 

=over

=item $tasman->e_index()

Returns reference to hash.  Key: IID, Value: Integer.

=item $tasman->e_class()

Returns reference to hash.  Key: IID, Value: General hardware type.

=item $tasman->e_descr()

Returns reference to hash.  Key: IID, Value: Human friendly name

=item $tasman->e_vendor()

Returns reference to hash.  Key: IID, Value: avaya

=item $tasman->e_serial()

Returns reference to hash.  Key: IID, Value: Serial number

=item $tasman->e_pos()

Returns reference to hash.  Key: IID, Value: The relative position among all
entities sharing the same parent.

=item $tasman->e_type()

Returns reference to hash.  Key: IID, Value: Type of component/sub-component.

=item $tasman->e_parent()

Returns reference to hash.  Key: IID, Value: The value of e_index() for the
entity which 'contains' this entity.  A value of zero indicates	this entity
is not contained in any other entity.

=item $entity->e_fru()

BOOLEAN. Is a Field Replaceable unit?

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"TABLE METHODS"> for details.

=cut
