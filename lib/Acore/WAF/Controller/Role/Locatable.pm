package Acore::WAF::Controller::Role::Locatable;

use strict;
use Any::Moose '::Role';
use String::CamelCase qw/ decamelize /;

requires '_auto';

sub locatable {
    my ($class, $args) = @_;
    my $location = defined $args->{location}
                 ? $args->{location}
                 : decamelize( (split /::/, $class)[-1] );
    no strict 'refs';
    ${"${class}::Location"} = $location;
    Acore::WAF::Render::set_location($location);
    1;
}

1;
