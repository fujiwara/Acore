package Acore::WAF::Plugin::Session;

use strict;
use warnings;
use Want;
use Exporter 'import';
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
        $c->log->debug("session inited.");
    }
    return want('HASH') ? $c->{_session_obj}->as_hashref
                        : $c->{_session_obj};
}

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

=head1 DESCRIPTION

Acore session plugin by HTTP::Session

=head1 EXPORT METHODS

=over 4

=item session

An instance of HTTP::Session.

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

HTTP::Session

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
