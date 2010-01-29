# -*- mode:perl -*-

use strict;
use warnings;
use Test::More;
use t::WAFTest::Engine;
use HTTP::Request;
use Data::Dumper;

BEGIN {
    use_ok "t::WAFTest";
};

my $req = HTTP::Request->new( GET => 'http://localhost/act/forward_main' );
$req->protocol('HTTP/1.0');
my $Engine = create_engine;
my $engine = $Engine->new(
    interface => {
        module => 'Test',
        request_handler => sub {
            my $app = t::WAFTest->new;
            $app->handle_request({ name => "WAFTest" }, @_);
        },
    },
);
my $response = $engine->run($req);
is $response->code => 500;
is $response->content => "error on forward_to_2";

done_testing;
