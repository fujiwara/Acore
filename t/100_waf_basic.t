# -*- mode:perl -*-
use strict;
use warnings;
use Test::Base;
use HTTP::Request;
use Data::Dumper;

plan tests => 1 * blocks;

filters {
    response => [qw/chop/],
};

use_ok("HTTP::Engine");
use_ok("Acore::WAF");
use_ok("t::WAFTest");

run {
    my $block = shift;

    my $req = HTTP::Request->new( GET => $block->uri );
    $req->protocol('HTTP/1.0');
    eval $block->preprocess if $block->preprocess;
    die $@ if $@;

    my $config = {};
    my $engine = HTTP::Engine->new(
        interface => {
            module => 'Test',
            request_handler => sub {
                my $app = t::WAFTest->new;
                $app->handle_request($config, @_);
            },
        },
    );
    my $response = $engine->run($req);
    my $data = $response->headers->as_string."\n".$response->content;
    is $data, $block->response;
};

__END__
===
--- uri
http://localhost/
--- response
Content-Length: 5
Content-Type: text/html
Status: 200

index

===
--- uri
http://localhost/ok
--- response
Content-Length: 2
Content-Type: text/html
Status: 200

ok




