# SNMP::Info::Layer1::Asante
# Max Baker <max@warped.org>
#
# Copyright (c) 2002, Regents of the University of California
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#     * Neither the name of the University of California, Santa Cruz nor the 
#       names of its contributors may be used to endorse or promote products 
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Layer1::Asante;
$VERSION = 0.1;
use strict;

use Exporter;
use SNMP::Info::Layer1;

@SNMP::Info::Layer1::Asante::ISA = qw/SNMP::Info::Layer1 Exporter/;
@SNMP::Info::Layer1::Asante::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD $INIT $DEBUG/;

# Set for No CDP
%GLOBALS = (
            %SNMP::Info::Layer1::GLOBALS,
            );

%FUNCS   = (%SNMP::Info::Layer1::FUNCS,
            'i_speed2'     => 'ifSpeed',
            'i_mac2'       => 'ifPhysAddress',
            'i_descr2'     => 'ifDescr',
            'i_name2'      => 'ifName',
            'asante_port'  => 'ePortIndex',
            'asante_group' => 'ePortGrpIndex',
            'i_type'       => 'ePortStateType',
            'asante_up'    => 'ePortStateLinkStatus',
            );

%MIBS    = (
            %SNMP::Info::Layer1::MIBS,
            'ASANTE-HUB1012-MIB' => 'asante'
            );

%MUNGE   = (%SNMP::Info::Layer1::MUNGE,
            'i_mac2' => \&SNMP::Info::munge_mac,
            'i_speed2' => \&SNMP::Info::munge_speed,
            );

sub interfaces {
    my $asante = shift;

    my $rptr_port = $asante->rptr_port();

    my %interfaces;

    foreach my $port (keys %$rptr_port){
        $interfaces{$port} = $port;
    }

    return \%interfaces;
}

sub vendor {
    return 'asante';
}

sub model {
    my $asante = shift;

    my $id = $asante->id();
    my $model = &SNMP::translateObj($id);

    return $model;
}

sub i_up {
    my $asante = shift;

    my $asante_up = $asante->asante_up();

    my $i_up = {};
    foreach my $port (keys %$asante_up){
        my $up = $asante_up->{$port};
        $i_up->{$port} = 'down' if $up =~ /on/;
        $i_up->{$port} = 'up' if $up =~ /off/;
    }
    
    return $i_up;
}

sub i_speed {
    my $asante = shift;

    my $i_speed = $asante->i_speed2();

    my %i_speed;

    $i_speed{"1.2"} = $i_speed->{1};

    return \%i_speed;
}

sub i_mac {
    my $asante = shift;

    my $i_mac = $asante->i_mac2();

    my %i_mac;

    $i_mac{"1.2"} = $i_mac->{1};

    return \%i_mac;
}

sub i_description {
    return undef;
}

sub i_name {
    my $asante = shift;

    my $i_name = $asante->i_descr2();

    my %i_name;

    $i_name{"1.2"} = $i_name->{1};

    return \%i_name;
}
1;
__END__

=head1 NAME

SNMP::Info::Layer1::Asante - SNMP Interface to old Asante 1012 Hubs

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a 
Asante device through SNMP. See inherited classes' documentation for 
inherited methods.

Inherits from:

 SNMP::Info::Layer1

Required MIBs:

ASANTE-HUB1012-MIB - Download from http://www.mibdepot.com

 MIBs listed in SNMP::Info::Layer1

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 my $asante = new SNMP::Info::Layer1::Asante(DestHost  => 'mycat1900' , 
                              Community => 'public' ); 

=head1 CREATING AN OBJECT

=over

=item  new SNMP::Info::Layer1::Asante()

Arguments passed to new() are passed on to SNMP::Session::new()
    

    my $asante = new SNMP::Info::Layer1::Asante(
        DestHost => $host,
        Community => 'public',
        Version => 3,...
        ) 
    die "Couldn't connect.\n" unless defined $asante;

=item  $asante->session()

Sets or returns the SNMP::Session object

    # Get
    my $sess = $asante->session();

    # Set
    my $newsession = new SNMP::Session(...);
    $asante->session($newsession);

=back

=head1 GLOBALS

=over

=item $asante->vendor()

Returns 'asante' :)

=item $asante->root_ip()

Returns IP Address of Managed Hub.

(B<actualIpAddr>)

=item $asante->model()

Trys to cull out AT-nnnnX out of the description field.

=back

=head1 TABLE ENTRIES

=head2 Overrides

=over

=item $asante->i_name()

Returns reference to map of IIDs to human-set port name.

=item $asante->i_up()

Returns reference to map of IIDs to link status.  Changes
the values of ati_up() to 'up' and 'down'.

=back

=head2 Asante MIB

=over

=item $asante->ati_p_name()

(B<portName>)

=item $asante->ati_up()

(B<linkTestLED>)

=back

=cut
