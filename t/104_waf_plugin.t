# -*- mode:perl -*-
use strict;
use warnings;
use Test::Base;
use HTTP::Request;
use Data::Dumper;

plan tests => (3 + 1 * blocks);

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
    my @res_args = $block->preprocess ? eval $block->preprocess : ();
    die $@ if $@;

    my $config = { root => "t" };
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
    $data =~ s/[\r\n]+\z//;

    is $data, sprintf($block->response, @res_args);

    eval $block->postprocess if $block->postprocess;
    die $@ if $@;
};

__END__

===
--- uri
http://localhost/
--- response
Content-Length: 5
Content-Type: text/html; charset=utf-8
Status: 200

index

