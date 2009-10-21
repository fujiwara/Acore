# -*- mode:perl -*-
use strict;
use Test::More tests => 33;
use Test::Exception;
use Data::Dumper;
use utf8;

BEGIN {
    use_ok 'Acore::Easy';
};

can_ok "Acore::Easy", qw/ acore Dump init log reset config /;
unlink "t/tmp/test.sqlite";
my $base_config = {
    dsn => [
        "dbi:SQLite:dbname=t/tmp/test.sqlite",
        "",
        "",
        { RaiseError => 1, AutoCommit => 1 },
    ],
};
my $config_local = Storable::dclone($base_config);
$config_local->{dsn}->[3]->{AutoCommit} = 0;

Acore::YAML::DumpFile("t/tmp/config.yaml"       => $base_config);
Acore::YAML::DumpFile("t/tmp/config_local.yaml" => $config_local);

my $config;
sub run(&) {
    $config = Storable::dclone($base_config);
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

run {
    init($config);
    isa_ok acore() => "Acore";
    is user_class() => "Acore::User";
};

run {
    $config->{user_class} = "t::MyUser";
    init($config);
    isa_ok acore() => "Acore";
    is user_class() => "t::MyUser";
};

run {
    init($config);
    is log->level => "info";
    log->debug("debug");
    log->error("error");
    log->info("info");
};

run {
    $config->{log}->{level} = "debug";
    init($config);
    is log->level => "debug";
    log->debug("debug");
    log->error("error");
    log->info("info");
};


unlink "t/tmp/config.yaml";
unlink "t/tmp/config_local.yaml";
unlink "t/tmp/test.sqlite";
