# SNMP::Info::Layer3::ArubaCX
#
# Copyright (c) 2021 Jeroen van Ingen
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

package SNMP::Info::Layer3::ArubaCX;

use strict;
use warnings;
use Exporter;
use SNMP::Info::IEEE802dot3ad 'agg_ports_lag';
use SNMP::Info::Layer3;
use SNMP::Info::IEEE802_Bridge;

@SNMP::Info::Layer3::ArubaCX::ISA = qw/
  SNMP::Info::IEEE802dot3ad
  SNMP::Info::Layer3
  SNMP::Info::IEEE802_Bridge
  Exporter
/;
@SNMP::Info::Layer3::ArubaCX::EXPORT_OK = qw/
  agg_ports
/;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.73';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::IEEE802dot3ad::MIBS,
    %SNMP::Info::IEEE802_Bridge::MIBS,
    'ARUBAWIRED-FAN-MIB' => 'arubaWiredFanName',
    'ARUBAWIRED-VSF-MIB' => 'arubaWiredVsfTrapEnable',
    'ARUBAWIRED-POWERSUPPLY-MIB' => 'arubaWiredPSUName',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::IEEE802_Bridge::GLOBALS,
    'ps1_type' => 'arubaWiredPSUProductName.1.1',
    'ps2_type' => 'arubaWiredPSUProductName.1.2',
    'ps1_status' => 'arubaWiredPSUState.1.1',
    'ps2_status' => 'arubaWiredPSUState.1.2',
    'vsf_topology' => 'arubaWiredVsfTopology',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::IEEE802dot3ad::FUNCS,
    %SNMP::Info::IEEE802_Bridge::FUNCS,
    'fan_names' => 'arubaWiredFanName',
    'fan_states' => 'arubaWiredFanState',
    'psu_names' => 'arubaWiredPSUName',
    'psu_types' => 'arubaWiredPSUProductName',
    'psu_states' => 'arubaWiredPSUState',
    'vsf_prod_names' => 'arubaWiredVsfMemberProductName',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::IEEE802dot3ad::MUNGE,
    %SNMP::Info::IEEE802_Bridge::MUNGE,
);

sub _at_pbb_one {
    my $in = shift // {};
    my $ret = {};
    foreach my $key (keys %$in) {
        if ($key =~ /^1\.(\d+)$/) {
            $ret->{$1} = $in->{$key};
        }
    }
    return $ret;
}

sub fan {
    my $cx = shift;
    my $names = $cx->fan_names() || {};
    my $states = $cx->fan_states() || {};
    my @ary = ();
    foreach my $idx (sort keys %$names) {
        my $name = $names->{$idx} // 'n/a';
        my $state = $states->{$idx} // 'n/a';
        push @ary, sprintf("%s: %s", $name, $state);
    }
    return join (', ', @ary);
}

sub vendor {
    my $cx = shift;
    my $mfg = $cx->entPhysicalMfgName(1) || {};
    my $vendor = $mfg->{1} || "aruba";
    return lc($vendor);
}

sub stack_info {
    my $cx = shift;
    my $vsf_topo = $cx->vsf_topology();
    if (defined $vsf_topo and $vsf_topo ne 'standalone') {
        my $member_prod_names = $cx->vsf_prod_names() || {};
        my $num_members = scalar keys %$member_prod_names;
        my $fullname = (values %$member_prod_names)[0];
        my $modelname = '';
        if ($fullname =~ /^(\S+)/) {
            $modelname = $1;
        }
        return sprintf("%s (stack of %d)", $modelname, $num_members);
    } else {
        return;
    }
}

sub model {
    my $cx = shift;
    my $model = $cx->entPhysicalModelName(1) || {};
    my $id = $cx->id();
    my $translated_id = &SNMP::translateObj($id) || $id;
    $translated_id =~ s/arubaWiredSwitch//i;
    return $cx->stack_info() || $model->{1} || $translated_id;
}

sub os {
    return "arubaos-cx";
}

sub os_ver {
    my $cx = shift;
    my $ver_release = $cx->entPhysicalSoftwareRev(1) || {};
    return $ver_release->{1};
}

