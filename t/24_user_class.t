# -*- mode:perl -*-
use strict;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'Acore';
};

{
    my $acore = Acore->new;
    isa_ok $acore => "Acore";

    is $acore->user_class => "Acore::User";
    ok $INC{"Acore/User.pm"}, "Acore::User required";

    $acore->user_class("t::MyUser");
    is $acore->user_class => "t::MyUser";
    ok $INC{"t/MyUser.pm"}, "t::MyUser required";

    throws_ok {
        $acore->user_class("t::UserNotFound");
    } qr/Can't require/, "user_class can't require";
}

done_testing;
