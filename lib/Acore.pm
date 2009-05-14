package Acore;

use strict;
use warnings;
our $VERSION = '0.01';
use base qw/ Class::Accessor::Fast /;
use Acore::Storage;
use Acore::User;
use Acore::Document;
use Carp;
use Data::Structure::Util qw/ unbless /;
use Clone qw/ clone /;
use utf8;

__PACKAGE__->mk_accessors(qw/ storage user_class /);

sub new {
    my $class = shift;
    my $args  = shift;
    my $self  = $class->SUPER::new();
    if ( $args->{dbh} ) {
        $self->storage(
            Acore::Storage->new({ dbh => $args->{dbh} })
        );
    }
    if ( $args->{setup_db} ) {
        $self->storage->setup();
    }
    $self->{user_class} ||= "Acore::User";
    $self;
}

sub get_user {
    my $self = shift;
    my $args = shift;
    my $user = $self->storage->user->get( $args->{name} )
        or return;
    $user = bless $user, $self->user_class;
    $user->init;
    $user;
}

sub authenticate_user {
    my $self = shift;
    my $args = shift;

    my $user = $self->get_user($args)
        or return;
    return $user->authenticate($args);
}

sub save_user {
    my $self = shift;
    my $user = shift;
    $self->storage->user->put( unbless $user );
}

sub create_user {
    my $self = shift;
    my $args = shift;

    unless ( defined $args->{name} ) {
        croak "name is not defined.";
    }

    my $user = $self->storage->user->get( $args->{name} );
    if ($user) {
        croak "user name=$args->{name} is already exists.";
    }
    $self->storage->user->put( $args->{name} => $args );
    $user = $self->storage->user->get( $args->{name} );
    $user = bless $user, $self->user_class;
    $user->init;
    return $user;
}

sub get_document {
    my ($self, $args) = @_;

    my $doc;
    if ( defined $args->{id} ) {
        $doc = $self->storage->document->get($args->{id});
    }
    elsif ( defined $args->{path} ) {
        my $view = $self->storage->document->view(
            "path/all", {
                key          => $args->{path},
                include_docs => 1,
            }
        )->next;
        return unless $view;
        $doc = $view->{document};
    }
    return unless $doc;

    return Acore::Document->from_object($doc);
}

sub put_document {
    my $self = shift;
    my $doc  = shift;

    if ( $doc->id ) {
        require Acore::DateTime;
        $doc->updated_on( Acore::DateTime->now() );
        my $obj = $doc->to_object;
        $self->storage->document->put($obj);
        return $doc;
    }
    else {
        my $obj = $doc->to_object;
        my $id = $self->storage->document->post($obj);
        return $self->get_document({ id => $id });
    }
}

sub search_documents {
    my $self = shift;
    my $args = shift;

    return unless defined $args->{path};
    my $itr = $self->storage->document->view(
        "path/all" => {
            key_like     => $args->{path} . "%",
            limit        => $args->{limit},
            offfset      => $args->{offset},
            include_docs => 1,
        });
    my @docs = map { Acore::Document->from_object( $_->{document} ) }
        $itr->all;
    return wantarray ? @docs : \@docs;
}

1;
__END__

=head1 NAME

Acore - AnyCMS core

=head1 SYNOPSIS

  use Acore;
  $dbh = DBI->connect($dsn, ... );
  $acore = Acore->new({ dbh => $dbh });

  $user = $acore->create_user({ name => "foo" });
  $user = $acore->get_user({ name => "foo" });
  $user = $acore->authenticate_user({ name => "foo", password => "secret" });

  $doc = $acore->put_document(
      Acore::Document::Foo->new()
  );
  $doc = $acore->get_document({ id => $id });
  @doc = $acore->search_documents({ path => "/path/to" });

=head1 DESCRIPTION

Acore is AnyCMS core module.

=head1 METHODS

=over 4

=item new

Constractor.

 $acore = Acore->new({ dbh => $dbh, setup_db => 1 });

dbh: DBI データベースハンドル

setup_db: 真を指定すると DB のテーブルを作成します

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
