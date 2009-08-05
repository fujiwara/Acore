use inc::Module::Install;
name 'Acore';
all_from 'lib/Acore.pm';

build_requires 'Module::Install' => 0.77;
requires 'Any::Moose';
requires 'CGI::ExceptionManager' => 0.05;
requires 'Crypt::SaltedHash';
requires 'DBI';
requires 'DBIx::CouchLike' => 0.08;
requires 'FormValidator::Lite';
requires 'Getopt::Long';
requires 'HTTP::Date';
requires 'HTTP::Engine' => 0.001008;
requires 'HTTP::Session';
requires 'HTTPx::Dispatcher';
requires 'MIME::Base64';
requires 'Path::Class';
requires 'Text::MicroTemplate';
requires 'Want';
requires 'Sub::Pipe';
requires 'Data::Path';
requires 'HTML::FillInForm';
requires 'Text::SimpleTable';
requires 'Data::Visitor';
requires 'String::CamelCase';

test_requires 'DBD::SQLite';
test_requires 'Test::Base';
test_requires 'Text::Diff';
test_requires 'Math::BigInt';
test_requires 'Clone';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
install_script 'acore_setupdb.pl';
install_script 'acore_setupwaf.pl';

WriteAll;
