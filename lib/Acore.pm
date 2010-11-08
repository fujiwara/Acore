package Acore;

use strict;
use warnings;
use 5.008_001;
our $VERSION = "0.1005";
use Acore::Storage;
use Acore::User;
use Acore::Document;
use Acore::Transaction;
use Carp qw/ croak carp /;
use utf8;
use Any::Moose;
use Encode qw/ encode_utf8 /;
use Fcntl ':flock';
use Try::Tiny;

has storage => (
    is      => "rw",
    isa     => "Acore::Storage",
    lazy    => 1,
    default => sub {
        my $self = shift;
        Acore::Storage->new({ dbh => $self->{dbh} });
    },
    handles => {
        setup_db => "setup",
    },
);

has user_class => (
    is      => "rw",
    isa     => "Str",
    default => "Acore::User",
);

has cache => (
    is => "rw",
);

has dbh => (
    is => "rw",
);

has document_loader => (
    is      => "rw",
    lazy    => 1,
    default => sub {
        my $self = shift;
        require Acore::DocumentLoader;
        Acore::DocumentLoader->new({ acore => $self });
    },
);

has senna_index => (
    is      => "rw",
    lazy    => 1,
    default => sub {
        my $self = shift;
        require Senna;
        croak("Senna version >= 0.60000 required.")
            if Senna->VERSION < 0.60000;
        Senna::Index->open( $self->senna_index_path );
    },
);

has senna_index_path => (
    is => "rw",
);

has in_transaction => (
    is      => "rw",
    default => 0,
);

has transaction_data => (
    is      => "rw",
    default => sub { +{} },
    lazy    => 1,
);

before user_class => sub {
    my ($self, $user_class) = @_;
    return $self->{user_class}
        unless defined $user_class;
    $user_class->require
        or croak "Can't require $user_class. $@";
};

has auto_transaction => (
    is      => "rw",
    default => 0,
);

around put_document_multi => \&_wrap_txn;
around put_document       => \&_wrap_txn;
around delete_document    => \&_wrap_txn;

__PACKAGE__->meta->make_immutable;
no Any::Moose;

sub init_senna_index {
    my $self = shift;
    require Senna;
    croak("Senna version >= 0.60000 required.")
        if Senna->VERSION < 0.60000;

    my $index = Senna::Index->create({
        path               => $self->senna_index_path,
        key_size           => 0,
        initial_n_segments => 256,
        flags              => Senna::Constants::SEN_INDEX_NORMALIZE(),
        encoding           => Senna::Constants::SEN_ENC_UTF8(),
    });
}

sub lock_senna_index {
    my $self = shift;

    return $self->{lock_senna_index}
        if $self->{lock_senna_index};

    my $lock_file = $self->senna_index_path . ".lock";
    open my $fh, "+>", $lock_file
        or croak("Can't open $lock_file $!");
    flock $fh, LOCK_EX;

    $self->{lock_senna_index} = $fh
        if $self->in_transaction;

    return $fh;
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
    } $self->storage->user->all({ exclude_designs => 1 });
    @user;
}

sub search_users_has_role {
    my $self = shift;
    my $role = shift;

    my $itr = $self->storage->user->view(
        "roles/all", {
            key          => $role,
            include_docs => 1,
        }
    );
    my @user;
    while ( my $row = $itr->next ) {
        my $user = $row->{document};
        $user->{id} ||= $_->{id};
        bless $user, $self->user_class;
        $user->init;
        push @user, $user;
    }
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
    my $unbless_user = Acore::Document::unbless($user);
    $self->storage->user->put( $unbless_user );
    $self->cache->set( "Acore::User/name=" . $user->{name} => $unbless_user )
        if $self->cache;
    $user;
}

sub delete_user {
    my ($self, $user) = @_;
    $self->storage->user->delete($user->name);
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
              $_->{value}->{id} ||= $_->{id};
              $self->cache->set("Acore::Document/id=" . $_->{id} => $_->{value})
                  if $self->cache && $_;

              Acore::Document->from_object( $_->{value} )
          }
          $self->storage->document->all($args);
    return wantarray ? @docs : \@docs;
}

