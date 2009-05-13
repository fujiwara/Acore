# -*- mode:perl -*-
use strict;
use warnings;
use Test::Base;
use HTTP::Request;
use Data::Dumper;

plan tests => (3 + 1 * blocks);

filters {
    response => [qw/chop/],
};

use_ok("HTTP::Engine");
use_ok("Acore::WAF");
use_ok("t::WAFTest");

run {
    my $block = shift;

    my $req = HTTP::Request->new( GET => $block->uri );
    $req->protocol('HTTP/1.0');
    my @res_args = $block->preprocess ? eval $block->preprocess : ();
    die $@ if $@;

    my $config = { root => "t" };
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

__END__

===
--- uri
http://localhost/
--- response
Content-Length: 5
Content-Type: text/html
Status: 200

index

===
--- uri
http://localhost/act/ok
--- response
Content-Length: 2
Content-Type: text/html
Status: 200

ok

===
--- uri
http://localhost/act/ng
--- response
Content-Length: 10
Content-Type: text/html
Status: 404

Not found.

===
--- uri
http://localhost/ng
--- response
Content-Length: 10
Content-Type: text/html
Status: 404

Not found.

===
--- uri
http://localhost/static/not_found.txt
--- response
Content-Length: 10
Content-Type: text/html
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
Content-Type: text/plain
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
Content-Type: text/html
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
Content-Type: text/html
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
Content-Type: text/plain
Last-Modified: %s
Status: 200

0123456789

===
--- uri
http://localhost/act/rd
--- response
Location: http://localhost/redirect_to
Content-Length: 0
Content-Type: text/html
Status: 302
