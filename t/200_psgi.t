# -*- mode:perl -*-
use strict;
use warnings;
use Plack::Test;
use Test::More;

use_ok("t::WAFTest");

my $psgi_app = t::WAFTest->psgi_application({});
isa_ok $psgi_app => "CODE";

test_psgi
    app    => $psgi_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new( GET => "http://localhost/act/psgi" );
        my $res = $cb->($req);
        like $res->content, qr/psgi\./;
    };

done_testing;
