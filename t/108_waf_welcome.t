# -*- mode:perl -*-

use strict;
use warnings;
use Test::More tests => 4;
use t::WAFTest::Engine;
use HTTP::Request;

BEGIN {
    eval "use Modile::CoreList;";
    plan $@ ? (skip_all => "Module::CoreList is not installed") : (tests => 4);
    use_ok "HTTP::Engine";
    use_ok "t::WAFTest";
};

my $req = HTTP::Request->new( GET => 'http://localhost/act/welcome' );
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
is $response->code      => 200;
like $response->content => qr/WAFTest/;
