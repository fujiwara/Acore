package Acore::SimpleApp;

use strict;
use warnings;
use Any::Moose;
extends 'Acore::WAF';

__PACKAGE__->meta->make_immutable;
no Any::Moose;

use Acore::WAF::Controller::AdminConsole;
{
    package Acore::SimpleApp::Dispatcher;
    use HTTPx::Dispatcher;
    connect "",
        { controller => "Acore::SimpleApp", action => "dispatch_index" };
    connect "adoc/:path",
        { controller => "Acore::SimpleApp", action => "dispatch_acore" };
    connect "static/:filename",
        { controller => "Acore::SimpleApp", action => "dispatch_static" };
    connect "favicon.ico",
        { controller => "Acore::SimpleApp", action => "dispatch_favicon" };
    connect "admin_console/:action",
        { controller => "Acore::WAF::Controller::AdminConsole" };
}

__PACKAGE__->setup(qw/ Session /);

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
