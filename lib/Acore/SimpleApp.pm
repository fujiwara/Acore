package Acore::SimpleApp;

use strict;
use warnings;
use Any::Moose;
use Acore;
use Text::MicroTemplate::File ();
use Path::Class ();
use MIME::Types;
use HTTP::Date;
use DBI;

has context => ( is => "rw" );
__PACKAGE__->meta->make_immutable;

no Any::Moose;
*c = \&context;

sub handle_request {
    my $self = shift;
    my ($config, $req) = @_;
    $self->context(
        Acore::SimpleApp::Context->new({
            request => $req,
            config  => $config,
        })
    );
    $self->dispatch;
    return $self->context->response;
}

sub dispatch {
    my ( $self ) = @_;
    my $c = $self->context;

    my $path = $ENV{PATH_INFO} || $self->context->req->path;
    my ($controller, @args)
        = grep /./, split("/", $path);
    $controller ||= "index";
    $c->stash->{args} = \@args;

    if ( my $sub = $self->can("dispatch_${controller}") ) {
        return $sub->($self);
    }
    else {
        $c->res->status(404);
        $c->res->body("not found");
    }
}

sub prepare_acore {
    my $self = shift;
    my $c = $self->c;
    my $dbh  = DBI->connect( @{ $c->config->{dsn} } )
        or die "Can't connect DB: " . DBI->errstr;
    $c->acore( Acore->new({ dbh => $dbh }) );
}

sub dispatch_index {
    my ($self) = @_;
    $self->prepare_acore();
    $self->render("index.mt");
}

sub dispatch_static {
    my $self = shift;
    my $c = $self->c;

    my $file = $c->path_to(
        "static",
        join("/", @{$c->stash->{args}} ),
    );

    if ( -f $file && -r _ ) {
        my $mtime = $file->stat->mtime;
        if (my $ims = $c->req->headers->header('If-Modified-Since')) {
            my $time = HTTP::Date::str2time($ims);
            if ( $mtime <= $time ) {
                $c->res->status(304);
                return;
            }
        }
        $c->res->body( scalar $file->slurp );

        my $ext = ( $file =~ /\.(\w+)$/ ) ? lc($1) : "";
        $c->res->headers->header(
            'Content-Type' =>  MIME::Types->new->mimeTypeOf($ext) || "text/plain",
        );
        $c->res->headers->header(
            'Last-Modified' => HTTP::Date::time2str($mtime)
        );
    }
    else {
        $c->res->status(404);
        $c->res->body("not found");
    }
}

sub render {
    my ($self, $tmpl) = @_;
    my $c = $self->context;

    my $path = Path::Class::dir(
        $c->config->{root} || ".",
        "templates",
    );
    my $mt = Text::MicroTemplate::File->new(
        include_path => [ $path ],
        use_cache    => 1,
    );
    $c->res->body(
        $mt->render_file( $tmpl, $c )->as_string,
    );
}

package Acore::SimpleApp::Context;
use Any::Moose;

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

has response => (
    is      => "rw",
    default => sub { HTTP::Engine::Response->new },
);

has acore => (
    is  => "rw",
    isa => "Acore",
);

__PACKAGE__->meta->make_immutable;
no Any::Moose;
*req = \&request;
*res = \&response;

sub path_to {
    my $self = shift;
    Path::Class::file(
        $self->config->{root} || ".",
        @_,
    );
}

1;
