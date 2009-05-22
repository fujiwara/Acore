package Acore::WAF::Render;

use strict;
use warnings;
use URI::Escape;

use overload
    '|'  => sub {
        my ($self, $arg) = @_;
        $self->($arg);
    },
    '""' => sub { $_[0] },
;

sub filter(&) { ## no critic
    bless $_[0], __PACKAGE__;
}

sub html() { ## no critic
    filter {
        local $_ = $_[0];
        s{&}{&amp;}g;
        s{<}{&lt;}g;
        s{>}{&gt;}g;
        s{"}{&quot;}g;
        s{'}{&#39;}g;
        $_;
    };
}

sub uri() {  ## no critic
    filter {
        URI::Escape::uri_escape_utf8($_[0]);
    };
}

sub replace($$) {  ## no critic
    my ( $regex, $replace ) = @_;
    filter {
        local $_ = $_[0];
        s{$regex}{$replace}g;
        $_;
    };
}

sub html_line_break() { ## no critic
    filter {
        local $_ = $_[0];
        s{\r*\n}{<br/>}g;
        $_;
    };
}

1;
__END__


