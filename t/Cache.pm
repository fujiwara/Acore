package t::Cache;

use strict;
use warnings;
use Any::Moose;
our $Cache = {};

sub get {
    my ($self, $key) = @_;
    $Cache->{$key};
}

sub set {
    my ($self, $key, $value) = @_;
    $Cache->{$key} = $value;
}

sub remove {
    my ($self, $key) = @_;
    delete $Cache->{$key};
    undef;
}


1;
