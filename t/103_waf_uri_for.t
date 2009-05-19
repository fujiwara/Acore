# -*- mode:perl -*-
use strict;
use Test::Base;
use HTTP::Engine::Test::Request;
use utf8;
use Encode qw/ encode_utf8 /;

plan tests => (3 + 1 * blocks);

filters {
    code => [qw/chop/],
    uri  => [qw/chop/],
};

use_ok("HTTP::Engine");
use_ok("Acore::WAF");
use_ok("t::WAFTest");
my $app = t::WAFTest->new;
my $req = HTTP::Engine::Test::Request->new(
    uri    => 'http://example.com/aaa/bbb?foo=bar&bar=baz',
    method => "GET",
);
$app->request($req);
$app->config({ include_path => [] });

run {
    my $block = shift;
    my $result = eval $block->code;
    die $@ if $@;

    is $result => $block->uri, encode_utf8( $block->code );
}

__END__

===
--- code
$app->uri_for('/foo/bar')
--- uri
http://example.com/foo/bar

===
--- code
$app->uri_for('/foo/', "A", "B", "C");
--- uri
http://example.com/foo/A/B/C

===
--- code
$app->uri_for('/foo/', "あ", "い", "う")
--- uri
http://example.com/foo/%E3%81%82/%E3%81%84/%E3%81%86

===
--- code
$app->uri_for('/foo/', { aa => "bb", cc => "dd" });
--- uri
http://example.com/foo/?cc=dd&aa=bb

===
--- code
$app->uri_for('/foo/', { aa => "あ", cc => "い" });
--- uri
http://example.com/foo/?cc=%E3%81%84&aa=%E3%81%82
