package t::WAFTest::Controller;

use strict;
use warnings;
use utf8;

sub index {
    my ($self, $c) = @_;
    $c->res->body("index");
}

sub ok {
    my ($self, $c) = @_;
    $c->res->body("ok");
}

sub rd {
    my ($self, $c) = @_;
    $c->redirect( $c->uri_for('/redirect_to') );
}

sub rd301 {
    my ($self, $c) = @_;
    $c->redirect( $c->uri_for('/redirect_to'), 301 );
}

sub error {
    die;
}

sub forward {
    my ($self, $c) = @_;
    $c->log->info("forward");
    $c->forward("t::WAFTest::Controller::X", "xyz", [qw/ a b c /]);
}

sub forward_internal {
    my ($self, $c) = @_;
    $c->log->info("forward");
    $c->forward($self, "ok");
}

sub render {
    my ($self, $c) = @_;
    $c->stash->{value} = "<html>";
    $c->render("test.mt");
}

sub sample_plugin {
    my ($self, $c) = @_;
    $c->sample_method;
}

sub adoc {
    my ($self, $c, $args) = @_;
    $c->serve_acore_document( "/" . $args->{path} );
}

sub say {
    my ($self, $c) = @_;
    $c->res->body(
        $c->encode("入力は" . $c->req->params->{'input'} . "です。\n")
    );
}

sub say_mt {
    my ($self, $c) = @_;
    $c->render("say.mt");
}

sub say_multi {
    my ($self, $c) = @_;
    my @input = $c->req->param('input');
    $c->res->body(
        $c->encode("入力は" . join("", @input) . "です。\n")
    );
}

sub rest_GET    { $_[1]->res->body("GET")    }
sub rest_POST   { $_[1]->res->body("POST")   }
sub rest_PUT    { $_[1]->res->body("PUT")    }
sub rest_DELETE { $_[1]->res->body("DELETE") }

sub name_is_not_null {
    my ($self, $c) = @_;

    my $res = $c->form->check(
        name => [qw/ NOT_NULL /],
    );
    $c->res->body( $res->has_error ? "ng" : "ok" );
}

package t::WAFTest::Controller::X;

sub xyz {
    my ($self, $c, $args) = @_;

    $c->log->info("forwarded");
    $c->res->body( join("", @$args) );
}

1;


