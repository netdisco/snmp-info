# SNMP::Info::Layer1 - SNMP Interface to Layer1 Devices 
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

package SNMP::Info::Layer1;
$VERSION = 0.1;

use strict;

use Exporter;
use SNMP::Info;

use vars qw/$VERSION $DEBUG %GLOBALS %MIBS %FUNCS %PORTSTAT %MUNGE $INIT/;

@SNMP::Info::Layer1::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::Layer1::EXPORT_OK = qw//;

$DEBUG=0;
$SNMP::debugging=$DEBUG;

# See SNMP::Info for the details of these data structures and 
#       the interworkings.
$INIT = 0;

%MIBS = ( %SNMP::Info::MIBS, 
          'SNMP-REPEATER-MIB' => 'rptrPortGroupIndex'
        );

%GLOBALS = (
            %SNMP::Info::GLOBALS,
            'ports_managed'  => 'ifNumber',
            'rptr_slots'     => 'rptrGroupCapacity',
            'slots'          => 'rptrGroupCapacity'
            );

%FUNCS   = (
            %SNMP::Info::FUNCS,
            'i_up2'         => 'ifOperStatus',
            'i_up_admin2'   => 'ifAdminStatus',
            'rptr_ports'    => 'rptrGroupPortCapacity',
            'rptr_port'     => 'rptrPortIndex',
            'rptr_slot'     => 'rptrPortGroupIndex',
            'rptr_up_admin' => 'rptrPortAdminStatus',
            'rptr_up'       => 'rptrPortOperStatus',
           );

%MUNGE = (
            # Inherit all the built in munging
            %SNMP::Info::MUNGE,
         );

# Method OverRides

# assuming managed ports aren't in repeater ports?
sub ports {
    my $l1 = shift;

    my $ports         = $l1->ports_managed();
    my $rptr_ports    = $l1->rptr_ports();

    foreach my $group (keys %$rptr_ports){
        $ports += $rptr_ports->{$group}; 
    }

    return $ports;
}

# $l1->model() - Looks at sysObjectID which gives the oid of the system
#       name, contained in a propriatry MIB. 
sub model {
    my $l1 = shift;
    my $id = $l1->id();
    my $model = &SNMP::translateObj($id);
    
    # HP
    $model =~ s/^hpswitch//i;

    # Cisco
    $model =~ s/sysid$//i;

    return $model;
}

sub vendor {
    my $l1 = shift;
    my $descr = $l1->description();

    return 'hp' if ($descr =~ /hp/i);
    return 'cisco' if ($descr =~ /(catalyst|cisco|ios)/i);
    return 'allied' if ($descr =~ /allied/i);
    return 'asante' if ($descr =~ /asante/i);

}

# By Default we'll use the description field
sub interfaces {
    my $l1 = shift;
    my $interfaces = $l1->i_index();
    my $rptr_port  = $l1->rptr_port();

    foreach my $port (keys %$rptr_port){
        $interfaces->{$port} = $port;
    }
    return $interfaces;
}

sub i_up_admin {
    my $l1 = shift;

    my $i_up_admin = $l1->i_up_admin2();
    my $rptr_up_admin = $l1->rptr_up_admin();

    foreach my $key (keys %$rptr_up_admin){
        my $up = $rptr_up_admin->{$key};
        $i_up_admin->{$key} = 'up' if $up =~ /enabled/; 
        $i_up_admin->{$key} = 'down' if $up =~ /disabled/; 
    }

    return $i_up_admin;
}

sub i_up {
    my $l1 = shift;
    my $i_up = $l1->i_up2();
    my $rptr_up = $l1->rptr_up();

    foreach my $key (keys %$rptr_up){
        my $up = $rptr_up->{$key};
        $i_up->{$key} = 'up' if $up =~ /operational/; 
    }

    return $i_up;
    
}
1;
__END__

=head1 NAME

SNMP::Info::Layer1 - Perl5 Interface to Layer1 network devices.

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a 
Layer1 device through SNMP.  Information is stored in a number of MIBs.

See super classes for descriptions of other available methods.

Inherits from: 

 SNMP::Info

MIBS: 

 MIBS listed in SNMP::Info

Cisco MIBs can be found at ftp://ftp.cisco.com/pub/mibs/v2/v2.tar.gz

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 my $l1 = new SNMP::Info::Layer1(DestHost  => 'mybridge' , 
                              Community => 'public' ); 

=head1 CREATING AN OBJECT

=over

=item  new SNMP::Info::Layer1()

Arguments passed to new() are passed on to SNMP::Session::new()
    

    my $l1 = new SNMP::Info::Layer1(
        DestHost => $host,
        Community => 'public',
        Version => 3,...
        ) 
    die "Couldn't connect.\n" unless defined $l1;

=item  $l1->session()

Sets or returns the SNMP::Session object

    # Get
    my $sess = $l1->session();

    # Set
    my $newsession = new SNMP::Session(...);
    $l1->session($newsession);

=back

=head1 GLOBALS

=over

=item $l1->vendor()

Trys to discover the vendor from $l1->model() and $l1->vendor()

=item $l1->ports_managed()

Gets the number of ports under the interface mib 

(B<ifNumber>)

=item $l1->ports()

Adds the values from rptr_ports() and ports_managed()

=item $l1->slots()

Number of 'groups' in the Repeater MIB

(B<rptrGroupCapacity>)

=back

=head1 TABLE ENTRIES

=head2 Overrides

=over

=item $l1->interfaces()

=item $l1->i_up()

=item $l1->i_up_admin()

=back

=head2 Repeater MIB

=over

=item $l1->rptr_ports()

Number of ports in each group.

(B<rptrGroupPortCapacity>)

=item $l1->rptr_port()

Port number in Group

(B<rptrPortIndex>)

=item $l1->rptr_slot()

Group (slot) Number for given port.

(B<rptrPortGroupIndex>)

=item $l1->rptr_up_admin()

(B<rptrPortAdminStatus>)

=item $l1->rptr_up()

(B<rptrPortOperStatus>)

=back

=cut
