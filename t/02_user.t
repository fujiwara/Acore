# -*- mode:perl -*-
use strict;
use Test::More tests => 35;
use Data::Dumper;

BEGIN {
    use_ok 'Acore::User';
};

{
    my $u = Acore::User->new({ name => "foo" });
    ok $u->init;
    is $u->name => "foo", "name is set";
    ok $u->has_role("Reader"), "has_role Reader";
    ok $u->has_authentication("Password"), "has_authentication Password";
    ok $u->can('set_password'), "can set_password";
    ok $u->set_password('bar');
    ok $u->can('password'), "can password";
    ok $u->can('authenticate'), "can authenticate";
    ok $u->authenticate({ password => "bar" });
}

{
    my $u = Acore::User->new({ name => "foo" });
    ok $u->init;
    is $u->name => "foo", "name is set";
    for my $r (qw/ Foo Bar /) {
        ok $u->add_role($r), "add role $r";
        ok $u->has_role($r), "has role $r";
        ok $u->delete_role($r), "delete role $r";
        ok !$u->has_role($r), "hasn't role $r";
    }
    for my $r (qw/ Foo Bar /) {
        ok $u->add_authentication($r), "add authentication $r";
        ok $u->has_authentication($r), "has authentication $r";
        ok $u->delete_authentication($r), "delete authentication $r";
        ok !$u->has_authentication($r), "hasn't authentication $r";
    }
}

{
    my $u = Acore::User->new({ name => "foo" });
    $u->init;
    $u->set_password('foo');
    is_deeply [ $u->attributes ], [], "attributes";

    $u->{email} = 'foo@example.com';
    is_deeply [ $u->attributes ], [qw/ email /], "attributes added";
    is $u->attr("email") => 'foo@example.com';
    is $u->attr("name")  => "foo";
    ok $u->attr("email", 'foo@example.jp');
    is $u->attr("email") => 'foo@example.jp';

    is $u->attr($_) => $u->attribute($_)
        for $u->attributes;
}
