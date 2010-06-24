# -*- mode:perl -*-
use strict;
use Test::More;
use Test::Exception;
use Test::Requires qw/ Senna /;
use Data::Dumper;
use utf8;

package SennaDocument;
use Any::Moose;
extends 'Acore::Document';
has for_search => ( is => "rw" );
with 'Acore::Document::Role::FullTextSearch';

package main;

BEGIN {
    use_ok 'Acore';
    use_ok 'Acore::Document';
};

{
    my @docs;
    my $dbh = do "t/connect_db.pm";
    my $ac  = Acore->new({ dbh => $dbh });
    $ac->senna_index_path("t/tmp/senna");
    $ac->init_senna_index;
    $ac->setup_db;

    isa_ok $ac => "Acore";

    ok $ac->put_document( SennaDocument->new({
        id         => 9999,
        path       => "/foo/bar/baz",
        body       => "This is a document.",
        for_search => "test document",
    }));
    ok !$ac->{lock_senna_index};

    @docs = $ac->fulltext_search_documents({ query => "test" });
    ok @docs == 1;
    is $docs[0]->id => 9999;

    my $doc = SennaDocument->new({
        path       => "/foo/bar/baz",
        body       => "This is a document.",
        for_search => "全文検索にヒットしてください",
    });

    can_ok $doc => qw/ create_fts_index update_fts_index delete_fts_index
                       for_search /;

    ok $doc = $ac->put_document($doc);
    @docs = $ac->fulltext_search_documents({ query => "全文検索" });
    ok @docs == 1;
    ok $docs[0]->for_search =~ /全文検索/;

    $doc->for_search('部分一致検索にヒットしてください');
    ok $ac->put_document($doc);

    @docs = $ac->fulltext_search_documents({ query => "全文検索" });
    ok @docs == 0;

    @docs = $ac->fulltext_search_documents({ query => "部分一致" });
    ok @docs == 1;

    $doc->xpath->set('/for_search' => 'Senna検索にヒットしてください');
    ok $ac->put_document($doc);

    @docs = $ac->fulltext_search_documents({ query => "Senna検索" });
    ok @docs == 1;

    @docs = $ac->fulltext_search_documents({ query => "部分一致" });
    ok @docs == 0;

    ok $ac->delete_document($doc);
    @docs = $ac->fulltext_search_documents({ query => "Senna検索" });
    ok @docs == 0;
}

done_testing;
