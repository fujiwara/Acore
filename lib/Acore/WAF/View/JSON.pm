package Acore::WAF::View::JSON;

use strict;
use warnings;
use Any::Moose;
use JSON -convert_blessed_universally;
use Encode ();

has encoding => (
    is      => "rw",
    default => "utf-8",
);

has allow_callback => (
    is      => "rw",
    default => 0,
);

has callback_param => (
    is      => "rw",
    default => "callback",
);

has no_x_json_header => (
    is      => "rw",
    default => 0,
);

has converter => (
    is      => "rw",
    default => sub {
        my $json = JSON->new;
        $json->allow_blessed(1);
        $json->convert_blessed(1);
        $json;
    },
    lazy => 1,
);

__PACKAGE__->meta->make_immutable;
no Any::Moose;

sub setup {
    my ($self, $c) = @_;
    my $config = $c->config->{'View::JSON'} || {};
    for my $key ( keys %$config ) {
        $self->$key( $config->{$key} )
            if $self->can($key);
    }
    $self;
}

sub process {
    my ($self, $c, $obj) = @_;

    my $json = $self->converter->encode($obj);

    my $cb_param = $self->allow_callback ? $self->callback_param : undef;
    my $cb       = $cb_param ? $c->req->param($cb_param) : undef;
    utf8::encode($cb) if defined $cb;

    $self->validate_callback_param($cb) if $cb;

    my $encoding = $self->encoding;
    if ( Encode::is_utf8($json) ) {
        $json = Encode::encode($encoding, $json);
    }
    $c->encoding($encoding);

    if (($c->req->user_agent || '') =~ /Opera/) {
        $c->res->content_type("application/x-javascript; charset=$encoding");
    } else {
        $c->res->content_type("application/json; charset=$encoding");
    }

    if ($c->req->header('X-Prototype-Version') && !$self->no_x_json_header) {
        $c->res->header('X-JSON' => 'eval("("+this.transport.responseText+")")');
    }

    my $output;

    ## add UTF-8 BOM if the client is Safari
    if (($c->req->user_agent || '') =~ m/Safari/ and $encoding eq 'utf-8') {
        $output = "\xEF\xBB\xBF";
    }

    $output .= "$cb(" if $cb;
    $output .= $json;
    $output .= ");"   if $cb;

    $c->res->body($output);
}

sub validate_callback_param {
    my($self, $param) = @_;
    $param =~ /^[a-zA-Z0-9\.\_\[\]]+$/
        or croak("Invalid callback parameter $param");
}

1;

__END__

=head1 NAME

Acore::WAF::View::JSON

=head1 SYNOPSYS

  package YourApp::View::JSON;
  use Any::Moose;
  extends "Acore::WAF::View::JSON";
  1;

  package YourApp::Controller::Foo;
  sub foo {
       my ($self, $c, $args) = @_;
       # create some hash ref
       $c->forward( $c->view("JSON") => "process", $hash_ref );
  }

  # YourApp.yaml
  'View::JSON':
    allow_callback: 1
    callback_param: "callback_me"