sub agg_ports { return agg_ports_lag(@_) }

# Overrides for VLAN & forwarding table methods
sub v_name {
    my $cx = shift;
    return _at_pbb_one($cx->iqb_v_name()) || $cx->SUPER::v_name();
}
sub qb_i_vlan {
    my $cx = shift;
    return _at_pbb_one($cx->iqb_i_vlan()) || $cx->SUPER::qb_i_vlan();
}
sub i_vlan_type {
    my $cx = shift;
    return _at_pbb_one($cx->iqb_i_vlan_type()) || $cx->SUPER::qb_i_vlan_type();
}
sub qb_v_egress {
    my $cx = shift;
    return $cx->iqb_v_egress() || $cx->SUPER::qb_v_egress();
}
sub qb_cv_egress {
    my $cx = shift;
    return $cx->iqb_cv_egress() || $cx->SUPER::qb_cv_egress();
}
sub qb_v_untagged {
    my $cx = shift;
    return $cx->iqb_v_untagged() || $cx->SUPER::qb_v_untagged();
}
sub qb_cv_untagged {
    my $cx = shift;
    return $cx->iqb_cv_untagged() || $cx->SUPER::qb_cv_untagged();
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::ArubaCX - SNMP Interface to L3 Devices running ArubaOS-CX

=head1 AUTHORS

Jeroen van Ingen

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $cx = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $cx->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for devices running ArubaOS-CX

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::IEEE802_Bridge

=item SNMP::Info::IEEE802dot3ad

=back

=head2 Required MIBs

=over

=item F<ARUBAWIRED-FAN-MIB>
=item F<ARUBAWIRED-VSF-MIB>
=item F<ARUBAWIRED-POWERSUPPLY-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

See L<SNMP::Info::IEEE802_Bridge> for its own MIB requirements.

See L<SNMP::Info::IEEE802dot3ad> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $cx->stack_info()

If the device supports VSF stacking and is not in standalone mode, returns
a string describing the switch family and the number of stack members.
Example return value: '6300M (stack of 2)'. Will return undef when VSF is not
supported or when the device is VSF standalone.

=item $cx->model()

Returns L<stack_info()> if defined, otherwise will fall back to returning the
model from C<entPhysicalModelName.1>; if that's also not set, will use
C<sysObjectID> as a last resort, stripping 'arubaWiredSwitch' from the value.

=item $cx->vendor()

Returns (lowercased) value for C<entPhysicalMfgName.1>, or 'aruba'.

=item $cx->os()

Returns 'arubaos-cx'.

=item $cx->os_ver()

Returns the software version. Either C<entPhysicalSoftwareRev.1> or
extracted from C<sysDescr>.

=item $cx->fan()

Returns a string with status information for all fans listed in
C<ARUBAWIRED-FAN-MIB>.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Globals imported from SNMP::Info::IEEE802_Bridge

See documentation in L<SNMP::Info::IEEE802_Bridge> for details.

=head2 Globals imported from SNMP::Info::IEEE802dot3ad

See documentation in L<SNMP::Info::IEEE802dot3ad> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item C<agg_ports>

Returns a HASH reference mapping from slave to master port for each member of
a port bundle on the device. Keys are ifIndex of the slave ports, Values are
ifIndex of the corresponding master ports.

=item C<v_name>
=item C<qb_i_vlan>
=item C<i_vlan_type>
=item C<qb_v_egress>
=item C<qb_cv_egress>
=item C<qb_v_untagged>
=item C<qb_cv_untagged>
All overridden to return the VLAN data structures that we'd expect for a
device that implements C<Q-BRIDGE-MIB>, but with data from
L<SNMP::Info::IEEE8021_Bridge> at PBB 1.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head2 Table Methods imported from SNMP::Info::IEEE802_Bridge

See documentation in L<SNMP::Info::IEEE802_Bridge> for details.

=head2 Table Methods imported from SNMP::Info::IEEE802dot3ad

See documentation in L<SNMP::Info::IEEE802dot3ad> for details.

=cut
