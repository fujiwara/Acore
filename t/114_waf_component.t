# -*- mode:perl -*-
use strict;
use Test::More;
use HTTP::Engine::Test::Request;
use Scalar::Util qw/ blessed /;
use t::WAFTest::Engine;

BEGIN {
    use_ok 'Acore::WAF';
    use_ok 't::WAFTest';
    use_ok 'HTTP::Engine';
};

my $c = t::WAFTest->new;
my $req = create_request(
    uri    => 'http://example.com/',
    method => "GET",
);
$c->request($req);
$c->config({ include_path => [] });

{
    my $model = $c->model("Foo");
    is $model => "t::WAFTest::Model::Foo";
    is $model->foo => "foo";
}
{
    my $model = $c->model("Bar");
    ok blessed $model;
    isa_ok $model => "t::WAFTest::Model::Bar";
    is $model->bar => "bar";

    is $model => $c->model("Bar"), "same instance";
}

done_testing;
