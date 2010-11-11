# -*- mode:perl -*-
use strict;
use Data::Dumper;
use Test::More;

use_ok("Acore::WAF::Plugin::Session");

{
    my $flash = Acore::WAF::Plugin::Session::Flash->new;
    isa_ok $flash => "Acore::WAF::Plugin::Session::Flash";
    can_ok $flash, qw/ get set finalize /;

    $flash->set( foo => "FOO" );
    is $flash->get("foo") => "FOO";
    is $flash->finalize => undef;

    $flash->set( foo => "FOO" );
    $flash->set( bar => "BAR" );
    is $flash->get("foo") => "FOO";
    is $flash->get("foo") => "FOO";
    is_deeply $flash->finalize => { bar => "BAR" };

    is $flash->get("bar") => "BAR";
    is $flash->finalize => undef;
}

done_testing;
