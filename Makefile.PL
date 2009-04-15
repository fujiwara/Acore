use inc::Module::Install;
name 'Acore';
all_from 'lib/Acore.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
