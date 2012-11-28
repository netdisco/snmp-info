package SNMP::Info::Layer3::SonicWALL;

# Copyright (c) 2011 Netdisco Project
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
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::SonicWALL::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::SonicWALL::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '2.09';

%MIBS = (
    %SNMP::Info::Layer2::MIBS, %SNMP::Info::Layer3::MIBS,
    'SNWL-COMMON-MIB' => 'snwlCommonModule',
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS, %SNMP::Info::Layer3::GLOBALS,
    #From SNWL-COMMON-MIB
    'sw_model' => 'snwlSysModel',
    'sw_serial' => 'snwlSysSerialNumber',
    'sw_firmware' => 'snwlSysFirmwareVersion',
);

%FUNCS = ( %SNMP::Info::Layer2::FUNCS, %SNMP::Info::Layer3::FUNCS, );

%MUNGE = ( %SNMP::Info::Layer2::MUNGE, %SNMP::Info::Layer3::MUNGE, );

sub vendor {
    return 'SonicWALL';
}

sub os {
        my $sonicos = shift;
        my $swos = $sonicos->sw_firmware();
        if ($swos =~ /Enhanced/) {
            return 'SonicOS Enhanced';
        }
        return 'SonicOS Standard';
}

sub os_ver {
    my $sonicosver = shift;
        my $osver = $sonicosver->sw_firmware();
        if ( $osver =~ /\S+\s\S+\s(\S+)/) {
            return $1
        }
}

sub serial {
        my $sw = shift;
        my $serial = $sw->sw_serial();
        return $serial;
}

sub model {
        my $swmodel = shift;
        my $model = $swmodel->sw_model();
        return $model;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::SonicWALL - SNMP Interface to L3 SonicWALL Firewall

=head1 AUTHOR

phishphreek@gmail.com

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $router = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 1
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $router->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Generic SonicWALL Firewalls

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=head2 Overrides

=over

=item $router->vendor()

Returns C<'SonicWALL'>

=item $router->os()

Returns C<'SonicOS'>

=item $router->os_ver()

Returns '4.2.0.0-10e'

=item $router->model()

Returns C<'PRO 3060 Enhanced'>

=item $router->serial()

Returns the MAC address of the first X0/LAN interface.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut

