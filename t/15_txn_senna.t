# -*- mode:perl -*-
use strict;
use Test::More tests => 10;
use Test::Exception;
use Data::Dumper;
use utf8;

BEGIN {
    use_ok 'Acore';
    use_ok 'Acore::Document';
};

package SennaDocument;
use Any::Moose;
extends 'Acore::Document';
with 'Acore::Document::Role::FullTextSearch';

package main;
{
    my @docs;
    my $dbh = do "t/connect_db.pm";
    my $ac  = Acore->new({ dbh => $dbh });
    $ac->senna_index_path("t/tmp/senna");
    $ac->init_senna_index;
    $ac->setup_db;

    $ac->txn_do(sub {
        $ac->put_document(
            SennaDocument->new({ id => 1, for_search => "foo" })
        );
        $ac->put_document(
            SennaDocument->new({ id => 2, for_search => "bar" })
        );
    });
    @docs = $ac->fulltext_search_documents({ query => "foo" });
    ok @docs == 1;
    is $docs[0]->id => 1;

    throws_ok( sub {
        $ac->txn_do(
            sub {
                $ac->put_document(
                    SennaDocument->new({ id => 3, for_search => "baz" })
                );
                $ac->put_document(
                    SennaDocument->new({ id => 4, for_search => "bar" })
                );
                $ac->put_document(
                    SennaDocument->new({ id => 1, for_search => "xxx" })
                );
                die "died";
            });
    }, qr{died} );

    @docs = $ac->fulltext_search_documents({ query => "baz" });
    ok @docs == 0;

    @docs = $ac->fulltext_search_documents({ query => "bar" });
    ok @docs == 1;
    is $docs[0]->id => 2;

    @docs = $ac->fulltext_search_documents({ query => "foo" });
    ok @docs == 1;
    is $docs[0]->id => 1;
}

