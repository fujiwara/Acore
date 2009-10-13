use inc::Module::Install;
name 'Acore';
all_from 'lib/Acore.pm';

if (-e ".svn" && -d _) {
    # set dist version from svn revision.
    my $rev = (qx{LANG=C svn info} =~ /Revision:\s*(\d+)/ && $1);
    version sprintf "0.%05d", $rev;
    warn "set version from svn revision $rev\n";
}

build_requires 'Module::Install' => 0.77;
requires 'Any::Moose';
requires 'Crypt::SaltedHash';
requires 'Class::Inspector';
requires 'DBI';
requires 'DBIx::CouchLike' => 0.09;
requires 'Devel::StackTrace';
requires 'Devel::StackTrace::AsHTML';
requires 'Encode' => 2.13;
requires 'FormValidator::Lite';
requires 'Getopt::Long';
requires 'HTTP::Date';
requires 'HTTP::Engine' => 0.001008;
requires 'HTTP::Session';
requires 'HTTPx::Dispatcher';
requires 'MIME::Base64';
requires 'Path::Class';
requires 'Text::MicroTemplate' => 0.07;
requires 'Want';
requires 'Sub::Pipe';
requires 'Data::Path';
requires 'HTML::FillInForm';
requires 'Text::SimpleTable';
requires 'Data::Visitor';
requires 'String::CamelCase';
requires 'HTTP::MobileAgent' => 0.27;
requires 'Encode::JP::Mobile' => 0.26;

test_requires 'Test::Base';
test_requires 'Text::Diff';
test_requires 'Math::BigInt';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
install_script 'acore_setupdb.pl';
install_script 'acore_setupwaf.pl';
install_script 'acoresh';

WriteAll;
