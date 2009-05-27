package Acore::Storage;

use strict;
use warnings;
our $VERSION = '0.01';
use base qw/ Class::Accessor::Fast /;
use DBIx::CouchLike "0.03";

__PACKAGE__->mk_accessors(qw/ dbh user document /);

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

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    for my $table (qw/ user document /) {
        $self->$table(
            DBIx::CouchLike->new({
                dbh   => $self->dbh,
                table => "acore_$table",
            })
        );
    }
    return $self;
}

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
