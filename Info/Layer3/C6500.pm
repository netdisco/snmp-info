# SNMP::Info::Layer3::C6500
# $Id$
#
# Copyright (c) 2008-2009 Max Baker
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

package SNMP::Info::Layer3::C6500;

use strict;
use warnings;
use Exporter;
use SNMP::Info::CiscoStack;
use SNMP::Info::Layer3::CiscoSwitch;
use SNMP::Info::MAU;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

# NOTE : Top-most items gets precedence for @ISA
@SNMP::Info::Layer3::C6500::ISA = qw/
    SNMP::Info::CiscoStack
    SNMP::Info::Layer3::CiscoSwitch
    SNMP::Info::MAU
    Exporter
/;

@SNMP::Info::Layer3::C6500::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '3.19';

# NOTE: Order creates precedence
#       Example: v_name exists in Bridge.pm and CiscoVTP.pm
#       Bridge is called from Layer3 and CiscoStpExtensions
#       So we want CiscoVTP to come last to get the right one.
# The @ISA order should match these orders.

%MIBS = (
    %SNMP::Info::MAU::MIBS,
    %SNMP::Info::Layer3::CiscoSwitch::MIBS,
    %SNMP::Info::CiscoStack::MIBS,
    'CISCO-VIRTUAL-SWITCH-MIB' => 'cvsSwitchMode',
);

%GLOBALS = (
    %SNMP::Info::MAU::GLOBALS,
    %SNMP::Info::Layer3::CiscoSwitch::GLOBALS,
    %SNMP::Info::CiscoStack::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::MAU::FUNCS,
    %SNMP::Info::Layer3::CiscoSwitch::FUNCS,
    %SNMP::Info::CiscoStack::FUNCS,
);

%MUNGE = (
    %SNMP::Info::MAU::MUNGE,
    %SNMP::Info::Layer3::CiscoSwitch::MUNGE,
    %SNMP::Info::CiscoStack::MUNGE,
);

sub vendor {
    return 'cisco';
}

sub serial {
    my $c6500 = shift;

    my $serial = $c6500->SUPER::serial();
    return $serial if defined $serial and $serial;

    # now grab the table only if SUPER cannot find it
    my $e_serial = $c6500->e_serial();

    # Find entity table entry for this unit
    foreach my $e ( sort keys %$e_serial ) {
        if (defined $e_serial->{$e} and $e_serial->{$e} !~ /^\s*$/) {
            return $e_serial->{$e};
        }
    }
}

#  Newer versions use the ETHERLIKE-MIB to report operational duplex.

sub i_duplex {
    my $c6500   = shift;
    my $partial = shift;

    my $el_duplex = $c6500->el_duplex($partial);

    # Newer software
    if ( defined $el_duplex and scalar( keys %$el_duplex ) ) {
        my %i_duplex;
        foreach my $el_port ( keys %$el_duplex ) {
            my $duplex = $el_duplex->{$el_port};
            next unless defined $duplex;

            $i_duplex{$el_port} = 'half' if $duplex =~ /half/i;
            $i_duplex{$el_port} = 'full' if $duplex =~ /full/i;
        }
        return \%i_duplex;
    }

    # Fall back to CiscoStack method
    else {
        return $c6500->SUPER::i_duplex($partial);
    }
}

# Newer software uses portDuplex as admin setting

sub i_duplex_admin {
    my $c6500   = shift;
    my $partial = shift;

    my $el_duplex = $c6500->el_duplex($partial);

    # Newer software
    if ( defined $el_duplex and scalar( keys %$el_duplex ) ) {
        my $p_port   = $c6500->p_port()   || {};
        my $p_duplex = $c6500->p_duplex() || {};

        my $i_duplex_admin = {};
        foreach my $port ( keys %$p_duplex ) {
            my $iid = $p_port->{$port};
            next unless defined $iid;
            next if ( defined $partial and $iid !~ /^$partial$/ );

            $i_duplex_admin->{$iid} = $p_duplex->{$port};
        }
        return $i_duplex_admin;
    }

    # Fall back to CiscoStack method
    else {
        return $c6500->SUPER::i_duplex_admin($partial);
    }
}

sub is_virtual_switch {
    my $cvs = shift;
    my $cvsSwM = $cvs->cvsSwitchMode() || '';

    if ( $cvsSwM eq 'multiNode' ) {
        return 1;
    }
    return 0;
}

