package Acore::Document::Struct;

use strict;
use warnings;
use Any::Moose;
use utf8;

extends 'Acore::Document';

has title => ( is => "rw" );
has body  => ( is => "rw" );
has description => ( is => "rw" );

has content_type => (
    is      => "rw",
    default => "text/html",
);

sub html_form_to_create {
    my $class = shift;
    q{
? my ($c) = @_;
<fieldset>
  <legend>Content</legend>
  <div>
    <label for="title">タイトル</label>
    <input type="text" name="title" value="" size="40"/>
  </div>
  <div>
    <label for="description">description</label>
    <input type="text" name="description" value="" size="40"/>
  </div>
  <div>
    <label for="body">本文</label>
    <textarea name="body" cols="40" rows="10"></textarea>
  </div>
</fieldset>
};
}

sub html_form_to_update {
    my $self = shift;
    q{
? my ($c, $doc) = @_;
<fieldset>
  <legend>Content</legend>
  <div>
    <label for="title">タイトル</label>
    <input type="text" name="title" value="<?= $doc->title ?>" size="40"/>
  </div>
  <div>
    <label for="description">description</label>
    <input type="text" name="description" value="<?= $doc->description ?>" size="40"/>
  </div>
  <div>
    <label for="body">本文</label>
    <textarea name="body" cols="40" rows="10"><?= $doc->body ?></textarea>
  </div>
</fieldset>
};
}

sub validate_to_create {
    my ($class, $c) = @_;

    $c->form->check(
        title => [qw/NOT_NULL/],
    );
    my $obj = {};
    $obj->{$_} = $c->req->param($_) for qw/ title description body /;
    $class->new($obj);
}

sub validate_to_update {
    my ($self, $c) = @_;

    $c->form->check(
        title => [qw/NOT_NULL/],
    );
    $self->$_( $c->req->param($_) ) for qw/ title description body /;
    $self;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;
