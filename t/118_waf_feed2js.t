# -*- mode:perl -*-
use strict;
use Test::More;
use HTTP::Engine::Test::Request;
use Scalar::Util qw/ blessed /;

BEGIN {
    eval "use XML::Feed";
    plan $@ ? (skip_all => "no XML::Feed") : (tests => 5);

    use_ok 'Acore::WAF';
    use_ok 't::WAFTest';
    use_ok 'HTTP::Engine';
    use_ok 'Acore::WAF::Controller::Feed2Js';
    no warnings "redefine";
    *Acore::WAF::Controller::Feed2Js::fetch_uri = sub {
        my ($self, $c, $uri) = @_;
        my $res = HTTP::Response->new;
        open my $in, "<", $uri or die "$!";
        $res->content( do { local $/; <$in> } );
        $res;
    };
};

my $uri  = "t/sample.rss";
my $json = '{"link":"http://example.com/blog/","base":null,"language":null,"entries":[{"link":"http://example.com/entry/1","base":null,"content":"エントリー1の内容","author":"acore","modified":null,"tags":null,"summary":null,"issued":"2009-09-15T03:49:03","title":"エントリー1","category":null,"id":"http://example.com/entry/1"}],"self_link":null,"copyright":null,"author":"acore","description":"サンプルのためのBlog","modified":null,"generator":null,"tagline":"サンプルのためのBlog","title":"サンプルBlog"}';

my $c = t::WAFTest->new;
$c->config({ include_path => [] });

{
    my $req = HTTP::Engine::Test::Request->new(
        uri    => "http://example.com/?uri=$uri",
        method => "GET",
    );
    $c->request($req);
    $c->forward( "Acore::WAF::Controller::Feed2Js" => "process" );
    is $c->res->body => $json;
}
