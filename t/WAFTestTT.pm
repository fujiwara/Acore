package t::WAFTestTT;

use strict;
use warnings;
use Any::Moose;
extends 'Acore::WAF';

__PACKAGE__->meta->make_immutable;
no Any::Moose;

__PACKAGE__->setup(qw/ TT Xslate /);

{
    package t::WAFTestTT::Dispatcher;
    use Acore::WAF::Util qw/:dispatcher/;
    use HTTPx::Dispatcher;
    connect "",            to class "t::WAFTestTT::Controller" => "index";
    connect "act/:action", to class "t::WAFTestTT::Controller";
}

1;
