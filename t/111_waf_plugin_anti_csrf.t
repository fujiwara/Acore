# -*- mode:perl -*-
use strict;
use warnings;
use Test::Base;
use HTTP::Request;
use Data::Dumper;
use Clone qw/ clone /;

plan tests => 10;

filters {
    response => [qw/chomp/],
    uri      => [qw/chomp/],
    method   => [qw/chomp/],
};

use_ok("HTTP::Engine");
use_ok("Acore::WAF");
use_ok("t::WAFTest");

my $base_config = {
    root => "t",
    anti_csrf => { param => 'token' },
    session => {
        store => {
            class => "DBM",
            args  => { file => "t/tmp/session.dbm", },
        },
        state => {
            class => "Cookie",
            args  => { name => "sid" },
        },
    },
};
t::WAFTest->setup(qw/ Session AntiCSRF /);

our $Client = {};

run {
    my $block  = shift;
    my $config = clone $base_config;
    my $method = $block->method || 'GET';
    my $req = HTTP::Request->new( $method => $block->uri );
    $req->protocol('HTTP/1.0');

    eval $block->preprocess if $block->preprocess;

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
    eval $block->handle_response or die $!
};

__END__

=== get_form
--- uri
http://localhost/act/anti_csrf
--- handle_response
{
    ok $response->content =~ qr{name="token" value="(.+)"};
    ok $1, "token $1";
    $Client->{token} = $1;
    ok $response->header('Set-Cookie') =~ qr{sid=(.+?);};
    ok $1, "session_id $1";
    $Client->{session_id} = $1;
}

=== post_ok
--- method
POST
--- uri
http://localhost/act/anti_csrf
--- preprocess
{
    my $body = "token=" . $Client->{token};
    $req->content($body);
    $req->header("Cookie" => "sid=" . $Client->{session_id} . ";");
    $req->content_length( length $body );
    $req->content_type('application/x-www-form-urlencoded');
}
--- handle_response
{
    like $response->content => qr/ok/, "post_ok";
}

=== post_ng
--- method
POST
--- uri
http://localhost/act/anti_csrf
--- preprocess
{
    my $body = "token=" . $Client->{token} . "XXX";
    $req->content($body);
    $req->header("Cookie" => "sid=" . $Client->{session_id} . ";");
    $req->content_length( length $body );
    $req->content_type('application/x-www-form-urlencoded');
}
--- handle_response
{
    is $response->code    => 400, "status 400";
    is $response->content => "Bad Request";
}
