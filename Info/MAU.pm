# SNMP::Info::MAU - Media Access Unit - RFC2668
# Max Baker <max@warped.org>
#
# Copyright (c) 2002, Regents of the University of California
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#     * Neither the name of the University of California, Santa Cruz nor the 
#       names of its contributors may be used to endorse or promote products 
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::MAU;
$VERSION = 0.1;

use strict;

use Exporter;
use SNMP::Info;

use vars qw/$VERSION $DEBUG %MIBS %FUNCS %GLOBALS %MUNGE $INIT/;
@SNMP::Info::MAU::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::MAU::EXPORT_OK = qw//;

$DEBUG=0;
$SNMP::debugging=$DEBUG;

$INIT = 0;

%MIBS = ('MAU-MIB' => 'mauMod');

%GLOBALS = (
           );

%FUNCS = (
          # Interface MAU Table
          'mau_index'    => 'ifMauIfIndex',
          'mau_link'     => 'ifMauType',
          'mau_status'   => 'ifMauStatus',
          'mau_up'       => 'ifMauMediaAvailable',
          'mau_type'     => 'ifMauTypeList',
          'mau_type_admin'     => 'ifMauDefaultType',
          # Interface Auto-Negotiation Table
          'mau_auto'     => 'ifMauAutoNegSupported',
          'mau_autostat' => 'ifMauAutoNegAdminStatus',
          'mau_autosent' => 'ifMauAutoNegCapAdvertised',
          'mau_autorec'  => 'ifMauAutoNegCapReceived',
          );

%MUNGE = (
          # Inherit all the built in munging
          %SNMP::Info::MUNGE,
          # Add ones for our class
          'mau_type' => \&munge_int2bin,
          'mau_autosent' => \&munge_int2bin,
          'mau_autorec' => \&munge_int2bin,
         );


sub munge_int2bin {
    my $int = shift;
    return undef unless defined $int;
    return unpack("B32", pack("N", $int));
}

sub _isfullduplex{
    my $mau = shift;
    my $mautype = shift;

    my @full_types = qw/11 13 16 18 20/;
    foreach my $type ( @full_types ) {
        return 1 if (substr($mautype,32-$type,1) eq '1')
    }
    return 0;
}

sub _ishalfduplex{
    my $mau = shift;
    my $mautype = shift;

    my @half_types = qw/10 12 15 17 19/;
    foreach my $type ( @half_types ) {
        return 1 if (substr($mautype,32-$type,1) eq '1')
    }
    return 0;
}

1;
__END__


=head1 NAME

SNMP::Info::MAU - Perl5 Interface to SNMP Medium Access Unit (MAU) MIB (RFC2668) 

=head1 DESCRIPTION

MAU-MIB is used by Layer 2 devices like HP Switches . The MAU table
contains link and duplex info for the port itself and the device
connected to that port.

Inherits all methods from SNMP::Info

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 my $mau = new SNMP::Info::MAU(      DestHost  => 'myswitch',
                               Community => 'public');

=head1 CREATING AN OBJECT

=over

=item  new SNMP::Info::MAU()

Arguments passed to new() are passed on to SNMP::Session::new()
    

    my $mau = new SNMP::Info::MAU(
        DestHost => $host,
        Community => 'public',
        Version => 3,...
        ) 
    die "Couldn't connect.\n" unless defined $mau;

=item  $mau->session()

Sets or returns the SNMP::Session object

    # Get
    my $sess = $mau->session();

    # Set
    my $newsession = new SNMP::Session(...);
    $mau->session($newsession);

=item  $mau->all(), $mau->load_all()

Queries each of the methods listed in %FUNCS and returns a hash reference.

$mau->all() will call $mau->load_all() once and then return cahced valued.  
Use $mau->load_all() to reload from the device.

=back

=head1 MAU Global Configuration Values

=over

=item None

=back

=head1 MAU INTERFACE TABLE ENTRIES

=over

=item $mau->mau_index() -  Returns a list of interfaces
and their index in the MAU IF Table.

(B<ifMauIfIndex>)

=item $mau->mau_link() - Returns the type of Media Access used.  

    This is essentially the type of link in use.  
    eg. dot3MauType100BaseTXFD - 100BaseT at Full Duplex

(B<ifMauType>)

=item $mau->mau_status() - Returns the admin link condition as 

    1 - other
    2 - unknown
    3 - operational
    4 - standby
    5 - shutdown
    6 - reset

Use 5 and !5 to see if the link is up or down on the admin side.

(B<ifMauStatus>)

=item $mau->mau_up() -  Returns the current link condition

 (B<ifMauMediaAvailable>)

=item $mau->mau_type() - Returns a 32bit string reporting the capabilities
of the port from a MAU POV. 

  Directly from the MAU-MIB : 
          Bit   Capability
            0      other or unknown
            1      AUI
            2      10BASE-5
            3      FOIRL
            4      10BASE-2
            5      10BASE-T duplex mode unknown
            6      10BASE-FP
            7      10BASE-FB
            8      10BASE-FL duplex mode unknown
            9      10BROAD36
           10      10BASE-T  half duplex mode
           11      10BASE-T  full duplex mode
           12      10BASE-FL half duplex mode
           13      10BASE-FL full duplex mode
           14      100BASE-T4
           15      100BASE-TX half duplex mode
           16      100BASE-TX full duplex mode
           17      100BASE-FX half duplex mode
           18      100BASE-FX full duplex mode
           19      100BASE-T2 half duplex mode
           20      100BASE-T2 full duplex mode

(B<ifMauTypeList>)

=item $mau->mau_auto() - Returns status of auto-negotiation mode for ports.

(B<ifMauAutoNegAdminStatus>)

=item $mau->mau_autosent() - Returns a 32 bit bit-string representing the
capabilities we are broadcasting on that port 

    Uses the same decoder as $mau->mau_type().

(B<ifMauAutoNegCapAdvertised>)


=item $mau->mau_autorec() - Returns a 32 bit bit-string representing the 
capabilities of the device on the other end. 

    Uses the same decoder as $mau->mau_type().

(B<ifMauAutoNegCapReceived>)

=back

=head1 Utility Functions

=over 

=item munge_int2bin() - Unpacks an integer into a 32bit bit string.

=item $mau->_isfullduplex(bitstring)

    Boolean. Checks to see if any of the full_duplex types from mau_type() are
    high.  Currently bits 11,13,16,18,20.

=item $mau->_ishalfduplex(bitstring)
    
    Boolean.  Checks to see if any of the half_duplex types from mau_type() are
    high.  Currently bits 10,12,15,17,19.

=back
=cut
