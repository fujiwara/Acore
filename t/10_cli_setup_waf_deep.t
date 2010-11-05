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
qx{ rm -rf For_Test };
Acore::CLI::SetupWAF->run("For::Test");

ok -d "For_Test/$_", "$_ is dir"
    for qw( static templates db script lib config t xt
            lib lib/For/Test lib/For/Test/Controller );

ok -f "For_Test/$_", "$_ is file"
    for qw( For_Test.psgi
            Makefile.PL
            lib/For/Test.pm lib/For/Test/Controller/Root.pm
            config/For_Test.pl
            config/For_Test_development.pl
            static/favicon.ico static/anycms-logo.png
            t/00_compile.t );

{
    chdir "For_Test" or die $!;

    local $0 = "For_Test.psgi"; # fake for FindBin
    my $app  = do "For_Test.psgi";

    test_psgi
        app    => $app,
        client => sub {
            my $cb = shift;

            my $res = $cb->(GET "http://localhost/");
            is   $res->code    => 200, "status ok";
            like $res->content => qr{<title>.*?For::Test.*</title>}, "title ok";

            $res = $cb->(GET "http://localhost/static/anycms-logo.png");
            is $res->content => file("static/anycms-logo.png")->slurp,
                "static content body";
            is $res->content_type => "image/png",
                "static content type";
        };
}

done_testing;
