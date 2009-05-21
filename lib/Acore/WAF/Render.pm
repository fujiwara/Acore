package Acore::WAF::Render;

use strict;
use warnings;
use URI::Escape;

sub html($) { ## no critic
    local $_ = $_[0];
    s{&}{&amp;}g;
    s{<}{&lt;}g;
    s{>}{&gt;}g;
    s{"}{&quot;}g;
    s{'}{&#39;}g;
    $_;
}

sub uri($) {  ## no critic
    URI::Escape::uri_escape_utf8($_[0]);
}

sub replace($$$) {  ## no critic
    my ( $src, $regex, $replace ) = @_;
    $src =~ s/$regex/$replace/g;
    $src;
}

1;
__END__


