package t::WAFTest::Controller;

use strict;
use warnings;
use utf8;

sub index {
    my ($self, $c, $args) = @_;
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

sub render_string {
    my ($self, $c) = @_;
    $c->stash->{value} = "<html>";
    my $body = $c->render_string(<<'END'
? my $c = $_[0];
uri: <?= $c->req->uri ?>
html: <?= $c->stash->{value} ?>
raw1: <?= raw $c->stash->{value} ?>
raw2: <?= $c->stash->{value} | raw ?>
日本語は UTF-8 で書きます
?= $c->render_part("include.mt");
END
);
    $c->res->body($body);
}

sub sample_plugin {
    my ($self, $c) = @_;
    $c->sample_method;
}

sub static_file {
    my ($self, $c, $args) = @_;
    use Path::Class qw/ file /;
    file("t/tmp/static_file.txt")->openw->print("STATIC_FILE");
    qx{ touch -m -t 200907281122.33 t/tmp/static_file.txt };
    $c->serve_static_file("t/tmp/static_file.txt");
}

sub static_file_fh {
    my ($self, $c, $args) = @_;
    use Path::Class qw/ file /;
    file("t/tmp/static_file.txt")->openw->print("STATIC_FILE");
    qx{ touch -m -t 200907281122.33 t/tmp/static_file.txt };
    my $fh = file("t/tmp/static_file.txt")->openr;
    $c->res->content_type("text/plain; charset=utf-8");
    $c->res->body($fh);
}

sub adoc {
    my ($self, $c, $args) = @_;
    $c->serve_acore_document( "/" . $args->{path} );
}

sub say {
    my ($self, $c) = @_;
    $c->res->body(
        $c->encode("入力は" . $c->req->param('input') . "です。\n")
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

sub minimal_cgi {
    my ($self, $c) = @_;
    my @input = $c->req->param('input');

    my $body = "入力は" . join("", @input) . "です。\n";
    $body   .= "base=" . $c->req->base . "\n";
    $body   .= "path=" . $c->req->path . "\n";
    $body   .= "address=" . $c->req->address . "\n";
    $body   .= "user_agent=" . $c->req->user_agent . "\n";
    $c->res->body( $body );
}

sub _private {
    my ($self, $c) = @_;
    $c->res->body('private action');
}

sub cache_set {
    my ($self, $c) = @_;
    $c->cache->set( key => $c->encode( $c->req->param('value') ) );
    $c->res->body( $c->cache->get('key') );
}

sub cache_get {
    my ($self, $c) = @_;
    $c->res->body( $c->cache->get('key') );
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

sub login {
    my ($self, $c) = @_;
    if ( $c->login( $c->req->param('name'), $c->req->param("password") ) ) {
        $c->res->body("login_ok");
    }
    else {
        $c->res->body("login_ng");
    }
}

sub logged_in {
    my ($self, $c) = @_;

    $c->res->body( $c->user ? "logged_in" : "not_logged_in" );
}

sub logout {
    my ($self, $c) = @_;
    $c->logout;
    $c->res->body( "logout_ok" );
}

sub detach {
    my ($self, $c) = @_;
    $c->res->body("before detach");
    $c->detach();
    $c->res->body("after detach"); # not reached
}

sub welcome {
    my ($self, $c) = @_;
    my $body = $c->welcome_message;
    utf8::encode($body);
    $c->res->body($body);
}

sub render_package {
    my ($self, $c) = @_;
    $c->render("render_package.mt");
}

sub render_filter {
    my ($self, $c) = @_;
    $c->render("render_filter.mt");
}

sub form {
    my ($self, $c) = @_;
    $c->render('form.mt');
    $c->fillform();
}

sub anti_csrf_GET {
    my ($self, $c) = @_;
    $c->res->body(
        $c->render_string(q{
? my $c = $_[0];
<input type="hidden" name="<?= $c->config->{anti_csrf}->{param} ?>" value="<?= $c->onetime_token ?>">})
    );
}

sub anti_csrf_POST {
    my ($self, $c) = @_;

    $c->csrf_proof
        or $c->error( 400 => "bad request" );
    $c->res->body("ok");
}

sub handle_args {
    my ($self, $c, $args) = @_;
    $c->res->body("args.foo=" . $args->{foo});
}

sub _sites_auto {
    my ($self, $c, $args) = @_;
    return $c->req->param('auto_ng') ? undef : 1;
}

sub set_flash {
    my ($self, $c) = @_;
    $c->flash->set( xxx => $c->req->param('value') );
    $c->redirect( $c->uri_for('/act/get_flash') );
}

sub get_flash {
    my ($self, $c) = @_;
    my $value = $c->flash->get('xxx');
    $c->res->body("flash=$value");
}

sub mobile {
    my ($self, $c) = @_;
    my $sid = $c->session->session_id;
    $c->res->body( $c->render_string(
        q{session_id: <?= $_[0]->session->session_id ?>
          <a href="<?= $_[0]->uri_for('/act/mobile') ?>"></a>}
    ));
}

sub page_cache_enabled {
    my ($self, $c) = @_;

    $c->res->header("Last-Modified" => HTTP::Date::time2str(1234567890));
    $c->res->body("page-cached");
}

sub page_cache_enabled_but_no_cache {
    my ($self, $c) = @_;

    $c->res->header("Cache-Control" => "no-cache, no-store");
    $c->res->body("page-cached");
}

sub page_cache_enabled_age {
    my ($self, $c) = @_;

    $c->res->header("Cache-Control" => "max-age=2");
    $c->res->body("page-cached");
}

sub page_cache_disabled {
    my ($self, $c) = @_;
    $c->res->body("no-cached");
}

sub psgi {
    my ($self, $c) = @_;
    my $env = $c->psgi_env;
    my $body = "";
    for my $key (sort keys %$env) {
        $body .= "$key: $env->{$key}\n";
    }
    $c->log->info("running on psgi");
    $c->res->body($body);
}

sub forward_main {
    my ($self, $c) = @_;
    $c->log->info("forward_main");
    $c->forward( $self => 'forward_to_1' );
    $c->res->body("not reached here");
}
sub forward_to_1 {
    my ($self, $c) = @_;
    $c->log->info("forward_to_1");
    $c->forward( $self => 'forward_to_2' );
}
sub forward_to_2 {
    my ($self, $c) = @_;
    $c->log->info("forward_to_2");
    $c->res->body("error on forward_to_2");
    $c->error( 500 => 'error' );
}

sub error_message_args {
    my ($self, $c) = @_;
    $c->error( 500 => "Error message %s", $c->req->param("uniq") );
}

package t::WAFTest::Controller::X;

sub xyz {
    my ($self, $c, $args) = @_;

    $c->log->info("forwarded");
    $c->res->body( join("", @$args) );
}


1;


