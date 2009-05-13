package Acore::WAF::Plugin::Session;

use strict;
use warnings;
use Want;
require Exporter;
our @EXPORT = qw/ session /;

sub setup {
    my ($class, $controller) = @_;
    $controller->add_trigger(
        AFTER_DISPATCH => sub {
            my $c = shift;
            $c->session->response_filter($c->response)
                if $c->{_session_obj};
        },
    );
}

sub session {
    my $c = shift;

    unless ( $c->{_session_obj} ) {
        require HTTP::Session;
        my $config = $c->config->{session};
        my $store_class = "HTTP::Session::Store::" . $config->{store}->{class};
        my $state_class = "HTTP::Session::State::" . $config->{state}->{class};
        $store_class->require;
        $state_class->require;
        $c->{_session_obj} = HTTP::Session->new(
            store   => $store_class->new( %{ $config->{store}->{args} } ),
            state   => $state_class->new( %{ $config->{state}->{args} } ),
            request => $c->request,
        );
        $c->log( debug => "session inited." );
    }
    return want('HASH') ? $c->{_session_obj}->as_hashref
                        : $c->{_session_obj};
}


1;
