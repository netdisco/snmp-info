# SNMP::Info::Layer3::DLink - SNMP Interface to DLink Devices
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

package SNMP::Info::Layer3::DLink;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::DLink::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::DLink::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %FUNCS, %MIBS, %MUNGE);

$VERSION = '3.70';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'DLINK-ID-REC-MIB' => 'dlink',
    'SWPRIMGMT-DES3200-MIB' => 'dlink-des3200SeriesProd',
    'SWPRIMGMT-DES30XXP-MIB' => 'dlink-des30xxproductProd',
    'SWPRIMGMT-DES1228ME-MIB' => 'dlink-des1228MEproductProd',
    'SWDES3528-52PRIMGMT-MIB' => 'dlink-Des3500Series',
    'DES-1210-28-AX' => 'des-1210-28ax',
    'DES-1210-10MEbx' => 'des-1210-10mebx',
    'DES-1210-26MEbx' => 'des-1210-26mebx',
    'DES-1210-52-BX' => 'des-1210-52bx',
    'DES-1210-52-CX' => 'des-1210-52-cx',
    'DGS-1210-24-AX' => 'dgs-1210-24ax',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    'dlink_fw' => 'probeSoftwareRev',
    'dlink_hw' => 'probeHardwareRev',
    # Replaced with OID since these MIBs are no longer in the netdisco-mibs
    # collection. Commit reference of MIB removal in netdisco-mibs:
    # d6ec3f15861e28d220a681e7fa3b222c21664fda
    'dlink_stp_i_root_port' => '.1.3.6.1.4.1.171.12.15.2.3.1.18',
    'dlink_serial_no' => '.1.3.6.1.4.1.171.12.1.1.12',
    # TODO: hardcoded OIDs using get() in method calls below should be
    # replaced similarly and use the library getter methods
);

%MUNGE = ( %SNMP::Info::Layer3::MUNGE, );

sub model {
    my $dlink=shift;
    my $id = $dlink->id();
    my $model = &SNMP::translateObj($id);
    return $id unless defined $model;
    if (defined $model && $model !~ /dlink-products/) {
	return $model;
    } else {
    	#If don't have a device MIB
	return $dlink->description();
    }
}

# ifDescr is the same for all interfaces in a class, but the ifName is
# unique, so let's use that for port name.
sub interfaces {
    my $dlink = shift;
    my $partial = shift;

    my $interfaces = $dlink->orig_i_name($partial);
    return $interfaces;
}


sub vendor {
    return 'dlink';
}

sub serial {
    my $dlink = shift;
    my $model = $dlink->model();
    my $id = $dlink->id();
    my $serial;
    if ($model =~ /1210/) {
	#Due to the zoo of MIB from DLink by 1210 series
	$serial->{0} = $dlink->session()->get($id.'.1.30.0');
    } else {
	$serial = $dlink->dlink_serial_no();
    }

    return $serial->{0} if ( defined $serial->{0} and $serial->{0} !~ /^\s*$/ and $serial->{0} !~ 'NOSUCHOBJECT' );
    return $dlink->SUPER::serial();
}

sub fwver {
    my $dlink=shift;
    my $model = $dlink->model();
    my $id = $dlink->id();
    my $fw;
    if ($model =~ /1210/) {
	#Due to the zoo of MIB from DLink by 1210 series
	$fw->{0} = $dlink->session()->get($id.'.1.3.0');
    } else {
	$fw = $dlink->dlink_fw();
    }
    return $fw->{0} if ( defined $fw->{0} and $fw->{0} !~ /^\s*$/ and $fw->{0} !~ 'NOSUCHOBJECT');
}

sub hwver {
    my $dlink=shift;
    my $model = $dlink->model();
    my $id = $dlink->id();
    my $hw;
    if ($model =~ /1210/) {
	#Due to the zoo of MIB from DLink by 1210 series
	$hw->{0} = $dlink->session()->get($id.'.1.2.0');
    } else {
	$hw = $dlink->dlink_hw();
    }
    return $hw->{0} if ( defined $hw->{0} and $hw->{0} !~ /^\s*$/ and $hw->{0} !~ 'NOSUCHOBJECT');
}

sub stp_i_root_port {
    my $dlink=shift;
    my $model = $dlink->model();
    my $id = $dlink->id();
    my $stp_i_root_port;
    if ($model =~ /1210-(?:10|26)/) {
	#Due to the zoo of MIB from DLink by 1210 series
	$stp_i_root_port->{0} = $dlink->session()->get($id.'.6.1.13.0');
    } else {
	$stp_i_root_port = $dlink->dlink_stp_i_root_port();
    }
    return $stp_i_root_port if ( defined $stp_i_root_port->{0} and $stp_i_root_port->{0} !~ /^\s*$/ and $stp_i_root_port->{0} !~ 'NOSUCHOBJECT');
    return $dlink->SUPER::stp_i_root_port();
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::DLink - SNMP Interface to DLink Devices

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $dlink = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $dlink->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for DLink devices.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<DLINK-ID-REC-MIB>

=item F<SWPRIMGMT-DES3200-MIB>

=item F<SWPRIMGMT-DES30XXP-MIB>

=item F<SWPRIMGMT-DES1228ME-MIB>

=item F<SWDES3528-52PRIMGMT-MIB>

=item F<DES-1210-28-AX>

=item F<DES-1210-10MEbx>

=item F<DES-1210-26MEbx>

=item F<DES-1210-52-BX>

=item F<DES-1210-52-CX>

=item F<DGS-1210-24-AX>

=back

=head2 Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $dlink->model()

Returns the ID or else description.

=item $dlink->vendor()

Returns 'dlink'.

=item $dlink->serial()

Returns serial number.

=item $dlink->fwver()

Returns the firmware version.

=item $dlink->hwver()

Returns the hardware version.

=item $dlink->stp_i_root_port()

Returns the STP root port.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $dlink->interfaces();

Returns the map between SNMP Interface Identifier (iid) and C<ifName>.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
