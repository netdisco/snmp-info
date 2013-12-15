# SNMP::Info::Layer2::Airespace
#
# Copyright (c) 2008 Eric Miller
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

package SNMP::Info::Layer2::Airespace;

use strict;
use Exporter;
use SNMP::Info::Bridge;
use SNMP::Info::CDP;
use SNMP::Info::Airespace;

@SNMP::Info::Layer2::Airespace::ISA
    = qw/SNMP::Info::Airespace SNMP::Info::CDP SNMP::Info::Bridge Exporter/;
@SNMP::Info::Layer2::Airespace::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE/;

$VERSION = '3.09';

%MIBS = (
    %SNMP::Info::MIBS,      %SNMP::Info::Bridge::MIBS,
    %SNMP::Info::CDP::MIBS, %SNMP::Info::Airespace::MIBS,
    'CISCO-LWAPP-DOT11-CLIENT-MIB' => 'cldcClientCurrentTxRateSet',
    'CISCO-LWAPP-DOT11-MIB'        => 'cldHtDot11nChannelBandwidth',
    'CISCO-LWAPP-AP-MIB'           => 'cLApIfMacAddress',
);

%GLOBALS = (
    %SNMP::Info::GLOBALS,      %SNMP::Info::Bridge::GLOBALS,
    %SNMP::Info::CDP::GLOBALS, %SNMP::Info::Airespace::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::FUNCS,      %SNMP::Info::Bridge::FUNCS,
    %SNMP::Info::CDP::FUNCS, %SNMP::Info::Airespace::FUNCS,
    # CISCO-LWAPP-AP-MIB::cLApTable
    'ap_if_mac'        => 'cLApIfMacAddress',
    # CISCO-LWAPP-DOT11-CLIENT-MIB::cldcClientTable
    'client_txrate'    => 'cldcClientCurrentTxRateSet',
    'cd11_proto'       => 'cldcClientProtocol',
    'cd11_rateset'     => 'cldcClientDataRateSet',
    # CISCO-LWAPP-DOT11-MIB::cldHtMacOperationsTable
    'cd11n_ch_bw'      => 'cldHtDot11nChannelBandwidth',

);

%MUNGE = (
    %SNMP::Info::MUNGE,      %SNMP::Info::Bridge::MUNGE,
    %SNMP::Info::CDP::MUNGE, %SNMP::Info::Airespace::MUNGE,
    'ap_if_mac'         => \&SNMP::Info::munge_mac,
    'cd11n_ch_bw'       => \&munge_cd11n_ch_bw,
    'cd11_rateset'      => \&munge_cd11_rateset,
    'cd11_proto'        => \&munge_cd11_proto,
);

# 802.11n Modulation and Coding Scheme (MCS)
my $mcs_index = {
    20 => {
	m0  => '6.5',
	m1  => '13',
	m2  => '19.5',
	m3  => '26',
	m4  => '39',
	m5  => '52',
	m6  => '58.5',
	m7  => '65',
	m8  => '13',
	m9  => '26',
	m10 => '39',
	m11 => '52',
	m12 => '78',
	m13 => '104',
	m14 => '117',
	m15 => '130',
	# This is a cheat for 802.11a bonded
	m108 => '108',
    },
    40 => {
	m0  => '15',
	m1  => '30',
	m2  => '45',
	m3  => '60',
	m4  => '90',
	m5  => '120',
	m6  => '135',
	m7  => '157.5',
	m8  => '30',
	m9  => '60',
	m10 => '90',
	m11 => '120',
	m12 => '180',
	m13 => '240',
	m14 => '270',
	m15 => '300',
    }
};

sub os {
    return 'cisco';
}

sub vendor {
    return 'cisco';
}

sub model {
    my $airespace = shift;
    my $model     = $airespace->airespace_model();
    return unless defined $model;

    return $model;
}

sub cd11_mac {
    my $airespace = shift;
    my $cd11_sigstrength = $airespace->cd11_sigstrength();

    my $ret = {};
    foreach my $idx ( keys %$cd11_sigstrength ) {
	my $mac = join( ":", map { sprintf "%02x", $_ } split /\./, $idx );
	$ret->{$idx} = $mac
    }
    return $ret;
}