sub get_documents_by_id {
    my ($self, @id) = @_;

    my (%cached, %no_cached, @docs);

    my $cache = $self->cache;
    if ($cache) {
        for my $id (@id) {
            my $doc = $cache->get("Acore::Document/id=$id");
            if ($doc) {
                $cached{$id} = Acore::Document->from_object($doc);
            }
            else {
                $no_cached{$id} = 1;
            }
        }
        if (keys %no_cached == 0) { # 全部 cache から見つかった
            @docs = sort { $a->id cmp $b->id } values %cached;
            return wantarray ? @docs : \@docs;
        }
        @id   = keys %no_cached;
        @docs = values %cached;
    }

    push @docs, $self->all_documents({ id_in => \@id });
    @docs = sort { $a->id cmp $b->id } @docs;
    return wantarray ? @docs : \@docs;
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

    $doc = Acore::Document->from_object($doc);
    return if $args->{isa} && !$doc->isa( $args->{isa} );

    $doc;
}

sub put_document {
    my $self = shift;
    my ($doc, $options) = @_;
    $options ||= { update_timestamp => 1 };

    if ( $doc->id ) {
        if ( $options->{update_timestamp} ) {
            require Acore::DateTime;
            $doc->updated_on( Acore::DateTime->now() );
        }
        my $old_for_search;
        if ( $doc->does("Acore::Document::Role::FullTextSearch")
          && $self->senna_index_path ) {
            my $old_doc = $self->get_document({ id => $doc->id });
            if ($old_doc) {
                $old_for_search = $old_doc->for_search;
            }
        }

        my $obj = $doc->to_object;
        $self->storage->document->put($obj);
        if ($self->cache) {
            $self->cache->set("Acore::Document/id=". $doc->id, $obj);
            $self->cache->remove("Acore::Document/path=". $doc->path);
        }
        if ( defined $old_for_search ) {
            $doc->update_fts_index( $self, $old_for_search );
        }
        elsif ( $doc->does("Acore::Document::Role::FullTextSearch")
             && $self->senna_index_path ) {
            $doc->create_fts_index( $self );
        }

        return $doc;
    }
    else {
        my $obj = $doc->to_object;
        my $id  = $self->storage->document->post($obj);
        $doc = $self->get_document({ id => $id });

        $doc->create_fts_index( $self )
            if $doc->does("Acore::Document::Role::FullTextSearch")
            && $self->senna_index_path;

        return $doc;
    }
}

sub put_document_multi {
    my $self = shift;
    my @doc  = @_;
    my %old_for_search;
    my (@put_doc, @post_doc);
    for my $doc (@doc) {
        if ( $doc->id ) {
            my $id = $doc->id;
            my $old_for_search;
            if ( $doc->does("Acore::Document::Role::FullTextSearch")
              && $self->senna_index_path )
            {
                my $old_doc = $self->get_document({ id => $id });
                if ($old_doc) {
                    $old_for_search{$id} = $old_doc->for_search;
                }
            }
            push @put_doc, $doc;
        }
        else {
            push @post_doc, $doc;
        }
    }
    my @return_doc;

    if (@put_doc) {
        my @put_obj = map { $_->to_object } @put_doc;
        $self->storage->document->put_multi(@put_obj);
        my $n = 0;
        for my $doc (@put_doc) {
            if ($self->cache) {
                $self->cache->set("Acore::Document/id=". $doc->id, $put_obj[$n]);
                $self->cache->remove("Acore::Document/path=". $doc->path);
            }
            if ( defined $old_for_search{ $doc->id } ) {
                $doc->update_fts_index( $self, $old_for_search{ $doc->id } );
            }
            elsif ( $doc->does("Acore::Document::Role::FullTextSearch")
                 && $self->senna_index_path )
            {
                $doc->create_fts_index( $self );
            }
            push @return_doc, $doc;
            ++$n;
        }
    }

    if (@post_doc) {
        my @post_obj = map { $_->to_object } @post_doc;
        my @id  = $self->storage->document->post_multi(@post_obj);
        my @doc = $self->all_documents({ id_in => \@id });
        for my $doc (@doc) {
            $doc->create_fts_index( $self )
                if $doc->does("Acore::Document::Role::FullTextSearch")
                && $self->senna_index_path;
        }
        push @return_doc, @doc;
    }
    return @return_doc;
}

