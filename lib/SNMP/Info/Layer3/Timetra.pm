# SNMP::Info::Layer3::Timetra
# $Id$
#
# Copyright (c) 2008 Bill Fenner
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

package SNMP::Info::Layer3::Timetra;

use strict;

use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Timetra::ISA = qw/SNMP::Info::Layer3
  Exporter/;
@SNMP::Info::Layer3::Timetra::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.54';

%MIBS = (
  %SNMP::Info::Layer3::MIBS,
  'TIMETRA-GLOBAL-MIB' => 'timetraReg',
  'TIMETRA-LLDP-MIB'   => 'tmnxLldpAdminStatus',
);

%GLOBALS = (%SNMP::Info::Layer3::GLOBALS,);

%FUNCS = (
  %SNMP::Info::Layer3::FUNCS,

  # For some reason LLDP-MIB::lldpLocManAddrTable is populated
  # but LLDP-MIB::lldpRemTable is not and we need to use the
  # proprietary TIMETRA-LLDP-MIB Note: these tables are
  # indexed differently than LLDP-MIB
  # TIMETRA-LLDP-MIB::tmnxLldpRemTable 
  'lldp_rem_id_type'  => 'tmnxLldpRemChassisIdSubtype',
  'lldp_rem_id'       => 'tmnxLldpRemChassisId',
  'lldp_rem_pid_type' => 'tmnxLldpRemPortIdSubtype',
  'lldp_rem_pid'      => 'tmnxLldpRemPortId',
  'lldp_rem_desc'     => 'tmnxLldpRemPortDesc',
  'lldp_rem_sysname'  => 'tmnxLldpRemSysName',
  'lldp_rem_sysdesc'  => 'tmnxLldpRemSysDesc',
  'lldp_rem_sys_cap'  => 'tmnxLldpRemSysCapEnabled',
  'lldp_rem_cap_spt'  => 'tmnxLldpRemSysCapSupported',

  # TIMETRA-LLDP-MIB::tmnxLldpRemManAddrTable
  'lldp_rman_addr' => 'tmnxLldpRemManAddrIfSubtype',
);

%MUNGE = (%SNMP::Info::Layer3::MUNGE,);

sub model {
  my $timetra = shift;
  my $id      = $timetra->id();
  my $model   = SNMP::translateObj($id);
  my $descr   = $timetra->description();

  if (defined $model && $model =~ /^tmnxModel/) {
    $model =~ s/^tmnxModel//;
    $model =~ s/Reg$//;
    return $model;
  }

  if ($descr =~ /\s+(7\d{3})/) {
    return $1;
  }

  return $model || $id;
}

sub os {
  return 'TiMOS';
}

sub vendor {
  return 'nokia';
}

sub os_ver {
  my $timetra = shift;

  my $descr = $timetra->description();
  if ($descr =~ m/^TiMOS-(\S+)/) {
    return $1;
  }
  return;
}

# The interface description contains the SFP type, so
# to avoid losing historical information through a configuration change
# we use interface name instead.
sub interfaces {
  my $alu     = shift;
  my $partial = shift;

  return $alu->orig_i_name($partial);
}

# The TIMETRA-LLDP-MIB::tmnxLldpRemTable unambiguously states it uses ifIndex
# Trying to cross reference to ifDescr or ifAlias would cause unpredictable
# results based upon how the device names ports.
sub lldp_if {
  my $alu    = shift;
  my $partial = shift;

  my $addr = $alu->lldp_rem_pid($partial) || {};

  my %lldp_if;
  foreach my $key (keys %$addr) {
    my @aOID = split('\.', $key);
    my $port = $aOID[1];
    next unless $port;

    $lldp_if{$key} = $port;
  }
  return \%lldp_if;
}

# The proprietary TIMETRA-LLDP-MIB tables are indexed differently than LLDP-MIB
# We overwrite the private function so that the we don't have to replicate
# the code in SNMP::Info::LLDP that uses it.
#
# We can't use inheritance to override since it is a function, not  a method
# in SNMP::Info::LLDP. This brute force redefines the code in the symbol table.

*SNMP::Info::LLDP::_lldp_addr_index = sub {
  my $idx = shift;
  my @oids = split(/\./, $idx);

  # Index has extra field compared to LLDP-MIB
  my $index = join('.', splice(@oids, 0, 4));
  my $proto = shift(@oids);
  shift(@oids) if scalar @oids > 4;    # $length

  # IPv4
  if ($proto == 1) {
    return ($index, $proto, join('.', @oids));
  }

  # IPv6
  elsif ($proto == 2) {
    return ($index, $proto, join(':', unpack('(H4)*', pack('C*', @oids))));
  }

  # MAC
  elsif ($proto == 6) {
    return ($index, $proto, join(':', map { sprintf "%02x", $_ } @oids));
  }

  # TODO - Other protocols may be used as well; implement when needed?
  else {
    return;
  }
};

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Timetra - SNMP Interface to Alcatel-Lucent SR

=head1 AUTHOR

Bill Fenner

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $alu = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $alu->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Alcatel-Lucent Service Routers

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<TIMETRA-GLOBAL-MIB>

=item F<TIMETRA-LLDP-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $alu->vendor()

Returns 'alcatel-lucent'

=item $alu->os()

Returns 'TiMOS'

=item $alu->os_ver()

Grabs the version string from C<sysDescr>.

=item $alu->model()

Tries to reference $alu->id() to one of the product MIBs listed above

Removes 'tmnxModel' from the name for readability.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $alu->interfaces()

Returns C<ifName>, since the default Layer3 C<ifDescr> varies based
upon the transceiver inserted.

=item $alu->lldp_if()

Returns the mapping to the SNMP Interface Table. Utilizes (C<ifIndex>) 
from the (C<tmnxLldpRemEntry >) index.


=back

=head2 LLDP Remote Table (C<lldpRemTable>) uses (C<TIMETRA-LLDP-MIB::tmnxLldpRemTable>)

=over

=item $lldp->lldp_rem_id_type()

(C<tmnxLldpRemChassisIdSubtype>)

=item $lldp->lldp_rem_id()

(C<tmnxLldpRemChassisId>)

=item $lldp->lldp_rem_pid_type()

(C<tmnxLldpRemPortIdSubtype>)

=item $lldp->lldp_rem_pid()

(C<tmnxLldpRemPortId>)

=item $lldp->lldp_rem_desc()

(C<tmnxLldpRemPortDesc>)

=item $lldp->lldp_rem_sysname()

(C<tmnxLldpRemSysName>)

=item $lldp->lldp_rem_sysdesc()

(C<tmnxLldpRemSysDesc>)

=item  $lldp->lldp_rem_sys_cap()

(C<tmnxLldpRemSysCapEnabled>)

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
