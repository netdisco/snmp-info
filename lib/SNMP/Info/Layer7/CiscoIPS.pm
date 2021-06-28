# SNMP::Info::Layer7::CiscoIPS
#
# Copyright (c) 2013 Moe Kraus
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
# LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Layer7::CiscoIPS;

use strict;
use warnings;
use Exporter;
use SNMP::Info::CiscoStats;
use SNMP::Info::Layer7;
use SNMP::Info::Entity;

@SNMP::Info::Layer7::CiscoIPS::ISA = qw/
    SNMP::Info::CiscoStats
    SNMP::Info::Layer7
    Exporter/;
@SNMP::Info::Layer7::CiscoIPS::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.73';

%MIBS = ( %SNMP::Info::Layer7::MIBS, %SNMP::Info::Entity::MIBS, );

%GLOBALS
    = ( %SNMP::Info::Layer7::GLOBALS, %SNMP::Info::Entity::GLOBALS, );

%FUNCS = (
    %SNMP::Info::Layer7::FUNCS,
    %SNMP::Info::Entity::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer7::MUNGE,
    %SNMP::Info::Entity::MUNGE,
);

my ($serial, $descr, $model);

sub _fetch_info {
    my $self = shift;
    foreach my $id ( keys %{ $self->e_id() } ){

        if (
            $self->e_name->{$id} =~ m/^Module$/ and
            $self->e_model->{$id} =~ m/IPS/
        ) {
            $serial = $self->e_serial->{$id};
            $descr  = $self->e_descr->{$id};
            $model  = $self->e_model->{$id};
        }

    }

}

sub layers {
    return '01001000';
}

sub serial {
    my $self = shift;
    _fetch_info($self) unless defined $serial;
    return $serial;
}

sub sysdescr {
    my $self = shift;
    _fetch_info($self) unless defined $descr;
    return $descr;
}

sub model {
    my $self = shift;
    _fetch_info($self) unless defined $descr;
    $descr =~ s/ Security Services Processor//g;
    $descr =~ s/ /-/g;
    return $descr;
}

sub productname {
    my $self = shift;
    return $self->model;
}

sub b_mac {
    my ( $self ) = shift;

    foreach my $mac ( values %{$self->i_mac()} ){

        next unless defined $mac;
        next unless $mac =~ m/^e4:d3:f1/;
        return  $mac;
    }

    return '';
}

sub e_index {
    my $self = shift();
    my %index;
    foreach my $id ( keys %{$self->e_id} ){
        $index{$id} = $id;
    }
    return \%index;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer7::CiscoIPS - Cisco Adaptive Security Appliance IPS module

=head1 AUTHOR

Moe Kraus

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $info = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myIPS',
                        Community   => 'public',
                        Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $info->class();
 print "SNMP::Info determined this device to fall under subclass: $class\n";

=head1 DESCRIPTION

Subclass for Cisco IPS Module

=head2 Inherited Classes

=over

=item SNMP::Info::Entity

=item SNMP::Info::Layer7

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See classes listed above for their required MIBs.

=back


=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $info->b_mac()

Returns base mac. Matches only on e4:d3:f1

=item $info->serial()

Fetches serial from Module

=item $info->e_index()

overrides Entity->e_index() since entity table the IPS delivering is buggy.

=item $info->layers

Returns '01001000'

=item $info->model

Returns model name

=item $info->productname

Returns the product name

=item $info->serial

Returns the serial number

=item $info->sysdescr

Returns the system description

=back

=head2 Global Methods imported from SNMP::Info::Layer7

See documentation in L<SNMP::Info::Layer7/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::Entity

See documentation in L<SNMP::Info::Entity/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a
reference to a hash.

=head2 Table Methods imported from SNMP::Info::Layer7

See documentation in L<SNMP::Info::Layer7/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::Entity

See documentation in L<SNMP::Info::Entity/"TABLE METHODS"> for details.

=cut
