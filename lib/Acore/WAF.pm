package Acore::WAF;

use strict;
use warnings;
use Any::Moose;
use Text::MicroTemplate::File ();
use Path::Class ();
use HTTP::Date;
use utf8;
use Encode ();
use UNIVERSAL::require;
use Acore::WAF::Log;
use Acore::MIME::Types;
use URI::Escape;
use CGI::ExceptionManager;
use CGI::ExceptionManager::StackTrace;
use Clone qw/ clone /;
use Data::Dumper;

our $VERSION = 0.1;

has stash => (
    is      => "rw",
    isa     => "HashRef",
    default => sub { +{} },
);

has config  => (
    is      => "rw",
    isa     => "HashRef",
    default => sub { +{} },
);

has request => (
    is  => "rw",
    isa => "HTTP::Engine::Request",
);
*req = \&request;

has response => (
    is      => "rw",
    default => sub { HTTP::Engine::Response->new },
);
*res = \&response;

has acore => (
    is         => "rw",
    isa        => "Acore",
    lazy_build => 1,
);

has _triggers => (
    is  => "rw",
    isa => "HashRef",
);

has log => (
    is         => "rw",
    isa        => "Acore::WAF::Log",
    lazy_build => 1,
);

has renderer => (
    is         => "rw",
    lazy_build => 1,
);

has encoding => (
    is      => "rw",
    default => "utf-8",
);

has encoder => (
    is         => "rw",
    lazy_build => 1,
    handles    => {
        "encode" => "encode",
        "decode" => "decode",
    },
);

has user => (
    is         => "rw",
    lazy_build => 1,
);

has debug => (
    is => "rw",
);

sub _build_log {
    my $self = shift;
    my $log  = Acore::WAF::Log->new;
    $log->level( $self->config->{log}->{level} )
        if defined $self->config->{log}->{level};
    $log;
}

sub _build_renderer {
    my $self = shift;
    my $path = $self->path_to("templates");
    Text::MicroTemplate::File->new(
        include_path => [ $path, @{ $self->config->{include_path} } ],
        use_cache    => 1,
    );
}

sub _build_encoder {
    my $self = shift;
    Encode::find_encoding( $self->encoding )
        or die "Can't found encoding " . $self->encoding;
}

sub _build_acore {
    my $self = shift;

    require Acore;
    require DBI;
    my $dbh  = DBI->connect( @{ $self->config->{dsn} } )
        or die "Can't connect DB: " . DBI->errstr;
    Acore->new({ dbh => $dbh });
}

