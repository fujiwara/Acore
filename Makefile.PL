use inc::Module::Install;
name 'Acore';
all_from 'lib/Acore.pm';

build_requires 'Module::Install' => 0.77;
requires 'Any::Moose';
requires 'CGI::ExceptionManager' => 0.05;
requires 'Class::Accessor::Fast';
requires 'Clone';
requires 'Crypt::SaltedHash';
requires 'DBI';
requires 'DBIx::CouchLike' => 0.05;
requires 'FormValidator::Lite';
requires 'Getopt::Long';
requires 'HTTP::Date';
requires 'HTTP::Engine';
requires 'HTTP::Session';
requires 'HTTPx::Dispatcher';
requires 'MIME::Base64';
requires 'Path::Class';
requires 'Sub::Pipe';
test_requires 'DBD::SQLite';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
install_script 'acore_setupdb.pl';
install_script 'acore_setupwaf.pl';

WriteAll;
