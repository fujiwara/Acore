package Acore::User;

use strict;
use warnings;
our $VERSION = '0.01';
use base qw/ Class::Accessor::Fast /;
use UNIVERSAL::require;
__PACKAGE__->mk_accessors(qw/ name /);

sub init {
    my $self = shift;

    $self->{authentications} ||= ["Password"];
    $self->{roles}           ||= ["Reader"];
    _auth_class($_)->require for $self->authentications;
    _role_class($_)->require for $self->roles;

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

1;
__END__

=head1 NAME

Acore::User -

=head1 SYNOPSIS

  use Acore::User;

=head1 DESCRIPTION

Acore is

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
