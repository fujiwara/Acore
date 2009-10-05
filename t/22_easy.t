# -*- mode:perl -*-
use strict;
use Test::More tests => 22;
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
my $config_local = Storable::dclone($config);
$config_local->{dsn}->[3]->{AutoCommit} = 0;

YAML::DumpFile("t/tmp/config.yaml"       => $config);
YAML::DumpFile("t/tmp/config_local.yaml" => $config_local);

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
    ok $acore->dbh->{AutoCommit}, "AutoCommit on by config";
}

undef $Acore::Easy::Acore;
{
    my $acore = acore("t/tmp/config.yaml", "t/tmp/config_local.yaml");
    isa_ok $acore => "Acore";
    ok $acore->dbh->ping;
    ok !$acore->dbh->{AutoCommit}, "AutoCommit off by config_local";
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

undef $Acore::Easy::Acore;
{
    $ENV{CONFIG} = "t/tmp/config.yaml";
    my $acore = acore();
    isa_ok $acore => "Acore";
    ok $acore->dbh->ping;
    ok $acore->dbh->{AutoCommit}, "AutoCommit on by config";
}

undef $Acore::Easy::Acore;
{
    $ENV{CONFIG}       = "t/tmp/config.yaml";
    $ENV{CONFIG_LOCAL} = "t/tmp/config_local.yaml";
    my $acore = acore();
    isa_ok $acore => "Acore";
    ok $acore->dbh->ping;
    ok !$acore->dbh->{AutoCommit}, "AutoCommit off by config_local";
}

undef $Acore::Easy::Acore;
{
    init($config);
    my $acore = acore;
    is acore() => $acore, "same instance";
    isnt init($config) => $acore, "other instance";
}

unlink "t/tmp/config.yaml";
unlink "t/tmp/config_local.yaml";
unlink "t/tmp/test.sqlite";
