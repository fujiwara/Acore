package Acore::SimpleApp;

use strict;
use warnings;
use Any::Moose;
extends 'Acore::WAF';

__PACKAGE__->meta->make_immutable;
no Any::Moose;

{
    package Acore::SimpleApp::Dispatcher;
    use HTTPx::Dispatcher;
    connect "",
        { controller => "Acore::SimpleApp::Controller", action => "dispatch_index" };
    connect "adoc/:path",
        { controller => "Acore::SimpleApp::Controller", action => "dispatch_acore" };
    connect "static/:filename",
        { controller => "Acore::SimpleApp", action => "dispatch_static" };

    connect "favicon.ico",
        { controller => "Acore::SimpleApp", action => "dispatch_favicon" };

# Admin console
    connect "admin_console/",
        { controller => "Acore::WAF::Controller::AdminConsole",
          action     => "index" };

    connect "admin_console/static/:filename",
        { controller => "Acore::WAF::Controller::AdminConsole",
          action     => "static" };

    connect "admin_console/:action",
        { controller => "Acore::WAF::Controller::AdminConsole" };

# default action
    connect ":action",
        { controller => "Acore::SimpleApp::Controller", };
}

__PACKAGE__->setup(qw/ Session FormValidator /);

1;
