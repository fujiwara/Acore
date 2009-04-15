package connect_db;
use DBI;
use strict;
unlink "t/test.sqlite";
my $dbh = DBI->connect(
    'dbi:SQLite:dbname=t/test.sqlite', '', '',
    { RaiseError => 1, AutoCommit => 0 },
);
