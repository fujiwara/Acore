package Acore::WAF::Plugin::Sample;

use strict;
use warnings;
use Any::Moose "::Role";

after _dispatch => sub {
    my $c = shift;
};

has sumple_attr => (
    is => "rw",
);

sub sample_method {
    my $c = shift;
    $c->res->body("sample plugin");
}

1;

