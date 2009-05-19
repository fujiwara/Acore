use inc::Module::Install;
name 'Acore';
all_from 'lib/Acore.pm';

build_requires 'Module::Install' => 0.77;
requires 'HTTP::Engine';
requires 'HTTPx::Dispatcher';
requires 'Any::Moose';
requires 'Class::Accessor::Fast';
requires 'DBIx::CouchLike' => 0.03;
requires 'FormValidator::Lite';
requires 'HTTP::Date';
requires 'Getopt::Long';
requires 'MIME::Base64';
requires 'Path::Class';
requires 'Crypt::SaltedHash';
requires 'CGI::ExceptionManager' => 0.05;
requires 'DBI';
requires 'Clone';
test_requires 'DBD::SQLite';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
install_script 'acore_setupdb.pl';
install_script 'acore_setupwaf.pl';

WriteAll;
