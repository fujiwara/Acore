#!perl
use strict;
use Benchmark qw/:all/;
use Acore::Document;
use Test::More qw/ no_plan /;

my $doc = Acore::Document->new({
    foo => 1,
    bar => {
        baz => 2,
    },
    list => [ 3, 4, 5 ],
});
ok $doc;

cmpthese timethese( 0, {
    normal_get => sub {
        $doc->{foo};
        $doc->{bar}->{baz};
        $doc->{list}->[1];
    },
    xpath_get => sub {
        $doc->xpath->get('/foo');
        $doc->xpath->get('/bar/baz');
        $doc->xpath->get('/list[1]');
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

