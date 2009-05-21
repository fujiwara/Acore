# -*- mode:perl -*-
use strict;
use warnings;
use Test::Base;
use HTTP::Request;
use Data::Dumper;
use Clone qw/ clone /;

plan tests => ( 3 + 1 * blocks );

filters {
    response => [qw/chomp convert_charset/],
    method   => [qw/chomp/],
};

use_ok("HTTP::Engine");
use_ok("Acore::WAF");
use_ok("t::WAFTestTT");

my $base_config = {
    root => "t",
    tt   => {},
};

run {
    my $block  = shift;
    my $config = clone $base_config;

    my $method = $block->method || "GET";
    my $req = HTTP::Request->new( $method => $block->uri );
    $req->protocol('HTTP/1.0');
    $req->header(
        "Content-Length" => 0,
        "Content-Type"   => "text/plain",
    );

    my @res_args = $block->preprocess ? eval $block->preprocess : ();
    die $@ if $@;

    my $engine = HTTP::Engine->new(
        interface => {
            module => 'Test',
            request_handler => sub {
                my $app = t::WAFTestTT->new;
                $app->handle_request($config, @_);
            },
        },
    );
    my $response = $engine->run($req);
    my $data = $response->headers->as_string."\n".$response->content;
    $data =~ s/[\r\n]+\z//;

    is $data, sprintf($block->response, @res_args), $block->name;

    eval $block->postprocess if $block->postprocess;
    die $@ if $@;
};

sub convert_charset {
    my $str = shift;
    if ( $str =~ /Shift_JIS/i ) {
        Encode::from_to($str, 'utf-8', 'cp932');
    }
    $str;
}

__END__

=== /
--- uri
http://localhost/
--- response
Content-Length: 5
Content-Type: text/html; charset=utf-8
Status: 200

index

=== render
--- uri
http://localhost/act/render
--- response
Content-Length: 113
Content-Type: text/html; charset=utf-8
Status: 200

uri: http://localhost/act/render
html: &lt;html&gt;
raw: <html>
日本語は UTF-8 で書きます
include file

=== broken template
--- uri
http://localhost/act/render_broken_tt
--- response
Content-Length: 21
Content-Type: text/html; charset=utf-8
Status: 500

Internal Server Error
