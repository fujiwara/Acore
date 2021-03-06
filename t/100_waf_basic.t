# -*- mode:perl -*-
BEGIN {
    *CORE::GLOBAL::time = sub { 1234567890 };
};
use strict;
use warnings;
use Test::Base;
use Test::More;
use HTTP::Request;
use Data::Dumper;
use Acore::Document;
use Acore;
use DBI;
use Storable qw/ dclone /;
use Path::Class qw/ file dir /;
use t::WAFTest::Engine;

filters {
    response  => [qw/chomp convert_charset/],
    method    => [qw/chomp/],
    app_class => [qw/chomp/],
};

use_ok("Acore::WAF");
use_ok("t::WAFTest");

my $base_config = {
    root => "t",
    dsn  => [
        'dbi:SQLite:dbname=t/tmp/test.sqlite', '', '',
        { RaiseError => 1, AutoCommit => 1 },
    ],
    session => {
        store => {
            class => "DBM",
            args  => { file => "t/tmp/session.dbm", },
        },
        state => {
            class => "Cookie",
            args  => {},
        },
    },
};

my $ctx = {};
run {
    my $block  = shift;
    my $config = dclone $base_config;
    run_engine_test($config, $block, $ctx, $block->app_class);
};

done_testing;


sub create_adoc {
    my $config = shift;

    unlink "t/tmp/test.sqlite";
    my $dbh = DBI->connect(@{ $config->{dsn} });
    my $app = Acore->new({ dbh => $dbh });
    $app->setup_db;
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
    is $doc->as_string => "Acore::Document::Test body", "Acore::Document as_string";

    $doc = $app->put_document($doc);
    ok $doc, "Acore->put_document";
    $doc;
}

sub create_user {
    my $config = shift;

    unlink "t/tmp/test.sqlite";
    my $dbh = DBI->connect(@{ $config->{dsn} });
    my $app = Acore->new({ dbh => $dbh });
    $app->setup_db;

    my $user = $app->create_user({
        name => "root",
    });
    $user->set_password('toor');
    $app->save_user($user);
    $user;
}

unlink $_ for qw( t/tmp/test.sqlite
                  t/tmp/session.dbm.dir
                  t/tmp/test_config.yaml
                  t/tmp/test_config_development.yaml
                  t/tmp/session.dbm.pag );

__END__

=== /
--- uri
http://localhost/
--- response
Content-Length: 5
Content-Type: text/html; charset=utf-8
Status: 200

index

=== ok
--- uri
http://localhost/act/ok
--- response
Content-Length: 2
Content-Type: text/html; charset=utf-8
Status: 200

ok

=== not found
--- uri
http://localhost/act/ng
--- response
Content-Length: 9
Content-Type: text/html; charset=utf-8
Status: 404

Not Found

=== not found
--- uri
http://localhost/ng
--- response
Content-Length: 9
Content-Type: text/html; charset=utf-8
Status: 404

Not Found

=== static not found
--- preprocess
{
    mkdir "t/static";
}
--- uri
http://localhost/static/not_found.txt
--- response
Content-Length: 9
Content-Type: text/html; charset=utf-8
Status: 404

Not Found

=== static ok
--- preprocess
{
    use Path::Class qw/ file /;
    mkdir "t/static";
    my $fh = file("t/static/test.txt")->openw;
    $fh->print("0123456789\nabcdefg");
}
(HTTP::Date::time2str(file("t/static/test.txt")->stat->mtime));
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

=== static forbidden
--- preprocess
{
    use Path::Class qw/ file /;
    my $fh = file("t/static/hide.txt")->openw;
    $fh->print("0123456789\nabcdefg");
    chmod 0000, "t/static/hide.txt";
}
--- postprocess
chmod 0600, "t/static/hide.txt";
unlink("t/static/hide.txt");
--- uri
http://localhost/static/hide.txt
--- response
Content-Length: 9
Content-Type: text/html; charset=utf-8
Status: 403

Forbidden

=== static not modified
--- preprocess
{
    use Path::Class qw/ file /;
    my $fh = file("t/static/test2.txt")->openw;
    $fh->print("0123456789\nabcdefg");
    $req->header("If-Modified-Since"
        => HTTP::Date::time2str(file("t/static/test2.txt")->stat->mtime)
    );
}
--- postprocess
unlink("t/static/test2.txt");
--- uri
http://localhost/static/test2.txt
--- response
Content-Type: text/html; charset=utf-8
Status: 304

