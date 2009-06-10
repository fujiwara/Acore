package Acore::WAF::Controller::AdminConsole;

use strict;
use warnings;
use Data::Dumper;

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

    my $limit  = 20;
    my $page   = int( $c->req->param('page') || 1 );
    my $offset = ( $page - 1 ) * $limit;

    $c->form->check(
        type => [['CHOICE', 'path', 'tag', '']],
    );
    $c->error( 500 ) if $c->form->has_error;

    $c->forward( $self => "_document_add_keys" );

    my $type  = $c->req->param('type');
    my $query = $c->req->param('q');
     if ( $type && $query ne '' ) {
        $c->stash->{all_documents} = [
            $c->acore->search_documents({
                $type  => $query,
                offset => $offset,
                limit  => $limit,
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
    $c->render('admin_console/document_list.mt');
    $c->fillform;
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

    my $id  = $c->req->param('id');
    my $doc = $c->acore->get_document({ id => $id });
    $c->error( 404 => "document not found." )
        unless $doc;

    $c->acore->delete_document($doc);

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
#    $class->require
#        and $c->form->set_error( class => "EXISTS" );
    if ($c->form->has_error) {
        $c->render('admin_console/doc_class.mt');
        $c->fillform;
        $c->detach;
    }
    $c->stash->{class} = $class;
    ( $c->stash->{class_filename} = $class ) =~ s{::}{_}g;
    1;
}

sub doc_class_pm_GET {
    my ($self, $c) = @_;
    $c->forward( $self => "is_logged_in" );
    $c->forward( $self => "_doc_class_validate" );

    $c->render('admin_console/doc_class_pm.mt');

    $c->res->header(
        "Content-Type"        => "text/plain",
        "Content-Disposition" =>
            sprintf("attachment; filename=%s.pm", $c->stash->{class_filename}),
    );
}

sub doc_class_tmpl_GET {
    my ($self, $c) = @_;
    $c->forward( $self => "is_logged_in" );
    $c->forward( $self => "_doc_class_validate" );
    $c->render('admin_console/doc_class_tmpl.mt');

    $c->res->header(
        "Content-Type"        => "text/plain",
        "Content-Disposition" =>
            sprintf("attachment; filename=%s_create_form.mt", $c->stash->{class_filename}),
    );
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

