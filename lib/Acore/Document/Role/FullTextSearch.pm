package Acore::Document::Role::FullTextSearch;
use strict;
use warnings;
use Any::Moose '::Role';
use Senna;
use Senna::Constants qw/ SEN_RC_SUCCESS /;
use Encode qw/ encode_utf8 /;

requires 'for_search';

sub delete_fts_index {
    my ($self, $acore, $old) = @_;

    my $res = $acore->senna_index->update(
        $self->id,
        encode_utf8($old),
        undef,
    );
    if ( $acore->in_transaction ) {
        push @{ $acore->transaction_data->{senna} },
             [ $self->id, undef, $old ];
    }
    $res == SEN_RC_SUCCESS ? 1 : 0;
}

sub update_fts_index {
    my ($self, $acore, $old) = @_;

    my $for_search = $self->for_search;
    my $res = $acore->senna_index->update(
        $self->id,
        encode_utf8($old),
        encode_utf8($for_search),
    );
    if ( $acore->in_transaction ) {
        push @{ $acore->transaction_data->{senna} },
             [ $self->id, $for_search, $old ];
    }
    $res == SEN_RC_SUCCESS ? 1 : 0;
}

sub create_fts_index {
    my ($self, $acore) = @_;

    my $for_search = $self->for_search;
    my $res = $acore->senna_index->insert({
        key   => $self->id,
        value => encode_utf8($for_search),
    });
    if ( $acore->in_transaction ) {
        push @{ $acore->transaction_data->{senna} },
             [ $self->id, $for_search, undef ];
    }
    $res == SEN_RC_SUCCESS ? 1 : 0;
}

1;

__END__

__END__

=head1 NAME

Acore::Document::Role::FullTextSearch - Role for fulltext search

=head1 SYNOPSIS

  package YourDocument;
  use Any::Moose;
  extends 'Acore::Document';
  has for_search => (
     is => "rw",
  );
  with 'Acore::Document::Role::FullTextSearch';

  $doc = YourDocument->new({ for_search => "text for full text search" });
  $acore->put_document($doc);
  @doc = $acore->fulltext_search({ query => "full text" });

=head1 DESCRIPTION

Acore::Document::Role::FullTextSearch is Role for full text search.

=head1 REQUIRES

=over 4

=item for_search

Method to supply text for full text search.

  has for_search => ( is => "rw", isa => "Str" );

  sub for_search {
      my $self = shift;
      $text = ".....";
      return $text;
  }

=back

=head1 METHODS

=over 4

=item create_fts_index

=item update_fts_index

=item delete_fts_index

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
