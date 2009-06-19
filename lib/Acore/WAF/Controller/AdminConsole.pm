package Acore::WAF::Controller::AdminConsole;

use strict;
use warnings;
use Data::Dumper;
use List::MoreUtils;
use List::Util;
use utf8;

my $PermitRole = "AdminConsoleLogin";

sub is_logged_in {
    my ($self, $c) = @_;

    if ( $c->user && $c->user->has_role($PermitRole) ) {
        $c->log->debug("user logged in.");
        if ( $c->req->method eq "POST"
                 && $c->req->param('sid') ne $c->session->session_id )
        {
            $c->error( 500 => 'CSRF detacted.' );
        }
        return 1;
    }
    $c->log->debug( $c->user );

    $c->redirect( $c->uri_for('/admin_console/login_form') );
    $c->detach();
}

sub index {
    my ($self, $c) = @_;
    my @all_users = $c->acore->all_users;
    if (@all_users) {
        $c->redirect( $c->uri_for('/admin_console/login_form') );
    }
    else {
        $c->redirect( $c->uri_for('/admin_console/setup_at_first') );
    }
}

sub static {
    my ($self, $c, $args) = @_;

    $c->log->disabled(1);
    my ($path) = grep qr{/admin_console/}, @{ $c->config->{include_path} };
    my $file = Path::Class::file( $path, "../static/", $args->{filename} );
    $c->serve_static_file($file);
}

sub login_form_GET {
    my ($self, $c) = @_;
    $c->render("admin_console/login_form.mt");
}

sub login_form_POST {
    my ($self, $c) = @_;

    my $r = $c->req;
    if ( $c->login( $r->param('name'), $r->param('password') ) ) {
        $c->log->info("login succeeded.");
        $c->redirect( $c->uri_for('/admin_console/menu') ) ;
    }
    else {
        $c->form->set_error('login' => "FAILED");
        $c->render('admin_console/login_form.mt');
    }
}

sub logout {
    my ($self, $c) = @_;
    $c->logout;
    $c->redirect( $c->uri_for('/admin_console/login_form') );
}

sub menu_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    $c->render("admin_console/menu.mt");
}

sub setup_at_first_GET {
    my ($self, $c) = @_;

    my @all_users = $c->acore->all_users;
    if (@all_users) {
        $c->stash->{user_exists} = 1;
    }

    $c->render('admin_console/setup_at_first.mt');
}

sub setup_at_first_POST {
    my ($self, $c) = @_;

    $c->form->check(
        name      => [qw/ NOT_NULL ASCII /],
        password1 => [qw/ NOT_NULL ASCII /],
        { password => [qw/password1 password2/]} => ['DUP'],
    );
    if ($c->form->has_error) {
        $c->render('admin_console/setup_at_first.mt');
        $c->fillform;
        return;
    }

    my $user = $c->acore->create_user({
        name => $c->req->param('name'),
    });
    $user->add_role($PermitRole);
    $user->set_password($c->req->param('password1'));
    $c->acore->save_user($user);

    $c->render('admin_console/setup_done.mt');
}

sub user_list_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    $c->stash->{all_users} = [ $c->acore->all_users ];
    $c->render('admin_console/user_list.mt');
}

sub user_form_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    my $name = $c->req->param('name');
    $c->stash->{user} = $c->acore->get_user({ name => $name })
        or $c->error( 404, "user name='$name' not found" );

    $c->render('admin_console/user_form.mt');
}

sub user_form_POST {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    my $name = $c->req->param('name');
    my $user = $c->acore->get_user({ name => $name })
        or $c->error( 404, "user name='$name' not found" );

    if ( $c->req->param('password1') ne '' ) {
        $c->form->check(
            password1 => [qw/ NOT_NULL ASCII /],
            { password => [qw/password1 password2/]} => ['DUP'],
        );
        if ($c->form->has_error) {
            $c->stash->{user} = $user;
            $c->render('admin_console/user_form.mt');
            $c->fillform;
            return;
        }
        $user->set_password($c->req->param('password1'));
    }

    my @roles = grep { /\A[\w:]+\z/ } $c->req->param('roles');
    $user->roles(\@roles);
    $c->acore->save_user($user);

    $c->redirect(
        $c->uri_for('/admin_console/user_form', { name => $name })
    );
}

sub user_create_form_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    $c->render('admin_console/user_create_form.mt');
}

