package t::WAFTest;

use strict;
use warnings;
use Any::Moose;
extends 'Acore::WAF';

__PACKAGE__->meta->make_immutable;
no Any::Moose;

__PACKAGE__->setup;

{
    package t::WAFTest::Dispatcher;
    use HTTPx::Dispatcher;
    connect "",
        { controller => "t::WAFTest::Controller", action => "index"};
    connect "favicon.ico",
        { controller => "t::WAFTest", action => "dispatch_favicon"};
    connect "static/:filename",
        { controller => "t::WAFTest", action => "dispatch_static" };
    connect "act/:action",
        { controller => "t::WAFTest::Controller", };
}

1;