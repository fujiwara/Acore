# -*- mode:perl -*-
use strict;
use Test::More tests => 12;
use Test::Exception;
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

SKIP: {
    skip "Senna is not installed.", 10 unless eval { require Senna };
    my @docs;
    my $dbh = do "t/connect_db.pm";
    my $ac  = Acore->new({ dbh => $dbh });
    $ac->senna_index_path("t/tmp/senna");
    $ac->init_senna_index;
    $ac->setup_db;

    $ac->put_document( SennaDocument->new({ id => $_, for_search => "test " x $_ }) )
        for ( 1 .. 10 );

    @docs = $ac->fulltext_search_documents({ query => "test" });
    is scalar @docs => 10;
    is_deeply [ map { $_->id } @docs ] => [ reverse (1 .. 10) ];

    @docs = $ac->fulltext_search_documents({ query => "test", limit => 5 });
    is scalar @docs => 5;
    is_deeply [ map { $_->id } @docs ] => [ reverse (6 .. 10) ];

    @docs = $ac->fulltext_search_documents({ query => "test", offset => 3, limit => 3 });
    is scalar @docs => 3;
    is_deeply [ map { $_->id } @docs ] => [ reverse (5 .. 7) ];

    @docs = $ac->fulltext_search_documents({ query => "test", offset => 8 });
    is scalar @docs => 2;
    is_deeply [ map { $_->id } @docs ] => [ reverse (1 .. 2) ];

    @docs = $ac->fulltext_search_documents({ query => "test", offset => 8, limit => 10 });
    is scalar @docs => 2;
    is_deeply [ map { $_->id } @docs ] => [ reverse (1 .. 2) ];
}

