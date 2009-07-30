# -*- mode:perl -*-
use strict;
use Test::More tests => 11;
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
    $ENV{PATH_INFO}         = "/act/minimal_cgi";
    $ENV{HTTP_HOST}         = "localhost";
    $ENV{REMOTE_ADDR}       = "127.0.0.1";
    $ENV{HTTP_USER_AGENT}   = "Mozilla/1.0";
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
    like $data => qr{base=http://localhost/index\.cgi/};
    like $data => qr{path=/act/minimal_cgi};
    like $data => qr{address=127\.0\.0\.1};
    like $data => qr{user_agent=Mozilla/1\.0};
}

