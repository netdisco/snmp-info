package Test::SNMP::Info::CiscoAuthFramework;

use Test::Class::Most parent => 'My::Test::Class';

use SNMP::Info::CiscoAuthFramework;

sub startup : Tests(startup => 1) {
    my $test = shift;

    $test->SUPER::startup();

    return;
}

sub setup : Tests(setup) {
    my $test = shift;

    $test->SUPER::setup;

    return;
}

sub i_auth_vlan_membership : Tests(2) {
    my $test = shift;
    my $info = $test->{info};

    can_ok($info, 'i_auth_vlan_membership');

    # cafSessionTable is indexed by:
    #
    #   ifIndex + IMPLIED cafSessionId
    #
    # SNMP::Info represents the complete index as a dot-separated
    # string. The values below simulate multiple authentication
    # sessions on interfaces 10 and 48.
    #
    # Interface 10:
    #   VLAN 302
    #   VLAN 304 (twice)
    #   VLAN 0   (must be ignored)
    #
    # Interface 48:
    #   VLAN 311
    #   VLAN 330
    #   VLAN 800
    #
    # Use SNMP::Info's cache mechanism to simulate an already loaded
    # cafSessionAuthVlan table.
    $info->_cache(
        'caf_session_auth_vlan',
        {
            '10.56.56.48.48.48.48.49' => 302,
            '10.56.56.48.48.48.48.50' => 304,
            '10.56.56.48.48.48.48.51' => 304,
            '10.56.56.48.48.48.48.52' => 0,
            '48.56.56.48.48.48.48.53' => 800,
            '48.56.56.48.48.48.48.54' => 330,
            '48.56.56.48.48.48.48.55' => 311,
        }
    );

    my $membership = $info->i_auth_vlan_membership();

    cmp_deeply(
        $membership,
        {
            10 => [302, 304],
            48 => [311, 330, 800],
        },
        'Authorized VLANs are grouped, deduplicated, and sorted by ifIndex'
    );

    return;
}

sub i_auth_vlan_membership_empty : Tests(1) {
    my $test = shift;
    my $info = $test->{info};

    # Simulate an already loaded but empty cafSessionAuthVlan table.
    $info->_cache(
        'caf_session_auth_vlan',
        {}
    );

    my $membership = $info->i_auth_vlan_membership();

    cmp_deeply(
        $membership,
        {},
        'Empty CAF session table returns empty membership'
    );

    return;
}

sub i_auth_vlan_membership_invalid : Tests(1) {
    my $test = shift;
    my $info = $test->{info};

    $info->_cache(
        'caf_session_auth_vlan',
        {
            # Valid entry.
            '10.56.56.48.48.48.48.49' => 302,

            # VLAN zero means that no authorized VLAN was applied.
            '10.56.56.48.48.48.48.50' => 0,

            # Invalid VLAN values.
            '10.56.56.48.48.48.48.51' => 'invalid',
            '10.56.56.48.48.48.48.52' => undef,

            # Invalid ifIndex.
            'invalid.56.56.48.48.48.48.53' => 304,
        }
    );

    my $membership = $info->i_auth_vlan_membership();

    cmp_deeply(
        $membership,
        {
            10 => [302],
        },
        'Invalid indexes, invalid VLANs, and VLAN zero are ignored'
    );

    return;
}

1;
