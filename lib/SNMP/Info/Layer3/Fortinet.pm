# SNMP::Info::Layer3::Fortinet
#
# Copyright (c) 2014 Eric Miller
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

package SNMP::Info::Layer3::Fortinet;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::Aggregate 'agg_ports_ifstack';

@SNMP::Info::Layer3::Fortinet::ISA = qw/
    SNMP::Info::Layer3
    SNMP::Info::Aggregate
    Exporter
/;
@SNMP::Info::Layer3::Fortinet::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %FUNCS, %MIBS, %MUNGE);

$VERSION = '3.985002';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::Aggregate::MIBS,
    'FORTINET-CORE-MIB'      => 'fnSysSerial',
    'FORTINET-FORTIGATE-MIB' => 'fgVdMaxVdoms',
    'FORTINET-FORTIMANAGER-FORTIANALYZER-MIB' => 'fmSysVersion',
    'FORTINET-FORTIAUTHENTICATOR-MIB' => 'facSysVersion',
    'FORTINET-FORTISWITCH-MIB'        => 'fsSysVersion',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,

    # FORTINET-FORTISWITCH-MIB
    'fs_version' => 'fsSysVersion',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
);

sub vendor {
    return 'fortinet';
}

# fortios 5.4 and higher can have empty ifDescr. use ifName (but
# without the ifAlias fixup that's done in layer3::i_name()) which
# mimics fortios >5.4
# copied from an old Layer3.pm which did not have duplicate
# description fixup
sub interfaces {
    my $fortinet = shift;
    my $partial  = shift;

    my $interfaces   = $fortinet->i_index($partial);
    my $descriptions = $fortinet->orig_i_name($partial);

    my %interfaces = ();
    foreach my $iid ( keys %$interfaces ) {
        my $desc = $descriptions->{$iid};
        next unless defined $desc;

        $interfaces{$iid} = $desc;
    }

    return \%interfaces;
}

# FortiSwitches register under 12356.106.1, not under the MIB's fsModel
# branch (12356.106.5), so their sysObjectID does not translate to a model
sub _is_fortiswitch {
    my $fortinet = shift;
    my $id       = $fortinet->id() // '';

    return $id =~ /^\.?1\.3\.6\.1\.4\.1\.12356\.106(?:\.|$)/;
}

# fsSysVersion is "FortiSwitch-<model> v<version>,build...":
# "FortiSwitch-148F-FPOE v7.6.0,build1015,240812 (GA)"
sub _fs_version_parts {
    my $fortinet = shift;
    my $version  = $fortinet->fs_version() // '';

    return $version =~ /^FortiSwitch-(\S+)\s+v(\d+(?:\.\d+)+)/;
}

sub model {
    my $fortinet = shift;

    if ( $fortinet->_is_fortiswitch() ) {
        my ($model) = $fortinet->_fs_version_parts();
        return "FS-$model" if defined $model;
    }

    my $id = $fortinet->id() || '';

    my $model = &SNMP::translateObj($id);

    return $id unless defined $model;

    $model =~ s/^f[grsw][tfw]?//i;
    return $model;
}

sub os {
    return 'fortios';
}

sub os_ver {
    my $fortinet = shift;

    if ( $fortinet->_is_fortiswitch() ) {
        my ( undef, $version ) = $fortinet->_fs_version_parts();
        return $version if defined $version;
    }

    my $ver = $fortinet->fgSysVersion() || $fortinet->fmSysVersion() || $fortinet->facSysVersion() || '';

    if ( $ver =~ /(\d+[\.\d]+)/ ) {
        return $1;
    }

    return $ver;
}

sub serial {
    my $fortinet = shift;

    # FortiSwitches serve no fnSysSerial; their serial is the base entity's
    return $fortinet->fnSysSerial() || $fortinet->SUPER::serial();
}

# FortiSwitch management address rows name other local ports and remote
# indexes than the neighbor rows they belong to, so none can be trusted.
# A chassis ID that is an address is taken from the neighbor row itself;
# every other neighbor gets 0.0.0.0, which Netdisco resolves by looking up
# its chassis ID among known devices.
sub lldp_ip {
    my $fortinet = shift;
    my $partial  = shift;

    return $fortinet->SUPER::lldp_ip($partial)
        unless $fortinet->_is_fortiswitch();

    my $id_types = $fortinet->_lldp_rem( 'lldp_rem_id_type', $partial );
    my $ids      = $fortinet->lldp_id($partial) || {};

    my %lldp_ip;
    foreach my $key ( keys %$id_types ) {
        my $id = $ids->{$key} // '';
        $lldp_ip{$key}
            = (     $id_types->{$key} eq 'networkAddress'
                and $id =~ /^\d{1,3}(?:\.\d{1,3}){3}$/ )
            ? $id
            : '0.0.0.0';
    }
    return \%lldp_ip;
}

