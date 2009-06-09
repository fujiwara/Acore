package Acore::Document::Templatize;

use strict;
use warnings;
use Any::Moose;
use utf8;

extends 'Acore::Document';

sub create_template {}
sub edit_template   {}
sub view_template   {}

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

    my $self = $class->new;
    for my $name ( grep /^\//, $c->req->param ) {
        my @value = $c->req->param($name);
        $self->xpath->set(
            $name => ( @value == 1 ) ? $value[0] : \@value
        );
    }
}

sub validate_to_update {
    my $self = shift;
    my ($c)  = @_;

    return super(@_) unless $self->edit_template;

    for my $name ( grep /^\//, $c->req->param ) {
        my @value = $c->req->param($name);
        $self->xpath->set(
            $name => ( @value == 1 ) ? $value[0] : \@value
        );
    }
    $self;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=head1 NAME

Acore::Document::Templatize - templatize document base class

=head1 SYNOPSIS

  package YourDocument;
  use Any::Moose;
  extends 'Acore::Document::Templatize';
  use constant create_template => "create.mt";
  use constant edit_template   => "edit.mt";

  # create.mt
  <fieldset>
    <legend>YourDocument</legend>
    <div>
      <input type="text" name="/foo" value=""/>
      <input type="text" name="/bar/baz[0]" value=""/>
      <input type="text" name="/bar/baz[1]" value=""/>
      <input type="text" name="/bar/baz[2]" value=""/>
    </div>
  </fieldset>

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
