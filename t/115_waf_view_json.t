# -*- mode:perl -*-
use strict;
use Test::More tests => 10;
use HTTP::Engine::Test::Request;
use Scalar::Util qw/ blessed /;

BEGIN {
    use_ok 'Acore::WAF';
    use_ok 't::WAFTest';
    use_ok 'HTTP::Engine';
};

my $c = t::WAFTest->new;
my $req = HTTP::Engine::Test::Request->new(
    uri    => 'http://example.com/',
    method => "GET",
);
$c->request($req);
$c->config({ include_path => [] });
{
    my $view = $c->view('JSON');
    isa_ok $view               => "t::WAFTest::View::JSON";
    is $view->encoding         => "utf-8";
    is $view->allow_callback   => 0;
    is $view->callback_param   => "callback";
    is $view->no_x_json_header => 0;
    isa_ok $view->converter    => "JSON";

    $c->forward( $view => "process", { foo => 1, bar => "BAR" } );
    is $c->res->body => '{"bar":"BAR","foo":1}';
}