sub _search_documents_args {
    my $self = shift;
    my $args = shift;

    my $view;
    if (defined $args->{path}) {
        $args->{key_start_with} = delete($args->{path});
        $view = "path/all";
    }
    elsif (defined $args->{tag} || defined $args->{tags}) {
        $args->{key} = delete $args->{tag} || delete $args->{tags};
        $view = "tags/all";
    }
    elsif (defined $args->{view}) {
        $view = delete $args->{view};
    }
    else {
        croak("no arguments path or tags or view");
    }
    return ($view, $args);
}

sub search_documents {
    my $self = shift;
    my $args = shift;
    my $view;
    ($view, $args) = $self->_search_documents_args($args);
    $args->{include_docs} = 1;

    my $itr = $self->storage->document->view( $view => $args );
    my @docs = $itr
        ? map { Acore::Document->from_object( $_->{document} ) } $itr->all
        : ();
    return wantarray ? @docs : \@docs;
}

sub search_documents_count {
    my $self = shift;
    my $args = shift;
    my $view;
    ($view, $args) = $self->_search_documents_args($args);
    $args->{include_docs} = 0;

    my $itr   = $self->storage->document->view( $view => $args );
    my $count = 0;
    $count++ while $itr->next;
    $count;
}

sub search_documents_count_by_key {
    my $self = shift;
    my $args = shift;
    my $view;
    ($view, $args) = $self->_search_documents_args($args);
    $args->{include_docs} = 0;

    my $itr = $self->storage->document->view($view);
    my %count;
    while ( my $map = $itr->next ) {
        no warnings;
        $count{ $map->{key} } += 1;
    }
    %count;
}

sub delete_document {
    my ($self, $doc) = @_;

    if ( my $cache = $self->cache) {
        $cache->remove("Acore::Document/id=". $doc->id);
        $cache->remove("Acore::Document/path=". $doc->path);
    }
    my $old_for_search;
    if ( $doc->does("Acore::Document::Role::FullTextSearch")
      && $self->senna_index_path )
    {
        my $old_doc = $self->get_document({ id => $doc->id });
        if ($old_doc) {
            $old_for_search = $old_doc->for_search;
        }
    }
    my $result = $self->storage->document->delete($doc->id);
    $doc->delete_fts_index( $self, $old_for_search )
        if $old_for_search;
    $doc->call_trigger('delete');

    return $result;
}

sub fulltext_search_documents {
    my $self = shift;
    my $args = shift;

    my $rs = $self->senna_index->select( encode_utf8 $args->{query} );
    if ( $rs->nhits == 0 ) {
        return wantarray ? () : [];
    }
    my $offset = $args->{offset} || 0;
    my $limit  = $args->{limit}  || 100;
    $rs->sort($limit + $offset);
    my (@id, %order);
    my $n = 0;
    while ( my $r = $rs->next ) {
        next if ++$n <= $offset;
        push @id, $r->key;
        $order{ $r->key } = $n;
    }
    my @docs = sort { $order{$a->id} <=> $order{$b->id} }
        $self->get_documents_by_id(@id);

    return wantarray ? @docs : \@docs;
}

sub txn_begin {
    my $self = shift;

    $self->dbh->begin_work;
    $self->in_transaction(1);
    $self->transaction_data({ senna => [], });
}

sub txn_commit {
    my $self = shift;
    delete $self->{lock_senna_index};
    $self->in_transaction(0);
    $self->dbh->commit;
}

sub txn_rollback {
    my $self = shift;

    $self->dbh->rollback;
    $self->in_transaction(0);

    if ( $self->senna_index_path ) {
        my $index = $self->senna_index;
        my $data  = $self->transaction_data->{senna};
        for my $act ( reverse @$data ) {
            # restore senna index
            $index->update(
                $act->[0],
                encode_utf8($act->[1]),
                encode_utf8($act->[2]),
            );
        }
    }
    delete $self->{lock_senna_index};
}

sub _wrap_txn {
    my ($next, $self, @args) = @_;
    if ($self->auto_transaction) {
        $self->txn_do(sub { $next->($self, @args) });
    }
    else {
        $next->($self, @args);
    }
}

sub txn_do {
    my $self = shift;
    my $sub  = shift;

    return $sub->() if $self->in_transaction;

    my $txn = $self->txn;
    my (@r, $r);
    my $array_context = wantarray;
    try {
        $array_context ? @r = $sub->()
                       : $r = $sub->();
    }
    catch {
        $txn->rollback;
        die $_;
    };
    $txn->commit;
    $array_context ? @r : $r;
}

