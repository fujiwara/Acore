package Acore::Document::File;

use strict;
use warnings;
use base qw/ Acore::Document /;
use Path::Class;
our $AUTOLOAD;

__PACKAGE__->mk_accessors(qw/ file_path /);

sub AUTOLOAD {
    my $self   = shift;
    my $method = $1 if $AUTOLOAD =~ /::(\w+)$/;

    return unless defined $method;

    Path::Class::file( $self->{file_path} )->$method(@_);
}

sub DESTROY {}

1;
