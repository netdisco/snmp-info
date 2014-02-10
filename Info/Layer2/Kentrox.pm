package SNMP::Info::Layer2::Kentrox;

# Copyright (c) 2011 Netdisco Project
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

use strict;
use Exporter;
use SNMP::Info::Layer2;

@SNMP::Info::Layer2::Kentrox::ISA       = qw/SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::Kentrox::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD/;

$VERSION = '3.12';

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,
        #from DATASMART-MIB
        # MIB isn't yet in netdisco-mibs (not clear permission)
        # ... when it is, this can change to dsScWyv
        'ds_sysinfo' => '.1.3.6.1.4.1.181.2.2.12.15.0',
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
);

%MUNGE = ( %SNMP::Info::Layer2::MUNGE, );

sub os {
    return 'Kentrox';
}

sub os_ver {
    my $dsver = shift;
    my $descr = $dsver->description();
    if ( $descr =~ /^\S+\s\S+\s\S+\s(\S+)/){
        return $1;
    }
}

sub serial {
    my $dsserial = shift;
    my $serial = $dsserial->ds_sysinfo();
    if ( $serial =~ /SERIAL\s(\S+)/){
        my $str = substr($1,8,10);
        return $str;
    }

}
sub vendor {
    return 'Kentrox';
}

sub model {
    my $dsmodel = shift;
    my $descr = $dsmodel->description();
    if ( $descr =~ /^(\S+\s\S+)/){
        return $1;
    }
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::Kentrox - SNMP Interface to L2 Kentrox DataSMART DSU/CSU

=head1 AUTHOR

phishphreek@gmail.com

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $router = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 1
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $router->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Kentrox DataSMART DSU/CSU

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer2/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=head2 Overrides

=over

=item $router->vendor()

=item $router->os()

=item $router->os_ver()

=item $router->model()

=item $router->serial()

=back

=head2 Globals imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See documentation in L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=cut

