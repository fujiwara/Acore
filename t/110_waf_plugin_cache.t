# -*- mode:perl -*-
use strict;
use warnings;
use Test::Base;
use HTTP::Request;
use Data::Dumper;
use Clone qw/ clone /;

plan tests => ( 3 + 1 * blocks );

filters {
    response => [qw/chomp/],
    uri      => [qw/chomp/],
};

use_ok("HTTP::Engine");
use_ok("Acore::WAF");
use_ok("t::WAFTest");

my $base_config = {
    root => "t",
    cache => {
        class => "t::Cache",
        args  => {
            cache_root => "t/tmp/",
        },
    },
};
t::WAFTest->setup("Cache");

run {
    my $block  = shift;
    my $config = clone $base_config;

    my $req = HTTP::Request->new( GET => $block->uri );
    $req->protocol('HTTP/1.0');

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

    is $data, $block->response, $block->name;
};

__END__

=== set
--- uri
http://localhost/act/cache_set?value=foo
--- response
Content-Length: 3
Content-Type: text/html; charset=utf-8
Status: 200

foo

=== get
--- uri
http://localhost/act/cache_get
--- response
Content-Length: 3
Content-Type: text/html; charset=utf-8
Status: 200

foo
