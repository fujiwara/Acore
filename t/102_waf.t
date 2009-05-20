# -*- mode:perl -*-
use strict;
use Test::More tests => 5;
use HTTP::Engine::Test::Request;

BEGIN {
    use_ok 'Acore::WAF';
    use_ok 't::WAFTest';
    use_ok 'HTTP::Engine';
};

my $app = t::WAFTest->new;
my $req = HTTP::Engine::Test::Request->new(
    uri    => 'http://example.com/?foo=bar&bar=baz',
    method => "GET",
);
$app->request($req);
$app->config({ include_path => [] });

isa_ok $app => "Acore::WAF";
can_ok $app, qw/ setup path_to handle_request _dispatch dispatch_static
                 serve_static_file serve_acore_document
                 redirect uri_for render render_part dispatch_favicon
                 add_trigger _call_trigger
                 stash config request response acore _triggers log
                 req res error detach welcome_message
               /;

