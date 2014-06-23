# SNMP::Info::Layer3::Force10
# $Id$
#
# Copyright (c) 2012 William Bulley
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
#     * Neither the name of University of California, Santa Cruz nor the
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

package SNMP::Info::Layer3::Force10;

use strict;
use Exporter;

use SNMP::Info::Layer3;
use SNMP::Info::MAU;
use SNMP::Info::LLDP;

@SNMP::Info::Layer3::Force10::ISA = qw/SNMP::Info::LLDP SNMP::Info::MAU
    SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Force10::EXPORT_OK = qw//;

use vars qw/$VERSION $DEBUG %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.17';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::MAU::MIBS,
    %SNMP::Info::LLDP::MIBS,
    'F10-PRODUCTS-MIB' => 'f10Products',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::MAU::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::MAU::FUNCS,
    %SNMP::Info::LLDP::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::MAU::MUNGE,
    %SNMP::Info::LLDP::MUNGE,
);

# use MAU-MIB for admin. duplex and admin. speed
*SNMP::Info::Layer3::Force10::i_duplex_admin
    = \&SNMP::Info::MAU::mau_i_duplex_admin;
*SNMP::Info::Layer3::Force10::i_speed_admin
    = \&SNMP::Info::MAU::mau_i_speed_admin;

sub vendor {
    return 'force10';
}

sub os {
    return 'ftos';
}

sub os_ver {
    my $force10 = shift;
    my $descr   = $force10->description();
    my $os_ver  = undef;

    $os_ver = $1 if ( $descr =~ /Force10\s+Application\s+Software\s+Version:\s+(\S+)/s );

    return $os_ver;
}

sub model {
    my $force10 = shift;
    my $id      = $force10->id();

    my $model = &SNMP::translateObj($id);
    return $id unless defined $model;

    return $model;
}

sub v_name {
    my $force10 = shift;
    my $partial = shift;

    return $force10->qb_v_name($partial);
}

# ------------------- stub for now-----------------
sub i_vlan {
    my $force10 = shift;
    my $partial = shift;

    my $i_vlan = {};

    return $i_vlan;
}

sub i_vlan_membership {
    my $force10 = shift;
    my $partial = shift;

    my $index = $force10->bp_index();
    my $v_index = $force10->v_index();

    my $v_ports  = $force10->qb_v_egress();

    # If given a partial it will be an ifIndex, we need to use dot1dBasePort
    if ($partial) {
        my %r_index = reverse %$index;
        $partial    = $r_index{$partial};
    }

    my $i_vlan_membership = {};

    foreach my $idx ( sort keys %{$v_ports} ) {
        next unless ( defined $v_ports->{$idx} );
        my $portlist = $v_ports->{$idx}; # is an array reference
        my $ret      = [];
        my $vlan_ndx = $idx;

        # Convert portlist bit array to bp_index array
        for ( my $i = 0; $i <= $#$portlist; $i++ ) {
            push( @{$ret}, $i + 1 ) if ( @$portlist[$i] );
        }

        #Create HoA ifIndex -> VLAN array
        foreach my $port ( @{$ret} ) {
            my $ifindex = $index->{$port};
            next unless ( defined($ifindex) );    # shouldn't happen
            next if ( defined $partial and $ifindex !~ /^$partial$/ );
            my $vlan_tag = $v_index->{$vlan_ndx};

            # FIXME: would be preferable to use
            # the mapping from Q-BRIDGE-MIB::dot1qVlanFdbId 
            my $mod = $vlan_tag % 4096;

            push ( @{ $i_vlan_membership->{$ifindex} }, ($mod) );
        }
    }

    return $i_vlan_membership;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer3::Force10 - SNMP Interface to Force10 Networks FTOS

=head1 AUTHOR

William Bulley

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $force10 = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $force10->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Force10 Networks FTOS-based devices.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::MAU

=item SNMP::Info::LLDP

=back

=head2 Required MIBs

=over

=item F<F10-PRODUCTS-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::MAU/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::LLDP/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar values from SNMP:

=over

=item $force10->vendor()

Returns C<'force10'>

=item $force10->model()

Tries to reference $force10->id() to the Force10 product MIB listed above.

=item $force10->os()

Returns C<'ftos'>.

=item $force10->os_ver()

Grabs the operating system version from C<sysDescr>

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $force10->v_name()

Returns the VLAN names.

=item $force10->i_vlan()

Currently not implemented.

=item $force10->i_vlan_membership()

Returns reference to hash of arrays:
key = C<ifIndex>, value = array of VLAN IDs.
These are the VLANs which are members of the egress list for the port.

=item $force10->i_duplex_admin()

Returns info from F<MAU-MIB>

=item $force10->i_speed_admin()

Returns info from F<MAU-MIB>

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"TABLE METHODS"> for details.

=cut
