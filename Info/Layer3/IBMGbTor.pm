# SNMP::Info::Layer3::IBMGbTor - SNMP Interface to IBM Rackswitch devices
# $Id$
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
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::LLDP;

@SNMP::Info::Layer3::IBMGbTor::ISA
    = qw/SNMP::Info::LLDP SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::IBMGbTor::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %FUNCS %MIBS %MUNGE/;

$VERSION = '3.16';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,

    # LLDP MIBs not loaded to prevent possible unqualified namespace conflict
    # with IBM definitions
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
    'lldp_rem_id_type'  => 'lldpInfoRemoteDevicesChassisSubtype',
    'lldp_rem_id'       => 'lldpInfoRemoteDevicesSystemName',
    'lldp_rem_pid_type' => 'lldpInfoRemoteDevicesPortSubtype',
    'lldp_rem_pid'      => 'lldpInfoRemoteDevicesPortId',
    'lldp_rem_desc'     => 'lldpInfoRemoteDevicesPortDescription',
    'lldp_rem_sysname'  => 'lldpInfoRemoteDevicesSystemName',
    'lldp_rem_sysdesc'  => 'lldpInfoRemoteDevicesSystemDescription',
    'lldp_rem_sys_cap'  => 'lldpInfoRemoteDevicesSystemCapEnabled',

    # IBM-GbTOR-10G-L2L3-MIB::lldpInfoRemoteDevicesManAddrTable
    'lldp_rman_type' => 'lldpInfoRemoteDevicesManAddrSubtype',
    'lldp_rman_addr' => 'lldpInfoRemoteDevicesManAddr',
);

%MUNGE = ( %SNMP::Info::Layer3::MUNGE, %SNMP::Info::LLDP::MUNGE, );

sub hasLLDP {
    my $ibm = shift;

    # We may be have LLDP, but nothing in lldpRemoteSystemsData Tables
    # Look to see if LLDP Rx enabled on any port
    my $lldp_cap = $ibm->lldp_port_status();

    foreach my $if ( keys %$lldp_cap ) {
        if ( $lldp_cap->{$if} =~ /enabledRx/i ) {
            return 1;
        }
    }
    return;
}

sub lldp_ip {
    my $ibm     = shift;
    my $partial = shift;

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

sub lldp_if {
    my $lldp    = shift;
    my $partial = shift;

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

SNMP::Info::Layer3::IBMGbTor - SNMP Interface to IBM Rackswitch devices

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $ibm = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 1
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class = $ibm->class();

 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for IBM Rackswitch (formerly Blade Network Technologies)
network devices.

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above.

 my $ibm = new SNMP::Info::Layer3::IBMGbTor(...);

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

Checks to see if at least one interface is enabled to receive LLDP packets.

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

=item $ibm->lldp_if()

Returns the mapping to the SNMP Interface Table. Tries to cross reference 
(C<lldpInfoRemoteDevicesLocalPort>) with (C<ifDescr>) and (C<ifAlias>)
to get (C<ifIndex>).

=item $ibm->lldp_ip()

Returns remote IPv4 address.  Returns for all other address types, use
lldp_addr if you want any return address type.

=item $ibm->lldp_platform()

Returns remote device system description.

(C<lldpInfoRemoteDevicesSystemDescription>)

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"TABLE METHODS"> for details.

=cut
