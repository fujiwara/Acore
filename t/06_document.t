# -*- mode:perl -*-
use strict;
use Test::More tests => 14;
use Test::Exception;
use Data::Dumper;
my $dbh = require t::connect_db;

BEGIN {
    use_ok 'Acore';
    use_ok 'Acore::Document';
};

{
    my $ac = Acore->new({ dbh => $dbh, setup_db => 1, });
    isa_ok $ac => "Acore";

    ok $ac->can('get_document'), "can get_document";
    ok $ac->can('put_document'), "can put_document";

    my $doc = $ac->put_document( Acore::Document->new({
        path => "/foo/bar/baz",
        body => "This is a document.",
    }) );
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
}

$dbh->commit;
