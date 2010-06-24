# -*- mode:perl -*-

use strict;
use warnings;
use Test::More;
use t::WAFTest::Engine;
use HTTP::Request;
use_ok "t::WAFTest";

my $req = HTTP::Request->new( GET => 'http://localhost/act/error' );
$req->protocol('HTTP/1.0');

my $engine = create_engine->new(
    interface => {
        module => 'Test',
        request_handler => sub {
            my $app = t::WAFTest->new;
            $app->handle_request({
                name  => "WAFTest",
                debug => 1,
            }, @_);
        },
    },
);
my $response = $engine->run($req);
is $response->code      => 500;
like $response->content => qr{Died at t/WAFTest/Controller\.pm};

done_testing;
