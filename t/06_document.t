# -*- mode:perl -*-
use strict;
use Test::More;
use Test::Exception;
use Data::Dumper;
use t::Cache;

BEGIN {
    use_ok 'Acore';
    use_ok 'Acore::Document';
};
{
    package MyDocument;
    use Any::Moose;
    extends 'Acore::Document';
}

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
    is $o->xpath->get('/body') => "This is a document.";
    my $doc = $ac->put_document($o);
    ok $doc, "result doc";
    isa_ok $doc => "Acore::Document";
    ok $doc->id, "has id";
    is $doc->path => "/foo/bar/baz", "path ok";
    is $doc->{body} => "This is a document.", "body ok";
    ok ! ref $doc->id, "id is not ref";

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
    is $ac->search_documents_count({ path => "/foo/" }) => 2;
    my %count_by_key
        = $ac->search_documents_count_by_key({ view => "path/all" });
    is_deeply \%count_by_key => { "/foo/bar/baz" => 1, "/foo/boo" => 1 };

    my $updated_on  = $docs[0]->updated_on;
    sleep 1;
    my $updated_doc = $ac->put_document($docs[0]);
    ok $updated_doc->updated_on > $updated_on, "update timestamp";

    my $id = $ac->new_document_id;
    ok $id;
    ok $id != $ac->new_document_id, "different id";
    ok !ref $id;

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

    my $mydoc = MyDocument->new({ foo => "bar" });
    isa_ok $mydoc => "MyDocument";
    $mydoc = $ac->put_document($mydoc);

    my $gotdoc = $ac->get_document({ id => $mydoc->id });
    ok $gotdoc;
    isa_ok $gotdoc => "MyDocument";

    $gotdoc = $ac->get_document({ id => $mydoc->id, isa => "Acore::Document" });
    ok $gotdoc;
    isa_ok $gotdoc => "Acore::Document";

    $gotdoc = $ac->get_document({ id => $mydoc->id, isa => "MyDocument" });
    ok $gotdoc;
    isa_ok $gotdoc => "MyDocument";

    $gotdoc = $ac->get_document({ id => $mydoc->id, isa => "SomeDocument" });
    ok !$gotdoc, "returns only is SomeDocument";
}

done_testing;
