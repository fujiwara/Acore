# -*- mode:perl -*-
use strict;
use Test::More tests => 27;
use Test::Exception;
use Data::Dumper;
use t::Cache;
use utf8;
use IO::Scalar;

BEGIN {
    use_ok 'Acore';
    use_ok 'Acore::DocumentLoader';
};

{
    my $dbh = do "t/connect_db.pm";
    my $ac  = Acore->new({ dbh => $dbh });
    $ac->setup_db;

    my $loader = Acore::DocumentLoader->new({ acore => $ac });
    isa_ok $loader => "Acore::DocumentLoader";
    is     $loader->acore => $ac;
    can_ok $loader, qw/ load has_error add_error debug /;
    is     $loader->loaded => 0;
    $loader->debug(1);

    my $source = source();
    $loader->load($source);
    ok !$loader->has_error, "no error";
    is $loader->loaded => 2;

    my $doc1 = $ac->get_document({ id => 1234 });
    is        $doc1->id => 1234;
    isa_ok    $doc1 => "Acore::Document";
    is        $doc1->foo => "bar";
    is_deeply $doc1->list => ['A', 'B', 'C'];

    my $doc2 = $ac->get_document({ path => "/FOO/BAR" });
    ok        $doc2->id;
    isa_ok    $doc2 => "t::MyDocument";
    is        $doc2->foo => "BAR";
    is_deeply $doc2->list => ['X', 'Y', 'Z'];

    $ac->delete_document($_) for ($doc1, $doc2);
    undef $doc1, $doc2;

    my $handle = IO::Scalar->new(\$source);
    $loader->load($handle);
    ok !$loader->has_error, "no error";
    is $loader->loaded => 2;

    $doc1 = $ac->get_document({ id => 1234 });
    is        $doc1->id => 1234;
    isa_ok    $doc1 => "Acore::Document";
    is        $doc1->foo => "bar";
    is_deeply $doc1->list => ['A', 'B', 'C'];

    $doc2 = $ac->get_document({ path => "/FOO/BAR" });
    ok        $doc2->id;
    isa_ok    $doc2 => "t::MyDocument";
    is        $doc2->foo => "BAR";
    is_deeply $doc2->list => ['X', 'Y', 'Z'];

    isa_ok $ac->document_loader => "Acore::DocumentLoader";
}

sub source {
<<'END'
---
id: 1234
_class: Acore::Document
foo: bar
path: /foo/bar
list:
  - A
  - B
  - C

---
_class: t::MyDocument
foo: BAR
path: /FOO/BAR
list:
  - X
  - Y
  - Z

END
}