=== static no extention
--- preprocess
{
    use Path::Class qw/ file /;
    my $fh = file("t/static/noext")->openw;
    $fh->print("0123456789");
}
(HTTP::Date::time2str( file("t/static/noext")->stat->mtime ));
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

=== static directory traversal
--- uri
http://localhost/static/../WAFTest.pm
--- response
Content-Length: 9
Content-Type: text/html; charset=utf-8
Status: 403

Forbidden

=== redirect
--- uri
http://localhost/act/rd
--- response
Location: http://localhost/redirect_to
Content-Length: 0
Content-Type: text/html; charset=utf-8
Status: 302

=== redirect 301
--- uri
http://localhost/act/rd301
--- response
Location: http://localhost/redirect_to
Content-Length: 0
Content-Type: text/html; charset=utf-8
Status: 301

=== server error
--- uri
http://localhost/act/error
--- handle_response
{
    is $response->code => 500;
}

=== detach
--- uri
http://localhost/act/detach
--- response
Content-Length: 13
Content-Type: text/html; charset=utf-8
Status: 200

before detach

=== favicon
--- preprocess
{
    use Path::Class qw/ file /;
    my $fh = file("t/static/favicon.ico")->openw;
    $fh->print("AAA");
}
(HTTP::Date::time2str(file("t/static/favicon.ico")->stat->mtime));
--- postprocess
unlink "t/static/favicon.ico";
--- uri
http://localhost/favicon.ico
--- response
Content-Length: 3
Content-Type: image/vnd.microsoft.icon
Last-Modified: %s
Status: 200

AAA

=== forward
--- uri
http://localhost/act/forward
--- response
Content-Length: 3
Content-Type: text/html; charset=utf-8
Status: 200

abc

=== forward internal
--- uri
http://localhost/act/forward_internal
--- response
Content-Length: 2
Content-Type: text/html; charset=utf-8
Status: 200

ok

=== render
--- uri
http://localhost/act/render
--- response
Content-Length: 127
Content-Type: text/html; charset=utf-8
Status: 200

uri: http://localhost/act/render
html: &lt;html&gt;
raw1: <html>
raw2: <html>
日本語は UTF-8 で書きます
include file

=== render_string
--- uri
http://localhost/act/render_string
--- response
Content-Length: 134
Content-Type: text/html; charset=utf-8
Status: 200

uri: http://localhost/act/render_string
html: &lt;html&gt;
raw1: <html>
raw2: <html>
日本語は UTF-8 で書きます
include file

=== plugin
--- uri
http://localhost/act/sample_plugin
--- response
Content-Length: 13
Content-Type: text/html; charset=utf-8
Status: 200

sample plugin

=== acore document
--- preprocess
my $doc = main::create_adoc($config);
(HTTP::Date::time2str($doc->updated_on->epoch));
--- uri
http://localhost/adoc/foo/bar
--- response
Content-Length: 26
Content-Type: text/plain; charset=utf-8
Last-Modified: %s
Status: 200

Acore::Document::Test body

=== acore document not found
--- uri
http://localhost/adoc/foo/baz
--- response
Content-Length: 9
Content-Type: text/html; charset=utf-8
Status: 404

Not Found

=== decode input
--- uri
http://localhost/act/say?input=%E3%81%82%E3%81%84%E3%81%86
--- response
Content-Length: 28
Content-Type: text/html; charset=utf-8
Status: 200

入力はあいうです。

=== decode input & render
--- uri
http://localhost/act/say_mt?input=%E3%81%82%E3%81%84%E3%81%86
--- response
Content-Length: 28
Content-Type: text/html; charset=utf-8
Status: 200

入力はあいうです。

=== cp932
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

=== cp932 & render
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

=== input multi param
--- uri
http://localhost/act/say_multi?input=%E3%81%82&input=%E3%81%84&input=%E3%81%86
--- response
Content-Length: 28
Content-Type: text/html; charset=utf-8
Status: 200

入力はあいうです。

=== rest GET
--- uri
http://localhost/act/rest
--- response
Content-Length: 3
Content-Type: text/html; charset=utf-8
Status: 200

GET

=== rest POST
--- method
POST
--- uri
http://localhost/act/rest
--- response
Content-Length: 4
Content-Type: text/html; charset=utf-8
Status: 200

POST

