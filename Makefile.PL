# SNMP::Info -  Makefile.PL
# $Id$

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'SNMP::Info',
    VERSION_FROM       => 'Info.pm',
    PL_FILES           => {},
    PREREQ_PM          => {
                            'Test::More'   => 0,
                            'Math::BigInt' => 0,
                            'SNMP'         => 0,
                            },
    ($] >= 5.005 ?    
          (ABSTRACT_FROM => 'Info.pm', 
           AUTHOR        => 'Eric A. Miller <eric@jeneric.org>',)
                 : () 
    ),
    PMLIBDIRS          => ['Info','$(BASEEXT)'],
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean              => { FILES => 'SNMP-Info-*' },
    realclean          => { FILES => 'Makefile.old' },
);

sub MY::postamble { "
.PHONY: readme
readme: README
README: Info.pm
	pod2text -l Info.pm > README" }
