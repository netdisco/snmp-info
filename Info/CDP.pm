# SNMP::Info::CDP
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

package SNMP::Info::CDP;
$VERSION = 0.1;

use strict;

use Exporter;
use SNMP::Info;
use Carp;

@SNMP::Info::CDP::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::CDP::EXPORT_OK = qw//;

use vars qw/$VERSION $DEBUG %FUNCS %GLOBALS %MIBS %MIBS_V1 %MUNGE $INIT/;
# Debug
$DEBUG=0;
$SNMP::debugging=$DEBUG;

# Five data structures required by SNMP::Info
$INIT = 0;
%MIBS    = ( 'CISCO-CDP-MIB' => 'cdpGlobalRun' );
%MIBS_V1 = ( 'CISCO-CDP-MIB-V1SMI' => 'cdpGlobalRun' );
# Notice we dont inherit the default GLOBALS and FUNCS
# only the default MUNGE.
%GLOBALS = (
            'cdp_run'      => 'cdpGlobalRun',
            'cdp_interval' => 'cdpGlobalMessageInterval',
            'cdp_holdtime' => 'cdpGlobalHoldTime',
            'cdp_id'       => 'cdpGlobalDeviceId',
           );

%FUNCS  = (
            'c_if'           => 'cdpCacheIfIndex',
            'c_proto'        => 'cdpCacheAddressType',
            'c_ip'           => 'cdpCacheAddress',
            'c_ver'          => 'cdpCacheVersion',
            'c_id'           => 'cdpCacheDeviceId',
            'c_port'         => 'cdpCacheDevicePort',
            'c_platform'     => 'cdpCachePlatform',
            'c_capabilities' => 'cdpCacheCapabilities',
            'c_domain'       => 'cdpCacheVTPMgmtDomain',
            'c_vlan'         => 'cdpCacheNativeVLAN',
            'c_duplex'       => 'cdpCacheDuplex'
          );

%MUNGE = (
          'c_capabilities' => \&SNMP::Info::munge_octet2hex,
          'c_ip'           => \&SNMP::Info::munge_ip
         );


sub hasCDP {
    my $cdp = shift;

    my $ver = $cdp->{_version};


    # SNMP v1 clients dont have the globals
    if (defined $ver and $ver == 1){
        my $c_ip = $cdp->c_ip();
        # See if anything in cdp cache, if so we have cdp
        return 1 if (defined $c_ip and scalar(keys %$c_ip)) ;
        return undef;
    }
    
    return $cdp->cdp_run();
}
1;
__END__

=head1 NAME

SNMP::Info::CDP - Perl5 Interface to Cisco Discovery Protocol (CDP) using SNMP

=head1 DESCRIPTION

CDP provides Layer 2 discovery of attached devices that also
speak CDP, including switches, routers and hubs.

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 my $cdp = new SNMP::Info::CDP( DestHost  => 'router' , 
                          Community => 'public' );
 $hascdp = $cdp->hasCDP() ? 'yes' : 'no';
 @neighbor_ips = values( %{$cdp->ip()} );

=head1 CREATING AN OBJECT

=over

=item new SNMP::Info::CDP()

Arguments passed to new() are passed on to SNMP::Session::new()
    

    my $cdp = new SNMP::Info::CDP(
        DestHost => $host,
        Community => 'public'
        ) 
    die "Couldn't connect.\n" unless defined $cdp;

=item  $cdp->session()

Sets or returns the SNMP::Session object

    # Get
    my $sess = $cdp->session();

    # Set
    my $newsession = new SNMP::Session(...);
    $cdp->session($newsession);

=back

=head2 Your Device May Vary

Each device implements a subset of the global and cache entries. 
Check the return value to see if that data is held by the device.

=head1 CDP GLOBAL VALUES

=over

=item  $cdp->hasCDP()

Is CDP is active in this device?  

Accounts for SNMP version 1 devices which may have CDP but not cdp_run()

=item $cdp->cdp_run()

Is CDP enabled on this device?

(B<cdpGlobalRun>)

=item $cdp->cdp_interval()

Interval in seconds at which CDP messages are generated.

(B<cdpGlobalMessageInterval>)

=item $cdp->cdp_holdtime()

Time in seconds that CDP messages are kept. 

(B<cdpGlobalHoldTime>)

=item  $cdp->cdp_id() 

Returns CDP device ID.  

This is the device id broadcast via CDP to other devices, and is what is retrieved from remote devices with $cdp->id().

(B<cdpGlobalDeviceId>)

=back

=head1 CDP CACHE ENTRIES

=over

=item  $cdp->c_proto()

Returns remote address type received.  Usually IP.

(B<cdpCacheAddressType>)

=item  $cdp->c_ip()

Returns remote IP address

(B<cdpCacheAddress>)

=item $cdp->c_ver() 

Returns remote hardware version

(B<cdpCacheVersion>)

=item $cdp->c_id()

Returns remote device id string

(B<cdpCacheDeviceId>)

=item $cdp->c_port()

Returns remote port ID

(B<cdpDevicePort>)

=item $cdp->c_platform() 

Returns remote platform id 

(B<cdpCachePlatform>)

=item $cdp->c_capabilities()

Returns Device Functional Capabilities bitmap.  

Anyone know where I can get info on how to decode this?

(B<cdpCacheCapabilities>)

=item $cdp->c_domain()

Returns remote VTP Management Domain as defined in CISCO-VTP-MIB::managementDomainName

(B<cdpCacheVTPMgmtDomain>)

=item $cdp->c_vlan()

Returns the remote interface native VLAN.

(B<cdpCacheNativeVLAN>)

=item $cdp->c_duplex() 

Returns the port duplex status from remote devices.

(B<cdpCacheDuplex>)

=back

=cut
