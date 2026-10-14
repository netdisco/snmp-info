# SNMP::Info::Layer3::IBMGbTor - SNMP Interface to IBM Rackswitch devices
#
# Copyright (c) 2013 Eric Miller
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

package SNMP::Info::Layer3::IBMGbTor;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::IBMGbTor::ISA
    = qw/SNMP::Info::LLDP SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::IBMGbTor::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %FUNCS, %MIBS, %MUNGE);

$VERSION = '3.979000';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,

    # Standard LLDP-MIB comes from Layer3; this table is the fallback
    'IBM-GbTOR-10G-L2L3-MIB' => 'lldpInfoRemoteDevicesLocalPort',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,
    'temp' => 'hwTempSensors',
    'fan'  => 'hwFanSpeed',

    # Can't find the equivalent in IBM-GbTOR-10G-L2L3-MIB
    # use a different strategy for lldp_sys_cap in hasLLDP()
    #'lldp_sysname' => 'lldpLocSysName',
    #'lldp_sysdesc' => 'lldpLocSysDesc',
    #'lldp_sys_cap' => 'lldpLocSysCapEnabled',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::LLDP::FUNCS,

    # IBM-GbTOR-10G-L2L3-MIB::portInfoTable
    'sw_duplex' => 'portInfoMode',

    # Can't find the equivalent in IBM-GbTOR-10G-L2L3-MIB
    # not currently used in LLDP class
    #'lldp_lman_addr' => 'lldpLocManAddrIfId',

    # IBM-GbTOR-10G-L2L3-MIB::lldpInfoPortTable
    'lldp_port_status' => 'lldpInfoPortAdminStatus',

    # IBM-GbTOR-10G-L2L3-MIB::lldpInfoRemoteDevicesTable
    'ibm_lldp_rem_id_type'  => 'lldpInfoRemoteDevicesChassisSubtype',
    'ibm_lldp_rem_id'       => 'lldpInfoRemoteDevicesSystemName',
    'ibm_lldp_rem_pid_type' => 'lldpInfoRemoteDevicesPortSubtype',
    'ibm_lldp_rem_pid'      => 'lldpInfoRemoteDevicesPortId',
    'ibm_lldp_rem_desc'     => 'lldpInfoRemoteDevicesPortDescription',
    'ibm_lldp_rem_sysname'  => 'lldpInfoRemoteDevicesSystemName',
    'ibm_lldp_rem_sysdesc'  => 'lldpInfoRemoteDevicesSystemDescription',
    'ibm_lldp_rem_sys_cap'  => 'lldpInfoRemoteDevicesSystemCapEnabled',

    # IBM-GbTOR-10G-L2L3-MIB::lldpInfoRemoteDevicesManAddrTable
    'lldp_rman_type'     => 'lldpInfoRemoteDevicesManAddrSubtype',
    'ibm_lldp_rman_addr' => 'lldpInfoRemoteDevicesManAddr',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::LLDP::MUNGE,
    'ibm_lldp_rem_sysname' => \&SNMP::Info::munge_null,
    'ibm_lldp_rem_sysdesc' => \&SNMP::Info::munge_null,
    'ibm_lldp_rem_sys_cap' => \&SNMP::Info::munge_bits,
);

sub hasLLDP {
    my $ibm = shift;

    return 1 if $ibm->SUPER::hasLLDP();

    # We may be have LLDP, but nothing in lldpRemoteSystemsData Tables
    # Look to see if LLDP Rx enabled on any port
    my $lldp_cap = $ibm->lldp_port_status() || {};

    foreach my $if ( keys %$lldp_cap ) {
        if ( $lldp_cap->{$if} =~ /enabledRx/i ) {
            return 1;
        }
    }
    return;
}

