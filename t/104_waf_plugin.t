# -*- mode:perl -*-
use strict;
use warnings;
use Test::Base;
use HTTP::Request;
use Data::Dumper;
use t::WAFTest::Engine;

plan tests => (2 + 1 * blocks);

filters {
    response => [qw/chop/],
};

use_ok("Acore::WAF");
use_ok("t::WAFTest");
my $Engine = create_engine;
my $config = { root => "t" };
my $ctx    = {};
run {
    my $block = shift;
    run_engine_test($config, $block, $ctx);
};

__END__

===
--- uri
http://localhost/
--- response
Content-Length: 5
Content-Type: text/html; charset=utf-8
Status: 200

index

