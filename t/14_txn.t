# -*- mode:perl -*-
use strict;
use Test::More;
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

    {
        my $txn = $ac->txn;
        isa_ok($txn, "Acore::Transaction");

        ok $ac->put_document( Acore::Document->new({ id => 1 }) );
        ok $ac->put_document( Acore::Document->new({ id => 2 }) );
        @docs = (
            $ac->get_document({ id => 1 }),
            $ac->get_document({ id => 2 }),
        );
        ok @docs == 2;
        is $docs[0]->id => 1;
        is $docs[1]->id => 2;
        ok $txn->commit;
    }

    throws_ok {
        my $txn2 = $ac->txn;
        ok $ac->put_document( Acore::Document->new({ id => 3 }) );
        ok $ac->put_document( Acore::Document->new({ id => 4 }) );
        die "died";
        $txn2->commit;
    } qr/died/;

    {
        my $txn = $ac->txn;
        ok $ac->put_document( Acore::Document->new({ id => 5 }) );
        ok $txn->rollback;
    }

    @docs = map { $ac->get_document({ id => $_ }) } (1..5);
    ok @docs == 2;
    is $docs[0]->id => 1;
    is $docs[1]->id => 2;
}

done_testing;
