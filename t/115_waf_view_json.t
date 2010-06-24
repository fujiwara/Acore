# -*- mode:perl -*-
use strict;
use Test::More;
use HTTP::Engine::Test::Request;
use Scalar::Util qw/ blessed /;
use t::WAFTest::Engine;

BEGIN {
    use_ok 'Acore::WAF';
    use_ok 't::WAFTest';
};

my $c = t::WAFTest->new;
my $req = create_request(
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

done_testing;
