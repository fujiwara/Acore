package Acore::WAF;

use strict;
use warnings;
use Any::Moose;
use Text::MicroTemplate::File ();
use Path::Class ();
use MIME::Types;
use HTTP::Date;
use utf8;
use Encode qw/ encode_utf8 decode_utf8 encode decode /;
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

has triggers => (
    is  => "rw",
    isa => "HashRef",
);

has log => (
    is         => "rw",
    isa        => "Acore::WAF::Log",
    lazy_build => 1,
);

sub _build_log {
    my $self = shift;
    my $log  = Acore::WAF::Log->new;
    $log->level( $self->config->{log}->{level} )
        if defined $self->config->{log}->{level};
    $log;
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

sub handle_request {
    my $self = shift;
    my ($config, $req) = @_;

    my $class = ref $self;
    $self->request($req);
    $self->config($config);
    $config->{include_path} ||= [];
    $self->triggers( $Triggers->{$class} );
    eval {
        $self->call_trigger('BEFORE_DISPATCH');
        $self->dispatch;
        $self->call_trigger('AFTER_DISPATCH');
    };
    if ($@) {
        $self->log->error($@);
        $self->res->body("Internal Server Error");
        $self->res->status(500);
    }
    $self->log->flush;
    return $self->response;
}

sub dispatch {
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
            $self->log->error("dispatch action (${controller}::${action}) is not found. for " . $self->req->uri );
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
    return unless $doc;

    my $res   = $self->response;
    my $ctype = $doc->can('content_type')
        ? $doc->content_type : "text/plain";
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
    $self->res->body( encode_utf8($html) );
}

sub render_part {
    my ($self, $tmpl) = @_;

    my $path = $self->path_to("templates");
    my $mt   = Text::MicroTemplate::File->new(
        include_path => [ $path, @{ $self->config->{include_path} } ],
    );
    return $mt->render_file( $tmpl, $self )->as_string;
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

sub call_trigger {
    my $self  = shift;
    my $point = shift;
    for my $sub (@{ $self->triggers->{$point} }) {
        $sub->($self);
    }
}

1;
