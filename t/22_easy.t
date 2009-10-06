# -*- mode:perl -*-
use strict;
use Test::More tests => 27;
use Test::Exception;
use Data::Dumper;
use utf8;

BEGIN {
    use_ok 'Acore::Easy';
};

can_ok "Acore::Easy", qw/ acore Dump init log reset config /;
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

sub run(&) {
    reset;
    $_[0]->();
}

run {
    my $acore = acore($config);
    isa_ok $acore => "Acore";
    ok $acore->dbh->ping;
};

run {
    my $acore = acore("t/tmp/config.yaml");
    isa_ok $acore => "Acore";
    ok $acore->dbh->ping;
    ok $acore->dbh->{AutoCommit}, "AutoCommit on by config";
};

run {
    my $acore = acore("t/tmp/config.yaml", "t/tmp/config_local.yaml");
    isa_ok $acore => "Acore";
    ok $acore->dbh->ping;
    ok !$acore->dbh->{AutoCommit}, "AutoCommit off by config_local";
};

run {
    throws_ok {
        acore();
    } qr/./, "no config";
};

run {
    throws_ok {
        acore("t/tmp/noconfig.yaml");
    } qr/./, "no config";
};

run {
    $ENV{CONFIG} = "t/tmp/config.yaml";
    my $acore = acore();
    isa_ok $acore => "Acore";
    ok $acore->dbh->ping;
};

run {
    $ENV{CONFIG} = "t/tmp/config.yaml";
    my $acore = acore();
    isa_ok $acore => "Acore";
    ok $acore->dbh->ping;
    ok $acore->dbh->{AutoCommit}, "AutoCommit on by config";
};

run {
    $ENV{CONFIG}       = "t/tmp/config.yaml";
    $ENV{CONFIG_LOCAL} = "t/tmp/config_local.yaml";
    my $acore = acore();
    isa_ok $acore => "Acore";
    ok $acore->dbh->ping;
    ok !$acore->dbh->{AutoCommit}, "AutoCommit off by config_local";
};

run {
    init($config);
    my $acore = acore;
    is acore() => $acore, "same instance";
    isnt init($config) => $acore, "other instance";
};

run {
    init($config);
    is_deeply $config => config(), "same config";
    isa_ok log() => "Acore::WAF::Log";
    ok log->error("error log");
    ok log->info("info log");
    my $now = now;
    ok $now, "$now";
};

unlink "t/tmp/config.yaml";
unlink "t/tmp/config_local.yaml";
unlink "t/tmp/test.sqlite";
