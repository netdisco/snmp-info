# SNMP::Info::Layer2::Netgear
# $Id$
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

package SNMP::Info::Layer2::Netgear;

use strict;
use Exporter;
use SNMP::Info::Layer2;
use SNMP::Info::LLDP;

@SNMP::Info::Layer2::Netgear::ISA       = qw/SNMP::Info::LLDP SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::Netgear::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.22';

# This will be filled in with the device's index into the EntPhysicalEntry
# table by the serial() function.
our $index = undef;

%MIBS = ( %SNMP::Info::Layer2::MIBS, %SNMP::Info::LLDP::MIBS, );

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS, %SNMP::Info::LLDP::GLOBALS,
    ng_fsosver   => '.1.3.6.1.4.1.4526.11.11.1.0',
    ng_gsmserial => '.1.3.6.1.4.1.4526.10.1.1.1.4.0',
    ng_gsmosver  => '.1.3.6.1.4.1.4526.10.1.1.1.13.0',
);

%FUNCS = ( %SNMP::Info::Layer2::FUNCS, %SNMP::Info::LLDP::FUNCS, );

%MUNGE = ( %SNMP::Info::Layer2::MUNGE, %SNMP::Info::LLDP::MUNGE, );

sub vendor {
    return 'netgear';
}

sub os {
    return 'netgear';
}

# We will attempt to use Entity-MIB if present.  In that case, we will
# also set the shared variable $index, which is used by other functions
# to index within Entity-MIB tables. This assumes, of course, that there
# is only one serial number (entPhysicalSerialNum) present in the table.
sub serial {
    my $netgear = shift;
    my $serial = undef;
    
    my $e_serial = $netgear->e_serial();
    if (defined($e_serial)) { # This unit sports the Entity-MIB
        # Find entity table entry for this unit
        foreach my $e ( keys %$e_serial ) {
            if (defined ($e_serial->{$e}) and $e_serial->{$e} !~ /^\s*$/) {
                $index = $e;
                last;
            }
        }
        return $e_serial->{$index} if defined $index;
    }

    # Without Enitity-MIB, we've got to work our way through a bunch of
    # different locales...
    return $netgear->ng_gsmserial() if defined $netgear->model and $netgear->model =~ m/GSM\d/i;;
    return 'none';
}

# If device supports Entity-MIB, index into that to divine model and
# hardware version, otherwise default to sysDescr.
sub model {
    my $netgear = shift;
    if (defined($index)) {
        my $model   = $netgear->e_descr();
        my $e_hwver = $netgear->e_hwver();

        $model = "$model->{$index} $e_hwver->{$index}";
        return $model;
    }
    return $netgear->description();
}

# ifDescr is the same for all interfaces in a class, but the ifName is
# unique, so let's use that for port name.  If all else fails, 
# concatentate ifDesc and ifIndex.
sub interfaces {
    my $netgear = shift;
    my $partial = shift;

    my $interfaces = $netgear->i_index($partial)       || {};
    my $i_descr    = $netgear->i_description($partial) || {};
    my $i_name     = $netgear->i_name($partial);
    my $i_isset    = ();
    # Replace the description with the ifName field, if set
    foreach my $iid ( keys %$i_name ) {
        my $name = $i_name->{$iid};
        next unless defined $name;
        if (defined $name and $name !~ /^\s*$/) {
            $interfaces->{$iid} = $name;
            $i_isset->{$iid} = 1;
        }
    }
    # Replace the Index with the ifDescr field, appended with index
    # number, to deal with devices with non-unique ifDescr.
    foreach my $iid ( keys %$i_descr ) {
        my $port = $i_descr->{$iid} . '-' . $iid;
        next unless defined $port;
        next if (defined $i_isset->{$iid} and $i_isset->{$iid} == 1);
        $interfaces->{$iid} = $port;
    }

    return $interfaces;
}

# these seem to work for GSM models but not GS
# https://sourceforge.net/tracker/?func=detail&aid=3085413&group_id=70362&atid=527529
sub os_ver {
    my $netgear = shift;
    my $serial  = $netgear->serial(); # Make sure that index gets primed
    if (defined($index)) {
        my $os_ver  = $netgear->e_swver();
        return $os_ver->{$index} if defined $os_ver;
    }
    return $netgear->ng_gsmosver() if defined  $netgear->model and $netgear->model =~ m/GSM\d/i;
    return $netgear->ng_fsosver() if defined  $netgear->model and $netgear->model =~ m/FS\d/i;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer2::Netgear - SNMP Interface to Netgear switches

=head1 AUTHOR

 Bill Fenner and Zoltan Erszenyi, 
 Hacked in LLDP support from Baystack.pm by 
 Nic Bernstein <nic@onlight.com>

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $netgear = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $netgear->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a 
Netgear device through SNMP. See inherited classes' documentation for 
inherited methods.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2
=item SNMP::Info::Entity
=item SNMP::Info::LLDP

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

MIBs listed in L<SNMP::Info::Layer2/"Required MIBs"> and its inherited
classes.

See L<SNMP::Info::Entity/"Required MIBs"> for its MIB requirements.

See L<SNMP::Info::LLDP/"Required MIBs"> for its MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=head2 Overrides

=over

=item $netgear->vendor()

Returns 'netgear'

=item $netgear->os()

Returns 'netgear' 

=item $netgear->model()

Returns concatenation of $e_model and $e_hwver if Entity MIB present, 
otherwise returns description()

=item $netgear->os_ver()

Returns OS Version.

=item $netgear->serial()

Returns Serial Number if available (older FS switches have no accessible
serial number).

=back

=head2 Global Methods imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::Entity

See documentation in L<SNMP::Info::Entity/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of
a reference to a hash.

=head2 Overrides

=over

=item $netgear->interfaces()

Uses the i_name() field.

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::Entity

See documentation in L<SNMP::Info::Entity/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"TABLE METHODS"> for details.

=cut
