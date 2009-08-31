# -*- mode:perl -*-
use strict;
use Test::More tests => 11;
use HTTP::Engine::Test::Request;
use Scalar::Util qw/ blessed /;

BEGIN {
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
    "Model::DBIC" => {
        schema_class => "t::MySchema",
        connect_info => [
            'dbi:SQLite:dbname=t/tmp/test.sqlite',
            '',
            '',
        ]
    },
});

{
    my $schema = $c->model('DBIC')->schema;
    isa_ok $schema => "t::MySchema";
    my $foo = $schema->resultset("Foo")->create({ foo => "FOO" });
    ok $foo;
    is $foo->foo => "FOO";
    my $id = $foo->id;

    my $foo2 = $schema->resultset("Foo")->find($id);
    is $foo2->id  => $id;
    is $foo2->foo => "FOO";
    $foo2->foo("BAR");
    $foo2->update;

    my $foo3 = $c->model('DBIC')->rs("Foo")->find($id);
    is $foo3->id  => $id;
    is $foo3->foo => "BAR";
}
