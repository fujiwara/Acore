package t::WAFTest;

use strict;
use warnings;
use Any::Moose;
extends 'Acore::WAF';

__PACKAGE__->meta->make_immutable;
no Any::Moose;

{
    package t::WAFTest::Dispatcher;
    use HTTPx::Dispatcher;
    connect "",
        { controller => "t::WAFTest", action => "index"};
    connect "favicon.ico",
        { controller => "t::WAFTest", action => "dispatch_favicon"};
    connect "static/:filename",
        { controller => "t::WAFTest", action => "dispatch_static" };
    connect "act/:action",
        { controller => "t::WAFTest", };
}

__PACKAGE__->setup;

sub index {
    my ($self, $c) = @_;
    $c->res->body("index");
}

sub ok {
    my ($self, $c) = @_;
    $c->res->body("ok");
}

sub rd {
    my ($self, $c) = @_;
    $c->redirect( $c->uri_for('/redirect_to') );
}

sub error {
    die;
}


1;
