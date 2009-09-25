package Acore::WAF::Plugin::Session;

use strict;
use warnings;
use Any::Moose "::Role";

after _dispatch => sub {
    my $c = shift;
    if ( my $session = $c->{session} ) {
        if ( my $flash = $session->get('__flash_data') ) {
            $session->set( __flash_data => $flash->finalize );
        }
        my ($type) = $c->res->content_type;
        $session->response_filter($c->response)
            if $type eq "" || $type =~ m{^text/x?html};
    }
};

has session => (
    is      => "rw",
    lazy    => 1,
    default => sub {
        my $c = shift;
        require HTTP::Session;
        my $config = $c->config->{session};
        my $store_class = "HTTP::Session::Store::" . $config->{store}->{class};
        my $state_class = "HTTP::Session::State::" . $config->{state}->{class};
        $store_class->require;

        my $state = $c->for_mobile
            ? do {
                # mobile は常に State::URI
                require HTTP::Session::State::URI;
                $c->log->debug("using State::URI");
                HTTP::Session::State::URI->new( session_id_name => "_sid" );
            }
            : do {
                $state_class->require;
                $state_class->new( %{ $config->{state}->{args} } );
            };

        my $s = HTTP::Session->new(
            store   => $store_class->new( %{ $config->{store}->{args} } ),
            state   => $state,
            request => $c->request,
        );
        $c->log->debug("Session inited. state=$state_class store=$store_class");
        return $s;
    },
);

sub flash {
    my $c     = shift;
    my $flash = $c->session->get('__flash_data');
    return $flash if $flash;

    $flash = Acore::WAF::Plugin::Session::Flash->new;
    $c->session->set( __flash_data => $flash );
    $flash;
}

requires "_uri_for";
around   "_uri_for" => sub {
    my $next = shift;
    my $self = shift;
    my $uri  = $next->($self, @_);

    if ( $self->for_mobile ) {
        my $s    = $self->session;
        my $name = $s->state->session_id_name;
        my %q    = $uri->query_form;
        $q{$name} ||= $s->session_id;
        $uri->query_form(%q);
    }
    $uri;
};

package Acore::WAF::Plugin::Session::Flash;
use Any::Moose;

sub get {
    my ($self, $key) = @_;
    $self->{__got_key}->{$key} = 1;
    $self->{$key};
}

sub set {
    my ($self, $key, $value) = @_;
    delete $self->{__got_key}->{$key};
    $self->{$key} = $value;
}

sub finalize {
    my $self = shift;

    if ( $self->{__got_key} ) {
        for my $key ( keys %{ $self->{__got_key} } ) {
            delete $self->{$key};
        }
    }
    delete $self->{__got_key};
    return keys %$self ? $self : undef;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Acore::WAF::Plugin::Session - AnyCMS session plugin

=head1 SYNOPSIS

 YourApp->setup(qw/ Session /);
 $config->{session} = {
     store => {
         class => "DBM",
         args  => { file => "t/sessoin.dbm", },
     },
     state => {
         class => "Cookie",
         args  => {
             name => "yourapp_session_id",
             path => "/foo/bar",
         },
     },
 };

 package YourApp::Controller;
 sub foo {
     my ($self, $c) = @_;
     $c->session->set(foo => "bar");
     $c->session->get("foo");
     $c->session->expire();
 }

 # for POST REDIRECT GET pattern
 sub update_POST {
     my ($self, $c) = @_;
     $c->flash->set( updated => 1 );
     $c->redirect( $c->uri_for("/updated") );
 }
 sub updated_GET {
     my ($self, $c) = @_;
     $c->flash->get('updated');
 }

=head1 DESCRIPTION

Acore session plugin by HTTP::Session

=head1 EXPORT METHODS

=over 4

=item session

An instance of HTTP::Session.

=item flash

An instance of flash data.

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

HTTP::Session

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
