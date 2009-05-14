package Acore::WAF;

use strict;
use warnings;
use Any::Moose;
use Text::MicroTemplate::File ();
use Path::Class ();
use MIME::Types;
use HTTP::Date;
use utf8;
use Encode qw/ encode_utf8 decode_utf8 /;
use UNIVERSAL::require;
use Acore::WAF::Log;
use URI::Escape;

has stash => (
    is      => "rw",
    isa     => "HashRef",
    default => sub { +{} },
);

has config  => (
    is => "rw",
    isa => "HashRef",
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
    is  => "rw",
    isa => "Acore",
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
        $log->info("loading plugin: $p_class");
        $p_class->use or die "Can't load plugin: $@";
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
    my $ref  = $self->request->params;
    my $enc  = $self->encoder;

    for my $n ( keys %$ref ) {
        my $v = $ref->{$n};
        $ref->{$n}
            = ( ref $v eq "ARRAY" ) ? [ map { $enc->decode($_) } @$v ]
            : ( !ref $v )           ? $enc->decode($v)
            : $v;
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

    eval {
        $self->_call_trigger('BEFORE_DISPATCH');
        $self->_dispatch;
        $self->_call_trigger('AFTER_DISPATCH');
    };
    if ($@) {
        $self->log->error($@);
        $self->res->body("Internal Server Error");
        $self->res->status(500);
    }
    $self->finalize();
    $self->log->flush;
    return $self->response;
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
    my $rule = $dispatcher->match( $self->req );
    if ($rule) {
        my $action = $rule->{action};
        use Data::Dumper;
        local $Data::Dumper::Indent = 1;
        $self->log->debug( "dispatch rule: " . Dumper $rule );
        my $controller = $rule->{controller};
        $controller->require;

        my $method = uc $self->req->method;
        my $sub = $controller->can("${action}_${method}")
               || $controller->can($action);

        if ($sub) {
            $sub->( $controller, $self, $rule->{args} );
        }
        else {
            $self->log->error("dispatch action (${controller}::${action} or ${controller}::${action}_${method}) is not found. for " . $self->req->uri );
            $self->res->body("Not found.");
            $self->res->status(404);
        }
    }
    else {
        $self->log->error("dispatch rule is not found for " . $self->req->uri);
        $self->res->body("Not found.");
        $self->res->status(404);
    }
    $self;
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
            $self->log->error("can't read file $file : $!");
            $res->status(403);
            $res->body("forbidden.");
            return;
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
            'Content-Type'  => MIME::Types->new->mimeTypeOf($ext) || "text/plain",
            'Last-Modified' => HTTP::Date::time2str($mtime)
        );
    }
    else {
        $self->log->error("$file is not exists. $!");
        $res->status(404);
        $res->body("Not found.");
    }
}

sub prepare_acore {
    my $self = shift;

    return if $self->acore;
    require Acore;
    require DBI;
    my $dbh  = DBI->connect( @{ $self->config->{dsn} } )
        or die "Can't connect DB: " . DBI->errstr;
    $self->acore( Acore->new({ dbh => $dbh }) );
}

sub serve_acore_document {
    my ( $self, $path ) = @_;

    $self->log->debug("serving acore_document path: $path");

    $self->prepare_acore();
    my $doc = $self->acore->get_document({ path => $path });
    unless ($doc) {
        $self->res->status(404);
        $self->res->body("Not found.");
        return;
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
    my ($self, $to) = @_;
    $self->res->status(302);
    $self->res->header( Location => $to );
    $self->log->debug("redirecting to $to");
}

sub uri_for {
    my $self = shift;
    my $path = shift;

    my @path = map { uri_escape_utf8($_) } grep {! ref $_ } @_;
    $path .= join("/", @path);

    my $uri = URI->new($path);
    $uri = $uri->abs( $self->req->uri );

    $uri->query_form(%{ $_[-1] })
        if ref $_[-1] eq 'HASH';

    return $uri;
}

sub render {
    my ($self, $tmpl) = @_;
    my $html = $self->render_part($tmpl);
    my $res  = $self->res;
    $res->body( $self->encoder->encode($html) );
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

 $c->prepare_acore
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

=item path_to(@path)

Returns Path::Class object under $config->{root}.

 $config->{root} = "/your_app/root";
 $file = $c->path_to("static", "foo.jpg"); # /your_app/root/static/foo.jpg
 $dir  = $c->path_to("static");
 $dir->file("foo.jpg");

=item prepare_acore

Prepare Acore object. $config->{dsn} is required.

See also acore attribute.

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

Forward other controller's action.

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

=back

=head1 INSTALLED ACTIONS

 package YourApp::Dispatcher;
 use HTTPx::Dispatcher;
 connect "static/:filename",
     { controller => "YourApp", action => "dispatch_static" };
 connect "favicon.ico",
     { controller => "YourApp", action => "dispatch_favicon" };
 connect "document/:path",
     { controller => "YourApp", action => "dispatch_acore_document" };

=over 4

=item dispatch_static

Serve static file in {root}/static dir.

=item dispatch_favicon

Serve {root}/favicon.ico .

=item dispatch_acore

Server Acore::Document.

=back


=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
