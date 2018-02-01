use strict;
use warnings;
use Module::Build;

Module::Build->new(
  module_name => 'SNMP::Info',
  license     => 'bsd',
  dist_author => 'Eric A. Miller <emiller@cpan.org>',
  # dynamic_config => 1,
  create_readme => 1,
  configure_requires => {
    'Module::Build' => '0.42',
  },
  # build_requires => {
  # },
  requires => {
    'SNMP' => '0',
    'Math::BigInt' => '0',
  },
  recommends => {
    'PPI' => '0',
    'Class::ISA' => '0',
    'Module::Info' => '0',
    'Module::Load' => '0',
    'File::Slurp' => '0',
  },
  test_requires => {
    'Test::More' => '0.88',
    'Test::Distribution' => '0',
  },
  # script_files => [
  # ],
  # share_dir => 'share',
  meta_merge => {
    resources => {
      homepage => 'http://netdisco.org/',
      bugtracker => 'https://github.com/netdisco/snmp-info/issues',
      repository => 'https://github.com/netdisco/snmp-info',
      MailingList => 'https://lists.sourceforge.net/lists/listinfo/snmp-info-users',
      IRC => 'irc://irc.freenode.org/#netdisco',
    },
  },
)->create_build_script;
