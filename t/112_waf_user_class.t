# -*- mode:perl -*-
use strict;
use warnings;
use HTTP::Request;
use Data::Dumper;
use Test::More tests => 12;

use_ok("HTTP::Engine");
use_ok("Acore::WAF");
use_ok("t::WAFTest");

t::WAFTest->setup();
my $config = {
    dsn  => [
        'dbi:SQLite:dbname=t/tmp/test.sqlite', '', '',
        { RaiseError => 1, AutoCommit => 1 },
    ],
};

for my $class ( undef, "t::MyUser" ) {
    $config->{user_class} = $class;
    my $app = t::WAFTest->new({ config => $config });
    isa_ok $app => "t::WAFTest";
    isa_ok $app => "Acore::WAF";
    isa_ok $app->acore => "Acore";
    is $app->acore->user_class => $class || "Acore::User";
}

ok $INC{"t/MyUser.pm"}, "t::MyUser required";