sub user_create_form_POST {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    my $name = $c->req->param('name');
    my $user = $c->acore->get_user({ name => $name });
    if ($user) {
        $c->form->set_error( name => 'EXISTS' );
    }

    $c->form->check(
        password1 => [qw/ NOT_NULL ASCII /],
        { password => [qw/password1 password2/]} => ['DUP'],
    );
    if ($c->form->has_error) {
        $c->render('admin_console/user_create_form.mt');
        $c->fillform;
        return;
    }

    $user = $c->acore->create_user({
        name => $name,
    });
    my @roles = grep { /\A[\w:]+\z/ } $c->req->param('roles');
    $user->roles(\@roles);
    $user->set_password( $c->req->param('password1') );
    $c->acore->save_user($user);

    $c->redirect(
        $c->uri_for('/admin_console/user_form', { name => $name })
    );
}

sub user_DELETE {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    my $name = $c->req->param('name');
    my $user = $c->acore->get_user({ name => $name })
        or $c->error( 404, "user name='$name' not found" );

    if ($c->user->name eq $user->name) {
        $c->error( 500, "Can't delete user logged in." );
    }

    $c->acore->delete_user($user);

    $c->render('admin_console/user_deleted.mt');
}

sub document_list_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    my $limit  = int( $c->req->param('limit') || 20 );
    my $page   = int( $c->req->param('page')  || 1  );
    my $offset = ( $page - 1 ) * $limit;

    $c->forward( $self => "_document_add_keys" );

    my $type  = $c->req->param('type');
    my $query = $c->req->param('q');
    if ( $type =~ /\A(?:path|tags)\z/ && $query ne '' ) {
        $c->stash->{all_documents} = [
            $c->acore->search_documents({
                $type  => $query,
                offset => $offset,
                limit  => $limit,
            }),
        ];
    }
    elsif ( $type && $query ne '' ) {
        my @args = ($c->req->param('match') eq 'like')
                 ? ( key_like => $query . "%" )
                 : ( key      => $query       );
        $c->stash->{all_documents} = [
            $c->acore->search_documents({
                view   => "${type}/all",
                offset => $offset,
                limit  => $limit,
                @args,
            }),
        ];
    }
    else {
        $c->stash->{all_documents} = [
            $c->acore->all_documents({
                offset  => $offset,
                limit   => $limit,
                reverse => 1,
            }),
        ];
    }
    $c->stash->{offset} = $offset;
    $c->stash->{limit}  = $limit;
    $c->stash->{page}   = $page;

    if ( $c->req->param('download') ) {
        require YAML;
        $c->render('admin_console/document_list_download.mt');
        $c->res->content_type('application/x-yaml; charset=utf-8');
    }
    else {
        $c->render('admin_console/document_list.mt');
        $c->fillform;
    }
}

sub _document_add_keys {
    my ($self, $c) = @_;

    return unless $c->req->param('update_keys');
    my @keys = grep /./, $c->req->param('keys');
    $c->session->set( document_show_keys => \@keys );
    $c->req->param('keys' => @keys);
}

sub document_form_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    $c->stash->{document}
        = $c->acore->get_document({ id => $c->req->param('id') });

    $c->render('admin_console/document_form.mt');
}

sub document_form_POST {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    my $id  = $c->req->param('id');
    my $doc = $c->acore->get_document({ id => $id });
    $c->error( 404 => "document not found." )
        unless $doc;

    $c->stash->{document} = $doc;

    $c->form->check(
        id   => [qw/ NOT_NULL ASCII /],
        path => [qw/ NOT_NULL ASCII /],
    );
    $doc->validate_to_update($c);

    if ( $c->form->has_error ) {
        $c->render('admin_console/document_form.mt');
        $c->fillform;
        return;
    }
    $doc->$_( $c->req->param($_) ) for qw/ path content_type /;

    $c->acore->put_document($doc);

    $c->redirect(
        $c->uri_for('/admin_console/document_form', { id => $id, _t => time } )
    );
}

sub document_create_form_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    my $classes = $c->config->{admin_console}->{document_classes};
    $c->log->debug("document_classes: @$classes") if $classes;
    my $class = $c->req->param('_class')
             || ( (ref $classes eq 'ARRAY') ? $classes->[0]
                                          : "Acore::Document" );
    if ( !$class->use || !$class->isa('Acore::Document') ) {
        die "Invalid class $@";
    }
    $c->stash->{_class} = $class;

    $c->render('admin_console/document_create_form.mt');
}

sub document_create_form_POST {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    $c->form->check(
        path => [qw/ NOT_NULL ASCII /],
    );

    my $class = $c->req->param('_class');
    if ( !$class->require || !$class->isa('Acore::Document') ) {
        $c->log->error($@);
        $c->form->set_error( _class => "INVALID" );
    }
    $c->stash->{_class} = $class;

    $c->form->check(
        path => [qw/ NOT_NULL ASCII /],
    );
    my $doc = $class->validate_to_create($c);

    if ( $c->form->has_error || !$doc ) {
        $c->render('admin_console/document_create_form.mt');
        $c->fillform;
        return;
    }
    $doc->$_( $c->req->param($_) ) for qw/ path content_type /;

    $doc = $c->acore->put_document($doc);

    $c->redirect(
        $c->uri_for('/admin_console/document_form', { id => $doc->id, _t => time } )
    );
}

