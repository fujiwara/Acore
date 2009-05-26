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

__PACKAGE__->mk_accessors(qw/ storage user_class cache /);

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

sub all_users {
    my $self = shift;
    my $args = shift;
    my @user = map {
        my $user = $_->{value};
        $user->{id} ||= $_->{id};
        bless $user, $self->user_class;
        $user->init;
        $user;
    } $self->storage->user->all;
    @user;
}

sub get_user {
    my $self = shift;
    my $args = shift;

    my $user;
    $user = $self->cache->get( "Acore::User/name=". $args->{name} )
        if defined $args->{name} && $self->cache;
    unless ($user) {
        $user = $self->storage->user->get( $args->{name} );
        $self->cache->set("Acore::User/name=". $args->{name} => $user)
            if $self->cache && $user;
    }

    $user or return;

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
    my $unbless_user = unbless $user;
    $self->storage->user->put( $unbless_user );
    $self->cache->set( "Acore::User/name=" . $user->{name} => $unbless_user )
        if $self->cache;
    $user;
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

sub new_document_id {
    my $self = shift;
    $self->storage->document->id_generator->get_id;
}

sub all_documents {
    my $self = shift;
    my $args = shift;

    $args->{exclude_designs} = 1;
    my @docs
        = map  {
            $_->{value}->{_id} ||= $_->{id};
            Acore::Document->from_object( $_->{value} ) }
          $self->storage->document->all($args);
    @docs;
}

sub get_document {
    my ($self, $args) = @_;

    my $doc;
    if ( defined $args->{id} ) {
        $doc = $self->cache->get("Acore::Document/id=" . $args->{id})
            if $self->cache;
        unless ($doc) {
            $doc = $self->storage->document->get($args->{id});
            $self->cache->set("Acore::Document/id=" . $args->{id} => $doc)
                if $self->cache && $doc;
        }
    }
    elsif ( defined $args->{path} ) {
        $doc = $self->cache->get("Acore::Document/path=" . $args->{path})
            if $self->cache;
        unless ($doc) {
            my $view = $self->storage->document->view(
                "path/all", {
                    key          => $args->{path},
                    include_docs => 1,
                }
            )->next;
            return unless $view;
            $doc = $view->{document};
            $self->cache->set("Acore::Document/path=" . $args->{path} => $doc)
                if $self->cache && $doc;
        }
    }
    return unless $doc;

    return Acore::Document->from_object($doc);
}

sub put_document {
    my $self = shift;
    my $doc  = shift;

    if ( $doc->id ) {
        require Acore::DateTime;
        $doc->updated_on( Acore::DateTime->now( time_zone => "local" ) );
        my $obj = $doc->to_object;
        $self->storage->document->put($obj);
        if ($self->cache) {
            $self->cache->set("Acore::Document/id=". $doc->id, $obj);
            $self->cache->remove("Acore::Document/path=". $doc->path);
        }
        return $doc;
    }
    else {
        my $obj = $doc->to_object;
        my $id  = $self->storage->document->post($obj);
        return $self->get_document({ id => $id });
    }
}

sub search_documents {
    my $self = shift;
    my $args = shift;

    return unless defined $args->{path};

    $args->{key_like}     = delete($args->{path}) . "%";
    $args->{include_docs} = 1;

    my $itr = $self->storage->document->view(
        "path/all" => $args
    );
    my @docs = $itr
        ? map { Acore::Document->from_object( $_->{document} ) } $itr->all
        : ();
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

dbh: DBI database handle.

setup_db: Flag of create tables.

=item get_user

Get Acore::User from storage.

 $user = $acore->get_user({ name => "username" });

=item save_user

Store Acore::User to storage.

 $acore->save_user($user);

=item create_user

Create Acore::User.

 $user = $acore->create_user({ name => "foo" });
 $user->set_password('secret');
 $acore->save_user($user);

=item authenticate_user

Authenticate user. Returns Acore::User.

 $user = $acore->authenticate_user({
     name     => "foo",
     password => "secret",
 });

=item new_document_id

Generate new document id.

=item get_document

Get Acore::Document from storage.

 $doc = $acore->get_document({ id => $id });
 $doc = $acore->get_document({ path => $path });

=item put_document

Store Acore::Document to storage.

 $doc = $acore->put_document($doc);

=item search_documents

Search Acore::Documents from storage, path first match.

 @doc = $acore->search_documents({ path => "/foo/bar" });

=item cache

Cache object which has Cache::Cache like interfaces.

 $acore->cache( Cache::Memcached->new({ ... } ) ); # enable cache

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
