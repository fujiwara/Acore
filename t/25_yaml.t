# -*- mode:perl -*-
use strict;
use Test::More tests => 8;
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

my @data = [
    { foo => [ 1, 2, 3 ], bar => { baz => "foo" } },
    { foo => "日本語" },
];
for my $data (@data) {
    my $yaml = Dump($data);
    ok utf8::is_utf8($yaml), "utf8 flagged";
    is_deeply Load($yaml) => $data, "roundtrip ok";
}

my $class = Acore::YAML->class;
ok $class, "loaded class is $class";