=== rest PUT
--- method
PUT
--- uri
http://localhost/act/rest
--- response
Content-Length: 3
Content-Type: text/html; charset=utf-8
Status: 200

PUT

=== rest DELETE
--- method
DELETE
--- uri
http://localhost/act/rest
--- response
Content-Length: 6
Content-Type: text/html; charset=utf-8
Status: 200

DELETE

=== overload POST DELETE
--- method
POST
--- uri
http://localhost/act/rest?_method=DELETE
--- response
Content-Length: 6
Content-Type: text/html; charset=utf-8
Status: 200

DELETE

=== overload GET DELETE
--- method
GET
--- uri
http://localhost/act/rest?_method=DELETE
--- response
Content-Length: 3
Content-Type: text/html; charset=utf-8
Status: 200

GET

=== form validator plugin ok
--- uri
http://localhost/act/name_is_not_null?name=foo
--- response
Content-Length: 2
Content-Type: text/html; charset=utf-8
Status: 200

ok

=== form validator plugin ok
--- uri
http://localhost/act/name_is_not_null?name=
--- response
Content-Length: 2
Content-Type: text/html; charset=utf-8
Status: 200

ng

=== login_ok
--- preprocess
main::create_user($config);
--- uri
http://localhost/act/login?name=root&password=toor
--- response
Content-Length: 8
Content-Type: text/html; charset=utf-8
Set-Cookie: http_session_sid=SESSIONID; path=/
Status: 200

login_ok

=== logged_in
--- uri
http://localhost/act/logged_in
--- response
Content-Length: 9
Content-Type: text/html; charset=utf-8
Set-Cookie: http_session_sid=SESSIONID; path=/
Status: 200

logged_in

=== logout
--- uri
http://localhost/act/logout
--- response
Content-Length: 9
Content-Type: text/html; charset=utf-8
Status: 200

logout_ok

=== logged_in
--- uri
http://localhost/act/logged_in
--- response
Content-Length: 13
Content-Type: text/html; charset=utf-8
Set-Cookie: http_session_sid=SESSIONID; path=/
Status: 200

not_logged_in

=== login_ng
--- uri
http://localhost/act/login?name=root&password=xxxx
--- response
Content-Length: 8
Content-Type: text/html; charset=utf-8
Set-Cookie: http_session_sid=SESSIONID; path=/
Status: 200

login_ng

=== private
--- uri
http://localhost/act/_private
--- response
Content-Length: 9
Content-Type: text/html; charset=utf-8
Status: 404

Not Found

=== package
--- uri
http://localhost/act/render_package
--- response
Content-Length: 18
Content-Type: text/html; charset=utf-8
Status: 200

Acore::WAF::Render

=== render filter
--- uri
http://localhost/act/render_filter
--- response
Content-Length: 88
Content-Type: text/html; charset=utf-8
Status: 200

&lt;s&gt;
%E3%81%82%E3%81%84%E3%81%86
Aいう
%26lt%3Bs%26gt%3B
&lt;s&gt;<br/>&lt;s&gt;
--- raw
1

=== fill in form
--- uri
http://localhost/act/form?foo=FOO&bar=%E3%81%82%E3%81%84%E3%81%86&baz=%E3%81%82%E3%81%84%E3%81%86
--- response
Content-Length: 293
Content-Type: text/html; charset=utf-8
Status: 200

<form>
<input type="text" name="foo" value="FOO"/>
<input type="text" name="bar" value="あいう"/>
<select name="baz">
<option value="あああ">あああ</option>
<option value="あいう" selected="selected">あいう</option>
<option value="いいい">いいい</option>
</select>
</form>

=== auto action no run
--- uri
http://localhost/auto/run
--- response
Content-Length: 0
Content-Type: text/html; charset=utf-8
Status: 200

=== auto action run
--- uri
http://localhost/auto/run?auto=1
--- response
Content-Length: 33
Content-Type: text/html; charset=utf-8
Status: 200

t::WAFTest::Controller::Auto::run

=== rest post
--- method
POST
--- uri
http://localhost/rest/document
--- body
{"id":12345,"foo":"FOO","bar":[1,2,3],"baz":"日本語"}
--- response
Location: http://localhost/rest/document/id/12345
Content-Length: 0
Content-Type: text/html; charset=utf-8
Status: 201

