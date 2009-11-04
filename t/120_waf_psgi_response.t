# -*- mode:perl -*-
use strict;
use Test::More;
use t::WAFTest::Engine;

BEGIN {
    plan $ENV{TEST_PSGI} ? (tests    => 3)
                         : (skip_all => "not running PSGI test");
    use_ok 'Acore::WAF';
    use_ok 't::WAFTest';
};

my $app = t::WAFTest->new;
my $req = create_request(
    uri    => 'http://example.com/act/native_psgi_response',
    method => "GET",
);
$app->request($req);
$app->handle_request({}, $req);

is_deeply $app->res => [
    200,
    ["Content-Type" => "text/plain"],
    ["native_psgi_response"],
], "pass through PSGI response";
