# -*- mode:perl -*-

use strict;
use warnings;
use Test::More;
use t::WAFTest::Engine;
use HTTP::Request;
use Data::Dumper;
use Path::Class qw/ file /;

BEGIN {
    use_ok "t::WAFTest";
};
my $uniq = rand();
my $req = HTTP::Request->new( GET => "http://localhost/act/error_message_args?uniq=$uniq" );
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
like file("t/tmp/error_log")->slurp => qr{Error message $uniq};

done_testing;
