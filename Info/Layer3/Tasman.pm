# SNMP::Info::Layer3::Tasman
#
# Copyright (c) 2012 Eric Miller
# All Rights Reserved
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

package SNMP::Info::Layer3::Tasman;

use strict;
use Exporter;

use SNMP::Info::Layer3;
use SNMP::Info::MAU;

@SNMP::Info::Layer3::Tasman::ISA = qw/SNMP::Info::MAU
    SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer3::Tasman::EXPORT_OK = qw//;

use vars qw/$VERSION %GLOBALS %MIBS %FUNCS %MUNGE/;

$VERSION = '2.10';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::MAU::MIBS,
    'NT-ENTERPRISE-DATA-MIB' => 'ntEnterpriseRouters',
    'SYSTEM-MIB'             => 'nnsysVersion',
    'CHASSIS-MIB'            => 'nnchassisModel',
    'ENVIRONMENT-MIB'        => 'nnenvPwrsupStatus',
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,
    %SNMP::Info::MAU::GLOBALS,
    'ps1_type'   => 'nnenvPwrsupType.1',
    'ps1_status' => 'nnenvPwrsupStatus.1',
    'ps2_type'   => 'nnenvPwrsupType.2',
    'ps2_status' => 'nnenvPwrsupStatus.2',
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::MAU::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::MAU::MUNGE,
);

# use MAU-MIB for admin. duplex and admin. speed
*SNMP::Info::Layer3::Tasman::i_duplex_admin
    = \&SNMP::Info::MAU::mau_i_duplex_admin;
*SNMP::Info::Layer3::Tasman::i_speed_admin
    = \&SNMP::Info::MAU::mau_i_speed_admin;

sub vendor {
    return 'avaya';
}

sub os {
    return 'tasman';
}

sub os_ver {
    my $tasman  = shift;
    my $version = $tasman->nnsysVersion() || "";
    my $descr   = $tasman->description()  || "";

    # Newer versions
    return $1 if ( $version =~ /^SW:\s+(.+?)\s+/ );
    # Older versions
    return $1 if ( $descr =~ /Software Version\s+=\s+[r]*(.+),/);
    # Can't find
    return;
}

sub model {
    my $tasman = shift;

    my $id        = $tasman->id();
    my $ch_model = $tasman->nnchassisModel();
    
    return $ch_model if $ch_model;

    my $model = &SNMP::translateObj($id);
    return $id unless defined $model;

    $model =~ s/^ntSecureRouter/SR/;
    return $model;
}

sub serial {
    my $tasman = shift;

    # Newer versions of the software redefined the MIB in a non-backwards
    # compatible manner.  Try the old OID first.
    my $serial = $tasman->nnchassisOperStatus();
    # Newer versions populate status, serial should contain some numbers
    return $serial if ($serial !~ /^\D+$/);

    # Unfortunately newer versions don't seem to populate the newer OID.
    return $tasman->nnchassisSerialNumber();
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::Tasman - SNMP Interface to Avaya Secure Routers

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $tasman = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $tasman->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Avaya Secure Routers

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

=item SNMP::Info::MAU

=back

=head2 Required MIBs

=over

=item F<NT-ENTERPRISE-DATA-MIB>

=item F<SYSTEM-MIB>

=item F<CHASSIS-MIB>

=item F<ENVIRONMENT-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::MAU/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar values from SNMP

=over

=item $tasman->vendor()

Returns 'avaya'

=item $tasman->model()

Tries to get the model from C<nnchassisModel> and if not available 
cross references $tasman->id() to F<NT-ENTERPRISE-DATA-MIB>.

Substitutes 'SR' for 'ntSecureRouter' in the name for readability.

=item $tasman->os()

Returns 'tasman'

=item $tasman->os_ver()

Grabs the os version from C<nnsysVersion>

=item $tasman->ps1_type()

(C<nnenvPwrsupType.1>)

=item $tasman->ps1_status()

(C<nnenvPwrsupStatus.1>)

=item $tasman->ps2_type()

(C<nnenvPwrsupType.2>)

=item $tasman->ps2_status()

(C<nnenvPwrsupStatus.2>)

=item $tasman->serial()

Tries both (C<nnchassisOperStatus>) and (C<nnchassisSerialNumber>) as OID's
were redefined between versions.

=back

=head2 Global Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over 4

=item $stack->i_duplex_admin()

Returns reference to hash of iid to administrative duplex setting.

First checks for fixed gigabit ports which are always full duplex. Next checks
the port administrative speed (C<portAdminSpeed>) which if set to
autonegotiate then the duplex will also autonegotiate, otherwise it uses the
reported port duplex (C<portDuplex>).

=item $stack->i_speed_admin()

Returns reference to hash of iid to administrative speed setting.

C<portAdminSpeed>

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::MAU

See documentation in L<SNMP::Info::MAU/"TABLE METHODS"> for details.

=cut
