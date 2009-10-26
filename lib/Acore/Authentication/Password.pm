package Acore::Authentication::Password;

use strict;
use warnings;
our $VERSION = '0.01';
use Crypt::SaltedHash;

sub validate {
    my ( $class, $user, $args ) = @_;
    Crypt::SaltedHash->validate($user->{password}, $args->{password});
}

package Acore::Authentication::Password::Role;
use Any::Moose "::Role";

has password => ( is => "rw" );

sub set_password {
    my ( $user, $password ) = @_;

    my $crypt = Crypt::SaltedHash->new( algorithm => 'SHA-1' );
    $crypt->add($password);
    $user->{password} = $crypt->generate;
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
