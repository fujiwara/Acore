package Acore::WAF::Controller::AdminConsole;

use strict;
use warnings;
use Data::Dumper;

my $PermitRole = "AdminConsoleLogin";

sub _is_logged_in {
    my ($self, $c) = @_;
    my $user = $c->session->get('acore_user');
    if ( $user && $user->has_role($PermitRole) ) {
        return 1;
    }
    else {
        $c->log->error('user not logged in');
        $c->redirect( $c->uri_for("login_form") );
        return;
    }
}

sub login_form_GET {
    my ($self, $c) = @_;
    $c->log( debug => "uri_for=". $c->uri_for("login_form") );
    $c->render("admin_console/login_form.mt");
}

sub login_form_POST {
    my ($self, $c) = @_;

    $c->prepare_acore;
    my $user = $c->acore->authenticate_user({
        name     => $c->req->param('name'),
        password => $c->req->param('password'),
    });
    if ($user) {
        $c->session->set( acore_user => $user );
        $c->redirect( $c->uri_for("menu") );
    }
    else {
        $c->stash->{login_failed} = 1;
        $c->render("admin_console/login_form.mt");
    }
}

sub menu_GET {
    my ($self, $c) = @_;
    $self->_is_logged_in($c) or return;
    $c->render("admin_console/menu.mt");
}

sub setup_at_first_GET {
    my ($self, $c) = @_;
    $c->render('admin_console/setup_at_first.mt');
}

sub setup_at_first_POST {
    my ($self, $c) = @_;

    my $password = $c->req->param('password');
    if ($password) {
        $c->prepare_acore;
        my $user = $c->acore->create_user({
            name => "root",
        });
        $user->add_role($PermitRole);
        $user->set_password($password);
        $c->acore->save_user($user);
    }

    $c->render('admin_console/setup_at_first.mt');
}

1;

