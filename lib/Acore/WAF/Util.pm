package Acore::WAF::Util;

use strict;
use warnings;

sub adjust_request_mod_perl {
    my ($class, $req) = @_;

    my $location = $req->_connection->{apache_request}->location || '/';
    $location   .= '/' if $location !~ m{/$};

    $req->uri->base->path_query($location);
    $req->location($location);

    return $req;
}

sub adjust_request_fcgi {
    my ($class, $req) = @_;
    $req->location( $req->uri->base->path );
    return $req;
}

{
    package ## hide for pause
        HTTP::Engine::Request;
    use Any::Moose;
    has location => ( is => "rw" );
}

{
    package Acore::WAF::Util::RequestForDispatcher;
    use Any::Moose;

    has uri    => ( is => "rw" );
    has method => ( is => "rw" );

    __PACKAGE__->meta->make_immutable;
}

1;

__END__
