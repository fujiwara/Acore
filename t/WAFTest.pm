package t::WAFTest;

use strict;
use warnings;
use Any::Moose;
extends 'Acore::WAF';

__PACKAGE__->meta->make_immutable;
no Any::Moose;

__PACKAGE__->setup(qw/ Sample FormValidator Session FillInForm /);

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
        { controller => "t::WAFTest::Controller" };
    connect "adoc/:path",
        { controller => "t::WAFTest::Controller", action => "adoc" };
}

1;
