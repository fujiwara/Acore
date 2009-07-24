package t::WAFTest;

use strict;
use warnings;
use Any::Moose;
extends 'Acore::WAF';

override _build_log => sub {
    my $self = shift;
    Acore::WAF::Log->new({ file => "t/tmp/error_log" });
};


__PACKAGE__->meta->make_immutable;
no Any::Moose;

__PACKAGE__->setup(qw/ Sample FormValidator Session FillInForm TT /);

{
    package t::WAFTest::Dispatcher;
    use HTTPx::Dispatcher;
    use Acore::WAF::Util qw/:dispatcher/;

    connect "",
        { controller => "t::WAFTest::Controller", action => "index" };
    connect "favicon.ico",
        { controller => "t::WAFTest", action => "dispatch_favicon"};
    connect "static/:filename",
        { controller => "t::WAFTest", action => "dispatch_static" };
    connect "act/:action",
        { controller => "t::WAFTest::Controller" };
    connect "adoc/:path",
        { controller => "t::WAFTest::Controller", action => "adoc" };
    connect "auto/:action",
        { controller => "t::WAFTest::Controller::Auto" };
    connect "handle_args",
        {
            controller => "t::WAFTest::Controller",
            action     => "handle_args",
            args       => { foo => "bar" },
        };

    connect "rest/document/id/:id",
        { controller => "Acore::WAF::Controller::REST", action => "document" };
    connect "rest/document/path/:path",
        { controller => "Acore::WAF::Controller::REST", action => "document" };
    connect "rest/document",
        { controller => "Acore::WAF::Controller::REST", action => "new_document" };

    my $auto = sub {
        my ($self, $c) = @_;
        $c->log->info('Sites auto OK');
        $c->req->param('auto_ng') ? undef : 1;
    };
    for (bundled "Sites") {
        connect "sites/",     to $_ => "page";
        connect "sites/auto1", to $_ => "page",
            args => { auto => $auto, page => "auto", };
        connect "sites/auto2", to $_ => "page",
            args => { auto => \&t::WAFTest::Controller::_sites_auto,
                      page => "auto" };
        connect "sites/path/:page",   to $_ => "path";
        connect "sites/:page/id=:id", to $_ => "page";
        connect "sites/:page",        to $_ => "page";
    }
}

1;
