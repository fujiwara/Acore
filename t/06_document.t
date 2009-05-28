# -*- mode:perl -*-
use strict;
use Test::More tests => 50;
use Test::Exception;
use Data::Dumper;
use t::Cache;

BEGIN {
    use_ok 'Acore';
    use_ok 'Acore::Document';
};

for my $cache ( undef, t::Cache->new({}) )
{
    my $dbh = do "t/connect_db.pm";
    my $ac  = Acore->new({ dbh => $dbh });
    $ac->setup_db;

    isa_ok $ac => "Acore";
    $ac->cache($cache);

    ok $ac->can('get_document'), "can get_document";
    ok $ac->can('put_document'), "can put_document";

    my $o = Acore::Document->new({
        path => "/foo/bar/baz",
        body => "This is a document.",
    });
    my $doc = $ac->put_document($o);

    ok $doc, "result doc";
    isa_ok $doc => "Acore::Document";
    ok $doc->id, "has id";
    is $doc->path => "/foo/bar/baz", "path ok";
    is $doc->{body} => "This is a document.", "body ok";

    my $doc2 = $ac->get_document({ id => $doc->id });
    is_deeply $doc2 => $doc, "same object";

    my $doc3 = $ac->get_document({ path => "/foo/bar/baz" });
    is_deeply $doc3 => $doc, "same object";

    ok ! $ac->get_document({ path => "not_found" });
    ok ! $ac->get_document({ id   => 0 });

    my $doc4 = $ac->put_document( Acore::Document->new({
        path => "/foo/boo",
        body => "This is a document boo.",
    }) );
    my @docs = $ac->search_documents({ path => "/foo/" });
    isa_ok $_ => "Acore::Document" for @docs;
    is_deeply $docs[0] => $doc;
    is_deeply $docs[1] => $doc4;

    my $updated_on  = $docs[0]->updated_on;
    sleep 1;
    my $updated_doc = $ac->put_document($docs[0]);
    ok $updated_doc->updated_on > $updated_on, "update timestamp";

    my $id = $ac->new_document_id;
    ok $id;
    ok $id != $ac->new_document_id, "different id";

    my @doc = $ac->all_documents;
    is_deeply \@doc => [
        $ac->get_document({ id => $doc->id }),
        $ac->get_document({ id => $doc4->id }),
    ];

    @doc = $ac->get_documents_by_id( $doc->id );
    is_deeply \@doc => [
        $ac->get_document({ id => $doc->id }),
    ];

    my $doc5 = $ac->put_document( Acore::Document->new({
        path => "/foo/baz",
        body => "This is a document baz.",
    }) );

    @doc = $ac->get_documents_by_id( $doc->id, $doc5->id );

    is_deeply \@doc => [
        $ac->get_document({ id => $doc->id }),
        $ac->get_document({ id => $doc5->id }),
    ];

    {
        my $id = $doc->id;
        ok $ac->delete_document($doc);
        ok !$ac->get_document({ id => $doc->id }),
    }

    $dbh->commit;
}

