package Acore::WAF::MinimalCGI;

use strict;
use warnings;
use URI;
{
    package HTTP::Engine::Request;
    sub uri  { $ENV{PATH_INFO} }
    sub path { $ENV{PATH_INFO} }
    sub base {
        my $self = shift;
        $self->{base} ||= URI->new(
            sprintf(
                "http%s://%s%s/",
                ($ENV{HTTPS} ? "s" : ""),
                ($ENV{HTTP_HOST} || $ENV{SERVER_NAME}),
                ($ENV{SCRIPT_NAME})
            )
        );
        $self->{base};
    }
}

1;

