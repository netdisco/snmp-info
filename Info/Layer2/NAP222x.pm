# SNMP::Info::Layer2::NAP222x
# Eric Miller <eric@jeneric.org>
# $Id$
#
# Copyright (c) 2004 Eric Miller
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

package SNMP::Info::Layer2::NAP222x;
$VERSION = 1.0;
use strict;

use Exporter;
use SNMP::Info;
use SNMP::Info::Bridge;
use SNMP::Info::SONMP;

@SNMP::Info::Layer2::NAP222x::ISA = qw/SNMP::Info SNMP::Info::Bridge SNMP::Info::SONMP Exporter/;
@SNMP::Info::Layer2::NAP222x::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD $INIT $DEBUG/;

%MIBS    = (
            %SNMP::Info::MIBS,
            %SNMP::Info::Bridge::MIBS,
            %SNMP::Info::SONMP::MIBS,
            'NORTEL-WLAN-AP-MIB' => 'ntWlanSwHardwareVer',
           );

%GLOBALS = (
            %SNMP::Info::GLOBALS,
            %SNMP::Info::Bridge::GLOBALS,
            %SNMP::Info::SONMP::GLOBALS,
            'nt_hw_ver'     => 'ntWlanSwHardwareVer',
            'nt_fw_ver'     => 'ntWlanSwBootRomVer',
            'nt_sw_ver'     => 'ntWlanSwOpCodeVer',
            'nt_cc'         => 'ntWlanSwCountryCode',
            'tftp_action'   => 'ntWlanTransferStart',
            'tftp_host'     => 'ntWlanFileServer',
            'tftp_file'     => 'ntWlanDestFile',
            'tftp_type'     => 'ntWlanFileType',
            'tftp_result'   => 'ntWlanFileTransferStatus',
            'tftp_xtype'    => 'ntWlanTransferType',
            'tftp_src_file' => 'ntWlanSrcFile',
            'ftp_user'      => 'ntWlanUserName',
            'ftp_pass'      => 'ntWlanPassword',
           );

%FUNCS   = (
            %SNMP::Info::FUNCS,
            %SNMP::Info::Bridge::FUNCS,
            %SNMP::Info::SONMP::FUNCS,
            'i_name2'             => 'ifName',
            'bp_index_2'  => 'dot1dTpFdbPort',
            # From ntWlanPortTable
            'nt_prt_name'   => 'ntWlanPortName',
            'nt_dpx_admin'  => 'ntWlanPortCapabilities',
            'nt_auto'       => 'ntWlanPortAutonegotiation',
            'nt_dpx'        => 'ntWlanPortSpeedDpxStatus',
            );

%MUNGE   = (
            %SNMP::Info::MUNGE,
            %SNMP::Info::Bridge::MUNGE,
            %SNMP::Info::SONMP::MUNGE,
            );

sub os {
    return 'nortel';
}

sub os_ver {
    my $nap222x = shift;
    my $ver = $nap222x->nt_sw_ver();
    return undef unless defined $ver;
    
    if ($ver =~ m/(\d+\.\d+\.\d+\.\d+)/){
        return $1;
        }
    return undef;
}

sub os_bin {
    my $nap222x = shift;
    my $bin = $nap222x->nt_fw_ver();
    return undef unless defined $bin;

    if ($bin =~ m/(\d+\.\d+\.\d+)/){
        return $1;
        }
    return undef;
}

sub vendor {
    return 'nortel';
}

sub model {
    my $nap222x = shift;
    my $descr = $nap222x->description();
    return undef unless defined $descr;

    return 'AP-2220' if ($descr =~ /2220/);
    return 'AP-2221' if ($descr =~ /2221/);
    return 'AP-2225' if ($descr =~ /2225/);
    return undef;
}

sub mac {
    my $nap222x = shift;
    my $i_mac = $nap222x->i_mac();

# Return Interface MAC   
    foreach my $entry (keys %$i_mac){
        my $sn = $i_mac->{$entry};
        next unless $sn;
        return $sn;
    }
    return undef;
}

