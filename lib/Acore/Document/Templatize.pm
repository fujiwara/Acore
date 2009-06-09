package Acore::Document::Templatize;

use strict;
use warnings;
use Any::Moose;
use utf8;

extends 'Acore::Document';

sub create_template {}
sub edit_template   {}
sub view_template   {}

sub param {
    my $self = shift;
    my $name = shift;

    return ( $name =~ /^\// ) ? $self->xpath->get($name)
                              : $self->{$name};
}

sub html_form_to_create {
    my $class = shift;

    return $class->SUPER::html_form_to_create(@_)
        unless $class->create_template;

    sprintf q{?=r $_[0]->render_part("%s");}, $class->create_template;
}

sub html_form_to_update {
    my $self = shift;

    return $self->SUPER::html_form_to_update(@_)
        unless $self->edit_template;

    sprintf q{?=r $_[0]->render_part("%s");}, $self->edit_template;
}

sub validate_to_create {
    my $class = shift;
    my ($c)   = @_;

    return super(@_) unless $class->create_template;

    my $obj = {};
    for my $name ( grep /^\//, $c->req->param ) {
        my @value = $c->req->param($name);
        (my $key = $name) =~ s{^/}{};
        $obj->{$key} = ( @value == 1 ) ? $value[0] : \@value;
    }
    $class->new($obj);
}

sub validate_to_update {
    my $self = shift;
    my ($c)  = @_;

    return super(@_) unless $self->edit_template;

    for my $name ( grep /^\//, $c->req->param ) {
        my @value = $c->req->param($name);
        (my $key = $name) =~ s{^/}{};
        $self->{$key} = ( @value == 1 ) ? $value[0] : \@value;
    }
    $self;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;
