package t::WAFTest::Controller;

use strict;
use warnings;

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

sub forward {
    my ($self, $c) = @_;
    $c->log->info("forward");
    $c->forward("t::WAFTest::Controller::X", "xyz", [qw/ a b c /]);
}

sub forward_internal {
    my ($self, $c) = @_;
    $c->log->info("forward");
    $c->forward($self, "ok");
}

package t::WAFTest::Controller::X;

sub xyz {
    my ($self, $c, $args) = @_;

    $c->log->info("forwarded");
    $c->res->body( join("", @$args) );
}

1;