sub _build_user {
    my $self = shift;
    $self->session->get('user');
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

my $Triggers = {};

sub setup {
    my $class   = shift;
    my @plugins = @_;

    $Triggers->{$class} = +{
        BEFORE_DISPATCH => [],
        AFTER_DISPATCH  => [],
    };
    my $log = Acore::WAF::Log->new;
    for my $plugin (@plugins) {
        my $p_class = $plugin =~ /^\+/ ? $plugin : "Acore::WAF::Plugin::${plugin}";
        $log->debug("loading plugin: $p_class");
        {
            no warnings 'redefine';
            $p_class->use or die "Can't load plugin: $@";
        }
        $p_class->setup($class) if $p_class->can('setup');
    }
    $log->flush;
}

sub path_to {
    my $self = shift;
    my $obj = Path::Class::dir( $self->config->{root} || ".", @_ );
    return $obj if -d $obj;
    return Path::Class::file( $obj->stringify );
}

sub _decode_request {
    my $self = shift;
    my $req  = $self->request;
    my $enc  = $self->encoder;

    for my $n ( $req->param ) {
        $req->param(
            $n => map { $enc->decode($_) } $req->param($n)
        );
    }
}

sub handle_request {
    my $self = shift;
    my ($config, $req) = @_;
    my $class = ref $self;

    $self->config($config);
    $config->{include_path} ||= [];
    $self->encoding( $config->{encoding} )
        if $config->{encoding};

    $self->request($req);
    $self->_decode_request;
    $self->_triggers( $Triggers->{$class} );
    $self->debug( $ENV{DEBUG} || $config->{debug} || 0 );

    no warnings "redefine";
    local *CGI::ExceptionManager::StackTrace::output = sub {
        $self->_output_stack_trace(@_);
    };

    CGI::ExceptionManager->run(
        callback => sub {
            $self->_call_trigger('BEFORE_DISPATCH');
            $self->_dispatch;
            $self->_call_trigger('AFTER_DISPATCH');
            return $self->response;
        },
        powered_by => __PACKAGE__,
    );
    $self->finalize();
    $self->log->flush;
    return $self->response;
}

sub _output_stack_trace {
    my $self = shift;
    my ($error, %args) = @_;

    $self->log->error( $error->{message} );
    my $res = $self->res;
    $res->status(500);
    $res->headers->content_type('text/html; charset=utf-8');

    if ( $self->debug ) {
        my $body = $error->as_html(%args);
        utf8::encode($body);
        $res->body($body);
    }
    else {
        $res->body("Internal Server Error");
    }
    $res;
}

sub finalize {
    my $self = shift;

    my $c_type = $self->res->content_type || "text/html";
    if ( $c_type =~ m{^text/} && $c_type !~ m{; *charset=}i ) {
        $c_type .= "; charset=" . ($self->config->{charset} || $self->encoding)
    }
    $self->res->content_type($c_type);
    1;
}

sub _dispatch {
    my ( $self ) = @_;

    my $dispatcher = (ref $self) . "::Dispatcher";

    my $rule = $dispatcher->match(
        ($ENV{GATEWAY_INTERFACE} and $ENV{GATEWAY_INTERFACE} =~ /^CGI/)
            ? do {
                my $r = clone $self->req;
                $r->path($ENV{PATH_INFO});
                $r
            }
            : $self->req
        );
    if ($rule) {
        my $action = $rule->{action};
        $self->error( 404 => "dispatch action $action is private." )
            if $action =~ /^_/;

        local $Data::Dumper::Indent = 1;
        $self->log->debug(
            "dispatch rule: " . Data::Dumper->Dump([$rule], ["rule"])
        ) if $self->debug;
        my $controller = $rule->{controller};
        $controller->require;

        my $method = uc $self->req->method;
        my $sub = $controller->can("${action}_${method}")
               || $controller->can($action);

        if ($sub) {
            $sub->( $controller, $self, $rule->{args} );
        }
        else {
            $self->error(
                404 => "dispatch action (${controller}::${action} or ${controller}::${action}_${method}) is not found. for " . $self->req->uri
            );
        }
    }
    else {
        $self->error(
            404 => "dispatch rule is not found for " . $self->req->uri
        );
    }
    $self;
}

sub error {
    my ($self, $status, $message) = @_;
    my (undef, $file, $line) = caller;
    $self->log->error($message . " at $file line $line");
    require HTTP::Status;
    $status ||= 500;
    $self->res->body( HTTP::Status::status_message($status) );
    $self->res->status($status);
    detach();
}

sub detach {
    CGI::ExceptionManager::detach()
}

sub dispatch_static {
    my (undef, $self, $args) = @_;

    my $file = $self->path_to("static", $args->{filename});
    $self->serve_static_file($file);
}

sub serve_static_file {
    my ( $self, $file ) = @_;

    $file = Path::Class::file($file) unless ref $file;

    $self->log->debug("serving static file. $file");

    my $res = $self->res;
    if ( -f $file ) {
        unless ( -r _ ) {
            $self->error( 403 => "can't read file $file : $!" );
        }

        my $mtime = $file->stat->mtime;
        if (my $ims = $self->req->header('If-Modified-Since')) {
            my $time = HTTP::Date::str2time($ims);
            if ( $mtime <= $time ) {
                $res->status(304);
                return;
            }
        }
        $res->body( scalar $file->slurp );

        my $ext = ( $file =~ /\.(\w+)$/ ) ? lc($1) : "";
        $res->header(
            'Content-Type'  => Acore::MIME::Types->mimeTypeOf($ext) || "text/plain",
            'Last-Modified' => HTTP::Date::time2str($mtime)
        );
    }
    else {
        $self->error( 404 => "$file is not exists. $!");
    }
}


sub serve_acore_document {
    my ( $self, $path ) = @_;

    $self->log->debug("serving acore_document path: $path");

    my $doc = $self->acore->get_document({ path => $path });
    unless ($doc) {
        $self->error( 404 => "Not found acore document path: $path" );
    }

    my $res   = $self->response;
    my $ctype = $doc->can('content_type') ? $doc->content_type
                                          : "text/plain";
    $res->header(
        "Content-Type"  => $ctype,
        "Last-Modified" => HTTP::Date::time2str( $doc->updated_on->epoch ),
    );
    $res->body( $doc->as_string );
    return 1;
}

sub redirect {
    my ($self, $to, $status) = @_;
    $self->res->status( $status || 302 );
    $self->res->header( Location => $to );
    $self->log->debug("redirecting to $to");
    $to;
}

sub uri_for {
    my $self = shift;
    my $path = shift;

    my @path = map { uri_escape_utf8($_) } grep {! ref $_ } @_;
    $path .= join("/", @path);
    $path =~ s{^/}{};

    my $uri = URI->new($path);
    $uri = $uri->abs( $self->req->base );

    $uri->query_form(%{ $_[-1] })
        if ref $_[-1] eq 'HASH';

    return $uri;
}

sub render {
    my ($self, $tmpl) = @_;
    my $html = $self->render_part($tmpl);
    $self->res->body( $self->encoder->encode($html) );
}

sub render_part {
    my ($self, $tmpl) = @_;
    return $self->renderer->render_file( $tmpl, $self )->as_string;
}

sub dispatch_favicon {
    my ($self, $c) = @_;
    $c->serve_static_file( $c->path_to("favicon.ico") );
}

sub add_trigger {
    my $class    = shift;
    my %triggers = @_;
    push @{ $Triggers->{$class}->{$_} }, $triggers{$_}
        for keys %triggers;
}

sub _call_trigger {
    my $self  = shift;
    my $point = shift;
    for my $sub (@{ $self->_triggers->{$point} }) {
        $sub->($self);
    }
}

sub forward {
    my $self = shift;
    my ($class, $action, @args) = @_;

    $self->log->debug("forward to ${class}->${action}");
    $class->$action( $self, @args );
}

sub login {
    my $self = shift;
    my ( $name, $password ) = @_;

    my $user = $self->acore->authenticate_user({
        name     => $name,
        password => $password,
    });
    $self->log->info( "login: name=$name " . ($user ? "succeeded" : "failed") );
    $self->session->set( user => $user );
    $self->user($user);
}

sub logout {
    my $self = shift;
    $self->user(undef);
    $self->session->expire();
}

sub welcome_message {
    my $c    = shift;
    my $name = $c->config->{name};
    my $base = $c->req->base;

    use English;
    require Module::CoreList;

    $c->response->content_type('text/html; charset=utf-8');
    my $body = Text::MicroTemplate::render_mt(<<'EOF'
? my $c = $_[0]
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
  <head>
  <meta http-equiv="Content-Language" content="ja" />
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title><?= $c->config->{name} ?> on Acore::WAF <?= $Acore::WAF::VERSION ?></title>
  <style type="text/css">
    body {
      color: #000;
      background-color: #eee;
    }
    div#content {
      width: 640px;
      margin-left: auto;
      margin-right: auto;
      margin-top: 10px;
      margin-bottom: 10px;
      text-align: left;
      background-color: #ccc;
      border: 1px solid #aaa;
    }
    p, h1, h2 {
      margin-left: 20px;
      margin-right: 20px;
      font-family: verdana, tahoma, sans-serif;
    }
    a {
      font-family: verdana, tahoma, sans-serif;
    }
    :link, :visited {
      text-decoration: none;
      color: #b00;
      border-bottom: 1px dotted #bbb;
    }
    :link:hover, :visited:hover {
      color: #555;
    }
    div#topbar {
      margin: 0px;
    }
    pre {
      margin: 10px;
      padding: 8px;
    }
    div#answers {
      padding: 8px;
      margin: 10px;
      background-color: #fff;
      border: 1px solid #aaa;
    }
    h1 {
      font-size: 0.9em;
      font-weight: normal;
      text-align: center;
    }
    p {
      font-size: 0.9em;
    }
    p img {
      float: right;
      margin-left: 10px;
    }
    span#appname {
      font-weight: bold;
      font-size: 1.6em;
    }
    </style>
  </head>
  <body>
    <div id="content">
      <div id="topbar">
        <h1><span id="appname"><?= $c->config->{name} ?></span> on Acore::WAF <?= $Acore::WAF::VERSION ?></h1>
      </div>
      <div id="answers">
        <p><img src="<?= $c->uri_for('/static/anycms-logo.png') ?>" alt="AnyCMS" width="200" height="67" />
          Welcome to the  world of Acore::WAF.
        </p>
        <h2>Information</h2>
        <table>
          <tr><th>OS</th><td><?= $OSNAME ?></td></tr>
          <tr><th>Perl version</th><td><?= $] ?></td></tr>
          <tr><th>Perlのパス</th><td><?= $EXECUTABLE_NAME ?></td></tr>
          <tr><th>モジュールパス</th><td>
