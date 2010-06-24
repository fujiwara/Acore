# -*- mode:perl -*-
use strict;
use warnings;
use Test::More;
use Cwd;

BEGIN {
    use_ok ("Acore::CLI::SetupWAF");
};

chdir "t/tmp" or die "Can't chdir t/tmp";
qx{ rm -rf ForTest };
Acore::CLI::SetupWAF->run("ForTest");

ok -d "ForTest/$_", "$_ is dir"
    for qw( static templates db script lib config t xt
            lib lib/ForTest lib/ForTest/Controller );

ok -f "ForTest/$_", "$_ is file"
    for qw( script/ForTest.psgi
            Makefile.PL
            lib/ForTest.pm lib/ForTest/Controller/Root.pm
            config/ForTest.yaml
            static/favicon.ico static/anycms-logo.png
            t/00_compile.t );

done_testing;
