package Acore::Document::File;

use strict;
use warnings;
use Path::Class;
our $AUTOLOAD;
use Any::Moose;

extends 'Acore::Document';

has file_path => ( is => "rw" );

__PACKAGE__->meta->make_immutable;
no Any::Moose;


sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD =~ /::(\w+)$/ ? $1 : undef;
    return unless defined $method;

    no strict "refs";
    *{"$method"} = sub {
        my $that = shift;
        Path::Class::file( $that->{file_path} )->$method(@_);
    };
    $self->$method(@_);
}

sub DESTROY {}

1;