# Decided once per device so neighbor keys never mix. Only the G8124 serves
# the IBM-GbTOR-10G-L2L3-MIB neighbor table, so LLDP-MIB rows take precedence.
# Memoized because an empty walk is not cached; clear_cache resets it.
sub _ibm_lldp_standard {
    my $ibm = shift;

    return $ibm->{_ibm_lldp_standard} if exists $ibm->{_ibm_lldp_standard};
    my $rem_id = $ibm->SUPER::lldp_rem_id() || {};
    return $ibm->{_ibm_lldp_standard} = scalar keys %$rem_id ? 1 : 0;
}

sub _ibm_lldp_column {
    my ( $ibm, $column, $partial ) = @_;

    my $method = $ibm->_ibm_lldp_standard ? "SUPER::$column" : "ibm_$column";
    return $ibm->$method($partial);
}

sub lldp_rem_id_type {
    my ( $ibm, $partial ) = @_;
    return $ibm->_ibm_lldp_column( 'lldp_rem_id_type', $partial );
}

sub lldp_rem_id {
    my ( $ibm, $partial ) = @_;
    return $ibm->_ibm_lldp_column( 'lldp_rem_id', $partial );
}

sub lldp_rem_pid_type {
    my ( $ibm, $partial ) = @_;
    return $ibm->_ibm_lldp_column( 'lldp_rem_pid_type', $partial );
}

sub lldp_rem_pid {
    my ( $ibm, $partial ) = @_;
    return $ibm->_ibm_lldp_column( 'lldp_rem_pid', $partial );
}

sub lldp_rem_desc {
    my ( $ibm, $partial ) = @_;
    return $ibm->_ibm_lldp_column( 'lldp_rem_desc', $partial );
}

sub lldp_rem_sysname {
    my ( $ibm, $partial ) = @_;
    return $ibm->_ibm_lldp_column( 'lldp_rem_sysname', $partial );
}

sub lldp_rem_sysdesc {
    my ( $ibm, $partial ) = @_;
    return $ibm->_ibm_lldp_column( 'lldp_rem_sysdesc', $partial );
}

sub lldp_rem_sys_cap {
    my ( $ibm, $partial ) = @_;
    return $ibm->_ibm_lldp_column( 'lldp_rem_sys_cap', $partial );
}

sub lldp_rman_addr {
    my ( $ibm, $partial ) = @_;
    return $ibm->_ibm_lldp_column( 'lldp_rman_addr', $partial );
}

sub lldp_ip {
    my $ibm     = shift;
    my $partial = shift;

    return $ibm->SUPER::lldp_ip($partial) if $ibm->_ibm_lldp_standard;

    my $rman_type = $ibm->lldp_rman_type($partial) || {};
    my $rman_addr = $ibm->lldp_rman_addr($partial) || {};

    my %lldp_ip;
    foreach my $key ( keys %$rman_addr ) {
        my $type = $rman_type->{$key};
        next unless defined $type;
        next unless $type eq 'ipV4';
        if ( $key =~ /^(\d+)\./ ) {
            $lldp_ip{$1} = $rman_addr->{$key};
        }
    }
    return \%lldp_ip;
}

# The LLDP-MIB local port number is the bridge port, and lldpLocPortDesc
# holds the port alias (XGE3), which matches neither ifDescr nor ifAlias.
sub _ibm_lldp_std_if {
    my ( $ibm, $partial ) = @_;

    my $inherited = $ibm->SUPER::lldp_if($partial) || {};
    my $bp_index  = $ibm->bp_index()               || {};

    my %lldp_if = %$inherited;
    foreach my $key ( keys %lldp_if ) {
        my $local_port = ( split /\./, $key )[1];
        $lldp_if{$key} = $bp_index->{$local_port}
            if defined $local_port and exists $bp_index->{$local_port};
    }
    return \%lldp_if;
}

