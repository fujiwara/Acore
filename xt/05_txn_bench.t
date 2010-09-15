#!perl
use strict;
use Benchmark qw/:all/;
use Acore;
use Acore::Document;
use Test::More;

plan skip_all => "Set TEST_BENCH environment variable to run this test"
    unless $ENV{TEST_BENCH};

my @doc = map { Acore::Document->new({ path => "/$_" }) } ( 1 .. 10 );
my $acore;

my $benchmarks = {
    put => sub {
        $acore->put_document($_) for @doc;
    },
    put_multi => sub {
        $acore->put_document_multi(@doc);
    },
    txn_put => sub {
        $acore->txn_do(
            sub { $acore->put_document($_) for @doc; }
        );
    },
    txn_put_multi => sub {
        $acore->txn_do(
            sub { $acore->put_document_multi(@doc); }
        );
    },
};

for my $auto ( 0, 1 ) {
    note "Acore->auto_transaction: $auto\n";
    my $result = {};
    for my $name (sort keys %$benchmarks) {
        $acore = init();
        $acore->auto_transaction($auto);
        $result->{$name} = timethis(100, $benchmarks->{$name}, $name);
    }
    cmpthese $result;
}


done_testing;

sub init {
    my $dbh   = do "t/connect_db.pm";
    my $acore = Acore->new({ dbh => $dbh });
    $acore->setup_db;
    $acore;
}
