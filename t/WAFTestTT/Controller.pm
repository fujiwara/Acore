package t::WAFTestTT::Controller;

use strict;
use warnings;

sub index {
    my ($self, $c) = @_;
    $c->res->body("index");
}

sub render {
    my ($self, $c) = @_;
    $c->stash->{value} = "<html>";
    $c->render("test.tt");
}

sub render_broken_tt {
    my ($self, $c) = @_;
    $c->render("broken.tt");
}

1;
