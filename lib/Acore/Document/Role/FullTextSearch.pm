package Acore::Document::Role::FullTextSearch;
use strict;
use warnings;
use Any::Moose '::Role';
use Senna;
use Senna::Constants qw/ SEN_RC_SUCCESS /;
use Encode qw/ encode_utf8 /;

sub for_search {
    my $self = shift;
    if (@_) {
        $self->{for_search} = shift;
    }
    $self->{for_search};
}

sub delete_fts_index {
    my ($self, $index, $old) = @_;

    my $res = $index->update(
        $self->id,
        encode_utf8($old),
        undef,
    );
    $res == SEN_RC_SUCCESS ? 1 : 0;
}

sub update_fts_index {
    my ($self, $index, $old) = @_;
    my $res = $index->update(
        $self->id,
        encode_utf8( $old ),
        encode_utf8( $self->{for_search} ),
    );
    $res == SEN_RC_SUCCESS ? 1 : 0;
}

sub create_fts_index {
    my ($self, $index) = @_;

    my $res = $index->insert({
        key   => $self->id,
        value => encode_utf8( $self->{for_search} ),
    });
    $res == SEN_RC_SUCCESS ? 1 : 0;
}

1;
