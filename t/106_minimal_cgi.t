# -*- mode:perl -*-
use strict;
use Test::More tests => 7;
use HTTP::Request;

BEGIN {
    use_ok 'Acore::WAF';
    use_ok 'HTTP::Engine::MinimalCGI';
    use_ok 'Acore::WAF::MinimalCGI';
    use_ok 't::WAFTest';
    $ENV{GATEWAY_INTERFACE} = "CGI/1.1";
    $ENV{REQUEST_METHOD}    = "GET";
    $ENV{SCRIPT_NAME}       = "/index.cgi";
    $ENV{QUERY_STRING}      = "input=%E3%81%82&input=%E3%81%84&input=%E3%81%86";
    $ENV{PATH_INFO}         = "/act/say_multi";
    $ENV{HTTP_HOST}         = "localhost";
};

{
    my $req = HTTP::Request->new(
        GET => sprintf(
            "http://%s%s%s?%s",
            $ENV{HTTP_HOST},
            $ENV{SCRIPT_NAME},
            $ENV{PATH_INFO},
            $ENV{QUERY_STRING},
        ),
    );
    $req->protocol('HTTP/1.0');

    my $engine = HTTP::Engine->new(
        interface => {
            module => 'MinimalCGI',
            request_handler => sub {
                my $app = t::WAFTest->new;
                $app->handle_request({}, @_);
            },
        },
    );
    use IO::Scalar;
    my $data;
    my $fh = IO::Scalar->new(\$data);
    select $fh;
    $engine->run($req);
    $fh->close;
    like $data => qr{Status: 200};
    like $data => qr{Content-Type: text/html; charset=utf-8};
    like $data => qr{入力はあいうです。};
}

