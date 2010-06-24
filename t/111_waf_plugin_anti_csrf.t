# -*- mode:perl -*-
use strict;
use warnings;
use Test::Base;
use Test::More;
use HTTP::Request;
use Data::Dumper;
use Storable qw/ dclone /;
use t::WAFTest::Engine;

filters {
    response => [qw/chomp/],
    uri      => [qw/chomp/],
    method   => [qw/chomp/],
};

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

our $ctx = {};
run {
    my $block  = shift;
    my $config = dclone $base_config;
    run_engine_test($config, $block, $ctx);
};

done_testing;

__END__

=== get_form
--- uri
http://localhost/act/anti_csrf
--- handle_response
{
    ok $response->content =~ qr{name="token" value="(.+)"};
    ok $1, "token $1";
    $ctx->{token} = $1;
    ok $response->header('Set-Cookie') =~ qr{sid=(.+?);};
    ok $1, "session_id $1";
    $ctx->{session_id} = $1;
}

=== post_ok
--- method
POST
--- uri
http://localhost/act/anti_csrf
--- preprocess
{
    my $body = "token=" . $ctx->{token};
    $req->content($body);
    $req->header("Cookie" => "sid=" . $ctx->{session_id} . ";");
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
    my $body = "token=" . $ctx->{token} . "XXX";
    $req->content($body);
    $req->header("Cookie" => "sid=" . $ctx->{session_id} . ";");
    $req->content_length( length $body );
    $req->content_type('application/x-www-form-urlencoded');
}
--- handle_response
{
    is $response->code    => 400, "status 400";
    is $response->content => "Bad Request";
}
