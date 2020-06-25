# SNMP::Info::Layer3::CheckPoint
#
# Copyright (c) 2008 Bill Fenner
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

package SNMP::Info::Layer3::CheckPoint;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::CheckPoint::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::CheckPoint::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.70';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'CHECKPOINT-MIB'      => 'fwProduct',
    'UCD-SNMP-MIB'        => 'versionTag',
    'NET-SNMP-TC'         => 'netSnmpAliasDomain',
    'NET-SNMP-EXTEND-MIB' => 'nsExtendNumEntries',
    'HOST-RESOURCES-MIB'  => 'hrSystem',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'netsnmp_vers'   => 'versionTag',
    'hrSystemUptime' => 'hrSystemUptime',
    'serial_number'  => 'svnApplianceSerialNumber',
    'product_name'   => 'svnApplianceProductName',
    'manufacturer'   => 'svnApplianceManufacturer',
    'version'        => 'svnVersion',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,

    # Net-SNMP Extend table that could but customize to add a the CheckPoint version
    'extend_output_table' => 'nsExtendOutputFull',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
);

sub vendor {
    my $ckp = shift;

    if (defined $ckp->manufacturer) {
        return lc $ckp->manufacturer;
    } else {
        return 'checkpoint';
    }
}

sub model {
    my $ckp = shift;
    my $id = $ckp->id;

    my $model = &SNMP::translateObj($id);

    if (defined $ckp->product_name) {
        return $ckp->product_name;
    } elsif (defined $model) {
        $model =~ s/^checkPoint//;
        return $model;
    } else {
        return $id;
    }
}

sub os {
    return 'checkpoint';
}

sub os_ver {
    my $ckp = shift;
    if (defined $ckp->version) {
        return $ckp->version;
    } else {
        my $extend_table = $ckp->extend_output_table() || {};

        my $descr   = $ckp->description();
        my $vers    = $ckp->netsnmp_vers();
        my $os_ver  = undef;

        foreach my $ex (keys %$extend_table) {
            (my $name = pack('C*',split(/\./,$ex))) =~ s/[^[:print:]]//g;
            if ($name eq 'ckpVersion') {
                return $1 if ($extend_table->{$ex} =~ /^This is Check Point's software version (.*)$/);
                last;
            }
        }

        $os_ver = $1 if ( $descr =~ /^\S+\s+\S+\s+(\S+)\s+/ );
        if ($vers) {
            $os_ver = "???" unless defined($os_ver);
            $os_ver .= " / Net-SNMP " . $vers;
        }
        return $os_ver;
    }
}

sub serial {
    my $ckp = shift;

    if (defined $ckp->serial_number) {
        return $ckp->serial_number;
    } else {
        my $extend_table = $ckp->extend_output_table() || {};

        foreach my $ex (keys %$extend_table) {
            (my $name = pack('C*',split(/\./,$ex))) =~ s/[^[:print:]]//g;
            if ($name eq 'ckpAsset') {
                return $1 if ($extend_table->{$ex} =~ /Serial Number: (\S+)/);
                last;
            }
        }
    }
    return '';
}

sub layers {
    return '01001100';
}

# sysUptime gives us the time since the SNMP daemon has restarted,
# so return the system uptime since that's probably what the user
# wants.  (Caution: this could cause trouble if using
# sysUptime-based discontinuity timers or other TimeStamp
# objects.
sub uptime {
    my $ckp = shift;
    my $uptime;

    $uptime = $ckp->hrSystemUptime();
    return $uptime if defined $uptime;

    return $ckp->SUPER::uptime();
}

sub i_ignore {
    my $l3      = shift;
    my $partial = shift;

    my $interfaces = $l3->interfaces($partial) || {};

    my %i_ignore;
    foreach my $if ( keys %$interfaces ) {

        # lo0 etc
        if ( $interfaces->{$if} =~ /\blo\d*\b/i ) {
            $i_ignore{$if}++;
        }
    }
    return \%i_ignore;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::CheckPoint - SNMP Interface to CheckPoint Devices

=head1 AUTHORS

Ambroise Rosset

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $ckp = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $ckp->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for CheckPoint Devices.

=head2 WARNING

To correctly and completely work on IPSO based devices, you should
add the following line in the file C</etc/snmp/snmpd.local.conf> on each
of your CheckPoint devices:

 # Netdisco SNMP configuration
 extend  ckpVersion /opt/CPsuite-R77/fw1/bin/fw ver
 extend  ckpAsset /bin/clish -c 'show asset all'

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<CHECKPOINT-MIB>

=item F<UCD-SNMP-MIB>

=item F<NET-SNMP-EXTEND-MIB>

=item F<NET-SNMP-TC>

=item F<HOST-RESOURCES-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $ckp->vendor()

Returns C<svnApplianceManufacturer> in lowercase, else 'checkpoint'.

=item $ckp->model()

Returns C<svnApplianceProductName>, else the model type based on the
sysObjectOID translation.

=item $ckp->os()

Returns the OS extracted from C<sysDescr>.

=item $ckp->os_ver()

Returns C<svnVersion>, else the software version is extracted from
C<sysDescr>, along with the Net-SNMP version.

=item $ckp->uptime()

Returns the system uptime instead of the agent uptime.
NOTE: discontinuity timers and other Time Stamp based objects
are based on agent uptime, so use orig_uptime().

=item $ckp->serial()

Returns <svnApplianceSerialNumber>, else the serial number of the
device if the SNMP server is configured as indicated previously.
Returns '' in other case.

=item $ckp->layers()

Return '01001100'.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $ckp->i_ignore()

Returns reference to hash.  Increments value of IID if port is to be ignored.

Ignores loopback

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head1 NOTES

If your device is not recognized by SNMP::Info as being in the class
L<SNMP::Info::Layer3::CheckPoint> you might need additional snmp
configuration on the CheckPoint device.

In order to cause SNMP::Info to classify your device into this class, it
may be necessary to put a configuration line into your F<snmpd.conf>
similar to

  sysobjectid .1.3.6.1.4.1.8072.3.2.N

where N is the object ID for your OS from the C<NET-SNMP-TC> MIB (or
255 if not listed).  Some Net-SNMP installations default to an
incorrect return value for C<system.sysObjectId>.

In order to recognize a Net-SNMP device as Layer3, it may be necessary
to put a configuration line similar to

  sysservices 76

in your F<snmpd.conf>.

=cut
