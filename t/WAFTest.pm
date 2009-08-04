package t::WAFTest;

use strict;
use warnings;
use Any::Moose;
extends 'Acore::WAF';

override _build_log => sub {
    my $self = shift;
    my $log = Acore::WAF::Log->new({ file => "t/tmp/error_log" });
};


__PACKAGE__->meta->make_immutable;
no Any::Moose;

__PACKAGE__->setup(qw/ Sample FormValidator Session FillInForm TT /);

{
    package t::WAFTest::Dispatcher;
    use HTTPx::Dispatcher;
    use Acore::WAF::Util qw/:dispatcher/;

    my $controller = "t::WAFTest::Controller";

    connect "", to class $controller, "index";
    connect "favicon.ico",      to class "t::WAFTest", "dispatch_favicon";
    connect "static/:filename", to class "t::WAFTest", "dispatch_static";
    connect "act/:action",      to class $controller;
    connect "adoc/:path",       to class $controller, "adoc";
    connect "auto/:action",     to controller "Auto";

    connect "handle_args", to class $controller, "handle_args",
        args => { foo => "bar" };

    connect "rest/document/id/:id",     to bundled "REST", "document";
    connect "rest/document/path/:path", to bundled "REST", "document";
    connect "rest/document",            to bundled "REST", "new_document";

    my $auto = sub {
        my ($self, $c) = @_;
        $c->log->info('Sites auto OK');
        $c->req->param('auto_ng') ? undef : 1;
    };
    for (bundled "Sites") {
        connect "sites/",      to $_ => "page";
        connect "sites/auto1", to $_ => "page",
            args => { auto => $auto, page => "auto", };
        connect "sites/auto2", to $_ => "page",
            args => { auto => \&t::WAFTest::Controller::_sites_auto,
                      page => "auto" };
        connect "sites/path/:page",   to $_ => "path";
        connect "sites/:page/id=:id", to $_ => "page";
        connect "sites/:page",        to $_ => "page";
    }

    connect "any_location/:action", to controller "AnyLocation";
    connect "somewhere/:action",    to controller "AnyLocation" => undef,
        args => { location => "somewhere" };
}

1;
