package SNMP::Info::Layer3::JuniperEX;

# Copyright (c) 2011 David Baldwin
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

use strict;
use Exporter;
use SNMP::Info::Layer3::Juniper;
use SNMP::Info::LLDP;

@SNMP::Info::Layer3::JuniperEX::ISA
    = qw/SNMP::Info::Layer3::Juniper SNMP::Info::LLDP Exporter/;
@SNMP::Info::Layer3::JuniperEX::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '2.06';

%MIBS = (
    %SNMP::Info::Layer3::Juniper::MIBS,
    %SNMP::Info::LLDP::MIBS,
    'JUNIPER-VLAN-MIB' => 'jnxExVlanTag',
);

%GLOBALS = ( %SNMP::Info::Layer3::Juniper::GLOBALS, %SNMP::Info::LLDP::GLOBALS,  );

%FUNCS = ( %SNMP::Info::Layer3::Juniper::FUNCS, %SNMP::Info::LLDP::FUNCS, );

%MUNGE = ( %SNMP::Info::Layer3::Juniper::MUNGE, %SNMP::Info::LLDP::MUNGE, );

sub remap_idx {
    my $juniper = shift;
    my $remap = shift;
    my $vlan_map = $juniper->vlan_tag();

    return $remap unless $vlan_map;

    my %mapped = ();
    foreach my $tid (keys %$remap) {
        $mapped{$vlan_map->{$tid}} = $remap->{$tid};
    }

    return \%mapped;
}

sub remap_tag {
    my $juniper = shift;
    my $remap = shift;

    return undef unless defined $remap;
    my $vlan_map = $juniper->vlan_tag();

    if (ref {} eq ref $remap) {
        my %mapped;
        foreach my $tid (keys %$remap) {
            if (ref [] eq ref $remap->{$tid}) {
                my @remap = map {$vlan_map->{$_}} @{$remap->{$tid}};
                $mapped{$tid} = \@remap;
            } else {
                $mapped{$tid} = $vlan_map->{$remap->{$tid}};
            }
        }
        return \%mapped;
    }
    else {
        return $vlan_map->{$remap};
    }
}

sub vlan_tag {
    my ($juniper) = shift;
    my ($partial) = shift;

    my ($vlantags) = $juniper->jnxExVlanTag($partial);

    return undef unless keys %$vlantags;
    return $vlantags;
}

sub v_index {
    my ($juniper) = shift;
    my $vlantags = $juniper->vlan_tag;

    return $juniper->SUPER::v_index unless $vlantags;
    
    my %v_index;
    foreach my $tid (keys %$vlantags) {
        $v_index{$vlantags->{$tid}} = $vlantags->{$tid};
    }

    return \%v_index;
}

sub qb_i_vlan {
    my ($juniper) = shift;
    my $remap = $juniper->SUPER::qb_i_vlan;
    my $vlan_map = $juniper->vlan_tag();

    return $remap unless $vlan_map;
    
    my %mapped;
    foreach my $tid (keys %$remap) {
        $mapped{$tid} = $vlan_map->{$remap->{$tid}} || '0';
    }

    return \%mapped;
}

sub v_name {
    my ($juniper) = shift;
    return $juniper->remap_idx( $juniper->SUPER::v_name );
}

sub qb_v_name {
    my ($juniper) = shift;
    return $juniper->v_name;
}

sub qb_v_egress {
    my ($juniper) = shift;
    return $juniper->remap_idx( $juniper->SUPER::qb_v_egress );
}

sub qb_v_fbdn_egress {
    my ($juniper) = shift;
    return $juniper->remap_idx( $juniper->SUPER::qb_v_fbdn_egress );
}

sub qb_v_untagged {
    my ($juniper) = shift;
    return $juniper->remap_idx( $juniper->SUPER::qb_v_untagged );
}

sub qb_v_stat {
    my ($juniper) = shift;
    return $juniper->remap_idx( $juniper->SUPER::qb_v_stat );
}

sub qb_fw_port {
    my ($juniper) = shift;
    return $juniper->remap_idx( $juniper->SUPER::qb_fw_port );
}

sub qb_fw_status {
    my ($juniper) = shift;
    return $juniper->remap_idx( $juniper->SUPER::qb_fw_status );
}

sub i_vlan {
    my ($juniper) = shift;
    my ($partial) = shift;

    my ($qb_i_vlan) = $juniper->qb_i_vlan($partial);
    my ($i_type) = $juniper->i_type($partial);
    my ($i_descr) = $juniper->i_description($partial);
    my %i_vlan;

    foreach my $idx ( keys %$i_descr ) {
        if ( defined $qb_i_vlan->{$idx} ) {
            $i_vlan{$idx} = $qb_i_vlan->{$idx};
        } elsif ( $i_type->{$idx} eq 'l2vlan' || $i_type->{$idx} eq 135 ) {
            if ( $i_descr->{$idx} =~ /\.(\d+)$/ ) {
                $i_vlan{$idx} = $1;
            }
        }
    }
    return \%i_vlan;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::JuniperEX - SNMP Interface to Juniper EX series switche Devices

=head1 AUTHOR

David Baldwin

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $juniper = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $juniper->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Juniper EX series switches running JUNOS

All the Q-BRIDGE-MIB methods are overridden due to a re-mapping of VLAN tags
to index numbers in the standard MIB.  Remap everything back to being indexed
by VLAN tag.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3::Juniper

=back

=head2 Required MIBs

=over

=item F<JUNIPER-VLAN-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3::Juniper/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3::Juniper/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $juniper->i_vlan()

Returns the list of interfaces whose C<ifType> is l2vlan(135), and
the VLAN ID extracted from the interface description.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
