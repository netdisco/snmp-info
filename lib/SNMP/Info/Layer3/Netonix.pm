# SNMP::Info::Layer3::Netonix
#
# Copyright (c) 2014-2016 Max Kosmach
# Copyright (c) 2022 by Avant Wireless, LLC.
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

package SNMP::Info::Layer3::Netonix;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Netonix::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Netonix::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.975000';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'NETONIX-SWITCH-MIB'   => 'firmwareVersion',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'os_ver' => 'firmwareVersion',
    'mac'    => 'dot1dBaseBridgeAddress.0',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
);

sub layers {
    # layers 2 and 3
    return '00000110';
}

sub os {
    my $netonix = shift;

    return 'netonix';
}

sub vendor {
    return 'netonix';
}

sub model {
    my $netonix = shift;

    my $descr = $netonix->description() || '';

    my $model = undef;
    $model = $1 if ( $descr =~ /^Netonix\s+(\S+)$/i );
    return $model;
}

## simply take the MAC and clean it up
sub serial {
    my $netonix = shift;

    my $serial = $netonix->mac();
    if($serial){
        $serial =~ s/://g;
        return uc $serial;
    }
    return ;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Netonix - SNMP Interface to Netonix devices

=head1 AUTHORS

Max Kosmach
Avant Wireless

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $nx = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $nx->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Netonix devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<NETONIX-SWITCH-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $nx->vendor()

Returns C<'netonix'>.

=item $nx->os()

Returns C<'netonix'>.

=item $nx->model()

Returns the model substring of C<description>.

=item $nx->os_ver()

Returns the value of C<firmwareVersion>.

=item $nx->serial()

Returns the value of C<dot1dBaseBridgeAddress.0> without colons.

=back

=head2 Overrides

=over

=item $nx->layers()

Returns 00000110. Netonix doesn't report layers, modified to reflect
Layer 2 and 3 functionality.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=cut