sub txn {
    my $self = shift;
    return Acore::Transaction->new($self);
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
  $num = $acore->search_documents_count({ path => "/path/to" });

  @doc = $acore->all_documents({ offset => 0, limit => 10 });
  @doc = $acore->get_documents_by_id( 1, 2, 3 );

  $acore->delete_document($doc);

  $acore->txn_do( sub {
      # in transaction
      $acore->put_document($doc1);
      $acore->put_document($doc2);
  });

  {
      $txn = $acore->txn;
      # in transaction;
      $txn->commit;
  }

=head1 DESCRIPTION

Acore is AnyCMS core module.

=head1 METHODS

=over 4

=item new

Constractor.

 $acore = Acore->new({ dbh => $dbh });

dbh: DBI database handle.

=item setup_db

Create tables in Storage.

=item all_users

Returns all Acore::User from storage.

 @user = $acore->all_users;

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

=item search_users_has_role

Returns all Acore::User which has role from storage.

 @user = $acore->search_users_has_role("AdminConsoleLogin");

=item new_document_id

Generate new document id.

=item get_document

Get Acore::Document from storage.

 $doc = $acore->get_document({ id => $id });
 $doc = $acore->get_document({ path => $path });

Argument 'isa' has set, returns only $doc->isa($args->{isa})
 $doc = $acore->get_document({ id => $id, isa => "MyDocument" });

=item put_document

Store Acore::Document to storage.

 $doc = $acore->put_document($doc);
 $doc = $acore->put_document($doc, { update_timestamp => 0 }); # keep updated_on

=item search_documents

Search Acore::Documents from storage, path (first match) or tag (full match) or view.

 @doc = $acore->search_documents({ path => "/foo/bar" });
 @doc = $acore->search_documents({ tag  => "cat" });
 @doc = $acore->search_documents({ view => "xxx/all" });
 
 # options
 @doc = $acore->search_documents({
     view          => "xxx/all",
     key           => ["foo", "bar"],
     key_reverse   => 1,
     value_reverse => 1,
     limit         => 20,
     offfset       => 10,
 });

Arguments are pass to DBIx::CouchLike->view( $view, \%arguments );

=item search_documents_count

Search Acore::Documents from storage and returning count.

 $num = $acore->search_documents_count({ path => "/foo/bar" });
 $num = $acore->search_documents_count({ tag  => "cat" });
 $num = $acore->search_documents_count({ view => "xxx/all", key => "foo" });

=item search_documents_count_by_key

Search Acore::Documents from storage and returning count grouped by key.

 %num = $acore->search_documents_count_by_key({ view => "tags/all" });
 # %num = (
 #    tagA => $num_of_tagA,
 #    tagB => $num_of_tagB,
 # )

=item fulltext_search_documents

Full text search Acore::Documents. Senna (>=0.6000) is required.

 $acore->senna_index_path("/path/to/index_file");
 $acore->init_senna_index; # at first only

 @docs = $acore->fulltext_search_documents({ query => $query, limit => $limit });
 # query: Senna query string. see http://qwik.jp/senna/query.html

=item delete_document

Delete the document from storage.

 $acore->delete_document($doc);

=item cache

Cache object which has Cache::Cache like interfaces.

 $acore->cache( Cache::Memcached->new({ ... } ) ); # enable cache

=item txn

Return Acore::Transaction object.

 {
    my $txn = $acore->txn;
    # begin transcation
    # ...
 }  # rollback!

When txn object will be destroyed (and if it's not committed or rollbacked yet), transaction will be rollback automatically.

 {
    my $txn = $acore->txn;
    # begin transcation
    $txn->commit;
 }  # commited.

=item txn_begin

Begin transaction.

=item txn_commit

Commit transaction.

=item txn_rollback

Rollback transaction.

=item txn_do

Do coderef in transcation scope.

 eval {
     $acore->txn_do(sub {
        # do something
     });
 };
 if ( $exception = $@ ) {
     # rollbacked
 }

=item auto_transaction

If true, automaticaly wrap by txn_do for methods delete_document, put_document(_multi).

default false.

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

L<DBIx::CouchLike>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