? for my $inc (@INC) {
              <?= $inc ?><br/>
? }
          </td></tr>
          <tr><th>プロセスID</th><td><?= $$ ?></td></tr>
        </table>

        <h2>環境変数</h2>
        <table>
? for my $key (sort keys %ENV) {
          <tr><th><?= $key ?></th><td><?= $ENV{$key} ?></td>
? }
        </table>

        <h2>Perl標準添付モジュール(perl <?= $] ?>)</h2>
        <table>
? my $modules = $Module::CoreList::version{$]};
? for my $key (sort keys %$modules) {
        <tr><th><?= $key ?></th><td><?= $modules->{$key} || '' ?></td>
? }
        </table>
      </div>
    </div>
  </body>
</html>
EOF
    , $c )->as_string;
    $c->response->body($body);
}

1;

__END__

=head1 NAME

Acore::WAF - AnyCMS web application framework

=head1 SYNOPSIS

 package YourApp;
 use Any::Moose;
 extends 'Acore::WAF';
 __PACKAGE__->setup(@plugins);

 package YourApp::Dispatcher;
 use HTTPx::Dispatcher;
 connect "",
     { controller => "YourApp::Controller", action => "dispatch_index" };
 connect "static/:filename",
     { controller => "YourApp", action => "dispatch_static" };
 connect "favicon.ico",
     { controller => "YourApp", action => "dispatch_favicon" };
 connect ":action",
     { controller => "YourApp::Controller" };

 package YourApp::Controller;
 use utf8;
 sub dispatch_index {
     my ($self, $c) = @_;
     $c->render("index.mt");
 }
 sub foo {
     my ($self, $c) = @_;
     $c->request->param('foo');
     $c->response->body( $c->encode($utf8_flagged_str) );
 }

 #!/usr/bin/perl
 use HTTP::Engine;
 use YourApp;
 my $engine = HTTP::Engine->new(
    interface => {
        module => 'ServerSimple',
        args   => {
            host => "0.0.0.0",
            port => 3000,
        },
        request_handler => sub {
            YourApp->new->handle_request($config, @_);
        },
    },
 );
 $engine->run;

