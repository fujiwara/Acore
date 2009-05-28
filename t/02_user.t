# -*- mode:perl -*-
use strict;
use Test::More tests => 28;
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