sub set_i_duplex_admin {

    # map a textual duplex to an integer one the switch understands
    my %duplexes = qw/half 1 full 2 auto 4/;

    my $c6500 = shift;
    my ( $duplex, $iid ) = @_;
 
    if ( $c6500->is_virtual_switch() ) {

        # VSS -> MAU
        # Due to VSS bug
        # 1. Set the ifMauDefaultType
        # 2. Disable ifMauAutoNegAdminStatus
        # If the second set is not done, this is not going to be
        # working... Cisco Bug id CSCty97033.
        # SXI is not working (up to at least relase SXI9).
        # SXJ is working at SXJ3 (not before).

        return $c6500->mau_set_i_duplex_admin( $duplex, $iid );
    }

    my $el_duplex = $c6500->el_duplex($iid);

    # Auto duplex only supported on newer software
    if ( defined $el_duplex and scalar( keys %$el_duplex ) ) {
        my $p_port = $c6500->p_port() || {};
        my %reverse_p_port = reverse %$p_port;

        $duplex = lc($duplex);

        return 0 unless defined $duplexes{$duplex};

        $iid = $reverse_p_port{$iid};

        return $c6500->set_p_duplex( $duplexes{$duplex}, $iid );
    }
    else {
        return $c6500->SUPER::set_i_duplex_admin( $duplex, $iid );
    }
}

sub set_i_speed_admin {
    my $c6500   = shift;
    my ( $speed, $iid ) = @_;

    if ( $c6500->is_virtual_switch() ) {

        # VSS -> MAU
        # Due to VSS bug
        # 1. Set the ifMauDefaultType
        # 2. Disable ifMauAutoNegAdminStatus
        # If the second set is not done, this is not going to be working...
        # Cisco Bug id CSCty97033.
        # SXI is not working (at least up to relase SXI9).
        # SXJ is working at SXJ3 (not before).

        return $c6500->mau_set_i_speed_admin( $speed, $iid );
    }
    else {

        # normal behavior using the CiscoStack method
        return $c6500->SUPER::set_i_speed_admin( $speed, $iid );
    }
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::C6500 - SNMP Interface to Cisco Catalyst 6500 Layer 2/3
Switches running IOS and/or CatOS

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $c6500 = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $c6500->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for Cisco Catalyst 6500 Layer 2/3 Switches.  

These devices run IOS but have some of the same characteristics as the
Catalyst WS-C family (5xxx). For example, forwarding tables are held in
VLANs, and extended interface information is gleaned from F<CISCO-SWITCH-MIB>.

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

 my $c6500 = new SNMP::Info::Layer3::C6500(...);

=head2 Inherited Classes

=over

=item SNMP::Info::CiscoStack

=item SNMP::Info::Layer3::CiscoSwitch

=item SNMP::Info::MAU

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::CiscoStack/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::Layer3::CiscoSwitch/"Required MIBs"> for its own MIB
requirements.

See L<SNMP::Info::MAU/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $c6500->vendor()

    Returns 'cisco'

=item $c6500->cvsSwitchMode()

Returns the Switch status: multiNode or standalone.

=item $c6500->is_virtual_switch()

Return 1 if the switch (C<cvsSwitchMode>) is in multimode (VSS).

=item $c6500->serial()

Returns serial number of unit (falls back to C<entPhysicalSerialNum>).

=back

=head2 Globals imported from SNMP::Info::CiscoStack

See documentation in L<SNMP::Info::CiscoStack/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::Layer3::CiscoSwitch

See documentation in L<SNMP::Info::Layer3::CiscoSwitch/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $c6500->i_duplex()

Returns reference to hash of iid to current link duplex setting.

Newer software versions return duplex based upon the result of
$c6500->el_duplex().  Otherwise it uses the result of the call to
CiscoStack::i_duplex().

See L<SNMP::Info::Etherlike> for el_duplex() method and
L<SNMP::Info::CiscoStack> for its i_duplex() method.

=item $c6500->i_duplex_admin()

Returns reference to hash of iid to administrative duplex setting.

Newer software versions return duplex based upon the result of
$c6500->p_duplex().  Otherwise it uses the result of the call to
CiscoStack::i_duplex().

See L<SNMP::Info::CiscoStack> for its i_duplex() and p_duplex() methods.

=item $c6500->set_i_duplex_admin(duplex, ifIndex)

Sets port duplex, must be supplied with duplex and port C<ifIndex>.

Speed choices are 'auto', 'half', 'full'.

Crosses $c6500->p_port() with $c6500->p_duplex() to utilize port C<ifIndex>.

    Example:
    my %if_map = reverse %{$c6500->interfaces()};
    $c6500->set_i_duplex_admin('auto', $if_map{'FastEthernet0/1'}) 
        or die "Couldn't change port duplex. ",$c6500->error(1);

=item $c6500->set_i_speed_admin(speed, ifIndex)

Sets port speed, must be supplied with speed and port C<ifIndex>.

Speed choices are '10', '100', '1000'.

Crosses $c6500->p_port() with $c6500->p_speed() to utilize port C<ifIndex>.

=back

=head2 Table Methods imported from SNMP::Info::CiscoStack

See documentation in L<SNMP::Info::CiscoStack/"TABLE METHODS"> for details.


=head2 Table Methods imported from SNMP::Info::Layer3::CiscoSwitch

See documentation in L<SNMP::Info::Layer3::CiscoSwitch/"TABLE METHODS"> for
details.


=head2 Table Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"TABLE METHODS"> for details.

=cut