=head1 DESCRIPTION

Acore::WAF is HTTP::Engine based web application framework, with Acore.

=head1 ATTRIBUTES

=over 4

=item stash

 $c->stash->{key} = $value;

=item config

Config hashref.

=item request

HTTP::Engine::Request object.

 $c->request->params->{foo}
 $c->req->params->{foo};

=item response

HTTP::Engine::Response object.

 $c->response->body("body");
 $c->res->body("body");

=item acore

Acore object.

 $config = {
     dsn => ['dbi:SQLite:dbname=foo', '', '',
             { AutoCommit => 1, RaiseError => 1 }
     ],
 };

 $doc = $c->acore->get_document({ path => "/" });

=item log

Acore::WAF::Log object.

 $c->log->info("info message");

=item encoding

External encoding name. default: "utf-8".

=back

=head1 METHODS

=over 4

=item new

Constractor.

=item setup

Class method. Setup plugins.

 # load Acore::WAF::Plugin::Session
 YourApp->setup(qw/ Session /);

=item handle_request

Request handler for HTTP::Engine.

 HTTP::Engine->new(
    interface => {
        module => 'CGI',
        request_handler => sub {
            YourApp->new()->handle_request($config, @_);
        },
    },
 )->run();

=item path_to

Returns Path::Class object in $config->{root}.

 $config->{root} = "/your_app/root";
 $file = $c->path_to("static", "foo.jpg"); # /your_app/root/static/foo.jpg
 $dir  = $c->path_to("static");
 $dir->file("foo.jpg");

