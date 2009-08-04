package t::WAFTest::Controller::AnyLocation;

use Any::Moose;
with 'Acore::WAF::Controller::Role::Locatable';
our $Location;

sub _auto {
    my ($self, $c, $args) = @_;
    $self->set_location( $c, $args );
    1;
}

sub locate {
    my ($self, $c, $args) = @_;
    $c->res->body(
        join(" ", $self->location, location(), $Location)
    );
}

1;
