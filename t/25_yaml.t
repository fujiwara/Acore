# -*- mode:perl -*-
use strict;
use Test::More tests => 10;
use Test::Exception;
use utf8;

BEGIN {
    use_ok 'Acore::YAML';
};
Acore::YAML->import();
my @data = (
    { foo => [ 1, 2, 3 ], bar => { baz => "あいうえお" } },
    { foo => "日本語" },
);
for my $data (@data) {
    my $yaml = Dump($data);
    ok utf8::is_utf8($yaml), "utf8 flagged";
    is_deeply Load($yaml) => $data, "roundtrip";

    ok DumpFile("t/tmp/test.yaml", $data), "DumpFile";
    is_deeply LoadFile("t/tmp/test.yaml") => $data, "roundtrip file";
    unlink "t/tmp/test.yaml";
}

my $class = Acore::YAML->class;
ok $class, "loaded class is $class";

