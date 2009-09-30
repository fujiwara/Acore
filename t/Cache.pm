package t::Cache;

use strict;
use warnings;
use Any::Moose;
use Clone qw/ clone /;
our $Cache   = {};
our $Expires = {};

sub get {
    my ($self, $key) = @_;
    if ( defined $Expires->{$key} && $Expires->{$key} < time() ) {
        delete $Cache->{$key};
    }
    ref $Cache->{$key} ? clone($Cache->{$key}) : $Cache->{$key};
}

sub set {
    my ($self, $key, $value, $expires) = @_;
    $Expires->{$key} = time() + $expires if defined $expires;
    $Cache->{$key} = $value;
}

sub remove {
    my ($self, $key) = @_;
    delete $Cache->{$key};
    undef;
}


1;