sub document_DELETE {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    $c->forward( $self => "_off_auto_commit" );
    for my $id ( $c->req->param('id') ) {
        my $doc = $c->acore->get_document({ id => $id });
        next unless $doc;
        $c->acore->delete_document($doc);
    }
    $c->forward( $self => "_restore_auto_commit" );

    $c->render('admin_console/document_deleted.mt');
}

sub doc_class_GET {
    my ($self, $c) = @_;
    $c->forward( $self => "is_logged_in" );
    $c->render('admin_console/doc_class.mt');
}

sub _doc_class_validate {
    my ($self, $c) = @_;

    $c->form->check(
        class => [['REGEX', qr/\A[A-Z]([_a-zA-Z0-9]+|::)*[_a-zA-Z0-9]+\z/]],
    );

    my $class = $c->req->param('class');
    if ($c->form->has_error) {
        $c->render('admin_console/doc_class.mt');
        $c->fillform;
        $c->detach;
    }
    $c->stash->{class} = $class;
    ( $c->stash->{class_filename} = $class ) =~ s{::}{_}g;
    1;
}

sub doc_class_POST {
    my ($self, $c) = @_;
    $c->forward( $self => "is_logged_in" );
    $c->forward( $self => "_doc_class_validate" );

    if ($c->req->param('download-pm')) {
        my $html = $c->req->param('form-html');
        my @names = ($html =~ m/name=['"]\/(\w+)['"]/g );
        $c->stash->{names} = [ List::MoreUtils::uniq(@names) ];

        $c->render('admin_console/doc_class_pm.mt');
        $c->res->header(
            "Content-Type"        => "text/plain",
            "Content-Disposition" =>
                sprintf("attachment; filename=%s.pm", $c->stash->{class_filename}),
        );
    }
    elsif ($c->req->param('download-tmpl')) {
        my $body = $c->render_part('admin_console/doc_class_tmpl.mt');
        $body =~ s/\r*\n/\n/g;
        $c->res->body( $body );
        $c->res->header(
            "Content-Type"        => "text/plain",
            "Content-Disposition" =>
                sprintf("attachment; filename=%s_create_form.mt", $c->stash->{class_filename}),
        );
    }
}

sub view_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    my @design = $c->acore->storage->document->all_designs;
    $c->stash->{all_views} = [
        map { $_->{value}->{id} = $_->{id}; $_->{value} } @design
    ];
    $c->render('admin_console/view.mt');
}

sub view_form_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    my $id = $c->req->param('id');
    my $design = $c->acore->storage->document->get($id)
        or $c->error( 404 => "design not found" );
    $c->stash->{design} = $design;
    $c->render('admin_console/view_form.mt');
}

sub view_form_POST {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    $c->form->check(
        id => [['REGEX', qr{\A_design/\w+\z}]],
    );

    my $id     = $c->req->param('id');
    my $design = $c->acore->storage->document->get($id)
              || {
                    _id   => $id,
                    views => { all => { map => "", reduce => "" } },
                 };

    for my $view ( $c->req->param('views') ) {
        $c->form->check(
            "${view}_name" => ['NOT_NULL', 'ASCII'],
        );
    TYPE:
        for my $type (qw/ map reduce /) {
            my $code = $c->req->param("${view}_${type}");
            next TYPE unless $code;
            my $sub = eval $code;     ## no critic
            if ($@) {
                $c->form->set_error( "${view}_${type}" => 'SYNTAX_ERROR' );
            }
            elsif (ref $sub ne 'CODE') {
                $c->form->set_error( "${view}_${type}" => 'NOT_CODE_REF' );
            }
            else {
                $design->{views}->{$view}->{$type} = $code;
            }
        }
    }
    if ($c->form->has_error) {
        $c->stash->{design} = $design;
        $c->render('admin_console/view_form.mt');
        return $c->fillform;
    }

    $c->forward( $self, "_off_auto_commit" );
    my $backend = $c->acore->storage->document;
    $backend->put($design);
    $backend->create_view( $design->{_id}, $design );
    $c->forward( $self, "_restore_auto_commit" );

    $c->redirect(
        $c->uri_for(
            '/admin_console/view_form',
            { id => $design->{_id}, _t => time },
        )
    );
}

