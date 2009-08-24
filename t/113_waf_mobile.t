# -*- mode:perl -*-
use strict;
use warnings;
use Test::Base;
use HTTP::Request;
use Data::Dumper;
use Clone qw/ clone /;

plan tests => 13;

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
    support_mobile => 1,
};
t::WAFTest->setup(qw/ Session /);

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

=== pc
--- uri
http://localhost/act/mobile
--- preprocess
$req->header( "User-Agent" => "Mozilla/5.0" );
--- handle_response
{
    my $html = $response->content;
    ok $html =~ m{session_id: (\w{32})};
    my $sid  = $1;
    ok $sid, "session_id $sid";
    ok $html =~ m{\Q"http://localhost/act/mobile"\E};
    my (undef, $charset) = $response->content_type;
    ok $charset =~ m{UTF-8}i;
}

=== docomo
--- uri
http://localhost/act/mobile
--- preprocess
$req->header( "User-Agent" => "DoCoMo/2.0 N900i(c100;TB;W24H12)" );
--- handle_response
{
    my $html = $response->content;
    ok $html =~ m{session_id: (\w{32})};
    my $sid  = $1;
    ok $sid, "session_id $sid";
    ok $html =~ m{\Qhttp://localhost/act/mobile?_sid=$sid\E};
    my (undef, $charset) = $response->content_type;
    ok $charset =~ m{Shift_JIS}i;
}

=== ezweb
--- uri
http://localhost/act/mobile
--- preprocess
$req->header( "User-Agent" => "KDDI-HI31 UP.Browser/6.2.0.6.2 (GUI) MMP/2.0" );
--- handle_response
{
    my $html = $response->content;
    my (undef, $charset) = $response->content_type;
    ok $charset =~ m{Shift_JIS}i;
}

=== softbank
--- uri
http://localhost/act/mobile
--- preprocess
$req->header( "User-Agent" => "SoftBank/1.0/910T/TJ001/SNXXXXXXXXX Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1" );
--- handle_response
{
    my $html = $response->content;
    my (undef, $charset) = $response->content_type;
    ok $charset =~ m{UTF-8}i;
}

