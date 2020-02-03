# SNMP::Info::Layer3::VMware
#
# Copyright (c) 2014-2016 Max Kosmach
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

package SNMP::Info::Layer3::VMware;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;
use SNMP::Info::IEEE802dot3ad 'agg_ports_lag';

@SNMP::Info::Layer3::VMware::ISA       = qw/SNMP::Info::IEEE802dot3ad SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::VMware::EXPORT_OK = qw/agg_ports/;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.70';

%MIBS = (
    %SNMP::Info::IEEE802dot3ad::MIBS,
    %SNMP::Info::Layer3::MIBS,
    'VMWARE-PRODUCTS-MIB' => 'vmwProducts',
    'VMWARE-SYSTEM-MIB'   => 'vmwProdName',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    # VMWARE-SYSTEM-MIB
    'vmwProdVersion'  => 'vmwProdVersion',
    'vmwProdBuild'    => 'vmwProdBuild',
    'vmwProdUpdate'   => 'vmwProdUpdate',
    'vmwProdPatch'    => 'vmwProdPatch',
    'os'              => 'vmwProdName',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::IEEE802dot3ad::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::IEEE802dot3ad::MUNGE,
);

sub vendor {
    return 'vmware';
}

sub os_ver {
    my $vmware     = shift;
    my $vmwProdVersion = $vmware->vmwProdVersion();
    my $vmwProdBuild = $vmware->vmwProdBuild() || '';
    my $vmwProdUpdate = $vmware->vmwProdUpdate() || '';
    my $vmwProdPatch = $vmware->vmwProdPatch() || '';

    my $ver = "$vmwProdVersion" . "-" . "$vmwProdUpdate.$vmwProdPatch.$vmwProdBuild";
    return $ver;
}

sub agg_ports {
   return agg_ports_lag(@_);
}

#sub layers {
#    return '01001010';
#}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::VMware - SNMP Interface to VMware ESXi

=head1 AUTHORS

Max Kosmach

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $host = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myhost',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $host->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for VMware ESXi

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::IEEE802dot3ad

=back

=head2 Required MIBs

=over

=item F<VMWARE-SYSTEM-MIB>

=item F<VMWARE-PRODUCTS-MIB>

=back

=head2 Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its MIB requirements.

See L<SNMP::Info::IEEE802dot3ad/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $vmware->vendor()

Returns C<'vmware'>.

=item $vmware->os()

Returns the value of C<vmwProdName.0>.

=item $vmware->os_ver()

Returns the software version specified as major-update.patch.build (ex.  5.1.0-3.55.2583090).

(C<vmwProdVersion>)-(C<vmwProdUpdate>).(C<vmwProdPatch>).(C<vmwProdBuild>)

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item C<agg_ports>

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Table Methods imported from SNMP::Info::IEEE802dot3ad

See documentation in L<SNMP::Info::IEEE802dot3ad> for details.

=cut
