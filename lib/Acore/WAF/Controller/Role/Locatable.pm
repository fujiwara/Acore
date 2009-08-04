package Acore::WAF::Controller::Role::Locatable;

use strict;
use Any::Moose '::Role';
use String::CamelCase qw/ decamelize /;

requires '_auto';

sub set_location {
    my ($class, $c, $args) = @_;

    my $location = defined $args->{location}
                 ? $args->{location}
                 : decamelize( (split /::/, $class)[-1] );

    $c->log->info("set location: $location");

    no strict 'refs';
    ${"${class}::Location"} = $location;
    Acore::WAF::Render::set_location($location);
    1;
}

sub location {
    my $class = shift;
    $class ||= (caller)[0];
    no strict 'refs';
    ${"${class}::Location"};
}

1;

__END__

=head1 NAME

Acore::WAF::Controller::Role::Locatable - Role for locatable controller

=head1 SYNOPSIS

 package YourApp::Dispatcher;
 # locate on default
 connect "/any_location/:action", to controller "AnyLocation";
 
 # locate on the other location
 connect "/somewhere/:action", to controller "AnyLocation" => undef,
     args => { location => "somewhere" };

 package YourApp::Controller::AnyLocation;
 use Any::Moose;
 our $Location;
 with 'Acore::WAF::Controller::Role::Locatable';
 sub _auto {
     my ($self, $c, $args) = @_;
     $self->locatable($c, $args);
     1;
 }
 sub action {
     my ($self, $c, $args) = @_;
     $c->redirect( $c->uri_for("/$Location/foo") );
 }
 sub foo {
     my ($self, $c, $args) = @_;
     $c->render( location() . "/foo.mt" );
 }

 # foo.mt
 $c->uri_for("@{[ location ]}/foo");
 $c->render_part( location . "/bar.mt" );


=head1 DESCRIPTION

Acore::WAF::Controller::Role::Locatable is Role for locatable controller.

=head1 REQUIRES

=over 4

=item our $Location

=item _auto

In "_auto" method, call $self->locatable($c, $args).

 sub _auto {
     my ($self, $c, $args) = @_;
     $self->locatable($c, $args);
     1;
 }

Default location is decamelize(ControllerName).

 YourApp::Controller::AnyLocationr => any_location

=back

=head1 PROVIDES

=over 4

=item set_location

Set $Location by $args.

 $self->set_location( $c, $args );

=item location

returns $Location

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

