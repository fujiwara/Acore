# -*- mode:perl -*-
use strict;
use Test::More tests => 7;
use Test::Exception;
use utf8;

BEGIN {
    use_ok 'Acore::YAML';
};
Acore::YAML->import();

ok \&Dump, "Dump is exported";
ok \&Load, "Load is exported";
ok \&DumpFile, "DumpFile is exported";
ok \&LoadFile, "LoadFile is exported";

my $data = { foo => [ 1, 2, 3 ], bar => { baz => "foo" } };
my $yaml = Dump($data);
is_deeply Load($yaml) => $data, "roundtrip ok";

my $class = Acore::YAML->class;
ok $class, "loaded class is $class";