=== rest get
--- uri
http://localhost/rest/document/id/12345
--- handle_response
{
    is $response->code => 200;
    is $response->content_type => "application/json";

    my $json = JSON->new;
    my $expect = $json->decode(q|{"baz":"日本語","_class":"Acore::Document","tags":[],"updated_on":"2009-02-14T08:31:30+09:00","content_type":"text/plain","bar":[1,2,3],"created_on":"2009-02-14T08:31:30+09:00","id":"12345","foo":"FOO"}|);
    my $got = $json->decode( $response->content );
    is_deeply $got => $expect, "same json";
}

=== rest get not found
--- uri
http://localhost/rest/document/id/123456
--- response
Content-Length: 9
Content-Type: text/html; charset=utf-8
Status: 404

Not Found

=== rest put
--- method
PUT
--- uri
http://localhost/rest/document/id/12345
--- body
{"id":12345,"bar":[2,3,4],"baz":"英語"}
--- response
Content-Length: 2
Content-Type: text/html; charset=utf-8
Status: 200

OK

=== rest get
--- uri
http://localhost/rest/document/id/12345
--- handle_response
{
    is $response->code => 200;
    is $response->content_type => "application/json";
    my $json = JSON->new;
    my $expect = $json->decode(q|{"baz":"英語","_class":"Acore::Document","tags":[],"updated_on":"2009-02-14T08:31:30+09:00","content_type":"text/plain","bar":[2,3,4],"created_on":"2009-02-14T08:31:30+09:00","id":"12345"}|);
    my $got    = $json->decode( $response->content );
    is_deeply $got => $expect, "same json";
}
=== rest delete
--- method
DELETE
--- uri
http://localhost/rest/document/id/12345
--- response
Content-Length: 2
Content-Type: text/html; charset=utf-8
Status: 200

OK

=== rest get deleted
--- uri
http://localhost/rest/document/id/12345
--- response
Content-Length: 9
Content-Type: text/html; charset=utf-8
Status: 404

Not Found

=== rest put bad
--- method
POST
--- uri
http://localhost/rest/document
--- body
[1,2,3]
--- response
Content-Length: 11
Content-Type: text/html; charset=utf-8
Status: 400

Bad Request

=== sites not found
--- uri
http://localhost/sites/xxx
--- response
Content-Length: 9
Content-Type: text/html; charset=utf-8
Status: 404

Not Found

=== sites index
--- uri
http://localhost/sites/
--- response
Content-Length: 42
Content-Type: text/html; charset=utf-8
Status: 200

<h1>Sites index.mt</h1>
http://localhost/

=== sites page
--- uri
http://localhost/sites/page
--- response
Content-Length: 41
Content-Type: text/html; charset=utf-8
Status: 200

<h1>Sites page.mt</h1>
http://localhost/

=== sites page deep
--- uri
http://localhost/sites/page/foo/bar
--- response
Content-Length: 22
Content-Type: text/html; charset=utf-8
Status: 200

<h1>Sites bar.mt</h1>

=== sites path
--- uri
http://localhost/sites/path/foo/bar
--- response
Content-Length: 22
Content-Type: text/html; charset=utf-8
Status: 200

<h1>Sites foo.mt</h1>

=== sites tt not found
--- preprocess
$config->{sites}->{use_tt} = 1;
--- uri
http://localhost/sites/xxx
--- response
Content-Length: 9
Content-Type: text/html; charset=utf-8
Status: 404

Not Found

=== sites index tt
--- preprocess
$config->{sites}->{use_tt} = 1;
--- uri
http://localhost/sites/
--- response
Content-Length: 42
Content-Type: text/html; charset=utf-8
Status: 200

<h1>Sites index.tt</h1>
http://localhost/

=== sites args
--- uri
http://localhost/sites/get_args/id=12345
--- response
Content-Length: 41
Content-Type: text/html; charset=utf-8
Status: 200

<h1>Sites get_args.mt</h1>
args.id=12345

=== sites auto1
--- uri
http://localhost/sites/auto1
--- response
Content-Length: 23
Content-Type: text/html; charset=utf-8
Status: 200

<h1>Sites auto.mt</h1>

=== sites auto1 ng
--- uri
http://localhost/sites/auto1?auto_ng=1
--- response
Content-Length: 0
Content-Type: text/html; charset=utf-8
Status: 200

=== sites auto2
--- uri
http://localhost/sites/auto2
--- response
Content-Length: 23
Content-Type: text/html; charset=utf-8
Status: 200

<h1>Sites auto.mt</h1>