# FortiSwitches can serve one neighbor's lldpRemTable columns under
# different time marks, so its rows share no key across columns. The local
# port and remote index identify the neighbor; where two time marks give
# the same neighbor, the later row is kept.
sub _lldp_rem {
    my ( $fortinet, $method, $partial ) = @_;

    my $rows = $fortinet->SUPER::_lldp_rem( $method, $partial );
    return $rows unless $fortinet->_is_fortiswitch();

    my @keys
        = sort { _lldp_time_mark($a) <=> _lldp_time_mark($b) } keys %$rows;
    my %rows;
    foreach my $key (@keys) {
        next unless $key =~ /^\d+\.(\d+(?:\.\d+)*)$/;
        $rows{"0.$1"} = $rows->{$key};
    }
    return \%rows;
}

sub _lldp_time_mark {
    my $key = shift;

    return $key =~ /^(\d+)\./ ? $1 : 0;
}

# A FortiSwitch's LLDP chassis ID, which its neighbors report, is one
# below the address of its first interface
sub mac {
    my $fortinet = shift;

    if ( $fortinet->_is_fortiswitch() ) {
        my $type    = $fortinet->lldp_loc_id_type() // '';
        my $chassis = $type =~ /mac/ ? $fortinet->lldp_loc_id() : undef;
        return $chassis
            if defined $chassis
            and $chassis =~ /^(?:[0-9a-f]{2}:){5}[0-9a-f]{2}$/;
    }
    return $fortinet->SUPER::mac();
}

sub lldp_ipv6 {
    my $fortinet = shift;
    my $partial  = shift;

    return $fortinet->SUPER::lldp_ipv6($partial)
        unless $fortinet->_is_fortiswitch();
    return {};
}

sub agg_ports { return agg_ports_ifstack(@_) }

sub _agg_ports_walked { return qw/ifStackStatus ifType/ }

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Fortinet - SNMP Interface to Fortinet network devices.

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $fortinet = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $fortinet->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for Fortinet network devices.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::Aggregate

=back

=head2 Required MIBs

=over

=item F<FORTINET-CORE-MIB>

=item F<FORTINET-FORTIAUTHENTICATOR-MIB>

=item F<FORTINET-FORTIMANAGER-FORTIANALYZER-MIB>

=item F<FORTINET-FORTIGATE-MIB>

=item F<FORTINET-FORTISWITCH-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::Aggregate/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $fortinet->vendor()

Returns 'fortinet'

=item $fortinet->model()

Returns the chassis model. For a FortiSwitch, the model named in
C<fsSysVersion> with an C<FS-> prefix (C<FS-148F-FPOE>); its
C<sysObjectID> does not translate to a model name.

=item $fortinet->os()

Returns 'fortios'

=item $fortinet->os_ver()

Returns the software version extracted from the Fortinet MIB in this order:

(C<fgSysVersion>)
(C<fmSysVersion>)
(C<facSysVersion>)

For a FortiSwitch, the version in C<fsSysVersion> (C<7.6.0> from
C<FortiSwitch-148F-FPOE v7.6.0,build1015,240812 (GA)>).

=item $fortinet->serial()

Returns the chassis serial number, from C<fnSysSerial> or, on devices
that do not serve it such as FortiSwitches, the ENTITY-MIB chassis entry.

(C<fnSysSerial>)

=item $fortinet->fs_version()

(C<fsSysVersion>)

=item $fortinet->mac()

For a FortiSwitch, the LLDP chassis ID when it is a MAC address. This is
the address its neighbors report, one below the address of its first
interface. Other devices, and FortiSwitches without a MAC chassis ID,
return the inherited C<mac()>.

(C<lldpLocChassisId>)

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $fortinet->interfaces();

Returns the map between SNMP Interface Identifier (iid) and C<ifName>.

=item C<agg_ports>

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.

=item $fortinet->lldp_ip()

Returns reference to hash. On a FortiSwitch, management address rows name
other local ports and remote indexes than the neighbor rows, so none is
used. A neighbor whose chassis ID is an IPv4 address returns that address;
every other neighbor returns C<0.0.0.0>, and the calling application then
identifies it by its chassis ID. Other devices return the inherited
C<lldp_ip()>.

On a FortiSwitch, the keys of every LLDP neighbor method begin with C<0>
in place of the time mark, since the switch can serve one neighbor's
columns under different time marks.

=item $fortinet->lldp_ipv6()

Returns reference to hash. Empty on a FortiSwitch, for the same reason;
the inherited C<lldp_ipv6()> otherwise.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
