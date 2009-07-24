# -*- mode:perl -*-
use strict;
{
    package Foo::Dispatcher;
    use Acore::WAF::Util qw/:dispatcher/;
    use Test::More tests => 7;

    is( controller "Bar"      => "Foo::Controller::Bar" );
    is( controller "Bar::Baz" => "Foo::Controller::Bar::Baz");
    is( bundled "Sites"       => "Acore::WAF::Controller::Sites");
    is( class "XYZ"           => "XYZ");

    my $res = to controller "Bar" => "xxx";
    is_deeply( $res => { controller => "Foo::Controller::Bar",
                         action     => "xxx" } );

    $res = to bundled "Sites" => "page", args => { foo => "bar" };
    is_deeply( $res => { controller => "Acore::WAF::Controller::Sites",
                         action     => "page",
                         args       => { foo => "bar" } });

    $res = to class "App";
    is_deeply( $res => { controller => "App" } );
}