=== sites auto2 ng
--- uri
http://localhost/sites/auto1?auto_ng=1
--- response
Content-Length: 0
Content-Type: text/html; charset=utf-8
Status: 200

=== /handle_args
--- uri
http://localhost/handle_args
--- response
Content-Length: 12
Content-Type: text/html; charset=utf-8
Status: 200

args.foo=bar

=== custom error page
--- preprocess
Path::Class::file("t/templates/404.mt")->openw->print(q{? my $c = shift;
<h1>Custom Error Page. <?= $c->res->status ?></h1>
});
--- uri
http://localhost/not_found
--- response
Content-Length: 32
Content-Type: text/html; charset=utf-8
Status: 404

<h1>Custom Error Page. 404</h1>

--- postprocess
Path::Class::file("t/templates/404.mt")->remove;

=== set flash
--- uri
http://localhost/act/set_flash?value=ABC
--- response
Location: http://localhost/act/get_flash
Content-Length: 0
Content-Type: text/html; charset=utf-8
Set-Cookie: http_session_sid=SESSIONID; path=/
Status: 302

=== get flash
--- uri
http://localhost/act/get_flash
--- response
Content-Length: 9
Content-Type: text/html; charset=utf-8
Set-Cookie: http_session_sid=SESSIONID; path=/
Status: 200

flash=ABC

=== get flash again
--- uri
http://localhost/act/get_flash
--- response
Content-Length: 6
Content-Type: text/html; charset=utf-8
Set-Cookie: http_session_sid=SESSIONID; path=/
Status: 200

flash=

=== serve_static_file
--- uri
http://localhost/act/static_file
--- response
Content-Length: 11
Content-Type: text/plain; charset=utf-8
Last-Modified: Tue, 28 Jul 2009 02:22:33 GMT
Status: 200

STATIC_FILE

=== serve_static_file_fh
--- uri
http://localhost/act/static_file_fh
--- response
Content-Length: 11
Content-Type: text/plain; charset=utf-8
Status: 200

STATIC_FILE

=== send serve_static_file
--- preprocess
$config->{x_sendfile_header} = "X-Sendfile";
--- uri
http://localhost/act/static_file
--- response
Content-Length: 0
Content-Type: text/plain; charset=utf-8
Last-Modified: Tue, 28 Jul 2009 02:22:33 GMT
Status: 200
X-Sendfile: t/tmp/static_file.txt

=== send serve_static_file
--- preprocess
$config->{x_sendfile_header} = "X-LIGHTTPD-send-file";
--- uri
http://localhost/act/static_file
--- response
Content-Length: 0
Content-Type: text/plain; charset=utf-8
Last-Modified: Tue, 28 Jul 2009 02:22:33 GMT
Status: 200
X-LIGHTTPD-Send-File: t/tmp/static_file.txt

=== any_location
--- uri
http://localhost/any_location/locate
--- response
Content-Length: 38
Content-Type: text/html; charset=utf-8
Status: 200

any_location any_location any_location

=== any_location somewhere
--- uri
http://localhost/somewhere/locate
--- response
Content-Length: 29
Content-Type: text/html; charset=utf-8
Status: 200

somewhere somewhere somewhere

=== redirector
--- uri
http://localhost/rd/
--- response
Content-Length: 9
Content-Type: text/html; charset=utf-8
Status: 404

Not Found

=== redirector http://example.com
--- uri
http://localhost/rd/http://example.com
--- response
Location: http://example.com
Content-Length: 0
Content-Type: text/html; charset=utf-8
Status: 302

=== redirector https://example.com
--- uri
http://localhost/rd/https://example.com

--- response
Location: https://example.com
Content-Length: 0
Content-Type: text/html; charset=utf-8
Status: 302

=== redirector example.com/foo/bar
--- uri
http://localhost/rd/example.com/foo/bar

--- response
Location: http://example.com/foo/bar
Content-Length: 0
Content-Type: text/html; charset=utf-8
Status: 302

=== redirector example.com/foo/bar?a=b&c=%20
--- uri
http://localhost/rd/example.com/foo/bar?a=b&c=%20

--- response
Location: http://example.com/foo/bar?a=b&c=%%20
Content-Length: 0
Content-Type: text/html; charset=utf-8
Status: 302

=== ovreride finalize
--- app_class
t::WAFTest2
--- uri
http://localhost/
--- response
--- response
Content-Length: 5
Content-Type: text/html; charset=utf-8
Status: 200
X-Override-Finalize: ok

index

