# SNMP::Info::Layer3::OneAccess
#
# Copyright (c) 2017 Rob Woodward
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

package SNMP::Info::Layer3::OneAccess;

use strict;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::OneAccess::ISA = qw/
  SNMP::Info::Layer3
  Exporter
/;
@SNMP::Info::Layer3::OneAccess::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.65';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'ONEACCESS-GLOBAL-REG' => 'oacOne10',
    'ONEACCESS-SYS-MIB'    => 'oacSysSecureCrashlogCount',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    # model can be based on oacOneOsDevices, but the mib isn't up to date,
    # so use the first product name instead
    'oa_model' => 'oacExpIMSysHwcProductName.0',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
);

# notes:
# duplex: oneos v5 has dot3StatsDuplexStatus but it always seems to
#   return 0 so useless. oneos v6 no longer has any info.
# macsuck: bridge-mib and oneaccess mibs didn't return useable data
# arpnip: oneos v5 returns usable data from ip-mib & rfc1213 which is
#   usable, both version support ip-forward-mib but this does not by
#   itself provide enough data to be usable. v6 even fails for the
#   snmp::info->ipforwarding() test.

sub vendor {
    return "oneaccess";
}

sub model {
  my $oneos = shift;

  # prefer oneaccess mib, but can fall back to entity mib

  return $oneos->oa_model()
    || $oneos->e_model();
}

sub os {
  return 'oneos';
}

sub os_ver {
  my $oneos = shift;
  my $descr = $oneos->description();

  # there is no easy way to get the os version, and the syntax also
  # changed between major versions. for now we'll use everything after
  # the last dash as version string
  # SNMPv2-MIB::sysDescr.0 = STRING: OneOS-pCPE-ARM_pi1-6.1.rc1patch06
  # SNMPv2-MIB::sysDescr.0 = STRING: OneOS-pCPE-ARM_pi1-6.1.3
  # SNMPv2-MIB::sysDescr.0 = STRING: ONEOS16-ADVIP_11N-V5.2R1C12
  # and this one comes from the snmp::info test modules: ONEOS5-VOIP_H323-V4.3R4E18

  if (defined $descr) {
    if ( $descr =~ /^.*-(.*$)/ ) {
      return $1;
    }
  }
  return;
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

1;
__END__

=head1 NAME

SNMP::Info::Layer3::OneAccess - SNMP Interface to OneAccess routers.

=head1 AUTHORS

Rob Woodward

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $oneos = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $oneos->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for OneAccess routers.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<ONEACCESS-GLOBAL-REG>

=item F<ONEACCESS-SYS-MIB>

=back

=head2 Inherited Classes' MIBs

=over

See L<SNMP::Info::Layer3> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP.

=over

=item $oneos->oa_model()

Returns the hardware model from C<oacExpIMSysHwcProductName.0>.

=item $oneos->os_ver()

Returns the software version extracted from C<sysDescr>.

=back

=head2 Overrides

=over

=item $oneos->model()

Returns C<oa_model()> with a fallback to C<e_model()> from
L<SNMP::Info::Entity>.

=item $oneos->os()

Returns 'oneos'.

=item $oneos->vendor()

Returns 'oneaccess'.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $oneos->i_ignore()

Returns reference to hash.  Increments value of IID if port is to be ignored.

Ignores InLoopback and Console interfaces

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=cut
