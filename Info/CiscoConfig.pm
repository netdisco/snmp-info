# SNMP::Info::CiscoConfig
# Justin Hunter
# $Id$
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

package SNMP::Info::CiscoConfig;
$VERSION = 1.05;

use strict;

use Exporter;
use SNMP::Info;

@SNMP::Info::CiscoConfig::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::CiscoConfig::EXPORT_OK = qw//;

use vars qw/$VERSION %MIBS %FUNCS %GLOBALS %MUNGE/;

%MIBS = (
         'CISCO-CONFIG-COPY-MIB' => 'ccCopyTable',
         'CISCO-FLASH-MIB'       => 'ciscoFlashCopyTable',
         'OLD-CISCO-SYS-MIB'     => 'writeMem',
        );

%GLOBALS = (
            # OLD-CISCO-SYS-MIB
            'old_write_mem'             => 'writeMem',
            'old_write_net'             => 'writeNet',
            );

%FUNCS = (
          # CISCO-COPY-CONFIG-MIB::ccCopyTable
          'config_protocol'           => 'ccCopyProtocol',
          'config_source_type'        => 'ccCopySourceFileType',
          'config_dest_type'          => 'ccCopyDestFileType',
          'config_server_addr'        => 'ccCopyServerAddress',
          'config_filename'           => 'ccCopyFileName',
          'config_username'           => 'ccCopyUserName',
          'config_password'           => 'ccCopyUserPassword',
          'config_notify_complete'    => 'ccCopyNotificationOnCompletion',
          'config_copy_state'         => 'ccCopyState',
          'config_copy_start_time'    => 'ccCopyTimeStarted',
          'config_copy_complete_time' => 'ccCopyTimeCompleted',
          'config_fail_cause'         => 'ccCopyFailCause',
          'config_row_status'         => 'ccCopyEntryRowStatus',
          # CISCO-FLASH-MIB::ciscoFlashCopyTable
          'flash_copy_cmd'            => 'ciscoFlashCopyCommand',
          'flash_copy_protocol'       => 'ciscoFlashCopyProtocol',
          'flash_copy_address'        => 'ciscoFlashCopyServerAddress',
          'flash_copy_source'         => 'ciscoFlashCopySourceName',
          'flash_copy_dest'           => 'ciscoFlashCopyDestinationName',
          'flash_copy_row_status'     => 'ciscoFlashCopyEntryStatus',
         );

%MUNGE = (
          );

sub copy_run_tftp {
    my $ciscoconfig = shift;
    my ( $tftphost, $tftpfile ) = @_;

    srand( time() ^ ( $$ + ( $$ << 15 ) ) );
    my $rand = int( rand( 1 << 24 ) );

    $ciscoconfig->set_config_protocol( 1, $rand );
    $ciscoconfig->set_config_source_type( 4, $rand );
    $ciscoconfig->set_config_dest_type( 1, $rand );
    $ciscoconfig->set_config_server_addr( $tftphost, $rand );
    $ciscoconfig->set_config_filename( $tftpfile, $rand );
    $ciscoconfig->set_config_row_status( 1, $rand );
    my $status = 0;
    while ( $status !~ /successful|failed/ ) {
        my $t = $ciscoconfig->config_copy_state($rand);
        $status = $t->{$rand};
        last if $status =~ /successful|failed/;
        sleep 1;
    }

    $ciscoconfig->set_config_row_status( 6, $rand );
    return 0 if $status eq 'failed';
    return 1 if $status eq 'successful';
}

sub copy_run_start {
    my $ciscoconfig = shift;

    srand( time() ^ ( $$ + ( $$ << 15 ) ) );
    my $rand = int( rand( 1 << 24 ) );

    my $t = $ciscoconfig->set_config_source_type( 4, $rand );
    $ciscoconfig->set_config_dest_type( 3, $rand );
    $ciscoconfig->set_config_row_status( 1, $rand );
    my $status = 0;
    while ( $status !~ /successful|failed/ ) {
        my $t = $ciscoconfig->config_copy_state($rand);
        $status = $t->{$rand};
        last if $status =~ /successful|failed/;
        sleep 1;
    }
    $ciscoconfig->set_config_row_status( 6, $rand );

    return 0 if $status eq 'failed';
    return 1 if $status eq 'successful';
}

1;
__END__


=head1 NAME

