# -*- mode:perl -*-
use strict;
use Test::More tests => 13;
use Test::Exception;
use Data::Dumper;
use utf8;

package SennaDocument;
use Any::Moose;
extends 'Acore::Document';
with 'Acore::Document::Role::FullTextSearch';

package main;

BEGIN {
    use_ok 'Acore';
    use_ok 'Acore::Document';
};

{
    my $dbh = do "t/connect_db.pm";
    my $ac  = Acore->new({ dbh => $dbh });
    $ac->senna_index_path("t/tmp/senna");
    $ac->init_senna_index;
    $ac->setup_db;

    isa_ok $ac => "Acore";

    ok $ac->put_document( SennaDocument->new({
        path       => "/foo/bar/baz",
        body       => "This is a document.",
        for_search => "test document",
    }));

    my $doc = SennaDocument->new({
        path       => "/foo/bar/baz",
        body       => "This is a document.",
        for_search => "全文検索にヒットしてください",
    });

    can_ok $doc => qw/ create_fts_index update_fts_index delete_fts_index
                       for_search /;

    ok $doc = $ac->put_document($doc);
    my @docs;
    @docs = $ac->fulltext_search_documents({ query => "全文検索" });
    ok @docs;
    ok $_->for_search =~ /全文検索/ for @docs;

    $doc->for_search('部分一致検索にヒットしてください');
    ok $ac->put_document($doc);

    @docs = $ac->fulltext_search_documents({ query => "全文検索" });
    ok @docs == 0;

    @docs = $ac->fulltext_search_documents({ query => "部分一致" });
    ok @docs == 1;

    ok $ac->delete_document($doc);
    @docs = $ac->fulltext_search_documents({ query => "部分一致" });
    ok @docs == 0;
}

