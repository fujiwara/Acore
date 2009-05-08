package Acore::Document::File;

use strict;
use warnings;
use base qw/ Acore::Document /;
use Path::Class;
our $AUTOLOAD;

__PACKAGE__->mk_accessors(qw/ file_path /);

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
