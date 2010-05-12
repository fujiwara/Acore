# -*- mode:perl -*-
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use HTTP::Engine::Test::Request;
use Scalar::Util qw/ blessed /;
use t::WAFTest::Engine;

BEGIN {
    eval "require DBIx::Skinny";
    plan $@ ? (skip_all => "DBIx::Skinny is not installed") : (tests => 13);

    use_ok "Acore";
    use_ok 'Acore::WAF';
    use_ok 't::WAFTest';
    use_ok 'HTTP::Engine';
};

my $dbh = do "t/connect_db.pm";
$dbh->do("CREATE TABLE foo (id integer primary key, foo text)");

my $c = t::WAFTest->new;
my $req = create_request(
    uri    => 'http://example.com/',
    method => "GET",
);
$c->request($req);

{
    $c->config({
        include_path => [],
        "Model::Skinny" => {
            connect_info => {
                dsn => 'dbi:SQLite:dbname=t/tmp/test.sqlite',
            },
        },
    });

    my $skinny = $c->model('Skinny');
    isa_ok $skinny->schema => "t::WAFTest::Model::Skinny::Schema";
    my $foo = $skinny->insert('foo' => { foo => 'FOO' });
    ok $foo;
    is $foo->foo => "FOO";
    my $id = $foo->id;

    my $foo2 = $skinny->single('foo' => { id => $id });
    is $foo2->id  => $id;
    is $foo2->foo => "FOO";
    $foo2->update({ foo => "BAR" });

    my $foo3 = $skinny->single('foo' => { id => $id });
    is $foo3->id  => $id;
    is $foo3->foo => "BAR";
}

{
    $c->config({
        dsn => [
            'dbi:SQLite:dbname=t/tmp/test.sqlite',
            '',
            '',
            { RaiseError => 1, AutoCommit => 1 },
        ],
    });

    my $skinny = $c->model('Skinny');
    my $foo = $skinny->insert('foo' => { foo => 'FOO' });
    ok $foo;
    is $foo->foo => "FOO";
}

