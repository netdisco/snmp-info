package SNMP::Info::CiscoAuthFramework;

use strict;
use warnings;
use Exporter;
use SNMP::Info;

@SNMP::Info::CiscoAuthFramework::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::CiscoAuthFramework::EXPORT_OK = qw//;

our ($VERSION, %MIBS, %FUNCS, %GLOBALS, %MUNGE);

$VERSION = '3.977001';

%MIBS = (
    'CISCO-AUTH-FRAMEWORK-MIB' => 'ciscoAuthFrameworkMIB',
);

%GLOBALS = ();

%FUNCS = (
    # CISCO-AUTH-FRAMEWORK-MIB::cafSessionTable
    'caf_session_auth_vlan' => 'cafSessionAuthVlan',
);

%MUNGE = ();

sub i_auth_vlan_membership {
    my $auth = shift;

    my $sessions = $auth->caf_session_auth_vlan() || {};

    # Table methods in SNMP::Info normally return a hash reference.
    # Be defensive in case the underlying implementation changes or
    # returns an unexpected value.
    return {} unless ref $sessions eq 'HASH';

    my %seen;
    my %membership;

    foreach my $index (keys %{$sessions}) {
        next unless defined $index;

        # cafSessionTable is indexed by:
        #   ifIndex + IMPLIED cafSessionId
        #
        # SNMP::Info represents the complete SNMP table index as a
        # dot-separated string. We only need the leading ifIndex here.
        my ($ifindex) = split /\./, $index, 2;

        my $vlan = $sessions->{$index};

        next unless defined $ifindex && $ifindex =~ /^\d+$/;
        next unless defined $vlan    && $vlan    =~ /^\d+$/;

        # cafSessionAuthVlan uses VlanIndexOrZero.
        # A value of 0 means that no authorized VLAN was applied.
        next if $vlan == 0;

        # Multiple authentication sessions may exist on the same
        # interface and several sessions may use the same VLAN.
        # Store the data as a set first to avoid duplicates.
        $seen{$ifindex}{$vlan} = 1;
    }

    foreach my $ifindex (keys %seen) {
        $membership{$ifindex} = [
            sort { $a <=> $b } keys %{ $seen{$ifindex} }
        ];
    }

    return \%membership;
}

1;

__END__

=head1 NAME

SNMP::Info::CiscoAuthFramework - Cisco Authentication Framework information

=head1 DESCRIPTION

Provides access to information from CISCO-AUTH-FRAMEWORK-MIB.

The module exposes Cisco Authentication Framework session information and
provides helper methods for normalized interface-based authentication data.

=head1 TABLE METHODS

=head2 $cisco->caf_session_auth_vlan()

Returns the authorized VLAN assigned to each Cisco Authentication Framework
session.

The underlying C<cafSessionTable> is indexed by C<ifIndex> and
C<cafSessionId>. The returned hash therefore uses the complete SNMP table
index as its key.

Example:

    {
        '10.56.56.48...' => 302,
        '10.56.56.48...' => 304,
        '48.56.56.48...' => 800,
    }

=head2 $cisco->i_auth_vlan_membership()

Returns the authorized VLANs grouped by interface index.

Multiple authentication sessions may exist on the same interface. Duplicate
VLAN assignments are removed.

Example:

    {
        10 => [302, 304],
        48 => [311, 330, 800],
    }

Sessions with C<cafSessionAuthVlan> equal to zero are ignored.

=cut