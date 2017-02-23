# SNMP::Info::Layer3::Huawei
#
# Copyright (c) 2015 Jeroen van Ingen
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

package SNMP::Info::Layer3::Huawei;

use strict;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::LLDP;
use SNMP::Info::IEEE802dot3ad 'agg_ports_lag';

@SNMP::Info::Layer3::Huawei::ISA = qw/
  SNMP::Info::IEEE802dot3ad
  SNMP::Info::LLDP
  SNMP::Info::Layer3
  Exporter
/;
@SNMP::Info::Layer3::Huawei::EXPORT_OK = qw/
  agg_ports
/;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.34';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::LLDP::MIBS,
    %SNMP::Info::IEEE802dot3ad::MIBS,
    'HUAWEI-MIB' => 'quidway',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::LLDP::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::LLDP::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::LLDP::MUNGE,
);

sub vendor {
    return "Huawei";
}

sub os {
    my $huawei = shift;
    my $descr  = $huawei->description();

    return $1 if ( $descr =~ /\b(VRP)\b/ );
    return "huawei";
}

sub os_ver {
    my $huawei = shift;
    my $descr  = $huawei->description();
    my $os_ver = undef;

    $os_ver = "$1" if ( $descr =~ /\bVersion ([0-9.]+)/i );

    return $os_ver;
}

sub i_ignore {
    my $l3      = shift;
    my $partial = shift;

    my $interfaces = $l3->interfaces($partial) || {};

    my %i_ignore;
    foreach my $if ( keys %$interfaces ) {

        # lo0 etc
        if ( $interfaces->{$if} =~ /\b(inloopback|console)\d*\b/i ) {
            $i_ignore{$if}++;
        }
    }
    return \%i_ignore;
}

sub agg_ports { return agg_ports_lag(@_) }

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Huawei - SNMP Interface to Huawei Layer 3 switches and routers.

=head1 AUTHORS

Jeroen van Ingen

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $huawei = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $huawei->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Huawei Quidway switches

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::LLDP

=item SNMP::Info::IEEE802dot3ad

=back

=head2 Required MIBs

=over

=item F<HUAWEI-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

See L<SNMP::Info::LLDP> for its own MIB requirements.

See L<SNMP::Info::IEEE802dot3ad> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $huawei->vendor()

Returns 'Huawei'.

=item $huawei->os()

Returns 'VRP' if contained in C<sysDescr>, 'huawei' otherwise.

=item $huawei->os_ver()

Returns the software version extracted from C<sysDescr>.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Globals imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $huawei->i_ignore()

Returns reference to hash.  Increments value of IID if port is to be ignored.

Ignores InLoopback and Console interfaces

=item C<agg_ports>

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP> for details.

=cut
