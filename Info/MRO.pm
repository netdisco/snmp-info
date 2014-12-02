package SNMP::Info::MRO;

use warnings;
use strict;

use vars qw/$VERSION/;
$VERSION = '3.22';
 
use PPI;
use Class::ISA;
use Module::Info;
use Module::Load ();
# use Data::Printer;

sub _walk_global_data {
    my $self = shift;
    my $class = (ref $self ? ref $self : $self);

    my $ppi = PPI::Document->new( file($class) );
    my $name    = shift or die "name (e.g. GLOBALS) required";
    my $results = shift || {};
    my $subref  = \&_walk_global_data;

    # get the hash declaration
    my $declaration = $ppi->find_first(sub {
      my ($doc, $tok) = @_;
      return ($tok->isa('PPI::Token::Symbol')
              and $tok->symbol eq "\%$name");
    });

    # get the hash content
    my $content = $declaration->snext_sibling->snext_sibling;

    # get relevant tokens in the hash content
    my @tokens = $content->find(sub {
      my ($doc, $tok) = @_;
      return ($tok->isa('PPI::Token::Symbol')
              or $tok->isa('PPI::Token::Quote'));
    });

    return $results unless scalar @tokens and ref $tokens[0] eq ref [];
    @tokens = @{ $tokens[0] };

    # walk tokens and build final result
    while (my $tok = splice(@tokens, 0, 1)) {
        if ($tok->isa('PPI::Token::Quote')) {
            my $token = $tok->string;
            my $leaf = splice(@tokens, 0, 1);
            my $extract = (($leaf =~ m/^&/) ? 'symbol' : 'string');

            unshift @{ $results->{$token} },
                     [ $class => $leaf->$extract ]
              # we can sometimes see the same package twice
              unless scalar grep { $_ eq $class }
                            map  { $_->[0] }
                                 @{ $results->{$token} };
        }
        elsif ($tok->isa('PPI::Token::Symbol')) {
            # recurse to get the results of the mentioned package
            (my $otherpkg = $tok->symbol) =~ s/^\%(.+)::$name$/$1/;
            $results = $subref->($otherpkg, $name, $results);
        }
    }

    return $results;
}

sub _print_global_data {
    my $results = _walk_global_data(@_);
    
    foreach my $key (sort keys %$results) {
        print $key, "\n";
        my @defs = @{ $results->{$key} };

        my $first = 0;
        while (my $classdef = splice(@defs, 0, 1)) {
            my $class = $classdef->[0];
            my $meth  = $classdef->[1];

            if ($first) {
                printf "     %s ( %s )\n", $meth, $class;
            }
            else {
                printf " `-- %s ( %s )\n", $meth, $class;
                $first = 1;
            }
        }
    }
}

=head1 NAME

SNMP::Info::MRO - Method resolution introspection for SNMP::Info

=head1 SYNOPSIS

 use SNMP::Info::MRO;
 use Data::Printer;
 
 p SNMP::Info::MRO::all_methods('SNMP::Info::Layer3::Juniper');

=head1 DESCRIPTION

This is a set of helpers to show where a given method in SNMP::Info has been
implemented, and which implementation is being used at runtime.

The following distributions are I<required> to run this code:

=over 4

=item *

PPI

=item *

Class::ISA

=item *

Module::Info

=item *

Module::Load

=back

=head1 FUNCTIONS

None of the functions are exported. For all helper functions, you can pass
either the name of a Perl module, or an object instance of SNMP::Info.

=over 4

=item all_methods( $module )

Returns the location of methods defined in C<$module> and all its ancestor
classes (superclasses), either as Perl subroutines or via C<%GLOBALS>
or C<%FUNCS> configuration. The data structure looks like:

 {
   method_name => {
     globals => [
       [ Package::Name        => 'mib_leaf.0' ],
       [ Other::Package::Name => '1.3.6.1.4.1.9.2.1.58.0' ],
     ],
   },
   other_method_name => [
     subs => [
       'Package::Name',
     ],
     funcs => [
       [ Package::Name => 'mib_leaf_name' ],
     ],
   ],
 }

It should be noted that the order of method resolution in SNMP::Info is to
first look for a defined subroutine (this is done by Perl), then the 
AUTOLOAD sequence will search for a definition in C<%GLOBALS> followed by
C<%FUNCS>.

The defining class or module at runtime is always the first entry in the
list, if it exists:

 $data->{method_name}->{subs}->[0]
   if exists $data->{method_name}->{subs};

=cut

sub all_methods {
    my $self = shift;
    my $class = (ref $self ? ref $self : $self);

    my $results = subroutines( $class );
    $results = { map { $_ => { subs => $results->{$_} } }
                     keys %$results };

    my $globals = globals( $class );
    foreach my $key (keys %$globals) {
        $results->{$key}->{globals} = $globals->{$key};
    }

    my $funcs = funcs( $class );
    foreach my $key (keys %$funcs) {
        $results->{$key}->{funcs} = $funcs->{$key};
    }

    #foreach my $key (keys %$results) {
    #    $results->{$key}->{subs}    ||= [];
    #    $results->{$key}->{globals} ||= [];
    #    $results->{$key}->{funcs}   ||= [];
    #}

    return $results;
}

