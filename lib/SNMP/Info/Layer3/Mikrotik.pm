# SNMP::Info::Layer3::Mikrotik
#
# Copyright (c) 2011 Jeroen van Ingen
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

package SNMP::Info::Layer3::Mikrotik;

use strict;
use warnings;
use Exporter;
use SNMP::Info::Layer3;

@SNMP::Info::Layer3::Mikrotik::ISA       = qw/SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Mikrotik::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.977001';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    'HOST-RESOURCES-MIB'       => 'hrSystem',
    'MIKROTIK-MIB'             => 'mtxrLicVersion',
    'MIKROTIK-LLDP-EXT-MIB'    => 'mtLldpRemManAddr', # override bc of CCR quirk
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    'hrSystemUptime' => 'hrSystemUptime',
    'os_level'       => 'mtxrLicLevel',
    'os_ver'         => 'mtxrLicVersion',
    'serial1'        => 'mtxrSystem.3.0',
    'firmware'       => 'mtxrSystem.4.0',
    'fan_type'       => 'mtxrHlActiveFan',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
#    'mt_lldp_rman_addr' => 'mtLldpRemManAddr',  # unique leaf, unique method
 'mt_lldp_rman_addr'    => 'lldpRemManAddr',
 'mt_lldp_rman_subtype' => 'lldpRemManAddrSubtype',
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
);

sub vendor {
    return 'mikrotik';
}

sub serial {
    my $mikrotik = shift;
    return $mikrotik->serial1;
}

sub model {
    my $mikrotik = shift;
    my $descr = $mikrotik->description() || '';
    my $model = undef;
    $model = $1 if ( $descr =~ /^RouterOS\s+(\S+)$/i );
    $model = $1 if ( $descr =~ /^RouterOS\s+(RB .*)$/i );
    return $model;
}

sub os {
    return 'routeros';
}

sub board_temp {
    my $mikrotik = shift;
    my $temp = $mikrotik->mtxrHlTemperature;
    return $temp / 10.0;
}

sub cpu_temp {
    my $mikrotik = shift;
    my $temp = $mikrotik->mtxrHlProcessorTemperature;
    return $temp / 10.0;
}

sub _norm_mac_text {
    my $v = shift;
    return unless defined $v;
    $v =~ s/^\s+|\s+$//g;
    $v =~ s/-/:/g;
    return lc $v if $v =~ /^([0-9a-f]{2}:){5}[0-9a-f]{2}$/i;
    return;
}

sub c_id {
    my ($self, $partial) = @_;
    my $super = $self->SUPER::c_id($partial) || {};
    return $super if scalar keys %$super;

    my $rid = $self->lldp_rem_id($partial)     || {};
    my $sub = $self->lldp_rem_id_sub($partial) || {};
    my %out;

    for my $idx (keys %$rid) {
        my $v = $rid->{$idx};
        next unless defined $v && length $v;

        if (defined $sub->{$idx} && $sub->{$idx} == 4) { # macAddress subtype
            my $m = _norm_mac_text($v);
            $out{$idx} = $m if defined $m;
            next;
        }

        $out{$idx} = $v;
    }

    return scalar(keys %out) ? \%out : $super;
}
sub c_ip {
    my ($self, $partial) = @_;

    # normal behavior first
    my $super = $self->SUPER::c_ip($partial) || {};
    return $super if scalar keys %$super;

    # fallback: build keyspace from joinable neighbor tuples
    my $cid   = $self->c_id($partial)   || {};
    my $cif   = $self->c_if($partial)   || {};
    my $cport = $self->c_port($partial) || {};

    my %out;
    for my $idx (keys %$cif) {
        next unless exists $cid->{$idx};
        next unless exists $cport->{$idx};

        # placeholder only; value is not trusted mgmt IP
        $out{$idx} = '0.0.0.0';
    }

    return \%out;
}
sub _mt_unlock_rem_man_addr {
    for my $n (qw(lldpRemManAddr mtLldpRemManAddr)) {
        my $m = $SNMP::MIB{$n} or next;
        $m->{access} = 'ReadOnly';
    }
}

sub mt_mib_probe {
    my $self = shift;
    my $sess = $self->session;

    my $info     = $self->mt_lldp_rman_addr;
    my $name_tbl = $sess->gettable('mtLldpRemManAddr');
    my $oid_tbl  = $sess->gettable('.1.0.8802.1.1.2.1.4.2.1.2');

    my $name_n = (ref $name_tbl eq 'HASH') ? scalar keys %{$name_tbl} : -1;
    my $oid_n  = (ref $oid_tbl  eq 'HASH') ? scalar keys %{$oid_tbl}  : -1;

    return {
        sess         => $sess ? 1 : 0,
        info_defined => defined $info ? 1 : 0,
        name_ref     => ref($name_tbl) || 'undef',
        name_keys    => $name_n,
        oid_ref      => ref($oid_tbl) || 'undef',
        oid_keys     => $oid_n,
    };
}


1;
__END__

=head1 NAME

SNMP::Info::Layer3::Mikrotik - SNMP Interface to Mikrotik devices

=head1 AUTHORS

Jeroen van Ingen
initial version based on SNMP::Info::Layer3::NetSNMP by Bradley Baetz and Bill Fenner

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $mikrotik = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $mikrotik->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Mikrotik devices

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item F<HOST-RESOURCES-MIB>

=item F<MIKROTIK-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $mikrotik->vendor()

Returns C<'mikrotik'>.

=item $mikrotik->os()

Returns C<'routeros'>.

=item $mikrotik->model()

Tries to extract the device model from C<sysDescr>.

=item $mikrotik->os_ver()

Returns the value of C<mtxrLicVersion>.

=item $mikrotik->os_level()

Returns the value of RouterOS level C<mtxrLicLevel>

=item $mikrotik->board_temp()

=item $mikrotik->cpu_temp()

Returns the appropriate temperature values

=item $mikrotik->serial()

Returns the device serial.

=item $mikrotik->firmware()

Returns the firmware version of hardware.

=back

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

None.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3> for details.

=cut
