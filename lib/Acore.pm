package Acore;

use strict;
use warnings;
our $VERSION = '0.01';
use base qw/ Class::Accessor::Fast /;
use Acore::Storage;
use Acore::User;
use Carp;
use Data::Structure::Util qw/ unbless /;
use DateTime;

__PACKAGE__->mk_accessors(qw/ storage user_class /);

sub new {
    my $class = shift;
    my $args  = shift;
    my $self  = $class->SUPER::new();
    if ( $args->{dbh} ) {
        $self->storage(
            Acore::Storage->new({ dbh => $args->{dbh} })
        );
    }
    if ( $args->{setup_db} ) {
        $self->storage->setup();
    }
    $self->{user_class} ||= "Acore::User";
    $self;
}

sub authenticate_user {
    my $self = shift;
    my $args = shift;

    my $user = $self->storage->user->get( $args->{name} )
        or return;
    $user = bless $user, $self->user_class;
    $user->init;
    return $user->authenticate($args);
}

sub save_user {
    my $self = shift;
    my $user = shift;
    $self->storage->user->put( unbless $user );
}

sub create_user {
    my $self = shift;
    my $args = shift;

    unless ( defined $args->{name} ) {
        croak "name is not defined.";
    }

    my $user = $self->storage->user->get( $args->{name} );
    if ($user) {
        croak "user name=$args->{name} is already exists.";
    }
    $self->storage->user->put( $args->{name} => $args );
    $user = $self->storage->user->get( $args->{name} );
    $user = bless $user, $self->user_class;
    $user->init;
    return $user;
}

sub now {
    DateTime->now();
}


1;
__END__

=head1 NAME

Acore -

=head1 SYNOPSIS

  use Acore;

=head1 DESCRIPTION

Acore is

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
