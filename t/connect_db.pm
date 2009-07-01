package connect_db;
use DBI;
use strict;
unlink "t/tmp/test.sqlite";
my $dbh = DBI->connect(
    'dbi:SQLite:dbname=t/tmp/test.sqlite', '', '',
    { RaiseError => 1, AutoCommit => 1 },
);