sub lldp_if {
    my $lldp    = shift;
    my $partial = shift;

    return $lldp->_ibm_lldp_std_if($partial) if $lldp->_ibm_lldp_standard;

    my $lldp_desc = $lldp->lldpInfoRemoteDevicesLocalPort($partial) || {};
    my $i_descr   = $lldp->i_description()                          || {};
    my $i_alias   = $lldp->i_alias()                                || {};
    my %r_i_descr = reverse %$i_descr;
    my %r_i_alias = reverse %$i_alias;

    my %lldp_if;
    foreach my $key ( keys %$lldp_desc ) {

    # Cross reference lldpLocPortDesc with ifDescr and ifAlias to get ifIndex,
    # prefer ifAlias over ifDescr since MIB says 'alias'.
        my $desc = $lldp_desc->{$key};
        next unless $desc;
        my $port = $desc;

    # If cross reference is successful use it, otherwise stick with
    # lldpRemLocalPortNum
        if ( exists $r_i_alias{$desc} ) {
            $port = $r_i_alias{$desc};
        }
        elsif ( exists $r_i_descr{$desc} ) {
            $port = $r_i_descr{$desc};
        }

        $lldp_if{$key} = $port;
    }
    return \%lldp_if;
}

sub lldp_platform {
    my $ibm = shift;
    my $partial = shift;

    return $ibm->SUPER::lldp_platform($partial) if $ibm->_ibm_lldp_standard;
    return $ibm->lldpInfoRemoteDevicesSystemDescription($partial);
}

sub i_ignore {
    my $ibm     = shift;
    my $partial = shift;

    my $interfaces = $ibm->interfaces($partial) || {};

    my %i_ignore;
    foreach my $if ( keys %$interfaces ) {
        if ( $interfaces->{$if} =~ /(tunnel|loopback|\blo\b|lb|null)/i ) {
            $i_ignore{$if}++;
        }
    }
    return \%i_ignore;
}

sub i_duplex {
    my $ibm     = shift;
    my $partial = shift;

    return $ibm->sw_duplex($partial);
}

sub model {
    my $ibm   = shift;
    my $id    = $ibm->id();
    my $descr = $ibm->description();
    my $model = &SNMP::translateObj($id);

    if ( $descr =~ /RackSwitch\s(.*)/ ) {
        return $1;
    }

    return $model || $id;
}

sub os {
    return 'ibm';
}

# TODO: from os version 8 this should return lenovo
sub vendor {
    return 'ibm';
}

sub os_ver {
    my $ibm = shift;

    return $ibm->agSoftwareVersion();
}

