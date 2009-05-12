package Acore::WAF::Plugin::Sample;

use strict;
use warnings;
require Exporter;
our @EXPORT = qw/ simple_method /;

sub sample_method {
    my ($self, $c) = @_;
}

1;
