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
    my $res = $acore->senna_index->update(
        $self->id,
        encode_utf8( $old ),
        encode_utf8( $self->{for_search} ),
    );
    if ( $acore->in_transaction ) {
        push @{ $acore->transaction_data->{senna} },
             [ $self->id, $self->{for_search}, $old ];
    }
    $res == SEN_RC_SUCCESS ? 1 : 0;
}

sub create_fts_index {
    my ($self, $acore) = @_;

    my $res = $acore->senna_index->insert({
        key   => $self->id,
        value => encode_utf8( $self->{for_search} ),
    });
    if ( $acore->in_transaction ) {
        push @{ $acore->transaction_data->{senna} },
             [ $self->id, $self->{for_search}, undef ];
    }
    $res == SEN_RC_SUCCESS ? 1 : 0;
}

1;
