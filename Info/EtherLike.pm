# SNMP::Info::EtherLike
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

package SNMP::Info::EtherLike;
$VERSION = 0.1;

use strict;

use Exporter;
use SNMP::Info;

use vars qw/$VERSION $DEBUG %MIBS %FUNCS %GLOBALS %MUNGE $INIT/;
@SNMP::Info::EtherLike::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::EtherLike::EXPORT_OK = qw//;

$DEBUG=0;
$SNMP::debugging=$DEBUG;

$INIT = 0;

# Same info in both rfc1398 and this?
%MIBS = ('ETHERLIKE-MIB' => 'etherMIB' );

%GLOBALS = ();

%FUNCS = (
          # EtherLike StatsTable
          'el_index'  => 'dot3StatsIndex',
          'el_duplex' => 'dot3StatsDuplexStatus',
          );

%MUNGE = ( %SNMP::Info::MUNGE );

1;
__END__


=head1 NAME

SNMP::Info::EtherLike - Perl5 Interface to SNMP ETHERLIKE-MIB 

=head1 DESCRIPTION

ETHERLIKE-MIB is used by some Layer 3 Devices such as Cisco routers.

Inherits all methods from SNMP::Info

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 my $el = new SNMP::Info::EtherLike(DestHost  => 'myrouter',
                                    Community => 'public');

 my $el_decoder = $el->el_index();
 my $el_duplex = $el->el_duplex(); 

=head1 CREATING AN OBJECT

=over

=item  new SNMP::Info::EtherLike()

Arguments passed to new() are passed on to SNMP::Session::new()
    

    my $el = new SNMP::Info::EtherLike(
        DestHost => $host,
        Community => 'public',
        Version => 3,...
        ) 
    die "Couldn't connect.\n" unless defined $el;

=item  $el->session()

Sets or returns the SNMP::Session object

    # Get
    my $sess = $el->session();

    # Set
    my $newsession = new SNMP::Session(...);
    $el->session($newsession);

=back

=head1 GLOBALS

=over

=item None

=back

=head1 ETHERLIKE STATS TABLE (dot3StatsTable)

=over

=item $el->el_index()

Returns reference to hash. Indexes Stats Table to the interface index (iid).

(B<dot3StatsIndex>)

=item $el->el_duplex()

Returns reference to hash.  Indexes Stats Table to Duplex Status of port.

(B<dot3StatsDuplexStatus>)

=back

=cut