SNMP::Info::CiscoConfig - SNMP Interface to Cisco Configuration Files

=head1 AUTHOR

Justin Hunter

=head1 SYNOPSIS

    my $ciscoconfig = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 

    or die "Can't connect to DestHost.\n";

    my $class = $ciscoconfig->class();
    print " Using device sub class : $class\n";

=head1 DESCRIPTION

SNMP::Info::CiscoConfig is a subclass of SNMP::Info that provides an interface
to C<CISCO-CONFIG-COPY-MIB>, C<CISCO-FLASH-MIB>, and C<OLD-CISCO-SYS-MIB>.
These MIBs facilitate the writing of configuration files.

Use or create a subclass of SNMP::Info that inherits this one.
Do not use directly.

=head2 Inherited Classes

=over

None.

=back

=head2 Required MIBs

=over

=item CISCO-CONFIG-COPY-MIB

=item CISCO-FLASH-MIB

=item OLD-CISCO-SYS-MIB

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $ciscoconfig->old_write_mem()

(B<writeMem>)

=item $ciscoconfig->old_write_net()

(B<writeNet>)

=back

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=over

=back

=head2 Config Copy Request Table  (B<ccCopyTable>)

=over

=item $ciscoconfig->config_protocol()

(B<ccCopyProtocol>)

=item $ciscoconfig->config_source_type()

(B<ccCopySourceFileType>)

=item $ciscoconfig->config_dest_type()

(B<ccCopyDestFileType>)

=item $ciscoconfig->config_server_addr()

(B<ccCopyServerAddress>)

=item $ciscoconfig->config_filename()

(B<ccCopyFileName>)

=item $ciscoconfig->config_username()

(B<ccCopyUserName>)

=item $ciscoconfig->config_password()

(B<ccCopyUserPassword>)

=item $ciscoconfig->config_notify_complete()

(B<ccCopyNotificationOnCompletion>)

=item $ciscoconfig->config_copy_state()

(B<ccCopyState>)

=item $ciscoconfig->config_copy_start_time()

(B<ccCopyTimeStarted>)

=item $ciscoconfig->config_copy_complete_time()

(B<ccCopyTimeCompleted>)

=item $ciscoconfig->config_fail_cause()

(B<ccCopyFailCause>)

=item $ciscoconfig->config_row_status()

(B<ccCopyEntryRowStatus>)

=back

=head2 Flash Copy Table (B<ciscoFlashCopyTable>)

Table of Flash copy operation entries.

=over

=item $ciscoconfig->flash_copy_cmd()

(B<ciscoFlashCopyCommand>)

=item $ciscoconfig->flash_copy_protocol()

(B<ciscoFlashCopyProtocol>)

=item $ciscoconfig->flash_copy_address()

(B<ciscoFlashCopyServerAddress>)

=item $ciscoconfig->flash_copy_source()

(B<ciscoFlashCopySourceName>)

=item $ciscoconfig->flash_copy_dest()

(B<ciscoFlashCopyDestinationName>)

=item $ciscoconfig->flash_copy_row_status()

(B<ciscoFlashCopyEntryStatus>)

=back

=head1 SET METHODS

These are methods that provide SNMP set functionality for overridden methods or
provide a simpler interface to complex set operations.  See
L<SNMP::Info/"SETTING DATA VIA SNMP"> for general information on set operations. 

=over

=item $ciscoconfig->copy_run_tftp (tftpserver, tftpfilename )

Store the running configuration on a TFTP server.  Equivalent to the CLI
command "copy running-config tftp".

This method currently only supports Cisco devices with the
CISCO-CONFIG-COPY-MIB available with Cisco IOS software release 12.0, or on
some devices as early as release 11.2P.

 Example:
 $ciscoconfig->copy_run_tftp('1.2.3.4', 'myconfig') 
    or die Couldn't save config. ",$ciscoconfig->error(1);

=item $ciscoconfig->copy_run_start()

Copy the running configuration to the startup configuration.  Equivalent to
the CLI command "copy running-config startup-config".

This method currently only supports Cisco devices with the
CISCO-CONFIG-COPY-MIB available with Cisco IOS software release 12.0, or on
some devices as early as release 11.2P.

 Example:
 $ciscoconfig->copy_run_start()
    or die "Couldn't save config. ",$ciscoconfig->error(1);

=cut