sub serial {
    my $nap222x = shift;
    my $i_mac = $nap222x->i_mac();

# Return Interface MAC   
    foreach my $entry (keys %$i_mac){
        my $sn = $i_mac->{$entry};
        next unless $sn;
        return $sn;
    }
    return undef;
}

sub i_ignore {
    my $nap222x = shift;
    my $descr = $nap222x->i_description();

    my %i_ignore;
    foreach my $if (keys %$descr){
        my $type = $descr->{$if};
      # Skip virtual interfaces  
        $i_ignore{$if}++ if $type =~ /(loopback|lo|other)/i;
    }
    return \%i_ignore;
}

sub interfaces {
    my $nap222x = shift;
    my $interfaces = $nap222x->i_index();
    my $description = $nap222x->i_description();

    my %interfaces = ();
    foreach my $iid (keys %$interfaces){
        my $desc = $description->{$iid};
        next unless defined $desc;
        next if $desc =~ /lo/i;

        $interfaces{$iid} = $desc;
    }
    return \%interfaces;
}

sub i_duplex {
    my $nap222x = shift;
    
    my $mode = $nap222x->nt_dpx();
    my $port_name = $nap222x->nt_prt_name();
    my $interfaces = $nap222x->interfaces();
    
    my %i_duplex;
    foreach my $if (keys %$interfaces){
        my $port = $interfaces->{$if};
        next unless $port =~ /dp/i;
        foreach my $idx (keys %$mode) {
            my $name = $port_name->{$idx}||'unknown';
            next unless $name eq $port;
            my $duplex = $mode->{$idx};
            
            $duplex = 'other' unless defined $duplex;
            $duplex = 'half' if $duplex =~ /half/i;
            $duplex = 'full' if $duplex =~ /full/i;
    
            $i_duplex{$if}=$duplex;
        }
    }
    return \%i_duplex;
}

sub i_duplex_admin {
    my $nap222x = shift;
    
    my $dpx_admin = $nap222x->nt_dpx_admin();
    my $nt_auto = $nap222x->nt_auto();
    my $interfaces = $nap222x->interfaces();
    my $port_name = $nap222x->nt_prt_name();
 
    my %i_duplex_admin;
    foreach my $if (keys %$interfaces){
        my $port = $interfaces->{$if};
        next unless $port =~ /dp/i;
        foreach my $idx (keys %$dpx_admin) {
            my $name = $port_name->{$idx}||'unknown';
            next unless $name eq $port;
            my $duplex = $dpx_admin->{$idx};
            my $auto = $nt_auto->{$idx};
    
            $duplex = 'other' unless defined $duplex;
            $duplex = 'half' if ($duplex =~ /half/i and $auto =~ /disabled/i);
            $duplex = 'full' if ($duplex =~ /full/i and $auto =~ /disabled/i);
            $duplex = 'auto' if $auto =~ /enabled/i;
    
            $i_duplex_admin{$if}=$duplex;
        }
    }
    return \%i_duplex_admin;
}

sub i_name {
    my $nap222x = shift;
    my $interfaces = $nap222x->interfaces();

    my %i_name;
    foreach my $if (keys %$interfaces){
        my $desc = $interfaces->{$if};
    next unless defined $desc;
        
        my $name = 'unknown';
        $name = 'Ethernet Interface' if $desc =~ /dp/i;
        $name = 'Wireless Interface B' if $desc =~ /ndc/i;
        $name = 'Wireless Interface A' if $desc =~ /ar/i;
        
        $i_name{$if} = $name;
    }
    return \%i_name;
}

