package SNMP::Info::Layer3::DLink;

use strict;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::LLDP;

@SNMP::Info::Layer3::DLink::ISA       = qw/SNMP::Info::LLDP SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::DLink::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %FUNCS %MIBS %MUNGE/;

$VERSION = '3.49';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::LLDP::MIBS,
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
    %SNMP::Info::LLDP::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::LLDP::FUNCS,
    'dlink_fw' => 'probeSoftwareRev',
    'dlink_hw' => 'probeHardwareRev',
    'dlink_stp_i_root_port' => 'MSTP_MIB__swMSTPInstRootPort',
    'dlink_serial_no' => 'AGENT_GENERAL_MIB__agentSerialNumber',
);

%MUNGE = ( %SNMP::Info::Layer3::MUNGE, %SNMP::Info::LLDP::MUNGE, );

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

Subclass for Vyatta Devices running dlink.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::LLDP

=back

=head2 Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::LLDP/"Required MIBs"> for its own MIB requirements.

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

See documentation in L<SNMP::Info::LLDP/"GLOBALS"> for details.

=head1 TABLE METHODS

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

See documentation in L<SNMP::Info::LLDP/"TABLE METHODS"> for details.

=cut
