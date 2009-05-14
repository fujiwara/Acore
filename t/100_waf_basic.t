# -*- mode:perl -*-
use strict;
use warnings;
use Test::Base;
use HTTP::Request;
use Data::Dumper;
use Acore::Document;
use Acore;
use DBI;
use Clone qw/ clone /;

plan tests => ( 3 + 4 + 1 * blocks );

filters {
    response => [qw/chop convert_charset/],
};

use_ok("HTTP::Engine");
use_ok("Acore::WAF");
use_ok("t::WAFTest");

my $base_config = {
    root => "t",
    dsn  => [
        'dbi:SQLite:dbname=t/test.sqlite', '', '',
        { RaiseError => 1, AutoCommit => 1 },
    ],
};

run {
    my $block  = shift;
    my $config = clone $base_config;

    my $req = HTTP::Request->new( GET => $block->uri );
    $req->protocol('HTTP/1.0');
    my @res_args = $block->preprocess ? eval $block->preprocess : ();
    die $@ if $@;

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
    my $data = $response->headers->as_string."\n".$response->content;
    $data =~ s/[\r\n]+\z//;

    is $data, sprintf($block->response, @res_args);

    eval $block->postprocess if $block->postprocess;
    die $@ if $@;
};

sub convert_charset {
    my $str = shift;
    if ( $str =~ /Shift_JIS/i ) {
        Encode::from_to($str, 'utf-8', 'cp932');
    }
    $str;
}

sub create_adoc {
    my $config = shift;

    unlink "t/test.sqlite";
    my $dbh = DBI->connect(@{ $config->{dsn} });
    my $app = Acore->new({ dbh => $dbh, setup_db => 1, });
    {
        package Acore::Document::Test;
        use Any::Moose;
        extends 'Acore::Document';
        override "as_string" => sub { shift->{body} };
    }
    my $doc = Acore::Document::Test->new({
        path         => "/foo/bar",
        content_type => "text/plain",
        body         => "Acore::Document::Test body",
    });
    isa_ok $doc => "Acore::Document::Test";
    isa_ok $doc => "Acore::Document";
    is $doc->as_string => "Acore::Document::Test body";

    $doc = $app->put_document($doc);
    ok $doc;
    $doc;
}

__END__

===
--- uri
http://localhost/
--- response
Content-Length: 5
Content-Type: text/html; charset=utf-8
Status: 200

index

===
--- uri
http://localhost/act/ok
--- response
Content-Length: 2
Content-Type: text/html; charset=utf-8
Status: 200

ok

===
--- uri
http://localhost/act/ng
--- response
Content-Length: 10
Content-Type: text/html; charset=utf-8
Status: 404

Not found.

===
--- uri
http://localhost/ng
--- response
Content-Length: 10
Content-Type: text/html; charset=utf-8
Status: 404

Not found.

===
--- uri
http://localhost/static/not_found.txt
--- response
Content-Length: 10
Content-Type: text/html; charset=utf-8
Status: 404

Not found.

===
--- preprocess
{
    my $fh = Path::Class::file("t/static/test.txt")->openw;
    $fh->print("0123456789\nabcdefg");
}
(HTTP::Date::time2str(time));
--- postprocess
unlink("t/static/test.txt");
--- uri
http://localhost/static/test.txt
--- response
Content-Length: 18
Content-Type: text/plain; charset=utf-8
Last-Modified: %s
Status: 200

0123456789
abcdefg

===
--- preprocess
{
    my $fh = Path::Class::file("t/static/hide.txt")->openw;
    $fh->print("0123456789\nabcdefg");
    chmod 0000, "t/static/hide.txt";
}
--- postprocess
chmod 0600, "t/static/hide.txt";
unlink("t/static/hide.txt");
--- uri
http://localhost/static/hide.txt
--- response
Content-Length: 10
Content-Type: text/html; charset=utf-8
Status: 403

forbidden.

===
--- preprocess
$req->header("If-Modified-Since" => HTTP::Date::time2str(time));
{
    my $fh = Path::Class::file("t/static/test2.txt")->openw;
    $fh->print("0123456789\nabcdefg");
}
--- postprocess
unlink("t/static/test2.txt");
--- uri
http://localhost/static/test2.txt
--- response
Content-Type: text/html; charset=utf-8
Status: 304

===
--- preprocess
{
    my $fh = Path::Class::file("t/static/noext")->openw;
    $fh->print("0123456789");
}
(HTTP::Date::time2str(time));
--- postprocess
unlink("t/static/noext");
--- uri
http://localhost/static/noext
--- response
Content-Length: 10
Content-Type: text/plain; charset=utf-8
Last-Modified: %s
Status: 200

0123456789

===
--- uri
http://localhost/act/rd
--- response
Location: http://localhost/redirect_to
Content-Length: 0
Content-Type: text/html; charset=utf-8
Status: 302

===
--- uri
http://localhost/act/error
--- response
Content-Length: 21
Content-Type: text/html; charset=utf-8
Status: 500

Internal Server Error

===
--- preprocess
{
    my $fh = Path::Class::file("t/favicon.ico")->openw;
    $fh->print("AAA");
}
(HTTP::Date::time2str(time));
--- postprocess
unlink "t/favicon.ico";
--- uri
http://localhost/favicon.ico
--- response
Content-Length: 3
Content-Type: image/vnd.microsoft.icon
Last-Modified: %s
Status: 200

AAA

===
--- uri
http://localhost/act/forward
--- response
Content-Length: 3
Content-Type: text/html; charset=utf-8
Status: 200

abc

===
--- uri
http://localhost/act/forward_internal
--- response
Content-Length: 2
Content-Type: text/html; charset=utf-8
Status: 200

ok

===
--- uri
http://localhost/act/render
--- response
Content-Length: 113
Content-Type: text/html; charset=utf-8
Status: 200

uri: http://localhost/act/render
html: &lt;html&gt;
raw: <html>
日本語は UTF-8 で書きます
include file

===
--- uri
http://localhost/act/sample_plugin
--- response
Content-Length: 13
Content-Type: text/html; charset=utf-8
Status: 200

sample plugin

===
--- preprocess
create_adoc($config);
(HTTP::Date::time2str(time));
--- uri
http://localhost/adoc/foo/bar
--- response
Content-Length: 26
Content-Type: text/plain; charset=utf-8
Last-Modified: %s
Status: 200

Acore::Document::Test body

===
--- uri
http://localhost/adoc/foo/baz
--- response
Content-Length: 10
Content-Type: text/html; charset=utf-8
Status: 404

Not found.

===
--- uri
http://localhost/act/say?input=%E3%81%82%E3%81%84%E3%81%86
--- response
Content-Length: 28
Content-Type: text/html; charset=utf-8
Status: 200

入力はあいうです。

===
--- uri
http://localhost/act/say_mt?input=%E3%81%82%E3%81%84%E3%81%86
--- response
Content-Length: 28
Content-Type: text/html; charset=utf-8
Status: 200

入力はあいうです。

===
--- preprocess
$config->{encoding} = "cp932";
$config->{charset}  = "Shift_JIS";
--- uri
http://localhost/act/say?input=%82%A0%82%A2%82%A4
--- response
Content-Length: 19
Content-Type: text/html; charset=Shift_JIS
Status: 200

入力はあいうです。

===
--- preprocess
$config->{encoding} = "cp932";
$config->{charset}  = "Shift_JIS";
--- uri
http://localhost/act/say_mt?input=%82%A0%82%A2%82%A4
--- response
Content-Length: 19
Content-Type: text/html; charset=Shift_JIS
Status: 200

入力はあいうです。