# dot1dBasePortTable does not exist and dot1dTpFdbPort does not map to ifIndex
sub bp_index {
    my $nap222x = shift;
    my $interfaces = $nap222x->interfaces();

    my %bp_index;
    foreach my $iid (keys %$interfaces){
        my $desc = $interfaces->{$iid};
        next unless defined $desc;
        next unless $desc =~ /(ndc|ar)/i;
        
        my $port = 1;
        $port = 2 if $desc =~ /ndc/i;

    $bp_index{$port} = $iid;
    }
    return \%bp_index;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::nap222x - SNMP Interface to Nortel 2220 Series Access Points

=head1 AUTHOR

Eric Miller (C<eric@jeneric.org>)

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $nap222x = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $nap222x->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a Nortel
2220 series wireless Access Points through SNMP. 

For speed or debugging purposes you can call the subclass directly, but not after determining
a more specific class using the method above. 

 my $nap222x = new SNMP::Info::Layer2::nap222x(...);

=head2 Inherited Classes

=over

=item SNMP::Info

=item SNMP::Info::Bridge

=item SNMP::Info::SONMP

=back

=head2 Required MIBs

=over

=item NORTEL-WLAN-AP-MIB

=item Inherited classes

See SNMP::Info for its own MIB requirements.

See SNMP::Info::Bridge for its own MIB requirements.

See SNMP::Info::SONMP for its own MIB requirements.

=back

MIBs can be found on the CD that came with your product.

Or, they can be downloaded directly from Nortel Networks regardless of support
contract status.

Go to http://www.nortelnetworks.com Techninal Support, Browse Technical Support,
Select by Product Families, Wireless LAN, WLAN - Access Point 2220, Software.
Filter on mibs and download the latest version's archive.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $nap222x->vendor()

Returns 'Nortel'

=item $nap222x->model()

Returns the model extracted from B<sysDescr>.

=item $nap222x->os()

Returns 'Nortel'

=item $nap222x->os_ver()

Returns the software version extracted from B<ntWlanSwOpCodeVer>.

=item $nap222x->os_bin()

Returns the firmware version extracted from B<ntWlanSwBootRomVer>.

=item $nap222x->mac()

Returns the MAC address of the first Ethernet Interface.

=item $nap222x->serial()

Returns the MAC address of the first Ethernet Interface.

=item $nap222x->nt_hw_ver()

Returns the hardware version.

B<ntWlanSwHardwareVer>

=item $nap222x->nt_cc()

Returns the country code of the AP.

B<ntWlanSwHardwareVer>

=item $nap222x->tftp_action()

B<ntWlanTransferStart>

=item $nap222x->tftp_host()

B<ntWlanFileServer>

=item $nap222x->tftp_file()

B<ntWlanDestFile>

=item $nap222x->tftp_type()

B<ntWlanFileType>

=item $nap222x->tftp_result()

B<ntWlanFileTransferStatus>

=item $nap222x->tftp_xtype()

B<ntWlanTransferType>

=item $nap222x->tftp_src_file()

B<ntWlanSrcFile>

=item $nap222x->ftp_user()

B<ntWlanUserName>

=item $nap222x->ftp_pass()

B<ntWlanPassword>

=back

=head2 Globals imported from SNMP::Info

See documentation in SNMP::Info for details.

=head2 Globals imported from SNMP::Info::Bridge

See documentation in SNMP::Info::Bridge for details.

=head2 Global Methods imported from SNMP::Info::SONMP

See documentation in SNMP::Info::SONMP for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $nap222x->interfaces()

Returns reference to map of IIDs to physical ports. 

=item $nap222x->i_ignore()

Returns reference to hash of IIDs to ignore.

=item $nap222x->i_duplex()

Returns reference to hash.  Maps port operational duplexes to IIDs.

B<ntWlanPortSpeedDpxStatus>

=item $nap222x->i_duplex_admin()

Returns reference to hash.  Maps port admin duplexes to IIDs.

B<ntWlanPortCapabilities>

=item $nap222x->i_name()

Returns a human name based upon port description.

=item $nap222x->bp_index()

Returns a mapping between ifIndex and the Bridge Table.  This does not exist in
the MIB and bridge port index is not the same as ifIndex so it is created. 

=back

=head2 Table Methods imported from SNMP::Info

See documentation in SNMP::Info for details.

=head2 Table Methods imported from SNMP::Info::Bridge

See documentation in SNMP::Info::Bridge for details.

=head2 Table Methods imported from SNMP::Info::SONMP

See documentation in SNMP::Info::SONMP for details.

=cut