=item subroutines( $module )

Returns the set of subroutines defined in C<$module> and all its ancestor
classes (superclasses). The data structure looks like:

 {
   method_name => [
     'Package::Name',
     'Other::Package::Name',
   ],
   other_method_name => [
     'Package::Name',
   ],
 }

Should a subroutine have been defined more than once,
the defining classes are listed in reverse order, such that the definition
used at runtime is always:

 $data->{method_name}->[0];

=cut

sub subroutines {
    my $self = shift;
    my $class = (ref $self ? ref $self : $self);
    my $results = {};

    my @super = superclasses($class);
    foreach my $parent (reverse @super) {
        my %sh = Module::Info->new_from_module( $parent )->subroutines;
        my @subs = grep { $_ !~ m/^_/ }
                   map { $_ =~ s/^.+:://; $_ }
                   keys %sh;

        foreach my $sub (@subs) {
            unshift @{ $results->{$sub} }, $parent;
        }
    }

    return $results;
}

=item globals( $module || $object )

Returns a data structure showing how L<SNMP::Info> will resolve MIB Leaf
Nodes configured through the C<%GLOBALS> hashes in C<$module>.

The data structure looks like:

 {
   method_name => [
     [ Package::Name        => 'mib_leaf_name' ],
     [ Other::Package::Name => '1.3.6.1.4.1.9.2.1.58.0' ],
   ],
   other_method_name => [
     [ Package::Name => 'mib_leaf.0' ],
   ],
 }

Where a method has been defined in different packages, then they are listed in
reverse order, such that the mapping used by SNMP::Info is always:

 $data->{method_name}->[0];

=cut

sub globals { _walk_global_data(shift, 'GLOBALS') }

=item funcs( $module || $object )

Returns a data structure showing how L<SNMP::Info> will resolve MIB Tables
configured through the C<%FUNCS> hashes in C<$module>.

See L<SNMP::Info::Layer3/"GLOBALS"> for further detail.

=cut

sub funcs { _walk_global_data(shift, 'FUNCS') }

=item munge( $module || $object )

Returns a data structure showing the subroutines used for munging returned
values for any method defined in C<%FUNCS> or C<%GLOBALS>.

The data structure looks like:

 {
   method_name => [
     [ Package::Name        => '&subroutine' ],
     [ Other::Package::Name => '&Other::Package::subroutine' ],
   ],
   other_method_name => [
     [ Package::Name => '&subroutine' ],
   ],
 }

Where a mapping has been defined in different packages, then they are listed
in reverse order, such that the munge subroutine used by SNMP::Info is always:

 $data->{method_name}->[0];

=cut

sub munge { _walk_global_data(shift, 'MUNGE') }

=item file( $module )

Returns the filename from which Perl will load the given module.

=cut

sub file {
    my $self = shift;
    my $class = (ref $self ? ref $self : $self);

    return Module::Info->new_from_module( $class )->file;
}

=item superclasses( $class || $object )

Returns the list (in order) of the names of classes Perl will search to find
methods for this SNMP::Info class or object instance.

Note this B<requires> the L<Class:ISA> distribution to be installed.

=cut

sub superclasses {
    my $self = shift;
    my $class = (ref $self ? ref $self : $self);

    Module::Load::load( $class );
    return Class::ISA::self_and_super_path( $class );
}

=item print_globals( $module || $object )

Pretty print the output of C<globals()>.

=cut

sub print_globals { _print_global_data(shift, 'GLOBALS') }

=item print_funcs( $module || $object )

Pretty print the output of C<funcs()>.

=cut

sub print_funcs { _print_global_data(shift, 'FUNCS') }

=item print_munge( $module || $object )

Pretty print the output of C<munge()>.

=cut

sub print_munge { _print_global_data(shift, 'MUNGE') }

=item print_superclasses( $class || $object )

Pretty print the output of C<superclasses()>.

=cut

sub print_superclasses {
    print join ("\n", (shift)->superclasses), "\n";
}

=back

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by The SNMP::Info Project.

 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted provided that the following conditions are met:
 #
 #    * Redistributions of source code must retain the above copyright notice,
 #      this list of conditions and the following disclaimer.
 #    * Redistributions in binary form must reproduce the above copyright
 #      notice, this list of conditions and the following disclaimer in the
 #      documentation and/or other materials provided with the distribution.
 #    * Neither the name of the University of California, Santa Cruz nor the
 #      names of its contributors may be used to endorse or promote products
 #      derived from this software without specific prior written permission.
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

=cut

1;
