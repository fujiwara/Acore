use inc::Module::Install;
use Module::Install::TestTarget;

name 'Acore';
all_from 'lib/Acore.pm';
build_requires 'Module::Install' => 0.77;
requires 'Any::Moose';
requires 'Crypt::SaltedHash';
requires 'Class::Inspector';
requires 'DBI';
requires 'DBIx::CouchLike' => 0.09;
requires 'DBD::SQLite';
requires 'DateTime';
requires 'Devel::StackTrace';
requires 'Devel::StackTrace::AsHTML';
requires 'Encode' => 2.13;
requires 'FormValidator::Lite';
requires 'Getopt::Long';
requires 'HTTP::Date';
requires 'HTTP::Session';
requires 'HTTPx::Dispatcher';
requires 'MIME::Base64';
requires 'Path::Class';
requires 'Plack::Builder';
requires 'Plack::Middleware::Static';
requires 'Text::MicroTemplate' => 0.07;
requires 'Sub::Pipe';
requires 'HTML::FillInForm::Lite';
requires 'Text::SimpleTable';
requires 'String::CamelCase';
requires 'HTTP::MobileAgent' => 0.27;
requires 'Encode::JP::Mobile' => 0.26;
requires 'YAML';
requires 'Try::Tiny';
requires 'Digest::SHA::PurePerl';
requires 'HTML::StickyQuery';

test_requires 'Test::Base';
test_requires 'Text::Diff';
test_requires 'Math::BigInt';
test_requires 'Test::Output';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More' => 0.87_1;
use_test_base;
auto_include;
install_script 'acore_setupdb.pl';
install_script 'acore_setupwaf.pl';
install_script 'acoresh';

test_target moose => (
    env => { ANY_MOOSE => "Moose" },
);

test_target debug => (
    env   => { DEBUG => 1 },
);

WriteAll;
