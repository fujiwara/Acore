# -*- mode:perl -*-
use strict;
use Test::More tests => 14;
use Test::Exception;
use Data::Dumper;
my $dbh = require t::connect_db;

BEGIN {
    use_ok 'Acore';
};

{
    my $ac = Acore->new({ dbh => $dbh, setup_db => 1, });
    isa_ok $ac => "Acore";
    isa_ok $ac->storage => "Acore::Storage";
    ok $ac->can('create_user'), "can create_user";
    ok $ac->can('authenticate_user'), "can authenticate_user";

    throws_ok { $ac->create_user() } qr/name/, "name is required";
    my $u = $ac->create_user({ name => "foo", xxx => "yyy" });
    isa_ok $u => "Acore::User";
    ok $u->add_role("Admin");
    ok $u->set_password("secret");
    ok $ac->save_user($u);

    ok !$ac->authenticate_user();
    ok !$ac->authenticate_user({ name => time });

    ok !$ac->authenticate_user({ name => "foo", password => "xxx" });
    my $u2;
    ok $u2 = $ac->authenticate_user({ name => "foo", password => "secret" });
}

$dbh->commit;
