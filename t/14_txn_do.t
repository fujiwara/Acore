# -*- mode:perl -*-
use strict;
use Test::More tests => 9;
use Test::Exception;
use Data::Dumper;
use utf8;

BEGIN {
    use_ok 'Acore';
    use_ok 'Acore::Document';
};

{
    my @docs;
    my $dbh = do "t/connect_db.pm";
    my $ac  = Acore->new({ dbh => $dbh });
    $ac->setup_db;
    $ac->txn_do(sub {
        $ac->put_document( Acore::Document->new({ id => 1 }) );
        $ac->put_document( Acore::Document->new({ id => 2 }) );
    });
    @docs = (
        $ac->get_document({ id => 1 }),
        $ac->get_document({ id => 2 }),
    );
    ok @docs == 2;
    is $docs[0]->id => 1;
    is $docs[1]->id => 2;

    throws_ok( sub {
        $ac->txn_do(
            sub {
                $ac->put_document( Acore::Document->new({ id => 3 }) );
                $ac->put_document( Acore::Document->new({ id => 4 }) );
                die "died";
            }
        );
    }, qr{died} );

    @docs = map { $ac->get_document({ id => $_ }) } (1..4);
    ok @docs == 2;
    is $docs[0]->id => 1;
    is $docs[1]->id => 2;
}

