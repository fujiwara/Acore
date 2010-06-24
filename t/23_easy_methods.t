# -*- mode:perl -*-
use strict;
use Test::More;
use Test::Exception;
use Data::Dumper;
use utf8;

BEGIN {
    use_ok 'Acore::Easy';
};

unlink "t/tmp/test.sqlite";
my $config = {
    dsn => [
        "dbi:SQLite:dbname=t/tmp/test.sqlite",
        "",
        "",
        { RaiseError => 1, AutoCommit => 1 },
    ],
};

my @methods
    = qw/ acore init Dump
          all_documents all_users authenticate_user
          cache create_user dbh delete_document
          delete_user document_loader
          fulltext_search_documents get_document get_documents_by_id
          get_user in_transaction init_senna_index lock_senna_index
          new_document_id put_document put_document_multi
          save_user search_documents search_documents_count
          search_documents_count_by_key senna_index senna_index_path
          setup_db storage transaction_data txn_do user_class /;
can_ok __PACKAGE__, @methods;

{
    ok init($config), "init ok";
    isa_ok acore, "Acore";
    is acore() => acore(), "same instance";

    ok setup_db, "setup_db";
    my $doc = Acore::Document->new({ id => 1, path => "/foo" });
    ok put_document($doc), "put_document";
    my $getdoc = get_document({ id => 1 });
    isa_ok $getdoc => "Acore::Document";
    is $getdoc->id => 1, "id is 1";
    is $getdoc->path => "/foo", "path is /foo";
}

unlink "t/tmp/test.sqlite";

done_testing;
