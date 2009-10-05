# -*- mode:perl -*-
use strict;
use Test::More tests => 10;
use Test::Exception;
use Data::Dumper;
use utf8;

BEGIN {
    use_ok 'Acore::CLI::Loader';
};

can_ok "Acore::CLI::Loader", "acore", "Dump";

my $config = {
    dsn => [
        "dbi:SQLite:dbname=t/tmp/test.sqlite",
        "",
        "",
        { RaiseError => 1, AutoCommit => 1 },
    ],
};
YAML::DumpFile("t/tmp/config.yaml" => $config);

{
    my $acore = acore($config);
    isa_ok $acore => "Acore";
    ok $acore->dbh->ping;
}

{
    my $acore = acore("t/tmp/config.yaml");
    isa_ok $acore => "Acore";
    ok $acore->dbh->ping;
}

{
    $ENV{CONFIG} = "t/tmp/config.yaml";
    my $acore = acore();
    isa_ok $acore => "Acore";
    ok $acore->dbh->ping;
}

delete $ENV{CONFIG};
throws_ok {
    acore();
} qr/./, "no config";

throws_ok {
    acore("t/tmp/noconfig.yaml");
} qr/./, "no config";


unlink "t/tmp/config.yaml";

