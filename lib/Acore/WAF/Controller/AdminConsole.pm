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

sub user_list {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    $c->stash->{all_users} = [ $c->acore->all_users ];
    $c->render('admin_console/user_list.mt');
}

sub document_list {
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

    require YAML;
    my $obj  = eval { YAML::Load( $c->req->param('content') ) };
    if ($@ || !$obj) {
        $c->log->error("invalid YAML. $@");
        $c->form->set_error( content => "INVALID_YAML" );
        my $msg = $@;
        $msg =~  s{at .+? line \d+}{};
        $c->stash->{yaml_error_message} = $msg;
    }

    if ( $c->form->has_error ) {
        $c->render('admin_console/document_form.mt');
        $c->fillform;
        return;
    }

    for my $n ( keys %$obj ) {
        $doc->{$n} = $obj->{$n};
    }
    $doc->{_id}  = $id;
    $doc->{$_} = $c->req->param($_) for qw/ path content_type /;

    $c->acore->put_document($doc);

    $c->redirect(
        $c->uri_for('/admin_console/document_form', { id => $id, _t => time } )
    );
}

sub document_create_form_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    $c->render('admin_console/document_create_form.mt');
}

sub document_create_form_POST {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    $c->form->check(
        path => [qw/ NOT_NULL ASCII /],
    );
    require YAML;
    my $obj  = eval { YAML::Load( $c->req->param('content') ) };
    if ($@ || !$obj) {
        $c->log->error("invalid YAML. $@");
        $c->form->set_error( content => "INVALID_YAML" );
        my $msg = $@;
        $msg =~  s{at .+? line \d+}{};
        $c->stash->{yaml_error_message} = $msg;
    }

    my $class = $c->req->param('_class');
    if ( !$class->require || !$class->isa('Acore::Document') ) {
        $c->set_error( _class => "INVALID" );
    }

    if ( $c->form->has_error ) {
        $c->render('admin_console/document_create_form.mt');
        $c->fillform;
        return;
    }

    $obj->{$_} = $c->req->param($_) for qw/ path content_type /;
    my $doc = $c->acore->put_document( $class->new($obj) );

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

1;

