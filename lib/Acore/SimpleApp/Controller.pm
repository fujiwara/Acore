package Acore::SimpleApp::Controller;

use strict;
use warnings;

sub null {
    my ($self, $c) = @_;
    $c->res->body("ok");
}

sub dispatch_index {
    my ($self, $c) = @_;
    $c->log->info("dispatch index");
    $c->prepare_acore();

    my $count = $c->session->get('counter');
    $c->session->set( counter => ++$count );

    $c->render("index.mt");
}

sub dispatch_acore {
    my ($self, $c, $args) = @_;
    $c->serve_acore_document( "/" . $args->{path} )
        or do {
            $c->res->status(404);
            $c->res->body("Not found / acore document");
        };
}

1;
