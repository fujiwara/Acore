package t::WAFTest::Controller::Auto;
use strict;
use warnings;

sub _auto {
    my ($self, $c, $args) = @_;
    return $c->req->param('auto') ? 1 : 0;
}

sub run {
    my ($self, $c, $args) = @_;

    $c->res->body("${self}::run");
}

1;
