package Acore::WAF::Controller::Redirector;
use strict;
use warnings;

sub _create_uri {
    my ($self, $c, $args) = @_;
    my $url = $args->{url};

    if ( $url !~ m{^https?://} ) {
        $url = "http://$url";
    }
    if ( $c->req->uri =~ /\?/ ) {
        my (undef, $param) = split /\?/, $c->req->uri, 2;
        $url .= "?$param";
    }
    my $uri = URI->new($url);
    $c->error( 404, "invalid uri $uri" )
        if $uri->scheme !~ /^https?/;
    $uri;
}

sub redirect {
    my ($self, $c, $args) = @_;

    my $uri = $c->forward( $self => "_create_uri", $args );
    $c->redirect($uri);
}

1;

__END__

=head1 DISPATCH TABLE

    connect "rd/:url", to bundled "Redirector" => "redirect";
