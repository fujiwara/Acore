package Acore::SimpleApp;

use Any::Moose;
extends 'Acore::WAF';

__PACKAGE__->meta->make_immutable;
no Any::Moose;

use HTTPx::Dispatcher;
connect "",
    { controller => __PACKAGE__, action => "dispatch_index" };
connect "adoc/:path",
    { controller => __PACKAGE__, action => "dispatch_acore" };
connect "static/:filename",
    { controller => __PACKAGE__, action => "dispatch_static" };

__PACKAGE__->setup(qw/ Session /);

sub dispatch_index {
    my ($self, $c) = @_;
    $c->log( info => "dispatch index" );
    $c->prepare_acore();
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
