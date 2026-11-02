# SNMP::Info::Layer2::FortiAP
#
# Copyright (c) 2026 SNMP::Info Developers
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

package SNMP::Info::Layer2::FortiAP;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer2;

@SNMP::Info::Layer2::FortiAP::ISA = qw/
    SNMP::Info::Layer2
    Exporter
/;
@SNMP::Info::Layer2::FortiAP::EXPORT_OK = qw//;

our ( $VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE );

$VERSION = '3.984000';

%MIBS = ( %SNMP::Info::Layer2::MIBS, );

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,

    # FORTINET-FORTIAP-MIB objects are read by OID until the MIB is in a
    # netdisco-mibs release, netdisco/netdisco-mibs#312
    # fapVersion, fapSerialNum
    'fap_version' => '.1.3.6.1.4.1.12356.120.1.1.0',
    'fap_serial'  => '.1.3.6.1.4.1.12356.120.1.2.0',
);

%FUNCS = ( %SNMP::Info::Layer2::FUNCS, );

%MUNGE = ( %SNMP::Info::Layer2::MUNGE, );

# FortiAPs serve no sysServices
sub layers {
    my $fap = shift;

    return $fap->SUPER::layers() || '00000010';
}

sub vendor {
    return 'fortinet';
}

sub os {
    return 'fortiap';
}

# fapVersion is "<image>-v<version>", e.g. "FP221E-v7.0-build0033"
sub os_ver {
    my $fap     = shift;
    my $version = $fap->fap_version();

    return unless defined $version;
    return $1 if $version =~ /^\S+?-v(\S+)$/;
    return $version;
}

# The image name before "-v" names the model: FP231G, PU231F
sub model {
    my $fap     = shift;
    my $version = $fap->fap_version() // '';

    return $1 if $version =~ /^(\S+?)-v/;
    return $fap->SUPER::model();
}

sub serial {
    my $fap = shift;

    return $fap->fap_serial();
}

# Loopback and Linux pseudo devices that carry no traffic
sub i_ignore {
    my $fap     = shift;
    my $partial = shift;

    my $ignore  = $fap->SUPER::i_ignore($partial) || {};
    my $i_descr = $fap->i_description($partial)   || {};
    my $i_type  = $fap->i_type($partial)          || {};

    foreach my $iid ( keys %$i_descr ) {
        my $name = $i_descr->{$iid};
        my $type = $i_type->{$iid} // '';
        $ignore->{$iid}++
            if $type eq 'softwareLoopback'
            or $name =~ /^(?:gre|gretap|ip6tnl|sit|ip6gre|ifb|teql|soc)\d*$/
            or $name =~ /^(?:ipsecdummy|miireg)$/;
    }
    return $ignore;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::FortiAP - SNMP Interface to Fortinet FortiAP access
points

=head1 AUTHOR

SNMP::Info Developers

=head1 SYNOPSIS

    # Let SNMP::Info determine the correct subclass for you.
    my $fap = new SNMP::Info(
                            AutoSpecify => 1,
                            Debug       => 1,
                            DestHost    => 'myap',
                            Community   => 'public',
                            Version     => 2
                          )
        or die "Can't connect to DestHost.\n";

    my $class = $fap->class();
    print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a
Fortinet FortiAP access point via SNMP. It is chosen for C<sysObjectID>s
under the FortiAP branch, C<.1.3.6.1.4.1.12356.120>.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

None beyond those of the inherited class. The F<FORTINET-FORTIAP-MIB>
objects are read by OID.

=head2 Inherited MIBs

See L<SNMP::Info::Layer2/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP.

=over

=item $fap->vendor()

Returns 'fortinet'.

=item $fap->os()

Returns 'fortiap'.

=item $fap->os_ver()

Returns the firmware version from C<fapVersion>, without the image name
before C<-v> (C<7.0-build0033> from C<FP221E-v7.0-build0033>).

=item $fap->model()

Returns the image name before C<-v> in C<fapVersion> (C<FP231G> from
C<FP231G-v7.4-build0771>), or the inherited model when it has none.

=item $fap->serial()

Returns the serial number.

(C<fapSerialNum>)

=item $fap->fap_version()

(C<fapVersion>)

=item $fap->fap_serial()

(C<fapSerialNum>)

=back

=head2 Overrides

=over

=item $fap->layers()

Returns layer 2 when the device serves no C<sysServices>, as FortiAPs do.

=back

=head2 Global Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a
reference to a hash.

=head2 Overrides

=over

=item $fap->i_ignore()

Returns reference to hash. Adds the loopback and the Linux pseudo
devices that carry no traffic (C<gre>, C<sit>, C<ifb>, C<teql> and
similar) to the inherited list.

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=cut
