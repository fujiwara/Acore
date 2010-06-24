# -*- mode:perl -*-
use strict;
use Test::More;
use Test::Requires qw/ XML::Feed /;
use Scalar::Util qw/ blessed /;
use t::WAFTest::Engine;

BEGIN {
    use_ok 'Acore::WAF';
    use_ok 't::WAFTest';
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
my $json = '{"link":"http://example.com/blog/","base":null,"language":null,"entries":[{"link":"http://example.com/entry/1","base":null,"content":"エントリー1の内容","author":"acore","modified":null,"summary":null,"issued":"2009-09-15T03:49:03","title":"エントリー1","category":null,"id":"http://example.com/entry/1"}],"self_link":null,"copyright":null,"author":"acore","description":"サンプルのためのBlog","modified":null,"generator":null,"tagline":"サンプルのためのBlog","title":"サンプルBlog"}';

my $c = t::WAFTest->new;
$c->config({ include_path => [] });

{
    my $req = create_request(
        uri    => "http://example.com/?uri=$uri",
        method => "GET",
    );
    $c->request($req);
    $c->forward( "Acore::WAF::Controller::Feed2Js" => "process" );
    use JSON;
    is_deeply from_json($c->res->body) => from_json($json), "decoded json ok";
}

done_testing;
