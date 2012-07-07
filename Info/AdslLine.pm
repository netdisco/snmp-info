# SNMP::Info::AdslLine
#
# Copyright (c) 2009 Alexander Hartmaier
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

package SNMP::Info::AdslLine;

use strict;
use Exporter;
use SNMP::Info;

@SNMP::Info::AdslLine::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::AdslLine::EXPORT_OK = qw//;

use vars qw/$VERSION %MIBS %FUNCS %GLOBALS %MUNGE/;

$VERSION = '2.07_001';

%MIBS = ( 'ADSL-LINE-MIB' => 'adslLineType' );

%GLOBALS = ();

%FUNCS = (
    # ADSL-LINE-MIB::adslAtucChanTable
    'adsl_atuc_interleave_delay'    => 'adslAtucChanInterleaveDelay',
    'adsl_atuc_curr_tx_rate'        => 'adslAtucChanCurrTxRate',
    'adsl_atuc_prev_tx_rate'        => 'adslAtucChanPrevTxRate',
    'adsl_atuc_crc_block_len'       => 'adslAtucChanCrcBlockLength',
    
    # ADSL-LINE-MIB::adslAturChanTable
    'adsl_atur_interleave_delay'    => 'adslAturChanInterleaveDelay',
    'adsl_atur_curr_tx_rate'        => 'adslAturChanCurrTxRate',
    'adsl_atur_prev_tx_rate'        => 'adslAturChanPrevTxRate',
    'adsl_atur_crc_block_len'       => 'adslAturChanCrcBlockLength',
);

%MUNGE = ();

1;
__END__

=head1 NAME

SNMP::Info::AdslLine - SNMP Interface to the ADSL-LINE-MIB

=head1 AUTHOR

Alexander Hartmaier

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $info = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class = $info->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

SNMP::Info::AdslLine is a subclass of SNMP::Info that provides 
information about the adsl interfaces of a device.

Use or create in a subclass of SNMP::Info.  Do not use directly.

=head2 Inherited Classes

none.

=head2 Required MIBs

=over

=item F<ADSL-LINE-MIB>

=back

MIBs can be found at ftp://ftp.cisco.com/pub/mibs/v2/v2.tar.gz

=head1 GLOBALS

=over

=item none

=back

=head1 TABLE METHODS

=head2 ATUC channel table (C<adslAtucChanTable>)

This table provides one row for each ATUC channel.
ADSL channel interfaces are those ifEntries where ifType
is equal to adslInterleave(124) or adslFast(125).

=over

=item $info->adsl_atuc_interleave_delay()

(C<adslAtucChanInterleaveDelay>)

=item $info->adsl_atuc_curr_tx_rate()

(C<adslAtucChanCurrTxRate>)

=item $info->adsl_atuc_prev_tx_rate()

(C<adslAtucChanPrevTxRate>)

=item $info->adsl_atuc_crc_block_len()

(C<adslAtucChanCrcBlockLength>)

=back

=head2 ATUR channel table (C<adslAturChanTable>)

This table provides one row for each ATUR channel.
ADSL channel interfaces are those ifEntries where ifType
is equal to adslInterleave(124) or adslFast(125).

=over

=item $info->adsl_atur_interleave_delay()

(C<adslAturChanInterleaveDelay>)

=item $info->adsl_atur_curr_tx_rate()

(C<adslAturChanCurrTxRate>)

=item $info->adsl_atur_prev_tx_rate()

(C<adslAturChanPrevTxRate>)

=item $info->adsl_atur_crc_block_len()

(C<adslAturChanCrcBlockLength>)

=back

=cut
