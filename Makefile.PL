use inc::Module::Install;
name 'Acore';
all_from 'lib/Acore.pm';

if (-e ".svn" && -d _) {
    # set dist version from svn revision.
    my $rev = (qx{LANG=C svn info} =~ /Revision:\s*(\d+)/ && $1);
    version sprintf "0.%05d", $rev;
    warn "set version from svn revision $rev\n";
}
elsif (-e ".git" && -d _) {
    my $rev = (qx{git log -1} =~ /commit (\w{8})/ && $1);
    version $rev;
    warn "set version from git commit $rev\n";
}

build_requires 'Module::Install' => 0.77;
requires 'Any::Moose';
requires 'Crypt::SaltedHash';
requires 'Class::Inspector';
requires 'DBI';
requires 'DBIx::CouchLike' => 0.09;
requires 'DBD::SQLite';
requires 'Devel::StackTrace';
requires 'Devel::StackTrace::AsHTML';
requires 'Encode' => 2.13;
requires 'FormValidator::Lite';
requires 'Getopt::Long';
requires 'HTTP::Date';
requires 'HTTP::Engine' => 0.001008;
requires 'HTTP::Session';
requires 'HTTPx::Dispatcher';
requires 'HTML::StickyQuery';
requires 'MIME::Base64';
requires 'Path::Class';
requires 'Text::MicroTemplate' => 0.07;
requires 'Sub::Pipe';
requires 'HTML::FillInForm';
requires 'Text::SimpleTable';
requires 'Data::Visitor::Encode';
requires 'String::CamelCase';
requires 'HTTP::MobileAgent' => 0.27;
requires 'Encode::JP::Mobile' => 0.26;
requires 'YAML::Tiny';
requires 'Try::Tiny';
requires 'Digest::SHA';

test_requires 'Test::Base';
test_requires 'Text::Diff';
test_requires 'Math::BigInt';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More' => 0.87_1;
use_test_base;
auto_include;
install_script 'acore_setupdb.pl';
install_script 'acore_setupwaf.pl';
install_script 'acoresh';

if (author_context) {
    for my $pair ([ TEST_PSGI => 1 ], [ ANY_MOOSE => "Moose" ], [ DEBUG => 1 ]) {
        my $env   = $pair->[0];
        my $value = $pair->[1];

        my $test = qq{$env=$value }
                 . q{$(FULLPERLRUN) -MExtUtils::Command::MM -e}
                 . q{"test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')"}
                 . q{ $(TEST_FILES)} . "\n";

        my $name = lc "${env}_${value}";
        postamble qq{test_dynamic :: test_${name}\n\n}
                . qq{test_${name} :: pure_all\n}
                . qq{\t} . $test;
    }
}

WriteAll;
