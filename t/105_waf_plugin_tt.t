# -*- mode:perl -*-
use strict;
use warnings;
use Test::Base;
use Test::More;
use HTTP::Request;
use Data::Dumper;
use Storable qw/ dclone /;
use t::WAFTest::Engine;

filters {
    response => [qw/chomp convert_charset/],
    method   => [qw/chomp/],
};

use_ok("Acore::WAF");
use_ok("t::WAFTestTT");

my $base_config = {
    root => "t",
    tt   => {},
};
my $ctx = {};

run {
    my $block  = shift;
    my $config = dclone $base_config;
    run_engine_test($config, $block, $ctx, "t::WAFTestTT");
};

done_testing;

__END__

=== /
--- uri
http://localhost/
--- response
Content-Length: 5
Content-Type: text/html; charset=utf-8
Status: 200

index

=== render
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

=== broken template
--- uri
http://localhost/act/render_broken_tt
--- handle_response
{
    is $response->code => 500;
}