sub cd11_txrate {
    my $airespace = shift;
    
    my $rates  = $airespace->client_txrate() || {};
    my $protos = $airespace->cd11_proto()    || {};
    my $bws    = $airespace->cd11n_ch_bw()   || {};
    
    my $cd11_txrate = {};
    foreach my $idx ( keys %$rates ) {
	my $rate = $rates->{$idx} || '0.0';
	
	if ( $rate =~ /^\d+/ ) {
            $cd11_txrate->{$idx} = [ $rate * 1.0 ];
	}
	elsif ( $rate =~ /^m/ ) {
	    my $band = $protos->{$idx};
	    my $bw   = $bws->{$band};
	    $cd11_txrate->{$idx} = [ $mcs_index->{$bw}->{$rate} || '0.0' ];
	}
	else {
	    $cd11_txrate->{$idx} = [ $rate ];
	}
    }
    return $cd11_txrate;
}

sub munge_cd11n_ch_bw {
    my $bw = shift;
    
    if ( $bw =~ /forty/ ) {
	return 40;
    }
    return 20;
}

sub munge_cd11_proto {
    my $bw = shift;
    
    return 2 if ( $bw eq 'dot11n5' );

    return 1;
}

sub munge_cd11_rateset {
    my $rates = shift;
    return [ map { $_ * 1.0 } split /,/, $rates ];
}

# Cisco provides the AP's Ethernet MAC via
# CISCO-LWAPP-AP-MIB::cLApIfMacAddress this was not available pre-Cisco
sub i_mac {
    my $airespace = shift;
    my $partial   = shift;

    my $i_index = $airespace->i_index($partial)  || {};
    my $ap_mac  = $airespace->ap_if_mac()        || {};

    my $i_mac = $airespace->SUPER::i_mac() || {};
    foreach my $iid ( keys %$i_index ) {
	my $index = $i_index->{$iid};
	next unless defined $index;

	if ( $index =~ /(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/ ) {
	    $index =~ s/\.\d+$//;
	    next unless defined $index;
	    my $sys_mac = join( '.', map { hex($_) } split( ':', $index ) );
	    my $mac = $ap_mac->{$sys_mac};
	    $i_mac->{$iid} = $mac;
	}
    }
    return $i_mac;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::Airespace - SNMP Interface to Cisco (Airespace) Wireless
Controllers

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

    #Let SNMP::Info determine the correct subclass for you.

    my $airespace = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 

    or die "Can't connect to DestHost.\n";

    my $class = $airespace->class();
    print " Using device sub class : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from 
Cisco (Airespace) Wireless Controllers through SNMP.

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

my $airespace = new SNMP::Info::Layer2::Airespace(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Airespace

=item SNMP::Info::CDP

=item SNMP::Info::Bridge

=back

=head2 Required MIBs

=over

=item F<CISCO-LWAPP-DOT11-CLIENT-MIB>

=item F<CISCO-LWAPP-DOT11-MIB>

=item F<CISCO-LWAPP-AP-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Airespace/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CDP/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::Bridge/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $airespace->vendor()

Returns 'cisco'

=item $airespace->os()

Returns 'cisco'

=item $airespace->model()

(C<agentInventoryMachineModel>)

=back

=head2 Global Methods imported from SNMP::Info::Airespace

See documentation in L<SNMP::Info::Airespace/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::CDP

See documentation in L<SNMP::Info::CDP/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::Bridge

See documentation in L<SNMP::Info::Bridge/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over 

=item cd11_mac()

Returns client radio interface MAC addresses.

=item cd11_txrate()

Returns client transmission speed in Mbs.

=back 

=head2 Overrides

=over

=item i_mac()

Adds AP Ethernet MAC as port mac on radio ports from C<CISCO-LWAPP-AP-MIB>.

=back

=head2 Table Methods imported from SNMP::Info::Airespace

See documentation in L<SNMP::Info::Airespace/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CDP

See documentation in L<SNMP::Info::CDP/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::Bridge

See documentation in L<SNMP::Info::Bridge/"TABLE METHODS"> for details.

=head1 Data Munging Callback Subroutines

=over

=item munge_cd11n_ch_bw()

Converts 802.11n channel bandwidth to either 20 or 40.

=item munge_cd11_proto()

Converts 802.11n 2.4Ghz to 1 and 5Ghz to 2 to correspond to the
(C<cldHtMacOperationsTable>) index.

=item munge_cd11_rateset()

Converts rate set to array.

=back

=cut
