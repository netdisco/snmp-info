# SNMP::Info::Layer3::Steelhead
#
# Copyright (c) 2013 Eric Miller
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

package SNMP::Info::Layer3::Steelhead;

use strict;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Steelhead::ISA
    = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Steelhead::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %FUNCS %MIBS %MUNGE/;

$VERSION = '3.16';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'STEELHEAD-MIB' => 'serialNumber',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    # Fully qualified to remove ambiguity of 'model'
    'rb_model' => 'STEELHEAD-MIB::model',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
);

sub layers {
    return '01001100';
}

sub vendor {
    return 'riverbed';
}

sub model {
    my $riverbed = shift;

    my $model = $riverbed->rb_model() || '';
    
    if ($model =~ /^(\d+)/) {
        return $1;
    }
    return $model;
}

sub os {
    return 'steelhead';
}

sub os_ver {
    my $riverbed = shift;
    
    my $ver = $riverbed->systemVersion() || '';

    if ( $ver =~ /(\d+[\.\d]+)/ ) {
        return $1;
    }
    
    return $ver;
}

sub serial {
    my $riverbed = shift;
    
    return $riverbed->serialNumber();
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Steelhead - SNMP Interface to Riverbed Steelhead WAN
optimization appliances.

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $riverbed = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class = $riverbed->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for Riverbed Steelhead WAN optimization appliances.

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

 my $riverbed = new SNMP::Info::Layer3::Steelhead(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

F<STEELHEAD-MIB>

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $riverbed->vendor()

Returns 'riverbed'

=item $riverbed->model()

Returns the chassis model.

(C<STEELHEAD-MIB::model>)

=item $riverbed->os()

Returns 'steelhead'

=item $riverbed->os_ver()

Returns the software version extracted from (C<systemVersion>).

=item $riverbed->serial()

Returns the chassis serial number.

(C<serialNumber>)

=back

=head2 Overrides

=over

=item $riverbed->layers()

Returns 01001100.  Steelhead does not support bridge MIB, so override reported
layers.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