=item serve_acore_document

Serve Acore::Document object.

 $c->serve_acore_document("/path/to/object");

Content-Type is Acore::Document->content_type.

Response body is Acore::Document->as_string.

=item uri_for

 $c->uri_for("/path/to", @args?, {params}?);

Like Catalyst->uri_for.

=item redirect

Redirect to URL.

 $c->redirect( $c->uri_for('/path/to') );

=item render

Render template, and set response body.

Template engine is Text::MicroTemplate.

 $c->render("index.mt");

Include path is $config->{root}->{templates} by default.

To set other include path,
 $config->{include_path} = [ "/path/1", "path/2" ];

# template file

 ? $c = $_[0]
 <title><?= $c->stash->{title} ?></title>
 uri: <?= $c->req->uri ?>

=item render_part

Render template, but not set response body.

 $mail = $c->render_part("mail_template.mt");

Like TT's [% INCLUDE %]

 ?=r $_[0]->render_part("file");

=item serve_static_file

Serve static file in $config->{root} dir.

 $c->serve_static_file("static/foo.jpg");

=item forward

Forward to other controller's action.

 $c->forward("YourApp::Controller::Foo", "action", @args);

 package YourApp::Controller::Foo;
 sub action {
     my ($self, $c, @args) = @_;
     $c->forward($self, "other");
 }
 sub other {
     my ($self, $c) = @_;
 }

=item add_trigger

Class method. Set trigger in YourApp class.

Available trigger points are "BEFORE_DISPATCH" and "AFTER_DISPATCH".

 package Acore::WAF::Plugin::Foo;
 sub setup {
     my ($class, $app) = @_;
     $app->add_trigger(
         BEFORE_DISPATCH => sub {
             my $c = shift;
             # ...
         },
     );
 }

=item finalize

Finalize method.

 package YourApp;
 use Any::Moose;
 extends 'Acore::WAF';
 override "finalize" => sub {
     super()
     # your finalize code
 };

=item detach

Detach from action.

 sub action_foo {
     my ($self, $c) = @_;
     $c->detach;
     # not reached here
 }

=item error

Send error to client and detach().

 sub action_foo {
     my ($self, $c) = @_;
     $c->error( $status_code => $message_for_log );
     # not reached here
 }

=item welcome_message

Returns welcome message HTML.

=item login

Login user using Acore::User->authenticate_user();

Plugin::Session required.

 if ( $c->login("username", "password") ) {
     # login succeeded
     $c->user;  # isa Acore::User
 }

=item logout

Log out user from session.

=back

=head1 INSTALLED ACTIONS

 package YourApp::Dispatcher;
 use HTTPx::Dispatcher;
 connect "static/:filename",
     { controller => "YourApp", action => "dispatch_static" };
 connect "favicon.ico",
     { controller => "YourApp", action => "dispatch_favicon" };

=over 4

=item dispatch_static

Serve static file in {root}/static dir.

=item dispatch_favicon

Serve {root}/favicon.ico .

=back


=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
