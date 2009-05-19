# -*- mode:perl -*-
use strict;
use Test::More tests => 5;
use HTTP::Request;

BEGIN {
    use_ok 'Acore::WAF';
    use_ok 'HTTP::Engine::MinimalCGI';
    use_ok 't::WAFTest';
    use_ok 'Acore::WAF::MinimalCGI';
};

{
    my $req = HTTP::Request->new( GET => "http://localhost/" );
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
    like $data => qr/Status: 200/;
}

