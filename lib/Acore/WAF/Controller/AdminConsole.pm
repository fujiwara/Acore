package Acore::WAF::Controller::AdminConsole;

use strict;
use warnings;
use Data::Dumper;

my $PermitRole = "AdminConsoleLogin";

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
    if ($c->user) {
        $c->render("admin_console/menu.mt");
    }
    else {
        $c->redirect( $c->uri_for('/admin_console/login_form') );
    }
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

    $c->stash->{all_users} = [ $c->acore->all_users ];
    $c->render('admin_console/user_list.mt');
}

sub document_list {
    my ($self, $c) = @_;

    my $limit  = 20;
    my $offset = ( int( $c->req->param('page') || 1 ) - 1 ) * $limit;

    $c->stash->{all_documents} = [
        $c->acore->all_documents({
            offset => $offset,
            limit  => $limit,
        }),
    ];
    $c->render('admin_console/document_list.mt');
}

1;

