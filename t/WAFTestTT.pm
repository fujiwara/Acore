package t::WAFTestTT;

use strict;
use warnings;
use Any::Moose;
extends 'Acore::WAF';

__PACKAGE__->meta->make_immutable;
no Any::Moose;

__PACKAGE__->setup(qw/ TT /);

{
    package t::WAFTestTT::Dispatcher;
    use HTTPx::Dispatcher;
    connect "",
        { controller => "t::WAFTestTT::Controller", action => "index"};
    connect "act/:action",
        { controller => "t::WAFTestTT::Controller" };
}

1;
