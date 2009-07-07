#!perl
use strict;
use Benchmark qw/:all/;
use Acore::Document;
use Test::More;

plan skip_all => "Set TEST_BENCH environment variable to run this test"
    unless $ENV{TEST_BENCH};

plan tests => 1;

my $doc = Acore::Document->new({
    foo => 1,
    bar => {
        baz => 2,
    },
    list => [ 3, 4, 5 ],
});
ok $doc;
my $v;
cmpthese timethese( 0, {
    normal_get => sub {
        $v = $doc->{foo};
        $v = $doc->{bar}->{baz};
        $v = $doc->{list}->[1];
    },
    xpath_get => sub {
        $v = $doc->xpath->get('/foo');
        $v = $doc->xpath->get('/bar/baz');
        $v = $doc->xpath->get('/list[1]');
    },
    normal_set => sub {
        $doc->{foo}        = 1;
        $doc->{bar}->{baz} = 2;
        $doc->{list}->[1]  = 4;
    },
    xpath_set => sub {
        $doc->xpath->set('/foo'     => 1);
        $doc->xpath->set('/bar/baz' => 2);
        $doc->xpath->set('/list[1]' => 4);
    },
});

