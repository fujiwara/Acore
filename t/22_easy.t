# -*- mode:perl -*-
use strict;
use Test::More tests => 10;
use Test::Exception;
use Data::Dumper;
use utf8;

BEGIN {
    use_ok 'Acore::Easy';
};

can_ok "Acore::Easy", qw/ acore Dump init /;
unlink "t/tmp/test.sqlite";
my $config = {
    dsn => [
        "dbi:SQLite:dbname=t/tmp/test.sqlite",
        "",
        "",
        { RaiseError => 1, AutoCommit => 1 },
    ],
};
YAML::DumpFile("t/tmp/config.yaml" => $config);

undef $Acore::Easy::Acore;
{
    my $acore = acore($config);
    isa_ok $acore => "Acore";
    ok $acore->dbh->ping;
}

undef $Acore::Easy::Acore;
{
    my $acore = acore("t/tmp/config.yaml");
    isa_ok $acore => "Acore";
    ok $acore->dbh->ping;
}

undef $Acore::Easy::Acore;
throws_ok {
    acore();
} qr/./, "no config";

undef $Acore::Easy::Acore;
throws_ok {
    acore("t/tmp/noconfig.yaml");
} qr/./, "no config";

undef $Acore::Easy::Acore;
{
    $ENV{CONFIG} = "t/tmp/config.yaml";
    my $acore = acore();
    isa_ok $acore => "Acore";
    ok $acore->dbh->ping;
}

unlink "t/tmp/config.yaml";
unlink "t/tmp/test.sqlite";
