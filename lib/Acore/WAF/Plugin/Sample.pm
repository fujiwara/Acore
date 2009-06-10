package Acore::WAF::Plugin::Sample;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw/ sample_method /;

sub setup {
    my ($class, $controller) = @_;
    $controller->add_trigger(
        AFTER_DISPATCH => sub { },
    );
}

sub sample_method {
    my $c = shift;
    $c->res->body("sample plugin");
}

1;
