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

sub log {
    my $self = shift;
    my ($level, $msg) = @_;
    warn "[$level] $msg\n";
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
    $self->request($req);
    $self->config($config);
    eval {
        $self->dispatch;
    };
    if ($@) {
        $self->log( error => $@ );
        $self->res->body("Internal Server Error");
        $self->res->status(500);
    }
    return $self->response;
}

sub before_dispatch {}
sub after_dispatch {}

sub dispatch {
    my ( $self ) = @_;

    my $path = $ENV{PATH_INFO} || $self->req->path;
    my ($controller, @args)
        = grep /./, split("/", $path);
    $controller ||= "index";
    $self->stash->{args} = \@args;

    if ( my $sub = $self->can("dispatch_${controller}") ) {
        my $response = $sub->($self);
        return $response;
    }
    else {
        $self->res->status(404);
        $self->res->body("not found");
    }
}

sub prepare_acore {
    my $self = shift;
    require Acore;
    require DBI;
    my $dbh  = DBI->connect( @{ $self->config->{dsn} } )
        or die "Can't connect DB: " . DBI->errstr;
    $self->acore( Acore->new({ dbh => $dbh }) );
}

sub dispatch_static {
    my $self = shift;

    my $file = $self->path_to(
        "static",
        join("/", @{$self->stash->{args}} ),
    );
    $self->serve_static_file($file);
}

sub serve_static_file {
    my $self = shift;
    my $file = shift;

    $file = Path::Class::file($file) unless ref $file;

    my $res = $self->res;
    if ( -f $file && -r _ ) {
        my $mtime = $file->stat->mtime;
        if (my $ims = $self->req->headers->header('If-Modified-Since')) {
            my $time = HTTP::Date::str2time($ims);
            if ( $mtime <= $time ) {
                $res->status(304);
                return;
            }
        }
        $res->body( scalar $file->slurp );

        my $ext = ( $file =~ /\.(\w+)$/ ) ? lc($1) : "";
        $res->headers->header(
            'Content-Type'  => MIME::Types->new->mimeTypeOf($ext) || "text/plain",
            'Last-Modified' => HTTP::Date::time2str($mtime)
        );
    }
    else {
        $res->status(404);
        $res->body("Not found.");
    }
}

sub render {
    my ($self, $tmpl) = @_;

    my $path = $self->path_to("templates");
    my $mt   = Text::MicroTemplate::File->new(
        include_path => [ $path ],
        use_cache    => 1,
    );
    my $html = $mt->render_file( $tmpl, $self )->as_string;
    $self->res->body( encode_utf8($html) );
}

1;