sub interfaces {
    my $ibm     = shift;
    my $partial = shift;

    my $i_descr = $ibm->i_description($partial) || {};
    my $i_name  = $ibm->i_name($partial)        || {};

    foreach my $iid ( keys %$i_name ) {
        my $name = $i_name->{$iid};
        next unless defined $name;
        $i_descr->{$iid} = $name
            if $name =~ /^port\d+/i;
    }

    return $i_descr;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::IBMGbTor - SNMP Interface to Lenovo/IBM Rackswitch devices

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $ibm = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class = $ibm->class();

 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for IBM Rackswitch (formerly Blade Network Technologies)
network devices. Lenovo acquired these from IBM and is now selling
them under the Lenovo brand.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3;

=item SNMP::Info::LLDP;

=back

=head2 Required MIBs

=over

=item F<IBM-GbTOR-10G-L2L3-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $ibm->model()

Returns model type.  Attempts to pull model from device description.
Otherwise checks $ibm->id() against the F<IBM-GbTOR-10G-L2L3-MIB>.

=item $ibm->vendor()

Returns 'ibm'

=item $ibm->os()

Returns 'ibm'

=item $ibm->os_ver()

Returns the software version

(C<agSoftwareVersion>)

=item $ibm->temp()

(C<hwTempSensors>)

=item $ibm->fan()

(C<hwFanSpeed>)

=back

=head2 Overrides

=over

=item $ibm->hasLLDP()

Is LLDP is active in this device?

Note:  LLDP may be active, but nothing in C<lldpRemoteSystemsData> Tables so
the device would not return any useful topology information.

Returns true when the standard F<LLDP-MIB> reports LLDP. Otherwise checks to
see if at least one interface is enabled to receive LLDP packets.

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $ibm->interfaces()

Returns reference to hash of interface names to iids.

=item $ibm->i_ignore()

Returns reference to hash of interfaces to be ignored.

Ignores interfaces with descriptions of tunnel, loopback, and null.

=item $ibm->i_duplex()

Returns reference to hash of interface link duplex status.

(C<portInfoMode>)

=back

=head2 LLDP Neighbor Tables

Neighbors come from the standard F<LLDP-MIB> when C<lldpRemTable> has rows.
Otherwise they come from C<lldpInfoRemoteDevicesTable> in
F<IBM-GbTOR-10G-L2L3-MIB>, which only the G8124 serves. The choice is made
once per device, so neighbor keys never mix.

=over

=item $ibm->lldp_if()

Returns the mapping to the SNMP Interface Table.

From F<LLDP-MIB>, maps the local port number through C<dot1dBasePortIfIndex>,
since C<lldpLocPortDesc> holds the port alias. Otherwise tries to cross
reference (C<lldpInfoRemoteDevicesLocalPort>) with (C<ifDescr>) and
(C<ifAlias>) to get (C<ifIndex>).

=item $ibm->lldp_ip()

Returns remote IPv4 address.  Returns for all other address types, use
lldp_addr if you want any return address type.

=item $ibm->lldp_platform()

Returns remote device system description.

(C<lldpRemSysDesc> or C<lldpInfoRemoteDevicesSystemDescription>)

=item $ibm->lldp_rem_id_type()

(C<lldpRemChassisIdSubtype> or C<lldpInfoRemoteDevicesChassisSubtype>)

=item $ibm->lldp_rem_id()

(C<lldpRemChassisId> or C<lldpInfoRemoteDevicesSystemName>)

=item $ibm->lldp_rem_pid_type()

(C<lldpRemPortIdSubtype> or C<lldpInfoRemoteDevicesPortSubtype>)

=item $ibm->lldp_rem_pid()

(C<lldpRemPortId> or C<lldpInfoRemoteDevicesPortId>)

=item $ibm->lldp_rem_desc()

(C<lldpRemPortDesc> or C<lldpInfoRemoteDevicesPortDescription>)

=item $ibm->lldp_rem_sysname()

(C<lldpRemSysName> or C<lldpInfoRemoteDevicesSystemName>)

=item $ibm->lldp_rem_sysdesc()

(C<lldpRemSysDesc> or C<lldpInfoRemoteDevicesSystemDescription>)

=item $ibm->lldp_rem_sys_cap()

(C<lldpRemSysCapEnabled> or C<lldpInfoRemoteDevicesSystemCapEnabled>)

=item $ibm->lldp_rman_addr()

(C<lldpRemManAddrIfSubtype> or C<lldpInfoRemoteDevicesManAddr>)

=back

=head2 IBM LLDP Table Methods

=over

=item $ibm->lldp_port_status()

(C<lldpInfoPortAdminStatus>)

=item $ibm->lldp_rman_type()

(C<lldpInfoRemoteDevicesManAddrSubtype>)

=item $ibm->ibm_lldp_rem_id_type()

(C<lldpInfoRemoteDevicesChassisSubtype>)

=item $ibm->ibm_lldp_rem_id()

(C<lldpInfoRemoteDevicesSystemName>)

=item $ibm->ibm_lldp_rem_pid_type()

(C<lldpInfoRemoteDevicesPortSubtype>)

=item $ibm->ibm_lldp_rem_pid()

(C<lldpInfoRemoteDevicesPortId>)

=item $ibm->ibm_lldp_rem_desc()

(C<lldpInfoRemoteDevicesPortDescription>)

=item $ibm->ibm_lldp_rem_sysname()

(C<lldpInfoRemoteDevicesSystemName>)

=item $ibm->ibm_lldp_rem_sysdesc()

(C<lldpInfoRemoteDevicesSystemDescription>)

=item $ibm->ibm_lldp_rem_sys_cap()

(C<lldpInfoRemoteDevicesSystemCapEnabled>)

=item $ibm->ibm_lldp_rman_addr()

(C<lldpInfoRemoteDevicesManAddr>)

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"TABLE METHODS"> for details.

=cut
