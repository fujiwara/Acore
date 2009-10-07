# -*- mode:perl -*-
use strict;
use Test::More tests => 75;
use Test::Exception;
use Data::Dumper;
use t::Cache;

BEGIN {
    use_ok 'Acore';
};

for my $cache ( undef, t::Cache->new() )
{
    my $dbh = do "t/connect_db.pm";
    my $ac = Acore->new({ dbh => $dbh });
    $ac->setup_db;

    $ac->cache($cache);

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

    throws_ok { $ac->create_user({ name => "foo", xxx => "yyy" }) }
        qr/already exists/i, "user is is already exists";

    ok !$ac->authenticate_user();
    ok !$ac->authenticate_user({ name => time });

    ok !$ac->authenticate_user({ name => "foo", password => "xxx" });
    my $u2;
    ok $u2 = $ac->authenticate_user({ name => "foo", password => "secret" });

    my $u3 = $ac->get_user({ name => "foo" });
    isa_ok $u3 => "Acore::User";
    is $u3->name  => "foo";
    is $u3->{xxx} => "yyy";

    $u3->{xxx} = "zzz";
    ok $ac->save_user($u3);

    my $u4 = $ac->get_user({ name => "foo" });
    isa_ok $u4 => "Acore::User";
    is $u4->name  => "foo";
    is $u4->{xxx} => "zzz";

    my $u5 = $ac->create_user({ name => "bar", xxx => "www" });
    my @u = $ac->all_users;
    is $u[0]->name  => "bar";
    is $u[0]->{xxx} => "www";
    is $u[1]->name  => "foo";
    is $u[1]->{xxx} => "zzz";

    {
        # test for search_users_has_role
        $ac->create_user({ name => "role1", roles => ['A', 'B'] });
        $ac->create_user({ name => "role2", roles => ['A', 'C'] });
        $ac->create_user({ name => "role3", roles => ['A', 'C', 'D'] });

        for my $pair ([ A => 3 ], [ B => 1 ], [ C => 2 ], [ D => 1 ], [ E => 0 ]) {
            my ($role, $num) = @$pair;
            my @u = $ac->search_users_has_role($role);
            is scalar @u => $num, "role $role: $num users";
            for my $u (@u) {
                ok $u->has_role($role), "has role $role";
            }
        }
    }

    $dbh->commit;
}

