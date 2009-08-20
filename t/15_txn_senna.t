# -*- mode:perl -*-
use strict;
use Test::More tests => 19;
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
has  'for_search' => ( is => "rw" );
with 'Acore::Document::Role::FullTextSearch';

package main;
SKIP: {
    skip "Senna is not installed.", 17 unless eval { require Senna };
    my @docs;
    my $dbh = do "t/connect_db.pm";
    my $ac  = Acore->new({ dbh => $dbh });
    $ac->senna_index_path("t/tmp/senna");
    $ac->init_senna_index;
    $ac->setup_db;

    $ac->txn_do(sub {
        diag "begin transaction";
        ok !$ac->{lock_senna_index};
        $ac->put_document(
            SennaDocument->new({ id => 1, for_search => "foo" })
        );
        ok $ac->{lock_senna_index};
        $ac->put_document(
            SennaDocument->new({ id => 2, for_search => "bar" })
        );
    });
    ok !$ac->{lock_senna_index};

    @docs = $ac->fulltext_search_documents({ query => "foo" });
    ok @docs == 1;
    is $docs[0]->id => 1;

    throws_ok( sub {
        $ac->txn_do(
            sub {
                ok !$ac->{lock_senna_index};
                $ac->put_document(
                    SennaDocument->new({ id => 3, for_search => "baz" })
                );
                my $fh = $ac->{lock_senna_index};
                ok $fh;
                $ac->put_document(
                    SennaDocument->new({ id => 4, for_search => "bar" })
                );
                is $ac->{lock_senna_index} => $fh;
                $ac->put_document(
                    SennaDocument->new({ id => 1, for_search => "xxx" })
                );
                is $ac->{lock_senna_index} => $fh;
                $ac->put_document(
                    SennaDocument->new({ id => 1, for_search => "yyy" })
                );
                is $ac->{lock_senna_index} => $fh;
                die "died";
            });
    }, qr{died} );
    ok !$ac->{lock_senna_index};

    @docs = $ac->fulltext_search_documents({ query => "baz" });
    ok @docs == 0;

    @docs = $ac->fulltext_search_documents({ query => "bar" });
    ok @docs == 1;
    is $docs[0]->id => 2;

    @docs = $ac->fulltext_search_documents({ query => "foo" });
    ok @docs == 1;
    is $docs[0]->id => 1;
}

