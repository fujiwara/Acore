# -*- mode:perl -*-
use strict;
use Test::More tests => 7;

BEGIN {
    use_ok 'Acore::Storage';
    use_ok 'DBI';
};

{
    my $db  = "t/tmp/test.sqlite";
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db");
    my $s = Acore::Storage->new({ dbh => $dbh });
    isa_ok $s => "Acore::Storage";
    is $s->dbh => $dbh;
    isa_ok $s->user     => "DBIx::CouchLike";
    isa_ok $s->document => "DBIx::CouchLike";
    ok unlink $db;
}

