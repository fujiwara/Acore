package Acore::SimpleApp;

use Any::Moose;
extends 'Acore::WAF';

__PACKAGE__->meta->make_immutable;
no Any::Moose;

sub dispatch_index {
    my ($c) = @_;

    $c->log( info => "dispatch index" );
    $c->prepare_acore();
    $c->render("index.mt");
}

1;
