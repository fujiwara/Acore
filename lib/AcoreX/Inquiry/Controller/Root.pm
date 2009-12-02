package AcoreX::Inquiry::Controller::Root;

use strict;
use warnings;
use Any::Moose;
our $Location;

with "Acore::WAF::Controller::Role::Locatable";

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub _config {
    my ($c) = @_;
    $c->config->{"AcoreX::Inquiry"}->{$Location} || {};
}

sub _auto {
    my ($self, $c, $args) = @_;
    $args->{location} ||= "inquiry";
    $self->set_location($c, $args);

    if ( $c->req->method eq 'POST' && $c->does('Acore::WAF::Plugin::Session') ) {
        $c->log->debug("session id: " . $c->session->session_id);
        $c->log->debug("session id: " . $c->req->param('sid') );
        if ( $c->req->param('sid') ne $c->session->session_id ) {
            $c->error( 500 => "CSRF detected" );
        }
    }
    my $messages = _config($c)->{messages};
    if ($messages) {
        my $cur_messages = {};
        for my $key ( keys %$messages ) {
            $cur_messages->{"$Location/$key"} = $messages->{$key};
        }
        $c->form->set_message( %$cur_messages );
    }

    1;
}

sub _validate {
    my ($self, $c) = @_;

    my $rules = _config($c)->{rules}
        or return;
    my $cur_rules = {};
    for my $key ( keys %$rules ) {
        $cur_rules->{"$Location/$key"} = $rules->{$key};
    }
    $c->form->check( %$cur_rules );
    if ($c->form->has_error) {
        $c->render("$Location/form.mt");
        $c->fillform;
        $c->detach;
    }
}

sub form_GET {
    my ($self, $c, $args) = @_;
    $c->render("$Location/form.mt");
}

sub confirm_POST {
    my ($self, $c, $args) = @_;

    $c->forward( $self => "_validate" );
    $c->render("$Location/confirm.mt");
    $c->fillform;
}

sub finish_GET {
    my ($self, $c, $args) = @_;
    $c->render("$Location/finish.mt");
}

sub finish_POST {
    my ($self, $c, $args) = @_;

    if ($c->req->param('back')) {
        $c->render("$Location/form.mt");
        $c->fillform;
        return;
    }

    $c->forward( $self => "_validate" );

    my $id  = $c->acore->new_document_id;
    my $obj = {
        _id  => $id,
        path => "/$Location/$id",
    };
    for my $key ( $c->req->param ) {
        $key =~ m{^$Location/(.+)$} or next;
        $key = $1;
        my @value = $c->req->param("$Location/$key");
        $obj->{$key} = @value > 1 ? \@value : $value[0];
    }
    my $document_class = _config($c)->{document_class} || "Acore::Document";
    $document_class->require
        or $c->error("Can't require $document_class. $@");

    $c->acore->put_document( $document_class->new($obj) );
    if ($c->does('Acore::WAF::Plugin::Session')) {
        $c->flash->set( id => $id );
        $c->redirect(
            $c->uri_for("$Location/finish")
        );
    }
    else {
        $c->stash->{id} = $id;
        $c->render("$Location/finish.mt");
    }
}

1;

__END__

