package Acore::Storage;

use strict;
use warnings;
our $VERSION = '0.01';
use Any::Moose;
use DBIx::CouchLike 0.09;

has dbh  => ( is => "rw" );

has user => (
    is         => "rw",
    isa        => "DBIx::CouchLike",
    lazy_build => 1,
);

has document => (
    is         => "rw",
    isa        => "DBIx::CouchLike",
    lazy_build => 1,
);

__PACKAGE__->meta->make_immutable;
no Any::Moose;

sub _build_user {
    my $self = shift;
    DBIx::CouchLike->new({
        dbh   => $self->dbh,
        table => "acore_user",
    })
}

sub _build_document {
    my $self = shift;
    DBIx::CouchLike->new({
        dbh   => $self->dbh,
        table => "acore_document",
    })
}


our $document_all =<<'_END_OF_CODE_';
sub {
    my ($obj, $emit) = @_;
    $emit->( $obj->{path} => $obj->{updated_on} );
}
_END_OF_CODE_
;

our $document_tags =<<'_END_OF_CODE_';
sub {
    my ($obj, $emit) = @_;
    return if ref $obj->{tags} ne 'ARRAY';
    for my $tag ( @{ $obj->{tags} } ) {
        $emit->( $tag => $obj->{path} ) if defined $tag;
    }
}
_END_OF_CODE_
;

our $user_roles =<<'_END_OF_CODE_';
sub {
    my ($obj, $emit) = @_;
    return if ref $obj->{roles} ne 'ARRAY';
    for my $role ( @{ $obj->{roles} } ) {
        $emit->( $role => $obj->{_id} ) if defined $role;
    }
}
_END_OF_CODE_
;


sub setup {
    my $self = shift;
    $self->user->create_table();
    $self->document->create_table();
    $self->document->post( "_design/path", {
        views => {
            all => {
                map => $document_all,
            },
        },
    });
    $self->document->post( "_design/tags", {
        views => {
            all => {
                map => $document_tags,
            },
        },
    });
    $self->user->post( "_design/roles", {
        views => {
            all => {
                map => $user_roles,
            },
        },
    });
}

1;
__END__

=head1 NAME

Acore::Storage -

=head1 SYNOPSIS

  use Acore::Storage;

=head1 DESCRIPTION

Acore is

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
