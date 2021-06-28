package SNMP::Info::DocsisHE;

use strict;
use warnings;
use Exporter;

use SNMP::Info;

@SNMP::Info::DocsisHE::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::DocsisHE::EXPORT_OK = qw//;

our ($VERSION, %MIBS, %FUNCS, %GLOBALS, %MUNGE);

$VERSION = '3.73';

%MIBS = (
    'DOCS-IF3-MIB' => 'docsIf3Mib',
    'DOCS-IF-MIB'  => 'docsIfMib',
);

%GLOBALS = ();

%FUNCS  = (
    # DOCSIS 3.0 (DOCS-IF3-MIB) from CableLabs
    'docs_if3_cmts_cm_status_md_if_index'=> 'docsIf3CmtsCmRegStatusMdIfIndex',
    # DOCSIS (1.1, etc) from IETF
    'docs_if_cmts_cm_status_inet_address_type' => 'docsIfCmtsCmStatusInetAddressType',
    'docs_if_cmts_cm_status_inet_address'      => 'docsIfCmtsCmStatusInetAddress',
    'docs_cmts_cm_down_channel_if_index'       => 'docsIfCmtsCmStatusDownChannelIfIndex',
    'docs_cmts_cm_up_channel_if_index'         => 'docsIfCmtsCmStatusUpChannelIfIndex',
);

%MUNGE = ();

1;
__END__

=head1 NAME

SNMP::Info::DocsisHE - SNMP Interface for F<DOCS-IF-MIB> and F<DOCS-IF3-MIB>

=head1 AUTHOR

Ryan Gasik

=head1 SYNOPSIS

 my $cmts = new SNMP::Info(
                             AutoSpecify => 1,
                             Debug       => 1,
                             DestHost    => 'cmts',
                             Community   => 'public',
                             Version     => 2
                          );
 # Get a list of modems off the DOCSIS CMTS
 my $modems = $cmts->docs_if_cmts_cm_status_inet_address()

=head1 DESCRIPTION
SNMP::Info::DocsisHE is a subclass of SNMP::Info that provides information
about the cable modems of a DOCSIS CMTS.

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item F<DOCS-IF-MIB>
Standard IETF MIBs for DOCSIS 1.1

=item F<DOCS-IF3-MIB>
CableLabs MIBs for DOCSIS 3

=back

=head1 GLOBALS

None.

=head1 TABLE METHODS

=over

=item $info->docs_if3_cmts_cm_status_md_if_index()

Returns reference to hash of the IfIndex associated with each cable modem.

(C<docsIf3CmtsCmRegStatusMdIfIndex>)

=item $info->docs_if_cmts_cm_status_inet_address_type()

Returns reference to hash of the type of IP address (ie, IPv4, IPv6)
associated with each cable modem

(C<docsIfCmtsCmStatusInetAddressType>)

=item $info->docs_if_cmts_cm_status_inet_address()

Returns reference to hash of the IP address associated with each
cable modem.

(C<docsIfCmtsCmStatusInetAddress>)

=item $info->docs_cmts_cm_down_channel_if_index()

Returns reference to hash of the IfIndex of the down channel
(for DOCSIS 1.1) or a down channel (DOCSIS 3+) associated with each
cable modem.

(C<docsIfCmtsCmStatusDownChannelIfIndex>)

=item $info->docs_cmts_cm_up_channel_if_index()

Returns reference to hash of the IfIndex of the up channel
(for DOCSIS 1.1) or a up channel (DOCSIS 3+) associated with each
cable modem.

(C<docsIfCmtsCmStatusUpChannelIfIndex>)

=back

=cut
