# SNMP::Info::Layer7 - SNMP Interface to Layer7 Devices
#
# Copyright (c) 2011 Jeroen van Ingen
#
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

package SNMP::Info::Layer7;

use strict;
use Exporter;
use SNMP::Info;

@SNMP::Info::Layer7::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::Layer7::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.09';

%MIBS = (
    %SNMP::Info::MIBS,
);

%GLOBALS = (
    %SNMP::Info::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::FUNCS,
);

%MUNGE = (
    # Inherit all the built in munging
    %SNMP::Info::MUNGE,
);


# $l7->model() - Looks at sysObjectID which gives the oid of the system
#       name, contained in a proprietary  MIB.
sub model {
    my $l7    = shift;
    my $id    = $l7->id();
    my $model = &SNMP::translateObj($id);

    # Neoteris (Juniper IVE)    
    $model =~ s/^ive//i;

    return $model;
}

sub vendor {
    my $l7    = shift;
    my $id    = $l7->id();
    my $vendor = 'unknown';
    if ( defined($id) && $id =~ /^(\.1\.3\.6\.1\.4\.1\.\d+)/ ) {
        my $enterprise = &SNMP::translateObj($1);
        $vendor = $enterprise if defined $enterprise;
    }
    return $vendor;
}

# By Default we'll use the description field
sub interfaces {
    my $l7      = shift;
    my $partial = shift;

    my $interfaces = $l7->i_index($partial)       || {};
    my $i_descr    = $l7->i_description($partial) || {};

    # Replace the Index with the ifDescr field.
    foreach my $iid ( keys %$i_descr ) {
        my $port = $i_descr->{$iid};
        next unless defined $port;
        $interfaces->{$iid} = $port;
    }
    return $interfaces;
}

sub i_ignore {
    my $l7      = shift;
    my $partial = shift;

    my $i_type = $l7->i_type($partial) || {};

    my %i_ignore = ();

    foreach my $if ( keys %$i_type ) {
        my $type = $i_type->{$if};
        $i_ignore{$if}++
            if $type =~ /(loopback|other|cpu)/i;
    }

    return \%i_ignore;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer7 - SNMP Interface to network devices serving Layer7 only.

=head1 AUTHOR

Jeroen van Ingen

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $l7 = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 1
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class = $l7->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

 # Let's get some basic Port information
 my $interfaces = $l7->interfaces();
 my $i_up       = $l7->i_up();
 my $i_speed    = $l7->i_speed();

 foreach my $iid (keys %$interfaces) {
    my $port  = $interfaces->{$iid};
    my $up    = $i_up->{$iid};
    my $speed = $i_speed->{$iid}
    print "Port $port is $up. Port runs at $speed.\n";
 }

=head1 DESCRIPTION

This class is usually used as a superclass for more specific device classes
listed under SNMP::Info::Layer7::*   Please read all docs under SNMP::Info
first.

Provides abstraction to the configuration information obtainable from a 
Layer7 device through SNMP.  Information is stored in a number of MIBs.

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

 my $l7 = new SNMP::Info::Layer7(...);

=head2 Inherited Classes 

=over

=item SNMP::Info

=back

=head2 Required MIBs 

=over

=item None

=back

MIBs required for L<SNMP::Info/"Required MIBs">

See L<SNMP::Info/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=back

=head2 Overrides

=over

=item $l7->model()

Cross references $l7->id() with product IDs.

=item $l7->vendor()

Tries to discover the vendor by looking up the enterprise number in
C<sysObjectID>.

=back

=head2 Global Methods imported from SNMP::Info

See documentation in L<SNMP::Info/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $l7->interfaces()

Returns reference to the map between IID and physical Port.

=item $l7->i_ignore()

Returns reference to hash.  Increments value of IID if port is to be ignored.

Ignores loopback, other, and cpu

=back

=head2 Table Methods imported from SNMP::Info

See documentation in L<SNMP::Info/"TABLE METHODS"> for details.

=cut
