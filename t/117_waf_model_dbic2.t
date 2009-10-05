# -*- mode:perl -*-
use strict;
use Test::More;
use HTTP::Engine::Test::Request;
use Scalar::Util qw/ blessed /;

BEGIN {
    eval { use DBIx::Class::Schema::Loader };
    plan $@ ? (skip_all => "DBIx::Class::Schema::Loader in not installed") : (tests => 8);

    use_ok "Acore";
    use_ok 'Acore::WAF';
    use_ok 't::WAFTest';
    use_ok 'HTTP::Engine';
};

my $dbh = do "t/connect_db.pm";
$dbh->do("CREATE TABLE foo (id integer primary key, foo text)");

my $c = t::WAFTest->new;
my $req = HTTP::Engine::Test::Request->new(
    uri    => 'http://example.com/',
    method => "GET",
);
$c->request($req);
$c->config({
    include_path => [],
    dsn => [
         'dbi:SQLite:dbname=t/tmp/test.sqlite',
         '',
         '',
         { RaiseError => 1, AutoCommit => 1 },
    ],
    "Model::DBIC" => {
        schema_class => "t::MySchema",
    },
});

{
    my $schema = $c->model('DBIC')->schema;
    isa_ok $schema => "t::MySchema";
    my $foo = $schema->resultset("Foo")->create({ foo => "FOO" });
    ok $foo;
    is $foo->foo => "FOO";
    my $id = $foo->id;

    is $schema->storage->dbh => $c->acore->dbh, "same dbh";
}
