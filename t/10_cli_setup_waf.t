# -*- mode:perl -*-
use strict;
use warnings;
use Test::More;
use Cwd;
use Path::Class qw/ file /;
use HTTP::Request::Common;

BEGIN {
    use_ok ("Acore::CLI::SetupWAF");
    use_ok ("Plack::Test");
};

chdir "t/tmp" or die "Can't chdir t/tmp";
qx{ rm -rf ForTest };
Acore::CLI::SetupWAF->run("ForTest");

ok -d "ForTest/$_", "$_ is dir"
    for qw( static templates db script lib config t xt
            lib lib/ForTest lib/ForTest/Controller );

ok -f "ForTest/$_", "$_ is file"
    for qw( ForTest.psgi
            Makefile.PL
            lib/ForTest.pm
            lib/ForTest/Controller/Root.pm
            lib/ForTest/Dispatcher.pm
            config/ForTest.pl
            config/ForTest_development.pl
            static/favicon.ico static/anycms-logo.png
            t/00_compile.t );

{
    chdir "ForTest" or die $!;

    local $0 = "ForTest.psgi"; # fake for FindBin
    my $app  = do "ForTest.psgi";

    test_psgi
        app    => $app,
        client => sub {
            my $cb = shift;

            my $res = $cb->(GET "http://localhost/");
            is   $res->code    => 200, "status ok";
            like $res->content => qr{<title>.*?ForTest.*</title>}, "title ok";

            $res = $cb->(GET "http://localhost/static/anycms-logo.png");
            is $res->content => file("static/anycms-logo.png")->slurp,
                "static content body";
            is $res->content_type => "image/png",
                "static content type";
        };
}

done_testing;
