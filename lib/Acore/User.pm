package Acore::User;

use strict;
use warnings;
our $VERSION = '0.01';
use Any::Moose;
use Acore::Authentication::Password;
use UNIVERSAL::require;

has name => (
    is => "rw",
);

with "Acore::Authentication::Password::Role";

sub init {
    my $self = shift;

    $self->{authentications} ||= ["Password"];
    $self->{roles}           ||= ["Reader"];
    for ( $self->authentications ) {
        my $class = _auth_class($_);
        $class->use
            or die "Can't use $class: $@";
    }
    for ( $self->roles ) {
        my $class = _role_class($_);
        $class->require;
    }

    $self;
}

sub authentications {
    my $self = shift;
    if ( ref $_[0] eq "ARRAY" ) {
        $self->{authentications} = $_[0];
    }
    return wantarray ? @{ $self->{authentications} }
                     : $self->{authentications};
}

sub roles {
    my $self = shift;
    if ( ref $_[0] eq "ARRAY" ) {
        $self->{roles} = $_[0];
    }
    return wantarray ? @{ $self->{roles} }
                     : $self->{roles};
}

sub has_authentication {
    my $self = shift;
    my $auth = shift;
    return grep { $_ eq $auth } $self->authentications;
}

sub has_role {
    my $self = shift;
    my $role = shift;
    return grep { $_ eq $role } $self->roles;
}

sub add_role {
    my $self = shift;
    my $role = shift;
    unless ( $self->has_role($role) ) {
        push @{ $self->{roles} }, $role;
    }
}

sub delete_role {
    my $self = shift;
    my $role = shift;
    if ( $self->has_role($role) ) {
        $self->roles([ grep { $_ ne $role } $self->roles ]);
    }
}

sub add_authentication {
    my $self = shift;
    my $auth = shift;
    unless ( $self->has_authentication($auth) ) {
        push @{ $self->{authentications} }, $auth;
    }
}

sub delete_authentication {
    my $self = shift;
    my $auth = shift;
    if ( $self->has_authentication($auth) ) {
        $self->authentications(
            [ grep { $_ ne $auth } $self->authentications ]
        );
    }
}

sub authenticate {
    my $self = shift;
    my $args = shift;
    for my $auth ( $self->authentications ) {
        _auth_class($auth)->validate( $self, $args )
            and return $self;
    }
    return;
}

sub _auth_class { "Acore::Authentication::$_[0]" }
sub _role_class { "Acore::Role::$_[0]" }

my $Ignore_attrs
    = +{ map {( $_ => 1 )}
         qw/ _id id roles authentications password name /
    };
sub attributes {
    my $self = shift;
    sort grep { !$Ignore_attrs->{$_} } keys %$self;
}

sub attr {
    my $self = shift;
    my $key  = shift;
    if (@_) {
        return if $Ignore_attrs->{$key};
        $self->{$key} = shift;
    }
    $self->{$key};
}

*attribute = \&attr;

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;
__END__

=head1 NAME

Acore::User -

=head1 SYNOPSIS

  use Acore::User;

  $user = Acore::User->new({ name => $name });

=head1 DESCRIPTION

Acore is

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
