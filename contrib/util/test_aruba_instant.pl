#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use File::Spec;
use Getopt::Long qw/GetOptions/;
use JSON::PP;
use POSIX qw/ECHO TCSANOW/;
use SNMP::Info::Layer3::ArubaInstant;

# Query the checkout directly. No Netdisco transport or database is used.
sub _main {
my ($host, $user, $help);
my $version = 2;
my $level = 'authPriv';
my $auth = 'SHA';
my $priv = 'AES';
my $home = $ENV{NETDISCO_HOME} || $ENV{HOME};
my $mibdir = File::Spec->catdir($home, 'netdisco-mibs');
GetOptions(
    'host=s' => \$host, 'version=i' => \$version, 'mibdir=s' => \$mibdir,
    'user=s' => \$user, 'security-level=s' => \$level,
    'auth-proto=s' => \$auth, 'priv-proto=s' => \$priv,
    'help' => \$help,
) or die "Use --help for usage.\n";
$host ||= shift @ARGV;
if ($help || !$host) {
    print <<'USAGE';
Usage: ~/bin/localenv perl contrib/util/test_aruba_instant.pl AP_IP

Reads the PR checkout without installing it or accessing Netdisco's database.
Prompts for the SNMPv2 community (hidden on a terminal).
Uses all subdirectories of ~/netdisco-mibs, or --mibdir PATH.

SNMPv3: add --version 3 --user USER [--auth-proto SHA] [--priv-proto AES]
        [--security-level authPriv|authNoPriv|noAuthNoPriv]
Passwords are prompted. Credentials may alternatively be supplied through
SNMP_COMMUNITY, SNMP_AUTH_PASSWORD and SNMP_PRIV_PASSWORD environment variables.
Output includes SSIDs and MAC addresses; redact these before posting publicly.
USAGE
    return($help ? 0 : 1);
}
die "Unexpected arguments.\n" if @ARGV;
die "Version must be 1, 2 or 3.\n" unless $version =~ /^[123]$/;
die "MIB directory does not exist: $mibdir\n" unless -d $mibdir;
my @mibdirs = grep {-d $_} glob(File::Spec->catfile($mibdir, '*'));
die "No MIB subdirectories found in $mibdir.\n" unless @mibdirs;

my %args = (
    DestHost => $host, Version => $version, AutoSpecify => 0,
    MibDirs => \@mibdirs, IgnoreNetSNMPConf => 1,
    UseEnums => 1, RetryNoSuch => 1, BulkWalk => 0,
);
if ($version == 3) {
    die "SNMPv3 requires --user.\n" unless defined $user && length $user;
    die "Invalid security level.\n" unless $level =~ /^(?:authPriv|authNoPriv|noAuthNoPriv)$/;
    @args{qw/SecName SecLevel/} = ($user, $level);
    if ($level ne 'noAuthNoPriv') {
        $args{AuthProto} = $auth;
        $args{AuthPass} = $ENV{SNMP_AUTH_PASSWORD} // _secret('SNMP authentication password');
    }
    if ($level eq 'authPriv') {
        $args{PrivProto} = $priv;
        $args{PrivPass} = $ENV{SNMP_PRIV_PASSWORD} // _secret('SNMP privacy password');
    }
}
else {
    $args{Community} = $ENV{SNMP_COMMUNITY} // _secret('SNMP community');
}
my $base = SNMP::Info->new(%args) or die "Unable to create SNMP session.\n";
my $description = $base->description();
die "No sysDescr returned. Check SNMP access, credentials and version.\n"
    unless defined $description && length $description;
my $detected = $base->device_type();
die "Detected $detected; this test is for Instant 8.x only.\n"
    unless $detected eq 'SNMP::Info::Layer3::ArubaInstant';
my $info = SNMP::Info::Layer3::ArubaInstant->new(%args, Session => $base->session())
    or die "Unable to create ArubaInstant reader.\n";
my $report = _report($info);
$report->{description} = $description;
$report->{class} = $detected;
$report->{library} = $INC{'SNMP/Info/Layer3/ArubaInstant.pm'};
print JSON::PP->new->canonical->pretty->encode($report);
return(@{$report->{unmapped_clients}} ? 2 : 0);
}

sub _report {
    my $info = shift;
    my $interfaces = $info->interfaces() || {};
    my $ssids = $info->i_ssidlist() || {};
    my $bssids = $info->i_ssidmac() || {};
    my $broadcast = $info->i_ssidbcast() || {};
    my $channels = $info->i_80211channel() || {};
    my $power = $info->dot11_cur_tx_pwr_mw() || {};
    my $raw_power = $info->instant_radio_power() || {};
    my $raw_channels = $info->instant_radio_channel() || {};
    my $macs = $info->fw_mac() || {};
    my $ports = $info->fw_port() || {};
    my $bridge = $info->bp_index() || {};
    my (@wlans, @radios, @clients, @unmapped);
    foreach my $key (sort keys %$ssids) {
        (my $iid = $key) =~ s/\.\d+$//;
        push @wlans, {port => $interfaces->{$iid}, ssid => $ssids->{$key},
            bssid => $bssids->{$key}, broadcast => $broadcast->{$key}};
    }
    foreach my $iid (sort keys %$interfaces) {
        next unless $interfaces->{$iid} =~ /\.radio\d+$/;
        (my $source = $iid) =~ s/\.0$//;
        push @radios, {port => $interfaces->{$iid}, channel => $channels->{$iid},
            raw_channel => $raw_channels->{$source}, power_dbm => $raw_power->{$source},
            power_mw => $power->{$iid}};
    }
    foreach my $key (sort grep {/^instant\./} keys %$macs) {
        my $bp = $ports->{$key};
        my $iid = defined $bp ? $bridge->{$bp} : undef;
        my $port = defined $iid ? $interfaces->{$iid} : undef;
        push @clients, {mac => $macs->{$key}, bssid => $bp, port => $port};
    }
    # The class deliberately omits clients whose BSSID cannot be joined.
    my $raw_macs = $info->instant_client_mac() || {};
    my $raw_bssids = $info->instant_client_bssid() || {};
    foreach my $key (sort keys %$raw_macs) {
        next if exists $macs->{"instant.$key"};
        push @unmapped, {mac => $raw_macs->{$key}, bssid => $raw_bssids->{$key}};
    }
    return {wlans => \@wlans, radios => \@radios, clients => \@clients,
        unmapped_clients => \@unmapped};
}

sub _secret {
    my $label = shift;
    print STDERR "$label: ";
    my ($terminal, $flags);
    if (-t STDIN) {
        $terminal = POSIX::Termios->new();
        $terminal->getattr(fileno STDIN);
        $flags = $terminal->getlflag();
        $terminal->setlflag($flags & ~ECHO);
        $terminal->setattr(fileno STDIN, TCSANOW);
    }
    my $restore = sub {
        if ($terminal) {
            $terminal->setlflag($flags);
            $terminal->setattr(fileno STDIN, TCSANOW);
            print STDERR "\n";
        }
    };
    local $SIG{INT} = sub { $restore->(); die "Interrupted.\n" };
    my $value = <STDIN>;
    $restore->();
    die "No credential supplied.\n" unless defined $value;
    $value =~ s/[\r\n]+$//;
    die "Empty credential.\n" unless length $value;
    return $value;
}

exit _main() unless caller;
1;
