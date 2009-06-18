package t::Cache;

use strict;
use warnings;
use Any::Moose;

sub get {
    my ($self, $key) = @_;
    $self->{$key};
}

sub set {
    my ($self, $key, $value) = @_;
    $self->{$key} = $value;
}

sub remove {
    my ($self, $key) = @_;
    delete $self->{$key};
    undef;
}


1;
