# SNMP::Info::Layer2::Orinoco
# Eric Miller
# $Id$
#
# Copyright (c) 2004-6 Eric Miller
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

package SNMP::Info::Layer2::Orinoco;
$VERSION = '1.03';
use strict;

use Exporter;
use SNMP::Info;
use SNMP::Info::Bridge;

@SNMP::Info::Layer2::Orinoco::ISA = qw/SNMP::Info SNMP::Info::Bridge Exporter/;
@SNMP::Info::Layer2::Orinoco::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD $INIT $DEBUG/;

%MIBS    = (
            %SNMP::Info::MIBS,
            %SNMP::Info::Bridge::MIBS,
           );

%GLOBALS = (
            %SNMP::Info::GLOBALS,
            %SNMP::Info::Bridge::GLOBALS,
           );

%FUNCS   = (
            %SNMP::Info::FUNCS,
            %SNMP::Info::Bridge::FUNCS,
             );

%MUNGE   = (
            %SNMP::Info::MUNGE,
            %SNMP::Info::Bridge::MUNGE,
            );

sub os {
    return 'orinoco';
}

sub os_ver {
    my $orinoco = shift;
    my $descr = $orinoco->description();
    return undef unless defined $descr;

    if ($descr =~ m/V(\d+\.\d+)/){
        return $1;
    }
    if ($descr =~ m/v(\d+\.\d+\.\d+)/){
        return $1;
    }

    return undef;
}

sub os_bin {
    my $orinoco = shift;
    my $descr = $orinoco->description();
    return undef unless defined $descr;

    if ($descr =~ m/V(\d+\.\d+)$/){
        return $1;
    }
    if ($descr =~ m/v(\d+\.\d+\.\d+)$/){
        return $1;
    }

    return undef;
}

sub vendor {
    return 'proxim';
}

sub model {
    my $orinoco = shift;
    my $descr = $orinoco->description();
    return undef unless defined $descr;

    return $1 if ($descr =~ /(AP-\d+)/);
    return 'WavePOINT-II' if ($descr =~ /WavePOINT-II/);
    return undef;
}

sub serial {
    my $orinoco = shift;
    my $descr = $orinoco->description();
    return undef unless defined $descr;

    $descr  = $1 if $descr =~ /SN-(\S+)/;
    return $descr;
}

sub i_ignore {
    my $orinoco = shift;
    my $descr = $orinoco->i_description();

    my %i_ignore;
    foreach my $if (keys %$descr){
        my $type = $descr->{$if};
	  # Skip virtual interfaces  
        $i_ignore{$if}++ if $type =~ /(lo|empty|PCMCIA)/i;
    }
    return \%i_ignore;
}

sub interfaces {
    my $orinoco = shift;
    my $interfaces = $orinoco->i_index();
    my $descriptions = $orinoco->i_description();

    my %interfaces = ();
    foreach my $iid (keys %$interfaces){
        my $desc = $descriptions->{$iid};
        next unless defined $desc;
        next if $desc =~ /(lo|empty|PCMCIA)/i;

	$desc  = 'AMD' if $desc =~ /AMD/;

        $interfaces{$iid} = $desc;
    }
    return \%interfaces;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::Orinoco - SNMP Interface to Orinoco Series Access Points

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $orinoco = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $orinoco->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a Orinoco
Access Point through SNMP. 

For speed or debugging purposes you can call the subclass directly, but not after
determining a more specific class using the method above. 

 my $orinoco = new SNMP::Info::Layer2::Orinoco(...);

=head2 Inherited Classes

=over

=item SNMP::Info

=item SNMP::Info::Bridge

=back

=head2 Required MIBs

=over

=item Inherited classes

See SNMP::Info for its own MIB requirements.

See SNMP::Info::Bridge for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $orinoco->vendor()

Returns 'Proxim' :)

=item $orinoco->model()

Returns the model extracted from B<sysDescr>.

=item $orinoco->os()

Returns 'Orinoco'

=item $orinoco->os_ver()

Returns the software version extracted from B<sysDescr>.

=item $orinoco->os_bin()

Returns the firmware version extracted from B<sysDescr>.

=item $orinoco->serial()

Returns the serial number extracted from B<sysDescr>.

=back

=head2 Globals imported from SNMP::Info

See documentation in SNMP::Info for details.

=head2 Globals imported from SNMP::Info::Bridge

See documentation in SNMP::Info::Bridge for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $orinoco->interfaces()

Returns reference to map of IIDs to physical ports. 

=item $orinoco->i_ignore()

Returns reference to hash of IIDs to ignore.

=back

=head2 Table Methods imported from SNMP::Info

See documentation in SNMP::Info for details.

=head2 Table Methods imported from SNMP::Info::Bridge

See documentation in SNMP::Info::Bridge for details.

=cut
