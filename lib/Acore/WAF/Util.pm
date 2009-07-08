package Acore::WAF::Util;

use strict;
use warnings;

sub adjust_request_mod_perl {
    my ($class, $req) = @_;

    my $location = $req->_connection->{apache_request}->location || '/';
    $location   .= '/' if $location !~ m{/$};
    my $uri      = $req->uri;
    my $path     = $uri->path;
    $path =~ s/^$location//;
    $uri->path($path);
    $uri->base->path_query($location);
    $req->uri($uri);
    return $req;
}

sub adjust_request_fcgi {
    my ($class, $req) = @_;
    my $uri      = $req->uri;
    my $location = $uri->base->path;
    my $path     = $uri->path;
    $path =~ s/^$location//;
    $uri->path($path);
    $req->uri($uri);
    return $req;
}

1;

__END__