sub view_form_DELETE {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    my $id = $c->req->param('id');
    my $design = $c->acore->storage->document->get($id)
        or $c->error( 404 => "design not found" );

    $c->acore->storage->document->delete($design->{_id});
    $c->render('admin_console/view_deleted.mt');
}

sub view_create_form_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    my $map = q{
sub {
    my ($obj, $emit) = @_;
    # $emit->( $key, $value );
}
};
    my $design = {
        _id   => "",
        views => { all => { map => $map, reduce => "" } },
    };
    $c->stash->{design} = $design;
    $c->render('admin_console/view_form.mt');
}


sub view_test_POST {
    my ($self, $c) = @_;
    $c->forward( $self => "is_logged_in" );
    require JSON;

    my $map  = $c->forward( $self => "_eval_code", $c->req->param('map') );
    my $pair = $c->forward( $self => "_do_map", $map );
    if ( $c->req->param('reduce') ) {
        my $reduce =
            $c->forward( $self => "_eval_code", $c->req->param('reduce') );
        $pair = $c->forward( $self => "_do_reduce", $reduce, @$pair );
    }
    $c->stash->{pairs} = $pair;
    $c->render("admin_console/view_test.mt");
}

sub _eval_code {
    my ($self, $c, $code) = @_;

    $code = eval $code;  ## no critic
    if ($@) {
        $c->res->body("Error in eval map.: $@");
        $c->detach;
    }
    if (ref $code ne 'CODE') {
        $c->res->body("not CODE ref.");
        $c->detach;
    }
    $code;
}

sub _do_map {
    my ($self, $c, $map) = @_;

    my @pair;
    my $emit = sub {
        push @pair, [ $_[0], $_[1] ];
    };
    my @docs = $c->acore->all_documents({ limit => 20 });
    for my $doc (@docs) {
        eval {
            $map->( $doc->to_object, $emit );
        };
        if ($@) {
            return $c->res->body("Error at mapping.: $@");
        }
    }
    [ sort { $a->[0] cmp $b->[0] } @pair ];
}

sub _do_reduce {
    my ($self, $c, $reduce, @pair) = @_;

    my @result;
    my $pre_key = $pair[0]->[0];
    my @pre_values;
    for my $pair (@pair) {
        my ($key, $value) = @$pair;
        if ($key ne $pre_key) {
            my $result = eval { $reduce->( $pre_key, \@pre_values ) };
            if ($@) {
                $c->res->body("Error at reducing.: $@");
                $c->detach;
            }
            push @result, [ $pre_key, $result ];
            $pre_key    = $key;
            @pre_values = ();
        }
        push @pre_values, $value;
    }

    my $result = eval { $reduce->( $pre_key, \@pre_values ) };
    if ($@) {
        return $c->res->body("Error at reducing.: $@");
    }
    push @result, [ $pre_key, $result ];

    \@result;
}

sub upload_document_GET {
    my ($self, $c) = @_;
    $c->forward( $self => "is_logged_in" );
    $c->render('admin_console/upload_document.mt');
}

sub upload_document_POST {
    my ($self, $c) = @_;
    $c->forward( $self => "is_logged_in" );

    my $upload = $c->req->upload('file');
    my $loader = $c->acore->document_loader;

    $c->forward( $self, "_off_auto_commit" );
    eval {
        $loader->load( $upload->fh );
    };

    if ($@) {
        $c->form->set_error( exception => $@ );
        $c->acore->dbh->rollback;
    }
    if ( $loader->has_error ) {
        for my $error ( @{ $loader->errors } ) {
            $c->form->set_error( loader => $error );
        }
        $c->acore->dbh->rollback;
    }
    else {
        $c->stash->{notice}
            = sprintf "%d 件の Document が投入されました", $loader->loaded;
    }
    $c->forward( $self, "_restore_auto_commit" );

    $c->render('admin_console/upload_document.mt');
}

sub _off_auto_commit {
    my ($self, $c) = @_;
    $c->stash->{__auto_commit}   = $c->acore->dbh->{AutoCommit};
    $c->acore->dbh->{AutoCommit} = 0;
    1;
}

sub _restore_auto_commit {
    my ($self, $c) = @_;
    $c->acore->dbh->{AutoCommit} = $c->stash->{__auto_commit};
    1;
}


1;

__END__

=head1 DISPATCH TABLE

 connect "admin_console/",
    { controller => "Acore::WAF::Controller::AdminConsole",
      action     => "index" };
 connect "admin_console/static/:filename",
    { controller => "Acore::WAF::Controller::AdminConsole",
      action     => "static" };
 connect "admin_console/:action",
    { controller => "Acore::WAF::Controller::AdminConsole" };

