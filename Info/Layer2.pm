# SNMP::Info::Layer2 - SNMP Interface to Layer2 Devices 
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

package SNMP::Info::Layer2;
$VERSION = 0.1;

use strict;

use Exporter;
use SNMP::Info;
use SNMP::Info::Bridge;
use SNMP::Info::CDP;

use vars qw/$VERSION $DEBUG %GLOBALS %MIBS %FUNCS %PORTSTAT %MUNGE $INIT/;

@SNMP::Info::Layer2::ISA = qw/SNMP::Info SNMP::Info::Bridge SNMP::Info::CDP Exporter/;
@SNMP::Info::Layer2::EXPORT_OK = qw//;

$DEBUG=0;
$SNMP::debugging=$DEBUG;

# See SNMP::Info for the details of these data structures and 
#       the interworkings.
$INIT = 0;

%MIBS = ( %SNMP::Info::MIBS, 
          %SNMP::Info::Bridge::MIBS,
          %SNMP::Info::CDP::MIBS,
          'CISCO-PRODUCTS-MIB' => 'sysName',
          'CISCO-STACK-MIB'    => 'wsc1900sysID',
          'HP-ICF-OID'         => 'hpSwitch4000',
        );

%GLOBALS = (
            %SNMP::Info::GLOBALS,
            %SNMP::Info::Bridge::GLOBALS,
            %SNMP::Info::CDP::GLOBALS,
            );

%FUNCS   = (
            %SNMP::Info::FUNCS,
            %SNMP::Info::Bridge::FUNCS,
            %SNMP::Info::CDP::FUNCS,
           );

%MUNGE = (
            # Inherit all the built in munging
            %SNMP::Info::MUNGE,
            %SNMP::Info::Bridge::MUNGE,
            %SNMP::Info::CDP::MUNGE,
         );

# Method OverRides

# $l2->model() - Looks at sysObjectID which gives the oid of the system
#       name, contained in a propriatry MIB. 
sub model {
    my $l2 = shift;
    my $id = $l2->id();
    my $model = &SNMP::translateObj($id);
    
    # HP
    $model =~ s/^hpswitch//i;

    # Cisco
    $model =~ s/sysid$//i;

    return $model;
}

sub vendor {
    my $l2 = shift;
    my $model = $l2->model();
    my $descr = $l2->description();

    if ($model =~ /hp/i or $descr =~ /hp/i) {
        return 'hp';
    }

    if ($model =~ /catalyst/i or $descr =~ /(catalyst|cisco)/i) {
        return 'cisco';
    }

}

sub i_ignore {
    my $l2 = shift;

    my $i_type = $l2->i_type();

    my %i_ignore = ();

    foreach my $if (keys %$i_type){
        my $type = $i_type->{$if};
        $i_ignore{$if}++ 
            if $type =~ /(loopback|propvirtual|other|cpu)/i;
    }

    return \%i_ignore;
}    

# By Default we'll use the description field
sub interfaces {
    my $l2 = shift;
    my $interfaces = $l2->i_index();
    my $i_descr    = $l2->i_description(); 
    my $i_name     = $l2->i_name();

    my %if;
    foreach my $iid (keys %$interfaces){
        my $port = $i_descr->{$iid};
        my $name = $i_name->{$iid};
        $port = $name if (defined $name and $name !~ /^\s*$/);
        next unless defined $port;

        # Cisco 1900 has a space in some of its port descr.
        # get rid of any weird characters
        $port =~ s/[^\d\/,()\w]+//gi;
    
        # Translate Cisco 2926,etc. from 1/5 to 1.5
        $port =~ s/\//\./ if ($port =~ /^\d+\/\d+$/);

        $if{$iid} = $port;
    }

    return \%if
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2 - Perl5 Interface to Layer2 network devices.

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a 
Layer2 device through SNMP.  Information is stored in a number of MIBs.

See super classes for descriptions of other available methods.

Inherits from: 

 SNMP::Info
 SNMP::Info::Bridge
 SNMP::Info::CDP

MIBS: 

 CISCO-PRODUCTS-MIB - Needed for ID of Cisco Products
 CISCO-STACK-MIB    - Needed for ID of Cisco Products
 HP-ICF-OID         - Needed for ID of HP    Products
 MIBS listed in SNMP::Info::Bridge and SNMP::Info::CDP

Cisco MIBs can be found at ftp://ftp.cisco.com/pub/mibs/v2/v2.tar.gz

HP MIBs can be found at http://www.hp.com/rnd/software

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 my $l2 = new SNMP::Info::Layer2(DestHost  => 'mybridge' , 
                              Community => 'public' ); 

=head1 CREATING AN OBJECT

=over

=item  new SNMP::Info::Layer2()

Arguments passed to new() are passed on to SNMP::Session::new()
    

    my $l2 = new SNMP::Info::Layer2(
        DestHost => $host,
        Community => 'public',
        Version => 3,...
        ) 
    die "Couldn't connect.\n" unless defined $l2;

=item  $l2->session()

Sets or returns the SNMP::Session object

    # Get
    my $sess = $l2->session();

    # Set
    my $newsession = new SNMP::Session(...);
    $l2->session($newsession);

=back

=head1 GLOBALS

=over

=item $l2->model()

Cross references $l2->id() with product IDs in the 
Cisco and HP specific MIBs.

For HP devices, removes 'hpswitch' from the name

For Cisco devices, removes 'sysid' from the name

=item $l2->vendor()

Trys to discover the vendor from $l2->model() and $l2->vendor()

=back

=head1 TABLE ENTRIES

=head2 Overrides

=over

=item $l2->interfaces()

Creates a map between the interface identifier (iid) and the physical port name.

Defaults to B<ifDescr> but checks and overrides with B<ifName>

=item $l2->i_ignore()

Returns reference to hash.  Increments value of IID if port is to be ignored.

Ignores ports with B<ifType> of loopback,propvirtual,other, and cpu

=back

=cut
